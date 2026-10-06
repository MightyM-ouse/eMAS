# EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT

**Task ID:** `EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT`  
**Roadmap ID:** T3b  
**Authoritative base commit:** `e83123bba30a6c51727d04290b76a950e9c47d59`  
**Accepted T3c coordination reference:** `4f34d08de9277028589bd8e4e877cbdc9ead91ad`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user merge decision  
**Task type:** Bounded workbook-authoring / VBA-export / POC-conformance implementation  
**Native Windows/Excel qualification:** Required later; not claimed by this task unless actually executed and evidenced

## Purpose

Upgrade the source-controlled synthetic XLSM/VBA proof of concept so the authoring model can create and validate **Schema 1.1.0 Identification rules** and export them safely to Runtime JSON.

This task is the bridge between accepted T3a schema support and future T4 `IdentificationInterpretation`.

It must prove that workbook-authored Identification rules can be represented, validated, previewed and exported without:

- leaking Draft/InReview content into controlled runtime JSON;
- leaving orphan dependent rows after lifecycle filtering;
- exporting workbook-only legacy traceability;
- inventing numeric Identification weights;
- collapsing canonical dimensions;
- importing historical mapping rules directly.

This task implements authoring/export capability. It does **not** implement the T4 interpretation engine and does **not** make any historical regulatory rule Effective.

## Mandatory source basis

Read before changing code:

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
2. accepted Identification Rules report/review;
3. accepted T3 runtime-design report/review;
4. accepted T3a task/review and Schema 1.1.0 implementation;
5. accepted T3c disposition report/review from `coordination/emas-ms04-prior-mapping-disposition` at `4f34d08de9277028589bd8e4e877cbdc9ead91ad`;
6. `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`;
7. `docs/configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md`;
8. `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`;
9. `docs/configuration/05_eMAS_Normalized_Rule_Model.md`;
10. `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md`;
11. `docs/configuration/07_eMAS_Data_Dictionary.md`;
12. `docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md`;
13. `docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md`;
14. current synthetic POC source, Python verifier/exporter and reviewed VBA modules.

Where T3/T3a/T3c central-review decisions differ from an earlier sketch, the accepted central review controls.

## Current accepted baseline

T1a and T3a are merged.

Runtime JSON Schema supports:

- `1.0.0`;
- `1.1.0`.

Schema 1.1.0 Identification semantics include:

- `ruleOutput.targetEntityType`;
- `ruleOutput.evidenceStrength`;
- `ruleOutput.evidencePolarity`;
- `fieldDefinition.maxEvidenceStrength`;
- `conflictPolicy.minimumEvidenceStrengthForValue`;
- `confidencePolicy.resultConfidence`;
- `confidencePolicy.corroborationRule`;
- ordinal `STRONG > MEDIUM > WEAK`;
- dimension-scoped candidate resolution;
- no numeric Identification weight;
- no global cross-dimension code uniqueness.

The future engine-side normalization remains:

`Supporting → MEDIUM`

and is **not** implemented in the workbook by aliases.

## T3c constraints

The accepted historical-rule disposition is:

- RE_MODEL: 19;
- SEED_AS_DRAFT: 4;
- REJECT: 16.

No historical rule is imported directly.

No historical rule becomes Effective automatically.

For T3b:

- `LegacyRuleId` is permitted as **workbook-only informational traceability**;
- it must never become the runtime `RuleId`;
- it must not be serialized into Runtime JSON;
- all executable rules use new governed RuleIds;
- T3c open decisions U2–U9 remain open and must not be silently resolved;
- T1b EU envelope capture is a future evidence task, not T3b;
- the accepted Weak-only final-value floor is `MEDIUM`.

## Core implementation scope

### 1. Upgrade the synthetic workbook POC to Schema 1.1.0

The source-controlled POC must author/export Schema 1.1.0.

Update the synthetic `tblConfiguration` row and associated manifest/golden evidence to use:

`SchemaVersion = 1.1.0`

