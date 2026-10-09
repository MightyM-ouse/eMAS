#requires -Version 7.0
# Runner-specific tests for tools/demo/Invoke-eMASMS04Demo.ps1.
# End-to-end checks run the real runner (and through it the real harnesses and
# Pre-Sales script) into -OutputRoot. Unit checks use the private modules and
# the synthetic stub harness in tests/demo-runner/stubs. No fixture, engine,
# configuration or oracle file is written.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    # Optional external corpora; without them the corpus-backed FullRegression check is SKIP.
    [string] $Wave1CorpusRoot,
    [string] $Wave1DCorpusRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runnerPath = Join-Path $repositoryRoot 'tools/demo/Invoke-eMASMS04Demo.ps1'
$stubPath = Join-Path $PSScriptRoot 'stubs/Invoke-StubHarness.ps1'
Import-Module (Join-Path $repositoryRoot 'tools/demo/private/eMAS.MS04DemoRunner.psm1') -Force
Import-Module (Join-Path $repositoryRoot 'tools/demo/private/eMAS.MS04DemoReport.psm1') -Force
$pwshPath = Get-eMASPwshPath
$oracleCase = Join-Path $repositoryRoot 'tests/identification-interpretation/oracle/cases/IDO-01'
$v4Fixture = Join-Path $repositoryRoot 'tests/fixtures/repository-discovery-ectd4/wave1e/fixtures/SD-063/fixture.zip'

$resolvedOutputRoot = Get-eMASRealPath -Path $OutputRoot
if (Test-eMASPathWithin -Child $resolvedOutputRoot -Parent (Get-eMASRealPath -Path $repositoryRoot)) { throw 'OutputRoot must be outside the repository.' }
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)
$scratch = Join-Path $resolvedOutputRoot 'scratch'
$runs = Join-Path $resolvedOutputRoot 'runs'
[void][System.IO.Directory]::CreateDirectory($scratch)
[void][System.IO.Directory]::CreateDirectory($runs)

$script:passed = 0
$script:failed = 0
$script:skipped = 0
$checks = New-Object System.Collections.ArrayList

function Assert-eMASTrue { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMASEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Invoke-eMASCheck {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $script:passed++
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null; Seconds = [math]::Round($watch.Elapsed.TotalSeconds, 1) })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        if ($_.Exception.Message.StartsWith('SKIP:', [System.StringComparison]::Ordinal)) {
            $script:skipped++
            [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'SKIP'; Detail = $_.Exception.Message.Substring(5).Trim(); Seconds = 0 })
            Write-Output ('[SKIP] {0}: {1}' -f $Name, $_.Exception.Message.Substring(5).Trim())
            return
        }
        $script:failed++
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message; Seconds = [math]::Round($watch.Elapsed.TotalSeconds, 1) })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

function Invoke-eMASRunner {
    # Runs the real runner as a child process; returns exit code, console text and the run manifest.
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string[]] $Arguments, [string] $Label)
    $consoleDir = Join-Path $scratch ('console-' + $Label + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
    [void][System.IO.Directory]::CreateDirectory($consoleDir)
    $before = @(Get-ChildItem -LiteralPath $runs -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]](@('-NoProfile', '-NonInteractive', '-File', $runnerPath) + $Arguments)) -WorkingDirectory $consoleDir -StdoutPath (Join-Path $consoleDir 'stdout.log') -StderrPath (Join-Path $consoleDir 'stderr.log') -TimeoutSeconds 1800
    $after = @(Get-ChildItem -LiteralPath $runs -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
    $new = @($after | Where-Object { $before -notcontains $_ })
    $manifest = $null
    $runDirectory = $null
    if ($new.Count -eq 1) {
        $runDirectory = $new[0]
        $manifestFile = Join-Path $runDirectory 'run-manifest.json'
        if ([System.IO.File]::Exists($manifestFile)) { $manifest = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($manifestFile)) }
    }
    return [pscustomobject]@{
        ExitCode = $process.ExitCode; Stdout = [System.IO.File]::ReadAllText((Join-Path $consoleDir 'stdout.log')); Stderr = [System.IO.File]::ReadAllText((Join-Path $consoleDir 'stderr.log'))
        NewRunDirectories = $new.Count; RunDirectory = $runDirectory; Manifest = $manifest
    }
}

function Get-eMASStage { param([object] $Manifest, [string] $Id) return @($Manifest.Stages | Where-Object { $_.Id -eq $Id }) | Select-Object -First 1 }

function Get-eMASRepositoryState {
    $state = Get-eMASGitState -RepositoryRoot $repositoryRoot
    return [pscustomobject]@{ Head = $state.HeadSha; StatusDigest = $state.StatusDigest; Fixtures = (Get-eMASTreeDigest -Root (Join-Path $repositoryRoot 'tests/fixtures')).Sha256; Oracle = (Get-eMASTreeDigest -Root (Join-Path $repositoryRoot 'tests/identification-interpretation/oracle')).Sha256 }
}

function Assert-eMASRunEvidence {
    param([object] $Run)
    Assert-eMASEqual 1 $Run.NewRunDirectories 'Exactly one new run directory must be created.'
    Assert-eMASTrue ($null -ne $Run.Manifest) 'run-manifest.json missing or unreadable.'
    Assert-eMASTrue ([System.IO.File]::Exists((Join-Path $Run.RunDirectory 'summary.html'))) 'summary.html missing.'
    Assert-eMASTrue (-not (Test-eMASPathWithin -Child (Get-eMASRealPath $Run.RunDirectory) -Parent (Get-eMASRealPath $repositoryRoot))) 'Run directory is inside the repository.'
    Assert-eMASEqual 'Completed' $Run.Manifest.Run.State 'Run state.'
    Assert-eMASEqual $Run.Manifest.Run.ExitCode $Run.ExitCode 'Process exit code must equal the manifest exit code.'
    Assert-eMASEqual 'PASS' (Get-eMASStage $Run.Manifest 'IMMUTABILITY').Status 'Immutability stage.'
    $html = [System.IO.File]::ReadAllText((Join-Path $Run.RunDirectory 'summary.html'))
    Assert-eMASTrue ($html -notmatch '<script') 'summary.html must not contain scripts.'
    Assert-eMASTrue ($html -notmatch '(src|href)\s*=\s*"(https?:)?//') 'summary.html must not reference remote resources.'
}

$repositoryBefore = Get-eMASRepositoryState
$common = @('-OutputRoot', $runs, '-NoUserSettings')

# ---------------------------------------------------------------------------
# 1. QuickCheck from a checkout with no external corpora
# ---------------------------------------------------------------------------
$quickRun = $null
Invoke-eMASCheck -Name 'RT-01 QuickCheck without corpora: focused 21+1 SKIP, T4 28/28, oracle 23/23, PASS_WITH_SKIPS (not PASS)' -Action {
    $script:quickRun = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'QuickCheck') + $common)) -Label 'quick'
    $run = $script:quickRun
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'PASS_WITH_SKIPS' $run.Manifest.Run.OverallStatus 'Overall status.'
    Assert-eMASEqual 2 $run.ExitCode 'Exit code.'
    $t2 = Get-eMASStage $run.Manifest 'T2-SUXI'
    Assert-eMASEqual 'PASS_WITH_SKIPS' $t2.Status 'T2 status.'
    Assert-eMASTrue ($t2.Counts.Total -eq 22 -and $t2.Counts.Passed -eq 21 -and $t2.Counts.Skipped -eq 1 -and $t2.Counts.Failed -eq 0) 'T2 counts must be 22 total / 21 passed / 1 skipped.'
    Assert-eMASTrue (@($t2.Diagnostics | Where-Object { $_ -like '[[]SKIP] SD-090*' }).Count -eq 1) 'The SD-090 SKIP must be reported explicitly.'
    $engine = Get-eMASStage $run.Manifest 'T4-ENGINE'; $oracle = Get-eMASStage $run.Manifest 'T4-ORACLE'
    Assert-eMASTrue ($engine.Status -eq 'PASS' -and $engine.Counts.Passed -eq 28 -and $engine.Counts.Total -eq 28) 'T4 engine 28/28.'
    Assert-eMASTrue ($oracle.Status -eq 'PASS' -and $oracle.Counts.Passed -eq 23 -and $oracle.Counts.Total -eq 23) 'T4 oracle 23/23.'
    Assert-eMASEqual 'PASS' (Get-eMASStage $run.Manifest 'FROZEN-MANIFESTS').Status 'Committed freeze manifests.'
    Assert-eMASEqual 6 @($run.Manifest.Stages).Count 'QuickCheck stage count.'
    foreach ($stage in @($run.Manifest.Stages | Where-Object { $_.Kind -eq 'Harness' })) {
        Assert-eMASTrue ($stage.Command.Arguments[0] -eq '-NoProfile' -and $stage.Command.Arguments[1] -eq '-NonInteractive' -and $stage.Command.Arguments[2] -eq '-File') ('{0} must run as pwsh -NoProfile -NonInteractive -File.' -f $stage.Id)
        foreach ($name in @('stdout', 'stderr')) { Assert-eMASTrue ([System.IO.File]::Exists((Join-Path $run.RunDirectory $stage.Artifacts.$name))) ('{0} {1} log missing.' -f $stage.Id, $name) }
    }
}

# ---------------------------------------------------------------------------
# 2. FullRegression
# ---------------------------------------------------------------------------
$wave1Dependent = @('W1-RD', 'W1-BXI', 'W1-RI', 'W1-RR', 'W1-MRI', 'W1-DCC', 'W1-CMI', 'W1-CEC', 'W1D', 'ROOT', 'B3')
$corpusFree = @('T2-SUXI', 'T4-ENGINE', 'T4-ORACLE', 'T1B', 'W1E')
Invoke-eMASCheck -Name 'RT-02 FullRegression without corpora: 11 corpus suites SKIP with cause, 5 corpus-free suites execute, no 15/15 claim' -Action {
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'FullRegression') + $common)) -Label 'full-nocorpus'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'PASS_WITH_SKIPS' $run.Manifest.Run.OverallStatus 'Overall status.'
    foreach ($id in $wave1Dependent) {
        $stage = Get-eMASStage $run.Manifest $id
        Assert-eMASEqual 'SKIP' $stage.Status ('{0} status.' -f $id)
        Assert-eMASTrue ($null -eq $stage.ExitCode -and $null -eq $stage.Command) ('{0} must not have been executed.' -f $id)
        Assert-eMASTrue (@($stage.Reasons) -join ' ' -match 'not supplied') ('{0} must state the missing corpus.' -f $id)
    }
    foreach ($id in $corpusFree) { Assert-eMASTrue (@('PASS', 'PASS_WITH_SKIPS') -contains (Get-eMASStage $run.Manifest $id).Status) ('{0} must execute and pass.' -f $id) }
    Assert-eMASEqual 11 $run.Manifest.Coverage.HarnessStagesSkipped 'Skipped harness stage count.'
    Assert-eMASEqual 5 $run.Manifest.Coverage.HarnessStagesExecuted 'Executed harness stage count.'
    Assert-eMASEqual 15 @($run.Manifest.Stages | Where-Object { $_.GateGroup -eq 'Established15' }).Count 'The plan must list the 15 established gates.'
}

Invoke-eMASCheck -Name 'RT-03 FullRegression with external corpora: 15 gates + focused T2 executed, exact counts, corpora unchanged' -Action {
    if ([string]::IsNullOrWhiteSpace($Wave1CorpusRoot) -or [string]::IsNullOrWhiteSpace($Wave1DCorpusRoot)) { throw 'SKIP: -Wave1CorpusRoot and -Wave1DCorpusRoot were not both supplied; the frozen corpora are external to the repository.' }
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'FullRegression', '-Wave1CorpusRoot', $Wave1CorpusRoot, '-Wave1DCorpusRoot', $Wave1DCorpusRoot) + $common)) -Label 'full-corpus'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'PASS' $run.Manifest.Run.OverallStatus 'Overall status.'
    Assert-eMASEqual 0 $run.ExitCode 'Exit code.'
    Assert-eMASEqual 16 $run.Manifest.Coverage.HarnessStagesExecuted 'Executed harness stages.'
    $t2 = Get-eMASStage $run.Manifest 'T2-SUXI'
    Assert-eMASTrue ($t2.Counts.Passed -eq 22 -and $t2.Counts.Skipped -eq 0 -and $t2.ExpectedProfile -eq 'WithWave1') 'T2 must be 22/22 with the corpus.'
    foreach ($inputRow in @($run.Manifest.Inputs | Where-Object { $_.Role -like 'Wave*' })) { Assert-eMASTrue ($inputRow.UnchangedAfterRun -eq $true) ('{0} hash changed.' -f $inputRow.Role) }
}

Invoke-eMASCheck -Name 'RT-04 FullRegression with a supplied but missing corpus path: dependent suites BLOCKED, overall BLOCKED' -Action {
    $missing = Join-Path $scratch 'no such corpus ü'
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'FullRegression', '-Wave1CorpusRoot', $missing) + $common)) -Label 'full-badcorpus'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'BLOCKED' $run.Manifest.Run.OverallStatus 'Overall status.'
    Assert-eMASEqual 4 $run.ExitCode 'Exit code.'
    Assert-eMASEqual 'BLOCKED' (Get-eMASStage $run.Manifest 'W1-RD').Status 'W1-RD status.'
    Assert-eMASEqual 'BLOCKED' (Get-eMASStage $run.Manifest 'PREFLIGHT').Status 'Preflight status.'
    Assert-eMASEqual 'PASS' (Get-eMASStage $run.Manifest 'T1B').Status 'Unaffected T1B must still run.'
}

# ---------------------------------------------------------------------------
# 3-5, 8. MS04Demo with the real Pre-Sales script
# ---------------------------------------------------------------------------
Invoke-eMASCheck -Name 'RT-05 MS04Demo without Runtime JSON (empty VS Code inputs): evidence executes, identification BLOCKED, no demo PASS' -Action {
    # Empty strings are what the VS Code task passes when the optional prompts are left blank.
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $v4Fixture, '-RuntimeConfigurationPath', '', '-ExpectedIdentificationPath', '', '-SubmissionUnitXmlInventory', 'Exclude') + $common)) -Label 'demo-noconfig'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'BLOCKED' $run.Manifest.Run.OverallStatus 'Overall status.'
    Assert-eMASEqual 4 $run.ExitCode 'Exit code.'
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' (Get-eMASStage $run.Manifest 'DEMO-EVIDENCE').Status 'Evidence status.'
    $identification = Get-eMASStage $run.Manifest 'DEMO-IDENTIFICATION'
    Assert-eMASEqual 'BLOCKED' $identification.Status 'Identification status.'
    Assert-eMASTrue ($null -eq $identification.Command) 'Identification must not have been executed.'
    Assert-eMASTrue (@(Get-ChildItem -LiteralPath $run.RunDirectory -Recurse -Filter 'identification.json').Count -eq 0) 'No Identification document may exist.'
    $evidence = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText((Join-Path $run.RunDirectory (Get-eMASStage $run.Manifest 'DEMO-EVIDENCE').Artifacts.'observed JSON')))
    Assert-eMASEqual 'eMAS.MS04.PreSales.ScannerObservations/1.0' $evidence.ContractId 'Observed evidence contract.'
}

Invoke-eMASCheck -Name 'RT-06 MS04Demo with invalid Runtime JSON: real loader rejection is FAIL, no Identification document fabricated' -Action {
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $v4Fixture, '-RuntimeConfigurationPath', (Join-Path $repositoryRoot 'tests/fixtures/runtime-config/invalid-malformed.json')) + $common)) -Label 'demo-invalid'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'FAIL' $run.Manifest.Run.OverallStatus 'Overall status.'
    $identification = Get-eMASStage $run.Manifest 'DEMO-IDENTIFICATION'
    Assert-eMASEqual 'FAIL' $identification.Status 'Identification status.'
    Assert-eMASTrue ($identification.ExitCode -ne 0) 'The real Pre-Sales script must have exited non-zero.'
    Assert-eMASTrue ((@($identification.Diagnostics) -join ' ') -match 'CFG-FILE-009') 'The real loader error code must be preserved.'
    Assert-eMASTrue (@(Get-ChildItem -LiteralPath $run.RunDirectory -Recurse -Filter 'identification.json').Count -eq 0) 'No Identification document may exist.'
    Assert-eMASEqual 'BLOCKED' (Get-eMASStage $run.Manifest 'DEMO-VERIFICATION').Status 'Verification status.'
}

Invoke-eMASCheck -Name 'RT-07 MS04Demo with synthetic test-only Runtime JSON and no expected document: EXECUTED_UNVERIFIED, never VERIFIED' -Action {
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $v4Fixture, '-RuntimeConfigurationPath', (Join-Path $oracleCase 'runtime-config.json'), '-SubmissionUnitXmlInventory', 'Include') + $common)) -Label 'demo-valid'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' $run.Manifest.Run.OverallStatus 'Overall status.'
    Assert-eMASEqual 3 $run.ExitCode 'Exit code.'
    $identification = Get-eMASStage $run.Manifest 'DEMO-IDENTIFICATION'
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' $identification.Status 'Identification status.'
    $document = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText((Join-Path $run.RunDirectory $identification.Artifacts.'observed JSON')))
    Assert-eMASEqual 'eMAS.MS04.PreSales.Identification/1.0' $document.ContractId 'Identification contract.'
    Assert-eMASEqual 'ORACLE_IDO_01' $document.RuntimeConfig.ConfigurationId 'Runtime JSON identity.'
    Assert-eMASTrue ((@($identification.Reasons) -join ' ') -match 'projection v1 does not consume') 'The T2/T4 v1 limitation must be stated.'
    Assert-eMASTrue ((@($identification.Reasons) -join ' ') -match 'not an approved release configuration') 'A DEV export must not be presented as approved.'
    Assert-eMASEqual 'SKIP' (Get-eMASStage $run.Manifest 'DEMO-VERIFICATION').Status 'No expectation supplied: verification is SKIP, not BLOCKED.'
    $source = @($run.Manifest.Inputs | Where-Object { $_.Role -eq 'Dossier source' })[0]
    Assert-eMASTrue ($source.UnchangedAfterRun -eq $true -and $source.Sha256 -eq (Get-eMASFileSha256 $v4Fixture)) 'Source ZIP must be unchanged.'
}

Invoke-eMASCheck -Name 'RT-08 MS04Demo verification mismatch: an independent expected document that does not match gives FAIL with differences' -Action {
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $v4Fixture, '-RuntimeConfigurationPath', (Join-Path $oracleCase 'runtime-config.json'), '-ExpectedIdentificationPath', (Join-Path $oracleCase 'expected-identification.json')) + $common)) -Label 'demo-mismatch'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'FAIL' $run.Manifest.Run.OverallStatus 'Overall status.'
    $verification = Get-eMASStage $run.Manifest 'DEMO-VERIFICATION'
    Assert-eMASEqual 'FAIL' $verification.Status 'Verification status.'
    Assert-eMASTrue (@($verification.Reasons | Where-Object { $_ -like 'Difference: $.Results*' }).Count -gt 0) 'Differences must be listed.'
}

Invoke-eMASCheck -Name 'RT-09 Comparator and verdict units: volatile fields and key order ignored, value/array-order changes detected, VERIFIED only on equality' -Action {
    $expectedPath = Join-Path $oracleCase 'expected-identification.json'
    $volatile = @((Import-PowerShellDataFile (Join-Path $repositoryRoot 'tools/demo/private/eMAS.MS04SuiteCatalog.psd1')).IdentificationVolatileFields)
    $document = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($expectedPath))
    $document.Execution.StartedAtUtc = '2030-01-01T00:00:00Z'; $document.Execution.ExecutionId = 'OTHER'; $document.EvidenceSource.DocumentSha256 = ('0' * 64)
    $reordered = [ordered]@{}
    foreach ($name in @($document.PSObject.Properties.Name | Sort-Object -Descending)) { $reordered[$name] = $document.$name }
    $samePath = Join-Path $scratch 'same.json'
    [System.IO.File]::WriteAllText($samePath, (ConvertTo-Json -InputObject ([pscustomobject]$reordered) -Depth 100))
    Assert-eMASTrue (Compare-eMASIdentificationDocument -ObservedPath $samePath -ExpectedPath $expectedPath -VolatileFields $volatile).Equal 'Volatile-only and key-order changes must compare equal.'
    $changed = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($expectedPath))
    $changed.Results[0].Confidence = 'LOW'
    $changedPath = Join-Path $scratch 'changed.json'
    [System.IO.File]::WriteAllText($changedPath, (ConvertTo-Json -InputObject $changed -Depth 100))
    $result = Compare-eMASIdentificationDocument -ObservedPath $changedPath -ExpectedPath $expectedPath -VolatileFields $volatile
    Assert-eMASTrue ((-not $result.Equal) -and (@($result.Differences) -contains '$.Results[0].Confidence: value differs')) 'A changed value must be detected at its path.'
    $original = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($expectedPath))
    $withTwo = @($original.Results)
    if ($withTwo.Count -ge 2) {
        $original.Results = @($withTwo[1], $withTwo[0]) + @($withTwo | Select-Object -Skip 2)
        $swappedPath = Join-Path $scratch 'swapped.json'
        [System.IO.File]::WriteAllText($swappedPath, (ConvertTo-Json -InputObject $original -Depth 100))
        Assert-eMASTrue (-not (Compare-eMASIdentificationDocument -ObservedPath $swappedPath -ExpectedPath $expectedPath -VolatileFields $volatile).Equal) 'Array order must be significant.'
    }
    $stages = @(
        [pscustomobject]@{ Id = 'DEMO-EVIDENCE'; Status = 'EXECUTED_UNVERIFIED' }, [pscustomobject]@{ Id = 'DEMO-IDENTIFICATION'; Status = 'EXECUTED_UNVERIFIED' },
        [pscustomobject]@{ Id = 'DEMO-VERIFICATION'; Status = 'VERIFIED' }, [pscustomobject]@{ Id = 'IMMUTABILITY'; Status = 'PASS' })
    Assert-eMASEqual 'VERIFIED' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $stages).Status 'VERIFIED verdict.'
    $stages[2].Status = 'SKIP'
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $stages).Status 'No expected document supplied.'
    $stages[2].Status = 'BLOCKED'
    Assert-eMASEqual 'BLOCKED' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $stages).Status 'An unusable supplied expected document must be BLOCKED, not EXECUTED_UNVERIFIED.'
    $stages[2].Status = 'VERIFIED'
    $withBlockedInput = @($stages) + @([pscustomobject]@{ Id = 'DEMO-INPUTS'; Status = 'BLOCKED' })
    Assert-eMASEqual 'BLOCKED' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $withBlockedInput).Status 'VERIFIED must not survive another BLOCKED stage.'
    $stages[1].Status = 'BLOCKED'
    Assert-eMASEqual 'BLOCKED' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $stages).Status 'No identification.'
    $stages[2].Status = 'VERIFIED'; $stages[3].Status = 'FAIL'; $stages[1].Status = 'EXECUTED_UNVERIFIED'
    Assert-eMASEqual 'FAIL' (Get-eMASOverallVerdict -Mode 'MS04Demo' -Stages $stages).Status 'A failed immutability gate overrides VERIFIED.'
}

# ---------------------------------------------------------------------------
# 6. Escaping / injection
# ---------------------------------------------------------------------------
Invoke-eMASCheck -Name 'RT-10 HTML escaping: hostile paths and diagnostics are encoded; no markup, script or remote reference survives' -Action {
    $hostile = '/tmp/<script>alert(1)</script>&"''/x <img src=x onerror=alert(2)>'
    $manifest = [pscustomobject]@{
        Runner = [pscustomobject]@{ Version = '1<b>'; ScriptSha256 = 'x'; CatalogVersion = 'y'; CatalogSha256 = 'z' }
        Run = [pscustomobject]@{ RunId = 'r"><script>'; Mode = 'QuickCheck</title><script>'; State = 'Completed'; StartedAtUtc = 's'; CompletedAtUtc = 'c'; ElapsedSeconds = 1; OverallStatus = 'FAIL'; OverallReason = '</section><script>x</script>'; ExitCode = 1 }
        Repository = [pscustomobject]@{ Root = $hostile; HeadSha = 'h'; Branch = 'b<i>'; WorktreeClean = $true; StatusEntryCount = 0 }
        Platform = [pscustomobject]@{ OSDescription = '<svg onload=alert(3)>' }
        Inputs = @([pscustomobject]@{ Role = 'Dossier source'; Path = $hostile; Origin = 'Parameter'; Kind = 'File'; FileCount = 1; Sha256 = 'a'; UnchangedAfterRun = $true })
        Stages = @([pscustomobject]@{
                Order = 1; Id = 'X"><script>'; Name = '<iframe>'; Kind = 'Harness'; GateGroup = 'g'; Status = 'FAIL'; Reasons = @('reason </li><script>alert(4)</script>')
                Command = [pscustomobject]@{ Display = 'pwsh -File ''' + $hostile + '''' }; WorkingDirectory = $hostile; ExitCode = 1; TimedOut = $false; StartedAtUtc = 's'; DurationSeconds = 1
                Counts = $null; LineCounts = $null; Expected = $null; ExpectedProfile = $null; Diagnostics = @('[FAIL] </pre><script>alert(5)</script> & "q"')
                Artifacts = [pscustomobject]@{ stdout = 'stages/01-x/std"out<.log' }; Details = [pscustomobject]@{ XmlDerived = '<?xml version="1.0"?><ectd:a xmlns:ectd="&amp;">' }
            })
        Coverage = (Get-eMASCoverage -Stages @())
        Limitations = @('<b>limit</b>')
        Outputs = [pscustomobject]@{ RunDirectory = $hostile }
    }
    $html = New-eMASRunSummaryHtml -Manifest $manifest
    foreach ($forbidden in @('<script', '<img', '<svg', '<iframe', '<b>', '<i>', '<?xml', '<ectd')) { Assert-eMASTrue (-not $html.Contains($forbidden)) ('Unescaped fragment survived: ' + $forbidden) }
    foreach ($required in @('&lt;script&gt;alert(1)&lt;/script&gt;', '&amp;&quot;&#39;', '&lt;?xml', 'href="stages/01-x/std%22out%3C.log"', 'id="stage-X&quot;&gt;&lt;script&gt;"')) { Assert-eMASTrue ($html.Contains($required)) ('Expected encoded fragment missing: ' + $required) }
    Assert-eMASTrue ($html.Contains("default-src 'none'")) 'A restrictive Content-Security-Policy must be present.'
}

$unicodeRun = $null
Invoke-eMASCheck -Name 'RT-11 End-to-end spaces, Unicode and metacharacters in source and output paths' -Action {
    $sourceDir = Join-Path $scratch 'dossier <b>&"'' ü 試験'
    [void][System.IO.Directory]::CreateDirectory($sourceDir)
    $source = Join-Path $sourceDir 'SD 063 <copy>.zip'
    [System.IO.File]::Copy($v4Fixture, $source, $true)
    $outputUnicode = Join-Path $resolvedOutputRoot 'runs ü space'
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]]@('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-Mode', 'MS04Demo', '-SourcePath', $source, '-OutputRoot', $outputUnicode, '-NoUserSettings')) -WorkingDirectory $scratch -StdoutPath (Join-Path $scratch 'unicode.out') -StderrPath (Join-Path $scratch 'unicode.err') -TimeoutSeconds 600
    Assert-eMASEqual 4 $process.ExitCode 'Exit code (BLOCKED: no Runtime JSON).'
    $runDirectory = @(Get-ChildItem -LiteralPath $outputUnicode -Directory)[0].FullName
    $manifest = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText((Join-Path $runDirectory 'run-manifest.json')))
    Assert-eMASEqual $source @($manifest.Inputs | Where-Object { $_.Role -eq 'Dossier source' })[0].Path 'Unicode source path must be recorded verbatim.'
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' (Get-eMASStage $manifest 'DEMO-EVIDENCE').Status 'Evidence must run on the Unicode path.'
    $html = [System.IO.File]::ReadAllText((Join-Path $runDirectory 'summary.html'))
    # WebUtility.HtmlEncode writes Latin-1 letters as numeric entities (ü -> &#252;); decoding must give the exact path back.
    Assert-eMASTrue ($html.Contains('dossier &lt;b&gt;&amp;&quot;&#39; ')) 'Source path markup characters must be HTML-encoded.'
    Assert-eMASTrue ([System.Net.WebUtility]::HtmlDecode($html).Contains($source)) 'Decoded report must contain the exact Unicode source path.'
    Assert-eMASTrue (-not $html.Contains('<b>&')) 'Raw markup from the path must not appear.'
}

Invoke-eMASCheck -Name 'RT-24 MS04Demo with a directory source: real evidence route runs and the directory is unchanged' -Action {
    $directorySource = Join-Path $scratch 'extracted SD-063 ü'
    if (Test-Path -LiteralPath $directorySource) { Remove-Item -LiteralPath $directorySource -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($v4Fixture, $directorySource)
    $before = Get-eMASTreeDigest -Root $directorySource
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $directorySource, '-RuntimeConfigurationPath', (Join-Path $oracleCase 'runtime-config.json')) + $common)) -Label 'demo-directory'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 'EXECUTED_UNVERIFIED' $run.Manifest.Run.OverallStatus 'Overall status.'
    $source = @($run.Manifest.Inputs | Where-Object { $_.Role -eq 'Dossier source' })[0]
    Assert-eMASEqual 'Directory' $source.Kind 'Source kind.'
    Assert-eMASTrue ($source.UnchangedAfterRun -eq $true -and $source.Sha256 -eq $before.Sha256 -and (Get-eMASTreeDigest -Root $directorySource).Sha256 -eq $before.Sha256) 'Directory source must be unchanged.'
}

Invoke-eMASCheck -Name 'RT-26 MS04Demo supplied expectation contract: invalid or missing expected document is BLOCKED, distinct from not supplied' -Action {
    $notIdentification = Join-Path $scratch 'expected-not-identification.json'
    [System.IO.File]::WriteAllText($notIdentification, '{"ContractId":"eMAS.MS04.PreSales.ScannerObservations/1.0"}')
    $malformed = Join-Path $scratch 'expected-malformed.json'
    [System.IO.File]::WriteAllText($malformed, '{"ContractId": ')
    $absent = Join-Path $scratch 'expected-absent.json'
    foreach ($case in @(@{ Label = 'wrong-contract'; Path = $notIdentification }, @{ Label = 'malformed'; Path = $malformed }, @{ Label = 'absent'; Path = $absent })) {
        foreach ($policy in @('Strict', 'Task')) {
            $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'MS04Demo', '-SourcePath', $v4Fixture, '-RuntimeConfigurationPath', (Join-Path $oracleCase 'runtime-config.json'), '-ExpectedIdentificationPath', $case.Path, '-ExitCodePolicy', $policy) + $common)) -Label ('demo-expected-' + $case.Label + '-' + $policy)
            Assert-eMASRunEvidence -Run $run
            Assert-eMASEqual 'BLOCKED' $run.Manifest.Run.OverallStatus ('{0}/{1}: overall status.' -f $case.Label, $policy)
            Assert-eMASEqual 4 $run.ExitCode ('{0}/{1}: BLOCKED exits 4 under every policy.' -f $case.Label, $policy)
            Assert-eMASEqual 'BLOCKED' (Get-eMASStage $run.Manifest 'DEMO-VERIFICATION').Status ('{0}/{1}: verification status.' -f $case.Label, $policy)
            Assert-eMASEqual 'EXECUTED_UNVERIFIED' (Get-eMASStage $run.Manifest 'DEMO-IDENTIFICATION').Status ('{0}/{1}: identification still executed.' -f $case.Label, $policy)
            Assert-eMASTrue ($run.Manifest.Run.OverallReason -match 'DEMO-INPUTS') ('{0}/{1}: reason must name the blocked input stage.' -f $case.Label, $policy)
        }
    }
}

Invoke-eMASCheck -Name 'RT-25 VS Code Task exit policy: completed PASS_WITH_SKIPS exits 0 with an explicit banner; OverallStatus and strict code unchanged' -Action {
    foreach ($status in @('PASS', 'VERIFIED', 'PASS_WITH_SKIPS', 'EXECUTED_UNVERIFIED', 'UNVERIFIED', 'BLOCKED', 'FAIL', 'INCOMPLETE')) {
        $strict = Get-eMASExitCode -Status $status -Policy 'Strict'
        $task = Get-eMASExitCode -Status $status -Policy 'Task'
        $expectedTask = $(if (@('PASS', 'VERIFIED', 'PASS_WITH_SKIPS', 'EXECUTED_UNVERIFIED') -contains $status) { 0 } else { $strict })
        Assert-eMASEqual $expectedTask $task ('Task code for ' + $status)
        if (@('UNVERIFIED', 'BLOCKED', 'FAIL', 'INCOMPLETE') -contains $status) { Assert-eMASTrue ($task -ne 0) ($status + ' must stay non-zero under the Task policy.') }
    }
    Assert-eMASEqual 2 (Get-eMASExitCode -Status 'PASS_WITH_SKIPS') 'Default policy must remain Strict.'
    $run = Invoke-eMASRunner -Arguments ([string[]](@('-Mode', 'QuickCheck', '-ExitCodePolicy', 'Task') + $common)) -Label 'quick-task'
    Assert-eMASRunEvidence -Run $run
    Assert-eMASEqual 0 $run.ExitCode 'Task policy process exit code.'
    Assert-eMASEqual 'PASS_WITH_SKIPS' $run.Manifest.Run.OverallStatus 'OverallStatus must not change with the exit policy.'
    Assert-eMASEqual 2 $run.Manifest.Run.StrictExitCode 'Strict code must still be recorded.'
    Assert-eMASEqual 'Task' $run.Manifest.Run.ExitCodePolicy 'Policy must be recorded.'
    Assert-eMASTrue ($run.Stdout.Contains('RESULT: PASS WITH SKIPS') -and $run.Stdout.Contains('This is not an unqualified PASS.')) 'The terminal banner must state PASS WITH SKIPS explicitly.'
    Assert-eMASTrue ($run.Stdout.Contains('not an unqualified PASS; strict code 2')) 'The terminal must explain the Task exit code.'
    $html = [System.IO.File]::ReadAllText((Join-Path $run.RunDirectory 'summary.html'))
    Assert-eMASTrue ($html.Contains('PASS WITH SKIPS') -and $html.Contains('strict code 2')) 'summary.html must show the qualified result and the strict code.'
    Assert-eMASEqual 1 @($run.Manifest.Stages | Where-Object { $_.Id -eq 'T2-SUXI' -and $_.Counts.Skipped -eq 1 -and $_.Counts.Passed -eq 21 }).Count 'Skipped checks must not be counted as passed.'
}

# ---------------------------------------------------------------------------
# 7. Process failure handling (synthetic stub harness)
# ---------------------------------------------------------------------------
function Invoke-eMASStubStage {
    param([string] $Behavior, [hashtable] $Expected, [int] $Timeout = 120, [string[]] $Extra = @())
    $dir = Join-Path $scratch ('stub-' + $Behavior + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
    [void][System.IO.Directory]::CreateDirectory($dir)
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]](@('-NoProfile', '-NonInteractive', '-File', $stubPath, '-Behavior', $Behavior) + $Extra)) -WorkingDirectory $dir -StdoutPath (Join-Path $dir 'stdout.log') -StderrPath (Join-Path $dir 'stderr.log') -TimeoutSeconds $Timeout
    $stdout = [System.IO.File]::ReadAllText((Join-Path $dir 'stdout.log'))
    $counter = @{ Kind = 'ResultLine'; Pattern = '^Stub tests completed: (?<total>\d+) total, (?<passed>\d+) passed, (?<failed>\d+) failed, (?<skipped>\d+) skipped\.$' }
    $structured = Get-eMASStructuredCounts -Counter $counter -HarnessOutput $dir -Stdout $stdout
    $verdict = Get-eMASHarnessStatus -Process $process -LineCounts (Get-eMASLineCounts -Text $stdout) -Structured $structured -Expected $Expected -GateExpectations $null
    return [pscustomobject]@{ Process = $process; Verdict = $verdict; Directory = $dir }
}

Invoke-eMASCheck -Name 'RT-12 Non-zero exit is FAIL even when the harness printed passes' -Action {
    $r = Invoke-eMASStubStage -Behavior 'NonZeroExit' -Expected @{ Total = 1 }
    Assert-eMASEqual 'FAIL' $r.Verdict.Status 'Status.'
    Assert-eMASTrue ((@($r.Verdict.Reasons) -join ' ') -match 'exit code 3') 'Exit code must be reported.'
    Assert-eMASTrue ([System.IO.File]::ReadAllText((Join-Path $r.Directory 'stderr.log')).Contains('simulated crash <after>')) 'stderr must be preserved verbatim.'
}
Invoke-eMASCheck -Name 'RT-13 Harness-reported failure with exit code 0 is FAIL' -Action {
    $r = Invoke-eMASStubStage -Behavior 'ReportedFailureZeroExit' -Expected $null
    Assert-eMASEqual 0 $r.Process.ExitCode 'Stub exit code.'
    Assert-eMASEqual 'FAIL' $r.Verdict.Status 'Status.'
    Assert-eMASTrue ((@($r.Verdict.Reasons) -join ' ') -match 'despite process exit code 0') 'The zero-exit failure must be called out.'
}
Invoke-eMASCheck -Name 'RT-14 Timeout terminates the process tree and is FAIL' -Action {
    $r = Invoke-eMASStubStage -Behavior 'Sleep' -Expected $null -Timeout 3
    Assert-eMASTrue $r.Process.TimedOut 'TimedOut flag.'
    Assert-eMASTrue ($r.Process.DurationSeconds -lt 30) ('Timeout must stop the stub promptly; took {0}s.' -f $r.Process.DurationSeconds)
    Assert-eMASEqual 'FAIL' $r.Verdict.Status 'Status.'
}
Invoke-eMASCheck -Name 'RT-15 SKIP accounting, missing result and count drift' -Action {
    $skip = Invoke-eMASStubStage -Behavior 'Skip' -Expected @{ Total = 2; Passed = 1; Skipped = 1 }
    Assert-eMASEqual 'PASS_WITH_SKIPS' $skip.Verdict.Status 'Skip status.'
    $none = Invoke-eMASStubStage -Behavior 'NoResultLine' -Expected @{ Total = 1 }
    Assert-eMASEqual 'UNVERIFIED' $none.Verdict.Status 'Exit 0 without a structured result must not be PASS.'
    $drift = Invoke-eMASStubStage -Behavior 'Pass' -Expected @{ Total = 4; Passed = 4 } -Extra @('-Total', '3')
    Assert-eMASEqual 'FAIL' $drift.Verdict.Status 'Fewer tests than the baseline must be FAIL.'
    Assert-eMASTrue ((@($drift.Verdict.Reasons) -join ' ') -match 'Count drift: Total expected 4, observed 3') 'Count drift must be explained.'
    $ok = Invoke-eMASStubStage -Behavior 'Pass' -Expected @{ Total = 3; Passed = 3 } -Extra @('-Total', '3')
    Assert-eMASEqual 'PASS' $ok.Verdict.Status 'Matching counts.'
}
Invoke-eMASCheck -Name 'RT-16 Arguments reach the child verbatim with no shell evaluation' -Action {
    $payload = [string[]]@('a b', "it's", '"double"', '$(whoami)', '`backtick', ';echo pwned', '&&', '|', '*', 'üñí 試験', '<tag>&')
    $dir = Join-Path $scratch 'echo'
    [void][System.IO.Directory]::CreateDirectory($dir)
    $echoPath = Join-Path $dir 'argv.json'
    $process = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]](@('-NoProfile', '-NonInteractive', '-File', $stubPath, '-Behavior', 'EchoArguments', '-OutputPath', $echoPath) + $payload)) -WorkingDirectory $dir -StdoutPath (Join-Path $dir 'o.log') -StderrPath (Join-Path $dir 'e.log') -TimeoutSeconds 60
    Assert-eMASEqual 0 $process.ExitCode 'Echo stub exit code.'
    $argv = @(ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($echoPath)))
    $tail = @($argv | Select-Object -Last $payload.Count)
    for ($i = 0; $i -lt $payload.Count; $i++) { Assert-eMASEqual $payload[$i] $tail[$i] ('Argument {0} changed.' -f $i) }
}

Invoke-eMASCheck -Name 'RT-17 Interrupted run (SIGINT and SIGKILL) is never reported as completed PASS' -Action {
    if (-not ($IsMacOS -or $IsLinux)) { throw 'SKIP: POSIX signals are only exercised on macOS/Linux.' }
    foreach ($signal in @('INT', 'KILL')) {
        $out = Join-Path $resolvedOutputRoot ('interrupt-' + $signal)
        [void][System.IO.Directory]::CreateDirectory($out)
        $info = New-Object System.Diagnostics.ProcessStartInfo
        $info.FileName = $pwshPath
        foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-Mode', 'QuickCheck', '-OutputRoot', $out, '-NoUserSettings')) { $info.ArgumentList.Add($argument) }
        $info.UseShellExecute = $false; $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::Start($info)
        $stdoutTask = $process.StandardOutput.ReadToEndAsync(); $stderrTask = $process.StandardError.ReadToEndAsync()
        $deadline = [DateTime]::UtcNow.AddSeconds(60)
        $manifestFile = $null
        while ([DateTime]::UtcNow -lt $deadline) {
            $manifestFile = @(Get-ChildItem -LiteralPath $out -Recurse -Filter 'run-manifest.json' -ErrorAction SilentlyContinue | Select-Object -First 1)
            if ($manifestFile.Count -eq 1 -and [System.IO.File]::ReadAllText($manifestFile[0].FullName).Contains('"Status": "RUNNING"')) { break }
            Start-Sleep -Milliseconds 100
        }
        Assert-eMASTrue ($manifestFile.Count -eq 1) 'The runner did not reach a running stage.'
        & /bin/kill ('-' + $signal) $process.Id
        [void]$process.WaitForExit(60000)
        [void]$stdoutTask.Wait(5000); [void]$stderrTask.Wait(5000)
        $manifest = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($manifestFile[0].FullName))
        Assert-eMASEqual 'INCOMPLETE' $manifest.Run.OverallStatus ('{0}: overall status.' -f $signal)
        Assert-eMASTrue (@($manifest.Stages | Where-Object { $_.Status -eq 'NOT_RUN' }).Count -gt 0) ('{0}: remaining stages must be NOT_RUN.' -f $signal)
        Assert-eMASTrue ([System.IO.File]::ReadAllText((Join-Path $manifestFile[0].DirectoryName 'summary.html')).Contains('INCOMPLETE')) ('{0}: summary.html must show INCOMPLETE.' -f $signal)
        if ($signal -eq 'INT') {
            Assert-eMASEqual 'Interrupted' $manifest.Run.State 'SIGINT state.'
            Assert-eMASEqual 5 $process.ExitCode 'SIGINT exit code.'
            Assert-eMASTrue (@($manifest.Stages | Where-Object { $_.Status -eq 'FAIL' -and (@($_.Reasons) -join ' ') -match 'Interrupted while running' }).Count -eq 1) 'The running stage must be marked interrupted.'
        }
        else { Assert-eMASEqual 'InProgress' $manifest.Run.State 'A killed runner leaves the last saved InProgress state.' }
    }
}

# ---------------------------------------------------------------------------
# 8. Output guard, uniqueness, immutability, no network
# ---------------------------------------------------------------------------
Invoke-eMASCheck -Name 'RT-18 Output-path guard rejects repository, source, config, corpus, symlink escape, relative, traversal and file targets' -Action {
    $protected = [ordered]@{ repository = $repositoryRoot; source = (Join-Path $scratch 'src'); 'runtime configuration directory' = (Join-Path $scratch 'cfg'); 'Wave 1 corpus' = (Join-Path $scratch 'w1') }
    foreach ($path in @($protected.Values)) { [void][System.IO.Directory]::CreateDirectory($path) }
    $link = Join-Path $scratch 'link-to-repo'
    if (-not (Test-Path -LiteralPath $link)) { [void](New-Item -ItemType SymbolicLink -Path $link -Target $repositoryRoot) }
    $file = Join-Path $scratch 'a-file.txt'; [System.IO.File]::WriteAllText($file, 'x')
    $cases = @(
        @{ Path = (Join-Path $repositoryRoot 'output/runs'); Code = 'RUNNER-PATH-005' }
        @{ Path = ($repositoryRoot.ToUpperInvariant() + '/x'); Code = 'RUNNER-PATH-005' }
        @{ Path = (Join-Path $scratch 'src/out'); Code = 'RUNNER-PATH-005' }
        @{ Path = (Join-Path $scratch 'cfg'); Code = 'RUNNER-PATH-005' }
        @{ Path = (Join-Path $scratch 'w1/deep/out'); Code = 'RUNNER-PATH-005' }
        @{ Path = (Join-Path $link 'tests/out'); Code = 'RUNNER-PATH-005' }
        @{ Path = 'relative/out'; Code = 'RUNNER-PATH-002' }
        @{ Path = ($scratch + '/../escape'); Code = 'RUNNER-PATH-003' }
        @{ Path = $file; Code = 'RUNNER-PATH-004' }
    )
    foreach ($case in $cases) {
        $message = $null
        try { [void](Resolve-eMASOutputRoot -OutputRoot $case.Path -ProtectedRoots $protected) } catch { $message = $_.Exception.Message }
        Assert-eMASTrue ($null -ne $message -and $message.StartsWith($case.Code)) ('{0} must be rejected with {1}; got: {2}' -f $case.Path, $case.Code, $message)
    }
    Assert-eMASTrue ((Resolve-eMASOutputRoot -OutputRoot (Join-Path $scratch 'ok-out') -ProtectedRoots $protected).EndsWith('ok-out')) 'A safe external root must be accepted.'
    $refused = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]]@('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-Mode', 'QuickCheck', '-OutputRoot', (Join-Path $repositoryRoot 'output/demo-runner-guard-test'), '-NoUserSettings')) -WorkingDirectory $scratch -StdoutPath (Join-Path $scratch 'guard.out') -StderrPath (Join-Path $scratch 'guard.err') -TimeoutSeconds 120
    Assert-eMASEqual 6 $refused.ExitCode 'The runner must refuse an output root inside the repository.'
    Assert-eMASTrue (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot 'output/demo-runner-guard-test'))) 'Nothing may be created inside the repository.'
    Assert-eMASTrue ([System.IO.File]::ReadAllText((Join-Path $scratch 'guard.err')).Contains('RUNNER-PATH-005')) 'The refusal must name the guard code.'
}

Invoke-eMASCheck -Name 'RT-19 Repeated runs get unique directories and never overwrite an existing run' -Action {
    $root = Join-Path $scratch 'unique'
    $id = New-eMASRunId -Mode 'QuickCheck' -StartedAtUtc ([DateTime]::UtcNow)
    [void](New-eMASRunDirectory -OutputRoot $root -RunId $id)
    $message = $null
    try { [void](New-eMASRunDirectory -OutputRoot $root -RunId $id) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue ($null -ne $message -and $message.StartsWith('RUNNER-PATH-007')) 'An existing run directory must not be reused.'
    $ids = 1..50 | ForEach-Object { New-eMASRunId -Mode 'QuickCheck' -StartedAtUtc ([DateTime]'2026-01-01') }
    Assert-eMASEqual 50 @($ids | Sort-Object -Unique).Count 'Run ids generated in the same second must differ.'
    $runDirectories = @(Get-ChildItem -LiteralPath $runs -Directory | ForEach-Object Name)
    Assert-eMASEqual $runDirectories.Count @($runDirectories | Sort-Object -Unique).Count 'Every runner invocation in this suite produced its own directory.'
}

Invoke-eMASCheck -Name 'RT-20 User settings: unsupported key or missing explicit file is refused before any run directory is created' -Action {
    $settings = Join-Path $scratch 'settings-bad.json'
    [System.IO.File]::WriteAllText($settings, '{"Wave1CorpusRoot":"/x","Password":"nope"}')
    $before = @(Get-ChildItem -LiteralPath $runs -Directory).Count
    $bad = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]]@('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-Mode', 'QuickCheck', '-OutputRoot', $runs, '-UserSettingsPath', $settings)) -WorkingDirectory $scratch -StdoutPath (Join-Path $scratch 's1.out') -StderrPath (Join-Path $scratch 's1.err') -TimeoutSeconds 120
    Assert-eMASEqual 6 $bad.ExitCode 'Unsupported settings key.'
    $missing = Invoke-eMASChildProcess -Executable $pwshPath -Arguments ([string[]]@('-NoProfile', '-NonInteractive', '-File', $runnerPath, '-Mode', 'QuickCheck', '-OutputRoot', $runs, '-UserSettingsPath', (Join-Path $scratch 'absent.json'))) -WorkingDirectory $scratch -StdoutPath (Join-Path $scratch 's2.out') -StderrPath (Join-Path $scratch 's2.err') -TimeoutSeconds 120
    Assert-eMASEqual 6 $missing.ExitCode 'Missing explicit settings file.'
    Assert-eMASEqual $before @(Get-ChildItem -LiteralPath $runs -Directory).Count 'No run directory may be created.'
}

Invoke-eMASCheck -Name 'RT-21 Static: runner has no network, download, Invoke-Expression or shell-string execution' -Action {
    $files = @(Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'tools/demo') -Recurse -File -Include 'Invoke-eMASMS04Demo.ps1', 'eMAS.MS04*.ps*1')
    Assert-eMASEqual 4 $files.Count 'Runner file set.'
    foreach ($file in $files) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($pattern in @('Invoke-WebRequest', 'Invoke-RestMethod', 'Net.WebClient', 'HttpClient', 'Invoke-Expression', '\biex\b', 'Start-BitsTransfer', 'Install-Module', 'Install-Package', 'UseShellExecute\s*=\s*\$true', '/bin/(ba|z)?sh', 'cmd\.exe', 'https?://')) {
            Assert-eMASTrue ($text -notmatch $pattern) ('{0} matches forbidden pattern {1}' -f $file.Name, $pattern)
        }
    }
}

Invoke-eMASCheck -Name 'RT-22 Static: VS Code tasks are one-click, process-type, with no personal paths' -Action {
    $tasks = [System.IO.File]::ReadAllText((Join-Path $repositoryRoot '.vscode/tasks.json')) | ConvertFrom-Json
    $labels = @($tasks.tasks | ForEach-Object label)
    foreach ($label in @('eMAS: MS-04 Quick Check', 'eMAS: MS-04 Full Regression', 'eMAS: MS-04 Demo')) { Assert-eMASTrue ($labels -contains $label) ('Missing task ' + $label) }
    foreach ($task in @($tasks.tasks | Where-Object { $_.label -like 'eMAS: MS-04*' })) {
        Assert-eMASEqual 'process' $task.type ('{0} must not go through a shell.' -f $task.label)
        $joined = @($task.args) -join ' '
        Assert-eMASTrue ($joined -notmatch '/Users/|/home/|C:\\\\') ('{0} contains a personal path.' -f $task.label)
        Assert-eMASTrue ($joined.Contains('tools/demo/Invoke-eMASMS04Demo.ps1')) ('{0} must call the runner.' -f $task.label)
        Assert-eMASTrue ($joined.Contains('-ExitCodePolicy Task')) ('{0} must use the Task exit-code policy.' -f $task.label)
    }
    $quick = @($tasks.tasks | Where-Object { $_.label -eq 'eMAS: MS-04 Quick Check' })[0]
    Assert-eMASTrue (-not ((@($quick.args) -join ' ').Contains('${input:'))) 'Quick Check must need no input.'
}

$repositoryAfter = Get-eMASRepositoryState
Invoke-eMASCheck -Name 'RT-23 Repository, committed fixtures and oracle unchanged by the whole suite' -Action {
    Assert-eMASEqual $repositoryBefore.Head $repositoryAfter.Head 'HEAD changed.'
    Assert-eMASEqual $repositoryBefore.StatusDigest $repositoryAfter.StatusDigest 'git status changed.'
    Assert-eMASEqual $repositoryBefore.Fixtures $repositoryAfter.Fixtures 'tests/fixtures changed.'
    Assert-eMASEqual $repositoryBefore.Oracle $repositoryAfter.Oracle 'Oracle changed.'
}

$summary = [pscustomobject][ordered]@{
    Suite = 'MS04DemoRunner'; Runtime = [string]$PSVersionTable.PSVersion; Platform = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    Total = $script:passed + $script:failed + $script:skipped; Passed = $script:passed; Failed = $script:failed; Skipped = $script:skipped
    Checks = [object[]]@($checks)
}
$summaryPath = Join-Path $resolvedOutputRoot 'demo-runner-test-summary.json'
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('MS04DemoRunner tests completed: {0} total, {1} passed, {2} failed, {3} skipped; summary={4}' -f $summary.Total, $summary.Passed, $summary.Failed, $summary.Skipped, $summaryPath)
if ($script:failed -gt 0) { exit 1 }
exit 0
