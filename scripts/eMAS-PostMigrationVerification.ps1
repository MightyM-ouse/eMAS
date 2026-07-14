[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias('RuntimeJsonPath', 'ConfigurationPath')]
    [ValidateNotNullOrEmpty()]
    [string] $RuntimeConfigurationPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
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

Invoke-eMASPhaseReport `
    -Phase 'POST_MIGRATION' `
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