The POC must continue to prove the repository can still validate independent Schema 1.0.0 fixtures through T3a. T3b does not remove 1.0.0 support.

### 2. Workbook authoring columns

Extend the POC tables only where required by Schema 1.1.0 and accepted governance.

At minimum:

#### `tblFieldCatalogue`

Add:

- `MaxEvidenceStrength`

#### `tblRuleOutputs`

Add:

- `TargetEntityType`
- `EvidenceStrength`
- `EvidencePolarity`

#### `tblConflictPolicies`

Add:

- `MinimumEvidenceStrengthForValue`

#### `tblConfidencePolicies`

Add:

- `ResultConfidence`
- `CorroborationRule`

Keep `WeightOrScore` available for non-Identification scopes.

#### `tblRules`

Add workbook-only:

- `LegacyRuleId`

Rules:

- optional;
- informational only;
- not a runtime identity;
- never exported;
- must not alter RuleId uniqueness/supersession logic.

Do not add other new columns unless the current canonical model requires them. If a new column appears necessary, stop and document the exact canonical requirement before widening scope.

### 3. Controlled value lists

The POC must author the Schema 1.1.0 controlled code sets:

- `EVIDENCE_STRENGTH`: STRONG, MEDIUM, WEAK with correct SortOrder;
- `CONFIDENCE`: HIGH, MEDIUM, LOW, UNKNOWN;
- `EVIDENCE_POLARITY`: SUPPORTS, CONTRADICTS;
- `TIE_BEHAVIOR`: UNKNOWN, MANUAL_REVIEW;
- `CORROBORATION_RULE`: NONE_REQUIRED, INDEPENDENT_SOURCE_CLASS;
- `IDENTIFICATION_DIMENSION`: governed subset of canonical entity types;
- `RULE_TYPE` including IDENTIFICATION.

Do not add `Supporting` as an executable code.

### 4. Synthetic Identification authoring examples

Add only synthetic POC rows sufficient to prove the model.

At minimum include:

#### Effective synthetic rule

One synthetic Effective IDENTIFICATION rule that:

- targets a canonical dimension;
- uses a field with an appropriate MaxEvidenceStrength;
- produces a `ClassificationCandidate`;
- carries TargetEntityType / EvidenceStrength / EvidencePolarity;
- has explicit PRE_SALES phase assignment;
- has valid condition-group/condition rows;
- resolves to existing synthetic master data;
- uses no numeric candidate score;
- exports successfully in controlled-equivalent reference validation.

#### Draft synthetic legacy-traceability rule

One synthetic Draft IDENTIFICATION rule that:

- has a fresh governed RuleId;
- contains a synthetic `LegacyRuleId` value;
- has dependent phase/group/condition/output rows;
- is intentionally not runtime eligible;
- proves that the rule and **all dependent rows** disappear from the controlled runtime projection;
- proves LegacyRuleId itself never appears in exported JSON.

Do not reproduce confidential prior rule conditions or proprietary payloads.

Do not seed real R-FMT/R-TYP logic in this implementation task. T3c remains a backlog/governance input.

### 5. Effective-only dependency-safe controlled projection

Implement one central runtime-eligibility projection used by both:

- the independent Python reference exporter;
- the VBA JSON exporter/preview path.

For controlled export, runtime eligibility is:

`Status = Effective AND EffectiveFrom <= export/evaluation date AND (EffectiveTo empty OR export/evaluation date < EffectiveTo)`

The filter must apply to the **whole dependent rule graph**.

If a rule is not runtime eligible, exclude its dependent:

- rulePhases;
- conditionGroups;
- ruleConditions;
- ruleOutputs;
- supersession/runtime references where the normalized model requires runtime-only relationships.

The resulting JSON must have no orphan references.

Do not merely filter `rules` and leave child rows behind.

### 6. DEV behavior

Preserve the canonical distinction:

- CONTROLLED projection: runtime-eligible Effective rules only;
- DEV projection: may include Reviewed rules only when explicitly configured/selected according to existing requirements.

