Attribute VB_Name = "modWorkbookStructure"
Option Explicit

Public Sub ValidateWorkbookStructure(ByRef issues As Collection)
    Dim tableName As Variant
    Dim lo As ListObject
    For Each tableName In RequiredTableNames()
        Set lo = GetTableByName(CStr(tableName))
        If lo Is Nothing Then
            AddValidationIssue issues, "POC_REQUIRED_TABLE", "Error", CStr(tableName), vbNullString, vbNullString, "Required table is missing."
        End If
    Next tableName

    ValidateColumns issues, "tblConfiguration", Array("ConfigurationId", "SchemaVersion", "MappingVersion", "SourceWorkbookVersion", "MinimumEngineVersion", "ExportType", "Status")
    ValidateColumns issues, "tblRules", Array("RuleId", "RuleRevision", "RuleType", "Status", "EffectiveFrom", "EffectiveTo", "Priority", "ConflictGroup", "ConflictStrategy", "Specificity", "StopProcessing", "LegacyRuleId")
    ValidateColumns issues, "tblValueLists", Array("ListName", "Code", "Status", "EffectiveFrom", "SortOrder")
    ValidateColumns issues, "tblFieldCatalogue", Array("FieldCode", "MaxEvidenceStrength")
    ValidateColumns issues, "tblRuleOutputs", Array("RuleOutputId", "RuleId", "OutputType", "OutputCode", "OutputValue", "TargetEntityType", "EvidenceStrength", "EvidencePolarity")
    ValidateColumns issues, "tblConflictPolicies", Array("ConflictPolicyId", "RuleType", "TieBehavior", "MinimumEvidenceStrengthForValue")
    ValidateColumns issues, "tblConfidencePolicies", Array("ConfidencePolicyId", "Scope", "EvidenceStrength", "WeightOrScore", "ResultConfidence", "CorroborationRule")
    ValidateColumns issues, "tblRuleConditions", Array("ConditionId", "RuleId", "ConditionGroupId", "FieldCode", "Operator", "ValueDataType")
    ValidateColumns issues, "tblMasterDataRelationships", Array("RelationshipId", "RelationshipType", "SourceEntityType", "SourceEntityCode", "TargetEntityType", "TargetEntityCode")
    ValidateColumns issues, "tblEffortThresholds", Array("EffortThresholdId", "ThresholdScopeType", "ThresholdScopeCode", "LowerBound", "UpperBound", "LowerInclusive", "UpperInclusive")
End Sub

Private Sub ValidateColumns(ByRef issues As Collection, ByVal tableName As String, ByVal columns As Variant)
    Dim lo As ListObject
    Dim columnName As Variant
    Set lo = GetTableByName(tableName)
    If lo Is Nothing Then Exit Sub
    For Each columnName In columns
        If Not ColumnExists(lo, CStr(columnName)) Then
            AddValidationIssue issues, "POC_REQUIRED_COLUMN", "Error", tableName, vbNullString, CStr(columnName), "Required column is missing."
        End If
    Next columnName
End Sub
