#requires -Version 7.6
<#
.SYNOPSIS
    Generates the three fictional Aurelis Therapeutics eMAS demo report
    workbooks (Pre-Sales Assessment, Migration Readiness, Post-Migration
    Verification) using the real eMAS report-generation and template-
    population implementation.

.DESCRIPTION
    This is a thin orchestrator over the actual production report-population
    path already implemented in the repository:

        engine/reporting/eMAS.ReportPopulation.psm1  (Export-eMASResultToTemplate)
        engine/reporting/emas_report_openxml.py       (the OpenXML MVP writer)

    It does not contain any template-writing logic of its own. It copies each
    finalized controlled template, applies the corresponding authoritative
    mapping contract under config/report-mappings/, and writes the fictional
    Aurelis normalized-result JSON (tools/demo/data/aurelis-*-result.json)
    into three workbooks under artifacts/demo/aurelis-therapeutics/.

    Source templates and mapping contracts are never modified; only copies
    are written.
#>
[CmdletBinding()]
param(
    [string] $PythonExecutablePath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$reportModule = Join-Path $repositoryRoot 'engine/reporting/eMAS.ReportPopulation.psm1'
$mappingSchema = Join-Path $repositoryRoot 'config/report-mappings/report-template-map.schema.json'
$dataDir = Join-Path $repositoryRoot 'tools/demo/data'
$outputDir = Join-Path $repositoryRoot 'artifacts/demo/aurelis-therapeutics'
# Execution logs are diagnostic, not part of the final deliverable directory,
# so they are written alongside the seed data rather than into $outputDir.
$logDir = Join-Path $dataDir 'logs'

Import-Module -Name $reportModule -Force -ErrorAction Stop
[void][System.IO.Directory]::CreateDirectory($outputDir)
[void][System.IO.Directory]::CreateDirectory($logDir)

$phases = @(
    @{
        Name             = 'Pre-Sales Assessment'
        ResultJsonPath   = Join-Path $dataDir 'aurelis-pre-sales-result.json'
        TemplateMapping  = Join-Path $repositoryRoot 'config/report-mappings/pre-sales.template-map.json'
        TemplatePath     = Join-Path $repositoryRoot 'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx'
        OutputFileName   = 'Aurelis_PreSales_Assessment_AUR-MIG-26-041.xlsx'
        LogFileName      = 'Aurelis_PreSales_Assessment_AUR-MIG-26-041.log'
    },
    @{
        Name             = 'Migration Readiness'
        ResultJsonPath   = Join-Path $dataDir 'aurelis-pre-migration-result.json'
        TemplateMapping  = Join-Path $repositoryRoot 'config/report-mappings/pre-migration.template-map.json'
        TemplatePath     = Join-Path $repositoryRoot 'templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx'
        OutputFileName   = 'Aurelis_Migration_Readiness_AUR-MIG-26-041.xlsx'
        LogFileName      = 'Aurelis_Migration_Readiness_AUR-MIG-26-041.log'
    },
    @{
        Name             = 'Post-Migration Verification'
        ResultJsonPath   = Join-Path $dataDir 'aurelis-post-migration-result.json'
        TemplateMapping  = Join-Path $repositoryRoot 'config/report-mappings/post-migration.template-map.json'
        TemplatePath     = Join-Path $repositoryRoot 'templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx'
        OutputFileName   = 'Aurelis_Post_Migration_Verification_AUR-MIG-26-041.xlsx'
        LogFileName      = 'Aurelis_Post_Migration_Verification_AUR-MIG-26-041.log'
    }
)

$results = @()
foreach ($phase in $phases) {
    Write-Host ("Generating {0} ..." -f $phase.Name)
    $exportParameters = @{
        ResultJsonPath      = $phase.ResultJsonPath
        TemplateMappingPath = $phase.TemplateMapping
        TemplatePath        = $phase.TemplatePath
        OutputWorkbookPath  = Join-Path $outputDir $phase.OutputFileName
        ExecutionLogPath    = Join-Path $logDir $phase.LogFileName
        MappingSchemaPath   = $mappingSchema
    }
    if ($PythonExecutablePath) { $exportParameters['PythonExecutablePath'] = $PythonExecutablePath }
    $report = Export-eMASResultToTemplate @exportParameters
    Write-Host ("  Result: {0}" -f $report.FinalResult)
    Write-Host ("  Workbook: {0}" -f $report.OutputWorkbookPath)
    $results += [pscustomobject]@{ Phase = $phase.Name; Report = $report }
}

$results
