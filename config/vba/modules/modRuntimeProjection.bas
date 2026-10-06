Attribute VB_Name = "modRuntimeProjection"
Option Explicit

' Central runtime-eligibility projection used by every Runtime JSON export (DEV and CONTROLLED).
' Runtime eligible = Status = Effective AND EffectiveFrom <= evaluation date
'                    AND (EffectiveTo is empty OR evaluation date < EffectiveTo).
' A non-eligible rule is excluded together with its phases, condition groups, conditions,
' outputs and RULE_SUPERSESSION relationships. Workbook-only columns are never serialized.

Public Function RuntimeEvaluationDate(ByVal deterministic As Boolean) As String
    If deterministic Then
        RuntimeEvaluationDate = EMAS_POC_EVALUATION_DATE
    Else
        RuntimeEvaluationDate = Left$(UtcNowIso(), 10)
    End If
End Function

Public Function IsoDateText(ByVal value As Variant) As String
    If IsBlankValue(value) Then
        IsoDateText = vbNullString
    ElseIf VarType(value) = vbDate Then
        IsoDateText = Format$(value, "yyyy-mm-dd")
    ElseIf VarType(value) = vbDouble Then
        IsoDateText = Format$(CDate(value), "yyyy-mm-dd")
    Else
        IsoDateText = Left$(Trim$(TextValue(value)), 10)
    End If
End Function

Public Function IsRuntimeEligibleRule(ByVal rules As ListObject, ByVal rowIndex As Long, ByVal evaluationDate As String) As Boolean
    Dim startDate As String
    Dim endDate As String
    If StrComp(TextValue(RowValue(rules, rowIndex, "Status")), EMAS_RUNTIME_STATUS, vbBinaryCompare) <> 0 Then Exit Function
    startDate = IsoDateText(RowValue(rules, rowIndex, "EffectiveFrom"))
    If Len(startDate) = 0 Or StrComp(startDate, evaluationDate, vbBinaryCompare) > 0 Then Exit Function
    endDate = IsoDateText(RowValue(rules, rowIndex, "EffectiveTo"))
    If Len(endDate) > 0 Then
        If StrComp(evaluationDate, endDate, vbBinaryCompare) >= 0 Then Exit Function
    End If
    IsRuntimeEligibleRule = True
End Function

Public Function RuntimeEligibleRuleIds(ByVal evaluationDate As String) As Object
    Dim eligible As Object
    Dim rules As ListObject
    Dim i As Long
    Set eligible = CreateObject("Scripting.Dictionary")
    Set rules = GetTableByName("tblRules")
    If Not rules Is Nothing Then
        If Not rules.DataBodyRange Is Nothing Then
            For i = 1 To rules.DataBodyRange.Rows.Count
                If IsRuntimeEligibleRule(rules, i, evaluationDate) Then eligible(TextValue(RowValue(rules, i, "RuleId"))) = True
            Next i
        End If
    End If
    Set RuntimeEligibleRuleIds = eligible
End Function

Public Function RowBelongsToRuntimeRule(ByVal lo As ListObject, ByVal rowIndex As Long, ByVal eligible As Object) As Boolean
    RowBelongsToRuntimeRule = eligible.Exists(TextValue(RowValue(lo, rowIndex, "RuleId")))
End Function

Public Function RelationshipIsRuntime(ByVal lo As ListObject, ByVal rowIndex As Long, ByVal eligible As Object) As Boolean
    If TextValue(RowValue(lo, rowIndex, "RelationshipType")) <> "RULE_SUPERSESSION" Then
        RelationshipIsRuntime = True
    Else
        RelationshipIsRuntime = eligible.Exists(TextValue(RowValue(lo, rowIndex, "SourceEntityCode"))) And _
                                eligible.Exists(TextValue(RowValue(lo, rowIndex, "TargetEntityCode")))
    End If
End Function

Public Sub AssertRuntimeJsonHasNoLegacyRuleId(ByVal jsonText As String)
    Dim rules As ListObject
    Dim i As Long
    Dim legacyValue As String
    If InStr(1, jsonText, Chr$(34) & "legacyRuleId" & Chr$(34), vbTextCompare) > 0 Then
        Err.Raise vbObjectError + 2301, "AssertRuntimeJsonHasNoLegacyRuleId", "POC_LEGACY_RULE_ID_EXPORTED: workbook-only LegacyRuleId property was serialized."
    End If
    Set rules = GetTableByName("tblRules")
    If rules Is Nothing Then Exit Sub
    If rules.DataBodyRange Is Nothing Then Exit Sub
    If Not ColumnExists(rules, EMAS_WORKBOOK_ONLY_RULE_COLUMNS) Then Exit Sub
    For i = 1 To rules.DataBodyRange.Rows.Count
        legacyValue = Trim$(TextValue(RowValue(rules, i, EMAS_WORKBOOK_ONLY_RULE_COLUMNS)))
        If Len(legacyValue) > 0 Then
            If InStr(1, jsonText, JsonEscape(legacyValue), vbBinaryCompare) > 0 Then
                Err.Raise vbObjectError + 2302, "AssertRuntimeJsonHasNoLegacyRuleId", "POC_LEGACY_RULE_ID_EXPORTED: a LegacyRuleId value was serialized."
            End If
        End If
    Next i
End Sub
