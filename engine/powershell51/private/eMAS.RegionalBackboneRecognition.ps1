#requires -Version 5.1

function Get-eMASRegionalPathFamily {
    param([AllowNull()][string] $SequenceRelativePath)

    if ([string]::Equals($SequenceRelativePath, 'm1/eu/eu-regional.xml', [System.StringComparison]::OrdinalIgnoreCase)) { return 'EU_M1' }
    if ([string]::Equals($SequenceRelativePath, 'm1/us/us-regional.xml', [System.StringComparison]::OrdinalIgnoreCase)) { return 'US_M1' }
    return $null
}

function Get-eMASRegionalRecognition {
    <#
    .SYNOPSIS
    Corroborates a physical regional candidate with previously parsed XML facts.
    .DESCRIPTION
    Performs no source access, parsing, regulatory interpretation or validation.
    Profile families are technical signatures, not Region or Authority values.
    #>
    param(
        [AllowNull()][string] $SequenceRelativePath,
        [Parameter(Mandatory = $true)][object] $Metadata,
        [bool] $AmbiguousPath = $false
    )

    $pathFamily = Get-eMASRegionalPathFamily -SequenceRelativePath $SequenceRelativePath
    $xmlFamily = $null
    if ($Metadata.ParseStatus -eq 'Parsed') {
        if ($Metadata.RootElement -ceq 'eu-backbone' -and $Metadata.NamespaceUri -ceq 'http://europa.eu.int') { $xmlFamily = 'EU_M1' }
        elseif ($Metadata.RootElement -ceq 'fda-regional' -and $Metadata.NamespaceUri -ceq 'http://www.ich.org/fda') { $xmlFamily = 'US_M1' }
    }
    $status = 'NotAttempted'
    $support = 'NotAttempted'
    if ($AmbiguousPath) { $status = 'AmbiguousPath' }
    elseif ($Metadata.ParseStatus -eq 'Parsed') {
        if ($null -eq $pathFamily) { $status = 'UnsupportedPath' }
        elseif ($null -eq $xmlFamily) { $status = 'UnrecognizedStructure' }
        elseif ($pathFamily -ne $xmlFamily) { $status = 'PathXmlMismatch' }
        else {
            $status = 'Matched'
            if ($xmlFamily -eq 'US_M1') { $support = 'NotImplemented' }
            elseif ($null -ne $Metadata.RegionalEnvelope -and $Metadata.RegionalEnvelope.ProfileStatus -eq 'Supported') { $support = 'Supported' }
            else { $support = 'UnsupportedProfile' }
        }
    }
    return [pscustomobject][ordered]@{
        PathProfileFamily = $pathFamily
        XmlProfileFamily = $xmlFamily
        RecognitionStatus = $status
        ExtractionSupport = $support
    }
}
