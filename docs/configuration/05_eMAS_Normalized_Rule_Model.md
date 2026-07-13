# eMAS Normalized Rule Model

**Status:** Approved design baseline  
**Effective date:** 2026-07-13  
**Decision references:** RM-001 through RM-027, REG-003, REG-004

## 1. Core model

The mapping workbook and runtime JSON must keep the following concerns separate:

- rule identity and lifecycle;
- phase assignments;
- condition groups and conditions;
- outputs;
- fields and metrics;
- findings;
- recommendations;
- finding-to-recommendation links;
- conflicts;
- exception policies;
- master data and relationships;
- aliases;
- thresholds and effort bands.

No comma-separated or free-text multi-value relationship is permitted where a relationship table is appropriate.

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

## 5. Condition model

One condition is stored per row. Conditions contain:

- ConditionId
- RuleId
- GroupId
- Sequence
- FieldCode
- Operator
- Value1
- optional Value2
- value data type
- case-sensitivity flag
- negation flag

Within a group, conditions use AND. Separate groups for the same rule use OR. Schema 1.0.0 supports two logical levels only. Arbitrary VBA, PowerShell or expression-language code is prohibited in cells.

## 6. Outputs

Rule outputs are maintained separately and may include:

- ClassificationCandidate
- Finding
- RAG
- ConfidenceImpact
- EffortImpact
- DecisionImpact
- ClarificationTrigger

One rule may have multiple ordered outputs.

## 7. Findings and recommendations

A finding describes evidence or an evaluated outcome. A recommendation describes the action or guidance resulting from a finding.

They must remain separate and linked through `Finding_Recommendation_Links`. Customer-facing and consultant-facing recommendation text remain separate. A finding may link to multiple recommendations by phase, link type and sequence.

## 8. Evaluation status and RAG

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

## 9. Conflicts

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

## 10. Exceptions

The master configuration stores exception policies, not project-specific accepted exceptions.

Supported effects:

- AcknowledgeOnly
- RemoveBlock
- ExcludeFromScope
- AcceptDifference
- DowngradeDecisionImpact

An accepted exception may alter decision treatment but must never erase or replace the original finding, original RAG or evidence. Carry-forward to post-migration defaults to false.

## 11. Thresholds and effort

Thresholds contain lower and upper bounds, inclusivity flags and unit. The default convention is lower-inclusive and upper-exclusive. Gaps, overlaps and duplicate bands fail validation where complete classification is required.

Effort uses a hybrid model:

- weighted driver score;
- mandatory minimum-band overrides for critical conditions;
- separately calculated effort confidence;
- customer-facing presentation of final band, confidence, primary drivers, assumptions and missing information;
- raw numeric score remains internal unless explicitly approved.

## 12. Classification dimensions

The normalized classification backbone is:

- Region
- Authority
- TechnicalStandard
- RegionalImplementation
- ProductDomain
- LifecycleContext
- ProductClass
- ProcedureContext where applicable

ASMF is a ProcedureContext, not a technical format. Regional implementations are layered on technical standards. A report-level primary dossier type may be derived but is not maintained as a single authoring dimension.

## 13. Aliases

Aliases map approved alternate source names to canonical fields or values. They must be scoped, versioned, traceable and validated. Alias resolution must not change raw evidence values.

## 14. Required implementation artifacts

The logical model must be published as:

- workbook data dictionary;
- entity-relationship diagram;
- JSON relationship matrix;
- generated Rule Index;
- representative end-to-end golden fixtures;
- validation rules for keys, references, lifecycle, conditions, conflicts, thresholds and outputs.