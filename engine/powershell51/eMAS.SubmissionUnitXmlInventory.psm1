#requires -Version 5.1

Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'private/eMAS.SafeXml.ps1')
. (Join-Path $PSScriptRoot 'private/eMAS.Ectd4SubmissionUnit.ps1')

$script:eMASSuxiFieldCodes = @('ECTD4_IG_OID','ECTD4_SU_TYPE','ECTD4_SUBMISSION_TYPE','ECTD4_APPLICATION_TYPE','ECTD4_SEQUENCE_NUMBER')

function Get-eMASSuxiPropertyValue {
    param([AllowNull()][object] $InputObject, [Parameter(Mandatory = $true)][string] $Name)
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function ConvertTo-eMASSuxiRelativePath {
    param([AllowEmptyString()][string] $Path)
    $normalized = ($Path -replace '\\', '/').Trim('/')
    foreach ($segment in @($normalized -split '/')) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.' -or $segment -eq '..') { throw ('SUXI-PATH-001 Unsafe relative path: {0}' -f $Path) }
    }
    return $normalized
}

function Get-eMASSuxiParentPath {
    param([AllowEmptyString()][string] $RelativePath)
    $position = $RelativePath.LastIndexOf('/')
    if ($position -lt 0) { return '' }
    return $RelativePath.Substring(0, $position)
}

function Get-eMASSuxiLeafName {
    param([AllowEmptyString()][string] $RelativePath)
    $position = $RelativePath.LastIndexOf('/')
    if ($position -lt 0) { return $RelativePath }
    return $RelativePath.Substring($position + 1)
}

function Join-eMASSuxiRelativePath {
    param([AllowEmptyString()][string] $Parent, [Parameter(Mandatory = $true)][string] $Child)
    if ([string]::IsNullOrEmpty($Parent)) { return $Child }
    return ('{0}/{1}' -f $Parent, $Child)
}

function Get-eMASSuxiSortedObjects {
    param([AllowEmptyCollection()][object[]] $Objects, [string] $Property = 'RelativePath')
    $byKey = @{}
    $keys = New-Object System.Collections.ArrayList
    $position = 0
    foreach ($item in @($Objects)) {
        $key = '{0}{1}{2:D8}' -f [string]$item.$Property, [char]0, $position
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

function Test-eMASSuxiOutputPath {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [Parameter(Mandatory = $true)][string] $SourceKind, [Parameter(Mandatory = $true)][string] $OutputPath)
    $resolved = [System.IO.Path]::GetFullPath($OutputPath)
    if ($SourceKind -eq 'Zip' -and $resolved.Equals($SourcePath, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'SUXI-OUTPUT-001 OutputPath must not overwrite SourcePath.' }
    if ($SourceKind -eq 'Directory') {
        $prefix = $SourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if ($resolved.Equals($SourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolved.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'SUXI-OUTPUT-002 OutputPath must not be inside SourcePath.' }
    }
    return $resolved
}

function Test-eMASSuxiReparsePath {
    param([Parameter(Mandatory = $true)][string] $SourceRoot, [Parameter(Mandatory = $true)][string] $TargetPath)
    $current = $TargetPath
    while (-not [string]::IsNullOrWhiteSpace($current) -and -not $current.Equals($SourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
        $current = [System.IO.Path]::GetDirectoryName($current)
    }
    return $false
}

function New-eMASSuxiNotAttemptedStructure {
    return [pscustomobject][ordered]@{
        RootLocalName = $null; RootNamespaceUri = $null; ItsVersion = $null; SchemaLocationDeclared = $null
        HasDocumentType = $null; SubmissionUnitCount = 0; StructureStatus = 'NotAttempted'
    }
}

function New-eMASSuxiDocument {
    param(
        [Parameter(Mandatory = $true)][string] $Id,
        [Parameter(Mandatory = $true)][object] $Descriptor,
        [Parameter(Mandatory = $true)][bool] $Exists,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][string] $ParseStatus,
        [AllowNull()][object] $Facts,
        [AllowNull()][string] $ParseErrorCode,
        [AllowNull()][object] $ParseErrorLineNumber,
        [AllowNull()][object] $ParseErrorLinePosition,
        [AllowNull()][string] $Diagnostic,
        [AllowEmptyCollection()][string[]] $AdditionalReasons = @()
    )

    $reasonCodes = New-Object System.Collections.ArrayList
    if ($null -ne $Facts) {
        foreach ($reason in @($Facts.Diagnostics.ReasonCodes)) { if (-not $reasonCodes.Contains([string]$reason)) { [void]$reasonCodes.Add([string]$reason) } }
    }
    foreach ($reason in @($AdditionalReasons)) { if (-not $reasonCodes.Contains($reason)) { [void]$reasonCodes.Add($reason) } }
    return [pscustomobject][ordered]@{
        SubmissionUnitXmlId = $Id
        DossierId = [string]$Descriptor.Sequence.DossierId
        SequenceId = [string]$Descriptor.Sequence.SequenceId
        UnitFolderKind = [string]$Descriptor.Sequence.SequenceLikeKind
        FileId = $(if ($null -ne $Descriptor.FileRecord) { [string]$Descriptor.FileRecord.FileId } else { $null })
        RelativePath = [string]$Descriptor.RelativePath
        Exists = $Exists
        CaptureStatus = $CaptureStatus
        ParseStatus = $ParseStatus
        ParseErrorCode = $(if ([string]::IsNullOrWhiteSpace($ParseErrorCode)) { $null } else { $ParseErrorCode })
        ParseErrorLineNumber = $ParseErrorLineNumber
        ParseErrorLinePosition = $ParseErrorLinePosition
        Diagnostic = $(if ([string]::IsNullOrWhiteSpace($Diagnostic)) { $null } else { $Diagnostic })
        SchemaValidation = 'NotEvaluated'
        Structure = $(if ($null -ne $Facts) { $Facts.Structure } else { New-eMASSuxiNotAttemptedStructure })
        VocabularyId = 'ECTD4-SUXI-VOCABULARY/1'
        ProfileStatus = $(if ($null -ne $Facts) { [string]$Facts.ProfileStatus } else { 'NotAttempted' })
        ProfileMarkers = [object[]]@($(if ($null -ne $Facts) { @($Facts.ProfileMarkers) } else { @() }))
        SubmissionUnit = $(if ($null -ne $Facts) { $Facts.SubmissionUnit } else { $null })
        Submissions = [object[]]@($(if ($null -ne $Facts) { @($Facts.Submissions) } else { @() }))
        Diagnostics = [pscustomobject][ordered]@{
            ContextOfUseCount = $(if ($null -ne $Facts) { [int]$Facts.Diagnostics.ContextOfUseCount } else { 0 })
            DocumentCount = $(if ($null -ne $Facts) { [int]$Facts.Diagnostics.DocumentCount } else { 0 })
            ProfileIdPresent = $(if ($null -ne $Facts) { [bool]$Facts.Diagnostics.ProfileIdPresent } else { $false })
            ReasonCodes = [object[]]@($reasonCodes)
        }
    }
}

function Get-eMASSuxiPrimaryReason {
    param([Parameter(Mandatory = $true)][object] $Document)
    $reasons = @($Document.Diagnostics.ReasonCodes)
    if ($reasons.Count -gt 0) { return [string]$reasons[0] }
    return $null
}

function Get-eMASSuxiDocumentCoverage {
    param([Parameter(Mandatory = $true)][object] $Document)
    $status = 'Collected'
    $reason = Get-eMASSuxiPrimaryReason -Document $Document
    if ($Document.ParseStatus -ne 'Parsed' -or $Document.CaptureStatus -ne 'Available' -or $Document.Structure.StructureStatus -ne 'Recognized') { $status = 'NotAssessed' }
    elseif ($null -eq $Document.SubmissionUnit -or $Document.ProfileStatus -ne 'MarkersRecognized') { $status = 'Partial' }
    elseif (@($Document.Diagnostics.ReasonCodes | Where-Object { $_ -notin @('ExternalReferenceNotResolved','ProfileSourceDraft','ProfileSourceUnpublished','RegionalCardinalityExceeded','SequenceNumberDiffersFromFolder','AmbiguousUnitFolder') }).Count -gt 0) { $status = 'Partial' }
    return [pscustomobject][ordered]@{
        CheckId = 'SubmissionUnitXmlInventory'; SubjectType = 'SubmissionUnitXml'; SubjectId = [string]$Document.SubmissionUnitXmlId
        CaptureStatus = [string]$Document.CaptureStatus; CollectionStatus = $status; RecordsProduced = 1
        ReasonCode = $reason; SchemaValidation = 'NotEvaluated'
    }
}

function Get-eMASSuxiFieldState {
    param([Parameter(Mandatory = $true)][object] $Document, [Parameter(Mandatory = $true)][string] $FieldCode)

    if ($Document.ParseStatus -ne 'Parsed' -or $Document.CaptureStatus -ne 'Available' -or $Document.Structure.StructureStatus -ne 'Recognized' -or $null -eq $Document.SubmissionUnit) {
        return [pscustomobject]@{ Status = 'NotAssessed'; Count = 0; Reason = Get-eMASSuxiPrimaryReason -Document $Document }
    }
    $values = @()
    switch ($FieldCode) {
        'ECTD4_IG_OID' { $values = @($Document.ProfileMarkers | ForEach-Object { [pscustomobject]@{ Status = [string]$_.Recognition } }) }
        'ECTD4_SU_TYPE' { $values = @([pscustomobject]@{ Status = [string]$Document.SubmissionUnit.Code.Recognition }) }
        'ECTD4_SUBMISSION_TYPE' { $values = @($Document.Submissions | ForEach-Object { [pscustomobject]@{ Status = [string]$_.Code.Recognition } }) }
        'ECTD4_APPLICATION_TYPE' { $values = @($Document.Submissions | ForEach-Object { $_.Applications } | ForEach-Object { [pscustomobject]@{ Status = [string]$_.Code.Recognition } }) }
        'ECTD4_SEQUENCE_NUMBER' { $values = @($Document.Submissions | ForEach-Object { [pscustomobject]@{ Status = [string]$_.SequenceNumber.ValueStatus } }) }
    }
    $recognizedNames = $(if ($FieldCode -eq 'ECTD4_IG_OID') { @('RecognizedIchIg','RecognizedRegionalIg') } elseif ($FieldCode -eq 'ECTD4_SEQUENCE_NUMBER') { @('WholeNumberInRange') } else { @('Known') })
    $recognized = @($values | Where-Object { $recognizedNames -contains $_.Status }).Count
    $bad = @($values | Where-Object { $recognizedNames -notcontains $_.Status })
    if ($bad.Count -eq 0 -and $values.Count -gt 0) { return [pscustomobject]@{ Status = 'Collected'; Count = $recognized; Reason = $null } }
    if ($recognized -gt 0) { return [pscustomobject]@{ Status = 'Partial'; Count = $recognized; Reason = [string]$bad[0].Status } }
    $badStatus = $(if ($bad.Count -gt 0) { [string]$bad[0].Status } else { 'MandatoryFieldAbsent' })
    $collectionStatus = $(if ($badStatus -eq 'Absent') { 'Collected' } else { 'NotAssessed' })
    $reason = $(if ($badStatus -eq 'Absent') { 'MandatoryFieldAbsent' } elseif ($badStatus -eq 'MultipleValues') { 'CardinalityViolation' } elseif ($badStatus -eq 'Empty') { 'UnrecognizedProfileMarker' } else { $badStatus })
    return [pscustomobject]@{ Status = $collectionStatus; Count = 0; Reason = $reason }
}

function Get-eMASSuxiCoverageRows {
    param([Parameter(Mandatory = $true)][object] $Document)
    $rows = New-Object System.Collections.ArrayList
    [void]$rows.Add((Get-eMASSuxiDocumentCoverage -Document $Document))
    foreach ($fieldCode in $script:eMASSuxiFieldCodes) {
        $state = Get-eMASSuxiFieldState -Document $Document -FieldCode $fieldCode
        [void]$rows.Add([pscustomobject][ordered]@{
            CheckId = ('SubmissionUnitXmlField:{0}' -f $fieldCode); SubjectType = 'SubmissionUnitXml'; SubjectId = [string]$Document.SubmissionUnitXmlId
            CaptureStatus = [string]$Document.CaptureStatus; CollectionStatus = [string]$state.Status; RecordsProduced = [int]$state.Count; ReasonCode = $state.Reason
        })
    }
    return @($rows)
}

function Write-eMASSuxiResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)
    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-eMASSubmissionUnitXmlInventory {
    <#
    .SYNOPSIS
    Adds optional, factual eCTD v4 submissionunit.xml inventory to an MS-04 scanner result.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $SourcePath,
        [Parameter(Mandatory = $true)][Alias('BackboneXmlInventoryResult','RepositoryDiscoveryResult')][ValidateNotNull()][object] $InputResult,
        [AllowNull()][string] $OutputPath
    )

    if ($InputResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') { throw 'SUXI-INPUT-001 Input uses an unsupported contract.' }
    $capabilities = @(Get-eMASSuxiPropertyValue -InputObject $InputResult.Execution -Name 'Capabilities')
    if ($capabilities -contains 'SubmissionUnitXmlInventory') { throw 'SUXI-INPUT-002 Input already declares SubmissionUnitXmlInventory.' }
    if ($capabilities -notcontains 'RepositoryDiscovery' -or $capabilities -notcontains 'BackboneXmlInventory') { throw 'SUXI-INPUT-003 Input does not declare RepositoryDiscovery and BackboneXmlInventory.' }

    $resolvedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    $sourceKind = [string]$InputResult.Repository.SourceKind
    if ($sourceKind -eq 'Directory' -and -not [System.IO.Directory]::Exists($resolvedSourcePath)) { throw 'SUXI-SOURCE-001 Source directory does not exist.' }
    if ($sourceKind -eq 'Zip' -and -not [System.IO.File]::Exists($resolvedSourcePath)) { throw 'SUXI-SOURCE-001 Source ZIP does not exist.' }
    if ($sourceKind -notin @('Directory','Zip')) { throw 'SUXI-SOURCE-002 Only directory and top-level ZIP inputs are supported.' }
    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) { $resolvedOutputPath = Test-eMASSuxiOutputPath -SourcePath $resolvedSourcePath -SourceKind $sourceKind -OutputPath $OutputPath }

    $workingResult = ($InputResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $descriptors = New-Object System.Collections.ArrayList
    $acceptedKinds = @('SubmissionUnitFolder','AmbiguousRegulatoryUnitFolder','DamagedSubmissionUnitCandidate')
    foreach ($sequence in @(Get-eMASSuxiSortedObjects -Objects @($workingResult.Sequences | Where-Object { $acceptedKinds -contains [string]$_.SequenceLikeKind }))) {
        $markerFiles = @($workingResult.Files | Where-Object {
            [string]$_.SequenceId -eq [string]$sequence.SequenceId -and
            (Get-eMASSuxiParentPath -RelativePath ([string]$_.RelativePath)) -ceq [string]$sequence.RelativePath -and
            (Get-eMASSuxiLeafName -RelativePath ([string]$_.RelativePath)) -ieq 'submissionunit.xml'
        })
        $expectedPath = Join-eMASSuxiRelativePath -Parent ([string]$sequence.RelativePath) -Child 'submissionunit.xml'
        [void]$descriptors.Add([pscustomobject][ordered]@{
            Sequence = $sequence; MarkerFiles = [object[]]$markerFiles; FileRecord = $(if ($markerFiles.Count -eq 1) { $markerFiles[0] } else { $null })
            RelativePath = $(if ($markerFiles.Count -eq 1) { [string]$markerFiles[0].RelativePath } else { $expectedPath })
        })
    }

    $documents = New-Object System.Collections.ArrayList
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
            $id = 'SUX-{0:D4}' -f ($index + 1)
            if ($descriptor.MarkerFiles.Count -eq 0) {
                [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $false -CaptureStatus 'InputUnavailable' -ParseStatus 'Missing' -Facts $null -ParseErrorCode $null -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic $null -AdditionalReasons @('SubmissionUnitXmlConfirmedAbsent')))
                continue
            }
            if ($descriptor.MarkerFiles.Count -gt 1) {
                [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'InputUnavailable' -ParseStatus 'NotAttempted' -Facts $null -ParseErrorCode 'SUXI-DUPLICATE-001' -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic 'Multiple case-insensitive submissionunit.xml markers were discovered.' -AdditionalReasons @('DuplicateSubmissionUnitFiles')))
                continue
            }

            $stream = $null
            try {
                if ($sourceKind -eq 'Zip') {
                    $entry = $zipArchive.GetEntry([string]$descriptor.FileRecord.ContainerPath)
                    if ($null -eq $entry) {
                        [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'InputUnavailable' -ParseStatus 'NotAttempted' -Facts $null -ParseErrorCode 'XML-ZIP-ENTRY-001' -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic 'The discovered submissionunit.xml entry was unavailable.' -AdditionalReasons @('SourceXmlUnavailable')))
                        continue
                    }
                    $stream = $entry.Open()
                }
                else {
                    $relativePlatformPath = ([string]$descriptor.RelativePath) -replace '/', [System.IO.Path]::DirectorySeparatorChar
                    $xmlPath = [System.IO.Path]::GetFullPath((Join-Path $resolvedSourcePath $relativePlatformPath))
                    $sourcePrefix = $resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
                    if (-not $xmlPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'SUXI-PATH-002 Discovered XML path escaped SourcePath.' }
                    if (-not [System.IO.File]::Exists($xmlPath)) {
                        [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'InputUnavailable' -ParseStatus 'NotAttempted' -Facts $null -ParseErrorCode 'XML-FILE-001' -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic 'The discovered submissionunit.xml file was unavailable.' -AdditionalReasons @('SourceXmlUnavailable')))
                        continue
                    }
                    if (Test-eMASSuxiReparsePath -SourceRoot $resolvedSourcePath -TargetPath $xmlPath) { throw 'SUXI-REPARSE-001 Reparse points are not traversed.' }
                    $stream = [System.IO.File]::Open($xmlPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
                }

                $load = Read-eMASSafeXmlDocument -Stream $stream
                if ($load.ParseStatus -ne 'Parsed') {
                    [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'ParseFailed' -ParseStatus 'ParseFailed' -Facts $null -ParseErrorCode ([string]$load.ParseErrorCode) -ParseErrorLineNumber $load.ParseErrorLineNumber -ParseErrorLinePosition $load.ParseErrorLinePosition -Diagnostic ([string]$load.Diagnostic) -AdditionalReasons @('SourceXmlParseFailed')))
                    continue
                }
                $facts = Get-eMASEctd4SubmissionUnitFacts -Document $load.Document -UnitFolderName ([string]$descriptor.Sequence.FolderName)
                $additional = @()
                if ([string]$descriptor.Sequence.SequenceLikeKind -eq 'AmbiguousRegulatoryUnitFolder') { $additional = @('AmbiguousUnitFolder') }
                [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'Available' -ParseStatus 'Parsed' -Facts $facts -ParseErrorCode $null -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic $null -AdditionalReasons $additional))
            }
            catch [System.UnauthorizedAccessException] {
                [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'AccessDenied' -ParseStatus 'NotAttempted' -Facts $null -ParseErrorCode 'XML-ACCESS-001' -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic 'Access to the discovered submissionunit.xml was denied.' -AdditionalReasons @('SourceXmlAccessDenied')))
            }
            catch {
                [void]$documents.Add((New-eMASSuxiDocument -Id $id -Descriptor $descriptor -Exists $true -CaptureStatus 'InputUnavailable' -ParseStatus 'NotAttempted' -Facts $null -ParseErrorCode 'XML-READ-001' -ParseErrorLineNumber $null -ParseErrorLinePosition $null -Diagnostic (ConvertTo-eMASSafeXmlDiagnosticMessage -Message $_.Exception.Message) -AdditionalReasons @('SourceXmlUnavailable')))
            }
            finally { if ($null -ne $stream) { $stream.Dispose() } }
        }
    }
    finally {
        if ($null -ne $zipArchive) { $zipArchive.Dispose() }
        if ($null -ne $zipStream) { $zipStream.Dispose() }
    }

    $workingResult | Add-Member -MemberType NoteProperty -Name SubmissionUnitXmlDocuments -Value ([object[]]@($documents)) -Force
    $coverage = New-Object System.Collections.ArrayList
    foreach ($row in @($workingResult.CollectionCoverage)) {
        if ([string]$row.CheckId -ne 'SubmissionUnitXmlInventory' -and -not ([string]$row.CheckId).StartsWith('SubmissionUnitXmlField:', [System.StringComparison]::Ordinal)) { [void]$coverage.Add($row) }
    }
    foreach ($document in $documents) { foreach ($row in @(Get-eMASSuxiCoverageRows -Document $document)) { [void]$coverage.Add($row) } }
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = ('{0}+SubmissionUnitXmlInventory' -f [string]$workingResult.Execution.ScannerName)
    $workingResult.Execution.ScannerVersion = '0.11.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]](@($capabilities) + 'SubmissionUnitXmlInventory')
    if (@($documents | Where-Object { $_.CaptureStatus -ne 'Available' -or $_.Structure.StructureStatus -ne 'Recognized' }).Count -gt 0) { $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps' }

    if ($null -ne $resolvedOutputPath) { Write-eMASSuxiResult -Result $workingResult -OutputPath $resolvedOutputPath }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASSubmissionUnitXmlInventory
