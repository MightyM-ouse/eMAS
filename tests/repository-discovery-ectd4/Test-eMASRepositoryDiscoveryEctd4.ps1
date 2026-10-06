#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    [string] $Wave1ERoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ([string]::IsNullOrWhiteSpace($Wave1ERoot)) {
    $Wave1ERoot = Join-Path $repositoryRoot 'tests/fixtures/repository-discovery-ectd4/wave1e'
}
$resolvedWave1ERoot = [System.IO.Path]::GetFullPath($Wave1ERoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)

Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceResolution.psm1') -Force -ErrorAction Stop

$expectationsPath = Join-Path $resolvedWave1ERoot 'wave1e-expectations.json'
$manifestPath = Join-Path $resolvedWave1ERoot 'WAVE1E_FREEZE_MANIFEST.csv'
$expectations = [System.IO.File]::ReadAllText($expectationsPath) | ConvertFrom-Json
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$checks = New-Object System.Collections.ArrayList
$additionalChecks = New-Object System.Collections.ArrayList
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-rd-v4-{0}' -f [guid]::NewGuid().ToString('N'))
$lockedPaths = New-Object System.Collections.ArrayList
$freezeState = @{}

function Get-eMASV4Sha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::OpenRead($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Assert-eMASV4True {
    param([bool] $Condition, [Parameter(Mandatory = $true)][string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-eMASV4Equal {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [Parameter(Mandatory = $true)][string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}

function Get-eMASV4SortedText {
    param([AllowEmptyCollection()][object[]] $Values)
    $text = [string[]]@($Values | ForEach-Object { [string]$_ })
    [System.Array]::Sort($text, [System.StringComparer]::Ordinal)
    return ($text -join "`n")
}

function ConvertTo-eMASV4Projection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ([pscustomobject][ordered]@{
        Candidates = [object[]]@($Result.DossierCandidates | ForEach-Object {
            [pscustomobject][ordered]@{ Id = $_.DossierId; Path = $_.RelativePath; Evidence = [object[]]@($_.DiscoveryEvidenceIds); Children = [object[]]@($_.DirectChildItems) }
        })
        Sequences = [object[]]@($Result.Sequences | ForEach-Object {
            [pscustomobject][ordered]@{ Id = $_.SequenceId; DossierId = $_.DossierId; Path = $_.RelativePath; Name = $_.FolderName; Exact = $_.IsExactSequenceFolder; Number = $_.SequenceNumber; Kind = $_.SequenceLikeKind; Parent = $_.ParentSequenceId; Files = $_.FileCount; Directories = $_.DirectoryCount }
        })
        Wrappers = [object[]]@($Result.Repository.WrapperPaths)
        Files = [object[]]@($Result.Files | ForEach-Object {
            [pscustomobject][ordered]@{ Id = $_.FileId; DossierId = $_.DossierId; SequenceId = $_.SequenceId; Path = $_.RelativePath; Size = $_.SizeBytes; Archive = $_.IsArchive }
        })
        Observations = [object[]]@($Result.Observations)
    } | ConvertTo-Json -Depth 64 -Compress)
}

function Test-eMASV4ExpectedResult {
    param([Parameter(Mandatory = $true)][object] $Fixture, [Parameter(Mandatory = $true)][object] $Result)
    $sampleId = [string]$Fixture.sampleId
    $expected = $Fixture.expected
    Assert-eMASV4Equal (Get-eMASV4SortedText @($expected.candidatePaths)) (Get-eMASV4SortedText @($Result.DossierCandidates | ForEach-Object { $_.RelativePath })) "$sampleId candidate paths differ."
    Assert-eMASV4Equal (Get-eMASV4SortedText @($expected.wrapperPaths)) (Get-eMASV4SortedText @($Result.Repository.WrapperPaths | ForEach-Object { $_.RelativePath })) "$sampleId wrapper paths differ."
    Assert-eMASV4Equal 0 @($Result.XmlDocuments).Count "$sampleId RepositoryDiscovery populated XmlDocuments."
    Assert-eMASV4Equal 0 @($Result.References).Count "$sampleId RepositoryDiscovery populated References."
    Assert-eMASV4Equal 0 @($Result.ClassificationEvidence).Count "$sampleId RepositoryDiscovery populated ClassificationEvidence."

    foreach ($expectedUnit in @($expected.units)) {
        $candidate = @($Result.DossierCandidates | Where-Object { [string]$_.RelativePath -eq [string]$expectedUnit.candidatePath })
        Assert-eMASV4Equal 1 $candidate.Count "$sampleId unit candidate lookup differs for $($expectedUnit.relativePath)."
        $sequence = @($Result.Sequences | Where-Object { [string]$_.RelativePath -eq [string]$expectedUnit.relativePath })
        Assert-eMASV4Equal 1 $sequence.Count "$sampleId unit count differs for $($expectedUnit.relativePath)."
        Assert-eMASV4Equal ([string]$expectedUnit.sequenceLikeKind) ([string]$sequence[0].SequenceLikeKind) "$sampleId unit kind differs for $($expectedUnit.relativePath)."
        Assert-eMASV4Equal ([bool]$expectedUnit.isExactSequenceFolder) ([bool]$sequence[0].IsExactSequenceFolder) "$sampleId exact flag differs for $($expectedUnit.relativePath)."
        Assert-eMASV4Equal $candidate[0].DossierId $sequence[0].DossierId "$sampleId dossier link differs for $($expectedUnit.relativePath)."
        if ($null -eq $expectedUnit.sequenceNumber) {
            Assert-eMASV4Equal $null $sequence[0].SequenceNumber "$sampleId sequence number differs for $($expectedUnit.relativePath)."
        }
        else {
            Assert-eMASV4Equal ([int]$expectedUnit.sequenceNumber) ([int]$sequence[0].SequenceNumber) "$sampleId sequence number differs for $($expectedUnit.relativePath)."
        }
    }
    Assert-eMASV4Equal @($expected.units).Count @($Result.Sequences).Count "$sampleId total unit count differs."

    foreach ($property in @($expected.observationCounts.PSObject.Properties)) {
        Assert-eMASV4Equal ([int]$property.Value) @($Result.Observations | Where-Object { $_.Code -eq $property.Name }).Count "$sampleId observation count differs for $($property.Name)."
    }
    $unplaced = @($Result.Observations | Where-Object { $_.Code -eq 'UnplacedSubmissionUnitMarker' } | ForEach-Object { $_.ObservedValue })
    Assert-eMASV4Equal (Get-eMASV4SortedText @($expected.unplacedSubmissionUnitMarkers)) (Get-eMASV4SortedText $unplaced) "$sampleId unplaced marker paths differ."
    foreach ($deniedPath in @($expected.accessDeniedPaths)) {
        Assert-eMASV4Equal 1 @($Result.Repository.Errors | Where-Object { $_.RelativePath -eq $deniedPath -and $_.CaptureStatus -eq 'AccessDenied' }).Count "$sampleId access diagnostic differs for $deniedPath."
    }

    $json = $Result | ConvertTo-Json -Depth 64 -Compress
    foreach ($forbiddenProperty in @('DetectedFormat', 'DetectedRegion', 'FormatConclusion', 'RegionConclusion')) {
        Assert-eMASV4True ($json -notmatch ('"{0}"\s*:' -f $forbiddenProperty)) "$sampleId emitted forbidden conclusion $forbiddenProperty."
    }
}

function Test-eMASV4DownstreamIsolation {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [Parameter(Mandatory = $true)][object] $Discovery, [Parameter(Mandatory = $true)][string] $SampleId)
    $specialIds = [string[]]@($Discovery.Sequences | Where-Object { $_.SequenceLikeKind -in @('SubmissionUnitFolder', 'DamagedSubmissionUnitCandidate', 'AmbiguousRegulatoryUnitFolder') } | ForEach-Object { $_.SequenceId })
    if ($specialIds.Count -eq 0) { return }
    Assert-eMASV4Equal 0 @($Discovery.Sequences | Where-Object { $_.SequenceId -in $specialIds -and $_.IsExactSequenceFolder }).Count "$SampleId special unit entered the exact v3 path."
    $xml = Invoke-eMASBackboneXmlInventory -SourcePath $SourcePath -RepositoryDiscoveryResult $Discovery
    Assert-eMASV4Equal 0 @($xml.XmlDocuments | Where-Object { $_.SequenceId -in $specialIds }).Count "$SampleId v4/ambiguous unit was probed by BackboneXmlInventory."
    Assert-eMASV4Equal 0 @($xml.Observations | Where-Object { $_.SubjectId -in $specialIds -and $_.Code -in @('MissingCommonBackbone', 'MissingRegionalBackbone') }).Count "$SampleId received a false v3 missing-backbone observation."
    $references = Invoke-eMASReferenceInventory -SourcePath $SourcePath -RepositoryDiscoveryResult $Discovery -BackboneXmlInventoryResult $xml
    Assert-eMASV4Equal 0 @($references.References | Where-Object { $_.SequenceId -in $specialIds }).Count "$SampleId v3 ReferenceInventory was extended to a v4/ambiguous unit."
    $resolved = Invoke-eMASReferenceResolution -SourcePath $SourcePath -RepositoryDiscoveryResult $Discovery -ReferenceInventoryResult $references
    Assert-eMASV4Equal 0 @($resolved.References | Where-Object { $_.SequenceId -in $specialIds }).Count "$SampleId v3 ReferenceResolution was extended to a v4/ambiguous unit."
}

try {
    [void][System.IO.Directory]::CreateDirectory($temporaryRoot)
    foreach ($row in $manifestRows) {
        Assert-eMASV4Equal 'FROZEN' $row.Status "Wave1E manifest status differs for $($row.SampleId)."
        $path = Join-Path $resolvedWave1ERoot ($row.FixtureFilename -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        Assert-eMASV4True ([System.IO.File]::Exists($path)) "Wave1E fixture is missing: $($row.SampleId)."
        $hash = Get-eMASV4Sha256 $path
        Assert-eMASV4Equal $row.FixtureSHA256 $hash "Wave1E fixture hash differs for $($row.SampleId)."
        $freezeState[$row.SampleId] = [pscustomobject]@{ Path = $path; Hash = $hash; WriteTime = (Get-Item -LiteralPath $path).LastWriteTimeUtc }
    }

    foreach ($fixture in @($expectations.fixtures)) {
        $sampleId = [string]$fixture.sampleId
        try {
            $state = $freezeState[$sampleId]
            if ($fixture.sourceMode -eq 'DirectoryAccess') {
                $source = Join-Path $temporaryRoot $sampleId
                [System.IO.Compression.ZipFile]::ExtractToDirectory($state.Path, $source)
                foreach ($relativePath in @($fixture.expected.accessDeniedPaths)) {
                    $lockedPath = Join-Path $source ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                    & /bin/chmod 000 $lockedPath
                    [void]$lockedPaths.Add($lockedPath)
                }
                $result = Invoke-eMASRepositoryDiscovery -SourcePath $source -ExecutionId "EXEC-V4-$sampleId-DIR"
                Test-eMASV4ExpectedResult -Fixture $fixture -Result $result
                foreach ($lockedPath in @($lockedPaths)) { & /bin/chmod 700 $lockedPath }
                $lockedPaths.Clear()
            }
            else {
                $zipResult = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId "EXEC-V4-$sampleId-ZIP"
                $repeatResult = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId "EXEC-V4-$sampleId-REPEAT"
                $source = Join-Path $temporaryRoot $sampleId
                [System.IO.Compression.ZipFile]::ExtractToDirectory($state.Path, $source)
                $directoryResult = Invoke-eMASRepositoryDiscovery -SourcePath $source -ExecutionId "EXEC-V4-$sampleId-DIR"
                Test-eMASV4ExpectedResult -Fixture $fixture -Result $zipResult
                Test-eMASV4ExpectedResult -Fixture $fixture -Result $directoryResult
                Assert-eMASV4Equal (ConvertTo-eMASV4Projection $zipResult) (ConvertTo-eMASV4Projection $repeatResult) "$sampleId repeat projection differs."
                Assert-eMASV4Equal (ConvertTo-eMASV4Projection $zipResult) (ConvertTo-eMASV4Projection $directoryResult) "$sampleId ZIP/directory projection differs."
                Test-eMASV4DownstreamIsolation -SourcePath $state.Path -Discovery $zipResult -SampleId $sampleId
            }
            [void]$checks.Add([pscustomobject][ordered]@{ SampleId = $sampleId; Status = 'PASS'; Detail = $null })
            Write-Output "[PASS] $sampleId $($fixture.scenarioId)"
        }
        catch {
            [void]$checks.Add([pscustomobject][ordered]@{ SampleId = $sampleId; Status = 'FAIL'; Detail = $_.Exception.Message })
            Write-Output "[FAIL] $sampleId $($fixture.scenarioId): $($_.Exception.Message)"
        }
        finally {
            foreach ($lockedPath in @($lockedPaths)) { if ([System.IO.Directory]::Exists($lockedPath)) { & /bin/chmod 700 $lockedPath } }
            $lockedPaths.Clear()
        }
    }

    foreach ($case in @(
        [pscustomobject]@{
            Name = 'classified v4 unit suppresses a deeper candidate'
            Files = @('Container/1/submissionunit.xml', 'Container/1/Embedded/2/submissionunit.xml')
            Candidates = @('Container')
        },
        [pscustomobject]@{
            Name = 'numeric-looking unclassified segment does not suppress a deeper candidate'
            Files = @('Container/12/submissionunit.xml', 'Container/123/Embedded/2/submissionunit.xml')
            Candidates = @('Container', 'Container/123/Embedded')
        }
    )) {
        try {
            $caseRoot = Join-Path $temporaryRoot ('nested-{0}' -f $additionalChecks.Count)
            foreach ($relativePath in $case.Files) {
                $path = Join-Path $caseRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($path))
                [System.IO.File]::WriteAllText($path, '<discovery-stub />', (New-Object System.Text.UTF8Encoding($false)))
            }
            $caseResult = Invoke-eMASRepositoryDiscovery -SourcePath $caseRoot -ExecutionId ('EXEC-V4-NESTED-{0}' -f $additionalChecks.Count)
            Assert-eMASV4Equal (Get-eMASV4SortedText $case.Candidates) (Get-eMASV4SortedText @($caseResult.DossierCandidates | ForEach-Object { $_.RelativePath })) $case.Name
            [void]$additionalChecks.Add([pscustomobject][ordered]@{ Name = $case.Name; Status = 'PASS'; Detail = $null })
            Write-Output "[PASS] $($case.Name)"
        }
        catch {
            [void]$additionalChecks.Add([pscustomobject][ordered]@{ Name = $case.Name; Status = 'FAIL'; Detail = $_.Exception.Message })
            Write-Output "[FAIL] $($case.Name): $($_.Exception.Message)"
        }
    }

    foreach ($row in $manifestRows) {
        $state = $freezeState[$row.SampleId]
        Assert-eMASV4Equal $state.Hash (Get-eMASV4Sha256 $state.Path) "Post-test fixture hash differs for $($row.SampleId)."
        Assert-eMASV4Equal $state.WriteTime (Get-Item -LiteralPath $state.Path).LastWriteTimeUtc "Post-test fixture timestamp differs for $($row.SampleId)."
    }
}
finally {
    foreach ($lockedPath in @($lockedPaths)) { if ([System.IO.Directory]::Exists($lockedPath)) { & /bin/chmod 700 $lockedPath } }
    if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
}

$failureCount = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count + @($additionalChecks | Where-Object { $_.Status -eq 'FAIL' }).Count
$summary = [pscustomobject][ordered]@{
    Capability = 'RepositoryDiscoveryEctd4PhysicalDiscovery'
    FixtureSet = 'Wave1E'
    FixtureCount = $checks.Count
    PassCount = @($checks | Where-Object { $_.Status -eq 'PASS' }).Count
    AdditionalCheckCount = $additionalChecks.Count
    AdditionalPassCount = @($additionalChecks | Where-Object { $_.Status -eq 'PASS' }).Count
    FailCount = $failureCount
    FreezeGateCount = $manifestRows.Count
    ZipDirectoryEquivalenceCount = @($expectations.fixtures | Where-Object { $_.sourceMode -eq 'ZipAndDirectory' }).Count
    OverallStatus = $(if ($failureCount -eq 0) { 'PASS' } else { 'FAIL' })
    Checks = [object[]]@($checks)
    AdditionalChecks = [object[]]@($additionalChecks)
}
$summaryPath = Join-Path $resolvedOutputRoot 'repository-discovery-ectd4-test-summary.json'
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 16), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('RepositoryDiscovery eCTD v4 tests completed: {0} ({1}/{2} fixtures; {3}/{4} additional); summary={5}' -f $summary.OverallStatus, $summary.PassCount, $summary.FixtureCount, $summary.AdditionalPassCount, $summary.AdditionalCheckCount, $summaryPath)
if ($failureCount -gt 0) { exit 1 }
