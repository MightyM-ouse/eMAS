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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/declared-checksum-comparison/wave1-expectations.json'
}
$repositoryDiscoveryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$xmlInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$referenceInventoryModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1'
$referenceResolutionModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceResolution.psm1'
$missingInterpretationModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.MissingReferenceInterpretation.psm1'
$checksumModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.DeclaredChecksumComparison.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
Import-Module -Name $repositoryDiscoveryModulePath -Force -ErrorAction Stop
Import-Module -Name $xmlInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceInventoryModulePath -Force -ErrorAction Stop
Import-Module -Name $referenceResolutionModulePath -Force -ErrorAction Stop
Import-Module -Name $missingInterpretationModulePath -Force -ErrorAction Stop
Import-Module -Name $checksumModulePath -Force -ErrorAction Stop

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

function ConvertTo-eMASPreChecksumReferenceProjection {
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
            NormalizedTargetPath = $_.NormalizedTargetPath
            TargetFileId = $_.TargetFileId
            TargetExists = $_.TargetExists
            DeclaredChecksumAlgorithm = $_.DeclaredChecksumAlgorithm
            DeclaredChecksum = $_.DeclaredChecksum
            Operation = $_.Operation
            ModifiedFileRawPath = $_.ModifiedFileRawPath
            ResolutionStatus = $_.ResolutionStatus
            ResolutionDiagnosticCode = $_.ResolutionDiagnosticCode
            CaptureStatus = $_.CaptureStatus
        }
    }) | ConvertTo-Json -Depth 32 -Compress)
}

