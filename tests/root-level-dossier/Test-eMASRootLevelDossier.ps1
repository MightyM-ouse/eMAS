#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CorpusRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$entryScript = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
$fixturePath = Join-Path ([System.IO.Path]::GetFullPath($CorpusRoot)) 'fixtures/SD-002/fixture.zip'
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)
$script:eMASRootPhysicalMarkerEvidenceTypes = @(
    'RegulatoryUnitKind',
    'SubmissionUnitMarkerFile',
    'TocFileMarker',
    'ChecksumFileMarker',
    'UtilityDtdFolderMarker'
)
$script:eMASRootRegionalEnvelopeEvidenceTypes = @(
    'EuEnvelopeCountry',
    'EuAgencyCode',
    'EuProcedureType',
    'EuSubmissionType',
    'EuSubmissionUnitType'
)
$script:eMASRootAdditiveEvidenceTypes = @($script:eMASRootPhysicalMarkerEvidenceTypes) + @($script:eMASRootRegionalEnvelopeEvidenceTypes)

function Assert-eMASRootTrue {
    param([bool] $Condition, [Parameter(Mandatory = $true)][string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-eMASRootEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [Parameter(Mandatory = $true)][string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}

function ConvertTo-eMASRootJson {
    param([AllowNull()][object] $Value)
    return ([object[]]@($Value) | ConvertTo-Json -Depth 64 -Compress)
}

function Get-eMASRootHistoricalClassificationEvidence {
    param([AllowEmptyCollection()][object[]] $Records)
    return @($Records | Where-Object { $script:eMASRootAdditiveEvidenceTypes -notcontains $_.EvidenceType })
}

function ConvertTo-eMASRootReferenceProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ConvertTo-eMASRootJson ([object[]]@($Result.References | ForEach-Object {
        [pscustomobject][ordered]@{
            ReferenceId = $_.ReferenceId
            XmlId = $_.XmlId
            DossierId = $_.DossierId
            SequenceId = $_.SequenceId
            RawHref = $_.RawHref
            NormalizedTargetPath = $_.NormalizedTargetPath
            TargetFileId = $_.TargetFileId
            TargetExists = $_.TargetExists
            ResolutionStatus = $_.ResolutionStatus
            ResolutionDiagnosticCode = $_.ResolutionDiagnosticCode
            CaptureStatus = $_.CaptureStatus
        }
    }))
}

function ConvertTo-eMASRootClassificationProjection {
    param([Parameter(Mandatory = $true)][object] $Result)
    return ConvertTo-eMASRootJson ([object[]]@($Result.ClassificationEvidence | Where-Object { $_.EvidenceType -ne 'DossierRootPath' } | ForEach-Object {
        [pscustomobject][ordered]@{
            EvidenceType = $_.EvidenceType
            Dimension = $_.Dimension
            Strength = $_.Strength
            SourceTier = $_.SourceTier
            SequenceFolder = $_.SequenceFolder
            SequenceRelativePath = $_.SequenceRelativePath
            ObservedValue = $_.ObservedValue
            CaptureStatus = $_.CaptureStatus
            XmlId = $_.XmlId
            SequenceId = $_.SequenceId
        }
    }))
}

function Invoke-eMASRootEntry {
    param(
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $ExecutionId,
        [Parameter(Mandatory = $true)][string] $OutputPath,
        [switch] $Classification
    )

    $parameters = @{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        ExecutionId = $ExecutionId
    }
    if ($Classification) { $parameters.IncludeClassificationEvidenceCollection = $true }
    else { $parameters.IncludeReferenceResolution = $true }
    return & $entryScript @parameters
}

function Invoke-eMASRootCheck {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][scriptblock] $Action,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList] $Results
    )

    try {
        & $Action
        [void]$Results.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        [void]$Results.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

if (-not [System.IO.File]::Exists($fixturePath)) { throw ('Root-level source fixture is missing: {0}' -f $fixturePath) }
try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-root-level-dossier-{0}' -f [guid]::NewGuid().ToString('N'))
$wrappedSource = Join-Path $temporaryRoot 'wrapped-source'
$results = New-Object System.Collections.ArrayList

try {
    [void][System.IO.Directory]::CreateDirectory($wrappedSource)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($fixturePath, $wrappedSource)
    $dossierRoots = [System.IO.Directory]::GetDirectories($wrappedSource)
    Assert-eMASRootEqual -Expected 1 -Actual $dossierRoots.Count -Message 'SD-002 extracted dossier root count differs.'
    $rootSource = $dossierRoots[0]

    $wrappedReference = Invoke-eMASRootEntry -SourcePath $wrappedSource -ExecutionId 'EXEC-ROOT-WRAPPED-REFERENCE' -OutputPath (Join-Path $resolvedOutputRoot 'wrapped-reference.json')
    $rootReference = Invoke-eMASRootEntry -SourcePath $rootSource -ExecutionId 'EXEC-ROOT-REFERENCE' -OutputPath (Join-Path $resolvedOutputRoot 'root-reference.json')

    Invoke-eMASRootCheck -Name 'Root-level ReferenceResolution preserves paths and target identity' -Results $results -Action {
        Assert-eMASRootEqual -Expected '' -Actual ([string]$rootReference.DossierCandidates[0].RelativePath) -Message 'Root dossier path differs.'
        Assert-eMASRootEqual -Expected 94 -Actual @($rootReference.References).Count -Message 'Root reference count differs.'
        Assert-eMASRootEqual -Expected 93 -Actual @($rootReference.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedPresent' }).Count -Message 'Root resolved-present count differs.'
        Assert-eMASRootEqual -Expected 0 -Actual @($rootReference.References | Where-Object { $_.ResolutionStatus -eq 'ResolvedAbsent' }).Count -Message 'Root dossier produced false absent targets.'
        Assert-eMASRootTrue -Condition (@($rootReference.References | Where-Object { $_.NormalizedTargetPath -like '0000/*' }).Count -gt 0) -Message 'Root normalized paths lost the 0000 prefix.'
        Assert-eMASRootEqual -Expected (ConvertTo-eMASRootReferenceProjection -Result $wrappedReference) -Actual (ConvertTo-eMASRootReferenceProjection -Result $rootReference) -Message 'Wrapped/root reference projections differ.'
    }

    Invoke-eMASRootCheck -Name 'Root-level ClassificationEvidenceCollection emits complete evidence' -Results $results -Action {
        $wrappedClassification = Invoke-eMASRootEntry -SourcePath $wrappedSource -ExecutionId 'EXEC-ROOT-WRAPPED-CLASSIFICATION' -OutputPath (Join-Path $resolvedOutputRoot 'wrapped-classification.json') -Classification
        $rootClassification = Invoke-eMASRootEntry -SourcePath $rootSource -ExecutionId 'EXEC-ROOT-CLASSIFICATION' -OutputPath (Join-Path $resolvedOutputRoot 'root-classification.json') -Classification
        Assert-eMASRootEqual -Expected '' -Actual ([string]$rootClassification.DossierCandidates[0].RelativePath) -Message 'Root dossier path differs.'
        $fullRecords = @($rootClassification.ClassificationEvidence)
        $historicalRecords = @(Get-eMASRootHistoricalClassificationEvidence -Records $fullRecords)
        Assert-eMASRootEqual -Expected 86 -Actual $historicalRecords.Count -Message 'Root historical classification evidence count differs.'
        Assert-eMASRootEqual -Expected 150 -Actual $fullRecords.Count -Message 'Root additive classification evidence count differs.'
        $rootPathEvidence = @($rootClassification.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'DossierRootPath' })
        Assert-eMASRootEqual -Expected 1 -Actual $rootPathEvidence.Count -Message 'Root dossier-path evidence count differs.'
        Assert-eMASRootEqual -Expected '' -Actual ([string]$rootPathEvidence[0].ObservedValue) -Message 'Root dossier-path observed value differs.'
        Assert-eMASRootEqual -Expected 'DossierContext' -Actual $rootPathEvidence[0].Dimension -Message 'Root dossier-path dimension differs.'
        Assert-eMASRootEqual -Expected 'Weak' -Actual $rootPathEvidence[0].Strength -Message 'Root dossier-path strength differs.'
        $coverage = @($rootClassification.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASRootEqual -Expected 1 -Actual $coverage.Count -Message 'Root classification repository coverage count differs.'
        Assert-eMASRootEqual -Expected 'Collected' -Actual $coverage[0].CollectionStatus -Message 'Root classification repository status differs.'
        Assert-eMASRootEqual -Expected $fullRecords.Count -Actual $coverage[0].RecordsProduced -Message 'Root classification records-produced differs from the full additive result.'
        Assert-eMASRootEqual -Expected (ConvertTo-eMASRootClassificationProjection -Result $wrappedClassification) -Actual (ConvertTo-eMASRootClassificationProjection -Result $rootClassification) -Message 'Wrapped/root classification projections differ.'
    }

    Invoke-eMASRootCheck -Name 'Unrelated SD-020 remains a legitimate collected zero-evidence result' -Results $results -Action {
        $unrelatedPath = Join-Path ([System.IO.Path]::GetFullPath($CorpusRoot)) 'fixtures/SD-020/fixture.zip'
        $unrelated = Invoke-eMASRootEntry -SourcePath $unrelatedPath -ExecutionId 'EXEC-ROOT-SD020' -OutputPath (Join-Path $resolvedOutputRoot 'sd020-classification.json') -Classification
        Assert-eMASRootEqual -Expected 0 -Actual @($unrelated.ClassificationEvidence).Count -Message 'SD-020 manufactured classification evidence.'
        $coverage = @($unrelated.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'Repository' })
        Assert-eMASRootEqual -Expected 1 -Actual $coverage.Count -Message 'SD-020 classification coverage count differs.'
        Assert-eMASRootEqual -Expected 'Collected' -Actual $coverage[0].CollectionStatus -Message 'SD-020 classification status differs.'
        Assert-eMASRootEqual -Expected 0 -Actual $coverage[0].RecordsProduced -Message 'SD-020 records-produced differs.'
    }
}
finally {
    if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
}

$failureCount = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
$summary = [pscustomobject][ordered]@{
    ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
    Capability = 'RootLevelDossierRegression'
    Platform = [pscustomobject][ordered]@{ PSEdition = $PSVersionTable.PSEdition; PSVersion = $PSVersionTable.PSVersion.ToString(); OS = $PSVersionTable.OS }
    CheckCount = $results.Count
    PassCount = @($results | Where-Object { $_.Status -eq 'PASS' }).Count
    FailCount = $failureCount
    OverallStatus = $(if ($failureCount -eq 0) { 'PASS' } else { 'FAIL' })
    Checks = [object[]]@($results)
}
$summaryPath = Join-Path $resolvedOutputRoot 'root-level-dossier-test-summary.json'
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 16), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('Root-level dossier tests completed: {0}; summary={1}' -f $summary.OverallStatus, $summaryPath)
if ($failureCount -gt 0) { exit 1 }
