Attribute VB_Name = "modUtilities"
Option Explicit

#If VBA7 Then
    Private Declare PtrSafe Sub GetSystemTime Lib "kernel32" (ByRef lpSystemTime As SYSTEMTIME)
#Else
    Private Declare Sub GetSystemTime Lib "kernel32" (ByRef lpSystemTime As SYSTEMTIME)
#End If

Private Type SYSTEMTIME
    wYear As Integer
    wMonth As Integer
    wDayOfWeek As Integer
    wDay As Integer
    wHour As Integer
    wMinute As Integer
    wSecond As Integer
    wMilliseconds As Integer
End Type

Public Function GetTableByName(ByVal tableName As String) As ListObject
    Dim ws As Worksheet
    Dim lo As ListObject
    For Each ws In ThisWorkbook.Worksheets
        Set lo = Nothing
        On Error Resume Next
        Set lo = ws.ListObjects(tableName)
        On Error GoTo 0
        If Not lo Is Nothing Then
            Set GetTableByName = lo
            Exit Function
        End If
    Next ws
    Set GetTableByName = Nothing
End Function

Public Function ColumnExists(ByVal lo As ListObject, ByVal columnName As String) As Boolean
    Dim lc As ListColumn
    On Error Resume Next
    Set lc = lo.ListColumns(columnName)
    ColumnExists = Not lc Is Nothing
    Set lc = Nothing
    On Error GoTo 0
End Function

Public Function RowValue(ByVal lo As ListObject, ByVal rowIndex As Long, ByVal columnName As String) As Variant
    If lo.DataBodyRange Is Nothing Then
        RowValue = Empty
        Exit Function
    End If
    RowValue = lo.DataBodyRange.Cells(rowIndex, lo.ListColumns(columnName).Index).Value2
End Function

Public Function TextValue(ByVal value As Variant) As String
    If IsError(value) Or IsNull(value) Or IsEmpty(value) Then
        TextValue = vbNullString
    Else
        TextValue = CStr(value)
    End If
End Function

Public Function IsBlankValue(ByVal value As Variant) As Boolean
    IsBlankValue = Len(Trim$(TextValue(value))) = 0
End Function

Public Function JsonEscape(ByVal value As String) As String
    Dim result As String
    Dim i As Long
    Dim ch As String
    Dim code As Long
    result = vbNullString
    For i = 1 To Len(value)
        ch = Mid$(value, i, 1)
        code = AscW(ch)
        Select Case ch
            Case Chr$(34): result = result & Chr$(92) & Chr$(34)
            Case Chr$(92): result = result & Chr$(92) & Chr$(92)
            Case Chr$(8): result = result & "\b"
            Case Chr$(12): result = result & "\f"
            Case vbCr: result = result & "\r"
            Case vbLf: result = result & "\n"
            Case vbTab: result = result & "\t"
            Case Else
                If code >= 0 And code < 32 Then
                    result = result & "\u" & Right$("0000" & Hex$(code), 4)
                Else
                    result = result & ch
                End If
        End Select
    Next i
    JsonEscape = result
End Function

Public Function JsonString(ByVal value As String) As String
    JsonString = Chr$(34) & JsonEscape(value) & Chr$(34)
End Function

Public Function ToCamelCase(ByVal headerName As String) As String
    Select Case headerName
        Case "RAG": ToCamelCase = "rag"
        Case "DefaultRAG": ToCamelCase = "defaultRag"
        Case "RagPolicyId": ToCamelCase = "ragPolicyId"
        Case Else: ToCamelCase = LCase$(Left$(headerName, 1)) & Mid$(headerName, 2)
    End Select
End Function

Public Function IsBooleanHeader(ByVal headerName As String) As Boolean
    Select Case headerName
        Case "IsSensitive", "RequiredForCompleteBanding", "IsMandatory", _
             "StopProcessing", "IsBlocker", "ExceptionEligible", _
             "CaseSensitive", "Negate", "CustomerVisible", "ExpiryRequired", _
             "CarryForwardToPostMigration", "MinimumBandOverrideEligible", _
             "LowerInclusive", "UpperInclusive", "MandatoryBlockerOverride", "Required"
            IsBooleanHeader = True
    End Select
End Function

Public Function IsNumberHeader(ByVal headerName As String) As Boolean
    Select Case headerName
        Case "EvaluationOrder", "RuleRevision", "Priority", "Specificity", _
             "Sequence", "GroupSequence", "DefaultPriorityIncrement", _
             "MaximumValidityDays", "WeightOrScore", "Weight", "Cap", "Floor", _
             "LowerBound", "UpperBound", "OutputValue"
            IsNumberHeader = True
    End Select
End Function

Public Function InvariantNumber(ByVal value As Variant) As String
    Dim text As String
    text = CStr(value)
    text = Replace(text, Application.International(xlThousandsSeparator), vbNullString)
    text = Replace(text, Application.International(xlDecimalSeparator), ".")
    InvariantNumber = text
End Function

Public Function JsonScalar(ByVal value As Variant, ByVal headerName As String, Optional ByVal explicitDataType As String = vbNullString) As String
    If IsBlankValue(value) Then
        JsonScalar = "null"
        Exit Function
    End If
    If explicitDataType = "Boolean" Or IsBooleanHeader(headerName) Then
        JsonScalar = IIf(CBool(value), "true", "false")
    ElseIf explicitDataType = "Integer" Or explicitDataType = "Decimal" Or IsNumberHeader(headerName) Then
        JsonScalar = InvariantNumber(value)
    Else
        JsonScalar = JsonString(TextValue(value))
    End If
End Function

Public Function UtcNowIso() As String
    Dim st As SYSTEMTIME
    GetSystemTime st
    UtcNowIso = Format$(st.wYear, "0000") & "-" & Format$(st.wMonth, "00") & "-" & _
                Format$(st.wDay, "00") & "T" & Format$(st.wHour, "00") & ":" & _
                Format$(st.wMinute, "00") & ":" & Format$(st.wSecond, "00") & "Z"
End Function

Public Function NewValidationRunId() As String
    NewValidationRunId = "VAL-" & Replace(Replace(Replace(UtcNowIso(), "-", vbNullString), ":", vbNullString), "T", "-")
    NewValidationRunId = Replace(NewValidationRunId, "Z", vbNullString)
End Function

Public Function JsonArrayFromCollection(ByVal values As Collection) As String
    Dim i As Long
    Dim result As String
    result = "["
    For i = 1 To values.Count
        If i > 1 Then result = result & ","
        result = result & CStr(values(i))
    Next i
    JsonArrayFromCollection = result & "]"
End Function

Public Function IsInStringArray(ByVal value As String, ByVal values As Variant) As Boolean
    Dim item As Variant
    For Each item In values
        If StrComp(value, CStr(item), vbTextCompare) = 0 Then
            IsInStringArray = True
            Exit Function
        End If
    Next item
End Function

Public Function JoinCollection(ByVal values As Collection, ByVal delimiter As String) As String
    Dim i As Long
    Dim result As String
    For i = 1 To values.Count
        If i > 1 Then result = result & delimiter
        result = result & CStr(values(i))
    Next i
    JoinCollection = result
End Function
