# EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE

**Task ID:** `EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE`  
**Roadmap ID:** T4b  
**Authoritative base:** `cff3456df0852b4c9cc8399d8908bac09bf5720e`  
**Base branch:** `coordination/emas-ms04-identification-interpretation`  
**Worker:** Codex  
**Task type:** Bounded shared-core engine implementation  
**Merge target:** `coordination/emas-ms04-identification-interpretation`

## Purpose

Implement the bounded, configuration-driven MS-04 Pre-Sales `IdentificationInterpretation` engine in the shared PowerShell core.

The engine converts accepted CEC facts plus validated Runtime JSON Schema 1.1.0 Identification rules into the separate `eMAS.MS04.PreSales.Identification/1.0` result.

Codex is the **single implementation owner**.

Claude owns the independent T4a oracle and expected outcomes.

## Parallel-work rule

T4b may start while T4a is being created.

However, before T4b can be declared ready for central review, Codex must:

1. wait for T4a to be centrally accepted/merged into the coordination branch;
2. update/rebase the implementation branch from that coordination branch;
3. run the implementation against the independent oracle;
4. fix the engine, not the oracle, for any implementation defect;
5. report genuine oracle/design contradictions rather than rewriting expected outcomes.

## Mandatory source basis

Read:

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`;
2. accepted Identification Rules report/review;
3. accepted T3 runtime-design report/review;
4. T3a Schema 1.1.0 task/review;
5. T3b workbook/export task/review;
6. accepted T1a CEC task/review;
7. current `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`;
8. current RuntimeConfiguration module/accessors;
9. Enterprise Requirements v3.1;
10. configuration docs 01–09;
11. Pre-Sales phase contract;
12. current `scripts/eMAS-PreSalesAssessment.ps1`.

When T4a is merged, read its `BEHAVIOR_CONTRACT.md` and oracle manifest before finalizing.

## Architecture boundary

Business/regulatory interpretation belongs in `engine/core`, not runtime adapters.

The implementation must parse under Windows PowerShell 5.1 and PowerShell 7.6.

Do not duplicate Identification business logic in `engine/powershell51` or `engine/powershell7`.

## Core input contract

The engine consumes:

1. a scanner observation object using:
   `eMAS.MS04.PreSales.ScannerObservations/1.0`
   with `ClassificationEvidenceCollection` capability and CEC coverage; and
2. a validated runtime-configuration wrapper or immutable Schema 1.1.0 runtime JSON loaded through the existing RuntimeConfiguration module.

The engine must never:

- reopen source files;
- enumerate repository paths itself;
- reparse XML;
- mutate CEC records;
- read the internal XLSM;
- generate/repair runtime JSON.

## Required module

Create a shared-core module, expected path:

`engine/core/eMAS.IdentificationInterpretation.psm1`

Private helpers may be added under:

`engine/core/private/eMAS.Identification.*.ps1`

if this materially improves testability.

Export one clear public entry point, recommended:

`Invoke-eMASIdentificationInterpretation`

Do not invent multiple competing identification engines.

## Binding engine behavior

### 1. Evidence normalization

Implement fixed engine policy:

`EVIDENCE-STRENGTH-NORMALIZATION/1`

- Strong → STRONG
- Supporting → MEDIUM
- Weak → WEAK
- unknown/unmapped raw strength → unavailable evidence with `UnmappedStrength`

Raw CEC objects must remain unchanged.

Record normalization policy/version in result provenance.

### 2. CEC field projection

Project CEC records into the scalar configured fields needed by Identification conditions.

Use the Runtime JSON field catalogue as the configured field boundary.

Do not allow arbitrary non-CEC scanner fields to masquerade as Identification evidence.

At minimum support the accepted synthetic T3b fields and the T4a oracle selectors.

Projection must retain the EvidenceIds that caused each field value to exist.

A field state must distinguish at least:

- available value;
- assessed absence where meaningful;
- not collected / capability unavailable;
- capture error/unmapped strength.

Do not collapse `Missing`, `NotCollected`, `AccessDenied`, parse failure, and unmapped strength into one null.

### 3. Rule evaluation

Evaluate only Runtime JSON rules where:

- `ruleType = IDENTIFICATION`;
- phase includes `PRE_SALES`;
- runtime config is already valid/compatible.

Use normalized rule entities:

- Rules;
- RulePhases;
- ConditionGroups;
- RuleConditions;
- RuleOutputs.

Semantics:

- conditions within one group are AND;
- groups are OR;
- case sensitivity follows condition;
- `negate` is a guard inversion;
- `MISSING` means assessed absence according to the field projection, not capability-not-collected;
- unavailable required input follows the configured rule-phase missing-input behavior and contributes traceable unavailable evidence;
- cite evidence from the group(s) that actually fired;
- negated guard conditions must not fabricate positive evidence strength.

Do not implement a second DSL.

### 4. Supported operators

For T4 bounded implementation, support the operators needed by accepted Identification fixtures/runtime config.

At minimum:

- EQUALS
- NOT_EQUALS
- EXISTS
- MISSING
- IN_LIST
- CONTAINS
- STARTS_WITH
- ENDS_WITH
- MATCHES_PATTERN

If the T4a oracle requires an already-canonical operator beyond this list, implement it only if it can be done generically and safely.

Do not broaden into unrelated numeric assessment logic merely because generic operators exist elsewhere.

### 5. Candidate construction

For fired `ClassificationCandidate` outputs:

- candidate key = `Dimension/TargetEntityType + OutputCode`;
- resolution is dimension-scoped;
- preserve all supporting RuleIds;
- preserve all contradicting RuleIds;
- preserve supporting/contradicting EvidenceIds;
- preserve raw and normalized evidence strength in evidence trace entries if the T4a contract requires it;
- do not globally deduplicate same code strings across dimensions.

No numeric business score is allowed.

### 6. Ordinal score model

Implement only:

`STRONG > MEDIUM > WEAK`

Order comes from governed runtime list metadata where practical, but the engine must fail/stop safely if the required list is inconsistent despite validated input.

Use the accepted ordinal score summary, e.g.:

- `ScoreModel = ORDINAL_TIER/1`;
- `BestStrength`;
- `TierRank`;
- counts by tier;
- corroborating source-class count where required by confidence policy.

Do not invent or consume numeric Identification `WeightOrScore`.

### 7. Final-value floor

Current accepted policy:

`minimumEvidenceStrengthForValue = MEDIUM`

If the best surviving candidate is below the configured floor:

- `EvaluationStatus = InsufficientEvidence`;
- final Value/ValueSet is null;
- `Confidence = Unknown`;
- `ReviewRequired = true`;
- candidates remain visible;
- limiting factor indicates below-floor evidence.

Do not discard Weak candidates.

### 8. Conflict/tie behavior

No numeric tie-breaker.

At minimum:

- stronger tier beats weaker tier;
- equal best-strength incompatible candidates in one dimension → `Conflict`;
- equal-strength supporting and contradicting evidence that prevents a safe selection → `Conflict`;
- `ReviewRequired = true`;
- final value is null for manual-review/tied conflict cases.

Respect configured `tieBehavior` only within the accepted machine model; do not introduce an `Outcome` status.

### 9. Confidence

Use configured Identification confidence policies only.

No built-in business weights.

Support:

- `resultConfidence`;
- `corroborationRule`;
- `NONE_REQUIRED`;
- `INDEPENDENT_SOURCE_CLASS`.

If no applicable approved/configured confidence row exists, use a conservative deterministic result described by the T4a contract; do not invent numeric confidence scoring.

### 10. Result contract

Produce a separate:

`eMAS.MS04.PreSales.Identification/1.0`

Do not mutate the scanner observation contract.

The machine contract must follow the accepted simplified model:

- execution/provenance;
- evidence-source identity;
- runtime-config identity;
- normalization policy;
- subject identity;
- canonical dimension;
- EvaluationStatus;
- Value or ValueSet;
- Confidence;
- ReviewRequired;
- candidates;
- supporting/contradicting evidence;
- unavailable evidence;
- fired RuleIds;
- ordinal score summary;
- limiting factors.

Do not include:

- `Outcome`;
- `SupportStatus`;
- readiness/acceptance conclusions;
- regulatory-validity claims.

### 11. Determinism

For the same scanner evidence and runtime config:

- result ordering must be stable;
- candidate ordering must be stable;
- EvidenceId ordering must be stable;
- IdentificationIds must be deterministic within the document;
- input object ordering must not change semantic output.

### 12. Output path safety

If the module writes an output file:

- UTF-8 without BOM;
- do not overwrite or write inside the evidence source repository;
- do not overwrite the runtime config;
- do not modify scanner input;
- output failure must not partially rewrite input artifacts.

Follow existing scanner-module safety patterns where applicable.

## Pre-Sales script integration

Bounded integration is allowed and recommended if it can be done without widening scope.

Add an opt-in switch such as:

`-IncludeIdentificationInterpretation`

Rules:

- it requires `RuntimeConfigurationPath`;
- it implies/depends on CEC being produced;
- the final `OutputPath` for this mode is the separate Identification/1.0 document;
- it must not append Identification fields into ScannerObservations/1.0;
- existing capability switches/behavior remain backward compatible.

If clean script integration would materially widen T4, document it and leave orchestration for a tiny follow-up. The engine module/oracle conformance is the primary T4 gate.

## Independent T4a oracle gate

After T4a is merged into the coordination branch:

- update this implementation branch;
- treat `tests/identification-interpretation/oracle/**` as read-only;
- add/complete a harness under the T4b-owned engine-test area that executes every oracle case;
- compare the engine result to expected output using the oracle's documented comparison rules;
- never rewrite oracle expected files from implementation output.

## Required engine tests

Create:

`tests/identification-interpretation/engine/**`

At minimum test:

- normalization mapping/provenance;
- raw evidence immutability;
- field projection and EvidenceId traceability;
- assessed missing vs not collected;
- AND/OR/negate semantics;
- dimension-scoped same-code behavior;
- Weak-only floor;
- Strong vs Medium;
- Medium vs Weak;
- equal-tier conflict;
- contradiction conflict;
- candidate merge from multiple rules;
- confidence with independent source classes;
- no numeric score;
- deterministic ordering/IDs;
- separate result contract;
- no Outcome/SupportStatus;
- invalid scanner contract rejected;
- missing CEC capability rejected or NotAssessed according to contract boundary;
- Schema 1.0 runtime config containing Identification features is rejected by existing loader before interpretation;
- input evidence/runtime config remain unchanged;
- output-path safety if file writing is implemented.

## Regression

Run and report:

- T4b engine tests;
- T4a oracle conformance after oracle merge;
- Runtime configuration PowerShell tests;
- Schema tests;
- CEC tests;
- T3b POC tests;
- existing scanner regression suites touched by script integration;
- macOS development execution;
- Windows PowerShell 5.1 / 7.6 CI where available.

Known PS5.1 UTF-8 expectation failure remains unrelated unless T4 changes that test.

## Allowed files

Codex owns:

- `engine/core/eMAS.IdentificationInterpretation.psm1`;
- `engine/core/private/eMAS.Identification.*.ps1`;
- `tests/identification-interpretation/engine/**`;
- bounded `scripts/eMAS-PreSalesAssessment.ps1` integration;
- bounded engine/tests README updates;
- CI workflow update only if needed to execute T4 engine/oracle tests;
- this T4b task report/status.

Codex may read T4a files but may not edit them.

## Forbidden

Do not modify:

- `tests/identification-interpretation/oracle/**`;
- T4a behavior contract;
- CEC/scanner evidence facts;
- RepositoryDiscovery/BackboneXmlInventory;
- Runtime JSON Schema 1.1.0 merely to make the engine easier;
- workbook/VBA;
- T1b/T2;
- T3c U2–U9;
- real regional rule packs;
- legacy mapping payloads;
- reporting templates/mappings beyond a necessary test stub;
- numeric Identification weights.

Do not automatically merge.

## Git workflow

Use branch:

`implementation/emas-ms04-identification-interpretation-engine`

Open a **draft PR into**:

`coordination/emas-ms04-identification-interpretation`

Do not merge.

## Report

Write:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE/reports/CODEX.md`

Return:

- branch;
- commit SHA;
- draft PR;
- engine module/files;
- public function signature;
- normalization implementation;
- field-projection approach;
- rule/operator support;
- candidate/conflict/floor/confidence behavior;
- Identification/1.0 shape implemented;
- engine test results;
- T4a oracle conformance results;
- scanner/config immutability proof;
- script-integration status;
- Windows/macOS results;
- blockers/open issues.

## Acceptance gate

T4b is not ready for central review until it is rebased/updated after T4a acceptance and passes the independent oracle.
