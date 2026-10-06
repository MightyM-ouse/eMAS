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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/checksum-mismatch-interpretation/wave1-expectations.json'
}
$modulePaths = @(
    'engine/powershell51/eMAS.RepositoryDiscovery.psm1',
    'engine/powershell51/eMAS.BackboneXmlInventory.psm1',
    'engine/powershell51/eMAS.ReferenceInventory.psm1',
    'engine/powershell51/eMAS.ReferenceResolution.psm1',
    'engine/powershell51/eMAS.MissingReferenceInterpretation.psm1',
    'engine/powershell51/eMAS.DeclaredChecksumComparison.psm1',
    'engine/powershell51/eMAS.ChecksumMismatchInterpretation.psm1'
)
foreach ($relativeModulePath in $modulePaths) { Import-Module -Name (Join-Path $repositoryRoot $relativeModulePath) -Force -ErrorAction Stop }
$interpretationModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ChecksumMismatchInterpretation.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'

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
$comparisonBySample = @{}
$frozenBeforeVerified = 0
$frozenAfterVerified = 0
$observationCode = [string]$expectations.observationCode

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

function Get-eMASMismatchObservations {
    param([Parameter(Mandatory = $true)][object] $Result)
    return @($Result.Observations | Where-Object { $_.Code -eq $observationCode })
}

function ConvertTo-eMASObservationProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ([object[]]@(Get-eMASMismatchObservations -Result $Result) | ConvertTo-Json -Depth 32 -Compress)
}

function ConvertTo-eMASInterpretationCoverageProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ([object[]]@($Result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' }) | ConvertTo-Json -Depth 32 -Compress)
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

function New-eMASSyntheticComparisonResult {
    param([AllowNull()][object] $State, [string] $RepositoryComparisonStatus = 'Collected')

    $references = @()
    if ($null -ne $State) {
        $statePropertyNames = @($State.PSObject.Properties.Name)
        $reference = [pscustomobject][ordered]@{
            ReferenceId = 'REF-0001'
            XmlId = 'XML-0001'
            DossierId = 'DOS-0001'
            SequenceId = 'SEQ-0001'
            XmlKind = 'CommonBackbone'
            SourceElement = 'leaf'
            SourceElementNamespaceUri = ''
            SourcePosition = 1
            SourceElementId = 'SYN-0001'
            RawHref = $(if ([string]$State.checksumDiagnosticCode -eq 'NoPhysicalHref') { $null } else { 'document.pdf' })
            NormalizedTargetPath = $(if ([string]$State.checksumDiagnosticCode -eq 'NoPhysicalHref') { $null } else { '0000/document.pdf' })
            TargetFileId = $(if ($statePropertyNames -contains 'resolutionStatus') { $null } else { 'FIL-0001' })
            TargetExists = $(if ($statePropertyNames -contains 'targetExists') { $State.targetExists } else { $true })
            DeclaredChecksumAlgorithm = $(if ($statePropertyNames -contains 'declaredAlgorithm') { $State.declaredAlgorithm } else { 'MD5' })
            DeclaredChecksum = $(if ($statePropertyNames -contains 'declaredChecksum') { $State.declaredChecksum } else { '693fce6b6c9690b400cdbd30762fbfca' })
            CalculatedChecksum = $State.calculatedChecksum
            ChecksumMatch = $State.checksumMatch
            Operation = 'new'
            ModifiedFileRawPath = $null
            ResolutionStatus = $(if ($statePropertyNames -contains 'resolutionStatus') { $State.resolutionStatus } else { 'ResolvedPresent' })
            ResolutionDiagnosticCode = $null
            CaptureStatus = 'Available'
            ChecksumComparisonStatus = $State.checksumComparisonStatus
            ChecksumDiagnosticCode = $State.checksumDiagnosticCode
        }
        if ([string]$State.checksumComparisonStatus -eq '__missing__') { $reference.PSObject.Properties.Remove('ChecksumComparisonStatus') }
        $references = @($reference)
    }
    return [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{
            ScenarioId = 'MS-04'
            Phase = 'PreSales'
            ExecutionId = 'EXEC-SYNTHETIC-CMI'
            ScannerName = 'SyntheticDeclaredChecksumComparison'
            ScannerVersion = '0.6.0'
            CompletedAtUtc = $null
            CompletionStatus = 'Completed'
            Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation', 'DeclaredChecksumComparison')
        }
        Repository = [pscustomobject][ordered]@{ RepositoryId = 'REP-0001'; SourcePath = $null; ResolvedSourcePath = $null; SourceKind = 'Directory'; SourceSha256 = $null; InventoryCaptureStatus = 'Available'; Errors = [object[]]@() }
        DossierCandidates = [object[]]@()
        Sequences = [object[]]@()
        XmlDocuments = [object[]]@()
        References = [object[]]$references
        Files = [object[]]@()
        LifecycleRelationships = [object[]]@()
        Observations = [object[]]@([pscustomobject][ordered]@{ ObservationId = 'OBS-0001'; Category = 'Inventory'; Code = 'ExactSequenceChildrenObserved'; SubjectType = 'Dossier'; SubjectId = 'DOS-0001'; ObservedValue = [object[]]@('0000'); CaptureStatus = 'Available'; EvidenceIds = [object[]]@() })
        ClassificationEvidence = [object[]]@()
        CollectionCoverage = [object[]]@(
            [pscustomobject][ordered]@{ CheckId = 'DeclaredChecksumComparison'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; ComparisonStatus = $RepositoryComparisonStatus; RecordsProduced = 0; ReasonCode = $null },
            [pscustomobject][ordered]@{ CheckId = 'ChecksumMismatchInterpretation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideDeclaredChecksumComparisonScope' },
            [pscustomobject][ordered]@{ CheckId = 'ZeroByteInterpretation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideDeclaredChecksumComparisonScope' }
        )
    }
}

# Freeze gate before any scanner invocation.
foreach ($manifestRow in @($manifestRows | Where-Object { $_.VerificationStatus -eq 'PASS_FROZEN' })) {
    $fixturePath = Join-Path $resolvedCorpusRoot ($manifestRow.FixtureFilename -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not [System.IO.File]::Exists($fixturePath)) { throw ('FREEZE-VERIFY-001 Frozen fixture is missing: {0}' -f $manifestRow.SampleId) }
    $actualHash = Get-eMASTestSha256 -Path $fixturePath
    if ($actualHash -ne $manifestRow.FixtureSHA256) { throw ('FREEZE-VERIFY-002 Frozen fixture hash mismatch: {0}' -f $manifestRow.SampleId) }
    $sourceState[$manifestRow.SampleId] = [pscustomobject]@{ Path = $fixturePath; Hash = $actualHash; LastWriteTimeUtc = (New-Object System.IO.FileInfo($fixturePath)).LastWriteTimeUtc }
    $frozenBeforeVerified++
}
Write-Output ('[PASS] Pre-test freeze gate verified {0} ZIP fixtures.' -f $frozenBeforeVerified)

foreach ($fixtureExpectation in @($expectations.fixtures)) {
    $sampleId = [string]$fixtureExpectation.sampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.checksum-mismatch-interpretation.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-CMI-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $inventory = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
        $resolution = Invoke-eMASReferenceResolution -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory
        $missing = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution
        $comparison = Invoke-eMASDeclaredChecksumComparison -SourcePath $state.Path -MissingReferenceInterpretationResult $missing
        $referencesBefore = [object[]]@($comparison.References) | ConvertTo-Json -Depth 64 -Compress
        $observationsBefore = @($comparison.Observations)
        $otherCoverageBefore = [object[]]@($comparison.CollectionCoverage | Where-Object { $_.CheckId -ne 'ChecksumMismatchInterpretation' }) | ConvertTo-Json -Depth 64 -Compress
        $result = Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $comparison -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $referencesBefore -Actual ([object[]]@($result.References) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed reference or checksum evidence."
        Assert-eMASEqual -Expected $otherCoverageBefore -Actual ([object[]]@($result.CollectionCoverage | Where-Object { $_.CheckId -ne 'ChecksumMismatchInterpretation' }) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed upstream coverage."
        Assert-eMASEqual -Expected (@($comparison.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed lifecycle relationships."
        Assert-eMASEqual -Expected (@($comparison.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed classification evidence."
        Assert-eMASEqual -Expected ($observationsBefore.Count + [int]$fixtureExpectation.expectedObservations) -Actual @($result.Observations).Count -Message "$sampleId observation count differs."
        for ($index = 0; $index -lt $observationsBefore.Count; $index++) {
            Assert-eMASEqual -Expected ($observationsBefore[$index] | ConvertTo-Json -Depth 32 -Compress) -Actual ($result.Observations[$index] | ConvertTo-Json -Depth 32 -Compress) -Message "$sampleId changed or reordered an existing observation."
        }

        $factualMismatches = @($comparison.References | Where-Object { $_.ChecksumComparisonStatus -eq 'Mismatched' -and $_.ChecksumMatch -is [bool] -and -not $_.ChecksumMatch })
        $mismatchObservations = @(Get-eMASMismatchObservations -Result $result)
        Assert-eMASEqual -Expected $fixtureExpectation.factualMismatches -Actual $factualMismatches.Count -Message "$sampleId factual mismatch evidence differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedObservations -Actual $mismatchObservations.Count -Message "$sampleId DeclaredChecksumMismatch count differs."
        foreach ($observation in $mismatchObservations) {
            $source = @($comparison.References | Where-Object { $_.ReferenceId -eq $observation.ReferenceId })
            Assert-eMASEqual -Expected 1 -Actual $source.Count -Message "$sampleId observation is not traceable to one reference."
            Assert-eMASEqual -Expected 'Mismatched' -Actual $source[0].ChecksumComparisonStatus -Message "$sampleId observation source was not Mismatched."
            Assert-eMASEqual -Expected $false -Actual $source[0].ChecksumMatch -Message "$sampleId observation source was not ChecksumMatch=false."
            Assert-eMASEqual -Expected $source[0].TargetFileId -Actual $observation.TargetFileId -Message "$sampleId observation target identity differs."
            Assert-eMASEqual -Expected $source[0].CalculatedChecksum -Actual $observation.CalculatedChecksum -Message "$sampleId observation calculated checksum differs."
            Assert-eMASEqual -Expected $source[0].DeclaredChecksum -Actual $observation.DeclaredChecksum -Message "$sampleId observation declared checksum differs."
            foreach ($forbidden in @($expectations.prohibitedFieldNames)) {
                Assert-eMASTrue -Condition (@($observation.PSObject.Properties.Name) -notcontains [string]$forbidden) -Message "$sampleId observation carries prohibited field $forbidden."
            }
        }
        foreach ($code in @($expectations.prohibitedObservationCodes)) {
            Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq $code }).Count -Message "$sampleId emitted prohibited observation $code."
        }

        $referenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Reference' })
        $repositoryCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Repository' })
        $assessed = @($referenceCoverage | Where-Object { $_.AssessmentStatus -eq 'Assessed' })
        $notApplicable = @($referenceCoverage | Where-Object { $_.AssessmentStatus -eq 'NotApplicable' })
        $notAssessed = @($referenceCoverage | Where-Object { $_.AssessmentStatus -eq 'NotAssessed' })
        Assert-eMASEqual -Expected @($result.References).Count -Actual $referenceCoverage.Count -Message "$sampleId per-reference interpretation coverage differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedAssessedReferences -Actual $assessed.Count -Message "$sampleId assessed reference count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedNotApplicableReferences -Actual $notApplicable.Count -Message "$sampleId not-applicable reference count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedNotAssessedReferences -Actual $notAssessed.Count -Message "$sampleId not-assessed reference count differs."
        Assert-eMASEqual -Expected 1 -Actual $repositoryCoverage.Count -Message "$sampleId repository interpretation coverage count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedRepositoryAssessmentStatus -Actual $repositoryCoverage[0].AssessmentStatus -Message "$sampleId repository assessment status differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedObservations -Actual $repositoryCoverage[0].RecordsProduced -Message "$sampleId repository records produced differs."
        foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
            $deferred = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
            Assert-eMASEqual -Expected 1 -Actual $deferred.Count -Message "$sampleId deferred coverage count differs for $checkId."
            Assert-eMASEqual -Expected 'NotCollected' -Actual $deferred[0].CaptureStatus -Message "$sampleId completed deferred capability $checkId."
        }
        Assert-eMASEqual -Expected 'ChecksumMismatchInterpretation' -Actual @($result.Execution.Capabilities)[-1] -Message "$sampleId capability declaration differs."
        Assert-eMASEqual -Expected $comparison.Execution.CompletionStatus -Actual $result.Execution.CompletionStatus -Message "$sampleId completion status changed."

        $repeat = Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $comparison
        Assert-eMASEqual -Expected (ConvertTo-eMASObservationProjection -Result $result) -Actual (ConvertTo-eMASObservationProjection -Result $repeat) -Message "$sampleId observations are not deterministic."
        Assert-eMASEqual -Expected (ConvertTo-eMASInterpretationCoverageProjection -Result $result) -Actual (ConvertTo-eMASInterpretationCoverageProjection -Result $repeat) -Message "$sampleId coverage is not deterministic."

        $resultBySample[$sampleId] = $result
        $comparisonBySample[$sampleId] = $comparison
        $actualSummary = [pscustomobject][ordered]@{
            FactualMismatches = $factualMismatches.Count
            Observations = $mismatchObservations.Count
            AssessedReferences = $assessed.Count
            NotApplicableReferences = $notApplicable.Count
            NotAssessedReferences = $notAssessed.Count
            RepositoryAssessmentStatus = $repositoryCoverage[0].AssessmentStatus
        }
        Write-Output ('[PASS] {0} ChecksumMismatchInterpretation acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = [pscustomobject][ordered]@{
            FactualMismatches = $fixtureExpectation.factualMismatches
            Observations = $fixtureExpectation.expectedObservations
            AssessedReferences = $fixtureExpectation.expectedAssessedReferences
            NotApplicableReferences = $fixtureExpectation.expectedNotApplicableReferences
            NotAssessedReferences = $fixtureExpectation.expectedNotAssessedReferences
            RepositoryAssessmentStatus = $fixtureExpectation.expectedRepositoryAssessmentStatus
        }
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

foreach ($expected in @($expectations.expectedObservations)) {
    Invoke-eMASRecordedCheck -Name ("{0} DeclaredChecksumMismatch traces exactly to {1}" -f $expected.sampleId, $expected.referenceId) -Action {
        $observation = @(Get-eMASMismatchObservations -Result $resultBySample[[string]$expected.sampleId])
        Assert-eMASEqual -Expected 1 -Actual $observation.Count -Message 'Observation count differs.'
        $o = $observation[0]
        Assert-eMASEqual -Expected $expected.observationId -Actual $o.ObservationId -Message 'ObservationId differs.'
        Assert-eMASEqual -Expected $expected.findingId -Actual $o.FindingId -Message 'FindingId differs.'
        Assert-eMASEqual -Expected 'DeclaredChecksumMismatch' -Actual $o.FindingCode -Message 'FindingCode differs.'
        Assert-eMASEqual -Expected 'Integrity' -Actual $o.Category -Message 'Category differs.'
        Assert-eMASEqual -Expected 'Reference' -Actual $o.SubjectType -Message 'SubjectType differs.'
        Assert-eMASEqual -Expected $expected.referenceId -Actual $o.SubjectId -Message 'SubjectId differs.'
        Assert-eMASEqual -Expected $expected.referenceId -Actual $o.ReferenceId -Message 'ReferenceId differs.'
        Assert-eMASEqual -Expected $expected.dossierId -Actual $o.DossierId -Message 'DossierId differs.'
        Assert-eMASEqual -Expected $expected.sequenceId -Actual $o.SequenceId -Message 'SequenceId differs.'
        Assert-eMASEqual -Expected $expected.xmlId -Actual $o.XmlId -Message 'XmlId differs.'
        Assert-eMASEqual -Expected $expected.targetFileId -Actual $o.TargetFileId -Message 'TargetFileId differs.'
        Assert-eMASEqual -Expected $expected.normalizedTargetPath -Actual $o.NormalizedTargetPath -Message 'NormalizedTargetPath differs.'
        Assert-eMASEqual -Expected $expected.declaredChecksumAlgorithm -Actual $o.DeclaredChecksumAlgorithm -Message 'Algorithm differs.'
        Assert-eMASEqual -Expected $expected.declaredChecksum -Actual $o.DeclaredChecksum -Message 'Declared checksum differs.'
        Assert-eMASEqual -Expected $expected.calculatedChecksum -Actual $o.CalculatedChecksum -Message 'Calculated checksum differs.'
        Assert-eMASEqual -Expected ('{0}|{1}' -f $expected.referenceId, $expected.targetFileId) -Actual (@($o.EvidenceIds) -join '|') -Message 'EvidenceIds differ.'
        Assert-eMASEqual -Expected 'ConfirmedMismatch' -Actual $o.EvidenceStatus -Message 'EvidenceStatus differs.'
        Assert-eMASEqual -Expected 'Assessed' -Actual $o.AssessmentStatus -Message 'AssessmentStatus differs.'
        Assert-eMASEqual -Expected $true -Actual $o.Evaluation -Message 'Evaluation differs.'
        Assert-eMASEqual -Expected $true -Actual $o.ObservedValue -Message 'ObservedValue differs.'
    }
}

Invoke-eMASRecordedCheck -Name 'SD-018 zero-byte target yields only DeclaredChecksumMismatch, not ZeroByteFile' -Action {
    $result = $resultBySample['SD-018']
    Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq 'ZeroByteFile' }).Count -Message 'ZeroByteFile was emitted.'
    $zeroByte = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ZeroByteInterpretation' })
    Assert-eMASEqual -Expected 'NotCollected' -Actual $zeroByte[0].CaptureStatus -Message 'ZeroByteInterpretation was collected.'
}

Invoke-eMASRecordedCheck -Name 'Absent targets in SD-003 and SD-006 are NotApplicable and never mismatch observations' -Action {
    foreach ($absent in @($expectations.absentTargets)) {
        $result = $resultBySample[[string]$absent.sampleId]
        Assert-eMASEqual -Expected 0 -Actual @(Get-eMASMismatchObservations -Result $result).Count -Message "$($absent.sampleId) produced a mismatch observation."
        $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectId -eq $absent.referenceId })
        Assert-eMASEqual -Expected 'NotApplicable' -Actual $coverage[0].AssessmentStatus -Message "$($absent.sampleId) absent target coverage differs."
        Assert-eMASEqual -Expected 'TargetAbsent' -Actual $coverage[0].ReasonCode -Message "$($absent.sampleId) absent target reason differs."
        Assert-eMASEqual -Expected 1 -Actual @($result.Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' -and $_.ReferenceId -eq $absent.referenceId }).Count -Message "$($absent.sampleId) MissingReference observation changed."
    }
}

Invoke-eMASRecordedCheck -Name 'No-href delete REF-0073 remains NotApplicable' -Action {
    $expected = $expectations.notApplicableReference
    $coverage = @($resultBySample[[string]$expected.sampleId].CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectId -eq $expected.referenceId })
    Assert-eMASEqual -Expected 'NotApplicable' -Actual $coverage[0].AssessmentStatus -Message 'No-href coverage differs.'
    Assert-eMASEqual -Expected $expected.reasonCode -Actual $coverage[0].ReasonCode -Message 'No-href reason differs.'
}

Invoke-eMASRecordedCheck -Name 'Clean SD-001/SD-002 are Assessed with zero observations (assessed-zero, not NotAssessed)' -Action {
    foreach ($sampleId in @('SD-001', 'SD-002')) {
        $result = $resultBySample[$sampleId]
        $repository = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Repository' })[0]
        Assert-eMASEqual -Expected 'Assessed' -Actual $repository.AssessmentStatus -Message "$sampleId was not Assessed."
        Assert-eMASEqual -Expected 0 -Actual $repository.RecordsProduced -Message "$sampleId produced records."
        Assert-eMASEqual -Expected 'Available' -Actual $repository.CaptureStatus -Message "$sampleId capture status differs."
    }
}

foreach ($pair in @($expectations.invariancePairs)) {
    Invoke-eMASRecordedCheck -Name ("Interpretation invariant: {0} vs {1}" -f $pair.baseline, $pair.comparison) -Action {
        Assert-eMASEqual -Expected (ConvertTo-eMASInterpretationCoverageProjection -Result $resultBySample[[string]$pair.baseline]) -Actual (ConvertTo-eMASInterpretationCoverageProjection -Result $resultBySample[[string]$pair.comparison]) -Message 'Interpretation coverage differs.'
        Assert-eMASEqual -Expected 0 -Actual @(Get-eMASMismatchObservations -Result $resultBySample[[string]$pair.comparison]).Count -Message 'Unexpected observation.'
    }
}

Invoke-eMASRecordedCheck -Name 'Coverage states distinguish collected, assessed and deferred capabilities' -Action {
    $result = $resultBySample['SD-004']
    $repositoryRow = { param($checkId) @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId -and $_.SubjectType -eq 'Repository' })[0] }
    Assert-eMASEqual -Expected 'Assessed' -Actual (& $repositoryRow 'MissingReferenceInterpretation').AssessmentStatus -Message 'MissingReferenceInterpretation coverage differs.'
    Assert-eMASEqual -Expected 'Collected' -Actual (& $repositoryRow 'DeclaredChecksumComparison').ComparisonStatus -Message 'DeclaredChecksumComparison coverage differs.'
    Assert-eMASEqual -Expected 'Assessed' -Actual (& $repositoryRow 'ChecksumMismatchInterpretation').AssessmentStatus -Message 'ChecksumMismatchInterpretation coverage differs.'
    foreach ($checkId in @('RepositoryInventory', 'CommonXmlParse', 'RegionalXmlParse', 'ReferenceInventory', 'ReferenceResolution')) {
        Assert-eMASEqual -Expected 'Available' -Actual (& $repositoryRow $checkId).CaptureStatus -Message "$checkId coverage differs."
    }
}

