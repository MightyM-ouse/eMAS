Attribute VB_Name = "modMain"
Option Explicit

Public Sub eMAS_ValidateWorkbook()
    Dim issues As Collection
    Set issues = ValidateWorkbook(True)
    If HasErrorIssues(issues) Then
        MsgBox "Validation failed. Review the Validation_Results table.", vbCritical, "eMAS POC"
    Else
        MsgBox "Validation passed with " & CStr(issues.Count) & " recorded issue(s).", vbInformation, "eMAS POC"
    End If
End Sub

Public Function eMAS_ValidateWorkbookForAutomation() As Boolean
    Dim issues As Collection
    Set issues = ValidateWorkbook(True)
    eMAS_ValidateWorkbookForAutomation = Not HasErrorIssues(issues)
End Function

Public Sub eMAS_PreviewDevJson()
    Dim issues As Collection
    Dim jsonText As String
    Set issues = ValidateWorkbook(True)
    If HasErrorIssues(issues) Then
        MsgBox "Preview is blocked because validation failed.", vbCritical, "eMAS POC"
        Exit Sub
    End If
    jsonText = BuildRuntimeJson(True)
    MsgBox Left$(jsonText, EMAS_MAX_PREVIEW_CHARS), vbInformation, "eMAS JSON Preview (truncated)"
End Sub

Public Function eMAS_ExportDevJson(Optional ByVal outputFolder As String = vbNullString, Optional ByVal deterministic As Boolean = False) As String
    Dim issues As Collection
    Dim jsonText As String
    Dim outputPath As String
    Dim sha256 As String
    Dim validationRunId As String
    On Error GoTo ExportFailed

    Set issues = ValidateWorkbook(True)
    If HasErrorIssues(issues) Then Err.Raise vbObjectError + 2201, "eMAS_ExportDevJson", "Workbook validation failed."
    If Len(outputFolder) = 0 Then outputFolder = ThisWorkbook.Path
    If Len(outputFolder) = 0 Then Err.Raise vbObjectError + 2202, "eMAS_ExportDevJson", "Select an output folder by saving the workbook or passing outputFolder."

    validationRunId = IIf(deterministic, EMAS_POC_VALIDATION_RUN_ID, NewValidationRunId())
    jsonText = BuildRuntimeJson(deterministic)
    outputPath = outputFolder & Application.PathSeparator & EMAS_RUNTIME_FILE_NAME
    AtomicWriteRuntimeJson outputPath, jsonText
    sha256 = CalculateFileSha256(outputPath)
    AppendExportHistory "DEV", outputPath, sha256, validationRunId, "Succeeded"
    eMAS_ExportDevJson = outputPath
    Exit Function

ExportFailed:
    On Error Resume Next
    If Len(outputPath) > 0 Then AppendExportHistory "DEV", outputPath, vbNullString, validationRunId, "Failed"
    On Error GoTo 0
    MsgBox "Export failed in " & Err.Source & ": " & Err.Number & " - " & Err.Description, vbCritical, "eMAS POC"
    eMAS_ExportDevJson = vbNullString
End Function

Public Function eMAS_ExportPocFixtureJson(ByVal outputPath As String) As String
    Dim outputFolder As String
    outputFolder = Left$(outputPath, InStrRev(outputPath, Application.PathSeparator) - 1)
    eMAS_ExportPocFixtureJson = eMAS_ExportDevJson(outputFolder, True)
End Function

Public Sub eMAS_ExportControlledJson()
    MsgBox "Controlled release export is intentionally not enabled in the public synthetic POC. Use the controlled internal build and qualification process.", vbExclamation, "eMAS POC"
End Sub
