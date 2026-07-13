[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('RuntimeJsonPath', 'ConfigurationPath')]
    [ValidateNotNullOrEmpty()]
    [string] $RuntimeConfigurationPath,

    [string] $ExecutionLogPath,

    [string] $TemplatePath
)

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/Initialize-eMASPhaseRuntime.ps1')

Initialize-eMASPhaseRuntime `
    -Phase 'PRE_SALES' `
    -RuntimeConfigurationPath $RuntimeConfigurationPath `
    -ActiveScript $MyInvocation.MyCommand.Name `
    -ExecutionLogPath $ExecutionLogPath `
    -TemplatePath $TemplatePath
