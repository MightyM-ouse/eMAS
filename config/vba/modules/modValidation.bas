Attribute VB_Name = "modValidation"
Option Explicit

Public Function ValidateWorkbook(Optional ByVal writeResults As Boolean = True) As Collection
    Dim issues As New Collection
    ValidateWorkbookStructure issues
    If Not HasErrorIssues(issues) Then
        ValidateDuplicateIdentifiers issues
        ValidateConditionReferences issues
        ValidateRelationshipEndpoints issues
        ValidateThresholds issues
        ValidateExceptionPolicies issues
        ValidateOutputTargets issues
        ValidateLifecycleAndLegacy issues
        ValidateIdentification issues
        ValidateControlledMetadata issues
    End If
    If writeResults Then WriteValidationResults issues
    Set ValidateWorkbook = issues
End Function

Public Sub AddValidationIssue(ByRef issues As Collection, ByVal errorCode As String, ByVal severity As String, _
                              ByVal entityType As String, ByVal entityId As String, ByVal fieldName As String, _
                              ByVal message As String)
    Dim issue As Object
    Set issue = CreateObject("Scripting.Dictionary")
    issue.Add "ErrorCode", errorCode
    issue.Add "Severity", severity
    issue.Add "EntityType", entityType
    issue.Add "EntityId", entityId
    issue.Add "FieldName", fieldName
    issue.Add "Message", message
    issues.Add issue
End Sub

Public Function HasErrorIssues(ByVal issues As Collection) As Boolean
    Dim issue As Variant
    For Each issue In issues
        If StrComp(CStr(issue("Severity")), "Error", vbTextCompare) = 0 Then
            HasErrorIssues = True
            Exit Function
        End If
    Next issue
End Function

Private Sub ValidateDuplicateIdentifiers(ByRef issues As Collection)
    CheckUnique issues, "tblRules", "RuleId"
    CheckUnique issues, "tblRulePhaseAssignments", "RulePhaseId"
    CheckUnique issues, "tblConditionGroups", "ConditionGroupId"
    CheckUnique issues, "tblRuleConditions", "ConditionId"
    CheckUnique issues, "tblRuleOutputs", "RuleOutputId"
    CheckUnique issues, "tblFindings", "FindingCode"
    CheckUnique issues, "tblRecommendations", "RecommendationCode"
    CheckUnique issues, "tblMasterDataRelationships", "RelationshipId"
    CheckUnique issues, "tblEffortThresholds", "EffortThresholdId"
End Sub

Private Sub CheckUnique(ByRef issues As Collection, ByVal tableName As String, ByVal keyColumn As String)
    Dim lo As ListObject
    Dim seen As Object
    Dim rowIndex As Long
    Dim keyValue As String
    Set lo = GetTableByName(tableName)
    If lo Is Nothing Then Exit Sub
    If lo.DataBodyRange Is Nothing Then Exit Sub
    Set seen = CreateObject("Scripting.Dictionary")
    For rowIndex = 1 To lo.DataBodyRange.Rows.Count
        keyValue = TextValue(RowValue(lo, rowIndex, keyColumn))
        If seen.Exists(keyValue) Then
            AddValidationIssue issues, "SEM_DUPLICATE_ID", "Error", tableName, keyValue, keyColumn, "Duplicate identifier."
        Else
            seen.Add keyValue, True
        End If
    Next rowIndex
End Sub

Private Sub ValidateConditionReferences(ByRef issues As Collection)
    Dim conditions As ListObject
    Dim fields As ListObject
    Dim allowed As ListObject
    Dim fieldCodes As Object
    Dim allowedPairs As Object
    Dim i As Long
    Dim fieldCode As String
    Dim op As String
    Set conditions = GetTableByName("tblRuleConditions")
    Set fields = GetTableByName("tblFieldCatalogue")
    Set allowed = GetTableByName("tblFieldAllowedOperators")
    If conditions Is Nothing Then Exit Sub
    If fields Is Nothing Then Exit Sub
    If allowed Is Nothing Then Exit Sub
    Set fieldCodes = CreateObject("Scripting.Dictionary")
    For i = 1 To fields.DataBodyRange.Rows.Count
        fieldCodes(TextValue(RowValue(fields, i, "FieldCode"))) = True
    Next i
    Set allowedPairs = CreateObject("Scripting.Dictionary")
    For i = 1 To allowed.DataBodyRange.Rows.Count
        allowedPairs(TextValue(RowValue(allowed, i, "FieldCode")) & "|" & TextValue(RowValue(allowed, i, "Operator"))) = True
    Next i
    For i = 1 To conditions.DataBodyRange.Rows.Count
        fieldCode = TextValue(RowValue(conditions, i, "FieldCode"))
        op = TextValue(RowValue(conditions, i, "Operator"))
        If Not fieldCodes.Exists(fieldCode) Then
            AddValidationIssue issues, "SEM_BROKEN_REFERENCE", "Error", "tblRuleConditions", TextValue(RowValue(conditions, i, "ConditionId")), "FieldCode", "Field code does not exist."
        ElseIf Not allowedPairs.Exists(fieldCode & "|" & op) Then
            AddValidationIssue issues, "SEM_OPERATOR_NOT_ALLOWED", "Error", "tblRuleConditions", TextValue(RowValue(conditions, i, "ConditionId")), "Operator", "Operator is not allowed for the field."
        End If
    Next i
End Sub

Private Sub ValidateRelationshipEndpoints(ByRef issues As Collection)
    Dim lo As ListObject
    Dim i As Long
    Dim relType As String
    Dim sourceType As String
    Dim targetType As String
    Dim expected As String
    Set lo = GetTableByName("tblMasterDataRelationships")
    If lo Is Nothing Then Exit Sub
    If lo.DataBodyRange Is Nothing Then Exit Sub
    For i = 1 To lo.DataBodyRange.Rows.Count
        relType = TextValue(RowValue(lo, i, "RelationshipType"))
        sourceType = TextValue(RowValue(lo, i, "SourceEntityType"))
        targetType = TextValue(RowValue(lo, i, "TargetEntityType"))
        expected = ExpectedRelationshipPair(relType)
        If Len(expected) = 0 Or StrComp(sourceType & "|" & targetType, expected, vbBinaryCompare) <> 0 Then
            AddValidationIssue issues, "SEM_RELATIONSHIP_ENDPOINT", "Error", "tblMasterDataRelationships", TextValue(RowValue(lo, i, "RelationshipId")), "RelationshipType", "Relationship endpoint pair is not approved."
        End If
    Next i
End Sub

Private Function ExpectedRelationshipPair(ByVal relationshipType As String) As String
    Select Case relationshipType
        Case "AUTHORITY_TO_REGION": ExpectedRelationshipPair = "AUTHORITY|REGION"
        Case "AUTHORITY_TO_TECHNICAL_STANDARD": ExpectedRelationshipPair = "AUTHORITY|TECHNICAL_STANDARD"
        Case "TECHNICAL_STANDARD_TO_REGIONAL_IMPLEMENTATION": ExpectedRelationshipPair = "TECHNICAL_STANDARD|REGIONAL_IMPLEMENTATION"
        Case "PROCEDURE_CONTEXT_TO_TECHNICAL_STANDARD": ExpectedRelationshipPair = "PROCEDURE_CONTEXT|TECHNICAL_STANDARD"
        Case Else: ExpectedRelationshipPair = vbNullString
    End Select
End Function

Private Sub ValidateThresholds(ByRef issues As Collection)
    Dim lo As ListObject
    Dim i As Long, j As Long
    Dim scopeKeyA As String, scopeKeyB As String
    Dim upperA As Variant, lowerB As Variant
    Set lo = GetTableByName("tblEffortThresholds")
    If lo Is Nothing Then Exit Sub
    If lo.DataBodyRange Is Nothing Then Exit Sub
    For i = 1 To lo.DataBodyRange.Rows.Count
        For j = i + 1 To lo.DataBodyRange.Rows.Count
            scopeKeyA = TextValue(RowValue(lo, i, "ThresholdScopeType")) & "|" & TextValue(RowValue(lo, i, "ThresholdScopeCode")) & "|" & TextValue(RowValue(lo, i, "Unit"))
            scopeKeyB = TextValue(RowValue(lo, j, "ThresholdScopeType")) & "|" & TextValue(RowValue(lo, j, "ThresholdScopeCode")) & "|" & TextValue(RowValue(lo, j, "Unit"))
            If scopeKeyA = scopeKeyB Then
                upperA = RowValue(lo, i, "UpperBound")
                lowerB = RowValue(lo, j, "LowerBound")
                If Not IsBlankValue(upperA) And Not IsBlankValue(lowerB) Then
                    If CDbl(lowerB) < CDbl(upperA) Or (CDbl(lowerB) = CDbl(upperA) And CBool(RowValue(lo, i, "UpperInclusive")) And CBool(RowValue(lo, j, "LowerInclusive"))) Then
                        AddValidationIssue issues, "SEM_THRESHOLD_OVERLAP", "Error", "tblEffortThresholds", TextValue(RowValue(lo, j, "EffortThresholdId")), "LowerBound", "Threshold overlaps the previous band."
                    End If
                End If
            End If
        Next j
    Next i
