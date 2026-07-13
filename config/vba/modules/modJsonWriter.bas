Attribute VB_Name = "modJsonWriter"
Option Explicit

Public Sub WriteUtf8WithoutBom(ByVal filePath As String, ByVal content As String)
    Dim textStream As Object
    Dim binaryStream As Object
    Set textStream = CreateObject("ADODB.Stream")
    textStream.Type = 2
    textStream.Charset = "utf-8"
    textStream.Open
    textStream.WriteText content
    textStream.Position = 3

    Set binaryStream = CreateObject("ADODB.Stream")
    binaryStream.Type = 1
    binaryStream.Open
    textStream.CopyTo binaryStream
    binaryStream.SaveToFile filePath, 2
    binaryStream.Close
    textStream.Close
End Sub

Public Sub AtomicWriteRuntimeJson(ByVal outputPath As String, ByVal jsonText As String)
    Dim temporaryPath As String
    Dim fso As Object
    temporaryPath = outputPath & ".tmp"
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(temporaryPath) Then fso.DeleteFile temporaryPath, True
    WriteUtf8WithoutBom temporaryPath, jsonText & vbLf
    If fso.FileExists(outputPath) Then fso.DeleteFile outputPath, True
    fso.MoveFile temporaryPath, outputPath
End Sub
