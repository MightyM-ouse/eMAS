Attribute VB_Name = "modConstants"
Option Explicit

Public Const EMAS_SCHEMA_VERSION As String = "1.0.0"
Public Const EMAS_MAPPING_VERSION As String = "0.1.0"
Public Const EMAS_WORKBOOK_VERSION As String = "0.1.0"
Public Const EMAS_RUNTIME_FILE_NAME As String = "eMAS_Runtime_Config.json"
Public Const EMAS_POC_FIXED_UTC As String = "2026-07-13T10:00:00.000Z"
Public Const EMAS_POC_EXPORTED_BY As String = "SYNTHETIC_POC"
Public Const EMAS_POC_VALIDATION_RUN_ID As String = "VAL-POC-001"
Public Const EMAS_VALIDATION_TABLE As String = "tblValidationResults"
Public Const EMAS_EXPORT_HISTORY_TABLE As String = "tblExportHistory"
Public Const EMAS_MAX_PREVIEW_CHARS As Long = 4000

Public Function RequiredTableNames() As Variant
    RequiredTableNames = Array( _
        "tblConfiguration", "tblValueLists", "tblFieldCatalogue", _
        "tblFieldAllowedOperators", "tblFieldPhases", "tblMetricCatalogue", _
        "tblMetricPhases", "tblRegions", "tblAuthorities", _
        "tblTechnicalStandards", "tblRegionalImplementations", _
        "tblProductDomains", "tblLifecycleContexts", "tblProductClasses", _
        "tblProcedureContexts", "tblSourcePresentations", _
        "tblMasterDataRelationships", "tblRules", "tblRulePhaseAssignments", _
        "tblConditionGroups", "tblRuleConditions", "tblRuleOutputs", _
        "tblFindings", "tblRecommendations", "tblFindingRecommendationLinks", _
        "tblExceptionPolicies", "tblAliases", "tblConflictPolicies", _
        "tblRagPolicies", "tblConfidencePolicies", "tblEffortDriverDefinitions", _
        "tblEffortDriverPhases", "tblEffortThresholds", "tblDecisionPolicies", _
        "tblQuestionnaireMap", "tblReportDefinitions", "tblPhaseResults", _
        "tblTechnicalSettings", EMAS_VALIDATION_TABLE, EMAS_EXPORT_HISTORY_TABLE)
End Function
