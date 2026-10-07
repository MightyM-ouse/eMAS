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
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/classification-evidence-collection/wave1-expectations.json'
}
foreach ($name in @('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation', 'DeclaredChecksumComparison', 'ChecksumMismatchInterpretation', 'ClassificationEvidenceCollection')) {
    Import-Module -Name (Join-Path $repositoryRoot ("engine/powershell51/eMAS.{0}.psm1" -f $name)) -Force -ErrorAction Stop
}
$collectionModulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'

$resolvedCorpusRoot = [System.IO.Path]::GetFullPath($CorpusRoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$wave1ERoot = Join-Path $repositoryRoot 'tests/fixtures/repository-discovery-ectd4/wave1e'
$wave1EManifestPath = Join-Path $wave1ERoot 'WAVE1E_FREEZE_MANIFEST.csv'
$resultRoot = Join-Path $resolvedOutputRoot 'results'
[void][System.IO.Directory]::CreateDirectory($resultRoot)

$startedAtUtc = [DateTime]::UtcNow
$manifestRows = @(Import-Csv -LiteralPath $FreezeManifestPath)
$expectations = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($ExpectationsPath)) | ConvertFrom-Json
$sourceState = @{}
$fixtureResults = New-Object System.Collections.ArrayList
$additionalResults = New-Object System.Collections.ArrayList
$resultBySample = @{}
$inputBySample = @{}
$frozenBeforeVerified = 0
$frozenAfterVerified = 0
$wave1EState = @{}
$wave1EFrozenBeforeVerified = 0
$wave1EFrozenAfterVerified = 0
$newPhysicalMarkerEvidenceTypes = @(
    'RegulatoryUnitKind',
    'SubmissionUnitMarkerFile',
    'TocFileMarker',
    'ChecksumFileMarker',
    'UtilityDtdFolderMarker'
)
$newRegionalEnvelopeEvidenceTypes = @(
    'EuEnvelopeCountry',
    'EuAgencyCode',
    'EuProcedureType',
    'EuSubmissionType',
    'EuSubmissionUnitType'
)
$allAdditiveEvidenceTypes = @($newPhysicalMarkerEvidenceTypes + $newRegionalEnvelopeEvidenceTypes)

function Get-eMASTestSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Assert-eMASTrue { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMASEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Write-eMASTestJson {
    param([Parameter(Mandatory = $true)][object] $Value, [Parameter(Mandatory = $true)][string] $Path)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 64), $encoding)
}
function ConvertTo-eMASJsonText { param([AllowNull()][object] $Value) return ([object[]]@($Value) | ConvertTo-Json -Depth 64 -Compress) }

function ConvertTo-eMASRecordKey {
    param([string] $Type, [string] $Dimension, [string] $Strength, [string] $Tier, [AllowNull()][object] $SequenceFolder, [AllowNull()][object] $XmlPath, [AllowNull()][object] $ObservedValue)
    $value = $(if ($ObservedValue -is [System.Array]) { ,([object[]]$ObservedValue) } else { $ObservedValue })
    return ([pscustomobject][ordered]@{ t = $Type; d = $Dimension; s = $Strength; r = $Tier; f = $SequenceFolder; x = $XmlPath; v = $value } | ConvertTo-Json -Depth 8 -Compress)
}

function Get-eMASSortedOrdinal {
    param([string[]] $Values)
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($value in @($Values)) { $list.Add($value) }
    $list.Sort([System.StringComparer]::Ordinal)
    return ($list.ToArray() -join "`n")
}

function ConvertTo-eMASDossierRelativeProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ConvertTo-eMASJsonText ([object[]]@($Result.ClassificationEvidence | Where-Object { $_.EvidenceType -ne 'DossierRootPath' -and $allAdditiveEvidenceTypes -notcontains $_.EvidenceType } | ForEach-Object {
        [pscustomobject][ordered]@{ EvidenceType = $_.EvidenceType; Dimension = $_.Dimension; Strength = $_.Strength; SourceTier = $_.SourceTier; SequenceFolder = $_.SequenceFolder; SequenceRelativePath = $_.SequenceRelativePath; ObservedValue = $_.ObservedValue; CaptureStatus = $_.CaptureStatus; XmlId = $_.XmlId; SequenceId = $_.SequenceId }
    }))
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

function Invoke-eMASAcceptedChain {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [Parameter(Mandatory = $true)][string] $ExecutionId)
    $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $SourcePath -ExecutionId $ExecutionId
    $xmlResult = Invoke-eMASBackboneXmlInventory -SourcePath $SourcePath -RepositoryDiscoveryResult $discovery
    $inventory = Invoke-eMASReferenceInventory -SourcePath $SourcePath -RepositoryDiscoveryResult $discovery -BackboneXmlInventoryResult $xmlResult
    $resolution = Invoke-eMASReferenceResolution -SourcePath $SourcePath -RepositoryDiscoveryResult $discovery -ReferenceInventoryResult $inventory
    $missing = Invoke-eMASMissingReferenceInterpretation -ReferenceResolutionResult $resolution
    $comparison = Invoke-eMASDeclaredChecksumComparison -SourcePath $SourcePath -MissingReferenceInterpretationResult $missing
    return (Invoke-eMASChecksumMismatchInterpretation -DeclaredChecksumComparisonResult $comparison)
}

function Copy-eMASResult { param([Parameter(Mandatory = $true)][object] $Result) return (($Result | ConvertTo-Json -Depth 64) | ConvertFrom-Json) }

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

foreach ($manifestRow in @(Import-Csv -LiteralPath $wave1EManifestPath)) {
    $fixturePath = Join-Path $wave1ERoot ($manifestRow.FixtureFilename -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not [System.IO.File]::Exists($fixturePath)) { throw ('FREEZE-VERIFY-005 Wave1E fixture is missing: {0}' -f $manifestRow.SampleId) }
    $actualHash = Get-eMASTestSha256 -Path $fixturePath
    if ($actualHash -ne $manifestRow.FixtureSHA256) { throw ('FREEZE-VERIFY-006 Wave1E fixture hash mismatch: {0}' -f $manifestRow.SampleId) }
    $wave1EState[$manifestRow.SampleId] = [pscustomobject]@{ Path = $fixturePath; Hash = $actualHash; LastWriteTimeUtc = (New-Object System.IO.FileInfo($fixturePath)).LastWriteTimeUtc }
    $wave1EFrozenBeforeVerified++
}
Write-Output ('[PASS] Pre-test Wave1E freeze gate verified {0} ZIP fixtures.' -f $wave1EFrozenBeforeVerified)

$unchangedCollections = @('Repository', 'DossierCandidates', 'Sequences', 'XmlDocuments', 'References', 'Files', 'LifecycleRelationships', 'Observations')
foreach ($fixtureExpectation in @($expectations.fixtures)) {
    $sampleId = [string]$fixtureExpectation.sampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.classification-evidence-collection.json' -f $sampleId
    $status = 'PASS'; $detail = $null; $actualSummary = $null
    try {
        $inputResult = Invoke-eMASAcceptedChain -SourcePath $state.Path -ExecutionId ('EXEC-CEC-{0}' -f $sampleId)
        $before = @{}
        foreach ($collection in $unchangedCollections) { $before[$collection] = ConvertTo-eMASJsonText $inputResult.$collection }
        $otherCoverageBefore = ConvertTo-eMASJsonText ([object[]]@($inputResult.CollectionCoverage | Where-Object { $_.CheckId -ne 'ClassificationEvidenceCollection' -and $_.CheckId -notlike 'RegionalEnvelopeField:*' }))
        $result = Invoke-eMASClassificationEvidenceCollection -InputResult $inputResult -OutputPath (Join-Path $resultRoot $resultFileName)

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        foreach ($collection in $unchangedCollections) {
            Assert-eMASEqual -Expected $before[$collection] -Actual (ConvertTo-eMASJsonText $result.$collection) -Message "$sampleId changed accepted $collection evidence."
        }
        Assert-eMASEqual -Expected $otherCoverageBefore -Actual (ConvertTo-eMASJsonText ([object[]]@($result.CollectionCoverage | Where-Object { $_.CheckId -ne 'ClassificationEvidenceCollection' -and $_.CheckId -notlike 'RegionalEnvelopeField:*' }))) -Message "$sampleId changed upstream coverage."

        $records = @($result.ClassificationEvidence)
        $historicalRecords = @($records | Where-Object { $allAdditiveEvidenceTypes -notcontains $_.EvidenceType })
        Assert-eMASEqual -Expected $fixtureExpectation.expectedRecordCount -Actual $historicalRecords.Count -Message "$sampleId historical record count differs."
        $actualKeys = [string[]]@($historicalRecords | ForEach-Object { ConvertTo-eMASRecordKey $_.EvidenceType $_.Dimension $_.Strength $_.SourceTier $_.SequenceFolder $_.SequenceRelativePath $_.ObservedValue })
        $expectedKeys = [string[]]@($fixtureExpectation.records | ForEach-Object { ConvertTo-eMASRecordKey $_.evidenceType $_.dimension $_.strength $_.sourceTier $_.sequenceFolder $_.xmlSequenceRelativePath $_.observedValue })
        Assert-eMASEqual -Expected (Get-eMASSortedOrdinal $expectedKeys) -Actual (Get-eMASSortedOrdinal $actualKeys) -Message "$sampleId evidence records differ from independent expectations."
        foreach ($property in @($fixtureExpectation.countsByType.PSObject.Properties)) {
            Assert-eMASEqual -Expected ([int]$property.Value) -Actual @($historicalRecords | Where-Object { $_.EvidenceType -eq $property.Name }).Count -Message "$sampleId count differs for $($property.Name)."
        }
        foreach ($property in @($fixtureExpectation.countsByDimension.PSObject.Properties)) {
            Assert-eMASEqual -Expected ([int]$property.Value) -Actual @($historicalRecords | Where-Object { $_.Dimension -eq $property.Name }).Count -Message "$sampleId historical count differs for dimension $($property.Name)."
        }

        $xmlById = @{}; foreach ($xml in @($result.XmlDocuments)) { $xmlById[[string]$xml.XmlId] = $xml }
        $sequenceIds = @($result.Sequences | ForEach-Object { [string]$_.SequenceId })
        for ($index = 0; $index -lt $records.Count; $index++) {
            $record = $records[$index]
            Assert-eMASEqual -Expected ('EVD-{0:D4}' -f ($index + 1)) -Actual $record.EvidenceId -Message "$sampleId evidence identity/order differs."
            foreach ($nullField in @($expectations.nullFields)) { Assert-eMASEqual -Expected $null -Actual $record.$nullField -Message "$sampleId $nullField was populated." }
            foreach ($forbidden in @($expectations.prohibitedRecordFields)) { Assert-eMASTrue -Condition (@($record.PSObject.Properties.Name) -notcontains [string]$forbidden) -Message "$sampleId record carries prohibited field $forbidden." }
            if ($null -ne $record.XmlId) {
                Assert-eMASTrue -Condition $xmlById.ContainsKey([string]$record.XmlId) -Message "$sampleId XmlId not traceable."
                Assert-eMASEqual -Expected $xmlById[[string]$record.XmlId].RelativePath -Actual $record.RelativePath -Message "$sampleId XML evidence path not traceable."
            }
            if ($null -ne $record.SequenceId) { Assert-eMASTrue -Condition ($sequenceIds -contains [string]$record.SequenceId) -Message "$sampleId SequenceId not traceable." }
        }

        foreach ($expectedXml in @($fixtureExpectation.xmlCoverage)) {
            $xml = @($result.XmlDocuments | Where-Object { $_.SequenceId -ne $null -and $_.RelativePath.EndsWith('/' + $expectedXml.sequenceFolder + '/' + $expectedXml.xmlSequenceRelativePath, [System.StringComparison]::Ordinal) })
            Assert-eMASEqual -Expected 1 -Actual $xml.Count -Message "$sampleId XML for coverage not unique."
            $row = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'XmlDocument' -and $_.SubjectId -eq $xml[0].XmlId })
            Assert-eMASEqual -Expected 1 -Actual $row.Count -Message "$sampleId per-XML coverage count differs."
            Assert-eMASEqual -Expected $expectedXml.captureStatus -Actual $row[0].CaptureStatus -Message "$sampleId per-XML capture status differs."
            Assert-eMASEqual -Expected $expectedXml.collectionStatus -Actual $row[0].CollectionStatus -Message "$sampleId per-XML collection status differs."
            Assert-eMASEqual -Expected $expectedXml.structuredRecords -Actual @($historicalRecords | Where-Object { $_.XmlId -eq $xml[0].XmlId -and ($_.SourceTier -eq 'StructuredXml' -or $_.SourceTier -eq 'BackboneDeclaration') }).Count -Message "$sampleId historical structured record count differs for $($expectedXml.xmlSequenceRelativePath)."
        }
        $repository = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASEqual -Expected 1 -Actual $repository.Count -Message "$sampleId repository coverage count differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedRepositoryCollectionStatus -Actual $repository[0].CollectionStatus -Message "$sampleId repository collection status differs."
        Assert-eMASEqual -Expected $records.Count -Actual $repository[0].RecordsProduced -Message "$sampleId repository records produced differs."
        Assert-eMASEqual -Expected $fixtureExpectation.expectedCompletionStatus -Actual $result.Execution.CompletionStatus -Message "$sampleId completion status differs."
        foreach ($checkId in @($expectations.mustRemainNotCollectedCoverage)) {
            $deferred = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $checkId })
            Assert-eMASEqual -Expected 1 -Actual $deferred.Count -Message "$sampleId deferred coverage differs for $checkId."
            Assert-eMASEqual -Expected 'NotCollected' -Actual $deferred[0].CaptureStatus -Message "$sampleId completed deferred capability $checkId."
        }
        foreach ($capability in @($expectations.prohibitedCapabilities)) {
            Assert-eMASTrue -Condition (@($result.Execution.Capabilities) -notcontains [string]$capability) -Message "$sampleId declares $capability."
            Assert-eMASEqual -Expected 0 -Actual @($result.CollectionCoverage | Where-Object { $_.CheckId -eq $capability }).Count -Message "$sampleId has coverage for $capability."
        }
        foreach ($code in @($expectations.prohibitedObservationCodes)) { Assert-eMASEqual -Expected 0 -Actual @($result.Observations | Where-Object { $_.Code -eq $code }).Count -Message "$sampleId emitted $code." }
        Assert-eMASEqual -Expected 'ClassificationEvidenceCollection' -Actual @($result.Execution.Capabilities)[-1] -Message "$sampleId capability declaration differs."

        $repeat = Invoke-eMASClassificationEvidenceCollection -InputResult $inputResult
        Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $result.ClassificationEvidence) -Actual (ConvertTo-eMASJsonText $repeat.ClassificationEvidence) -Message "$sampleId evidence is not deterministic."
        Assert-eMASEqual -Expected (ConvertTo-eMASJsonText ([object[]]@($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' }))) -Actual (ConvertTo-eMASJsonText ([object[]]@($repeat.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' }))) -Message "$sampleId coverage is not deterministic."

        $resultBySample[$sampleId] = $result
        $inputBySample[$sampleId] = $inputResult
        $byDimension = [ordered]@{}; foreach ($group in @($records | Group-Object -Property Dimension | Sort-Object Name)) { $byDimension[$group.Name] = $group.Count }
        $newByType = [ordered]@{}; foreach ($group in @($records | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType } | Group-Object -Property EvidenceType | Sort-Object Name)) { $newByType[$group.Name] = $group.Count }
        $actualSummary = [pscustomobject][ordered]@{ RecordCount = $records.Count; HistoricalRecordCount = $historicalRecords.Count; NewPhysicalMarkerCountsByType = [pscustomobject]$newByType; CountsByDimension = [pscustomobject]$byDimension; RepositoryCollectionStatus = $repository[0].CollectionStatus; CompletionStatus = $result.Execution.CompletionStatus }
        Write-Output ('[PASS] {0} ClassificationEvidenceCollection acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'; $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }
    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = [pscustomobject][ordered]@{ RecordCount = $fixtureExpectation.expectedRecordCount; CountsByDimension = $fixtureExpectation.countsByDimension; CountsByType = $fixtureExpectation.countsByType; RepositoryCollectionStatus = $fixtureExpectation.expectedRepositoryCollectionStatus; CompletionStatus = $fixtureExpectation.expectedCompletionStatus }
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

$v4ResultBySample = @{}
foreach ($sampleId in @('SD-053', 'SD-063', 'SD-069', 'SD-073')) {
    Invoke-eMASRecordedCheck -Name ("{0} physical-marker evidence can be collected from accepted Wave1E discovery" -f $sampleId) -Action {
        $input = Invoke-eMASAcceptedChain -SourcePath $wave1EState[$sampleId].Path -ExecutionId ("EXEC-CEC-MARKER-{0}" -f $sampleId)
        $v4ResultBySample[$sampleId] = Invoke-eMASClassificationEvidenceCollection -InputResult $input
        Write-eMASTestJson -Value $v4ResultBySample[$sampleId] -Path (Join-Path $resultRoot ("{0}.physical-marker-evidence.json" -f $sampleId))
        Assert-eMASTrue -Condition (@($v4ResultBySample[$sampleId].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType }).Count -gt 0) -Message 'No new physical-marker evidence was produced.'
    }
}

Invoke-eMASRecordedCheck -Name 'v3 sequence records unit kind, direct index-md5 marker and exact util/dtd relationship' -Action {
    $records = @($resultBySample['SD-002'].ClassificationEvidence)
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'NumericSequenceDirectory' -and $_.Strength -eq 'Weak' }).Count -Message 'v3 unit-kind evidence differs.'
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'ChecksumFileMarker' -and $_.ObservedValue -eq 'index-md5.txt' }).Count -Message 'v3 checksum marker evidence differs.'
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'UtilityDtdFolderMarker' -and $_.ObservedValue -eq 'util/dtd' }).Count -Message 'v3 util/dtd marker evidence differs.'
}

Invoke-eMASRecordedCheck -Name 'clean v4 submission unit records direct submissionunit.xml and sha256.txt markers' -Action {
    $records = @($v4ResultBySample['SD-053'].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'SubmissionUnitFolder' }).Count -Message 'Clean v4 unit kind differs.'
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'SubmissionUnitMarkerFile' -and $_.ObservedValue -eq 'submissionunit.xml' }).Count -Message 'Clean v4 submission marker differs.'
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'ChecksumFileMarker' -and $_.ObservedValue -eq 'sha256.txt' }).Count -Message 'Clean v4 checksum marker differs.'
}

Invoke-eMASRecordedCheck -Name 'damaged v4-like unit records sha256.txt without manufacturing submissionunit.xml' -Action {
    $records = @($v4ResultBySample['SD-063'].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'DamagedSubmissionUnitCandidate' }).Count -Message 'Damaged v4 unit kind differs.'
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'ChecksumFileMarker' -and $_.ObservedValue -eq 'sha256.txt' }).Count -Message 'Damaged v4 checksum marker differs.'
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.EvidenceType -eq 'SubmissionUnitMarkerFile' }).Count -Message 'Missing submission marker became evidence.'
}

Invoke-eMASRecordedCheck -Name 'ambiguous unit preserves both-backbone unit kind and only its direct submission marker' -Action {
    $records = @($v4ResultBySample['SD-073'].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'AmbiguousRegulatoryUnitFolder' -and $_.RelativePath -eq 'Pkg2/0001' }).Count -Message 'Ambiguous unit kind differs.'
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'SubmissionUnitMarkerFile' -and $_.RelativePath -eq 'Pkg2/0001/submissionunit.xml' }).Count -Message 'Ambiguous direct submission marker differs.'
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.RelativePath -like 'Pkg/1234567/*' }).Count -Message 'Out-of-range marker leaked to accepted unit.'
}

$syntheticMarkerState = @{}
Invoke-eMASRecordedCheck -Name 'NeeS-like sequence records only source-backed direct TOC names and exact util/dtd marker' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-cec-marker-{0}' -f [guid]::NewGuid().ToString('N'))
    try {
        foreach ($directory in @('Package/0001/m1', 'Package/0001/m2', 'Package/0001/util/DTD')) {
            [void][System.IO.Directory]::CreateDirectory((Join-Path $temporaryRoot $directory))
        }
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        foreach ($relativePath in @('Package/0001/ctd-toc.pdf', 'Package/0001/M1-TOC.PDF', 'Package/0001/random.pdf', 'Package/0001/m2/sha256.txt', 'Package/submissionunit.xml')) {
            [System.IO.File]::WriteAllText((Join-Path $temporaryRoot $relativePath), 'synthetic test-local marker', $utf8)
        }
        $discovery = Invoke-eMASRepositoryDiscovery -SourcePath $temporaryRoot -ExecutionId 'EXEC-CEC-SYNTHETIC-MARKERS'
        $input = Invoke-eMASBackboneXmlInventory -SourcePath $temporaryRoot -RepositoryDiscoveryResult $discovery
        $syntheticMarkerState['Result'] = Invoke-eMASClassificationEvidenceCollection -InputResult $input
        Write-eMASTestJson -Value $syntheticMarkerState['Result'] -Path (Join-Path $resultRoot 'synthetic-nees-physical-marker-evidence.json')
        $records = @($syntheticMarkerState['Result'].ClassificationEvidence)
        Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'TocFileMarker' -and $_.ObservedValue -ceq 'ctd-toc.pdf' }).Count -Message 'ctd-toc.pdf evidence differs.'
        Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'TocFileMarker' -and $_.ObservedValue -ceq 'M1-TOC.PDF' }).Count -Message 'Module TOC evidence differs.'
        Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'UtilityDtdFolderMarker' -and $_.ObservedValue -eq 'util/DTD' }).Count -Message 'Exact direct util/DTD evidence differs.'
    }
    finally { if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) } }
}

Invoke-eMASRecordedCheck -Name 'random PDF never becomes TOC evidence' -Action {
    Assert-eMASEqual -Expected 0 -Actual @($syntheticMarkerState['Result'].ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'TocFileMarker' -and $_.ObservedValue -eq 'random.pdf' }).Count -Message 'Random PDF became TOC evidence.'
}

Invoke-eMASRecordedCheck -Name 'wrapper and nested file markers do not leak into sequence evidence' -Action {
    $records = @($syntheticMarkerState['Result'].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.RelativePath -eq 'Package/submissionunit.xml' }).Count -Message 'Wrapper marker leaked.'
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.RelativePath -eq 'Package/0001/m2/sha256.txt' }).Count -Message 'Nested marker leaked.'
}

Invoke-eMASRecordedCheck -Name 'mixed v3/v4 container preserves evidence ownership per regulatory unit' -Action {
    $records = @($v4ResultBySample['SD-069'].ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 2 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'NumericSequenceDirectory' }).Count -Message 'Mixed v3 units differ.'
    Assert-eMASEqual -Expected 1 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.ObservedValue -eq 'SubmissionUnitFolder' }).Count -Message 'Mixed v4 unit differs.'
    $submission = @($records | Where-Object { $_.EvidenceType -eq 'SubmissionUnitMarkerFile' })
    $checksum = @($records | Where-Object { $_.EvidenceType -eq 'ChecksumFileMarker' })
    Assert-eMASEqual -Expected 1 -Actual $submission.Count -Message 'Mixed submission marker count differs.'
    Assert-eMASEqual -Expected '4' -Actual $submission[0].SequenceFolder -Message 'Submission marker assigned to wrong unit folder.'
    Assert-eMASEqual -Expected 'App/4/submissionunit.xml' -Actual $submission[0].RelativePath -Message 'Submission marker path differs.'
    Assert-eMASEqual -Expected $submission[0].SequenceId -Actual $checksum[0].SequenceId -Message 'v4 markers do not share unit ownership.'
}

Invoke-eMASRecordedCheck -Name 'partial inventory does not manufacture false marker absence' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $firstSequence = @($synthetic.Sequences | Sort-Object RelativePath)[0]
    $removedPath = ([string]$firstSequence.RelativePath) + '/index-md5.txt'
    $synthetic.Files = [object[]]@($synthetic.Files | Where-Object { $_.RelativePath -cne $removedPath })
    $synthetic.Observations = [object[]]@($synthetic.Observations) + [pscustomobject]@{ Code = 'SyntheticPartialInventory'; RelativePath = $removedPath; CaptureStatus = 'AccessDenied' }
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    $newRecords = @($result.ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 0 -Actual @($newRecords | Where-Object { $_.RelativePath -eq $removedPath }).Count -Message 'Unavailable marker became observed evidence.'
    Assert-eMASEqual -Expected 0 -Actual @($newRecords | Where-Object { $_.ObservedValue -is [bool] -and $_.ObservedValue -eq $false }).Count -Message 'Marker absence was manufactured.'
    Assert-eMASEqual -Expected 1 -Actual @($newRecords | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.SequenceId -eq $firstSequence.SequenceId }).Count -Message 'Available unit fact was lost.'
}

Invoke-eMASRecordedCheck -Name 'new physical-marker records keep all interpretation fields null' -Action {
    $allNew = @($resultBySample.Values + $v4ResultBySample.Values | ForEach-Object { $_.ClassificationEvidence } | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASTrue -Condition ($allNew.Count -gt 0) -Message 'No new evidence was available to validate.'
    foreach ($record in $allNew) {
        Assert-eMASEqual -Expected $null -Actual $record.CandidateValue -Message 'CandidateValue was populated.'
        Assert-eMASEqual -Expected $null -Actual $record.Polarity -Message 'Polarity was populated.'
        Assert-eMASEqual -Expected $null -Actual $record.SourceRuleId -Message 'SourceRuleId was populated.'
    }
}

Invoke-eMASRecordedCheck -Name 'new physical-marker records preserve raw Weak and Supporting strength vocabulary' -Action {
    $allNew = @($resultBySample.Values + $v4ResultBySample.Values | ForEach-Object { $_.ClassificationEvidence } | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 0 -Actual @($allNew | Where-Object { $_.Strength -eq 'Medium' }).Count -Message 'Supporting was normalized to Medium.'
    Assert-eMASEqual -Expected 0 -Actual @($allNew | Where-Object { $_.EvidenceType -eq 'RegulatoryUnitKind' -and $_.Strength -ne 'Weak' }).Count -Message 'Unit kind strength differs.'
    Assert-eMASEqual -Expected 0 -Actual @($allNew | Where-Object { $_.EvidenceType -ne 'RegulatoryUnitKind' -and $_.Strength -ne 'Supporting' }).Count -Message 'Physical marker strength differs.'
}

Invoke-eMASRecordedCheck -Name 'additive evidence is deterministic and preserves historical EvidenceIds' -Action {
    $result = $resultBySample['SD-002']
    $repeat = Invoke-eMASClassificationEvidenceCollection -InputResult $inputBySample['SD-002']
    Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $result.ClassificationEvidence) -Actual (ConvertTo-eMASJsonText $repeat.ClassificationEvidence) -Message 'Marker evidence ordering is not deterministic.'
    $historical = @($result.ClassificationEvidence | Where-Object { $allAdditiveEvidenceTypes -notcontains $_.EvidenceType })
    Assert-eMASEqual -Expected 86 -Actual $historical.Count -Message 'Historical evidence count changed.'
    for ($index = 0; $index -lt $historical.Count; $index++) {
        Assert-eMASEqual -Expected ('EVD-{0:D4}' -f ($index + 1)) -Actual $historical[$index].EvidenceId -Message 'Historical EvidenceId changed.'
    }
    Assert-eMASEqual -Expected 'EVD-0087' -Actual @($result.ClassificationEvidence | Where-Object { $newPhysicalMarkerEvidenceTypes -contains $_.EvidenceType })[0].EvidenceId -Message 'Additive evidence did not follow the historical ID range.'
}

Invoke-eMASRecordedCheck -Name 'EU regional-envelope evidence implements exactly five accepted factual types' -Action {
    $records = @($resultBySample['SD-002'].ClassificationEvidence | Where-Object { $newRegionalEnvelopeEvidenceTypes -contains $_.EvidenceType })
    Assert-eMASEqual -Expected 49 -Actual $records.Count -Message 'SD-002 regional-envelope evidence count differs.'
    foreach ($expected in @(
        @{ Type = 'EuEnvelopeCountry'; Count = 10; Dimension = 'Region' },
        @{ Type = 'EuAgencyCode'; Count = 10; Dimension = 'Region' },
        @{ Type = 'EuProcedureType'; Count = 10; Dimension = 'DossierContext' },
        @{ Type = 'EuSubmissionType'; Count = 10; Dimension = 'DossierContext' },
        @{ Type = 'EuSubmissionUnitType'; Count = 9; Dimension = 'DossierContext' }
    )) {
        $typed = @($records | Where-Object { $_.EvidenceType -eq $expected.Type })
        Assert-eMASEqual -Expected $expected.Count -Actual $typed.Count -Message ("Count differs for {0}." -f $expected.Type)
        Assert-eMASEqual -Expected 0 -Actual @($typed | Where-Object { $_.Dimension -ne $expected.Dimension }).Count -Message ("Dimension hint differs for {0}." -f $expected.Type)
    }
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.Strength -ne 'Strong' -or $_.SourceTier -ne 'StructuredXml' -or $_.SourceCapability -ne 'BackboneXmlInventory' }).Count -Message 'Regional evidence strength, tier or source capability differs.'
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $null -ne $_.CandidateValue -or $null -ne $_.Polarity -or $null -ne $_.SourceRuleId }).Count -Message 'Regional evidence populated interpretation fields.'
}

Invoke-eMASRecordedCheck -Name 'SourceOrdinal is present only on new regional-envelope records' -Action {
    $records = @($resultBySample['SD-002'].ClassificationEvidence)
    $regional = @($records | Where-Object { $newRegionalEnvelopeEvidenceTypes -contains $_.EvidenceType })
    $other = @($records | Where-Object { $newRegionalEnvelopeEvidenceTypes -notcontains $_.EvidenceType })
    Assert-eMASEqual -Expected 0 -Actual @($regional | Where-Object { $_.PSObject.Properties.Name -notcontains 'SourceOrdinal' -or [int]$_.SourceOrdinal -lt 1 }).Count -Message 'Regional evidence lacks a valid source ordinal.'
    Assert-eMASEqual -Expected 0 -Actual @($other | Where-Object { $_.PSObject.Properties.Name -contains 'SourceOrdinal' }).Count -Message 'Historical or physical-marker evidence gained SourceOrdinal.'
}

Invoke-eMASRecordedCheck -Name 'historical and T1a EvidenceIds remain unchanged before the T1b range' -Action {
    $records = @($resultBySample['SD-002'].ClassificationEvidence)
    $preT1b = @($records | Where-Object { $newRegionalEnvelopeEvidenceTypes -notcontains $_.EvidenceType })
    Assert-eMASEqual -Expected 101 -Actual $preT1b.Count -Message 'Pre-T1b evidence count changed.'
    for ($index = 0; $index -lt $preT1b.Count; $index++) {
        Assert-eMASEqual -Expected ('EVD-{0:D4}' -f ($index + 1)) -Actual $preT1b[$index].EvidenceId -Message 'Pre-T1b EvidenceId changed.'
    }
    Assert-eMASEqual -Expected 'EVD-0102' -Actual @($records | Where-Object { $newRegionalEnvelopeEvidenceTypes -contains $_.EvidenceType })[0].EvidenceId -Message 'T1b evidence did not start after the accepted range.'
}

Invoke-eMASRecordedCheck -Name 'regional-envelope field coverage preserves profile, missing and parse-failed reasons' -Action {
    $sd002Rows = @($resultBySample['SD-002'].CollectionCoverage | Where-Object { $_.CheckId -like 'RegionalEnvelopeField:*' })
    Assert-eMASEqual -Expected 25 -Actual $sd002Rows.Count -Message 'SD-002 regional field coverage row count differs.'
    $profile20Xml = @($resultBySample['SD-002'].XmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' -and $_.DeclaredVersion -eq '2.0' })[0]
    $notDefined = @($sd002Rows | Where-Object { $_.SubjectId -eq $profile20Xml.XmlId -and $_.CheckId -eq 'RegionalEnvelopeField:EU_SUBMISSION_UNIT_TYPE' })
    Assert-eMASEqual -Expected 1 -Actual $notDefined.Count -Message '2.0 submission-unit coverage is missing.'
    Assert-eMASEqual -Expected 'FieldNotDefinedInProfile' -Actual $notDefined[0].ReasonCode -Message '2.0 submission-unit reason differs.'
    Assert-eMASEqual -Expected 5 -Actual @($resultBySample['SD-006'].CollectionCoverage | Where-Object { $_.CheckId -like 'RegionalEnvelopeField:*' -and $_.ReasonCode -eq 'SourceXmlMissing' }).Count -Message 'Missing regional XML field coverage differs.'
    Assert-eMASEqual -Expected 5 -Actual @($resultBySample['SD-008'].CollectionCoverage | Where-Object { $_.CheckId -like 'RegionalEnvelopeField:*' -and $_.ReasonCode -eq 'SourceXmlParseFailed' }).Count -Message 'Malformed regional XML field coverage differs.'
}

Invoke-eMASRecordedCheck -Name 'CEC consumes mocked RegionalEnvelope facts without reopening XML' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $synthetic.Repository.ResolvedSourcePath = '/source/that/is/not/available/to-cec.zip'
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    Assert-eMASEqual -Expected 49 -Actual @($result.ClassificationEvidence | Where-Object { $newRegionalEnvelopeEvidenceTypes -contains $_.EvidenceType }).Count -Message 'Mocked upstream regional facts were not collected.'
}

Invoke-eMASRecordedCheck -Name 'SD-001 historical DTD versions are preserved verbatim' -Action {
    $check = $expectations.historicalVersionCheck
    $records = @($resultBySample[[string]$check.sampleId].ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'DtdVersion' })
    foreach ($property in @($check.regionalValuesBySequence.PSObject.Properties)) {
        $regional = @($records | Where-Object { $_.SequenceFolder -eq $property.Name -and $_.SequenceRelativePath -eq 'm1/eu/eu-regional.xml' })
        Assert-eMASEqual -Expected 1 -Actual $regional.Count -Message "Regional version record missing for $($property.Name)."
        Assert-eMASEqual -Expected ([string]$property.Value) -Actual $regional[0].ObservedValue -Message "Regional version rewritten for $($property.Name)."
        $common = @($records | Where-Object { $_.SequenceFolder -eq $property.Name -and $_.SequenceRelativePath -eq 'index.xml' })
        Assert-eMASEqual -Expected ([string]$check.commonValue) -Actual $common[0].ObservedValue -Message "Common version rewritten for $($property.Name)."
    }
}

Invoke-eMASRecordedCheck -Name 'SD-001 collects structured common and regional backbone evidence with no final classification' -Action {
    $records = @($resultBySample['SD-001'].ClassificationEvidence)
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'XmlNamespace' -and $_.ObservedValue -eq 'http://www.ich.org/ectd' -and $_.Strength -eq 'Strong' }).Count -Message 'Common namespace evidence differs.'
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'XmlRootElement' -and $_.ObservedValue -eq 'eu-backbone' -and $_.Dimension -eq 'Region' }).Count -Message 'Regional root evidence differs.'
    Assert-eMASEqual -Expected 5 -Actual @($records | Where-Object { $_.EvidenceType -eq 'RegionalBackbonePath' -and $_.ObservedValue -eq 'm1/eu/eu-regional.xml' -and $_.SourceTier -eq 'OfficialPhysicalPath' }).Count -Message 'Regional path evidence differs.'
    Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $null -ne $_.CandidateValue }).Count -Message 'Candidate value populated.'
}

foreach ($missing in @($expectations.primaryChecks.missingXml)) {
    Invoke-eMASRecordedCheck -Name ("{0} missing {1} yields presence=false and no fabricated XML evidence" -f $missing.sampleId, $missing.noStructuredFor) -Action {
        $records = @($resultBySample[[string]$missing.sampleId].ClassificationEvidence | Where-Object { $_.SequenceFolder -eq $missing.sequenceFolder })
        $presence = @($records | Where-Object { $_.EvidenceType -eq $missing.evidenceType })
        Assert-eMASEqual -Expected 1 -Actual $presence.Count -Message 'Presence record missing.'
        Assert-eMASEqual -Expected $false -Actual $presence[0].ObservedValue -Message 'Presence is not false.'
        Assert-eMASEqual -Expected 'Available' -Actual $presence[0].CaptureStatus -Message 'Presence capture differs.'
        Assert-eMASEqual -Expected 0 -Actual @($records | Where-Object { $_.SequenceRelativePath -eq $missing.noStructuredFor -and $_.EvidenceType -notlike '*Presence' }).Count -Message 'Fabricated evidence for missing XML.'
        Assert-eMASTrue -Condition (@($records | Where-Object { $_.SourceTier -eq 'StructuredXml' -and $_.SequenceRelativePath -ne $missing.noStructuredFor }).Count -gt 0) -Message 'Remaining structured evidence was not preserved.'
        Assert-eMASEqual -Expected 'Collected' -Actual @($resultBySample[[string]$missing.sampleId].CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })[0].CollectionStatus -Message 'Confirmed absence became a collection gap.'
    }
}

foreach ($malformed in @($expectations.primaryChecks.malformedXml)) {
    Invoke-eMASRecordedCheck -Name ("{0} malformed {1} yields no reconstructed structured evidence" -f $malformed.sampleId, $malformed.xmlSequenceRelativePath) -Action {
        $records = @($resultBySample[[string]$malformed.sampleId].ClassificationEvidence | Where-Object { $_.SequenceFolder -eq $malformed.sequenceFolder -and $_.SequenceRelativePath -eq $malformed.xmlSequenceRelativePath })
        Assert-eMASEqual -Expected 'Presence|Path' -Actual ((@($records | ForEach-Object { $_.EvidenceType -replace '^(Common|Regional)Backbone', '' }) -join '|')) -Message 'Malformed XML evidence differs from physical-only.'
        Assert-eMASEqual -Expected $true -Actual $records[0].ObservedValue -Message 'Malformed XML presence differs.'
    }
}

Invoke-eMASRecordedCheck -Name 'SD-020 unrelated documents are not force-classified' -Action {
    $result = $resultBySample['SD-020']
    Assert-eMASEqual -Expected 0 -Actual @($result.ClassificationEvidence).Count -Message 'Evidence was manufactured.'
    $repository = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })[0]
    Assert-eMASEqual -Expected 'Collected' -Actual $repository.CollectionStatus -Message 'Zero-evidence result was not Collected.'
    Assert-eMASEqual -Expected 'Available' -Actual $repository.CaptureStatus -Message 'Zero-evidence capture status differs.'
}

foreach ($pair in @($expectations.invariancePairs)) {
    Invoke-eMASRecordedCheck -Name ("Classification evidence invariant: {0} vs {1} ({2})" -f $pair.baseline, $pair.comparison, $pair.projection) -Action {
        $baseline = $resultBySample[[string]$pair.baseline]; $comparison = $resultBySample[[string]$pair.comparison]
        if ($pair.projection -eq 'Full') {
            $baselineHistorical = [object[]]@($baseline.ClassificationEvidence | Where-Object { $allAdditiveEvidenceTypes -notcontains $_.EvidenceType })
            $comparisonHistorical = [object[]]@($comparison.ClassificationEvidence | Where-Object { $allAdditiveEvidenceTypes -notcontains $_.EvidenceType })
            Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $baselineHistorical) -Actual (ConvertTo-eMASJsonText $comparisonHistorical) -Message 'Historical classification evidence differs.'
        }
        else {
            Assert-eMASEqual -Expected (ConvertTo-eMASDossierRelativeProjection -Result $baseline) -Actual (ConvertTo-eMASDossierRelativeProjection -Result $comparison) -Message 'Dossier-relative classification evidence differs.'
        }
    }
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP classification evidence is equivalent for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-cec-directory-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $directoryResult = Invoke-eMASClassificationEvidenceCollection -InputResult (Invoke-eMASAcceptedChain -SourcePath $directorySource -ExecutionId 'EXEC-CEC-SD-002-DIRECTORY')
        Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $resultBySample['SD-002'].ClassificationEvidence) -Actual (ConvertTo-eMASJsonText $directoryResult.ClassificationEvidence) -Message 'Directory evidence differs from ZIP.'
        Assert-eMASTrue -Condition ((ConvertTo-eMASJsonText $directoryResult.ClassificationEvidence) -notlike "*$temporaryRoot*") -Message 'Temporary path leaked.'
    }
    finally { if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) } }
}

Invoke-eMASRecordedCheck -Name 'Integrity findings and checksum evidence do not influence classification evidence' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $synthetic.Observations = [object[]]@()
    foreach ($reference in @($synthetic.References)) { $reference.ChecksumMatch = $false; $reference.ChecksumComparisonStatus = 'Mismatched' }
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $resultBySample['SD-002'].ClassificationEvidence) -Actual (ConvertTo-eMASJsonText $result.ClassificationEvidence) -Message 'Integrity evidence influenced classification evidence.'
}

Invoke-eMASRecordedCheck -Name 'Synthetic: folder named FDA or EU is retained only as raw weak path evidence' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $synthetic.DossierCandidates[0].RelativePath = 'FDA/US/Canada/ASMF/EU'
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    $root = @($result.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'DossierRootPath' })
    Assert-eMASEqual -Expected 1 -Actual $root.Count -Message 'Dossier root record count differs.'
    Assert-eMASEqual -Expected 'FDA/US/Canada/ASMF/EU' -Actual $root[0].ObservedValue -Message 'Raw path was rewritten.'
    Assert-eMASEqual -Expected 'Weak' -Actual $root[0].Strength -Message 'Folder evidence was strengthened.'
    Assert-eMASEqual -Expected 'DossierContext' -Actual $root[0].Dimension -Message 'Folder name became region/format evidence.'
    Assert-eMASEqual -Expected 0 -Actual @($result.ClassificationEvidence | Where-Object { $null -ne $_.CandidateValue }).Count -Message 'Candidate value populated from folder name.'
}

Invoke-eMASRecordedCheck -Name 'Synthetic: access-denied backbone XML is NotAssessed and yields no structured evidence' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $xml = $synthetic.XmlDocuments[1]
    $xml.Exists = $null; $xml.ParseStatus = 'NotAttempted'; $xml.CaptureStatus = 'AccessDenied'
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    $records = @($result.ClassificationEvidence | Where-Object { $_.XmlId -eq $xml.XmlId })
    Assert-eMASEqual -Expected 1 -Actual $records.Count -Message 'Access-denied XML produced more than an unknown presence record.'
    Assert-eMASEqual -Expected $null -Actual $records[0].ObservedValue -Message 'Unknown presence became a fact.'
    Assert-eMASEqual -Expected 'AccessDenied' -Actual $records[0].CaptureStatus -Message 'Presence capture differs.'
    $repository = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })[0]
    Assert-eMASEqual -Expected 'Partial' -Actual $repository.CollectionStatus -Message 'Repository status differs.'
    Assert-eMASEqual -Expected 'AccessDenied' -Actual $repository.CaptureStatus -Message 'Repository capture differs.'
    Assert-eMASEqual -Expected 'CompletedWithCollectionGaps' -Actual $result.Execution.CompletionStatus -Message 'Gap not surfaced.'
}

Invoke-eMASRecordedCheck -Name 'Synthetic: unavailable repository inventory is NotAssessed with zero evidence' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $synthetic.Repository.InventoryCaptureStatus = 'AccessDenied'
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic
    Assert-eMASEqual -Expected 0 -Actual @($result.ClassificationEvidence).Count -Message 'Evidence emitted without inventory.'
    Assert-eMASEqual -Expected 'NotAssessed' -Actual @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })[0].CollectionStatus -Message 'Status differs.'
}

Invoke-eMASRecordedCheck -Name 'Input guards reject missing prerequisites and repeated collection' -Action {
    $synthetic = Copy-eMASResult $inputBySample['SD-002']
    $synthetic.Execution.Capabilities = [object[]]@('RepositoryDiscovery')
    $message = $null
    try { [void](Invoke-eMASClassificationEvidenceCollection -InputResult $synthetic) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue -Condition ([string]$message -like 'CEC-INPUT-003*') -Message 'Missing prerequisite not rejected.'
    $message = $null
    try { [void](Invoke-eMASClassificationEvidenceCollection -InputResult $resultBySample['SD-002']) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue -Condition ([string]$message -like 'CEC-INPUT-004*') -Message 'Repeated collection not rejected.'
}

Invoke-eMASRecordedCheck -Name 'Collection module performs no source access, XML parsing, network, classification or scoring' -Action {
    $moduleText = [System.IO.File]::ReadAllText($collectionModulePath)
    foreach ($pattern in @('File\]::Open', 'ReadAll', 'OpenRead', 'Get-ChildItem', 'Get-Content', 'ZipArchive', 'Compression', 'System\.Xml', 'XmlReader', '\[xml\]', 'LoadXml', 'SelectNodes', 'Cryptography', 'Invoke-WebRequest', 'WebClient', 'HttpClient', 'RegionDetection', 'FormatDetection', 'DetectedRegion', 'DetectedFormat', 'PrimaryRegion', '\bConfidence\b', '\bRAG\b', '\bSeverity\b', 'NewGuid', 'New-Guid')) {
        Assert-eMASTrue -Condition ($moduleText -notmatch $pattern) -Message "Module contains prohibited pattern $pattern."
    }
    Assert-eMASTrue -Condition ($moduleText -cnotmatch "'(EU|eu|FDA|US|us|CA|ca|Canada|ASMF|NeeS|v3|v4|3\.2\.2)'") -Message 'Module hard-codes a region/format token.'
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry point composes ClassificationEvidenceCollection' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-002-entrypoint.classification-evidence-collection.json'
    $entryResult = & $entryScriptPath -SourcePath $sourceState['SD-002'].Path -OutputPath $entryResultPath -ExecutionId 'EXEC-CEC-ENTRYPOINT' -IncludeClassificationEvidenceCollection
    Assert-eMASEqual -Expected (ConvertTo-eMASJsonText $resultBySample['SD-002'].ClassificationEvidence) -Actual (ConvertTo-eMASJsonText $entryResult.ClassificationEvidence) -Message 'Entry-point evidence differs.'
    Assert-eMASEqual -Expected 'ClassificationEvidenceCollection' -Actual @($entryResult.Execution.Capabilities)[-1] -Message 'Entry-point capability differs.'
    Assert-eMASTrue -Condition ([System.IO.File]::Exists($entryResultPath)) -Message 'Entry-point output not written.'
}

foreach ($sampleId in @($sourceState.Keys)) {
    $state = $sourceState[$sampleId]
    if ((Get-eMASTestSha256 -Path $state.Path) -ne $state.Hash) { throw ('FREEZE-VERIFY-003 Frozen fixture changed during testing: {0}' -f $sampleId) }
    if ((New-Object System.IO.FileInfo($state.Path)).LastWriteTimeUtc -ne $state.LastWriteTimeUtc) { throw ('FREEZE-VERIFY-004 Frozen fixture timestamp changed during testing: {0}' -f $sampleId) }
    $frozenAfterVerified++
}
Write-Output ('[PASS] Post-test freeze gate verified {0} ZIP fixtures.' -f $frozenAfterVerified)

foreach ($sampleId in @($wave1EState.Keys)) {
    $state = $wave1EState[$sampleId]
    if ((Get-eMASTestSha256 -Path $state.Path) -ne $state.Hash) { throw ('FREEZE-VERIFY-007 Wave1E fixture changed during testing: {0}' -f $sampleId) }
    if ((New-Object System.IO.FileInfo($state.Path)).LastWriteTimeUtc -ne $state.LastWriteTimeUtc) { throw ('FREEZE-VERIFY-008 Wave1E fixture timestamp changed during testing: {0}' -f $sampleId) }
    $wave1EFrozenAfterVerified++
}
Write-Output ('[PASS] Post-test Wave1E freeze gate verified {0} ZIP fixtures.' -f $wave1EFrozenAfterVerified)

$fixtureFailureCount = @($fixtureResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$additionalFailureCount = @($additionalResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$overallStatus = $(if (($fixtureFailureCount + $additionalFailureCount) -eq 0) { 'PASS' } else { 'FAIL' })
$summary = [pscustomobject][ordered]@{
    ContractId = $expectations.contractId
    Capability = 'ClassificationEvidenceCollection'
    StartedAtUtc = $startedAtUtc.ToString('o')
    CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    OverallStatus = $overallStatus
    FrozenFixtureCountVerifiedBefore = $frozenBeforeVerified
    FrozenFixtureCountVerifiedAfter = $frozenAfterVerified
    Wave1EFrozenFixtureCountVerifiedBefore = $wave1EFrozenBeforeVerified
    Wave1EFrozenFixtureCountVerifiedAfter = $wave1EFrozenAfterVerified
    FixtureCount = $fixtureResults.Count
    FixturePassCount = @($fixtureResults | Where-Object { $_.Status -eq 'PASS' }).Count
    FixtureFailCount = $fixtureFailureCount
    AdditionalCheckCount = $additionalResults.Count
    AdditionalCheckPassCount = @($additionalResults | Where-Object { $_.Status -eq 'PASS' }).Count
    AdditionalCheckFailCount = $additionalFailureCount
    FixtureResults = [object[]]@($fixtureResults)
    AdditionalChecks = [object[]]@($additionalResults)
}
$summaryPath = Join-Path $resolvedOutputRoot 'classification-evidence-collection-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('ClassificationEvidenceCollection tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') { exit 1 }
exit 0
