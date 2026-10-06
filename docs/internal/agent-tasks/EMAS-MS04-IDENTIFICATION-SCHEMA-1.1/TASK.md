# EMAS-MS04-IDENTIFICATION-SCHEMA-1.1

**Task ID:** `EMAS-MS04-IDENTIFICATION-SCHEMA-1.1`  
**Roadmap ID:** T3a  
**Authoritative base commit:** `9d622cfa12bb94464ad5f149aec581bedac12dbc`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Codex) → ChatGPT central review → user merge decision  
**Task type:** Bounded schema/validator/loader implementation  
**Windows:** Runtime contract CI required; native end-to-end qualification remains deferred

## Purpose

Implement the accepted T3 runtime-contract decision:

- introduce explicit Runtime JSON Schema **1.1.0** support for Identification rule semantics;
- preserve valid Schema 1.0.0 behavior;
- add semantic validator guards;
- update the PowerShell configuration loader to accept the supported 1.1.0 contract;
- synchronize the canonical schema/runtime documentation and fixture contract.

This task does **not** implement workbook authoring/export (T3b) or IdentificationInterpretation (T4).

## Governing decisions

Read and follow:

- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/REVIEW.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN/reports/CLAUDE.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN/reports/REVIEW.md`
- `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
- `docs/configuration/07_eMAS_Data_Dictionary.md`
- `docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md`
- current schema, validators, fixture suite and PowerShell loader contracts.

The ChatGPT T3 review amendments are normative where they differ from Claude's proposal.

## Accepted versioning decision

Implement:

`schemaVersion = 1.1.0`

as a **MINOR**, backward-compatible extension.

Do not silently amend 1.0.0 in place.

Required compatibility behavior:

1. existing valid 1.0.0 documents remain valid;
2. existing invalid 1.0.0 documents remain invalid for the same reason where applicable;
3. 1.1-only executable properties are not silently accepted as 1.0.0;
4. valid 1.1.0 documents are accepted by schema/semantic validation;
5. the PowerShell loader recognizes supported 1.0.0 and 1.1.0 versions;
6. unsupported schema versions still fail fast.

Use the smallest implementation approach that proves these behaviors. Do not duplicate the entire schema tree unless version dispatch requires it.

## Required Schema 1.1 additions

### Rule output

Identification `ClassificationCandidate` outputs require optional 1.1 properties:

- `targetEntityType`
- `evidenceStrength`
- `evidencePolarity`

For `ruleType = IDENTIFICATION`, semantic validation must require and validate these fields.

### Conflict policy

Add optional:

- `minimumEvidenceStrengthForValue`

This is schema capability only. No production Weak-floor policy becomes Effective in this task.

### Confidence policy

Add optional:

- `resultConfidence`
- `corroborationRule`

Make `weightOrScore` conditionally optional for the Identification policy shape so ordinal confidence can be represented without inventing numeric weights.

Do not remove numeric weight support for other existing policy uses.

No production confidence policy becomes Effective merely because the schema supports these fields.

### Field definition

Add optional:

- `maxEvidenceStrength`

This is an authoring/runtime semantic ceiling. It does not rewrite factual evidence.

### Value-list ordering

The existing schema already supports `sortOrder` on controlled values.

T3a must verify and preserve that capability because ordinal:

`STRONG > MEDIUM > WEAK`

depends on governed ordering.

## Required controlled-code model

Ensure canonical support for:

### EVIDENCE_STRENGTH

- `STRONG`
- `MEDIUM`
- `WEAK`

### CONFIDENCE

- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

### RULE_TYPE

Must support:

- `IDENTIFICATION`

### New controlled lists as required by the accepted model

- `IDENTIFICATION_DIMENSION`
- `EVIDENCE_POLARITY`
- `TIE_BEHAVIOR`
- `CORROBORATION_RULE`

Use canonical codes from the accepted T3 model.

Do not create report/display synonyms as executable codes.

## Required semantic validator guards

For `ruleType = IDENTIFICATION`:

### Dimension-scoped candidate resolution

- `targetEntityType` must be an approved Identification dimension/entity type;
- `conflictGroup` must match the intended identification dimension;
- `ClassificationCandidate.outputCode` must exist **within the declared targetEntityType collection**.

Do **not** impose global cross-dimension code uniqueness.

A code such as `UNKNOWN` or `OTHER` may legitimately exist in more than one dimension.

### Candidate evidence metadata

- `evidenceStrength` must resolve to EVIDENCE_STRENGTH;
- `evidencePolarity` must resolve to EVIDENCE_POLARITY.

### Rule type / conflict / tie behavior

Validate controlled references that current 1.0.0 validators leave too permissive, including the Identification-scoped use of:

- rule type;
- conflict/dimension group;
- tie behavior;
- confidence evidence strength;
- result confidence;
- corroboration rule.

Do not broaden validation in ways that unexpectedly invalidate unrelated 1.0.0 content unless the canonical contract already requires the check.

### Evidence-strength ceiling

For an Identification rule, the requested output `evidenceStrength` must not exceed the minimum allowed `maxEvidenceStrength` of the required evidence fields used by that rule.

Required negative fixture:

- a STRONG candidate produced solely from a Weak- or Medium-capped field must fail with a stable semantic error code.

This is a rule-authoring safety guard, not evidence rewriting.

### Alias safety

Do not use generic aliases to implement `Supporting → Medium`.

That normalization remains an engine-side T4 adapter.

If T3a touches alias validation, it may only tighten behavior required by existing canonical rules and must be separately evidenced.

## Identification result contract boundary

This task does **not** implement the result writer.

However, schema/runtime docs must remain consistent with the accepted future contract:

`eMAS.MS04.PreSales.Identification/1.0`

Do not add:

- `Outcome`
- `SupportStatus`

as executable result fields.

Those were rejected by central review.

## PowerShell loader requirements

Update the bounded configuration contract/loader so:

- 1.0.0 remains supported;
- 1.1.0 is supported;
- unsupported versions remain rejected;
- loader behavior remains read-only and fail-fast;
- no runtime JSON is repaired or rewritten;
- minimum-engine compatibility remains enforced.

Do not implement Identification rule execution.

If a version adapter is genuinely required, keep it compatibility-only. Do not transform 1.0.0 rule semantics into 1.1.0 identification semantics.

## Fixture requirements

Extend the schema fixture set with explicit 1.1 cases.

At minimum include:

### Valid / boundary

1. minimal valid Identification rule with dimension-bound candidate;
2. IDENTIFICATION output with STRONG structured-XML field ceiling;
3. ordinal evidence-strength list with sortOrder;
4. weightless Identification confidence policy using resultConfidence/corroborationRule;
5. valid same code string in two different master-data dimensions, resolved by targetEntityType;
6. valid 1.0.0 fixture proving compatibility.

### Invalid

1. ClassificationCandidate code not in targetEntityType;
2. targetEntityType does not match identification conflict/dimension group;
3. evidenceStrength unknown;
4. evidencePolarity unknown;
5. tieBehavior unknown;
6. resultConfidence unknown;
7. corroborationRule unknown;
8. requested evidence strength exceeds field maxEvidenceStrength;
9. 1.1-only property labelled as 1.0.0;
10. unsupported schema version.

Each invalid fixture must produce a stable expected error code.

## Required validation

Run and record:

- schema fixture validation;
- Python semantic validator tests;
- `tests/schema/test_schema_fixtures.py`;
- runtime configuration tests on supported platforms available in CI;
- existing static runtime-contract tests;
- any loader compatibility tests added for 1.0.0 + 1.1.0.

The known Windows PowerShell 5.1 UTF-8 assertion is pre-existing and unrelated. Do not widen this task to repair it unless your changes actually touch the failing files or introduce a new failure.

## Canonical documentation synchronization

Update only the canonical documents required to describe the accepted 1.1 behavior, including as applicable:

- Runtime JSON Contract;
- Normalized Rule Model;
- Data Dictionary;
- Schema Validation and Fixture Contract;
- schema README.

Document:

- Schema 1.1.0;
- supported version behavior;
- added fields;
- dimension-scoped candidate resolution;
- ordinal/no-weight Identification semantics;
- governed code lists;
- evidence-strength ceiling;
- no global cross-dimension code uniqueness.

Do not rewrite unrelated requirements.

## Allowed implementation files

May modify only files required for this bounded contract change:

- `config/schema/eMAS-runtime-config.schema.json`
- relevant `config/schema/defs/*.schema.json`
- `config/schema/examples/**`
- `build/validate_emas_schema.py`
- `build/emas_schema_model.py`
- `build/emas_schema_semantics.py`
- `tests/schema/**`
- `engine/core/eMAS.Configuration.Contract.psm1`
- `engine/core/eMAS.RuntimeConfiguration.psm1` only if required for version support
- `engine/core/private/eMAS.RuntimeConfiguration.Validation.ps1` only if required
- `tests/runtime/Test-eMASRuntimeConfiguration.ps1` only for new version-contract tests, without touching the unrelated UTF-8 expectation
- the canonical docs listed above
- this task's report/status files.

If another file is genuinely required, stop and document why before widening scope.

## Forbidden

Do not modify:

- workbook POC tables;
- VBA;
- JSON export implementation;
- ClassificationEvidenceCollection;
- RepositoryDiscovery;
- BackboneXmlInventory;
- IdentificationInterpretation;
- report mappings;
- prior mapping artifact;
- production regulatory rule content.

T3b owns workbook/export implementation.

## Report

Create/update:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-SCHEMA-1.1/reports/CODEX.md`

Include:

- exact schema fields added;
- exact code lists / validation guards added;
- version-dispatch approach;
- changed files;
- fixture matrix/results;
- loader tests for 1.0.0 and 1.1.0;
- proof 1.0.0 cannot silently use 1.1-only executable fields;
- proof no global code-uniqueness rule was added;
- canonical docs synchronized;
- CI/regression results;
- blockers/open issues.

## Git workflow

Use branch:

`implementation/emas-ms04-identification-schema-1-1`

Open a **draft PR into `demo/end-to-end-mvp`**.

Do not merge.

## Acceptance criteria

Ready for ChatGPT review when:

1. Schema 1.1.0 is explicit and version-safe;
2. 1.0.0 compatibility is proven;
3. all required semantic guards are enforced;
4. no unapproved numeric Identification weights are introduced;
5. candidate resolution is dimension-scoped;
6. loader safely supports 1.1.0;
7. canonical docs and fixtures are synchronized;
8. no workbook/export/T4 implementation leaks into scope.
