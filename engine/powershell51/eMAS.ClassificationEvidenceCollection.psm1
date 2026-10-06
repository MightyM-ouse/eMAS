#requires -Version 5.1

Set-StrictMode -Version 2.0

# Bounded evidence-type catalogue. Strength uses the contract vocabulary (Strong/Supporting/Weak);
# SourceTier records the evidence-hierarchy tier. Neither is a classification or a numeric score.
$script:eMASCecTypeOrder = @(
    'DossierRootPath', 'SequenceFolder', 'CtdModuleFolders', 'Module1RegionalFolder',
    'CommonBackbonePresence', 'CommonBackbonePath', 'RegionalBackbonePresence', 'RegionalBackbonePath',
    'XmlRootElement', 'XmlNamespace', 'DtdVersion', 'DocumentTypeName', 'DtdSystemIdentifier', 'DtdPublicIdentifier'
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
    param([Parameter(Mandatory = $true)][string] $ParentPath, [Parameter(Mandatory = $true)][string] $ChildPath)

    if ($ChildPath.Length -le $ParentPath.Length + 1) { return $null }
    if (-not $ChildPath.StartsWith($ParentPath + '/', [System.StringComparison]::Ordinal)) { return $null }
    return $ChildPath.Substring($ParentPath.Length + 1)
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
        [Parameter(Mandatory = $true)][string] $DossierPath,
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
        [Parameter(Mandatory = $true)][string] $SourceField
    )

    $spec = $script:eMASCecTypeSpec[$EvidenceType]
    $dimension = [string]$spec.Dimension
    if ($dimension -eq 'ByXmlKind') { $dimension = $(if ($XmlKind -eq 'RegionalBackbone') { 'Region' } else { 'TechnicalFormat' }) }
    $typeIndex = [array]::IndexOf($script:eMASCecTypeOrder, $EvidenceType)
    $sortKey = '{0}{1}{2}{1}{3}{1}{4:D2}' -f $DossierPath, [char]1, [string]$SequenceFolder, [string]$SequenceRelativePath, $typeIndex
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
    return [pscustomobject]@{ SortKey = $sortKey; Record = $record }
}

function New-eMASCecCoverage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'XmlDocument')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][ValidateSet('Collected', 'Partial', 'NotAssessed', 'NotApplicable')][string] $CollectionStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'ClassificationEvidenceCollection'
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        CollectionStatus = $CollectionStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
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
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -ne 'ClassificationEvidenceCollection') { [void]$coverage.Add($item) }
    }
    $xmlCoverage = New-Object System.Collections.ArrayList
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
            foreach ($draft in $xmlDrafts) { [void]$drafts.Add($draft) }
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
    [void]$coverage.Add((New-eMASCecCoverage -SubjectType 'Repository' -SubjectId 'REP-0001' -CaptureStatus $repositoryCaptureStatus -CollectionStatus $repositoryCollectionStatus -RecordsProduced $items.Count -ReasonCode $repositoryReasonCode))

    $workingResult.ClassificationEvidence = [object[]]@($existingEvidence)
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = ('{0}+ClassificationEvidenceCollection' -f [string]$workingResult.Execution.ScannerName)
    $workingResult.Execution.ScannerVersion = '0.8.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]](@($capabilities) + 'ClassificationEvidenceCollection')
    if ($workingResult.Execution.CompletionStatus -eq 'Completed' -and $repositoryCollectionStatus -ne 'Collected') {
        $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps'
    }

    if ($null -ne $resolvedOutputPath) { Write-eMASClassificationEvidenceResult -Result $workingResult -OutputPath $resolvedOutputPath }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASClassificationEvidenceCollection
