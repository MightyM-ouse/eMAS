#requires -Version 5.1

Set-StrictMode -Version 2.0

function Test-eMASMissingReferenceOutputPath {
    param(
        [Parameter(Mandatory = $true)][object] $ReferenceResolutionResult,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $sourceKind = [string]$ReferenceResolutionResult.Repository.SourceKind
    $resolvedSourcePath = [string]$ReferenceResolutionResult.Repository.ResolvedSourcePath
    if (-not [string]::IsNullOrWhiteSpace($resolvedSourcePath)) {
        if ($sourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'MRI-OUTPUT-001 OutputPath must not overwrite SourcePath.'
        }
        if ($sourceKind -eq 'Directory') {
            $sourcePrefix = $resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if ($resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw 'MRI-OUTPUT-002 OutputPath must not be inside SourcePath.'
            }
        }
    }
    return $resolvedOutputPath
}

function Write-eMASMissingReferenceInterpretationResult {
    param(
        [Parameter(Mandatory = $true)][object] $Result,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function New-eMASMissingReferenceCoverage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'Reference')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][ValidateSet('Assessed', 'Partial', 'NotAssessed', 'NotApplicable')][string] $AssessmentStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'MissingReferenceInterpretation'
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        AssessmentStatus = $AssessmentStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Get-eMASNextObservationOrdinal {
    param([AllowEmptyCollection()][object[]] $Observations)

    $maximum = 0
    foreach ($observation in @($Observations)) {
        $observationId = [string]$observation.ObservationId
        if ($observationId -match '^OBS-(\d+)$') {
            $ordinal = [int]$matches[1]
            if ($ordinal -gt $maximum) { $maximum = $ordinal }
        }
    }
    return ($maximum + 1)
}

function Test-eMASConfirmedAbsentReference {
    param([Parameter(Mandatory = $true)][object] $Reference)

    if ([string]$Reference.ResolutionStatus -ne 'ResolvedAbsent') { return $false }
    if ([string]$Reference.CaptureStatus -ne 'Available') { return $false }
    if ($null -eq $Reference.TargetExists -or -not ($Reference.TargetExists -is [bool]) -or [bool]$Reference.TargetExists) { return $false }
    if ([string]::IsNullOrWhiteSpace([string]$Reference.RawHref)) { return $false }
    if ([string]::IsNullOrWhiteSpace([string]$Reference.NormalizedTargetPath)) { return $false }
    if ($null -ne $Reference.TargetFileId) { return $false }
    if (-not [string]::IsNullOrWhiteSpace([string]$Reference.ResolutionDiagnosticCode)) { return $false }
    return $true
}

function Get-eMASReferenceAssessmentOutcome {
    param([Parameter(Mandatory = $true)][object] $Reference)

    if (Test-eMASConfirmedAbsentReference -Reference $Reference) {
        return [pscustomobject][ordered]@{ AssessmentStatus = 'Assessed'; CaptureStatus = 'Available'; ReasonCode = $null; EmitFinding = $true }
    }
    if ([string]$Reference.ResolutionStatus -eq 'ResolvedPresent' -and
        [string]$Reference.CaptureStatus -eq 'Available' -and
        $Reference.TargetExists -is [bool] -and [bool]$Reference.TargetExists -and
        -not [string]::IsNullOrWhiteSpace([string]$Reference.NormalizedTargetPath) -and
        -not [string]::IsNullOrWhiteSpace([string]$Reference.TargetFileId) -and
        [string]::IsNullOrWhiteSpace([string]$Reference.ResolutionDiagnosticCode)) {
        return [pscustomobject][ordered]@{ AssessmentStatus = 'Assessed'; CaptureStatus = 'Available'; ReasonCode = $null; EmitFinding = $false }
    }
    if ([string]$Reference.ResolutionStatus -eq 'NotApplicable' -and $null -eq $Reference.TargetExists) {
        return [pscustomobject][ordered]@{
            AssessmentStatus = 'NotApplicable'
            CaptureStatus = 'NotApplicable'
            ReasonCode = $(if ([string]::IsNullOrWhiteSpace([string]$Reference.ResolutionDiagnosticCode)) { 'ReferenceNotApplicable' } else { [string]$Reference.ResolutionDiagnosticCode })
            EmitFinding = $false
        }
    }

    $captureStatus = [string]$Reference.CaptureStatus
    if (@('AccessDenied', 'InputUnavailable', 'ParseFailed', 'NotApplicable') -notcontains $captureStatus) { $captureStatus = 'InputUnavailable' }
    $reasonCode = [string]$Reference.ResolutionDiagnosticCode
    if ([string]::IsNullOrWhiteSpace($reasonCode)) { $reasonCode = 'ResolutionEvidenceNotConfirmed' }
    return [pscustomobject][ordered]@{ AssessmentStatus = 'NotAssessed'; CaptureStatus = $captureStatus; ReasonCode = $reasonCode; EmitFinding = $false }
}

function Invoke-eMASMissingReferenceInterpretation {
    <#
    .SYNOPSIS
    Interprets confirmed-absent ReferenceResolution facts as bounded missing-reference observations.

    .DESCRIPTION
    Consumes accepted ReferenceResolution output only. It does not access the source, parse XML,
    resolve paths, calculate checksums, detect orphan files, assign RAG/severity, or recommend action.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $ReferenceResolutionResult,
        [AllowNull()][string] $OutputPath
    )

    if ($ReferenceResolutionResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'MRI-INPUT-001 Input uses an unsupported contract.'
    }
    if ($ReferenceResolutionResult.Execution.Phase -ne 'PreSales' -or $ReferenceResolutionResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'MRI-INPUT-002 Input is not an MS-04 PreSales result.'
    }
    if (-not ($ReferenceResolutionResult.Execution.PSObject.Properties.Name -contains 'Capabilities') -or
        @($ReferenceResolutionResult.Execution.Capabilities) -notcontains 'ReferenceResolution') {
        throw 'MRI-INPUT-003 Input does not declare the accepted ReferenceResolution capability.'
    }
    if (@($ReferenceResolutionResult.Execution.Capabilities) -contains 'MissingReferenceInterpretation') {
        throw 'MRI-INPUT-004 Input already declares MissingReferenceInterpretation.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASMissingReferenceOutputPath -ReferenceResolutionResult $ReferenceResolutionResult -OutputPath $OutputPath
    }

    $workingResult = ($ReferenceResolutionResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $referenceIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($reference in @($workingResult.References)) {
        if ([string]::IsNullOrWhiteSpace([string]$reference.ReferenceId)) { throw 'MRI-INPUT-005 Reference without ReferenceId.' }
        if (-not $referenceIds.Add([string]$reference.ReferenceId)) { throw ('MRI-INPUT-006 Duplicate ReferenceId: {0}' -f $reference.ReferenceId) }
    }

    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -ne 'MissingReferenceInterpretation') { [void]$coverage.Add($item) }
    }
    $observations = New-Object System.Collections.ArrayList
    foreach ($observation in @($workingResult.Observations)) { [void]$observations.Add($observation) }

    $nextObservationOrdinal = Get-eMASNextObservationOrdinal -Observations @($observations)
    $findingOrdinal = 0
    $assessmentOutcomes = New-Object System.Collections.ArrayList
    foreach ($reference in @($workingResult.References | Sort-Object -Property ReferenceId)) {
        $outcome = Get-eMASReferenceAssessmentOutcome -Reference $reference
        [void]$assessmentOutcomes.Add($outcome)
        $recordsProduced = 0
        if ($outcome.EmitFinding) {
            $findingOrdinal++
            $findingId = 'FND-MISSINGREF-{0:D4}' -f $findingOrdinal
            $observationId = 'OBS-{0:D4}' -f $nextObservationOrdinal
            $nextObservationOrdinal++
            [void]$observations.Add([pscustomobject][ordered]@{
                ObservationId = $observationId
                Category = 'Integrity'
                Code = 'ReferenceTargetMissing'
                SubjectType = 'Reference'
                SubjectId = $reference.ReferenceId
                ObservedValue = $true
                CaptureStatus = 'Available'
                EvidenceIds = [object[]]@($reference.ReferenceId)
                FindingId = $findingId
                FindingCode = 'MissingReference'
                ReferenceId = $reference.ReferenceId
                DossierId = $reference.DossierId
                SequenceId = $reference.SequenceId
                XmlId = $reference.XmlId
                SourceElementId = $reference.SourceElementId
                RawHref = $reference.RawHref
                NormalizedTargetPath = $reference.NormalizedTargetPath
                EvidenceStatus = 'ConfirmedAbsent'
                AssessmentStatus = 'Assessed'
                Evaluation = $true
            })
            $recordsProduced = 1
        }
        [void]$coverage.Add((New-eMASMissingReferenceCoverage `
            -SubjectType 'Reference' `
            -SubjectId ([string]$reference.ReferenceId) `
            -CaptureStatus ([string]$outcome.CaptureStatus) `
            -AssessmentStatus ([string]$outcome.AssessmentStatus) `
            -RecordsProduced $recordsProduced `
            -ReasonCode $outcome.ReasonCode))
    }

    $repositoryAssessmentStatus = 'Assessed'
    $repositoryCaptureStatus = 'Available'
    $repositoryReasonCode = $null
    $outcomes = @($assessmentOutcomes)
    if ($outcomes.Count -eq 0) {
        $resolutionCoverage = @($workingResult.CollectionCoverage | Where-Object { $_.CheckId -eq 'ReferenceResolution' -and $_.SubjectType -eq 'Repository' })
        if ($resolutionCoverage.Count -ne 1 -or $resolutionCoverage[0].CaptureStatus -ne 'Available') {
            $repositoryAssessmentStatus = 'NotAssessed'
            $repositoryCaptureStatus = 'InputUnavailable'
            $repositoryReasonCode = 'ReferenceResolutionUnavailable'
        }
    }
    else {
        $notAssessed = @($outcomes | Where-Object { $_.AssessmentStatus -eq 'NotAssessed' })
        $assessedOrNotApplicable = @($outcomes | Where-Object { $_.AssessmentStatus -eq 'Assessed' -or $_.AssessmentStatus -eq 'NotApplicable' })
        if ($notAssessed.Count -eq $outcomes.Count) {
            $repositoryAssessmentStatus = 'NotAssessed'
            $repositoryCaptureStatus = $(if (@($notAssessed | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } else { 'InputUnavailable' })
            $repositoryReasonCode = 'NoReferenceCouldBeAssessed'
        }
        elseif ($notAssessed.Count -gt 0 -and $assessedOrNotApplicable.Count -gt 0) {
            $repositoryAssessmentStatus = 'Partial'
            $repositoryCaptureStatus = $(if (@($notAssessed | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } else { 'InputUnavailable' })
            $repositoryReasonCode = 'OneOrMoreReferencesNotAssessed'
        }
    }
    [void]$coverage.Add((New-eMASMissingReferenceCoverage `
        -SubjectType 'Repository' `
        -SubjectId 'REP-0001' `
        -CaptureStatus $repositoryCaptureStatus `
        -AssessmentStatus $repositoryAssessmentStatus `
        -RecordsProduced $findingOrdinal `
        -ReasonCode $repositoryReasonCode))

    $workingResult.Observations = [object[]]@($observations)
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation'
    $workingResult.Execution.ScannerVersion = '0.5.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation')
    if ($workingResult.Execution.CompletionStatus -eq 'Completed' -and $repositoryAssessmentStatus -ne 'Assessed') {
        $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps'
    }

    if ($null -ne $resolvedOutputPath) {
        Write-eMASMissingReferenceInterpretationResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASMissingReferenceInterpretation
