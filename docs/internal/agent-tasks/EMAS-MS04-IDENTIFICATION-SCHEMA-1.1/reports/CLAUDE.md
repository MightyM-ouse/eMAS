# Claude Report — EMAS-MS04-IDENTIFICATION-SCHEMA-1.1 (T3a)

**Status:** `IMPLEMENTATION_COMPLETE — READY FOR REVIEW`
**Agent:** Claude (single worker)
**Branch:** `implementation/emas-ms04-identification-schema-1-1-claude`
**Based on:** `coordination/emas-ms04-identification-schema-1-1` @ `2cf1b52`. This contains the authoritative base `9d622cf` and accepted T1a `08f4d0d`.
**Draft PR target:** `demo/end-to-end-mvp`
**Date:** 2026-10-06

## Summary

| Item | Result |
|---|---|
| Schema 1.1.0 | Explicit MINOR version. `schemaVersion ∈ {1.0.0, 1.1.0}`. One schema tree; a root version gate rejects every 1.1.0 property in a document labelled 1.0.0. |
| 1.0.0 compatibility | **Proven.** The 16 original fixtures are byte-unchanged and keep their exact expectations. A 1.0.0 confidence policy still requires `weightOrScore`. |
| 1.1 fields as 1.0.0 | **Rejected by JSON Schema alone** (`SCHEMA_VERSION_FEATURE`), for each of the 7 new properties. `ruleType = IDENTIFICATION` in 1.0.0 is rejected semantically (`SEM_VERSION_FEATURE`). |
| Semantic guards | Dimension-scoped candidate resolution; candidate metadata; Identification-scoped rule type, tie behavior, floor, confidence evidence strength, result confidence and corroboration rule; evidence-strength ceiling; ordinal order; no numeric Identification weights. |
| Global code uniqueness | **Not added.** A fixture with the same code in two dimensions is valid. A test places `UNKNOWN` in all 9 master-data collections and the document stays valid. |
| Fixtures | 43/43 manifest expectations pass: the 16 originals plus 27 new (3 valid, 2 boundary, 22 invalid, including 5 version/compatibility negatives; see §5). |
| Python tests | `tests/schema`: 44 passed (14 existing + 30 new). `tests/runtime` (py): 12 passed. |
| Loader | PowerShell 7.5.2 (macOS): 28/28 passed (22 existing + 6 new). It supports 1.0.0 and 1.1.0, rejects 1.2.0 and 9.0.0, and rejects 1.1.0 features in 1.0.0 (`CFG-COMPAT-004`). |
| Regression | XLSM/VBA POC conformance, VBA tests, report mappings/reporting and operational skills all pass unchanged. |
| Out of scope, untouched | Workbook, VBA, export, CEC/T1a, RepositoryDiscovery, BackboneXmlInventory, IdentificationInterpretation, report mappings, prior mapping artifacts, the Windows PS5.1 UTF-8 assertion. |

---

## 1. Version-dispatch approach

I chose the smallest approach that proves all six compatibility behaviours. It uses **one schema tree with a root version gate**, not a duplicated 1.1 tree.

1. `configuration.schemaVersion` changes from `const "1.0.0"` to `enum ["1.0.0", "1.1.0"]` (`defs/catalog.schema.json`).
2. The 1.1.0 properties are added as **optional** properties of the shared definitions (`ruleOutput`, `conflictPolicy`, `confidencePolicy`, `fieldDefinition`). `confidencePolicy.weightOrScore` moves from `required` to conditional.
3. The root schema has three `allOf` branches:
   - `allOf[0]` `VERSION-GATE-1.0.0`: if `schemaVersion = 1.0.0`, then each 1.1.0 property is forbidden (`not/anyOf/required`) on `fieldCatalogue[]`, `ruleOutputs[]`, `policies.conflictPolicies[]` and `policies.confidencePolicies[]`.
   - `allOf[1]`: if `1.0.0`, then `confidencePolicies[].weightOrScore` is required, exactly as before.
   - `allOf[2]`: if `1.1.0`, then a confidence policy with `scope = IDENTIFICATION` requires `resultConfidence` and `corroborationRule`; every other scope still requires `weightOrScore`.
4. In `build/validate_emas_schema.py`, schema errors raised under `allOf[0]` get the stable code `SCHEMA_VERSION_FEATURE`. An enum failure on `configuration.schemaVersion` gets `SCHEMA_UNSUPPORTED_VERSION`. All other structural errors keep `SCHEMA_ERROR`, so existing invalid fixtures fail for the same reason as before.
5. The semantic validator selects its required lists and codes by version. The 1.1.0 code lists and Identification guards apply to 1.1.0 documents only; 1.0.0 documents run the unchanged 1.0.0 checks.
6. There is no compatibility adapter. 1.0.0 documents are never rewritten into 1.1.0 semantics, and `SchemaVersionAdapters` stays `@{}`.

## 2. Exact schema fields added (1.1.0, all optional at the structural level)

| Definition | Property | Type | Notes |
|---|---|---|---|
| `ruleOutput` | `targetEntityType` | identifier | Required semantically on IDENTIFICATION `ClassificationCandidate` |
| `ruleOutput` | `evidenceStrength` | identifier | Same as above |
| `ruleOutput` | `evidencePolarity` | identifier | Same as above |
| `conflictPolicy` | `minimumEvidenceStrengthForValue` | identifier | Weak-floor **capability** only. No production floor row is added. |
| `confidencePolicy` | `resultConfidence` | identifier | Required for `scope = IDENTIFICATION` in 1.1.0 |
| `confidencePolicy` | `corroborationRule` | identifier | Same as above |
| `confidencePolicy` | `weightOrScore` | number | Requiredness is now conditional (§1). Numeric support is kept for all non-IDENTIFICATION scopes. |
| `fieldDefinition` | `maxEvidenceStrength` | identifier | Authoring ceiling; never rewrites evidence |

`codeValue.sortOrder` already existed. It is preserved and is now **required to encode the ordinal order** of `EVIDENCE_STRENGTH` in 1.1.0.

The schema has no `Outcome` or `SupportStatus` property (asserted by a test). The `eMAS.MS04.PreSales.Identification/1.0` result writer is not implemented.

## 3. Controlled code lists (1.1.0 documents only)

| List | Codes | Enforcement |
|---|---|---|
| `EVIDENCE_STRENGTH` | `STRONG`, `MEDIUM`, `WEAK` | Exact set. `sortOrder` must be present, unique and ascending in STRONG > MEDIUM > WEAK (`SEM_ORDINAL_ORDER`). |
| `CONFIDENCE` | `HIGH`, `MEDIUM`, `LOW`, `UNKNOWN` | Exact set |
| `EVIDENCE_POLARITY` | `SUPPORTS`, `CONTRADICTS` | Exact set; required list |
| `TIE_BEHAVIOR` | `UNKNOWN`, `MANUAL_REVIEW` | Exact set; required list |
| `CORROBORATION_RULE` | `NONE_REQUIRED`, `INDEPENDENT_SOURCE_CLASS` | Exact set; required list |
| `IDENTIFICATION_DIMENSION` | Any subset of the 9 canonical master-data entity types | Required list. Non-canonical codes give `SEM_UNKNOWN_CODE`. |
| `RULE_TYPE` | Must contain `IDENTIFICATION` when IDENTIFICATION rules or conflict policies exist | `SEM_CONTROLLED_REFERENCE` |

These codes come from the accepted T3 model. I created no display synonyms (such as `Supporting`) as executable codes. 1.0.0 `REQUIRED_CODES` is unchanged, so the 1.0.0 base with `EVIDENCE_STRENGTH = [HIGH]` stays valid as 1.0.0. The canonical codes apply from 1.1.0, and `HIGH` is rejected there (fixture `identification-noncanonical-evidence-strength-1.1`).

`IDENTIFICATION_DIMENSION` allows the full canonical dimension set (Requirements v3.1 §8). Each document's list selects which dimensions its Identification rules may target. I did not hard-code the six "initial" dimensions from the T3 sketch, so that choice stays governed content.

## 4. Semantic guards added (`build/emas_schema_semantics.py::_identification_issues`)

| Guard | Error code |
|---|---|
| `ruleType = IDENTIFICATION` in a 1.0.0 document | `SEM_VERSION_FEATURE` |
| `IDENTIFICATION` not in `RULE_TYPE` (rule or conflict policy) | `SEM_CONTROLLED_REFERENCE` |
| IDENTIFICATION rule without `conflictGroup` | `SEM_IDENTIFICATION_METADATA_REQUIRED` |
| `conflictGroup` / `targetEntityType` not an approved `IDENTIFICATION_DIMENSION` | `SEM_IDENTIFICATION_DIMENSION` |
| `targetEntityType ≠ conflictGroup` | `SEM_IDENTIFICATION_DIMENSION_MISMATCH` |
| **Candidate `outputCode` not in the declared `targetEntityType` collection** (dimension-scoped; replaces the global `all_master_codes` lookup for IDENTIFICATION rules only) | `SEM_OUTPUT_TARGET` |
| Missing `targetEntityType` / `evidenceStrength` / `evidencePolarity` on an IDENTIFICATION candidate | `SEM_IDENTIFICATION_METADATA_REQUIRED` |
| `evidenceStrength`, `evidencePolarity`, `tieBehavior`, `minimumEvidenceStrengthForValue`, `maxEvidenceStrength`, Identification `confidencePolicy.evidenceStrength`, `resultConfidence` or `corroborationRule` does not resolve to its list | `SEM_CONTROLLED_REFERENCE` (the path names the property) |
| **Output `evidenceStrength` exceeds the weakest `maxEvidenceStrength` of the rule's non-negated evidence fields, across all OR groups**; or the rule has no positive evidence field | `SEM_EVIDENCE_STRENGTH_CEILING` |
| A field used as evidence by an IDENTIFICATION rule has no ceiling | `SEM_IDENTIFICATION_METADATA_REQUIRED` |
| `outputValue` on an IDENTIFICATION candidate, or `weightOrScore` on an IDENTIFICATION confidence row | `SEM_IDENTIFICATION_NUMERIC_WEIGHT` |
| Identification-only properties used outside Identification scope | `SEM_IDENTIFICATION_METADATA_SCOPE` |

**Ceiling semantics.** Negated conditions are treated as guards, not evidence, so they do not cap strength (boundary fixture). `MISSING` asserts absence evidence and does count. The ceiling uses the **weakest** field across every OR group, because a rule's output strength does not know which group fired (invalid fixture `identification-weak-field-mixed-group-1.1`). The guard is read-only: a test proves the instance is unchanged after validation.

**Scoping.** Every new guard is scoped to `ruleType = IDENTIFICATION`, Identification conflict policies or `scope = IDENTIFICATION`. Non-Identification `ClassificationCandidate` outputs keep 1.0.0 global resolution, even inside 1.1.0 documents (test). Aliases are untouched, and `Supporting → MEDIUM` is not implemented through aliases.

## 5. Fixture matrix

The 1.1.0 fixtures are built from base fragments 01–04 plus `base/05-identification-1.1.json`. That fragment holds a synthetic IDENTIFICATION rule `ID-TS-001` (TECHNICAL_STANDARD → `ICH_ECTD_3_2_2`, STRONG, SUPPORTS), three synthetic CEC-projection fields with ceilings STRONG/MEDIUM/WEAK, the canonical lists and an IDENTIFICATION conflict policy. All content is synthetic (`SYNTHETIC_FIXTURE`).

