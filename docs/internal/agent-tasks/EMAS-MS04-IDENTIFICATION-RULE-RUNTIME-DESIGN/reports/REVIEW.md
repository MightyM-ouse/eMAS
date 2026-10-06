# ChatGPT Review — EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN

**Status:** `DECISION_ACCEPTED — T3A_AND_T3C_AUTHORIZED`  
**Reviewed Claude commit:** `ea4deca45919ed923521d584a6d7f2afdbe825bb`  
**Reviewed PR:** #46

## Overall verdict

Claude's T3 analysis is strong and, importantly, it tested the real schema/validators instead of designing against an imaginary configuration model.

The central conclusions are accepted:

- current Schema 1.0.0 is only partially sufficient;
- the missing capabilities are executable semantics, not descriptive metadata;
- a backward-compatible schema extension is required;
- `Supporting → Medium` belongs in a fixed engine-side evidence normalization adapter, not editable aliases;
- ordinal evidence precedence can satisfy the current design without unapproved numeric weights;
- the separate `eMAS.MS04.PreSales.Identification/1.0` result contract remains the right boundary;
- Effective-only export must be implemented;
- prior mapping content needs a disposition/guard task rather than direct import.

## Decision 1 — use Schema 1.1.0

Accept Claude's recommendation:

`SchemaVersion = 1.1.0`

Do not amend 1.0.0 in place.

The Runtime JSON Contract explicitly defines MINOR as backward-compatible optional structure. The proposed identification fields are additive/optional, while the loader must be updated in the same bounded change.

The pre-release status makes the controlled-code cleanup feasible, but explicit 1.1.0 versioning gives better traceability than another silent baseline amendment.

T3a must prove:

- all existing valid/boundary fixtures remain valid;
- new identification fixtures require 1.1.0;
- the PowerShell loader accepts both supported versions as intended;
- minimum engine version is updated appropriately;
- validators/docs/fixtures remain synchronized.

## Decision 2 — keep engine-side evidence normalization

Accept:

`EVIDENCE-STRENGTH-NORMALIZATION/1`

Raw CEC values remain immutable:

- `Strong → STRONG`
- `Supporting → MEDIUM`
- `Weak → WEAK`

Unknown raw values are not guessed; they become unavailable/unmapped evidence.

The result provenance records the normalization policy/version.

Do not implement this through aliases.

## Decision 3 — ordinal precedence, no production numeric weights

Accept the ordinal model:

`STRONG > MEDIUM > WEAK`

This ordering is precedence metadata, not a business score.

Until numeric weights are formally approved:

- no Effective identification rule contains a numeric business score;
- no numeric value is used to break otherwise equal evidence;
- equal best-strength contradictory candidates remain Conflict;
- independent corroboration affects confidence according to governed policy;
- the Weak-only floor remains governed policy.

For FR-CLASS-005 traceability, preserve a score summary as an ordinal model, but do not pretend `NumericScore = null` is a numeric score. Prefer naming such as `ScoreModel = ORDINAL_TIER/1`, `BestStrength`, `TierRank`, and counts.

## Amendment 1 — remove duplicate Outcome status from the Identification contract

Reject the proposed executable field:

`Outcome = Value|ValueSet|Unknown|ManualReview|null`

It duplicates the already accepted machine model:

- `EvaluationStatus`
- `Value / ValueSet`
- `ReviewRequired`
- `Confidence`

Use:

- Conflict + null value + ReviewRequired=true for manual-review cases;
- InsufficientEvidence + null value for weak/inadequate evidence;
- Evaluated + Value/ValueSet for usable results.

A report can derive display wording later.

## Amendment 2 — remove SupportStatus from the Identification contract

Do not include:

`SupportStatus = Supported|Unsupported`

in `Identification/1.0`.

That wording can be mistaken for regulatory support, migration support, or product support and is outside identification.

If supportability is needed later, it belongs to a separate assessment/policy layer.

## Amendment 3 — do not prohibit duplicate codes across canonical dimensions globally

Reject the proposed global `SEM_CROSS_DIMENSION_CODE` uniqueness rule.