foreach ($state in @($expectations.syntheticStates)) {
    Invoke-eMASRecordedCheck -Name ("Synthetic semantic state: {0}" -f $state.name) -Action {
        $synthetic = New-eMASSyntheticComparisonResult -State $state
        $referencesBefore = [object[]]@($synthetic.References) | ConvertTo-Json -Depth 32 -Compress
        $result = Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $synthetic
        $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Reference' })
        Assert-eMASEqual -Expected 1 -Actual $coverage.Count -Message 'Per-reference coverage count differs.'
        Assert-eMASEqual -Expected $state.expectedAssessmentStatus -Actual $coverage[0].AssessmentStatus -Message 'Assessment status differs.'
        Assert-eMASEqual -Expected $state.expectedReasonCode -Actual $coverage[0].ReasonCode -Message 'Reason code differs.'
        Assert-eMASEqual -Expected $state.expectedObservations -Actual @(Get-eMASMismatchObservations -Result $result).Count -Message 'Observation count differs.'
        Assert-eMASEqual -Expected $referencesBefore -Actual ([object[]]@($result.References) | ConvertTo-Json -Depth 32 -Compress) -Message 'Evidence was modified.'
        if ($state.expectedObservations -eq 0 -and $state.expectedAssessmentStatus -eq 'NotAssessed') {
            Assert-eMASEqual -Expected 'CompletedWithCollectionGaps' -Actual $result.Execution.CompletionStatus -Message 'NotAssessed state did not surface as a gap.'
        }
    }
}

