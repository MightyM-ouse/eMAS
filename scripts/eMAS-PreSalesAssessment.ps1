[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('RuntimeJsonPath', 'ConfigurationPath')]
    [ValidateNotNullOrEmpty()]
    [string] $RuntimeConfigurationPath,

    [string] $NormalizedResultPath,
    [string] $ExecutionLogPath,
    [string] $TemplatePath,
    [string] $TemplateMappingPath,
    [string] $OutputWorkbookPath,
    [string] $MappingSchemaPath,
    [string] $ResultSchemaPath,
    [string] $PythonExecutablePath
)

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/Initialize-eMASPhaseRuntime.ps1')
. (Join-Path $PSScriptRoot 'private/Invoke-eMASPhaseReport.ps1')

if ([string]::IsNullOrWhiteSpace($NormalizedResultPath)) {
    Initialize-eMASPhaseRuntime `
        -Phase 'PRE_SALES' `
        -RuntimeConfigurationPath $RuntimeConfigurationPath `
        -ActiveScript $MyInvocation.MyCommand.Name `
        -ExecutionLogPath $ExecutionLogPath `
        -TemplatePath $TemplatePath
    return
}

Invoke-eMASPhaseReport `
    -Phase 'PRE_SALES' `
    -RuntimeConfigurationPath $RuntimeConfigurationPath `
    -NormalizedResultPath $NormalizedResultPath `
    -ActiveScript $MyInvocation.MyCommand.Name `
    -ExecutionLogPath $ExecutionLogPath `
    -TemplatePath $TemplatePath `
    -TemplateMappingPath $TemplateMappingPath `
    -OutputWorkbookPath $OutputWorkbookPath `
    -MappingSchemaPath $MappingSchemaPath `
    -ResultSchemaPath $ResultSchemaPath `
    -PythonExecutablePath $PythonExecutablePath
