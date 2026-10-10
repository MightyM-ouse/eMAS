#requires -Version 5.1

[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixtureRoot = Join-Path $repositoryRoot 'tests/fixtures/regional-xml-evidence'
$safeXmlPath = Join-Path $repositoryRoot 'engine/powershell51/private/eMAS.SafeXml.ps1'
$helperPath = Join-Path $repositoryRoot 'engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1'
$bxiPath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1'
$cecPath = Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1'
. $safeXmlPath
. $helperPath
Import-Module $cecPath -Force

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)
$checks = New-Object System.Collections.ArrayList
$fixtureState = @{}
$regionalTypes = @('EuEnvelopeCountry','EuAgencyCode','EuProcedureType','EuSubmissionType','EuSubmissionUnitType')

function Assert-eMAST1bTrue { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMAST1bEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Get-eMAST1bSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose(); $stream.Dispose() }
}
function Invoke-eMAST1bCheck {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)
    try {
        & $Action
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        [void]$checks.Add([pscustomobject][ordered]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message)
    }
}
function Read-eMAST1bFixture {
    param([Parameter(Mandatory = $true)][string] $Name)
    $path = Join-Path $fixtureRoot $Name
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try { $loaded = Read-eMASSafeXmlDocument -Stream $stream }
    finally { $stream.Dispose() }
    if ($loaded.ParseStatus -ne 'Parsed') { return $loaded }
    return Get-eMASEuRegionalEnvelope -Document $loaded.Document
}
function Get-eMAST1bField {
    param([Parameter(Mandatory = $true)][object] $RegionalEnvelope, [Parameter(Mandatory = $true)][string] $FieldCode, [int] $EnvelopeOrdinal = 1)
    return @($RegionalEnvelope.Envelopes[$EnvelopeOrdinal - 1].Fields | Where-Object { $_.FieldCode -eq $FieldCode })[0]
}
function New-eMAST1bMockInput {
    param([Parameter(Mandatory = $true)][object] $RegionalEnvelope, [object[]] $ExistingEvidence = @())
    return [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{
            ExecutionId = 'EXEC-T1B-MOCK'; Phase = 'PreSales'; ScenarioId = 'MS-04'; ScannerName = 'eMAS.RepositoryDiscovery+BackboneXmlInventory'
            ScannerVersion = '0.3.0'; Capabilities = [object[]]@('RepositoryDiscovery','BackboneXmlInventory'); CompletionStatus = 'Completed'
            StartedAtUtc = '2026-01-01T00:00:00.0000000Z'; CompletedAtUtc = '2026-01-01T00:00:01.0000000Z'
        }
        Repository = [pscustomobject][ordered]@{
            SourceKind = 'Directory'; ResolvedSourcePath = '/source/is/intentionally/unavailable'; InventoryCaptureStatus = 'Available'
            Entries = [object[]]@(
                [pscustomobject]@{ EntryKind = 'Directory'; RelativePath = 'Dossier' },
                [pscustomobject]@{ EntryKind = 'Directory'; RelativePath = 'Dossier/0001' },
                [pscustomobject]@{ EntryKind = 'Directory'; RelativePath = 'Dossier/0001/m1' }
            )
        }
        DossierCandidates = [object[]]@([pscustomobject]@{ DossierId = 'DOS-0001'; RelativePath = 'Dossier' })
        Sequences = [object[]]@([pscustomobject]@{ DossierId = 'DOS-0001'; SequenceId = 'SEQ-0001'; RelativePath = 'Dossier/0001'; FolderName = '0001'; SequenceLikeKind = 'NumericSequenceDirectory' })
        XmlDocuments = [object[]]@([pscustomobject][ordered]@{
            XmlId = 'XML-0001'; DossierId = 'DOS-0001'; SequenceId = 'SEQ-0001'; RelativePath = 'Dossier/0001/m1/eu/eu-regional.xml'
            XmlKind = 'RegionalBackbone'; Exists = $true; ParseStatus = 'Parsed'; CaptureStatus = 'Available'; RootElement = 'eu-backbone'
            NamespaceUri = 'http://europa.eu.int'; DeclaredVersion = $RegionalEnvelope.ProfileVersion; HasDocumentType = $false
            DocumentTypeName = $null; SystemId = $null; PublicId = $null; RegionalEnvelope = $RegionalEnvelope
        })
        References = [object[]]@(); Files = [object[]]@(); LifecycleRelationships = [object[]]@(); Observations = [object[]]@()
        ClassificationEvidence = [object[]]@($ExistingEvidence); CollectionCoverage = [object[]]@()
    }
}

foreach ($file in [System.IO.Directory]::GetFiles($fixtureRoot, '*.xml')) {
    $fixtureState[$file] = [pscustomobject]@{ Hash = Get-eMAST1bSha256 -Path $file; LastWriteTimeUtc = (New-Object System.IO.FileInfo($file)).LastWriteTimeUtc }
}

$eu20 = Read-eMAST1bFixture 'eu20.xml'
$eu301 = Read-eMAST1bFixture 'eu301.xml'
$eu31 = Read-eMAST1bFixture 'eu31-multiple-prefix.xml'
$missingUnit = Read-eMAST1bFixture 'eu31-missing-unit.xml'
$unknown = Read-eMAST1bFixture 'eu31-unknown.xml'
$duplicateAgency = Read-eMAST1bFixture 'eu31-duplicate-agency.xml'
$unsupported = Read-eMAST1bFixture 'unsupported-profile.xml'
$missingProfile = Read-eMAST1bFixture 'missing-profile.xml'
$rootMismatch = Read-eMAST1bFixture 'root-namespace-mismatch.xml'
$defaultEnvelope = Read-eMAST1bFixture 'default-namespace-envelope.xml'
$malformed = Read-eMAST1bFixture 'malformed.xml'

Invoke-eMAST1bCheck 'supported 2.0, 3.0.1 and 3.1 profiles extract exactly five ordered fields' {
    foreach ($case in @(@{ Result = $eu20; Version = '2.0' }, @{ Result = $eu301; Version = '3.0.1' }, @{ Result = $eu31; Version = '3.1' })) {
        Assert-eMAST1bEqual 'Supported' $case.Result.ProfileStatus 'Profile status differs.'
        Assert-eMAST1bEqual $case.Version $case.Result.ProfileVersion 'Profile version differs.'
        Assert-eMAST1bEqual 'EU_ENVELOPE_COUNTRY|EU_AGENCY_CODE|EU_PROCEDURE_TYPE|EU_SUBMISSION_TYPE|EU_SUBMISSION_UNIT_TYPE' (@($case.Result.Envelopes[0].Fields | ForEach-Object { $_.FieldCode }) -join '|') 'Field catalogue/order differs.'
    }
    Assert-eMAST1bEqual 'NotDefinedInProfile' (Get-eMAST1bField $eu20 'EU_SUBMISSION_UNIT_TYPE').ValueStatus '2.0 submission-unit status differs.'
}

Invoke-eMAST1bCheck 'namespace prefix variation and legitimate multiple envelopes preserve document order' {
    Assert-eMAST1bEqual 2 $eu31.EnvelopeCount '3.1 envelope count differs.'
    Assert-eMAST1bEqual '1|2' (@($eu31.Envelopes | ForEach-Object { $_.EnvelopeOrdinal }) -join '|') 'Envelope ordinals differ.'
    Assert-eMAST1bEqual 'fr|de' (@($eu31.Envelopes | ForEach-Object { (Get-eMAST1bField $eu31 'EU_ENVELOPE_COUNTRY' $_.EnvelopeOrdinal).Value }) -join '|') 'Country order differs.'
}

Invoke-eMAST1bCheck 'mandatory absence, vocabulary misses and cardinality violation remain distinct raw facts' {
    Assert-eMAST1bEqual 'Absent' (Get-eMAST1bField $missingUnit 'EU_SUBMISSION_UNIT_TYPE').ValueStatus 'Mandatory absence status differs.'
    Assert-eMAST1bEqual 'OutsideProfileVocabulary' (Get-eMAST1bField $unknown 'EU_ENVELOPE_COUNTRY').ValueStatus 'EU-EMA country status differs.'
    Assert-eMAST1bEqual 'EU-EMA' (Get-eMAST1bField $unknown 'EU_ENVELOPE_COUNTRY').Value 'EU-EMA country raw value was changed.'
    Assert-eMAST1bEqual 'OutsideProfileVocabulary' (Get-eMAST1bField $unknown 'EU_AGENCY_CODE').ValueStatus 'Lower-case agency status differs.'
    $multiple = Get-eMAST1bField $duplicateAgency 'EU_AGENCY_CODE'
    Assert-eMAST1bEqual 'MultipleValues' $multiple.ValueStatus 'Duplicate agency status differs.'
    Assert-eMAST1bEqual 'FR-ANSM|DE-BFARM' (@($multiple.Values) -join '|') 'Duplicate agency raw values differ.'
}

