#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$modulePath = Join-Path $repositoryRoot 'engine/core/eMAS.IdentificationInterpretation.psm1'
Import-Module -Name $modulePath -Force -ErrorAction Stop

$script:passed = 0
$script:failed = 0

function Assert-eMASTrue { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw $Message } }
function Assert-eMASEqual {
    param([AllowNull()][object] $Expected, [AllowNull()][object] $Actual, [string] $Message)
    if ($Expected -ne $Actual) { throw ('{0} Expected={1}; Actual={2}' -f $Message, $Expected, $Actual) }
}
function Assert-eMASNull { param([AllowNull()][object] $Value, [string] $Message) if ($null -ne $Value) { throw ('{0} Actual={1}' -f $Message, $Value) } }
function Invoke-eMASTest {
    param([Parameter(Mandatory = $true)][string] $Name, [Parameter(Mandatory = $true)][scriptblock] $Action)
    try {
        & $Action
        $script:passed++
        Write-Output ('[PASS] {0}' -f $Name)
    }
    catch {
        $script:failed++
        Write-Output ('[FAIL] {0}: {1} ({2})' -f $Name, $_.Exception.Message, $_.ScriptStackTrace)
    }
}

function Copy-eMASObject { param([Parameter(Mandatory = $true)][object] $Value) return (($Value | ConvertTo-Json -Depth 64) | ConvertFrom-Json) }
function Add-eMASProperty {
    param([Parameter(Mandatory = $true)][object] $Object, [Parameter(Mandatory = $true)][string] $Name, [AllowNull()][object] $Value)
    if ($null -ne $Object.PSObject.Properties[$Name]) { $Object.$Name = $Value }
    else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}

function New-eMASField {
    param(
        [Parameter(Mandatory = $true)][string] $Code,
        [Parameter(Mandatory = $true)][string[]] $Operators,
        [string] $DataType = 'String',
        [string] $MaximumStrength = 'STRONG'
    )
    return [pscustomobject][ordered]@{
        fieldCode = $Code
        displayName = $Code
        dataType = $DataType
        valueSource = 'Observed'
        allowedOperators = [object[]]$Operators
        supportedPhases = @('PRE_SALES')
        producingComponent = 'CLASSIFICATION_EVIDENCE_COLLECTION'
        evaluationOrder = 0
        isSensitive = $false
        maxEvidenceStrength = $MaximumStrength
    }
}

function New-eMASTestConfiguration {
    $path = Join-Path $repositoryRoot 'tests/fixtures/runtime-config/valid-minimal.json'
    $configuration = [System.IO.File]::ReadAllText($path) | ConvertFrom-Json
    $configuration.configuration.schemaVersion = '1.1.0'
    Add-eMASProperty -Object $configuration.configuration -Name 'exportType' -Value 'DEV'
    Add-eMASProperty -Object $configuration.configuration -Name 'sourceWorkbookVersion' -Value '1.1.0'
    Add-eMASProperty -Object $configuration.configuration -Name 'minimumEngineVersion' -Value '1.1.0'
    Add-eMASProperty -Object $configuration.configuration -Name 'exportedAtUtc' -Value '2026-10-06T00:00:00Z'
    Add-eMASProperty -Object $configuration.configuration -Name 'exportedBy' -Value 'SYNTHETIC_TEST'
    Add-eMASProperty -Object $configuration.configuration -Name 'validationRunId' -Value 'VAL-ID-ENGINE'

    Add-eMASProperty -Object $configuration.valueLists -Name 'EVIDENCE_STRENGTH' -Value @(
        [pscustomobject]@{ code = 'STRONG'; displayValue = 'Strong'; sortOrder = 1 },
        [pscustomobject]@{ code = 'MEDIUM'; displayValue = 'Medium'; sortOrder = 2 },
        [pscustomobject]@{ code = 'WEAK'; displayValue = 'Weak'; sortOrder = 3 }
    )
    $configuration.valueLists.CONFIDENCE = @(
        [pscustomobject]@{ code = 'HIGH'; displayValue = 'High'; sortOrder = 1 },
        [pscustomobject]@{ code = 'MEDIUM'; displayValue = 'Medium'; sortOrder = 2 },
        [pscustomobject]@{ code = 'LOW'; displayValue = 'Low'; sortOrder = 3 },
        [pscustomobject]@{ code = 'UNKNOWN'; displayValue = 'Unknown'; sortOrder = 4 }
    )
    Add-eMASProperty -Object $configuration.valueLists -Name 'IDENTIFICATION_DIMENSION' -Value @(
        [pscustomobject]@{ code = 'TECHNICAL_STANDARD'; displayValue = 'TechnicalStandard'; sortOrder = 1 },
        [pscustomobject]@{ code = 'REGION'; displayValue = 'Region'; sortOrder = 2 }
    )
    Add-eMASProperty -Object $configuration.valueLists -Name 'EVIDENCE_POLARITY' -Value @(
        [pscustomobject]@{ code = 'SUPPORTS'; displayValue = 'Supports' },
        [pscustomobject]@{ code = 'CONTRADICTS'; displayValue = 'Contradicts' }
    )

    $configuration.fieldCatalogue = @()
    $configuration.rules = @()
    $configuration.rulePhases = @()
    $configuration.conditionGroups = @()
    $configuration.ruleConditions = @()
    $configuration.ruleOutputs = @()
    $configuration.policies = [pscustomobject][ordered]@{
        conflictPolicies = @([pscustomobject][ordered]@{
            conflictPolicyId = 'CP-ID-001'; ruleType = 'IDENTIFICATION'; conflictStrategy = 'HighestEvidenceScore'; tieBehavior = 'MANUAL_REVIEW'; stopBehavior = 'CONTINUE'; defaultPriorityIncrement = 100; status = 'Effective'; description = 'Synthetic ordinal policy.'; minimumEvidenceStrengthForValue = 'MEDIUM'
        })
        ragPolicies = @()
        confidencePolicies = @(
            [pscustomobject][ordered]@{ confidencePolicyId = 'CONF-STRONG-NONE'; scope = 'IDENTIFICATION'; evidenceStrength = 'STRONG'; resultConfidence = 'MEDIUM'; corroborationRule = 'NONE_REQUIRED'; agreementRequirement = 'Synthetic'; missingEvidenceBehavior = 'LOWER_CONFIDENCE'; status = 'Effective'; effectiveFrom = '2026-10-06'; sourceReference = 'SYNTHETIC' },
            [pscustomobject][ordered]@{ confidencePolicyId = 'CONF-MEDIUM-NONE'; scope = 'IDENTIFICATION'; evidenceStrength = 'MEDIUM'; resultConfidence = 'LOW'; corroborationRule = 'NONE_REQUIRED'; agreementRequirement = 'Synthetic'; missingEvidenceBehavior = 'LOWER_CONFIDENCE'; status = 'Effective'; effectiveFrom = '2026-10-06'; sourceReference = 'SYNTHETIC' }
        )
        effortDrivers = @()
        effortThresholds = @()
        decisionPolicies = @()
    }
    return $configuration
}

function Add-eMASIdentificationRule {
    param(
        [Parameter(Mandatory = $true)][object] $Configuration,
        [Parameter(Mandatory = $true)][string] $RuleId,
        [Parameter(Mandatory = $true)][string] $Dimension,
        [Parameter(Mandatory = $true)][string] $Candidate,
        [Parameter(Mandatory = $true)][string] $Strength,
        [string] $Polarity = 'SUPPORTS',
        [Parameter(Mandatory = $true)][object[]] $Groups,
        [int] $Priority = 100
    )
    $Configuration.rules = @($Configuration.rules) + [pscustomobject][ordered]@{
        ruleId = $RuleId; ruleRevision = 1; ruleType = 'IDENTIFICATION'; title = $RuleId; description = $RuleId; status = 'Effective'; effectiveFrom = '2026-10-06'; priority = $Priority; conflictGroup = $Dimension; conflictStrategy = 'HighestEvidenceScore'; specificity = 1; stopProcessing = $false; requirementReference = 'SYNTHETIC'; sourceReference = 'SYNTHETIC'
    }
    $Configuration.rulePhases = @($Configuration.rulePhases) + [pscustomobject][ordered]@{
        rulePhaseId = 'RPH-' + $RuleId; ruleId = $RuleId; phase = 'PRE_SALES'; evaluationStatusOnMissingInput = 'NotAssessed'; isBlocker = $false; exceptionEligible = $false; sequence = $Priority
    }
    $groupIndex = 0
    foreach ($groupConditions in $Groups) {
        $groupId = 'CG-{0}-{1:D2}' -f $RuleId, $groupIndex
        $Configuration.conditionGroups = @($Configuration.conditionGroups) + [pscustomobject][ordered]@{ conditionGroupId = $groupId; ruleId = $RuleId; groupSequence = $groupIndex; groupOperator = 'AND' }
        $conditionIndex = 0
        foreach ($definition in @($groupConditions)) {
            $Configuration.ruleConditions = @($Configuration.ruleConditions) + [pscustomobject][ordered]@{
                conditionId = 'COND-{0}-{1:D2}-{2:D2}' -f $RuleId, $groupIndex, $conditionIndex
                ruleId = $RuleId
                conditionGroupId = $groupId
                sequence = $conditionIndex
                fieldCode = [string]$definition.FieldCode
                operator = [string]$definition.Operator
                value1 = $definition.Value1
                valueDataType = $(if ($null -ne $definition.PSObject.Properties['ValueDataType']) { [string]$definition.ValueDataType } else { 'String' })
                caseSensitive = $(if ($null -ne $definition.PSObject.Properties['CaseSensitive']) { [bool]$definition.CaseSensitive } else { $true })
                negate = $(if ($null -ne $definition.PSObject.Properties['Negate']) { [bool]$definition.Negate } else { $false })
            }
            $conditionIndex++
        }
        $groupIndex++
    }
    $Configuration.ruleOutputs = @($Configuration.ruleOutputs) + [pscustomobject][ordered]@{
        ruleOutputId = 'OUT-' + $RuleId; ruleId = $RuleId; phase = 'PRE_SALES'; outputType = 'ClassificationCandidate'; outputCode = $Candidate; sequence = 0; targetEntityType = $Dimension; evidenceStrength = $Strength; evidencePolarity = $Polarity
    }
}

function New-eMASEvidence {
    param(
        [Parameter(Mandatory = $true)][string] $Id,
        [Parameter(Mandatory = $true)][string] $Type,
        [AllowNull()][object] $Value,
        [string] $Strength = 'Strong',
        [string] $Dimension = 'TechnicalFormat',
        [string] $SourceTier = 'StructuredXml',
        [string] $CaptureStatus = 'Available',
        [string] $SequenceId = 'SEQ-0001',
        [string] $DossierId = 'DOS-0001',
        [string] $RelativePath = 'dossier/0000/index.xml'
    )
    return [pscustomobject][ordered]@{
        EvidenceId = $Id; Dimension = $Dimension; CandidateValue = $null; EvidenceType = $Type; RelativePath = $RelativePath; ObservedValue = $Value; Strength = $Strength; Polarity = $null; SourceRuleId = $null; CaptureStatus = $CaptureStatus; DossierId = $DossierId; SequenceId = $SequenceId; XmlId = 'XML-0001'; SubjectType = 'XmlDocument'; SourceTier = $SourceTier; SequenceFolder = '0000'; SequenceRelativePath = 'index.xml'; SourceCapability = 'BackboneXmlInventory'; SourceField = 'XmlDocuments.RootElement'
    }
}

function New-eMASTestInput {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Evidence, [string] $CollectionStatus = 'Collected')
    return [pscustomobject][ordered]@{
        ContractId = 'eMAS.MS04.PreSales.ScannerObservations/1.0'
        Execution = [pscustomobject][ordered]@{ ExecutionId = 'EXEC-ID-TEST'; Phase = 'PreSales'; ScenarioId = 'MS-04'; Capabilities = @('RepositoryDiscovery', 'BackboneXmlInventory', 'ClassificationEvidenceCollection') }
        Repository = [pscustomobject][ordered]@{ SourceKind = 'Directory'; ResolvedSourcePath = Join-Path ([System.IO.Path]::GetTempPath()) 'emas-identification-source' }
        DossierCandidates = @([pscustomobject][ordered]@{ DossierId = 'DOS-0001'; RelativePath = 'dossier' })
        Sequences = @([pscustomobject][ordered]@{ SequenceId = 'SEQ-0001'; DossierId = 'DOS-0001'; RelativePath = 'dossier/0000' })
        XmlDocuments = @([pscustomobject][ordered]@{ XmlId = 'XML-0001'; DossierId = 'DOS-0001'; SequenceId = 'SEQ-0001'; XmlKind = 'CommonBackbone'; CaptureStatus = 'Available' })
        ClassificationEvidence = [object[]]$Evidence
        CollectionCoverage = @(
            [pscustomobject][ordered]@{ CheckId = 'ClassificationEvidenceCollection'; SubjectType = 'XmlDocument'; SubjectId = 'XML-0001'; CaptureStatus = $(if ($CollectionStatus -eq 'Collected') { 'Available' } else { 'InputUnavailable' }); CollectionStatus = $CollectionStatus; RecordsProduced = $Evidence.Count; ReasonCode = $null },
            [pscustomobject][ordered]@{ CheckId = 'ClassificationEvidenceCollection'; SubjectType = 'Repository'; SubjectId = 'REP-0001'; CaptureStatus = $(if ($CollectionStatus -eq 'Collected') { 'Available' } else { 'InputUnavailable' }); CollectionStatus = $CollectionStatus; RecordsProduced = $Evidence.Count; ReasonCode = $null }
        )
    }
}

function New-eMASCondition {
    param([string] $FieldCode, [string] $Operator, [AllowNull()][object] $Value1, [bool] $Negate = $false, [bool] $CaseSensitive = $true, [string] $ValueDataType = 'String')
    return [pscustomobject]@{ FieldCode = $FieldCode; Operator = $Operator; Value1 = $Value1; Negate = $Negate; CaseSensitive = $CaseSensitive; ValueDataType = $ValueDataType }
}

function New-eMASSingleRuleScenario {
    param(
        [Parameter(Mandatory = $true)][object] $Field,
        [Parameter(Mandatory = $true)][object] $Condition,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $Evidence,
        [string] $Strength = 'STRONG',
        [string] $Polarity = 'SUPPORTS',
        [string] $Candidate = 'ICH_ECTD_3_2_2',
        [string] $Dimension = 'TECHNICAL_STANDARD',
        [string] $CollectionStatus = 'Collected'
    )
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @($Field)
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-RULE-001' -Dimension $Dimension -Candidate $Candidate -Strength $Strength -Polarity $Polarity -Groups @(,@($Condition))
    $inputResult = New-eMASTestInput -Evidence $Evidence -CollectionStatus $CollectionStatus
    return [pscustomobject]@{ Configuration = $configuration; Input = $inputResult }
}

Invoke-eMASTest -Name 'normalization provenance and EvidenceId traceability' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0001' -Type 'XmlRootElement' -Value 'ectd'))
    $result = Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration
    Assert-eMASEqual 'EVIDENCE-STRENGTH-NORMALIZATION' $result.Normalization.PolicyId 'Normalization policy differs.'
    Assert-eMASEqual '1' $result.Normalization.Version 'Normalization version differs.'
    Assert-eMASEqual 'Strong' $result.Results[0].Candidates[0].SupportingEvidence[0].RawStrength 'Raw strength changed.'
    Assert-eMASEqual 'STRONG' $result.Results[0].Candidates[0].SupportingEvidence[0].NormalizedStrength 'Normalized strength differs.'
    Assert-eMASEqual 'EVD-0001' $result.Results[0].Candidates[0].SupportingEvidence[0].EvidenceId 'Evidence trace differs.'
}

Invoke-eMASTest -Name 'Supporting normalizes to MEDIUM' -Action {
    $field = New-eMASField -Code 'CEC_COMMON_BACKBONE_PRESENCE' -Operators @('EQUALS') -DataType 'Boolean' -MaximumStrength 'MEDIUM'
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 $true -ValueDataType 'Boolean') -Evidence @((New-eMASEvidence -Id 'EVD-0002' -Type 'CommonBackbonePresence' -Value $true -Strength 'Supporting')) -Strength 'MEDIUM'
    $result = Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration
    Assert-eMASEqual 'MEDIUM' $result.Results[0].Candidates[0].SupportingEvidence[0].NormalizedStrength 'Supporting was not normalized to MEDIUM.'
    Assert-eMASEqual 'Evaluated' $result.Results[0].EvaluationStatus 'Medium evidence did not satisfy floor.'
}

Invoke-eMASTest -Name 'Weak-only candidate remains visible below floor' -Action {
    $field = New-eMASField -Code 'CEC_DOSSIER_ROOT_PATH' -Operators @('CONTAINS') -MaximumStrength 'WEAK'
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'CONTAINS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0003' -Type 'DossierRootPath' -Value 'ectd-dossier' -Strength 'Weak' -SourceTier 'FolderNameHeuristic' -SequenceId '')) -Strength 'WEAK'
    $result = Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration
    Assert-eMASEqual 'InsufficientEvidence' $result.Results[0].EvaluationStatus 'Weak floor status differs.'
    Assert-eMASNull $result.Results[0].Value 'Weak candidate produced a final value.'
    Assert-eMASEqual 1 @($result.Results[0].Candidates).Count 'Weak candidate was discarded.'
    Assert-eMASEqual 'UNKNOWN' $result.Results[0].Confidence 'Weak confidence differs.'
}

Invoke-eMASTest -Name 'AND OR and negated guard semantics' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @(
        (New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')),
        (New-eMASField -Code 'CEC_DOSSIER_ROOT_PATH' -Operators @('CONTAINS') -MaximumStrength 'WEAK')
    )
    $failing = @((New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'wrong'))
    $firing = @(
        (New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'),
        (New-eMASCondition -FieldCode 'CEC_DOSSIER_ROOT_PATH' -Operator 'CONTAINS' -Value1 'draft' -Negate $true)
    )
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-OR-001' -Dimension 'TECHNICAL_STANDARD' -Candidate 'ICH_ECTD_3_2_2' -Strength 'STRONG' -Groups @($failing, $firing)
    $input = New-eMASTestInput -Evidence @(
        (New-eMASEvidence -Id 'EVD-0010' -Type 'XmlRootElement' -Value 'ectd'),
        (New-eMASEvidence -Id 'EVD-0011' -Type 'DossierRootPath' -Value 'approved-dossier' -Strength 'Weak' -SourceTier 'FolderNameHeuristic' -SequenceId '')
    )
    $result = Invoke-eMASIdentificationInterpretation -InputResult $input -RuntimeConfiguration $configuration
    Assert-eMASEqual 'Evaluated' $result.Results[0].EvaluationStatus 'OR branch did not fire.'
    Assert-eMASEqual 1 @($result.Results[0].Candidates[0].SupportingEvidence).Count 'Negated guard fabricated positive evidence.'
    Assert-eMASEqual 'EVD-0010' $result.Results[0].Candidates[0].SupportingEvidence[0].EvidenceId 'Wrong fired-group evidence cited.'
}

Invoke-eMASTest -Name 'assessed MISSING differs from not collected' -Action {
    $field = New-eMASField -Code 'CEC_COMMON_BACKBONE_PRESENCE' -Operators @('MISSING') -DataType 'Boolean' -MaximumStrength 'MEDIUM'
    $condition = New-eMASCondition -FieldCode $field.fieldCode -Operator 'MISSING' -Value1 $null -ValueDataType 'Boolean'
    $presentAbsence = New-eMASSingleRuleScenario -Field $field -Condition $condition -Evidence @() -Strength 'MEDIUM'
    $absentResult = Invoke-eMASIdentificationInterpretation -InputResult $presentAbsence.Input -RuntimeConfiguration $presentAbsence.Configuration
    Assert-eMASEqual 'Evaluated' $absentResult.Results[0].EvaluationStatus 'Assessed absence did not satisfy MISSING.'

    $notCollected = New-eMASSingleRuleScenario -Field $field -Condition $condition -Evidence @() -Strength 'MEDIUM' -CollectionStatus 'NotAssessed'
    $notCollectedResult = Invoke-eMASIdentificationInterpretation -InputResult $notCollected.Input -RuntimeConfiguration $notCollected.Configuration
    Assert-eMASEqual 'NotAssessed' $notCollectedResult.Results[0].EvaluationStatus 'Not-collected input became assessed absence.'
    Assert-eMASTrue (@($notCollectedResult.Results[0].UnavailableEvidence).Count -gt 0) 'Unavailable evidence was not retained.'
}

Invoke-eMASTest -Name 'stronger candidate beats weaker candidate' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @(
        (New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')),
        (New-eMASField -Code 'CEC_COMMON_BACKBONE_PRESENCE' -Operators @('EQUALS') -DataType 'Boolean' -MaximumStrength 'MEDIUM')
    )
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-STRONG' -Dimension 'TECHNICAL_STANDARD' -Candidate 'STRONG_VALUE' -Strength 'STRONG' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd')))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-MEDIUM' -Dimension 'TECHNICAL_STANDARD' -Candidate 'MEDIUM_VALUE' -Strength 'MEDIUM' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_COMMON_BACKBONE_PRESENCE' -Operator 'EQUALS' -Value1 $true -ValueDataType 'Boolean')))
    $input = New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0030' -Type 'XmlRootElement' -Value 'ectd'), (New-eMASEvidence -Id 'EVD-0031' -Type 'CommonBackbonePresence' -Value $true -Strength 'Supporting'))
    $result = Invoke-eMASIdentificationInterpretation -InputResult $input -RuntimeConfiguration $configuration
    Assert-eMASEqual 'STRONG_VALUE' $result.Results[0].Value 'Ordinal winner differs.'
}

Invoke-eMASTest -Name 'Medium beats Weak' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @(
        (New-eMASField -Code 'CEC_COMMON_BACKBONE_PRESENCE' -Operators @('EQUALS') -DataType 'Boolean' -MaximumStrength 'MEDIUM'),
        (New-eMASField -Code 'CEC_DOSSIER_ROOT_PATH' -Operators @('CONTAINS') -MaximumStrength 'WEAK')
    )
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-MEDIUM' -Dimension 'TECHNICAL_STANDARD' -Candidate 'MEDIUM_VALUE' -Strength 'MEDIUM' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_COMMON_BACKBONE_PRESENCE' -Operator 'EQUALS' -Value1 $true -ValueDataType 'Boolean')))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-WEAK' -Dimension 'TECHNICAL_STANDARD' -Candidate 'WEAK_VALUE' -Strength 'WEAK' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_DOSSIER_ROOT_PATH' -Operator 'CONTAINS' -Value1 'dossier')))
    $input = New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0040' -Type 'CommonBackbonePresence' -Value $true -Strength 'Supporting'), (New-eMASEvidence -Id 'EVD-0041' -Type 'DossierRootPath' -Value 'dossier' -Strength 'Weak' -SourceTier 'FolderNameHeuristic' -SequenceId ''))
    $result = Invoke-eMASIdentificationInterpretation -InputResult $input -RuntimeConfiguration $configuration
    Assert-eMASEqual 'MEDIUM_VALUE' $result.Results[0].Value 'Medium did not beat Weak.'
}

