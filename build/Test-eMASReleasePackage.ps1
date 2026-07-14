[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RootPath,

    [string] $ManifestPath,

    [ValidateSet('CustomerPreSales', 'InternalRelease')]
    [string] $ExpectedPackageType,

    [string] $ValidationResultPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-eMASPackageSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::OpenRead($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Add-eMASPackageFinding {
    param(
        [System.Collections.ArrayList] $Findings,
        [string] $Code,
        [string] $Message,
        [AllowNull()][object] $Evidence
    )
    [void] $Findings.Add([ordered]@{
        code = $Code
        severity = 'Error'
        message = $Message
        evidence = $Evidence
        blocking = $true
    })
}

$resolvedRoot = (Resolve-Path -LiteralPath $RootPath -ErrorAction Stop).ProviderPath
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $resolvedRoot 'package-manifest.json'
}
$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath -ErrorAction Stop).ProviderPath
$findings = New-Object System.Collections.ArrayList

try {
    $manifest = Get-Content -LiteralPath $resolvedManifest -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "PKG-VALIDATE-001: Package manifest could not be parsed. $($_.Exception.Message)"
}

if ($manifest.manifestVersion -ne '1.0.0') {
    Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-002' -Message 'Unsupported package manifest version.' -Evidence $manifest.manifestVersion
}
if ($ExpectedPackageType -and $manifest.packageType -ne $ExpectedPackageType) {
    Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-003' -Message 'Package type does not match the expected type.' -Evidence @{ expected = $ExpectedPackageType; actual = $manifest.packageType }
}

$prohibitedPatterns = @(
    '(^|/)\.git(/|$)',
    '(^|/)__pycache__(/|$)',
    '\.py[co]$',
    '(^|/)customer-data(/|$)',
    '(^|/)customer-reports(/|$)',
    '(^|/)project-evidence(/|$)',
    '(^|/)migration-evidence(/|$)',
    '(^|/)accepted-exceptions(/|$)',
    '(^|/)logs?(/|$)',
    '(^|/)output(/|$)',
    '(^|/)\.env($|\.)',
    '\.(secret|secrets|credential|credentials)$',
    '(^|/)~\$'
)

$seen = @{}
foreach ($entry in @($manifest.files)) {
    $relativePath = [string] $entry.path
    $normalized = $relativePath.Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized.StartsWith('/') -or $normalized -match '(^|/)\.\.(/|$)') {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-004' -Message 'Manifest contains an unsafe relative path.' -Evidence $relativePath
        continue
    }

    $key = $normalized.ToLowerInvariant()
    if ($seen.ContainsKey($key)) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-005' -Message 'Manifest contains a duplicate path.' -Evidence $relativePath
        continue
    }
    $seen[$key] = $true

    foreach ($pattern in $prohibitedPatterns) {
        if ($normalized -match $pattern) {
            Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-006' -Message 'Package contains a prohibited file or directory.' -Evidence $relativePath
            break
        }
    }

    $fullPath = Join-Path $resolvedRoot ($normalized.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    $resolvedCandidate = [System.IO.Path]::GetFullPath($fullPath)
    if (-not $resolvedCandidate.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-004' -Message 'Manifest path escapes the package root.' -Evidence $relativePath
        continue
    }
    if (-not (Test-Path -LiteralPath $resolvedCandidate -PathType Leaf)) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-007' -Message 'Manifest file is missing from the package.' -Evidence $relativePath
        continue
    }

    $actualLength = (Get-Item -LiteralPath $resolvedCandidate).Length
    if ([int64] $entry.sizeBytes -ne [int64] $actualLength) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-008' -Message 'Package file size differs from the manifest.' -Evidence @{ path = $relativePath; expected = $entry.sizeBytes; actual = $actualLength }
    }
    $actualHash = Get-eMASPackageSha256 -Path $resolvedCandidate
    if ([string] $entry.sha256 -ne $actualHash) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-009' -Message 'Package file hash differs from the manifest.' -Evidence @{ path = $relativePath; expected = $entry.sha256; actual = $actualHash }
    }
}

$requiredByType = @{
    CustomerPreSales = @(
        'README.md',
        'scripts/eMAS-PreSalesAssessment.ps1',
        'scripts/private/Initialize-eMASPhaseRuntime.ps1',
        'scripts/private/Invoke-eMASPhaseReport.ps1',
        'engine/core/eMAS.RuntimeConfiguration.psm1',
        'engine/reporting/eMAS.ReportPopulation.psm1',
        'engine/reporting/emas_report_openxml.py',
        'engine/reporting/emas_report_openxml_v32.py',
        'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx',
        'config/report-mappings/pre-sales.template-map.json',
        'config/report-mappings/report-template-map.schema.json',
        'config/result-schemas/report-redesign-v3.2/pre-sales.result.schema.json',
        'config/runtime/eMAS_Runtime_Config.json'
    )
    InternalRelease = @(
        'README.md',
        'scripts/eMAS-PreSalesAssessment.ps1',
        'scripts/eMAS-PreMigrationReadiness.ps1',
        'scripts/eMAS-PostMigrationVerification.ps1',
        'engine/core/eMAS.RuntimeConfiguration.psm1',
        'engine/reporting/eMAS.ReportPopulation.psm1',
        'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx',
        'templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx',
        'templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx',
        'config/report-mappings/pre-sales.template-map.json',
        'config/report-mappings/pre-migration.template-map.json',
        'config/report-mappings/post-migration.template-map.json',
        'config/runtime/eMAS_Runtime_Config.json'
    )
}

if ($requiredByType.ContainsKey([string] $manifest.packageType)) {
    foreach ($requiredPath in $requiredByType[[string] $manifest.packageType]) {
        if (-not $seen.ContainsKey($requiredPath.ToLowerInvariant())) {
            Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-010' -Message 'Required package file is absent from the manifest.' -Evidence $requiredPath
        }
    }
}

$actualPackageFiles = @(
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Force |
        ForEach-Object { $_.FullName.Substring($resolvedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/') } |
        Where-Object { $_ -notin @('package-manifest.json', 'package-manifest.sha256', 'package-validation.json') }
)
foreach ($actualPath in $actualPackageFiles) {
    if (-not $seen.ContainsKey($actualPath.ToLowerInvariant())) {
        Add-eMASPackageFinding -Findings $findings -Code 'PKG-VALIDATE-011' -Message 'Package contains an unmanifested file.' -Evidence $actualPath
    }
}

$result = [ordered]@{
    validationVersion = '1.0.0'
    validatedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    packageType = $manifest.packageType
    packageVersion = $manifest.packageVersion
    packageRoot = $resolvedRoot
    manifestPath = $resolvedManifest
    status = $(if ($findings.Count -eq 0) { 'Passed' } else { 'Failed' })
    blockingIssueCount = $findings.Count
    findings = @($findings)
}

if ($ValidationResultPath) {
    $target = [System.IO.Path]::GetFullPath($ValidationResultPath)
    $targetDirectory = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, ($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine, $encoding)
}

if ($findings.Count -gt 0) {
    $first = $findings[0]
    throw ('{0}: {1}' -f $first.code, $first.message)
}

[pscustomobject] $result