Invoke-eMASRecordedCheck -Name 'Zero-reference input: Assessed only when DeclaredChecksumComparison was Collected' -Action {
    $collected = Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult (New-eMASSyntheticComparisonResult -State $null -RepositoryComparisonStatus 'Collected')
    Assert-eMASEqual -Expected 'Assessed' -Actual @($collected.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Repository' })[0].AssessmentStatus -Message 'Collected zero-reference input was not Assessed.'
    $notAssessed = Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult (New-eMASSyntheticComparisonResult -State $null -RepositoryComparisonStatus 'NotAssessed')
    Assert-eMASEqual -Expected 'NotAssessed' -Actual @($notAssessed.CollectionCoverage | Where-Object { $_.CheckId -eq 'ChecksumMismatchInterpretation' -and $_.SubjectType -eq 'Repository' })[0].AssessmentStatus -Message 'Unavailable comparison was not NotAssessed.'
}

Invoke-eMASRecordedCheck -Name 'Input guards reject missing prerequisite and repeated interpretation' -Action {
    $withoutComparison = New-eMASSyntheticComparisonResult -State $null
    $withoutComparison.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'ReferenceResolution', 'MissingReferenceInterpretation')
    $message = $null
    try { [void](Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $withoutComparison) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue -Condition ([string]$message -like 'CMI-INPUT-003*') -Message 'Missing DeclaredChecksumComparison was not rejected.'
    $message = $null
    try { [void](Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $resultBySample['SD-004']) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue -Condition ([string]$message -like 'CMI-INPUT-004*') -Message 'Repeated interpretation was not rejected.'
}

Invoke-eMASRecordedCheck -Name 'Interpretation module performs no file read, hashing, XML, ZIP, resolution, network or impact logic' -Action {
    $moduleText = [System.IO.File]::ReadAllText($interpretationModulePath)
    foreach ($prohibitedPattern in @('File\]::Open', 'ReadAll', 'OpenRead', 'Get-ChildItem', 'Get-Content', 'ZipArchive', 'Compression', 'Cryptography', 'MD5\]::Create', 'System\.Xml', 'XmlReader', 'SelectNodes', 'Resolve-eMASReferencePath', 'Invoke-WebRequest', 'WebClient', 'HttpClient', 'ChecksumMatch\s+-ne\s+\$true', '\bRAG\b', '\bSeverity\b', '\bRecommendation', '\bConfidence\b', 'Corrupt', 'ZeroByteFile', 'New-Guid', 'NewGuid')) {
        Assert-eMASTrue -Condition ($moduleText -notmatch $prohibitedPattern) -Message "Interpretation module contains prohibited pattern $prohibitedPattern."
    }
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes ChecksumMismatchInterpretation' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-004-entrypoint.checksum-mismatch-interpretation.json'
    $entryResult = & $entryScriptPath -SourcePath $sourceState['SD-004'].Path -OutputPath $entryResultPath -ExecutionId 'EXEC-CMI-ENTRYPOINT' -IncludeChecksumMismatchInterpretation
    Assert-eMASEqual -Expected 1 -Actual @(Get-eMASMismatchObservations -Result $entryResult).Count -Message 'Entry-point observation count differs.'
    Assert-eMASEqual -Expected 'REF-0094' -Actual @(Get-eMASMismatchObservations -Result $entryResult)[0].ReferenceId -Message 'Entry-point observation reference differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation+DeclaredChecksumComparison+ChecksumMismatchInterpretation' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
    Assert-eMASTrue -Condition ([System.IO.File]::Exists($entryResultPath)) -Message 'Entry-point output was not written.'
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
    Capability = 'ChecksumMismatchInterpretation'
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
$summaryPath = Join-Path $resolvedOutputRoot 'checksum-mismatch-interpretation-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('ChecksumMismatchInterpretation tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
