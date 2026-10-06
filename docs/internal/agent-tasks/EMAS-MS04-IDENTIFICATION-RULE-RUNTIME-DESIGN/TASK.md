# EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN

**Task ID:** `EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN`  
**Roadmap ID:** T3  
**Authoritative base commit:** `8a8c842b45e2cbf12025c15995cf99b0b8012b55`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user decision  
**Task type:** Runtime/configuration compatibility and design gate only  
**Implementation:** NOT authorized in this task  
**Windows:** Deferred

## Purpose

Determine the smallest governed workbook/runtime-JSON/engine contract needed to support the accepted unified `IdentificationInterpretation` capability.

This task answers **how approved identification rules can be authored, exported, validated, loaded, and traced**.

It does not implement identification logic and does not create Effective regulatory rule packs.

## Governing design

Read and follow:

- accepted `EMAS-MS04-IDENTIFICATION-RULES` Claude report;
- accepted ChatGPT review and amendments;
- current canonical authority/precedence policy;
- Enterprise Requirements v3.1;
- Mapping Functional/Technical Requirements;
- Content Catalogue;
- Runtime JSON Contract;
- Normalized Rule Model;
- Relationship Matrix;
- Data Dictionary;
- Schema Validation/Fixture Contract;
- XLSM/VBA POC conformance contract;
- current Runtime JSON schema and examples;
- current workbook POC source/validators/VBA JSON builder;
- current PowerShell RuntimeConfiguration loader/adapter contracts.

## Central-review decisions that this task must preserve

1. one unified `IdentificationInterpretation` capability;
2. canonical dimensions underneath derived report projections;
3. no new executable Identified/Probable status vocabulary;
4. raw CEC `Supporting` is preserved and normalized to canonical `Medium` only at interpretation time;
5. Weak-only evidence may generate candidates but cannot produce a final value once the policy is approved;
6. numeric scoring/weights remain Draft until Migration SME + Product Owner approval;
7. dossier aggregation is dimension-specific, not universal minimum confidence;
8. Region and RegionalImplementation remain distinct;
9. Identification output uses a separate versioned result contract;
10. regulatory rule content remains Draft until required SME/Product Owner approval.

## First question: can the current model already express the rules?

Perform a source-backed gap analysis of current:

- `Rules`
- `Rule_Phase_Assignment`
- `Condition_Groups`
- `Rule_Conditions`
- `Rule_Outputs`
- `Conflict_Policies`
- `Confidence_Policies`
- master-data relationships
- aliases
- field catalogue
- runtime schema
- semantic validators
- VBA/POC JSON export.

Specifically determine whether current Schema 1.0.0 can express:

- a classification rule bound to a canonical dimension;
- conditions over CEC evidence fields;
- candidate output to a specific master-data entity/value;
- positive vs contradictory evidence;
- evidence-strength requirement;
- `Supporting → Medium` normalization;
- `HighestEvidenceScore`;
- tie → Unknown/ManualReview;
- Weak-only floor;
- independent-corroboration confidence;
- rule/evidence traceability;
- per-dossier/per-unit scope;
- applicability to TechnicalStandard / Region / RegionalImplementation / ProcedureContext etc.;
- multi-value/lifecycle aggregate results;
- no-value `InsufficientEvidence` outcome.

For each capability classify:

`Already expressible / Expressible with configuration only / Requires schema-model change / Requires engine-only behavior / Requires governance decision`.

## Critical current inconsistency to investigate

The current synthetic POC contains confidence examples using values such as `HIGH` and numeric `WeightOrScore`, while canonical Classification evidence strength is `Strong/Medium/Weak` and current CEC raw evidence uses `Strong/Supporting/Weak`.

Do not fix this in the design task.

Document:

- exact current schema/value-list behavior;
- whether these are illustrative POC values or an actual canonical incompatibility;
- smallest safe correction route;
- migration/backward-compatibility implications.

## Rule schema design

Propose the **minimum** machine-readable identification rule representation.

Prefer reusing existing normalized entities over adding a new rule DSL.

At minimum show how to represent:

- RuleId / revision / lifecycle;
- dimension target;
- candidate master-data target;
- condition groups over factual evidence;
- required/forbidden/any-of evidence semantics;
- evidence-strength floor;
- conflict group / strategy / priority;
- confidence impact;
- phase applicability;
- dossier/unit scope;
- source references / requirement references.

If an existing field can carry the meaning safely, reuse it.

If not, identify the exact gap.

## Evidence normalization

Design the interpretation-boundary normalization:

`Strong → Strong`  
`Supporting → Medium`  
`Weak → Weak`

Requirements:

- raw CEC record remains immutable;
- normalized strength is traceable;
- the exact normalization policy/version is recorded in interpretation provenance;
- future CEC versions may natively emit canonical Medium without breaking old evidence.

Decide whether normalization belongs in:

- Runtime JSON policy;
- engine compatibility adapter;
- rule pre-processing layer;
- or another bounded component.

Recommend one.

## Scoring and conflict policy

Do not invent numeric production weights.

The design must support current approved semantics without pretending unapproved scores exist:

- Strong > Medium > Weak precedence;
- equal best-strength contradictory candidates → Conflict;
- independent corroboration may raise confidence;
- Weak-only floor is policy-controlled;
- numeric WeightOrScore remains Draft/unapproved.

Evaluate whether `HighestEvidenceScore` currently *requires* decimal weights in schema/runtime.

If yes, propose the smallest governed bridge until weights are approved.

If no, show how tier precedence can be represented deterministically.

## Identification output contract

Design a separate result contract:

`eMAS.MS04.PreSales.Identification/1.0`

Do not modify `ScannerObservations/1.0` in this task.

Specify the smallest result shape needed for:

- subject (Dossier/Sequence or SubmissionUnit);
- canonical dimension;
- EvaluationStatus;
- Value or ValueSet;
- Confidence;
- ReviewRequired;
- matched candidates;
- normalized score/strength summary;
- supporting evidence IDs;
- contradicting evidence IDs;
- unavailable evidence;
- fired RuleIds;
- runtime config hash/version;
- limiting factors.

Also specify how report projections map:

- TechnicalStandard → TechnicalFormat;
- RegionalImplementation/version components → SpecificationProfile;
- ProcedureContext/LifecycleContext/application metadata → DossierContext.

No report implementation here.

## Runtime JSON compatibility decision

Determine whether identification rule support is:

- compatible within current Schema 1.0.0;
- requires an approved additive 1.0.x/1.1-style extension under current project versioning;
- or requires a breaking major schema change.

Use the actual schema's `additionalProperties`, required sections, validators and compatibility rules.

Do not assume `TR-JSON-006` permits executable extensions.

## Workbook impact

Identify exactly which existing workbook tables can carry identification rule content and which, if any, require new columns/tables.

Do not alter workbook files.

Include:

- authoring table;
- validation rules;
- controlled value lists;
- relationship checks;
- export mapping;
- rule lifecycle;
- review/approval fields;
- traceability.

## Prior mapping correction route

The prior `eMAS_PreSalesMapping.json` includes obsolete concepts:

- regional implementations as formats;
- ASMF/DMF as formats;
- overconfident v4 file-presence rules.

Design how those concepts are prevented from entering the future governed workbook/runtime rule pack.

Do not edit the prior file.

Recommend a bounded correction/migration task with explicit acceptance tests.

## Required prototypes

Scratch/local prototypes are allowed but must not be committed.

Use them only to prove:

- whether current schema validates the minimal rule representation;
- whether current semantic validators accept/reject the necessary outputs/references;
- whether current POC export can serialize the required structure.

Report exact results.

## Required deliverable

Create only:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN/reports/CLAUDE.md`

The report must include:

1. source basis/authority;
2. current-model capability matrix;
3. schema/runtime gap matrix;
4. minimal rule representation;
5. evidence normalization decision;
6. scoring/conflict design without unapproved weights;
7. separate Identification result contract;
8. workbook impact;
9. Runtime JSON versioning decision;
10. prior-mapping correction route;
11. implementation file/task impact;
12. prototype evidence;
13. open governance decisions;
14. recommended bounded implementation task.

## Forbidden changes

Do not modify:

- config schema;
- workbook POC/source;
- VBA;
- runtime engine;
- PowerShell;
- tests/fixtures;
- CEC;
- IdentificationInterpretation;
- prior mapping artifacts.

Report only.

## Git workflow

Use branch:

`analysis/emas-ms04-identification-rule-runtime-design`

Open a draft PR into:

`coordination/emas-ms04-identification-rule-runtime-design`

Do not merge.

## Acceptance criteria

Ready for ChatGPT review when:

1. current schema expressiveness is proven, not guessed;
2. every gap maps to a specific canonical source or implementation constraint;
3. no new rule DSL is invented unnecessarily;
4. raw evidence normalization remains traceable;
5. no unapproved numeric scoring is smuggled in;
6. separate Identification result contract is specified;
7. schema/versioning impact is explicit;
8. prior mapping correction route is explicit;
9. implementation scope is bounded and practical.
