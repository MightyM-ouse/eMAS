Attribute VB_Name = "modExportHistory"
Option Explicit

Public Sub AppendExportHistory(ByVal exportType As String, ByVal outputPath As String, ByVal sha256 As String, ByVal validationRunId As String, ByVal status As String)
    Dim lo As ListObject
    Dim lr As ListRow
    Set lo = GetTableByName(EMAS_EXPORT_HISTORY_TABLE)
    If lo Is Nothing Then Exit Sub
    Set lr = lo.ListRows.Add
    lr.Range.Cells(1, lo.ListColumns("ExportId").Index).Value2 = "EXP-" & Format$(Now, "yyyymmddhhnnss")
    lr.Range.Cells(1, lo.ListColumns("ExportType").Index).Value2 = exportType
    lr.Range.Cells(1, lo.ListColumns("SchemaVersion").Index).Value2 = EMAS_SCHEMA_VERSION
    lr.Range.Cells(1, lo.ListColumns("MappingVersion").Index).Value2 = EMAS_MAPPING_VERSION
    lr.Range.Cells(1, lo.ListColumns("WorkbookVersion").Index).Value2 = EMAS_WORKBOOK_VERSION
    lr.Range.Cells(1, lo.ListColumns("ExportedAtUtc").Index).Value2 = UtcNowIso()
    lr.Range.Cells(1, lo.ListColumns("ExportedBy").Index).Value2 = Environ$("USERNAME")
    lr.Range.Cells(1, lo.ListColumns("OutputPath").Index).Value2 = outputPath
    lr.Range.Cells(1, lo.ListColumns("Sha256").Index).Value2 = sha256
    lr.Range.Cells(1, lo.ListColumns("ValidationRunId").Index).Value2 = validationRunId
    lr.Range.Cells(1, lo.ListColumns("Status").Index).Value2 = status
End Sub
