#requires -Version 5.1

<#
.SYNOPSIS
Wave1D dossier-diversity regression harness (EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D).

Runs the composed accepted 8-capability chain (entry script with
-IncludeClassificationEvidenceCollection) over SD-044..SD-051 and compares the
results with the independently derived expectations in
tests/fixtures/dossier-diversity/wave1d-expectations.json.

SD-044..SD-050 use the original normative expectations. SD-051 uses the
versioned B3-FO normative expectation while its earlier characterization is
retained unchanged for provenance.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CorpusRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    [string] $FreezeManifestPath,
    [string] $ExpectationsPath,
    [string] $CharacterizationPath,
    [string] $SD051NormativePath,
    [string] $Wave1CorpusRoot,
    [switch] $RecordCharacterization
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$entryScript = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
$resolvedCorpusRoot = [System.IO.Path]::GetFullPath($CorpusRoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
if ([string]::IsNullOrWhiteSpace($FreezeManifestPath)) { $FreezeManifestPath = Join-Path $resolvedCorpusRoot 'WAVE1D_FREEZE_MANIFEST.csv' }
if ([string]::IsNullOrWhiteSpace($ExpectationsPath)) { $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/dossier-diversity/wave1d-expectations.json' }
if ([string]::IsNullOrWhiteSpace($CharacterizationPath)) { $CharacterizationPath = Join-Path $repositoryRoot 'tests/fixtures/dossier-diversity/wave1d-sd051-characterization.json' }
if ([string]::IsNullOrWhiteSpace($SD051NormativePath)) { $SD051NormativePath = Join-Path $repositoryRoot 'tests/fixtures/dossier-diversity/wave1d-sd051-normative.v2.json' }
$resultRoot = Join-Path $resolvedOutputRoot 'results'
[void][System.IO.Directory]::CreateDirectory($resultRoot)

$expectations = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($ExpectationsPath)) | ConvertFrom-Json
$sd051Normative = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($SD051NormativePath)) | ConvertFrom-Json
$manifestRows = @(Import-Csv -LiteralPath $FreezeManifestPath)
$checks = New-Object System.Collections.ArrayList
$resultBySample = @{}
$sourceState = @{}
$characterizationStatus = 'NOT_RUN'
$script:eMASW1dPhysicalMarkerEvidenceTypes = @(
    'RegulatoryUnitKind',
    'SubmissionUnitMarkerFile',
    'TocFileMarker',
    'ChecksumFileMarker',
    'UtilityDtdFolderMarker'
)

function Get-eMASW1dSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Assert-eMASW1dTrue { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMASW1dEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Get-eMASW1dProperty {
    param([AllowNull()][object] $Object, [Parameter(Mandatory = $true)][string] $Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}
function ConvertTo-eMASW1dJson { param([AllowNull()][object] $Value) return ([object[]]@($Value) | ConvertTo-Json -Depth 64 -Compress) }
function Get-eMASW1dHistoricalClassificationEvidence {
    param([AllowEmptyCollection()][object[]] $Records)
    return @($Records | Where-Object { $script:eMASW1dPhysicalMarkerEvidenceTypes -notcontains $_.EvidenceType })
}
function Write-eMASW1dJson {
    param([Parameter(Mandatory = $true)][object] $Value, [Parameter(Mandatory = $true)][string] $Path)
    [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 64), (New-Object System.Text.UTF8Encoding($false)))
}
function Get-eMASW1dSortedText {
    param([AllowEmptyCollection()][string[]] $Values)
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($value in @($Values)) { $list.Add([string]$value) }
    $list.Sort([System.StringComparer]::Ordinal)
    return ($list.ToArray() -join "`n")
}
# Same canonical record key as the accepted ClassificationEvidenceCollection harness.
function ConvertTo-eMASW1dRecordKey {
    param([string] $Type, [string] $Dimension, [string] $Strength, [string] $Tier, [AllowNull()][object] $SequenceFolder, [AllowNull()][object] $XmlPath, [AllowNull()][object] $ObservedValue)
    $value = $(if ($ObservedValue -is [System.Array]) { ,([object[]]$ObservedValue) } else { $ObservedValue })
    return ([pscustomobject][ordered]@{ t = $Type; d = $Dimension; s = $Strength; r = $Tier; f = $SequenceFolder; x = $XmlPath; v = $value } | ConvertTo-Json -Depth 8 -Compress)
}
function Test-eMASW1dUnderRoot {
    param([AllowNull()][string] $Path, [AllowNull()][string] $Root)
    if ($null -eq $Path) { return $false }
    if ([string]::IsNullOrEmpty($Root)) { return $true }
    return ($Path -eq $Root -or $Path.StartsWith($Root + '/', [System.StringComparison]::Ordinal))
}

function Invoke-eMASW1dCheck {
    param([Parameter(Mandatory = $true)][string] $SampleId, [Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action, [string] $Category = 'Normative')
    try {
        & $Action
        [void]$checks.Add([pscustomobject][ordered]@{ SampleId = $SampleId; Category = $Category; Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0} {1}' -f $SampleId, $Name)
    }
    catch {
        [void]$checks.Add([pscustomobject][ordered]@{ SampleId = $SampleId; Category = $Category; Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0} {1}: {2}' -f $SampleId, $Name, $_.Exception.Message)
    }
}

function Invoke-eMASW1dChain {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [Parameter(Mandatory = $true)][string] $SampleId)
    $outputPath = Join-Path $resultRoot ('{0}.presales.json' -f $SampleId)
    $null = & $entryScript -SourcePath $SourcePath -OutputPath $outputPath -ExecutionId ('EXEC-W1D-{0}' -f $SampleId) -IncludeClassificationEvidenceCollection
    # Reload the persisted contract so every comparison sees exactly what a consumer sees.
    return ([System.IO.File]::ReadAllText($outputPath) | ConvertFrom-Json)
}

# Index helpers -------------------------------------------------------------
function Get-eMASW1dIndex {
    param([Parameter(Mandatory = $true)][object] $Result)
    $index = @{ Dossier = @{}; DossierByPath = @{}; Sequence = @{}; Xml = @{}; File = @{} }
    foreach ($item in @($Result.DossierCandidates)) { $index.Dossier[$item.DossierId] = $item; $index.DossierByPath[[string]$item.RelativePath] = $item }
    foreach ($item in @($Result.Sequences)) { $index.Sequence[$item.SequenceId] = $item }
    foreach ($item in @($Result.XmlDocuments)) { $index.Xml[$item.XmlId] = $item }
    foreach ($item in @($Result.Files)) { $index.File[$item.FileId] = $item }
    return $index
}
function Get-eMASW1dSequenceRelative {
    param([Parameter(Mandatory = $true)][object] $Xml)
    return $Xml.RelativePath.Substring(([string]$Xml.SequencePath).Length + 1)
}

# Dossier-relative, ID-free, root-free projection used for cross-fixture invariance.
function Get-eMASW1dDossierProjection {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][AllowEmptyString()][string] $RootPath)
    $index = Get-eMASW1dIndex -Result $Result
    $dossier = $index.DossierByPath[$RootPath]
    if ($null -eq $dossier) { throw ('Dossier {0} not discovered.' -f $RootPath) }
    $dossierId = $dossier.DossierId
    $records = [string[]]@($Result.ClassificationEvidence | Where-Object { $_.DossierId -eq $dossierId -and $_.EvidenceType -ne 'DossierRootPath' } | ForEach-Object {
        ConvertTo-eMASW1dRecordKey $_.EvidenceType $_.Dimension $_.Strength $_.SourceTier $_.SequenceFolder $_.SequenceRelativePath $_.ObservedValue })
    $xml = [string[]]@($Result.XmlDocuments | Where-Object { $_.DossierId -eq $dossierId } | ForEach-Object {
        ConvertTo-eMASW1dJson ([pscustomobject][ordered]@{ s = $index.Sequence[$_.SequenceId].FolderName; p = (Get-eMASW1dSequenceRelative -Xml $_); k = $_.XmlKind; ps = $_.ParseStatus; r = $_.RootElement; n = $_.NamespaceUri; v = $_.DeclaredVersion; t = $_.DocumentTypeName; si = $_.SystemId; pi = $_.PublicId }) })
    $references = [string[]]@($Result.References | Where-Object { $_.DossierId -eq $dossierId } | ForEach-Object {
        $source = $index.Xml[$_.XmlId]
        ConvertTo-eMASW1dJson ([pscustomobject][ordered]@{ s = $index.Sequence[$_.SequenceId].FolderName; p = (Get-eMASW1dSequenceRelative -Xml $source); i = $_.SourcePosition; h = $_.RawHref; n = $_.NormalizedTargetPath; rs = $_.ResolutionStatus; cs = $_.ChecksumComparisonStatus; dc = $_.DeclaredChecksum; cc = $_.CalculatedChecksum; op = $_.Operation }) })
    # WrapperDepth intentionally describes wrapper context (asserted by the wrapper-path check), so it is
    # excluded here like the DossierRootPath record.
    $observations = [string[]]@($Result.Observations | Where-Object { $_.SubjectType -eq 'Dossier' -and $_.SubjectId -eq $dossierId -and $_.Code -ne 'WrapperDepth' } | ForEach-Object { ConvertTo-eMASW1dJson @($_.Code, $_.ObservedValue) })
    return ('CEC:' + (Get-eMASW1dSortedText $records) + "`nXML:" + (Get-eMASW1dSortedText $xml) + "`nREF:" + (Get-eMASW1dSortedText $references) + "`nOBS:" + (Get-eMASW1dSortedText $observations))
}

# Normative per-dossier comparison ------------------------------------------
function Test-eMASW1dDossier {
    param([Parameter(Mandatory = $true)][string] $SampleId, [Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][object] $Expected)
    $root = [string]$Expected.rootPath
    $label = $(if ($root -eq '') { '<archive root>' } else { $root })
    $index = Get-eMASW1dIndex -Result $Result

    Invoke-eMASW1dCheck -SampleId $SampleId -Name ("dossier '{0}' discovery, sequences and backbone XML" -f $label) -Action {
        $dossier = $index.DossierByPath[$root]
        Assert-eMASW1dTrue ($null -ne $dossier) ("Dossier '{0}' not discovered." -f $label)
        $sequences = [string[]]@($Result.Sequences | Where-Object { $_.DossierId -eq $dossier.DossierId -and $_.IsExactSequenceFolder } | ForEach-Object { $_.FolderName })
        Assert-eMASW1dEqual (Get-eMASW1dSortedText ([string[]]@($Expected.sequenceFolders))) (Get-eMASW1dSortedText $sequences) 'Sequence folders differ.'
        $expectedXml = [string[]]@($Expected.xmlDocuments | ForEach-Object { '{0}|{1}|{2}' -f $_.sequenceFolder, $_.xmlSequenceRelativePath, $_.xmlKind })
        $actualXml = [string[]]@($Result.XmlDocuments | Where-Object { $_.DossierId -eq $dossier.DossierId -and $_.ParseStatus -eq 'Parsed' } | ForEach-Object { '{0}|{1}|{2}' -f $index.Sequence[$_.SequenceId].FolderName, (Get-eMASW1dSequenceRelative -Xml $_), $_.XmlKind })
        Assert-eMASW1dEqual (Get-eMASW1dSortedText $expectedXml) (Get-eMASW1dSortedText $actualXml) 'Parsed backbone XML set differs.'
        Assert-eMASW1dEqual 0 @($Result.XmlDocuments | Where-Object { $_.DossierId -eq $dossier.DossierId -and $_.ParseStatus -ne 'Parsed' }).Count 'Unexpected non-parsed backbone XML.'
    }

    Invoke-eMASW1dCheck -SampleId $SampleId -Name ("dossier '{0}' references, resolution and checksums" -f $label) -Action {
        $dossierId = $index.DossierByPath[$root].DossierId
        $references = @($Result.References | Where-Object { $_.DossierId -eq $dossierId })
        $e = $Expected.references
        Assert-eMASW1dEqual $e.referenceCount $references.Count 'Reference count differs.'
        Assert-eMASW1dEqual $e.hrefCount @($references | Where-Object { $null -ne $_.RawHref }).Count 'Href count differs.'
        Assert-eMASW1dEqual $e.commonReferenceCount @($references | Where-Object { $_.XmlKind -eq 'CommonBackbone' }).Count 'Common reference count differs.'
        Assert-eMASW1dEqual $e.regionalReferenceCount @($references | Where-Object { $_.XmlKind -eq 'RegionalBackbone' }).Count 'Regional reference count differs.'
        Assert-eMASW1dEqual $e.resolvedPresentCount @($references | Where-Object { $_.ResolutionStatus -eq 'ResolvedPresent' }).Count 'Resolved-present count differs.'
        Assert-eMASW1dEqual $e.resolvedAbsentCount @($references | Where-Object { $_.ResolutionStatus -eq 'ResolvedAbsent' }).Count 'Resolved-absent count differs.'
        Assert-eMASW1dEqual $e.notApplicableCount @($references | Where-Object { $_.ResolutionStatus -eq 'NotApplicable' }).Count 'Not-applicable count differs.'
        Assert-eMASW1dEqual $e.unresolvedCount @($references | Where-Object { @('ResolvedPresent', 'ResolvedAbsent', 'NotApplicable') -notcontains $_.ResolutionStatus }).Count 'Unresolved count differs.'
        foreach ($row in @($e.perXml)) {
            $count = @($references | Where-Object { $index.Sequence[$_.SequenceId].FolderName -eq $row.sequenceFolder -and (Get-eMASW1dSequenceRelative -Xml $index.Xml[$_.XmlId]) -eq $row.xmlSequenceRelativePath }).Count
            Assert-eMASW1dEqual $row.referenceCount $count ('Per-XML reference count differs for {0}/{1}.' -f $row.sequenceFolder, $row.xmlSequenceRelativePath)
        }
        $c = $Expected.checksums
        Assert-eMASW1dEqual $c.matchedCount @($references | Where-Object { $_.ChecksumComparisonStatus -eq 'Matched' }).Count 'Matched checksum count differs.'
        Assert-eMASW1dEqual $c.mismatchedCount @($references | Where-Object { $_.ChecksumComparisonStatus -eq 'Mismatched' }).Count 'Mismatched checksum count differs.'
        Assert-eMASW1dEqual $c.notAssessedCount @($references | Where-Object { $_.ChecksumComparisonStatus -eq 'NotAssessed' }).Count 'Not-assessed checksum count differs.'
        Assert-eMASW1dEqual $c.notApplicableCount @($references | Where-Object { $_.ChecksumComparisonStatus -eq 'NotApplicable' }).Count 'Not-applicable checksum count differs.'
        $referenceIds = @{}; foreach ($reference in $references) { $referenceIds[$reference.ReferenceId] = $true }
        $missing = @($Result.Observations | Where-Object { $_.Code -eq $expectations.findingObservationCodes.missingReference -and $referenceIds.ContainsKey([string]$_.SubjectId) })
        $mismatch = @($Result.Observations | Where-Object { $_.Code -eq $expectations.findingObservationCodes.checksumMismatch -and $referenceIds.ContainsKey([string]$_.SubjectId) })
        Assert-eMASW1dEqual $Expected.missingReferenceFindingCount $missing.Count 'Missing-reference finding count differs.'
        Assert-eMASW1dEqual $Expected.checksumMismatchObservationCount $mismatch.Count 'Checksum-mismatch observation count differs.'
    }

    Invoke-eMASW1dCheck -SampleId $SampleId -Name ("dossier '{0}' historical classification evidence multiset ({1} records)" -f $label, $Expected.classificationRecordCount) -Action {
        $dossierId = $index.DossierByPath[$root].DossierId
        $records = @(Get-eMASW1dHistoricalClassificationEvidence -Records @($Result.ClassificationEvidence | Where-Object { $_.DossierId -eq $dossierId }))
        Assert-eMASW1dEqual $Expected.classificationRecordCount $records.Count 'Classification record count differs.'
        $actualKeys = [string[]]@($records | ForEach-Object { ConvertTo-eMASW1dRecordKey $_.EvidenceType $_.Dimension $_.Strength $_.SourceTier $_.SequenceFolder $_.SequenceRelativePath $_.ObservedValue })
        $expectedKeys = [string[]]@($Expected.classificationRecords | ForEach-Object { ConvertTo-eMASW1dRecordKey $_.evidenceType $_.dimension $_.strength $_.sourceTier $_.sequenceFolder $_.xmlSequenceRelativePath $_.observedValue })
        Assert-eMASW1dEqual (Get-eMASW1dSortedText $expectedKeys) (Get-eMASW1dSortedText $actualKeys) 'Classification evidence multiset differs.'
        $rootRecords = @($records | Where-Object { $_.EvidenceType -eq 'DossierRootPath' })
        Assert-eMASW1dEqual 1 $rootRecords.Count 'DossierRootPath record count differs.'
        Assert-eMASW1dEqual $root ([string]$rootRecords[0].ObservedValue) 'DossierRootPath value differs.'
        Assert-eMASW1dEqual $root ([string]$rootRecords[0].RelativePath) 'DossierRootPath relative path differs.'
        foreach ($record in $records) {
            Assert-eMASW1dTrue (Test-eMASW1dUnderRoot -Path ([string]$record.RelativePath) -Root $root) ('Record {0} RelativePath {1} is outside its dossier.' -f $record.EvidenceId, $record.RelativePath)
            if ($root -eq '') { Assert-eMASW1dTrue (-not ([string]$record.RelativePath).StartsWith('/')) ('Root-level record {0} has a leading slash.' -f $record.EvidenceId) }
        }
    }
}

# Freeze gate (pre) -----------------------------------------------------------
foreach ($row in $manifestRows) {
    $path = Join-Path $resolvedCorpusRoot ('fixtures/{0}/fixture.zip' -f $row.SampleId)
    if (-not [System.IO.File]::Exists($path)) { throw ('FREEZE-VERIFY-001 Wave1D fixture missing: {0}' -f $row.SampleId) }
    $hash = Get-eMASW1dSha256 -Path $path
    if ($hash -ne $row.ZipSHA256) { throw ('FREEZE-VERIFY-002 Wave1D fixture hash mismatch: {0}' -f $row.SampleId) }
    $sourceState[$row.SampleId] = [pscustomobject]@{ Path = $path; Hash = $hash; Status = $row.Status }
}
$manifestIds = Get-eMASW1dSortedText ([string[]]@($manifestRows | ForEach-Object { $_.SampleId }))
$expectedIds = Get-eMASW1dSortedText ([string[]]@($expectations.fixtures | ForEach-Object { $_.sampleId }))
if ($manifestIds -ne $expectedIds) { throw 'FREEZE-VERIFY-003 Freeze manifest and expectations list different fixtures.' }
Write-Output ('[PASS] Pre-test freeze gate verified {0} Wave1D fixtures ({1}).' -f $manifestRows.Count, (($manifestRows | ForEach-Object { $_.Status } | Sort-Object -Unique) -join ','))

# Optional Wave 1 invariance references -----------------------------------------
$wave1References = @{}
if (-not [string]::IsNullOrWhiteSpace($Wave1CorpusRoot)) {
    $wave1Root = [System.IO.Path]::GetFullPath($Wave1CorpusRoot)
    $wave1Rows = @(Import-Csv -LiteralPath (Join-Path $wave1Root 'WAVE1_FREEZE_MANIFEST.csv'))
    foreach ($sampleId in @($expectations.invarianceGroups | ForEach-Object { $_.wave1Reference } | Sort-Object -Unique)) {
        $row = @($wave1Rows | Where-Object { $_.SampleId -eq $sampleId })[0]
        $path = Join-Path $wave1Root ('fixtures/{0}/fixture.zip' -f $sampleId)
        if ((Get-eMASW1dSha256 -Path $path) -ne $row.FixtureSHA256) { throw ('FREEZE-VERIFY-004 Wave 1 reference hash mismatch: {0}' -f $sampleId) }
        $wave1References[$sampleId] = Invoke-eMASW1dChain -SourcePath $path -SampleId ('W1-{0}' -f $sampleId)
    }
    Write-Output ('[PASS] Wave 1 invariance references verified and run: {0}.' -f (($wave1References.Keys | Sort-Object) -join ', '))
}

# Per-fixture checks ------------------------------------------------------------
foreach ($fixture in @($expectations.fixtures)) {
    $sampleId = [string]$fixture.sampleId
    $result = Invoke-eMASW1dChain -SourcePath $sourceState[$sampleId].Path -SampleId $sampleId
    $resultBySample[$sampleId] = $result
    $index = Get-eMASW1dIndex -Result $result
    $negative = Get-eMASW1dProperty $fixture 'negativeAssertions'
    $normativeOverride = $(if ($sampleId -eq [string]$sd051Normative.sampleId) { $sd051Normative } else { $null })
    $isNormative = ($fixture.kind -eq 'Normative' -or $null -ne $normativeOverride)

    Invoke-eMASW1dCheck -SampleId $sampleId -Name 'contract, capability chain and prohibited content' -Action {
        Assert-eMASW1dEqual $expectations.contractId $result.ContractId 'Contract differs.'
        Assert-eMASW1dEqual 'RepositoryDiscovery,BackboneXmlInventory,ReferenceInventory,ReferenceResolution,MissingReferenceInterpretation,DeclaredChecksumComparison,ChecksumMismatchInterpretation,ClassificationEvidenceCollection' (@($result.Execution.Capabilities) -join ',') 'Capability chain differs.'
        foreach ($capability in @($expectations.prohibitedCapabilities)) { Assert-eMASW1dTrue (@($result.Execution.Capabilities) -notcontains $capability) ('Prohibited capability {0} present.' -f $capability) }
        foreach ($code in @($expectations.prohibitedObservationCodes)) { Assert-eMASW1dEqual 0 @($result.Observations | Where-Object { $_.Code -eq $code }).Count ('Prohibited observation code {0} emitted.' -f $code) }
        foreach ($record in @($result.ClassificationEvidence)) {
            foreach ($field in @($expectations.nullFields)) { Assert-eMASW1dTrue ($null -eq (Get-eMASW1dProperty $record $field)) ('Record {0} has non-null {1}.' -f $record.EvidenceId, $field) }
            foreach ($field in @($expectations.prohibitedRecordFields)) { Assert-eMASW1dTrue ($null -eq $record.PSObject.Properties[$field]) ('Record {0} carries prohibited field {1}.' -f $record.EvidenceId, $field) }
        }
    }

    if ($isNormative) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'repository discovery, completion and coverage' -Action {
            $repositoryExpectation = $(if ($null -ne $normativeOverride) { $normativeOverride } else { $fixture })
            $candidates = [string[]]@($result.DossierCandidates | ForEach-Object { [string]$_.RelativePath })
            Assert-eMASW1dEqual (Get-eMASW1dSortedText ([string[]]@($repositoryExpectation.discovery.candidateRootPaths))) (Get-eMASW1dSortedText $candidates) 'Dossier candidate paths differ.'
            Assert-eMASW1dEqual (Get-eMASW1dSortedText ([string[]]@($repositoryExpectation.discovery.wrapperPaths))) (Get-eMASW1dSortedText ([string[]]@($result.Repository.WrapperPaths | ForEach-Object { [string]$_.RelativePath }))) 'Wrapper paths differ.'
            Assert-eMASW1dEqual $repositoryExpectation.expectedCompletionStatus $result.Execution.CompletionStatus 'Completion status differs.'
            $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })
            Assert-eMASW1dEqual 1 $coverage.Count 'Repository CEC coverage row count differs.'
            Assert-eMASW1dEqual $repositoryExpectation.expectedRepositoryCollectionStatus $coverage[0].CollectionStatus 'Repository CEC collection status differs.'
            $fullRecords = @($result.ClassificationEvidence)
            $historicalRecords = @(Get-eMASW1dHistoricalClassificationEvidence -Records $fullRecords)
            Assert-eMASW1dEqual $repositoryExpectation.expectedRepositoryRecordCount $historicalRecords.Count 'Repository historical CEC record total differs.'
            Assert-eMASW1dEqual $fullRecords.Count $coverage[0].RecordsProduced 'Repository CEC records-produced differs from the full additive result.'
            Assert-eMASW1dTrue ($fullRecords.Count -gt 0) 'A fixture with a dossier produced zero classification evidence.'
        }
    }
    else {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'genuine dossier remains independently discoverable' -Action {
            foreach ($root in @($fixture.discovery.candidateRootPathsMustInclude)) { Assert-eMASW1dTrue ($index.DossierByPath.ContainsKey([string]$root)) ('Genuine dossier {0} not discovered.' -f $root) }
        }
    }

    foreach ($expectedDossier in @($fixture.dossiers)) { Test-eMASW1dDossier -SampleId $sampleId -Result $result -Expected $expectedDossier }

    if ($null -ne $normativeOverride) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name ('B3 ownership semantics ({0})' -f $normativeOverride.statusLabel) -Action {
            Assert-eMASW1dEqual $normativeOverride.fixtureSha256 $sourceState[$sampleId].Hash 'Versioned expectation fixture hash differs.'
            foreach ($item in @($normativeOverride.unrelatedFiles)) {
                $file = @($result.Files | Where-Object { $_.RelativePath -eq $item.path })
                Assert-eMASW1dEqual 1 $file.Count ('Unrelated file {0} was not inventoried exactly once.' -f $item.path)
                $ownerRoot = $(if ($null -eq $file[0].DossierId) { $null } else { [string]$index.Dossier[$file[0].DossierId].RelativePath })
                Assert-eMASW1dEqual $item.expectedDossierRootPath $ownerRoot ('Owner of {0} differs.' -f $item.path)
                if ($item.mustNotProduceClassificationEvidence) {
                    Assert-eMASW1dEqual 0 @($result.ClassificationEvidence | Where-Object { $_.RelativePath -eq $item.path -or ([string]$_.RelativePath).StartsWith($item.path + '/', [System.StringComparison]::Ordinal) }).Count ('{0} produced classification evidence.' -f $item.path)
                }
            }
        }
    }

    Invoke-eMASW1dCheck -SampleId $sampleId -Name 'dossier isolation of sequences, XML, references and evidence' -Action {
        foreach ($sequence in @($result.Sequences)) { Assert-eMASW1dTrue (Test-eMASW1dUnderRoot -Path ([string]$sequence.RelativePath) -Root ([string]$index.Dossier[$sequence.DossierId].RelativePath)) ('Sequence {0} outside its dossier.' -f $sequence.SequenceId) }
        foreach ($xml in @($result.XmlDocuments)) {
            Assert-eMASW1dEqual $xml.DossierId $index.Sequence[$xml.SequenceId].DossierId ('XML {0} sequence/dossier mismatch.' -f $xml.XmlId)
            Assert-eMASW1dTrue (Test-eMASW1dUnderRoot -Path ([string]$xml.RelativePath) -Root ([string]$index.Dossier[$xml.DossierId].RelativePath)) ('XML {0} outside its dossier.' -f $xml.XmlId)
        }
        foreach ($reference in @($result.References)) {
            Assert-eMASW1dEqual $reference.DossierId $index.Xml[$reference.XmlId].DossierId ('Reference {0} XML/dossier mismatch.' -f $reference.ReferenceId)
            Assert-eMASW1dEqual $reference.DossierId $index.Sequence[$reference.SequenceId].DossierId ('Reference {0} sequence/dossier mismatch.' -f $reference.ReferenceId)
            if ($null -ne $reference.TargetFileId) {
                $target = $index.File[$reference.TargetFileId]
                Assert-eMASW1dEqual $reference.DossierId $target.DossierId ('Reference {0} resolved to a file of another dossier ({1}).' -f $reference.ReferenceId, $target.RelativePath)
                Assert-eMASW1dEqual (([string]$index.Dossier[$reference.DossierId].RelativePath), [string]$reference.NormalizedTargetPath -join '/').TrimStart('/') ([string]$target.RelativePath) ('Reference {0} target path is not dossier-scoped.' -f $reference.ReferenceId)
            }
        }
        foreach ($record in @($result.ClassificationEvidence)) {
            if ($null -ne $record.SequenceId) { Assert-eMASW1dEqual $record.DossierId $index.Sequence[$record.SequenceId].DossierId ('Evidence {0} sequence/dossier mismatch.' -f $record.EvidenceId) }
            if ($null -ne $record.XmlId) { Assert-eMASW1dEqual $record.DossierId $index.Xml[$record.XmlId].DossierId ('Evidence {0} XML/dossier mismatch.' -f $record.EvidenceId) }
            Assert-eMASW1dTrue (Test-eMASW1dUnderRoot -Path ([string]$record.RelativePath) -Root ([string]$index.Dossier[$record.DossierId].RelativePath)) ('Evidence {0} outside its dossier.' -f $record.EvidenceId)
        }
    }

    $unrelatedFiles = Get-eMASW1dProperty $negative 'unrelatedFiles'
    if ($null -ne $unrelatedFiles) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'unrelated content does not become dossier evidence' -Action {
            foreach ($item in @($unrelatedFiles)) {
                $files = @($result.Files | Where-Object { $_.RelativePath -eq $item.path })
                Assert-eMASW1dEqual 1 $files.Count ('Unrelated file {0} not inventoried exactly once.' -f $item.path)
                $ownerRoot = $(if ($null -eq $files[0].DossierId) { $null } else { [string]$index.Dossier[$files[0].DossierId].RelativePath })
                $forbidden = Get-eMASW1dProperty $item 'mustNotBelongToDossierRootPaths'
                if ($null -ne $forbidden) {
                    Assert-eMASW1dTrue (@($forbidden) -notcontains $ownerRoot) ('{0} belongs to genuine dossier {1}.' -f $item.path, $ownerRoot)
                }
                else {
                    Assert-eMASW1dEqual $item.expectedDossierRootPath $ownerRoot ('Owner of {0} differs.' -f $item.path)
                    Assert-eMASW1dTrue ($null -eq $files[0].SequenceId) ('{0} was assigned to a sequence.' -f $item.path)
                }
                Assert-eMASW1dEqual 0 @($result.XmlDocuments | Where-Object { $_.RelativePath -eq $item.path }).Count ('{0} became an XML document.' -f $item.path)
                Assert-eMASW1dEqual 0 @($result.ClassificationEvidence | Where-Object { $_.RelativePath -eq $item.path -or ([string]$_.RelativePath).StartsWith($item.path + '/', [System.StringComparison]::Ordinal) }).Count ('{0} produced classification evidence.' -f $item.path)
                Assert-eMASW1dEqual 0 @($result.References | Where-Object { $null -ne $_.TargetFileId -and $index.File[$_.TargetFileId].RelativePath -eq $item.path }).Count ('{0} became a reference target.' -f $item.path)
            }
        }
    }

    $tokens = Get-eMASW1dProperty $negative 'folderTokensOnlyInRootContext'
    if ($null -ne $tokens) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'misleading folder tokens stay in root context only' -Action {
            foreach ($token in @($tokens)) {
                foreach ($record in @($result.ClassificationEvidence | Where-Object { $_.EvidenceType -ne 'DossierRootPath' })) {
                    Assert-eMASW1dTrue (-not (ConvertTo-eMASW1dJson $record.ObservedValue).Contains($token)) ('Token {0} leaked into {1} {2}.' -f $token, $record.EvidenceType, $record.EvidenceId)
                }
                foreach ($xml in @($result.XmlDocuments)) {
                    foreach ($field in @('RootElement', 'NamespaceUri', 'DeclaredVersion', 'DocumentTypeName', 'SystemId', 'PublicId')) {
                        Assert-eMASW1dTrue (-not ([string]$xml.$field).Contains($token)) ('Token {0} in XML {1} {2}.' -f $token, $xml.XmlId, $field)
                    }
                }
            }
            $rootRecords = @($result.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'DossierRootPath' })
            foreach ($record in $rootRecords) {
                Assert-eMASW1dEqual 'DossierContext' $record.Dimension 'Root-context record dimension differs.'
                Assert-eMASW1dEqual 'Weak' $record.Strength 'Root-context record strength differs.'
                Assert-eMASW1dEqual 'FolderNameHeuristic' $record.SourceTier 'Root-context record tier differs.'
            }
            $asmf = [string]$negative.tokenNotTechnicalFormatEvidence
            Assert-eMASW1dEqual 0 @($result.ClassificationEvidence | Where-Object { $_.Dimension -eq 'TechnicalFormat' -and (ConvertTo-eMASW1dJson $_.ObservedValue).Contains($asmf) }).Count ('{0} appears as TechnicalFormat evidence.' -f $asmf)
            Assert-eMASW1dEqual 0 @($result.ClassificationEvidence | Where-Object { $_.Dimension -ne 'DossierContext' -and (ConvertTo-eMASW1dJson $_.ObservedValue).Contains($asmf) }).Count ('{0} appears outside DossierContext.' -f $asmf)
        }
    }

    $exactRoot = Get-eMASW1dProperty $negative 'exactRootPathPreserved'
    if ($null -ne $exactRoot) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'safe ASCII root name preserved byte-for-byte' -Action {
            Assert-eMASW1dTrue ($index.DossierByPath.ContainsKey([string]$exactRoot)) 'Exact root name not discovered.'
            foreach ($entry in @($result.Repository.Entries | Where-Object { $_.EntryKind -eq 'File' })) {
                Assert-eMASW1dTrue (([string]$entry.RelativePath).StartsWith($exactRoot + '/', [System.StringComparison]::Ordinal)) ('Entry outside exact root: {0}' -f $entry.RelativePath)
            }
            Assert-eMASW1dEqual 0 @($result.Repository.Errors).Count 'Repository errors reported for safe ASCII naming.'
        }
    }

    if ($null -ne (Get-eMASW1dProperty $negative 'rootDossierPathMustBeEmpty')) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'root-level dossier uses empty root path and resolves all references' -Action {
            Assert-eMASW1dEqual 1 @($result.DossierCandidates).Count 'Root-level dossier count differs.'
            Assert-eMASW1dEqual '' ([string]$result.DossierCandidates[0].RelativePath) 'Root dossier path is not empty.'
            Assert-eMASW1dEqual 0 @($result.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedAbsent' }).Count 'Root-level dossier produced false absent targets.'
            Assert-eMASW1dTrue (@($result.References | Where-Object { ([string]$_.NormalizedTargetPath).StartsWith('0000/', [System.StringComparison]::Ordinal) }).Count -gt 0) 'Normalized paths lost the 0000 prefix.'
            Assert-eMASW1dEqual 0 @($result.Observations | Where-Object { $_.Code -eq $expectations.findingObservationCodes.missingReference }).Count 'False ReferenceTargetMissing findings.'
        }
    }

    if ($null -ne (Get-eMASW1dProperty $negative 'noCrossDossierLinks')) {
        Invoke-eMASW1dCheck -SampleId $sampleId -Name 'multi-dossier identities are distinct and contiguous per dossier' -Action {
            Assert-eMASW1dEqual @($fixture.dossiers).Count (@($result.DossierCandidates | ForEach-Object { $_.DossierId } | Sort-Object -Unique)).Count 'Dossier identities merged.'
            foreach ($collection in @('Sequences', 'XmlDocuments', 'References', 'ClassificationEvidence')) {
                $owners = @($result.$collection | ForEach-Object { $_.DossierId } | Sort-Object -Unique)
                Assert-eMASW1dEqual @($fixture.dossiers).Count $owners.Count ('{0} are not split across both dossiers.' -f $collection)
            }
        }
    }
}

# Cross-fixture invariance ------------------------------------------------------
foreach ($group in @($expectations.invarianceGroups)) {
    Invoke-eMASW1dCheck -SampleId 'ALL' -Category 'Invariance' -Name ('dossier-relative invariance: {0}' -f $group.name) -Action {
        $reference = $null; $referenceName = $null
        if ($wave1References.ContainsKey([string]$group.wave1Reference)) {
            $reference = Get-eMASW1dDossierProjection -Result $wave1References[[string]$group.wave1Reference] -RootPath 'EXTEDORIN 50mg Tablets EU-FR'
            $referenceName = 'Wave 1 ' + $group.wave1Reference
        }
        foreach ($member in @($group.members)) {
            $projection = Get-eMASW1dDossierProjection -Result $resultBySample[[string]$member.sampleId] -RootPath ([string]$member.rootPath)
            if ($null -eq $reference) { $reference = $projection; $referenceName = '{0}:{1}' -f $member.sampleId, $member.rootPath; continue }
            Assert-eMASW1dEqual $reference $projection ('{0}:{1} differs from {2}.' -f $member.sampleId, $member.rootPath, $referenceName)
        }
    }
}

# SD-051 normative v2 provenance -------------------------------------------------
Invoke-eMASW1dCheck -SampleId 'SD-051' -Category 'Normative' -Name 'historical characterization is retained and superseded by normative v2' -Action {
    Assert-eMASW1dTrue ([System.IO.File]::Exists($CharacterizationPath)) 'Historical SD-051 characterization file is missing.'
    Assert-eMASW1dEqual 'wave1d-sd051-characterization.json' $sd051Normative.supersedes 'Normative v2 provenance differs.'
    Assert-eMASW1dEqual 'NORMATIVE_B3_FO' $sd051Normative.statusLabel 'Normative v2 status label differs.'
    Assert-eMASW1dTrue (-not $RecordCharacterization) 'The superseded historical characterization must not be overwritten.'
}
$characterizationStatus = 'SUPERSEDED_BY_NORMATIVE_V2'

# Freeze gate (post) ----------------------------------------------------------------
foreach ($sampleId in $sourceState.Keys) {
    if ((Get-eMASW1dSha256 -Path $sourceState[$sampleId].Path) -ne $sourceState[$sampleId].Hash) { throw ('FREEZE-VERIFY-005 Wave1D fixture changed during the run: {0}' -f $sampleId) }
}
Write-Output ('[PASS] Post-test freeze gate verified {0} Wave1D fixtures unchanged.' -f $sourceState.Count)

$failureCount = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count
$summary = [pscustomobject][ordered]@{
    ContractId = $expectations.contractId
    TaskId = $expectations.taskId
    Capability = 'DossierDiversityWave1DRegression'
    Platform = [pscustomobject][ordered]@{ PSEdition = $PSVersionTable.PSEdition; PSVersion = $PSVersionTable.PSVersion.ToString(); OS = [string]$PSVersionTable['OS'] }
    ExpectationsSha256 = Get-eMASW1dSha256 -Path ([System.IO.Path]::GetFullPath($ExpectationsPath))
    SD051NormativeSha256 = Get-eMASW1dSha256 -Path ([System.IO.Path]::GetFullPath($SD051NormativePath))
    FreezeManifestSha256 = Get-eMASW1dSha256 -Path ([System.IO.Path]::GetFullPath($FreezeManifestPath))
    Wave1InvarianceReferences = [object[]]@($wave1References.Keys | Sort-Object)
    FixtureHashes = [object[]]@($sourceState.Keys | Sort-Object | ForEach-Object { [pscustomobject][ordered]@{ SampleId = $_; Sha256 = $sourceState[$_].Hash; Status = $sourceState[$_].Status } })
    CheckCount = $checks.Count
    PassCount = @($checks | Where-Object { $_.Status -eq 'PASS' }).Count
    FailCount = $failureCount
    NormativeFailCount = @($checks | Where-Object { $_.Status -eq 'FAIL' -and $_.Category -ne 'Characterization' }).Count
    CharacterizationStatus = $characterizationStatus
    OverallStatus = $(if ($failureCount -eq 0) { 'PASS' } else { 'FAIL' })
    Checks = [object[]]@($checks)
}
$summaryPath = Join-Path $resolvedOutputRoot 'dossier-diversity-test-summary.json'
Write-eMASW1dJson -Value $summary -Path $summaryPath
Write-Output ('Wave1D dossier-diversity tests completed: {0} ({1}/{2} checks); characterization={3}; summary={4}' -f $summary.OverallStatus, $summary.PassCount, $summary.CheckCount, $characterizationStatus, $summaryPath)
if ($failureCount -gt 0) { exit 1 }