End Sub

Private Sub ValidateExceptionPolicies(ByRef issues As Collection)
    Dim findings As ListObject
    Dim policies As ListObject
    Dim findingEligible As Object
    Dim i As Long
    Dim findingCode As String
    Set findings = GetTableByName("tblFindings")
    Set policies = GetTableByName("tblExceptionPolicies")
    If findings Is Nothing Then Exit Sub
    If policies Is Nothing Then Exit Sub
    Set findingEligible = CreateObject("Scripting.Dictionary")
    For i = 1 To findings.DataBodyRange.Rows.Count
        findingEligible(TextValue(RowValue(findings, i, "FindingCode"))) = CBool(RowValue(findings, i, "ExceptionEligible"))
    Next i
    For i = 1 To policies.DataBodyRange.Rows.Count
        findingCode = TextValue(RowValue(policies, i, "EligibleFindingCode"))
        If Not findingEligible.Exists(findingCode) Then
            AddValidationIssue issues, "SEM_BROKEN_REFERENCE", "Error", "tblExceptionPolicies", TextValue(RowValue(policies, i, "ExceptionPolicyId")), "EligibleFindingCode", "Finding does not exist."
        ElseIf Not CBool(findingEligible(findingCode)) Then
            AddValidationIssue issues, "SEM_EXCEPTION_INELIGIBLE", "Error", "tblExceptionPolicies", TextValue(RowValue(policies, i, "ExceptionPolicyId")), "EligibleFindingCode", "Finding is not exception eligible."
        End If
    Next i
End Sub

Private Sub ValidateOutputTargets(ByRef issues As Collection)
    Dim outputs As ListObject
    Dim findings As Object
    Dim masterCodes As Object
    Dim lo As ListObject
    Dim tableName As Variant
    Dim codeColumn As Variant
    Dim i As Long
    Dim outputType As String
    Dim outputCode As String
    Dim t As Long
    Dim identificationRules As Object
    Set identificationRules = RuleIdsOfType(EMAS_IDENTIFICATION_RULE_TYPE)
    Set outputs = GetTableByName("tblRuleOutputs")
    If outputs Is Nothing Then Exit Sub
    Set findings = CreateObject("Scripting.Dictionary")
    Set lo = GetTableByName("tblFindings")
    For i = 1 To lo.DataBodyRange.Rows.Count
        findings(TextValue(RowValue(lo, i, "FindingCode"))) = True
    Next i
    Set masterCodes = CreateObject("Scripting.Dictionary")
    tableName = Array("tblRegions", "tblAuthorities", "tblTechnicalStandards", "tblRegionalImplementations", "tblProductDomains", "tblLifecycleContexts", "tblProductClasses", "tblProcedureContexts", "tblSourcePresentations")
    codeColumn = Array("RegionCode", "AuthorityCode", "TechnicalStandardCode", "RegionalImplementationCode", "ProductDomainCode", "LifecycleContextCode", "ProductClassCode", "ProcedureContextCode", "SourcePresentationCode")
    For t = LBound(tableName) To UBound(tableName)
        Set lo = GetTableByName(CStr(tableName(t)))
        For i = 1 To lo.DataBodyRange.Rows.Count
            masterCodes(TextValue(RowValue(lo, i, CStr(codeColumn(t))))) = True
        Next i
    Next t
    For i = 1 To outputs.DataBodyRange.Rows.Count
        outputType = TextValue(RowValue(outputs, i, "OutputType"))
        outputCode = TextValue(RowValue(outputs, i, "OutputCode"))
        If outputType = "Finding" And Not findings.Exists(outputCode) Then
            AddValidationIssue issues, "SEM_OUTPUT_TARGET", "Error", "tblRuleOutputs", TextValue(RowValue(outputs, i, "RuleOutputId")), "OutputCode", "Finding output target does not exist."
        ElseIf outputType = "ClassificationCandidate" And identificationRules.Exists(TextValue(RowValue(outputs, i, "RuleId"))) Then
            ' Identification candidates are resolved within their declared TargetEntityType by ValidateIdentification.
        ElseIf outputType = "ClassificationCandidate" And Not masterCodes.Exists(outputCode) Then
            AddValidationIssue issues, "SEM_OUTPUT_TARGET", "Error", "tblRuleOutputs", TextValue(RowValue(outputs, i, "RuleOutputId")), "OutputCode", "Classification output target does not exist."
        End If
    Next i
