#requires -Version 5.1

Set-StrictMode -Version 2.0

# Bounded evidence-type catalogue. Strength uses the contract vocabulary (Strong/Supporting/Weak);
# SourceTier records the evidence-hierarchy tier. Neither is a classification or a numeric score.
$script:eMASCecTypeOrder = @(
    'DossierRootPath', 'SequenceFolder', 'CtdModuleFolders', 'Module1RegionalFolder',
    'CommonBackbonePresence', 'CommonBackbonePath', 'RegionalBackbonePresence', 'RegionalBackbonePath',
    'XmlRootElement', 'XmlNamespace', 'DtdVersion', 'DocumentTypeName', 'DtdSystemIdentifier', 'DtdPublicIdentifier',
    'RegulatoryUnitKind', 'SubmissionUnitMarkerFile', 'TocFileMarker', 'ChecksumFileMarker', 'UtilityDtdFolderMarker',
    'EuEnvelopeCountry', 'EuAgencyCode', 'EuProcedureType', 'EuSubmissionType', 'EuSubmissionUnitType',
    'Ectd4MessageRootElement', 'Ectd4MessageNamespace', 'Ectd4ImplementationGuideOid',
    'Ectd4SubmissionUnitTypeCode', 'Ectd4SubmissionTypeCode', 'Ectd4ApplicationTypeCode',
    'Ectd4ApplicationIdNamespaceOid', 'Ectd4SequenceNumber'
)
$script:eMASCecTypeSpec = @{
    DossierRootPath          = @{ Dimension = 'DossierContext'; Strength = 'Weak'; SourceTier = 'FolderNameHeuristic' }
    SequenceFolder           = @{ Dimension = 'TechnicalFormat'; Strength = 'Weak'; SourceTier = 'PackageStructure' }
    CtdModuleFolders         = @{ Dimension = 'TechnicalFormat'; Strength = 'Weak'; SourceTier = 'PackageStructure' }
    Module1RegionalFolder    = @{ Dimension = 'Region'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    CommonBackbonePresence   = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    CommonBackbonePath       = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    RegionalBackbonePresence = @{ Dimension = 'Region'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    RegionalBackbonePath     = @{ Dimension = 'Region'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    XmlRootElement           = @{ Dimension = 'ByXmlKind'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    XmlNamespace             = @{ Dimension = 'ByXmlKind'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    DtdVersion               = @{ Dimension = 'SpecificationProfile'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    DocumentTypeName         = @{ Dimension = 'ByXmlKind'; Strength = 'Supporting'; SourceTier = 'BackboneDeclaration' }
    DtdSystemIdentifier      = @{ Dimension = 'SpecificationProfile'; Strength = 'Supporting'; SourceTier = 'BackboneDeclaration' }
    DtdPublicIdentifier      = @{ Dimension = 'SpecificationProfile'; Strength = 'Supporting'; SourceTier = 'BackboneDeclaration' }
    RegulatoryUnitKind       = @{ Dimension = 'TechnicalFormat'; Strength = 'Weak'; SourceTier = 'PackageStructure' }
    SubmissionUnitMarkerFile = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    TocFileMarker            = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    ChecksumFileMarker       = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    UtilityDtdFolderMarker   = @{ Dimension = 'TechnicalFormat'; Strength = 'Supporting'; SourceTier = 'OfficialPhysicalPath' }
    EuEnvelopeCountry        = @{ Dimension = 'Region'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    EuAgencyCode             = @{ Dimension = 'Region'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    EuProcedureType          = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    EuSubmissionType         = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    EuSubmissionUnitType     = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4MessageRootElement = @{ Dimension = 'TechnicalFormat'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4MessageNamespace = @{ Dimension = 'TechnicalFormat'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4ImplementationGuideOid = @{ Dimension = 'SpecificationProfile'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4SubmissionUnitTypeCode = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4SubmissionTypeCode = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4ApplicationTypeCode = @{ Dimension = 'DossierContext'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4ApplicationIdNamespaceOid = @{ Dimension = 'Region'; Strength = 'Strong'; SourceTier = 'StructuredXml' }
    Ectd4SequenceNumber = @{ Dimension = 'DossierContext'; Strength = 'Supporting'; SourceTier = 'StructuredXml' }
}
$script:eMASCecRegionalEnvelopeTypeByField = @{
    EU_ENVELOPE_COUNTRY = 'EuEnvelopeCountry'
    EU_AGENCY_CODE = 'EuAgencyCode'
    EU_PROCEDURE_TYPE = 'EuProcedureType'
    EU_SUBMISSION_TYPE = 'EuSubmissionType'
    EU_SUBMISSION_UNIT_TYPE = 'EuSubmissionUnitType'
}

function Get-eMASCecPropertyValue {
    param([AllowNull()][object] $InputObject, [Parameter(Mandatory = $true)][string] $Name)

    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-eMASClassificationEvidenceOutputPath {
    param([Parameter(Mandatory = $true)][object] $InputResult, [Parameter(Mandatory = $true)][string] $OutputPath)

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $sourceKind = [string]$InputResult.Repository.SourceKind
    $resolvedSourcePath = [string](Get-eMASCecPropertyValue -InputObject $InputResult.Repository -Name 'ResolvedSourcePath')
    if (-not [string]::IsNullOrWhiteSpace($resolvedSourcePath)) {
        if ($sourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'CEC-OUTPUT-001 OutputPath must not overwrite SourcePath.'
        }
        if ($sourceKind -eq 'Directory') {
            $sourcePrefix = $resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if ($resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw 'CEC-OUTPUT-002 OutputPath must not be inside SourcePath.'
            }
        }
    }
    return $resolvedOutputPath
}

function Write-eMASClassificationEvidenceResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function Get-eMASCecChildPath {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $ParentPath, [Parameter(Mandatory = $true)][string] $ChildPath)

    if ([string]::IsNullOrEmpty($ParentPath)) { return $ChildPath }
    if ($ChildPath.Length -le $ParentPath.Length + 1) { return $null }
    if (-not $ChildPath.StartsWith($ParentPath + '/', [System.StringComparison]::Ordinal)) { return $null }
    return $ChildPath.Substring($ParentPath.Length + 1)
}

function Get-eMASCecParentPath {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $RelativePath)

    $separator = $RelativePath.LastIndexOf('/')
    if ($separator -lt 0) { return '' }
    return $RelativePath.Substring(0, $separator)
}

function Get-eMASCecChildDirectoryNames {
    param([Parameter(Mandatory = $true)][object] $ChildrenByParent, [Parameter(Mandatory = $true)][string] $ParentPath)

    $names = New-Object 'System.Collections.Generic.List[string]'
    if ($ChildrenByParent.ContainsKey($ParentPath)) {
        foreach ($name in $ChildrenByParent[$ParentPath]) { $names.Add([string]$name) }
    }
    $array = $names.ToArray()
    [System.Array]::Sort($array, [System.StringComparer]::Ordinal)
    return ,([object[]]$array)
}

function New-eMASCecDraft {
    param(
        [Parameter(Mandatory = $true)][string] $EvidenceType,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $DossierPath,
        [AllowNull()][string] $SequenceFolder,
        [AllowNull()][string] $SequenceRelativePath,
        [AllowNull()][string] $XmlKind,
        [AllowNull()][string] $RelativePath,
        [AllowNull()][object] $ObservedValue,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [AllowNull()][string] $DossierId,
        [AllowNull()][string] $SequenceId,
        [AllowNull()][string] $XmlId,
        [Parameter(Mandatory = $true)][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SourceCapability,
        [Parameter(Mandatory = $true)][string] $SourceField,
        [int] $SortGroup = 0,
        [AllowNull()][object] $SourceOrdinal,
        [AllowNull()][string] $SourcePath,
        [AllowNull()][string] $SubmissionUnitXmlId,
        [AllowNull()][string] $ObservedCodeSystem
    )

    $spec = $script:eMASCecTypeSpec[$EvidenceType]
    $dimension = [string]$spec.Dimension
    if ($dimension -eq 'ByXmlKind') { $dimension = $(if ($XmlKind -eq 'RegionalBackbone') { 'Region' } else { 'TechnicalFormat' }) }
    $typeIndex = [array]::IndexOf($script:eMASCecTypeOrder, $EvidenceType)
    # New evidence is sorted after the accepted historical catalogue so existing records retain stable IDs.
    $sortKey = '{0:D2}{1}{2}{1}{3}{1}{4}{1}{5:D2}{1}{6}' -f $SortGroup, [char]1, $DossierPath, [string]$SequenceFolder, [string]$SequenceRelativePath, $typeIndex, [string]$RelativePath
    if ($SortGroup -eq 3) {
        $sortKey = '{0:D2}{1}{2}{1}{3}{1}{4}{1}{5:D2}' -f $SortGroup, [char]1, $DossierPath, [string]$SequenceFolder, [string]$SubmissionUnitXmlId, $typeIndex
    }
    $hasSourceOrdinal = $PSBoundParameters.ContainsKey('SourceOrdinal')
    if ($hasSourceOrdinal) { $sortKey += ('{0}{1:D4}' -f [char]1, [int]$SourceOrdinal) }
    $record = [pscustomobject][ordered]@{
        EvidenceId = $null
        Dimension = $dimension
        CandidateValue = $null
        EvidenceType = $EvidenceType
        RelativePath = $(if ([string]::IsNullOrEmpty($RelativePath)) { $null } else { $RelativePath })
        ObservedValue = $ObservedValue
        Strength = [string]$spec.Strength
        Polarity = $null
        SourceRuleId = $null
        CaptureStatus = $CaptureStatus
        DossierId = $(if ([string]::IsNullOrEmpty($DossierId)) { $null } else { $DossierId })
        SequenceId = $(if ([string]::IsNullOrEmpty($SequenceId)) { $null } else { $SequenceId })
        XmlId = $(if ([string]::IsNullOrEmpty($XmlId)) { $null } else { $XmlId })
        SubjectType = $SubjectType
        SourceTier = [string]$spec.SourceTier
        SequenceFolder = $(if ([string]::IsNullOrEmpty($SequenceFolder)) { $null } else { $SequenceFolder })
        SequenceRelativePath = $(if ([string]::IsNullOrEmpty($SequenceRelativePath)) { $null } else { $SequenceRelativePath })
        SourceCapability = $SourceCapability
        SourceField = $SourceField
    }
    if ($hasSourceOrdinal) {
        $record | Add-Member -MemberType NoteProperty -Name SourceOrdinal -Value ([int]$SourceOrdinal)
    }
    if ($PSBoundParameters.ContainsKey('SourcePath')) {
        $record | Add-Member -MemberType NoteProperty -Name SourcePath -Value $(if ([string]::IsNullOrWhiteSpace($SourcePath)) { $null } else { $SourcePath })
    }
    if ($PSBoundParameters.ContainsKey('SubmissionUnitXmlId')) {
        $record | Add-Member -MemberType NoteProperty -Name SubmissionUnitXmlId -Value $(if ([string]::IsNullOrWhiteSpace($SubmissionUnitXmlId)) { $null } else { $SubmissionUnitXmlId })
    }
    if ($PSBoundParameters.ContainsKey('ObservedCodeSystem')) {
        $record | Add-Member -MemberType NoteProperty -Name ObservedCodeSystem -Value $(if ([string]::IsNullOrWhiteSpace($ObservedCodeSystem)) { $null } else { $ObservedCodeSystem })
    }
    return [pscustomobject]@{ SortKey = $sortKey; Record = $record }
}

function New-eMASCecCoverage {
    param(
        [string] $CheckId = 'ClassificationEvidenceCollection',
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'XmlDocument', 'SubmissionUnitXml')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][ValidateSet('Collected', 'Partial', 'NotAssessed', 'NotApplicable')][string] $CollectionStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = $CheckId
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        CollectionStatus = $CollectionStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Get-eMASCecRegionalFieldCoverage {
    param(
        [Parameter(Mandatory = $true)][object] $XmlDocument,
        [Parameter(Mandatory = $true)][string] $FieldCode,
        [AllowEmptyCollection()][object[]] $Fields,
        [Parameter(Mandatory = $true)][int] $RecordsProduced
    )

    $exists = Get-eMASCecPropertyValue -InputObject $XmlDocument -Name 'Exists'
    $parseStatus = [string](Get-eMASCecPropertyValue -InputObject $XmlDocument -Name 'ParseStatus')
    $xmlCapture = [string](Get-eMASCecPropertyValue -InputObject $XmlDocument -Name 'CaptureStatus')
    $regional = Get-eMASCecPropertyValue -InputObject $XmlDocument -Name 'RegionalEnvelope'

    $captureStatus = 'Available'
    $collectionStatus = 'Collected'
    $reasonCode = $null
    if ($exists -is [bool] -and -not [bool]$exists) {
        $captureStatus = 'InputUnavailable'; $collectionStatus = 'NotApplicable'; $reasonCode = 'SourceXmlMissing'
    }
    elseif ($parseStatus -eq 'ParseFailed') {
        $captureStatus = 'ParseFailed'; $collectionStatus = 'NotAssessed'; $reasonCode = 'SourceXmlParseFailed'
    }
    elseif ($xmlCapture -ne 'Available' -or $null -eq $regional) {
        $captureStatus = $(if ($xmlCapture -eq 'AccessDenied') { 'AccessDenied' } else { 'InputUnavailable' })
        $collectionStatus = 'NotAssessed'; $reasonCode = 'SourceXmlUnavailable'
    }
    elseif ([string]$regional.ProfileStatus -eq 'UnsupportedRegionalProfile') {
        $captureStatus = 'NotCollected'; $collectionStatus = 'NotAssessed'; $reasonCode = 'UnsupportedRegionalProfile'
    }
    elseif ([string]$regional.ProfileStatus -eq 'UnrecognizedRegionalStructure') {
        $captureStatus = 'NotCollected'; $collectionStatus = 'NotAssessed'; $reasonCode = 'UnrecognizedRegionalStructure'
    }
    elseif ([string]$regional.ProfileStatus -eq 'NotAttempted') {
        $captureStatus = $(if ($xmlCapture -eq 'AccessDenied') { 'AccessDenied' } elseif ($parseStatus -eq 'ParseFailed') { 'ParseFailed' } else { 'InputUnavailable' })
        $collectionStatus = 'NotAssessed'
        $reasonCode = $(if ($parseStatus -eq 'ParseFailed') { 'SourceXmlParseFailed' } else { 'SourceXmlUnavailable' })
    }
    elseif (@($Fields | Where-Object { $_.ValueStatus -eq 'MultipleValues' }).Count -gt 0) {
        $collectionStatus = 'NotAssessed'; $reasonCode = 'CardinalityViolation'
    }
    elseif (@($Fields | Where-Object { $_.ValueStatus -eq 'OutsideProfileVocabulary' }).Count -gt 0) {
        $collectionStatus = 'NotAssessed'; $reasonCode = 'ValueOutsideProfileVocabulary'
    }
    elseif (@($Fields | Where-Object { $_.ValueStatus -eq 'Absent' }).Count -gt 0) {
        $reasonCode = 'MandatoryFieldAbsent'
    }
    elseif ($Fields.Count -gt 0 -and @($Fields | Where-Object { $_.ValueStatus -eq 'NotDefinedInProfile' }).Count -eq $Fields.Count) {
        $captureStatus = 'NotCollected'; $collectionStatus = 'NotAssessed'; $reasonCode = 'FieldNotDefinedInProfile'
    }
    elseif ($Fields.Count -eq 0) {
        $captureStatus = 'InputUnavailable'; $collectionStatus = 'NotAssessed'; $reasonCode = 'SourceXmlUnavailable'
    }
    else {
        $knownValues = [string[]]@($Fields | Where-Object { $_.ValueStatus -eq 'Known' } | ForEach-Object { [string]$_.Value })
        if (@($knownValues | Select-Object -Unique).Count -gt 1) { $reasonCode = 'EnvelopeValuesDiffer' }
    }

    return New-eMASCecCoverage -CheckId ('RegionalEnvelopeField:{0}' -f $FieldCode) -SubjectType 'XmlDocument' -SubjectId ([string]$XmlDocument.XmlId) `
        -CaptureStatus $captureStatus -CollectionStatus $collectionStatus -RecordsProduced $RecordsProduced -ReasonCode $reasonCode
}

function Add-eMASCecSubmissionUnitDraft {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList] $Drafts,
        [Parameter(Mandatory = $true)][hashtable] $Counters,
        [Parameter(Mandatory = $true)][hashtable] $RecordCounts,
        [Parameter(Mandatory = $true)][string] $EvidenceType,
        [Parameter(Mandatory = $true)][object] $Document,
        [Parameter(Mandatory = $true)][hashtable] $Common,
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $SourceField,
        [AllowNull()][object] $ObservedValue,
        [AllowNull()][string] $ObservedCodeSystem
    )

    $counterKey = '{0}|{1}' -f [string]$Document.SubmissionUnitXmlId, $EvidenceType
    if (-not $Counters.ContainsKey($counterKey)) { $Counters[$counterKey] = 0 }
    $Counters[$counterKey] = [int]$Counters[$counterKey] + 1
    $countKey = '{0}|{1}' -f [string]$Document.SubmissionUnitXmlId, $EvidenceType
    if (-not $RecordCounts.ContainsKey($countKey)) { $RecordCounts[$countKey] = 0 }
    $RecordCounts[$countKey] = [int]$RecordCounts[$countKey] + 1

    $parameters = @{
        EvidenceType = $EvidenceType; ObservedValue = $ObservedValue; CaptureStatus = 'Available'; SourceField = $SourceField
        SortGroup = 3; SourceOrdinal = [int]$Counters[$counterKey]; SourcePath = $SourcePath
        SubmissionUnitXmlId = [string]$Document.SubmissionUnitXmlId
    }
    if ($PSBoundParameters.ContainsKey('ObservedCodeSystem')) { $parameters.ObservedCodeSystem = $ObservedCodeSystem }
    foreach ($key in $Common.Keys) { $parameters[$key] = $Common[$key] }
    [void]$Drafts.Add((New-eMASCecDraft @parameters))
}

function Get-eMASCecSubmissionUnitCoverageRecordCount {
    param(
        [Parameter(Mandatory = $true)][hashtable] $RecordCounts,
        [Parameter(Mandatory = $true)][string] $SubmissionUnitXmlId,
        [Parameter(Mandatory = $true)][string] $CheckId
    )

    $types = @()
    switch ($CheckId) {
        'SubmissionUnitXmlField:ECTD4_IG_OID' { $types = @('Ectd4ImplementationGuideOid') }
        'SubmissionUnitXmlField:ECTD4_SU_TYPE' { $types = @('Ectd4SubmissionUnitTypeCode') }
        'SubmissionUnitXmlField:ECTD4_SUBMISSION_TYPE' { $types = @('Ectd4SubmissionTypeCode') }
        'SubmissionUnitXmlField:ECTD4_APPLICATION_TYPE' { $types = @('Ectd4ApplicationTypeCode') }
        'SubmissionUnitXmlField:ECTD4_SEQUENCE_NUMBER' { $types = @('Ectd4SequenceNumber') }
        default { $types = @($script:eMASCecTypeOrder | Where-Object { $_ -like 'Ectd4*' }) }
    }
    $count = 0
    foreach ($type in $types) {
        $key = '{0}|{1}' -f $SubmissionUnitXmlId, $type
        if ($RecordCounts.ContainsKey($key)) { $count += [int]$RecordCounts[$key] }
    }
    return $count
}

function Invoke-eMASClassificationEvidenceCollection {
    <#
    .SYNOPSIS
    Collects factual structural and backbone-XML evidence that later region/format/specification interpretation may use.

    .DESCRIPTION
    Consumes accepted RepositoryDiscovery and BackboneXmlInventory facts already present in the result object.
    It does not access the source, parse XML, or assign any region, format, specification or candidate value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $InputResult,
        [AllowNull()][string] $OutputPath
    )

    if ($InputResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') { throw 'CEC-INPUT-001 Input uses an unsupported contract.' }
    if ($InputResult.Execution.Phase -ne 'PreSales' -or $InputResult.Execution.ScenarioId -ne 'MS-04') { throw 'CEC-INPUT-002 Input is not an MS-04 PreSales result.' }
    $capabilities = @(Get-eMASCecPropertyValue -InputObject $InputResult.Execution -Name 'Capabilities')
    if ($capabilities -notcontains 'RepositoryDiscovery' -or $capabilities -notcontains 'BackboneXmlInventory') {
        throw 'CEC-INPUT-003 Input does not declare the accepted RepositoryDiscovery and BackboneXmlInventory capabilities.'
    }
    if ($capabilities -contains 'ClassificationEvidenceCollection') { throw 'CEC-INPUT-004 Input already declares ClassificationEvidenceCollection.' }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASClassificationEvidenceOutputPath -InputResult $InputResult -OutputPath $OutputPath
    }

    $workingResult = ($InputResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $drafts = New-Object System.Collections.ArrayList
    $coverage = New-Object System.Collections.ArrayList
    $submissionUnitCoverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        $checkId = [string]$item.CheckId
        if ($checkId -eq 'SubmissionUnitXmlInventory' -or $checkId.StartsWith('SubmissionUnitXmlField:', [System.StringComparison]::Ordinal)) {
            [void]$submissionUnitCoverage.Add($item)
        }
        elseif ($checkId -ne 'ClassificationEvidenceCollection') { [void]$coverage.Add($item) }
    }
    $xmlCoverage = New-Object System.Collections.ArrayList
    $regionalFieldCoverage = New-Object System.Collections.ArrayList
    $submissionUnitRecordCounts = @{}
    $inventoryAvailable = ([string](Get-eMASCecPropertyValue -InputObject $workingResult.Repository -Name 'InventoryCaptureStatus') -eq 'Available')

    if ($inventoryAvailable) {
        $dossierPathById = @{}
        foreach ($dossier in @($workingResult.DossierCandidates)) { $dossierPathById[[string]$dossier.DossierId] = [string]$dossier.RelativePath }
        $sequenceById = @{}
        foreach ($sequence in @($workingResult.Sequences)) { $sequenceById[[string]$sequence.SequenceId] = $sequence }

        $directories = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        $childrenByParent = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]' ([System.StringComparer]::Ordinal)
        foreach ($entry in @(Get-eMASCecPropertyValue -InputObject $workingResult.Repository -Name 'Entries')) {
            if ($null -eq $entry -or [string]$entry.EntryKind -ne 'Directory') { continue }
            $path = [string]$entry.RelativePath
            if (-not $directories.Add($path)) { continue }
            $separator = $path.LastIndexOf('/')
            $parent = $(if ($separator -lt 0) { '' } else { $path.Substring(0, $separator) })
            if (-not $childrenByParent.ContainsKey($parent)) { $childrenByParent[$parent] = New-Object 'System.Collections.Generic.List[string]' }
            $childrenByParent[$parent].Add($path.Substring($separator + 1))
        }

        # Dossier-level: the physical dossier root path (folder names are weak, uninterpreted evidence).
        foreach ($dossier in @($workingResult.DossierCandidates)) {
            [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'DossierRootPath' -DossierPath ([string]$dossier.RelativePath) -SequenceFolder $null -SequenceRelativePath $null -XmlKind $null `
                -RelativePath ([string]$dossier.RelativePath) -ObservedValue ([string]$dossier.RelativePath) -CaptureStatus 'Available' -DossierId ([string]$dossier.DossierId) -SequenceId $null -XmlId $null `
                -SubjectType 'Dossier' -SourceCapability 'RepositoryDiscovery' -SourceField 'DossierCandidates.RelativePath'))
        }

        # Sequence-level package structure from RepositoryDiscovery inventory.
        foreach ($sequence in @($workingResult.Sequences)) {
            $dossierPath = [string]$dossierPathById[[string]$sequence.DossierId]
            $sequencePath = [string]$sequence.RelativePath
            $sequenceFolder = Get-eMASCecChildPath -ParentPath $dossierPath -ChildPath $sequencePath
            if ($null -eq $sequenceFolder) { $sequenceFolder = $sequencePath }
            [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'SequenceFolder' -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $null -XmlKind $null `
                -RelativePath $sequencePath -ObservedValue ([string]$sequence.FolderName) -CaptureStatus 'Available' -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null `
                -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Sequences.FolderName'))

            $sequenceLikeKind = [string](Get-eMASCecPropertyValue -InputObject $sequence -Name 'SequenceLikeKind')
            if (-not [string]::IsNullOrWhiteSpace($sequenceLikeKind)) {
                [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'RegulatoryUnitKind' -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $null -XmlKind $null `
                    -RelativePath $sequencePath -ObservedValue $sequenceLikeKind -CaptureStatus 'Available' -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null `
                    -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Sequences.SequenceLikeKind' -SortGroup 1))
            }

            # Only exact direct children of this accepted sequence can provide file-marker evidence.
            $directFilePaths = New-Object 'System.Collections.Generic.List[string]'
            foreach ($file in @($workingResult.Files)) {
                if ([string]$file.SequenceId -ne [string]$sequence.SequenceId) { continue }
                $filePath = [string]$file.RelativePath
                if ((Get-eMASCecParentPath -RelativePath $filePath) -ceq $sequencePath) { $directFilePaths.Add($filePath) }
            }
            $sortedDirectFilePaths = $directFilePaths.ToArray()
            [System.Array]::Sort($sortedDirectFilePaths, [System.StringComparer]::Ordinal)
            foreach ($filePath in $sortedDirectFilePaths) {
                $leafName = $filePath.Substring($filePath.LastIndexOf('/') + 1)
                $evidenceType = $null
                if ($leafName.Equals('submissionunit.xml', [System.StringComparison]::OrdinalIgnoreCase)) {
                    $evidenceType = 'SubmissionUnitMarkerFile'
                }
                elseif ($leafName.Equals('index-md5.txt', [System.StringComparison]::OrdinalIgnoreCase) -or $leafName.Equals('sha256.txt', [System.StringComparison]::OrdinalIgnoreCase)) {
                    $evidenceType = 'ChecksumFileMarker'
                }
                elseif ($leafName.Equals('ctd-toc.pdf', [System.StringComparison]::OrdinalIgnoreCase) -or $leafName -imatch '^m[1-5]-toc\.pdf$') {
                    $evidenceType = 'TocFileMarker'
                }
                if ($null -ne $evidenceType) {
                    [void]$drafts.Add((New-eMASCecDraft -EvidenceType $evidenceType -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $leafName -XmlKind $null `
                        -RelativePath $filePath -ObservedValue $leafName -CaptureStatus 'Available' -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null `
                        -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Files.RelativePath' -SortGroup 1))
                }
            }

            if (-not $directories.Contains($sequencePath)) { continue }
            $children = Get-eMASCecChildDirectoryNames -ChildrenByParent $childrenByParent -ParentPath $sequencePath
            $moduleFolders = [object[]]@($children | Where-Object { $_ -cmatch '^m[1-5]$' })
            [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'CtdModuleFolders' -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $null -XmlKind $null `
                -RelativePath $sequencePath -ObservedValue $moduleFolders -CaptureStatus 'Available' -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null `
                -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Repository.Entries'))
            if (@($children) -ccontains 'm1') {
                $moduleOnePath = $sequencePath + '/m1'
                [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'Module1RegionalFolder' -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $null -XmlKind $null `
                    -RelativePath $moduleOnePath -ObservedValue (Get-eMASCecChildDirectoryNames -ChildrenByParent $childrenByParent -ParentPath $moduleOnePath) -CaptureStatus 'Available' `
                    -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Repository.Entries'))
            }
            foreach ($utilityName in @($children | Where-Object { $_ -ieq 'util' })) {
                $utilityPath = $sequencePath + '/' + $utilityName
                $utilityChildren = Get-eMASCecChildDirectoryNames -ChildrenByParent $childrenByParent -ParentPath $utilityPath
                foreach ($dtdName in @($utilityChildren | Where-Object { $_ -ieq 'dtd' })) {
                    $markerPath = $utilityPath + '/' + $dtdName
                    $sequenceRelativeMarkerPath = $utilityName + '/' + $dtdName
                    [void]$drafts.Add((New-eMASCecDraft -EvidenceType 'UtilityDtdFolderMarker' -DossierPath $dossierPath -SequenceFolder $sequenceFolder -SequenceRelativePath $sequenceRelativeMarkerPath -XmlKind $null `
                        -RelativePath $markerPath -ObservedValue $sequenceRelativeMarkerPath -CaptureStatus 'Available' -DossierId ([string]$sequence.DossierId) -SequenceId ([string]$sequence.SequenceId) -XmlId $null `
                        -SubjectType 'Sequence' -SourceCapability 'RepositoryDiscovery' -SourceField 'Repository.Entries' -SortGroup 1))
                }
            }
        }

        # Backbone XML evidence from BackboneXmlInventory: physical presence/path always; structured fields only when Parsed.
        foreach ($xml in @($workingResult.XmlDocuments)) {
            $xmlKind = [string]$xml.XmlKind
            if ($xmlKind -ne 'CommonBackbone' -and $xmlKind -ne 'RegionalBackbone') { continue }
            $prefix = $(if ($xmlKind -eq 'CommonBackbone') { 'Common' } else { 'Regional' })
            $sequence = $sequenceById[[string]$xml.SequenceId]
            $dossierPath = [string]$dossierPathById[[string]$xml.DossierId]
            $sequencePath = [string]$sequence.RelativePath
            $sequenceFolder = Get-eMASCecChildPath -ParentPath $dossierPath -ChildPath $sequencePath
            if ($null -eq $sequenceFolder) { $sequenceFolder = $sequencePath }
            $xmlPath = [string]$xml.RelativePath
            $sequenceRelativePath = Get-eMASCecChildPath -ParentPath $sequencePath -ChildPath $xmlPath
            if ($null -eq $sequenceRelativePath) { $sequenceRelativePath = $xmlPath }
            $common = @{ DossierPath = $dossierPath; SequenceFolder = $sequenceFolder; SequenceRelativePath = $sequenceRelativePath; XmlKind = $xmlKind; RelativePath = $xmlPath; DossierId = [string]$xml.DossierId; SequenceId = [string]$xml.SequenceId; XmlId = [string]$xml.XmlId; SubjectType = 'XmlDocument'; SourceCapability = 'BackboneXmlInventory' }
            $recognition = Get-eMASCecPropertyValue -InputObject $xml -Name 'RegionalRecognition'
            $isUsRegional = ($xmlKind -eq 'RegionalBackbone' -and
                ((Get-eMASCecPropertyValue -InputObject $recognition -Name 'PathProfileFamily') -eq 'US_M1' -or $sequenceRelativePath -ieq 'm1/us/us-regional.xml'))
            # New US facts follow all existing groups, including T1b and T2.
            if ($isUsRegional) { $common.SortGroup = 4 }

            $exists = Get-eMASCecPropertyValue -InputObject $xml -Name 'Exists'
            $parseStatus = [string](Get-eMASCecPropertyValue -InputObject $xml -Name 'ParseStatus')
            $xmlCaptureStatus = [string](Get-eMASCecPropertyValue -InputObject $xml -Name 'CaptureStatus')
            $existsKnown = ($exists -is [bool])
            $presenceCapture = $(if ($existsKnown) { 'Available' } elseif ([string]::IsNullOrWhiteSpace($xmlCaptureStatus)) { 'InputUnavailable' } else { $xmlCaptureStatus })
            $xmlDrafts = New-Object System.Collections.ArrayList
            [void]$xmlDrafts.Add((New-eMASCecDraft -EvidenceType ($prefix + 'BackbonePresence') -ObservedValue $(if ($existsKnown) { [bool]$exists } else { $null }) -CaptureStatus $presenceCapture -SourceField 'XmlDocuments.Exists' @common))
            if ($existsKnown -and [bool]$exists) {
                [void]$xmlDrafts.Add((New-eMASCecDraft -EvidenceType ($prefix + 'BackbonePath') -ObservedValue $sequenceRelativePath -CaptureStatus 'Available' -SourceField 'XmlDocuments.RelativePath' @common))
            }

            $structuredCount = 0
            if ($existsKnown -and [bool]$exists -and $parseStatus -eq 'Parsed' -and $xmlCaptureStatus -eq 'Available') {
                $structured = @(
                    @{ Type = 'XmlRootElement'; Field = 'RootElement'; Value = Get-eMASCecPropertyValue -InputObject $xml -Name 'RootElement' },
                    @{ Type = 'XmlNamespace'; Field = 'NamespaceUri'; Value = Get-eMASCecPropertyValue -InputObject $xml -Name 'NamespaceUri' },
                    @{ Type = 'DtdVersion'; Field = 'DeclaredVersion'; Value = Get-eMASCecPropertyValue -InputObject $xml -Name 'DeclaredVersion' },
                    @{ Type = 'DocumentTypeName'; Field = 'DocumentTypeName'; Value = $(if ((Get-eMASCecPropertyValue -InputObject $xml -Name 'HasDocumentType') -eq $true) { Get-eMASCecPropertyValue -InputObject $xml -Name 'DocumentTypeName' } else { $null }) },
                    @{ Type = 'DtdSystemIdentifier'; Field = 'SystemId'; Value = Get-eMASCecPropertyValue -InputObject $xml -Name 'SystemId' },
                    @{ Type = 'DtdPublicIdentifier'; Field = 'PublicId'; Value = Get-eMASCecPropertyValue -InputObject $xml -Name 'PublicId' }
                )
                foreach ($fact in $structured) {
                    # RootElement and NamespaceUri are recorded verbatim even when empty; optional declarations only when present.
                    $isAlwaysRecorded = ($fact.Type -eq 'XmlRootElement' -or $fact.Type -eq 'XmlNamespace')
                    if ($null -eq $fact.Value -or (-not $isAlwaysRecorded -and [string]::IsNullOrEmpty([string]$fact.Value))) { continue }
                    [void]$xmlDrafts.Add((New-eMASCecDraft -EvidenceType $fact.Type -ObservedValue ([string]$fact.Value) -CaptureStatus 'Available' -SourceField ('XmlDocuments.' + $fact.Field) @common))
                    $structuredCount++
                }

                if ($xmlKind -eq 'RegionalBackbone' -and -not $isUsRegional) {
                    $regionalEnvelope = Get-eMASCecPropertyValue -InputObject $xml -Name 'RegionalEnvelope'
                    foreach ($fieldCode in @($script:eMASCecRegionalEnvelopeTypeByField.Keys | Sort-Object { [array]::IndexOf(@('EU_ENVELOPE_COUNTRY','EU_AGENCY_CODE','EU_PROCEDURE_TYPE','EU_SUBMISSION_TYPE','EU_SUBMISSION_UNIT_TYPE'), $_) })) {
                        $fieldFacts = New-Object System.Collections.ArrayList
                        if ($null -ne $regionalEnvelope -and [string]$regionalEnvelope.ProfileStatus -eq 'Supported') {
                            foreach ($envelope in @($regionalEnvelope.Envelopes)) {
                                $field = @($envelope.Fields | Where-Object { $_.FieldCode -eq $fieldCode })
                                if ($field.Count -ne 1) { continue }
                                [void]$fieldFacts.Add($field[0])
                                if ([string]$field[0].ValueStatus -eq 'Known') {
                                    [void]$xmlDrafts.Add((New-eMASCecDraft -EvidenceType ([string]$script:eMASCecRegionalEnvelopeTypeByField[$fieldCode]) -ObservedValue ([string]$field[0].Value) `
                                        -CaptureStatus 'Available' -SourceField ('XmlDocuments.RegionalEnvelope.' + $fieldCode) -SortGroup 2 -SourceOrdinal ([int]$envelope.EnvelopeOrdinal) @common))
                                }
                            }
                        }
                        [void]$regionalFieldCoverage.Add((Get-eMASCecRegionalFieldCoverage -XmlDocument $xml -FieldCode $fieldCode -Fields @($fieldFacts) `
                            -RecordsProduced @($fieldFacts | Where-Object { $_.ValueStatus -eq 'Known' }).Count))
                    }
                }
                [void]$xmlCoverage.Add((New-eMASCecCoverage -SubjectType 'XmlDocument' -SubjectId ([string]$xml.XmlId) -CaptureStatus 'Available' -CollectionStatus 'Collected' -RecordsProduced $xmlDrafts.Count -ReasonCode $null))
            }
            elseif ($existsKnown -and -not [bool]$exists) {
                [void]$xmlCoverage.Add((New-eMASCecCoverage -SubjectType 'XmlDocument' -SubjectId ([string]$xml.XmlId) -CaptureStatus 'InputUnavailable' -CollectionStatus 'NotApplicable' -RecordsProduced $xmlDrafts.Count -ReasonCode 'SourceXmlMissing'))
            }
            elseif ($parseStatus -eq 'ParseFailed') {
                [void]$xmlCoverage.Add((New-eMASCecCoverage -SubjectType 'XmlDocument' -SubjectId ([string]$xml.XmlId) -CaptureStatus 'ParseFailed' -CollectionStatus 'NotAssessed' -RecordsProduced $xmlDrafts.Count -ReasonCode 'SourceXmlParseFailed'))
            }
            else {
                $unavailableCapture = $(if ($xmlCaptureStatus -eq 'AccessDenied') { 'AccessDenied' } else { 'InputUnavailable' })
                [void]$xmlCoverage.Add((New-eMASCecCoverage -SubjectType 'XmlDocument' -SubjectId ([string]$xml.XmlId) -CaptureStatus $unavailableCapture -CollectionStatus 'NotAssessed' -RecordsProduced $xmlDrafts.Count -ReasonCode 'SourceXmlUnavailable'))
            }
            if ($xmlKind -eq 'RegionalBackbone' -and -not $isUsRegional -and -not ($existsKnown -and [bool]$exists -and $parseStatus -eq 'Parsed' -and $xmlCaptureStatus -eq 'Available')) {
                foreach ($fieldCode in @('EU_ENVELOPE_COUNTRY','EU_AGENCY_CODE','EU_PROCEDURE_TYPE','EU_SUBMISSION_TYPE','EU_SUBMISSION_UNIT_TYPE')) {
                    [void]$regionalFieldCoverage.Add((Get-eMASCecRegionalFieldCoverage -XmlDocument $xml -FieldCode $fieldCode -Fields @() -RecordsProduced 0))
                }
            }
            foreach ($draft in $xmlDrafts) { [void]$drafts.Add($draft) }
            if ($isUsRegional) {
                $reason = $(if (-not $exists) { 'SourceXmlMissing' } elseif ($parseStatus -eq 'ParseFailed') { 'SourceXmlParseFailed' } elseif ($xmlCaptureStatus -ne 'Available') { 'SourceXmlUnavailable' } else { 'RegionalEnvelopeExtractionNotImplemented' })
                [void]$regionalFieldCoverage.Add((New-eMASCecCoverage -CheckId 'RegionalEnvelopeExtraction:US_M1' -SubjectType 'XmlDocument' -SubjectId ([string]$xml.XmlId) `
                    -CaptureStatus 'NotCollected' -CollectionStatus 'NotAssessed' -RecordsProduced 0 -ReasonCode $reason))
            }
        }

        # Optional T2 facts. CEC consumes only the already-populated SUXI model and never reopens XML.
        if ($capabilities -contains 'SubmissionUnitXmlInventory') {
            $sourceCounters = @{}
            foreach ($document in @($workingResult.SubmissionUnitXmlDocuments | Sort-Object SubmissionUnitXmlId)) {
                if ([string]$document.CaptureStatus -ne 'Available' -or [string]$document.ParseStatus -ne 'Parsed' -or [string]$document.Structure.StructureStatus -ne 'Recognized') { continue }
                $sequence = $sequenceById[[string]$document.SequenceId]
                $dossierPath = [string]$dossierPathById[[string]$document.DossierId]
                $sequencePath = [string]$sequence.RelativePath
                $sequenceFolder = Get-eMASCecChildPath -ParentPath $dossierPath -ChildPath $sequencePath
                if ($null -eq $sequenceFolder) { $sequenceFolder = $sequencePath }
                $relativePath = [string]$document.RelativePath
                $sequenceRelativePath = Get-eMASCecChildPath -ParentPath $sequencePath -ChildPath $relativePath
                if ($null -eq $sequenceRelativePath) { $sequenceRelativePath = $relativePath }
                $common = @{
                    DossierPath = $dossierPath; SequenceFolder = $sequenceFolder; SequenceRelativePath = $sequenceRelativePath; XmlKind = $null
                    RelativePath = $relativePath; DossierId = [string]$document.DossierId; SequenceId = [string]$document.SequenceId; XmlId = $null
                    SubjectType = 'SubmissionUnitXml'; SourceCapability = 'SubmissionUnitXmlInventory'
                }

                Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4MessageRootElement' `
                    -Document $document -Common $common -SourcePath 'R' -SourceField 'SubmissionUnitXmlDocuments.Structure.RootLocalName' -ObservedValue ([string]$document.Structure.RootLocalName)
                Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4MessageNamespace' `
                    -Document $document -Common $common -SourcePath 'R' -SourceField 'SubmissionUnitXmlDocuments.Structure.RootNamespaceUri' -ObservedValue ([string]$document.Structure.RootNamespaceUri)

                foreach ($marker in @($document.ProfileMarkers | Sort-Object MarkerOrdinal)) {
                    if ([string]$marker.Recognition -notin @('RecognizedIchIg','RecognizedRegionalIg')) { continue }
                    Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4ImplementationGuideOid' `
                        -Document $document -Common $common -SourcePath ('M{0}' -f [int]$marker.MarkerOrdinal) -SourceField 'SubmissionUnitXmlDocuments.ProfileMarkers.Root' -ObservedValue ([string]$marker.Root)
                }

                if ($null -eq $document.SubmissionUnit) { continue }
                $unitCode = $document.SubmissionUnit.Code
                if ([int]$unitCode.Occurrences -eq 1 -and [string]$unitCode.Recognition -eq 'Known') {
                    Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4SubmissionUnitTypeCode' `
                        -Document $document -Common $common -SourcePath 'U' -SourceField 'SubmissionUnitXmlDocuments.SubmissionUnit.Code.Code' -ObservedValue ([string]$unitCode.Code) -ObservedCodeSystem ([string]$unitCode.CodeSystem)
                }

                foreach ($submission in @($document.Submissions | Sort-Object SubmissionOrdinal)) {
                    $submissionPath = 'S{0}' -f [int]$submission.SubmissionOrdinal
                    $submissionCode = $submission.Code
                    if ([int]$submissionCode.Occurrences -eq 1 -and [string]$submissionCode.Recognition -eq 'Known') {
                        Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4SubmissionTypeCode' `
                            -Document $document -Common $common -SourcePath $submissionPath -SourceField 'SubmissionUnitXmlDocuments.Submissions.Code.Code' -ObservedValue ([string]$submissionCode.Code) -ObservedCodeSystem ([string]$submissionCode.CodeSystem)
                    }

                    foreach ($application in @($submission.Applications | Sort-Object ApplicationOrdinal)) {
                        $applicationPath = '{0}/A{1}' -f $submissionPath, [int]$application.ApplicationOrdinal
                        $applicationCode = $application.Code
                        if ([int]$applicationCode.Occurrences -eq 1 -and [string]$applicationCode.Recognition -eq 'Known') {
                            Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4ApplicationTypeCode' `
                                -Document $document -Common $common -SourcePath $applicationPath -SourceField 'SubmissionUnitXmlDocuments.Submissions.Applications.Code.Code' -ObservedValue ([string]$applicationCode.Code) -ObservedCodeSystem ([string]$applicationCode.CodeSystem)
                        }
                        foreach ($item in @($application.IdItems | Sort-Object ItemOrdinal)) {
                            if ([string]$item.RootRecognition -ne 'RecognizedNamespaceOid') { continue }
                            Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4ApplicationIdNamespaceOid' `
                                -Document $document -Common $common -SourcePath ('{0}/I{1}' -f $applicationPath, [int]$item.ItemOrdinal) -SourceField 'SubmissionUnitXmlDocuments.Submissions.Applications.IdItems.Root' -ObservedValue ([string]$item.Root)
                        }
                    }

                    $sequenceNumber = $submission.SequenceNumber
                    if ([int]$sequenceNumber.Occurrences -eq 1 -and [string]$sequenceNumber.ValueStatus -eq 'WholeNumberInRange') {
                        Add-eMASCecSubmissionUnitDraft -Drafts $drafts -Counters $sourceCounters -RecordCounts $submissionUnitRecordCounts -EvidenceType 'Ectd4SequenceNumber' `
                            -Document $document -Common $common -SourcePath $submissionPath -SourceField 'SubmissionUnitXmlDocuments.Submissions.SequenceNumber.Value' -ObservedValue ([string]$sequenceNumber.Value)
                    }
                }
            }
        }
    }

    # Deterministic ordinal ordering and EVD-nnnn identity continuing any existing evidence.
    $maximum = 0
    $existingEvidence = New-Object System.Collections.ArrayList
    foreach ($evidence in @($workingResult.ClassificationEvidence)) {
        if ($null -eq $evidence) { continue }
        [void]$existingEvidence.Add($evidence)
        $existingId = [string](Get-eMASCecPropertyValue -InputObject $evidence -Name 'EvidenceId')
        if ($existingId -match '^EVD-(\d+)$') { if ([int]$Matches[1] -gt $maximum) { $maximum = [int]$Matches[1] } }
    }
    $sorted = New-Object 'System.Collections.Generic.SortedDictionary[string,object]' ([System.StringComparer]::Ordinal)
    for ($index = 0; $index -lt $drafts.Count; $index++) {
        $sorted.Add(('{0}{1}{2:D6}' -f $drafts[$index].SortKey, [char]1, $index), $drafts[$index].Record)
    }
    $items = [object[]]@($sorted.Values)
    $ordinal = $maximum
    foreach ($record in $items) {
        $ordinal++
        $record.EvidenceId = 'EVD-{0:D4}' -f $ordinal
        [void]$existingEvidence.Add($record)
    }

    $repositoryCollectionStatus = 'Collected'
    $repositoryCaptureStatus = 'Available'
    $repositoryReasonCode = $null
    if (-not $inventoryAvailable) {
        $repositoryCollectionStatus = 'NotAssessed'
        $repositoryCaptureStatus = 'InputUnavailable'
        $repositoryReasonCode = 'RepositoryInventoryUnavailable'
    }
    else {
        $notAssessedXml = @($xmlCoverage | Where-Object { $_.CollectionStatus -eq 'NotAssessed' })
        if ($notAssessedXml.Count -gt 0) {
            $repositoryCollectionStatus = 'Partial'
            $repositoryCaptureStatus = $(if (@($notAssessedXml | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } elseif (@($notAssessedXml | Where-Object { $_.CaptureStatus -eq 'ParseFailed' }).Count -gt 0) { 'ParseFailed' } else { 'InputUnavailable' })
            $repositoryReasonCode = 'OneOrMoreBackboneXmlStructuredEvidenceUnavailable'
        }
    }
    foreach ($row in $xmlCoverage) { [void]$coverage.Add($row) }
    foreach ($row in $regionalFieldCoverage) { [void]$coverage.Add($row) }
    foreach ($row in $submissionUnitCoverage) {
        $recordsProduced = Get-eMASCecSubmissionUnitCoverageRecordCount -RecordCounts $submissionUnitRecordCounts -SubmissionUnitXmlId ([string]$row.SubjectId) -CheckId ([string]$row.CheckId)
        $updated = [ordered]@{
            CheckId = [string]$row.CheckId
            SubjectType = [string]$row.SubjectType
            SubjectId = [string]$row.SubjectId
            CaptureStatus = [string]$row.CaptureStatus
            CollectionStatus = [string]$row.CollectionStatus
            RecordsProduced = $recordsProduced
            ReasonCode = Get-eMASCecPropertyValue -InputObject $row -Name 'ReasonCode'
        }
        $schemaValidation = Get-eMASCecPropertyValue -InputObject $row -Name 'SchemaValidation'
        if ($null -ne $schemaValidation) { $updated.SchemaValidation = $schemaValidation }
        [void]$coverage.Add([pscustomobject]$updated)
    }
    [void]$coverage.Add((New-eMASCecCoverage -SubjectType 'Repository' -SubjectId 'REP-0001' -CaptureStatus $repositoryCaptureStatus -CollectionStatus $repositoryCollectionStatus -RecordsProduced $items.Count -ReasonCode $repositoryReasonCode))

    $workingResult.ClassificationEvidence = [object[]]@($existingEvidence)
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = ('{0}+ClassificationEvidenceCollection' -f [string]$workingResult.Execution.ScannerName)
    $workingResult.Execution.ScannerVersion = $(if ($capabilities -contains 'SubmissionUnitXmlInventory') { '0.13.0' } else { '0.12.0' })
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]](@($capabilities) + 'ClassificationEvidenceCollection')
    if ($workingResult.Execution.CompletionStatus -eq 'Completed' -and $repositoryCollectionStatus -ne 'Collected') {
        $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps'
    }

    if ($null -ne $resolvedOutputPath) { Write-eMASClassificationEvidenceResult -Result $workingResult -OutputPath $resolvedOutputPath }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASClassificationEvidenceCollection
