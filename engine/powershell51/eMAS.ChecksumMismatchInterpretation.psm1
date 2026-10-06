#requires -Version 5.1

Set-StrictMode -Version 2.0

function Get-eMASCmiPropertyValue {
    param([Parameter(Mandatory = $true)][object] $InputObject, [Parameter(Mandatory = $true)][string] $Name)

    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-eMASChecksumMismatchOutputPath {
    param(
        [Parameter(Mandatory = $true)][object] $DeclaredChecksumComparisonResult,
        [Parameter(Mandatory = $true)][string] $OutputPath
    )

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $sourceKind = [string]$DeclaredChecksumComparisonResult.Repository.SourceKind
    $resolvedSourcePath = [string]$DeclaredChecksumComparisonResult.Repository.ResolvedSourcePath
    if (-not [string]::IsNullOrWhiteSpace($resolvedSourcePath)) {
        if ($sourceKind -eq 'Zip' -and $resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'CMI-OUTPUT-001 OutputPath must not overwrite SourcePath.'
        }
        if ($sourceKind -eq 'Directory') {
            $sourcePrefix = $resolvedSourcePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if ($resolvedOutputPath.Equals($resolvedSourcePath, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutputPath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw 'CMI-OUTPUT-002 OutputPath must not be inside SourcePath.'
            }
        }
    }
    return $resolvedOutputPath
}

function Write-eMASChecksumMismatchInterpretationResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)

    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, ($Result | ConvertTo-Json -Depth 64), $encoding)
}

function New-eMASChecksumMismatchCoverage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Repository', 'Reference')][string] $SubjectType,
        [Parameter(Mandatory = $true)][string] $SubjectId,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [Parameter(Mandatory = $true)][ValidateSet('Assessed', 'Partial', 'NotAssessed', 'NotApplicable')][string] $AssessmentStatus,
        [Parameter(Mandatory = $true)][int] $RecordsProduced,
        [AllowNull()][string] $ReasonCode
    )

    return [pscustomobject][ordered]@{
        CheckId = 'ChecksumMismatchInterpretation'
        SubjectType = $SubjectType
        SubjectId = $SubjectId
        CaptureStatus = $CaptureStatus
        AssessmentStatus = $AssessmentStatus
        RecordsProduced = $RecordsProduced
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
    }
}

function Get-eMASChecksumMismatchNextObservationOrdinal {
    param([AllowEmptyCollection()][object[]] $Observations)

    $maximum = 0
    foreach ($observation in @($Observations)) {
        $observationId = [string](Get-eMASCmiPropertyValue -InputObject $observation -Name 'ObservationId')
        if ($observationId -match '^OBS-(\d+)$') {
            $ordinal = [int]$Matches[1]
            if ($ordinal -gt $maximum) { $maximum = $ordinal }
        }
    }
    return ($maximum + 1)
}

function New-eMASChecksumMismatchOutcome {
    param(
        [Parameter(Mandatory = $true)][string] $AssessmentStatus,
        [Parameter(Mandatory = $true)][string] $CaptureStatus,
        [AllowNull()][string] $ReasonCode,
        [Parameter(Mandatory = $true)][bool] $EmitObservation
    )

    return [pscustomobject][ordered]@{
        AssessmentStatus = $AssessmentStatus
        CaptureStatus = $CaptureStatus
        ReasonCode = $(if ([string]::IsNullOrWhiteSpace($ReasonCode)) { $null } else { $ReasonCode })
        EmitObservation = $EmitObservation
    }
}

function Get-eMASChecksumMismatchReferenceOutcome {
    param([Parameter(Mandatory = $true)][object] $Reference)

    $status = [string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'ChecksumComparisonStatus')
    $diagnostic = [string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'ChecksumDiagnosticCode')
    $checksumMatch = Get-eMASCmiPropertyValue -InputObject $Reference -Name 'ChecksumMatch'
    $calculated = Get-eMASCmiPropertyValue -InputObject $Reference -Name 'CalculatedChecksum'
    $declared = [string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'DeclaredChecksum')
    $algorithm = [string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'DeclaredChecksumAlgorithm')

    # Comparison was not applicable upstream (no href, no declared checksum, confirmed absent target).
    if ($status -eq 'NotApplicable') {
        if ($null -ne $checksumMatch -or $null -ne $calculated) {
            return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus 'InputUnavailable' -ReasonCode 'InconsistentChecksumEvidence' -EmitObservation $false
        }
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotApplicable' -CaptureStatus 'NotApplicable' -ReasonCode $(if ([string]::IsNullOrWhiteSpace($diagnostic)) { 'ChecksumComparisonNotApplicable' } else { $diagnostic }) -EmitObservation $false
    }

    # Comparison was not completed upstream: unknown is never a mismatch.
    if ($status -eq 'NotAssessed' -or $status -eq 'Unsupported') {
        if ($null -ne $checksumMatch -or $null -ne $calculated) {
            return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus 'InputUnavailable' -ReasonCode 'InconsistentChecksumEvidence' -EmitObservation $false
        }
        $captureStatus = $(if ($diagnostic -eq 'TargetAccessDenied') { 'AccessDenied' } else { 'InputUnavailable' })
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus $captureStatus -ReasonCode $(if ([string]::IsNullOrWhiteSpace($diagnostic)) { 'ChecksumComparisonNotAssessed' } else { $diagnostic }) -EmitObservation $false
    }

    if ($status -ne 'Matched' -and $status -ne 'Mismatched') {
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus 'InputUnavailable' -ReasonCode 'ChecksumComparisonEvidenceUnavailable' -EmitObservation $false
    }

    # A completed comparison must carry complete, internally consistent evidence.
    $calculatedText = [string]$calculated
    $evidenceComplete = (
        [string]::IsNullOrWhiteSpace($diagnostic) -and
        $checksumMatch -is [bool] -and
        $null -ne $calculated -and $calculatedText -cmatch '^[0-9a-f]{32}$' -and
        $declared -match '^[0-9A-Fa-f]{32}$' -and
        $algorithm.Trim().Equals('MD5', [System.StringComparison]::OrdinalIgnoreCase) -and
        [string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'ResolutionStatus') -eq 'ResolvedPresent' -and
        (Get-eMASCmiPropertyValue -InputObject $Reference -Name 'TargetExists') -is [bool] -and
        [bool](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'TargetExists') -and
        -not [string]::IsNullOrWhiteSpace([string](Get-eMASCmiPropertyValue -InputObject $Reference -Name 'TargetFileId'))
    )
    if (-not $evidenceComplete) {
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus 'InputUnavailable' -ReasonCode 'InconsistentChecksumEvidence' -EmitObservation $false
    }

    $valuesEqual = $calculatedText.Equals($declared, [System.StringComparison]::OrdinalIgnoreCase)
    if ($status -eq 'Matched' -and [bool]$checksumMatch -and $valuesEqual) {
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'Assessed' -CaptureStatus 'Available' -ReasonCode $null -EmitObservation $false
    }
    if ($status -eq 'Mismatched' -and -not [bool]$checksumMatch -and -not $valuesEqual) {
        return New-eMASChecksumMismatchOutcome -AssessmentStatus 'Assessed' -CaptureStatus 'Available' -ReasonCode $null -EmitObservation $true
    }
    return New-eMASChecksumMismatchOutcome -AssessmentStatus 'NotAssessed' -CaptureStatus 'InputUnavailable' -ReasonCode 'InconsistentChecksumEvidence' -EmitObservation $false
}

function Invoke-eMASChecksumMismatchInterpretation {
    <#
    .SYNOPSIS
    Interprets completed declared-checksum comparisons as bounded DeclaredChecksumMismatch observations.

    .DESCRIPTION
    Consumes accepted DeclaredChecksumComparison output only. It does not access the source, read files,
    calculate hashes, parse XML, resolve references, infer a cause, or assign impact ratings or actions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $DeclaredChecksumComparisonResult,
        [AllowNull()][string] $OutputPath
    )

    if ($DeclaredChecksumComparisonResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') {
        throw 'CMI-INPUT-001 Input uses an unsupported contract.'
    }
    if ($DeclaredChecksumComparisonResult.Execution.Phase -ne 'PreSales' -or $DeclaredChecksumComparisonResult.Execution.ScenarioId -ne 'MS-04') {
        throw 'CMI-INPUT-002 Input is not an MS-04 PreSales result.'
    }
    if (-not ($DeclaredChecksumComparisonResult.Execution.PSObject.Properties.Name -contains 'Capabilities') -or
        @($DeclaredChecksumComparisonResult.Execution.Capabilities) -notcontains 'DeclaredChecksumComparison') {
        throw 'CMI-INPUT-003 Input does not declare the accepted DeclaredChecksumComparison capability.'
    }
    if (@($DeclaredChecksumComparisonResult.Execution.Capabilities) -contains 'ChecksumMismatchInterpretation') {
        throw 'CMI-INPUT-004 Input already declares ChecksumMismatchInterpretation.'
    }

    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutputPath = Test-eMASChecksumMismatchOutputPath -DeclaredChecksumComparisonResult $DeclaredChecksumComparisonResult -OutputPath $OutputPath
    }

    $workingResult = ($DeclaredChecksumComparisonResult | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $referenceIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($reference in @($workingResult.References)) {
        if ([string]::IsNullOrWhiteSpace([string]$reference.ReferenceId)) { throw 'CMI-INPUT-005 Reference without ReferenceId.' }
        if (-not $referenceIds.Add([string]$reference.ReferenceId)) { throw ('CMI-INPUT-006 Duplicate ReferenceId: {0}' -f $reference.ReferenceId) }
    }

    $coverage = New-Object System.Collections.ArrayList
    foreach ($item in @($workingResult.CollectionCoverage)) {
        if ($item.CheckId -ne 'ChecksumMismatchInterpretation') { [void]$coverage.Add($item) }
    }
    $observations = New-Object System.Collections.ArrayList
    foreach ($observation in @($workingResult.Observations)) { [void]$observations.Add($observation) }

    $nextObservationOrdinal = Get-eMASChecksumMismatchNextObservationOrdinal -Observations @($observations)
    $findingOrdinal = 0
    $outcomes = New-Object System.Collections.ArrayList
    foreach ($reference in @($workingResult.References | Sort-Object -Property ReferenceId)) {
        $outcome = Get-eMASChecksumMismatchReferenceOutcome -Reference $reference
        [void]$outcomes.Add($outcome)
        $recordsProduced = 0
        if ($outcome.EmitObservation) {
            $findingOrdinal++
            $observationId = 'OBS-{0:D4}' -f $nextObservationOrdinal
            $nextObservationOrdinal++
            [void]$observations.Add([pscustomobject][ordered]@{
                ObservationId = $observationId
                Category = 'Integrity'
                Code = 'DeclaredChecksumMismatch'
                SubjectType = 'Reference'
                SubjectId = $reference.ReferenceId
                ObservedValue = $true
                CaptureStatus = 'Available'
                EvidenceIds = [object[]]@($reference.ReferenceId, $reference.TargetFileId)
                FindingId = ('FND-CHECKSUM-{0:D4}' -f $findingOrdinal)
                FindingCode = 'DeclaredChecksumMismatch'
                ReferenceId = $reference.ReferenceId
                DossierId = $reference.DossierId
                SequenceId = $reference.SequenceId
                XmlId = $reference.XmlId
                SourceElementId = $reference.SourceElementId
                TargetFileId = $reference.TargetFileId
                NormalizedTargetPath = $reference.NormalizedTargetPath
                DeclaredChecksumAlgorithm = $reference.DeclaredChecksumAlgorithm
                DeclaredChecksum = $reference.DeclaredChecksum
                CalculatedChecksum = $reference.CalculatedChecksum
                EvidenceStatus = 'ConfirmedMismatch'
                AssessmentStatus = 'Assessed'
                Evaluation = $true
            })
            $recordsProduced = 1
        }
        [void]$coverage.Add((New-eMASChecksumMismatchCoverage `
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
    $allOutcomes = @($outcomes)
    if ($allOutcomes.Count -eq 0) {
        $comparisonCoverage = @($workingResult.CollectionCoverage | Where-Object { $_.CheckId -eq 'DeclaredChecksumComparison' -and $_.SubjectType -eq 'Repository' })
        if ($comparisonCoverage.Count -ne 1 -or [string](Get-eMASCmiPropertyValue -InputObject $comparisonCoverage[0] -Name 'ComparisonStatus') -ne 'Collected') {
            $repositoryAssessmentStatus = 'NotAssessed'
            $repositoryCaptureStatus = 'InputUnavailable'
            $repositoryReasonCode = 'DeclaredChecksumComparisonUnavailable'
        }
    }
    else {
        $notAssessed = @($allOutcomes | Where-Object { $_.AssessmentStatus -eq 'NotAssessed' })
        if ($notAssessed.Count -gt 0) {
            $repositoryAssessmentStatus = $(if ($notAssessed.Count -eq $allOutcomes.Count) { 'NotAssessed' } else { 'Partial' })
            $repositoryCaptureStatus = $(if (@($notAssessed | Where-Object { $_.CaptureStatus -eq 'AccessDenied' }).Count -gt 0) { 'AccessDenied' } else { 'InputUnavailable' })
            $repositoryReasonCode = $(if ($notAssessed.Count -eq $allOutcomes.Count) { 'NoChecksumComparisonCouldBeAssessed' } else { 'OneOrMoreChecksumComparisonsNotAssessed' })
        }
    }
    [void]$coverage.Add((New-eMASChecksumMismatchCoverage `
        -SubjectType 'Repository' `
        -SubjectId 'REP-0001' `
        -CaptureStatus $repositoryCaptureStatus `
        -AssessmentStatus $repositoryAssessmentStatus `
        -RecordsProduced $findingOrdinal `
        -ReasonCode $repositoryReasonCode))

    $workingResult.Observations = [object[]]@($observations)
    $workingResult.CollectionCoverage = [object[]]@($coverage)
    $workingResult.Execution.ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory+ReferenceInventory+ReferenceResolution+MissingReferenceInterpretation+DeclaredChecksumComparison+ChecksumMismatchInterpretation'
    $workingResult.Execution.ScannerVersion = '0.7.0'
    $workingResult.Execution.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    $workingResult.Execution.Capabilities = [object[]]@('RepositoryDiscovery', 'BackboneXmlInventory', 'ReferenceInventory', 'ReferenceResolution', 'MissingReferenceInterpretation', 'DeclaredChecksumComparison', 'ChecksumMismatchInterpretation')
    if ($workingResult.Execution.CompletionStatus -eq 'Completed' -and $repositoryAssessmentStatus -ne 'Assessed') {
        $workingResult.Execution.CompletionStatus = 'CompletedWithCollectionGaps'
    }

    if ($null -ne $resolvedOutputPath) {
        Write-eMASChecksumMismatchInterpretationResult -Result $workingResult -OutputPath $resolvedOutputPath
    }
    return $workingResult
}

Export-ModuleMember -Function Invoke-eMASChecksumMismatchInterpretation
