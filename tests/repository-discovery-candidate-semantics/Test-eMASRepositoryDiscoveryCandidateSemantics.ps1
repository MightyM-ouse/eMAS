#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CorpusRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$modulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)
Import-Module -Name $modulePath -Force -ErrorAction Stop
$script:eMASB3PhysicalMarkerEvidenceTypes = @(
    'RegulatoryUnitKind',
    'SubmissionUnitMarkerFile',
    'TocFileMarker',
    'ChecksumFileMarker',
    'UtilityDtdFolderMarker'
)

$checks = New-Object System.Collections.ArrayList
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-rd-b3-{0}' -f [guid]::NewGuid().ToString('N'))
$sourceRoot = Join-Path $temporaryRoot 'source'
$lockedPaths = New-Object System.Collections.ArrayList

function Assert-eMASB3True {
    param([bool] $Condition, [Parameter(Mandatory = $true)][string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-eMASB3Equal {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [Parameter(Mandatory = $true)][string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}

function Get-eMASB3SortedText {
    param([AllowEmptyCollection()][string[]] $Values)
    $sorted = [string[]]@($Values)
    [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return ($sorted -join "`n")
}

function Get-eMASB3HistoricalClassificationEvidence {
    param([AllowEmptyCollection()][object[]] $Records)
    return @($Records | Where-Object { $script:eMASB3PhysicalMarkerEvidenceTypes -notcontains $_.EvidenceType })
}

function Invoke-eMASB3Check {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)
    try {
        & $Action
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

function Add-eMASB3Directory {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    $path = Join-Path $sourceRoot $RelativePath
    [void][System.IO.Directory]::CreateDirectory($path)
    return $path
}

function Add-eMASB3File {
    param([Parameter(Mandatory = $true)][string] $RelativePath, [string] $Content = 'synthetic')
    $path = Join-Path $sourceRoot $RelativePath
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($path))
    [System.IO.File]::WriteAllText($path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-eMASB3Result {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [Parameter(Mandatory = $true)][string] $ExecutionId)
    return Invoke-eMASRepositoryDiscovery -SourcePath $SourcePath -ExecutionId $ExecutionId
}

try {
    [void][System.IO.Directory]::CreateDirectory($sourceRoot)

    Add-eMASB3File 'Exports/2024/ProductABC/0001/M1/document.pdf'
    Add-eMASB3File 'Exports/2024/Archive/2019/annual-report.pdf'
    Add-eMASB3File 'Signals/Module/0001/m5/document.pdf'
    Add-eMASB3File 'Signals/Index/0001/INDEX.XML' '<ectd />'
    Add-eMASB3File 'Signals/Submission/0001/SubMissionUnit.XML' '<submission-unit />'
    Add-eMASB3File 'Signals/NestedOnly/0001/other/m1/document.pdf'
    Add-eMASB3File 'Signals/Structureless/0001/readme.txt'
    Add-eMASB3File 'Signals/AnySequence/0001/readme.txt'
    Add-eMASB3File 'Signals/AnySequence/0002/m2/document.pdf'
    Add-eMASB3File 'NonV4Expansion/submission/SubMissionUnit.XML' '<submission-unit />'
    Add-eMASB3File 'RootDossier/0001/m1/document.pdf'

    $accessExact = Add-eMASB3Directory 'AccessExact/0001'
    $descendantLocked = Add-eMASB3Directory 'DescendantGap/0001/other/locked/child'
    $descendantLocked = [System.IO.Path]::GetDirectoryName($descendantLocked)
    & /bin/chmod 000 $accessExact
    [void]$lockedPaths.Add($accessExact)
    & /bin/chmod 000 $descendantLocked
    [void]$lockedPaths.Add($descendantLocked)

    $directoryResult = Get-eMASB3Result -SourcePath $sourceRoot -ExecutionId 'EXEC-RD-B3-DIRECTORY'

    Invoke-eMASB3Check -Name 'year wrapper is preserved without promotion and genuine dossier is discovered' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -contains 'Exports/2024/ProductABC') 'Genuine dossier below the year wrapper was not discovered.'
        Assert-eMASB3True ($paths -notcontains 'Exports') 'Year-wrapper parent was promoted as a dossier.'
        Assert-eMASB3True ($paths -notcontains 'Exports/2024/Archive') 'Structureless numeric parent was promoted as a dossier.'
        $wrapperPaths = [string[]]@($directoryResult.Repository.WrapperPaths | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($wrapperPaths -contains 'Exports') 'Outer wrapper path was not retained.'
        Assert-eMASB3True ($wrapperPaths -contains 'Exports/2024') 'Year wrapper path was not retained.'
    }

    Invoke-eMASB3Check -Name 'direct CTD module signal m1 through m5 is case-insensitive' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -contains 'Signals/Module') 'Direct mixed-case m5 signal did not qualify the parent.'
    }

    Invoke-eMASB3Check -Name 'direct index.xml signal is case-insensitive' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -contains 'Signals/Index') 'Direct mixed-case index.xml signal did not qualify the parent.'
    }

    Invoke-eMASB3Check -Name 'direct submissionunit.xml signal is case-insensitive without expanding the sequence gate' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -contains 'Signals/Submission') 'Direct mixed-case submissionunit.xml signal did not qualify the parent.'
        Assert-eMASB3True ($paths -notcontains 'NonV4Expansion') 'Discovery expanded beyond direct exact four-digit sequence children.'
    }

    Invoke-eMASB3Check -Name 'nested-only dossier signals do not qualify a parent' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -notcontains 'Signals/NestedOnly') 'Nested m1 signal incorrectly qualified the parent.'
    }

    Invoke-eMASB3Check -Name 'structureless numeric parent is not promoted' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -notcontains 'Signals/Structureless') 'Structureless numeric parent was promoted.'
    }

    Invoke-eMASB3Check -Name 'any qualifying exact sequence promotes the parent and retains all exact sequences' -Action {
        $candidate = @($directoryResult.DossierCandidates | Where-Object { $_.RelativePath -eq 'Signals/AnySequence' })[0]
        Assert-eMASB3True ($null -ne $candidate) 'Parent with a qualifying second sequence was not promoted.'
        $folders = [string[]]@($directoryResult.Sequences | Where-Object { $_.DossierId -eq $candidate.DossierId -and $_.IsExactSequenceFolder } | ForEach-Object { $_.FolderName })
        Assert-eMASB3Equal ("0001`n0002") (Get-eMASB3SortedText $folders) 'Exact sequence inventory differs.'
    }

    Invoke-eMASB3Check -Name 'unreadable exact sequence fails open without an empty-sequence observation' -Action {
        $candidate = @($directoryResult.DossierCandidates | Where-Object { $_.RelativePath -eq 'AccessExact' })[0]
        Assert-eMASB3True ($null -ne $candidate) 'Unreadable exact sequence did not fail open.'
        $sequence = @($directoryResult.Sequences | Where-Object { $_.DossierId -eq $candidate.DossierId -and $_.RelativePath -eq 'AccessExact/0001' })[0]
        Assert-eMASB3Equal 1 @($directoryResult.Repository.Errors | Where-Object { $_.RelativePath -eq 'AccessExact/0001' -and $_.CaptureStatus -eq 'AccessDenied' }).Count 'Unreadable exact sequence access error was not retained.'
        Assert-eMASB3Equal 0 @($directoryResult.Observations | Where-Object { $_.SubjectId -eq $sequence.SequenceId -and $_.Code -eq 'EmptyExactSequenceFolder' }).Count 'Unreadable exact sequence was reported as empty.'
    }

    Invoke-eMASB3Check -Name 'unreadable deeper descendant does not fail open the exact sequence' -Action {
        $paths = [string[]]@($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASB3True ($paths -notcontains 'DescendantGap') 'Unreadable descendant incorrectly qualified the parent.'
    }

    Invoke-eMASB3Check -Name 'root-level dossier remains discoverable under the bounded rule' -Action {
        $rootResult = Get-eMASB3Result -SourcePath (Join-Path $sourceRoot 'RootDossier') -ExecutionId 'EXEC-RD-B3-ROOT'
        Assert-eMASB3Equal 1 @($rootResult.DossierCandidates).Count 'Root-level dossier candidate count differs.'
        Assert-eMASB3Equal '' ([string]$rootResult.DossierCandidates[0].RelativePath) 'Root-level dossier path differs.'
    }

    Invoke-eMASB3Check -Name 'year-wrapped SD-002 retains the accepted end-to-end projection' -Action {
        $sd002Zip = Join-Path ([System.IO.Path]::GetFullPath($CorpusRoot)) 'fixtures/SD-002/fixture.zip'
        Assert-eMASB3True ([System.IO.File]::Exists($sd002Zip)) 'Frozen SD-002 fixture is missing.'
        $sd002Extracted = Join-Path $temporaryRoot 'sd002-extracted'
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sd002Zip, $sd002Extracted)
        $dossierRoots = [System.IO.Directory]::GetDirectories($sd002Extracted)
        Assert-eMASB3Equal 1 $dossierRoots.Count 'SD-002 extracted dossier-root count differs.'
        $wrappedDossier = Join-Path $temporaryRoot 'year-wrapper/Exports/2024/ProductABC'
        [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($wrappedDossier))
        Copy-Item -LiteralPath $dossierRoots[0] -Destination $wrappedDossier -Recurse
        $wrappedOutput = Join-Path $resolvedOutputRoot 'year-wrapped-sd002.json'
        $wrapped = & $entryScriptPath -SourcePath (Join-Path $temporaryRoot 'year-wrapper') -OutputPath $wrappedOutput -ExecutionId 'EXEC-RD-B3-YEAR-WRAPPER' -IncludeClassificationEvidenceCollection
        Assert-eMASB3Equal 1 @($wrapped.DossierCandidates).Count 'Year-wrapped SD-002 candidate count differs.'
        Assert-eMASB3Equal 'Exports/2024/ProductABC' ([string]$wrapped.DossierCandidates[0].RelativePath) 'Year-wrapped SD-002 dossier path differs.'
        Assert-eMASB3Equal 94 @($wrapped.References).Count 'Year-wrapped SD-002 reference count differs.'
        Assert-eMASB3Equal 93 @($wrapped.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedPresent' }).Count 'Year-wrapped SD-002 resolved-present count differs.'
        $fullRecords = @($wrapped.ClassificationEvidence)
        $historicalRecords = @(Get-eMASB3HistoricalClassificationEvidence -Records $fullRecords)
        Assert-eMASB3Equal 86 $historicalRecords.Count 'Year-wrapped SD-002 historical classification-evidence count differs.'
        Assert-eMASB3Equal 101 $fullRecords.Count 'Year-wrapped SD-002 additive classification-evidence count differs.'
        $coverage = @($wrapped.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASB3Equal 1 $coverage.Count 'Year-wrapped SD-002 CEC repository coverage count differs.'
        Assert-eMASB3Equal $fullRecords.Count $coverage[0].RecordsProduced 'Year-wrapped SD-002 CEC records-produced differs from the full additive result.'
    }

    foreach ($lockedPath in @($lockedPaths)) { & /bin/chmod 700 $lockedPath }
    $lockedPaths.Clear()

    $zipPath = Join-Path $temporaryRoot 'source.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceRoot, $zipPath)
    $zipResult = Get-eMASB3Result -SourcePath $zipPath -ExecutionId 'EXEC-RD-B3-ZIP'
    Invoke-eMASB3Check -Name 'directory and ZIP candidate and wrapper projections are deterministic' -Action {
        $directoryCandidates = Get-eMASB3SortedText ([string[]]@($directoryResult.DossierCandidates | Where-Object { $_.RelativePath -notin @('AccessExact', 'DescendantGap') } | ForEach-Object { $_.RelativePath }))
        $zipCandidates = Get-eMASB3SortedText ([string[]]@($zipResult.DossierCandidates | Where-Object { $_.RelativePath -notin @('AccessExact', 'DescendantGap') } | ForEach-Object { $_.RelativePath }))
        Assert-eMASB3Equal $directoryCandidates $zipCandidates 'Directory and ZIP candidate paths differ.'
        $directoryWrappers = Get-eMASB3SortedText ([string[]]@($directoryResult.Repository.WrapperPaths | ForEach-Object { $_.RelativePath }))
        $zipWrappers = Get-eMASB3SortedText ([string[]]@($zipResult.Repository.WrapperPaths | ForEach-Object { $_.RelativePath }))
        Assert-eMASB3Equal $directoryWrappers $zipWrappers 'Directory and ZIP wrapper paths differ.'
    }
}
finally {
    foreach ($lockedPath in @($lockedPaths)) {
        if ([System.IO.Directory]::Exists($lockedPath)) { & /bin/chmod 700 $lockedPath }
    }
    if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
}

$failureCount = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count
$summary = [pscustomobject][ordered]@{
    Capability = 'RepositoryDiscoveryCandidateSemanticsB3'
    Platform = [pscustomobject][ordered]@{ PSEdition = $PSVersionTable.PSEdition; PSVersion = $PSVersionTable.PSVersion.ToString(); OS = $PSVersionTable.OS }
    CheckCount = $checks.Count
    PassCount = @($checks | Where-Object { $_.Status -eq 'PASS' }).Count
    FailCount = $failureCount
    OverallStatus = $(if ($failureCount -eq 0) { 'PASS' } else { 'FAIL' })
    Checks = [object[]]@($checks)
}
$summaryPath = Join-Path $resolvedOutputRoot 'repository-discovery-candidate-semantics-test-summary.json'
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 16), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('RepositoryDiscovery B3 candidate-semantics tests completed: {0} ({1}/{2}); summary={3}' -f $summary.OverallStatus, $summary.PassCount, $summary.CheckCount, $summaryPath)
if ($failureCount -gt 0) { exit 1 }