End Sub

Private Function RuleIdsOfType(ByVal ruleType As String) As Object
    Dim rules As ListObject
    Dim i As Long
    Dim result As Object
    Set result = CreateObject("Scripting.Dictionary")
    Set rules = GetTableByName("tblRules")
    If Not rules Is Nothing Then
        If Not rules.DataBodyRange Is Nothing Then
            For i = 1 To rules.DataBodyRange.Rows.Count
                If TextValue(RowValue(rules, i, "RuleType")) = ruleType Then result(TextValue(RowValue(rules, i, "RuleId"))) = i
            Next i
        End If
    End If
    Set RuleIdsOfType = result
End Function

Private Function ListCodes(ByVal listName As String) As Object
    Dim lo As ListObject
    Dim i As Long
    Dim result As Object
    Set result = CreateObject("Scripting.Dictionary")
    Set lo = GetTableByName("tblValueLists")
    If Not lo Is Nothing Then
        If Not lo.DataBodyRange Is Nothing Then
            For i = 1 To lo.DataBodyRange.Rows.Count
                If TextValue(RowValue(lo, i, "ListName")) = listName Then result(TextValue(RowValue(lo, i, "Code"))) = RowValue(lo, i, "SortOrder")
            Next i
        End If
    End If
    Set ListCodes = result
End Function

Private Function EntityCodes(ByVal entityType As String) As Object
    Dim lo As ListObject
    Dim i As Long
    Dim tableName As String
    Dim codeColumn As String
    Dim result As Object
    Set result = CreateObject("Scripting.Dictionary")
    Select Case entityType
        Case "REGION": tableName = "tblRegions": codeColumn = "RegionCode"
        Case "AUTHORITY": tableName = "tblAuthorities": codeColumn = "AuthorityCode"
        Case "TECHNICAL_STANDARD": tableName = "tblTechnicalStandards": codeColumn = "TechnicalStandardCode"
        Case "REGIONAL_IMPLEMENTATION": tableName = "tblRegionalImplementations": codeColumn = "RegionalImplementationCode"
        Case "PRODUCT_DOMAIN": tableName = "tblProductDomains": codeColumn = "ProductDomainCode"
        Case "LIFECYCLE_CONTEXT": tableName = "tblLifecycleContexts": codeColumn = "LifecycleContextCode"
        Case "PRODUCT_CLASS": tableName = "tblProductClasses": codeColumn = "ProductClassCode"
        Case "PROCEDURE_CONTEXT": tableName = "tblProcedureContexts": codeColumn = "ProcedureContextCode"
        Case "SOURCE_PRESENTATION": tableName = "tblSourcePresentations": codeColumn = "SourcePresentationCode"
    End Select
    If Len(tableName) > 0 Then
        Set lo = GetTableByName(tableName)
        If Not lo Is Nothing Then
            If Not lo.DataBodyRange Is Nothing Then
                For i = 1 To lo.DataBodyRange.Rows.Count
                    result(TextValue(RowValue(lo, i, codeColumn))) = True
                Next i
            End If
        End If
    End If
    Set EntityCodes = result
End Function

Private Function StrengthRank(ByVal strength As String) As Long
    Select Case strength
        Case "STRONG": StrengthRank = 1
        Case "MEDIUM": StrengthRank = 2
        Case "WEAK": StrengthRank = 3
        Case Else: StrengthRank = 0
    End Select
End Function

