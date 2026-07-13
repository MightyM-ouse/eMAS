Attribute VB_Name = "modChecksum"
Option Explicit

Public Function CalculateFileSha256(ByVal filePath As String) As String
    Dim shell As Object
    Dim process As Object
    Dim output As String
    Dim lines As Variant
    Dim i As Long
    Set shell = CreateObject("WScript.Shell")
    Set process = shell.Exec("certutil -hashfile """ & filePath & """ SHA256")
    output = process.StdOut.ReadAll
    If process.ExitCode <> 0 Then Err.Raise vbObjectError + 2101, "CalculateFileSha256", "certutil failed: " & process.StdErr.ReadAll
    lines = Split(Replace(output, vbCr, vbNullString), vbLf)
    For i = LBound(lines) To UBound(lines)
        If Len(Replace(Trim$(CStr(lines(i))), " ", vbNullString)) = 64 Then
            CalculateFileSha256 = LCase$(Replace(Trim$(CStr(lines(i))), " ", vbNullString))
            Exit Function
        End If
    Next i
    Err.Raise vbObjectError + 2102, "CalculateFileSha256", "SHA-256 output could not be parsed."
End Function
