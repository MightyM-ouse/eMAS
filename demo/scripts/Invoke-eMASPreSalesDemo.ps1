[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $RuntimeConfigurationPath,
    [Parameter(Mandatory = $true)][string] $ResultJsonPath,
    [Parameter(Mandatory = $true)][string] $TemplatePath,
    [Parameter(Mandatory = $true)][string] $TemplateMappingPath,
    [Parameter(Mandatory = $true)][string] $OutputDirectory,
    [string] $ReportFileName, [string] $LogFileName, [string] $PythonExecutablePath,
    [switch] $KeepIntermediateFiles
)
. (Join-Path $PSScriptRoot 'private/Invoke-eMASDemoPhase.ps1')
try {
    Invoke-eMASDemoPhase -Phase 'PRE_SALES' @PSBoundParameters -ActiveScript $PSCommandPath
    exit 0
}
catch { Write-Error $_; exit 1 }
