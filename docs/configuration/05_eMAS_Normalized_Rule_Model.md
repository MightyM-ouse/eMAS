# eMAS Normalized Rule Model

**Version:** 1.1  
**Status:** Approved design baseline  
**Effective date:** 2026-07-13  
**Owner:** Product Owner and Technical Architect  
**Decision references:** RM-001 through RM-027, REG-003, REG-004  
**Canonical logical-model references:** Normalized Relationship Matrix v1.0; Logical Data Dictionary v1.0

## 1. Core model

The mapping workbook and runtime JSON must keep the following concerns separate:

- rule identity and lifecycle;
- phase assignments;
- condition groups and conditions;
- outputs;
- fields and metrics;
- field/operator and field/phase relationships;
- findings;
- recommendations;
- finding-to-recommendation links;
- conflicts;
- exception policies;
- master data and relationships;
- aliases;
- thresholds and effort bands.

No comma-separated or free-text multi-value relationship is permitted where a relationship table is appropriate.

The [Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) is the authority for entity relationships, cardinality, temporal rules and endpoint types. The [Logical Data Dictionary](07_eMAS_Data_Dictionary.md) is the authority for fields, keys, data types and requiredness.

## 2. Rule identity

Every executable rule has a stable `RuleId` and an integer `RuleRevision`.

- Keep the same RuleId and revision for non-semantic wording or formatting corrections.
- Increment RuleRevision for clarifications that do not change business meaning.
- Create a new RuleId and supersession relationship when condition logic, severity, blocker meaning, output type, phase meaning or threshold value changes materially.
- Retired or superseded RuleIds must never be reused.

## 3. Lifecycle

Rule lifecycle codes are:

- Draft
- InReview
- Reviewed
- Effective
- Superseded
- Retired

Approved transition path:

`Draft → InReview → Reviewed → Effective`

Allowed subsequent transitions:

- `Reviewed → Draft` for rework;
- `Effective → Superseded` through an explicit supersession relationship;
- `Effective → Retired`.

No transition may skip review and move directly to Effective.

Runtime eligibility is calculated, not edited:

`Status = Effective AND EffectiveFrom <= execution date AND (EffectiveTo is empty OR execution date < EffectiveTo)`

Editable `IsActive` is prohibited as the primary lifecycle mechanism.

## 4. Phase assignments

A rule may behave differently in each phase. `Rule_Phase_Assignment` contains:

- RulePhaseId
- RuleId
- Phase
- EvaluationStatusOnMissingInput
- RAG
- Severity
- IsBlocker
- ExceptionEligible
- DecisionImpact
- OutputCode
- Sequence

Phase assignment overrides finding defaults for phase-specific RAG, severity, blocker and decision effects. Rule outputs add explicit outputs; they do not silently override phase assignment.

Every runtime-eligible rule has at least one explicit phase row. `All` is a workbook helper only and is expanded before export.

## 5. Field and metric applicability

Field and metric applicability is normalized through dedicated link entities:

- `Field_Operator_Links` — one row per allowed field/operator pair;
- `Field_Phase_Links` — one row per supported field/phase pair;
- `Metric_Phase_Links` — one row per supported metric/phase pair;
- `Effort_Driver_Phase_Links` — one row per effort-driver/phase pair.

Repeated comma-separated operator or phase cells are prohibited in the canonical model. Runtime JSON may serialize these link rows as arrays inside field or metric definitions where the schema requires nested representation.

## 6. Condition model

One condition is stored per row. Conditions contain:

- ConditionId
- RuleId
- ConditionGroupId
- Sequence
- FieldCode
- Operator
- Value1
- optional Value2
- ValueDataType
- CaseSensitive
- Negate

Within a group, conditions use AND. Separate groups for the same rule use OR. Schema 1.0.0 supports two logical levels only. Arbitrary VBA, PowerShell or expression-language code is prohibited in cells.

Every condition must reference:

- an existing condition group for the same RuleId;
- an Effective field definition;
- an operator explicitly allowed for that field;
- a phase-compatible field for every phase in which the rule is evaluated.

## 7. Outputs

Rule outputs are maintained separately and may include:

- ClassificationCandidate
- Finding
- RAG
- ConfidenceImpact
- EffortImpact
- DecisionImpact
- ClarificationTrigger

One rule may have multiple ordered outputs. `OutputType` is the discriminator that determines the permitted `OutputCode` target and `OutputValue` type.

`Rules.FindingCode`, where used, is the optional primary/default finding reference. Additional or phase-specific findings are emitted through `Rule_Outputs`. Complete finding definitions remain in `Findings`.

## 8. Findings and recommendations

A finding describes evidence or an evaluated outcome. A recommendation describes the action or guidance resulting from a finding.

They must remain separate and linked through `Finding_Recommendation_Links`. Customer-facing and consultant-facing recommendation text remain separate. A finding may link to multiple recommendations by phase, link type and sequence.

## 9. Evaluation status and RAG

Evaluation status:

- Evaluated
- NotAssessed
- NotApplicable
- Skipped
- Error
- InsufficientEvidence
- Conflict

RAG:

- Green
- Amber
- Red
- Unknown

`NotAssessed` and `NotApplicable` are never RAG values.

## 10. Conflicts

Lower numeric priority executes first. Priority values normally use increments of 100.

Supported conflict strategies:

- FirstMatch
- MostSpecific
- MostSevere
- Aggregate
- ErrorOnMultipleMatch
- HighestEvidenceScore
- ManualReview

Defaults:

- classification: HighestEvidenceScore;
- tied top classification: Unknown or ManualReview;
- folder/file findings: Aggregate;
- RAG aggregation: MostSevere;
- decisions: ordered FirstMatch with mandatory blocker override.

Unresolved conflicts must never be silently resolved.

## 11. Exceptions

The master configuration stores exception policies, not project-specific accepted exceptions.

Supported effects:

- AcknowledgeOnly
- RemoveBlock
- ExcludeFromScope
- AcceptDifference
- DowngradeDecisionImpact

An accepted exception may alter decision treatment but must never erase or replace the original finding, original RAG, original evaluation status or evidence. Carry-forward to post-migration defaults to false.

## 12. Thresholds and effort

Thresholds contain lower and upper bounds, inclusivity flags and unit. The default convention is lower-inclusive and upper-exclusive. Gaps, overlaps and duplicate bands fail validation where complete classification is required.

`Effort_Thresholds` uses `ThresholdScopeType + ThresholdScopeCode` to identify a driver or the approved overall model. Free-text mixed references such as `DriverCodeOrOverallModel` are not part of the frozen dictionary.

Effort uses a hybrid model:

- weighted driver score;
- mandatory minimum-band overrides for critical conditions;
- separately calculated effort confidence;
- customer-facing presentation of final band, confidence, primary drivers, assumptions and missing information;
- raw numeric score remains internal unless explicitly approved.

## 13. Classification dimensions

The normalized classification backbone is:

- Region
- Authority
- TechnicalStandard
- RegionalImplementation
- ProductDomain
- LifecycleContext
- ProductClass
- ProcedureContext where applicable
- SourcePresentation where applicable

ASMF is a ProcedureContext, not a technical format. Regional implementations are layered on technical standards. A report-level primary dossier type may be derived but is not maintained as a single authoring dimension.

Master-data relationship types and permitted endpoint pairs are frozen in the relationship matrix. Broad regional groupings must not act as regulatory authorities.

## 14. Aliases and polymorphic references

Aliases map approved alternate source names to canonical fields, controlled values or master-data codes. They must be scoped, versioned, traceable and validated. Alias resolution must not change raw evidence values.

Every polymorphic reference requires an explicit type discriminator. Approved polymorphic references include:

- Alias target type and code;
- Rule output type and output code;
- Effort-threshold scope type and code;
- Questionnaire trigger type and code;
- Decision-condition type and reference;
- validation-result entity type and ID.

Free-text polymorphic fields without a discriminator are prohibited in the frozen model.

## 15. Validation-run model

`Validation_Runs` is the parent execution record for validation evidence. `Validation_Results` belongs to one run, and `Export_History` must reference the completed validation run used for export.

A controlled export is prohibited when the referenced run:

- is incomplete;
- has blocking results;
- does not match the configuration, mapping, schema or workbook version being exported;
- does not satisfy the controlled validation profile.

## 16. Required implementation artifacts

The logical model is published as:

- [Logical Data Dictionary v1.0](07_eMAS_Data_Dictionary.md) — complete;
- [Normalized Relationship Matrix v1.0](06_eMAS_Normalized_Relationship_Matrix.md) — complete;
- entity-relationship diagram — pending architecture/model visualization stage;
- JSON relationship serialization — defined by Runtime JSON Contract and schema, fixture synchronization pending;
- generated Rule Index — implementation pending;
- representative end-to-end golden fixtures — pending schema-fixture stage;
- validation rules for keys, references, lifecycle, conditions, conflicts, thresholds and outputs — contract complete, implementation pending.

## 17. Freeze and change control

The logical relationship and data contracts are frozen at Version 1.0. A change to entity structure, key, field type, requiredness, relationship endpoint, cardinality or semantic code meaning requires:

- a DecisionId and requirement reference;
- Product Owner and Technical Architect approval;
- applicable Regulatory or Migration SME approval;
- JSON Schema compatibility assessment;
- XLSM/VBA, PowerShell, report and test impact analysis;
- updated valid and invalid fixtures;
- updated canonical and machine-readable indexes.

Adding approved content rows without changing structure or semantics does not change the logical-model version.

## 18. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Initial approved normalized rule model |
| 1.1 | 2026-07-13 | Bound rule behavior to frozen relationship, data-dictionary, link-entity, polymorphic-reference and validation-run contracts |