| # | Fixture | Expected | Result |
|---|---|---|---|
| V1 | base 1.1 (minimal Identification rule; STRONG from STRONG-capped structured-XML field; ordinal list with sortOrder) | valid | PASS |
| V2 | `valid/identification-weightless-confidence-1.1` (ordinal confidence rows; floor capability) | valid | PASS |
| V3 | `valid/identification-same-code-two-dimensions-1.1` (`OTHER` in TECHNICAL_STANDARD and REGIONAL_IMPLEMENTATION, each resolved by `targetEntityType`) | valid | PASS |
| B1 | `boundary/identification-strength-equals-ceiling-1.1` (STRONG with a negated WEAK guard) | valid | PASS |
| B2 | `boundary/identification-contradicting-medium-1.1` (CONTRADICTS at MEDIUM = ceiling) | valid | PASS |
| C1 | the 16 original 1.0.0 fixtures (files unchanged) | as before | 16/16 PASS |
| I1 | `identification-candidate-outside-dimension-1.1` (`EU_MODULE1` exists globally, not in TECHNICAL_STANDARD) | `SEM_OUTPUT_TARGET` | PASS |
| I2 | `identification-dimension-mismatch-1.1` | `SEM_IDENTIFICATION_DIMENSION_MISMATCH` | PASS |
| I3 | `identification-unknown-evidence-strength-1.1` (`SUPPORTING`) | `SEM_CONTROLLED_REFERENCE` | PASS |
| I4 | `identification-unknown-evidence-polarity-1.1` | `SEM_CONTROLLED_REFERENCE` | PASS |
| I5 | `identification-unknown-tie-behavior-1.1` | `SEM_CONTROLLED_REFERENCE` | PASS |
| I6 | `identification-unknown-result-confidence-1.1` | `SEM_CONTROLLED_REFERENCE` | PASS |
| I7 | `identification-unknown-corroboration-rule-1.1` | `SEM_CONTROLLED_REFERENCE` | PASS |
| I8 | `identification-strength-exceeds-ceiling-1.1` (STRONG solely from a MEDIUM-capped field) | `SEM_EVIDENCE_STRENGTH_CEILING` | PASS |
| I8b | `identification-weak-field-mixed-group-1.1` (STRONG with a WEAK-only OR group) | `SEM_EVIDENCE_STRENGTH_CEILING` | PASS |
| I9 | `version-1.1-property-labelled-1.0.0` | `SCHEMA_VERSION_FEATURE` | PASS |
| I9b | `version-1.1-field-ceiling-labelled-1.0.0` | `SCHEMA_VERSION_FEATURE` | PASS |
| I9c | `version-identification-rule-labelled-1.0.0` | `SEM_VERSION_FEATURE` | PASS |
| I9d | `version-1.0.0-confidence-weight-missing` (1.0.0 requiredness preserved) | `SCHEMA_ERROR` | PASS |
| I10 | `version-unsupported-schema-version` (`1.2.0`) | `SCHEMA_UNSUPPORTED_VERSION` | PASS |
| I11 | `identification-noncanonical-evidence-strength-1.1` (`HIGH`) | `SEM_REQUIRED_CODE`, `SEM_UNKNOWN_CODE` | PASS |
| I12 | `identification-ordinal-sort-order-1.1` | `SEM_ORDINAL_ORDER` | PASS |
| I13 | `identification-numeric-weight-1.1` | `SEM_IDENTIFICATION_NUMERIC_WEIGHT` | PASS |
| I14 | `identification-candidate-output-value-1.1` | `SEM_IDENTIFICATION_NUMERIC_WEIGHT` | PASS |
| I15 | `identification-unapproved-dimension-1.1` | `SEM_IDENTIFICATION_DIMENSION` | PASS |
| I16 | `identification-metadata-missing-1.1` | `SEM_IDENTIFICATION_METADATA_REQUIRED` | PASS |
| I17 | `identification-metadata-out-of-scope-1.1` | `SEM_IDENTIFICATION_METADATA_SCOPE` | PASS |
| I18 | `identification-dimension-not-canonical-1.1` | `SEM_UNKNOWN_CODE` | PASS |

I checked every invalid fixture for isolation: each produces **only** its expected code. The one exception is I11, where the non-canonical list also cascades into `SEM_CONTROLLED_REFERENCE` on the fields that reference it; that is expected. `test_controlled_reference_paths_are_stable` asserts the exact JSON path and a single issue for I3–I7.

Totals: `python build/validate_emas_schema.py` → **43 PASS, 0 FAIL**.

## 6. Proof: 1.0.0 cannot silently use 1.1-only executable fields

- `test_every_1_1_property_is_rejected_by_json_schema_alone_when_labelled_1_0_0` validates with **bare `Draft202012Validator`**, with no semantic layer. It sets each of the 7 properties on a valid 1.0.0 document. Every case fails and maps only to `SCHEMA_VERSION_FEATURE`. Relabelling the same document as `1.1.0` removes the gate error.
- `ruleType = IDENTIFICATION` in 1.0.0 → `SEM_VERSION_FEATURE` (I9c).
- The loader independently blocks the same cases (`CFG-COMPAT-004`, §7).
- `test_all_original_1_0_0_fixtures_keep_their_expectations`: all 16 original fixtures still pass with the same validity and codes. `git diff` on `config/schema/examples/{base/01–04,valid,boundary,invalid}` for the original files is empty.

## 7. PowerShell loader

| File | Change |
|---|---|
| `engine/core/eMAS.Configuration.Contract.psm1` | `SchemaVersion = '1.1.0'`; `SupportedSchemaVersions = @('1.0.0', '1.1.0')`; `SchemaVersionAdapters = @{}` (unchanged); new `IdentificationSchemaVersion`, `IdentificationRuleType`, `VersionFeatureContracts` (section-scoped 1.1.0 properties) |
| `engine/core/private/eMAS.RuntimeConfiguration.Validation.ps1` | New read-only helper `Get-eMASSchemaVersionFeatureUse`. When a document declares `1.0.0` and uses any 1.1.0 property or `ruleType IDENTIFICATION`, the loader emits blocking `CFG-COMPAT-004`. |

Why the validation file changed: the TASK requires 1.1-only fields not to be silently accepted as 1.0.0, and the loader is the runtime gate T4 will rely on. The check is section-scoped, so 1.0.0 `relationships[].targetEntityType` and `confidencePolicies[].evidenceStrength` are **not** flagged (test).

The loader stays read-only and fail-fast. It never repairs or rewrites JSON and does not execute Identification rules.

New harness tests (all pass on PowerShell 7.5.2):
- schema version 1.0.0 remains supported (`CFG-COMPAT-001`);
- schema version 1.1.0 is supported, including Identification properties (`Valid`, `CFG-COMPAT-001`);
- unsupported 1.2.0 is blocking (`CFG-COMPAT-003` plus a `CFG-VALIDATION-001` throw); the existing 9.0.0 test still passes;
- 1.0.0 with a 1.1.0 property is blocking (`CFG-COMPAT-004` plus a throw);
- 1.0.0 with an IDENTIFICATION rule is blocking (`CFG-COMPAT-004`);
- 1.0.0 properties with colliding names are not flagged.

The harness did not touch the UTF-8 metadata assertion, and I made no test-fixture file changes under `tests/fixtures/runtime-config`; the 1.1.0 variants are written to the harness temp directory.

**Minimum-engine compatibility.** No engine-version constant or `minimumEngineVersion` enforcement exists in the loader at this base; I checked by grepping `engine/`. There was therefore nothing to "keep enforced". I did not invent an engine-version scheme. The 1.1.0 fixtures declare `minimumEngineVersion = 1.1.0`. This is listed as open issue O-2.

## 8. Changed files

| Area | Files |
|---|---|
| Schema | `config/schema/eMAS-runtime-config.schema.json`, `defs/catalog.schema.json`, `defs/rules.schema.json`, `defs/policies.schema.json` |
| Validators | `build/validate_emas_schema.py`, `build/emas_schema_model.py`, `build/emas_schema_semantics.py` |
| Fixtures | `config/schema/examples/fixture-manifest.json` (adds `supportedSchemaVersions`; 27 entries appended; the original 16 entries are unchanged and first); new `base/05-identification-1.1.json`; 2 valid, 2 boundary and 22 invalid patch files |
| Tests | new `tests/schema/test_identification_schema_1_1.py`; `tests/runtime/Test-eMASRuntimeConfiguration.ps1` (6 new tests only) |
| Loader | `engine/core/eMAS.Configuration.Contract.psm1`, `engine/core/private/eMAS.RuntimeConfiguration.Validation.ps1` |
| Canonical docs | `docs/configuration/04_eMAS_Runtime_JSON_Contract.md` (v1.3), `05_eMAS_Normalized_Rule_Model.md` (v1.2), `07_eMAS_Data_Dictionary.md` (v1.1), `08_eMAS_Schema_Validation_and_Fixture_Contract.md` (v1.1), `config/schema/README.md`, `tests/schema/README.md` |
| Report | this file |

`engine/core/eMAS.RuntimeConfiguration.psm1` is **not** changed. No forbidden path is changed.

## 9. Canonical documentation synchronized

- **Runtime JSON Contract §3.1 (new):**
  - Schema 1.1.0 and supported-version behaviour;
  - the dispatch design and added-fields table;
  - governed code lists and ordinal/no-weight semantics;
  - dimension-scoped resolution, with no global uniqueness;
  - normalization kept engine-side;
  - result contract without `Outcome`/`SupportStatus`.