function ConvertTo-eMASChecksumProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([object[]]@($Result.References | ForEach-Object {
        [pscustomobject][ordered]@{
            ReferenceId = $_.ReferenceId
            DeclaredChecksumAlgorithm = $_.DeclaredChecksumAlgorithm
            DeclaredChecksum = $_.DeclaredChecksum
            CalculatedChecksum = $_.CalculatedChecksum
            ChecksumMatch = $_.ChecksumMatch
            ChecksumComparisonStatus = $_.ChecksumComparisonStatus
            ChecksumDiagnosticCode = $_.ChecksumDiagnosticCode
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

function New-eMASSyntheticChecksumInput {
    param(
        [Parameter(Mandatory = $true)][object] $State,
        [Parameter(Mandatory = $true)][string] $SourceRoot
    )

    $targetFileId = $(if ([string]$State.resolutionStatus -eq 'ResolvedPresent' -or [string]$State.resolutionStatus -eq 'AccessDenied') { 'FIL-0001' } else { $null })
    $normalizedTargetPath = $(if ([string]$State.resolutionStatus -eq 'NotApplicable') { $null } else { '0000/document.pdf' })
    $rawHref = $(if ([string]$State.resolutionStatus -eq 'NotApplicable') { $null } else { 'document.pdf' })
    return [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{
            ScenarioId = 'MS-04'
            Phase = 'PreSales'
            ExecutionId = 'EXEC-SYNTHETIC-CHECKSUM'
            ScannerName = 'SyntheticMissingReferenceInterpretation'
            ScannerVersion = '0.5.0'
            CompletedAtUtc = $null
            CompletionStatus = 'Completed'
            Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation')
        }
        Repository = [pscustomobject][ordered]@{
            RepositoryId = 'REP-0001'
            SourcePath = $SourceRoot
            ResolvedSourcePath = [System.IO.Path]::GetFullPath($SourceRoot)
            SourceKind = 'Directory'
            SourceSha256 = $null
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
            DeclaredChecksumAlgorithm = $State.declaredAlgorithm
            DeclaredChecksum = $State.declaredChecksum
            CalculatedChecksum = $null
            ChecksumMatch = $null
            Operation = $(if ([string]$State.resolutionStatus -eq 'NotApplicable') { 'delete' } else { 'new' })
            ModifiedFileRawPath = $null
            ResolutionStatus = $State.resolutionStatus
            ResolutionDiagnosticCode = $State.expectedDiagnostic
            CaptureStatus = $State.captureStatus
        })
        Files = [object[]]@([pscustomobject][ordered]@{
            FileId = 'FIL-0001'
            DossierId = 'DOS-0001'
            SequenceId = 'SEQ-0001'
            RelativePath = $(if (($State.PSObject.Properties.Name -contains 'fileRelativePath') -and -not [string]::IsNullOrWhiteSpace([string]$State.fileRelativePath)) { [string]$State.fileRelativePath } else { 'Synthetic/0000/document.pdf' })
            CaptureStatus = $(if ([string]$State.captureStatus -eq 'AccessDenied') { 'AccessDenied' } else { 'Available' })
        })
        LifecycleRelationships = [object[]]@()
        Observations = [object[]]@()
        ClassificationEvidence = [object[]]@()
        CollectionCoverage = [object[]]@(
            [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Reference'; SubjectId = 'REF-0001'; CaptureStatus = $State.captureStatus; RecordsProduced = 1; ReasonCode = $State.expectedDiagnostic },
            [pscustomobject][ordered]@{ CheckId = 'ReferenceResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; RecordsProduced = 1; ReasonCode = $null },
            [pscustomobject][ordered]@{ CheckId = 'MissingReferenceInterpretation'; SubjectType = 'Reference'; SubjectId = 'REF-0001'; CaptureStatus = $State.captureStatus; AssessmentStatus = 'NotAssessed'; RecordsProduced = 0; ReasonCode = $State.expectedDiagnostic },
            [pscustomobject][ordered]@{ CheckId = 'MissingReferenceInterpretation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'Available'; AssessmentStatus = 'Assessed'; RecordsProduced = 0; ReasonCode = $null },
            [pscustomobject][ordered]@{ CheckId = 'DeclaredChecksumComparison'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideMissingReferenceInterpretationScope' },
            [pscustomobject][ordered]@{ CheckId = 'FileReferenceOrphanCorrelation'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' },
            [pscustomobject][ordered]@{ CheckId = 'LifecycleLinkResolution'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = 'NotCollected'; RecordsProduced = 0; ReasonCode = 'OutsideReferenceResolutionScope' }
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
    $resultFileName = '{0}.declared-checksum-comparison.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null
    try {
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-DCC-{0}' -f $sampleId)
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery
        $inventory = Invoke-eMASReferenceInventory -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
        $resolution = Invoke-eMASReferenceResolution -SourcePath $state.Path -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory
        $interpretation = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution
        $referenceProjectionBefore = ConvertTo-eMASPreChecksumReferenceProjection -Result $interpretation
        $observationsBefore = @($interpretation.Observations) | ConvertTo-Json -Depth 64 -Compress
        $result = Invoke-eMASDeclaredChecksumComparison -SourcePath $state.Path -MissingReferenceInterpretationResult $interpretation -OutputPath $resultPath

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $referenceProjectionBefore -Actual (ConvertTo-eMASPreChecksumReferenceProjection -Result $result) -Message "$sampleId changed accepted raw or resolution evidence."
        Assert-eMASEqual -Expected $observationsBefore -Actual (@($result.Observations) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed or added assessment observations."
        Assert-eMASEqual -Expected (@($interpretation.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.LifecycleRelationships) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed lifecycle relationships."
        Assert-eMASEqual -Expected (@($interpretation.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Actual (@($result.ClassificationEvidence) | ConvertTo-Json -Depth 64 -Compress) -Message "$sampleId changed classification evidence."

        $matched = @($result.References | Where-Object { $_.ChecksumComparisonStatus -eq 'Matched' })
        $mismatched = @($result.References | Where-Object { $_.ChecksumComparisonStatus -eq 'Mismatched' })
        $notAssessed = @($result.References | Where-Object { $_.ChecksumComparisonStatus -eq 'NotAssessed' -or $_.ChecksumComparisonStatus -eq 'Unsupported' })
        $notApplicable = @($result.References | Where-Object { $_.ChecksumComparisonStatus -eq 'NotApplicable' })
        $applicable = @($matched + $mismatched)
        Assert-eMASEqual -Expected $fixtureExpectation.applicableCount -Actual $applicable.Count -Message "$sampleId applicable checksum count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.matchedCount -Actual $matched.Count -Message "$sampleId matched checksum count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.mismatchedCount -Actual $mismatched.Count -Message "$sampleId mismatched checksum count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.notAssessedCount -Actual $notAssessed.Count -Message "$sampleId not-assessed count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.notApplicableCount -Actual $notApplicable.Count -Message "$sampleId not-applicable count differs."

        foreach ($reference in $applicable) {
            Assert-eMASTrue -Condition ([string]$reference.CalculatedChecksum -match '^[0-9a-f]{32}$') -Message "$sampleId calculated checksum is not canonical lowercase MD5."
            Assert-eMASTrue -Condition ($reference.ChecksumMatch -is [bool]) -Message "$sampleId checksumMatch is not Boolean."
            Assert-eMASEqual -Expected $null -Actual $reference.ChecksumDiagnosticCode -Message "$sampleId successful comparison received a diagnostic."
        }
        foreach ($reference in @($notAssessed + $notApplicable)) {
            Assert-eMASEqual -Expected $null -Actual $reference.CalculatedChecksum -Message "$sampleId non-comparison received a calculated checksum."
            Assert-eMASEqual -Expected $null -Actual $reference.ChecksumMatch -Message "$sampleId non-comparison became a false mismatch."
        }
        foreach ($code in @($expectations.prohibitedObservationCodes)) {
            Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq $code }).Count -Message "$sampleId emitted prohibited observation $code."
        }

        $expectedMismatches = @($expectations.expectedMismatches | Where-Object { $_.sampleId -eq $sampleId })
        Assert-eMASEqual -Expected $expectedMismatches.Count -Actual $mismatched.Count -Message "$sampleId exact mismatch expectation differs."
        foreach ($expected in $expectedMismatches) {
            $match = @($mismatched | Where-Object { $_.ReferenceId -eq $expected.referenceId })
            Assert-eMASEqual -Expected 1 -Actual $match.Count -Message "$sampleId omitted or duplicated expected mismatch."
            Assert-eMASEqual -Expected $expected.declaredChecksumAlgorithm -Actual $match[0].DeclaredChecksumAlgorithm -Message "$sampleId declared algorithm changed."
            Assert-eMASEqual -Expected $expected.declaredChecksum -Actual $match[0].DeclaredChecksum -Message "$sampleId declared checksum changed."
            Assert-eMASEqual -Expected $expected.calculatedChecksum -Actual $match[0].CalculatedChecksum -Message "$sampleId calculated checksum differs."
            Assert-eMASEqual -Expected $expected.normalizedTargetPath -Actual $match[0].NormalizedTargetPath -Message "$sampleId mismatch target differs."
            Assert-eMASEqual -Expected $false -Actual $match[0].ChecksumMatch -Message "$sampleId mismatch Boolean differs."
        }

        $expectedUnavailable = @($expectations.expectedUnavailableTargets | Where-Object { $_.sampleId -eq $sampleId })
        foreach ($expected in $expectedUnavailable) {
            $match = @($result.References | Where-Object { $_.ReferenceId -eq $expected.referenceId })
            Assert-eMASEqual -Expected 1 -Actual $match.Count -Message "$sampleId unavailable target was not unique."
            Assert-eMASEqual -Expected $expected.status -Actual $match[0].ChecksumComparisonStatus -Message "$sampleId unavailable target status differs."
            Assert-eMASEqual -Expected $expected.diagnosticCode -Actual $match[0].ChecksumDiagnosticCode -Message "$sampleId unavailable target diagnostic differs."
            Assert-eMASEqual -Expected $null -Actual $match[0].CalculatedChecksum -Message "$sampleId unavailable target was hashed."
            Assert-eMASEqual -Expected $null -Actual $match[0].ChecksumMatch -Message "$sampleId unavailable target became a mismatch."
        }

        foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
            $futureCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
            Assert-eMASEqual -Expected 1 -Actual $futureCoverage.Count -Message "$sampleId deferred coverage count differs for $checkId."
            Assert-eMASEqual -Expected 'NotCollected' -Actual $futureCoverage[0].CaptureStatus -Message "$sampleId completed deferred capability $checkId."
        }
        $perReferenceCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'DeclaredChecksumComparison' -and $_.SubjectType -eq 'Reference' })
        $repositoryCoverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'DeclaredChecksumComparison' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected @($result.References).Count -Actual $perReferenceCoverage.Count -Message "$sampleId per-reference checksum coverage differs."
        Assert-eMASEqual -Expected 1 -Actual $repositoryCoverage.Count -Message "$sampleId repository checksum coverage differs."
        Assert-eMASEqual -Expected $applicable.Count -Actual $repositoryCoverage[0].RecordsProduced -Message "$sampleId repository checksum record count differs."
        $expectedCollectionStatus = $(if ($fixtureExpectation.notAssessedCount -gt 0) { 'Partial' } else { 'Collected' })
        Assert-eMASEqual -Expected $expectedCollectionStatus -Actual $repositoryCoverage[0].ComparisonStatus -Message "$sampleId repository comparison status differs."

        $repeat = Invoke-eMASDeclaredChecksumComparison -SourcePath $state.Path -MissingReferenceInterpretationResult $interpretation
        Assert-eMASEqual -Expected (ConvertTo-eMASChecksumProjection -Result $result) -Actual (ConvertTo-eMASChecksumProjection -Result $repeat) -Message "$sampleId deterministic checksum projection differs."

        $resultBySample[$sampleId] = $result
        $actualSummary = [pscustomobject][ordered]@{
            ApplicableChecksumCount = $applicable.Count
            MatchedCount = $matched.Count
            MismatchedCount = $mismatched.Count
            NotAssessedCount = $notAssessed.Count
            NotApplicableCount = $notApplicable.Count
        }
        Write-Output ('[PASS] {0} DeclaredChecksumComparison acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = [pscustomobject][ordered]@{
            ApplicableChecksumCount = $fixtureExpectation.applicableCount
            MatchedCount = $fixtureExpectation.matchedCount
            MismatchedCount = $fixtureExpectation.mismatchedCount
            NotAssessedCount = $fixtureExpectation.notAssessedCount
            NotApplicableCount = $fixtureExpectation.notApplicableCount
        }
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'SD-004 has exactly one factual checksum mismatch and no finding' -Action {
    $result = $resultBySample['SD-004']
    $mismatch = @($result.References | Where-Object { $_.ChecksumComparisonStatus -eq 'Mismatched' })
    Assert-eMASEqual -Expected 1 -Actual $mismatch.Count -Message 'SD-004 mismatch count differs.'
    Assert-eMASEqual -Expected 'REF-0094' -Actual $mismatch[0].ReferenceId -Message 'SD-004 mismatch reference differs.'
    Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq 'DeclaredChecksumMismatch' }).Count -Message 'SD-004 emitted a mismatch finding.'
}

Invoke-eMASRecordedCheck -Name 'SD-018 hashes the present zero-byte target without interpreting it' -Action {
    $result = $resultBySample['SD-018']
    $reference = @($result.References | Where-Object { $_.ReferenceId -eq 'REF-0094' })[0]
    Assert-eMASEqual -Expected $true -Actual $reference.TargetExists -Message 'SD-018 target is no longer present.'
    Assert-eMASEqual -Expected 'd41d8cd98f00b204e9800998ecf8427e' -Actual $reference.CalculatedChecksum -Message 'SD-018 empty-file MD5 differs.'
    Assert-eMASEqual -Expected $false -Actual $reference.ChecksumMatch -Message 'SD-018 comparison result differs.'
    Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq 'ZeroByteFile' -or $_.Code -eq 'DeclaredChecksumMismatch' }).Count -Message 'SD-018 emitted a prohibited interpretation.'
}

Invoke-eMASRecordedCheck -Name 'Absent targets in SD-003 and SD-006 are NotApplicable, not hashed, not mismatched, and not a collection gap' -Action {
    foreach ($expected in @($expectations.expectedUnavailableTargets)) {
        $reference = @($resultBySample[[string]$expected.sampleId].References | Where-Object { $_.ReferenceId -eq $expected.referenceId })[0]
        Assert-eMASEqual -Expected $false -Actual $reference.TargetExists -Message "$($expected.sampleId) target existence differs."
        Assert-eMASEqual -Expected $null -Actual $reference.CalculatedChecksum -Message "$($expected.sampleId) absent target was hashed."
        Assert-eMASEqual -Expected $null -Actual $reference.ChecksumMatch -Message "$($expected.sampleId) absent target became mismatch."
        Assert-eMASEqual -Expected 'NotApplicable' -Actual $reference.ChecksumComparisonStatus -Message "$($expected.sampleId) absent target is not NotApplicable."
        Assert-eMASEqual -Expected 'TargetAbsent' -Actual $reference.ChecksumDiagnosticCode -Message "$($expected.sampleId) absent target diagnostic differs."
        $repositoryCoverage = @($resultBySample[[string]$expected.sampleId].CollectionCoverage | Where-Object { $_.CheckId -eq 'DeclaredChecksumComparison' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected 'Collected' -Actual $repositoryCoverage[0].ComparisonStatus -Message "$($expected.sampleId) absent target caused a checksum collection gap."
        Assert-eMASEqual -Expected 'Completed' -Actual $resultBySample[[string]$expected.sampleId].Execution.CompletionStatus -Message "$($expected.sampleId) absent target changed completion status."
    }
}

Invoke-eMASRecordedCheck -Name 'No-href delete REF-0073 remains checksum NotApplicable' -Action {
    $expected = $expectations.notApplicableReference
    $reference = @($resultBySample[[string]$expected.sampleId].References | Where-Object { $_.ReferenceId -eq $expected.referenceId })[0]
    Assert-eMASEqual -Expected $expected.status -Actual $reference.ChecksumComparisonStatus -Message 'No-href checksum status differs.'
    Assert-eMASEqual -Expected $expected.diagnosticCode -Actual $reference.ChecksumDiagnosticCode -Message 'No-href checksum diagnostic differs.'
    Assert-eMASEqual -Expected $null -Actual $reference.CalculatedChecksum -Message 'No-href reference was hashed.'
    Assert-eMASEqual -Expected $null -Actual $reference.ChecksumMatch -Message 'No-href reference became mismatch.'
}

foreach ($pair in @($expectations.invariancePairs)) {
    Invoke-eMASRecordedCheck -Name ("Declared checksum comparison invariant: {0} vs {1}" -f $pair.baseline, $pair.comparison) -Action {
        Assert-eMASEqual -Expected (ConvertTo-eMASChecksumProjection -Result $resultBySample[[string]$pair.baseline]) -Actual (ConvertTo-eMASChecksumProjection -Result $resultBySample[[string]$pair.comparison]) -Message "$($pair.comparison) checksum projection differs from $($pair.baseline)."
    }
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP checksum evidence is equivalent for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-checksum-directory-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-DCC-SD-002-DIRECTORY'
        $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $directorySource -RepositoryDiscoveryResult $discovery
        $inventory = Invoke-eMASReferenceInventory -SourcePath $directorySource -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
        $resolution = Invoke-eMASReferenceResolution -SourcePath $directorySource -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory
        $interpretation = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution
        $directoryResult = Invoke-eMASDeclaredChecksumComparison -SourcePath $directorySource -MissingReferenceInterpretationResult $interpretation
        Assert-eMASEqual -Expected (ConvertTo-eMASChecksumProjection -Result $resultBySample['SD-002']) -Actual (ConvertTo-eMASChecksumProjection -Result $directoryResult) -Message 'Directory checksum evidence differs from ZIP.'
        Assert-eMASTrue -Condition ((ConvertTo-eMASChecksumProjection -Result $directoryResult) -notlike "*$temporaryRoot*") -Message 'Temporary directory path leaked into checksum evidence.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

foreach ($state in @($expectations.syntheticStates)) {
    Invoke-eMASRecordedCheck -Name ("Synthetic checksum state: {0}" -f $state.name) -Action {
        $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-checksum-synthetic-{0}' -f [guid]::NewGuid().ToString('N'))
        try {
            [void][System.IO.Directory]::CreateDirectory($temporaryRoot)
            $syntheticSourceRoot = Join-Path $temporaryRoot 'source'
            [void][System.IO.Directory]::CreateDirectory($syntheticSourceRoot)
            [System.IO.File]::WriteAllBytes((Join-Path $temporaryRoot 'outside.pdf'), [byte[]]@())
            $input = New-eMASSyntheticChecksumInput -State $state -SourceRoot $syntheticSourceRoot
            $result = Invoke-eMASDeclaredChecksumComparison -SourcePath $syntheticSourceRoot -MissingReferenceInterpretationResult $input
            $reference = $result.References[0]
            Assert-eMASEqual -Expected $state.expectedStatus -Actual $reference.ChecksumComparisonStatus -Message "$($state.name) comparison status differs."
            Assert-eMASEqual -Expected $state.expectedDiagnostic -Actual $reference.ChecksumDiagnosticCode -Message "$($state.name) diagnostic differs."
            Assert-eMASEqual -Expected $null -Actual $reference.CalculatedChecksum -Message "$($state.name) unexpectedly calculated a checksum."
            Assert-eMASEqual -Expected $null -Actual $reference.ChecksumMatch -Message "$($state.name) became a false mismatch."
        }
        finally {
            if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
        }
    }
}

Invoke-eMASRecordedCheck -Name 'Checksum module uses accepted target identity and contains no XML network or interpretation logic' -Action {
    $moduleText = [System.IO.File]::ReadAllText($checksumModulePath)
    foreach ($prohibitedPattern in @('System\.Xml', 'XmlReader', 'SelectNodes', 'Invoke-WebRequest', 'WebClient', 'HttpClient', 'Resolve-eMASReferencePath', 'DeclaredChecksumMismatch', 'FND-CHECKSUM', '\bRAG\b', '\bSeverity\b', '\bRecommendation\b')) {
        Assert-eMASTrue -Condition ($moduleText -notmatch $prohibitedPattern) -Message "Checksum module contains prohibited implementation pattern $prohibitedPattern."
    }
    Assert-eMASTrue -Condition ($moduleText -match 'TargetFileId') -Message 'Checksum module does not use accepted target identity.'
    Assert-eMASTrue -Condition ($moduleText -match '\$file\.RelativePath') -Message 'Checksum module does not open the accepted file observation path.'
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes DeclaredChecksumComparison' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-004-entrypoint.declared-checksum-comparison.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-004'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-DCC-ENTRYPOINT' `
        -IncludeDeclaredChecksumComparison
    Assert-eMASEqual -Expected 1 -Actual @($entryResult.References | Where-Object { $_.ChecksumComparisonStatus -eq 'Mismatched' }).Count -Message 'Entry-point mismatch count differs.'
    Assert-eMASEqual -Expected 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation+DeclaredChecksumComparison' -Actual $entryResult.Execution.ScannerName -Message 'Entry-point scanner identity differs.'
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
    Capability = 'DeclaredChecksumComparison'
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
$summaryPath = Join-Path $resolvedOutputRoot 'declared-checksum-comparison-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('DeclaredChecksumComparison tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
