Set-StrictMode -Version 2.0

# Contract metadata only. Functional Runtime JSON loading is not implemented here.

function Get-eMASConfigurationLoaderContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        SchemaVersion = '1.0.0'
        SupportedSchemaVersions = @('1.0.0')
        SchemaVersionAdapters = @{}
        MinimumCoreCompatibility = 'WindowsPowerShell5.1'
        RuntimeJsonFileName = 'eMAS_Runtime_Config.json'
        MetadataSectionCandidates = @(
            'configuration',
            'metadata',
            'configurationMetadata'
        )
        MetadataPropertyCandidates = [ordered]@{
            ConfigurationId = @('configurationId', 'id')
            ConfigurationName = @('configurationName', 'name')
            SchemaVersion = @('schemaVersion')
            ConfigurationVersion = @('mappingVersion', 'configurationVersion', 'version')
            EffectiveDate = @('effectiveFrom', 'effectiveDate')
            Status = @('status', 'configurationStatus')
        }
        SectionCandidates = [ordered]@{
            Metadata = @('configuration', 'metadata', 'configurationMetadata')
            CodeLists = @('valueLists', 'codeLists')
            FieldCatalogue = @('fieldCatalogue', 'fields')
            MetricCatalogue = @('metricCatalogue', 'metrics')
            MasterData = @('masterData')
            Relationships = @('relationships')
            Rules = @('rules', 'ruleCatalogue')
            RulePhases = @('rulePhases', 'ruleApplicability')
            ConditionGroups = @('conditionGroups')
            RuleConditions = @('ruleConditions', 'conditions')
            RuleOutputs = @('ruleOutputs', 'outputs')
            Findings = @('findings', 'findingCatalogue')
            Recommendations = @('recommendations', 'recommendationCatalogue')
            FindingRecommendationLinks = @('findingRecommendationLinks', 'recommendationLinks')
            ExceptionPolicies = @('exceptionPolicies')
            Aliases = @('aliases')
            Policies = @('policies')
            QuestionnaireMap = @('questionnaireMap')
            ReportTerminology = @('reportTerminology')
        }
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
        ObjectSectionNames = @(
            'Metadata',
            'CodeLists',
            'MasterData',
            'Policies',
            'ReportTerminology'
        )
        CollectionSectionNames = @(
            'FieldCatalogue',
            'MetricCatalogue',
            'Relationships',
            'Rules',
            'RulePhases',
            'ConditionGroups',
            'RuleConditions',
            'RuleOutputs',
            'Findings',
            'Recommendations',
            'FindingRecommendationLinks',
            'ExceptionPolicies',
            'Aliases',
            'QuestionnaireMap'
        )
        CollectionContracts = @(
            [pscustomobject]@{ Name = 'Relationships'; IdCandidates = @('relationshipId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'Rules'; IdCandidates = @('ruleId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'RulePhases'; IdCandidates = @('rulePhaseId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'ConditionGroups'; IdCandidates = @('conditionGroupId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'RuleConditions'; IdCandidates = @('conditionId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'RuleOutputs'; IdCandidates = @('ruleOutputId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'Findings'; IdCandidates = @('findingCode', 'findingId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'Recommendations'; IdCandidates = @('recommendationCode', 'recommendationId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'FindingRecommendationLinks'; IdCandidates = @('linkId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'ExceptionPolicies'; IdCandidates = @('exceptionPolicyId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'Aliases'; IdCandidates = @('aliasId', 'id'); Required = $true }
            [pscustomobject]@{ Name = 'QuestionnaireMap'; IdCandidates = @('questionnaireMapId', 'id'); Required = $true }
        )
        ReferenceContracts = @(
            [pscustomobject]@{ Source = 'RulePhases'; PropertyCandidates = @('ruleId'); Target = 'Rules'; TargetIdCandidates = @('ruleId', 'id') }
            [pscustomobject]@{ Source = 'ConditionGroups'; PropertyCandidates = @('ruleId'); Target = 'Rules'; TargetIdCandidates = @('ruleId', 'id') }
            [pscustomobject]@{ Source = 'RuleConditions'; PropertyCandidates = @('ruleId'); Target = 'Rules'; TargetIdCandidates = @('ruleId', 'id') }
            [pscustomobject]@{ Source = 'RuleConditions'; PropertyCandidates = @('conditionGroupId'); Target = 'ConditionGroups'; TargetIdCandidates = @('conditionGroupId', 'id') }
            [pscustomobject]@{ Source = 'RuleOutputs'; PropertyCandidates = @('ruleId'); Target = 'Rules'; TargetIdCandidates = @('ruleId', 'id') }
            [pscustomobject]@{ Source = 'FindingRecommendationLinks'; PropertyCandidates = @('findingCode', 'findingId'); Target = 'Findings'; TargetIdCandidates = @('findingCode', 'findingId', 'id') }
            [pscustomobject]@{ Source = 'FindingRecommendationLinks'; PropertyCandidates = @('recommendationCode', 'recommendationId'); Target = 'Recommendations'; TargetIdCandidates = @('recommendationCode', 'recommendationId', 'id') }
        )
        ControlledValueContracts = @(
            [pscustomobject]@{ CodeListCandidates = @('RAG', 'RagStatus'); PropertyCandidates = @('rag', 'defaultRag'); RequiredCodeList = $true }
            [pscustomobject]@{ CodeListCandidates = @('CONFIDENCE', 'Confidence'); PropertyCandidates = @('confidence', 'confidenceCode'); RequiredCodeList = $true }
            [pscustomobject]@{ CodeListCandidates = @('PHASE', 'Phase'); PropertyCandidates = @('phase', 'supportedPhase', 'supportedPhases'); RequiredCodeList = $true }
            [pscustomobject]@{ CodeListCandidates = @('MIGRATION_SCENARIO', 'MigrationScenario'); PropertyCandidates = @('migrationScenario', 'migrationScenarios', 'supportedMigrationScenarios'); RequiredCodeList = $true }
        )
        LifecycleStatusCodeListCandidates = @('RULE_LIFECYCLE_STATUS', 'RuleLifecycleStatus')
        LifecycleStatusPropertyCandidates = @('status', 'ruleStatus')
        PriorityPropertyCandidates = @('priority', 'sequence', 'sortOrder')
        ThresholdCollectionCandidates = @('effortThresholds', 'thresholds')
        ThresholdLowerBoundCandidates = @('lowerBound', 'minimum', 'min')
        ThresholdUpperBoundCandidates = @('upperBound', 'maximum', 'max')
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
