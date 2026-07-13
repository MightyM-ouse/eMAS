[CmdletBinding()]
param(
    [string]$Workbook,
    [string]$EvidenceDirectory,
    [switch]$BuildFirst
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Workbook)) {
    $Workbook = Join-Path $repoRoot 'dist\internal\poc\eMAS_Mapping_Configuration_POC.xlsm'
}
if ([string]::IsNullOrWhiteSpace($EvidenceDirectory)) {
    $EvidenceDirectory = Join-Path $repoRoot 'output\xlsm-vba-poc-evidence'
}
$Workbook = [System.IO.Path]::GetFullPath($Workbook)
$EvidenceDirectory = [System.IO.Path]::GetFullPath($EvidenceDirectory)

if ($env:OS -ne 'Windows_NT') { throw 'Native XLSM/VBA testing requires Windows and desktop Microsoft Excel.' }
if ($BuildFirst) { & (Join-Path $PSScriptRoot 'Build-eMASMappingPoc.ps1') -OutputWorkbook $Workbook }
if (-not (Test-Path -LiteralPath $Workbook -PathType Leaf)) { throw "XLSM not found: $Workbook" }

New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
$run1 = Join-Path $EvidenceDirectory 'run1'
$run2 = Join-Path $EvidenceDirectory 'run2'
New-Item -ItemType Directory -Path $run1, $run2 -Force | Out-Null

$excel = $null
$book = $null
try {
    Write-Host '[1/6] Starting Excel with macros enabled for the controlled POC test.'
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $false
    $excel.AutomationSecurity = 1

    Write-Host '[2/6] Opening generated XLSM.'
    $book = $excel.Workbooks.Open($Workbook, 0, $false)
    $macroPrefix = "'$($book.Name)'!"

    Write-Host '[3/6] Running VBA validation and deterministic export twice.'
    $validationPassed = [bool]$excel.Run($macroPrefix + 'eMAS_ValidateWorkbookForAutomation')
    if (-not $validationPassed) { throw 'VBA workbook validation reported errors.' }
    $export1 = [string]$excel.Run($macroPrefix + 'eMAS_ExportDevJson', $run1, $true)
    $export2 = [string]$excel.Run($macroPrefix + 'eMAS_ExportDevJson', $run2, $true)
    if ([string]::IsNullOrWhiteSpace($export1) -or [string]::IsNullOrWhiteSpace($export2)) {
        throw 'The VBA exporter did not return both output paths.'
    }
    $excelVersion = [string]$excel.Version
    $book.Close($false)
    $book = $null
    $excel.Quit()
    $excel = $null

    Write-Host '[4/6] Comparing deterministic exports and the approved POC golden hash.'
    $hash1 = (Get-FileHash -LiteralPath $export1 -Algorithm SHA256).Hash.ToLowerInvariant()
    $hash2 = (Get-FileHash -LiteralPath $export2 -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash1 -ne $hash2) { throw "Deterministic VBA exports differ: $hash1 vs $hash2" }
    $manifestPath = Join-Path $repoRoot 'config\authoring\poc\poc-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $expectedHash = [string]$manifest.expectedJsonSha256
    if ($hash1 -ne $expectedHash) { throw "VBA export differs from the approved POC golden hash: $hash1 vs $expectedHash" }

    Write-Host '[5/6] Running independent Runtime JSON Schema 1.0.0 validation.'
    & python (Join-Path $repoRoot 'build\validate_emas_schema.py') --instance $export1
    if ($LASTEXITCODE -ne 0) { throw 'Independent schema/semantic validation failed.' }

    Write-Host '[6/6] Writing manual execution evidence.'
    $evidence = [ordered]@{
        executedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        workbook = $Workbook
        workbookSha256 = (Get-FileHash -LiteralPath $Workbook -Algorithm SHA256).Hash.ToLowerInvariant()
        export1 = $export1
        export2 = $export2
        exportedJsonSha256 = $hash1
        expectedJsonSha256 = $expectedHash
        schemaVersion = '1.0.0'
        deterministicMatch = $true
        schemaValidation = 'Passed'
        environment = [ordered]@{
            os = [Environment]::OSVersion.VersionString
            excelVersion = $excelVersion
            powershellVersion = $PSVersionTable.PSVersion.ToString()
        }
    }
    $evidencePath = Join-Path $EvidenceDirectory 'native-excel-conformance-evidence.json'
    [IO.File]::WriteAllText($evidencePath, ($evidence | ConvertTo-Json -Depth 6) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Native Excel/VBA POC conformance passed. Evidence: $evidencePath"
}
finally {
    if ($null -ne $book) { try { $book.Close($false) } catch {} }
    if ($null -ne $excel) { try { $excel.Quit() } catch {} }
    if ($null -ne $book) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($book) }
    if ($null -ne $excel) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