Invoke-eMASTest -Name 'equal-tier candidates conflict' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
    $condition = New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-A' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-B' -Dimension 'TECHNICAL_STANDARD' -Candidate 'B' -Strength 'STRONG' -Groups @(,@($condition))
    $result = Invoke-eMASIdentificationInterpretation -InputResult (New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0050' -Type 'XmlRootElement' -Value 'ectd'))) -RuntimeConfiguration $configuration
    Assert-eMASEqual 'Conflict' $result.Results[0].EvaluationStatus 'Tie did not conflict.'
    Assert-eMASNull $result.Results[0].Value 'Tie produced a value.'
}

Invoke-eMASTest -Name 'equal-tier support and contradiction conflict' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
    $condition = New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-SUPPORT' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-CONTRADICT' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Polarity 'CONTRADICTS' -Groups @(,@($condition))
    $result = Invoke-eMASIdentificationInterpretation -InputResult (New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0060' -Type 'XmlRootElement' -Value 'ectd'))) -RuntimeConfiguration $configuration
    Assert-eMASEqual 'Conflict' $result.Results[0].EvaluationStatus 'Contradiction did not conflict.'
    Assert-eMASEqual 1 @($result.Results[0].Candidates[0].ContradictingRuleIds).Count 'Contradicting rule was not retained.'
}

Invoke-eMASTest -Name 'candidate merges multiple supporting rules' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
    $condition = New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-MERGE-A' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-MERGE-B' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition))
    $result = Invoke-eMASIdentificationInterpretation -InputResult (New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0070' -Type 'XmlRootElement' -Value 'ectd'))) -RuntimeConfiguration $configuration
    Assert-eMASEqual 1 @($result.Results[0].Candidates).Count 'Candidate did not merge.'
    Assert-eMASEqual 2 @($result.Results[0].Candidates[0].SupportingRuleIds).Count 'Supporting RuleIds were not preserved.'
}

Invoke-eMASTest -Name 'same code remains dimension scoped' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
    $condition = New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-DIM-TS' -Dimension 'TECHNICAL_STANDARD' -Candidate 'OTHER' -Strength 'STRONG' -Groups @(,@($condition))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-DIM-REGION' -Dimension 'REGION' -Candidate 'OTHER' -Strength 'STRONG' -Groups @(,@($condition))
    $result = Invoke-eMASIdentificationInterpretation -InputResult (New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0080' -Type 'XmlRootElement' -Value 'ectd'))) -RuntimeConfiguration $configuration
    Assert-eMASEqual 2 @($result.Results).Count 'Dimensions were globally deduplicated.'
    Assert-eMASEqual 'OTHER' @($result.Results | Where-Object { $_.Dimension -eq 'REGION' })[0].Value 'Region value differs.'
    Assert-eMASEqual 'OTHER' @($result.Results | Where-Object { $_.Dimension -eq 'TECHNICAL_STANDARD' })[0].Value 'Technical standard value differs.'
}

Invoke-eMASTest -Name 'independent source classes satisfy confidence policy' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.policies.confidencePolicies = @([pscustomobject][ordered]@{ confidencePolicyId = 'CONF-STRONG-INDEPENDENT'; scope = 'IDENTIFICATION'; evidenceStrength = 'STRONG'; resultConfidence = 'HIGH'; corroborationRule = 'INDEPENDENT_SOURCE_CLASS'; agreementRequirement = 'Synthetic'; missingEvidenceBehavior = 'LOWER_CONFIDENCE'; status = 'Effective'; effectiveFrom = '2026-10-06'; sourceReference = 'SYNTHETIC' })
    $configuration.fieldCatalogue = @(
        (New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')),
        (New-eMASField -Code 'CEC_SUBMISSION_UNIT_MARKER' -Operators @('EXISTS'))
    )
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-CONF-A' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd')))
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-CONF-B' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_SUBMISSION_UNIT_MARKER' -Operator 'EXISTS' -Value1 $null)))
    $evidence = @(
        (New-eMASEvidence -Id 'EVD-0090' -Type 'XmlRootElement' -Value 'ectd' -SourceTier 'StructuredXml'),
        (New-eMASEvidence -Id 'EVD-0091' -Type 'SubmissionUnitMarkerFile' -Value 'submissionunit.xml' -SourceTier 'OfficialPhysicalPath')
    )
    $result = Invoke-eMASIdentificationInterpretation -InputResult (New-eMASTestInput -Evidence $evidence) -RuntimeConfiguration $configuration
    Assert-eMASEqual 'HIGH' $result.Results[0].Confidence 'Independent-source confidence differs.'
    Assert-eMASEqual 2 $result.Results[0].ScoreSummary.IndependentSourceClassCount 'Source-class count differs.'
}

Invoke-eMASTest -Name 'result is separate and excludes prohibited fields and numeric score' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0100' -Type 'XmlRootElement' -Value 'ectd'))
    $result = Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration
    $json = $result | ConvertTo-Json -Depth 64 -Compress
    Assert-eMASEqual 'eMAS.MS04.PreSales.Identification/1.0' $result.ContractId 'Result contract differs.'
    Assert-eMASTrue (-not $json.Contains('"Outcome"')) 'Outcome is prohibited.'
    Assert-eMASTrue (-not $json.Contains('"SupportStatus"')) 'SupportStatus is prohibited.'
    Assert-eMASTrue (-not $json.Contains('NumericScore')) 'NumericScore was emitted.'
}

Invoke-eMASTest -Name 'input order does not change semantic results or IDs' -Action {
    $configuration = New-eMASTestConfiguration
    $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
    $condition = New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd'
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-Z' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition)) -Priority 200
    Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-A' -Dimension 'TECHNICAL_STANDARD' -Candidate 'A' -Strength 'STRONG' -Groups @(,@($condition)) -Priority 100
    $inputA = New-eMASTestInput -Evidence @((New-eMASEvidence -Id 'EVD-0111' -Type 'XmlRootElement' -Value 'ectd'), (New-eMASEvidence -Id 'EVD-0110' -Type 'XmlRootElement' -Value 'ectd'))
    $inputB = Copy-eMASObject -Value $inputA
    $inputB.ClassificationEvidence = @($inputB.ClassificationEvidence | Sort-Object EvidenceId)
    $configurationB = Copy-eMASObject -Value $configuration
    $configurationB.rules = @($configurationB.rules | Sort-Object ruleId -Descending)
    $first = Invoke-eMASIdentificationInterpretation -InputResult $inputA -RuntimeConfiguration $configuration
    $second = Invoke-eMASIdentificationInterpretation -InputResult $inputB -RuntimeConfiguration $configurationB
    Assert-eMASEqual ($first.Results | ConvertTo-Json -Depth 64 -Compress) ($second.Results | ConvertTo-Json -Depth 64 -Compress) 'Semantic output is not deterministic.'
}

Invoke-eMASTest -Name 'scanner and runtime inputs remain immutable' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0120' -Type 'XmlRootElement' -Value 'ectd'))
    $inputBefore = $scenario.Input | ConvertTo-Json -Depth 64 -Compress
    $configBefore = $scenario.Configuration | ConvertTo-Json -Depth 64 -Compress
    [void](Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration)
    Assert-eMASEqual $inputBefore ($scenario.Input | ConvertTo-Json -Depth 64 -Compress) 'Scanner evidence was mutated.'
    Assert-eMASEqual $configBefore ($scenario.Configuration | ConvertTo-Json -Depth 64 -Compress) 'Runtime configuration was mutated.'
}

Invoke-eMASTest -Name 'invalid scanner contract and missing CEC capability are rejected' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0130' -Type 'XmlRootElement' -Value 'ectd'))
    $badContract = Copy-eMASObject -Value $scenario.Input
    $badContract.ContractId = 'unsupported'
    $message = $null
    try { [void](Invoke-eMASIdentificationInterpretation -InputResult $badContract -RuntimeConfiguration $scenario.Configuration) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue ($message -like 'IDI-INPUT-001*') 'Invalid scanner contract was not rejected.'
    $missingCapability = Copy-eMASObject -Value $scenario.Input
    $missingCapability.Execution.Capabilities = @('RepositoryDiscovery')
    $message = $null
    try { [void](Invoke-eMASIdentificationInterpretation -InputResult $missingCapability -RuntimeConfiguration $scenario.Configuration) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue ($message -like 'IDI-INPUT-003*') 'Missing CEC capability was not rejected.'
}

Invoke-eMASTest -Name 'Schema 1.0 runtime config is rejected before interpretation' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0140' -Type 'XmlRootElement' -Value 'ectd'))
    $scenario.Configuration.configuration.schemaVersion = '1.0.0'
    $message = $null
    try { [void](Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue ($message -like 'IDI-CONFIG-001*') 'Schema 1.0 config was not rejected.'
}

Invoke-eMASTest -Name 'unmapped raw strength is unavailable and preserved' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0150' -Type 'XmlRootElement' -Value 'ectd' -Strength 'VeryStrong'))
    $before = $scenario.Input.ClassificationEvidence[0].Strength
    $result = Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration
    Assert-eMASEqual 'NotAssessed' $result.Results[0].EvaluationStatus 'Unmapped strength was interpreted.'
    Assert-eMASEqual 'UnmappedStrength' $result.Results[0].UnavailableEvidence[0].Reason 'Unmapped reason differs.'
    Assert-eMASEqual $before $scenario.Input.ClassificationEvidence[0].Strength 'Raw strength was rewritten.'
}

Invoke-eMASTest -Name 'output is UTF-8 without BOM and path safety is enforced' -Action {
    $field = New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')
    $scenario = New-eMASSingleRuleScenario -Field $field -Condition (New-eMASCondition -FieldCode $field.fieldCode -Operator 'EQUALS' -Value1 'ectd') -Evidence @((New-eMASEvidence -Id 'EVD-0160' -Type 'XmlRootElement' -Value 'ectd'))
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-identification-{0}' -f [guid]::NewGuid().ToString('N'))
    [void][System.IO.Directory]::CreateDirectory($temporaryRoot)
    try {
        $outputPath = Join-Path $temporaryRoot 'identification.json'
        [void](Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration -OutputPath $outputPath)
        $bytes = [System.IO.File]::ReadAllBytes($outputPath)
        Assert-eMASTrue (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) 'Output contains a UTF-8 BOM.'
        $unsafePath = Join-Path ([string]$scenario.Input.Repository.ResolvedSourcePath) 'identification.json'
        $message = $null
        try { [void](Invoke-eMASIdentificationInterpretation -InputResult $scenario.Input -RuntimeConfiguration $scenario.Configuration -OutputPath $unsafePath) } catch { $message = $_.Exception.Message }
        Assert-eMASTrue ($message -like 'IDI-OUTPUT-003*') 'Source-directory output path was not rejected.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

Invoke-eMASTest -Name 'Pre-Sales opt-in requires RuntimeConfigurationPath' -Action {
    $entryScript = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
    $message = $null
    try { [void](& $entryScript -SourcePath ([System.IO.Path]::GetTempPath()) -OutputPath (Join-Path ([System.IO.Path]::GetTempPath()) 'unused-identification.json') -ExecutionId 'EXEC-ID-NO-CONFIG' -IncludeIdentificationInterpretation) } catch { $message = $_.Exception.Message }
    Assert-eMASTrue ($message -like 'ID-SCRIPT-001*') 'Entry script did not require RuntimeConfigurationPath.'
}

Invoke-eMASTest -Name 'Pre-Sales opt-in emits separate Identification contract' -Action {
    $entryScript = Join-Path $repositoryRoot 'scripts/eMAS-PreSalesAssessment.ps1'
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('emas-identification-entry-{0}' -f [guid]::NewGuid().ToString('N'))
    $sourceRoot = Join-Path $temporaryRoot 'source'
    $outputRoot = Join-Path $temporaryRoot 'output'
    [void][System.IO.Directory]::CreateDirectory($sourceRoot)
    [void][System.IO.Directory]::CreateDirectory($outputRoot)
    try {
        $configuration = New-eMASTestConfiguration
        $configuration.fieldCatalogue = @((New-eMASField -Code 'CEC_XML_ROOT_ELEMENT_COMMON' -Operators @('EQUALS')))
        Add-eMASIdentificationRule -Configuration $configuration -RuleId 'ID-ENTRY-001' -Dimension 'TECHNICAL_STANDARD' -Candidate 'ICH_ECTD_3_2_2' -Strength 'STRONG' -Groups @(,@((New-eMASCondition -FieldCode 'CEC_XML_ROOT_ELEMENT_COMMON' -Operator 'EQUALS' -Value1 'ectd')))
        $configurationPath = Join-Path $temporaryRoot 'runtime.json'
        $outputPath = Join-Path $outputRoot 'identification.json'
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($configurationPath, ($configuration | ConvertTo-Json -Depth 64), $encoding)
        $result = & $entryScript -SourcePath $sourceRoot -OutputPath $outputPath -ExecutionId 'EXEC-ID-ENTRY' -RuntimeConfigurationPath $configurationPath -IncludeIdentificationInterpretation
        Assert-eMASEqual 'eMAS.MS04.PreSales.Identification/1.0' $result.ContractId 'Entry script returned the scanner contract.'
        Assert-eMASTrue ([System.IO.File]::Exists($outputPath)) 'Entry script did not persist Identification output.'
        $persisted = [System.IO.File]::ReadAllText($outputPath) | ConvertFrom-Json
        Assert-eMASEqual 'eMAS.MS04.PreSales.Identification/1.0' $persisted.ContractId 'Persisted contract differs.'
    }
    finally {
        if ([System.IO.Directory]::Exists($temporaryRoot)) { [System.IO.Directory]::Delete($temporaryRoot, $true) }
    }
}

$total = $script:passed + $script:failed
Write-Output ('IdentificationInterpretation engine tests completed: {0} total, {1} passed, {2} failed.' -f $total, $script:passed, $script:failed)
if ($script:failed -gt 0) { exit 1 }
