function Invoke-eMASPhaseReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PRE_SALES', 'PRE_MIGRATION', 'POST_MIGRATION')]
        [string] $Phase,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RuntimeConfigurationPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NormalizedResultPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ActiveScript,

        [AllowNull()]
        [string] $ExecutionLogPath,

        [AllowNull()]
        [string] $TemplatePath,

        [AllowNull()]
        [string] $TemplateMappingPath,

        [AllowNull()]
        [string] $OutputWorkbookPath,

        [AllowNull()]
        [string] $MappingSchemaPath,

        [AllowNull()]
        [string] $ResultSchemaPath,

        [AllowNull()]
        [string] $PythonExecutablePath
    )

    Set-StrictMode -Version 2.0

    $repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $phaseConfiguration = @{
        PRE_SALES = @{
            Template = 'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx'
            Mapping = 'config/report-mappings/pre-sales.template-map.json'
            OutputPrefix = 'eMAS_PreSalesAssessment'
        }
        PRE_MIGRATION = @{
            Template = 'templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx'
            Mapping = 'config/report-mappings/pre-migration.template-map.json'
            OutputPrefix = 'eMAS_PreMigrationReadiness'
        }
        POST_MIGRATION = @{
            Template = 'templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx'
            Mapping = 'config/report-mappings/post-migration.template-map.json'
            OutputPrefix = 'eMAS_PostMigrationVerification'
        }
    }[$Phase]

    if ([string]::IsNullOrWhiteSpace($TemplatePath)) {
        $TemplatePath = Join-Path $repositoryRoot $phaseConfiguration.Template
    }
    if ([string]::IsNullOrWhiteSpace($TemplateMappingPath)) {
        $TemplateMappingPath = Join-Path $repositoryRoot $phaseConfiguration.Mapping
    }
    if ([string]::IsNullOrWhiteSpace($MappingSchemaPath)) {
        $MappingSchemaPath = Join-Path $repositoryRoot 'config/report-mappings/report-template-map.schema.json'
    }

    $resolvedResultPath = (Resolve-Path -LiteralPath $NormalizedResultPath -ErrorAction Stop).ProviderPath
    $resolvedTemplatePath = (Resolve-Path -LiteralPath $TemplatePath -ErrorAction Stop).ProviderPath
    $resolvedMappingPath = (Resolve-Path -LiteralPath $TemplateMappingPath -ErrorAction Stop).ProviderPath
    $resolvedMappingSchemaPath = (Resolve-Path -LiteralPath $MappingSchemaPath -ErrorAction Stop).ProviderPath

    if ([string]::IsNullOrWhiteSpace($OutputWorkbookPath)) {
        $outputDirectory = Join-Path $repositoryRoot 'output'
        if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        }
        $outputName = '{0}_{1}.xlsx' -f $phaseConfiguration.OutputPrefix, [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
        $OutputWorkbookPath = Join-Path $outputDirectory $outputName
    }
    else {
        $outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputWorkbookPath))
        if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        }
    }

    Write-Host ('[{0}] Initializing runtime configuration...' -f $Phase)
    Write-Progress -Activity 'eMAS phase execution' -Status 'Validating runtime configuration' -PercentComplete 10

    $initialization = Initialize-eMASPhaseRuntime `
        -Phase $Phase `
        -RuntimeConfigurationPath $RuntimeConfigurationPath `
        -ActiveScript $ActiveScript `
        -ExecutionLogPath $ExecutionLogPath `
        -TemplatePath $resolvedTemplatePath

    $reportModule = Join-Path $repositoryRoot 'engine/reporting/eMAS.ReportPopulation.psm1'
    Import-Module -Name $reportModule -Force -ErrorAction Stop

    try {
        Write-Host ('[{0}] Runtime configuration validated. Loading normalized result...' -f $Phase)
        Write-Progress -Activity 'eMAS phase execution' -Status 'Validating normalized result contract' -PercentComplete 35

        Write-Host ('[{0}] Populating controlled report template...' -f $Phase)
        Write-Progress -Activity 'eMAS phase execution' -Status 'Populating controlled workbook' -PercentComplete 65

        $arguments = @{
            ResultJsonPath = $resolvedResultPath
            TemplateMappingPath = $resolvedMappingPath
            TemplatePath = $resolvedTemplatePath
            OutputWorkbookPath = [System.IO.Path]::GetFullPath($OutputWorkbookPath)
            ExecutionLogPath = $initialization.ExecutionLogPath
            MappingSchemaPath = $resolvedMappingSchemaPath
        }
        if (-not [string]::IsNullOrWhiteSpace($ResultSchemaPath)) {
            $arguments.ResultSchemaPath = $ResultSchemaPath
        }
        if (-not [string]::IsNullOrWhiteSpace($PythonExecutablePath)) {
            $arguments.PythonExecutablePath = $PythonExecutablePath
        }

        $report = Export-eMASResultToTemplate @arguments

        Write-Progress -Activity 'eMAS phase execution' -Status 'Finalizing report output' -PercentComplete 95
        Write-Host ('[{0}] Report completed.' -f $Phase)
        Write-Host ('Output workbook: {0}' -f $report.OutputWorkbookPath)
        Write-Host ('Execution log: {0}' -f $report.ExecutionLogPath)
        Write-Host ('Output SHA-256: {0}' -f $report.OutputSha256)

        return [pscustomobject]@{
            ExecutionId = $initialization.ExecutionId
            Phase = $Phase
            RuntimeConfigurationStatus = $initialization.InitializationStatus
            AssessmentProcessingStarted = $true
            ReportStatus = $report.Status
            FinalResult = $report.FinalResult
            MappingId = $report.MappingId
            MappingVersion = $report.MappingVersion
            TemplateId = $report.TemplateId
            TemplateVersion = $report.TemplateVersion
            ResultContractVersion = $report.ResultContractVersion
            ResultSchemaPath = $report.ResultSchemaPath
            OutputWorkbookPath = $report.OutputWorkbookPath
            ExecutionLogPath = $report.ExecutionLogPath
            OutputSha256 = $report.OutputSha256
            DurationSeconds = $report.DurationSeconds
            TargetRowCounts = $report.TargetRowCounts
            Validation = $report.Validation
        }
    }
    finally {
        Write-Progress -Activity 'eMAS phase execution' -Completed
    }
}