Do not make Draft or InReview executable in DEV.

The public POC may remain blocked from claiming an actual controlled release. It still must be able to **prove the controlled projection logic** deterministically in the reference/VBA conformance path without representing the synthetic POC as a released production workbook.

Document exactly how this distinction is implemented.

### 7. Identification policy authoring

Add synthetic Schema 1.1.0 policy rows sufficient to prove:

- `minimumEvidenceStrengthForValue = MEDIUM`;
- Identification confidence can use `resultConfidence` + `corroborationRule`;
- Identification confidence rows have no `WeightOrScore`;
- non-Identification confidence rows may retain existing numeric weight behavior.

These are synthetic conformance rows, not approved production regulatory confidence content.

### 8. Workbook semantic validation

Extend both independent and VBA-side validation so authoring errors are caught before export.

At minimum validate:

- required Schema 1.1.0 columns/tables;
- Identification candidate TargetEntityType;
- dimension-scoped OutputCode target;
- EvidenceStrength controlled value;
- EvidencePolarity controlled value;
- MaxEvidenceStrength present for fields used as Identification evidence;
- output strength does not exceed field ceiling;
- IDENTIFICATION conflict/dimension alignment;
- MinimumEvidenceStrengthForValue controlled value;
- ResultConfidence / CorroborationRule controlled values;
- no numeric Identification candidate score;
- no numeric Identification confidence weight;
- correct evidence-strength SortOrder;
- no direct Draft/InReview controlled export;
- no orphan dependent rows after projection;
- LegacyRuleId never enters executable JSON;
- LegacyRuleId cannot substitute for RuleId;
- current 1.0.0 compatibility assets remain untouched where they are not part of the POC migration.

Do not duplicate the entire Python T3a validator in VBA. Implement the workbook-authoring checks needed to prevent invalid export and always run the exported JSON through the independent schema/semantic validator in CI.

### 9. Deterministic export

Update:

- Python reference exporter;
- VBA JSON builder;
- POC manifest;
- golden Runtime JSON hash;
- source-workbook hashes/checksums;
- fixture expectations.

Two deterministic exports from equivalent workbook tables must remain byte-identical.

Python remains build/CI verification only.

PowerShell must not generate, repair or reinterpret Runtime JSON.

### 10. Export traceability

Preserve existing export-history behavior.

For deterministic POC evidence, ensure export evidence identifies:

- SchemaVersion 1.1.0;
- MappingVersion;
- SourceWorkbookVersion;
- export type/profile;
- validation status/run identifier;
- SHA-256.

Do not add legacy RuleIds to runtime export history.

## Required fixture coverage

Extend the workbook-model POC fixtures.

At minimum:

### Valid/boundary

1. Schema 1.1.0 base POC with Effective synthetic Identification rule;
2. Draft Identification rule with dependent rows excluded from controlled projection;
3. same code string in two dimensions, candidate resolved by TargetEntityType;
4. Identification strength exactly equal to field ceiling;
5. MEDIUM minimum-evidence floor;
6. weightless Identification confidence row;
7. non-Identification weighted confidence row preserved.

### Invalid

1. candidate OutputCode outside TargetEntityType;
2. TargetEntityType/conflict dimension mismatch;
3. unknown EvidenceStrength;
4. unknown EvidencePolarity;
5. output strength exceeds MaxEvidenceStrength;
6. missing MaxEvidenceStrength on required Identification field;
7. numeric Identification candidate score;
8. numeric Identification confidence weight;
9. bad STRONG/MEDIUM/WEAK SortOrder;
10. Draft rule present in controlled projection;
11. excluded rule leaves orphan phase/group/condition/output row;
12. LegacyRuleId serialized to JSON;
13. LegacyRuleId reused as RuleId/runtime identity;
14. non-Effective rule incorrectly treated as controlled runtime eligible.

Use stable POC error codes.

## Native Excel/VBA boundary

Automated CI must validate source/VBA/reference-export equivalence.

If Claude has access to supported Windows desktop Excel and can execute:

