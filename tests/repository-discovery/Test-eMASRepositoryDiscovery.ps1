#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CorpusRoot,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $FreezeManifestPath,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot,
    [string] $ExpectationsPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ([string]::IsNullOrWhiteSpace($ExpectationsPath)) {
    $ExpectationsPath = Join-Path $repositoryRoot 'tests/fixtures/repository-discovery/wave1-expectations.json'
}
$modulePath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1'
$entryScriptPath = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
$validRuntimeConfigurationPath = Join-Path $repositoryRoot 'tests/fixtures/runtime-config/valid-minimal.json'
Import-Module -Name $modulePath -Force -ErrorAction Stop

$resolvedCorpusRoot = [System.IO.Path]::GetFullPath($CorpusRoot)
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$resultRoot = Join-Path $resolvedOutputRoot 'results'
[void][System.IO.Directory]::CreateDirectory($resultRoot)

$startedAtUtc = [DateTime]::UtcNow
$manifestRows = @(Import-Csv -LiteralPath $FreezeManifestPath)
$expectations = [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($ExpectationsPath)) | ConvertFrom-Json
$fixtureResults = New-Object System.Collections.ArrayList
$additionalResults = New-Object System.Collections.ArrayList
$sourceState = @{}
$zipResultsBySample = @{}
$frozenBeforeVerified = 0
$frozenAfterVerified = 0

function Get-eMASTestSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Assert-eMASTrue {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-eMASEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) {
        throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual)
    }
}

function Assert-eMASArrayEqual {
    param([AllowEmptyCollection()][object[]] $Expected, [AllowEmptyCollection()][object[]] $Actual, [string] $Message)
    $expectedJson = @($Expected) | ConvertTo-Json -Compress
    $actualJson = @($Actual) | ConvertTo-Json -Compress
    if ($expectedJson -ne $actualJson) {
        throw ('{0} Expected={1}; Actual={2}' -f $Message, $expectedJson, $actualJson)
    }
}

function ConvertTo-eMASDeterministicProjection {
    param([Parameter(Mandatory = $true)][object] $Result)

    return ([pscustomobject][ordered]@{
        ContractId = $Result.ContractId
        Repository = $Result.Repository
        DossierCandidates = [object[]]@($Result.DossierCandidates)
        Sequences = [object[]]@($Result.Sequences)
        XmlDocuments = [object[]]@($Result.XmlDocuments)
        References = [object[]]@($Result.References)
        Files = [object[]]@($Result.Files)
        LifecycleRelationships = [object[]]@($Result.LifecycleRelationships)
        Observations = [object[]]@($Result.Observations)
        ClassificationEvidence = [object[]]@($Result.ClassificationEvidence)
        CollectionCoverage = [object[]]@($Result.CollectionCoverage)
    } | ConvertTo-Json -Depth 64 -Compress)
}

function Write-eMASTestJson {
    param([Parameter(Mandatory = $true)][object] $Value, [Parameter(Mandatory = $true)][string] $Path)
    $json = $Value | ConvertTo-Json -Depth 64
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $encoding)
}

function Invoke-eMASRecordedCheck {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][scriptblock] $Action
    )

    try {
        & $Action
        [void]$additionalResults.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        [void]$additionalResults.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}

# The freeze gate runs before any scanner invocation and covers every frozen ZIP, not only structural cases.
foreach ($manifestRow in @($manifestRows | Where-Object { $_.VerificationStatus -eq 'PASS_FROZEN' })) {
    $relativeFixturePath = $manifestRow.FixtureFilename -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $fixturePath = Join-Path $resolvedCorpusRoot $relativeFixturePath
    if (-not [System.IO.File]::Exists($fixturePath)) {
        throw ('FREEZE-VERIFY-001 Frozen fixture is missing: {0}' -f $manifestRow.SampleId)
    }
    $actualHash = Get-eMASTestSha256 -Path $fixturePath
    if ($actualHash -ne $manifestRow.FixtureSHA256) {
        throw ('FREEZE-VERIFY-002 Frozen fixture hash mismatch: {0}' -f $manifestRow.SampleId)
    }
    $sourceState[$manifestRow.SampleId] = [pscustomobject]@{
        Path = $fixturePath
        Hash = $actualHash
        LastWriteTimeUtc = (New-Object System.IO.FileInfo($fixturePath)).LastWriteTimeUtc
    }
    $frozenBeforeVerified++
}
Write-Output ('[PASS] Pre-test freeze gate verified {0} ZIP fixtures.' -f $frozenBeforeVerified)

foreach ($expected in @($expectations.fixtures)) {
    $sampleId = [string]$expected.sampleId
    $state = $sourceState[$sampleId]
    $resultFileName = '{0}.repository-discovery.json' -f $sampleId
    $resultPath = Join-Path $resultRoot $resultFileName
    $status = 'PASS'
    $detail = $null
    $actualSummary = $null

    try {
        $result = Invoke-eMASRepositoryDiscovery `
            -SourcePath $state.Path `
            -OutputPath $resultPath `
            -ExecutionId ('EXEC-REPOSITORY-DISCOVERY-{0}' -f $sampleId)

        Assert-eMASEqual -Expected $expectations.contractId -Actual $result.ContractId -Message "$sampleId contract differs."
        Assert-eMASEqual -Expected $expectations.sourceKind -Actual $result.Repository.SourceKind -Message "$sampleId source kind differs."
        Assert-eMASEqual -Expected $state.Hash -Actual $result.Repository.SourceSha256 -Message "$sampleId source identity differs."
        Assert-eMASTrue -Condition $result.Repository.ReadOnly -Message "$sampleId did not declare read-only access."
        Assert-eMASEqual -Expected 'SourceNameOnly' -Actual $result.Repository.PathDisclosure -Message "$sampleId path disclosure differs."
        Assert-eMASEqual -Expected $null -Actual $result.Repository.ResolvedSourcePath -Message "$sampleId exposed a resolved source path."
        Assert-eMASEqual -Expected $expected.candidateRootCount -Actual @($result.DossierCandidates).Count -Message "$sampleId candidate count differs."

        $actualCandidatePaths = @($result.DossierCandidates | ForEach-Object { $_.RelativePath })
        Assert-eMASArrayEqual -Expected @($expected.candidateRootPaths) -Actual $actualCandidatePaths -Message "$sampleId candidate paths differ."

        $actualNumericSequences = @($result.Sequences | Where-Object { $_.IsExactSequenceFolder } | ForEach-Object { $_.FolderName })
        Assert-eMASArrayEqual -Expected @($expected.numericSequences) -Actual $actualNumericSequences -Message "$sampleId numeric sequence set differs."

        $actualSequenceLikeItems = @($result.Sequences | Where-Object {
            -not $_.IsExactSequenceFolder -and $_.SequenceLikeKind -ne 'NestedSequenceLikeDirectory'
        } | ForEach-Object {
            [pscustomobject][ordered]@{ relativePath = $_.RelativePath; kind = $_.SequenceLikeKind }
        })
        Assert-eMASArrayEqual -Expected @($expected.sequenceLikeItems) -Actual $actualSequenceLikeItems -Message "$sampleId sequence-like items differ."

        $actualNestedPaths = @($result.Sequences | Where-Object {
            $_.SequenceLikeKind -eq 'NestedSequenceLikeDirectory'
        } | ForEach-Object { $_.RelativePath })
        Assert-eMASArrayEqual -Expected @($expected.nestedSequenceLikePaths) -Actual $actualNestedPaths -Message "$sampleId nested paths differ."

        $actualEmptyPaths = @($result.Sequences | Where-Object {
            $_.IsExactSequenceFolder -and $_.FileCount -eq 0 -and $_.DirectoryCount -eq 0
        } | ForEach-Object { $_.RelativePath })
        Assert-eMASArrayEqual -Expected @($expected.emptyNumericPaths) -Actual $actualEmptyPaths -Message "$sampleId empty numeric paths differ."

        $actualWrapperPaths = @($result.Repository.WrapperPaths | ForEach-Object { $_.RelativePath })
        Assert-eMASArrayEqual -Expected @($expected.wrapperPaths) -Actual $actualWrapperPaths -Message "$sampleId wrapper paths differ."

        if (@($result.DossierCandidates).Count -gt 0) {
            $availableRootItems = @($result.DossierCandidates[0].DirectChildItems | ForEach-Object { $_.Name })
        }
        else {
            $availableRootItems = @($result.Repository.Entries | Where-Object {
                $_.RelativePath -notmatch '/'
            } | ForEach-Object { Split-Path -Leaf $_.RelativePath })
        }
        foreach ($requiredItem in @($expected.requiredRootItems)) {
            Assert-eMASTrue -Condition ($availableRootItems -contains $requiredItem) -Message "$sampleId omitted required root item $requiredItem."
        }

        $resultJson = $result | ConvertTo-Json -Depth 64 -Compress
        foreach ($forbiddenProperty in @($expectations.forbiddenResultProperties)) {
            Assert-eMASTrue -Condition ($resultJson -notmatch ('"{0}"\s*:' -f [regex]::Escape($forbiddenProperty))) -Message "$sampleId emitted prohibited property $forbiddenProperty."
        }
        Assert-eMASEqual -Expected 0 -Actual @($result.ClassificationEvidence).Count -Message "$sampleId emitted classification evidence."

        if ($sampleId -eq 'SD-001') {
            Assert-eMASTrue -Condition ($actualNumericSequences -notcontains '0000-WorkingDocuments') -Message 'SD-001 normalized 0000-WorkingDocuments into a sequence.'
        }
        if ($sampleId -eq 'SD-011') {
            $nestedArchiveFile = @($result.Files | Where-Object { $_.RelativePath -like '*/0004.zip' })
            Assert-eMASEqual -Expected 1 -Actual $nestedArchiveFile.Count -Message 'SD-011 sequence-like archive file count differs.'
            Assert-eMASEqual -Expected 'NotCollected' -Actual $nestedArchiveFile[0].ArchiveInspectionStatus -Message 'SD-011 nested archive was unexpectedly inspected.'
            Assert-eMASEqual -Expected 0 -Actual @($result.Repository.Entries | Where-Object { $_.RelativePath -like '*/0004.zip/*' }).Count -Message 'SD-011 nested ZIP was recursively expanded.'
        }
        if ($sampleId -eq 'SD-014') {
            $nested = @($result.Sequences | Where-Object { $_.RelativePath -like '*/0003/0003' })
            Assert-eMASEqual -Expected 1 -Actual $nested.Count -Message 'SD-014 nested numeric directory count differs.'
            Assert-eMASTrue -Condition (-not $nested[0].IsExactSequenceFolder) -Message 'SD-014 nested directory was treated as a root-level sequence.'
            Assert-eMASTrue -Condition (-not [string]::IsNullOrWhiteSpace($nested[0].ParentSequenceId)) -Message 'SD-014 parent-child relationship is missing.'
        }
        if ($sampleId -eq 'SD-020') {
            Assert-eMASEqual -Expected 0 -Actual @($result.DossierCandidates).Count -Message 'SD-020 was force-classified as a dossier.'
            $coverage = @($result.CollectionCoverage | Where-Object { $_.CheckId -eq 'DossierCandidateDiscovery' })
            Assert-eMASEqual -Expected 'Available' -Actual $coverage[0].CaptureStatus -Message 'SD-020 discovery coverage was not completed.'
        }

        $repeat = Invoke-eMASRepositoryDiscovery -SourcePath $state.Path -ExecutionId ('EXEC-REPOSITORY-DISCOVERY-{0}' -f $sampleId)
        Assert-eMASEqual `
            -Expected (ConvertTo-eMASDeterministicProjection -Result $result) `
            -Actual (ConvertTo-eMASDeterministicProjection -Result $repeat) `
            -Message "$sampleId deterministic projection differs across repeat runs."

        $actualSummary = [pscustomobject][ordered]@{
            SourceKind = $result.Repository.SourceKind
            CandidateRootCount = @($result.DossierCandidates).Count
            CandidateRootPaths = [object[]]$actualCandidatePaths
            NumericSequences = [object[]]$actualNumericSequences
            SequenceLikeItems = [object[]]$actualSequenceLikeItems
            NestedSequenceLikePaths = [object[]]$actualNestedPaths
            EmptyNumericPaths = [object[]]$actualEmptyPaths
            WrapperPaths = [object[]]$actualWrapperPaths
        }
        $zipResultsBySample[$sampleId] = $result
        Write-Output ('[PASS] {0} structured discovery acceptance' -f $sampleId)
    }
    catch {
        $status = 'FAIL'
        $detail = $_.Exception.Message
        Write-Output ('[FAIL] {0}: {1}' -f $sampleId, $detail)
    }

    [void]$fixtureResults.Add([pscustomobject][ordered]@{
        Fixture = $sampleId
        Expected = $expected
        Actual = $actualSummary
        Status = $status
        Detail = $detail
        ResultPath = ('results/{0}' -f $resultFileName)
    })
}

Invoke-eMASRecordedCheck -Name 'Directory and ZIP discovery produce equivalent structural observations for SD-002' -Action {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-repository-discovery-{0}' -f [guid]::NewGuid().ToString('N'))
    $directorySource = Join-Path $temporaryRoot 'source'
    try {
        [void][System.IO.Directory]::CreateDirectory($directorySource)
        try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($sourceState['SD-002'].Path, $directorySource)
        $directoryResultPath = Join-Path $resultRoot 'SD-002-directory.repository-discovery.json'
        $directoryResult = Invoke-eMASRepositoryDiscovery `
            -SourcePath $directorySource `
            -OutputPath $directoryResultPath `
            -ExecutionId 'EXEC-REPOSITORY-DISCOVERY-SD-002-DIRECTORY'
        Assert-eMASEqual -Expected 'Directory' -Actual $directoryResult.Repository.SourceKind -Message 'Directory source kind differs.'
        Assert-eMASArrayEqual `
            -Expected @($zipResultsBySample['SD-002'].DossierCandidates | ForEach-Object { $_.RelativePath }) `
            -Actual @($directoryResult.DossierCandidates | ForEach-Object { $_.RelativePath }) `
            -Message 'Directory candidate paths differ from ZIP.'
        Assert-eMASArrayEqual `
            -Expected @($zipResultsBySample['SD-002'].Sequences | Where-Object IsExactSequenceFolder | ForEach-Object { $_.FolderName }) `
            -Actual @($directoryResult.Sequences | Where-Object IsExactSequenceFolder | ForEach-Object { $_.FolderName }) `
            -Message 'Directory sequence set differs from ZIP.'
        $directoryRepeat = Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -ExecutionId 'EXEC-REPOSITORY-DISCOVERY-SD-002-DIRECTORY'
        Assert-eMASEqual `
            -Expected (ConvertTo-eMASDeterministicProjection -Result $directoryResult) `
            -Actual (ConvertTo-eMASDeterministicProjection -Result $directoryRepeat) `
            -Message 'Directory deterministic projection differs across repeat runs.'

        $didRejectUnsafeOutput = $false
        try {
            Invoke-eMASRepositoryDiscovery -SourcePath $directorySource -OutputPath (Join-Path $directorySource 'result.json') -ExecutionId 'EXEC-UNSAFE-OUTPUT' | Out-Null
        }
        catch {
            $didRejectUnsafeOutput = $_.Exception.Message -like '*DISC-OUTPUT-002*'
        }
        Assert-eMASTrue -Condition $didRejectUnsafeOutput -Message 'Output inside directory SourcePath was not rejected.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) {
            [System.IO.Directory]::Delete($temporaryRoot, $true)
        }
    }
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry script orchestrates RepositoryDiscovery without mandatory runtime JSON' -Action {
    $entryResultPath = Join-Path $resultRoot 'SD-002-entrypoint.repository-discovery.json'
    $entryResult = & $entryScriptPath `
        -SourcePath $sourceState['SD-002'].Path `
        -OutputPath $entryResultPath `
        -ExecutionId 'EXEC-REPOSITORY-DISCOVERY-ENTRYPOINT'
    Assert-eMASEqual -Expected 1 -Actual @($entryResult.DossierCandidates).Count -Message 'Entry-point candidate count differs.'
    Assert-eMASEqual -Expected 'PreSales' -Actual $entryResult.Execution.Phase -Message 'Entry-point phase differs.'
}

Invoke-eMASRecordedCheck -Name 'Pre-Sales entry script reuses the runtime configuration loader when configuration is supplied' -Action {
    $configuredEntryResultPath = Join-Path $resultRoot 'SD-002-entrypoint-configured.repository-discovery.json'
    $configuredEntryResult = & $entryScriptPath `
        -RuntimeConfigurationPath $validRuntimeConfigurationPath `
        -SourcePath $sourceState['SD-002'].Path `
        -OutputPath $configuredEntryResultPath `
        -ExecutionId 'EXEC-REPOSITORY-DISCOVERY-ENTRYPOINT-CONFIGURED'
    Assert-eMASEqual -Expected 'CFG-SYNTHETIC-001' -Actual $configuredEntryResult.Execution.Configuration.ConfigurationId -Message 'Configuration identity was not attached.'
    Assert-eMASEqual -Expected (Get-eMASTestSha256 -Path $validRuntimeConfigurationPath) -Actual $configuredEntryResult.Execution.Configuration.Sha256 -Message 'Configuration hash differs.'
}

# Re-run the freeze gate after all tests and compare both hash and write time.
foreach ($sampleId in @($sourceState.Keys)) {
    $state = $sourceState[$sampleId]
    $actualHash = Get-eMASTestSha256 -Path $state.Path
    if ($actualHash -ne $state.Hash) {
        throw ('FREEZE-VERIFY-003 Frozen fixture changed during testing: {0}' -f $sampleId)
    }
    $actualWriteTime = (New-Object System.IO.FileInfo($state.Path)).LastWriteTimeUtc
    if ($actualWriteTime -ne $state.LastWriteTimeUtc) {
        throw ('FREEZE-VERIFY-004 Frozen fixture timestamp changed during testing: {0}' -f $sampleId)
    }
    $frozenAfterVerified++
}
Write-Output ('[PASS] Post-test freeze gate verified {0} ZIP fixtures.' -f $frozenAfterVerified)

$fixtureFailureCount = @($fixtureResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$additionalFailureCount = @($additionalResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$overallStatus = 'PASS'
if (($fixtureFailureCount + $additionalFailureCount) -gt 0) {
    $overallStatus = 'FAIL'
}

$summary = [pscustomobject][ordered]@{
    ContractId = $expectations.contractId
    Capability = 'RepositoryDiscovery'
    StartedAtUtc = $startedAtUtc.ToString('o')
    CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    OverallStatus = $overallStatus
    FrozenFixtureCountVerifiedBefore = $frozenBeforeVerified
    FrozenFixtureCountVerifiedAfter = $frozenAfterVerified
    FixtureCaseCount = $fixtureResults.Count
    FixturePassCount = @($fixtureResults | Where-Object { $_.Status -eq 'PASS' }).Count
    FixtureFailCount = $fixtureFailureCount
    AdditionalCheckCount = $additionalResults.Count
    AdditionalCheckFailCount = $additionalFailureCount
    FixtureResults = [object[]]@($fixtureResults)
    AdditionalChecks = [object[]]@($additionalResults)
}
$summaryPath = Join-Path $resolvedOutputRoot 'repository-discovery-test-summary.json'
Write-eMASTestJson -Value $summary -Path $summaryPath
Write-Output ('RepositoryDiscovery tests completed: {0}; summary={1}' -f $overallStatus, $summaryPath)
if ($overallStatus -ne 'PASS') {
    exit 1
}
exit 0
