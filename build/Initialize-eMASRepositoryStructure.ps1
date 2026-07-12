[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RootPath = (Join-Path -Path (Get-Location) -ChildPath 'eMAS')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$directories = @(
    '.github\workflows',
    '.github\ISSUE_TEMPLATE',
    'scripts\launchers',
    'engine',
    'config\authoring',
    'config\vba\modules',
    'config\vba\classes',
    'config\vba\forms',
    'config\schema',
    'config\runtime\controlled',
    'config\runtime\development',
    'config\samples',
    'templates\controlled\pre-sales',
    'templates\controlled\pre-migration',
    'templates\controlled\post-migration',
    'templates\branding',
    'templates\manifest',
    'templates\samples',
    'ui\pre-migration',
    'ui\post-migration',
    'ui\shared',
    'docs\requirements',
    'docs\architecture\decisions',
    'docs\configuration',
    'docs\repository',
    'docs\reporting',
    'docs\development',
    'docs\testing',
    'docs\validation',
    'docs\operations',
    'docs\governance\decisions',
    'docs\governance\open-questions',
    'docs\governance\traceability',
    'docs\governance\change-history',
    'docs\releases\release-notes',
    'docs\releases\known-limitations',
    'docs\llm-development-context',
    'tests\unit',
    'tests\integration',
    'tests\scenarios\pre-sales',
    'tests\scenarios\pre-migration',
    'tests\scenarios\post-migration',
    'tests\fixtures\folder-structures\green',
    'tests\fixtures\folder-structures\amber',
    'tests\fixtures\folder-structures\red',
    'tests\fixtures\folder-structures\unknown',
    'tests\fixtures\workbooks',
    'tests\fixtures\runtime-config\valid',
    'tests\fixtures\runtime-config\invalid',
    'tests\fixtures\accepted-exceptions',
    'tests\expected\pre-sales',
    'tests\expected\pre-migration',
    'tests\expected\post-migration',
    'tests\performance',
    'build',
    'releases\release-notes',
    'releases\known-limitations',
    'releases\manifests',
    'output',
    'logs',
    'dist'
)

$placeholderFolders = @(
    'config\runtime\development',
    'output',
    'logs',
    'dist'
)

$resolvedRoot = [System.IO.Path]::GetFullPath($RootPath)

if ($PSCmdlet.ShouldProcess($resolvedRoot, 'Create eMAS repository directory structure')) {
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null
    }

    foreach ($relativePath in $directories) {
        $directoryPath = Join-Path -Path $resolvedRoot -ChildPath $relativePath

        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
        }
    }

    foreach ($relativePath in $placeholderFolders) {
        $placeholderPath = Join-Path -Path $resolvedRoot -ChildPath (Join-Path -Path $relativePath -ChildPath '.gitkeep')

        if (-not (Test-Path -LiteralPath $placeholderPath -PathType Leaf)) {
            New-Item -ItemType File -Path $placeholderPath -Force | Out-Null
        }
    }

    Write-Host "eMAS repository structure is available at: $resolvedRoot"
}
