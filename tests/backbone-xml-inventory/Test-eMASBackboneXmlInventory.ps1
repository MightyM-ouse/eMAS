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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/backbone-xml-inventory/wave1-expectations.json'
}
$repositoryDiscoveryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$xmlInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$safeXmlHelperPath = Join-Path $repositoryRoot 'engine/powershell51/private/eMAS.SafeXml.ps1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
Import-Module -Name $repositoryDiscoveryModulePath -Force -ErrorAction Stop
Import-Module -Name $xmlInventoryModulePath -Force -ErrorAction Stop

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

function ConvertTo-eMASXmlDeterministicProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([pscustomobject][ordered]@{
        Repository = $Result.Repository
        DossierCandidates = [object[]]@($Result.DossierCandidates)
        Sequences = [object[]]@($Result.Sequences)
        XmlDocuments = [object[]]@($Result.XmlDocuments)
        References = [object[]]@($Result.References)
        Files = [object[]]@($Result.Files)
        LifecycleRelationships = [object[]]@($Result.LifecycleRelationships)
        Observations = [object[]]@($Result.Observations)
        ClassificationEvidence = [object[]]@($Result.ClassificationEvidence)
        CollectionCoverage = [object[]]@($Result.CollectionCoverage)
    } | ConvertTo-Json -Depth 64 -Compress)
}

function ConvertTo-eMASXmlDocumentProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ([object[]]@($Result.XmlDocuments) | ConvertTo-Json -Depth 32 -Compress)
}

function Copy-eMASExpectedDocument {
    param(
        [Parameter(Mandatory = $true)][object] $Profile,
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [Parameter(Mandatory = $true)][string] $Sequence,
        [Parameter(Mandatory = $true)][string] $DeclaredVersion
    )

    return [pscustomobject][ordered]@{
        RelativePath = $RelativePath
        Sequence = $Sequence
        XmlKind = $Profile.xmlKind
        Exists = $Profile.exists
        ParseStatus = $Profile.parseStatus
        CaptureStatus = $Profile.captureStatus
        RootElement = $Profile.rootElement
        NamespaceUri = $Profile.namespaceUri
        DeclaredVersion = $DeclaredVersion
        DocumentTypeName = $Profile.documentTypeName
        PublicId = $Profile.publicId
        SystemId = $Profile.systemId
        DeclaredEncoding = $Profile.declaredEncoding
        ParseErrorCode = $null
    }
}

function Get-eMASExpectedDocuments {
    param([Parameter(Mandatory = $true)][object] $FixtureExpectation)

    $profile = $expectations.baselineProfile
    $expectedByPath = @{}
    foreach ($sequence in @($profile.sequences)) {
        $commonPath = $profile.common.relativePathTemplate.Replace('{root}', $profile.candidateRootPath).Replace('{sequence}', $sequence)
        $regionalPath = $profile.regional.relativePathTemplate.Replace('{root}', $profile.candidateRootPath).Replace('{sequence}', $sequence)
        $expectedByPath[$commonPath] = Copy-eMASExpectedDocument -Profile $profile.common -RelativePath $commonPath -Sequence $sequence -DeclaredVersion $profile.common.declaredVersion
        $regionalVersion = $profile.regional.declaredVersionBySequence.$sequence
        $expectedByPath[$regionalPath] = Copy-eMASExpectedDocument -Profile $profile.regional -RelativePath $regionalPath -Sequence $sequence -DeclaredVersion $regionalVersion
    }
    foreach ($override in @($FixtureExpectation.overrides)) {
        $target = $expectedByPath[[string]$override.relativePath]
        Assert-eMASTrue -Condition ($null -ne $target) -Message ('Expectation override targets an unknown XML path: {0}' -f $override.relativePath)
        foreach ($property in $override.PSObject.Properties) {
            if ($property.Name -eq 'relativePath') { continue }
            $target.($property.Name.Substring(0, 1).ToUpperInvariant() + $property.Name.Substring(1)) = $property.Value
        }
    }
    foreach ($additional in @($FixtureExpectation.additionalDocuments)) {
        $expectedByPath[[string]$additional.relativePath] = [pscustomobject][ordered]@{
            RelativePath = $additional.relativePath
            Sequence = $additional.sequence
            XmlKind = $additional.xmlKind
            Exists = $additional.exists
            ParseStatus = $additional.parseStatus
            CaptureStatus = $additional.captureStatus
            RootElement = $additional.rootElement
            NamespaceUri = $additional.namespaceUri
            DeclaredVersion = $additional.declaredVersion
            DocumentTypeName = $additional.documentTypeName
            PublicId = $additional.publicId
            SystemId = $additional.systemId
            DeclaredEncoding = $additional.declaredEncoding
            ParseErrorCode = $null
        }
    }
    return @($expectedByPath.Values | Sort-Object RelativePath)
}

function Test-eMASNoProhibitedOutput {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $SampleId)

    $json = $Result | ConvertTo-Json -Depth 64 -Compress
    foreach ($property in @($expectations.mustNotReportProperties)) {
        Assert-eMASTrue -Condition ($json -notmatch ('"{0}"\s*:' -f [regex]::Escape($property))) -Message "$SampleId emitted prohibited property $property."
    }
    foreach ($collectionName in @($expectations.mustRemainEmptyCollections)) {
        Assert-eMASEqual -Expected 0 -Actual @($Result.$collectionName).Count -Message "$SampleId unexpectedly populated $collectionName."
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
    $resultFileName = '{0}.backbone-xml-inventory.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-BACKBONE-XML-{0}' -f $sampleId)
        $discoveryProjection = [pscustomobject][ordered]@{
            Repository = $discovery.Repository
            DossierCandidates = [object[]]@($discovery.DossierCandidates)
            Sequences = [object[]]@($discovery.Sequences)
            Files = [object[]]@($discovery.Files)
        } | ConvertTo-Json -Depth 64 -Compress
        $result = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedDocumentCount -Actual @($result.XmlDocuments).Count -Message "$sampleId XML document count differs."
        Test-eMASNoProhibitedOutput -Result $result -SampleId $sampleId
        Assert-eMASEqual -Expected $discoveryProjection -Actual ([pscustomobject][ordered]@{
            Repository = $result.Repository
            DossierCandidates = [object[]]@($result.DossierCandidates)
            Sequences = [object[]]@($result.Sequences)
            Files = [object[]]@($result.Files)
        } | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId altered RepositoryDiscovery domain facts."

        $actualByPath = @{}
        foreach ($document in @($result.XmlDocuments)) {
            Assert-eMASTrue -Condition (-not $actualByPath.ContainsKey([string]$document.RelativePath)) -Message "$sampleId emitted duplicate XML path $($document.RelativePath)."
            $actualByPath[[string]$document.RelativePath] = $document
            Assert-eMASEqual -Expected 'PhysicalPathAndName' -Actual $document.RoleBasis -Message "$sampleId role basis differs for $($document.RelativePath)."
        }

        foreach ($expectedDocument in @(Get-eMASExpectedDocuments -FixtureExpectation $fixtureExpectation)) {
            Assert-eMASTrue -Condition $actualByPath.ContainsKey([string]$expectedDocument.RelativePath) -Message "$sampleId omitted XML path $($expectedDocument.RelativePath)."
            $actual = $actualByPath[[string]$expectedDocument.RelativePath]
            foreach ($property in @('XmlKind', 'Exists', 'ParseStatus', 'CaptureStatus', 'RootElement', 'NamespaceUri', 'DeclaredVersion', 'DocumentTypeName', 'PublicId', 'SystemId', 'DeclaredEncoding', 'ParseErrorCode')) {
                Assert-eMASEqual -Expected $expectedDocument.$property -Actual $actual.$property -Message "$sampleId $property differs for $($expectedDocument.RelativePath)."
            }
            if ($null -ne $expectedDocument.Sequence) {
                Assert-eMASTrue -Condition ($actual.SequencePath -like ('*/{0}' -f $expectedDocument.Sequence)) -Message "$sampleId sequence relationship differs for $($expectedDocument.RelativePath)."
            }
            else {
                Assert-eMASEqual -Expected $null -Actual $actual.SequenceId -Message "$sampleId root XML was assigned to a sequence."
            }
            if ($actual.ParseStatus -eq 'Parsed' -and $null -ne $actual.DeclaredVersion) {
                $versionAttribute = @($actual.RootAttributes | Where-Object { $_.Name -eq 'dtd-version' })
                Assert-eMASEqual -Expected 1 -Actual $versionAttribute.Count -Message "$sampleId dtd-version root attribute count differs."
                Assert-eMASEqual -Expected $actual.DeclaredVersion -Actual $versionAttribute[0].Value -Message "$sampleId dtd-version root attribute differs."
            }
            if ($actual.ParseStatus -eq 'ParseFailed') {
                Assert-eMASTrue -Condition (-not [string]::IsNullOrWhiteSpace($actual.Diagnostic)) -Message "$sampleId parse failure omitted its bounded diagnostic."
                Assert-eMASTrue -Condition ($actual.Diagnostic -notlike "*$resolvedCorpusRoot*") -Message "$sampleId diagnostic exposed an absolute corpus path."
            }
        }

        if ($sampleId -eq 'SD-005') {
            Assert-eMASEqual -Expected 1 -Actual @($result.Observations | Where-Object { $_.Code -eq 'MissingCommonBackbone' }).Count -Message 'SD-005 missing common observation count differs.'
        }
        if ($sampleId -eq 'SD-006') {
            Assert-eMASEqual -Expected 1 -Actual @($result.Observations | Where-Object { $_.Code -eq 'MissingRegionalBackbone' }).Count -Message 'SD-006 missing regional observation count differs.'
        }
        if ($sampleId -eq 'SD-007') {
            Assert-eMASEqual -Expected 'ParseFailed' -Actual @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'CommonXmlParse' })[0].CaptureStatus -Message 'SD-007 common XML coverage differs.'
        }
        if ($sampleId -eq 'SD-008') {
            Assert-eMASEqual -Expected 'ParseFailed' -Actual @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'RegionalXmlParse' })[0].CaptureStatus -Message 'SD-008 regional XML coverage differs.'
        }

        $repeatDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-BACKBONE-XML-{0}' -f $sampleId)
        $repeat = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery
        Assert-eMASEqual -Expected (ConvertTo-eMASXmlDeterministicProjection -Result $result) -Actual (ConvertTo-eMASXmlDeterministicProjection -Result $repeat) -Message "$sampleId deterministic projection differs across repeat runs."

        $resultBySample[$sampleId] = $result
        $actualSummary = [pscustomobject][ordered]@{
            XmlDocumentCount = @($result.XmlDocuments).Count
            ParsedCount = @($result.XmlDocuments | Where-Object { $_.ParseStatus -eq 'Parsed' }).Count
            MissingCount = @($result.XmlDocuments | Where-Object { $_.ParseStatus -eq 'Missing' }).Count
            ParseFailedCount = @($result.XmlDocuments | Where-Object { $_.ParseStatus -eq 'ParseFailed' }).Count
        }
        Write-Output ('[PASS] {0} Backbone XML acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$primaryResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        ExpectedDocumentCount = $fixtureExpectation.expectedDocumentCount
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

# Run all other executable Wave 1 fixtures as bounded regressions without asserting later capabilities.
foreach ($manifestRow in @($manifestRows | Where-Object { $_.VerificationStatus -eq 'PASS_FROZEN' -and $primaryIds -notcontains $_.SampleId })) {
    $sampleId = [string]$manifestRow.SampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.backbone-xml-inventory.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $xmlDocumentCount = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-BACKBONE-XML-{0}' -f $sampleId)
        $result = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -OutputPath $resultPath
        Test-eMASNoProhibitedOutput -Result $result -SampleId $sampleId
        foreach ($document in @($result.XmlDocuments)) {
            Assert-eMASTrue -Condition (-not $document.RelativePath.StartsWith('/')) -Message "$sampleId emitted an absolute XML path."
        }
        if ($sampleId -eq 'SD-011') {
            Assert-eMASEqual -Expected 0 -Actual @($result.XmlDocuments | Where-Object { $_.RelativePath -like '*/0004.zip/*' }).Count -Message 'SD-011 nested sequence ZIP was inspected.'
        }
        if ($sampleId -eq 'SD-020') {
            Assert-eMASEqual -Expected 0 -Actual @($result.XmlDocuments).Count -Message 'SD-020 produced forced backbone records.'
        }
        $xmlDocumentCount = @($result.XmlDocuments).Count
        Write-Output ('[PASS] {0} bounded XML regression' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$regressionResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        XmlDocumentCount = $xmlDocumentCount
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP XML observations are equivalent and deterministic for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-backbone-xml-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $directoryResultPath = Join-Path $resultRoot 'SD-002-directory.backbone-xml-inventory.json'
        $directoryDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-BACKBONE-XML-SD-002-DIRECTORY'
        $directoryResult = Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -OutputPath $directoryResultPath
        Assert-eMASEqual -Expected (ConvertTo-eMASXmlDocumentProjection -Result $resultBySample['SD-002']) -Actual (ConvertTo-eMASXmlDocumentProjection -Result $directoryResult) -Message 'Directory XML observations differ from ZIP.'

        $directoryRepeatDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-BACKBONE-XML-SD-002-DIRECTORY'
        $directoryRepeat = Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryRepeatDiscovery
        Assert-eMASEqual -Expected (ConvertTo-eMASXmlDeterministicProjection -Result $directoryResult) -Actual (ConvertTo-eMASXmlDeterministicProjection -Result $directoryRepeat) -Message 'Directory deterministic projection differs.'

        $rejected = $false
        try {
            Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -OutputPath (Join-Path $directorySource 'xml-result.json') | Out-Null
        }
        catch { $rejected = $_.Exception.Message -like '*XML-OUTPUT-002*' }
        Assert-eMASTrue -Condition $rejected -Message 'XML output inside directory SourcePath was not rejected.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'SD-002 extracts supported EU envelope profiles during the existing BXI parse' -Action {
    $result = $resultBySample['SD-002']
    Assert-eMASEqual -Expected '0.3.0' -Actual $result.Execution.ScannerVersion -Message 'BXI scanner version differs.'
    $regional = @($result.XmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' })
    Assert-eMASEqual -Expected 5 -Actual $regional.Count -Message 'Regional XML document count differs.'
    Assert-eMASEqual -Expected '2.0|3.0.1|3.0.1|3.0.1|3.1' -Actual (@($regional | ForEach-Object { $_.RegionalEnvelope.ProfileVersion }) -join '|') -Message 'EU profile sequence differs.'
    Assert-eMASEqual -Expected 0 -Actual @($regional | Where-Object { $_.RegionalEnvelope.ProfileStatus -ne 'Supported' }).Count -Message 'A supported corpus profile was not recognized.'
    Assert-eMASEqual -Expected '1|1|3|3|2' -Actual (@($regional | ForEach-Object { $_.RegionalEnvelope.EnvelopeCount }) -join '|') -Message 'Envelope counts differ.'
    foreach ($document in $regional) {
        foreach ($envelope in @($document.RegionalEnvelope.Envelopes)) {
            Assert-eMASEqual -Expected 5 -Actual @($envelope.Fields).Count -Message 'Envelope field count differs.'
        }
    }
    $profile20Unit = @($regional[0].RegionalEnvelope.Envelopes[0].Fields | Where-Object { $_.FieldCode -eq 'EU_SUBMISSION_UNIT_TYPE' })[0]
    Assert-eMASEqual -Expected 'NotDefinedInProfile' -Actual $profile20Unit.ValueStatus -Message 'EU 2.0 submission-unit status differs.'
}

Invoke-eMASRecordedCheck -Name 'BXI preserves lifecycle envelope changes and new property remains regional-only' -Action {
    $result = $resultBySample['SD-002']
    $regional = @($result.XmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' })
    $procedureValues = @($regional | ForEach-Object { $_.RegionalEnvelope.Envelopes[0].Fields | Where-Object { $_.FieldCode -eq 'EU_PROCEDURE_TYPE' } | ForEach-Object { $_.Value } })
    Assert-eMASEqual -Expected 'national|national|mutual-recognition|mutual-recognition|mutual-recognition' -Actual ($procedureValues -join '|') -Message 'Procedure values were normalized or collapsed across lifecycle units.'
    $common = @($result.XmlDocuments | Where-Object { $_.XmlKind -eq 'CommonBackbone' })
    Assert-eMASEqual -Expected 0 -Actual @($common | Where-Object { $null -ne $_.RegionalEnvelope }).Count -Message 'Common backbone gained regional-envelope content.'
    $missing = @($resultBySample['SD-006'].XmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' -and -not $_.Exists })[0]
    Assert-eMASEqual -Expected $null -Actual $missing.RegionalEnvelope -Message 'Missing regional XML manufactured envelope content.'
    $malformed = @($resultBySample['SD-008'].XmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' -and $_.ParseStatus -eq 'ParseFailed' })[0]
    Assert-eMASEqual -Expected 'NotAttempted' -Actual $malformed.RegionalEnvelope.ProfileStatus -Message 'Malformed regional XML profile status differs.'
}

Invoke-eMASRecordedCheck -Name 'External XML entity and resource resolution is disabled' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-xml-safety-{0}' -f [guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $temporaryRoot 'source'
    $sequenceRoot = Join-Path $sourceRoot 'SyntheticDossier/0000'
    try {
        [void][System.IO.Directory]::CreateDirectory($sequenceRoot)
        $secretPath = Join-Path $temporaryRoot 'must-not-be-read.txt'
        [System.IO.File]::WriteAllText($secretPath, 'EMAS_XXE_SENTINEL_DO_NOT_DISCLOSE')
        $secretUri = (New-Object System.Uri($secretPath)).AbsoluteUri
        $maliciousXml = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE ectd:ectd [<!ENTITY xxe SYSTEM="' + $secretUri + '">]><ectd:ectd xmlns:ectd="http://www.ich.org/ectd" dtd-version="3.2">&xxe;</ectd:ectd>'
        [System.IO.File]::WriteAllText((Join-Path $sequenceRoot 'index.xml'), $maliciousXml, (New-Object System.Text.UTF8Encoding($false)))

        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $sourceRoot -ExecutionId 'EXEC-XML-SAFETY'
        $result = Invoke-eMASBackboneXmlInventory -SourcePath $sourceRoot -RepositoryDiscoveryResult $discovery
        $document = @($result.XmlDocuments | Where-Object { $_.XmlKind -eq 'CommonBackbone' })[0]
        Assert-eMASEqual -Expected 'ParseFailed' -Actual $document.ParseStatus -Message 'External entity was not blocked as an unresolvable XML resource.'
        $serialized = $result | ConvertTo-Json -Depth 64 -Compress
        Assert-eMASTrue -Condition ($serialized -notlike '*EMAS_XXE_SENTINEL_DO_NOT_DISCLOSE*') -Message 'External entity content leaked into the result.'
        Assert-eMASTrue -Condition ($serialized -notlike "*$secretPath*") -Message 'External entity path leaked into the result.'

        $safeXmlText = [System.IO.File]::ReadAllText($safeXmlHelperPath)
        Assert-eMASTrue -Condition ($safeXmlText -match '\$settings\.XmlResolver\s*=\s*\$null') -Message 'XmlReaderSettings.XmlResolver is not explicitly disabled.'
        Assert-eMASTrue -Condition ($safeXmlText -match '\$document\.XmlResolver\s*=\s*\$null') -Message 'XmlDocument.XmlResolver is not explicitly disabled.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes RepositoryDiscovery with BackboneXmlInventory' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-002-entrypoint.backbone-xml-inventory.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-002'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-BACKBONE-XML-ENTRYPOINT' `
        -IncludeBackboneXmlInventory
    Assert-eMASEqual -Expected 10 -Actual @($entryResult.XmlDocuments).Count -Message 'Entry-point XML count differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
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
    Capability = 'BackboneXmlInventory'
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
    AdditionalCheckFailCount = $additionalFailureCount
    PrimaryFixtureResults = [object[]]@($primaryResults)
    RegressionFixtureResults = [object[]]@($regressionResults)
    AdditionalChecks = [object[]]@($additionalResults)
}
$summaryPath = Join-Path $resolvedOutputRoot 'backbone-xml-inventory-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('BackboneXmlInventory tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
