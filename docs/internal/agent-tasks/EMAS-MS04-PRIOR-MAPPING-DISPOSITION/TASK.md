# EMAS-MS04-PRIOR-MAPPING-DISPOSITION

**Task ID:** `EMAS-MS04-PRIOR-MAPPING-DISPOSITION`  
**Roadmap ID:** T3c  
**Authoritative base commit:** `9d622cfa12bb94464ad5f149aec581bedac12dbc`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user decision  
**Task type:** Report/governance disposition only  
**Implementation:** NOT authorized  
**T3b dependency:** None; may proceed in parallel with T3a  
**T4 dependency:** Does not block test-engine implementation, but blocks migration of legacy mapping rules into the governed production rule pack

## Purpose

Disposition every rule in the prior MS-04 Pre-Sales mapping so obsolete concepts cannot leak into the new governed Identification model.

The prior mapping is a historical design input, not canonical authority.

No prior rule is imported automatically.

## Governing decisions

Read and follow:

- canonical authority and precedence policy;
- Enterprise Requirements v3.1;
- Mapping Functional Requirements;
- accepted `EMAS-MS04-IDENTIFICATION-RULES` reports/review;
- accepted T3 runtime-design reports/review;
- current master-data dimensions and relationships;
- current official regulatory sources needed to verify any rule proposed for reuse.

The ChatGPT central-review amendments are normative.

## Prior artifacts

Review, when available in the local/internal workspace:

- `eMAS_PreSalesMapping.json`
- `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v2.0.docx`
- `eMAS_Dossier_Classification_Mapping_v2.1_1386873065.xlsx`
- `eMAS_MS04_PreSales_Sample_Data_Catalogue_v1.1.xlsx`
- `eMAS-Requirement_Complete_Scenario_Matrix_v1.1_AdPromo.xlsx`

The T3 analysis identified **39 prior Pre-Sales rules** as the disposition population.

If the actual file available to you contains a different count, stop and explain the discrepancy before classifying anything.

## Confidentiality / public-repository rule

Do **not** commit the prior mapping JSON, binary workbook, raw rule text, proprietary condition expressions, or confidential internal source content.

The committed report must be a **redacted disposition register**.

It may contain:

- prior RuleId;
- high-level prior category;
- disposition;
- canonical target dimension/entity;
- evidence/source class;
- maximum allowed evidence strength;
- rationale code;
- official-source verification status;
- required reviewer/approval role;
- follow-up task reference.

It must not reproduce full historical rule conditions or internal mapping payloads.

Any detailed internal working register remains local/internal and uncommitted.

## Required disposition states

Every one of the 39 prior rules must receive exactly one primary disposition:

### RE_MODEL

The underlying intent may remain useful, but the old dimensional model or evidence semantics are wrong.

Examples include:

- regional implementations represented as formats;
- dossier/procedure concepts represented as technical formats;
- file-presence rules whose confidence/strength is too high.

### SEED_AS_DRAFT

The rule intent is still appropriate and can seed the new controlled workbook **only as Draft**, after verification against current official sources.

This status does **not** make the rule Effective.

### REJECT

The old rule is unsuitable for the governed Identification model.

Examples may include:

- free-text-only identification;
- unsupported inference;
- duplicate/superseded logic;
- path/file-name rules that claim strong/final classification;
- rules contrary to canonical requirements.

Do not add a fourth "keep as-is" path. Historical rules do not bypass the new governance model.

## Mandatory canonical corrections

Apply these accepted decisions:

### TechnicalStandard versus RegionalImplementation

Regional implementations must not be authored as TechnicalStandard.

For example, an EU regional implementation/profile belongs under `RegionalImplementation`, layered on the relevant technical standard.

### ASMF / DMF

ASMF and DMF are not technical formats.

They belong under `ProcedureContext` / dossier-context semantics as applicable.

### eCTD v4 physical markers

Physical `submissionunit.xml`, unit-kind, checksum marker, or v4 folder structure may support a candidate but may not produce a Strong/final v4 classification by itself.

Strong v4 identification requires structured v4 XML evidence from the future `SubmissionUnitXmlInventory` capability.

### Folder/path/free-text heuristics

Folder names, dossier names, product names and uncontrolled free text remain Weak and may not produce a final identified value by themselves.

### Region versus RegionalImplementation

Keep them separate.

An implementation/profile may support Region through an approved relationship but must not collapse the two concepts.

### Dimension-scoped candidate codes

The same code string may exist in multiple dimensions.

Do not recommend global cross-dimension code uniqueness.

Instead, every candidate must resolve inside its declared canonical target entity/dimension.

## Evidence-strength disposition

For every legacy rule proposed for RE_MODEL or SEED_AS_DRAFT, classify its strongest permissible evidence tier:

- `Strong`
- `Medium`
- `Weak`

Use the accepted future normalization vocabulary.

Do not infer a stronger tier than the underlying fields can support.

Examples:

- structured authoritative XML may permit Strong;
- approved physical regulatory markers generally cap at Medium;
- paths/names/free text generally cap at Weak.

If the source basis is uncertain, mark verification required rather than guessing.

## Required rationale codes

Use a small controlled set such as:

- `DIMENSION_WRONG`
- `EVIDENCE_OVERSTATED`
- `OUTDATED_SOURCE`
- `DUPLICATE_OR_SUPERSEDED`
- `UNCONTROLLED_TEXT_INFERENCE`
- `VALID_INTENT_REMODEL_REQUIRED`
- `CURRENT_SOURCE_VERIFIED`
- `OUT_OF_SCOPE`
- `INSUFFICIENT_BASIS`

Add a code only if genuinely necessary and define it once.

## Required 39/39 register

The committed report must contain one redacted row per prior rule.

Required columns:

- PriorRuleId
- PriorCategory
- Disposition
- CanonicalTarget
- EvidenceClass
- MaxStrength
- RationaleCode
- SourceVerification
- RequiredReviewer
- FollowUp

The register must total exactly 39 rows unless the source-count discrepancy gate is triggered.

## Required summary views

Report:

- counts by disposition;
- counts by prior category;
- counts by canonical target;
- count requiring official-source refresh;
- count blocked on future v4 XML evidence;
- count rejected because of dimension misuse;
- count rejected/remodelled because evidence strength was overstated.

## Official-source verification

For any rule marked `SEED_AS_DRAFT`:

- verify the regulatory premise using current official authority/ICH material;
- cite the source title/version/section;
- distinguish the regulatory fact from the eMAS design decision.

A rule may remain `RE_MODEL` without full current-source verification if the canonical dimensional defect alone already requires redesign, but note that source verification is still needed before any replacement becomes Effective.

## Guard recommendations

The report must map prior-rule failures to the future safeguards that prevent recurrence.

At minimum:

- dimension-scoped candidate target validation;
- field `maxEvidenceStrength` ceiling;
- no final result from Weak-only evidence;
- v4 physical markers capped below Strong;
- Draft-only new/changed regulatory rules until review;
- Effective-only export;
- no direct legacy JSON import.

Do not recommend global code uniqueness.

## Relationship to T3a/T3b

### T3a

May add structural validator capability to enforce:

- target entity correctness;
- evidence-strength ceilings;
- governed controlled values.

T3c should identify which guards are required, but must not edit validators.

### T3b

Will implement the governed workbook authoring/export path.

The T3c disposition register tells T3b/Content SMEs which legacy intents may be seeded as Draft or re-modelled.

No legacy rule becomes Effective automatically.

## Required deliverable

Create only:

`docs/internal/agent-tasks/EMAS-MS04-PRIOR-MAPPING-DISPOSITION/reports/CLAUDE.md`

The report must include:

1. source basis and precedence;
2. confirmation of the prior-rule population;
3. controlled disposition/rationale definitions;
4. 39/39 redacted register;
5. summary counts;
6. canonical correction themes;
7. official-source verification notes for SEED_AS_DRAFT;
8. guard-to-failure mapping;
9. rules blocked on future evidence capabilities;
10. implementation/content-authoring follow-up sequence;
11. unresolved SME/PO decisions.

## Forbidden changes

Do not modify:

- prior mapping files;
- workbook files;
- Runtime JSON schema;
- validators;
- PowerShell;
- CEC;
- fixtures/tests;
- regulatory rule content in production;
- T3a/T3b/T4 implementation.

Scratch/local analysis files are allowed but must not be committed.

## Git workflow

Use branch:

`analysis/emas-ms04-prior-mapping-disposition`

Open a draft PR into:

`coordination/emas-ms04-prior-mapping-disposition`

Do not merge.

## Acceptance criteria

Ready for ChatGPT review when:

1. exactly 39 prior rules are accounted for or a source-count discrepancy is explicitly blocked;
2. no raw proprietary rule payload is committed;
3. ASMF/DMF and regional implementation dimensional errors are corrected;
4. evidence strength is bounded by source quality;
5. every SEED_AS_DRAFT rule is source-verified;
6. no rule is automatically promoted to Effective;
7. recurrence-prevention guards are mapped;
8. the report is actionable for T3b/content governance.
