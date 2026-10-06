#requires -Version 5.1

[CmdletBinding()]
param(
    [string] $OracleRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
if ([string]::IsNullOrWhiteSpace($OracleRoot)) {
    $OracleRoot = Join-Path $repositoryRoot 'tests/identification-interpretation/oracle'
}
$OracleRoot = [System.IO.Path]::GetFullPath($OracleRoot)
if (-not [System.IO.Directory]::Exists($OracleRoot)) {
    throw ('T4a oracle is not present at {0}.' -f $OracleRoot)
}

Import-Module (Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1') -Force -ErrorAction Stop
Import-Module (Join-Path $repositoryRoot 'engine/core/eMAS.RuntimeConfiguration.psm1') -Force -ErrorAction Stop

function ConvertTo-eMASOracleComparisonJson {
    param([Parameter(Mandatory = $true)][object] $Document)
    foreach ($name in @('EngineVersion', 'StartedAtUtc', 'CompletedAtUtc')) {
        if ($null -ne $Document.Execution.PSObject.Properties[$name]) { $Document.Execution.PSObject.Properties.Remove($name) }
    }
    return ($Document | ConvertTo-Json -Depth 64 -Compress)
}

$manifest = [System.IO.File]::ReadAllText((Join-Path $OracleRoot 'manifest.json')) | ConvertFrom-Json
$passed = 0
$failed = 0
$outputCases = 0
$failureCases = 0
$scratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-ido-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($scratchRoot)
foreach ($case in @($manifest.cases)) {
    $caseRoot = Join-Path $OracleRoot ([string]$case.path)
    $scannerPath = Join-Path $caseRoot 'scanner-observations.json'
    $configPath = Join-Path $caseRoot 'runtime-config.json'
    $expectedPath = Join-Path $caseRoot 'expected-identification.json'
    $failurePath = Join-Path $caseRoot 'expected-failure.json'
    $expectation = [string]$case.expectation
    if ($expectation -eq 'Failure') { $failureCases++ } else { $outputCases++ }
    try {
        $scannerBytesBefore = [System.IO.File]::ReadAllBytes($scannerPath)
        $configBytesBefore = [System.IO.File]::ReadAllBytes($configPath)
        $scannerFileHashBefore = (Get-FileHash -LiteralPath $scannerPath -Algorithm SHA256).Hash
        $configFileHashBefore = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash
        $scanner = (New-Object System.Text.UTF8Encoding($false, $true)).GetString($scannerBytesBefore) | ConvertFrom-Json
        $scannerObjectBefore = $scanner | ConvertTo-Json -Depth 64 -Compress
        $configuration = Import-eMASRuntimeConfiguration -Path $configPath
        $configurationObjectBefore = $configuration.Raw | ConvertTo-Json -Depth 64 -Compress
        $scannerHash = (Get-FileHash -LiteralPath $scannerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($expectation -eq 'Failure') {
            # Contract I2: configuration validation fails before rule evaluation and writes no Identification document.
            $failure = ([System.IO.File]::ReadAllText($failurePath) | ConvertFrom-Json).ExpectedFailure
            $outputPath = Join-Path $scratchRoot ('{0}-identification.json' -f $case.id)
            $message = $null
            try { [void](Invoke-eMASIdentificationInterpretation -InputResult $scanner -RuntimeConfiguration $configuration -EvidenceSourceSha256 $scannerHash -OutputPath $outputPath) }
            catch { $message = $_.Exception.Message }
            if ($null -eq $message) { throw ('Expected {0} but the engine completed.' -f $failure.ErrorCode) }
            if (-not $message.StartsWith([string]$failure.ErrorCode + ' ', [System.StringComparison]::Ordinal)) { throw ('Expected {0}, got: {1}' -f $failure.ErrorCode, $message) }
            if (-not $message.Contains([string]$failure.RuleId) -or -not $message.Contains([string]$failure.ConditionId)) { throw ('Failure message does not name rule {0} and condition {1}: {2}' -f $failure.RuleId, $failure.ConditionId, $message) }
            if ($null -ne $failure.OutputDocument -or [System.IO.File]::Exists($outputPath) -or @([System.IO.Directory]::GetFiles($scratchRoot)).Count -gt 0) { throw 'A failed run wrote an Identification document.' }
        }
        else {
            $actual = Invoke-eMASIdentificationInterpretation -InputResult $scanner -RuntimeConfiguration $configuration -EvidenceSourceSha256 $scannerHash
            $expected = [System.IO.File]::ReadAllText($expectedPath) | ConvertFrom-Json

            $actualJson = ConvertTo-eMASOracleComparisonJson $actual
            $expectedJson = ConvertTo-eMASOracleComparisonJson $expected
            if ($actualJson -ne $expectedJson) { throw 'Semantic output differs from the independent expected document.' }
        }
        if ($scannerObjectBefore -ne ($scanner | ConvertTo-Json -Depth 64 -Compress)) { throw 'Scanner input object was mutated.' }
        if ($configurationObjectBefore -ne ($configuration.Raw | ConvertTo-Json -Depth 64 -Compress)) { throw 'Runtime configuration object was mutated.' }
        if ($scannerFileHashBefore -ne (Get-FileHash -LiteralPath $scannerPath -Algorithm SHA256).Hash) { throw 'Scanner fixture bytes changed.' }
        if ($configFileHashBefore -ne (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash) { throw 'Runtime fixture bytes changed.' }
        $passed++
        Write-Output ('[PASS] {0}' -f $case.id)
    }
    catch {
        $failed++
        Write-Output ('[FAIL] {0}: {1}' -f $case.id, $_.Exception.Message)
    }
}

if ([System.IO.Directory]::Exists($scratchRoot)) { [System.IO.Directory]::Delete($scratchRoot, $true) }
Write-Output ('IdentificationInterpretation oracle conformance: {0} cases ({1} output, {2} expected-failure), {3} passed, {4} failed.' -f ($passed + $failed), $outputCases, $failureCases, $passed, $failed)
if ($failed -gt 0) { exit 1 }
