# EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE

**Task ID:** `EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE`  
**Roadmap ID:** T4a  
**Authoritative base:** `cff3456df0852b4c9cc8399d8908bac09bf5720e`  
**Base branch:** `coordination/emas-ms04-identification-interpretation`  
**Worker:** Claude  
**Task type:** Independent behavioral contract + oracle fixture task  
**Implementation ownership:** NO engine implementation  
**Merge target:** `coordination/emas-ms04-identification-interpretation`

## Purpose

Freeze an implementation-independent behavioral contract for the bounded MS-04 Pre-Sales `IdentificationInterpretation` capability and create deterministic synthetic oracle cases against which the Codex engine implementation will be judged.

This task is deliberately independent from T4b.

Claude must define expected behavior from the accepted requirements/design and must not inspect or adapt expected outcomes to Codex implementation choices.

## Mandatory source basis

Read before writing the oracle:

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`;
2. accepted `EMAS-MS04-IDENTIFICATION-RULES` Claude report + ChatGPT review;
3. accepted `EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN` Claude report + ChatGPT review;
4. accepted T3a review;
5. accepted T3b review;
6. accepted T1a CEC task/review and current `eMAS.ClassificationEvidenceCollection.psm1`;
7. `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md`;
8. configuration documents 01–09;
9. Pre-Sales phase contract;
10. current Schema 1.1.0 and synthetic workbook/runtime examples.

T3/T3a/T3b central-review amendments override earlier sketches.

Do not use the old prior mapping as runtime authority.

## Binding accepted decisions

The oracle must enforce these already accepted decisions:

- one unified `IdentificationInterpretation` capability;
- facts come from CEC evidence/coverage only; interpretation does not reopen files or reparse XML;
- scanner contract `eMAS.MS04.PreSales.ScannerObservations/1.0` remains unchanged;
- separate output contract `eMAS.MS04.PreSales.Identification/1.0`;
- canonical dimensions stay independent;
- dimension-scoped candidate resolution;
- no global cross-dimension code uniqueness;
- raw CEC strength is immutable;
- normalization policy `EVIDENCE-STRENGTH-NORMALIZATION/1`:
  - `Strong -> STRONG`
  - `Supporting -> MEDIUM`
  - `Weak -> WEAK`;
- unmapped raw strength is never guessed and must be traceable as unavailable evidence;
- ordinal precedence only: `STRONG > MEDIUM > WEAK`;
- no numeric Identification score/weight is used to break ties;
- current minimum final-value evidence floor is `MEDIUM`;
- Weak-only evidence may preserve candidates but cannot produce a final value;
- equal best-strength incompatible candidates/contradictions produce `Conflict`;
- machine model uses `EvaluationStatus + Value/ValueSet + Confidence + ReviewRequired`;
- **no executable `Outcome` field**;
- **no `SupportStatus` field**;
- `TechnicalFormat`, `SpecificationProfile`, and `DossierContext` are report projections, not canonical authoring dimensions;
- physical v4 markers alone cannot yield Strong/final v4 identification;
- T3c open decisions U2–U9 stay unresolved.

## T4a deliverables

### 1. Behavioral contract

Create:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE/BEHAVIOR_CONTRACT.md`

Freeze exact behavior for the bounded T4 engine.

At minimum define:

- accepted inputs;
- input validation/failure boundary;
- subject partitioning;
- CEC-to-field projection semantics;
- condition evaluation;
- rule firing;
- candidate aggregation;
- evidence normalization;
- strength precedence;
- evidence-floor behavior;
- conflict/tie behavior;
- confidence selection from configured policies;
- unavailable-evidence treatment;
- deterministic ordering/IDs;
- output/provenance contract;
- explicit deferred behavior.

### 2. Identification/1.0 machine contract

Freeze exact field names and null/array conventions for the bounded result contract.

Minimum top-level concepts:

- `ContractId`;
- `Execution`;
- `EvidenceSource`;
- `RuntimeConfig`;
- `Normalization`;
- `Results`.

Minimum per-result concepts:

- `IdentificationId`;
- `SubjectType`;
- `SubjectId`;
- `DossierId`;
- `Dimension`;
- `EvaluationStatus`;
- `Value` or `ValueSet`;
- `Confidence`;
- `ReviewRequired`;
- `ValueSource`;
- `Candidates`;
- supporting evidence IDs;
- contradicting evidence IDs;
- `UnavailableEvidence`;
- `FiredRuleIds`;
- ordinal `ScoreSummary`;
- `LimitingFactors`.

The contract must not add `Outcome` or `SupportStatus`.

Keep report-only projections outside the core result or clearly marked as derived/non-authoritative.

### 3. Oracle fixture package

Create a new independent fixture area:

`tests/identification-interpretation/oracle/`

Recommended structure:

- `manifest.json`
- `cases/<case-id>/scanner-observations.json`
- `cases/<case-id>/runtime-config.json`
- `cases/<case-id>/expected-identification.json`
- `README.md`

Fixtures must be synthetic and deterministic.

Do not copy customer data, prior proprietary rule payloads, or real legacy rule conditions.

### 4. Mandatory oracle cases

At minimum cover:

1. **Strong single candidate** → Evaluated + value.
2. **Raw Supporting normalization** → MEDIUM, raw value preserved in cited evidence.
3. **Weak-only candidate** → InsufficientEvidence, Value null, Confidence Unknown, ReviewRequired true, candidate retained.
4. **Strong vs Medium candidates** → Strong candidate wins without numeric score.
5. **Medium vs Weak candidates** → Medium candidate wins when floor is MEDIUM.
6. **Equal best-strength different candidates** → Conflict, Value null, ReviewRequired true.
7. **Support + equal-strength contradiction for same candidate/dimension** → Conflict.
8. **Same code string in two canonical dimensions** → independent dimension-scoped results.
9. **Independent-source corroboration** → confidence follows explicit synthetic confidence policy.
10. **Single-source Strong** → confidence follows its explicit synthetic policy, not an invented weight.
11. **Unmapped raw strength** → evidence listed unavailable with reason `UnmappedStrength`; no guessed strength.
12. **Capability/field not collected** → NotAssessed where the configured rule cannot be evaluated because evidence was not collected.
13. **MISSING operator with assessed absence** → distinguish real assessed absence from NotCollected.
14. **Negated condition as guard** → guard affects firing but must not masquerade as positive evidence strength.
15. **OR condition groups** → only the fired group contributes cited evidence.
16. **Determinism** → shuffled input evidence order produces byte/semantic-equivalent ordered results.
17. **Duplicate candidate from multiple rules** → one candidate with all fired RuleIds/evidence retained.
18. **No applicable Identification rule for a dimension/subject** → explicit NotAssessed/NotApplicable behavior as justified by accepted contract; document which one and why.
19. **Physical v4 marker only** → cannot produce Strong/final v4 value.
20. **No numeric score** → ordinal score summary only; numeric business score absent.

If an expected status is not fully determined by accepted authority, do not invent it. Record it as an oracle design blocker for central review instead of silently choosing.

### 5. Confidence fixtures are synthetic policy tests

The oracle may create synthetic confidence-policy rows solely to prove engine semantics.

Do not claim those rows are approved production confidence content.

### 6. CEC projection contract

Define the bounded mapping from CEC record set to scalar rule fields required by the synthetic fixtures.

At minimum cover the field patterns already accepted by T3/T3b:

- common XML root element;
- common XML namespace where used;
- common backbone presence;
- dossier root path;
- unit kind / physical marker patterns when needed for the v4 negative case.

The oracle must preserve raw EvidenceIds and must not mutate CEC records.

If the accepted runtime field catalogue cannot unambiguously bind a FieldCode to a CEC evidence selector, document the exact gap instead of hard-coding an invisible convention.

### 7. Static oracle validation

Add a lightweight static validator/test for the oracle package that checks:

- every manifest case exists;
- scanner contract IDs are valid;
- runtime config declares Schema 1.1.0 for Identification cases;
- expected output uses `Identification/1.0`;
- no `Outcome` or `SupportStatus`;
- no numeric Identification score;
- expected cited EvidenceIds exist in the input;
- expected fired RuleIds exist in the runtime config;
- candidate values exist in the declared target dimension;
- ordering/IDs are deterministic in the fixture package.

The static validator must **not** implement a second Identification engine.

## Allowed files

Claude owns only:

- this task directory;
- `tests/identification-interpretation/oracle/**`;
- optional static oracle-validation helper under the same test directory.

Claude may read all repository files.

## Forbidden files/actions

Do not modify:

- `engine/**`;
- `scripts/eMAS-PreSalesAssessment.ps1`;
- Runtime JSON schema/validators;
- workbook/VBA;
- CEC/scanner modules;
- report mappings/templates;
- T3c open decisions U2–U9;
- production rule packs.

Do not create an alternative implementation engine.

## Git workflow

Use branch:

`analysis/emas-ms04-identification-interpretation-oracle`

Open a **draft PR into**:

`coordination/emas-ms04-identification-interpretation`

Do not merge.

## Report

Write:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE/reports/CLAUDE.md`

Return:

- branch;
- commit SHA;
- draft PR;
- behavioral-contract path;
- oracle manifest path;
- case count;
- contract shape summary;
- normalization/floor/conflict decisions encoded;
- static validation result;
- unresolved design blockers;
- confirmation no engine files changed.

## Acceptance gate

T4a is ready for central review only when the behavioral contract and oracle are internally consistent, traceable to accepted decisions, and independent of Codex implementation.
