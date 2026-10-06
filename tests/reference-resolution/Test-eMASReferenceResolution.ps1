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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/reference-resolution/wave1-expectations.json'
}
$repositoryDiscoveryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$xmlInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$referenceInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1'
$referenceResolutionModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceResolution.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
Import-Module -Name $repositoryDiscoveryModulePath -Force -ErrorAction Stop
Import-Module -Name $xmlInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceResolutionModulePath -Force -ErrorAction Stop

$resolvedCorpusRoot = [System.IO.Path]::GetFullPath($CorpusRoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$resultRoot = Join-Path $resolvedOutputRoot 'results'
[void][System.IO.Directory]::CreateDirectory($resultRoot)

$startedAtUtc = [DateTime]::UtcNow
$manifestRows = @(Import-Csv -LiteralPath $FreezeManifestPath)
$expectations = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($ExpectationsPath)) | ConvertFrom-Json
$sourceState = @{}
$fixtureResults = New-Object System.Collections.ArrayList
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

function ConvertTo-eMASRawReferenceProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([object[]]@($Result.References | ForEach-Object {
        [pscustomobject][ordered]@{
            ReferenceId = $_.ReferenceId
            XmlId = $_.XmlId
            DossierId = $_.DossierId
            SequenceId = $_.SequenceId
            XmlKind = $_.XmlKind
            SourceElement = $_.SourceElement
            SourceElementNamespaceUri = $_.SourceElementNamespaceUri
            SourcePosition = $_.SourcePosition
            SourceElementId = $_.SourceElementId
            RawHref = $_.RawHref
            DeclaredChecksumAlgorithm = $_.DeclaredChecksumAlgorithm
            DeclaredChecksum = $_.DeclaredChecksum
            Operation = $_.Operation
            ModifiedFileRawPath = $_.ModifiedFileRawPath
        }
    }) | ConvertTo-Json -Depth 32 -Compress)
}

