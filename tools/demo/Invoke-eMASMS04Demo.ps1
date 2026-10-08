#requires -Version 7.0
<#
.SYNOPSIS
One-click MS-04 Pre-Sales development runner for macOS PowerShell 7.

.DESCRIPTION
Runs existing, committed eMAS harnesses and the real Pre-Sales script as child
"pwsh -NoProfile -NonInteractive -File" processes and records what actually
happened. It does not assess dossiers, generate configuration or decide
business rules itself.

Modes:
  QuickCheck      preflight, committed freeze manifests, focused T2, T4 engine, T4 oracle
  FullRegression  the 15 established gates plus focused T2; corpus-dependent suites SKIP
                  when the external corpora are not supplied
  MS04Demo        the real scripts/eMAS-PreSalesAssessment.ps1 on a supplied dossier;
                  identification needs a supplied Runtime JSON, and VERIFIED needs a
                  supplied independent expected Identification/1.0 document

Every run writes a new directory under -OutputRoot containing run-manifest.json,
summary.html and per-stage logs and observed JSON. The repository, source,
configuration and corpora are only read.

Exit codes (-ExitCodePolicy Strict, the default): 0 PASS/VERIFIED, 1 FAIL, 2 PASS_WITH_SKIPS,
3 EXECUTED_UNVERIFIED/UNVERIFIED, 4 BLOCKED, 5 INCOMPLETE, 6 refused before a run directory
could be created. With -ExitCodePolicy Task (used by the VS Code tasks), PASS_WITH_SKIPS and
EXECUTED_UNVERIFIED also exit 0 so the editor does not report a completed run as "failed";
the qualified OverallStatus in the manifest, report and terminal banner is unchanged.

.EXAMPLE
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode QuickCheck

.EXAMPLE
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode FullRegression -Wave1CorpusRoot ~/eMAS-corpora/wave1 -Wave1DCorpusRoot ~/eMAS-corpora/wave1d

.EXAMPLE
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode MS04Demo -SourcePath ~/dossiers/example.zip -RuntimeConfigurationPath ~/configs/runtime.json
#>
[CmdletBinding()]
param(
    [ValidateSet('QuickCheck', 'FullRegression', 'MS04Demo')]
    [string] $Mode = 'QuickCheck',

    # Parent directory for run directories; default ~/eMAS-MS04-Runs. Must be outside the repository, source, configuration and corpora.
    [string] $OutputRoot,

    # External frozen Wave 1 corpus (contains fixtures/SD-0nn/fixture.zip and WAVE1_FREEZE_MANIFEST.csv).
    [string] $Wave1CorpusRoot,
    [string] $Wave1FreezeManifestPath,

    # External Wave1D dossier-diversity package (contains WAVE1D_FREEZE_MANIFEST.csv).
    [string] $Wave1DCorpusRoot,

    # MS04Demo: dossier directory or ZIP.
    [string] $SourcePath,

    # MS04Demo: Runtime JSON. Without it identification is BLOCKED.
    [string] $RuntimeConfigurationPath,

    # MS04Demo: independent expected Identification/1.0 document. Without it the demo is EXECUTED_UNVERIFIED at best.
    [string] $ExpectedIdentificationPath,

    # MS04Demo: request the T2 SubmissionUnit XML inventory capability.
    [ValidateSet('Exclude', 'Include')]
    [string] $SubmissionUnitXmlInventory = 'Exclude',

    # MS04Demo: execution id passed to the Pre-Sales script; generated when omitted.
    [string] $ExecutionId,

    [ValidateRange(1, 86400)]
    [int] $StageTimeoutSeconds = 1800,

    # Optional untracked local settings (JSON with OutputRoot, Wave1CorpusRoot, Wave1FreezeManifestPath, Wave1DCorpusRoot).
    # Default ~/.config/emas/ms04-demo-runner.json. Explicit parameters win.
    [string] $UserSettingsPath,
    [switch] $NoUserSettings,

    # Open summary.html in the default browser when the run ends. Failure to open never changes the verdict.
    [switch] $OpenReport,

    # Strict: distinct non-zero code per qualified result. Task: completed runs without a failure exit 0 (VS Code tasks).
    [ValidateSet('Strict', 'Task')]
    [string] $ExitCodePolicy = 'Strict'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$RunnerVersion = '1.0.0'
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$privateRoot = Join-Path $PSScriptRoot 'private'
Import-Module (Join-Path $privateRoot 'eMAS.MS04DemoRunner.psm1') -Force
Import-Module (Join-Path $privateRoot 'eMAS.MS04DemoReport.psm1') -Force
$catalogPath = Join-Path $privateRoot 'eMAS.MS04SuiteCatalog.psd1'
$catalog = Import-PowerShellDataFile -LiteralPath $catalogPath
$preSalesScript = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
$scannerContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
$identificationContractId = 'eMAS.MS04.PreSales.Identification/1.0'

function Write-eMASRunnerLine { param([string] $Text = '') [Console]::Out.WriteLine($Text) }

function Stop-eMASRunnerBeforeRun {
    param([Parameter(Mandatory = $true)][string] $Message)
    [Console]::Error.WriteLine('eMAS MS-04 runner refused to start: ' + $Message)
    [Console]::Error.WriteLine('No run directory was created and no input was modified.')
    exit 6
}

function ConvertTo-eMASUserPath {
    # Trims pasted quotes and expands a leading ~; returns $null for empty input.
    param([AllowNull()][AllowEmptyString()][string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2 -and (($trimmed[0] -eq '"' -and $trimmed[-1] -eq '"') -or ($trimmed[0] -eq "'" -and $trimmed[-1] -eq "'"))) { $trimmed = $trimmed.Substring(1, $trimmed.Length - 2) }
    if ($trimmed -eq '~') { $trimmed = $HOME }
    elseif ($trimmed.StartsWith('~/')) { $trimmed = Join-Path $HOME $trimmed.Substring(2) }
    if ([string]::IsNullOrWhiteSpace($trimmed)) { return $null }
    return $trimmed
}

function Resolve-eMASUserPath {
    param([AllowNull()][string] $Value, [Parameter(Mandatory = $true)][string] $Role)
    $path = ConvertTo-eMASUserPath -Value $Value
    if ($null -eq $path) { return $null }
    if (-not [System.IO.Path]::IsPathRooted($path)) { Stop-eMASRunnerBeforeRun ('{0} must be an absolute path (or start with ~/): {1}' -f $Role, $path) }
    if (Test-eMASPathHasTraversal -Path $path) { Stop-eMASRunnerBeforeRun ('{0} must not contain ".." segments: {1}' -f $Role, $path) }
    return [System.IO.Path]::GetFullPath($path)
}

# ---------------------------------------------------------------------------
# Settings and inputs
# ---------------------------------------------------------------------------

$settings = @{}
$settingsSource = 'Disabled'
if (-not $NoUserSettings) {
    $settingsFile = Resolve-eMASUserPath -Value $(if ([string]::IsNullOrWhiteSpace($UserSettingsPath)) { Join-Path $HOME '.config/emas/ms04-demo-runner.json' } else { $UserSettingsPath }) -Role 'UserSettingsPath'
    if ([System.IO.File]::Exists($settingsFile)) {
        try { $parsed = [System.IO.File]::ReadAllText($settingsFile) | ConvertFrom-Json -AsHashtable }
        catch { Stop-eMASRunnerBeforeRun ('user settings file is not valid JSON: {0} ({1})' -f $settingsFile, $_.Exception.Message) }
        $allowed = @('OutputRoot', 'Wave1CorpusRoot', 'Wave1FreezeManifestPath', 'Wave1DCorpusRoot')
        foreach ($key in @($parsed.Keys)) {
            if ($allowed -notcontains $key) { Stop-eMASRunnerBeforeRun ('user settings key "{0}" is not supported (allowed: {1}): {2}' -f $key, ($allowed -join ', '), $settingsFile) }
            $settings[$key] = [string]$parsed[$key]
        }
        $settingsSource = $settingsFile
    }
    elseif (-not [string]::IsNullOrWhiteSpace($UserSettingsPath)) { Stop-eMASRunnerBeforeRun ('user settings file not found: {0}' -f $settingsFile) }
    else { $settingsSource = 'NotPresent: ' + $settingsFile }
}

function Get-eMASSetting {
    param([Parameter(Mandatory = $true)][string] $Name, [AllowNull()][string] $ParameterValue)
    if (-not [string]::IsNullOrWhiteSpace($ParameterValue)) { return [pscustomobject]@{ Value = (Resolve-eMASUserPath -Value $ParameterValue -Role $Name); Origin = 'Parameter' } }
    if ($settings.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($settings[$Name])) { return [pscustomobject]@{ Value = (Resolve-eMASUserPath -Value $settings[$Name] -Role $Name); Origin = 'UserSettings' } }
    return [pscustomobject]@{ Value = $null; Origin = 'NotSupplied' }
}

$outputSetting = Get-eMASSetting -Name 'OutputRoot' -ParameterValue $OutputRoot
if ($null -eq $outputSetting.Value) { $outputSetting = [pscustomobject]@{ Value = [System.IO.Path]::GetFullPath((Join-Path $HOME 'eMAS-MS04-Runs')); Origin = 'Default' } }
$wave1Setting = Get-eMASSetting -Name 'Wave1CorpusRoot' -ParameterValue $Wave1CorpusRoot
$wave1ManifestSetting = Get-eMASSetting -Name 'Wave1FreezeManifestPath' -ParameterValue $Wave1FreezeManifestPath
if ($null -eq $wave1ManifestSetting.Value -and $null -ne $wave1Setting.Value) { $wave1ManifestSetting = [pscustomobject]@{ Value = (Join-Path $wave1Setting.Value 'WAVE1_FREEZE_MANIFEST.csv'); Origin = 'DerivedFromWave1CorpusRoot' } }
$wave1DSetting = Get-eMASSetting -Name 'Wave1DCorpusRoot' -ParameterValue $Wave1DCorpusRoot
$sourceValue = Resolve-eMASUserPath -Value $SourcePath -Role 'SourcePath'
$configValue = Resolve-eMASUserPath -Value $RuntimeConfigurationPath -Role 'RuntimeConfigurationPath'
$expectedValue = Resolve-eMASUserPath -Value $ExpectedIdentificationPath -Role 'ExpectedIdentificationPath'

if ($Mode -ne 'MS04Demo') {
    foreach ($pair in @(@('SourcePath', $sourceValue), @('RuntimeConfigurationPath', $configValue), @('ExpectedIdentificationPath', $expectedValue))) {
        if ($null -ne $pair[1]) { Stop-eMASRunnerBeforeRun ('{0} is only used by -Mode MS04Demo.' -f $pair[0]) }
    }
}

# Protected locations: no output may be written inside any of them.
$protectedRoots = [ordered]@{ 'repository' = $repositoryRoot }
if ($null -ne $sourceValue) { $protectedRoots['source'] = $sourceValue }
if ($null -ne $configValue) { $protectedRoots['runtime configuration directory'] = (Split-Path -Parent $configValue) }
if ($null -ne $expectedValue) { $protectedRoots['expected-outcome directory'] = (Split-Path -Parent $expectedValue) }
if ($null -ne $wave1Setting.Value) { $protectedRoots['Wave 1 corpus'] = $wave1Setting.Value }
if ($null -ne $wave1ManifestSetting.Value) { $protectedRoots['Wave 1 manifest directory'] = (Split-Path -Parent $wave1ManifestSetting.Value) }
if ($null -ne $wave1DSetting.Value) { $protectedRoots['Wave1D corpus'] = $wave1DSetting.Value }

try { $resolvedOutputRoot = Resolve-eMASOutputRoot -OutputRoot $outputSetting.Value -ProtectedRoots $protectedRoots }
catch { Stop-eMASRunnerBeforeRun $_.Exception.Message }

$startedAtUtc = [DateTime]::UtcNow
$runId = New-eMASRunId -Mode $Mode -StartedAtUtc $startedAtUtc
try { $runDirectory = New-eMASRunDirectory -OutputRoot $resolvedOutputRoot -RunId $runId }
catch { Stop-eMASRunnerBeforeRun $_.Exception.Message }
$stagesDirectory = Join-Path $runDirectory 'stages'
[void][System.IO.Directory]::CreateDirectory($stagesDirectory)
$manifestPath = Join-Path $runDirectory 'run-manifest.json'
$summaryPath = Join-Path $runDirectory 'summary.html'
$pwshPath = Get-eMASPwshPath
$runWatch = [System.Diagnostics.Stopwatch]::StartNew()

# ---------------------------------------------------------------------------
# Manifest skeleton
# ---------------------------------------------------------------------------

$gitStart = Get-eMASGitState -RepositoryRoot $repositoryRoot
$manifest = [ordered]@{
    ContractId = 'eMAS.MS04.DemoRunner.RunManifest/1.0'
    Runner = [ordered]@{
        Name = 'Invoke-eMASMS04Demo'; Version = $RunnerVersion
        ScriptPath = 'tools/demo/Invoke-eMASMS04Demo.ps1'; ScriptSha256 = Get-eMASFileSha256 -Path $PSCommandPath
        CatalogVersion = $catalog.CatalogVersion; CatalogSha256 = Get-eMASFileSha256 -Path $catalogPath
        PrivateModuleSha256 = [ordered]@{
            'eMAS.MS04DemoRunner.psm1' = Get-eMASFileSha256 -Path (Join-Path $privateRoot 'eMAS.MS04DemoRunner.psm1')
            'eMAS.MS04DemoReport.psm1' = Get-eMASFileSha256 -Path (Join-Path $privateRoot 'eMAS.MS04DemoReport.psm1')
        }
        UserSettings = $settingsSource
        StageTimeoutSeconds = $StageTimeoutSeconds
    }
    Run = [ordered]@{
        RunId = $runId; Mode = $Mode; State = 'InProgress'
        StartedAtUtc = $startedAtUtc.ToString('o'); CompletedAtUtc = $null; ElapsedSeconds = $null
        OverallStatus = 'INCOMPLETE'; OverallReason = 'Run in progress.'; ExitCode = $null; StrictExitCode = $null; ExitCodePolicy = $ExitCodePolicy
        ScenarioId = 'MS-04'; Phase = 'PreSales'
    }
    Repository = [ordered]@{
        Root = $repositoryRoot; GitAvailable = $gitStart.Available; HeadSha = $gitStart.HeadSha; Branch = $gitStart.Branch
        WorktreeClean = $gitStart.WorktreeClean; StatusEntryCount = $gitStart.StatusEntryCount; GitError = $gitStart.Error
    }
    Platform = Get-eMASPlatformInfo
    Inputs = New-Object System.Collections.ArrayList
    Stages = New-Object System.Collections.ArrayList
    Coverage = $null
    Limitations = New-Object System.Collections.ArrayList
    Outputs = [ordered]@{ RunDirectory = $runDirectory; Manifest = $manifestPath; SummaryHtml = $summaryPath; StagesDirectory = $stagesDirectory }
}

function Save-eMASRunEvidence {
    $manifest.Coverage = Get-eMASCoverage -Stages @($manifest.Stages)
    Write-eMASJsonFile -Value $manifest -Path $manifestPath
    $snapshot = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($manifestPath))
    Write-eMASTextFile -Text (New-eMASRunSummaryHtml -Manifest $snapshot) -Path $summaryPath
}

function New-eMASStage {
    param([string] $Id, [string] $Name, [string] $Kind, [string] $GateGroup, [object] $Definition = $null)
    $order = $manifest.Stages.Count + 1
    $stage = [ordered]@{
        Order = $order; Id = $Id; Name = $Name; Kind = $Kind; GateGroup = $GateGroup; Status = 'NOT_RUN'; Reasons = @()
        Command = $null; WorkingDirectory = $null; ExitCode = $null; TimedOut = $null; StartedAtUtc = $null; DurationSeconds = $null
        Counts = $null; LineCounts = $null; Expected = $null; ExpectedProfile = $null; Diagnostics = @(); Artifacts = $null; Details = $null
    }
    [void]$manifest.Stages.Add($stage)
    return [pscustomobject]@{ Record = $stage; Definition = $Definition; Directory = (Join-Path $stagesDirectory ('{0:00}-{1}' -f $order, $Id)) }
}

function Get-eMASRelativeArtifact { param([string] $Path) return [System.IO.Path]::GetRelativePath($runDirectory, $Path).Replace('\', '/') }

# ---------------------------------------------------------------------------
# Inputs and external corpora
# ---------------------------------------------------------------------------

$inputRecords = New-Object System.Collections.ArrayList
function Add-eMASInputRecord {
    param([string] $Role, [AllowNull()][string] $Path, [string] $Origin, [bool] $Hash = $true)
    $record = [ordered]@{ Role = $Role; Path = $Path; Origin = $Origin; Kind = 'NotSupplied'; FileCount = 0; Sha256 = $null; Sha256After = $null; UnchangedAfterRun = $null }
    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        if ($Hash) { $digest = Get-eMASInputDigest -Path $Path; $record.Kind = $digest.Kind; $record.FileCount = $digest.FileCount; $record.Sha256 = $digest.Sha256 }
        else { $record.Kind = $(if (Test-Path -LiteralPath $Path) { 'Present' } else { 'Missing' }) }
    }
    [void]$manifest.Inputs.Add($record)
    [void]$inputRecords.Add($record)
    return $record
}

function Get-eMASCorpusState {
    param([AllowNull()][string] $Root, [string] $ManifestPath, [string] $Label, [string] $ParameterName)
    if ([string]::IsNullOrWhiteSpace($Root)) { return [pscustomobject]@{ State = 'NotSupplied'; Reason = ('{0} not supplied (use -{1} or the user settings file); it is external to the repository and is never downloaded.' -f $Label, $ParameterName) } }
    if (-not [System.IO.Directory]::Exists($Root)) { return [pscustomobject]@{ State = 'Invalid'; Reason = ('{0} was supplied but the directory does not exist: {1}' -f $Label, $Root) } }
    if (-not [System.IO.File]::Exists($ManifestPath)) { return [pscustomobject]@{ State = 'Invalid'; Reason = ('{0} was supplied but its freeze manifest is missing: {1}' -f $Label, $ManifestPath) } }
    return [pscustomobject]@{ State = 'Available'; Reason = $null }
}

$wave1State = Get-eMASCorpusState -Root $wave1Setting.Value -ManifestPath $wave1ManifestSetting.Value -Label 'External frozen Wave 1 corpus' -ParameterName 'Wave1CorpusRoot'
$wave1DState = Get-eMASCorpusState -Root $wave1DSetting.Value -ManifestPath $(if ($null -ne $wave1DSetting.Value) { Join-Path $wave1DSetting.Value 'WAVE1D_FREEZE_MANIFEST.csv' } else { '' }) -Label 'External Wave1D dossier-diversity package' -ParameterName 'Wave1DCorpusRoot'
$corpusStates = @{ Wave1 = $wave1State; Wave1D = $wave1DState }

$tokens = @{
    '{Wave1CorpusRoot}' = $wave1Setting.Value
    '{Wave1FreezeManifestPath}' = $wave1ManifestSetting.Value
    '{Wave1DCorpusRoot}' = $wave1DSetting.Value
}

function Resolve-eMASArguments {
    param([object[]] $Template = @(), [string] $HarnessOutput)
    $resolved = New-Object System.Collections.Generic.List[string]
    foreach ($value in $Template) {
        $text = [string]$value
        if ($text -eq '{HarnessOutput}') { $resolved.Add($HarnessOutput); continue }
        if ($tokens.ContainsKey($text)) { $resolved.Add([string]$tokens[$text]); continue }
        if ($text.StartsWith('{')) { throw ('Unknown catalog token {0}' -f $text) }
        $resolved.Add($text)
    }
    return [string[]]$resolved.ToArray()
}

# ---------------------------------------------------------------------------
# Stage implementations
# ---------------------------------------------------------------------------

function Invoke-eMASPreflightStage {
    param([object] $Stage)
    $r = $Stage.Record
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $reasons = New-Object System.Collections.Generic.List[string]
    $status = 'PASS'
    if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { $status = 'FAIL'; $reasons.Add(('PowerShell 7 (Core) is required; found {0} {1}.' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion)) }
    if (-not $IsMacOS) { $reasons.Add('Not macOS: this runner targets macOS development verification; results on this platform are informational.') }
    $requiredScripts = @($catalog.Suites | Where-Object { @($_.Modes) -contains $Mode } | ForEach-Object { $_.Script })
    if ($Mode -eq 'MS04Demo') { $requiredScripts = @('scripts/eMAS-PreSalesAssessment.ps1') }
    $missing = @($requiredScripts | Where-Object { -not [System.IO.File]::Exists((Join-Path $repositoryRoot $_)) })
    if ($missing.Count -gt 0) { $status = 'FAIL'; $reasons.Add('Required repository scripts are missing: ' + ($missing -join ', ')) }
    if (-not $gitStart.Available) { $reasons.Add('Git state unavailable: ' + $gitStart.Error + ' The run is not attributable to a commit SHA.') }
    elseif (-not $gitStart.WorktreeClean) { $reasons.Add(('Worktree has {0} uncommitted/untracked entr(ies); results are not attributable to {1} alone.' -f $gitStart.StatusEntryCount, $gitStart.HeadSha)) }
    foreach ($name in @($(if ($Mode -eq 'MS04Demo') { @() } else { @('Wave1', 'Wave1D') }))) {
        $state = $corpusStates[$name]
        if ($state.State -eq 'Invalid') { $status = $(if ($status -eq 'FAIL') { 'FAIL' } else { 'BLOCKED' }); $reasons.Add($state.Reason) }
    }
    $r.Details = [ordered]@{ PowerShell = ('{0} {1}' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion); PwshExecutable = $pwshPath; RequiredScriptsPresent = ($requiredScripts.Count - $missing.Count); RequiredScripts = $requiredScripts.Count; Wave1Corpus = $wave1State.State; Wave1DCorpus = $wave1DState.State }
    $r.Status = $status
    $r.Reasons = [string[]]$reasons.ToArray()
    $r.DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
}

function Invoke-eMASFrozenManifestStage {
    param([object] $Stage)
    $r = $Stage.Record
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $reasons = New-Object System.Collections.Generic.List[string]
    $results = [ordered]@{}
    $failed = $false
    foreach ($definition in @($catalog.CommittedManifests)) {
        $check = Test-eMASCommittedManifest -RepositoryRoot $repositoryRoot -Definition $definition
        $results[$definition.Id] = ('{0}/{1} rows verified (expected {2})' -f $check.Verified, $check.Rows, $definition.ExpectedRows)
        if ($check.Rows -ne $definition.ExpectedRows -or $check.Verified -ne $check.Rows -or @($check.Mismatches).Count -gt 0 -or @($check.Missing).Count -gt 0) {
            $failed = $true
            $reasons.Add(('{0}: {1}/{2} verified; mismatched: {3}; missing: {4}' -f $definition.Path, $check.Verified, $check.Rows, (@($check.Mismatches) -join ', '), (@($check.Missing) -join ', ')))
        }
    }
    $reasons.Add('Runner-native read-only check of committed freeze manifests (SHA-256 of each listed file). External Wave 1/Wave1D manifests are verified by their own harnesses.')
    $r.Details = $results
    $r.Status = $(if ($failed) { 'FAIL' } else { 'PASS' })
    $r.Reasons = [string[]]$reasons.ToArray()
    $r.DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
}

function Invoke-eMASHarnessStage {
    param([object] $Stage)
    $r = $Stage.Record
    $definition = $Stage.Definition
    foreach ($requirement in @($definition.Requires)) {
        $state = $corpusStates[$requirement]
        if ($state.State -eq 'NotSupplied') { $r.Status = 'SKIP'; $r.Reasons = @('Not executed: ' + $state.Reason); return }
        if ($state.State -eq 'Invalid') { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: ' + $state.Reason); return }
    }
    [void][System.IO.Directory]::CreateDirectory($Stage.Directory)
    $harnessOutput = Join-Path $Stage.Directory 'harness-output'
    [void][System.IO.Directory]::CreateDirectory($harnessOutput)
    $arguments = New-Object System.Collections.Generic.List[string]
    foreach ($value in @('-NoProfile', '-NonInteractive', '-File', (Join-Path $repositoryRoot $definition.Script))) { $arguments.Add($value) }
    foreach ($value in (Resolve-eMASArguments -Template @($definition.Arguments) -HarnessOutput $harnessOutput)) { $arguments.Add($value) }
    $expectationProfile = 'Default'
    $notes = New-Object System.Collections.Generic.List[string]
    if ($definition.ContainsKey('OptionalArguments')) {
        foreach ($optional in @($definition.OptionalArguments)) {
            if ($corpusStates[$optional.Requires].State -eq 'Available') {
                foreach ($value in (Resolve-eMASArguments -Template @($optional.Arguments) -HarnessOutput $harnessOutput)) { $arguments.Add($value) }
                if ($definition.Expected.ContainsKey('With' + $optional.Requires)) { $expectationProfile = 'With' + $optional.Requires }
            }
            elseif ($definition.ContainsKey('SkipNote')) { $notes.Add($definition.SkipNote) }
        }
    }
    $stdoutPath = Join-Path $Stage.Directory 'stdout.log'
    $stderrPath = Join-Path $Stage.Directory 'stderr.log'
    $argumentArray = [string[]]$arguments.ToArray()
    $r.Command = [ordered]@{ Executable = $pwshPath; Arguments = $argumentArray; Display = (Format-eMASCommandLine -Executable $pwshPath -Arguments $argumentArray) }
    $r.WorkingDirectory = $Stage.Directory
    $r.Artifacts = [ordered]@{ stdout = (Get-eMASRelativeArtifact $stdoutPath); stderr = (Get-eMASRelativeArtifact $stderrPath); 'harness output' = (Get-eMASRelativeArtifact $harnessOutput) }
    $r.Status = 'RUNNING'
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    Save-eMASRunEvidence
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments $argumentArray -WorkingDirectory $Stage.Directory -StdoutPath $stdoutPath -StderrPath $stderrPath -TimeoutSeconds $StageTimeoutSeconds
    $stdout = [System.IO.File]::ReadAllText($stdoutPath)
    $stderr = [System.IO.File]::ReadAllText($stderrPath)
    $lineCounts = Get-eMASLineCounts -Text $stdout
    $structured = Get-eMASStructuredCounts -Counter $definition.Counter -HarnessOutput $harnessOutput -Stdout $stdout
    $expected = $definition.Expected[$expectationProfile]
    $gates = $(if ($definition.Counter.ContainsKey('Gates')) { $definition.Counter.Gates } else { $null })
    $verdict = Get-eMASHarnessStatus -Process $process -LineCounts $lineCounts -Structured $structured -Expected $expected -GateExpectations $gates
    $r.ExitCode = $process.ExitCode
    $r.TimedOut = $process.TimedOut
    $r.DurationSeconds = $process.DurationSeconds
    $r.LineCounts = $lineCounts
    $r.Counts = $structured
    $r.Expected = $expected
    $r.ExpectedProfile = $expectationProfile
    $r.Status = $verdict.Status
    $r.Reasons = [string[]](@($verdict.Reasons) + @($notes))
    $r.Diagnostics = Get-eMASDiagnosticLines -Stdout $stdout -Stderr $stderr
    if ($definition.Counter.Kind -eq 'Summary') { $r.Artifacts['harness summary'] = Get-eMASRelativeArtifact (Join-Path $harnessOutput $definition.Counter.SummaryFile) }
}

function Invoke-eMASPreSalesProcess {
    # Runs the real Pre-Sales script with an explicit argument list.
    param([object] $Stage, [string[]] $ScriptArguments, [string] $ObservedPath)
    [void][System.IO.Directory]::CreateDirectory($Stage.Directory)
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $ObservedPath))
    $r = $Stage.Record
    $arguments = [string[]](@('-NoProfile', '-NonInteractive', '-File', $preSalesScript) + @($ScriptArguments))
    $stdoutPath = Join-Path $Stage.Directory 'stdout.log'
    $stderrPath = Join-Path $Stage.Directory 'stderr.log'
    $r.Command = [ordered]@{ Executable = $pwshPath; Arguments = $arguments; Display = (Format-eMASCommandLine -Executable $pwshPath -Arguments $arguments) }
    $r.WorkingDirectory = $Stage.Directory
    $r.Artifacts = [ordered]@{ stdout = (Get-eMASRelativeArtifact $stdoutPath); stderr = (Get-eMASRelativeArtifact $stderrPath); 'observed JSON' = $null }
    $r.Status = 'RUNNING'
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    Save-eMASRunEvidence
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments $arguments -WorkingDirectory $Stage.Directory -StdoutPath $stdoutPath -StderrPath $stderrPath -TimeoutSeconds $StageTimeoutSeconds
    $r.ExitCode = $process.ExitCode
    $r.TimedOut = $process.TimedOut
    $r.DurationSeconds = $process.DurationSeconds
    $stderr = Remove-eMASAnsiEscape -Text ([System.IO.File]::ReadAllText($stderrPath))
    # Pre-Sales stdout echoes the full result object; the report shows only stderr diagnostics.
    $r.Diagnostics = [string[]]@($stderr -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 20 | ForEach-Object { 'stderr: ' + $(if ($_.Length -gt 600) { $_.Substring(0, 600) + '…' } else { $_ }) })
    $document = $null
    $readError = $null
    if ([System.IO.File]::Exists($ObservedPath)) {
        $r.Artifacts['observed JSON'] = Get-eMASRelativeArtifact $ObservedPath
        try { $document = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($ObservedPath)) } catch { $readError = $_.Exception.Message }
    }
    return [pscustomobject]@{ Process = $process; Document = $document; ReadError = $readError; OutputExists = [System.IO.File]::Exists($ObservedPath) }
}

function Get-eMASProcessFailureReasons {
    param([object] $Run, [string] $ExpectedContract)
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($null -ne $Run.Process.LaunchError) { $reasons.Add('Launch error: ' + $Run.Process.LaunchError) }
    if ($Run.Process.TimedOut) { $reasons.Add('Timed out; the process tree was terminated.') }
    if ($null -ne $Run.Process.ExitCode -and $Run.Process.ExitCode -ne 0) { $reasons.Add(('Pre-Sales script exit code {0}.' -f $Run.Process.ExitCode)) }
    if ($reasons.Count -eq 0) {
        if (-not $Run.OutputExists) { $reasons.Add('The script exited 0 but wrote no output document.') }
        elseif ($null -ne $Run.ReadError) { $reasons.Add('Output document is not valid JSON: ' + $Run.ReadError) }
        elseif ([string]$Run.Document.ContractId -ne $ExpectedContract) { $reasons.Add(('Output ContractId {0} is not {1}.' -f $Run.Document.ContractId, $ExpectedContract)) }
    }
    return [string[]]$reasons.ToArray()
}

$demoInputs = [ordered]@{ SourceValid = $false; ConfigState = 'NotSupplied'; ExpectedState = 'NotSupplied'; ExpectedReason = $null }
$demoExecutionId = $(if ([string]::IsNullOrWhiteSpace($ExecutionId)) { 'EXEC-MS04DEMO-' + $runId } else { $ExecutionId.Trim() })
$suxiArguments = $(if ($SubmissionUnitXmlInventory -eq 'Include') { @('-IncludeSubmissionUnitXmlInventory') } else { @() })

function Invoke-eMASDemoInputStage {
    param([object] $Stage)
    $r = $Stage.Record
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    $reasons = New-Object System.Collections.Generic.List[string]
    $status = 'PASS'
    if ($null -eq $sourceValue) { $status = 'BLOCKED'; $reasons.Add('No dossier -SourcePath supplied.') }
    elseif ([System.IO.Directory]::Exists($sourceValue)) { $demoInputs.SourceValid = $true; $reasons.Add('Source is a directory.') }
    elseif ([System.IO.File]::Exists($sourceValue)) {
        if ([System.IO.Path]::GetExtension($sourceValue) -ieq '.zip') { $demoInputs.SourceValid = $true; $reasons.Add('Source is a ZIP file.') }
        else { $status = 'BLOCKED'; $reasons.Add('Source file is not a .zip archive: ' + $sourceValue) }
    }
    else { $status = 'BLOCKED'; $reasons.Add('Source path does not exist: ' + $sourceValue) }
    if ($null -eq $configValue) { $reasons.Add('No Runtime JSON supplied: identification will be BLOCKED. config/runtime/development holds no approved MS-04 configuration.') }
    elseif ([System.IO.File]::Exists($configValue)) { $demoInputs.ConfigState = 'Present'; $reasons.Add('Runtime JSON file present; its content is validated only by the real Pre-Sales loader.') }
    else { $demoInputs.ConfigState = 'Invalid'; $status = 'BLOCKED'; $reasons.Add('Runtime JSON path does not exist or is not a file: ' + $configValue) }
    if ($null -eq $expectedValue) { $reasons.Add('No independent expected Identification/1.0 document supplied: the demo cannot be VERIFIED.') }
    elseif (-not [System.IO.File]::Exists($expectedValue)) { $demoInputs.ExpectedState = 'Invalid'; $demoInputs.ExpectedReason = 'Expected-outcome path does not exist or is not a file: ' + $expectedValue; $status = 'BLOCKED'; $reasons.Add($demoInputs.ExpectedReason) }
    else {
        try {
            $expectedDocument = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($expectedValue))
            if ([string]$expectedDocument.ContractId -ne $identificationContractId) { throw ('ContractId is {0}, not {1}' -f $expectedDocument.ContractId, $identificationContractId) }
            $demoInputs.ExpectedState = 'Present'
            $reasons.Add('Expected-outcome document supplied by the user (the runner never derives it from actual output).')
        }
        catch { $demoInputs.ExpectedState = 'Invalid'; $demoInputs.ExpectedReason = 'Expected-outcome document is not a usable Identification/1.0 JSON document: ' + $_.Exception.Message; $status = 'BLOCKED'; $reasons.Add($demoInputs.ExpectedReason) }
    }
    $r.Details = [ordered]@{ ExecutionId = $demoExecutionId; SubmissionUnitXmlInventory = $SubmissionUnitXmlInventory; Source = $sourceValue; RuntimeConfiguration = $configValue; ExpectedIdentification = $expectedValue }
    $r.Status = $status
    $r.Reasons = [string[]]$reasons.ToArray()
    $r.DurationSeconds = 0
}

