#requires -Version 5.1

Set-StrictMode -Version 2.0

# ECTD4-SUXI-VOCABULARY/1 is a bounded, exact-match registry derived from the
# accepted T2 source ledger. OIDs and codes are never matched by prefix.
$script:eMASEctd4VocabularyId = 'ECTD4-SUXI-VOCABULARY/1'
$script:eMASEctd4VocabularySources = [ordered]@{
    IchCvV7 = '5f54a6786580d379f7324d0cfd7d70feaabf78409b67bbf7a4d3b270d434687f'
    FdaCvV12 = 'a5aaf5a43b1269ee2899f8e4f2e696d83d495053cac25e6f5ac08d34690d6624'
    EuCvV3 = 'f4e3ff1dff074e402ebffd78d90d283c4937b02ef5cfcaaa98cd8fcb028bc812'
}

$script:eMASEctd4ProfileMarkers = @{
    '2.16.840.1.113883.3.989.2.2.1.11.1' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.2.2.1.11.2' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.2.2.1.11.3' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.2.2.1.11.4' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.2.2.1.11.5' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.2.2.1.11.6' = @{ Recognition = 'RecognizedIchIg'; Family = 'ICH'; SourceListVersion = 'ICH CV v7'; SourceStatus = 'Current' }
    '2.16.840.1.113883.3.989.5.1.2.2.1.18.7' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'FDA'; SourceListVersion = 'FDA CV v1.0'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.5.1.2.2.1.18.8' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'FDA'; SourceListVersion = 'FDA CV v1.1'; SourceStatus = 'Supported' }
    '2.16.840.1.113883.3.989.5.1.2.2.1.18.9' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'FDA'; SourceListVersion = 'FDA CV v1.2'; SourceStatus = 'Current' }
    '2.16.840.1.113883.3.989.5.1.1.6.1.1' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'EU'; SourceListVersion = 'EU IG change history'; SourceStatus = 'Historical' }
    '2.16.840.1.113883.3.989.5.1.1.6.1.2' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'EU'; SourceListVersion = 'EU CV v3'; SourceStatus = 'Draft' }
    '2.16.840.1.113883.3.989.5.1.1.6.1.3' = @{ Recognition = 'RecognizedRegionalIg'; Family = 'EU'; SourceListVersion = 'EU CV v3'; SourceStatus = 'RegisteredWithoutPublishedGuide' }
}

$script:eMASEctd4CodeSystems = @{
    '2.16.840.1.113883.3.989.5.1.2.2.1.13.2' = @{ ElementKind = 'SubmissionUnitType'; Codes = @('us_submission_unit_type_1','us_submission_unit_type_2','us_submission_unit_type_3','us_submission_unit_type_4','us_submission_unit_type_5','us_submission_unit_type_6','us_submission_unit_type_7') }
    '2.16.840.1.113883.3.989.5.1.2.2.1.12.5' = @{ ElementKind = 'SubmissionType'; Codes = @('us_submission_type_1','us_submission_type_2','us_submission_type_3','us_submission_type_4','us_submission_type_5','us_submission_type_6','us_submission_type_7','us_submission_type_8','us_submission_type_9','us_submission_type_10','us_submission_type_11') }
    '2.16.840.1.113883.3.989.5.1.2.2.1.1.4' = @{ ElementKind = 'ApplicationType'; Codes = @('us_application_type_1','us_application_type_2','us_application_type_3','us_application_type_4','us_application_type_5','us_application_type_6','us_application_type_7','us_application_type_9','us_application_type_10') }
    '2.16.840.1.113883.3.6905.1.8.1' = @{ ElementKind = 'SubmissionUnitType'; Codes = @('100000155047','100000155051','200000002281','200000002282','200000002283','200000002284','200000002285','200000002286','200000043411') }
    '2.16.840.1.113883.3.6905.1.11.1' = @{ ElementKind = 'SubmissionType'; Codes = @('100000155689','100000155690','100000155691','100000155692','100000155693','100000155694','100000155695','100000155696','100000155697','100000155699','100000155700','100000155701','100000155703','100000155704','100000155705','100000155706','100000155707','100000155708','100000155709','100000155710','100000155711','100000155713','100000155717','100000155718','200000002290','200000002291','200000002292','200000002293','200000002299','200000002300','200000002301','200000002302','200000002303','200000002305','200000002308','200000002310','200000002311','200000002312','200000002313','200000002314','200000002315','200000002318','200000002319','200000002320','200000002321','200000002322','200000002323','200000002325','220000000042','200000043524') }
    '2.16.840.1.113883.3.6905.1.11.2' = @{ ElementKind = 'SubmissionType'; Codes = @('100000155689','100000155690','100000155691','100000155692','100000155693','100000155694','100000155695','100000155696','100000155697','100000155699','100000155700','100000155701','100000155703','100000155704','100000155705','100000155706','100000155707','100000155708','100000155709','100000155710','100000155711','100000155713','100000155717','100000155718','200000002290','200000002291','200000002292','200000002293','200000002299','200000002300','200000002301','200000002302','200000002303','200000002305','200000002306','200000002308','200000002310','200000002311','200000002312','200000002313','200000002314','200000002315','200000002318','200000002319','200000002320','200000002321','200000002322','200000002323','200000002325','220000000042','200000043524') }
    '2.16.840.1.113883.3.6905.1.4.1' = @{ ElementKind = 'ApplicationType'; Codes = @('100000116047','100000116048','100000116050','100000116051','100000116052','100000116053','100000116054','100000116055','100000116056','100000116068','100000116081','200000013166','200000013167','200000013168','200000013169','200000013170','200000013171','200000016456','200000016457','200000023331','200000023341','200000023342','200000023343','200000023344') }
}

$script:eMASEctd4ApplicationNamespaces = @(
    '2.16.840.1.113883.3.989.5.1.2.2.1.15.1',
    '2.16.840.1.113883.3.989.5.1.2.2.1.16.1'
)

function Get-eMASEctd4VocabularyDescriptor {
    return [pscustomobject][ordered]@{
        VocabularyId = $script:eMASEctd4VocabularyId
        SourceHashes = [pscustomobject]$script:eMASEctd4VocabularySources
        ProfileMarkerCount = $script:eMASEctd4ProfileMarkers.Count
        CodeSystemCount = $script:eMASEctd4CodeSystems.Count
    }
}

function Resolve-eMASEctd4ProfileMarker {
    param([AllowNull()][string] $Root)

    if ([string]::IsNullOrWhiteSpace($Root)) {
        return [pscustomobject][ordered]@{ Recognition = 'Empty'; Family = $null; SourceListVersion = $null; SourceStatus = $null }
    }
    if (-not $script:eMASEctd4ProfileMarkers.ContainsKey($Root)) {
        return [pscustomobject][ordered]@{ Recognition = 'UnknownOid'; Family = $null; SourceListVersion = $null; SourceStatus = $null }
    }
    $entry = $script:eMASEctd4ProfileMarkers[$Root]
    return [pscustomobject][ordered]@{
        Recognition = [string]$entry.Recognition
        Family = [string]$entry.Family
        SourceListVersion = [string]$entry.SourceListVersion
        SourceStatus = [string]$entry.SourceStatus
    }
}

function Resolve-eMASEctd4CodedValue {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('SubmissionUnitType','SubmissionType','ApplicationType')][string] $ElementKind,
        [AllowNull()][string] $Code,
        [AllowNull()][string] $CodeSystem
    )

    if ([string]::IsNullOrWhiteSpace($Code) -or [string]::IsNullOrWhiteSpace($CodeSystem)) { return 'CodeOutsideCodeSystem' }
    if (-not $script:eMASEctd4CodeSystems.ContainsKey($CodeSystem)) { return 'UnrecognizedCodeSystem' }
    $entry = $script:eMASEctd4CodeSystems[$CodeSystem]
    if ([string]$entry.ElementKind -ne $ElementKind) { return 'CodeSystemNotExpectedForElement' }
    if (@($entry.Codes) -cnotcontains $Code) { return 'CodeOutsideCodeSystem' }
    return 'Known'
}

function Resolve-eMASEctd4ApplicationNamespace {
    param([AllowNull()][string] $Root)
    if (-not [string]::IsNullOrWhiteSpace($Root) -and $script:eMASEctd4ApplicationNamespaces -ccontains $Root) { return 'RecognizedNamespaceOid' }
    return 'NotRecognized'
}