function ConvertTo-eMASResolutionProjection {
    param([Parameter(Mandatory = $true)][object] $Result, [switch] $ExcludeTargetFileId)

    return ([object[]]@($Result.References | ForEach-Object {
        [pscustomobject][ordered]@{
            ReferenceId = $_.ReferenceId
            RawHref = $_.RawHref
            NormalizedTargetPath = $_.NormalizedTargetPath
            TargetFileId = $(if ($ExcludeTargetFileId) { $null } else { $_.TargetFileId })
            TargetExists = $_.TargetExists
            ResolutionStatus = $_.ResolutionStatus
            ResolutionDiagnosticCode = $_.ResolutionDiagnosticCode
            CaptureStatus = $_.CaptureStatus
        }
    }) | ConvertTo-Json -Depth 32 -Compress)
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

function New-eMASSyntheticInputs {
    param(
        [Parameter(Mandatory = $true)][object[]] $RawReferences,
        [AllowEmptyCollection()][object[]] $Files = @()
    )

    $references = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $RawReferences.Count; $index++) {
        [void]$references.Add([pscustomobject][ordered]@{
            ReferenceId = 'REF-{0:D4}' -f ($index + 1)
            XmlId = 'XML-0001'
            DossierId = 'DOS-0001'
            SequenceId = 'SEQ-0001'
            XmlKind = 'CommonBackbone'
            SourceElement = 'leaf'
            SourceElementNamespaceUri = ''
            SourcePosition = $index + 1
            SourceElementId = 'SYN-{0:D4}' -f ($index + 1)
            RawHref = $RawReferences[$index]
            NormalizedTargetPath = $null
            TargetFileId = $null
            TargetExists = $null
            DeclaredChecksumAlgorithm = $null
            DeclaredChecksum = $null
            CalculatedChecksum = $null
            ChecksumMatch = $null
            Operation = 'new'
            ModifiedFileRawPath = $null
            CaptureStatus = 'Available'
        })
    }
    $execution = [pscustomobject][ordered]@{
        Phase = 'PreSales'
        ScenarioId = 'MS-04'
        ExecutionId = 'EXEC-SYNTHETIC-RESOLUTION'
        ScannerName = 'SyntheticReferenceInventory'
        ScannerVersion = '0.3.0'
        CompletedAtUtc = $null
        CompletionStatus = 'Completed'
        Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory')
    }
    $repository = [pscustomobject][ordered]@{
        RepositoryId = 'REP-0001'
        SourcePath = 'source'
        SourceKind = 'Directory'
        SourceSha256 = $null
        InventoryCaptureStatus = 'Available'
        Errors = [object[]]@()
    }
    $coverage = [object[]]@(
        [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceInventoryScope' },
        [pscustomobject][ordered]@{ CheckId = 'DeclaredChecksumComparison'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceInventoryScope' },
        [pscustomobject][ordered]@{ CheckId = 'LifecycleLinkResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceInventoryScope' },
        [pscustomobject][ordered]@{ CheckId = 'FileReferenceOrphanCorrelation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceInventoryScope' }
    )
    $common = [ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = $execution
        Repository = $repository
        DossierCandidates = [object[]]@([pscustomobject][ordered]@{ DossierId = 'DOS-0001'; RelativePath = 'Synthetic' })
        Sequences = [object[]]@([pscustomobject][ordered]@{ SequenceId = 'SEQ-0001'; DossierId = 'DOS-0001'; RelativePath = 'Synthetic/0000' })
        XmlDocuments = [object[]]@([pscustomobject][ordered]@{ XmlId = 'XML-0001'; DossierId = 'DOS-0001'; SequenceId = 'SEQ-0001'; RelativePath = 'Synthetic/0000/index.xml'; XmlKind = 'CommonBackbone' })
        References = [object[]]@($references)
        Files = [object[]]@($Files)
        LifecycleRelationships = [object[]]@()
        Observations = [object[]]@()
        ClassificationEvidence = [object[]]@()
        CollectionCoverage = $coverage
    }
    $inventory = [pscustomobject]$common
    $discovery = ($inventory | ConvertTo-Json -Depth 32) | ConvertFrom-Json
    $discovery.Execution.Capabilities = [object[]]@('RepositoryDiscovery')
    return [pscustomobject][ordered]@{ Discovery = $discovery; Inventory = $inventory }
}

# Freeze gate before any scanner invocation.
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

foreach ($fixtureExpectation in @($expectations.fixtures)) {
    $sampleId = [string]$fixtureExpectation.sampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.reference-resolution.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-RESOLUTION-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $inventory = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
        $acceptedDomainBefore = ConvertTo-eMASAcceptedDomainProjection -Result $inventory
        $rawReferencesBefore = ConvertTo-eMASRawReferenceProjection -Result $inventory
        $result = Invoke-eMASReferenceResolution -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $acceptedDomainBefore -Actual (ConvertTo-eMASAcceptedDomainProjection -Result $result) -Message "$sampleId altered accepted repository/XML/file domain facts."
        Assert-eMASEqual -Expected $rawReferencesBefore -Actual (ConvertTo-eMASRawReferenceProjection -Result $result) -Message "$sampleId altered raw reference facts or IDs."
        Assert-eMASEqual -Expected $fixtureExpectation.referenceCount -Actual @($result.References).Count -Message "$sampleId reference count differs."

        $present = @($result.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedPresent' })
        $absent = @($result.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedAbsent' })
        $notApplicable = @($result.References | Where-Object { $_.ResolutionStatus -eq 'NotApplicable' })
        $unresolved = @($result.References | Where-Object { @('ResolvedPresent', 'ResolvedAbsent', 'NotApplicable') -notcontains $_.ResolutionStatus })
        Assert-eMASEqual -Expected $fixtureExpectation.resolvedPresentCount -Actual $present.Count -Message "$sampleId resolved-present count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.resolvedAbsentCount -Actual $absent.Count -Message "$sampleId resolved-absent count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.notApplicableCount -Actual $notApplicable.Count -Message "$sampleId not-applicable count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.unresolvedCount -Actual $unresolved.Count -Message "$sampleId unresolved count differs."

        foreach ($reference in $present) {
            Assert-eMASEqual -Expected $true -Actual $reference.TargetExists -Message "$sampleId present target boolean differs."
            Assert-eMASTrue -Condition (-not [string]::IsNullOrWhiteSpace([string]$reference.NormalizedTargetPath)) -Message "$sampleId present target omitted normalized path."
            Assert-eMASTrue -Condition (-not [string]::IsNullOrWhiteSpace([string]$reference.TargetFileId)) -Message "$sampleId present target omitted existing FileId."
            Assert-eMASEqual -Expected 'Available' -Actual $reference.CaptureStatus -Message "$sampleId present target capture status differs."
        }
        foreach ($reference in $absent) {
            Assert-eMASEqual -Expected $false -Actual $reference.TargetExists -Message "$sampleId absent target boolean differs."
            Assert-eMASTrue -Condition (-not [string]::IsNullOrWhiteSpace([string]$reference.NormalizedTargetPath)) -Message "$sampleId absent target omitted normalized path."
            Assert-eMASEqual -Expected $null -Actual $reference.TargetFileId -Message "$sampleId absent target received a FileId."
            Assert-eMASEqual -Expected 'Available' -Actual $reference.CaptureStatus -Message "$sampleId absent target capture status differs."
        }
        foreach ($reference in $notApplicable) {
            Assert-eMASEqual -Expected $null -Actual $reference.NormalizedTargetPath -Message "$sampleId not-applicable reference received a target path."
            Assert-eMASEqual -Expected $null -Actual $reference.TargetExists -Message "$sampleId not-applicable reference became absent."
            Assert-eMASEqual -Expected 'NotApplicable' -Actual $reference.CaptureStatus -Message "$sampleId not-applicable capture status differs."
        }
        foreach ($reference in @($result.References)) {
            foreach ($field in @($expectations.mustRemainNullReferenceFields)) {
                Assert-eMASEqual -Expected $null -Actual $reference.$field -Message "$sampleId populated deferred field $field."
            }
            if ($null -ne $reference.NormalizedTargetPath) {
                Assert-eMASTrue -Condition (-not ([string]$reference.NormalizedTargetPath).StartsWith('/')) -Message "$sampleId exposed an absolute normalized target."
                Assert-eMASTrue -Condition (@(([string]$reference.NormalizedTargetPath) -split '/') -notcontains '..') -Message "$sampleId retained parent traversal in normalized target."
                Assert-eMASTrue -Condition (([string]$reference.NormalizedTargetPath) -notlike "*$($state.Path)*") -Message "$sampleId exposed a source path."
            }
        }

        Assert-eMASEqual -Expected 0 -Actual @($result.LifecycleRelationships).Count -Message "$sampleId populated lifecycle relationships."
        Assert-eMASEqual -Expected 0 -Actual @($result.ClassificationEvidence).Count -Message "$sampleId populated classification evidence."
        foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
            $futureCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
            Assert-eMASEqual -Expected 1 -Actual $futureCoverage.Count -Message "$sampleId future coverage count differs for $checkId."
            Assert-eMASEqual -Expected 'NotCollected' -Actual $futureCoverage[0].CaptureStatus -Message "$sampleId completed future capability $checkId."
        }
        foreach ($code in @($expectations.prohibitedObservationCodes)) {
            Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq $code }).Count -Message "$sampleId emitted prohibited observation $code."
        }

        $perReferenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceResolution' -and $_.SubjectType -eq 'Reference' })
        $repositoryCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceResolution' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected $fixtureExpectation.referenceCount -Actual $perReferenceCoverage.Count -Message "$sampleId per-reference coverage count differs."
        Assert-eMASEqual -Expected 1 -Actual $repositoryCoverage.Count -Message "$sampleId repository resolution coverage count differs."
        Assert-eMASEqual -Expected 'Available' -Actual $repositoryCoverage[0].CaptureStatus -Message "$sampleId repository resolution coverage differs."
        Assert-eMASEqual -Expected $fixtureExpectation.referenceCount -Actual $repositoryCoverage[0].RecordsProduced -Message "$sampleId repository resolution coverage total differs."

        $absentExpectations = @($expectations.expectedAbsentTargets | Where-Object { $_.sampleId -eq $sampleId })
        Assert-eMASEqual -Expected $absentExpectations.Count -Actual $absent.Count -Message "$sampleId absent expectation count differs."
        foreach ($expectedAbsent in $absentExpectations) {
            $match = @($absent | Where-Object { $_.ReferenceId -eq $expectedAbsent.referenceId })
            Assert-eMASEqual -Expected 1 -Actual $match.Count -Message "$sampleId omitted expected absent reference $($expectedAbsent.referenceId)."
            Assert-eMASEqual -Expected $expectedAbsent.rawHref -Actual $match[0].RawHref -Message "$sampleId absent raw href differs."
            Assert-eMASEqual -Expected $expectedAbsent.normalizedTargetPath -Actual $match[0].NormalizedTargetPath -Message "$sampleId absent normalized path differs."
        }

        $repeatDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-RESOLUTION-{0}' -f $sampleId)
        $repeatXml = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery
        $repeatInventory = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery -BackboneXmlInventoryResult $repeatXml
        $repeat = Invoke-eMASReferenceResolution -SourcePath $state.Path -RepositoryDiscoveryResult $repeatDiscovery -ReferenceInventoryResult $repeatInventory
        Assert-eMASEqual -Expected (ConvertTo-eMASResolutionProjection -Result $result) -Actual (ConvertTo-eMASResolutionProjection -Result $repeat) -Message "$sampleId deterministic resolution projection differs."

        $resultBySample[$sampleId] = $result
        $actualSummary = [pscustomobject][ordered]@{
            ReferenceCount = @($result.References).Count
            ResolvedPresentCount = $present.Count
            ResolvedAbsentCount = $absent.Count
            NotApplicableCount = $notApplicable.Count
            UnresolvedCount = $unresolved.Count
        }
        Write-Output ('[PASS] {0} ReferenceResolution acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = [pscustomobject][ordered]@{
            ReferenceCount = $fixtureExpectation.referenceCount
            ResolvedPresentCount = $fixtureExpectation.resolvedPresentCount
            ResolvedAbsentCount = $fixtureExpectation.resolvedAbsentCount
            NotApplicableCount = $fixtureExpectation.notApplicableCount
            UnresolvedCount = $fixtureExpectation.unresolvedCount
        }
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'Baseline common and regional normalization matches independent evidence' -Action {
    $baselineResult = $resultBySample['SD-002']
    $xmlById = @{}
    foreach ($xml in @($baselineResult.XmlDocuments)) { $xmlById[[string]$xml.XmlId] = $xml }
    foreach ($expected in @($expectations.baselineRepresentativeTargets)) {
        $matches = @($baselineResult.References | Where-Object {
            $_.RawHref -eq $expected.rawHref -and $xmlById[[string]$_.XmlId].RelativePath.EndsWith([string]$expected.xmlPathSuffix, [System.StringComparison]::Ordinal)
        })
        Assert-eMASEqual -Expected 1 -Actual $matches.Count -Message "Representative target was not unique for $($expected.rawHref)."
        Assert-eMASEqual -Expected $expected.normalizedTargetPath -Actual $matches[0].NormalizedTargetPath -Message "Representative normalization differs for $($expected.rawHref)."
        Assert-eMASEqual -Expected $true -Actual $matches[0].TargetExists -Message "Representative target was not present for $($expected.rawHref)."
    }
}

Invoke-eMASRecordedCheck -Name 'No-href delete reference is NotApplicable rather than absent' -Action {
    $expected = $expectations.notApplicableReference
    $match = @($resultBySample[[string]$expected.sampleId].References | Where-Object { $_.ReferenceId -eq $expected.referenceId })
    Assert-eMASEqual -Expected 1 -Actual $match.Count -Message 'No-href delete reference was not unique.'
    Assert-eMASEqual -Expected $expected.operation -Actual $match[0].Operation -Message 'Delete operation changed.'
    Assert-eMASEqual -Expected $null -Actual $match[0].RawHref -Message 'Delete raw href changed.'
    Assert-eMASEqual -Expected $expected.resolutionStatus -Actual $match[0].ResolutionStatus -Message 'Delete resolution status differs.'
    Assert-eMASEqual -Expected $expected.captureStatus -Actual $match[0].CaptureStatus -Message 'Delete capture status differs.'
    Assert-eMASEqual -Expected $expected.diagnosticCode -Actual $match[0].ResolutionDiagnosticCode -Message 'Delete diagnostic differs.'
    Assert-eMASEqual -Expected $null -Actual $match[0].TargetExists -Message 'Delete leaf became a missing target.'
}

foreach ($pair in @($expectations.invariancePairs)) {
    Invoke-eMASRecordedCheck -Name ("Physical resolution invariant: {0} vs {1}" -f $pair.baseline, $pair.comparison) -Action {
        Assert-eMASEqual -Expected (ConvertTo-eMASResolutionProjection -Result $resultBySample[[string]$pair.baseline] -ExcludeTargetFileId) -Actual (ConvertTo-eMASResolutionProjection -Result $resultBySample[[string]$pair.comparison] -ExcludeTargetFileId) -Message "$($pair.comparison) physical resolution differs from $($pair.baseline)."
    }
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP ReferenceResolution observations are equivalent for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-reference-resolution-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $directoryDiscovery = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-RESOLUTION-SD-002-DIRECTORY'
        $directoryXml = Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery
        $directoryInventory = Invoke-eMASReferenceInventory -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -BackboneXmlInventoryResult $directoryXml
        $directoryResult = Invoke-eMASReferenceResolution -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -ReferenceInventoryResult $directoryInventory
        Assert-eMASEqual -Expected (ConvertTo-eMASResolutionProjection -Result $resultBySample['SD-002']) -Actual (ConvertTo-eMASResolutionProjection -Result $directoryResult) -Message 'Directory resolution differs from ZIP.'
        Assert-eMASTrue -Condition ((ConvertTo-eMASResolutionProjection -Result $directoryResult) -notlike "*$temporaryRoot*") -Message 'Temporary extraction path leaked into resolution output.'

        $rejected = $false
        try {
            Invoke-eMASReferenceResolution -SourcePath $directorySource -RepositoryDiscoveryResult $directoryDiscovery -ReferenceInventoryResult $directoryInventory -OutputPath (Join-Path $directorySource 'resolution-result.json') | Out-Null
        }
        catch { $rejected = $_.Exception.Message -like '*RES-OUTPUT-002*' }
        Assert-eMASTrue -Condition $rejected -Message 'Resolution output inside directory SourcePath was not rejected.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'Synthetic unsafe and external hrefs are rejected without lookup' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-reference-safety-{0}' -f [guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($sourceRoot)
        $rawHrefs = [object[]]@($expectations.syntheticSafetyCases | ForEach-Object { $_.rawHref })
        $inputs = New-eMASSyntheticInputs -RawReferences $rawHrefs
        $result = Invoke-eMASReferenceResolution -SourcePath $sourceRoot -RepositoryDiscoveryResult $inputs.Discovery -ReferenceInventoryResult $inputs.Inventory
        for ($index = 0; $index -lt $expectations.syntheticSafetyCases.Count; $index++) {
            $expected = $expectations.syntheticSafetyCases[$index]
            $actual = $result.References[$index]
            Assert-eMASEqual -Expected $expected.rawHref -Actual $actual.RawHref -Message "Safety raw href changed for $($expected.name)."
            Assert-eMASEqual -Expected $expected.resolutionStatus -Actual $actual.ResolutionStatus -Message "Safety status differs for $($expected.name)."
            Assert-eMASEqual -Expected $expected.diagnosticCode -Actual $actual.ResolutionDiagnosticCode -Message "Safety diagnostic differs for $($expected.name)."
            Assert-eMASEqual -Expected $null -Actual $actual.NormalizedTargetPath -Message "Unsafe target path was normalized for $($expected.name)."
            Assert-eMASEqual -Expected $null -Actual $actual.TargetExists -Message "Unsafe target received an existence value for $($expected.name)."
            Assert-eMASEqual -Expected $null -Actual $actual.TargetFileId -Message "Unsafe target received a FileId for $($expected.name)."
        }
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'Fragment is ignored for bounded physical file lookup' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-reference-fragment-{0}' -f [guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($sourceRoot)
        $files = [object[]]@(
            [pscustomobject][ordered]@{ FileId = 'FIL-0001'; RelativePath = 'Synthetic/0000/document.pdf'; CaptureStatus = 'Available' },
            [pscustomobject][ordered]@{ FileId = 'FIL-0002'; RelativePath = 'Synthetic/0000/index.xml'; CaptureStatus = 'Available' }
        )
        $inputs = New-eMASSyntheticInputs -RawReferences @('document.pdf#ID0001', '#ID0002') -Files $files
        $result = Invoke-eMASReferenceResolution -SourcePath $sourceRoot -RepositoryDiscoveryResult $inputs.Discovery -ReferenceInventoryResult $inputs.Inventory
        Assert-eMASEqual -Expected 'document.pdf#ID0001' -Actual $result.References[0].RawHref -Message 'Fragment-bearing raw href changed.'
        Assert-eMASEqual -Expected '0000/document.pdf' -Actual $result.References[0].NormalizedTargetPath -Message 'Physical path portion was not resolved.'
        Assert-eMASEqual -Expected $true -Actual $result.References[0].TargetExists -Message 'Fragment-bearing physical target was not found.'
        Assert-eMASEqual -Expected 'ResolvedPresent' -Actual $result.References[0].ResolutionStatus -Message 'Fragment-bearing resolution status differs.'
        Assert-eMASEqual -Expected '#ID0002' -Actual $result.References[1].RawHref -Message 'Fragment-only raw href changed.'
        Assert-eMASEqual -Expected '0000/index.xml' -Actual $result.References[1].NormalizedTargetPath -Message 'Fragment-only href did not resolve to the containing XML.'
        Assert-eMASEqual -Expected $true -Actual $result.References[1].TargetExists -Message 'Containing XML was not found for fragment-only href.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'Access-denied inventory target remains unknown rather than absent' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-reference-access-{0}' -f [guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($sourceRoot)
        $file = [pscustomobject][ordered]@{ FileId = 'FIL-0001'; RelativePath = 'Synthetic/0000/document.pdf'; CaptureStatus = 'AccessDenied' }
        $inputs = New-eMASSyntheticInputs -RawReferences @('document.pdf') -Files @($file)
        $result = Invoke-eMASReferenceResolution -SourcePath $sourceRoot -RepositoryDiscoveryResult $inputs.Discovery -ReferenceInventoryResult $inputs.Inventory
        Assert-eMASEqual -Expected '0000/document.pdf' -Actual $result.References[0].NormalizedTargetPath -Message 'Access-denied target path differs.'
        Assert-eMASEqual -Expected 'FIL-0001' -Actual $result.References[0].TargetFileId -Message 'Access-denied known target identity was lost.'
        Assert-eMASEqual -Expected $null -Actual $result.References[0].TargetExists -Message 'Access-denied target was treated as absent.'
        Assert-eMASEqual -Expected 'AccessDenied' -Actual $result.References[0].ResolutionStatus -Message 'Access-denied status differs.'
        Assert-eMASEqual -Expected 'AccessDenied' -Actual $result.References[0].CaptureStatus -Message 'Access-denied capture status differs.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASRecordedCheck -Name 'ReferenceResolution performs no XML parse network call or target-file open' -Action {
    $moduleText = [System.IO.File]::ReadAllText($referenceResolutionModulePath)
    foreach ($prohibitedPattern in @('System\.Xml', 'XmlReader', 'SelectNodes', 'Invoke-WebRequest', 'WebClient', 'HttpClient', 'GetResponse', 'ZipArchive', '\[System\.IO\.File\]::Open')) {
        Assert-eMASTrue -Condition ($moduleText -notmatch $prohibitedPattern) -Message "ReferenceResolution contains prohibited implementation pattern $prohibitedPattern."
    }
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes ReferenceResolution' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-002-entrypoint.reference-resolution.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-002'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-RESOLUTION-ENTRYPOINT' `
        -IncludeReferenceResolution
    Assert-eMASEqual -Expected 93 -Actual @($entryResult.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedPresent' }).Count -Message 'Entry-point present count differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
}

# Post-test freeze gate compares hash and timestamp for every executable frozen ZIP.
foreach ($sampleId in @($sourceState.Keys)) {
    $state = $sourceState[$sampleId]
    if ((Get-eMASTestSha256 -Path $state.Path) -ne $state.Hash) { throw ('FREEZE-VERIFY-003 Frozen fixture changed during testing: {0}' -f $sampleId) }
    if ((New-Object System.IO.FileInfo($state.Path)).LastWriteTimeUtc -ne $state.LastWriteTimeUtc) { throw ('FREEZE-VERIFY-004 Frozen fixture timestamp changed during testing: {0}' -f $sampleId) }
    $frozenAfterVerified++
}
Write-Output ('[PASS] Post-test freeze gate verified {0} ZIP fixtures.' -f $frozenAfterVerified)

$fixtureFailureCount = @($fixtureResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$additionalFailureCount = @($additionalResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$overallStatus = $(if (($fixtureFailureCount + $additionalFailureCount) -eq 0) { 'PASS' } else { 'FAIL' })
$summary = [pscustomobject][ordered]@{
    ContractId = $expectations.contractId
    Capability = 'ReferenceResolution'
    StartedAtUtc = $startedAtUtc.ToString('o')
    CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    OverallStatus = $overallStatus
    FrozenFixtureCountVerifiedBefore = $frozenBeforeVerified
    FrozenFixtureCountVerifiedAfter = $frozenAfterVerified
    FixtureCount = $fixtureResults.Count
    FixturePassCount = @($fixtureResults | Where-Object { $_.Status -eq 'PASS' }).Count
    FixtureFailCount = $fixtureFailureCount
    AdditionalCheckCount = $additionalResults.Count
    AdditionalCheckPassCount = @($additionalResults | Where-Object { $_.Status -eq 'PASS' }).Count
    AdditionalCheckFailCount = $additionalFailureCount
    FixtureResults = [object[]]@($fixtureResults)
    AdditionalChecks = [object[]]@($additionalResults)
}
$summaryPath = Join-Path $resolvedOutputRoot 'reference-resolution-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('ReferenceResolution tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
