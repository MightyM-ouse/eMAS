Set-StrictMode -Version 2.0

# Contract metadata only. Functional Runtime JSON loading is not implemented here.

function Get-eMASConfigurationLoaderContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        SchemaVersion = '1.0.0'
        MinimumCoreCompatibility = 'WindowsPowerShell5.1'
        RuntimeJsonFileName = 'eMAS_Runtime_Config.json'
        RequiredTopLevelSections = @(
            'configuration',
            'valueLists',
            'fieldCatalogue',
            'metricCatalogue',
            'masterData',
            'relationships',
            'rules',
            'rulePhases',
            'conditionGroups',
            'ruleConditions',
            'ruleOutputs',
            'findings',
            'recommendations',
            'findingRecommendationLinks',
            'exceptionPolicies',
            'aliases',
            'policies',
            'questionnaireMap',
            'reportTerminology'
        )
        EvaluationStatusCodes = @(
            'Evaluated',
            'NotAssessed',
            'NotApplicable',
            'Skipped',
            'Warning',
            'Error',
            'InsufficientEvidence',
            'Conflict'
        )
        ProhibitedLoaderActions = @(
            'ReadXlsm',
            'GenerateRuntimeJson',
            'RepairRuntimeJson',
            'ModifySourceEvidence',
            'ApplyBusinessInterpretation'
        )
    }
}

function Test-eMASEvaluationStatusCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Code
    )

    $contract = Get-eMASConfigurationLoaderContract
    return ($contract.EvaluationStatusCodes -contains $Code)
}

Export-ModuleMember -Function Get-eMASConfigurationLoaderContract, Test-eMASEvaluationStatusCode