Invoke-eMAST1bCheck 'unsupported profile and structural mismatches are not interpreted' {
    Assert-eMAST1bEqual 'UnsupportedRegionalProfile' $unsupported.ProfileStatus 'Unsupported profile status differs.'
    Assert-eMAST1bEqual 'UnsupportedRegionalProfile' $missingProfile.ProfileStatus 'Missing profile status differs.'
    Assert-eMAST1bEqual 'UnrecognizedRegionalStructure' $rootMismatch.ProfileStatus 'Root namespace mismatch status differs.'
    Assert-eMAST1bEqual 'UnrecognizedRegionalStructure' $defaultEnvelope.ProfileStatus 'Namespaced envelope mismatch status differs.'
    Assert-eMAST1bEqual 'ParseFailed' $malformed.ParseStatus 'Malformed XML was not rejected by the safe parser.'
}

Invoke-eMAST1bCheck 'CEC emits factual recognized values and field-specific coverage only' {
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput $eu31)
    $records = @($result.ClassificationEvidence | Where-Object { $regionalTypes -contains $_.EvidenceType })
    Assert-eMAST1bEqual 10 $records.Count '3.1 regional evidence count differs.'
    Assert-eMAST1bEqual 0 @($records | Where-Object { $_.Strength -ne 'Strong' -or $_.SourceTier -ne 'StructuredXml' }).Count 'Regional strength/tier differs.'
    Assert-eMAST1bEqual 0 @($records | Where-Object { $null -ne $_.CandidateValue -or $null -ne $_.Polarity -or $null -ne $_.SourceRuleId }).Count 'Interpretation fields were populated.'
    Assert-eMAST1bEqual 5 @($result.CollectionCoverage | Where-Object { $_.CheckId -like 'RegionalEnvelopeField:*' }).Count 'Field coverage count differs.'
    Assert-eMAST1bEqual 0 @($records | Where-Object { [string]$_.ObservedValue -like 'Synthetic*' }).Count 'Free text became first-wave evidence.'
}

Invoke-eMAST1bCheck 'out-of-vocabulary and ambiguous values emit no unsupported Strong record' {
    $unknownResult = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput $unknown)
    Assert-eMAST1bEqual 0 @($unknownResult.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'EuEnvelopeCountry' -or $_.EvidenceType -eq 'EuAgencyCode' }).Count 'Unknown values became Strong evidence.'
    Assert-eMAST1bEqual 2 @($unknownResult.CollectionCoverage | Where-Object { $_.ReasonCode -eq 'ValueOutsideProfileVocabulary' }).Count 'Unknown-value coverage differs.'
    $duplicateResult = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput $duplicateAgency)
    Assert-eMAST1bEqual 0 @($duplicateResult.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'EuAgencyCode' }).Count 'Ambiguous agency became Strong evidence.'
    Assert-eMAST1bEqual 1 @($duplicateResult.CollectionCoverage | Where-Object { $_.CheckId -eq 'RegionalEnvelopeField:EU_AGENCY_CODE' -and $_.ReasonCode -eq 'CardinalityViolation' }).Count 'Cardinality coverage differs.'
}

Invoke-eMAST1bCheck 'field-not-defined and mandatory-absent coverage remain distinct' {
    $profile20Result = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput $eu20)
    Assert-eMAST1bEqual 1 @($profile20Result.CollectionCoverage | Where-Object { $_.CheckId -eq 'RegionalEnvelopeField:EU_SUBMISSION_UNIT_TYPE' -and $_.ReasonCode -eq 'FieldNotDefinedInProfile' }).Count 'Field-not-defined coverage differs.'
    $missingResult = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput $missingUnit)
    Assert-eMAST1bEqual 1 @($missingResult.CollectionCoverage | Where-Object { $_.CheckId -eq 'RegionalEnvelopeField:EU_SUBMISSION_UNIT_TYPE' -and $_.ReasonCode -eq 'MandatoryFieldAbsent' }).Count 'Mandatory-absent coverage differs.'
}

Invoke-eMAST1bCheck 'historical shape and IDs are preserved while SourceOrdinal is new-record-only' {
    $existing = [pscustomobject][ordered]@{ EvidenceId = 'EVD-0042'; EvidenceType = 'HistoricalSynthetic'; CandidateValue = $null }
    $result = Invoke-eMASClassificationEvidenceCollection -InputResult (New-eMAST1bMockInput -RegionalEnvelope $eu301 -ExistingEvidence @($existing))
    $historical = @($result.ClassificationEvidence | Where-Object { $_.EvidenceId -eq 'EVD-0042' })[0]
    Assert-eMAST1bTrue ($historical.PSObject.Properties.Name -notcontains 'SourceOrdinal') 'Historical record gained SourceOrdinal.'
    $regional = @($result.ClassificationEvidence | Where-Object { $regionalTypes -contains $_.EvidenceType })
    Assert-eMAST1bEqual 0 @($regional | Where-Object { $_.PSObject.Properties.Name -notcontains 'SourceOrdinal' -or $_.SourceOrdinal -ne 1 }).Count 'Regional SourceOrdinal differs.'
    Assert-eMAST1bEqual 'EVD-0053' $regional[0].EvidenceId 'Regional IDs did not follow the other new factual records deterministically.'
}

Invoke-eMAST1bCheck 'CEC is deterministic and does not reopen the unavailable source path' {
    $input = New-eMAST1bMockInput $eu31
    $first = Invoke-eMASClassificationEvidenceCollection -InputResult $input
    $second = Invoke-eMASClassificationEvidenceCollection -InputResult $input
    Assert-eMAST1bEqual ($first.ClassificationEvidence | ConvertTo-Json -Depth 32 -Compress) ($second.ClassificationEvidence | ConvertTo-Json -Depth 32 -Compress) 'CEC evidence is not deterministic.'
    $reordered = ($input | ConvertTo-Json -Depth 32) | ConvertFrom-Json
    $reordered.XmlDocuments[0].RegionalEnvelope.Envelopes = [object[]]@($reordered.XmlDocuments[0].RegionalEnvelope.Envelopes[1], $reordered.XmlDocuments[0].RegionalEnvelope.Envelopes[0])
    $fromReorderedInput = Invoke-eMASClassificationEvidenceCollection -InputResult $reordered
    Assert-eMAST1bEqual ($first.ClassificationEvidence | ConvertTo-Json -Depth 32 -Compress) ($fromReorderedInput.ClassificationEvidence | ConvertTo-Json -Depth 32 -Compress) 'CEC evidence changed when envelope facts were supplied out of ordinal order.'
    $cecText = [System.IO.File]::ReadAllText($cecPath)
    foreach ($pattern in @('System\.Xml','XmlReader','LoadXml','SelectNodes','File\]::Open','ReadAllText')) {
        Assert-eMAST1bTrue ($cecText -notmatch $pattern) ("CEC contains prohibited source/XML access pattern {0}." -f $pattern)
    }
}

Invoke-eMAST1bCheck 'BXI invokes the EU helper on its already-loaded DOM with external resolution disabled' {
    $bxiText = [System.IO.File]::ReadAllText($bxiPath)
    $helperText = [System.IO.File]::ReadAllText($helperPath)
    $safeText = [System.IO.File]::ReadAllText($safeXmlPath)
    Assert-eMAST1bTrue ($bxiText -match 'Get-eMASEuRegionalEnvelope\s+-Document\s+\$document') 'BXI does not pass its loaded DOM to the EU helper.'
    Assert-eMAST1bTrue ($helperText -notmatch 'File\]::|Get-Content|XmlReader|Load\(') 'EU helper performs source I/O or a second parse.'
    Assert-eMAST1bTrue ($safeText -match '\$settings\.XmlResolver\s*=\s*\$null') 'Safe reader external resolution is not disabled.'
}

foreach ($file in @($fixtureState.Keys)) {
    Assert-eMAST1bEqual $fixtureState[$file].Hash (Get-eMAST1bSha256 -Path $file) ('Fixture hash changed: {0}' -f $file)
    Assert-eMAST1bEqual $fixtureState[$file].LastWriteTimeUtc (New-Object System.IO.FileInfo($file)).LastWriteTimeUtc ('Fixture timestamp changed: {0}' -f $file)
}

$failureCount = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count
$summary = [pscustomobject][ordered]@{
    TaskId = 'EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE'
    Platform = [pscustomobject][ordered]@{ PSEdition = $PSVersionTable.PSEdition; PSVersion = $PSVersionTable.PSVersion.ToString(); OS = $(if ($PSVersionTable.ContainsKey('OS')) { $PSVersionTable.OS } else { [System.Environment]::OSVersion.VersionString }) }
    FixtureCount = $fixtureState.Count; FixtureHashesVerifiedBeforeAndAfter = $fixtureState.Count
    CheckCount = $checks.Count; PassCount = @($checks | Where-Object { $_.Status -eq 'PASS' }).Count; FailCount = $failureCount
    OverallStatus = $(if ($failureCount -eq 0) { 'PASS' } else { 'FAIL' }); Checks = [object[]]@($checks)
}
$summaryPath = Join-Path $resolvedOutputRoot 'regional-xml-evidence-test-summary.json'
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 16), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('Regional XML evidence tests completed: {0} ({1}/{2}); fixtures read-only {3}/{3}; summary={4}' -f $summary.OverallStatus, $summary.PassCount, $summary.CheckCount, $summary.FixtureCount, $summaryPath)
if ($failureCount -gt 0) { exit 1 }
