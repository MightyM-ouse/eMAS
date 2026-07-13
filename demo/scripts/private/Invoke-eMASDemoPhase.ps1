function Invoke-eMASDemoPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PRE_SALES', 'PRE_MIGRATION', 'POST_MIGRATION')]
        [string] $Phase,
        [Parameter(Mandatory = $true)][string] $RuntimeConfigurationPath,
        [Parameter(Mandatory = $true)][string] $ResultJsonPath,
        [Parameter(Mandatory = $true)][string] $TemplatePath,
        [Parameter(Mandatory = $true)][string] $TemplateMappingPath,
        [Parameter(Mandatory = $true)][string] $OutputDirectory,
        [Parameter(Mandatory = $true)][string] $ActiveScript,
        [string] $ReportFileName,
        [string] $LogFileName,
        [string] $PythonExecutablePath,
        [switch] $KeepIntermediateFiles
    )

    $repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
    $runtimeBootstrap = Join-Path $repositoryRoot 'scripts/private/Initialize-eMASPhaseRuntime.ps1'
    $reportModule = Join-Path $repositoryRoot 'engine/reporting/eMAS.ReportPopulation.psm1'
    $phaseNames = @{ PRE_SALES = 'PreSales'; PRE_MIGRATION = 'PreMigration'; POST_MIGRATION = 'PostMigration' }
    $timestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
    if (-not $ReportFileName) { $ReportFileName = 'eMAS_{0}_Demo_{1}.xlsx' -f $phaseNames[$Phase], $timestamp }
    if (-not $LogFileName) { $LogFileName = 'eMAS_{0}_Demo_{1}.log' -f $phaseNames[$Phase], $timestamp }
    $outputDirectoryFull = [System.IO.Path]::GetFullPath($OutputDirectory)
    $reportPath = Join-Path $outputDirectoryFull $ReportFileName
    $logPath = Join-Path $outputDirectoryFull $LogFileName
    $started = [DateTime]::UtcNow

    try {
        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Initializing' -PercentComplete 0
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Validating paths' -PercentComplete 5
        Write-Host '[1/9] Initializing'
        foreach ($path in @($RuntimeConfigurationPath, $ResultJsonPath, $TemplatePath, $TemplateMappingPath, $runtimeBootstrap, $reportModule)) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file was not found: $path" }
        }
        if (-not (Test-Path -LiteralPath $outputDirectoryFull -PathType Container)) {
            [void][System.IO.Directory]::CreateDirectory($outputDirectoryFull)
        }

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Validating runtime configuration' -PercentComplete 12
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Loading shared runtime JSON' -PercentComplete 15
        Write-Host '[2/9] Validating runtime configuration'
        . $runtimeBootstrap
        $runtime = Initialize-eMASPhaseRuntime -Phase $Phase -RuntimeConfigurationPath $RuntimeConfigurationPath -ActiveScript $ActiveScript -ExecutionLogPath $logPath -TemplatePath $TemplatePath

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Loading normalized result' -PercentComplete 28
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Checking normalized result path' -PercentComplete 30
        Write-Host '[3/9] Loading normalized result'

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Validating report mapping' -PercentComplete 40
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Loading authoritative mapping contract' -PercentComplete 42
        Write-Host '[4/9] Validating report mapping'
        Import-Module -Name $reportModule -Force -ErrorAction Stop

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Validating controlled template' -PercentComplete 52
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Checking template identity and structure' -PercentComplete 55
        Write-Host '[5/9] Validating controlled template'

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Copying controlled template' -PercentComplete 63
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Preparing output copy' -PercentComplete 65
        Write-Host '[6/9] Copying controlled template'

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Populating mapped targets' -PercentComplete 72
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Writing mapped tables' -PercentComplete 75
        Write-Host '[7/9] Populating mapped targets'
        $exportParameters = @{
            ResultJsonPath = $ResultJsonPath
            TemplateMappingPath = $TemplateMappingPath
            TemplatePath = $TemplatePath
            OutputWorkbookPath = $reportPath
            ExecutionLogPath = $logPath
        }
        if ($PythonExecutablePath) { $exportParameters['PythonExecutablePath'] = $PythonExecutablePath }
        $report = Export-eMASResultToTemplate @exportParameters

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Validating generated workbook' -PercentComplete 88
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Verifying OpenXML preservation' -PercentComplete 90
        Write-Host '[8/9] Validating generated workbook'

        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Status 'Completing report' -PercentComplete 98
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Status 'Writing completion summary' -PercentComplete 100
        Write-Host '[9/9] Completing report'
        $duration = ([DateTime]::UtcNow - $started).TotalSeconds
        Write-Host ('Phase: {0}' -f $Phase)
        Write-Host ('Result: {0}' -f $report.FinalResult)
        Write-Host ('Duration seconds: {0:N3}' -f $duration)
        Write-Host ('Report: {0}' -f $report.OutputWorkbookPath)
        Write-Host ('Log: {0}' -f $report.ExecutionLogPath)
        Write-Host ('Validation: {0}' -f $report.Validation.OverallStatus)
        return [pscustomobject]@{ ExecutionId = $runtime.ExecutionId; RuntimeConfiguration = $runtime.RuntimeConfiguration; Report = $report; KeepIntermediateFiles = [bool]$KeepIntermediateFiles }
    }
    finally {
        Write-Progress -Id 2 -ParentId 1 -Activity 'Current task' -Completed
        Write-Progress -Id 1 -Activity 'eMAS demo report generation' -Completed
    }
}
