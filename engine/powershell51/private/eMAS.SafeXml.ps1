Set-StrictMode -Version 2.0

function Get-eMASSafeXmlInnermostException {
    param([Parameter(Mandatory = $true)][System.Exception] $Exception)

    $current = $Exception
    while ($null -ne $current.InnerException) { $current = $current.InnerException }
    return $current
}

function ConvertTo-eMASSafeXmlDiagnosticMessage {
    param([AllowNull()][string] $Message)

    if ([string]::IsNullOrWhiteSpace($Message)) { return $null }
    $safe = ($Message -replace '[\r\n]+', ' ').Trim()
    if ($safe.Length -gt 512) { $safe = $safe.Substring(0, 512) }
    return $safe
}

function Read-eMASSafeXmlDocument {
    param([Parameter(Mandatory = $true)][System.IO.Stream] $Stream)

    $settings = New-Object System.Xml.XmlReaderSettings
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
    $settings.XmlResolver = $null
    $settings.MaxCharactersFromEntities = 1024
    $settings.IgnoreComments = $false
    $settings.IgnoreProcessingInstructions = $false
    $settings.IgnoreWhitespace = $true

    $reader = $null
    try {
        $reader = [System.Xml.XmlReader]::Create($Stream, $settings)
        $document = New-Object System.Xml.XmlDocument
        $document.PreserveWhitespace = $false
        $document.XmlResolver = $null
        $document.Load($reader)
        return [pscustomobject][ordered]@{
            ParseStatus = 'Parsed'
            CaptureStatus = 'Available'
            Document = $document
            ParseErrorCode = $null
            ParseErrorLineNumber = $null
            ParseErrorLinePosition = $null
            Diagnostic = $null
        }
    }
    catch {
        $exception = Get-eMASSafeXmlInnermostException -Exception $_.Exception
        $lineNumber = $null
        $linePosition = $null
        $errorCode = 'XML-PARSE-001'
        if ($exception -is [System.Xml.XmlException]) {
            $errorCode = 'XML-WELLFORMEDNESS-001'
            $lineNumber = $exception.LineNumber
            $linePosition = $exception.LinePosition
        }
        return [pscustomobject][ordered]@{
            ParseStatus = 'ParseFailed'
            CaptureStatus = 'ParseFailed'
            Document = $null
            ParseErrorCode = $errorCode
            ParseErrorLineNumber = $lineNumber
            ParseErrorLinePosition = $linePosition
            Diagnostic = ConvertTo-eMASSafeXmlDiagnosticMessage -Message $exception.Message
        }
    }
    finally {
        if ($null -ne $reader) { $reader.Dispose() }
    }
}