- `build/Build-eMASMappingPoc.ps1`
- `build/Test-eMASMappingPoc.ps1`

record the evidence.

Otherwise explicitly report:

`NATIVE_EXCEL_QUALIFICATION_PENDING`

Do not claim native Excel qualification from source inspection or Python tests.

## Required regression

Run and record:

- `python build/validate_xlsm_vba_poc.py`;
- `python -m unittest discover -s tests/vba -p "test_*.py" -v`;
- Runtime schema fixture tests;
- schema semantic tests;
- static runtime tests;
- report mapping/reporting regressions;
- any workbook generator deterministic checks;
- PowerShell runtime-contract CI where affected.

The existing Windows PowerShell 5.1 UTF-8 assertion remains unrelated unless this task changes that behavior.

## Canonical documentation

Update only what is necessary to synchronize the implemented POC behavior.

At minimum review/update:

- `docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md`;
- `config/authoring/poc/README.md`;
- `config/vba/README.md`;
- `build/README.md`;
- POC manifest metadata.

Do not rewrite higher-authority requirements unless implementation exposes a genuine contradiction. Stop and report instead.

## Expected implementation areas

Likely allowed paths include:

- `config/authoring/poc/workbook-source-parts/**`;
- `config/authoring/poc/workbook-source.json` or its source assembler if generated;
- `config/authoring/poc/poc-manifest.json`;
- `config/authoring/poc/fixtures/**`;
- `config/vba/modules/*.bas`;
- `build/emas_xlsx_poc*.py`;
- `build/generate_emas_mapping_poc_workbook.py` only if required;
- `build/validate_xlsm_vba_poc.py`;
- `build/Test-eMASMappingPoc.ps1` only where Schema 1.1.0 validation text/contract must change;
- `tests/vba/**`;
- the documentation listed above;
- this task's report/status files.

Do not modify T3a schema/validator files merely to make T3b pass. If the accepted Schema 1.1.0 contract blocks a legitimate workbook need, stop and report the contract mismatch.

## Forbidden

Do not implement or modify:

- T4 `IdentificationInterpretation`;
- CEC/T1a;
- RepositoryDiscovery;
- BackboneXmlInventory;
- v4 XML parsing;
- regional T1b evidence;
- real legacy rule migration;
- real regulatory rule packs;
- production controlled XLSM binary;
- customer deliverables;
- numeric Identification weights;
- T3c U2–U9 policy decisions;
- PowerShell JSON generation.

## Report

Create/update:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT/reports/CLAUDE.md`

Include:

- workbook tables/columns changed;
- Schema 1.1.0 controlled lists added;
- synthetic Identification rows added;
- exact runtime-eligibility projection;
- dependent-row filtering algorithm;
- DEV vs controlled behavior;
- LegacyRuleId treatment/proof of non-export;
- Python and VBA mapping changes;
- validation/error codes added;
- deterministic source/XLSX/JSON hashes;
- fixture matrix/results;
- all regression results;
- native Excel status;
- changed files;
- blockers/open issues.

## Git workflow

Use branch:

`implementation/emas-ms04-identification-workbook-export-claude`

Open a **draft PR into `demo/end-to-end-mvp`**.

Do not merge.

## Acceptance criteria

Ready for ChatGPT central review when:

1. synthetic workbook authors Schema 1.1.0 Identification content;
2. reference and VBA exporters produce Schema 1.1.0-compatible output;
3. controlled projection includes only runtime-eligible Effective rules;
4. all dependent rule rows are filtered consistently with no orphans;
5. Draft/InReview rules cannot leak into controlled output;
6. LegacyRuleId is workbook-only and absent from Runtime JSON;
7. no historical mapping rule is directly imported;
8. no numeric Identification weight is introduced;
9. dimension-scoped candidate resolution is preserved;
10. deterministic export/golden-hash tests pass;
11. existing non-Identification behavior is preserved;
12. native Excel qualification is either evidenced or explicitly pending;
13. T4 remains unimplemented.