function Invoke-eMASDemoEvidenceStage {
    param([object] $Stage)
    $r = $Stage.Record
    if (-not $demoInputs.SourceValid) { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: no valid dossier source.'); return }
    $observed = Join-Path $Stage.Directory 'observed/scanner-observations.json'
    $scriptArguments = [string[]](@('-SourcePath', $sourceValue, '-OutputPath', $observed, '-ExecutionId', ($demoExecutionId + '-EVIDENCE'), '-ScenarioId', 'MS-04', '-Phase', 'PreSales', '-IncludeClassificationEvidenceCollection') + $suxiArguments)
    $run = Invoke-eMASPreSalesProcess -Stage $Stage -ScriptArguments $scriptArguments -ObservedPath $observed
    $failures = @(Get-eMASProcessFailureReasons -Run $run -ExpectedContract $scannerContractId)
    if ($failures.Count -gt 0) { $r.Status = 'FAIL'; $r.Reasons = [string[]]$failures; return }
    $document = $run.Document
    $evidence = @($document.ClassificationEvidence)
    $details = [ordered]@{
        CompletionStatus = [string]$document.Execution.CompletionStatus
        Capabilities = (@($document.Execution.Capabilities) -join ' → ')
        DossierCandidates = @($document.DossierCandidates).Count
        Sequences = @($document.Sequences).Count
        ClassificationEvidenceRecords = $evidence.Count
    }
    if ($null -ne $document.PSObject.Properties['SubmissionUnitXmlDocuments']) {
        $details['SubmissionUnitXmlDocuments'] = @($document.SubmissionUnitXmlDocuments).Count
        $details['Ectd4EvidenceRecords'] = @($evidence | Where-Object { ([string]$_.EvidenceType).StartsWith('Ectd4', [System.StringComparison]::Ordinal) }).Count
    }
    $r.Details = $details
    $r.Status = 'EXECUTED_UNVERIFIED'
    $r.Reasons = @(
        ('Real Pre-Sales evidence route executed and wrote {0}.' -f $scannerContractId),
        'Evidence content is factual scanner output; it is not independently verified by this runner.'
    )
}

function Invoke-eMASDemoIdentificationStage {
    param([object] $Stage)
    $r = $Stage.Record
    if (-not $demoInputs.SourceValid) { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: no valid dossier source.'); return }
    if ($demoInputs.ConfigState -eq 'NotSupplied') { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: identification requires -RuntimeConfigurationPath. No approved MS-04 Runtime JSON exists in the repository; the oracle Runtime JSON files are synthetic test policy.'); return }
    if ($demoInputs.ConfigState -ne 'Present') { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: the supplied Runtime JSON path is not a file.'); return }
    $observed = Join-Path $Stage.Directory 'observed/identification.json'
    $scriptArguments = [string[]](@('-SourcePath', $sourceValue, '-OutputPath', $observed, '-ExecutionId', ($demoExecutionId + '-IDENTIFICATION'), '-ScenarioId', 'MS-04', '-Phase', 'PreSales', '-RuntimeConfigurationPath', $configValue, '-IncludeIdentificationInterpretation') + $suxiArguments)
    $run = Invoke-eMASPreSalesProcess -Stage $Stage -ScriptArguments $scriptArguments -ObservedPath $observed
    $failures = @(Get-eMASProcessFailureReasons -Run $run -ExpectedContract $identificationContractId)
    if ($failures.Count -gt 0) {
        $extra = @()
        if ($null -ne $run.Process.ExitCode -and $run.Process.ExitCode -ne 0) {
            $extra = @($(if ($run.OutputExists) { 'An output file exists despite the failure; it is kept for inspection and not used.' } else { 'No Identification document was written; the runner does not fabricate one.' }))
        }
        $r.Status = 'FAIL'; $r.Reasons = [string[]](@($failures) + $extra); return
    }
    $document = $run.Document
    $rows = foreach ($result in @($document.Results) | Select-Object -First 200) {
        $value = if ($null -ne $result.Value) { [string]$result.Value } elseif ($null -ne $result.ValueSet) { (@($result.ValueSet) -join ', ') } else { '' }
        [ordered]@{ Subject = ('{0} {1}' -f $result.SubjectType, $result.SubjectId); Dimension = [string]$result.Dimension; EvaluationStatus = [string]$result.EvaluationStatus; Value = $value; Confidence = [string]$result.Confidence; ReviewRequired = $result.ReviewRequired }
    }
    $r.Details = [ordered]@{
        CompletionStatus = [string]$document.Execution.CompletionStatus
        RuntimeConfigurationId = [string]$document.RuntimeConfig.ConfigurationId
        RuntimeConfigurationExportType = [string]$document.RuntimeConfig.ExportType
        RuntimeConfigurationSha256 = [string]$document.RuntimeConfig.Sha256
        ResultCount = @($document.Results).Count
        ResultRows = @($rows)
    }
    $reasons = New-Object System.Collections.Generic.List[string]
    $reasons.Add(('Real Pre-Sales identification route executed and wrote a separate {0} document.' -f $identificationContractId))
    $reasons.Add('All interpretations come from the supplied Runtime JSON; the runner applies no business rules.')
    if ([string]$document.RuntimeConfig.ExportType -ne 'CONTROLLED') { $reasons.Add(('Runtime JSON export type is {0}; it is not an approved release configuration.' -f $document.RuntimeConfig.ExportType)) }
    if ($SubmissionUnitXmlInventory -eq 'Include') { $reasons.Add('T2 SubmissionUnit XML facts were collected, but IdentificationInterpretation projection v1 does not consume the eight T2 evidence types.') }
    $r.Status = 'EXECUTED_UNVERIFIED'
    $r.Reasons = [string[]]$reasons.ToArray()
    $r.Artifacts['observed JSON'] = Get-eMASRelativeArtifact $observed
}

function Invoke-eMASDemoVerificationStage {
    param([object] $Stage, [object] $IdentificationStage)
    $r = $Stage.Record
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    $observed = Join-Path $IdentificationStage.Directory 'observed/identification.json'
    if ($IdentificationStage.Record.Status -ne 'EXECUTED_UNVERIFIED') { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: there is no successfully produced Identification document to verify.'); return }
    if ($demoInputs.ExpectedState -eq 'NotSupplied') { $r.Status = 'SKIP'; $r.Reasons = @('Not executed: no independent expected-outcome document was supplied (-ExpectedIdentificationPath), so the demo stays EXECUTED_UNVERIFIED. The runner never generates expected results from the actual output.'); return }
    if ($demoInputs.ExpectedState -ne 'Present') { $r.Status = 'BLOCKED'; $r.Reasons = @('Not executed: the supplied expected-outcome document cannot be used. ' + $demoInputs.ExpectedReason); return }
    $comparison = Compare-eMASIdentificationDocument -ObservedPath $observed -ExpectedPath $expectedValue -VolatileFields @($catalog.IdentificationVolatileFields)
    $r.Details = [ordered]@{ ComparisonProfile = 'SemanticJsonEquality (object key order ignored, array order significant)'; VolatileFieldsRemoved = (@($catalog.IdentificationVolatileFields) -join ', '); Equal = $comparison.Equal }
    $r.DurationSeconds = 0
    if ($comparison.Equal) {
        $r.Status = 'VERIFIED'
        $r.Reasons = @('The observed Identification/1.0 document equals the supplied expected document under the comparison profile. Verification is only as independent as the supplied expected document.')
    }
    else {
        $r.Status = 'FAIL'
        $r.Reasons = [string[]](@('The observed Identification/1.0 document differs from the supplied expected document.') + @($comparison.Differences | ForEach-Object { 'Difference: ' + $_ }))
    }
}

function Invoke-eMASImmutabilityStage {
    param([object] $Stage)
    $r = $Stage.Record
    $r.StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $reasons = New-Object System.Collections.Generic.List[string]
    $changed = New-Object System.Collections.Generic.List[string]
    foreach ($record in $inputRecords) {
        if ($null -eq $record.Sha256) { continue }
        $after = Get-eMASInputDigest -Path $record.Path
        $record.Sha256After = $after.Sha256
        $record.UnchangedAfterRun = ($after.Sha256 -eq $record.Sha256)
        if (-not $record.UnchangedAfterRun) { $changed.Add(('{0} ({1})' -f $record.Role, $record.Path)) }
    }
    $gitEnd = Get-eMASGitState -RepositoryRoot $repositoryRoot
    $gitUnchanged = $null
    if ($gitStart.Available -and $gitEnd.Available) {
        $gitUnchanged = ($gitStart.HeadSha -eq $gitEnd.HeadSha -and $gitStart.StatusDigest -eq $gitEnd.StatusDigest)
        if (-not $gitUnchanged) { $changed.Add(('Git HEAD/worktree status changed during the run (HEAD {0} → {1}; status entries {2} → {3}).' -f $gitStart.HeadSha, $gitEnd.HeadSha, $gitStart.StatusEntryCount, $gitEnd.StatusEntryCount)) }
    }
    else { $reasons.Add('Git state unavailable; repository immutability relies on the protected-tree hashes only.') }
    $r.Details = [ordered]@{ InputsHashed = @($inputRecords | Where-Object { $null -ne $_.Sha256 }).Count; GitHeadAndStatusUnchanged = $gitUnchanged }
    if ($changed.Count -gt 0) { $r.Status = 'FAIL'; foreach ($item in $changed) { $reasons.Add('Changed during the run: ' + $item) } }
    else { $r.Status = 'PASS'; $reasons.Add('Every hashed input, protected repository tree and the Git worktree state are unchanged.') }
    $r.Reasons = [string[]]$reasons.ToArray()
    $r.DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
}

# ---------------------------------------------------------------------------
# Plan
# ---------------------------------------------------------------------------

$plan = New-Object System.Collections.ArrayList
[void]$plan.Add(@{ Stage = (New-eMASStage -Id 'PREFLIGHT' -Name 'Environment and repository preflight' -Kind 'RunnerNative' -GateGroup 'Preflight'); Action = 'Preflight' })
if ($Mode -in @('QuickCheck', 'FullRegression')) {
    [void]$plan.Add(@{ Stage = (New-eMASStage -Id 'FROZEN-MANIFESTS' -Name 'Committed freeze manifests (read-only)' -Kind 'RunnerNative' -GateGroup 'Preflight'); Action = 'Manifests' })
    foreach ($suite in @($catalog.Suites | Where-Object { @($_.Modes) -contains $Mode })) {
        [void]$plan.Add(@{ Stage = (New-eMASStage -Id $suite.Id -Name $suite.Name -Kind 'Harness' -GateGroup $suite.GateGroup -Definition $suite); Action = 'Harness' })
    }
}
else {
    [void]$plan.Add(@{ Stage = (New-eMASStage -Id 'DEMO-INPUTS' -Name 'Demo input validation' -Kind 'RunnerNative' -GateGroup 'Demo'); Action = 'DemoInputs' })
    [void]$plan.Add(@{ Stage = (New-eMASStage -Id 'DEMO-EVIDENCE' -Name 'Pre-Sales evidence route (RD → BXI → CEC)' -Kind 'PreSales' -GateGroup 'Demo'); Action = 'DemoEvidence' })
    $identificationStage = New-eMASStage -Id 'DEMO-IDENTIFICATION' -Name 'Pre-Sales identification route (Identification/1.0)' -Kind 'PreSales' -GateGroup 'Demo'
    [void]$plan.Add(@{ Stage = $identificationStage; Action = 'DemoIdentification' })
    [void]$plan.Add(@{ Stage = (New-eMASStage -Id 'DEMO-VERIFICATION' -Name 'Comparison with independent expected outcome' -Kind 'Verification' -GateGroup 'Demo'); Action = 'DemoVerification' })
}
[void]$plan.Add(@{ Stage = (New-eMASStage -Id 'IMMUTABILITY' -Name 'Input, fixture and repository immutability' -Kind 'RunnerNative' -GateGroup 'ReadOnly'); Action = 'Immutability' })

# Limitations recorded for every run.
foreach ($text in @(
        'macOS PowerShell 7 development verification only. A Mac run does not qualify Windows PowerShell 5.1 or the Windows PowerShell 7.6 CI lanes.',
        'No regulatory compliance claim: coverage is limited to the existing harness contracts (including T1b/T2) listed in this run.',
        'Open and out of scope: native Windows PowerShell 5.1 T1b qualification, the unrelated Windows PS5.1 RuntimeConfiguration UTF-8 CI expectation, the RD/BXI path-alias limitation and FDA D-3.')) { [void]$manifest.Limitations.Add($text) }
if ($Mode -eq 'QuickCheck') { [void]$manifest.Limitations.Add('QuickCheck runs focused T2, T4 engine, T4 oracle and committed freeze manifests only; it is not the 15-gate full regression and does not establish end-to-end MS-04 completion.') }
if ($Mode -ne 'MS04Demo' -and $wave1State.State -ne 'Available') { [void]$manifest.Limitations.Add($wave1State.Reason + ' T2 SD-090 mixed v3/v4 check and Wave 1-dependent suites are not executed.') }
if ($Mode -eq 'FullRegression' -and $wave1DState.State -ne 'Available') { [void]$manifest.Limitations.Add($wave1DState.Reason + ' The Wave1D suite is not executed.') }
if ($Mode -eq 'MS04Demo') {
    [void]$manifest.Limitations.Add('No approved MS-04 Runtime JSON exists in config/runtime. The oracle Runtime JSON files are synthetic test policy, not approved configuration.')
    [void]$manifest.Limitations.Add('IdentificationInterpretation projection v1 ignores the eight T2 SubmissionUnit XML evidence types.')
    [void]$manifest.Limitations.Add('Verification compares with a user-supplied expected document after removing: ' + (@($catalog.IdentificationVolatileFields) -join ', ') + '. EvidenceSource.DocumentSha256 hashes the in-memory, timestamped evidence document and differs between identical runs.')
}

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------

$completed = $false
$runnerError = $null
$currentStage = $null
try {
    [void](Add-eMASInputRecord -Role 'Runner script' -Path $PSCommandPath -Origin 'Repository')
    foreach ($tree in @($catalog.ProtectedTrees)) { [void](Add-eMASInputRecord -Role ('Repository tree ' + $tree) -Path (Join-Path $repositoryRoot $tree) -Origin 'Repository') }
    if ($Mode -eq 'MS04Demo') {
        [void](Add-eMASInputRecord -Role 'Dossier source' -Path $sourceValue -Origin $(if ($null -ne $sourceValue) { 'Parameter' } else { 'NotSupplied' }))
        [void](Add-eMASInputRecord -Role 'Runtime JSON' -Path $configValue -Origin $(if ($null -ne $configValue) { 'Parameter' } else { 'NotSupplied' }))
        [void](Add-eMASInputRecord -Role 'Expected Identification/1.0' -Path $expectedValue -Origin $(if ($null -ne $expectedValue) { 'Parameter' } else { 'NotSupplied' }))
    }
    else {
        [void](Add-eMASInputRecord -Role 'Wave 1 corpus' -Path $(if ($wave1State.State -eq 'Available') { $wave1Setting.Value } else { $null }) -Origin $wave1Setting.Origin)
        if ($wave1State.State -ne 'Available' -and $null -ne $wave1Setting.Value) { $manifest.Inputs[-1].Path = $wave1Setting.Value; $manifest.Inputs[-1].Kind = 'Invalid' }
        [void](Add-eMASInputRecord -Role 'Wave 1 freeze manifest' -Path $(if ($wave1State.State -eq 'Available') { $wave1ManifestSetting.Value } else { $null }) -Origin $wave1ManifestSetting.Origin)
        if ($Mode -eq 'FullRegression') {
            [void](Add-eMASInputRecord -Role 'Wave1D corpus' -Path $(if ($wave1DState.State -eq 'Available') { $wave1DSetting.Value } else { $null }) -Origin $wave1DSetting.Origin)
            if ($wave1DState.State -ne 'Available' -and $null -ne $wave1DSetting.Value) { $manifest.Inputs[-1].Path = $wave1DSetting.Value; $manifest.Inputs[-1].Kind = 'Invalid' }
        }
    }
    Save-eMASRunEvidence

    foreach ($step in $plan) {
        $stage = $step.Stage
        $currentStage = $stage.Record
        switch ($step.Action) {
            'Preflight' { Invoke-eMASPreflightStage -Stage $stage }
            'Manifests' { Invoke-eMASFrozenManifestStage -Stage $stage }
            'Harness' { Invoke-eMASHarnessStage -Stage $stage }
            'DemoInputs' { Invoke-eMASDemoInputStage -Stage $stage }
            'DemoEvidence' { Invoke-eMASDemoEvidenceStage -Stage $stage }
            'DemoIdentification' { Invoke-eMASDemoIdentificationStage -Stage $stage }
            'DemoVerification' { Invoke-eMASDemoVerificationStage -Stage $stage -IdentificationStage $identificationStage }
            'Immutability' { Invoke-eMASImmutabilityStage -Stage $stage }
        }
        Write-eMASRunnerLine ('  {0,-20} {1,-20} {2}' -f $stage.Record.Id, $stage.Record.Status, $(if ($null -ne $stage.Record.Counts -and $stage.Record.Counts.Available) { '{0}/{1} passed, {2} skipped' -f $stage.Record.Counts.Passed, $stage.Record.Counts.Total, $stage.Record.Counts.Skipped } else { '' }))
        Save-eMASRunEvidence
    }
    $completed = $true
}
catch {
    # A runner defect is recorded, never converted into a pass.
    $runnerError = $_
    $manifest.Run['RunnerError'] = ('{0} ({1})' -f $_.Exception.Message, $_.InvocationInfo.PositionMessage)
    if ($null -ne $currentStage) { $currentStage.Status = 'FAIL'; $currentStage.Reasons = [string[]](@($currentStage.Reasons) + ('Runner internal error: ' + $_.Exception.Message)) }
}
finally {
    $runWatch.Stop()
    if (-not $completed) {
        foreach ($record in $manifest.Stages) {
            if ($record.Status -eq 'RUNNING') { $record.Status = 'FAIL'; $record.Reasons = [string[]](@($record.Reasons) + 'Interrupted while running; partial logs are kept.') }
        }
        $manifest.Run.State = $(if ($null -ne $runnerError) { 'RunnerError' } else { 'Interrupted' })
    }
    else { $manifest.Run.State = 'Completed' }
    $verdict = Get-eMASOverallVerdict -Mode $Mode -Stages @($manifest.Stages) -Completed $completed
    $manifest.Run.OverallStatus = $verdict.Status
    $manifest.Run.OverallReason = $verdict.Reason
    $manifest.Run.StrictExitCode = Get-eMASExitCode -Status $verdict.Status -Policy 'Strict'
    $manifest.Run.ExitCode = Get-eMASExitCode -Status $verdict.Status -Policy $ExitCodePolicy
    $manifest.Run.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $manifest.Run.ElapsedSeconds = [math]::Round($runWatch.Elapsed.TotalSeconds, 3)
    Save-eMASRunEvidence
    if (-not $completed -and $null -eq $runnerError) {
        # Ctrl+C / SIGINT: the script cannot continue past this block, and pwsh would
        # otherwise exit 0. Report the evidence location and exit INCOMPLETE explicitly.
        [Console]::Error.WriteLine(('eMAS MS-04 {0}: INCOMPLETE (interrupted). Partial evidence: {1}' -f $Mode, $summaryPath))
        [System.Environment]::Exit($manifest.Run.ExitCode)
    }
}

Write-eMASRunnerLine ''
if ($null -ne $runnerError) { [Console]::Error.WriteLine('Runner internal error: ' + $manifest.Run.RunnerError) }
$bannerRule = '=' * 72
Write-eMASRunnerLine $bannerRule
Write-eMASRunnerLine ('  RESULT: {0}' -f ($manifest.Run.OverallStatus -replace '_', ' '))
switch ($manifest.Run.OverallStatus) {
    'PASS_WITH_SKIPS' { Write-eMASRunnerLine '  Every executed check passed, but some checks were SKIPPED. This is not an unqualified PASS.' }
    'EXECUTED_UNVERIFIED' { Write-eMASRunnerLine '  The real route ran, but no independent expected outcome verified it. This is not a PASS.' }
}
if ($manifest.Run.ExitCode -ne $manifest.Run.StrictExitCode) {
    Write-eMASRunnerLine ('  Exit code {0} (Task policy) means "completed without a failure", not an unqualified PASS; strict code {1}.' -f $manifest.Run.ExitCode, $manifest.Run.StrictExitCode)
}
Write-eMASRunnerLine $bannerRule
Write-eMASRunnerLine ('eMAS MS-04 {0}: {1}' -f $Mode, $manifest.Run.OverallStatus)
Write-eMASRunnerLine ('  {0}' -f $manifest.Run.OverallReason)
Write-eMASRunnerLine ('  Commit   {0} ({1}; worktree clean at start: {2})' -f $manifest.Repository.HeadSha, $manifest.Repository.Branch, $manifest.Repository.WorktreeClean)
Write-eMASRunnerLine ('  Summary  {0}' -f $summaryPath)
Write-eMASRunnerLine ('  Report   {0}' -f ([System.Uri]::new($summaryPath)).AbsoluteUri)
Write-eMASRunnerLine ('  Manifest {0}' -f $manifestPath)
Write-eMASRunnerLine ('  Exit code {0} (policy {1}; strict {2})' -f $manifest.Run.ExitCode, $ExitCodePolicy, $manifest.Run.StrictExitCode)

if ($OpenReport) {
    try {
        if ($IsMacOS) { & /usr/bin/open $summaryPath }
        elseif ($IsWindows) { Start-Process -FilePath $summaryPath }
        else { & xdg-open $summaryPath }
    }
    catch { Write-eMASRunnerLine ('  (Could not open the report automatically: {0}. The verdict is unaffected.)' -f $_.Exception.Message) }
}

exit $manifest.Run.ExitCode
