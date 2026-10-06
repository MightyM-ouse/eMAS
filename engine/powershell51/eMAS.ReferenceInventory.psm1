#requires -Version 5.1

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/eMAS.SafeXml.ps1')

$script:eMASReferenceXLinkNamespace = 'http://www.w3c.org/1999/xlink'

function Get-eMASReferenceOrdinalSortedObjects {
    param(
        [AllowEmptyCollection()][object[]] $Objects,
        [Parameter(Mandatory = $true)][string] $SortProperty
    )

    $byKey = @{}
    $keys = New-Object System.Collections.ArrayList
    $position = 0
    foreach ($item in @($Objects)) {
        $key = '{0}{1}{2:D8}' -f ([string]$item.$SortProperty), [char]0, $position
        $byKey[$key] = $item
        [void]$keys.Add($key)
        $position++
    }
    $sortedKeys = [string[]]@($keys)
    [System.Array]::Sort($sortedKeys, [System.StringComparer]::Ordinal)
    $result = New-Object System.Collections.ArrayList
    foreach ($key in $sortedKeys) { [void]$result.Add($byKey[$key]) }
    return @($result)
}

function Get-eMASReferenceAttributeValue {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Element,
        [Parameter(Mandatory = $true)][string] $LocalName,
        [AllowEmptyString()][string] $NamespaceUri = ''
    )

    $attribute = $Element.GetAttributeNode($LocalName, $NamespaceUri)
    if ($null -eq $attribute) { return $null }
    return $attribute.Value
}

function Get-eMASLeafReferenceDescriptors {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Document,
        [Parameter(Mandatory = $true)][ValidateSet('CommonBackbone', 'RegionalBackbone')][string] $XmlKind
    )

    # The historical ICH and EU profiles both declare unqualified leaf elements,
    # while xlink:href is explicitly read by namespace URI.
    $nodes = @($Document.SelectNodes("//*[local-name()='leaf' and namespace-uri()='']"))
    $descriptors = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $nodes.Count; $index++) {
        $leaf = [System.Xml.XmlElement]$nodes[$index]
        [void]$descriptors.Add([pscustomobject][ordered]@{
            XmlKind = $XmlKind
            SourceElement = $leaf.LocalName
            SourceElementNamespaceUri = $leaf.NamespaceURI
            SourcePosition = $index + 1
            SourceElementId = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'ID'
            RawHref = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'href' -NamespaceUri $script:eMASReferenceXLinkNamespace
            DeclaredChecksumAlgorithm = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'checksum-type'
            DeclaredChecksum = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'checksum'
            Operation = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'operation'
            ModifiedFileRawPath = Get-eMASReferenceAttributeValue -Element $leaf -LocalName 'modified-file'
        })
    }
    return @($descriptors)
}

function Get-eMASCommonBackboneReferenceDescriptors {
    param([Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Document)
    return @(Get-eMASLeafReferenceDescriptors -Document $Document -XmlKind 'CommonBackbone')
}

function Get-eMASRegionalBackboneReferenceDescriptors {
    param([Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Document)
    return @(Get-eMASLeafReferenceDescriptors -Document $Document -XmlKind 'RegionalBackbone')
}

function New-eMASReferenceCoverage {
    param(
        [Parameter(Mandatory = $true)][string] $XmlId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'ReferenceInventory'
        SubjectType = 'XmlDocument'
        SubjectId = $XmlId
        CaptureStatus = $CaptureStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Get-eMASReferenceUnavailableCoverage {
    param([Parameter(Mandatory = $true)][object] $XmlDocument)

    if ($XmlDocument.ParseStatus -eq 'Missing') {
        return New-eMASReferenceCoverage -XmlId $XmlDocument.XmlId -CaptureStatus 'InputUnavailable' -RecordsProduced 0 -ReasonCode 'SourceXmlMissing'
    }
    if ($XmlDocument.ParseStatus -eq 'ParseFailed' -or $XmlDocument.CaptureStatus -eq 'ParseFailed') {
        return New-eMASReferenceCoverage -XmlId $XmlDocument.XmlId -CaptureStatus 'ParseFailed' -RecordsProduced 0 -ReasonCode 'SourceXmlParseFailed'
    }
    if ($XmlDocument.CaptureStatus -eq 'AccessDenied') {
        return New-eMASReferenceCoverage -XmlId $XmlDocument.XmlId -CaptureStatus 'AccessDenied' -RecordsProduced 0 -ReasonCode 'SourceXmlAccessDenied'
    }
    if ($XmlDocument.CaptureStatus -eq 'InputUnavailable') {
        return New-eMASReferenceCoverage -XmlId $XmlDocument.XmlId -CaptureStatus 'InputUnavailable' -RecordsProduced 0 -ReasonCode 'SourceXmlUnavailable'
    }
    return New-eMASReferenceCoverage -XmlId $XmlDocument.XmlId -CaptureStatus 'NotCollected' -RecordsProduced 0 -ReasonCode 'SourceXmlNotParsed'
}

function Test-eMASReferenceOutputPath {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'REF-OUTPUT-001 OutputPath must not overwrite SourcePath.'
    }
    if ($SourceKind -eq 'Directory') {
        $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'REF-OUTPUT-002 OutputPath must not be inside SourcePath.'
        }
    }
    return $resolvedOutputPath
}

function Write-eMASReferenceInventoryResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function Read-eMASReferenceXmlDocument {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][object] $XmlDocument,
        [Parameter(Mandatory = $true)][object] $FileRecord,
        [AllowNull()][object] $ZipArchive
    )

    $stream = $null
    try {
        if ($SourceKind -eq 'Zip') {
            $entry = $null
            if (-not [string]::IsNullOrWhiteSpace([string]$FileRecord.ContainerPath)) {
                $entry = $ZipArchive.GetEntry([string]$FileRecord.ContainerPath)
            }
            if ($null -eq $entry) {
                return [pscustomobject][ordered]@{ CaptureStatus = 'InputUnavailable'; Document = $null; ReasonCode = 'SourceXmlZipEntryUnavailable' }
            }
            $stream = $entry.Open()
        }
        else {
            $platformRelativePath = ([string]$XmlDocument.RelativePath) -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $xmlPath = [System.IO.Path]::GetFullPath((Join-Path $ResolvedSourcePath $platformRelativePath))
            $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $xmlPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                return [pscustomobject][ordered]@{ CaptureStatus = 'NotCollected'; Document = $null; ReasonCode = 'SourceXmlPathOutsideSource'
                }
            }
            if (-not [System.IO.File]::Exists($xmlPath)) {
                return [pscustomobject][ordered]@{ CaptureStatus = 'InputUnavailable'; Document = $null; ReasonCode = 'SourceXmlUnavailable' }
            }
            $fileInfo = New-Object System.IO.FileInfo($xmlPath)
            if (($fileInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                return [pscustomobject][ordered]@{ CaptureStatus = 'NotCollected'; Document = $null; ReasonCode = 'SourceXmlReparsePointNotTraversed' }
            }
            $stream = [System.IO.File]::Open($xmlPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        }

        $loadResult = Read-eMASSafeXmlDocument -Stream $stream
        if ($loadResult.ParseStatus -ne 'Parsed') {
            return [pscustomobject][ordered]@{ CaptureStatus = 'ParseFailed'; Document = $null; ReasonCode = 'SourceXmlParseFailedOnExtraction' }
        }
        return [pscustomobject][ordered]@{ CaptureStatus = 'Available'; Document = $loadResult.Document; ReasonCode = $null }
    }
    catch [System.UnauthorizedAccessException] {
        return [pscustomobject][ordered]@{ CaptureStatus = 'AccessDenied'; Document = $null; ReasonCode = 'SourceXmlAccessDenied' }
    }
    catch {
        return [pscustomobject][ordered]@{ CaptureStatus = 'InputUnavailable'; Document = $null; ReasonCode = 'SourceXmlReadFailed' }
    }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Invoke-eMASReferenceInventory {
    <#
    .SYNOPSIS
    Adds factual raw leaf-reference records to accepted BackboneXmlInventory output.

    .DESCRIPTION
    Processes only successfully parsed CommonBackbone and RegionalBackbone documents selected
    by BackboneXmlInventory. It preserves raw leaf attributes and deliberately performs no
    target resolution, checksum calculation/comparison, lifecycle resolution, or classification.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $RepositoryDiscoveryResult,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $BackboneXmlInventoryResult,
        [AllowNull()][string] $OutputPath
    )

    if ($RepositoryDiscoveryResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0' -or $BackboneXmlInventoryResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'REF-INPUT-001 Input uses an unsupported contract.'
    }
    if ($RepositoryDiscoveryResult.Execution.Phase -ne 'PreSales' -or $RepositoryDiscoveryResult.Execution.ScenarioId -ne 'MS-04' -or
        $BackboneXmlInventoryResult.Execution.Phase -ne 'PreSales' -or $BackboneXmlInventoryResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'REF-INPUT-002 Inputs are not MS-04 PreSales results.'
    }
    if (-not ($BackboneXmlInventoryResult.Execution.PSObject.Properties.Name -contains 'Capabilities') -or
        @($BackboneXmlInventoryResult.Execution.Capabilities) -notcontains 'BackboneXmlInventory') {
        throw 'REF-INPUT-003 BackboneXmlInventoryResult does not declare the accepted capability.'
    }
    if ([string]$RepositoryDiscoveryResult.Repository.SourceSha256 -ne [string]$BackboneXmlInventoryResult.Repository.SourceSha256 -or
        @($RepositoryDiscoveryResult.Files).Count -ne @($BackboneXmlInventoryResult.Files).Count) {
        throw 'REF-INPUT-004 RepositoryDiscovery and BackboneXmlInventory results do not describe the same source.'
    }

    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    if (-not [System.IO.File]::Exists($resolvedSourcePath) -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'REF-SOURCE-001 SourcePath does not exist.'
    }
    $sourceKind = [string]$RepositoryDiscoveryResult.Repository.SourceKind
    if ($sourceKind -eq 'Directory' -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'REF-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -eq 'Zip' -and (-not [System.IO.File]::Exists($resolvedSourcePath) -or [System.IO.Path]::GetExtension($resolvedSourcePath) -ine '.zip')) {
        throw 'REF-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -ne 'Directory' -and $sourceKind -ne 'Zip') {
        throw 'REF-SOURCE-003 Only directory and top-level ZIP discovery results are supported.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASReferenceOutputPath -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath
    }

    $workingResult = ($BackboneXmlInventoryResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $fileById = @{}
    foreach ($file in @($RepositoryDiscoveryResult.Files)) { $fileById[[string]$file.FileId] = $file }
    $dossierPathById = @{}
    foreach ($dossier in @($BackboneXmlInventoryResult.DossierCandidates)) { $dossierPathById[[string]$dossier.DossierId] = [string]$dossier.RelativePath }

    $supportedDocuments = @($BackboneXmlInventoryResult.XmlDocuments | Where-Object { $_.XmlKind -eq 'CommonBackbone' -or $_.XmlKind -eq 'RegionalBackbone' })
    $documentDescriptors = New-Object System.Collections.ArrayList
    foreach ($xmlDocument in $supportedDocuments) {
        $dossierPath = ''
        if ($dossierPathById.ContainsKey([string]$xmlDocument.DossierId)) { $dossierPath = $dossierPathById[[string]$xmlDocument.DossierId] }
        [void]$documentDescriptors.Add([pscustomobject][ordered]@{
            SortKey = ('{0}{1}{2}{1}{3}' -f $dossierPath, [char]0, [string]$xmlDocument.SequencePath, [string]$xmlDocument.RelativePath)
            XmlDocument = $xmlDocument
        })
    }
    $documentDescriptors = @(Get-eMASReferenceOrdinalSortedObjects -Objects @($documentDescriptors) -SortProperty 'SortKey')

    $rawDescriptors = New-Object System.Collections.ArrayList
    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -eq 'ReferenceResolution' -or $item.CheckId -eq 'DeclaredChecksumComparison' -or $item.CheckId -eq 'LifecycleLinkResolution') {
            [void]$coverage.Add([pscustomobject][ordered]@{
                CheckId = $item.CheckId
                SubjectType = $item.SubjectType
                SubjectId = $item.SubjectId
                CaptureStatus = 'NotCollected'
                RecordsProduced = 0
                ReasonCode = 'OutsideReferenceInventoryScope'
            })
        }
        else { [void]$coverage.Add($item) }
    }
    if (@($coverage | Where-Object { $_.CheckId -eq 'FileReferenceOrphanCorrelation' }).Count -eq 0) {
        [void]$coverage.Add([pscustomobject][ordered]@{
            CheckId = 'FileReferenceOrphanCorrelation'
            SubjectType = 'Repository'
            SubjectId = 'REP-0001'
            CaptureStatus = 'NotCollected'
            RecordsProduced = 0
            ReasonCode = 'OutsideReferenceInventoryScope'
        })
    }

    $zipStream = $null
    $zipArchive = $null
    try {
        if ($sourceKind -eq 'Zip') {
            try { Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue } catch { }
            try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
            $zipStream = New-Object System.IO.FileStream($resolvedSourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        }

        foreach ($documentDescriptor in $documentDescriptors) {
            $xmlDocument = $documentDescriptor.XmlDocument
            if ($xmlDocument.ParseStatus -ne 'Parsed' -or $xmlDocument.CaptureStatus -ne 'Available') {
                [void]$coverage.Add((Get-eMASReferenceUnavailableCoverage -XmlDocument $xmlDocument))
                continue
            }
            if ([string]::IsNullOrWhiteSpace([string]$xmlDocument.FileId) -or -not $fileById.ContainsKey([string]$xmlDocument.FileId)) {
                [void]$coverage.Add((New-eMASReferenceCoverage -XmlId $xmlDocument.XmlId -CaptureStatus 'InputUnavailable' -RecordsProduced 0 -ReasonCode 'SourceXmlFileRecordUnavailable'))
                continue
            }

            $readResult = Read-eMASReferenceXmlDocument -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -XmlDocument $xmlDocument -FileRecord $fileById[[string]$xmlDocument.FileId] -ZipArchive $zipArchive
            if ($readResult.CaptureStatus -ne 'Available') {
                [void]$coverage.Add((New-eMASReferenceCoverage -XmlId $xmlDocument.XmlId -CaptureStatus $readResult.CaptureStatus -RecordsProduced 0 -ReasonCode $readResult.ReasonCode))
                continue
            }

            $xmlReferences = @()
            if ($xmlDocument.XmlKind -eq 'CommonBackbone') {
                $xmlReferences = @(Get-eMASCommonBackboneReferenceDescriptors -Document $readResult.Document)
            }
            else {
                $xmlReferences = @(Get-eMASRegionalBackboneReferenceDescriptors -Document $readResult.Document)
            }
            foreach ($rawReference in $xmlReferences) {
                $rawHrefSort = $(if ($null -eq $rawReference.RawHref) { '' } else { [string]$rawReference.RawHref })
                [void]$rawDescriptors.Add([pscustomobject][ordered]@{
                    SortKey = ('{0}{1}{2:D8}{1}{3}' -f $documentDescriptor.SortKey, [char]0, [int]$rawReference.SourcePosition, $rawHrefSort)
                    XmlId = $xmlDocument.XmlId
                    DossierId = $xmlDocument.DossierId
                    SequenceId = $xmlDocument.SequenceId
                    XmlKind = $xmlDocument.XmlKind
                    SourceElement = $rawReference.SourceElement
                    SourceElementNamespaceUri = $rawReference.SourceElementNamespaceUri
                    SourcePosition = $rawReference.SourcePosition
                    SourceElementId = $rawReference.SourceElementId
                    RawHref = $rawReference.RawHref
                    DeclaredChecksumAlgorithm = $rawReference.DeclaredChecksumAlgorithm
                    DeclaredChecksum = $rawReference.DeclaredChecksum
                    Operation = $rawReference.Operation
                    ModifiedFileRawPath = $rawReference.ModifiedFileRawPath
                })
            }
            [void]$coverage.Add((New-eMASReferenceCoverage -XmlId $xmlDocument.XmlId -CaptureStatus 'Available' -RecordsProduced $xmlReferences.Count -ReasonCode $null))
        }
    }
    finally {
        if ($null -ne $zipArchive) { $zipArchive.Dispose() }
        if ($null -ne $zipStream) { $zipStream.Dispose() }
    }

    $sortedRawDescriptors = @(Get-eMASReferenceOrdinalSortedObjects -Objects @($rawDescriptors) -SortProperty 'SortKey')
    $references = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $sortedRawDescriptors.Count; $index++) {
        $raw = $sortedRawDescriptors[$index]
        [void]$references.Add([pscustomobject][ordered]@{
            ReferenceId = 'REF-{0:D4}' -f ($index + 1)
            XmlId = $raw.XmlId
            DossierId = $raw.DossierId
            SequenceId = $raw.SequenceId
            XmlKind = $raw.XmlKind
            SourceElement = $raw.SourceElement
            SourceElementNamespaceUri = $raw.SourceElementNamespaceUri
            SourcePosition = $raw.SourcePosition
            SourceElementId = $raw.SourceElementId
            RawHref = $raw.RawHref
            NormalizedTargetPath = $null
            TargetFileId = $null
            TargetExists = $null
            DeclaredChecksumAlgorithm = $raw.DeclaredChecksumAlgorithm
            DeclaredChecksum = $raw.DeclaredChecksum
            CalculatedChecksum = $null
            ChecksumMatch = $null
            Operation = $raw.Operation
            ModifiedFileRawPath = $raw.ModifiedFileRawPath
            CaptureStatus = 'Available'
        })
    }

    $perXmlReferenceCoverage = @($coverage | Where-Object { $_.CheckId -eq 'ReferenceInventory' -and $_.SubjectType -eq 'XmlDocument' })
    $referenceInventoryStatus = 'Available'
    if (@($perXmlReferenceCoverage | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { $referenceInventoryStatus = 'AccessDenied' }
    elseif (@($perXmlReferenceCoverage | Where-Object { $_.CaptureStatus -eq 'InputUnavailable' }).Count -gt 0) { $referenceInventoryStatus = 'InputUnavailable' }
    elseif (@($perXmlReferenceCoverage | Where-Object { $_.CaptureStatus -eq 'ParseFailed' }).Count -gt 0) { $referenceInventoryStatus = 'ParseFailed' }
    elseif (@($perXmlReferenceCoverage | Where-Object { $_.CaptureStatus -eq 'NotCollected' }).Count -gt 0) { $referenceInventoryStatus = 'NotCollected' }
    [void]$coverage.Add([pscustomobject][ordered]@{
        CheckId = 'ReferenceInventory'
        SubjectType = 'Repository'
        SubjectId = 'REP-0001'
        CaptureStatus = $referenceInventoryStatus
        RecordsProduced = $references.Count
        ReasonCode = $(if ($referenceInventoryStatus -eq 'Available') { $null } else { 'OneOrMoreSourceXmlDocumentsUnavailable' })
    })

    $workingResult.References = [object[]]@($references)
    $workingResult.LifecycleRelationships = [object[]]@()
    $workingResult.ClassificationEvidence = [object[]]@()
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory'
    $workingResult.Execution.ScannerVersion = '0.3.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory')
    $referenceCoverageGaps = @($perXmlReferenceCoverage | Where-Object { $_.CaptureStatus -ne 'Available' }).Count
    $workingResult.Execution.CompletionStatus = $(if ($referenceCoverageGaps -gt 0) { 'CompletedWithCollectionGaps' } else { 'Completed' })

    if ($null -ne $resolvedOutputPath) {
        Write-eMASReferenceInventoryResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASReferenceInventory
