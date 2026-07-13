# eMAS Mapping and Configuration Workbook — Logical Content Catalogue

**Version:** 3.1  
**Status:** Approved

## 1. Common entity rules

Every controlled entity has a stable uppercase identifier, lifecycle/status where applicable, effective dates, owner/reviewer data, source reference and description. IDs are never reused.

## 2. Rule core

### Rule header

`RuleId`, `RuleRevision`, `RuleType`, `Title`, `Description`, `Status`, `EffectiveFrom`, `EffectiveTo`, `Priority`, `ConflictGroup`, `ConflictStrategy`, `Specificity`, `StopProcessing`, `FindingCode`, `RequirementReference`, `SourceReference`, `Comment`.

Specificity is calculated as populated applicability dimensions × 100 plus condition count, with controlled override only by justified exception.

### Rule phase assignment

`RulePhaseId`, `RuleId`, `Phase`, `EvaluationStatusOnMissingInput`, `RAG`, `Severity`, `IsBlocker`, `ExceptionEligible`, `DecisionImpact`, `OutputCode`, `Sequence`.

### Conditions

`ConditionId`, `RuleId`, `GroupId`, `Sequence`, `FieldCode`, `Operator`, `Value1`, `Value2`, `ValueDataType`, `CaseSensitive`, `Negate`, `Comment`.

### Outputs

`RuleOutputId`, `RuleId`, `Phase`, `OutputType`, `OutputCode`, typed payload, `Sequence`, `Comment`.

Approved output types: ClassificationCandidate, Finding, RAG, ConfidenceImpact, EffortImpact, DecisionImpact and ClarificationTrigger.

## 3. Master data dimensions

### Classification backbone

- Region
- Authority
- TechnicalStandard
- RegionalImplementation
- ProcedureContext
- SourcePresentation
- ProductDomain
- LifecycleContext
- ProductClass

`PrimaryDossierType` may be derived for display but is never the normalized storage dimension.

### Region types

RegulatoryJurisdiction, RegionalOrganisation, InternalGrouping, Other, Unknown.

Broad groups such as MENA, LATAM and RestOfEurope are InternalGrouping values and do not directly authorize authority-specific folder rules.

### Initial controlled taxonomy direction

- TechnicalStandard: ICH eCTD 3.2.2, eCTD 4.0, NeeS, VNeeS, Non-eCTD Electronic.
- RegionalImplementation: EU eCTD, US FDA eCTD, Canada eCTD, UK eCTD, Swiss eCTD, GCC eCTD, EAEU eCTD.
- ProcedureContext: ASMF and later approved procedures.
- SourcePresentation: Native Electronic, Scanned Paper, Mixed, Unknown.
- ProductDomain: Human, Veterinary, MedicalDevice, Other, Unknown.
- LifecycleContext: Investigational, PostMarketing, Other, Unknown.
- ProductClass: SmallMolecule, Biologic, Vaccine, BloodProduct, Other, Unknown.

## 4. Relationships

Dedicated link tables are mandatory for:

- Authority–Region;
- Authority–RegionalImplementation;
- TechnicalStandard–RegionalImplementation;
- ProductDomain–TechnicalStandard;
- ProductDomain–Region;
- LifecycleContext–TechnicalStandard;
- ProductClass–TechnicalStandard.

Active non-Other/non-Unknown values must satisfy minimum relationship coverage rules.

## 5. Field and metric catalogues

### Field_Catalogue

FieldCode, DisplayName, DataType, SourceType, AllowedOperators, SupportedPhases, ProducingComponent, EvaluationOrder and Description.

### Metric_Catalogue

MetricCode, DisplayName, DataType, Unit, CalculationSource, SupportedPhases, RequiredForCompleteBanding, RoundingRule and Description.

Unknown fields block export.

## 6. Findings and recommendations

### Finding

FindingCode, Title, Category, DefaultRAG, DefaultSeverity, ExceptionEligible, Description.

### Recommendation

RecommendationCode, CustomerFacingText, ConsultantFacingText, Status, Effective dates and source.

### Link

LinkId, FindingCode, RecommendationCode, Phase, LinkType, Sequence.

## 7. Exceptions

Policy fields include ExceptionPolicyId, eligible finding, allowed effect, required role, evidence requirement, expiry requirement, scope type and carry-forward permission.

Allowed effects:

- AcknowledgeOnly;
- RemoveBlock;
- ExcludeFromScope;
- AcceptDifference;
- DowngradeDecisionImpact.

Carry-forward defaults to false.

## 8. Aliases

Aliases are typed, lifecycle-controlled and SME-approved. Collisions block export. The engine applies aliases during normalization and logs every use.

## 9. Regulatory profile matrices

Folder, file, XML and extension requirements are maintained per profile composed from TechnicalStandard, RegionalImplementation and ProcedureContext. Requirements support Mandatory, Optional, Conditional, Prohibited and NotApplicable plus phase-specific severity and blocker effects.

eCTD v4.0 v1 support is detect-and-classify only.

## 10. Proof of concept

Before mass content population, one end-to-end example is required for each rule category and relationship type through:

`Excel table → VBA normalized object → JSON → schema validation → PowerShell loader → report result`.
