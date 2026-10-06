#requires -Version 5.1

Set-StrictMode -Version 2.0

function New-eMASChecksumOutcome {
    param(
        [Parameter(Mandatory = $true)][string] $Status,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [AllowNull()][object] $CalculatedChecksum,
        [AllowNull()][object] $ChecksumMatch,
        [AllowNull()][string] $DiagnosticCode
    )

    return [pscustomobject][ordered]@{
        Status = $Status
        CaptureStatus = $CaptureStatus
        CalculatedChecksum = $CalculatedChecksum
        ChecksumMatch = $ChecksumMatch
        DiagnosticCode = $(if ([string]::IsNullOrWhiteSpace($DiagnosticCode)) { $null } else { $DiagnosticCode })
    }
}

function Test-eMASChecksumPortablePath {
    param([Parameter(Mandatory = $true)][string] $RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $false }
    if ($RelativePath.StartsWith('/') -or $RelativePath.StartsWith('\')) { return $false }
    if ($RelativePath.Contains('\') -or $RelativePath -match '^[A-Za-z]:') { return $false }
    foreach ($segment in @($RelativePath -split '/')) {
        if ([string]::IsNullOrEmpty($segment) -or $segment -eq '.' -or $segment -eq '..') { return $false }
    }
    return $true
}

function ConvertTo-eMASLowerHex {
    param([Parameter(Mandatory = $true)][byte[]] $Bytes)
    return (($Bytes | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Get-eMASDirectoryTargetMD5 {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][string] $RepositoryRelativePath
    )

    if (-not (Test-eMASChecksumPortablePath -RelativePath $RepositoryRelativePath)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetIdentityUnsafe'
    }
    $platformRelativePath = $RepositoryRelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $ResolvedSourcePath $platformRelativePath))
    $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $targetPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetOutsideSourceBoundary'
    }

    $stream = $null
    $algorithm = $null
    try {
        $stream = [System.IO.File]::Open($targetPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $algorithm = [System.Security.Cryptography.MD5]::Create()
        $hash = ConvertTo-eMASLowerHex -Bytes $algorithm.ComputeHash($stream)
        return New-eMASChecksumOutcome -Status 'Calculated' -CaptureStatus 'Available' -CalculatedChecksum $hash -ChecksumMatch $null -DiagnosticCode $null
    }
    catch [System.UnauthorizedAccessException] {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'AccessDenied' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetAccessDenied'
    }
    catch {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetReadFailed'
    }
    finally {
        if ($null -ne $algorithm) { $algorithm.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Get-eMASZipTargetMD5 {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][string] $RepositoryRelativePath
    )

    if (-not (Test-eMASChecksumPortablePath -RelativePath $RepositoryRelativePath)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetIdentityUnsafe'
    }

    $zipStream = $null
    $archive = $null
    $entryStream = $null
    $algorithm = $null
    try {
        try { Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue } catch { }
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        $zipStream = [System.IO.File]::Open($ResolvedSourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
        $entries = @($archive.Entries | Where-Object { $_.FullName.Equals($RepositoryRelativePath, [System.StringComparison]::Ordinal) })
        if ($entries.Count -ne 1 -or $entries[0].FullName.EndsWith('/')) {
            return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetEntryUnavailable'
        }
        $entryStream = $entries[0].Open()
        $algorithm = [System.Security.Cryptography.MD5]::Create()
        $hash = ConvertTo-eMASLowerHex -Bytes $algorithm.ComputeHash($entryStream)
        return New-eMASChecksumOutcome -Status 'Calculated' -CaptureStatus 'Available' -CalculatedChecksum $hash -ChecksumMatch $null -DiagnosticCode $null
    }
    catch [System.UnauthorizedAccessException] {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'AccessDenied' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetAccessDenied'
    }
    catch {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetReadFailed'
    }
    finally {
        if ($null -ne $algorithm) { $algorithm.Dispose() }
        if ($null -ne $entryStream) { $entryStream.Dispose() }
        if ($null -ne $archive) { $archive.Dispose() }
        if ($null -ne $zipStream) { $zipStream.Dispose() }
    }
}

function Get-eMASChecksumReferenceOutcome {
    param(
        [Parameter(Mandatory = $true)][object] $Reference,
        [Parameter(Mandatory = $true)][object] $FileById,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath
    )

    if ([string]$Reference.ResolutionStatus -eq 'NotApplicable' -or [string]::IsNullOrWhiteSpace([string]$Reference.RawHref)) {
        return New-eMASChecksumOutcome -Status 'NotApplicable' -CaptureStatus 'NotApplicable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'NoPhysicalHref'
    }
    if ([string]::IsNullOrWhiteSpace([string]$Reference.DeclaredChecksum)) {
        return New-eMASChecksumOutcome -Status 'NotApplicable' -CaptureStatus 'NotApplicable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'NoDeclaredChecksum'
    }
    if ([string]::IsNullOrWhiteSpace([string]$Reference.DeclaredChecksumAlgorithm)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'MissingDeclaredAlgorithm'
    }
    if (-not ([string]$Reference.DeclaredChecksumAlgorithm).Trim().Equals('MD5', [System.StringComparison]::OrdinalIgnoreCase)) {
        return New-eMASChecksumOutcome -Status 'Unsupported' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'UnsupportedAlgorithm'
    }
    if (-not ([string]$Reference.DeclaredChecksum -match '^[0-9A-Fa-f]{32}$')) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'InvalidDeclaredChecksum'
    }
    if ($Reference.TargetExists -is [bool] -and -not [bool]$Reference.TargetExists -and [string]$Reference.ResolutionStatus -eq 'ResolvedAbsent') {
        # Confirmed absence is not a checksum collection failure: no physical target exists to hash.
        # Missing-target interpretation remains owned by MissingReferenceInterpretation.
        return New-eMASChecksumOutcome -Status 'NotApplicable' -CaptureStatus 'NotApplicable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetAbsent'
    }
    if ([string]$Reference.ResolutionStatus -eq 'AccessDenied' -or [string]$Reference.CaptureStatus -eq 'AccessDenied') {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'AccessDenied' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetAccessDenied'
    }
    if (-not ($Reference.TargetExists -is [bool]) -or -not [bool]$Reference.TargetExists -or [string]$Reference.ResolutionStatus -ne 'ResolvedPresent') {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetUnavailable'
    }
    if ([string]::IsNullOrWhiteSpace([string]$Reference.NormalizedTargetPath) -or [string]::IsNullOrWhiteSpace([string]$Reference.TargetFileId)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'ResolutionEvidenceIncomplete'
    }
    if (-not $FileById.ContainsKey([string]$Reference.TargetFileId)) {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetFileIdentityUnavailable'
    }

    $file = $FileById[[string]$Reference.TargetFileId]
    if ([string]$file.CaptureStatus -eq 'AccessDenied') {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'AccessDenied' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetAccessDenied'
    }
    if ([string]$file.CaptureStatus -ne 'Available') {
        return New-eMASChecksumOutcome -Status 'NotAssessed' -CaptureStatus 'InputUnavailable' -CalculatedChecksum $null -ChecksumMatch $null -DiagnosticCode 'TargetUnavailable'
    }

    $calculation = $(if ($SourceKind -eq 'Zip') {
        Get-eMASZipTargetMD5 -ResolvedSourcePath $ResolvedSourcePath -RepositoryRelativePath ([string]$file.RelativePath)
    }
    else {
        Get-eMASDirectoryTargetMD5 -ResolvedSourcePath $ResolvedSourcePath -RepositoryRelativePath ([string]$file.RelativePath)
    })
    if ($calculation.Status -ne 'Calculated') { return $calculation }

    $isChecksumMatch = ([string]$calculation.CalculatedChecksum).Equals([string]$Reference.DeclaredChecksum, [System.StringComparison]::OrdinalIgnoreCase)
    return New-eMASChecksumOutcome `
        -Status $(if ($isChecksumMatch) { 'Matched' } else { 'Mismatched' }) `
        -CaptureStatus 'Available' `
        -CalculatedChecksum ([string]$calculation.CalculatedChecksum) `
        -ChecksumMatch $isChecksumMatch `
        -DiagnosticCode $null
}

function New-eMASChecksumCoverage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'Reference')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][string] $ComparisonStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'DeclaredChecksumComparison'
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        ComparisonStatus = $ComparisonStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Test-eMASChecksumOutputPath {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSourcePath,
        [Parameter(Mandatory = $true)][ValidateSet('Directory', 'Zip')][string] $SourceKind,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'DCC-OUTPUT-001 OutputPath must not overwrite SourcePath.'
    }
    if ($SourceKind -eq 'Directory') {
        $sourcePrefix = $ResolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolvedOutputPath.Equals($ResolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'DCC-OUTPUT-002 OutputPath must not be inside SourcePath.'
        }
    }
    return $resolvedOutputPath
}

function Write-eMASDeclaredChecksumComparisonResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function Invoke-eMASDeclaredChecksumComparison {
    <#
    .SYNOPSIS
    Calculates and compares declared MD5 checksums for safely resolved present reference targets.

    .DESCRIPTION
    Consumes the accepted chain through MissingReferenceInterpretation. It reads only targets already
    linked by ReferenceResolution and emits factual checksum evidence without mismatch findings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $MissingReferenceInterpretationResult,
        [AllowNull()][string] $OutputPath
    )

    if ($MissingReferenceInterpretationResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'DCC-INPUT-001 Input uses an unsupported contract.'
    }
    if ($MissingReferenceInterpretationResult.Execution.Phase -ne 'PreSales' -or $MissingReferenceInterpretationResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'DCC-INPUT-002 Input is not an MS-04 PreSales result.'
    }
    if (-not ($MissingReferenceInterpretationResult.Execution.PSObject.Properties.Name -contains 'Capabilities') -or
        @($MissingReferenceInterpretationResult.Execution.Capabilities) -notcontains 'ReferenceResolution' -or
        @($MissingReferenceInterpretationResult.Execution.Capabilities) -notcontains 'MissingReferenceInterpretation') {
        throw 'DCC-INPUT-003 Input does not declare the accepted prerequisite capabilities.'
    }
    if (@($MissingReferenceInterpretationResult.Execution.Capabilities) -contains 'DeclaredChecksumComparison') {
        throw 'DCC-INPUT-004 Input already declares DeclaredChecksumComparison.'
    }

    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    $sourceKind = [string]$MissingReferenceInterpretationResult.Repository.SourceKind
    if ($sourceKind -eq 'Directory' -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) { throw 'DCC-SOURCE-001 Directory SourcePath does not exist.' }
    if ($sourceKind -eq 'Zip' -and (-not [System.IO.File]::Exists($resolvedSourcePath) -or [System.IO.Path]::GetExtension($resolvedSourcePath) -ine '.zip')) { throw 'DCC-SOURCE-002 ZIP SourcePath does not exist or is not a ZIP.' }
    if ($sourceKind -ne 'Directory' -and $sourceKind -ne 'Zip') { throw 'DCC-SOURCE-003 Only directory and top-level ZIP sources are supported.' }
    $acceptedSourcePath = [string]$MissingReferenceInterpretationResult.Repository.ResolvedSourcePath
    if (-not [string]::IsNullOrWhiteSpace($acceptedSourcePath) -and -not $resolvedSourcePath.Equals([System.IO.Path]::GetFullPath($acceptedSourcePath), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'DCC-SOURCE-004 SourcePath does not match the accepted repository source.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASChecksumOutputPath -ResolvedSourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath
    }

    $workingResult = ($MissingReferenceInterpretationResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $fileById = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
    foreach ($file in @($workingResult.Files)) {
        $fileId = [string]$file.FileId
        if ([string]::IsNullOrWhiteSpace($fileId)) { throw 'DCC-INPUT-005 File observation without FileId.' }
        if ($fileById.ContainsKey($fileId)) { throw ('DCC-INPUT-006 Duplicate FileId: {0}' -f $fileId) }
        $fileById.Add($fileId, $file)
    }

    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -ne 'DeclaredChecksumComparison') { [void]$coverage.Add($item) }
    }
    foreach ($futureCheck in @('ChecksumMismatchInterpretation', 'ZeroByteInterpretation')) {
        if (@($coverage | Where-Object { $_.CheckId -eq $futureCheck }).Count -eq 0) {
            [void]$coverage.Add([pscustomobject][ordered]@{
                CheckId = $futureCheck
                SubjectType = 'Repository'
                SubjectId = 'REP-0001'
                CaptureStatus = 'NotCollected'
                RecordsProduced = 0
                ReasonCode = 'OutsideDeclaredChecksumComparisonScope'
            })
        }
    }

    $processedReferences = New-Object System.Collections.ArrayList
    $outcomes = New-Object System.Collections.ArrayList
    foreach ($reference in @($workingResult.References)) {
        $outcome = Get-eMASChecksumReferenceOutcome `
            -Reference $reference `
            -FileById $fileById `
            -SourceKind $sourceKind `
            -ResolvedSourcePath $resolvedSourcePath
        [void]$outcomes.Add($outcome)
        $reference.CalculatedChecksum = $outcome.CalculatedChecksum
        $reference.ChecksumMatch = $outcome.ChecksumMatch
        $reference | Add-Member -NotePropertyName ChecksumComparisonStatus -NotePropertyValue $outcome.Status -Force
        $reference | Add-Member -NotePropertyName ChecksumDiagnosticCode -NotePropertyValue $outcome.DiagnosticCode -Force
        [void]$processedReferences.Add($reference)
        [void]$coverage.Add((New-eMASChecksumCoverage `
            -SubjectType 'Reference' `
            -SubjectId ([string]$reference.ReferenceId) `
            -CaptureStatus ([string]$outcome.CaptureStatus) `
            -ComparisonStatus ([string]$outcome.Status) `
            -RecordsProduced $(if ($outcome.Status -eq 'Matched' -or $outcome.Status -eq 'Mismatched') { 1 } else { 0 }) `
            -ReasonCode $outcome.DiagnosticCode))
    }

    $successful = @($outcomes | Where-Object { $_.Status -eq 'Matched' -or $_.Status -eq 'Mismatched' })
    $notApplicable = @($outcomes | Where-Object { $_.Status -eq 'NotApplicable' })
    $notAssessed = @($outcomes | Where-Object { $_.Status -eq 'NotAssessed' -or $_.Status -eq 'Unsupported' })
    $collectionStatus = 'Collected'
    $repositoryCaptureStatus = 'Available'
    $repositoryReasonCode = $null
    if ($notAssessed.Count -gt 0 -and $successful.Count -gt 0) {
        $collectionStatus = 'Partial'
        $repositoryCaptureStatus = $(if (@($notAssessed | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } else { 'InputUnavailable' })
        $repositoryReasonCode = 'OneOrMoreChecksumComparisonsNotAssessed'
    }
    elseif ($notAssessed.Count -gt 0 -and $successful.Count -eq 0) {
        $collectionStatus = 'NotAssessed'
        $repositoryCaptureStatus = $(if (@($notAssessed | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } else { 'InputUnavailable' })
        $repositoryReasonCode = 'NoChecksumComparisonCouldBeCompleted'
    }
    [void]$coverage.Add((New-eMASChecksumCoverage `
        -SubjectType 'Repository' `
        -SubjectId 'REP-0001' `
        -CaptureStatus $repositoryCaptureStatus `
        -ComparisonStatus $collectionStatus `
        -RecordsProduced $successful.Count `
        -ReasonCode $repositoryReasonCode))

    $workingResult.References = [object[]]@($processedReferences)
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation+DeclaredChecksumComparison'
    $workingResult.Execution.ScannerVersion = '0.6.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation', 'DeclaredChecksumComparison')
    if ($workingResult.Execution.CompletionStatus -eq 'Completed' -and $collectionStatus -ne 'Collected') {
        $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps'
    }

    if ($null -ne $resolvedOutputPath) {
        Write-eMASDeclaredChecksumComparisonResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASDeclaredChecksumComparison
