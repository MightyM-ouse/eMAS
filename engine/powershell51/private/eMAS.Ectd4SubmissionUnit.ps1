#requires -Version 5.1

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'eMAS.Ectd4Vocabulary.ps1')

$script:eMASEctd4V3Namespace = 'urn:hl7-org:v3'
$script:eMASEctd4XsiNamespace = 'http://www.w3.org/2001/XMLSchema-instance'

function Get-eMASEctd4DirectChildren {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Parent,
        [Parameter(Mandatory = $true)][string] $LocalName
    )

    $items = New-Object System.Collections.ArrayList
    foreach ($node in $Parent.ChildNodes) {
        if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element -and $node.LocalName -ceq $LocalName -and $node.NamespaceURI -ceq $script:eMASEctd4V3Namespace) {
            [void]$items.Add($node)
        }
    }
    return @($items)
}

function Get-eMASEctd4NestedChildren {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Parent,
        [Parameter(Mandatory = $true)][string[]] $Path
    )

    $current = @($Parent)
    foreach ($name in $Path) {
        $next = New-Object System.Collections.ArrayList
        foreach ($element in $current) {
            foreach ($child in @(Get-eMASEctd4DirectChildren -Parent $element -LocalName $name)) { [void]$next.Add($child) }
        }
        $current = @($next)
    }
    return @($current)
}

function ConvertTo-eMASEctd4BoundedText {
    param([AllowNull()][string] $Value, [int] $MaximumLength = 128)
    if ($null -eq $Value) { return $null }
    $valueText = $Value.Trim()
    if ($valueText.Length -gt $MaximumLength) { return $valueText.Substring(0, $MaximumLength) }
    return $valueText
}

function Get-eMASEctd4RootFormat {
    param([AllowNull()][string] $Value, [switch] $UuidOnly)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $(if ($UuidOnly) { 'Absent' } else { 'Other' }) }
    $parsed = [guid]::Empty
    if ([guid]::TryParse($Value, [ref]$parsed)) { return 'Uuid' }
    if ($UuidOnly) { return 'NotUuid' }
    if ($Value -match '^([0-2])((\.0)|(\.[1-9][0-9]*))+$') { return 'Oid' }
    return 'Other'
}

function Test-eMASEctd4DisplayNamePresent {
    param([Parameter(Mandatory = $true)][System.Xml.XmlElement] $CodeElement)

    if ($CodeElement.HasAttribute('displayName') -or $CodeElement.HasAttribute('codeSystemName')) { return $true }
    foreach ($node in $CodeElement.ChildNodes) {
        if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element -and ($node.LocalName -ceq 'displayName' -or $node.LocalName -ceq 'originalText')) { return $true }
    }
    return $false
}

function New-eMASEctd4CodedValue {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Parent,
        [Parameter(Mandatory = $true)][ValidateSet('SubmissionUnitType','SubmissionType','ApplicationType')][string] $ElementKind
    )

    $elements = @(Get-eMASEctd4DirectChildren -Parent $Parent -LocalName 'code')
    $observations = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $elements.Count; $index++) {
        $element = $elements[$index]
        [void]$observations.Add([pscustomobject][ordered]@{
            ObservationOrdinal = $index + 1
            Code = $(if ($element.HasAttribute('code')) { [string]$element.GetAttribute('code') } else { $null })
            CodeSystem = $(if ($element.HasAttribute('codeSystem')) { [string]$element.GetAttribute('codeSystem') } else { $null })
            DisplayNamePresent = [bool](Test-eMASEctd4DisplayNamePresent -CodeElement $element)
        })
    }

    $code = $null
    $codeSystem = $null
    $recognition = 'Absent'
    $displayNamePresent = $false
    if ($elements.Count -eq 1) {
        $code = $observations[0].Code
        $codeSystem = $observations[0].CodeSystem
        $displayNamePresent = [bool]$observations[0].DisplayNamePresent
        $recognition = Resolve-eMASEctd4CodedValue -ElementKind $ElementKind -Code $code -CodeSystem $codeSystem
    }
    elseif ($elements.Count -gt 1) {
        $recognition = 'MultipleValues'
        $displayNamePresent = @($observations | Where-Object { $_.DisplayNamePresent }).Count -gt 0
    }

    return [pscustomobject][ordered]@{
        Occurrences = $elements.Count
        Code = $code
        CodeSystem = $codeSystem
        Recognition = $recognition
        DisplayNamePresent = [bool]$displayNamePresent
        Observations = [object[]]@($observations)
    }
}

function New-eMASEctd4SequenceNumber {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Component,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $UnitFolderName
    )

    $elements = @(Get-eMASEctd4DirectChildren -Parent $Component -LocalName 'sequenceNumber')
    $observations = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $elements.Count; $index++) {
        [void]$observations.Add([pscustomobject][ordered]@{
            ObservationOrdinal = $index + 1
            Raw = $(if ($elements[$index].HasAttribute('value')) { [string]$elements[$index].GetAttribute('value') } else { $null })
        })
    }

    $raw = $null
    $value = $null
    $valueStatus = 'Absent'
    $matchesFolder = 'NotComparable'
    if ($elements.Count -eq 1) {
        $raw = $observations[0].Raw
        $parsed = 0
        if ([string]::IsNullOrWhiteSpace($raw) -or -not [int]::TryParse($raw, [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
            $valueStatus = 'SequenceNumberNotInteger'
        }
        elseif ($parsed -lt 1 -or $parsed -gt 999999) {
            $valueStatus = 'SequenceNumberOutOfRange'
        }
        else {
            $value = $parsed
            $valueStatus = 'WholeNumberInRange'
            $folderValue = 0
            if ([int]::TryParse($UnitFolderName, [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$folderValue)) {
                $matchesFolder = $(if ($folderValue -eq $parsed) { 'Equal' } else { 'Different' })
            }
        }
    }
    elseif ($elements.Count -gt 1) { $valueStatus = 'MultipleValues' }

    return [pscustomobject][ordered]@{
        Occurrences = $elements.Count
        Raw = $raw
        Value = $value
        ValueStatus = $valueStatus
        MatchesUnitFolderName = $matchesFolder
        Observations = [object[]]@($observations)
    }
}

function Get-eMASEctd4IdItems {
    param([Parameter(Mandatory = $true)][System.Xml.XmlElement] $Parent, [switch] $Application)

    $items = New-Object System.Collections.ArrayList
    $elements = @(Get-eMASEctd4NestedChildren -Parent $Parent -Path @('id','item'))
    for ($index = 0; $index -lt $elements.Count; $index++) {
        $element = $elements[$index]
        $root = $(if ($element.HasAttribute('root')) { [string]$element.GetAttribute('root') } else { $null })
        $item = [ordered]@{
            ItemOrdinal = $index + 1
            Root = $root
            RootFormat = Get-eMASEctd4RootFormat -Value $root
            Extension = $(if ($element.HasAttribute('extension')) { ConvertTo-eMASEctd4BoundedText -Value $element.GetAttribute('extension') -MaximumLength 64 } else { $null })
        }
        if ($Application) { $item.RootRecognition = Resolve-eMASEctd4ApplicationNamespace -Root $root }
        [void]$items.Add([pscustomobject]$item)
    }
    return @($items)
}

function Add-eMASEctd4ReasonCode {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList] $Reasons, [AllowNull()][string] $Reason)
    if (-not [string]::IsNullOrWhiteSpace($Reason) -and -not $Reasons.Contains($Reason)) { [void]$Reasons.Add($Reason) }
}

function Get-eMASEctd4SubmissionUnitFacts {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Document,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $UnitFolderName
    )

    $root = $Document.DocumentElement
    $reasons = New-Object System.Collections.ArrayList
    if ($null -ne $Document.DocumentType -or $root.HasAttribute('schemaLocation', $script:eMASEctd4XsiNamespace)) {
        Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'ExternalReferenceNotResolved'
    }

    $structureStatus = 'Recognized'
    if ($root.LocalName -cne 'PORP_IN000001UV') {
        $structureStatus = 'UnrecognizedRootElement'
        Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'UnrecognizedRootElement'
    }
    elseif ($root.NamespaceURI -cne $script:eMASEctd4V3Namespace) {
        $structureStatus = 'UnrecognizedNamespace'
        Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'UnrecognizedNamespace'
    }

    $structure = [pscustomobject][ordered]@{
        RootLocalName = [string]$root.LocalName
        RootNamespaceUri = [string]$root.NamespaceURI
        ItsVersion = $(if ($root.HasAttribute('ITSVersion')) { [string]$root.GetAttribute('ITSVersion') } else { $null })
        SchemaLocationDeclared = $(if ($root.HasAttribute('schemaLocation', $script:eMASEctd4XsiNamespace)) { ConvertTo-eMASEctd4BoundedText -Value $root.GetAttribute('schemaLocation', $script:eMASEctd4XsiNamespace) -MaximumLength 256 } else { $null })
        HasDocumentType = ($null -ne $Document.DocumentType)
        SubmissionUnitCount = 0
        StructureStatus = $structureStatus
    }
    if ($structureStatus -ne 'Recognized') {
        return [pscustomobject][ordered]@{
            Structure = $structure
            ProfileStatus = 'NotAttempted'
            ProfileMarkers = [object[]]@()
            SubmissionUnit = $null
            Submissions = [object[]]@()
            Diagnostics = [pscustomobject][ordered]@{ ContextOfUseCount = 0; DocumentCount = 0; ProfileIdPresent = $false; ReasonCodes = [object[]]@($reasons) }
        }
    }

    $markers = New-Object System.Collections.ArrayList
    $markerElements = @(Get-eMASEctd4NestedChildren -Parent $root -Path @('receiver','device','id','item'))
    for ($index = 0; $index -lt $markerElements.Count; $index++) {
        $element = $markerElements[$index]
        $markerRoot = $(if ($element.HasAttribute('root')) { [string]$element.GetAttribute('root') } else { $null })
        $resolved = Resolve-eMASEctd4ProfileMarker -Root $markerRoot
        [void]$markers.Add([pscustomobject][ordered]@{
            MarkerOrdinal = $index + 1
            Root = $markerRoot
            IdentifierName = $(if ($element.HasAttribute('identifierName')) { ConvertTo-eMASEctd4BoundedText -Value $element.GetAttribute('identifierName') -MaximumLength 128 } else { $null })
            Recognition = $resolved.Recognition
            Family = $resolved.Family
            SourceListVersion = $resolved.SourceListVersion
            SourceStatus = $resolved.SourceStatus
        })
        if ($resolved.SourceStatus -eq 'Draft') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'ProfileSourceDraft' }
        if ($resolved.SourceStatus -eq 'RegisteredWithoutPublishedGuide') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'ProfileSourceUnpublished' }
    }

    $recognizedIch = @($markers | Where-Object { $_.Recognition -eq 'RecognizedIchIg' })
    $recognizedRegional = @($markers | Where-Object { $_.Recognition -eq 'RecognizedRegionalIg' })
    $unknownMarkers = @($markers | Where-Object { $_.Recognition -eq 'UnknownOid' -or $_.Recognition -eq 'Empty' })
    $regionalFamilies = @($recognizedRegional | ForEach-Object { $_.Family } | Sort-Object -Unique)
    $profileStatus = 'MarkersRecognized'
    if ($markers.Count -eq 0) { $profileStatus = 'ProfileMarkersAbsent'; Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'ProfileMarkersAbsent' }
    elseif ($recognizedIch.Count -gt 1 -or $regionalFamilies.Count -gt 1) { $profileStatus = 'ConflictingProfileMarkers'; Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'ConflictingProfileMarkers' }
    elseif ($unknownMarkers.Count -gt 0) { $profileStatus = 'UnrecognizedProfileMarker'; Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'UnrecognizedProfileMarker' }
    elseif ($recognizedIch.Count -eq 0 -or $recognizedRegional.Count -eq 0) { $profileStatus = 'IncompleteProfileMarkers'; Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'IncompleteProfileMarkers' }

    $submissionUnits = @(Get-eMASEctd4NestedChildren -Parent $root -Path @('controlActProcess','subject','submissionUnit'))
    $structure.SubmissionUnitCount = $submissionUnits.Count
    if ($submissionUnits.Count -ne 1) {
        Add-eMASEctd4ReasonCode -Reasons $reasons -Reason $(if ($submissionUnits.Count -gt 1) { 'MultipleSubmissionUnits' } else { 'MandatoryFieldAbsent' })
        return [pscustomobject][ordered]@{
            Structure = $structure
            ProfileStatus = $profileStatus
            ProfileMarkers = [object[]]@($markers)
            SubmissionUnit = $null
            Submissions = [object[]]@()
            Diagnostics = [pscustomobject][ordered]@{ ContextOfUseCount = 0; DocumentCount = 0; ProfileIdPresent = (@(Get-eMASEctd4DirectChildren -Parent $root -LocalName 'profileId').Count -gt 0); ReasonCodes = [object[]]@($reasons) }
        }
    }

    $unit = $submissionUnits[0]
    $unitIds = @(Get-eMASEctd4DirectChildren -Parent $unit -LocalName 'id')
    $unitIdRoot = $(if ($unitIds.Count -eq 1 -and $unitIds[0].HasAttribute('root')) { [string]$unitIds[0].GetAttribute('root') } else { $null })
    $unitCode = New-eMASEctd4CodedValue -Parent $unit -ElementKind 'SubmissionUnitType'
    $statusElements = @(Get-eMASEctd4DirectChildren -Parent $unit -LocalName 'statusCode')
    $unitModel = [pscustomobject][ordered]@{
        IdRoot = $unitIdRoot
        IdRootFormat = Get-eMASEctd4RootFormat -Value $unitIdRoot -UuidOnly
        Code = $unitCode
        StatusCode = $(if ($statusElements.Count -eq 1 -and $statusElements[0].HasAttribute('code')) { [string]$statusElements[0].GetAttribute('code') } else { $null })
        SubmissionCount = 0
    }
    if ($unitCode.Recognition -eq 'Absent') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'MandatoryFieldAbsent' }
    elseif ($unitCode.Recognition -eq 'MultipleValues') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'CardinalityViolation' }
    elseif ($unitCode.Recognition -ne 'Known') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason ([string]$unitCode.Recognition) }

    $submissions = New-Object System.Collections.ArrayList
    $components = @(Get-eMASEctd4DirectChildren -Parent $unit -LocalName 'componentOf1')
    for ($submissionIndex = 0; $submissionIndex -lt $components.Count; $submissionIndex++) {
        $component = $components[$submissionIndex]
        $sequenceNumber = New-eMASEctd4SequenceNumber -Component $component -UnitFolderName $UnitFolderName
        if ($sequenceNumber.ValueStatus -eq 'Absent') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'MandatoryFieldAbsent' }
        elseif ($sequenceNumber.ValueStatus -eq 'MultipleValues') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'CardinalityViolation' }
        elseif ($sequenceNumber.ValueStatus -ne 'WholeNumberInRange') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason ([string]$sequenceNumber.ValueStatus) }
        elseif ($sequenceNumber.MatchesUnitFolderName -eq 'Different') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'SequenceNumberDiffersFromFolder' }

        $submissionElements = @(Get-eMASEctd4DirectChildren -Parent $component -LocalName 'submission')
        if ($submissionElements.Count -ne 1) { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'CardinalityViolation'; continue }
        $submission = $submissionElements[0]
        $submissionCode = New-eMASEctd4CodedValue -Parent $submission -ElementKind 'SubmissionType'
        if ($submissionCode.Recognition -eq 'Absent') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'MandatoryFieldAbsent' }
        elseif ($submissionCode.Recognition -eq 'MultipleValues') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'CardinalityViolation' }
        elseif ($submissionCode.Recognition -ne 'Known') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason ([string]$submissionCode.Recognition) }

        $applications = New-Object System.Collections.ArrayList
        $applicationElements = @(Get-eMASEctd4NestedChildren -Parent $submission -Path @('componentOf','application'))
        for ($applicationIndex = 0; $applicationIndex -lt $applicationElements.Count; $applicationIndex++) {
            $application = $applicationElements[$applicationIndex]
            $applicationCode = New-eMASEctd4CodedValue -Parent $application -ElementKind 'ApplicationType'
            if ($applicationCode.Recognition -eq 'Absent') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'MandatoryFieldAbsent' }
            elseif ($applicationCode.Recognition -eq 'MultipleValues') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'CardinalityViolation' }
            elseif ($applicationCode.Recognition -ne 'Known') { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason ([string]$applicationCode.Recognition) }
            $applicationIds = @(Get-eMASEctd4IdItems -Parent $application -Application)
            if ($applicationIds.Count -gt 1) { Add-eMASEctd4ReasonCode -Reasons $reasons -Reason 'RegionalCardinalityExceeded' }
            [void]$applications.Add([pscustomobject][ordered]@{
                ApplicationOrdinal = $applicationIndex + 1
                IdItems = [object[]]$applicationIds
                Code = $applicationCode
            })
        }

        [void]$submissions.Add([pscustomobject][ordered]@{
            SubmissionOrdinal = $submissionIndex + 1
            SequenceNumber = $sequenceNumber
            IdItems = [object[]]@(Get-eMASEctd4IdItems -Parent $submission)
            Code = $submissionCode
            Applications = [object[]]@($applications)
        })
    }
    $unitModel.SubmissionCount = $submissions.Count

    $contextCount = 0
    $documentCount = 0
    foreach ($element in $unit.GetElementsByTagName('*')) {
        if ($element.NamespaceURI -ne $script:eMASEctd4V3Namespace) { continue }
        if ($element.LocalName -eq 'contextOfUse') { $contextCount++ }
        elseif ($element.LocalName -eq 'document') { $documentCount++ }
    }

    return [pscustomobject][ordered]@{
        Structure = $structure
        ProfileStatus = $profileStatus
        ProfileMarkers = [object[]]@($markers)
        SubmissionUnit = $unitModel
        Submissions = [object[]]@($submissions)
        Diagnostics = [pscustomobject][ordered]@{
            ContextOfUseCount = $contextCount
            DocumentCount = $documentCount
            ProfileIdPresent = (@(Get-eMASEctd4DirectChildren -Parent $root -LocalName 'profileId').Count -gt 0)
            ReasonCodes = [object[]]@($reasons)
        }
    }
}
