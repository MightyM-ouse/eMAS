[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RuntimeConfigurationPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $DestinationRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersion,

    [string] $SourceCommit,
    [switch] $CreateArchive,
    [switch] $Force
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtimePath = (Resolve-Path -LiteralPath $RuntimeConfigurationPath -ErrorAction Stop).ProviderPath

try {
    $null = Get-Content -LiteralPath $runtimePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "PKG-PRESALES-001: Runtime JSON could not be parsed. $($_.Exception.Message)"
}

$destination = [System.IO.Path]::GetFullPath($DestinationRoot)
if (Test-Path -LiteralPath $destination) {
    if (-not $Force) {
        throw "PKG-PRESALES-002: Destination already exists. Use -Force to replace it: $destination"
    }
    Remove-Item -LiteralPath $destination -Recurse -Force
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null

function Copy-eMASPackagePath {
    param(
        [Parameter(Mandatory = $true)][string] $RelativePath,
        [string] $TargetRelativePath
    )
    if ([string]::IsNullOrWhiteSpace($TargetRelativePath)) {
        $TargetRelativePath = $RelativePath
    }
    $source = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $source)) {
        throw "PKG-PRESALES-003: Required source path is missing: $source"
    }
    $target = Join-Path $destination $TargetRelativePath
    $targetParent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
}

Copy-eMASPackagePath -RelativePath 'scripts/eMAS-PreSalesAssessment.ps1'
Copy-eMASPackagePath -RelativePath 'scripts/private/Initialize-eMASPhaseRuntime.ps1'
Copy-eMASPackagePath -RelativePath 'scripts/private/Invoke-eMASPhaseReport.ps1'
Copy-eMASPackagePath -RelativePath 'engine/core'
Copy-eMASPackagePath -RelativePath 'engine/reporting/eMAS.ReportPopulation.psm1'
Copy-eMASPackagePath -RelativePath 'engine/reporting/emas_report_openxml.py'
Copy-eMASPackagePath -RelativePath 'engine/reporting/emas_report_openxml_v32.py'
Copy-eMASPackagePath -RelativePath 'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/pre-sales.template-map.json'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/report-template-map.schema.json'
Copy-eMASPackagePath -RelativePath 'config/result-schemas/report-redesign-v3.2/pre-sales.result.schema.json'
Copy-eMASPackagePath -RelativePath 'build/requirements-reporting.txt'
Copy-eMASPackagePath -RelativePath 'build/New-eMASChecksumManifest.ps1'
Copy-eMASPackagePath -RelativePath 'build/Test-eMASReleasePackage.ps1'

$runtimeTarget = Join-Path $destination 'config/runtime/eMAS_Runtime_Config.json'
New-Item -ItemType Directory -Path (Split-Path -Parent $runtimeTarget) -Force | Out-Null
Copy-Item -LiteralPath $runtimePath -Destination $runtimeTarget -Force

$readme = @"
# eMAS Pre-Sales Assessment Customer Package

Package version: $PackageVersion

This controlled package performs Pre-Sales report generation from:

1. the included immutable `config/runtime/eMAS_Runtime_Config.json`; and
2. a normalized Pre-Sales result JSON conforming to result-contract version `1.0.0`.

The package does not modify source evidence or the Runtime JSON.

## Prerequisites

- Windows PowerShell 5.1 on Windows;
- Python 3 available as `python` or `python3`;
- the Python dependency listed in `build/requirements-reporting.txt`.

Install the reporting dependency once:

```powershell
python -m pip install -r .\build\requirements-reporting.txt
```

Validate package integrity:

```powershell
.\build\Test-eMASReleasePackage.ps1 -RootPath . -ExpectedPackageType CustomerPreSales
```

Run report generation:

```powershell
.\scripts\eMAS-PreSalesAssessment.ps1 -RuntimeConfigurationPath .\config\runtime\eMAS_Runtime_Config.json -NormalizedResultPath C:\Path\To\PreSalesResult.json
```

The generated workbook is written under `output/` unless `-OutputWorkbookPath` is supplied. A separate timestamped UTF-8 log is written under `logs/`.

## Share with EXTEDO

Share the generated XLSX report and its corresponding execution log. Do not share credentials, unrelated source data or uncontrolled local files.

## Release boundary

This package is integrity-controlled by `package-manifest.json` and `package-manifest.sha256`. Package integrity does not replace customer acceptance, supported-environment qualification or controlled release approval.
"@
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $destination 'README.md'), $readme + [Environment]::NewLine, $encoding)

$manifestScript = Join-Path $PSScriptRoot 'New-eMASChecksumManifest.ps1'
$validationScript = Join-Path $PSScriptRoot 'Test-eMASReleasePackage.ps1'
$manifest = & $manifestScript `
    -RootPath $destination `
    -PackageType 'CustomerPreSales' `
    -PackageVersion $PackageVersion `
    -SourceCommit $SourceCommit

$validation = & $validationScript `
    -RootPath $destination `
    -ExpectedPackageType 'CustomerPreSales' `
    -ValidationResultPath (Join-Path $destination 'package-validation.json')

$archivePath = $null
if ($CreateArchive) {
    $archivePath = $destination.TrimEnd([char[]]@('\', '/')) + '.zip'
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    Compress-Archive -Path (Join-Path $destination '*') -DestinationPath $archivePath -CompressionLevel Optimal
}

[pscustomobject]@{
    Status = 'Passed'
    PackageType = 'CustomerPreSales'
    PackageVersion = $PackageVersion
    PackageRoot = $destination
    ArchivePath = $archivePath
    ManifestPath = $manifest.ManifestPath
    ManifestSha256 = $manifest.ManifestSha256
    FileCount = $manifest.FileCount
    ValidationStatus = $validation.status
}
