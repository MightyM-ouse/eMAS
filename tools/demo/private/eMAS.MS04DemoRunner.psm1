#requires -Version 7.0
# MS-04 demo runner: path safety, hashing, child-process execution, result
# normalization and verdicts. Contains no assessment, scanner or rule logic.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:PathComparison = [System.StringComparison]::OrdinalIgnoreCase
$script:SupportsDateKind = (Get-Command -Name ConvertFrom-Json).Parameters.ContainsKey('DateKind')

function ConvertFrom-eMASJsonText {
    # Keeps ISO timestamps as strings where the host supports it (PowerShell 7.5+).
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text)
    if ($script:SupportsDateKind) { return ($Text | ConvertFrom-Json -Depth 100 -DateKind String) }
    return ($Text | ConvertFrom-Json -Depth 100)
}
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

function Test-eMASPathHasTraversal {
    param([Parameter(Mandatory = $true)][string] $Path)
    foreach ($segment in ($Path -split '[\\/]')) { if ($segment -eq '..') { return $true } }
    return $false
}

function Get-eMASRealPath {
    # Resolves symbolic links in every existing component; a missing tail is appended as given.
    param([Parameter(Mandatory = $true)][string] $Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($full)
    $parts = @($full.Substring($root.Length) -split '[\\/]' | Where-Object { $_ -ne '' })
    $current = $root
    $hops = 0
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $candidate = Join-Path $current $parts[$i]
        if (-not (Test-Path -LiteralPath $candidate)) {
            $rest = @($parts | Select-Object -Skip ($i + 1))
            if ($rest.Count -eq 0) { return [System.IO.Path]::GetFullPath($candidate) }
            return [System.IO.Path]::GetFullPath((Join-Path $candidate ($rest -join [System.IO.Path]::DirectorySeparatorChar)))
        }
        $item = Get-Item -LiteralPath $candidate -Force
        if ($null -ne $item.LinkTarget) {
            if (++$hops -gt 40) { throw ('RUNNER-PATH-006 Too many symbolic links while resolving {0}.' -f $Path) }
            $target = $item.LinkTarget
            if (-not [System.IO.Path]::IsPathRooted($target)) { $target = Join-Path $current $target }
            $rest = @($parts | Select-Object -Skip ($i + 1))
            $resolvedTarget = Get-eMASRealPath -Path $target
            if ($rest.Count -eq 0) { return $resolvedTarget }
            return Get-eMASRealPath -Path (Join-Path $resolvedTarget ($rest -join [System.IO.Path]::DirectorySeparatorChar))
        }
        $current = $candidate
    }
    return [System.IO.Path]::GetFullPath($current)
}

function Test-eMASPathWithin {
    # True when Child equals Parent or lies below it (case-insensitive, separator-aware).
    param([Parameter(Mandatory = $true)][string] $Child, [Parameter(Mandatory = $true)][string] $Parent)
    $c = $Child.TrimEnd('/', '\')
    $p = $Parent.TrimEnd('/', '\')
    if ($c.Equals($p, $script:PathComparison)) { return $true }
    return $c.StartsWith($p + [System.IO.Path]::DirectorySeparatorChar, $script:PathComparison) -or $c.StartsWith($p + '/', $script:PathComparison)
}

function Resolve-eMASOutputRoot {
    # Returns the real output root or throws RUNNER-PATH-* when it is unsafe.
    param(
        [Parameter(Mandatory = $true)][string] $OutputRoot,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary] $ProtectedRoots
    )
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) { throw 'RUNNER-PATH-001 Output root is empty.' }
    if (-not [System.IO.Path]::IsPathRooted($OutputRoot)) { throw ('RUNNER-PATH-002 Output root must be an absolute path: {0}' -f $OutputRoot) }
    if (Test-eMASPathHasTraversal -Path $OutputRoot) { throw ('RUNNER-PATH-003 Output root must not contain ".." segments: {0}' -f $OutputRoot) }
    $real = Get-eMASRealPath -Path $OutputRoot
    if ([System.IO.File]::Exists($real)) { throw ('RUNNER-PATH-004 Output root is an existing file, not a directory: {0}' -f $OutputRoot) }
    foreach ($role in @($ProtectedRoots.Keys)) {
        $protected = [string]$ProtectedRoots[$role]
        if ([string]::IsNullOrWhiteSpace($protected)) { continue }
        $protectedReal = Get-eMASRealPath -Path $protected
        if (Test-eMASPathWithin -Child $real -Parent $protectedReal) {
            throw ('RUNNER-PATH-005 Output root {0} resolves inside the protected {1} ({2}). Choose a directory outside the repository, source, configuration and corpora.' -f $OutputRoot, $role, $protectedReal)
        }
    }
    return $real
}

function New-eMASRunDirectory {
    param([Parameter(Mandatory = $true)][string] $OutputRoot, [Parameter(Mandatory = $true)][string] $RunId)
    [void][System.IO.Directory]::CreateDirectory($OutputRoot)
    $runDirectory = Join-Path $OutputRoot $RunId
    if (Test-Path -LiteralPath $runDirectory) { throw ('RUNNER-PATH-007 Run directory already exists and will not be overwritten: {0}' -f $runDirectory) }
    [void][System.IO.Directory]::CreateDirectory($runDirectory)
    return $runDirectory
}

function New-eMASRunId {
    param([Parameter(Mandatory = $true)][string] $Mode, [Parameter(Mandatory = $true)][datetime] $StartedAtUtc)
    return ('{0}-{1}-{2}' -f $StartedAtUtc.ToString('yyyyMMdd-HHmmss'), $Mode, [guid]::NewGuid().ToString('N').Substring(0, 8))
}

# ---------------------------------------------------------------------------
# Hashing and immutability
# ---------------------------------------------------------------------------

function Get-eMASFileSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.Convert]::ToHexString($algorithm.ComputeHash($stream)).ToLowerInvariant() }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}

function Get-eMASTextSha256 {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.Convert]::ToHexString($algorithm.ComputeHash($script:Utf8NoBom.GetBytes($Text))).ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function Get-eMASTreeDigest {
    # Digest of every file below Root (symlinks followed; Finder .DS_Store ignored).
    param([Parameter(Mandatory = $true)][string] $Root)
    $rootFull = (Get-eMASRealPath -Path $Root).TrimEnd('/', '\')
    $lines = New-Object System.Collections.Generic.List[string]
    $files = @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force -FollowSymlink -ErrorAction Stop | Where-Object { $_.Name -ne '.DS_Store' })
    foreach ($file in $files) {
        $relative = [System.IO.Path]::GetRelativePath($rootFull, $file.FullName).Replace('\', '/')
        $lines.Add(('{0}|{1}' -f $relative, (Get-eMASFileSha256 -Path $file.FullName)))
    }
    $sorted = [string[]]$lines.ToArray()
    [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return [pscustomobject][ordered]@{ FileCount = $sorted.Count; Sha256 = Get-eMASTextSha256 -Text ($sorted -join "`n") }
}

function Get-eMASInputDigest {
    param([Parameter(Mandatory = $true)][string] $Path)
    if ([System.IO.File]::Exists($Path)) { return [pscustomobject][ordered]@{ Kind = 'File'; FileCount = 1; Sha256 = Get-eMASFileSha256 -Path $Path } }
    if ([System.IO.Directory]::Exists($Path)) { $tree = Get-eMASTreeDigest -Root $Path; return [pscustomobject][ordered]@{ Kind = 'Directory'; FileCount = $tree.FileCount; Sha256 = $tree.Sha256 } }
    return [pscustomobject][ordered]@{ Kind = 'Missing'; FileCount = 0; Sha256 = $null }
}

function Test-eMASCommittedManifest {
    # Verifies the rows of a committed freeze manifest against the bytes on disk.
    param([Parameter(Mandatory = $true)][string] $RepositoryRoot, [Parameter(Mandatory = $true)][System.Collections.IDictionary] $Definition)
    $manifestPath = Join-Path $RepositoryRoot $Definition.Path
    $result = [ordered]@{ Id = $Definition.Id; Path = $Definition.Path; Rows = 0; Verified = 0; Mismatches = @(); Missing = @() }
    if (-not [System.IO.File]::Exists($manifestPath)) { $result.Missing = @($Definition.Path); return [pscustomobject]$result }
    $baseDirectory = Split-Path -Parent $manifestPath
    $rows = @(Import-Csv -LiteralPath $manifestPath)
    $result.Rows = $rows.Count
    $mismatches = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($row in $rows) {
        $relative = [string]$row.($Definition.PathColumn)
        $filePath = Join-Path $baseDirectory $relative
        if (-not [System.IO.File]::Exists($filePath)) { $missing.Add($relative); continue }
        if ((Get-eMASFileSha256 -Path $filePath) -ne ([string]$row.($Definition.HashColumn)).ToLowerInvariant()) { $mismatches.Add($relative); continue }
        $result.Verified++
    }
    $result.Mismatches = [string[]]$mismatches.ToArray()
    $result.Missing = [string[]]$missing.ToArray()
    return [pscustomobject]$result
}

# ---------------------------------------------------------------------------
# Environment and Git (read-only)
# ---------------------------------------------------------------------------

function Get-eMASGitState {
    param([Parameter(Mandatory = $true)][string] $RepositoryRoot)
    $state = [ordered]@{ Available = $false; HeadSha = $null; Branch = $null; WorktreeClean = $null; StatusEntryCount = $null; StatusDigest = $null; Error = $null }
    $git = Get-Command -Name git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $git) { $state.Error = 'git executable not found on PATH.'; return [pscustomobject]$state }
    try {
        # --no-optional-locks keeps 'git status' from refreshing .git/index.
        $head = & $git.Source --no-optional-locks -C $RepositoryRoot rev-parse HEAD 2>$null
        if ($LASTEXITCODE -ne 0) { $state.Error = 'Not a Git checkout (rev-parse failed).'; return [pscustomobject]$state }
        $branch = & $git.Source --no-optional-locks -C $RepositoryRoot rev-parse --abbrev-ref HEAD 2>$null
        $status = @(& $git.Source --no-optional-locks -C $RepositoryRoot status --porcelain=v1 --untracked-files=all 2>$null)
        if ($LASTEXITCODE -ne 0) { $state.Error = 'git status failed.'; return [pscustomobject]$state }
        $state.Available = $true
        $state.HeadSha = ([string]$head).Trim()
        $state.Branch = ([string]$branch).Trim()
        $state.StatusEntryCount = $status.Count
        $state.WorktreeClean = ($status.Count -eq 0)
        $state.StatusDigest = Get-eMASTextSha256 -Text ($status -join "`n")
    }
    catch { $state.Error = $_.Exception.Message }
    return [pscustomobject]$state
}

function Get-eMASPlatformInfo {
    return [pscustomobject][ordered]@{
        OSDescription = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        OSPlatform = $(if ($IsMacOS) { 'macOS' } elseif ($IsLinux) { 'Linux' } elseif ($IsWindows) { 'Windows' } else { 'Unknown' })
        Architecture = [string][System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        PowerShellVersion = [string]$PSVersionTable.PSVersion
        PowerShellEdition = [string]$PSVersionTable.PSEdition
        PowerShellExecutable = Get-eMASPwshPath
        DotNet = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        MachineName = [System.Environment]::MachineName
    }
}

function Get-eMASPwshPath {
    $path = [System.Environment]::ProcessPath
    if (-not [string]::IsNullOrWhiteSpace($path) -and [System.IO.Path]::GetFileNameWithoutExtension($path) -eq 'pwsh') { return $path }
    $command = Get-Command -Name pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) { return $command.Source }
    throw 'RUNNER-ENV-001 pwsh executable not found.'
}

# ---------------------------------------------------------------------------
# Child processes
# ---------------------------------------------------------------------------

function Format-eMASCommandLine {
    # Display-only rendering; execution never goes through a shell.
    param([Parameter(Mandatory = $true)][string] $Executable, [AllowEmptyString()][string[]] $Arguments = @())
    $quoted = foreach ($value in (@($Executable) + @($Arguments))) {
        if ($value -match '^[A-Za-z0-9_./:=@+,-]+$') { $value } else { "'" + $value.Replace("'", "''") + "'" }
    }
    return ($quoted -join ' ')
}

function Invoke-eMASChildProcess {
    # Runs Executable with an explicit argument list (no shell), streaming to files.
    param(
        [Parameter(Mandatory = $true)][string] $Executable,
        [AllowEmptyString()][string[]] $Arguments = @(),
        [Parameter(Mandatory = $true)][string] $WorkingDirectory,
        [Parameter(Mandatory = $true)][string] $StdoutPath,
        [Parameter(Mandatory = $true)][string] $StderrPath,
        [ValidateRange(1, 86400)][int] $TimeoutSeconds = 900
    )
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.RedirectStandardInput = $true
    $info.StandardOutputEncoding = $script:Utf8NoBom
    $info.StandardErrorEncoding = $script:Utf8NoBom
    # Plain-text error rendering in the child; harness behaviour is unaffected.
    $info.Environment['NO_COLOR'] = '1'
    $result = [ordered]@{ ExitCode = $null; TimedOut = $false; Interrupted = $true; StartedAtUtc = [DateTime]::UtcNow.ToString('o'); DurationSeconds = $null; LaunchError = $null }
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    $stdoutTask = $null
    $stderrTask = $null
    try {
        try { [void]$process.Start() }
        catch { $result.LaunchError = $_.Exception.Message; $result.Interrupted = $false; return [pscustomobject]$result }
        $process.StandardInput.Close()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        # Poll so that Ctrl+C can stop the runner between waits; finally kills the child.
        while (-not $process.WaitForExit(250)) {
            if ($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                $result.TimedOut = $true
                try { $process.Kill($true) } catch { }
                [void]$process.WaitForExit(10000)
                break
            }
        }
        if (-not $result.TimedOut) { $process.WaitForExit() }
        $result.ExitCode = $(if ($process.HasExited) { $process.ExitCode } else { $null })
        $result.Interrupted = $false
    }
    finally {
        try { if (-not $process.HasExited) { $process.Kill($true) } } catch { }
        $watch.Stop()
        $result.DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
        $stdout = ''
        $stderr = ''
        if ($null -ne $stdoutTask) { try { [void]$stdoutTask.Wait(5000); $stdout = $stdoutTask.Result } catch { } }
        if ($null -ne $stderrTask) { try { [void]$stderrTask.Wait(5000); $stderr = $stderrTask.Result } catch { } }
        [System.IO.File]::WriteAllText($StdoutPath, [string]$stdout, $script:Utf8NoBom)
        [System.IO.File]::WriteAllText($StderrPath, [string]$stderr, $script:Utf8NoBom)
        $process.Dispose()
    }
    return [pscustomobject]$result
}

# ---------------------------------------------------------------------------
# Harness result normalization
# ---------------------------------------------------------------------------

function Get-eMASLineCounts {
    param([AllowEmptyString()][string] $Text = '')
    $lines = @($Text -split "\r?\n")
    return [pscustomobject][ordered]@{
        Pass = @($lines | Where-Object { $_.StartsWith('[PASS]', [System.StringComparison]::Ordinal) }).Count
        Fail = @($lines | Where-Object { $_.StartsWith('[FAIL]', [System.StringComparison]::Ordinal) }).Count
        Skip = @($lines | Where-Object { $_.StartsWith('[SKIP]', [System.StringComparison]::Ordinal) }).Count
    }
}

function Remove-eMASAnsiEscape {
    param([AllowNull()][string] $Text)
    if ($null -eq $Text) { return '' }
    return [regex]::Replace($Text, '\x1B\[[0-9;?]*[ -/]*[@-~]', '')
}

function Get-eMASDiagnosticLines {
    # [FAIL]/[SKIP] lines, the last result line and stderr tail; capped for the report.
    param([AllowEmptyString()][string] $Stdout = '', [AllowEmptyString()][string] $Stderr = '', [int] $Limit = 40)
    $Stdout = Remove-eMASAnsiEscape -Text $Stdout
    $Stderr = Remove-eMASAnsiEscape -Text $Stderr
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($Stdout -split "\r?\n")) {
        if ($line.StartsWith('[FAIL]', [System.StringComparison]::Ordinal) -or $line.StartsWith('[SKIP]', [System.StringComparison]::Ordinal)) { $out.Add($line) }
    }
    $nonEmpty = @($Stdout -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($nonEmpty.Count -gt 0) { $out.Add('result: ' + $nonEmpty[-1]) }
    foreach ($line in @($Stderr -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 15)) { $out.Add('stderr: ' + $line) }
    return , [string[]]@($out | Select-Object -First $Limit | ForEach-Object { if ($_.Length -gt 600) { $_.Substring(0, 600) + '…' } else { $_ } })
}

function Get-eMASSumOfFields {
    param([Parameter(Mandatory = $true)][object] $Document, [string[]] $Fields = @())
    $sum = 0
    foreach ($field in $Fields) {
        $property = $Document.PSObject.Properties[$field]
        if ($null -eq $property -or $null -eq $property.Value) { throw ('summary field {0} is missing' -f $field) }
        $sum += [int]$property.Value
    }
    return $sum
}

function Get-eMASStructuredCounts {
    # Reads the harness's own structured result; never infers counts from the exit code.
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary] $Counter,
        [Parameter(Mandatory = $true)][string] $HarnessOutput,
        [AllowEmptyString()][string] $Stdout = ''
    )
    $result = [ordered]@{ Available = $false; Source = $null; Total = $null; Passed = $null; Failed = $null; Skipped = $null; ReportedStatus = $null; Gates = [ordered]@{}; Error = $null }
    try {
        if ($Counter.Kind -eq 'Summary') {
            $summaryPath = Join-Path $HarnessOutput $Counter.SummaryFile
            $result.Source = $Counter.SummaryFile
            if (-not [System.IO.File]::Exists($summaryPath)) { $result.Error = ('harness summary {0} was not written' -f $Counter.SummaryFile); return [pscustomobject]$result }
            $document = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($summaryPath))
            $result.Total = Get-eMASSumOfFields -Document $document -Fields $Counter.TotalFields
            $result.Failed = Get-eMASSumOfFields -Document $document -Fields $Counter.FailFields
            $result.Skipped = $(if ($Counter.ContainsKey('SkipFields')) { Get-eMASSumOfFields -Document $document -Fields $Counter.SkipFields } else { 0 })
            $result.Passed = $(if ($Counter.ContainsKey('PassFields')) { Get-eMASSumOfFields -Document $document -Fields $Counter.PassFields } else { $result.Total - $result.Failed - $result.Skipped })
            if ($Counter.ContainsKey('StatusField')) { $result.ReportedStatus = [string]$document.($Counter.StatusField) }
            if ($Counter.ContainsKey('Gates')) {
                foreach ($gate in @($Counter.Gates.Keys | Sort-Object)) {
                    $property = $document.PSObject.Properties[$gate]
                    $result.Gates[$gate] = $(if ($null -eq $property) { $null } else { $property.Value })
                }
            }
        }
        elseif ($Counter.Kind -eq 'ResultLine') {
            $result.Source = 'stdout result line'
            $match = $null
            foreach ($line in @($Stdout -split "\r?\n")) { $m = [regex]::Match($line.Trim(), $Counter.Pattern); if ($m.Success) { $match = $m } }
            if ($null -eq $match) { $result.Error = 'harness result line was not found in stdout'; return [pscustomobject]$result }
            $result.Total = [int]$match.Groups['total'].Value
            $result.Failed = [int]$match.Groups['failed'].Value
            $result.Skipped = $(if ($match.Groups['skipped'].Success) { [int]$match.Groups['skipped'].Value } else { 0 })
            $result.Passed = $(if ($match.Groups['passed'].Success) { [int]$match.Groups['passed'].Value } else { $result.Total - $result.Failed - $result.Skipped })
        }
        else { throw ('unknown counter kind {0}' -f $Counter.Kind) }
        $result.Available = $true
    }
    catch { $result.Available = $false; $result.Error = $_.Exception.Message }
    return [pscustomobject]$result
}

function Get-eMASHarnessStatus {
    # Combines exit code, harness-reported results and catalog expectations into one stage status.
    param(
        [Parameter(Mandatory = $true)][object] $Process,
        [Parameter(Mandatory = $true)][object] $LineCounts,
        [Parameter(Mandatory = $true)][object] $Structured,
        [AllowNull()][System.Collections.IDictionary] $Expected,
        [AllowNull()][System.Collections.IDictionary] $GateExpectations
    )
    $reasons = New-Object System.Collections.Generic.List[string]
    $failed = $false
    if ($null -ne $Process.LaunchError) { $reasons.Add('Launch error: ' + $Process.LaunchError); $failed = $true }
    if ($Process.Interrupted) { $reasons.Add('Interrupted before the harness exited.'); $failed = $true }
    if ($Process.TimedOut) { $reasons.Add('Timed out; the process tree was terminated.'); $failed = $true }
    if ($null -ne $Process.ExitCode -and $Process.ExitCode -ne 0) { $reasons.Add(('Process exit code {0}.' -f $Process.ExitCode)); $failed = $true }
    $harnessFailure = $LineCounts.Fail -gt 0 -or ($Structured.Available -and $Structured.Failed -gt 0) -or ($null -ne $Structured.ReportedStatus -and $Structured.ReportedStatus -ne 'PASS')
    if ($harnessFailure) {
        $suffix = $(if ($Process.ExitCode -eq 0) { ' despite process exit code 0' } else { '' })
        $reasons.Add(('Harness reported failure{0}: {1} [FAIL] line(s); structured failed={2}; reported status={3}.' -f $suffix, $LineCounts.Fail, $Structured.Failed, $Structured.ReportedStatus))
        $failed = $true
    }
    if (-not $Structured.Available) { $reasons.Add('Structured result unavailable: ' + $Structured.Error) }
    elseif ($null -ne $Expected) {
        foreach ($name in @('Total', 'Passed', 'Failed', 'Skipped')) {
            if ($Expected.ContainsKey($name) -and [int]$Expected[$name] -ne [int]$Structured.$name) {
                $reasons.Add(('Count drift: {0} expected {1}, observed {2}.' -f $name, $Expected[$name], $Structured.$name)); $failed = $true
            }
        }
    }
    if ($Structured.Available -and $null -ne $GateExpectations) {
        foreach ($gate in @($GateExpectations.Keys | Sort-Object)) {
            $observed = $Structured.Gates[$gate]
            if ($null -eq $observed -or [int]$observed -ne [int]$GateExpectations[$gate]) {
                $reasons.Add(('Freeze/read-only gate {0} expected {1}, observed {2}.' -f $gate, $GateExpectations[$gate], $observed)); $failed = $true
            }
        }
    }
    if ($failed) { $status = 'FAIL' }
    elseif (-not $Structured.Available) { $status = 'UNVERIFIED' }
    elseif ($Structured.Skipped -gt 0 -or $LineCounts.Skip -gt 0) { $status = 'PASS_WITH_SKIPS'; $reasons.Add(('{0} check(s) skipped by the harness; skipped checks are not counted as passed.' -f [math]::Max($Structured.Skipped, $LineCounts.Skip))) }
    else { $status = 'PASS' }
    return [pscustomobject][ordered]@{ Status = $status; Reasons = [string[]]$reasons.ToArray() }
}

# ---------------------------------------------------------------------------
# Verdicts
# ---------------------------------------------------------------------------

$script:StatusRank = @{ 'FAIL' = 0; 'INCOMPLETE' = 1; 'NOT_RUN' = 1; 'BLOCKED' = 2; 'UNVERIFIED' = 3; 'EXECUTED_UNVERIFIED' = 3; 'SKIP' = 4; 'PASS_WITH_SKIPS' = 4; 'PASS' = 5; 'VERIFIED' = 5 }

function Get-eMASOverallVerdict {
    param([Parameter(Mandatory = $true)][string] $Mode, [object[]] $Stages = @(), [bool] $Completed = $true)
    $statuses = @($Stages | ForEach-Object { [string]$_.Status })
    if (-not $Completed -or $statuses -contains 'NOT_RUN' -or $statuses -contains 'RUNNING') {
        return [pscustomobject]@{ Status = 'INCOMPLETE'; Reason = 'The run did not complete; results cover only the stages that finished. This is not a PASS.' }
    }
    if ($statuses -contains 'FAIL') { return [pscustomobject]@{ Status = 'FAIL'; Reason = ('{0} stage(s) failed.' -f @($statuses | Where-Object { $_ -eq 'FAIL' }).Count) } }
    if ($Mode -eq 'MS04Demo') {
        $identification = @($Stages | Where-Object { $_.Id -eq 'DEMO-IDENTIFICATION' }) | Select-Object -First 1
        $verification = @($Stages | Where-Object { $_.Id -eq 'DEMO-VERIFICATION' }) | Select-Object -First 1
        if ($null -eq $identification -or $identification.Status -ne 'EXECUTED_UNVERIFIED') {
            return [pscustomobject]@{ Status = 'BLOCKED'; Reason = 'Identification did not run (see blocked stages). An end-to-end demo PASS is not possible.' }
        }
        if ($null -ne $verification -and $verification.Status -eq 'VERIFIED') {
            return [pscustomobject]@{ Status = 'VERIFIED'; Reason = 'The observed Identification/1.0 document matched the supplied independent expected document under the documented comparison profile. This is not a regulatory compliance claim.' }
        }
        return [pscustomobject]@{ Status = 'EXECUTED_UNVERIFIED'; Reason = 'The real Pre-Sales script executed and produced Identification/1.0 output, but no independent expected-outcome document verified it.' }
    }
    if ($statuses -contains 'BLOCKED') { return [pscustomobject]@{ Status = 'BLOCKED'; Reason = 'One or more stages could not run because a supplied prerequisite was invalid.' } }
    if ($statuses -contains 'UNVERIFIED') { return [pscustomobject]@{ Status = 'UNVERIFIED'; Reason = 'At least one harness exited without a readable structured result.' } }
    if ($statuses -contains 'SKIP' -or $statuses -contains 'PASS_WITH_SKIPS') {
        $skipStages = @($statuses | Where-Object { $_ -eq 'SKIP' }).Count
        $partialStages = @($statuses | Where-Object { $_ -eq 'PASS_WITH_SKIPS' }).Count
        return [pscustomobject]@{ Status = 'PASS_WITH_SKIPS'; Reason = ('All executed checks passed, but coverage is incomplete: {0} stage(s) skipped and {1} stage(s) passed with skipped checks. This is not an unqualified PASS.' -f $skipStages, $partialStages) }
    }
    return [pscustomobject]@{ Status = 'PASS'; Reason = 'Every stage in this mode ran and passed with the expected counts.' }
}

function Get-eMASExitCode {
    param([Parameter(Mandatory = $true)][string] $Status)
    switch ($Status) {
        'PASS' { return 0 } 'VERIFIED' { return 0 } 'FAIL' { return 1 } 'PASS_WITH_SKIPS' { return 2 }
        'EXECUTED_UNVERIFIED' { return 3 } 'UNVERIFIED' { return 3 } 'BLOCKED' { return 4 } 'INCOMPLETE' { return 5 }
        default { return 1 }
    }
}

function Get-eMASCoverage {
    param([object[]] $Stages = @())
    $byStatus = [ordered]@{}
    foreach ($name in @('PASS', 'VERIFIED', 'PASS_WITH_SKIPS', 'EXECUTED_UNVERIFIED', 'UNVERIFIED', 'SKIP', 'BLOCKED', 'FAIL', 'NOT_RUN')) {
        $byStatus[$name] = @($Stages | Where-Object { $_.Status -eq $name }).Count
    }
    $harness = @($Stages | Where-Object { $_.Kind -eq 'Harness' -and $null -ne $_.Counts -and $_.Counts.Available })
    return [pscustomobject][ordered]@{
        StageCount = @($Stages).Count
        StagesByStatus = [pscustomobject]$byStatus
        HarnessStagesExecuted = @($Stages | Where-Object { $_.Kind -eq 'Harness' -and $null -ne $_.ExitCode }).Count
        HarnessStagesSkipped = @($Stages | Where-Object { $_.Kind -eq 'Harness' -and $_.Status -eq 'SKIP' }).Count
        HarnessChecksTotal = [int](($harness | ForEach-Object { [int]$_.Counts.Total } | Measure-Object -Sum).Sum)
        HarnessChecksPassed = [int](($harness | ForEach-Object { [int]$_.Counts.Passed } | Measure-Object -Sum).Sum)
        HarnessChecksFailed = [int](($harness | ForEach-Object { [int]$_.Counts.Failed } | Measure-Object -Sum).Sum)
        HarnessChecksSkipped = [int](($harness | ForEach-Object { [int]$_.Counts.Skipped } | Measure-Object -Sum).Sum)
    }
}

# ---------------------------------------------------------------------------
# Identification comparison (demo verification)
# ---------------------------------------------------------------------------

function ConvertTo-eMASCanonicalValue {
    # Objects get ordinal-sorted properties; array order is significant.
    param([AllowNull()][object] $Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $ordered = [ordered]@{}
        $names = [string[]]@($Value.PSObject.Properties.Name)
        [System.Array]::Sort($names, [System.StringComparer]::Ordinal)
        foreach ($name in $names) {
            $ordered[$name] = ConvertTo-eMASCanonicalValue -Value $Value.$name
        }
        return [pscustomobject]$ordered
    }
    if ($Value -is [System.Collections.IList] -and $Value -isnot [string]) {
        return , [object[]]@($Value | ForEach-Object { ConvertTo-eMASCanonicalValue -Value $_ })
    }
    return $Value
}

function Remove-eMASDottedField {
    param([Parameter(Mandatory = $true)][object] $Document, [Parameter(Mandatory = $true)][string] $DottedPath)
    $parts = $DottedPath.Split('.')
    $node = $Document
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        if ($null -eq $node -or $null -eq $node.PSObject.Properties[$parts[$i]]) { return }
        $node = $node.($parts[$i])
    }
    if ($null -ne $node -and $null -ne $node.PSObject.Properties[$parts[-1]]) { $node.PSObject.Properties.Remove($parts[-1]) }
}

function Find-eMASJsonDifferences {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Observed, [string] $Path = '$', [System.Collections.Generic.List[string]] $Output, [int] $Limit = 20)
    if ($Output.Count -ge $Limit) { return }
    if ($Expected -is [System.Management.Automation.PSCustomObject] -and $Observed -is [System.Management.Automation.PSCustomObject]) {
        $names = @(@($Expected.PSObject.Properties.Name) + @($Observed.PSObject.Properties.Name) | Sort-Object -Unique)
        foreach ($name in $names) {
            $e = $Expected.PSObject.Properties[$name]; $o = $Observed.PSObject.Properties[$name]
            if ($null -eq $e) { $Output.Add(('{0}.{1}: unexpected property in observed output' -f $Path, $name)) }
            elseif ($null -eq $o) { $Output.Add(('{0}.{1}: missing from observed output' -f $Path, $name)) }
            else { Find-eMASJsonDifferences -Expected $e.Value -Observed $o.Value -Path ('{0}.{1}' -f $Path, $name) -Output $Output -Limit $Limit }
            if ($Output.Count -ge $Limit) { return }
        }
        return
    }
    $expectedIsList = $Expected -is [System.Collections.IList] -and $Expected -isnot [string]
    $observedIsList = $Observed -is [System.Collections.IList] -and $Observed -isnot [string]
    if ($expectedIsList -and $observedIsList) {
        if ($Expected.Count -ne $Observed.Count) { $Output.Add(('{0}: array length expected {1}, observed {2}' -f $Path, $Expected.Count, $Observed.Count)) }
        for ($i = 0; $i -lt [math]::Min($Expected.Count, $Observed.Count); $i++) {
            Find-eMASJsonDifferences -Expected $Expected[$i] -Observed $Observed[$i] -Path ('{0}[{1}]' -f $Path, $i) -Output $Output -Limit $Limit
            if ($Output.Count -ge $Limit) { return }
        }
        return
    }
    $left = ConvertTo-Json -InputObject $Expected -Depth 64 -Compress
    $right = ConvertTo-Json -InputObject $Observed -Depth 64 -Compress
    if ($left -ne $right) { $Output.Add(('{0}: value differs' -f $Path)) }
}

function Compare-eMASIdentificationDocument {
    # Semantic equality after removing the documented volatile fields.
    param(
        [Parameter(Mandatory = $true)][string] $ObservedPath,
        [Parameter(Mandatory = $true)][string] $ExpectedPath,
        [Parameter(Mandatory = $true)][string[]] $VolatileFields
    )
    $observed = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($ObservedPath))
    $expected = ConvertFrom-eMASJsonText -Text ([System.IO.File]::ReadAllText($ExpectedPath))
    foreach ($document in @($observed, $expected)) { foreach ($field in $VolatileFields) { Remove-eMASDottedField -Document $document -DottedPath $field } }
    $observedCanonical = ConvertTo-eMASCanonicalValue -Value $observed
    $expectedCanonical = ConvertTo-eMASCanonicalValue -Value $expected
    $equal = (ConvertTo-Json -InputObject $observedCanonical -Depth 100 -Compress) -ceq (ConvertTo-Json -InputObject $expectedCanonical -Depth 100 -Compress)
    $differences = New-Object System.Collections.Generic.List[string]
    if (-not $equal) { Find-eMASJsonDifferences -Expected $expectedCanonical -Observed $observedCanonical -Output $differences }
    return [pscustomobject][ordered]@{ Equal = $equal; Differences = [string[]]$differences.ToArray() }
}

# ---------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------

function Write-eMASJsonFile {
    # Write to a temporary sibling, then rename, so a killed run never leaves half a manifest.
    param([Parameter(Mandatory = $true)][object] $Value, [Parameter(Mandatory = $true)][string] $Path)
    $temporary = $Path + '.tmp'
    [System.IO.File]::WriteAllText($temporary, (ConvertTo-Json -InputObject $Value -Depth 32), $script:Utf8NoBom)
    [System.IO.File]::Move($temporary, $Path, $true)
}

function Write-eMASTextFile {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Text, [Parameter(Mandatory = $true)][string] $Path)
    $temporary = $Path + '.tmp'
    [System.IO.File]::WriteAllText($temporary, $Text, $script:Utf8NoBom)
    [System.IO.File]::Move($temporary, $Path, $true)
}

Export-ModuleMember -Function @(
    'ConvertFrom-eMASJsonText',
    'Test-eMASPathHasTraversal', 'Get-eMASRealPath', 'Test-eMASPathWithin', 'Resolve-eMASOutputRoot', 'New-eMASRunDirectory', 'New-eMASRunId',
    'Get-eMASFileSha256', 'Get-eMASTextSha256', 'Get-eMASTreeDigest', 'Get-eMASInputDigest', 'Test-eMASCommittedManifest',
    'Get-eMASGitState', 'Get-eMASPlatformInfo', 'Get-eMASPwshPath',
    'Format-eMASCommandLine', 'Invoke-eMASChildProcess',
    'Get-eMASLineCounts', 'Remove-eMASAnsiEscape', 'Get-eMASDiagnosticLines', 'Get-eMASStructuredCounts', 'Get-eMASHarnessStatus',
    'Get-eMASOverallVerdict', 'Get-eMASExitCode', 'Get-eMASCoverage',
    'Compare-eMASIdentificationDocument', 'Write-eMASJsonFile', 'Write-eMASTextFile'
)
