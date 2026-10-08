#requires -Version 5.1

[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixtureRoot = Join-Path $repositoryRoot 'tests/fixtures/submissionunit-xml-inventory'
$manifestPath = Join-Path $fixtureRoot 'SUXI_FREEZE_MANIFEST.csv'
$wave1ERoot = Join-Path $repositoryRoot 'tests/fixtures/repository-discovery-ectd4/wave1e'
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-suxi-{0}' -f [guid]::NewGuid().ToString('N'))
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
[void][System.IO.Directory]::CreateDirectory($temporaryRoot)
[void][System.IO.Directory]::CreateDirectory($resolvedOutputRoot)

Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1') -Force
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1') -Force
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1') -Force
Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1') -Force
. (Join-Path $repositoryRoot 'engine/powershell51/private/eMAS.Ectd4Vocabulary.ps1')

$script:passed = 0
$script:failed = 0
$script:sourceState = @{}

function Assert-eMAST2True { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMAST2Equal {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Assert-eMAST2Null { param([AllowNull()][object] $Value, [string] $Message) if ($null -ne $Value) { throw ('{0} Actual={1}' -f $Message, $Value) } }

function Invoke-eMAST2Check {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)
    try { & $Action; $script:passed++; Write-Output ('[PASS] {0}' -f $Name) }
    catch { $script:failed++; Write-Output ('[FAIL] {0}: {1}' -f $Name, $_.Exception.Message) }
}

function Get-eMAST2Sha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try { $sha = [System.Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() } }
    finally { $stream.Dispose() }
}

function New-eMAST2Repository {
    param(
        [Parameter(Mandatory = $true)][hashtable] $XmlByFolder,
        [string] $Name = ([guid]::NewGuid().ToString('N')),
        [switch] $Ambiguous,
        [switch] $AsZip
    )
    $root = Join-Path $temporaryRoot $Name
    [void][System.IO.Directory]::CreateDirectory($root)
    foreach ($folder in $XmlByFolder.Keys) {
        $unit = Join-Path $root $folder
        [void][System.IO.Directory]::CreateDirectory((Join-Path $unit 'm1'))
        [System.IO.File]::Copy([string]$XmlByFolder[$folder], (Join-Path $unit 'submissionunit.xml'), $true)
        [System.IO.File]::WriteAllText((Join-Path $unit 'sha256.txt'), ('0' * 64), (New-Object System.Text.UTF8Encoding($false)))
        [System.IO.File]::WriteAllText((Join-Path $unit 'm1/synthetic-content.txt'), 'eMAS synthetic T2 content', (New-Object System.Text.UTF8Encoding($false)))
        if ($Ambiguous) { [System.IO.File]::WriteAllText((Join-Path $unit 'index.xml'), '<ectd/>', (New-Object System.Text.UTF8Encoding($false))) }
    }
    if (-not $AsZip) { return $root }
    try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue } catch { }
    $zipPath = $root + '.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($root, $zipPath, [System.IO.Compression.CompressionLevel]::NoCompression, $false)
    return $zipPath
}

function Invoke-eMAST2Chain {
    param([Parameter(Mandatory = $true)][string] $SourcePath, [switch] $SkipCec)
    $rd = Invoke-eMASRepositoryDiscovery -SourcePath $SourcePath -ExecutionId ('SUXI-' + [guid]::NewGuid().ToString('N')) -ScenarioId 'MS-04' -Phase 'PreSales'
    $bxi = Invoke-eMASBackboneXmlInventory -SourcePath $SourcePath -RepositoryDiscoveryResult $rd
    $suxi = Invoke-eMASSubmissionUnitXmlInventory -SourcePath $SourcePath -InputResult $bxi
    $cec = $null
    if (-not $SkipCec) { $cec = Invoke-eMASClassificationEvidenceCollection -InputResult $suxi }
    return [pscustomobject]@{ SourcePath = $SourcePath; Rd = $rd; Bxi = $bxi; Suxi = $suxi; Cec = $cec }
}

function Get-eMAST2FixturePath {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    return Join-Path $fixtureRoot $RelativePath
}

function ConvertTo-eMAST2StableJson {
    param([AllowNull()][object] $Value)
    return ($Value | ConvertTo-Json -Depth 64 -Compress)
}

try {
    $manifestRows = @(Import-Csv -LiteralPath $manifestPath)
    foreach ($row in $manifestRows) {
        $path = Get-eMAST2FixturePath -RelativePath ([string]$row.RelativePath)
        $hash = Get-eMAST2Sha256 -Path $path
        Assert-eMAST2Equal ([string]$row.SHA256) $hash ('Fixture hash mismatch: {0}' -f $row.SampleId)
        $script:sourceState[[string]$row.RelativePath] = $hash
    }
    Write-Output ('[PASS] Pre-test freeze gate verified {0} synthetic XML files.' -f $manifestRows.Count)

    $euPath = Get-eMAST2FixturePath 'fixtures/SD-028/submissionunit.xml'
    $fdaPath = Get-eMAST2FixturePath 'fixtures/SD-029/submissionunit.xml'
    $eu = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $euPath } -Name 'sd028')
    $fda = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $fdaPath } -Name 'sd029')

    Invoke-eMAST2Check 'T-1 namespace-prefix independence preserves extracted facts' {
        $prefixed = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-088/submissionunit.xml') } -Name 'sd088-prefix')
        $prefixedZip = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-088/submissionunit.xml') } -Name 'sd088-prefix-zip' -AsZip)
        Assert-eMAST2Equal 'PORP_IN000001UV' $prefixed.Suxi.SubmissionUnitXmlDocuments[0].Structure.RootLocalName 'Prefixed root local name differs.'
        Assert-eMAST2Equal 'urn:hl7-org:v3' $prefixed.Suxi.SubmissionUnitXmlDocuments[0].Structure.RootNamespaceUri 'Prefixed namespace differs.'
        Assert-eMAST2Equal 8 @($prefixed.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' }).Count 'Prefixed fact count differs.'
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson $prefixed.Suxi.SubmissionUnitXmlDocuments) (ConvertTo-eMAST2StableJson $prefixedZip.Suxi.SubmissionUnitXmlDocuments) 'Directory and ZIP inventory differ.'
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson @($prefixed.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })) (ConvertTo-eMAST2StableJson @($prefixedZip.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })) 'Directory and ZIP CEC evidence differ.'
    }

    Invoke-eMAST2Check 'T-2 free text and personal-data-shaped fields never reach inventory or CEC' {
        $json = ConvertTo-eMAST2StableJson -Value @($eu.Suxi.SubmissionUnitXmlDocuments, $eu.Cec.ClassificationEvidence)
        Assert-eMAST2True (-not $json.Contains('Synthetic product title must not be collected')) 'Free-text title leaked into output.'
        Assert-eMAST2True (-not $json.Contains('contactParty')) 'Contact content leaked into output.'
    }

    Invoke-eMAST2Check 'T-3 T2 CEC records preserve null interpretation fields and XmlId' {
        $records = @($fda.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })
        Assert-eMAST2True ($records.Count -gt 0) 'No T2 records were emitted.'
        foreach ($record in $records) { Assert-eMAST2Null $record.CandidateValue 'CandidateValue must be null.'; Assert-eMAST2Null $record.Polarity 'Polarity must be null.'; Assert-eMAST2Null $record.SourceRuleId 'SourceRuleId must be null.'; Assert-eMAST2Null $record.XmlId 'XmlId must be null.' }
    }

    Invoke-eMAST2Check 'T-4 historical CEC objects and IDs are property-identical' {
        $without = Invoke-eMASClassificationEvidenceCollection -InputResult $eu.Bxi
        $historicalWith = @($eu.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -notlike 'Ectd4*' })
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson @($without.ClassificationEvidence)) (ConvertTo-eMAST2StableJson $historicalWith) 'Historical CEC projection changed.'
        foreach ($record in $historicalWith) { Assert-eMAST2True ($null -eq $record.PSObject.Properties['SubmissionUnitXmlId']) 'Historical record gained a T2 property.' }
    }

    Invoke-eMAST2Check 'T-5 T2 CEC identity is deterministic under shuffled document input' {
        $mixed = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $euPath; '2' = $fdaPath } -Name 'shuffle')
        $clone = ($mixed.Suxi | ConvertTo-Json -Depth 64) | ConvertFrom-Json
        [array]::Reverse($clone.SubmissionUnitXmlDocuments)
        $shuffled = Invoke-eMASClassificationEvidenceCollection -InputResult $clone
        $a = @($mixed.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })
        $b = @($shuffled.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson $a) (ConvertTo-eMAST2StableJson $b) 'Shuffling changed T2 evidence.'
    }

    Invoke-eMAST2Check 'T-6 CEC is source-independent and contains no XML reader' {
        $isolated = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $euPath } -Name 'source-independent') -SkipCec
        [System.IO.Directory]::Delete($isolated.SourcePath, $true)
        $cec = Invoke-eMASClassificationEvidenceCollection -InputResult $isolated.Suxi
        Assert-eMAST2Equal 8 @($cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' }).Count 'CEC lost in-memory T2 facts.'
        $cecText = [System.IO.File]::ReadAllText((Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1'))
        Assert-eMAST2True ($cecText -notmatch 'Read-eMASSafeXmlDocument|XmlReader|XmlDocument\.Load') 'CEC contains XML reader logic.'
    }

    Invoke-eMAST2Check 'T-7 capability is absent unless explicitly requested' {
        $source = New-eMAST2Repository -XmlByFolder @{ '1' = $euPath } -Name 'disabled'
        $output = Join-Path $resolvedOutputRoot 'disabled.json'
        & (Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath $source -OutputPath $output -ExecutionId 'SUXI-DISABLED' -IncludeBackboneXmlInventory | Out-Null
        $result = [System.IO.File]::ReadAllText($output) | ConvertFrom-Json
        Assert-eMAST2True (@($result.Execution.Capabilities) -notcontains 'SubmissionUnitXmlInventory') 'Disabled capability token was present.'
        Assert-eMAST2True ($null -eq $result.PSObject.Properties['SubmissionUnitXmlDocuments']) 'Disabled capability created output member.'
        Assert-eMAST2Equal 0 @($result.CollectionCoverage | Where-Object { $_.CheckId -like 'SubmissionUnitXml*' }).Count 'Disabled capability created coverage.'
        $enabledOutput = Join-Path $resolvedOutputRoot 'enabled-cec.json'
        & (Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath $source -OutputPath $enabledOutput -ExecutionId 'SUXI-ENABLED' -IncludeSubmissionUnitXmlInventory -IncludeClassificationEvidenceCollection | Out-Null
        $enabled = [System.IO.File]::ReadAllText($enabledOutput) | ConvertFrom-Json
        Assert-eMAST2Equal 'RepositoryDiscovery,BackboneXmlInventory,SubmissionUnitXmlInventory,ClassificationEvidenceCollection' (@($enabled.Execution.Capabilities) -join ',') 'SUXI plus CEC invoked the optional deep-check chain.'
        $referenceOutput = Join-Path $resolvedOutputRoot 'enabled-reference-inventory.json'
        & (Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath $source -OutputPath $referenceOutput -ExecutionId 'SUXI-REFERENCE' -IncludeSubmissionUnitXmlInventory -IncludeReferenceInventory | Out-Null
        $reference = [System.IO.File]::ReadAllText($referenceOutput) | ConvertFrom-Json
        Assert-eMAST2Equal 'RepositoryDiscovery,BackboneXmlInventory,SubmissionUnitXmlInventory,ReferenceInventory' (@($reference.Execution.Capabilities) -join ',') 'Terminal ReferenceInventory execution lost or reordered SUXI.'
        Assert-eMAST2True ($null -ne $reference.PSObject.Properties['SubmissionUnitXmlDocuments']) 'Terminal ReferenceInventory output lost SUXI documents.'
        $deepOutput = Join-Path $resolvedOutputRoot 'enabled-deep-cec.json'
        & (Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath $source -OutputPath $deepOutput -ExecutionId 'SUXI-DEEP' -IncludeSubmissionUnitXmlInventory -IncludeReferenceInventory -IncludeClassificationEvidenceCollection | Out-Null
        $deep = [System.IO.File]::ReadAllText($deepOutput) | ConvertFrom-Json
        Assert-eMAST2Equal 'RepositoryDiscovery,BackboneXmlInventory,SubmissionUnitXmlInventory,ReferenceInventory,ReferenceResolution,MissingReferenceInterpretation,DeclaredChecksumComparison,ChecksumMismatchInterpretation,ClassificationEvidenceCollection' (@($deep.Execution.Capabilities) -join ',') 'Explicit deep-check execution lost or reordered SUXI.'
        Assert-eMAST2True ($null -ne $deep.PSObject.Properties['SubmissionUnitXmlDocuments']) 'Explicit deep-check execution lost SUXI documents.'
        Assert-eMAST2True (@($deep.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' }).Count -gt 0) 'Explicit deep-check execution lost T2 evidence.'
    }

    Invoke-eMAST2Check 'T-8 a second SUXI invocation fails with SUXI-INPUT-002' {
        $message = $null
        try { Invoke-eMASSubmissionUnitXmlInventory -SourcePath $eu.SourcePath -InputResult $eu.Suxi | Out-Null } catch { $message = $_.Exception.Message }
        Assert-eMAST2True ($message -like 'SUXI-INPUT-002*') 'Second invocation did not use SUXI-INPUT-002.'
    }

    Invoke-eMAST2Check 'T-9 external declarations are never resolved' {
        Assert-eMAST2True (@($eu.Suxi.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'ExternalReferenceNotResolved') 'schemaLocation diagnostic missing.'
        Assert-eMAST2Equal 'Parsed' $eu.Suxi.SubmissionUnitXmlDocuments[0].ParseStatus 'Safe parser did not parse without schema resolution.'
        $externalXml = [System.IO.File]::ReadAllText($fdaPath).Replace('?>', "?>`n<!DOCTYPE PORP_IN000001UV SYSTEM `"http://127.0.0.1:9/never.dtd`">")
        $externalPath = Join-Path $temporaryRoot 'external-doctype.xml'
        [System.IO.File]::WriteAllText($externalPath, $externalXml, (New-Object System.Text.UTF8Encoding($false)))
        $external = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $externalPath } -Name 'external-doctype')
        Assert-eMAST2Equal 'Parsed' $external.Suxi.SubmissionUnitXmlDocuments[0].ParseStatus 'External DTD caused a fetch or parse failure.'
        Assert-eMAST2True (@($external.Suxi.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'ExternalReferenceNotResolved') 'DOCTYPE diagnostic missing.'
        $malformed = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-079/submissionunit.xml') } -Name 'malformed')
        Assert-eMAST2Equal 'ParseFailed' $malformed.Suxi.SubmissionUnitXmlDocuments[0].ParseStatus 'Malformed XML parse state differs.'
        $wrong = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-080/submissionunit.xml') } -Name 'wrong-root')
        Assert-eMAST2Equal 'UnrecognizedRootElement' $wrong.Suxi.SubmissionUnitXmlDocuments[0].Structure.StructureStatus 'Wrong root was not rejected.'
        $wrongNamespaceXml = [System.IO.File]::ReadAllText($fdaPath).Replace('urn:hl7-org:v3', 'urn:example:wrong')
        $wrongNamespacePath = Join-Path $temporaryRoot 'wrong-namespace.xml'; [System.IO.File]::WriteAllText($wrongNamespacePath, $wrongNamespaceXml, (New-Object System.Text.UTF8Encoding($false)))
        $wrongNamespace = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $wrongNamespacePath } -Name 'wrong-namespace')
        Assert-eMAST2Equal 'UnrecognizedNamespace' $wrongNamespace.Suxi.SubmissionUnitXmlDocuments[0].Structure.StructureStatus 'Wrong namespace was not rejected.'
    }

    Invoke-eMAST2Check 'T-10 draft and unpublished EU markers keep source status without support claims' {
        Assert-eMAST2Equal 'Draft' $eu.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[1].SourceStatus 'EU draft status differs.'
        $unpublished = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-090/eu.xml') } -Name 'unpublished')
        Assert-eMAST2Equal 'RegisteredWithoutPublishedGuide' $unpublished.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[1].SourceStatus 'EU unpublished status differs.'
        Assert-eMAST2True ((ConvertTo-eMAST2StableJson $unpublished.Suxi.SubmissionUnitXmlDocuments) -notmatch 'Supported') 'Recognition was described as supported.'
        $fda18 = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-075/submissionunit.xml') } -Name 'fda18')
        Assert-eMAST2Equal 'RecognizedRegionalIg' $fda18.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[1].Recognition 'FDA 1.8 marker differs.'
        $historical = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-076/submissionunit.xml') } -Name 'historical')
        Assert-eMAST2Equal 'Historical' $historical.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[0].SourceStatus 'Historical ICH status differs.'
        Assert-eMAST2Equal 'Historical' $historical.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[1].SourceStatus 'Historical FDA status differs.'
        $unknown = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-077/submissionunit.xml') } -Name 'unknown-marker')
        Assert-eMAST2Equal 'UnrecognizedProfileMarker' $unknown.Suxi.SubmissionUnitXmlDocuments[0].ProfileStatus 'Unknown marker profile status differs.'
        $absent = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-078/submissionunit.xml') } -Name 'absent-marker')
        Assert-eMAST2Equal 'ProfileMarkersAbsent' $absent.Suxi.SubmissionUnitXmlDocuments[0].ProfileStatus 'Absent marker profile status differs.'
        $conflictingXml = [System.IO.File]::ReadAllText($fdaPath).Replace('</id></device></receiver>', '<item root="2.16.840.1.113883.3.989.5.1.1.6.1.2"/></id></device></receiver>')
        $conflictingPath = Join-Path $temporaryRoot 'conflicting-markers.xml'; [System.IO.File]::WriteAllText($conflictingPath, $conflictingXml, (New-Object System.Text.UTF8Encoding($false)))
        $conflicting = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $conflictingPath } -Name 'conflicting-markers')
        Assert-eMAST2Equal 'ConflictingProfileMarkers' $conflicting.Suxi.SubmissionUnitXmlDocuments[0].ProfileStatus 'Conflicting marker status differs.'
    }

    Invoke-eMAST2Check 'T-11 FDA .18.6 remains UnknownOid' {
        $xml = [System.IO.File]::ReadAllText($fdaPath).Replace('.18.9', '.18.6')
        $path = Join-Path $temporaryRoot 'unknown-18-6.xml'; [System.IO.File]::WriteAllText($path, $xml, (New-Object System.Text.UTF8Encoding($false)))
        $case = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $path } -Name 'unknown-18-6')
        Assert-eMAST2Equal 'UnknownOid' $case.Suxi.SubmissionUnitXmlDocuments[0].ProfileMarkers[1].Recognition 'FDA .18.6 was incorrectly recognized.'
    }

    Invoke-eMAST2Check 'T-12 depth-64 JSON round-trip preserves typed nested observations' {
        $roundTrip = ($fda.Suxi | ConvertTo-Json -Depth 64) | ConvertFrom-Json
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson $fda.Suxi.SubmissionUnitXmlDocuments) (ConvertTo-eMAST2StableJson $roundTrip.SubmissionUnitXmlDocuments) 'JSON round-trip changed inventory.'
        Assert-eMAST2Equal 1 @($roundTrip.SubmissionUnitXmlDocuments[0].SubmissionUnit.Code.Observations).Count 'Coded observations were lost.'
    }

    Invoke-eMAST2Check 'T-13 frozen Wave1E discovery stays unchanged and legacy stubs fail closed' {
        $stubPath = Join-Path $wave1ERoot 'fixtures/SD-053/fixture.zip'
        $stub = Invoke-eMAST2Chain -SourcePath $stubPath
        Assert-eMAST2Equal 'UnrecognizedRootElement' $stub.Suxi.SubmissionUnitXmlDocuments[0].Structure.StructureStatus 'Wave1E stub was interpreted.'
        $missingPath = Join-Path $wave1ERoot 'fixtures/SD-063/fixture.zip'
        $missing = Invoke-eMAST2Chain -SourcePath $missingPath
        Assert-eMAST2Equal 'Missing' $missing.Suxi.SubmissionUnitXmlDocuments[0].ParseStatus 'Frozen SD-063 was not confirmed absent.'
        $ambiguous = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-089/submissionunit.xml') } -Name 'ambiguous' -Ambiguous)
        Assert-eMAST2Equal 'AmbiguousRegulatoryUnitFolder' $ambiguous.Suxi.SubmissionUnitXmlDocuments[0].UnitFolderKind 'Ambiguous unit kind was lost.'
        Assert-eMAST2True (@($ambiguous.Suxi.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'AmbiguousUnitFolder') 'Ambiguous unit diagnostic missing.'
        Assert-eMAST2Equal 22 @(Import-Csv (Join-Path $wave1ERoot 'WAVE1E_FREEZE_MANIFEST.csv')).Count 'Wave1E manifest count changed.'
    }

    Invoke-eMAST2Check 'T-14 production change remains additive to frozen regressions' {
        Assert-eMAST2True ((Get-Item (Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1')).Length -gt 0) 'RD module unavailable.'
        Assert-eMAST2True ((Get-Item (Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1')).Length -gt 0) 'BXI module unavailable.'
        Assert-eMAST2True ((Get-Item (Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1')).Length -gt 0) 'T4 module unavailable.'
    }

    Invoke-eMAST2Check 'T-15 T1b fixture bytes remain frozen' {
        $t1bFixtures = @(Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'tests/fixtures/regional-xml-evidence') -File -Filter '*.xml')
        Assert-eMAST2Equal 11 $t1bFixtures.Count 'T1b focused fixture count changed.'
    }

    Invoke-eMAST2Check 'T-16 T4 inputs remain projection-v1 compatible' {
        foreach ($record in @($fda.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })) { Assert-eMAST2Null $record.XmlId 'T2 record would violate T4 XmlId validation.' }
        Assert-eMAST2Equal 0 @($fda.Cec.CollectionCoverage | Where-Object { $_.CheckId -eq 'ClassificationEvidenceCollection' -and $_.SubjectType -eq 'SubmissionUnitXml' }).Count 'T2 contaminated T4 coverage rows.'
    }

    Invoke-eMAST2Check 'T-17 T4 ignores T2 facts and preserves semantic identification' {
        Import-Module (Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1') -Force
        Import-Module (Join-Path $repositoryRoot 'engine/core/eMAS.RuntimeConfiguration.psm1') -Force
        $configPath = Join-Path $repositoryRoot 'tests/identification-interpretation/oracle/cases/IDO-01/runtime-config.json'
        $config = Import-eMASRuntimeConfiguration -Path $configPath
        $without = Invoke-eMASClassificationEvidenceCollection -InputResult $fda.Bxi
        $idWithout = Invoke-eMASIdentificationInterpretation -InputResult $without -RuntimeConfiguration $config
        $idWith = Invoke-eMASIdentificationInterpretation -InputResult $fda.Cec -RuntimeConfiguration $config
        Assert-eMAST2Equal (ConvertTo-eMAST2StableJson $idWithout.Results) (ConvertTo-eMAST2StableJson $idWith.Results) 'T2 facts changed T4 results.'
    }

    Invoke-eMAST2Check 'T-18 embedded vocabulary registry carries exact accepted source hashes' {
        $descriptor = Get-eMASEctd4VocabularyDescriptor
        Assert-eMAST2Equal '5f54a6786580d379f7324d0cfd7d70feaabf78409b67bbf7a4d3b270d434687f' $descriptor.SourceHashes.IchCvV7 'ICH source hash differs.'
        Assert-eMAST2Equal 'a5aaf5a43b1269ee2899f8e4f2e696d83d495053cac25e6f5ac08d34690d6624' $descriptor.SourceHashes.FdaCvV12 'FDA source hash differs.'
        Assert-eMAST2Equal 'f4e3ff1dff074e402ebffd78d90d283c4937b02ef5cfcaaa98cd8fcb028bc812' $descriptor.SourceHashes.EuCvV3 'EU source hash differs.'
    }

    Invoke-eMAST2Check 'T-19 grouped submissions use unique per-type ordinals and resolvable source paths' {
        $grouped = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-085/submissionunit.xml') } -Name 'grouped')
        $records = @($grouped.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -like 'Ectd4*' })
        $keys = @($records | ForEach-Object { '{0}|{1}|{2}' -f $_.SubmissionUnitXmlId, $_.EvidenceType, $_.SourceOrdinal })
        Assert-eMAST2Equal $keys.Count @($keys | Sort-Object -Unique).Count 'T2 evidence identity collided.'
        foreach ($type in @('Ectd4SubmissionTypeCode','Ectd4ApplicationTypeCode','Ectd4ApplicationIdNamespaceOid','Ectd4SequenceNumber')) {
            $typed = @($records | Where-Object { $_.EvidenceType -eq $type })
            Assert-eMAST2Equal '1,2' (($typed | ForEach-Object { $_.SourceOrdinal }) -join ',') ('Grouped ordinals differ for {0}.' -f $type)
        }
        Assert-eMAST2Equal 'S1/A1,S2/A1' ((@($records | Where-Object { $_.EvidenceType -eq 'Ectd4ApplicationTypeCode' }) | ForEach-Object { $_.SourcePath }) -join ',') 'Grouped application paths differ.'
        Assert-eMAST2Equal 'S1/A1/I1,S2/A1/I1' ((@($records | Where-Object { $_.EvidenceType -eq 'Ectd4ApplicationIdNamespaceOid' }) | ForEach-Object { $_.SourcePath }) -join ',') 'Grouped id-item paths differ.'
        $activity = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-086/sequence-1.xml'); '2' = (Get-eMAST2FixturePath 'fixtures/SD-086/sequence-2.xml') } -Name 'same-activity')
        Assert-eMAST2Equal 2 @($activity.Suxi.SubmissionUnitXmlDocuments).Count 'Two-unit activity was aggregated or lost.'
        Assert-eMAST2Equal $activity.Suxi.SubmissionUnitXmlDocuments[0].Submissions[0].IdItems[0].Root $activity.Suxi.SubmissionUnitXmlDocuments[1].Submissions[0].IdItems[0].Root 'Shared submission identity was not preserved per unit.'
    }

    Invoke-eMAST2Check 'T-20 duplicate coded values and sequence numbers remain lossless and emit no field record' {
        foreach ($name in @('different.xml','identical.xml')) {
            $case = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath ('fixtures/SD-082/{0}' -f $name)) } -Name ('duplicate-' + $name.Replace('.xml','')))
            $code = $case.Suxi.SubmissionUnitXmlDocuments[0].SubmissionUnit.Code
            Assert-eMAST2Equal 2 $code.Occurrences 'Duplicate code occurrence count differs.'
            Assert-eMAST2Equal 2 @($code.Observations).Count 'Duplicate observations were lost.'
            Assert-eMAST2Null $code.Code 'Duplicate parent Code must be null.'; Assert-eMAST2Null $code.CodeSystem 'Duplicate parent CodeSystem must be null.'
            Assert-eMAST2Equal 0 @($case.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'Ectd4SubmissionUnitTypeCode' }).Count 'Duplicate code emitted evidence.'
        }
        $sequenceCase = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-082/duplicate-sequence.xml') } -Name 'duplicate-sequence')
        Assert-eMAST2Equal 'MultipleValues' $sequenceCase.Suxi.SubmissionUnitXmlDocuments[0].Submissions[0].SequenceNumber.ValueStatus 'Duplicate sequence state differs.'
        Assert-eMAST2Equal 0 @($sequenceCase.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -eq 'Ectd4SequenceNumber' }).Count 'Duplicate sequence emitted evidence.'
        $missingFields = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-081/submissionunit.xml') } -Name 'missing-fields')
        Assert-eMAST2Equal 'Absent' $missingFields.Suxi.SubmissionUnitXmlDocuments[0].SubmissionUnit.Code.Recognition 'Missing unit code state differs.'
        Assert-eMAST2Equal 'Absent' $missingFields.Suxi.SubmissionUnitXmlDocuments[0].Submissions[0].SequenceNumber.ValueStatus 'Missing sequence state differs.'
        $unknownCode = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-083/submissionunit.xml') } -Name 'unknown-code')
        Assert-eMAST2Equal 'CodeOutsideCodeSystem' $unknownCode.Suxi.SubmissionUnitXmlDocuments[0].SubmissionUnit.Code.Recognition 'Unknown code state differs.'
        $wrongCodeSystem = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-084/submissionunit.xml') } -Name 'wrong-code-system')
        Assert-eMAST2Equal 'CodeSystemNotExpectedForElement' $wrongCodeSystem.Suxi.SubmissionUnitXmlDocuments[0].SubmissionUnit.Code.Recognition 'Unexpected code-system state differs.'
        $duplicateUnitXml = [System.IO.File]::ReadAllText($fdaPath)
        $unitStart = $duplicateUnitXml.IndexOf('<submissionUnit>')
        $unitEnd = $duplicateUnitXml.IndexOf('</submissionUnit>') + '</submissionUnit>'.Length
        $unitText = $duplicateUnitXml.Substring($unitStart, $unitEnd - $unitStart)
        $duplicateUnitXml = $duplicateUnitXml.Replace($unitText, ($unitText + $unitText))
        $duplicateUnitPath = Join-Path $temporaryRoot 'duplicate-unit.xml'; [System.IO.File]::WriteAllText($duplicateUnitPath, $duplicateUnitXml, (New-Object System.Text.UTF8Encoding($false)))
        $duplicateUnit = Invoke-eMAST2Chain -SourcePath (New-eMAST2Repository -XmlByFolder @{ '1' = $duplicateUnitPath } -Name 'duplicate-unit')
        Assert-eMAST2Equal 2 $duplicateUnit.Suxi.SubmissionUnitXmlDocuments[0].Structure.SubmissionUnitCount 'Duplicate submissionUnit count differs.'
        Assert-eMAST2Null $duplicateUnit.Suxi.SubmissionUnitXmlDocuments[0].SubmissionUnit 'Duplicate submissionUnit selected a winner.'
        Assert-eMAST2Equal 0 @($duplicateUnit.Cec.ClassificationEvidence | Where-Object { $_.EvidenceType -in @('Ectd4SubmissionUnitTypeCode','Ectd4SubmissionTypeCode','Ectd4ApplicationTypeCode','Ectd4ApplicationIdNamespaceOid','Ectd4SequenceNumber') }).Count 'Duplicate submissionUnit emitted nested evidence.'
        $duplicateFileZip = New-eMAST2Repository -XmlByFolder @{ '1' = $fdaPath } -Name 'duplicate-file' -AsZip
        $archive = [System.IO.Compression.ZipFile]::Open($duplicateFileZip, [System.IO.Compression.ZipArchiveMode]::Update)
        try {
            $entry = $archive.CreateEntry('1/SubmissionUnit.xml')
            $entryStream = $entry.Open()
            try {
                $writer = New-Object System.IO.StreamWriter($entryStream, (New-Object System.Text.UTF8Encoding($false)))
                try { $writer.Write([System.IO.File]::ReadAllText($fdaPath)); $writer.Flush() } finally { $writer.Dispose() }
            }
            finally { $entryStream.Dispose() }
        }
        finally { $archive.Dispose() }
        $duplicateFileRd = Invoke-eMASRepositoryDiscovery -SourcePath $duplicateFileZip -ExecutionId 'DUPLICATE-FILE' -ScenarioId 'MS-04' -Phase 'PreSales'
        $duplicateFileBxi = Invoke-eMASBackboneXmlInventory -SourcePath $duplicateFileZip -RepositoryDiscoveryResult $duplicateFileRd
        $listedMarker = @($duplicateFileBxi.Files | Where-Object { $_.RelativePath -ieq '1/submissionunit.xml' })[0]
        $secondMarker = ($listedMarker | ConvertTo-Json -Depth 16) | ConvertFrom-Json
        $secondMarker.FileId = 'FIL-DUPLICATE'
        $secondMarker.RelativePath = '1/SubmissionUnit.xml'
        $secondMarker.ContainerPath = '1/SubmissionUnit.xml'
        $duplicateFileBxi.Files = [object[]](@($duplicateFileBxi.Files) + $secondMarker)
        $duplicateFile = Invoke-eMASSubmissionUnitXmlInventory -SourcePath $duplicateFileZip -InputResult $duplicateFileBxi
        Assert-eMAST2True (@($duplicateFile.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'DuplicateSubmissionUnitFiles') 'Case-duplicate marker files were not rejected.'
    }

    Invoke-eMAST2Check 'T-21 confirmed absence, disappeared source, access denial and disabled capability stay distinct' {
        $missing = Invoke-eMAST2Chain -SourcePath (Join-Path $wave1ERoot 'fixtures/SD-063/fixture.zip')
        $missingDoc = $missing.Suxi.SubmissionUnitXmlDocuments[0]
        Assert-eMAST2Equal $false $missingDoc.Exists 'Confirmed absence Exists differs.'; Assert-eMAST2Equal 'Missing' $missingDoc.ParseStatus 'Confirmed absence parse state differs.'; Assert-eMAST2Equal 'InputUnavailable' $missingDoc.CaptureStatus 'Confirmed absence capture state differs.'
        Assert-eMAST2True (@($missingDoc.Diagnostics.ReasonCodes) -contains 'SubmissionUnitXmlConfirmedAbsent') 'Confirmed absence reason missing.'
        Assert-eMAST2Equal 0 @($missing.Suxi.CollectionCoverage | Where-Object { $_.CheckId -like 'SubmissionUnitXml*' -and $_.CollectionStatus -eq 'NotApplicable' }).Count 'Confirmed absence used NotApplicable.'

        $goneSource = New-eMAST2Repository -XmlByFolder @{ '1' = $euPath } -Name 'gone'
        $goneRd = Invoke-eMASRepositoryDiscovery -SourcePath $goneSource -ExecutionId 'GONE' -ScenarioId 'MS-04' -Phase 'PreSales'
        $goneBxi = Invoke-eMASBackboneXmlInventory -SourcePath $goneSource -RepositoryDiscoveryResult $goneRd
        [System.IO.File]::Delete((Join-Path $goneSource '1/submissionunit.xml'))
        $gone = Invoke-eMASSubmissionUnitXmlInventory -SourcePath $goneSource -InputResult $goneBxi
        Assert-eMAST2Equal $true $gone.SubmissionUnitXmlDocuments[0].Exists 'Disappeared source Exists differs.'; Assert-eMAST2Equal 'NotAttempted' $gone.SubmissionUnitXmlDocuments[0].ParseStatus 'Disappeared source parse state differs.'
        Assert-eMAST2True (@($gone.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'SourceXmlUnavailable') 'Disappeared source reason missing.'

        $deniedSource = New-eMAST2Repository -XmlByFolder @{ '1' = (Get-eMAST2FixturePath 'fixtures/SD-087/submissionunit.xml') } -Name 'denied'
        $deniedRd = Invoke-eMASRepositoryDiscovery -SourcePath $deniedSource -ExecutionId 'DENIED' -ScenarioId 'MS-04' -Phase 'PreSales'
        $deniedBxi = Invoke-eMASBackboneXmlInventory -SourcePath $deniedSource -RepositoryDiscoveryResult $deniedRd
        $deniedPath = Join-Path $deniedSource '1/submissionunit.xml'
        $isWindowsPlatform = ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT)
        if (-not $isWindowsPlatform) {
            & chmod 000 $deniedPath
            try {
                $denied = Invoke-eMASSubmissionUnitXmlInventory -SourcePath $deniedSource -InputResult $deniedBxi
                Assert-eMAST2Equal 'AccessDenied' $denied.SubmissionUnitXmlDocuments[0].CaptureStatus 'Access-denied capture state differs.'
                Assert-eMAST2True (@($denied.SubmissionUnitXmlDocuments[0].Diagnostics.ReasonCodes) -contains 'SourceXmlAccessDenied') 'Access-denied reason missing.'
            }
            finally { & chmod 600 $deniedPath }
        }
        else {
            $moduleText = [System.IO.File]::ReadAllText((Join-Path $repositoryRoot 'engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1'))
            Assert-eMAST2True ($moduleText.Contains('catch [System.UnauthorizedAccessException]')) 'Windows access-denied handling is absent.'
        }

        $disabled = $goneBxi
        Assert-eMAST2True (@($disabled.Execution.Capabilities) -notcontains 'SubmissionUnitXmlInventory') 'Disabled capability token present.'
    }

    foreach ($row in $manifestRows) {
        $path = Get-eMAST2FixturePath -RelativePath ([string]$row.RelativePath)
        Assert-eMAST2Equal $script:sourceState[[string]$row.RelativePath] (Get-eMAST2Sha256 -Path $path) ('Post-test fixture hash changed: {0}' -f $row.SampleId)
    }
    Write-Output ('[PASS] Post-test freeze gate verified {0} synthetic XML files unchanged.' -f $manifestRows.Count)
}
finally {
    if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
}

$summary = [pscustomobject][ordered]@{
    Suite = 'SubmissionUnitXmlInventory'; Runtime = $PSVersionTable.PSVersion.ToString(); Platform = [Environment]::OSVersion.Platform.ToString()
    Total = $script:passed + $script:failed; Passed = $script:passed; Failed = $script:failed; FixtureFiles = @($manifestRows).Count
}
[System.IO.File]::WriteAllText((Join-Path $resolvedOutputRoot 'submissionunit-xml-inventory-test-summary.json'), ($summary | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('SubmissionUnitXmlInventory tests completed: {0} total, {1} passed, {2} failed; summary={3}' -f $summary.Total, $summary.Passed, $summary.Failed, (Join-Path $resolvedOutputRoot 'submissionunit-xml-inventory-test-summary.json'))
if ($script:failed -gt 0) { throw ('SubmissionUnitXmlInventory tests failed: {0} check(s).' -f $script:failed) }
