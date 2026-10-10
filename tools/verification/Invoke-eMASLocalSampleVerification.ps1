#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string] $SourceRoot,
    [Parameter(Mandatory=$true)][string] $OutputRoot,
    [int] $ExpectedInputCount = 0,
    [string] $VerificationDate = [DateTime]::Now.ToString('yyyy-MM-dd')
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=[System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$source=(Get-Item -LiteralPath $SourceRoot).FullName
$output=[System.IO.Path]::GetFullPath($OutputRoot)
foreach($protected in @($repo,$source)) {
    if($output.Equals($protected,[System.StringComparison]::OrdinalIgnoreCase) -or $output.StartsWith($protected.TrimEnd('\')+'\',[System.StringComparison]::OrdinalIgnoreCase)) {throw 'Output must be outside the repository and source.'}
}
if(Test-Path -LiteralPath $output){throw 'Use a new output directory.'}
[void][System.IO.Directory]::CreateDirectory($output)
$encoding=New-Object System.Text.UTF8Encoding($false)
function Write-Json {param($Path,$Value) [System.IO.File]::WriteAllText($Path,(ConvertTo-Json -InputObject $Value -Depth 64),$encoding)}
function Counts {param($Items,[string]$Property) $result=[ordered]@{}; foreach($g in @($Items|Group-Object -Property $Property|Sort-Object Name)){$result[[string]$g.Name]=$g.Count}; return [pscustomobject]$result}
$inputs=@(Get-ChildItem -LiteralPath $source -Force | Where-Object {$_.PSIsContainer -or $_.Extension -ieq '.zip'})
if(@($inputs|Where-Object {-not $_.PSIsContainer}).Count -gt 0){throw 'This local audit utility requires directory inputs; use the accepted ZIP harness for archives.'}
if($ExpectedInputCount -gt 0 -and $inputs.Count -ne $ExpectedInputCount){throw 'Input count differs from requested verification scope.'}
$byName=@{}; foreach($item in $inputs){$byName[$item.Name]=$item}
$names=[string[]]@($byName.Keys); [array]::Sort($names,[System.StringComparer]::OrdinalIgnoreCase)
$mapping=New-Object System.Collections.ArrayList
$rows=New-Object System.Collections.ArrayList
$manifest=New-Object System.Collections.ArrayList
$ordinal=0
foreach($name in $names){
    $ordinal++; $id='S{0:D2}' -f $ordinal; $item=$byName[$name]
    [void]$mapping.Add([pscustomobject]@{SampleId=$id;Name=$item.Name;SourcePath=$item.FullName;PublicationPermission='Not established; local only'})
    $files=if($item.PSIsContainer){@(Get-ChildItem -LiteralPath $item.FullName -File -Recurse -Force)}else{@($item)}
    foreach($file in $files){[void]$manifest.Add([pscustomobject]@{SampleId=$id;Path=$file.FullName;Sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash;Length=$file.Length;Written=$file.LastWriteTimeUtc})}
    $physicalXml=@($files|Where-Object {$_.Extension -ieq '.xml'})
    $runs=@{}
    foreach($mode in @('historical','with-suxi')){
        $dir=Join-Path $output $mode; [void][System.IO.Directory]::CreateDirectory($dir)
        $parameters=@{SourcePath=$item.FullName;OutputPath=(Join-Path $dir ($id+'.json'));ExecutionId=('EXEC-LOCAL-'+$id+'-'+$mode);IncludeClassificationEvidenceCollection=$true}
        if($mode -eq 'with-suxi'){$parameters.IncludeSubmissionUnitXmlInventory=$true; $parameters.IncludeReferenceInventory=$true; $parameters.IncludeReferenceResolution=$true; $parameters.IncludeMissingReferenceInterpretation=$true; $parameters.IncludeDeclaredChecksumComparison=$true; $parameters.IncludeChecksumMismatchInterpretation=$true}
        try{$scan=& (Join-Path $repo 'scripts/eMAS-PreSalesAssessment.ps1') @parameters; $runs[$mode]=$scan}
        catch{Write-Json (Join-Path $dir ($id+'-failure.json')) ([pscustomobject]@{SampleId=$id;Error=$_.Exception.Message}); $runs[$mode]=$null}
    }
    $old=$runs['historical']; $scan=$runs['with-suxi']
    if($null -eq $scan){[void]$rows.Add([pscustomobject]@{SampleId=$id;ExecutionStatus='Failed'}); Write-Output ($id+' failed'); continue}
    $su=@(); if($scan.PSObject.Properties.Name -contains 'SubmissionUnitXmlDocuments'){$su=@($scan.SubmissionUnitXmlDocuments)}
    $recognition=@($scan.XmlDocuments|Where-Object {$_.PSObject.Properties.Name -contains 'RegionalRecognition'})
    $gaps=@($scan.CollectionCoverage|Where-Object {$_.CaptureStatus -ne 'Available' -or ($_.PSObject.Properties.Name -contains 'CollectionStatus' -and $_.CollectionStatus -ne 'Collected')})
    $findingRows=@($scan.Observations|Where-Object {$_.PSObject.Properties.Name -contains 'FindingCode'})
    $physicalChecks=New-Object System.Collections.ArrayList
    foreach($xml in @($scan.XmlDocuments)+$su){
        $path=Join-Path $item.FullName ([string]$xml.RelativePath -replace '/','\')
        [void]$physicalChecks.Add([pscustomobject]@{RelativePath=$xml.RelativePath;ReportedExists=$xml.Exists;ActualExists=[System.IO.File]::Exists($path);ParseStatus=$xml.ParseStatus;CaptureStatus=$xml.CaptureStatus})
    }
    Write-Json (Join-Path $output ($id+'-physical-checks.json')) @($physicalChecks)
    $row=[pscustomobject][ordered]@{
        SampleId=$id; InputType=$(if($item.PSIsContainer){'Directory'}else{'Zip'}); PhysicalFiles=$files.Count; PhysicalXml=$physicalXml.Count
        SubmissionUnitFiles=@($physicalXml|Where-Object {$_.Name -ieq 'submissionunit.xml'}).Count
        CommonIndexFiles=@($physicalXml|Where-Object {$_.Name -ieq 'index.xml'}).Count
        Dossiers=@($scan.DossierCandidates).Count; Sequences=@($scan.Sequences).Count; SequenceKinds=(Counts $scan.Sequences 'SequenceLikeKind')
        Xml=@($scan.XmlDocuments).Count; XmlParse=(Counts $scan.XmlDocuments 'ParseStatus'); XmlKinds=(Counts $scan.XmlDocuments 'XmlKind')
        RegionalRecognition=(Counts @($recognition|ForEach-Object {$_.RegionalRecognition}) 'RecognitionStatus'); RegionalFamilies=(Counts @($recognition|Where-Object {$_.RegionalRecognition.RecognitionStatus -eq 'Matched'}|ForEach-Object {$_.RegionalRecognition}) 'XmlProfileFamily')
        SubmissionUnits=$su.Count; SuParse=(Counts $su 'ParseStatus'); SuProfiles=(Counts $su 'ProfileStatus'); SuStructure=(Counts @($su|ForEach-Object {$_.Structure}) 'StructureStatus')
        Evidence=@($scan.ClassificationEvidence).Count; EvidenceTypes=(Counts $scan.ClassificationEvidence 'EvidenceType')
        References=@($scan.References).Count; Resolution=(Counts $scan.References 'ResolutionStatus'); Checksums=(Counts $scan.References 'ChecksumComparisonStatus')
        Operations=(Counts $scan.References 'Operation'); ModifiedFileRelationships=@($scan.References|Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_.ModifiedFileRawPath)}).Count
        Findings=(Counts $findingRows 'FindingCode'); Observations=(Counts $scan.Observations 'Code'); CoverageReasons=(Counts $gaps 'ReasonCode')
        PhysicalPresenceDisagreements=@($physicalChecks|Where-Object {$_.ReportedExists -ne $_.ActualExists}).Count
        InventoryFiles=@($scan.Files).Count; ExecutionStatus=$scan.Execution.CompletionStatus; Identification='Not executed: no approved assessment configuration supplied'
        Historical=[pscustomobject]@{ExecutionStatus=$(if($null -ne $old){$old.Execution.CompletionStatus}else{'Failed'});Sequences=$(if($null -ne $old){@($old.Sequences).Count}else{0});Xml=$(if($null -ne $old){@($old.XmlDocuments).Count}else{0});Evidence=$(if($null -ne $old){@($old.ClassificationEvidence).Count}else{0});References=$(if($null -ne $old){@($old.References).Count}else{0});Resolution=$(if($null -ne $old){Counts $old.References 'ResolutionStatus'}else{$null});Checksums=$(if($null -ne $old){Counts $old.References 'ChecksumComparisonStatus'}else{$null})}
    }
    [void]$rows.Add($row)
    Write-Output ('{0}: {1}; sequences={2}; XML={3}; SUXI={4}; references={5}; evidence={6}' -f $id,$row.ExecutionStatus,$row.Sequences,$row.Xml,$row.SubmissionUnits,$row.References,$row.Evidence)
}
foreach($f in $manifest){if($f.Sha256 -ne (Get-FileHash -LiteralPath $f.Path -Algorithm SHA256).Hash -or $f.Written -ne (Get-Item -LiteralPath $f.Path).LastWriteTimeUtc){throw 'Original source changed during verification.'}}
Write-Json (Join-Path $output 'local-input-mapping.json') @($mapping)
Write-Json (Join-Path $output 'local-source-manifest.json') @($manifest)
Write-Json (Join-Path $output 'sanitized-summary.json') ([pscustomobject]@{VerificationDate=$VerificationDate;Runtime=$PSVersionTable.PSVersion.ToString();InputCount=$inputs.Count;SourceFilesUnchanged=$manifest.Count;Publication='Counts only; mapping and detailed scans must remain local';Inputs=@($rows)})
Write-Output ('Verification finished; inputs={0}; unchanged source files={1}; evidence={2}' -f $inputs.Count,$manifest.Count,$output)
