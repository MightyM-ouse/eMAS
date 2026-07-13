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
        ElseIf outputType = "ClassificationCandidate" And Not masterCodes.Exists(outputCode) Then
            AddValidationIssue issues, "SEM_OUTPUT_TARGET", "Error", "tblRuleOutputs", TextValue(RowValue(outputs, i, "RuleOutputId")), "OutputCode", "Classification output target does not exist."
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