Private Sub CheckControlled(ByRef issues As Collection, ByVal tableName As String, ByVal entityId As String, ByVal fieldName As String, ByVal value As String, ByVal listName As String)
    If Not ListCodes(listName).Exists(value) Then
        AddValidationIssue issues, "SEM_CONTROLLED_REFERENCE", "Error", tableName, entityId, fieldName, value & " does not resolve to " & listName & "."
    End If
End Sub

Private Sub CheckRequiredControlled(ByRef issues As Collection, ByVal tableName As String, ByVal entityId As String, ByVal fieldName As String, ByVal value As String, ByVal listName As String)
    If Len(value) = 0 Then
        AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_REQUIRED", "Error", tableName, entityId, fieldName, fieldName & " is required."
    Else
        CheckControlled issues, tableName, entityId, fieldName, value, listName
    End If
End Sub

Private Sub ValidateLifecycleAndLegacy(ByRef issues As Collection)
    Dim rules As ListObject
    Dim ruleIds As Object
    Dim i As Long
    Dim ruleId As String
    Dim status As String
    Dim legacyId As String
    Set rules = GetTableByName("tblRules")
    If rules Is Nothing Then Exit Sub
    If rules.DataBodyRange Is Nothing Then Exit Sub
    Set ruleIds = CreateObject("Scripting.Dictionary")
    For i = 1 To rules.DataBodyRange.Rows.Count
        ruleIds(TextValue(RowValue(rules, i, "RuleId"))) = True
    Next i
    For i = 1 To rules.DataBodyRange.Rows.Count
        ruleId = TextValue(RowValue(rules, i, "RuleId"))
        status = TextValue(RowValue(rules, i, "Status"))
        If Not IsInStringArray(status, Array("Draft", "InReview", "Reviewed", "Effective", "Superseded", "Retired")) Then
            AddValidationIssue issues, "POC_RULE_LIFECYCLE", "Error", "tblRules", ruleId, "Status", "Status is not a rule lifecycle status."
        End If
        If ruleId Like "R-REG-##" Or ruleId Like "R-FMT-##" Or ruleId Like "R-TYP-##" Then
            AddValidationIssue issues, "POC_LEGACY_RULE_ID_AS_RULE_ID", "Error", "tblRules", ruleId, "RuleId", "A historical mapping rule ID cannot be a governed runtime RuleId."
        End If
        legacyId = Trim$(TextValue(RowValue(rules, i, EMAS_WORKBOOK_ONLY_RULE_COLUMNS)))
        If Len(legacyId) > 0 Then
            If ruleIds.Exists(legacyId) Then
                AddValidationIssue issues, "POC_LEGACY_RULE_ID_AS_RULE_ID", "Error", "tblRules", ruleId, EMAS_WORKBOOK_ONLY_RULE_COLUMNS, "LegacyRuleId cannot substitute for a RuleId."
            End If
        End If
    Next i
End Sub

Private Sub ValidateIdentification(ByRef issues As Collection)
    Dim rules As ListObject
    Dim outputs As ListObject
    Dim conditions As ListObject
    Dim fields As ListObject
    Dim policies As ListObject
    Dim identificationRules As Object
    Dim dimensions As Object
    Dim strengths As Object
    Dim ceilings As Object
    Dim weakestCeiling As Object
    Dim conflictGroups As Object
    Dim i As Long
    Dim ruleId As String
    Dim entityId As String
    Dim fieldCode As String
    Dim target As String
    Dim strength As String
    Dim value As String

    Set identificationRules = RuleIdsOfType(EMAS_IDENTIFICATION_RULE_TYPE)
    Set dimensions = ListCodes("IDENTIFICATION_DIMENSION")
    Set strengths = ListCodes("EVIDENCE_STRENGTH")

    ' Ordinal STRONG > MEDIUM > WEAK must be carried by unique ascending SortOrder.
    If strengths.Count <> 3 Or Not strengths.Exists("STRONG") Or Not strengths.Exists("MEDIUM") Or Not strengths.Exists("WEAK") Then
        AddValidationIssue issues, "SEM_ORDINAL_ORDER", "Error", "tblValueLists", "EVIDENCE_STRENGTH", "Code", "EVIDENCE_STRENGTH must be STRONG, MEDIUM, WEAK."
    ElseIf IsBlankValue(strengths("STRONG")) Or IsBlankValue(strengths("MEDIUM")) Or IsBlankValue(strengths("WEAK")) Then
        AddValidationIssue issues, "SEM_ORDINAL_ORDER", "Error", "tblValueLists", "EVIDENCE_STRENGTH", "SortOrder", "EVIDENCE_STRENGTH SortOrder is required."
    ElseIf Not (CDbl(strengths("STRONG")) < CDbl(strengths("MEDIUM")) And CDbl(strengths("MEDIUM")) < CDbl(strengths("WEAK"))) Then
        AddValidationIssue issues, "SEM_ORDINAL_ORDER", "Error", "tblValueLists", "EVIDENCE_STRENGTH", "SortOrder", "SortOrder must be ascending STRONG > MEDIUM > WEAK."
    End If

    Set rules = GetTableByName("tblRules")
    Set conflictGroups = CreateObject("Scripting.Dictionary")
    For i = 1 To rules.DataBodyRange.Rows.Count
        ruleId = TextValue(RowValue(rules, i, "RuleId"))
        If identificationRules.Exists(ruleId) Then
            CheckControlled issues, "tblRules", ruleId, "RuleType", EMAS_IDENTIFICATION_RULE_TYPE, "RULE_TYPE"
            target = TextValue(RowValue(rules, i, "ConflictGroup"))
            conflictGroups(ruleId) = target
            If Not dimensions.Exists(target) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_DIMENSION", "Error", "tblRules", ruleId, "ConflictGroup", "ConflictGroup is not an approved IDENTIFICATION_DIMENSION."
            End If
        End If
    Next i

    Set fields = GetTableByName("tblFieldCatalogue")
    Set ceilings = CreateObject("Scripting.Dictionary")
    For i = 1 To fields.DataBodyRange.Rows.Count
        value = TextValue(RowValue(fields, i, "MaxEvidenceStrength"))
        If Len(value) > 0 Then
            CheckControlled issues, "tblFieldCatalogue", TextValue(RowValue(fields, i, "FieldCode")), "MaxEvidenceStrength", value, "EVIDENCE_STRENGTH"
            ceilings(TextValue(RowValue(fields, i, "FieldCode"))) = value
        End If
    Next i

    ' Weakest ceiling across every positive (non-negated) evidence condition of each Identification rule.
    Set conditions = GetTableByName("tblRuleConditions")
    Set weakestCeiling = CreateObject("Scripting.Dictionary")
    For i = 1 To conditions.DataBodyRange.Rows.Count
        ruleId = TextValue(RowValue(conditions, i, "RuleId"))
        If identificationRules.Exists(ruleId) And Not CBool(RowValue(conditions, i, "Negate")) Then
            fieldCode = TextValue(RowValue(conditions, i, "FieldCode"))
            If Not ceilings.Exists(fieldCode) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_REQUIRED", "Error", "tblFieldCatalogue", fieldCode, "MaxEvidenceStrength", "Identification evidence field requires MaxEvidenceStrength."
            ElseIf Not weakestCeiling.Exists(ruleId) Then
                weakestCeiling(ruleId) = ceilings(fieldCode)
            ElseIf StrengthRank(CStr(ceilings(fieldCode))) > StrengthRank(CStr(weakestCeiling(ruleId))) Then
                weakestCeiling(ruleId) = ceilings(fieldCode)
            End If
        End If
    Next i

    Set outputs = GetTableByName("tblRuleOutputs")
    For i = 1 To outputs.DataBodyRange.Rows.Count
        ruleId = TextValue(RowValue(outputs, i, "RuleId"))
        entityId = TextValue(RowValue(outputs, i, "RuleOutputId"))
        target = TextValue(RowValue(outputs, i, "TargetEntityType"))
        strength = TextValue(RowValue(outputs, i, "EvidenceStrength"))
        value = TextValue(RowValue(outputs, i, "EvidencePolarity"))
        If identificationRules.Exists(ruleId) And TextValue(RowValue(outputs, i, "OutputType")) = "ClassificationCandidate" Then
            If Len(target) = 0 Or Len(strength) = 0 Or Len(value) = 0 Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_REQUIRED", "Error", "tblRuleOutputs", entityId, "TargetEntityType", "Identification candidate requires TargetEntityType, EvidenceStrength and EvidencePolarity."
            End If
            If Not IsBlankValue(RowValue(outputs, i, "OutputValue")) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_NUMERIC_WEIGHT", "Error", "tblRuleOutputs", entityId, "OutputValue", "Identification candidates carry no numeric score."
            End If
            If Len(target) > 0 Then
                If Not dimensions.Exists(target) Then
                    AddValidationIssue issues, "SEM_IDENTIFICATION_DIMENSION", "Error", "tblRuleOutputs", entityId, "TargetEntityType", "TargetEntityType is not an approved IDENTIFICATION_DIMENSION."
                Else
                    If target <> CStr(conflictGroups(ruleId)) Then
                        AddValidationIssue issues, "SEM_IDENTIFICATION_DIMENSION_MISMATCH", "Error", "tblRuleOutputs", entityId, "TargetEntityType", "TargetEntityType differs from the rule ConflictGroup."
                    End If
                    If Not EntityCodes(target).Exists(TextValue(RowValue(outputs, i, "OutputCode"))) Then
                        AddValidationIssue issues, "SEM_OUTPUT_TARGET", "Error", "tblRuleOutputs", entityId, "OutputCode", "Candidate code does not exist in its TargetEntityType."
                    End If
                End If
            End If
            If Len(value) > 0 Then CheckControlled issues, "tblRuleOutputs", entityId, "EvidencePolarity", value, "EVIDENCE_POLARITY"
            If Len(strength) > 0 Then
                If Not strengths.Exists(strength) Then
                    CheckControlled issues, "tblRuleOutputs", entityId, "EvidenceStrength", strength, "EVIDENCE_STRENGTH"
                ElseIf Not weakestCeiling.Exists(ruleId) Then
                    AddValidationIssue issues, "SEM_EVIDENCE_STRENGTH_CEILING", "Error", "tblRuleOutputs", entityId, "EvidenceStrength", "Rule has no positive evidence field."
                ElseIf StrengthRank(strength) < StrengthRank(CStr(weakestCeiling(ruleId))) Then
                    AddValidationIssue issues, "SEM_EVIDENCE_STRENGTH_CEILING", "Error", "tblRuleOutputs", entityId, "EvidenceStrength", "EvidenceStrength exceeds the evidence-field ceiling."
                End If
            End If
        ElseIf Len(target) > 0 Or Len(strength) > 0 Or Len(value) > 0 Then
            AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_SCOPE", "Error", "tblRuleOutputs", entityId, "TargetEntityType", "Identification metadata is only valid on IDENTIFICATION ClassificationCandidate outputs."
        End If
    Next i

    Set policies = GetTableByName("tblConflictPolicies")
    For i = 1 To policies.DataBodyRange.Rows.Count
        entityId = TextValue(RowValue(policies, i, "ConflictPolicyId"))
        value = TextValue(RowValue(policies, i, "MinimumEvidenceStrengthForValue"))
        If TextValue(RowValue(policies, i, "RuleType")) = EMAS_IDENTIFICATION_RULE_TYPE Then
            CheckControlled issues, "tblConflictPolicies", entityId, "RuleType", EMAS_IDENTIFICATION_RULE_TYPE, "RULE_TYPE"
            CheckControlled issues, "tblConflictPolicies", entityId, "TieBehavior", TextValue(RowValue(policies, i, "TieBehavior")), "TIE_BEHAVIOR"
            If Len(value) > 0 Then CheckControlled issues, "tblConflictPolicies", entityId, "MinimumEvidenceStrengthForValue", value, "EVIDENCE_STRENGTH"
        ElseIf Len(value) > 0 Then
            AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_SCOPE", "Error", "tblConflictPolicies", entityId, "MinimumEvidenceStrengthForValue", "Only valid on IDENTIFICATION conflict policies."
        End If
    Next i

    Set policies = GetTableByName("tblConfidencePolicies")
    For i = 1 To policies.DataBodyRange.Rows.Count
        entityId = TextValue(RowValue(policies, i, "ConfidencePolicyId"))
        If TextValue(RowValue(policies, i, "Scope")) = EMAS_IDENTIFICATION_RULE_TYPE Then
            CheckControlled issues, "tblConfidencePolicies", entityId, "EvidenceStrength", TextValue(RowValue(policies, i, "EvidenceStrength")), "EVIDENCE_STRENGTH"
            CheckRequiredControlled issues, "tblConfidencePolicies", entityId, "ResultConfidence", TextValue(RowValue(policies, i, "ResultConfidence")), "CONFIDENCE"
            CheckRequiredControlled issues, "tblConfidencePolicies", entityId, "CorroborationRule", TextValue(RowValue(policies, i, "CorroborationRule")), "CORROBORATION_RULE"
            If Not IsBlankValue(RowValue(policies, i, "WeightOrScore")) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_NUMERIC_WEIGHT", "Error", "tblConfidencePolicies", entityId, "WeightOrScore", "Numeric Identification confidence weights are not approved."
            End If
        Else
            If Not IsBlankValue(RowValue(policies, i, "ResultConfidence")) Or Not IsBlankValue(RowValue(policies, i, "CorroborationRule")) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_SCOPE", "Error", "tblConfidencePolicies", entityId, "ResultConfidence", "Only valid on IDENTIFICATION confidence policies."
            End If
            If IsBlankValue(RowValue(policies, i, "WeightOrScore")) Then
                AddValidationIssue issues, "SEM_IDENTIFICATION_METADATA_REQUIRED", "Error", "tblConfidencePolicies", entityId, "WeightOrScore", "Non-Identification confidence rows keep the numeric weight."
            End If
        End If
    Next i
End Sub

Private Sub ValidateControlledMetadata(ByRef issues As Collection)
    Dim lo As ListObject
    Set lo = GetTableByName("tblConfiguration")
    If lo Is Nothing Then Exit Sub
    If lo.DataBodyRange Is Nothing Then Exit Sub
    If TextValue(RowValue(lo, 1, "ExportType")) <> "CONTROLLED" Then Exit Sub
    CheckRequiredValue issues, lo, "Status", "Effective"
    CheckRequiredValue issues, lo, "EffectiveFrom", vbNullString
    CheckRequiredValue issues, lo, "ApprovalReference", vbNullString
    CheckRequiredValue issues, lo, "ReleaseManifestReference", vbNullString
    CheckRequiredValue issues, lo, "ChecksumAlgorithm", "SHA-256"
    CheckRequiredValue issues, lo, "ChecksumValue", vbNullString
    CheckRequiredValue issues, lo, "ChecksumScope", "CanonicalConfigurationExcludingChecksumFields"
End Sub

Private Sub CheckRequiredValue(ByRef issues As Collection, ByVal lo As ListObject, ByVal columnName As String, ByVal exactValue As String)
    Dim value As String
    value = TextValue(RowValue(lo, 1, columnName))
    If Len(exactValue) > 0 Then
        If value <> exactValue Then AddValidationIssue issues, "POC_CONTROLLED_METADATA", "Error", "tblConfiguration", "EMAS_POC", columnName, "Controlled metadata has an invalid value."
    ElseIf Len(Trim$(value)) = 0 Then
        AddValidationIssue issues, "POC_CONTROLLED_METADATA", "Error", "tblConfiguration", "EMAS_POC", columnName, "Controlled metadata is required."
    End If
End Sub

Private Sub WriteValidationResults(ByVal issues As Collection)
    Dim lo As ListObject
    Dim issue As Variant
    Dim lr As ListRow
    Set lo = GetTableByName(EMAS_VALIDATION_TABLE)
    If lo Is Nothing Then Exit Sub
    If Not lo.DataBodyRange Is Nothing Then lo.DataBodyRange.Delete
    For Each issue In issues
        Set lr = lo.ListRows.Add
        lr.Range.Cells(1, lo.ListColumns("ValidationRunId").Index).Value2 = NewValidationRunId()
        lr.Range.Cells(1, lo.ListColumns("Severity").Index).Value2 = issue("Severity")
        lr.Range.Cells(1, lo.ListColumns("ErrorCode").Index).Value2 = issue("ErrorCode")
        lr.Range.Cells(1, lo.ListColumns("EntityType").Index).Value2 = issue("EntityType")
        lr.Range.Cells(1, lo.ListColumns("EntityId").Index).Value2 = issue("EntityId")
        lr.Range.Cells(1, lo.ListColumns("FieldName").Index).Value2 = issue("FieldName")
        lr.Range.Cells(1, lo.ListColumns("Message").Index).Value2 = issue("Message")
        lr.Range.Cells(1, lo.ListColumns("CreatedAtUtc").Index).Value2 = UtcNowIso()
    Next issue
End Sub
