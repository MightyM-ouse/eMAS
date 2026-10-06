#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CorpusRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $FreezeManifestPath,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    [string] $ExpectationsPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ([string]::IsNullOrWhiteSpace($ExpectationsPath)) {
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/reference-inventory/wave1-expectations.json'
}
$repositoryDiscoveryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$xmlInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$referenceInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1'
$safeXmlHelperPath = Join-Path $repositoryRoot 'engine/powershell51/private/eMAS.SafeXml.ps1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
Import-Module -Name $repositoryDiscoveryModulePath -Force -ErrorAction Stop
Import-Module -Name $xmlInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceInventoryModulePath -Force -ErrorAction Stop

$resolvedCorpusRoot = [System.IO.Path]::GetFullPath($CorpusRoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$resultRoot = Join-Path $resolvedOutputRoot 'results'
[void][System.IO.Directory]::CreateDirectory($resultRoot)

$startedAtUtc = [DateTime]::UtcNow
$manifestRows = @(Import-Csv -LiteralPath $FreezeManifestPath)
$expectations = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($ExpectationsPath)) | ConvertFrom-Json
$sourceState = @{}
$primaryResults = New-Object System.Collections.ArrayList
$regressionResults = New-Object System.Collections.ArrayList
$additionalResults = New-Object System.Collections.ArrayList
$resultBySample = @{}
$frozenBeforeVerified = 0
$frozenAfterVerified = 0

function Get-eMASTestSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Assert-eMASTrue {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-eMASEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}

function Write-eMASTestJson {
    param([Parameter(Mandatory = $true)][object] $Value, [Parameter(Mandatory = $true)][string] $Path)

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 64), $encoding)
}

function ConvertTo-eMASAcceptedDomainProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([pscustomobject][ordered]@{
        Repository = $Result.Repository
        DossierCandidates = [object[]]@($Result.DossierCandidates)
        Sequences = [object[]]@($Result.Sequences)
        XmlDocuments = [object[]]@($Result.XmlDocuments)
        Files = [object[]]@($Result.Files)
        LifecycleRelationships = [object[]]@($Result.LifecycleRelationships)
        Observations = [object[]]@($Result.Observations)
        ClassificationEvidence = [object[]]@($Result.ClassificationEvidence)
    } | ConvertTo-Json -Depth 64 -Compress)
}

function ConvertTo-eMASReferenceProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([pscustomobject][ordered]@{
        References = [object[]]@($Result.References)
        Coverage = [object[]]@($Result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceInventory' })
    } | ConvertTo-Json -Depth 64 -Compress)
}

function Get-eMASExpectedPerXml {
    param([Parameter(Mandatory = $true)][string] $RelativePath)

    $matches = @($expectations.baseline.perXml | Where-Object { $RelativePath.EndsWith([string]$_.relativePathSuffix, [System.StringComparison]::Ordinal) })
    Assert-eMASEqual -Expected 1 -Actual $matches.Count -Message "No unique baseline expectation for $RelativePath."
    return $matches[0]
}

function Get-eMASUnavailableExpectation {
    param([Parameter(Mandatory = $true)][object] $FixtureExpectation, [Parameter(Mandatory = $true)][string] $RelativePath)

    $matches = @($FixtureExpectation.unavailableCoverage | Where-Object { $RelativePath.EndsWith([string]$_.relativePathSuffix, [System.StringComparison]::Ordinal) })
    if ($matches.Count -eq 0) { return $null }
    Assert-eMASEqual -Expected 1 -Actual $matches.Count -Message "Duplicate unavailable-coverage expectation for $RelativePath."
    return $matches[0]
}

function Test-eMASReferenceBoundary {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $SampleId)

    Assert-eMASEqual -Expected 0 -Actual @($Result.LifecycleRelationships).Count -Message "$SampleId populated lifecycleRelationships."
    Assert-eMASEqual -Expected 0 -Actual @($Result.ClassificationEvidence).Count -Message "$SampleId populated classificationEvidence."
    foreach ($reference in @($Result.References)) {
        foreach ($field in @($expectations.mustRemainNullReferenceFields)) {
            Assert-eMASEqual -Expected $null -Actual $reference.$field -Message "$SampleId populated deferred reference field $field on $($reference.ReferenceId)."
        }
        Assert-eMASEqual -Expected 'Available' -Actual $reference.CaptureStatus -Message "$SampleId raw-reference capture status differs."
    }
    foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
        $items = @($Result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
        Assert-eMASEqual -Expected 1 -Actual $items.Count -Message "$SampleId coverage count differs for $checkId."
        Assert-eMASEqual -Expected 'NotCollected' -Actual $items[0].CaptureStatus -Message "$SampleId completed deferred check $checkId."
        Assert-eMASEqual -Expected 0 -Actual $items[0].RecordsProduced -Message "$SampleId produced deferred records for $checkId."
    }
    foreach ($code in @($expectations.prohibitedObservationCodes)) {
        Assert-eMASEqual -Expected 0 -Actual @($Result.Observations | Where-Object { $_.Code -eq $code }).Count -Message "$SampleId emitted prohibited observation $code."
    }
}

