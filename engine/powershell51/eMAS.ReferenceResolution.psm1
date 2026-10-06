#requires -Version 5.1

Set-StrictMode -Version 2.0

function Get-eMASResolutionParentPath {
    param([AllowEmptyString()][string] $RelativePath)

    if ([string]::IsNullOrEmpty($RelativePath) -or -not $RelativePath.Contains('/')) { return '' }
    return $RelativePath.Substring(0, $RelativePath.LastIndexOf('/'))
}

function Join-eMASResolutionRelativePath {
    param([AllowEmptyString()][string] $Parent, [AllowEmptyString()][string] $Child)

    if ([string]::IsNullOrEmpty($Parent)) { return $Child }
    if ([string]::IsNullOrEmpty($Child)) { return $Parent }
    return ('{0}/{1}' -f $Parent, $Child)
}

function Test-eMASResolutionPathIsAtOrBelow {
    param([AllowEmptyString()][string] $Path, [AllowEmptyString()][string] $Ancestor)

    if ([string]::IsNullOrEmpty($Ancestor)) { return $true }
    if ($Path.Equals($Ancestor, [System.StringComparison]::Ordinal)) { return $true }
    return $Path.StartsWith(($Ancestor + '/'), [System.StringComparison]::Ordinal)
}

function New-eMASResolutionOutcome {
    param(
        [Parameter(Mandatory = $true)][string] $ResolutionStatus,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [AllowNull()][object] $NormalizedTargetPath,
        [AllowNull()][string] $DiagnosticCode
    )

    return [pscustomobject][ordered]@{
        ResolutionStatus = $ResolutionStatus
        CaptureStatus = $CaptureStatus
        NormalizedTargetPath = $NormalizedTargetPath
        DiagnosticCode = $(if ([string]::IsNullOrWhiteSpace($DiagnosticCode)) { $null } else { $DiagnosticCode })
    }
}

function Resolve-eMASReferencePath {
    param(
        [AllowNull()][object] $RawHref,
        [Parameter(Mandatory = $true)][string] $XmlPathRelativeToDossier
    )

    if ($null -eq $RawHref) {
        return New-eMASResolutionOutcome -ResolutionStatus 'NotApplicable' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'NoPhysicalHref'
    }
    $rawHrefText = [string]$RawHref
    if ($rawHrefText.Length -eq 0) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'EmptyHref'
    }
    if ($rawHrefText -match '[\x00-\x1F\x7F]') {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'ControlCharacterNotAllowed'
    }
    if ($rawHrefText.StartsWith('\\') -or $rawHrefText.StartsWith('//')) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsafePath' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'UncPathNotAllowed'
    }
    if ($rawHrefText -match '^[A-Za-z]:[\\/]') {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsafePath' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'DriveQualifiedPathNotAllowed'
    }
    if ($rawHrefText.StartsWith('/')) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsafePath' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'AbsolutePathNotAllowed'
    }
    if ($rawHrefText -match '^(?i:https?)://') {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'NetworkUriNotAllowed'
    }
    if ($rawHrefText -match '^[A-Za-z][A-Za-z0-9+.-]*:') {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'UnsupportedUriScheme'
    }
    if ($rawHrefText.Contains('\')) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsafePath' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'BackslashPathNotAllowed'
    }
    if ($rawHrefText.Contains('?')) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'QueryComponentUnsupported'
    }
    if ($rawHrefText.Contains('%')) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'PercentEncodingUnsupported'
    }

    $fragmentIndex = $rawHrefText.IndexOf('#')
    $physicalPath = $(if ($fragmentIndex -ge 0) { $rawHrefText.Substring(0, $fragmentIndex) } else { $rawHrefText })
    if ($physicalPath.Length -eq 0 -and $fragmentIndex -ge 0) {
        return New-eMASResolutionOutcome -ResolutionStatus 'ResolvedPath' -CaptureStatus 'Available' -NormalizedTargetPath $XmlPathRelativeToDossier -DiagnosticCode $null
    }
    if ($physicalPath.Length -eq 0) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'EmptyPhysicalPath'
    }

    $segments = New-Object System.Collections.ArrayList
    $xmlParent = Get-eMASResolutionParentPath -RelativePath $XmlPathRelativeToDossier
    foreach ($segment in @($xmlParent -split '/')) {
        if (-not [string]::IsNullOrEmpty($segment)) { [void]$segments.Add($segment) }
    }
    foreach ($segment in @($physicalPath -split '/')) {
        if ([string]::IsNullOrEmpty($segment)) {
            return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'EmptyPathSegmentUnsupported'
        }
        if ($segment -eq '.') { continue }
        if ($segment -eq '..') {
            if ($segments.Count -eq 0) {
                return New-eMASResolutionOutcome -ResolutionStatus 'UnsafePath' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'PathEscapesDossier'
            }
            $segments.RemoveAt($segments.Count - 1)
            continue
        }
        [void]$segments.Add($segment)
    }
    if ($segments.Count -eq 0) {
        return New-eMASResolutionOutcome -ResolutionStatus 'UnsupportedUri' -CaptureStatus 'NotApplicable' -NormalizedTargetPath $null -DiagnosticCode 'EmptyNormalizedTarget'
    }
    return New-eMASResolutionOutcome -ResolutionStatus 'ResolvedPath' -CaptureStatus 'Available' -NormalizedTargetPath (($segments | ForEach-Object { [string]$_ }) -join '/') -DiagnosticCode $null
}

function New-eMASResolutionCoverage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'Reference')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'ReferenceResolution'
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Test-eMASResolutionOutputPath {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'RES-OUTPUT-001 OutputPath must not overwrite SourcePath.'
    }
    if ($SourceKind -eq 'Directory') {
        $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'RES-OUTPUT-002 OutputPath must not be inside SourcePath.'
        }
    }
    return $resolvedOutputPath
}

function Write-eMASReferenceResolutionResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function Invoke-eMASReferenceResolution {
    <#
    .SYNOPSIS
    Resolves accepted raw href records to bounded dossier-relative repository objects.

    .DESCRIPTION
    Consumes RepositoryDiscovery and ReferenceInventory results without parsing XML or opening
    target files. Resolution uses the containing XML directory and the accepted file inventory.
    It does not evaluate missing-reference findings, checksums, lifecycle links, or orphan files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $RepositoryDiscoveryResult,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $ReferenceInventoryResult,
        [AllowNull()][string] $OutputPath
    )

    if ($RepositoryDiscoveryResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0' -or $ReferenceInventoryResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'RES-INPUT-001 Input uses an unsupported contract.'
    }
    if ($RepositoryDiscoveryResult.Execution.Phase -ne 'PreSales' -or $RepositoryDiscoveryResult.Execution.ScenarioId -ne 'MS-04' -or
        $ReferenceInventoryResult.Execution.Phase -ne 'PreSales' -or $ReferenceInventoryResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'RES-INPUT-002 Inputs are not MS-04 PreSales results.'
    }
    if (-not ($ReferenceInventoryResult.Execution.PSObject.Properties.Name -contains 'Capabilities') -or
        @($ReferenceInventoryResult.Execution.Capabilities) -notcontains 'ReferenceInventory') {
        throw 'RES-INPUT-003 ReferenceInventoryResult does not declare the accepted capability.'
    }
    if ([string]$RepositoryDiscoveryResult.Repository.SourceSha256 -ne [string]$ReferenceInventoryResult.Repository.SourceSha256 -or
        @($RepositoryDiscoveryResult.Files).Count -ne @($ReferenceInventoryResult.Files).Count) {
        throw 'RES-INPUT-004 RepositoryDiscovery and ReferenceInventory results do not describe the same source.'
    }

    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    if (-not [System.IO.File]::Exists($resolvedSourcePath) -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'RES-SOURCE-001 SourcePath does not exist.'
    }
    $sourceKind = [string]$RepositoryDiscoveryResult.Repository.SourceKind
    if ($sourceKind -eq 'Directory' -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) {
        throw 'RES-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -eq 'Zip' -and (-not [System.IO.File]::Exists($resolvedSourcePath) -or [System.IO.Path]::GetExtension($resolvedSourcePath) -ine '.zip')) {
        throw 'RES-SOURCE-002 SourcePath does not match the discovery source kind.'
    }
    if ($sourceKind -ne 'Directory' -and $sourceKind -ne 'Zip') {
        throw 'RES-SOURCE-003 Only directory and top-level ZIP discovery results are supported.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASResolutionOutputPath -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath
    }

    $workingResult = ($ReferenceInventoryResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $xmlById = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    foreach ($xmlDocument in @($ReferenceInventoryResult.XmlDocuments)) { $xmlById[[string]$xmlDocument.XmlId] = $xmlDocument }
    $dossierById = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    foreach ($dossier in @($ReferenceInventoryResult.DossierCandidates)) { $dossierById[[string]$dossier.DossierId] = $dossier }
    $fileByPath = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    foreach ($file in @($RepositoryDiscoveryResult.Files)) {
        $path = [string]$file.RelativePath
        if ($fileByPath.ContainsKey($path)) { throw ('RES-INPUT-005 Duplicate file path in RepositoryDiscoveryResult: {0}' -f $path) }
        $fileByPath.Add($path, $file)
    }

    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -eq 'ReferenceResolution') { continue }
        if ($item.CheckId -eq 'DeclaredChecksumComparison' -or $item.CheckId -eq 'LifecycleLinkResolution' -or $item.CheckId -eq 'FileReferenceOrphanCorrelation') {
            [void]$coverage.Add([pscustomobject][ordered]@{
                CheckId = $item.CheckId
                SubjectType = $item.SubjectType
                SubjectId = $item.SubjectId
                CaptureStatus = 'NotCollected'
                RecordsProduced = 0
                ReasonCode = 'OutsideReferenceResolutionScope'
            })
        }
        else { [void]$coverage.Add($item) }
    }
    if (@($coverage | Where-Object { $_.CheckId -eq 'MissingReferenceInterpretation' }).Count -eq 0) {
        [void]$coverage.Add([pscustomobject][ordered]@{
            CheckId = 'MissingReferenceInterpretation'
            SubjectType = 'Repository'
            SubjectId = 'REP-0001'
            CaptureStatus = 'NotCollected'
            RecordsProduced = 0
            ReasonCode = 'OutsideReferenceResolutionScope'
        })
    }

    $resolvedReferences = New-Object System.Collections.ArrayList
    foreach ($reference in @($workingResult.References)) {
        $captureStatus = 'InputUnavailable'
        $resolutionStatus = 'InputUnavailable'
        $diagnosticCode = 'SourceRelationshipUnavailable'
        $normalizedTargetPath = $null
        $targetFileId = $null
        $targetExists = $null

        if (-not $xmlById.ContainsKey([string]$reference.XmlId) -or -not $dossierById.ContainsKey([string]$reference.DossierId)) {
            $captureStatus = 'InputUnavailable'
            $resolutionStatus = 'InputUnavailable'
            $diagnosticCode = 'SourceRelationshipUnavailable'
        }
        else {
            $xmlDocument = $xmlById[[string]$reference.XmlId]
            $dossier = $dossierById[[string]$reference.DossierId]
            $dossierPath = [string]$dossier.RelativePath
            $xmlRepositoryPath = [string]$xmlDocument.RelativePath
            if (-not (Test-eMASResolutionPathIsAtOrBelow -Path $xmlRepositoryPath -Ancestor $dossierPath) -or $xmlRepositoryPath.Equals($dossierPath, [System.StringComparison]::Ordinal)) {
                $captureStatus = 'InputUnavailable'
                $resolutionStatus = 'InputUnavailable'
                $diagnosticCode = 'SourceXmlOutsideDossier'
            }
            else {
                $xmlPathRelativeToDossier = $xmlRepositoryPath.Substring($dossierPath.Length + 1)
                $pathOutcome = Resolve-eMASReferencePath -RawHref $reference.RawHref -XmlPathRelativeToDossier $xmlPathRelativeToDossier
                $captureStatus = $pathOutcome.CaptureStatus
                $resolutionStatus = $pathOutcome.ResolutionStatus
                $diagnosticCode = $pathOutcome.DiagnosticCode
                $normalizedTargetPath = $pathOutcome.NormalizedTargetPath

                if ($pathOutcome.ResolutionStatus -eq 'ResolvedPath') {
                    $repositoryTargetPath = Join-eMASResolutionRelativePath -Parent $dossierPath -Child $normalizedTargetPath
                    if (-not (Test-eMASResolutionPathIsAtOrBelow -Path $repositoryTargetPath -Ancestor $dossierPath)) {
                        $captureStatus = 'NotApplicable'
                        $resolutionStatus = 'UnsafePath'
                        $diagnosticCode = 'PathEscapesDossier'
                        $normalizedTargetPath = $null
                    }
                    elseif ($fileByPath.ContainsKey($repositoryTargetPath)) {
                        $targetFile = $fileByPath[$repositoryTargetPath]
                        $targetFileId = $targetFile.FileId
                        if ($targetFile.CaptureStatus -eq 'Available') {
                            $targetExists = $true
                            $captureStatus = 'Available'
                            $resolutionStatus = 'ResolvedPresent'
                            $diagnosticCode = $null
                        }
                        elseif ($targetFile.CaptureStatus -eq 'AccessDenied') {
                            $captureStatus = 'AccessDenied'
                            $resolutionStatus = 'AccessDenied'
                            $diagnosticCode = 'TargetInventoryAccessDenied'
                        }
                        else {
                            $captureStatus = 'InputUnavailable'
                            $resolutionStatus = 'InputUnavailable'
                            $diagnosticCode = 'TargetInventoryUnavailable'
                        }
                    }
                    elseif ($RepositoryDiscoveryResult.Repository.InventoryCaptureStatus -ne 'Available') {
                        $captureStatus = [string]$RepositoryDiscoveryResult.Repository.InventoryCaptureStatus
                        if ($captureStatus -ne 'AccessDenied') { $captureStatus = 'InputUnavailable' }
                        $resolutionStatus = $captureStatus
                        $diagnosticCode = 'RepositoryInventoryIncomplete'
                    }
                    else {
                        $relevantErrors = @($RepositoryDiscoveryResult.Repository.Errors | Where-Object {
                            -not [string]::IsNullOrWhiteSpace([string]$_.RelativePath) -and
                            (Test-eMASResolutionPathIsAtOrBelow -Path $repositoryTargetPath -Ancestor ([string]$_.RelativePath))
                        })
                        if (@($relevantErrors | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) {
                            $captureStatus = 'AccessDenied'
                            $resolutionStatus = 'AccessDenied'
                            $diagnosticCode = 'TargetInventoryAccessDenied'
                        }
                        elseif ($relevantErrors.Count -gt 0) {
                            $captureStatus = 'InputUnavailable'
                            $resolutionStatus = 'InputUnavailable'
                            $diagnosticCode = 'TargetInventoryUnavailable'
                        }
                        else {
                            $targetExists = $false
                            $captureStatus = 'Available'
                            $resolutionStatus = 'ResolvedAbsent'
                            $diagnosticCode = $null
                        }
                    }
                }
            }
        }

        [void]$resolvedReferences.Add([pscustomobject][ordered]@{
            ReferenceId = $reference.ReferenceId
            XmlId = $reference.XmlId
            DossierId = $reference.DossierId
            SequenceId = $reference.SequenceId
            XmlKind = $reference.XmlKind
            SourceElement = $reference.SourceElement
            SourceElementNamespaceUri = $reference.SourceElementNamespaceUri
            SourcePosition = $reference.SourcePosition
            SourceElementId = $reference.SourceElementId
            RawHref = $reference.RawHref
            NormalizedTargetPath = $normalizedTargetPath
            TargetFileId = $targetFileId
            TargetExists = $targetExists
            DeclaredChecksumAlgorithm = $reference.DeclaredChecksumAlgorithm
            DeclaredChecksum = $reference.DeclaredChecksum
            CalculatedChecksum = $null
            ChecksumMatch = $null
            Operation = $reference.Operation
            ModifiedFileRawPath = $reference.ModifiedFileRawPath
            ResolutionStatus = $resolutionStatus
            ResolutionDiagnosticCode = $diagnosticCode
            CaptureStatus = $captureStatus
        })
        [void]$coverage.Add((New-eMASResolutionCoverage -SubjectType 'Reference' -SubjectId $reference.ReferenceId -CaptureStatus $captureStatus -RecordsProduced 1 -ReasonCode $diagnosticCode))
    }

    $referenceCoverage = @($coverage | Where-Object { $_.CheckId -eq 'ReferenceResolution' -and $_.SubjectType -eq 'Reference' })
    $repositoryCaptureStatus = 'Available'
    if (@($referenceCoverage | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { $repositoryCaptureStatus = 'AccessDenied' }
    elseif (@($referenceCoverage | Where-Object { $_.CaptureStatus -eq 'InputUnavailable' -or $_.CaptureStatus -eq 'ParseFailed' -or $_.CaptureStatus -eq 'NotCollected' }).Count -gt 0) { $repositoryCaptureStatus = 'InputUnavailable' }
    [void]$coverage.Add((New-eMASResolutionCoverage -SubjectType 'Repository' -SubjectId 'REP-0001' -CaptureStatus $repositoryCaptureStatus -RecordsProduced $resolvedReferences.Count -ReasonCode $(if ($repositoryCaptureStatus -eq 'Available') { $null } else { 'OneOrMoreReferenceResolutionsUnavailable' })))

    $workingResult.References = [object[]]@($resolvedReferences)
    $workingResult.LifecycleRelationships = [object[]]@()
    $workingResult.ClassificationEvidence = [object[]]@()
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution'
    $workingResult.Execution.ScannerVersion = '0.4.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution')
    $workingResult.Execution.CompletionStatus = $(if ($repositoryCaptureStatus -eq 'Available') { 'Completed' } else { 'CompletedWithCollectionGaps' })

    if ($null -ne $resolvedOutputPath) {
        Write-eMASReferenceResolutionResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASReferenceResolution
