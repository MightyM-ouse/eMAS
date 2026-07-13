Attribute VB_Name = "modJsonBuilder"
Option Explicit

Public Function BuildRuntimeJson(Optional ByVal deterministic As Boolean = False) As String
    Dim properties As New Collection
    properties.Add JsonString("configuration") & ":" & BuildConfigurationJson(deterministic)
    properties.Add JsonString("valueLists") & ":" & BuildValueListsJson()
    properties.Add JsonString("fieldCatalogue") & ":" & BuildFieldCatalogueJson()
    properties.Add JsonString("metricCatalogue") & ":" & BuildMetricCatalogueJson()
    properties.Add JsonString("masterData") & ":" & BuildMasterDataJson()
    properties.Add JsonString("relationships") & ":" & BuildTableArray("tblMasterDataRelationships")
    properties.Add JsonString("rules") & ":" & BuildTableArray("tblRules")
    properties.Add JsonString("rulePhases") & ":" & BuildTableArray("tblRulePhaseAssignments")
    properties.Add JsonString("conditionGroups") & ":" & BuildTableArray("tblConditionGroups")
    properties.Add JsonString("ruleConditions") & ":" & BuildTableArray("tblRuleConditions")
    properties.Add JsonString("ruleOutputs") & ":" & BuildTableArray("tblRuleOutputs")
    properties.Add JsonString("findings") & ":" & BuildTableArray("tblFindings")
    properties.Add JsonString("recommendations") & ":" & BuildTableArray("tblRecommendations")
    properties.Add JsonString("findingRecommendationLinks") & ":" & BuildTableArray("tblFindingRecommendationLinks")
    properties.Add JsonString("exceptionPolicies") & ":" & BuildTableArray("tblExceptionPolicies")
    properties.Add JsonString("aliases") & ":" & BuildTableArray("tblAliases")
    properties.Add JsonString("policies") & ":" & BuildPoliciesJson()
    properties.Add JsonString("questionnaireMap") & ":" & BuildTableArray("tblQuestionnaireMap")
    properties.Add JsonString("reportTerminology") & ":" & BuildReportTerminologyJson()
    BuildRuntimeJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildConfigurationJson(ByVal deterministic As Boolean) As String
    Dim lo As ListObject
    Dim properties As New Collection
    Dim lc As ListColumn
    Dim headerName As String
    Dim value As Variant
    Set lo = GetTableByName("tblConfiguration")
    For Each lc In lo.ListColumns
        headerName = lc.Name
        value = RowValue(lo, 1, headerName)
        Select Case headerName
            Case "ExportedAtUtc"
                value = IIf(deterministic, EMAS_POC_FIXED_UTC, UtcNowIso())
            Case "ExportedBy"
                value = IIf(deterministic, EMAS_POC_EXPORTED_BY, Environ$("USERNAME"))
            Case "ValidationRunId"
                value = IIf(deterministic, EMAS_POC_VALIDATION_RUN_ID, NewValidationRunId())
        End Select
        If Not IsBlankValue(value) Then
            properties.Add JsonString(ToCamelCase(headerName)) & ":" & JsonScalar(value, headerName)
        End If
    Next lc
    BuildConfigurationJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildValueListsJson() As String
    Dim lo As ListObject
    Dim listNames As Object
    Dim listOrder As New Collection
    Dim i As Long
    Dim listName As String
    Dim properties As New Collection
    Dim items As New Collection
    Dim item As Variant
    Set lo = GetTableByName("tblValueLists")
    Set listNames = CreateObject("Scripting.Dictionary")
    For i = 1 To lo.DataBodyRange.Rows.Count
        listName = TextValue(RowValue(lo, i, "ListName"))
        If Not listNames.Exists(listName) Then
            listNames.Add listName, True
            listOrder.Add listName
        End If
    Next i
    For Each item In listOrder
        Set items = New Collection
        For i = 1 To lo.DataBodyRange.Rows.Count
            If TextValue(RowValue(lo, i, "ListName")) = CStr(item) Then
                items.Add BuildRowObject(lo, i, Array("ListName"))
            End If
        Next i
        properties.Add JsonString(CStr(item)) & ":" & JsonArrayFromCollection(items)
    Next item
    BuildValueListsJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildFieldCatalogueJson() As String
    Dim lo As ListObject
    Dim items As New Collection
    Dim i As Long
    Dim code As String
    Dim baseProperties As String
    Set lo = GetTableByName("tblFieldCatalogue")
    For i = 1 To lo.DataBodyRange.Rows.Count
        code = TextValue(RowValue(lo, i, "FieldCode"))
        baseProperties = BuildRowProperties(lo, i, Empty)
        baseProperties = baseProperties & "," & JsonString("allowedOperators") & ":" & BuildLinkStringArray("tblFieldAllowedOperators", "FieldCode", code, "Operator")
        baseProperties = baseProperties & "," & JsonString("supportedPhases") & ":" & BuildLinkStringArray("tblFieldPhases", "FieldCode", code, "Phase")
        items.Add "{" & baseProperties & "}"
    Next i
    BuildFieldCatalogueJson = JsonArrayFromCollection(items)
End Function

Private Function BuildMetricCatalogueJson() As String
    Dim lo As ListObject
    Dim items As New Collection
    Dim i As Long
    Dim code As String
    Dim baseProperties As String
    Set lo = GetTableByName("tblMetricCatalogue")
    For i = 1 To lo.DataBodyRange.Rows.Count
        code = TextValue(RowValue(lo, i, "MetricCode"))
        baseProperties = BuildRowProperties(lo, i, Empty)
        baseProperties = baseProperties & "," & JsonString("supportedPhases") & ":" & BuildLinkStringArray("tblMetricPhases", "MetricCode", code, "Phase")
        items.Add "{" & baseProperties & "}"
    Next i
    BuildMetricCatalogueJson = JsonArrayFromCollection(items)
End Function

Private Function BuildMasterDataJson() As String
    Dim properties As New Collection
    properties.Add JsonString("regions") & ":" & BuildTableArray("tblRegions")
    properties.Add JsonString("authorities") & ":" & BuildTableArray("tblAuthorities")
    properties.Add JsonString("technicalStandards") & ":" & BuildTableArray("tblTechnicalStandards")
    properties.Add JsonString("regionalImplementations") & ":" & BuildTableArray("tblRegionalImplementations")
    properties.Add JsonString("productDomains") & ":" & BuildTableArray("tblProductDomains")
    properties.Add JsonString("lifecycleContexts") & ":" & BuildTableArray("tblLifecycleContexts")
    properties.Add JsonString("productClasses") & ":" & BuildTableArray("tblProductClasses")
    properties.Add JsonString("procedureContexts") & ":" & BuildTableArray("tblProcedureContexts")
    properties.Add JsonString("sourcePresentations") & ":" & BuildTableArray("tblSourcePresentations")
    BuildMasterDataJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildPoliciesJson() As String
    Dim properties As New Collection
    properties.Add JsonString("conflictPolicies") & ":" & BuildTableArray("tblConflictPolicies")
    properties.Add JsonString("ragPolicies") & ":" & BuildTableArray("tblRagPolicies")
    properties.Add JsonString("confidencePolicies") & ":" & BuildTableArray("tblConfidencePolicies")
    properties.Add JsonString("effortDrivers") & ":" & BuildEffortDriversJson()
    properties.Add JsonString("effortThresholds") & ":" & BuildTableArray("tblEffortThresholds")
    properties.Add JsonString("decisionPolicies") & ":" & BuildTableArray("tblDecisionPolicies")
    BuildPoliciesJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildEffortDriversJson() As String
    Dim lo As ListObject
    Dim items As New Collection
    Dim i As Long
    Dim driverId As String
    Dim baseProperties As String
    Set lo = GetTableByName("tblEffortDriverDefinitions")
    For i = 1 To lo.DataBodyRange.Rows.Count
        driverId = TextValue(RowValue(lo, i, "EffortDriverId"))
        baseProperties = BuildRowProperties(lo, i, Empty)
        baseProperties = baseProperties & "," & JsonString("supportedPhases") & ":" & BuildLinkStringArray("tblEffortDriverPhases", "EffortDriverId", driverId, "Phase")
        items.Add "{" & baseProperties & "}"
    Next i
    BuildEffortDriversJson = JsonArrayFromCollection(items)
End Function

Private Function BuildReportTerminologyJson() As String
    Dim properties As New Collection
    properties.Add JsonString("definitions") & ":" & BuildTableArray("tblReportDefinitions")
    properties.Add JsonString("phaseResults") & ":" & BuildPhaseResultsJson()
    BuildReportTerminologyJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Private Function BuildPhaseResultsJson() As String
    Dim phases As Variant
    Dim phase As Variant
    Dim properties As New Collection
    Dim lo As ListObject
    Dim items As New Collection
    Dim i As Long
    phases = Array("PRE_SALES", "PRE_MIGRATION", "POST_MIGRATION")
    Set lo = GetTableByName("tblPhaseResults")
    For Each phase In phases
        Set items = New Collection
        For i = 1 To lo.DataBodyRange.Rows.Count
            If TextValue(RowValue(lo, i, "Phase")) = CStr(phase) Then
                items.Add BuildRowObject(lo, i, Array("Phase"))
            End If
        Next i
        properties.Add JsonString(CStr(phase)) & ":" & JsonArrayFromCollection(items)
    Next phase
    BuildPhaseResultsJson = "{" & JoinCollection(properties, ",") & "}"
End Function

Public Function BuildTableArray(ByVal tableName As String, Optional ByVal excludedHeaders As Variant) As String
    Dim lo As ListObject
    Dim items As New Collection
    Dim i As Long
    Set lo = GetTableByName(tableName)
    If lo Is Nothing Then
        BuildTableArray = "[]"
        Exit Function
    End If
    If lo.DataBodyRange Is Nothing Then
        BuildTableArray = "[]"
        Exit Function
    End If
    For i = 1 To lo.DataBodyRange.Rows.Count
        If RowHasValues(lo, i) Then items.Add BuildRowObject(lo, i, excludedHeaders)
    Next i
    BuildTableArray = JsonArrayFromCollection(items)
End Function

Private Function BuildRowObject(ByVal lo As ListObject, ByVal rowIndex As Long, ByVal excludedHeaders As Variant) As String
    BuildRowObject = "{" & BuildRowProperties(lo, rowIndex, excludedHeaders) & "}"
End Function

Private Function BuildRowProperties(ByVal lo As ListObject, ByVal rowIndex As Long, ByVal excludedHeaders As Variant) As String
    Dim properties As New Collection
    Dim lc As ListColumn
    Dim headerName As String
    Dim value As Variant
    Dim dataType As String
    For Each lc In lo.ListColumns
        headerName = lc.Name
        If Not HeaderIsExcluded(headerName, excludedHeaders) Then
            value = RowValue(lo, rowIndex, headerName)
            If Not IsBlankValue(value) Then
                dataType = vbNullString
                If lo.Name = "tblRuleConditions" And (headerName = "Value1" Or headerName = "Value2") Then
                    dataType = TextValue(RowValue(lo, rowIndex, "ValueDataType"))
                End If
                properties.Add JsonString(ToCamelCase(headerName)) & ":" & JsonScalar(value, headerName, dataType)
            End If
        End If
    Next lc
    BuildRowProperties = JoinCollection(properties, ",")
End Function

Private Function HeaderIsExcluded(ByVal headerName As String, ByVal excludedHeaders As Variant) As Boolean
    If IsEmpty(excludedHeaders) Then Exit Function
    HeaderIsExcluded = IsInStringArray(headerName, excludedHeaders)
End Function

Private Function BuildLinkStringArray(ByVal tableName As String, ByVal filterColumn As String, ByVal filterValue As String, ByVal valueColumn As String) As String
    Dim lo As ListObject
    Dim values As New Collection
    Dim i As Long
    Set lo = GetTableByName(tableName)
    If lo Is Nothing Then
        BuildLinkStringArray = "[]"
        Exit Function
    End If
    If lo.DataBodyRange Is Nothing Then
        BuildLinkStringArray = "[]"
        Exit Function
    End If
    For i = 1 To lo.DataBodyRange.Rows.Count
        If TextValue(RowValue(lo, i, filterColumn)) = filterValue Then
            values.Add JsonString(TextValue(RowValue(lo, i, valueColumn)))
        End If
    Next i
    BuildLinkStringArray = JsonArrayFromCollection(values)
End Function

Private Function RowHasValues(ByVal lo As ListObject, ByVal rowIndex As Long) As Boolean
    Dim lc As ListColumn
    For Each lc In lo.ListColumns
        If Not IsBlankValue(RowValue(lo, rowIndex, lc.Name)) Then
            RowHasValues = True
            Exit Function
        End If
    Next lc
End Function
