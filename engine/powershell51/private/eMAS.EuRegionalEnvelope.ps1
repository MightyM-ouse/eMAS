#requires -Version 5.1

Set-StrictMode -Version 2.0

# EU-M1-ENVELOPE-VOCABULARY/1 reproduces the controlled attribute values in
# the official EU M1 2.0, 3.0.1 and 3.1 DTD appendices accepted by T1b.
# It is used only for exact, profile-scoped value recognition. This helper is
# deliberately non-validating and never resolves or reads an external DTD.
$script:eMASEuEnvelopeFieldOrder = @(
    'EU_ENVELOPE_COUNTRY',
    'EU_AGENCY_CODE',
    'EU_PROCEDURE_TYPE',
    'EU_SUBMISSION_TYPE',
    'EU_SUBMISSION_UNIT_TYPE'
)

$script:eMASEuEnvelopeVocabulary = @{
    '2.0' = @{
        EU_ENVELOPE_COUNTRY = @('at','be','bg','cy','cz','de','dk','ee','el','ema','es','fi','fr','hr','hu','ie','is','it','li','lt','lu','lv','mt','nl','no','pl','pt','ro','se','si','sk','uk')
        EU_AGENCY_CODE = @('AT-AGES','BE-FAMHP','BG-BDA','CY-PHS','CZ-SUKL','DE-BFARM','DE-PEI','DK-DKMA','EE-SAM','EL-EOF','ES-AEMPS','FI-FIMEA','FR-ANSM','HR-HALMED','HU-OGYI','IE-IMB','IS-IMCA','IT-AIFA','LI-LLV','LT-SMCA','LU-MINSANT','LV-ZVA','MT-MEDAUTH','NL-MEB','NO-NOMA','PL-URPL','PT-INFARMED','RO-ANMMD','SE-MPA','SI-JAZMP','SK-SIDC','UK-MHRA','EU-EMA')
        EU_PROCEDURE_TYPE = @('centralised','national','mutual-recognition','decentralised')
        EU_SUBMISSION_TYPE = @('initial-maa','var-type1a','var-type1b','var-type2','var-nat','extension','psur','renewal','supplemental-info','fum','specific-obligation','asmf','pmf','referral','annual-reassessment','usr','paed-article-29','paed-article-46','article-58','notification-61-3','transfer-ma','corrigendum','lifting-suspension','withdrawal','reformat','rmp')
        EU_SUBMISSION_UNIT_TYPE = $null
    }
    '3.0.1' = @{
        EU_ENVELOPE_COUNTRY = @('at','be','bg','cy','cz','de','dk','edqm','ee','el','ema','es','fi','fr','hr','hu','ie','is','it','li','lt','lu','lv','mt','nl','no','pl','pt','ro','se','si','sk','uk')
        EU_AGENCY_CODE = @('AT-BASG','BE-FAMHP','BG-BDA','CY-PHS','CZ-SUKL','DE-BFARM','DE-PEI','DK-DKMA','EE-SAM','EL-EOF','ES-AEMPS','FI-FIMEA','FR-ANSM','HR-HALMED','HU-OGYI','IE-HPRA','IS-IMCA','IT-AIFA','LI-LLV','LT-SMCA','LU-MINSANT','LV-ZVA','MT-MEDAUTH','NL-MEB','NO-NOMA','PL-URPL','PT-INFARMED','RO-ANMMD','SE-MPA','SI-JAZMP','SK-SIDC','UK-MHRA','EU-EMA','EU-EDQM')
        EU_PROCEDURE_TYPE = @('centralised','national','mutual-recognition','decentralised')
        EU_SUBMISSION_TYPE = @('maa','var-type1a','var-type1ain','var-type1b','var-type2','var-nat','extension','rup','psur','psusa','rmp','renewal','pam-sob','pam-anx','pam-mea','pam-leg','pam-sda','pam-capa','pam-p45','pam-p46','pam-paes','pam-rec','pass107n','pass107q','asmf','pmf','referral-20','referral-294','referral-29p','referral-30','referral-31','referral-35','referral-5-3','referral-107i','referral-16c1c','referral-16c4','annual-reassessment','usr','clin-data-pub-rp','clin-data-pub-fv','paed-7-8-30','paed-29','paed-45','paed-46','article-58','notification-61-3','transfer-ma','lifting-suspension','withdrawal','cep','none')
        EU_SUBMISSION_UNIT_TYPE = @('initial','validation-response','response','additional-info','closing','consolidating','corrigendum','reformat')
    }
    '3.1' = @{
        EU_ENVELOPE_COUNTRY = @('at','be','bg','cy','cz','de','dk','edqm','ee','el','ema','es','fi','fr','hr','hu','ie','is','it','li','lt','lu','lv','mt','nl','no','pl','pt','ro','se','si','sk','uk','xi')
        EU_AGENCY_CODE = @('AT-BASG','BE-FAMHP','BG-BDA','CY-PHS','CZ-SUKL','DE-BFARM','DE-PEI','DK-DKMA','EE-SAM','EL-EOF','ES-AEMPS','FI-FIMEA','FR-ANSM','HR-HALMED','HU-OGYI','IE-HPRA','IS-IMCA','IT-AIFA','LI-LLV','LT-SMCA','LU-MINSANT','LV-ZVA','MT-MEDAUTH','NL-MEB','NO-NOMA','PL-URPL','PT-INFARMED','RO-ANMMD','SE-MPA','SI-JAZMP','SK-SIDC','UK-MHRA','EU-EMA','EU-EDQM')
        EU_PROCEDURE_TYPE = @('centralised','national','mutual-recognition','decentralised')
        EU_SUBMISSION_TYPE = @('maa','var-type1a','var-type1ain','var-type1b','var-type2','var-nat','extension','rup','psur','psusa','rmp','renewal','pam-sob','pam-anx','pam-mea','pam-leg','pam-sda','pam-capa','pam-p45','pam-p46','pam-paes','pam-rec','pass107n','pass107q','asmf','pmf','referral-20','referral-294','referral-29p','referral-30','referral-31','referral-35','referral-5-3','referral-107i','referral-16c1c','referral-16c4','annual-reassessment','usr','clin-data-pub-rp','clin-data-pub-fv','paed-7-8-30','paed-29','paed-45','paed-46','article-58','notification-61-3','transfer-ma','lifting-suspension','withdrawal','cep','article-18','none')
        EU_SUBMISSION_UNIT_TYPE = @('initial','validation-response','response','additional-info','closing','consolidating','corrigendum','reformat','re-examination')
    }
}

function Get-eMASEuEnvelopeDirectChildren {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Parent,
        [Parameter(Mandatory = $true)][string] $LocalName
    )

    $matches = New-Object System.Collections.ArrayList
    foreach ($node in $Parent.ChildNodes) {
        if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element -and $node.LocalName -ceq $LocalName -and [string]::IsNullOrEmpty($node.NamespaceURI)) {
            [void]$matches.Add($node)
        }
    }
    return @($matches)
}

function ConvertTo-eMASEuEnvelopeToken {
    param([AllowNull()][string] $Value)

    if ($null -eq $Value) { return $null }
    return $Value.Trim([char[]]@([char]0x20, [char]0x09, [char]0x0D, [char]0x0A))
}

function New-eMASEuEnvelopeField {
    param(
        [Parameter(Mandatory = $true)][string] $ProfileVersion,
        [Parameter(Mandatory = $true)][string] $FieldCode,
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $Envelope
    )

    $vocabulary = $script:eMASEuEnvelopeVocabulary[$ProfileVersion][$FieldCode]
    if ($null -eq $vocabulary) {
        return [pscustomobject][ordered]@{
            FieldCode = $FieldCode
            Value = $null
            ValueStatus = 'NotDefinedInProfile'
            Occurrences = 0
        }
    }

    $elements = @()
    $attributeName = $null
    switch ($FieldCode) {
        'EU_ENVELOPE_COUNTRY' { $elements = @($Envelope); $attributeName = 'country' }
        'EU_AGENCY_CODE' { $elements = @(Get-eMASEuEnvelopeDirectChildren -Parent $Envelope -LocalName 'agency'); $attributeName = 'code' }
        'EU_PROCEDURE_TYPE' { $elements = @(Get-eMASEuEnvelopeDirectChildren -Parent $Envelope -LocalName 'procedure'); $attributeName = 'type' }
        'EU_SUBMISSION_TYPE' { $elements = @(Get-eMASEuEnvelopeDirectChildren -Parent $Envelope -LocalName 'submission'); $attributeName = 'type' }
        'EU_SUBMISSION_UNIT_TYPE' { $elements = @(Get-eMASEuEnvelopeDirectChildren -Parent $Envelope -LocalName 'submission-unit'); $attributeName = 'type' }
    }

    if ($elements.Count -gt 1) {
        $values = New-Object System.Collections.ArrayList
        foreach ($element in $elements) {
            if ($element.HasAttribute($attributeName)) {
                [void]$values.Add((ConvertTo-eMASEuEnvelopeToken -Value $element.GetAttribute($attributeName)))
            }
        }
        return [pscustomobject][ordered]@{
            FieldCode = $FieldCode
            Value = $null
            Values = [object[]]@($values)
            ValueStatus = 'MultipleValues'
            Occurrences = $elements.Count
        }
    }

    if ($elements.Count -eq 0 -or -not $elements[0].HasAttribute($attributeName)) {
        return [pscustomobject][ordered]@{
            FieldCode = $FieldCode
            Value = $null
            ValueStatus = 'Absent'
            Occurrences = 0
        }
    }

    $value = ConvertTo-eMASEuEnvelopeToken -Value $elements[0].GetAttribute($attributeName)
    $known = (@($vocabulary) -ccontains $value)
    return [pscustomobject][ordered]@{
        FieldCode = $FieldCode
        Value = $value
        ValueStatus = $(if ($known) { 'Known' } else { 'OutsideProfileVocabulary' })
        Occurrences = 1
    }
}

function New-eMASEuRegionalEnvelopeNotAttempted {
    return [pscustomobject][ordered]@{
        ProfileFamily = 'EU_M1'
        ProfileVersion = $null
        ProfileStatus = 'NotAttempted'
        VocabularyId = 'EU-M1-ENVELOPE-VOCABULARY/1'
        EnvelopeCount = 0
        Envelopes = [object[]]@()
    }
}

function Get-eMASEuRegionalEnvelope {
    <#
    .SYNOPSIS
    Extracts bounded EU M1 envelope facts from an already-loaded XML document.

    .DESCRIPTION
    The caller owns XML loading. This helper performs no file, network or DTD
    access and returns raw profile-scoped facts without regulatory interpretation.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Document)

    $root = $Document.DocumentElement
    $profileVersion = ConvertTo-eMASEuEnvelopeToken -Value $root.GetAttribute('dtd-version')
    $base = [ordered]@{
        ProfileFamily = 'EU_M1'
        ProfileVersion = $(if ([string]::IsNullOrEmpty($profileVersion)) { $null } else { $profileVersion })
        ProfileStatus = $null
        VocabularyId = 'EU-M1-ENVELOPE-VOCABULARY/1'
        EnvelopeCount = 0
        Envelopes = [object[]]@()
    }

    if ($root.LocalName -cne 'eu-backbone' -or $root.NamespaceURI -cne 'http://europa.eu.int') {
        $base.ProfileStatus = 'UnrecognizedRegionalStructure'
        return [pscustomobject]$base
    }
    if ([string]::IsNullOrEmpty($profileVersion) -or -not $script:eMASEuEnvelopeVocabulary.ContainsKey($profileVersion)) {
        $base.ProfileStatus = 'UnsupportedRegionalProfile'
        return [pscustomobject]$base
    }

    $containers = @(Get-eMASEuEnvelopeDirectChildren -Parent $root -LocalName 'eu-envelope')
    if ($containers.Count -ne 1) {
        $base.ProfileStatus = 'UnrecognizedRegionalStructure'
        return [pscustomobject]$base
    }
    $envelopeElements = @(Get-eMASEuEnvelopeDirectChildren -Parent $containers[0] -LocalName 'envelope')
    if ($envelopeElements.Count -eq 0) {
        $base.ProfileStatus = 'UnrecognizedRegionalStructure'
        return [pscustomobject]$base
    }

    $envelopes = New-Object System.Collections.ArrayList
    for ($index = 0; $index -lt $envelopeElements.Count; $index++) {
        $fields = New-Object System.Collections.ArrayList
        foreach ($fieldCode in $script:eMASEuEnvelopeFieldOrder) {
            [void]$fields.Add((New-eMASEuEnvelopeField -ProfileVersion $profileVersion -FieldCode $fieldCode -Envelope $envelopeElements[$index]))
        }
        [void]$envelopes.Add([pscustomobject][ordered]@{
            EnvelopeOrdinal = $index + 1
            Fields = [object[]]@($fields)
        })
    }

    $base.ProfileStatus = 'Supported'
    $base.EnvelopeCount = $envelopes.Count
    $base.Envelopes = [object[]]@($envelopes)
    return [pscustomobject]$base
}
