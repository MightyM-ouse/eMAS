#requires -Version 5.1

[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $OutputRoot)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputRoot)
if ($resolvedOutput.StartsWith($repositoryRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutput -eq $repositoryRoot) {
    throw 'Use an OutputRoot outside the repository and its fixtures.'
}
[void][System.IO.Directory]::CreateDirectory($resolvedOutput)
$sourceRoot = Join-Path $resolvedOutput ('sources-' + [guid]::NewGuid().ToString('N'))
$baselineRoot = Join-Path $resolvedOutput 'baseline'
$baseline = 'ef0dc9205ada01d8868f86c171a7fbd174c7756b'
$checks = New-Object System.Collections.ArrayList
$sources = New-Object System.Collections.ArrayList
$encoding = New-Object System.Text.UTF8Encoding($false)

function Assert-True { param([bool] $Value, [string] $Message) if (-not $Value) { throw $Message } }
function Assert-Equal { param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message) if ($Expected -cne $Actual) { throw ('{0}; expected={1}, actual={2}' -f $Message,$Expected,$Actual) } }
function Check {
    param([string] $Name, [scriptblock] $Action)
    try { & $Action; [void]$checks.Add([pscustomobject]@{ Name=$Name; Status='PASS'; Detail=$null }); Write-Output ('[PASS] ' + $Name) }
    catch { [void]$checks.Add([pscustomobject]@{ Name=$Name; Status='FAIL'; Detail=$_.Exception.Message }); Write-Output ('[FAIL] ' + $Name + ': ' + $_.Exception.Message) }
}
function Json { param([AllowNull()][object] $Value) return ConvertTo-Json -InputObject $Value -Depth 64 -Compress }
function Write-Synthetic {
    param([string] $Root, [string] $RelativePath, [string] $Content)
    $path = Join-Path $Root ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($path))
    [System.IO.File]::WriteAllText($path,$Content,$encoding)
    [void]$sources.Add([pscustomobject]@{ Path=$path; Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash; Written=(Get-Item -LiteralPath $path).LastWriteTimeUtc })
}
function New-Source {
    param([string] $Name, [hashtable] $Files, [string[]] $Folders=@())
    $root=Join-Path $sourceRoot $Name
    [void][System.IO.Directory]::CreateDirectory($root)
    foreach($folder in $Folders){[void][System.IO.Directory]::CreateDirectory((Join-Path $root $folder))}
    foreach($relative in $Files.Keys){Write-Synthetic $root $relative ([string]$Files[$relative])}
    return $root
}

# Independently specified recognition-only XML. These are not regulatory submissions.
$common='<ich:ectd xmlns:ich="http://www.ich.org/ectd" dtd-version="3.2"/>'
$eu='<eu:eu-backbone xmlns:eu="http://europa.eu.int" dtd-version="3.1"><eu-envelope><envelope country="de"><agency code="DE-BFARM"/><procedure type="national"/><submission type="maa"/><submission-unit type="initial"/></envelope></eu-envelope></eu:eu-backbone>'
$us='<?xml version="1.0"?><!DOCTYPE fda-regional:fda-regional SYSTEM "us-regional-v3-3.dtd"><fda-regional:fda-regional xmlns:fda-regional="http://www.ich.org/fda" xmlns:xlink="http://www.w3c.org/1999/xlink" dtd-version="3.3"><admin/><m1-regional/></fda-regional:fda-regional>'

# Extract only known baseline engine sources from Git, never sample data or fixtures.
foreach($relative in @('engine/powershell51/eMAS.BackboneXmlInventory.psm1','engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1','engine/powershell51/eMAS.ReferenceInventory.psm1','engine/powershell51/private/eMAS.SafeXml.ps1','engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1')) {
    $lines=@(& git -C $repositoryRoot show ($baseline + ':' + $relative))
    if($LASTEXITCODE -ne 0){throw 'Unable to read the validated baseline sources.'}
    $destination=Join-Path $baselineRoot $relative
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination))
    [System.IO.File]::WriteAllText($destination,($lines -join "`n")+"`n",$encoding)
}
$oldBxi=Import-Module (Join-Path $baselineRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1') -Force -PassThru
$oldCec=Import-Module (Join-Path $baselineRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1') -Force -PassThru
$oldRi=Import-Module (Join-Path $baselineRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1') -Force -PassThru
$rd=Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.RepositoryDiscovery.psm1') -Force -PassThru
$bxi=Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.BackboneXmlInventory.psm1') -Force -PassThru
$cec=Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1') -Force -PassThru
$ri=Import-Module (Join-Path $repositoryRoot 'engine/powershell51/eMAS.ReferenceInventory.psm1') -Force -PassThru
$idi=Import-Module (Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1') -Force -PassThru

function Chain {
    param([string] $Path, [switch] $Old)
    $discovery=& $rd {param($p) Invoke-eMASRepositoryDiscovery -SourcePath $p -ExecutionId 'EXEC-REGIONAL-TEST' -ScenarioId MS-04 -Phase PreSales} $Path
    $xm=if($Old){$oldBxi}else{$bxi}; $cm=if($Old){$oldCec}else{$cec}
    $inventory=& $xm {param($p,$d) Invoke-eMASBackboneXmlInventory -SourcePath $p -RepositoryDiscoveryResult $d} $Path $discovery
    $evidence=& $cm {param($i) Invoke-eMASClassificationEvidenceCollection -InputResult $i} $inventory
    return [pscustomobject]@{ Discovery=$discovery; Inventory=$inventory; Evidence=$evidence }
}
function Us-Document { param($Result) return @($Result.Inventory.XmlDocuments | Where-Object {$_.PSObject.Properties.Name -contains 'RegionalRecognition' -and $_.RegionalRecognition.PathProfileFamily -eq 'US_M1'}) }
function Evidence-For { param($Result,$Xml) return @($Result.Evidence.ClassificationEvidence | Where-Object {$_.XmlId -eq $Xml.XmlId}) }

$euWithReference=$eu.Replace('</eu:eu-backbone>','<leaf xmlns:xlink="http://www.w3c.org/1999/xlink" ID="eu-leaf" xlink:href="eu-document.pdf"/></eu:eu-backbone>')
$euPath=New-Source 'eu-only' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/eu/eu-regional.xml'=$euWithReference;'Dossier/0002/index.xml'=$common;'Dossier/0002/m1/eu/eu-regional.xml'=$euWithReference.Replace('3.1','2.0')}
$euResult=Chain $euPath
$euOld=Chain $euPath -Old
Check 'EU-only XML, observation and CEC identity match validated baseline' {
    $legacyXml=@($euResult.Inventory.XmlDocuments | Select-Object * -ExcludeProperty RegionalRecognition)
    Assert-Equal (Json @($euOld.Inventory.XmlDocuments)) (Json $legacyXml) 'Existing XML facts/IDs/order changed'
    Assert-Equal (Json @($euOld.Inventory.Observations)) (Json @($euResult.Inventory.Observations)) 'EU observations changed'
    Assert-Equal (Json @($euOld.Evidence.ClassificationEvidence)) (Json @($euResult.Evidence.ClassificationEvidence)) 'EU CEC records changed'
    Assert-Equal 0 @(Us-Document $euResult).Count 'EU-only created missing-US descriptors'
}
Check 'EU-only historical coverage and reference output remain unchanged' {
    $legacyCoverage=@($euResult.Evidence.CollectionCoverage | Where-Object {$_.CheckId -ne 'RegionalBackboneRecognition'})
    Assert-Equal (Json @($euOld.Evidence.CollectionCoverage)) (Json $legacyCoverage) 'EU legacy coverage changed'
    $newRefs=& $ri {param($p,$r) Invoke-eMASReferenceInventory -SourcePath $p -RepositoryDiscoveryResult $r.Discovery -BackboneXmlInventoryResult $r.Inventory} $euPath $euResult
    $oldRefs=& $oldRi {param($p,$r) Invoke-eMASReferenceInventory -SourcePath $p -RepositoryDiscoveryResult $r.Discovery -BackboneXmlInventoryResult $r.Inventory} $euPath $euOld
    Assert-Equal 2 $newRefs.References.Count 'EU leaf reference preservation was not exercised'
    Assert-Equal 'eu-document.pdf' $newRefs.References[0].RawHref 'EU XLink selector changed'
    Assert-Equal (Json @($oldRefs.References)) (Json @($newRefs.References)) 'Legacy EU references changed'
}
Check 'EU 3.0.1 recognized with accepted envelope support' {
    $path=New-Source 'eu301' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/eu/eu-regional.xml'=$eu.Replace('3.1','3.0.1')}
    $doc=@((Chain $path).Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'RegionalBackbone'})[0]
    Assert-Equal 'Matched' $doc.RegionalRecognition.RecognitionStatus 'EU family not recognized'
    Assert-Equal 'Supported' $doc.RegionalRecognition.ExtractionSupport 'Accepted EU profile not supported'
}

$usPath=New-Source 'us-only' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$us}
$usResult=Chain $usPath
$usDoc=@(Us-Document $usResult)[0]
Check 'US path and XML signature corroborate recognition and raw metadata' {
    Assert-Equal 'RegionalBackbone' $usDoc.XmlKind 'US physical role'
    Assert-Equal 'Matched' $usDoc.RegionalRecognition.RecognitionStatus 'US recognition'
    Assert-Equal 'US_M1' $usDoc.RegionalRecognition.XmlProfileFamily 'US XML family'
    Assert-Equal '3.3' $usDoc.DeclaredVersion 'FDA DTD version changed'
    Assert-Equal 'fda-regional:fda-regional' $usDoc.DocumentTypeName 'DTD QName changed'
    Assert-Equal 'us-regional-v3-3.dtd' $usDoc.SystemId 'DTD identifier changed'
    Assert-Equal '3.2' @($usResult.Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'CommonBackbone'})[0].DeclaredVersion 'Common version changed'
}
Check 'US never invokes EU envelope extraction or EU field coverage' {
    Assert-True ($null -eq $usDoc.RegionalEnvelope) 'US received an EU envelope object'
    Assert-Equal 'NotImplemented' $usDoc.RegionalRecognition.ExtractionSupport 'US envelope support claimed'
    Assert-Equal 0 @((Evidence-For $usResult $usDoc) | Where-Object {$_.EvidenceType -like 'Eu*'}).Count 'US generated EU fields'
    Assert-Equal 0 @($usResult.Evidence.CollectionCoverage | Where-Object {$_.SubjectId -eq $usDoc.XmlId -and $_.CheckId -like 'RegionalEnvelopeField:EU_*'}).Count 'US checked EU fields'
}
Check 'US CEC has exactly seven generic types with null interpretation and traceability' {
    $facts=@(Evidence-For $usResult $usDoc)
    $types=@('RegionalBackbonePresence','RegionalBackbonePath','XmlRootElement','XmlNamespace','DtdVersion','DocumentTypeName','DtdSystemIdentifier')
    Assert-Equal 7 $facts.Count 'Unexpected US evidence count'
    foreach($type in $types){Assert-Equal 1 @($facts | Where-Object {$_.EvidenceType -eq $type}).Count ('Missing type '+$type)}
    foreach($fact in $facts){
        Assert-True ($null -eq $fact.CandidateValue -and $null -eq $fact.Polarity -and $null -eq $fact.SourceRuleId) 'US fact contains interpretation'
        Assert-Equal $usDoc.SequenceId $fact.SequenceId 'Lost sequence trace'
        Assert-Equal $usDoc.DossierId $fact.DossierId 'Lost dossier trace'
        Assert-Equal $usDoc.RelativePath $fact.RelativePath 'Lost path trace'
        Assert-Equal 'BackboneXmlInventory' $fact.SourceCapability 'Lost capability trace'
        Assert-True ($fact.PSObject.Properties.Name -notcontains 'SourceOrdinal') 'Generic fact gained envelope ordinal'
    }
}
Check 'Legacy missing EU is retained as an observation without a regulatory finding' {
    $missing=@($usResult.Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'RegionalBackbone' -and -not $_.Exists})
    Assert-Equal 1 $missing.Count 'Legacy EU probe missing'
    Assert-Equal 'EU_M1' $missing[0].RegionalRecognition.PathProfileFamily 'Incorrect absent profile'
    Assert-Equal 1 @($usResult.Inventory.Observations | Where-Object {$_.Code -eq 'MissingRegionalBackbone'}).Count 'Legacy observation missing'
    Assert-Equal 0 @($usResult.Evidence.Observations | Where-Object {$_.PSObject.Properties.Name -contains 'FindingCode'}).Count 'Absent EU became a finding'
}
Check 'US-only T4 scalar remains available with the missing-EU probe' {
    $s=[pscustomobject]@{SubjectId=$usDoc.SequenceId;DossierId=$usDoc.DossierId}
    $state=& $idi {param($s,$r) Get-eMASIdentificationFieldState -FieldCode CEC_XML_NAMESPACE_REGIONAL -Subject $s -Evidence @($r.ClassificationEvidence) -XmlDocuments @($r.XmlDocuments) -Coverage @($r.CollectionCoverage)} $s $usResult.Evidence
    Assert-Equal 'Available' $state.State 'US scalar unavailable'
    Assert-Equal 'http://www.ich.org/fda' $state.Value 'Namespace scalar altered'
}

$mixedPath=New-Source 'mixed' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/eu/eu-regional.xml'=$eu;'Dossier/0001/m1/us/us-regional.xml'=$us}
$mixed=Chain $mixedPath
Check 'Mixed EU and US facts remain distinct and T4 fails closed with AmbiguousProjection' {
    Assert-Equal 2 @($mixed.Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'RegionalBackbone' -and $_.Exists}).Count 'Mixed backbone count'
    $s=[pscustomobject]@{SubjectId=$mixed.Inventory.Sequences[0].SequenceId;DossierId=$mixed.Inventory.Sequences[0].DossierId}
    $state=& $idi {param($s,$r) Get-eMASIdentificationFieldState -FieldCode CEC_XML_NAMESPACE_REGIONAL -Subject $s -Evidence @($r.ClassificationEvidence) -XmlDocuments @($r.XmlDocuments) -Coverage @($r.CollectionCoverage)} $s $mixed.Evidence
    Assert-Equal 'Unavailable' $state.State 'Mixed values were merged'
    Assert-Equal 'AmbiguousProjection' $state.Unavailable[0].Reason 'Mixed ambiguity hidden'
}
Check 'New US CEC facts append after historical EU evidence without shifting IDs' {
    $old=Chain $mixedPath -Old
    $usIds=@(Us-Document $mixed | ForEach-Object {$_.XmlId})
    $legacy=@($mixed.Evidence.ClassificationEvidence | Where-Object {$usIds -notcontains $_.XmlId})
    Assert-Equal (Json @($old.Evidence.ClassificationEvidence)) (Json $legacy) 'Historical mixed-input evidence changed'
    Assert-Equal 7 ($mixed.Evidence.ClassificationEvidence.Count-$legacy.Count) 'US addition count'
    Assert-Equal $usIds[0] $mixed.Evidence.ClassificationEvidence[-1].XmlId 'US facts were not appended'
}
Check 'Detected US folder adds one missing-US descriptor and documents XML ordinal drift' {
    $path=New-Source 'missing-us' @{'Dossier/0001/index.xml'=$common;'Dossier/0002/index.xml'=$common} @('Dossier/0001/m1/us')
    $r=Chain $path; $old=Chain $path -Old; $doc=@(Us-Document $r)[0]
    Assert-True (-not $doc.Exists) 'Missing US exists'
    Assert-Equal 'Missing' $doc.ParseStatus 'Missing US parse state'
    Assert-Equal 'NotAttempted' $doc.RegionalRecognition.RecognitionStatus 'Missing XML recognized'
    Assert-Equal 3 @($r.Inventory.Observations | Where-Object {$_.Code -eq 'MissingRegionalBackbone'}).Count 'Missing observation count'
    Assert-Equal 'XML-0003' @($old.Inventory.XmlDocuments | Where-Object {$_.RelativePath -eq 'Dossier/0002/index.xml'})[0].XmlId 'Baseline ordinal'
    Assert-Equal 'XML-0004' @($r.Inventory.XmlDocuments | Where-Object {$_.RelativePath -eq 'Dossier/0002/index.xml'})[0].XmlId 'New ordinal drift'
    $falseFact=@((Evidence-For $r $doc) | Where-Object {$_.EvidenceType -eq 'RegionalBackbonePresence'})[0]
    Assert-Equal $false $falseFact.ObservedValue 'US absence not factual'
    Assert-Equal (Json @($old.Evidence.ClassificationEvidence | Select-Object EvidenceId,EvidenceType,ObservedValue)) (Json @($r.Evidence.ClassificationEvidence | Where-Object {$_.XmlId -ne $doc.XmlId} | Select-Object EvidenceId,EvidenceType,ObservedValue)) 'Legacy EVD order shifted'
}
Check 'No regional folder does not fan out missing US observations' {
    $path=New-Source 'no-region' @{'Dossier/0001/index.xml'=$common}
    $r=Chain $path
    Assert-Equal 0 @(Us-Document $r).Count 'US absence invented without a folder'
    Assert-Equal 2 $r.Inventory.XmlDocuments.Count 'Unexpected missing country probes'
}
Check 'Malformed US preserves physical presence and parse failure without EU objects' {
    $path=New-Source 'malformed-us' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'='<broken>'}
    $r=Chain $path; $doc=@(Us-Document $r)[0]
    Assert-True $doc.Exists 'Malformed file presence lost'
    Assert-Equal 'ParseFailed' $doc.ParseStatus 'Malformed file parsed'
    Assert-True ($null -eq $doc.RegionalEnvelope) 'Malformed US got EU error envelope'
    Assert-Equal 2 @(Evidence-For $r $doc).Count 'Malformed XML emitted structured facts'
}
Check 'Malformed EU extraction and coverage retain legacy behavior' {
    $path=New-Source 'malformed-eu' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/eu/eu-regional.xml'='<broken>'}
    $r=Chain $path; $old=Chain $path -Old
    Assert-Equal (Json @($old.Evidence.ClassificationEvidence)) (Json @($r.Evidence.ClassificationEvidence)) 'Malformed EU evidence changed'
    $doc=@($r.Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'RegionalBackbone'})[0]
    Assert-Equal 'NotAttempted' $doc.RegionalEnvelope.ProfileStatus 'EU failure envelope changed'
}
Check 'Unsupported EU version is retained without supported envelope claims' {
    $path=New-Source 'unsupported-eu' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/eu/eu-regional.xml'=$eu.Replace('3.1','99.0')}
    $r=Chain $path; $doc=@($r.Inventory.XmlDocuments | Where-Object {$_.XmlKind -eq 'RegionalBackbone'})[0]
    Assert-Equal 'Matched' $doc.RegionalRecognition.RecognitionStatus 'Root family lost'
    Assert-Equal 'UnsupportedProfile' $doc.RegionalRecognition.ExtractionSupport 'Unknown EU version supported'
    Assert-Equal '99.0' $doc.DeclaredVersion 'Unsupported declaration altered'
}
Check 'Unknown US version preserves raw facts but skips unsupported reference semantics' {
    $path=New-Source 'unsupported-us' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$us.Replace('3.3','99.0')}
    $r=Chain $path; $doc=@(Us-Document $r)[0]
    Assert-Equal '99.0' $doc.DeclaredVersion 'US version guessed'
    Assert-Equal 'NotImplemented' $doc.RegionalRecognition.ExtractionSupport 'Unknown US envelope supported'
    $refs=& $ri {param($p,$r) Invoke-eMASReferenceInventory -SourcePath $p -RepositoryDiscoveryResult $r.Discovery -BackboneXmlInventoryResult $r.Inventory} $path $r
    Assert-Equal 'UnsupportedRegionalReferenceProfile' @($refs.CollectionCoverage | Where-Object {$_.CheckId -eq 'ReferenceInventory' -and $_.SubjectId -eq $doc.XmlId})[0].ReasonCode 'Unsupported US reference profile not reported'
}
Check 'US path with EU signature is a mismatch, not a matched implementation' {
    $path=New-Source 'mismatch' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$eu}
    $r=Chain $path; $doc=@(Us-Document $r)[0]
    Assert-Equal 'PathXmlMismatch' $doc.RegionalRecognition.RecognitionStatus 'Mismatched root accepted'
    Assert-Equal 'EU_M1' $doc.RegionalRecognition.XmlProfileFamily 'XML family not retained'
    Assert-True ($null -eq $doc.RegionalEnvelope) 'US path invoked EU extraction'
}
Check 'Root local-name alone or namespace alone cannot establish recognition' {
    foreach($bad in @($us.Replace('http://www.ich.org/fda','urn:unknown'),$us.Replace('fda-regional:fda-regional','fda-regional:other'))){
        $path=New-Source ('unrecognized-'+[guid]::NewGuid().ToString('N')) @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$bad}
        Assert-Equal 'UnrecognizedStructure' @(Us-Document (Chain $path))[0].RegionalRecognition.RecognitionStatus 'Incomplete signature matched'
    }
}
Check 'Unknown regional path stays Other with explicit unsupported coverage' {
    $path=New-Source 'unknown-region' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/xx/xx-regional.xml'='<unknown/>'}
    $r=Chain $path; $doc=@($r.Inventory.XmlDocuments | Where-Object {$_.RelativePath -like '*xx-regional.xml'})[0]
    Assert-Equal 'Other' $doc.XmlKind 'Unsupported region promoted'
    Assert-Equal 'UnsupportedPath' $doc.RegionalRecognition.RecognitionStatus 'Unsupported path hidden'
    Assert-Equal 'UnsupportedPath' @($r.Inventory.CollectionCoverage | Where-Object {$_.CheckId -eq 'RegionalBackboneRecognition' -and $_.SubjectId -eq $doc.XmlId})[0].ReasonCode 'Missing unsupported coverage'
}
Check 'Familiar basename and FDA signature outside canonical path stay Other' {
    $path=New-Source 'decoy' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/notes/us-regional.xml'=$us}
    $r=Chain $path; $doc=@($r.Inventory.XmlDocuments | Where-Object {$_.RelativePath -like '*us-regional.xml'})[0]
    Assert-Equal 'Other' $doc.XmlKind 'Filename-only classification'
    Assert-Equal 0 @(Evidence-For $r $doc).Count 'Noncanonical file generated supported evidence'
}
Check 'Namespace prefix variation and Windows path casing preserve actual source paths' {
    $alternate=$us.Replace('fda-regional:','f:').Replace('xmlns:fda-regional=','xmlns:f=')
    $path=New-Source 'case-prefix' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/M1/US/US-REGIONAL.XML'=$alternate}
    $r=Chain $path; $doc=@(Us-Document $r)[0]
    Assert-Equal 'Matched' $doc.RegionalRecognition.RecognitionStatus 'Prefix/case not supported'
    Assert-Equal 'Dossier/0001/M1/US/US-REGIONAL.XML' $doc.RelativePath 'Actual source path altered'
}
Check 'Multiple sequences and dossiers retain independent profile/version traces' {
    $path=New-Source 'multiple' @{'A/0001/index.xml'=$common;'A/0001/m1/us/us-regional.xml'=$us;'A/0002/index.xml'=$common;'A/0002/m1/us/us-regional.xml'=$us.Replace('3.3','9.9');'B/0001/index.xml'=$common;'B/0001/m1/eu/eu-regional.xml'=$eu}
    $r=Chain $path; $docs=@(Us-Document $r)
    Assert-Equal 2 $docs.Count 'US sequence count'
    Assert-Equal 2 $r.Inventory.DossierCandidates.Count 'Dossier count'
    Assert-Equal '3.3' $docs[0].DeclaredVersion 'First version changed'
    Assert-Equal '9.9' $docs[1].DeclaredVersion 'Second version guessed'
    foreach($doc in $docs){foreach($fact in @(Evidence-For $r $doc)){Assert-Equal $doc.DossierId $fact.DossierId 'Cross-dossier leakage'; Assert-Equal $doc.SequenceId $fact.SequenceId 'Cross-sequence leakage'}}
}
Check 'Duplicate US discovery paths fail closed without parsing an arbitrary file' {
    $d=($usResult.Discovery | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $duplicate=($d.Files | Where-Object {$_.RelativePath -like '*us-regional.xml'} | ConvertTo-Json -Depth 16) | ConvertFrom-Json
    $duplicate.FileId='FIL-DUPLICATE'; $d.Files=@($d.Files)+@($duplicate)
    $inventory=& $bxi {param($p,$d) Invoke-eMASBackboneXmlInventory -SourcePath $p -RepositoryDiscoveryResult $d} $usPath $d
    $doc=@($inventory.XmlDocuments | Where-Object {$_.RelativePath -like '*us-regional.xml'})[0]
    Assert-Equal 'NotAttempted' $doc.ParseStatus 'Duplicate file was parsed'
    Assert-Equal 'AmbiguousPath' $doc.RegionalRecognition.RecognitionStatus 'Duplicate ambiguity hidden'
}
Check 'Disappeared US source remains unavailable rather than confirmed absent' {
    $d=($usResult.Discovery | ConvertTo-Json -Depth 64) | ConvertFrom-Json
    $empty=New-Source 'disappeared' @{}
    $inventory=& $bxi {param($p,$d) Invoke-eMASBackboneXmlInventory -SourcePath $p -RepositoryDiscoveryResult $d} $empty $d
    $doc=@($inventory.XmlDocuments | Where-Object {$_.RelativePath -like '*us-regional.xml'})[0]
    Assert-True $doc.Exists 'Discovery presence erased'
    Assert-Equal 'InputUnavailable' $doc.CaptureStatus 'Disappeared source not unavailable'
    Assert-Equal 'NotAttempted' $doc.ParseStatus 'Disappeared source marked missing'
}
Check 'CEC remains source-independent and deterministic for reordered XML/files' {
    $inputCopy=($mixed.Inventory | ConvertTo-Json -Depth 64)|ConvertFrom-Json
    [array]::Reverse($inputCopy.XmlDocuments); [array]::Reverse($inputCopy.Files)
    $r=& $cec {param($r) Invoke-eMASClassificationEvidenceCollection -InputResult $r} $inputCopy
    Assert-Equal (Json @($mixed.Evidence.ClassificationEvidence)) (Json @($r.ClassificationEvidence)) 'CEC ordering changed'
    $legacyCopy=($euResult.Inventory | ConvertTo-Json -Depth 64)|ConvertFrom-Json
    foreach($doc in $legacyCopy.XmlDocuments){$doc.PSObject.Properties.Remove('RegionalRecognition')}
    $r=& $cec {param($r) Invoke-eMASClassificationEvidenceCollection -InputResult $r} $legacyCopy
    Assert-Equal (Json @($euResult.Evidence.ClassificationEvidence)) (Json @($r.ClassificationEvidence)) 'Legacy optional-property fallback changed'
}
Check 'Directory and ZIP input produce equivalent recognition and evidence' {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=Join-Path $resolvedOutput 'us-only.zip'
    if([System.IO.File]::Exists($zip)){throw 'Use a fresh output directory for this harness.'}
    [System.IO.Compression.ZipFile]::CreateFromDirectory($usPath,$zip)
    $r=Chain $zip
    Assert-Equal (Json @($usResult.Evidence.ClassificationEvidence)) (Json @($r.Evidence.ClassificationEvidence)) 'ZIP evidence differs'
    Assert-Equal 'Matched' @(Us-Document $r)[0].RegionalRecognition.RecognitionStatus 'ZIP recognition failed'
}
Check 'US optional deep chain preserves actual missing-reference and checksum outcomes' {
    $content='synthetic leaf bytes'
    $md5=[System.Security.Cryptography.MD5]::Create()
    try{$checksum=($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))|ForEach-Object {$_.ToString('x2')}) -join ''}finally{$md5.Dispose()}
    $leaves='<leaf ID="present" xlink:href="present.txt" checksum-type="md5" checksum="'+$checksum+'"/><leaf ID="missing" xlink:href="missing.txt"/>'
    $path=New-Source 'deep' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$us.Replace('<m1-regional/>','<m1-regional>'+$leaves+'</m1-regional>');'Dossier/0001/m1/us/present.txt'=$content}
    $output=Join-Path $resolvedOutput 'deep-scan.json'
    $r=& (Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath $path -OutputPath $output -ExecutionId EXEC-DEEP -IncludeClassificationEvidenceCollection
    Assert-Equal 2 $r.References.Count 'US leaves not inventoried'
    Assert-Equal 1 @($r.References | Where-Object {$_.ResolutionStatus -eq 'ResolvedAbsent'}).Count 'Missing target not resolved'
    Assert-Equal 1 @($r.Observations | Where-Object {$_.PSObject.Properties.Name -contains 'FindingCode' -and $_.FindingCode -eq 'MissingReference'}).Count 'Actual missing target finding absent'
    Assert-Equal 'Matched' @($r.References | Where-Object {$_.SourceElementId -eq 'present'})[0].ChecksumComparisonStatus 'Correct MD5 was not compared'
    Assert-Equal $true @($r.References | Where-Object {$_.SourceElementId -eq 'present'})[0].ChecksumMatch 'Correct MD5 became mismatch'
    Assert-Equal 7 @($r.ClassificationEvidence | Where-Object {$_.RelativePath -like '*us-regional.xml'}).Count 'US evidence lost in deep chain'
}
Check 'Unknown US structure cannot generate optional leaf references' {
    $bad='<unrelated><leaf xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="bogus.txt"/></unrelated>'
    $path=New-Source 'unsupported-reference' @{'Dossier/0001/index.xml'=$common;'Dossier/0001/m1/us/us-regional.xml'=$bad}
    $r=Chain $path
    $refs=& $ri {param($p,$r) Invoke-eMASReferenceInventory -SourcePath $p -RepositoryDiscoveryResult $r.Discovery -BackboneXmlInventoryResult $r.Inventory} $path $r
    Assert-Equal 0 $refs.References.Count 'Unexpected root produced references'
}
Check 'Synthetic source hashes and timestamps remain unchanged' {
    foreach($source in $sources){Assert-Equal $source.Sha256 (Get-FileHash -LiteralPath $source.Path -Algorithm SHA256).Hash 'Source content modified'; Assert-Equal $source.Written (Get-Item -LiteralPath $source.Path).LastWriteTimeUtc 'Source timestamp modified'}
}

$summary=[pscustomobject][ordered]@{
    Baseline=$baseline; PowerShellVersion=$PSVersionTable.PSVersion.ToString(); PSEdition=$PSVersionTable.PSEdition
    Total=$checks.Count; Passed=@($checks|Where-Object {$_.Status -eq 'PASS'}).Count; Failed=@($checks|Where-Object {$_.Status -eq 'FAIL'}).Count; Skipped=0
    SyntheticSourcesVerified=$sources.Count; Checks=@($checks)
}
[System.IO.File]::WriteAllText((Join-Path $resolvedOutput 'regional-backbone-recognition-test-summary.json'),($summary|ConvertTo-Json -Depth 16),$encoding)
Write-Output ('Regional backbone recognition tests completed: {0} total, {1} passed, {2} failed, {3} skipped.' -f $summary.Total,$summary.Passed,$summary.Failed,$summary.Skipped)
if($summary.Failed -gt 0){exit 1}