Once every candidate is bound to `targetEntityType`, the same code string may legitimately exist in more than one normalized master-data collection, especially generic codes such as `UNKNOWN` or `OTHER`.

The required safety rule is:

- candidate resolution is always **dimension-scoped**;
- `outputCode` must exist in the declared `targetEntityType`;
- `targetEntityType` must match the identification conflict/dimension group.

This is sufficient to prevent ASMF/DMF from being emitted as TechnicalStandard without imposing unnecessary global code uniqueness.

## Amendment 4 — schema must validate source strength ceilings without changing raw facts

Accept `fieldDefinition.maxEvidenceStrength` as a controlled ceiling for identification rule authoring.

It is a rule-authoring guard, not an alteration of CEC evidence.

Examples:

- dossier path heuristic cannot authorize STRONG output;
- physical v4 marker cannot authorize STRONG output;
- structured XML fields may authorize STRONG where source-backed.

T3a must prove the semantic validator rejects a rule whose requested output strength exceeds the minimum allowed ceiling of its required evidence fields.

## Amendment 5 — Effective-only export is mandatory and must be dependency-safe

Accept Effective-only runtime export, but implementation must filter the complete dependent graph consistently.

A rule excluded because it is Draft/InReview/Reviewed must also exclude its:

- phase assignments;
- condition groups;
- conditions;
- outputs;
- supersession/runtime references where applicable.

The export must not leave broken orphan rows.

Draft content remains authoring content only.

## Amendment 6 — confidence-policy fields are schema capability, not approved policy content

T3a may add schema support for:

- `resultConfidence`;
- `corroborationRule`;
- conditional `weightOrScore`.

But no production confidence row becomes Effective merely because the schema supports it.

Migration SME + Product Owner approval is still required for actual policy rows.

## Amendment 7 — result contract simplification

The future `eMAS.MS04.PreSales.Identification/1.0` should minimally contain:

- execution/provenance;
- evidence-source identity;
- runtime-config identity;
- normalization policy;
- SubjectType / SubjectId / DossierId;
- canonical Dimension;
- EvaluationStatus;
- Value or ValueSet;
- Confidence;
- ReviewRequired;
- candidates;
- supporting/contradicting evidence IDs;
- unavailable evidence;
- fired RuleIds;
- ordinal score summary;
- limiting factors.

Keep TechnicalFormat / SpecificationProfile / DossierContext only as derived report projections.

## Prior mapping disposition

Accept the separate task:

`EMAS-MS04-PRIOR-MAPPING-DISPOSITION`

with one correction to Claude's guard design:

- keep dimension-scoped target validation;
- do **not** require globally unique code strings across all dimensions.

The 39 prior rules must each be explicitly re-modelled, seeded Draft, or rejected. No direct import.

## Accepted implementation sequence

### T3a — Schema 1.1.0 + validators + loader

Single implementation task.

Must include:

- schema additions;
- canonical code-list fixes;
- semantic validator guards;
- negative/boundary fixtures;
- loader 1.1.0 support;
- synchronized canonical docs;
- proof current fixtures remain compatible.

### T3c — Prior mapping disposition

Report/governance task.

May proceed in parallel with T3a.

### T3b — Workbook authoring/export

After T3a.

Must add the approved authoring columns/value lists/validation and Effective-only dependency-safe export.

### T4 — IdentificationInterpretation

Blocked until:

- T1a accepted;
- T3a accepted;
- T3b accepted.

T3c need not block T4 test-engine implementation, but it blocks production migration of the old mapping rules into the governed rule pack.

## Recommendation

**Accept T3 with these amendments, then authorize T3a and T3c.**

T3b should be created after T3a fixes the canonical schema/validator contract.


## User decision

Accepted. T3 is approved with the ChatGPT central-review amendments.

Authorized:

- T3a — `EMAS-MS04-IDENTIFICATION-SCHEMA-1.1`
- T3c — `EMAS-MS04-PRIOR-MAPPING-DISPOSITION`

T3b workbook/export remains blocked until T3a is accepted. T4 remains blocked on T1a, T3a and T3b.
