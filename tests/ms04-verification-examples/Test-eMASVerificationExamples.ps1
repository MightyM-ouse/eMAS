#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputRoot)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=[System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$output=[System.IO.Path]::GetFullPath($OutputRoot)
if($output.Equals($repo,[System.StringComparison]::OrdinalIgnoreCase) -or $output.StartsWith($repo+'\',[System.StringComparison]::OrdinalIgnoreCase)){throw 'OutputRoot must be outside the repository.'}
if(Test-Path -LiteralPath $output){throw 'Use a fresh output directory.'}
[void][System.IO.Directory]::CreateDirectory($output)
$checks=New-Object System.Collections.ArrayList
function Assert {param([bool]$Condition,[string]$Message)if(-not $Condition){throw $Message}}
function Check {param([string]$Name,[scriptblock]$Action)try{& $Action;[void]$checks.Add([pscustomobject]@{Name=$Name;Status='PASS'});Write-Output ('[PASS] '+$Name)}catch{[void]$checks.Add([pscustomobject]@{Name=$Name;Status='FAIL';Detail=$_.Exception.Message});Write-Output ('[FAIL] '+$Name+': '+$_.Exception.Message)}}
$fixtureRoot=Join-Path $PSScriptRoot 'fixtures'
$initial=@(Get-ChildItem -LiteralPath $fixtureRoot -File -Recurse|ForEach-Object {[pscustomobject]@{Path=$_.FullName;Hash=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash;Written=$_.LastWriteTimeUtc}})
$runs=@{}
foreach($name in @('linked-delete','dangling-delete','escape','no-backbone')){
    $runs[$name]=& (Join-Path $repo 'scripts/eMAS-PreSalesAssessment.ps1') -SourcePath (Join-Path $fixtureRoot $name) -OutputPath (Join-Path $output ($name+'.json')) -ExecutionId ('EXEC-SYN-'+$name) -IncludeClassificationEvidenceCollection
}
function Historical-Count {
    param([string]$Case,[string]$Fragment)
    $folder=if($Case -eq 'linked-delete'){'Wrapper/InventedDossier'}else{'InventedDossier'}
    $settings=New-Object System.Xml.XmlReaderSettings;$settings.DtdProcessing=[System.Xml.DtdProcessing]::Ignore;$settings.XmlResolver=$null
    $reader=[System.Xml.XmlReader]::Create((Join-Path $fixtureRoot ($Case+'/'+$folder+'/0000/index.xml')),$settings)
    try{$doc=New-Object System.Xml.XmlDocument;$doc.XmlResolver=$null;$doc.Load($reader)}finally{$reader.Dispose()}
    return @($doc.SelectNodes("//*[local-name()='leaf' and @ID='$Fragment']")).Count
}
Check 'V-01 linked delete: independently unique target; product remains unassessed' {
    Assert ((Historical-Count 'linked-delete' 'SYN-HISTORICAL') -eq 1) 'Synthetic historical target is not unique'
    $r=@($runs['linked-delete'].References|Where-Object {$_.Operation -eq 'delete'})
    Assert ($r.Count -eq 1 -and $r[0].ModifiedFileRawPath -ceq '../0000/index.xml#SYN-HISTORICAL') 'Delete not collected'
    Assert ($r[0].ResolutionStatus -eq 'NotApplicable' -and $r[0].ResolutionDiagnosticCode -eq 'NoPhysicalHref') 'Physical behavior changed'
    Assert ($runs['linked-delete'].LifecycleRelationships.Count -eq 0) 'Unexpected lifecycle validation claim'
}
Check 'V-02 dangling delete: independent absence; currently no broken-link finding' {
    Assert ((Historical-Count 'dangling-delete' 'SYN-ABSENT') -eq 0) 'Synthetic fragment is unexpectedly present'
    $r=@($runs['dangling-delete'].References|Where-Object {$_.Operation -eq 'delete'})[0]
    Assert ($r.ResolutionDiagnosticCode -eq 'NoPhysicalHref') 'Current coverage behavior changed'
    Assert ($runs['dangling-delete'].LifecycleRelationships.Count -eq 0) 'Lifecycle validator falsely assumed'
    Assert (@($runs['dangling-delete'].Observations|Where-Object {$_.PSObject.Properties.Name -contains 'FindingCode'}).Count -eq 0) 'Expected coverage example produced a physical missing-file finding'
}
Check 'V-03 present sibling target remains unsafe and checksum unassessed' {
    Assert (Test-Path -LiteralPath (Join-Path $fixtureRoot 'escape/InventedB/0000/invented.txt')) 'Sibling fixture missing'
    $r=$runs['escape'].References[0]
    Assert ($r.ResolutionStatus -eq 'UnsafePath' -and $r.ResolutionDiagnosticCode -eq 'PathEscapesDossier') 'Boundary not protected'
    Assert ($r.ChecksumComparisonStatus -eq 'NotAssessed') 'Unsafe target incorrectly evaluated'
    Assert (@($runs['escape'].Observations|Where-Object {$_.Code -eq 'ReferenceTargetMissing'}).Count -eq 0) 'Unsafe path treated as missing'
}
Check 'V-04 wrapper preserves dossier and two physical sequences' {
    Assert ($runs['linked-delete'].DossierCandidates.Count -eq 1 -and $runs['linked-delete'].Sequences.Count -eq 2) 'Wrapper discovery differs'
}
Check 'V-05 no-backbone folder is an inventory candidate, not an invalidity finding' {
    Assert ($runs['no-backbone'].Sequences.Count -eq 1) 'Numeric candidate not recorded'
    Assert (@($runs['no-backbone'].XmlDocuments|Where-Object {$_.ParseStatus -eq 'Missing'}).Count -eq 2) 'Expected probes differ'
    Assert (@($runs['no-backbone'].Observations|Where-Object {$_.PSObject.Properties.Name -contains 'FindingCode'}).Count -eq 0) 'Regulatory invalidity was inferred'
}
Check 'V-06 all publishable fixture hashes/timestamps unchanged' {
    foreach($f in $initial){Assert ($f.Hash -eq (Get-FileHash -LiteralPath $f.Path -Algorithm SHA256).Hash -and $f.Written -eq (Get-Item -LiteralPath $f.Path).LastWriteTimeUtc) 'Fixture changed'}
}
$summary=[pscustomobject]@{Runtime=$PSVersionTable.PSVersion.ToString();Total=$checks.Count;Passed=@($checks|Where-Object {$_.Status -eq 'PASS'}).Count;Failed=@($checks|Where-Object {$_.Status -eq 'FAIL'}).Count;Skipped=0;FixtureFiles=$initial.Count;LifecycleValidation='Not implemented; examples demonstrate coverage limitation';Checks=@($checks)}
[System.IO.File]::WriteAllText((Join-Path $output 'verification-examples-summary.json'),($summary|ConvertTo-Json -Depth 16),(New-Object System.Text.UTF8Encoding($false)))
Write-Output ('Verification examples: {0} total, {1} passed, {2} failed, {3} skipped.' -f $summary.Total,$summary.Passed,$summary.Failed,$summary.Skipped)
if($summary.Failed -gt 0){exit 1}
