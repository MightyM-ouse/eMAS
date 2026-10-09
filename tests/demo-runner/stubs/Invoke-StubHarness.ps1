# Synthetic harness used only by Test-eMASMS04DemoRunner.ps1 to exercise the
# runner's process and result handling. It touches no eMAS engine or fixture.
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('NonZeroExit', 'ReportedFailureZeroExit', 'Sleep', 'Skip', 'NoResultLine', 'Pass', 'EchoArguments')]
    [string] $Behavior,
    [string] $OutputPath,
    [int] $Total = 3,
    [Parameter(ValueFromRemainingArguments = $true)][string[]] $Rest
)
switch ($Behavior) {
    'NonZeroExit' {
        Write-Output '[PASS] stub check 1'
        Write-Output 'Stub tests completed: 1 total, 1 passed, 0 failed, 0 skipped.'
        [Console]::Error.WriteLine('stub: simulated crash <after> output & "quotes"')
        exit 3
    }
    'ReportedFailureZeroExit' {
        Write-Output '[PASS] stub check 1'
        Write-Output '[FAIL] stub check 2: simulated assertion failure'
        Write-Output 'Stub tests completed: 2 total, 1 passed, 1 failed, 0 skipped.'
        exit 0
    }
    'Sleep' { Write-Output 'stub: sleeping'; Start-Sleep -Seconds 120; exit 0 }
    'Skip' {
        Write-Output '[PASS] stub check 1'
        Write-Output '[SKIP] stub check 2: external corpus absent'
        Write-Output 'Stub tests completed: 2 total, 1 passed, 0 failed, 1 skipped.'
        exit 0
    }
    'NoResultLine' { Write-Output '[PASS] stub check 1'; exit 0 }
    'Pass' {
        1..$Total | ForEach-Object { Write-Output ('[PASS] stub check {0}' -f $_) }
        Write-Output ('Stub tests completed: {0} total, {0} passed, 0 failed, 0 skipped.' -f $Total)
        exit 0
    }
    'EchoArguments' {
        # The exact argv received by this pwsh process, for no-shell-evaluation checks.
        $json = ConvertTo-Json -InputObject ([string[]][System.Environment]::GetCommandLineArgs()) -Compress
        [System.IO.File]::WriteAllText($OutputPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        exit 0
    }
}
