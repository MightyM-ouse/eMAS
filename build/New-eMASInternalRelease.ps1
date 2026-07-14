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
    throw "PKG-INTERNAL-001: Runtime JSON could not be parsed. $($_.Exception.Message)"
}

$destination = [System.IO.Path]::GetFullPath($DestinationRoot)
if (Test-Path -LiteralPath $destination) {
    if (-not $Force) {
        throw "PKG-INTERNAL-002: Destination already exists. Use -Force to replace it: $destination"
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
        throw "PKG-INTERNAL-003: Required source path is missing: $source"
    }
    $target = Join-Path $destination $TargetRelativePath
    $targetParent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
}

Copy-eMASPackagePath -RelativePath 'scripts'
Copy-eMASPackagePath -RelativePath 'engine'
Copy-eMASPackagePath -RelativePath 'templates/controlled'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/pre-sales.template-map.json'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/pre-migration.template-map.json'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/post-migration.template-map.json'
Copy-eMASPackagePath -RelativePath 'config/report-mappings/report-template-map.schema.json'
Copy-eMASPackagePath -RelativePath 'config/result-schemas/report-redesign-v3.2'
Copy-eMASPackagePath -RelativePath 'config/schema/eMAS-runtime-config.schema.json'
Copy-eMASPackagePath -RelativePath 'build/requirements-reporting.txt'
Copy-eMASPackagePath -RelativePath 'docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md'
Copy-eMASPackagePath -RelativePath 'docs/requirements/report-redesign'
Copy-eMASPackagePath -RelativePath 'docs/architecture/phase-contracts'
Copy-eMASPackagePath -RelativePath 'docs/implementation/REPORT_REDESIGN_V3.2_ALIGNMENT_STATUS.md'

$runtimeTarget = Join-Path $destination 'config/runtime/eMAS_Runtime_Config.json'
New-Item -ItemType Directory -Path (Split-Path -Parent $runtimeTarget) -Force | Out-Null
Copy-Item -LiteralPath $runtimePath -Destination $runtimeTarget -Force

# Remove development-only caches defensively if present in the source workspace.
Get-ChildItem -LiteralPath $destination -Recurse -Directory -Force |
    Where-Object { $_.Name -in @('__pycache__', '.pytest_cache') } |
    Sort-Object FullName -Descending |
    Remove-Item -Recurse -Force
Get-ChildItem -LiteralPath $destination -Recurse -File -Force |
    Where-Object { $_.Extension -in @('.pyc', '.pyo') } |
    Remove-Item -Force

$readme = @"
# eMAS Internal Migration Assessment Package

Package version: $PackageVersion

This package contains the controlled report-generation and runtime-validation assets for:

- Pre-Sales Assessment;
- Pre-Migration Readiness;
- Post-Migration Verification.

It contains one immutable Runtime JSON at `config/runtime/eMAS_Runtime_Config.json`, template version `1.2.0`, report-template map version `2.0.0` and result-contract version `1.0.0`.

## Prerequisites

- Windows PowerShell 5.1 for Pre-Sales customer-compatible execution;
- PowerShell 7.6 LTS on Windows for Pre-Migration and Post-Migration qualification;
- Python 3 and the dependency in `build/requirements-reporting.txt` for the current OpenXML report adapter.

Install the report dependency:

```powershell
python -m pip install -r .\build\requirements-reporting.txt
```

Validate package integrity:

```powershell
.\build\Test-eMASReleasePackage.ps1 -RootPath . -ExpectedPackageType InternalRelease
```

## Phase commands

```powershell
.\scripts\eMAS-PreSalesAssessment.ps1 -RuntimeConfigurationPath .\config\runtime\eMAS_Runtime_Config.json -NormalizedResultPath C:\Evidence\PreSalesResult.json
.\scripts\eMAS-PreMigrationReadiness.ps1 -RuntimeConfigurationPath .\config\runtime\eMAS_Runtime_Config.json -NormalizedResultPath C:\Evidence\PreMigrationResult.json
.\scripts\eMAS-PostMigrationVerification.ps1 -RuntimeConfigurationPath .\config\runtime\eMAS_Runtime_Config.json -NormalizedResultPath C:\Evidence\PostMigrationResult.json
```

## Integrity and handling

- Keep source evidence read-only.
- Do not place customer evidence, generated reports, logs, credentials or accepted-exception approvals inside this controlled package.
- Store execution outputs outside the package or in local `output/` and `logs/` folders that are not redistributed.

## Release boundary

This package assembles repository-controlled implementation assets. It does not establish native Excel qualification, code signing, customer acceptance, regulatory approval or production release authorization.
"@
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $destination 'README.md'), $readme + [Environment]::NewLine, $encoding)

# Include package integrity tools themselves for independent verification.
Copy-eMASPackagePath -RelativePath 'build/New-eMASChecksumManifest.ps1'
Copy-eMASPackagePath -RelativePath 'build/Test-eMASReleasePackage.ps1'

$manifestScript = Join-Path $PSScriptRoot 'New-eMASChecksumManifest.ps1'
$validationScript = Join-Path $PSScriptRoot 'Test-eMASReleasePackage.ps1'
$manifest = & $manifestScript `
    -RootPath $destination `
    -PackageType 'InternalRelease' `
    -PackageVersion $PackageVersion `
    -SourceCommit $SourceCommit

$validation = & $validationScript `
    -RootPath $destination `
    -ExpectedPackageType 'InternalRelease' `
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
    PackageType = 'InternalRelease'
    PackageVersion = $PackageVersion
    PackageRoot = $destination
    ArchivePath = $archivePath
    ManifestPath = $manifest.ManifestPath
    ManifestSha256 = $manifest.ManifestSha256
    FileCount = $manifest.FileCount
    ValidationStatus = $validation.status
}
