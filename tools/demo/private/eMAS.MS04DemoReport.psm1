#requires -Version 7.0
# MS-04 demo runner: standalone HTML summary serialization.
# Every value from the manifest (paths, diagnostics, harness and XML-derived
# text) is HTML-encoded. The page has no scripts, fonts, CDNs or remote assets.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function ConvertTo-eMASHtmlText {
    param([AllowNull()][object] $Value)
    if ($null -eq $Value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function ConvertTo-eMASHtmlHref {
    # Relative artifact link: each segment percent-encoded, then attribute-encoded.
    param([AllowNull()][string] $RelativePath)
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return '' }
    $segments = $RelativePath.Replace('\', '/').Split('/') | ForEach-Object { [System.Uri]::EscapeDataString($_) }
    return ConvertTo-eMASHtmlText -Value ($segments -join '/')
}

function Get-eMASStatusClass {
    param([AllowNull()][string] $Status)
    switch ($Status) {
        'PASS' { return 'ok' } 'VERIFIED' { return 'ok' }
        'PASS_WITH_SKIPS' { return 'warn' } 'SKIP' { return 'warn' } 'EXECUTED_UNVERIFIED' { return 'warn' } 'UNVERIFIED' { return 'warn' }
        'FAIL' { return 'bad' } 'BLOCKED' { return 'bad' } 'INCOMPLETE' { return 'bad' }
        default { return 'neutral' }
    }
}

function Get-eMASStatusLabel {
    param([AllowNull()][string] $Status)
    switch ($Status) {
        'PASS' { return 'PASS' } 'VERIFIED' { return 'VERIFIED' }
        'PASS_WITH_SKIPS' { return 'PASS WITH SKIPS' } 'SKIP' { return 'SKIP' }
        'EXECUTED_UNVERIFIED' { return 'EXECUTED, UNVERIFIED' } 'UNVERIFIED' { return 'UNVERIFIED' }
        'FAIL' { return 'FAIL' } 'BLOCKED' { return 'BLOCKED' } 'INCOMPLETE' { return 'INCOMPLETE' }
        'NOT_RUN' { return 'NOT RUN' } 'RUNNING' { return 'RUNNING' }
        default { return [string]$Status }
    }
}

function New-eMASStatusBadge {
    param([AllowNull()][string] $Status)
    $symbol = switch (Get-eMASStatusClass -Status $Status) { 'ok' { '✓' } 'warn' { '!' } 'bad' { '✕' } default { '·' } }
    return ('<span class="badge {0}"><span aria-hidden="true">{1}</span> {2}</span>' -f (Get-eMASStatusClass -Status $Status), $symbol, (ConvertTo-eMASHtmlText (Get-eMASStatusLabel -Status $Status)))
}

function New-eMASKeyValueRows {
    param([AllowNull()][object] $Object, [string[]] $Exclude = @())
    if ($null -eq $Object) { return '' }
    $builder = New-Object System.Text.StringBuilder
    $properties = if ($Object -is [System.Collections.IDictionary]) { @($Object.Keys | ForEach-Object { [pscustomobject]@{ Name = $_; Value = $Object[$_] } }) } else { @($Object.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } }) }
    foreach ($property in $properties) {
        if ($Exclude -contains $property.Name) { continue }
        $value = $property.Value
        if ($null -ne $value -and ($value -is [System.Collections.IEnumerable]) -and $value -isnot [string]) { $value = ConvertTo-Json -InputObject $value -Depth 8 -Compress }
        elseif ($null -ne $value -and $value -is [System.Management.Automation.PSCustomObject]) { $value = ConvertTo-Json -InputObject $value -Depth 8 -Compress }
        [void]$builder.AppendFormat('<tr><th scope="row">{0}</th><td class="val">{1}</td></tr>', (ConvertTo-eMASHtmlText $property.Name), (ConvertTo-eMASHtmlText $value))
    }
    return $builder.ToString()
}

function Get-eMASCountsText {
    param([AllowNull()][object] $Counts)
    if ($null -eq $Counts -or -not $Counts.Available) { return '—' }
    $text = '{0}/{1} passed' -f $Counts.Passed, $Counts.Total
    if ([int]$Counts.Skipped -gt 0) { $text += (', {0} skipped' -f $Counts.Skipped) }
    if ([int]$Counts.Failed -gt 0) { $text += (', {0} failed' -f $Counts.Failed) }
    return $text
}

function Get-eMASReportStyle {
    return @'
:root{--bg:#ffffff;--fg:#1d2330;--muted:#5a6475;--line:#d8dde6;--panel:#f5f7fa;--code:#eef1f5;
--ok-bg:#e3f4e8;--ok-fg:#165c2c;--warn-bg:#fff2d6;--warn-fg:#7a4b00;--bad-bg:#fde4e2;--bad-fg:#8f1d16;--neutral-bg:#eceff3;--neutral-fg:#3d4655;--link:#0b57b0}
@media (prefers-color-scheme: dark){:root{--bg:#14171c;--fg:#e6e9ef;--muted:#a3abb9;--line:#323844;--panel:#1b1f26;--code:#232833;
--ok-bg:#183a24;--ok-fg:#9fe0b2;--warn-bg:#3d2e0e;--warn-fg:#f4cf7c;--bad-bg:#46201d;--bad-fg:#ffb4ab;--neutral-bg:#2a2f39;--neutral-fg:#c9cfdb;--link:#8ab8ff}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
main{max-width:1180px;margin:0 auto;padding:24px 16px 48px}
h1{font-size:1.6rem;margin:0 0 4px}h2{font-size:1.2rem;margin:32px 0 10px;border-bottom:1px solid var(--line);padding-bottom:4px}
h3{font-size:1rem;margin:0}
p.sub{color:var(--muted);margin:0 0 16px}
a{color:var(--link)}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:.86rem}
pre{background:var(--code);padding:10px;border-radius:6px;white-space:pre-wrap;word-break:break-all;margin:6px 0}
.verdict{border-radius:10px;padding:16px 18px;margin:16px 0;border:1px solid var(--line)}
.verdict.ok{background:var(--ok-bg);color:var(--ok-fg)}.verdict.warn{background:var(--warn-bg);color:var(--warn-fg)}
.verdict.bad{background:var(--bad-bg);color:var(--bad-fg)}.verdict.neutral{background:var(--neutral-bg);color:var(--neutral-fg)}
.verdict .big{font-size:1.35rem;font-weight:700;display:block}
.badge{display:inline-block;border-radius:999px;padding:1px 10px;font-weight:600;font-size:.8rem;white-space:nowrap}
.badge.ok{background:var(--ok-bg);color:var(--ok-fg)}.badge.warn{background:var(--warn-bg);color:var(--warn-fg)}
.badge.bad{background:var(--bad-bg);color:var(--bad-fg)}.badge.neutral{background:var(--neutral-bg);color:var(--neutral-fg)}
.scroll{overflow-x:auto}
table{border-collapse:collapse;width:100%;margin:6px 0}
th,td{text-align:left;vertical-align:top;padding:6px 8px;border-bottom:1px solid var(--line)}
thead th{background:var(--panel);font-size:.85rem}
th[scope=row]{width:30%;color:var(--muted);font-weight:600}
td.num{text-align:right;font-variant-numeric:tabular-nums}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:10px}
.card .n{font-size:1.4rem;font-weight:700;display:block}
details{border:1px solid var(--line);border-radius:8px;margin:8px 0;background:var(--panel)}
summary{cursor:pointer;padding:10px 12px;display:flex;gap:10px;align-items:center;flex-wrap:wrap}
details>div{padding:0 12px 12px}
ul.reasons{margin:6px 0;padding-left:20px}
.banner{border-left:4px solid var(--warn-fg);background:var(--warn-bg);color:var(--warn-fg);padding:8px 12px;border-radius:4px;margin:8px 0}
td{overflow-wrap:break-word}
td.path,td.val,.banner,.verdict{overflow-wrap:anywhere}
td.path{min-width:18ch}
@media print{details{break-inside:avoid}details>div{display:block}}
'@
}

function New-eMASRunSummaryHtml {
    param([Parameter(Mandatory = $true)][object] $Manifest)
    $h = { param($v) ConvertTo-eMASHtmlText $v }
    $run = $Manifest.Run
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">')
    [void]$sb.Append('<meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src ''none''; base-uri ''none''; form-action ''none''">')
    [void]$sb.AppendFormat('<title>eMAS MS-04 {0} — {1}</title>', (& $h $run.Mode), (& $h (Get-eMASStatusLabel $run.OverallStatus)))
    [void]$sb.AppendFormat('<style>{0}</style></head><body><main>', (Get-eMASReportStyle))
    [void]$sb.AppendFormat('<h1>eMAS MS-04 Pre-Sales — {0}</h1>', (& $h $run.Mode))
    [void]$sb.AppendFormat('<p class="sub">Run <code>{0}</code> · runner {1} · state {2}</p>', (& $h $run.RunId), (& $h $Manifest.Runner.Version), (& $h $run.State))

    $class = Get-eMASStatusClass -Status $run.OverallStatus
    [void]$sb.AppendFormat('<section class="verdict {0}" role="status" aria-label="Overall result"><span class="big">Overall: {1}</span>{2}</section>', $class, (& $h (Get-eMASStatusLabel $run.OverallStatus)), (& $h $run.OverallReason))
    if ($run.State -ne 'Completed') { [void]$sb.Append('<p class="banner">This run has not completed. Stages marked NOT RUN or RUNNING did not finish and are not counted as passed.</p>') }
    if ($null -ne $run.PSObject.Properties['RunnerError']) { [void]$sb.AppendFormat('<p class="banner">Runner internal error: {0}</p>', (& $h $run.RunnerError)) }
    if ($null -ne $Manifest.Repository -and $Manifest.Repository.WorktreeClean -eq $false) { [void]$sb.AppendFormat('<p class="banner">The repository worktree had {0} uncommitted or untracked entr(ies) at start; results are not attributable to commit {1} alone.</p>', (& $h $Manifest.Repository.StatusEntryCount), (& $h $Manifest.Repository.HeadSha)) }

    # Overview
    [void]$sb.Append('<h2>Run overview</h2><div class="scroll"><table><tbody>')
    $overview = [ordered]@{
        'Mode' = $run.Mode; 'Started (UTC)' = $run.StartedAtUtc; 'Completed (UTC)' = $run.CompletedAtUtc; 'Elapsed seconds' = $run.ElapsedSeconds
        'Runner exit code' = $(if ($null -ne $run.PSObject.Properties['StrictExitCode'] -and $null -ne $run.StrictExitCode -and $run.StrictExitCode -ne $run.ExitCode) { '{0} (policy {1}: completed without a failure; strict code {2})' -f $run.ExitCode, $run.ExitCodePolicy, $run.StrictExitCode } else { $run.ExitCode }); 'Git commit' = $Manifest.Repository.HeadSha; 'Git branch' = $Manifest.Repository.Branch
        'Worktree clean at start' = $Manifest.Repository.WorktreeClean; 'Repository root' = $Manifest.Repository.Root
        'Run directory' = $Manifest.Outputs.RunDirectory
    }
    [void]$sb.Append((New-eMASKeyValueRows -Object $overview))
    [void]$sb.Append('</tbody></table></div>')

    # Coverage
    $coverage = $Manifest.Coverage
    [void]$sb.Append('<h2>Coverage</h2><div class="cards">')
    $cards = @(, @('Stages', $coverage.StageCount))
    if ($run.Mode -ne 'MS04Demo') {
        $cards += @(@('Harness stages executed', $coverage.HarnessStagesExecuted), @('Harness stages skipped', $coverage.HarnessStagesSkipped),
            @('Checks passed', ('{0} / {1}' -f $coverage.HarnessChecksPassed, $coverage.HarnessChecksTotal)), @('Checks skipped', $coverage.HarnessChecksSkipped), @('Checks failed', $coverage.HarnessChecksFailed))
    }
    foreach ($item in $cards) {
        [void]$sb.AppendFormat('<div class="card"><span class="n">{0}</span>{1}</div>', (& $h $item[1]), (& $h $item[0]))
    }
    [void]$sb.Append('</div><div class="scroll"><table><thead><tr>')
    foreach ($name in @($coverage.StagesByStatus.PSObject.Properties.Name)) { [void]$sb.AppendFormat('<th scope="col">{0}</th>', (New-eMASStatusBadge $name)) }
    [void]$sb.Append('</tr></thead><tbody><tr>')
    foreach ($name in @($coverage.StagesByStatus.PSObject.Properties.Name)) { [void]$sb.AppendFormat('<td class="num">{0}</td>', (& $h $coverage.StagesByStatus.$name)) }
    [void]$sb.Append('</tr></tbody></table></div>')
    [void]$sb.Append('<p class="sub">Check counts come from each harness''s own structured summary or result line. Skipped checks are never counted as passed. A process exit code of 0 alone is not treated as a pass.</p>')

    # Stage table
    [void]$sb.Append('<h2>Stages</h2><div class="scroll"><table><thead><tr><th scope="col">#</th><th scope="col">Stage</th><th scope="col">Group</th><th scope="col">Status</th><th scope="col">Checks</th><th scope="col">Exit</th><th scope="col">Seconds</th></tr></thead><tbody>')
    foreach ($stage in @($Manifest.Stages)) {
        [void]$sb.AppendFormat('<tr><td class="num">{0}</td><td><a href="#stage-{1}">{2}</a><br><code>{3}</code></td><td>{4}</td><td>{5}</td><td>{6}</td><td class="num">{7}</td><td class="num">{8}</td></tr>',
            (& $h $stage.Order), (& $h $stage.Id), (& $h $stage.Name), (& $h $stage.Id), (& $h $stage.GateGroup), (New-eMASStatusBadge $stage.Status), (& $h (Get-eMASCountsText $stage.Counts)), (& $h $stage.ExitCode), (& $h $stage.DurationSeconds))
    }
    [void]$sb.Append('</tbody></table></div>')

    # Stage details
    [void]$sb.Append('<h2>Stage details</h2>')
    foreach ($stage in @($Manifest.Stages)) {
        $open = if ((Get-eMASStatusClass $stage.Status) -ne 'ok') { ' open' } else { '' }
        [void]$sb.AppendFormat('<details id="stage-{0}"{1}><summary>{2}<h3>{3}</h3><code>{4}</code></summary><div>', (& $h $stage.Id), $open, (New-eMASStatusBadge $stage.Status), (& $h $stage.Name), (& $h $stage.Id))
        $reasonList = @($stage.Reasons | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($reasonList.Count -gt 0) {
            [void]$sb.Append('<ul class="reasons">')
            foreach ($reason in $reasonList) { [void]$sb.AppendFormat('<li>{0}</li>', (& $h $reason)) }
            [void]$sb.Append('</ul>')
        }
        $facts = [ordered]@{ Kind = $stage.Kind; 'Exit code' = $stage.ExitCode; 'Timed out' = $stage.TimedOut; 'Started (UTC)' = $stage.StartedAtUtc; 'Duration seconds' = $stage.DurationSeconds }
        if ($null -ne $stage.Counts) { $facts['Structured counts'] = (Get-eMASCountsText $stage.Counts); $facts['Count source'] = $stage.Counts.Source; $facts['Harness reported status'] = $stage.Counts.ReportedStatus; if ($null -ne $stage.Counts.Gates -and @($stage.Counts.Gates.PSObject.Properties).Count -gt 0) { $facts['Read-only gates observed'] = $stage.Counts.Gates } }
        if ($null -ne $stage.Expected) { $facts['Expected counts'] = $stage.Expected; $facts['Expectation profile'] = $stage.ExpectedProfile }
        if ($null -ne $stage.LineCounts) { $facts['[PASS]/[FAIL]/[SKIP] lines'] = ('{0} / {1} / {2}' -f $stage.LineCounts.Pass, $stage.LineCounts.Fail, $stage.LineCounts.Skip) }
        [void]$sb.Append('<div class="scroll"><table><tbody>')
        [void]$sb.Append((New-eMASKeyValueRows -Object $facts))
        if ($null -ne $stage.Details) { [void]$sb.Append((New-eMASKeyValueRows -Object $stage.Details -Exclude @('ResultRows'))) }
        [void]$sb.Append('</tbody></table></div>')
        if ($null -ne $stage.Command) { [void]$sb.AppendFormat('<p><strong>Command</strong> (run directly, without a shell; working directory <code class="path">{0}</code>)</p><pre>{1}</pre>', (& $h $stage.WorkingDirectory), (& $h $stage.Command.Display)) }
        $diagnostics = @($stage.Diagnostics | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($diagnostics.Count -gt 0) { [void]$sb.AppendFormat('<p><strong>Diagnostics</strong> (failed/skipped lines, last result line, stderr tail)</p><pre>{0}</pre>', (& $h ($diagnostics -join "`n"))) }
        if ($null -ne $stage.Artifacts) {
            $links = @($stage.Artifacts.PSObject.Properties | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Value) })
            if ($links.Count -gt 0) {
                [void]$sb.Append('<p><strong>Artifacts</strong>: ')
                [void]$sb.Append((($links | ForEach-Object { '<a href="{0}">{1}</a>' -f (ConvertTo-eMASHtmlHref $_.Value), (& $h $_.Name) }) -join ' · '))
                [void]$sb.Append('</p>')
            }
        }
        [void]$sb.Append('</div></details>')
    }

    # Identification results (demo only, as emitted by the engine)
    $identificationStage = @($Manifest.Stages | Where-Object { $_.Id -eq 'DEMO-IDENTIFICATION' -and $null -ne $_.Details -and $null -ne $_.Details.PSObject.Properties['ResultRows'] }) | Select-Object -First 1
    if ($null -ne $identificationStage) {
        [void]$sb.Append('<h2>Identification results (as emitted)</h2>')
        [void]$sb.Append('<p class="sub">Shown exactly as produced by the IdentificationInterpretation engine from the supplied Runtime JSON. They are not verified unless the verification stage reports VERIFIED, and they are not a regulatory compliance statement.</p>')
        [void]$sb.Append('<div class="scroll"><table><thead><tr><th scope="col">Subject</th><th scope="col">Dimension</th><th scope="col">Evaluation status</th><th scope="col">Value</th><th scope="col">Confidence</th><th scope="col">Review required</th></tr></thead><tbody>')
        foreach ($row in @($identificationStage.Details.ResultRows)) {
            [void]$sb.AppendFormat('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>', (& $h $row.Subject), (& $h $row.Dimension), (& $h $row.EvaluationStatus), (& $h $row.Value), (& $h $row.Confidence), (& $h $row.ReviewRequired))
        }
        [void]$sb.Append('</tbody></table></div>')
    }

    # Inputs
    [void]$sb.Append('<h2>Inputs and provenance</h2><div class="scroll"><table><thead><tr><th scope="col">Role</th><th scope="col">Path</th><th scope="col">Origin</th><th scope="col">Kind</th><th scope="col">SHA-256 before</th><th scope="col">Unchanged after run</th></tr></thead><tbody>')
    foreach ($inputRow in @($Manifest.Inputs)) {
        [void]$sb.AppendFormat('<tr><td>{0}</td><td class="path"><code>{1}</code></td><td>{2}</td><td>{3}</td><td class="path"><code>{4}</code></td><td>{5}</td></tr>', (& $h $inputRow.Role), (& $h $inputRow.Path), (& $h $inputRow.Origin), (& $h ('{0} ({1} file(s))' -f $inputRow.Kind, $inputRow.FileCount)), (& $h $inputRow.Sha256), (& $h $inputRow.UnchangedAfterRun))
    }
    [void]$sb.Append('</tbody></table></div>')
    [void]$sb.Append('<div class="scroll"><table><tbody>')
    [void]$sb.Append((New-eMASKeyValueRows -Object ([ordered]@{ 'Runner script SHA-256' = $Manifest.Runner.ScriptSha256; 'Suite catalog version' = $Manifest.Runner.CatalogVersion; 'Suite catalog SHA-256' = $Manifest.Runner.CatalogSha256 })))
    [void]$sb.Append('</tbody></table></div>')

    # Environment
    [void]$sb.Append('<h2>Runtime environment</h2><div class="scroll"><table><tbody>')
    [void]$sb.Append((New-eMASKeyValueRows -Object $Manifest.Platform))
    [void]$sb.Append('</tbody></table></div>')

    # Limitations
    [void]$sb.Append('<h2>Limitations and open items</h2><ul class="reasons">')
    foreach ($limitation in @($Manifest.Limitations)) { [void]$sb.AppendFormat('<li>{0}</li>', (& $h $limitation)) }
    [void]$sb.Append('</ul>')
    [void]$sb.AppendFormat('<p class="sub">Machine-readable record: <a href="{0}">run-manifest.json</a></p>', (ConvertTo-eMASHtmlHref 'run-manifest.json'))
    [void]$sb.Append('</main></body></html>')
    return $sb.ToString()
}

Export-ModuleMember -Function @('ConvertTo-eMASHtmlText', 'ConvertTo-eMASHtmlHref', 'Get-eMASStatusClass', 'New-eMASRunSummaryHtml')
