#requires -Version 5.1

Set-StrictMode -Version 2.0

$runtimeConfigurationModulePath = Join-Path $PSScriptRoot 'eMAS.RuntimeConfiguration.psm1'
Import-Module -Name $runtimeConfigurationModulePath -Force -ErrorAction Stop

$script:eMASIdentificationEngineVersion = '0.1.0'
$script:eMASIdentificationStrengthMap = [ordered]@{ Strong = 'STRONG'; Supporting = 'MEDIUM'; Weak = 'WEAK' }
$script:eMASIdentificationFieldProjection = @{
    CEC_XML_ROOT_ELEMENT_COMMON = @{ EvidenceType = 'XmlRootElement'; Scope = 'Sequence'; XmlKind = 'CommonBackbone' }
    CEC_XML_NAMESPACE_COMMON = @{ EvidenceType = 'XmlNamespace'; Scope = 'Sequence'; XmlKind = 'CommonBackbone' }
    CEC_XML_ROOT_ELEMENT_REGIONAL = @{ EvidenceType = 'XmlRootElement'; Scope = 'Sequence'; XmlKind = 'RegionalBackbone' }
    CEC_XML_NAMESPACE_REGIONAL = @{ EvidenceType = 'XmlNamespace'; Scope = 'Sequence'; XmlKind = 'RegionalBackbone' }
    CEC_COMMON_BACKBONE_PRESENCE = @{ EvidenceType = 'CommonBackbonePresence'; Scope = 'Sequence' }
    CEC_DOSSIER_ROOT_PATH = @{ EvidenceType = 'DossierRootPath'; Scope = 'Dossier' }
    CEC_UNIT_KIND = @{ EvidenceType = 'RegulatoryUnitKind'; Scope = 'Sequence' }
    CEC_SUBMISSION_UNIT_MARKER = @{ EvidenceType = 'SubmissionUnitMarkerFile'; Scope = 'Sequence' }
    CEC_CHECKSUM_FILE_MARKER = @{ EvidenceType = 'ChecksumFileMarker'; Scope = 'Sequence' }
    CEC_TOC_FILE_MARKER = @{ EvidenceType = 'TocFileMarker'; Scope = 'Sequence' }
}

function Get-eMASIdentificationPropertyValue {
    param([AllowNull()][object] $InputObject, [Parameter(Mandatory = $true)][string] $Name)
    if ($null -eq $InputObject -or $null -eq $InputObject.PSObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-eMASIdentificationProperty {
    param([AllowNull()][object] $InputObject, [Parameter(Mandatory = $true)][string] $Name)
    return ($null -ne $InputObject -and $null -ne $InputObject.PSObject -and $null -ne $InputObject.PSObject.Properties[$Name])
}

function ConvertTo-eMASIdentificationArray {
    param([AllowNull()][object] $Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [string] -or $Value -is [System.Collections.IDictionary]) { return ,$Value }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value) }
    return ,$Value
}

function Get-eMASIdentificationSha256FromBytes {
    param([Parameter(Mandatory = $true)][byte[]] $Bytes)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return (($algorithm.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '') }
    finally { $algorithm.Dispose() }
}

function Get-eMASIdentificationObjectSha256 {
    param([Parameter(Mandatory = $true)][object] $Value)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    return Get-eMASIdentificationSha256FromBytes -Bytes $encoding.GetBytes(($Value | ConvertTo-Json -Depth 64 -Compress))
}

function Get-eMASIdentificationRawConfiguration {
    param([Parameter(Mandatory = $true)][object] $RuntimeConfiguration)
    if (Test-eMASIdentificationProperty $RuntimeConfiguration 'Raw') { return $RuntimeConfiguration.Raw }
    return $RuntimeConfiguration
}

function Get-eMASIdentificationAllowedReason {
    param([AllowNull()][string] $Reason)
    if ($Reason -in @('InputUnavailable', 'ParseFailed', 'AccessDenied', 'UnmappedStrength', 'AmbiguousProjection')) { return $Reason }
    return 'NotCollected'
}

function Assert-eMASIdentificationInputs {
    param([Parameter(Mandatory = $true)][object] $InputResult, [Parameter(Mandatory = $true)][object] $RuntimeConfiguration)

    if ([string]$InputResult.ContractId -ne 'eMAS.MS04.PreSales.ScannerObservations/1.0') { throw 'IDI-INPUT-001 Unsupported scanner contract.' }
    if ([string]$InputResult.Execution.ScenarioId -ne 'MS-04' -or [string]$InputResult.Execution.Phase -ne 'PreSales') { throw 'IDI-INPUT-002 Input is not an MS-04 PreSales observation document.' }
    $capabilities = @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult.Execution 'Capabilities'))
    if ($capabilities -notcontains 'ClassificationEvidenceCollection') { throw 'IDI-INPUT-003 ClassificationEvidenceCollection capability is absent.' }

    $sequenceIds = @{}
    foreach ($item in @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'Sequences'))) { $sequenceIds[[string]$item.SequenceId] = $true }
    $dossierIds = @{}
    foreach ($item in @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'DossierCandidates'))) { $dossierIds[[string]$item.DossierId] = $true }
    $xmlIds = @{}
    foreach ($item in @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'XmlDocuments'))) { $xmlIds[[string]$item.XmlId] = $true }
    $evidenceIds = @{}
    foreach ($item in @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'ClassificationEvidence'))) {
        $evidenceId = [string]$item.EvidenceId
        $sequenceId = [string](Get-eMASIdentificationPropertyValue $item 'SequenceId')
        $dossierId = [string](Get-eMASIdentificationPropertyValue $item 'DossierId')
        $xmlId = [string](Get-eMASIdentificationPropertyValue $item 'XmlId')
        if ([string]::IsNullOrWhiteSpace($evidenceId) -or $evidenceIds.ContainsKey($evidenceId) -or
            (-not [string]::IsNullOrWhiteSpace($sequenceId) -and -not $sequenceIds.ContainsKey($sequenceId)) -or
            (-not [string]::IsNullOrWhiteSpace($dossierId) -and -not $dossierIds.ContainsKey($dossierId)) -or
            (-not [string]::IsNullOrWhiteSpace($xmlId) -and -not $xmlIds.ContainsKey($xmlId))) { throw 'IDI-INPUT-004 Invalid or duplicate evidence reference.' }
        $evidenceIds[$evidenceId] = $true
    }

    $raw = Get-eMASIdentificationRawConfiguration $RuntimeConfiguration
    $metadata = Get-eMASConfigurationMetadata -Configuration $raw
    if ($null -eq $metadata -or [string]$metadata.schemaVersion -ne '1.1.0') { throw 'IDI-CONFIG-001 Runtime JSON Schema 1.1.0 is required.' }
    $validation = Get-eMASIdentificationPropertyValue $RuntimeConfiguration 'Validation'
    if ($null -eq $validation) { $validation = Test-eMASRuntimeConfiguration -Configuration $raw }
    if ($null -eq $validation -or [int]$validation.BlockingIssueCount -gt 0) { throw 'IDI-CONFIG-001 Runtime configuration has not passed validation.' }

    $identificationConflictPolicies = @(ConvertTo-eMASIdentificationArray $raw.policies.conflictPolicies | Where-Object { [string]$_.ruleType -eq 'IDENTIFICATION' })
    if ($identificationConflictPolicies.Count -ne 1) { throw 'IDI-CONFIG-002 Exactly one Identification conflict policy is required.' }
    $confidenceKeys = @{}
    foreach ($policy in @(ConvertTo-eMASIdentificationArray $raw.policies.confidencePolicies | Where-Object { [string]$_.scope -eq 'IDENTIFICATION' })) {
        $key = '{0}|{1}' -f [string]$policy.evidenceStrength, [string]$policy.corroborationRule
        if ($confidenceKeys.ContainsKey($key)) { throw 'IDI-CONFIG-003 Duplicate Identification confidence policy key.' }
        $confidenceKeys[$key] = $true
        if (Test-eMASIdentificationProperty $policy 'weightOrScore') { throw 'IDI-CONFIG-003 Numeric Identification confidence weights are prohibited.' }
    }
    $activeRuleIds = @{}
    foreach ($phase in @(ConvertTo-eMASIdentificationArray $raw.rulePhases)) { if ([string]$phase.phase -eq 'PRE_SALES') { $activeRuleIds[[string]$phase.ruleId] = $true } }
    $identificationRuleIds = @{}
    foreach ($rule in @(ConvertTo-eMASIdentificationArray $raw.rules)) { if ([string]$rule.ruleType -eq 'IDENTIFICATION' -and $activeRuleIds.ContainsKey([string]$rule.ruleId)) { $identificationRuleIds[[string]$rule.ruleId] = $true } }
    $catalogue = @{}
    foreach ($field in @(ConvertTo-eMASIdentificationArray $raw.fieldCatalogue)) { $catalogue[[string]$field.fieldCode] = $field }
    foreach ($condition in @(ConvertTo-eMASIdentificationArray $raw.ruleConditions)) {
        if (-not $identificationRuleIds.ContainsKey([string]$condition.ruleId)) { continue }
        $fieldCode = [string]$condition.fieldCode
        if (-not $catalogue.ContainsKey($fieldCode) -or [string]$catalogue[$fieldCode].producingComponent -ne 'CLASSIFICATION_EVIDENCE_COLLECTION' -or
            -not $script:eMASIdentificationFieldProjection.ContainsKey($fieldCode) -or [string]$condition.operator -notin @('EQUALS', 'NOT_EQUALS', 'IN_LIST', 'CONTAINS', 'STARTS_WITH', 'ENDS_WITH', 'EXISTS', 'MISSING')) {
            throw ('IDI-CONFIG-004 Unsupported CEC field projection or operator for {0}.' -f $fieldCode)
        }
    }
    return $raw
}

function Get-eMASIdentificationStrengthOrder {
    param([Parameter(Mandatory = $true)][object] $RawConfiguration)
    $rank = @{}
    foreach ($row in @(ConvertTo-eMASIdentificationArray $RawConfiguration.valueLists.EVIDENCE_STRENGTH)) { if ([string]$row.code -in @('STRONG', 'MEDIUM', 'WEAK')) { $rank[[string]$row.code] = [int]$row.sortOrder } }
    if ($rank.Count -ne 3 -or $rank.STRONG -ge $rank.MEDIUM -or $rank.MEDIUM -ge $rank.WEAK) { throw 'IDI-CONFIG-005 EVIDENCE_STRENGTH must order STRONG before MEDIUM before WEAK.' }
    return $rank
}

function Get-eMASIdentificationTrace {
    param([Parameter(Mandatory = $true)][object] $Evidence, [Parameter(Mandatory = $true)][string] $NormalizedStrength)
    return [pscustomobject][ordered]@{ EvidenceId = [string]$Evidence.EvidenceId; RawStrength = [string]$Evidence.Strength; NormalizedStrength = $NormalizedStrength; SourceTier = [string]$Evidence.SourceTier }
}

function New-eMASIdentificationUnavailable {
    param([Parameter(Mandatory = $true)][string] $FieldCode, [AllowNull()][string] $EvidenceId, [Parameter(Mandatory = $true)][string] $Reason)
    return [pscustomobject][ordered]@{ FieldCode = $FieldCode; EvidenceId = $(if ([string]::IsNullOrWhiteSpace($EvidenceId)) { $null } else { $EvidenceId }); Reason = (Get-eMASIdentificationAllowedReason $Reason) }
}

function Get-eMASIdentificationRepositoryCoverage {
    param([Parameter(Mandatory = $true)][object[]] $Coverage)
    return @($Coverage | Where-Object { [string]$_.CheckId -eq 'ClassificationEvidenceCollection' -and [string]$_.SubjectType -eq 'Repository' } | Select-Object -First 1)
}

function Get-eMASIdentificationFieldState {
    param(
        [Parameter(Mandatory = $true)][string] $FieldCode,
        [Parameter(Mandatory = $true)][object] $Subject,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Evidence,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $XmlDocuments,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Coverage
    )
    $selector = $script:eMASIdentificationFieldProjection[$FieldCode]
    $xmlById = @{}
    foreach ($xml in $XmlDocuments) { $xmlById[[string]$xml.XmlId] = $xml }
    $matching = New-Object System.Collections.ArrayList
    foreach ($record in $Evidence) {
        if ([string]$record.EvidenceType -ne [string]$selector.EvidenceType) { continue }
        if ([string]$selector.Scope -eq 'Dossier') {
            if (-not [string]::IsNullOrWhiteSpace([string](Get-eMASIdentificationPropertyValue $record 'SequenceId')) -or [string]$record.DossierId -ne [string]$Subject.DossierId) { continue }
        }
        elseif ([string]$record.SequenceId -ne [string]$Subject.SubjectId) { continue }
        if ($selector.ContainsKey('XmlKind')) {
            $xmlId = [string](Get-eMASIdentificationPropertyValue $record 'XmlId')
            if (-not $xmlById.ContainsKey($xmlId) -or [string]$xmlById[$xmlId].XmlKind -ne [string]$selector.XmlKind) { continue }
        }
        [void]$matching.Add($record)
    }

    $unavailable = New-Object System.Collections.ArrayList
    $available = New-Object System.Collections.ArrayList
    foreach ($record in $matching) {
        $normalized = [string]$script:eMASIdentificationStrengthMap[[string]$record.Strength]
        if ([string]::IsNullOrWhiteSpace($normalized)) { [void]$unavailable.Add((New-eMASIdentificationUnavailable $FieldCode ([string]$record.EvidenceId) 'UnmappedStrength')) }
        elseif ([string]$record.CaptureStatus -ne 'Available') { [void]$unavailable.Add((New-eMASIdentificationUnavailable $FieldCode ([string]$record.EvidenceId) ([string]$record.CaptureStatus))) }
        else { [void]$available.Add([pscustomobject]@{ Value = (Get-eMASIdentificationPropertyValue $record 'ObservedValue'); Trace = (Get-eMASIdentificationTrace $record $normalized) }) }
    }
    if ($available.Count -gt 1) { return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @((New-eMASIdentificationUnavailable $FieldCode $null 'AmbiguousProjection')) } }
    if ($available.Count -eq 1 -and $matching.Count -eq 1) { return [pscustomobject]@{ State = 'Available'; Value = $available[0].Value; Trace = $available[0].Trace; Unavailable = @() } }
    if ($unavailable.Count -gt 0) { return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @($unavailable) } }

    $repositoryCoverage = @(Get-eMASIdentificationRepositoryCoverage $Coverage)
    if ($selector.ContainsKey('XmlKind')) {
        $subjectXml = @($XmlDocuments | Where-Object { [string]$_.SequenceId -eq [string]$Subject.SubjectId -and [string]$_.XmlKind -eq [string]$selector.XmlKind })
        if ($subjectXml.Count -eq 0) {
            if ($repositoryCoverage.Count -gt 0 -and [string]$repositoryCoverage[0].CollectionStatus -in @('Collected', 'Partial')) { return [pscustomobject]@{ State = 'AssessedAbsent'; Value = $null; Trace = $null; Unavailable = @() } }
            $reason = $(if ($repositoryCoverage.Count -gt 0) { [string]$repositoryCoverage[0].CaptureStatus } else { 'NotCollected' })
            return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @((New-eMASIdentificationUnavailable $FieldCode $null $reason)) }
        }
        if ($subjectXml.Count -gt 1) { return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @((New-eMASIdentificationUnavailable $FieldCode $null 'AmbiguousProjection')) } }
        $xmlCoverage = @($Coverage | Where-Object { [string]$_.CheckId -eq 'ClassificationEvidenceCollection' -and [string]$_.SubjectType -eq 'XmlDocument' -and [string]$_.SubjectId -eq [string]$subjectXml[0].XmlId } | Select-Object -First 1)
        if ($xmlCoverage.Count -gt 0 -and [string]$xmlCoverage[0].CollectionStatus -in @('Collected', 'NotApplicable')) { return [pscustomobject]@{ State = 'AssessedAbsent'; Value = $null; Trace = $null; Unavailable = @() } }
        $reason = $(if ($xmlCoverage.Count -gt 0) { [string]$xmlCoverage[0].CaptureStatus } else { [string]$subjectXml[0].CaptureStatus })
        return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @((New-eMASIdentificationUnavailable $FieldCode $null $reason)) }
    }
    if ($repositoryCoverage.Count -gt 0 -and [string]$repositoryCoverage[0].CollectionStatus -in @('Collected', 'Partial')) { return [pscustomobject]@{ State = 'AssessedAbsent'; Value = $null; Trace = $null; Unavailable = @() } }
    $repositoryReason = $(if ($repositoryCoverage.Count -gt 0) { [string]$repositoryCoverage[0].CaptureStatus } else { 'NotCollected' })
    return [pscustomobject]@{ State = 'Unavailable'; Value = $null; Trace = $null; Unavailable = @((New-eMASIdentificationUnavailable $FieldCode $null $repositoryReason)) }
}

function Test-eMASIdentificationEqual {
    param([AllowNull()][object] $Actual, [AllowNull()][object] $Expected, [bool] $CaseSensitive)
    if ($null -eq $Actual -or $null -eq $Expected) { return ($null -eq $Actual -and $null -eq $Expected) }
    if ($Actual -is [string] -or $Expected -is [string]) {
        $comparison = $(if ($CaseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase })
        return ([string]$Actual).Equals([string]$Expected, $comparison)
    }
    return ($Actual -eq $Expected)
}

function Invoke-eMASIdentificationCondition {
    param([Parameter(Mandatory = $true)][object] $Condition, [Parameter(Mandatory = $true)][object] $FieldState)
    if ([string]$FieldState.State -eq 'Unavailable') { return 'Unknown' }
    $operator = [string]$Condition.operator
    if ($operator -eq 'EXISTS') { $answer = ([string]$FieldState.State -eq 'Available') }
    elseif ($operator -eq 'MISSING') { $answer = ([string]$FieldState.State -eq 'AssessedAbsent') }
    elseif ([string]$FieldState.State -eq 'AssessedAbsent') { $answer = ($operator -eq 'NOT_EQUALS') }
    else {
        $actual = $FieldState.Value
        $value1 = Get-eMASIdentificationPropertyValue $Condition 'value1'
        $caseSensitive = [bool]$Condition.caseSensitive
        switch ($operator) {
            'EQUALS' { $answer = Test-eMASIdentificationEqual $actual $value1 $caseSensitive }
            'NOT_EQUALS' { $answer = -not (Test-eMASIdentificationEqual $actual $value1 $caseSensitive) }
            'IN_LIST' {
                $answer = $false
                foreach ($expected in @(ConvertTo-eMASIdentificationArray $value1)) { if (Test-eMASIdentificationEqual $actual $expected $caseSensitive) { $answer = $true; break } }
            }
            'CONTAINS' {
                $comparison = $(if ($caseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase })
                $answer = (([string]$actual).IndexOf([string]$value1, $comparison) -ge 0)
            }
            'STARTS_WITH' {
                $comparison = $(if ($caseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase })
                $answer = ([string]$actual).StartsWith([string]$value1, $comparison)
            }
            'ENDS_WITH' {
                $comparison = $(if ($caseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase })
                $answer = ([string]$actual).EndsWith([string]$value1, $comparison)
            }
            default { throw ('IDI-CONFIG-004 Unsupported Identification operator {0}.' -f $operator) }
        }
    }
    if ([bool]$Condition.negate) { $answer = -not $answer }
    return $(if ($answer) { 'True' } else { 'False' })
}

function Get-eMASIdentificationUniqueEvidence {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Items)
    $byId = @{}
    foreach ($item in $Items) { if (-not $byId.ContainsKey([string]$item.EvidenceId)) { $byId[[string]$item.EvidenceId] = $item } }
    return @($byId.Values | Sort-Object @{ Expression = { [string]$_.EvidenceId } })
}

function Get-eMASIdentificationUniqueUnavailable {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Items)
    $byKey = @{}
    foreach ($item in $Items) {
        $id = [string](Get-eMASIdentificationPropertyValue $item 'EvidenceId')
        $key = '{0}|{1}|{2}' -f [string]$item.FieldCode, $id, [string]$item.Reason
        if (-not $byKey.ContainsKey($key)) { $byKey[$key] = $item }
    }
    return @($byKey.Values | Sort-Object @{ Expression = { [string]$_.FieldCode } }, @{ Expression = { if ($null -eq $_.EvidenceId) { '' } else { [string]$_.EvidenceId } } }, @{ Expression = { [string]$_.Reason } })
}

function Invoke-eMASIdentificationRule {
    param(
        [Parameter(Mandatory = $true)][object] $Rule,
        [Parameter(Mandatory = $true)][object[]] $Groups,
        [Parameter(Mandatory = $true)][object[]] $Conditions,
        [Parameter(Mandatory = $true)][hashtable] $FieldStates
    )
    $trueGroupEvidence = New-Object System.Collections.ArrayList
    $unavailable = New-Object System.Collections.ArrayList
    $anyTrue = $false
    $anyUnknown = $false
    foreach ($group in @($Groups | Where-Object { [string]$_.ruleId -eq [string]$Rule.ruleId } | Sort-Object groupSequence, conditionGroupId)) {
        $hasFalse = $false
        $hasUnknown = $false
        $groupEvidence = New-Object System.Collections.ArrayList
        foreach ($condition in @($Conditions | Where-Object { [string]$_.conditionGroupId -eq [string]$group.conditionGroupId } | Sort-Object sequence, conditionId)) {
            $state = $FieldStates[[string]$condition.fieldCode]
            foreach ($item in @($state.Unavailable)) { [void]$unavailable.Add($item) }
            $outcome = Invoke-eMASIdentificationCondition $condition $state
            if ($outcome -eq 'False') { $hasFalse = $true }
            elseif ($outcome -eq 'Unknown') { $hasUnknown = $true }
            elseif (-not [bool]$condition.negate -and [string]$state.State -eq 'Available') { [void]$groupEvidence.Add($state.Trace) }
        }
        if ($hasFalse) { continue }
        if ($hasUnknown) { $anyUnknown = $true; continue }
        $anyTrue = $true
        foreach ($item in $groupEvidence) { [void]$trueGroupEvidence.Add($item) }
    }
    return [pscustomobject]@{
        State = $(if ($anyTrue) { 'True' } elseif ($anyUnknown) { 'Unknown' } else { 'False' })
        Evidence = @(Get-eMASIdentificationUniqueEvidence @($trueGroupEvidence))
        Unavailable = @(Get-eMASIdentificationUniqueUnavailable @($unavailable))
    }
}

function Get-eMASIdentificationStrengthForRank {
    param([Parameter(Mandatory = $true)][hashtable] $StrengthOrder, [Parameter(Mandatory = $true)][int] $Rank)
    return [string](@($StrengthOrder.Keys | Where-Object { [int]$StrengthOrder[$_] -eq $Rank } | Select-Object -First 1)[0])
}

function Resolve-eMASIdentificationDimension {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Rules,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Hits,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Unavailable,
        [Parameter(Mandatory = $true)][hashtable] $StrengthOrder,
        [Parameter(Mandatory = $true)][object] $ConflictPolicy,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $ConfidencePolicies,
        [Parameter(Mandatory = $true)][bool] $AnyRuleUnknown
    )
    $candidates = New-Object System.Collections.ArrayList
    foreach ($candidateGroup in @($Hits | Group-Object OutputCode)) {
        $support = @($candidateGroup.Group | Where-Object { [string]$_.Polarity -eq 'SUPPORTS' })
        $contradict = @($candidateGroup.Group | Where-Object { [string]$_.Polarity -eq 'CONTRADICTS' })
        $supportRank = $null
        $contradictRank = $null
        foreach ($hit in $support) { if ($null -eq $supportRank -or [int]$StrengthOrder[$hit.Strength] -lt $supportRank) { $supportRank = [int]$StrengthOrder[$hit.Strength] } }
        foreach ($hit in $contradict) { if ($null -eq $contradictRank -or [int]$StrengthOrder[$hit.Strength] -lt $contradictRank) { $contradictRank = [int]$StrengthOrder[$hit.Strength] } }
        [void]$candidates.Add([pscustomobject][ordered]@{
            Value = [string]$candidateGroup.Name
            BestSupportStrength = $(if ($null -eq $supportRank) { $null } else { Get-eMASIdentificationStrengthForRank $StrengthOrder $supportRank })
            BestContradictionStrength = $(if ($null -eq $contradictRank) { $null } else { Get-eMASIdentificationStrengthForRank $StrengthOrder $contradictRank })
            SupportingRuleIds = [object[]]@($support | ForEach-Object { [string]$_.RuleId } | Sort-Object -Unique)
            ContradictingRuleIds = [object[]]@($contradict | ForEach-Object { [string]$_.RuleId } | Sort-Object -Unique)
            SupportingEvidence = [object[]]@(Get-eMASIdentificationUniqueEvidence @($support | ForEach-Object { $_.Evidence }))
            ContradictingEvidence = [object[]]@(Get-eMASIdentificationUniqueEvidence @($contradict | ForEach-Object { $_.Evidence }))
        })
    }
    $candidates = @($candidates | Sort-Object @{ Expression = { if ($null -eq $_.BestSupportStrength) { 2147483647 } else { [int]$StrengthOrder[[string]$_.BestSupportStrength] } } }, @{ Expression = { [string]$_.Value } })
    $supportCandidates = @($candidates | Where-Object { $null -ne $_.BestSupportStrength })
    $bestRank = $null
    foreach ($candidate in $supportCandidates) {
        $rank = [int]$StrengthOrder[[string]$candidate.BestSupportStrength]
        if ($null -eq $bestRank -or $rank -lt $bestRank) { $bestRank = $rank }
    }
    $bestStrength = $(if ($null -eq $bestRank) { $null } else { Get-eMASIdentificationStrengthForRank $StrengthOrder $bestRank })
    $top = @($supportCandidates | Where-Object { $null -ne $bestRank -and [int]$StrengthOrder[[string]$_.BestSupportStrength] -eq $bestRank })
    $floor = [string](Get-eMASIdentificationPropertyValue $ConflictPolicy 'minimumEvidenceStrengthForValue')
    if ([string]::IsNullOrWhiteSpace($floor)) { $floor = 'MEDIUM' }
    if (-not $StrengthOrder.ContainsKey($floor)) { throw 'IDI-CONFIG-005 Invalid Identification evidence floor.' }

    $status = 'NotAssessed'
    $value = $null
    $confidence = 'UNKNOWN'
    $reviewRequired = $true
    $valueSource = $null
    $independentCount = $null
    $lowerTierContradiction = $false
    $confidenceMatched = $false
    $limiting = New-Object System.Collections.ArrayList
    if ($Rules.Count -eq 0) { [void]$limiting.Add('NoIdentificationRuleConfigured') }
    elseif ($supportCandidates.Count -eq 0 -and $AnyRuleUnknown) { [void]$limiting.Add('RuleNotEvaluable') }
    elseif ($supportCandidates.Count -eq 0) { $status = 'InsufficientEvidence'; [void]$limiting.Add('NoRuleFired') }
    elseif ($bestRank -gt [int]$StrengthOrder[$floor]) { $status = 'InsufficientEvidence'; [void]$limiting.Add('BelowEvidenceFloor') }
    elseif ($top.Count -gt 1) { $status = 'Conflict'; [void]$limiting.Add('EqualBestStrengthCandidates') }
    elseif ($null -ne $top[0].BestContradictionStrength -and [int]$StrengthOrder[[string]$top[0].BestContradictionStrength] -le $bestRank) { $status = 'Conflict'; [void]$limiting.Add('SupportContradictedAtBestStrength') }
    else {
        $status = 'Evaluated'
        $value = [string]$top[0].Value
        $valueSource = 'Derived'
        if ($null -ne $top[0].BestContradictionStrength) {
            $contradictRank = [int]$StrengthOrder[[string]$top[0].BestContradictionStrength]
            if ($contradictRank -gt $bestRank -and $contradictRank -le [int]$StrengthOrder[$floor]) { $lowerTierContradiction = $true; [void]$limiting.Add('LowerTierContradiction') }
        }
        $sourceTiers = @($top[0].SupportingEvidence | Where-Object { [int]$StrengthOrder[[string]$_.NormalizedStrength] -le [int]$StrengthOrder[$floor] } | ForEach-Object { [string]$_.SourceTier } | Sort-Object -Unique)
        $independentCount = $sourceTiers.Count
        $policy = $null
        if ($independentCount -ge 2) {
            $selected = @($ConfidencePolicies | Where-Object { [string]$_.evidenceStrength -eq $bestStrength -and [string]$_.corroborationRule -eq 'INDEPENDENT_SOURCE_CLASS' } | Select-Object -First 1)
            if ($selected.Count -gt 0) { $policy = $selected[0] }
        }
        if ($null -eq $policy) {
            $selected = @($ConfidencePolicies | Where-Object { [string]$_.evidenceStrength -eq $bestStrength -and [string]$_.corroborationRule -eq 'NONE_REQUIRED' } | Select-Object -First 1)
            if ($selected.Count -gt 0) { $policy = $selected[0] }
        }
        if ($null -ne $policy) { $confidence = [string]$policy.resultConfidence; $confidenceMatched = $true }
        else { [void]$limiting.Add('NoConfidencePolicyMatched') }
        $reviewRequired = -not ($bestStrength -eq 'STRONG' -and -not $lowerTierContradiction -and $confidenceMatched)
    }
    if ($AnyRuleUnknown -and $supportCandidates.Count -gt 0) { [void]$limiting.Add('RuleNotEvaluable') }
    if (@($Hits | Where-Object { $_.StrengthCapped }).Count -gt 0) { [void]$limiting.Add('StrengthCappedByEvidence') }

    $countByStrength = [pscustomobject][ordered]@{ STRONG = 0; MEDIUM = 0; WEAK = 0 }
    foreach ($hit in @($Hits | Where-Object { [string]$_.Polarity -eq 'SUPPORTS' })) { $countByStrength.([string]$hit.Strength) = [int]$countByStrength.([string]$hit.Strength) + 1 }
    $supportIds = @($candidates | ForEach-Object { $_.SupportingEvidence } | ForEach-Object { [string]$_.EvidenceId } | Sort-Object -Unique)
    $contradictIds = @($candidates | ForEach-Object { $_.ContradictingEvidence } | ForEach-Object { [string]$_.EvidenceId } | Sort-Object -Unique)
    $firedIds = @($candidates | ForEach-Object { @($_.SupportingRuleIds) + @($_.ContradictingRuleIds) } | Sort-Object -Unique)
    return [pscustomobject]@{
        EvaluationStatus = $status; Value = $value; Confidence = $confidence; ReviewRequired = $reviewRequired; ValueSource = $valueSource
        Candidates = [object[]]$candidates; SupportingEvidenceIds = [object[]]$supportIds; ContradictingEvidenceIds = [object[]]$contradictIds
        FiredRuleIds = [object[]]$firedIds; UnavailableEvidence = [object[]]@(Get-eMASIdentificationUniqueUnavailable $Unavailable)
        ScoreSummary = [pscustomobject][ordered]@{ ScoreModel = 'ORDINAL_TIER/1'; BestStrength = $bestStrength; TierRank = $bestRank; CountByStrength = $countByStrength; IndependentSourceClassCount = $independentCount }
        LimitingFactors = [object[]]@($limiting | Sort-Object -Unique)
    }
}

function Test-eMASIdentificationOutputPath {
    param([Parameter(Mandatory = $true)][object] $InputResult, [Parameter(Mandatory = $true)][object] $RuntimeConfiguration, [Parameter(Mandatory = $true)][string] $OutputPath)
    $resolved = [System.IO.Path]::GetFullPath($OutputPath)
    $configurationPath = [string](Get-eMASIdentificationPropertyValue $RuntimeConfiguration 'Path')
    if (-not [string]::IsNullOrWhiteSpace($configurationPath) -and $resolved.Equals([System.IO.Path]::GetFullPath($configurationPath), [System.StringComparison]::OrdinalIgnoreCase)) { throw 'IDI-OUTPUT-001 Output must not overwrite Runtime JSON.' }
    $sourcePath = [string](Get-eMASIdentificationPropertyValue $InputResult.Repository 'ResolvedSourcePath')
    if ([string]::IsNullOrWhiteSpace($sourcePath)) { $sourcePath = [string](Get-eMASIdentificationPropertyValue $InputResult.Repository 'SourcePath') }
    if (-not [string]::IsNullOrWhiteSpace($sourcePath) -and [System.IO.Path]::IsPathRooted($sourcePath)) {
        $fullSource = [System.IO.Path]::GetFullPath($sourcePath)
        if ([string]$InputResult.Repository.SourceKind -eq 'Zip' -and $resolved.Equals($fullSource, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'IDI-OUTPUT-002 Output must not overwrite the source repository.' }
        if ([string]$InputResult.Repository.SourceKind -eq 'Directory') {
            $prefix = $fullSource.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if ($resolved.Equals($fullSource, [System.StringComparison]::OrdinalIgnoreCase) -or $resolved.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'IDI-OUTPUT-003 Output must not be inside the source repository.' }
        }
    }
    return $resolved
}

function Write-eMASIdentificationResult {
    param([Parameter(Mandatory = $true)][object] $Result, [Parameter(Mandatory = $true)][string] $OutputPath)
    $parent = [System.IO.Path]::GetDirectoryName($OutputPath)
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = [System.IO.Directory]::GetCurrentDirectory() }
    if (-not [System.IO.Directory]::Exists($parent)) { [void][System.IO.Directory]::CreateDirectory($parent) }
    $temporary = Join-Path $parent ('.{0}.{1}.tmp' -f [System.IO.Path]::GetFileName($OutputPath), [guid]::NewGuid().ToString('N'))
    try {
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($temporary, ($Result | ConvertTo-Json -Depth 64), $encoding)
        if ([System.IO.File]::Exists($OutputPath)) { [System.IO.File]::Delete($OutputPath) }
        [System.IO.File]::Move($temporary, $OutputPath)
    }
    finally { if ([System.IO.File]::Exists($temporary)) { [System.IO.File]::Delete($temporary) } }
}

function Invoke-eMASIdentificationInterpretation {
    <#
    .SYNOPSIS
    Interprets accepted CEC facts using validated Runtime JSON Schema 1.1.0 Identification rules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $InputResult,
        [Parameter(Mandatory = $true)][ValidateNotNull()][object] $RuntimeConfiguration,
        [AllowNull()][string] $EvidenceSourceSha256,
        [AllowNull()][string] $OutputPath
    )

    $startedAt = [DateTime]::UtcNow
    $raw = Assert-eMASIdentificationInputs $InputResult $RuntimeConfiguration
    $strengthOrder = Get-eMASIdentificationStrengthOrder $raw
    $resolvedOutputPath = $null
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) { $resolvedOutputPath = Test-eMASIdentificationOutputPath $InputResult $RuntimeConfiguration $OutputPath }
    $allEvidence = @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'ClassificationEvidence'))
    $xmlDocuments = @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'XmlDocuments'))
    $coverage = @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'CollectionCoverage'))
    $groups = @(ConvertTo-eMASIdentificationArray $raw.conditionGroups)
    $conditions = @(ConvertTo-eMASIdentificationArray $raw.ruleConditions)
    $outputs = @(ConvertTo-eMASIdentificationArray $raw.ruleOutputs)
    $activeRuleIds = @{}
    foreach ($phase in @(ConvertTo-eMASIdentificationArray $raw.rulePhases)) { if ([string]$phase.phase -eq 'PRE_SALES') { $activeRuleIds[[string]$phase.ruleId] = $true } }
    $rules = @(ConvertTo-eMASIdentificationArray $raw.rules | Where-Object { [string]$_.ruleType -eq 'IDENTIFICATION' -and $activeRuleIds.ContainsKey([string]$_.ruleId) })
    $dimensions = @(ConvertTo-eMASIdentificationArray $raw.valueLists.IDENTIFICATION_DIMENSION | Sort-Object sortOrder, code)
    $conflictPolicy = @(ConvertTo-eMASIdentificationArray $raw.policies.conflictPolicies | Where-Object { [string]$_.ruleType -eq 'IDENTIFICATION' })[0]
    $confidencePolicies = @(ConvertTo-eMASIdentificationArray $raw.policies.confidencePolicies | Where-Object { [string]$_.scope -eq 'IDENTIFICATION' })

    $resultRows = New-Object System.Collections.ArrayList
    $ordinal = 0
    foreach ($sequence in @(ConvertTo-eMASIdentificationArray (Get-eMASIdentificationPropertyValue $InputResult 'Sequences') | Sort-Object SequenceId)) {
        $subject = [pscustomobject]@{ SubjectId = [string]$sequence.SequenceId; DossierId = [string]$sequence.DossierId }
        foreach ($dimensionRow in $dimensions) {
            $dimension = [string]$dimensionRow.code
            $dimensionOutputs = @($outputs | Where-Object {
                [string](Get-eMASIdentificationPropertyValue $_ 'phase') -eq 'PRE_SALES' -and
                [string](Get-eMASIdentificationPropertyValue $_ 'outputType') -eq 'ClassificationCandidate' -and
                [string](Get-eMASIdentificationPropertyValue $_ 'targetEntityType') -eq $dimension -and
                $activeRuleIds.ContainsKey([string]$_.ruleId)
            })
            $dimensionRuleIds = @{}
            foreach ($output in $dimensionOutputs) { $dimensionRuleIds[[string]$output.ruleId] = $true }
            $dimensionRules = @($rules | Where-Object { $dimensionRuleIds.ContainsKey([string]$_.ruleId) } | Sort-Object ruleId)
            $fieldStates = @{}
            foreach ($condition in @($conditions | Where-Object { $dimensionRuleIds.ContainsKey([string]$_.ruleId) })) {
                $fieldCode = [string]$condition.fieldCode
                if (-not $fieldStates.ContainsKey($fieldCode)) { $fieldStates[$fieldCode] = Get-eMASIdentificationFieldState $fieldCode $subject $allEvidence $xmlDocuments $coverage }
            }
            $hits = New-Object System.Collections.ArrayList
            $unavailable = New-Object System.Collections.ArrayList
            $anyUnknown = $false
            foreach ($rule in $dimensionRules) {
                $evaluation = Invoke-eMASIdentificationRule $rule $groups $conditions $fieldStates
                foreach ($item in @($evaluation.Unavailable)) { [void]$unavailable.Add($item) }
                if ([string]$evaluation.State -eq 'Unknown') { $anyUnknown = $true }
                if ([string]$evaluation.State -ne 'True') { continue }
                foreach ($output in @($dimensionOutputs | Where-Object { [string]$_.ruleId -eq [string]$rule.ruleId } | Sort-Object sequence, ruleOutputId)) {
                    $declaredRank = [int]$strengthOrder[[string]$output.evidenceStrength]
                    $hitRank = $declaredRank
                    foreach ($trace in @($evaluation.Evidence)) {
                        $traceRank = [int]$strengthOrder[[string]$trace.NormalizedStrength]
                        if ($traceRank -gt $hitRank) { $hitRank = $traceRank }
                    }
                    [void]$hits.Add([pscustomobject]@{
                        OutputCode = [string]$output.outputCode; Polarity = [string]$output.evidencePolarity
                        Strength = Get-eMASIdentificationStrengthForRank $strengthOrder $hitRank
                        RuleId = [string]$rule.ruleId; Evidence = [object[]]@($evaluation.Evidence); StrengthCapped = ($hitRank -gt $declaredRank)
                    })
                }
            }
            $resolved = Resolve-eMASIdentificationDimension $dimensionRules @($hits) @($unavailable) $strengthOrder $conflictPolicy $confidencePolicies $anyUnknown
            $ordinal++
            [void]$resultRows.Add([pscustomobject][ordered]@{
                IdentificationId = 'IDR-{0:D4}' -f $ordinal
                SubjectType = 'Sequence'; SubjectId = [string]$subject.SubjectId; DossierId = [string]$subject.DossierId; Dimension = $dimension
                EvaluationStatus = [string]$resolved.EvaluationStatus; Value = $resolved.Value; ValueSet = $null
                Confidence = [string]$resolved.Confidence; ReviewRequired = [bool]$resolved.ReviewRequired; ValueSource = $resolved.ValueSource
                Candidates = [object[]]@($resolved.Candidates); SupportingEvidenceIds = [object[]]@($resolved.SupportingEvidenceIds)
                ContradictingEvidenceIds = [object[]]@($resolved.ContradictingEvidenceIds); UnavailableEvidence = [object[]]@($resolved.UnavailableEvidence)
                FiredRuleIds = [object[]]@($resolved.FiredRuleIds); ScoreSummary = $resolved.ScoreSummary; LimitingFactors = [object[]]@($resolved.LimitingFactors)
            })
        }
    }

    if ([string]::IsNullOrWhiteSpace($EvidenceSourceSha256)) { $EvidenceSourceSha256 = Get-eMASIdentificationObjectSha256 $InputResult }
    if ($EvidenceSourceSha256 -notmatch '^[0-9a-f]{64}$') { throw 'IDI-INPUT-005 EvidenceSourceSha256 must be a lowercase SHA-256 value.' }
    $runtimeHash = [string](Get-eMASIdentificationPropertyValue $RuntimeConfiguration 'FileHashSha256')
    if ([string]::IsNullOrWhiteSpace($runtimeHash)) { $runtimeHash = Get-eMASIdentificationObjectSha256 $raw }
    $metadata = $raw.configuration
    $completionStatus = $(if (@($resultRows | Where-Object { @($_.UnavailableEvidence).Count -gt 0 }).Count -gt 0) { 'CompletedWithEvidenceGaps' } else { 'Completed' })
    $result = [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.Identification/1.0'
        Execution = [pscustomobject][ordered]@{
            Capability = 'IdentificationInterpretation'; ExecutionId = [string]$InputResult.Execution.ExecutionId
            EngineVersion = $script:eMASIdentificationEngineVersion; StartedAtUtc = $startedAt.ToString('o'); CompletedAtUtc = [DateTime]::UtcNow.ToString('o'); CompletionStatus = $completionStatus
        }
        EvidenceSource = [pscustomobject][ordered]@{ ContractId = [string]$InputResult.ContractId; ExecutionId = [string]$InputResult.Execution.ExecutionId; DocumentSha256 = $EvidenceSourceSha256 }
        RuntimeConfig = [pscustomobject][ordered]@{ ConfigurationId = [string]$metadata.configurationId; SchemaVersion = [string]$metadata.schemaVersion; MappingVersion = [string]$metadata.mappingVersion; ExportType = [string]$metadata.exportType; Sha256 = $runtimeHash }
        Normalization = [pscustomobject][ordered]@{ PolicyId = 'EVIDENCE-STRENGTH-NORMALIZATION'; Version = '1'; Mapping = [pscustomobject][ordered]@{ Strong = 'STRONG'; Supporting = 'MEDIUM'; Weak = 'WEAK' } }
        FieldProjection = [pscustomobject][ordered]@{ PolicyId = 'CEC-FIELD-PROJECTION'; Version = '1' }
        Results = [object[]]@($resultRows)
    }
    if ($null -ne $resolvedOutputPath) { Write-eMASIdentificationResult $result $resolvedOutputPath }
    return $result
}

Export-ModuleMember -Function Invoke-eMASIdentificationInterpretation
