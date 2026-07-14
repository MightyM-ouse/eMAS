[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RootPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('CustomerPreSales', 'InternalRelease')]
    [string] $PackageType,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersion,

    [string] $OutputPath,
    [string] $SourceCommit,
    [string] $GeneratorVersion = '1.0.0'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-eMASPackageSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $stream = [System.IO.File]::OpenRead($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $algorithm.ComputeHash($stream)
        return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

$resolvedRoot = (Resolve-Path -LiteralPath $RootPath -ErrorAction Stop).ProviderPath
if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
    throw "PKG-MANIFEST-001: Package root is not a directory: $resolvedRoot"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $resolvedRoot 'package-manifest.json'
}
else {
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$manifestRelative = $null
if ($OutputPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    $manifestRelative = $OutputPath.Substring($resolvedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
}

$files = @(
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Force |
        Where-Object {
            $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
            $relative -ne $manifestRelative -and $relative -ne 'package-manifest.sha256'
        } |
        Sort-Object -Property @{ Expression = { $_.FullName.ToLowerInvariant() } } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($resolvedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
            [ordered]@{
                path = $relativePath
                sizeBytes = [int64] $_.Length
                sha256 = Get-eMASPackageSha256 -Path $_.FullName
            }
        }
)

$manifest = [ordered]@{
    manifestVersion = '1.0.0'
    packageType = $PackageType
    packageVersion = $PackageVersion
    generatedAtUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    sourceCommit = $SourceCommit
    generatorVersion = $GeneratorVersion
    fileCount = $files.Count
    files = $files
}

$json = $manifest | ConvertTo-Json -Depth 8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputPath, $json + [Environment]::NewLine, $utf8NoBom)

$manifestHash = Get-eMASPackageSha256 -Path $OutputPath
$hashPath = Join-Path (Split-Path -Parent $OutputPath) 'package-manifest.sha256'
$hashLine = '{0}  {1}' -f $manifestHash, (Split-Path -Leaf $OutputPath)
[System.IO.File]::WriteAllText($hashPath, $hashLine + [Environment]::NewLine, $utf8NoBom)

[pscustomobject]@{
    Status = 'Passed'
    PackageType = $PackageType
    PackageVersion = $PackageVersion
    PackageRoot = $resolvedRoot
    ManifestPath = $OutputPath
    ManifestSha256Path = $hashPath
    ManifestSha256 = $manifestHash
    FileCount = $files.Count
}