function Invoke-eMASRecordedCheck {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)

    try {
        & $Action
        [void]$additionalResults.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        [void]$additionalResults.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

# Freeze gate: verify every executable fixture before any scanner invocation.
foreach ($manifestRow in @($manifestRows | Where-Object { $_.VerificationStatus -eq 'PASS_FROZEN' })) {
    $relativeFixturePath = $manifestRow.FixtureFilename -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $fixturePath = Join-Path $resolvedCorpusRoot $relativeFixturePath
    if (-not [System.IO.File]::Exists($fixturePath)) { throw ('FREEZE-VERIFY-001 Frozen fixture is missing: {0}' -f $manifestRow.SampleId) }
    $actualHash = Get-eMASTestSha256 -Path $fixturePath
    if ($actualHash -ne $manifestRow.FixtureSHA256) { throw ('FREEZE-VERIFY-002 Frozen fixture hash mismatch: {0}' -f $manifestRow.SampleId) }
    $sourceState[$manifestRow.SampleId] = [pscustomobject]@{
        Path = $fixturePath
        Hash = $actualHash
        LastWriteTimeUtc = (New-Object System.IO.FileInfo($fixturePath)).LastWriteTimeUtc
    }
    $frozenBeforeVerified++
}
Write-Output ('[PASS] Pre-test freeze gate verified {0} ZIP fixtures.' -f $frozenBeforeVerified)

$primaryIds = @($expectations.fixtures | ForEach-Object { $_.sampleId })
foreach ($fixtureExpectation in @($expectations.fixtures)) {
    $sampleId = [string]$fixtureExpectation.sampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.reference-inventory.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-REFERENCE-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $acceptedDomainBefore = ConvertTo-eMASAcceptedDomainProjection -Result $xmlResult
        $result = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $acceptedDomainBefore -Actual (ConvertTo-eMASAcceptedDomainProjection -Result $result) -Message "$sampleId altered accepted RepositoryDiscovery/BackboneXmlInventory domain facts."
        Assert-eMASEqual -Expected $fixtureExpectation.referenceCount -Actual @($result.References).Count -Message "$sampleId reference count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.hrefCount -Actual @($result.References | Where-Object { $null -ne $_.RawHref }).Count -Message "$sampleId href count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.commonReferenceCount -Actual @($result.References | Where-Object { $_.XmlKind -eq 'CommonBackbone' }).Count -Message "$sampleId common reference count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.regionalReferenceCount -Actual @($result.References | Where-Object { $_.XmlKind -eq 'RegionalBackbone' }).Count -Message "$sampleId regional reference count differs."
        Assert-eMASEqual -Expected 0 -Actual @($result.References | Where-Object { $_.XmlKind -eq 'Other' }).Count -Message "$sampleId extracted references from XmlKind Other."
        Test-eMASReferenceBoundary -Result $result -SampleId $sampleId

        $supportedDocuments = @($result.XmlDocuments | Where-Object { $_.XmlKind -eq 'CommonBackbone' -or $_.XmlKind -eq 'RegionalBackbone' })
        $referenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceInventory' -and $_.SubjectType -eq 'XmlDocument' })
        Assert-eMASEqual -Expected $supportedDocuments.Count -Actual $referenceCoverage.Count -Message "$sampleId per-XML reference coverage count differs."
        $repositoryReferenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceInventory' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected 1 -Actual $repositoryReferenceCoverage.Count -Message "$sampleId repository ReferenceInventory coverage count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.referenceCount -Actual $repositoryReferenceCoverage[0].RecordsProduced -Message "$sampleId repository ReferenceInventory coverage total differs."
        foreach ($xmlDocument in $supportedDocuments) {
            $coverage = @($referenceCoverage | Where-Object { $_.SubjectId -eq $xmlDocument.XmlId })
            Assert-eMASEqual -Expected 1 -Actual $coverage.Count -Message "$sampleId coverage is not unique for $($xmlDocument.RelativePath)."
            $unavailableExpectation = Get-eMASUnavailableExpectation -FixtureExpectation $fixtureExpectation -RelativePath $xmlDocument.RelativePath
            if ($null -ne $unavailableExpectation) {
                Assert-eMASEqual -Expected $unavailableExpectation.captureStatus -Actual $coverage[0].CaptureStatus -Message "$sampleId unavailable coverage status differs for $($xmlDocument.RelativePath)."
                Assert-eMASEqual -Expected $unavailableExpectation.reasonCode -Actual $coverage[0].ReasonCode -Message "$sampleId unavailable coverage reason differs for $($xmlDocument.RelativePath)."
                Assert-eMASEqual -Expected 0 -Actual $coverage[0].RecordsProduced -Message "$sampleId salvaged references from unavailable XML $($xmlDocument.RelativePath)."
            }
            else {
                $perXmlExpectation = Get-eMASExpectedPerXml -RelativePath $xmlDocument.RelativePath
                Assert-eMASEqual -Expected 'Available' -Actual $coverage[0].CaptureStatus -Message "$sampleId available coverage status differs for $($xmlDocument.RelativePath)."
                Assert-eMASEqual -Expected $perXmlExpectation.referenceCount -Actual $coverage[0].RecordsProduced -Message "$sampleId per-XML reference count differs for $($xmlDocument.RelativePath)."
                Assert-eMASEqual -Expected $coverage[0].RecordsProduced -Actual @($result.References | Where-Object { $_.XmlId -eq $xmlDocument.XmlId }).Count -Message "$sampleId reference records do not match coverage for $($xmlDocument.RelativePath)."
            }
        }

        $expectedIds = for ($index = 1; $index -le $result.References.Count; $index++) { 'REF-{0:D4}' -f $index }
        Assert-eMASEqual -Expected ($expectedIds -join '|') -Actual (@($result.References | ForEach-Object { $_.ReferenceId }) -join '|') -Message "$sampleId reference IDs are not stable sequential IDs."

        $repeatDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-REFERENCE-{0}' -f $sampleId)
        $repeatXml = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery
        $repeat = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery -BackboneXmlInventoryResult $repeatXml
        Assert-eMASEqual -Expected (ConvertTo-eMASReferenceProjection -Result $result) -Actual (ConvertTo-eMASReferenceProjection -Result $repeat) -Message "$sampleId deterministic reference projection differs across repeat runs."

        $resultBySample[$sampleId] = $result
        $actualSummary = [pscustomobject][ordered]@{
            ReferenceCount = @($result.References).Count
            HrefCount = @($result.References | Where-Object { $null -ne $_.RawHref }).Count
            CommonReferenceCount = @($result.References | Where-Object { $_.XmlKind -eq 'CommonBackbone' }).Count
            RegionalReferenceCount = @($result.References | Where-Object { $_.XmlKind -eq 'RegionalBackbone' }).Count
            UnavailableCoverageCount = @($referenceCoverage | Where-Object { $_.CaptureStatus -ne 'Available' }).Count
        }
        Write-Output ('[PASS] {0} ReferenceInventory acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$primaryResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        ExpectedReferenceCount = $fixtureExpectation.referenceCount
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

# Every other executable fixture remains a bounded regression case.
foreach ($manifestRow in @($manifestRows | Where-Object { $_.VerificationStatus -eq 'PASS_FROZEN' -and $primaryIds -notcontains $_.SampleId })) {
    $sampleId = [string]$manifestRow.SampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.reference-inventory.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $referenceCount = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-REFERENCE-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $acceptedDomainBefore = ConvertTo-eMASAcceptedDomainProjection -Result $xmlResult
        $result = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult -OutputPath $resultPath
        Assert-eMASEqual -Expected $acceptedDomainBefore -Actual (ConvertTo-eMASAcceptedDomainProjection -Result $result) -Message "$sampleId altered accepted domain facts."
        Test-eMASReferenceBoundary -Result $result -SampleId $sampleId
        foreach ($reference in @($result.References)) {
            Assert-eMASTrue -Condition (@('CommonBackbone', 'RegionalBackbone') -contains $reference.XmlKind) -Message "$sampleId emitted an unsupported XML reference kind."
        }
        if ($sampleId -eq 'SD-011') {
            Assert-eMASEqual -Expected 0 -Actual @($result.References | Where-Object { $_.RawHref -like '*/0004.zip/*' }).Count -Message 'SD-011 nested ZIP was inspected for references.'
        }
        if ($sampleId -eq 'SD-020') {
            Assert-eMASEqual -Expected 0 -Actual @($result.References).Count -Message 'SD-020 produced forced reference records.'
            $repositoryCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceInventory' -and $_.SubjectType -eq 'Repository' })
            Assert-eMASEqual -Expected 1 -Actual $repositoryCoverage.Count -Message 'SD-020 omitted repository ReferenceInventory coverage.'
            Assert-eMASEqual -Expected 'Available' -Actual $repositoryCoverage[0].CaptureStatus -Message 'SD-020 zero-record ReferenceInventory coverage was not completed.'
            Assert-eMASEqual -Expected 0 -Actual $repositoryCoverage[0].RecordsProduced -Message 'SD-020 repository coverage count differs.'
        }
        $referenceCount = @($result.References).Count
        Write-Output ('[PASS] {0} bounded ReferenceInventory regression' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$regressionResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        ReferenceCount = $referenceCount
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'Baseline raw attributes and operation counts match independent evidence' -Action {
    $baselineResult = $resultBySample['SD-002']
    Assert-eMASEqual -Expected $expectations.baseline.modifiedFileCount -Actual @($baselineResult.References | Where-Object { $null -ne $_.ModifiedFileRawPath }).Count -Message 'Modified-file count differs.'
    foreach ($operationProperty in $expectations.baseline.operationCounts.PSObject.Properties) {
        Assert-eMASEqual -Expected $operationProperty.Value -Actual @($baselineResult.References | Where-Object { $_.Operation -eq $operationProperty.Name }).Count -Message "Operation count differs for $($operationProperty.Name)."
    }
    $xmlById = @{}
    foreach ($xml in @($baselineResult.XmlDocuments)) { $xmlById[[string]$xml.XmlId] = $xml }
    foreach ($expectedFact in @($expectations.baseline.rawLifecycleFacts)) {
        $matches = @($baselineResult.References | Where-Object {
            $xmlById[[string]$_.XmlId].RelativePath.EndsWith([string]$expectedFact.relativePathSuffix, [System.StringComparison]::Ordinal) -and
            $_.SourcePosition -eq $expectedFact.sourcePosition
        })
        Assert-eMASEqual -Expected 1 -Actual $matches.Count -Message "Lifecycle raw fact was not unique for $($expectedFact.relativePathSuffix) position $($expectedFact.sourcePosition)."
        foreach ($property in @('SourceElementId', 'Operation', 'ModifiedFileRawPath', 'RawHref')) {
            $expectationName = $property.Substring(0, 1).ToLowerInvariant() + $property.Substring(1)
            Assert-eMASEqual -Expected $expectedFact.$expectationName -Actual $matches[0].$property -Message "Raw lifecycle field $property differs."
        }
        if ($expectedFact.PSObject.Properties.Name -contains 'declaredChecksumAlgorithm') {
            Assert-eMASEqual -Expected $expectedFact.declaredChecksumAlgorithm -Actual $matches[0].DeclaredChecksumAlgorithm -Message 'Delete checksum algorithm raw value differs.'
            Assert-eMASEqual -Expected $expectedFact.declaredChecksum -Actual $matches[0].DeclaredChecksum -Message 'Delete checksum raw value differs.'
        }
    }
}

foreach ($pair in @($expectations.invariancePairs)) {
    Invoke-eMASRecordedCheck -Name ("Raw references invariant: {0} vs {1}" -f $pair.baseline, $pair.comparison) -Action {
        Assert-eMASEqual -Expected (ConvertTo-eMASReferenceProjection -Result $resultBySample[[string]$pair.baseline]) -Actual (ConvertTo-eMASReferenceProjection -Result $resultBySample[[string]$pair.comparison]) -Message "$($pair.comparison) raw XML reference inventory differs from $($pair.baseline)."
    }
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP raw reference observations are equivalent for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-reference-inventory-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $directoryDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-REFERENCE-SD-002-DIRECTORY'
        $directoryXml = Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery
        $directoryResult = Invoke-eMASReferenceInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -BackboneXmlInventoryResult $directoryXml
        Assert-eMASEqual -Expected (ConvertTo-eMASReferenceProjection -Result $resultBySample['SD-002']) -Actual (ConvertTo-eMASReferenceProjection -Result $directoryResult) -Message 'Directory raw-reference observations differ from ZIP.'
        $portableJson = ConvertTo-eMASReferenceProjection -Result $directoryResult
        Assert-eMASTrue -Condition ($portableJson -notlike "*$temporaryRoot*") -Message 'Temporary extraction path leaked into portable reference output.'

        $rejected = $false
        try {
            Invoke-eMASReferenceInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -BackboneXmlInventoryResult $directoryXml -OutputPath (Join-Path $directorySource 'reference-result.json') | Out-Null
        }
        catch { $rejected = $_.Exception.Message -like '*REF-OUTPUT-002*' }
        Assert-eMASTrue -Condition $rejected -Message 'Reference output inside directory SourcePath was not rejected.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'ReferenceInventory reuses the bounded safe XML helper' -Action {
    $xmlModuleText = [System.IO.File]::ReadAllText($xmlInventoryModulePath)
    $referenceModuleText = [System.IO.File]::ReadAllText($referenceInventoryModulePath)
    $safeXmlText = [System.IO.File]::ReadAllText($safeXmlHelperPath)
    Assert-eMASTrue -Condition ($xmlModuleText -match 'private/eMAS\.SafeXml\.ps1') -Message 'BackboneXmlInventory does not load the shared safe XML helper.'
    Assert-eMASTrue -Condition ($referenceModuleText -match 'private/eMAS\.SafeXml\.ps1') -Message 'ReferenceInventory does not load the shared safe XML helper.'
    Assert-eMASTrue -Condition ($safeXmlText -match '\$settings\.XmlResolver\s*=\s*\$null') -Message 'XmlReaderSettings.XmlResolver is not disabled.'
    Assert-eMASTrue -Condition ($safeXmlText -match '\$document\.XmlResolver\s*=\s*\$null') -Message 'XmlDocument.XmlResolver is not disabled.'
    Assert-eMASTrue -Condition ($safeXmlText -match 'MaxCharactersFromEntities\s*=\s*1024') -Message 'Entity expansion is not bounded.'
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes all three accepted capabilities' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-002-entrypoint.reference-inventory.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-002'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-REFERENCE-ENTRYPOINT' `
        -IncludeReferenceInventory
    Assert-eMASEqual -Expected $expectations.baseline.referenceCount -Actual @($entryResult.References).Count -Message 'Entry-point reference count differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
}

# Post-test freeze gate compares both hash and timestamp for every executable frozen ZIP.
foreach ($sampleId in @($sourceState.Keys)) {
    $state = $sourceState[$sampleId]
    if ((Get-eMASTestSha256 -Path $state.Path) -ne $state.Hash) { throw ('FREEZE-VERIFY-003 Frozen fixture changed during testing: {0}' -f $sampleId) }
    if ((New-Object System.IO.FileInfo($state.Path)).LastWriteTimeUtc -ne $state.LastWriteTimeUtc) { throw ('FREEZE-VERIFY-004 Frozen fixture timestamp changed during testing: {0}' -f $sampleId) }
    $frozenAfterVerified++
}
Write-Output ('[PASS] Post-test freeze gate verified {0} ZIP fixtures.' -f $frozenAfterVerified)

$primaryFailureCount = @($primaryResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$regressionFailureCount = @($regressionResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$additionalFailureCount = @($additionalResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$overallStatus = $(if (($primaryFailureCount + $regressionFailureCount + $additionalFailureCount) -eq 0) { 'PASS' } else { 'FAIL' })
$summary = [pscustomobject][ordered]@{
    ContractId = $expectations.contractId
    Capability = 'ReferenceInventory'
    StartedAtUtc = $startedAtUtc.ToString('o')
    CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    OverallStatus = $overallStatus
    FrozenFixtureCountVerifiedBefore = $frozenBeforeVerified
    FrozenFixtureCountVerifiedAfter = $frozenAfterVerified
    PrimaryFixtureCount = $primaryResults.Count
    PrimaryFixturePassCount = @($primaryResults | Where-Object { $_.Status -eq 'PASS' }).Count
    PrimaryFixtureFailCount = $primaryFailureCount
    RegressionFixtureCount = $regressionResults.Count
    RegressionFixturePassCount = @($regressionResults | Where-Object { $_.Status -eq 'PASS' }).Count
    RegressionFixtureFailCount = $regressionFailureCount
    AdditionalCheckCount = $additionalResults.Count
    AdditionalCheckPassCount = @($additionalResults | Where-Object { $_.Status -eq 'PASS' }).Count
    AdditionalCheckFailCount = $additionalFailureCount
    BaselineReferenceCount = $expectations.baseline.referenceCount
    BaselineHrefCount = $expectations.baseline.hrefCount
    BaselineCommonReferenceCount = $expectations.baseline.commonReferenceCount
    BaselineRegionalReferenceCount = $expectations.baseline.regionalReferenceCount
    PrimaryFixtureResults = [object[]]@($primaryResults)
    RegressionFixtureResults = [object[]]@($regressionResults)
    AdditionalChecks = [object[]]@($additionalResults)
}
$summaryPath = Join-Path $resolvedOutputRoot 'reference-inventory-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('ReferenceInventory tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
