#requires -Version 5.1

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/eMAS.SafeXml.ps1')

function ConvertTo-eMASXmlRelativePath {
    param([AllowEmptyString()][string] $Path)

    $normalized = ($Path -replace '\\', '/').Trim('/')
    if ([string]::IsNullOrEmpty($normalized)) { return '' }
    foreach ($segment in @($normalized -split '/')) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.' -or $segment -eq '..') {
            throw ('XML-PATH-001 Unsafe relative path was encountered: {0}' -f $Path)
        }
    }
    return $normalized
}

function Get-eMASXmlParentPath {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath) -or -not $RelativePath.Contains('/')) { return '' }
    return $RelativePath.Substring(0, $RelativePath.LastIndexOf('/'))
}

function Get-eMASXmlLeafName {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath) -or -not $RelativePath.Contains('/')) { return $RelativePath }
    return $RelativePath.Substring($RelativePath.LastIndexOf('/') + 1)
}

function Join-eMASXmlRelativePath {
    param([AllowEmptyString()][string] $Parent, [Parameter(Mandatory = $true)][string] $Child)

    if ([string]::IsNullOrEmpty($Parent)) { return $Child }
    return ('{0}/{1}' -f $Parent, $Child)
}

function Test-eMASXmlPathIsDescendantOf {
    param([AllowEmptyString()][string] $Path, [AllowEmptyString()][string] $Ancestor)

    if ([string]::IsNullOrEmpty($Ancestor)) { return -not [string]::IsNullOrEmpty($Path) }
    return $Path.StartsWith(($Ancestor + '/'), [System.StringComparison]::Ordinal)
}

function Get-eMASXmlOrdinalSortedObjects {
    param(
        [AllowEmptyCollection()][object[]] $Objects,
        [string] $PrimaryProperty = 'RelativePath',
        [string] $SecondaryProperty = 'XmlKind'
    )

    $indexed = @{}
    $keys = New-Object System.Collections.ArrayList
    $position = 0
    foreach ($item in @($Objects)) {
        $primary = [string]$item.$PrimaryProperty
        $secondary = ''
        if ($item.PSObject.Properties.Name -contains $SecondaryProperty) {
            $secondary = [string]$item.$SecondaryProperty
        }
        $key = '{0}{1}{2}{1}{3:D8}' -f $primary, [char]0, $secondary, $position
        $indexed[$key] = $item
        [void]$keys.Add($key)
        $position++
    }
    $sortedKeys = [string[]]@($keys)
    [System.Array]::Sort($sortedKeys, [System.StringComparer]::Ordinal)
    $result = New-Object System.Collections.ArrayList
    foreach ($key in $sortedKeys) { [void]$result.Add($indexed[$key]) }
    return @($result)
}

function Get-eMASXmlRootAttributes {
    param([Parameter(Mandatory = $true)][System.Xml.XmlElement] $RootElement)

    $descriptors = New-Object System.Collections.ArrayList
    foreach ($attribute in $RootElement.Attributes) {
        [void]$descriptors.Add([pscustomobject][ordered]@{
            SortKey = ('{0}{1}{2}' -f $attribute.Name, [char]0, $attribute.NamespaceURI)
            Name = $attribute.Name
            LocalName = $attribute.LocalName
            NamespaceUri = $attribute.NamespaceURI
            Value = $attribute.Value
        })
    }
    $sorted = @(Get-eMASXmlOrdinalSortedObjects -Objects @($descriptors) -PrimaryProperty 'SortKey' -SecondaryProperty 'Name')
    return @($sorted | ForEach-Object {
        [pscustomobject][ordered]@{
            Name = $_.Name
            LocalName = $_.LocalName
            NamespaceUri = $_.NamespaceUri
            Value = $_.Value
        }
    })
}

function Read-eMASXmlMetadata {
    param([Parameter(Mandatory = $true)][System.IO.Stream] $Stream)

    $loadResult = Read-eMASSafeXmlDocument -Stream $Stream
    if ($loadResult.ParseStatus -eq 'Parsed') {
        $document = $loadResult.Document

        $declaration = $null
        foreach ($node in $document.ChildNodes) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::XmlDeclaration) {
                $declaration = $node
                break
            }
        }
        $documentType = $document.DocumentType
        $declaredVersion = $document.DocumentElement.GetAttribute('dtd-version')
        if ([string]::IsNullOrEmpty($declaredVersion)) { $declaredVersion = $null }

        return [pscustomobject][ordered]@{
            ParseStatus = 'Parsed'
            CaptureStatus = 'Available'
            RootElement = $document.DocumentElement.LocalName
            NamespaceUri = $document.DocumentElement.NamespaceURI
            RootAttributes = [object[]](Get-eMASXmlRootAttributes -RootElement $document.DocumentElement)
            DeclaredVersion = $declaredVersion
            XmlDeclarationVersion = $(if ($null -ne $declaration) { $declaration.Version } else { $null })
            DeclaredEncoding = $(if ($null -ne $declaration -and -not [string]::IsNullOrWhiteSpace($declaration.Encoding)) { $declaration.Encoding } else { $null })
            Standalone = $(if ($null -ne $declaration -and -not [string]::IsNullOrWhiteSpace($declaration.Standalone)) { $declaration.Standalone } else { $null })
            HasDocumentType = ($null -ne $documentType)
            DocumentTypeName = $(if ($null -ne $documentType) { $documentType.Name } else { $null })
            PublicId = $(if ($null -ne $documentType -and -not [string]::IsNullOrWhiteSpace($documentType.PublicId)) { $documentType.PublicId } else { $null })
            SystemId = $(if ($null -ne $documentType -and -not [string]::IsNullOrWhiteSpace($documentType.SystemId)) { $documentType.SystemId } else { $null })
            ParseErrorCode = $null
            ParseErrorLineNumber = $null
            ParseErrorLinePosition = $null
            Diagnostic = $null
        }
    }
    else {
        return [pscustomobject][ordered]@{
            ParseStatus = 'ParseFailed'
            CaptureStatus = 'ParseFailed'
            RootElement = $null
            NamespaceUri = $null
            RootAttributes = [object[]]@()
            DeclaredVersion = $null
            XmlDeclarationVersion = $null
            DeclaredEncoding = $null
            Standalone = $null
            HasDocumentType = $null
            DocumentTypeName = $null
            PublicId = $null
            SystemId = $null
            ParseErrorCode = $loadResult.ParseErrorCode
            ParseErrorLineNumber = $loadResult.ParseErrorLineNumber
            ParseErrorLinePosition = $loadResult.ParseErrorLinePosition
            Diagnostic = $loadResult.Diagnostic
        }
    }
}

function New-eMASXmlUnavailableMetadata {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Missing', 'NotAttempted')][string] $ParseStatus,
        [Parameter(Mandatory = $true)][ValidateSet('Available', 'InputUnavailable', 'AccessDenied', 'NotCollected')][string] $CaptureStatus,
        [AllowNull()][string] $ErrorCode,
        [AllowNull()][string] $Diagnostic
    )

    return [pscustomobject][ordered]@{
        ParseStatus = $ParseStatus
        CaptureStatus = $CaptureStatus
        RootElement = $null
        NamespaceUri = $null
        RootAttributes = [object[]]@()
        DeclaredVersion = $null
        XmlDeclarationVersion = $null
        DeclaredEncoding = $null
        Standalone = $null
        HasDocumentType = $null
        DocumentTypeName = $null
        PublicId = $null
        SystemId = $null
        ParseErrorCode = $(if ([string]::IsNullOrWhiteSpace($ErrorCode)) { $null } else { $ErrorCode })
        ParseErrorLineNumber = $null
        ParseErrorLinePosition = $null
        Diagnostic = $(if ([string]::IsNullOrWhiteSpace($Diagnostic)) { $null } else { $Diagnostic })
    }
}

function Get-eMASXmlDescriptors {
    param([Parameter(Mandatory = $true)][object] $RepositoryDiscoveryResult)

    $fileByPath = @{}
    foreach ($file in @($RepositoryDiscoveryResult.Files)) { $fileByPath[[string]$file.RelativePath] = $file }

    $candidateById = @{}
    foreach ($candidate in @($RepositoryDiscoveryResult.DossierCandidates)) { $candidateById[[string]$candidate.DossierId] = $candidate }

    $exactSequences = @($RepositoryDiscoveryResult.Sequences | Where-Object { $_.IsExactSequenceFolder })
    $exactSequences = @(Get-eMASXmlOrdinalSortedObjects -Objects $exactSequences)
    $descriptors = New-Object System.Collections.ArrayList
    $descriptorByPath = @{}

    foreach ($sequence in $exactSequences) {
        $commonPath = Join-eMASXmlRelativePath -Parent $sequence.RelativePath -Child 'index.xml'
        $regionalPath = Join-eMASXmlRelativePath -Parent $sequence.RelativePath -Child 'm1/eu/eu-regional.xml'
        foreach ($specification in @(
            [pscustomobject]@{ RelativePath = $commonPath; XmlKind = 'CommonBackbone' },
            [pscustomobject]@{ RelativePath = $regionalPath; XmlKind = 'RegionalBackbone' }
        )) {
            $fileRecord = $null
            if ($fileByPath.ContainsKey($specification.RelativePath)) { $fileRecord = $fileByPath[$specification.RelativePath] }
            $descriptor = [pscustomobject][ordered]@{
                DossierId = $sequence.DossierId
                SequenceId = $sequence.SequenceId
                SequencePath = $sequence.RelativePath
                RelativePath = $specification.RelativePath
                XmlKind = $specification.XmlKind
                FileRecord = $fileRecord
            }
            [void]$descriptors.Add($descriptor)
            $descriptorByPath[$specification.RelativePath] = $descriptor
        }
    }

    foreach ($candidate in @(Get-eMASXmlOrdinalSortedObjects -Objects @($RepositoryDiscoveryResult.DossierCandidates))) {
        foreach ($file in @(Get-eMASXmlOrdinalSortedObjects -Objects @($RepositoryDiscoveryResult.Files))) {
            if ([System.IO.Path]::GetExtension([string]$file.RelativePath) -ine '.xml') { continue }
            if (-not (Test-eMASXmlPathIsDescendantOf -Path $file.RelativePath -Ancestor $candidate.RelativePath)) { continue }
            if ($descriptorByPath.ContainsKey([string]$file.RelativePath)) { continue }

            $matchedSequence = $null
            foreach ($sequence in $exactSequences) {
                if ($sequence.DossierId -eq $candidate.DossierId -and (Test-eMASXmlPathIsDescendantOf -Path $file.RelativePath -Ancestor $sequence.RelativePath)) {
                    $matchedSequence = $sequence
                    break
                }
            }
            $isDossierRootXml = (Get-eMASXmlParentPath -RelativePath $file.RelativePath) -eq $candidate.RelativePath
            if ($null -eq $matchedSequence -and -not $isDossierRootXml) { continue }

            $descriptor = [pscustomobject][ordered]@{
                DossierId = $candidate.DossierId
                SequenceId = $(if ($null -ne $matchedSequence) { $matchedSequence.SequenceId } else { $null })
                SequencePath = $(if ($null -ne $matchedSequence) { $matchedSequence.RelativePath } else { $null })
                RelativePath = $file.RelativePath
                XmlKind = 'Other'
                FileRecord = $file
            }
            [void]$descriptors.Add($descriptor)
            $descriptorByPath[$file.RelativePath] = $descriptor
        }
    }
    return @(Get-eMASXmlOrdinalSortedObjects -Objects @($descriptors))
}

function Test-eMASXmlOutputPath {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'XML-OUTPUT-001 OutputPath must not overwrite SourcePath.'
    }
    if ($SourceKind -eq 'Directory') {
        $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'XML-OUTPUT-002 OutputPath must not be inside SourcePath.'
        }
    }
    return $resolvedOutputPath
}

function Write-eMASBackboneXmlInventoryResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function Get-eMASXmlCoverageStatus {
    param([AllowEmptyCollection()][object[]] $Documents)

    if (@($Documents | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { return 'AccessDenied' }
    if (@($Documents | Where-Object { $_.CaptureStatus -eq 'InputUnavailable' }).Count -gt 0) { return 'InputUnavailable' }
    if (@($Documents | Where-Object { $_.CaptureStatus -eq 'ParseFailed' }).Count -gt 0) { return 'ParseFailed' }
    if (@($Documents | Where-Object { $_.CaptureStatus -eq 'NotCollected' }).Count -gt 0) { return 'NotCollected' }
    return 'Available'
}

function Invoke-eMASBackboneXmlInventory {
    <#
    .SYNOPSIS
    Adds safe Backbone XML inventory and parse-status facts to RepositoryDiscovery output.

    .DESCRIPTION
    Consumes the accepted RepositoryDiscovery result instead of rediscovering the repository.
    It opens only XML files identified by that result, disables external XML resolution, and
    records physical XML identity metadata without region/format classification or references.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $RepositoryDiscoveryResult,
        [AllowNull()][string] $OutputPath
    )

    if ($RepositoryDiscoveryResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'XML-INPUT-001 RepositoryDiscoveryResult uses an unsupported contract.'
    }
    if ($RepositoryDiscoveryResult.Execution.Phase -ne 'PreSales' -or $RepositoryDiscoveryResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'XML-INPUT-002 RepositoryDiscoveryResult is not an MS-04 PreSales result.'
    }

    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    if (-not [System.IO.File]::Exists($resolvedSourcePath) -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'XML-SOURCE-001 SourcePath does not exist.'
    }
    $sourceKind = [string]$RepositoryDiscoveryResult.Repository.SourceKind
    if ($sourceKind -eq 'Directory' -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'XML-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -eq 'Zip' -and (-not [System.IO.File]::Exists($resolvedSourcePath) -or [System.IO.Path]::GetExtension($resolvedSourcePath) -ine '.zip')) {
        throw 'XML-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -ne 'Directory' -and $sourceKind -ne 'Zip') {
        throw 'XML-SOURCE-003 Only directory and top-level ZIP discovery results are supported.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASXmlOutputPath -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath
    }

    $workingResult = ($RepositoryDiscoveryResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $descriptors = @(Get-eMASXmlDescriptors -RepositoryDiscoveryResult $workingResult)
    $xmlDocuments = New-Object System.Collections.ArrayList
    $zipStream = $null
    $zipArchive = $null

    try {
        if ($sourceKind -eq 'Zip') {
            try { Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue } catch { }
            try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
            $zipStream = New-Object System.IO.FileStream($resolvedSourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        }

        for ($index = 0; $index -lt $descriptors.Count; $index++) {
            $descriptor = $descriptors[$index]
            $metadata = $null
            $exists = $null -ne $descriptor.FileRecord
            if (-not $exists) {
                $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'Missing' -CaptureStatus 'Available' -ErrorCode $null -Diagnostic $null
            }
            elseif ($sourceKind -eq 'Zip') {
                $entry = $null
                if ($descriptor.FileRecord.PSObject.Properties.Name -contains 'ContainerPath' -and -not [string]::IsNullOrWhiteSpace([string]$descriptor.FileRecord.ContainerPath)) {
                    $entry = $zipArchive.GetEntry([string]$descriptor.FileRecord.ContainerPath)
                }
                if ($null -eq $entry) {
                    $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'InputUnavailable' -ErrorCode 'XML-ZIP-ENTRY-001' -Diagnostic 'The XML entry identified by RepositoryDiscovery was unavailable when opened.'
                }
                else {
                    $entryStream = $null
                    try {
                        $entryStream = $entry.Open()
                        $metadata = Read-eMASXmlMetadata -Stream $entryStream
                    }
                    catch [System.UnauthorizedAccessException] {
                        $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'AccessDenied' -ErrorCode 'XML-ACCESS-001' -Diagnostic 'Access to the discovered XML entry was denied.'
                    }
                    catch {
                        $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'InputUnavailable' -ErrorCode 'XML-READ-001' -Diagnostic (ConvertTo-eMASSafeXmlDiagnosticMessage -Message $_.Exception.Message)
                    }
                    finally {
                        if ($null -ne $entryStream) { $entryStream.Dispose() }
                    }
                }
            }
            else {
                $platformRelativePath = $descriptor.RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
                $xmlPath = [System.IO.Path]::GetFullPath((Join-Path $resolvedSourcePath $platformRelativePath))
                $sourcePrefix = $resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
                if (-not $xmlPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'NotCollected' -ErrorCode 'XML-PATH-002' -Diagnostic 'The discovered XML path did not remain inside SourcePath.'
                }
                elseif (-not [System.IO.File]::Exists($xmlPath)) {
                    $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'InputUnavailable' -ErrorCode 'XML-FILE-001' -Diagnostic 'The XML file identified by RepositoryDiscovery was unavailable when opened.'
                }
                else {
                    $fileInfo = New-Object System.IO.FileInfo($xmlPath)
                    if (($fileInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                        $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'NotCollected' -ErrorCode 'XML-REPARSE-001' -Diagnostic 'XML symbolic links and reparse points are not traversed.'
                    }
                    else {
                        $fileStream = $null
                        try {
                            $fileStream = [System.IO.File]::Open($xmlPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
                            $metadata = Read-eMASXmlMetadata -Stream $fileStream
                        }
                        catch [System.UnauthorizedAccessException] {
                            $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'AccessDenied' -ErrorCode 'XML-ACCESS-001' -Diagnostic 'Access to the discovered XML file was denied.'
                        }
                        catch {
                            $metadata = New-eMASXmlUnavailableMetadata -ParseStatus 'NotAttempted' -CaptureStatus 'InputUnavailable' -ErrorCode 'XML-READ-001' -Diagnostic (ConvertTo-eMASSafeXmlDiagnosticMessage -Message $_.Exception.Message)
                        }
                        finally {
                            if ($null -ne $fileStream) { $fileStream.Dispose() }
                        }
                    }
                }
            }

            [void]$xmlDocuments.Add([pscustomobject][ordered]@{
                XmlId = 'XML-{0:D4}' -f ($index + 1)
                DossierId = $descriptor.DossierId
                SequenceId = $descriptor.SequenceId
                SequencePath = $descriptor.SequencePath
                FileId = $(if ($exists) { $descriptor.FileRecord.FileId } else { $null })
                RelativePath = $descriptor.RelativePath
                FileName = Get-eMASXmlLeafName -RelativePath $descriptor.RelativePath
                XmlKind = $descriptor.XmlKind
                RoleBasis = 'PhysicalPathAndName'
                Exists = $exists
                ParseStatus = $metadata.ParseStatus
                RootElement = $metadata.RootElement
                NamespaceUri = $metadata.NamespaceUri
                RootAttributes = [object[]]$metadata.RootAttributes
                DeclaredVersion = $metadata.DeclaredVersion
                XmlDeclarationVersion = $metadata.XmlDeclarationVersion
                DeclaredEncoding = $metadata.DeclaredEncoding
                Standalone = $metadata.Standalone
                HasDocumentType = $metadata.HasDocumentType
                DocumentTypeName = $metadata.DocumentTypeName
                PublicId = $metadata.PublicId
                SystemId = $metadata.SystemId
                CaptureStatus = $metadata.CaptureStatus
                ParseErrorCode = $metadata.ParseErrorCode
                ParseErrorLineNumber = $metadata.ParseErrorLineNumber
                ParseErrorLinePosition = $metadata.ParseErrorLinePosition
                Diagnostic = $metadata.Diagnostic
            })
        }
    }
    finally {
        if ($null -ne $zipArchive) { $zipArchive.Dispose() }
        if ($null -ne $zipStream) { $zipStream.Dispose() }
    }

    $workingResult.XmlDocuments = [object[]]@($xmlDocuments)

    $observations = New-Object System.Collections.ArrayList
    foreach ($observation in @($workingResult.Observations)) { [void]$observations.Add($observation) }
    $missingDocuments = @($xmlDocuments | Where-Object { -not $_.Exists -and ($_.XmlKind -eq 'CommonBackbone' -or $_.XmlKind -eq 'RegionalBackbone') })
    $missingDocuments = @(Get-eMASXmlOrdinalSortedObjects -Objects $missingDocuments)
    foreach ($document in $missingDocuments) {
        $code = $(if ($document.XmlKind -eq 'CommonBackbone') { 'MissingCommonBackbone' } else { 'MissingRegionalBackbone' })
        [void]$observations.Add([pscustomobject][ordered]@{
            ObservationId = 'OBS-{0:D4}' -f ($observations.Count + 1)
            Category = 'Inventory'
            Code = $code
            SubjectType = 'Sequence'
            SubjectId = $document.SequenceId
            ObservedValue = $false
            CaptureStatus = 'Available'
            EvidenceIds = [object[]]@($document.XmlId)
        })
    }
    $workingResult.Observations = [object[]]@($observations)

    $commonDocuments = @($xmlDocuments | Where-Object { $_.XmlKind -eq 'CommonBackbone' })
    $regionalDocuments = @($xmlDocuments | Where-Object { $_.XmlKind -eq 'RegionalBackbone' })
    $commonCoverage = Get-eMASXmlCoverageStatus -Documents $commonDocuments
    $regionalCoverage = Get-eMASXmlCoverageStatus -Documents $regionalDocuments
    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -eq 'CommonXmlParse') {
            [void]$coverage.Add([pscustomobject][ordered]@{ CheckId = 'CommonXmlParse'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = $commonCoverage; RecordsProduced = $commonDocuments.Count; ReasonCode = $(if ($commonCoverage -eq 'Available') { $null } else { 'OneOrMoreDocumentsUnavailableOrUnparseable' }) })
        }
        elseif ($item.CheckId -eq 'RegionalXmlParse') {
            [void]$coverage.Add([pscustomobject][ordered]@{ CheckId = 'RegionalXmlParse'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = $regionalCoverage; RecordsProduced = $regionalDocuments.Count; ReasonCode = $(if ($regionalCoverage -eq 'Available') { $null } else { 'OneOrMoreDocumentsUnavailableOrUnparseable' }) })
        }
        else { [void]$coverage.Add($item) }
    }
    $workingResult.CollectionCoverage = [object[]]@($coverage)

    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory'
    $workingResult.Execution.ScannerVersion = '0.2.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    if ($workingResult.Execution.PSObject.Properties.Name -contains 'Capabilities') {
        $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory')
    }
    else {
        $workingResult.Execution | Add-Member -MemberType NoteProperty -Name Capabilities -Value ([object[]]@('RepositoryDiscovery', 'BackboneXmlInventory'))
    }
    $gapCount = @($xmlDocuments | Where-Object { $_.CaptureStatus -ne 'Available' }).Count
    $workingResult.Execution.CompletionStatus = $(if ($gapCount -gt 0) { 'CompletedWithCollectionGaps' } else { 'Completed' })

    if ($null -ne $resolvedOutputPath) {
        Write-eMASBackboneXmlInventoryResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASBackboneXmlInventory
