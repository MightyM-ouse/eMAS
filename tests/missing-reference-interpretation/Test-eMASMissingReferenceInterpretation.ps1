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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/missing-reference-interpretation/wave1-expectations.json'
}
$repositoryDiscoveryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$xmlInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$referenceInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1'
$referenceResolutionModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceResolution.psm1'
$interpretationModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.MissingReferenceInterpretation.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
Import-Module -Name $repositoryDiscoveryModulePath -Force -ErrorAction Stop
Import-Module -Name $xmlInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceResolutionModulePath -Force -ErrorAction Stop
Import-Module -Name $interpretationModulePath -Force -ErrorAction Stop

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

function ConvertTo-eMASReferenceProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ([object[]]@($Result.References) | ConvertTo-Json -Depth 64 -Compress)
}

function ConvertTo-eMASFindingProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([object[]]@($Result.Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' } | ForEach-Object {
        [pscustomobject][ordered]@{
            ObservationId = $_.ObservationId
            FindingId = $_.FindingId
            FindingCode = $_.FindingCode
            ReferenceId = $_.ReferenceId
            DossierId = $_.DossierId
            SequenceId = $_.SequenceId
            XmlId = $_.XmlId
            SourceElementId = $_.SourceElementId
            RawHref = $_.RawHref
            NormalizedTargetPath = $_.NormalizedTargetPath
            EvidenceStatus = $_.EvidenceStatus
            AssessmentStatus = $_.AssessmentStatus
            Evaluation = $_.Evaluation
        }
    }) | ConvertTo-Json -Depth 32 -Compress)
}

function ConvertTo-eMASExistingObservationProjection {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][int] $Count)

    $items = @($Result.Observations)
    if ($Count -eq 0) { return '[]' }
    return ([object[]]@($items[0..($Count - 1)]) | ConvertTo-Json -Depth 64 -Compress)
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

function New-eMASSyntheticResolutionResult {
    param([Parameter(Mandatory = $true)][object] $State)

    $normalizedTargetPath = $null
    if (@('ResolvedPresent', 'ResolvedAbsent', 'AccessDenied', 'InputUnavailable') -contains [string]$State.resolutionStatus) {
        $normalizedTargetPath = '0000/document.pdf'
    }
    $targetFileId = $(if (@('ResolvedPresent', 'AccessDenied') -contains [string]$State.resolutionStatus) { 'FIL-0001' } else { $null })
    $rawHref = $(if ([string]$State.resolutionStatus -eq 'NotApplicable') { $null } else { 'document.pdf' })
    return [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{
            ScenarioId = 'MS-04'
            Phase = 'PreSales'
            ExecutionId = 'EXEC-SYNTHETIC-INTERPRETATION'
            ScannerName = 'SyntheticReferenceResolution'
            ScannerVersion = '0.4.0'
            CompletedAtUtc = $null
            CompletionStatus = 'Completed'
            Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution')
        }
        Repository = [pscustomobject][ordered]@{
            RepositoryId = 'REP-0001'
            SourcePath = 'synthetic.zip'
            ResolvedSourcePath = '/synthetic/source.zip'
            SourceKind = 'Zip'
            SourceSha256 = 'synthetic'
            InventoryCaptureStatus = 'Available'
            Errors = [object[]]@()
        }
        DossierCandidates = [object[]]@([pscustomobject][ordered]@{ DossierId = 'DOS-0001'; RelativePath = 'Synthetic' })
        Sequences = [object[]]@([pscustomobject][ordered]@{ SequenceId = 'SEQ-0001'; DossierId = 'DOS-0001'; RelativePath = 'Synthetic/0000' })
        XmlDocuments = [object[]]@([pscustomobject][ordered]@{ XmlId = 'XML-0001'; DossierId = 'DOS-0001'; SequenceId = 'SEQ-0001'; RelativePath = 'Synthetic/0000/index.xml' })
        References = [object[]]@([pscustomobject][ordered]@{
            ReferenceId = 'REF-0001'
            XmlId = 'XML-0001'
            DossierId = 'DOS-0001'
            SequenceId = 'SEQ-0001'
            XmlKind = 'CommonBackbone'
            SourceElement = 'leaf'
            SourceElementNamespaceUri = ''
            SourcePosition = 1
            SourceElementId = 'SYN-0001'
            RawHref = $rawHref
            NormalizedTargetPath = $normalizedTargetPath
            TargetFileId = $targetFileId
            TargetExists = $State.targetExists
            DeclaredChecksumAlgorithm = $null
            DeclaredChecksum = $null
            CalculatedChecksum = $null
            ChecksumMatch = $null
            Operation = 'new'
            ModifiedFileRawPath = $null
            ResolutionStatus = $State.resolutionStatus
            ResolutionDiagnosticCode = $State.diagnosticCode
            CaptureStatus = $State.captureStatus
        })
        Files = [object[]]@()
        LifecycleRelationships = [object[]]@()
        Observations = [object[]]@()
        ClassificationEvidence = [object[]]@()
        CollectionCoverage = [object[]]@(
            [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Reference'; SubjectId = 'REF-0001'; CaptureStatus = $State.captureStatus; RecordsProduced = 1; ReasonCode = $State.diagnosticCode },
            [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = 1; ReasonCode = $null },
            [pscustomobject][ordered]@{ CheckId = 'MissingReferenceInterpretation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' },
            [pscustomobject][ordered]@{ CheckId = 'DeclaredChecksumComparison'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' },
            [pscustomobject][ordered]@{ CheckId = 'LifecycleLinkResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' },
            [pscustomobject][ordered]@{ CheckId = 'FileReferenceOrphanCorrelation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' }
        )
    }
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
    $resultFileName = '{0}.missing-reference-interpretation.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-MRI-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $inventory = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
        $resolution = Invoke-eMASReferenceResolution -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory
        $referenceProjectionBefore = ConvertTo-eMASReferenceProjection -Result $resolution
        $existingObservationCount = @($resolution.Observations).Count
        $existingObservationProjection = ConvertTo-eMASExistingObservationProjection -Result $resolution -Count $existingObservationCount
        $result = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $referenceProjectionBefore -Actual (ConvertTo-eMASReferenceProjection -Result $result) -Message "$sampleId changed raw or resolved reference evidence."
        Assert-eMASEqual -Expected $existingObservationProjection -Actual (ConvertTo-eMASExistingObservationProjection -Result $result -Count $existingObservationCount) -Message "$sampleId changed existing observations."
        Assert-eMASEqual -Expected (@($resolution.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed lifecycle relationships."
        Assert-eMASEqual -Expected (@($resolution.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed classification evidence."

        $resolvedAbsent = @($result.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedAbsent' })
        $findings = @($result.Observations | Where-Object { $_.Code -eq $expectations.observationCode })
        Assert-eMASEqual -Expected $fixtureExpectation.resolvedAbsentCount -Actual $resolvedAbsent.Count -Message "$sampleId resolved-absent count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedFindingCount -Actual $findings.Count -Message "$sampleId finding count differs."
        Assert-eMASEqual -Expected ($existingObservationCount + $findings.Count) -Actual @($result.Observations).Count -Message "$sampleId emitted an unrelated observation."

        foreach ($finding in $findings) {
            Assert-eMASEqual -Expected 'Integrity' -Actual $finding.Category -Message "$sampleId finding category differs."
            Assert-eMASEqual -Expected 'Reference' -Actual $finding.SubjectType -Message "$sampleId finding subject differs."
            Assert-eMASEqual -Expected $finding.ReferenceId -Actual $finding.SubjectId -Message "$sampleId finding subject ID differs."
            Assert-eMASEqual -Expected $expectations.findingCode -Actual $finding.FindingCode -Message "$sampleId finding code differs."
            Assert-eMASEqual -Expected 'ConfirmedAbsent' -Actual $finding.EvidenceStatus -Message "$sampleId evidence status differs."
            Assert-eMASEqual -Expected 'Assessed' -Actual $finding.AssessmentStatus -Message "$sampleId assessment status differs."
            Assert-eMASEqual -Expected $true -Actual $finding.Evaluation -Message "$sampleId finding evaluation differs."
            Assert-eMASEqual -Expected $true -Actual $finding.ObservedValue -Message "$sampleId observed value differs."
            Assert-eMASEqual -Expected 'Available' -Actual $finding.CaptureStatus -Message "$sampleId finding capture status differs."
            Assert-eMASEqual -Expected 1 -Actual @($finding.EvidenceIds).Count -Message "$sampleId finding evidence count differs."
            Assert-eMASEqual -Expected $finding.ReferenceId -Actual $finding.EvidenceIds[0] -Message "$sampleId finding evidence reference differs."
            foreach ($field in @($expectations.prohibitedFindingFields)) {
                Assert-eMASTrue -Condition ($finding.PSObject.Properties.Name -notcontains $field) -Message "$sampleId populated prohibited finding field $field."
            }
        }

        $expectedFindings = @($expectations.expectedFindings | Where-Object { $_.sampleId -eq $sampleId })
        Assert-eMASEqual -Expected $expectedFindings.Count -Actual $findings.Count -Message "$sampleId exact finding expectation differs."
        foreach ($expected in $expectedFindings) {
            $match = @($findings | Where-Object { $_.ReferenceId -eq $expected.referenceId })
            Assert-eMASEqual -Expected 1 -Actual $match.Count -Message "$sampleId omitted or duplicated expected finding for $($expected.referenceId)."
            foreach ($property in @('FindingId', 'ReferenceId', 'DossierId', 'SequenceId', 'XmlId', 'SourceElementId', 'RawHref', 'NormalizedTargetPath')) {
                $expectedName = $property.Substring(0, 1).ToLowerInvariant() + $property.Substring(1)
                Assert-eMASEqual -Expected $expected.$expectedName -Actual $match[0].$property -Message "$sampleId finding traceability differs for $property."
            }
        }

        foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
            $futureCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
            Assert-eMASEqual -Expected 1 -Actual $futureCoverage.Count -Message "$sampleId deferred coverage count differs for $checkId."
            Assert-eMASEqual -Expected 'NotCollected' -Actual $futureCoverage[0].CaptureStatus -Message "$sampleId completed deferred capability $checkId."
        }
        $perReferenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'MissingReferenceInterpretation' -and $_.SubjectType -eq 'Reference' })
        $repositoryCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'MissingReferenceInterpretation' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected @($result.References).Count -Actual $perReferenceCoverage.Count -Message "$sampleId per-reference interpretation coverage differs."
        Assert-eMASEqual -Expected 1 -Actual $repositoryCoverage.Count -Message "$sampleId repository interpretation coverage differs."
        Assert-eMASEqual -Expected 'Assessed' -Actual $repositoryCoverage[0].AssessmentStatus -Message "$sampleId repository assessment status differs."
        Assert-eMASEqual -Expected 'Available' -Actual $repositoryCoverage[0].CaptureStatus -Message "$sampleId repository interpretation capture differs."
        Assert-eMASEqual -Expected $findings.Count -Actual $repositoryCoverage[0].RecordsProduced -Message "$sampleId repository finding count differs."

        $repeat = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution
        Assert-eMASEqual -Expected (ConvertTo-eMASFindingProjection -Result $result) -Actual (ConvertTo-eMASFindingProjection -Result $repeat) -Message "$sampleId deterministic finding projection differs."

        $resultBySample[$sampleId] = $result
        $actualSummary = [pscustomobject][ordered]@{
            ResolvedAbsentReferences = $resolvedAbsent.Count
            MissingReferenceFindings = $findings.Count
            RepositoryAssessmentStatus = $repositoryCoverage[0].AssessmentStatus
        }
        Write-Output ('[PASS] {0} MissingReferenceInterpretation acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = [pscustomobject][ordered]@{
            ResolvedAbsentReferences = $fixtureExpectation.resolvedAbsentCount
            MissingReferenceFindings = $fixtureExpectation.expectedFindingCount
        }
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'SD-003 finding traces only to REF-0094 confirmed absent evidence' -Action {
    $findings = @($resultBySample['SD-003'].Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' })
    Assert-eMASEqual -Expected 1 -Actual $findings.Count -Message 'SD-003 finding count differs.'
    Assert-eMASEqual -Expected 'REF-0094' -Actual $findings[0].ReferenceId -Message 'SD-003 finding reference differs.'
    Assert-eMASEqual -Expected '0004/m1/eu/responses/de/de-responses.pdf' -Actual $findings[0].NormalizedTargetPath -Message 'SD-003 finding path differs.'
}

Invoke-eMASRecordedCheck -Name 'SD-006 finding remains a bounded physical target observation' -Action {
    $findings = @($resultBySample['SD-006'].Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' })
    Assert-eMASEqual -Expected 1 -Actual $findings.Count -Message 'SD-006 finding count differs.'
    Assert-eMASEqual -Expected 'REF-0091' -Actual $findings[0].ReferenceId -Message 'SD-006 finding reference differs.'
    Assert-eMASEqual -Expected '0004/m1/eu/eu-regional.xml' -Actual $findings[0].NormalizedTargetPath -Message 'SD-006 finding path differs.'
    foreach ($field in @('Region', 'RegulatoryValidity', 'MigrationReady', 'Severity', 'RAG')) {
        Assert-eMASTrue -Condition ($findings[0].PSObject.Properties.Name -notcontains $field) -Message "SD-006 finding populated prohibited interpretation field $field."
    }
}

Invoke-eMASRecordedCheck -Name 'No-href delete REF-0073 remains non-finding NotApplicable' -Action {
    $expected = $expectations.notApplicableReference
    $result = $resultBySample[[string]$expected.sampleId]
    Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' -and $_.ReferenceId -eq $expected.referenceId }).Count -Message 'No-href delete became a finding.'
    $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'MissingReferenceInterpretation' -and $_.SubjectType -eq 'Reference' -and $_.SubjectId -eq $expected.referenceId })
    Assert-eMASEqual -Expected 1 -Actual $coverage.Count -Message 'No-href delete coverage differs.'
    Assert-eMASEqual -Expected $expected.expectedAssessmentStatus -Actual $coverage[0].AssessmentStatus -Message 'No-href delete assessment differs.'
    Assert-eMASEqual -Expected $expected.expectedReasonCode -Actual $coverage[0].ReasonCode -Message 'No-href delete diagnostic was not preserved.'
}

foreach ($state in @($expectations.syntheticStates)) {
    Invoke-eMASRecordedCheck -Name ("Synthetic semantic state: {0}" -f $state.name) -Action {
        $input = New-eMASSyntheticResolutionResult -State $state
        $referenceBefore = ConvertTo-eMASReferenceProjection -Result $input
        $result = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $input
        $findings = @($result.Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' })
        $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'MissingReferenceInterpretation' -and $_.SubjectType -eq 'Reference' })
        Assert-eMASEqual -Expected $state.expectedFindingCount -Actual $findings.Count -Message "$($state.name) finding count differs."
        Assert-eMASEqual -Expected 1 -Actual $coverage.Count -Message "$($state.name) coverage count differs."
        Assert-eMASEqual -Expected $state.expectedAssessmentStatus -Actual $coverage[0].AssessmentStatus -Message "$($state.name) assessment status differs."
        Assert-eMASEqual -Expected $referenceBefore -Actual (ConvertTo-eMASReferenceProjection -Result $result) -Message "$($state.name) changed resolution evidence."
        if ($state.expectedFindingCount -eq 0 -and $null -ne $state.diagnosticCode) {
            Assert-eMASEqual -Expected $state.diagnosticCode -Actual $coverage[0].ReasonCode -Message "$($state.name) diagnostic was not preserved."
        }
    }
}

Invoke-eMASRecordedCheck -Name 'Clean byte-change orphan and zero-byte boundaries produce no missing finding' -Action {
    foreach ($sampleId in @('SD-001', 'SD-002', 'SD-004', 'SD-017', 'SD-018')) {
        Assert-eMASEqual -Expected 0 -Actual @($resultBySample[$sampleId].Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' }).Count -Message "$sampleId unexpectedly produced a missing-reference finding."
    }
}

Invoke-eMASRecordedCheck -Name 'Missing or malformed XML does not reconstruct missing-reference evidence' -Action {
    foreach ($sampleId in @('SD-005', 'SD-007', 'SD-008')) {
        Assert-eMASEqual -Expected 0 -Actual @($resultBySample[$sampleId].Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' }).Count -Message "$sampleId reconstructed a missing-reference finding."
    }
}

Invoke-eMASRecordedCheck -Name 'Interpretation module performs no source inspection XML parse or reference resolution' -Action {
    $moduleText = [System.IO.File]::ReadAllText($interpretationModulePath)
    foreach ($prohibitedPattern in @('System\.Xml', 'XmlReader', 'SelectNodes', 'Get-ChildItem', 'Invoke-WebRequest', 'WebClient', 'HttpClient', 'ZipArchive', '\[System\.IO\.File\]::Read', '\[System\.IO\.File\]::Open', 'Resolve-eMASReferencePath')) {
        Assert-eMASTrue -Condition ($moduleText -notmatch $prohibitedPattern) -Message "Interpretation module contains prohibited implementation pattern $prohibitedPattern."
    }
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes MissingReferenceInterpretation' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-003-entrypoint.missing-reference-interpretation.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-003'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-MRI-ENTRYPOINT' `
        -IncludeMissingReferenceInterpretation
    Assert-eMASEqual -Expected 1 -Actual @($entryResult.Observations | Where-Object { $_.Code -eq 'ReferenceTargetMissing' }).Count -Message 'Entry-point finding count differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
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
    Capability = 'MissingReferenceInterpretation'
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
$summaryPath = Join-Path $resolvedOutputRoot 'missing-reference-interpretation-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('MissingReferenceInterpretation tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
