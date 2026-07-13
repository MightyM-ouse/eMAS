[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SourceDefinition,
    [string]$GeneratedSourceWorkbook,
    [string]$VbaSourceDirectory,
    [string]$OutputWorkbook
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepositoryPath {
    param([string]$Path, [string]$DefaultRelativePath)
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $candidate = if ([string]::IsNullOrWhiteSpace($Path)) { Join-Path $repoRoot $DefaultRelativePath } else { $Path }
    return [System.IO.Path]::GetFullPath($candidate)
}

if ($env:OS -ne 'Windows_NT') {
    throw 'The XLSM build requires Windows and a supported desktop Microsoft Excel installation.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$SourceDefinition = Resolve-RepositoryPath $SourceDefinition 'config\authoring\poc\workbook-source.json'
$GeneratedSourceWorkbook = Resolve-RepositoryPath $GeneratedSourceWorkbook 'output\poc\eMAS_Mapping_Configuration_POC_Source.xlsx'
$VbaSourceDirectory = Resolve-RepositoryPath $VbaSourceDirectory 'config\vba\modules'
$OutputWorkbook = Resolve-RepositoryPath $OutputWorkbook 'dist\internal\poc\eMAS_Mapping_Configuration_POC.xlsm'

if (-not (Test-Path -LiteralPath $SourceDefinition -PathType Leaf)) { throw "Workbook source definition not found: $SourceDefinition" }
if (-not (Test-Path -LiteralPath $VbaSourceDirectory -PathType Container)) { throw "VBA source directory not found: $VbaSourceDirectory" }

$vbaFiles = @(Get-ChildItem -LiteralPath $VbaSourceDirectory -Filter '*.bas' -File | Sort-Object Name)
if ($vbaFiles.Count -eq 0) { throw "No .bas files found in $VbaSourceDirectory" }

New-Item -ItemType Directory -Path (Split-Path -Parent $GeneratedSourceWorkbook), (Split-Path -Parent $OutputWorkbook) -Force | Out-Null
if (Test-Path -LiteralPath $GeneratedSourceWorkbook) { Remove-Item -LiteralPath $GeneratedSourceWorkbook -Force }
if (Test-Path -LiteralPath $OutputWorkbook) { Remove-Item -LiteralPath $OutputWorkbook -Force }

Write-Host '[1/6] Generating the deterministic macro-free workbook source.'
& python (Join-Path $PSScriptRoot 'generate_emas_mapping_poc_workbook.py') --source $SourceDefinition --output $GeneratedSourceWorkbook
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $GeneratedSourceWorkbook -PathType Leaf)) {
    throw 'The deterministic workbook-source generation failed.'
}

$excel = $null
$workbook = $null
try {
    Write-Host '[2/6] Starting Microsoft Excel.'
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.EnableEvents = $false

    Write-Host '[3/6] Opening the generated synthetic workbook source.'
    $workbook = $excel.Workbooks.Open($GeneratedSourceWorkbook, 0, $false)

    Write-Host '[4/6] Importing reviewed VBA source.'
    try {
        $vbProject = $workbook.VBProject
        $null = $vbProject.VBComponents.Count
    }
    catch {
        throw "Excel denied programmatic access to the VBA project. Enable 'Trust access to the VBA project object model' only in the controlled internal build environment, then retry. $($_.Exception.Message)"
    }

    foreach ($file in $vbaFiles) {
        $componentName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $existing = $null
        foreach ($component in @($vbProject.VBComponents)) {
            if ($component.Type -eq 1 -and $component.Name -eq $componentName) {
                $existing = $component
                break
            }
        }
        if ($null -ne $existing) { $vbProject.VBComponents.Remove($existing) }
        $null = $vbProject.VBComponents.Import($file.FullName)
        Write-Host "  Imported $($file.Name)"
    }

    Write-Host '[5/6] Saving the generated macro-enabled workbook.'
    if ($PSCmdlet.ShouldProcess($OutputWorkbook, 'Save generated XLSM proof of concept')) {
        $xlOpenXmlWorkbookMacroEnabled = 52
        $workbook.SaveAs($OutputWorkbook, $xlOpenXmlWorkbookMacroEnabled)
    }
    $workbook.Close($true)
    $workbook = $null
    $excel.Quit()
    $excel = $null

    Write-Host '[6/6] Verifying that the XLSM package contains a VBA project.'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($OutputWorkbook)
    try {
        $vbaEntry = $archive.Entries | Where-Object FullName -eq 'xl/vbaProject.bin'
        if ($null -eq $vbaEntry) { throw 'Generated workbook does not contain xl/vbaProject.bin.' }
    }
    finally {
        $archive.Dispose()
    }

    $hash = (Get-FileHash -LiteralPath $OutputWorkbook -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "Generated: $OutputWorkbook"
    Write-Host "SHA-256:  $hash"
}
finally {
    if ($null -ne $workbook) { try { $workbook.Close($false) } catch {} }
    if ($null -ne $excel) { try { $excel.Quit() } catch {} }
    if ($null -ne $workbook) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($workbook) }
    if ($null -ne $excel) { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($excel) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