- **Runtime JSON Contract §5, §8, §9 and §14:** updated. §14 now states the loader behaviour.
- **Rule Model:**
  - §7.1 covers Identification candidates and the ceiling;
  - §10 covers ordinal precedence, tie behaviour, the floor and weightless confidence;
  - §13 covers dimension-scoped resolution.
- **Data Dictionary:**
  - field rows for `MaxEvidenceStrength`, `TargetEntityType`, `EvidenceStrength`, `EvidencePolarity`, `MinimumEvidenceStrengthForValue`, `ResultConfidence` and `CorroborationRule`;
  - conditional `WeightOrScore`;
  - `SortOrder` as ordinal for `EVIDENCE_STRENGTH`;
  - new §55.8 code sets;
  - §54 categories;
  - change-control note that the workbook implementation is T3b.
- **Fixture Contract:** stable `SCHEMA_*` specialisations, the §5.3.1 Identification guards, 12 new error codes and the 1.1.0 fixture assembly.

## 10. CI / regression results (local, macOS)

The environment was Python 3.14.4 in a venv with `build/requirements-schema-validation.txt` (`jsonschema[format]==4.26.0`), and PowerShell 7.5.2.

| Command | Result |
|---|---|
| `python build/validate_emas_schema.py` | 43 PASS / 0 FAIL — "Schema and semantic fixture validation passed." |
| `python -m unittest discover -s tests/schema -p "test_*.py"` | Ran 44, OK |
| `python -m unittest discover -s tests/runtime -p "test_*.py"` (static runtime-contract tests) | Ran 12, OK |
| `pwsh tests/runtime/Test-eMASRuntimeConfiguration.ps1` | 28 total, 0 failed |
| `python build/validate_xlsm_vba_poc.py` | Passed (POC still exports and validates as Schema 1.0.0) |
| `python -m unittest discover -s tests/vba` | Ran 4, OK |
| `python build/validate_report_mappings.py` / `tests/reporting` | PASS / Ran 28, OK |
| `python build/validate_operational_skills.py` / `tests/skills` | Pass / OK |

I could not run Windows PowerShell 5.1 locally. It runs in the `powershell-runtime-contracts.yml` CI job on the PR. The new PowerShell code uses only PS 5.1-compatible constructs: `[pscustomobject]`, `PSObject.Properties[...]` and `ArrayList.ToArray()`. The known PS 5.1 UTF-8 assertion is pre-existing; this change does not touch it.

## 11. Proof that no global code-uniqueness rule was added

- `test_no_global_cross_dimension_code_uniqueness` covers both the V3 fixture and a document with `UNKNOWN` in all 9 master-data collections. Both are valid.
- No `CROSS_DIMENSION` check exists in the validator source (asserted).
- Per-collection master-data code uniqueness, which already existed, is unchanged.

## 12. Blockers and open issues

| ID | Issue | Proposed owner |
|---|---|---|
| O-1 | `docs/CANONICAL_DOCUMENT_INDEX.md`, `docs/index.md` and `docs/configuration/README.md` still show the previous versions of documents 04/05/07/08. These files are outside T3a's allowed file list, so I did not edit them. They need a one-line version refresh at merge/coordination. | Coordinator |
| O-2 | There is no engine-version constant and no `minimumEngineVersion` enforcement in the loader at this base. The 1.1.0 fixtures declare `1.1.0`, but nothing enforces it. Defining an engine-version scheme is a separate decision. | Technical Architect / PowerShell Lead |
| O-3 | The XLSM POC and workbook still export Schema 1.0.0 with the illustrative `EVIDENCE_STRENGTH = HIGH`. That remains valid as 1.0.0. Authoring and exporting 1.1.0 is T3b. | T3b |
| O-4 | Decision point: the semantic validator **rejects** numeric weights on Identification candidates and confidence rows. This enforces "no numeric Identification weights until approved". If weights are approved later, a schema MINOR revision must relax this guard. | PO + Migration SME |
| O-5 | The ceiling treats negated conditions as non-evidence, and `MISSING` as evidence. Central review should confirm this interpretation. | Central review |
| O-6 | Windows PowerShell 5.1 and PowerShell 7.6 on Windows were not run locally; CI on the draft PR is the evidence. | CI |

There are no blockers to central review. T3c (PR #50) decisions U1–U11 were not implemented. The T3c guard mapping G1–G4 and G8 is covered by the capability added here, and the content remains T3b/T5 work.
