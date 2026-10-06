# Claude Report — EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT (T3b)

**Status:** `IMPLEMENTATION_COMPLETE — READY FOR REVIEW` · `NATIVE_EXCEL_QUALIFICATION_PENDING`
**Agent:** Claude (single worker)
**Branch:** `implementation/emas-ms04-identification-workbook-export-claude`
**Based on:** `coordination/emas-ms04-identification-workbook-export` @ `f9358b1`, which contains the authoritative base `e83123b` (T3a merged)
**Draft PR target:** `demo/end-to-end-mvp`
**Date:** 2026-10-06

## Summary

| Item | Result |
|---|---|
| Schema | The synthetic POC now authors and exports **Runtime JSON Schema 1.1.0**. Mapping and workbook version are 0.2.0. |
| Projection | One runtime-eligibility projection is shared by the reference exporter and the VBA exporter. It filters the **whole dependent rule graph**: phases, condition groups, conditions, outputs and `RULE_SUPERSESSION`. |
| Draft/InReview | Never exported, in DEV or CONTROLLED. Proven by the base export, unit tests, and fixtures that deliberately inject faults. |
| LegacyRuleId | Workbook-only. It is dropped by the projection and by the builder, and is absent from the JSON (checked by the scanner and the VBA guard). It can never act as a RuleId. |
| Weights | No numeric Identification candidate score or confidence weight. The non-Identification weighted confidence row is preserved. |
| Candidate resolution | Dimension-scoped, using `TargetEntityType`. Same-code-in-two-dimensions is valid. |
| Reference export | Deterministic. Golden JSON SHA-256 `3c6964c53db79815dfaa0d3b9ae4a290df2a00de5a0be4a27c055268e97cb68d`. Passes the unmodified T3a Schema 1.1.0 validator. |
| VBA/source conformance | 10 modules (1 new). Source contract and Schema 1.1.0 contract tokens pass. Reference/VBA parity tests pass. |
| Fixtures | 38/38 POC fixtures match expectations: 11 existing and 27 new. All valid/boundary variants pass Runtime JSON Schema 1.1.0. |
| Regression | All required suites pass (§10). |
| Native Excel | **`NATIVE_EXCEL_QUALIFICATION_PENDING`**: there was no Windows/desktop Excel in this environment. |
| Out of scope, untouched | T3a schema and validator files, T4, T1b/T2, CEC, RepositoryDiscovery, BackboneXmlInventory, PowerShell runtime, workflows, real rule packs, T3c U2–U9 |

---

## 1. Workbook tables and columns changed

| Table | Column(s) added | Rule |
|---|---|---|
| `tblValueLists` | `SortOrder` | **Canonical requirement:** Data Dictionary §13 lists `SortOrder` (Required). Schema 1.1.0 needs it to carry STRONG > MEDIUM > WEAK. Without it the 1.1.0 ordinal order cannot be authored, which is why I added it. |
| `tblFieldCatalogue` | `MaxEvidenceStrength` | Required for every field used by a non-negated condition of an IDENTIFICATION rule |
| `tblRules` | `LegacyRuleId` | Optional and **workbook-only**. It never participates in RuleId uniqueness or supersession, and is never exported. |
| `tblRuleOutputs` | `TargetEntityType`, `EvidenceStrength`, `EvidencePolarity` | Required on IDENTIFICATION `ClassificationCandidate` outputs; rejected on any other output |
| `tblConflictPolicies` | `MinimumEvidenceStrengthForValue` | IDENTIFICATION policies only |
| `tblConfidencePolicies` | `ResultConfidence`, `CorroborationRule` | Required for `Scope = IDENTIFICATION`, which has no `WeightOrScore`. Other scopes keep `WeightOrScore`. |

No table was added. I added no other columns.

Configuration and control changes:
- `tblConfiguration`: `SchemaVersion 1.1.0`, `MappingVersion`/`SourceWorkbookVersion 0.2.0`, `MinimumEngineVersion`/`MaximumTestedEngineVersion 1.1.0`.
- `tblTechnicalSettings.SchemaVersion = 1.1.0`.
- `tblWorkbookControl` and `tblDocumentControl` bumped to 0.2.0.

## 2. Controlled value lists (Schema 1.1.0)

| List | Codes (SortOrder) | Change |
|---|---|---|
| `EVIDENCE_STRENGTH` | STRONG (1), MEDIUM (2), WEAK (3) | Replaces the illustrative `HIGH` |
| `CONFIDENCE` | HIGH (1), MEDIUM (2), LOW (3), UNKNOWN (4) | Replaces the illustrative `HIGH`-only list |
| `EVIDENCE_POLARITY` | SUPPORTS, CONTRADICTS | New |
| `TIE_BEHAVIOR` | UNKNOWN, MANUAL_REVIEW | New |
| `CORROBORATION_RULE` | NONE_REQUIRED, INDEPENDENT_SOURCE_CLASS | New |
| `IDENTIFICATION_DIMENSION` | TECHNICAL_STANDARD, REGIONAL_IMPLEMENTATION | New. This is a governed **synthetic** subset. `REGION` is deliberately not enabled, because Region derivation is open decision U2. |
| `RULE_TYPE` | CLASSIFICATION, **IDENTIFICATION** | Extended |
| `RULE_LIFECYCLE_STATUS` | DRAFT, INREVIEW, REVIEWED, EFFECTIVE, SUPERSEDED, RETIRED | Extended to the full FR-GOV-002 set, so Draft rules can be authored |

`Supporting` is not an executable code (tested). No alias implements `Supporting → MEDIUM` (tested); that normalization stays engine-side T4 work.

## 3. Synthetic Identification rows

| Row set | Effective rule `ID-SYN-TS-001` | Draft rule `ID-SYN-RI-001` |
|---|---|---|
| Rule | IDENTIFICATION, `ConflictGroup = TECHNICAL_STANDARD`, Effective from 2026-07-13 | IDENTIFICATION, `ConflictGroup = REGIONAL_IMPLEMENTATION`, **Draft**, `LegacyRuleId = LEGACY-SYN-001` (synthetic, not a historical ID) |
| Phase | `RPH-ID-SYN-TS-001`, PRE_SALES | `RPH-ID-SYN-RI-001`, PRE_SALES |
| Group / condition | `CG-ID-SYN-TS-001` / `COND-ID-SYN-TS-001`: `CEC_XML_ROOT_ELEMENT_COMMON EQUALS "ectd"` | `CG-ID-SYN-RI-001` / `COND-ID-SYN-RI-001`: `CEC_COMMON_BACKBONE_PRESENCE EQUALS true` |
| Output | `OUT-ID-SYN-TS-001`: ClassificationCandidate `ICH_ECTD_3_2_2`, TECHNICAL_STANDARD, **STRONG = field ceiling STRONG**, SUPPORTS, no `OutputValue` | `OUT-ID-SYN-RI-001`: `EU_MODULE1`, REGIONAL_IMPLEMENTATION, MEDIUM, SUPPORTS |

**Supporting rows:**

- **Fields:** three synthetic CEC-projection fields:
  - `CEC_XML_ROOT_ELEMENT_COMMON` (STRONG)
  - `CEC_COMMON_BACKBONE_PRESENCE` (MEDIUM)
  - `CEC_DOSSIER_ROOT_PATH` (WEAK)

  Each has its operator and phase link rows.
- **Conflict policy:** `CP-ID-001`, IDENTIFICATION, `TieBehavior = MANUAL_REVIEW`, `MinimumEvidenceStrengthForValue = MEDIUM`. This is the accepted floor.
- **Confidence policies:**
  - `CONFP-ID-001`: IDENTIFICATION, STRONG → HIGH, `INDEPENDENT_SOURCE_CLASS`, with no weight.
  - `CONFP-001`: CLASSIFICATION, now `EvidenceStrength = STRONG`, keeps `WeightOrScore = 100`. This preserves non-Identification numeric behaviour.

All of these rows are synthetic conformance content (`SourceReference = SYNTHETIC`). No R-REG/R-FMT/R-TYP logic or payload is reproduced (tested: no historical-ID pattern anywhere in the workbook source).

## 4. Runtime-eligibility projection

There is one definition, implemented twice: Python `build/emas_xlsx_poc_projection.py::project_runtime_tables` and VBA `modRuntimeProjection.bas`, called from `BuildRuntimeJson`.

```text
runtime eligible = Status = Effective
                   AND EffectiveFrom <= evaluation date
                   AND (EffectiveTo is empty OR evaluation date < EffectiveTo)
```

- **Evaluation date:** the deterministic POC export uses `2026-07-13`, the date part of the fixed POC timestamp; this is Python `POC_EVALUATION_DATE` and VBA `EMAS_POC_EVALUATION_DATE` (parity tested). Normal DEV export uses the current UTC date.
- **Date comparison:** ISO `yyyy-mm-dd` text. VBA also normalizes Excel date values and date serial numbers.

### 4.1 Dependent-graph filtering algorithm

1. Compute `eligible = {RuleId | rule is runtime eligible}`.
2. `tblRules`: keep eligible rows only, and drop the workbook-only columns (`LegacyRuleId`).
3. `tblRulePhaseAssignments`, `tblConditionGroups`, `tblRuleConditions`, `tblRuleOutputs`: keep a row only if its `RuleId ∈ eligible`.
4. `tblMasterDataRelationships`: keep every non-rule relationship. Keep `RULE_SUPERSESSION` only if **both** endpoints are eligible.
5. Serialize. In VBA, `AssertRuntimeJsonHasNoLegacyRuleId` then raises an error if a `"legacyRuleId"` property or any authored LegacyRuleId value appears in the JSON text.

### 4.2 Independent verification (not a re-run of the filter)

`verify_runtime_projection(source, projected)` checks invariants over any projection, including a VBA one:

| Check | Code |
|---|---|
| Projected rule is Draft/InReview | `POC_PROJECTION_DRAFT_LEAK` |
| Projected rule is otherwise not eligible (Reviewed, Superseded, Retired, out of date window), or an eligible rule is missing | `POC_PROJECTION_INELIGIBLE` |
| Phase, group, condition or output row whose rule is not projected; condition whose group is not projected; supersession endpoint outside the projection; decision policy or finding/recommendation applicability that references an excluded condition group | `POC_PROJECTION_ORPHAN` |
| Workbook-only column present in the projection | `POC_LEGACY_RULE_ID_EXPORTED` |

`scan_runtime_json_for_legacy(runtime_json, source)` walks every key and string in the serialized JSON. It reports a `legacyRuleId` key or any authored LegacyRuleId value as `POC_LEGACY_RULE_ID_EXPORTED`.

`validate_workbook_tables` runs project → verify → build → scan for every workbook. A fixture may add `projectionOperations`, which inject an exporter fault into the projection, to prove the verifier catches it.

### 4.3 DEV versus CONTROLLED

- DEV and CONTROLLED use the **same** projection. They differ only in configuration metadata and release controls, which the existing `ValidateControlledMetadata` and the `POC-VALID-CONTROLLED` fixture enforce.
- Draft and InReview rules are never exported.
- **Reviewed rules are not exported in DEV either.** FR-GOV-006 (SHOULD) allows Reviewed rules in explicitly marked DEV exports. However, the accepted Runtime JSON Schema (1.0.0 and 1.1.0) declares `rule.status` as `const "Effective"`, so a Reviewed rule would make the DEV file schema-invalid. I did not change the T3a schema. This is reported as open issue O-1.
- The public POC still blocks controlled-release export (`eMAS_ExportControlledJson`). Controlled-projection behaviour is proven through:
  1. the shared projection;
  2. `test_dev_and_controlled_use_the_same_projection`, where the rule-graph collections are byte-equal under `ExportType = CONTROLLED`;
  3. the controlled-metadata fixture;
  4. the deterministic golden output.

## 5. LegacyRuleId treatment and proof of non-export

| Proof | Where |
|---|---|
| Authored in the workbook (`ID-SYN-RI-001.LegacyRuleId = LEGACY-SYN-001`) | `test_legacy_rule_id_is_authored_but_never_exported` |
| Exported JSON contains neither `legacyRuleId`/`LegacyRuleId` nor `LEGACY-SYN-001` | Same test, on the golden export |
| An **Effective** rule carrying a LegacyRuleId still does not serialize it | Same test (`LEGACY-SYN-002`) |
| The builder excludes the column even on unprojected tables (defence in depth) | `test_builder_excludes_workbook_only_columns_even_without_projection`; `WORKBOOK_ONLY_COLUMNS`; VBA `Array(EMAS_WORKBOOK_ONLY_RULE_COLUMNS)` |
| A value leak through another exported column is caught | Fixture `POC-ID-INVALID-012` |
| A property leak through a faulty projection is caught | Fixture `POC-ID-INVALID-012B`; `test_legacy_scanner_detects_property_and_value` |
| A LegacyRuleId cannot substitute for or reuse a RuleId | Fixture `POC-ID-INVALID-013` (`POC_LEGACY_RULE_ID_AS_RULE_ID`) |
| A historical `R-REG/FMT/TYP-nn` ID cannot be a runtime RuleId | Fixture `POC-ID-INVALID-013B`; VBA `Like "R-FMT-##"` |
| VBA refuses to return JSON containing it | `AssertRuntimeJsonHasNoLegacyRuleId` (raises `vbObjectError + 2301/2302`) |

## 6. Python and VBA mapping changes

| Area | Python reference | VBA |
|---|---|---|
| Projection | New `emas_xlsx_poc_projection.py` | New `modRuntimeProjection.bas` (`RuntimeEvaluationDate`, `IsoDateText`, `IsRuntimeEligibleRule`, `RuntimeEligibleRuleIds`, `RowBelongsToRuntimeRule`, `RelationshipIsRuntime`, `AssertRuntimeJsonHasNoLegacyRuleId`) |
| Export | `emas_xlsx_poc.build_runtime_json` projects before serializing; the model builder excludes `WORKBOOK_ONLY_COLUMNS` | `BuildRuntimeJson` uses `BuildRuntimeGraphArray` for relationships, rules, phases, groups, conditions and outputs; legacy assertion before return |
| Types | `SortOrder` typed as integer | `IsNumberHeader` includes `SortOrder` |
| Structure | `REQUIRED_TABLE_COLUMNS` includes all new columns | `ValidateWorkbookStructure` checks the new columns |
| Validation | `_validate_lifecycle_and_legacy`, `_validate_identification`, `validate_runtime_export` | `ValidateLifecycleAndLegacy`, `ValidateIdentification`; Identification candidates skip global master-code resolution |
| Constants | `POC_EVALUATION_DATE`, `RULE_LIFECYCLE_STATUSES`, `LEGACY_RULE_ID_PATTERN` | `EMAS_SCHEMA_VERSION 1.1.0`, versions 0.2.0, `EMAS_POC_EVALUATION_DATE`, `EMAS_RUNTIME_STATUS`, `EMAS_IDENTIFICATION_RULE_TYPE`, `EMAS_WORKBOOK_ONLY_RULE_COLUMNS` |
| Source contract | `validate_xlsm_vba_poc.py`: 10 required modules; new `REQUIRED_VBA_CONTRACT` tokens; `SUPPORTING` prohibited in VBA source; fixture harness supports `projectionOperations` | Module count 10 |

VBA is source-reviewed only (§11). All `.bas` files stay ASCII with CRLF (tested).

## 7. Validation and error codes

New POC codes:
- `POC_RULE_LIFECYCLE`
- `POC_LEGACY_RULE_ID_AS_RULE_ID`
- `POC_LEGACY_RULE_ID_EXPORTED`
- `POC_PROJECTION_DRAFT_LEAK`
- `POC_PROJECTION_INELIGIBLE`
- `POC_PROJECTION_ORPHAN`

Reused T3a semantic codes (same meaning at workbook level):
- `SEM_OUTPUT_TARGET` (dimension-scoped)
- `SEM_IDENTIFICATION_DIMENSION`
- `SEM_IDENTIFICATION_DIMENSION_MISMATCH`
- `SEM_CONTROLLED_REFERENCE`
- `SEM_EVIDENCE_STRENGTH_CEILING`
- `SEM_IDENTIFICATION_METADATA_REQUIRED`
- `SEM_IDENTIFICATION_METADATA_SCOPE`
- `SEM_IDENTIFICATION_NUMERIC_WEIGHT`
- `SEM_ORDINAL_ORDER`

Every exported valid/boundary JSON is additionally validated by the **unmodified** T3a `validate_emas_schema.py` (Schema 1.1.0 plus semantics).

## 8. Deterministic hashes

| Artifact | SHA-256 |
|---|---|
| Runtime JSON (golden, deterministic export) | `3c6964c53db79815dfaa0d3b9ae4a290df2a00de5a0be4a27c055268e97cb68d` |
| Generated source XLSX | `3ccfe818e630c8044253c168229170f21a18106069833f0ead33a207bf83f884` |
| Workbook source bundle | `e28ebc6c824fe58d8d0c2f7aadc3a72619e59cc5839957f112894c6ab124d1db` |

Two reference exports are byte-identical, and regenerating the XLSX gives byte-identical output (both tested). The previous 1.0.0 golden hash was `fb56f6f8…6eea`.

`poc-manifest.json` now records:
- `schemaVersion 1.1.0` and version `0.2.0`;
- `vbaModuleCount 10`;
- `nativeExcelQualification: NATIVE_EXCEL_QUALIFICATION_PENDING`;
- `runtimeProjection`, `deterministicEvaluationDate` and `workbookOnlyColumns`.

## 9. Fixture matrix

All 38 entries in `config/authoring/poc/fixtures/manifest.json` pass. I checked each invalid fixture for isolation: each emits only its expected code, except the two expected cascades noted below.

| ID | Case | Expected | Result |
|---|---|---|---|
| POC-VALID-BASE / POC-ID-VALID-001 | Schema 1.1.0 base: Effective Identification rule; Draft rule plus dependents excluded; MEDIUM floor; weightless and weighted confidence; STRONG = ceiling | valid | PASS + Schema 1.1.0 |
| POC-VALID-CONTROLLED, POC-BOUNDARY-001, POC-WARNING-VALID-001 | Existing controlled-metadata, version/date and Warning cases | valid | PASS + Schema 1.1.0 |
| POC-ID-VALID-002 | Same code `OTHER` in TECHNICAL_STANDARD and REGIONAL_IMPLEMENTATION | valid | PASS + Schema 1.1.0 |
| POC-ID-BOUNDARY-001 | MEDIUM = MEDIUM ceiling, CONTRADICTS | valid | PASS + Schema 1.1.0 |
| POC-ID-BOUNDARY-002/003/004 | Reviewed / future-dated / expired rule excluded | valid | PASS + Schema 1.1.0 |
| POC-INVALID-001…007 | Existing negatives | unchanged | PASS |
| POC-ID-INVALID-001 | Candidate outside TargetEntityType | `SEM_OUTPUT_TARGET` | PASS |
| POC-ID-INVALID-002 | TargetEntityType ≠ ConflictGroup | `SEM_IDENTIFICATION_DIMENSION_MISMATCH` | PASS |
| POC-ID-INVALID-003 / 004 | Unknown EvidenceStrength / EvidencePolarity | `SEM_CONTROLLED_REFERENCE` | PASS |
| POC-ID-INVALID-005 | STRONG output on a MEDIUM-capped field | `SEM_EVIDENCE_STRENGTH_CEILING` | PASS |
| POC-ID-INVALID-006 | Missing MaxEvidenceStrength | `SEM_IDENTIFICATION_METADATA_REQUIRED` | PASS |
| POC-ID-INVALID-007 / 008 | Numeric candidate score / Identification confidence weight | `SEM_IDENTIFICATION_NUMERIC_WEIGHT` | PASS |
| POC-ID-INVALID-009 | Bad EVIDENCE_STRENGTH SortOrder | `SEM_ORDINAL_ORDER` | PASS |
| POC-ID-INVALID-010 | Draft rule in the projection | `POC_PROJECTION_DRAFT_LEAK` | PASS |
| POC-ID-INVALID-011 | Excluded rule's output left in the projection | `POC_PROJECTION_ORPHAN` | PASS |
| POC-ID-INVALID-012 / 012B | LegacyRuleId serialized (value / property) | `POC_LEGACY_RULE_ID_EXPORTED` | PASS |
| POC-ID-INVALID-013 / 013B | LegacyRuleId reused as RuleId / historical ID as RuleId | `POC_LEGACY_RULE_ID_AS_RULE_ID` (013B also gives `SEM_RULE_INCOMPLETE`, expected) | PASS |
| POC-ID-INVALID-014 | Reviewed rule treated as eligible | `POC_PROJECTION_INELIGIBLE` | PASS |
| POC-ID-INVALID-015 | Unknown lifecycle status | `POC_RULE_LIFECYCLE` | PASS |
| POC-ID-INVALID-016 | Unapproved dimension (also gives a mismatch, expected) | `SEM_IDENTIFICATION_DIMENSION` | PASS |
| POC-ID-INVALID-017 | Identification metadata on a Finding output | `SEM_IDENTIFICATION_METADATA_SCOPE` | PASS |
| POC-ID-INVALID-018 / 019 | Unknown ResultConfidence / TieBehavior | `SEM_CONTROLLED_REFERENCE` | PASS |

## 10. Regression results (local, macOS)

The environment was Python 3.14.4 in a venv with `build/requirements-schema-validation.txt`, and PowerShell 7.5.2.

| Command | Result |
|---|---|
| `python build/validate_xlsm_vba_poc.py` | **Passed**: 53 PASS checks, 0 failures |
| `python -m unittest discover -s tests/vba -p "test_*.py" -v` | Ran 22 (4 existing + 18 new), OK |
| `python build/validate_emas_schema.py` | Passed (T3a fixture suite unchanged) |
| `python -m unittest discover -s tests/schema` | Ran 44, OK |
| `python -m unittest discover -s tests/runtime` (static runtime contracts) | Ran 12, OK |
| `python build/validate_report_mappings.py` / `tests/reporting` | OVERALL PASS / Ran 28, OK |
| `python build/validate_controlled_templates.py` | OVERALL PASS |
| `python build/validate_operational_skills.py` / `tests/skills` | Pass / Ran 3, OK |
| `pwsh tests/runtime/Test-eMASRuntimeConfiguration.ps1` | 28 total, 0 failed |
| Workbook generator determinism | Regenerated XLSX is byte-identical; source-bundle and XLSX hashes match the manifest |

The PowerShell runtime contract is not affected: no PowerShell runtime file changed. The known Windows PS 5.1 UTF-8 assertion is untouched.

## 11. Native Excel status

**`NATIVE_EXCEL_QUALIFICATION_PENDING`.** No Windows desktop Excel was available, so `build/Build-eMASMappingPoc.ps1` and `build/Test-eMASMappingPoc.ps1` were **not** executed.

The VBA changes are source-reviewed and contract-tested only. Python tests do not imply native qualification. The native test (labels updated to Schema 1.1.0) must show:
- two byte-identical VBA exports equal to `3c6964c5…cb68d`;
- a pass from the Schema 1.1.0 validator.

## 12. Changed files

| Area | Files |
|---|---|
| Workbook source | `config/authoring/poc/workbook-source.json` (start-sheet instruction); `workbook-source-parts/01, 02, 05, 06, 07, 08, 10, 11-tables.json` |
| Manifests / fixtures | `config/authoring/poc/poc-manifest.json`; `fixtures/manifest.json`; 26 new fixture files |
| Python | `build/emas_xlsx_poc.py`, `emas_xlsx_poc_model.py`, `emas_xlsx_poc_semantics.py`, **new** `emas_xlsx_poc_projection.py`, `validate_xlsm_vba_poc.py` |
| VBA | `config/vba/modules/modConstants.bas`, `modJsonBuilder.bas`, `modUtilities.bas`, `modValidation.bas`, `modWorkbookStructure.bas`, **new** `modRuntimeProjection.bas` |
| Native scripts | `build/Test-eMASMappingPoc.ps1` (Schema 1.1.0 labels only) |
| Tests | `tests/vba/test_xlsm_vba_poc.py` (projection-patch support), **new** `tests/vba/test_identification_workbook_export.py` |
| Docs | `docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md` (v1.1), `config/authoring/poc/README.md`, `config/vba/README.md`, `build/README.md` |
| Report | this file |

No T3a schema or validator file (`config/schema/**`, `build/validate_emas_schema.py`, `build/emas_schema_*.py`) was changed.

## 13. Blockers and open issues

| ID | Issue | Proposed owner |
|---|---|---|
| O-1 | **Contract mismatch (reported, not resolved):** FR-GOV-006 / TR-LIFE-006 allow Reviewed rules in explicitly marked DEV exports, but Runtime JSON Schema 1.0.0/1.1.0 requires `rule.status = Effective`. DEV therefore uses the Effective-only projection. Enabling Reviewed-in-DEV needs a schema/contract decision. | Technical Architect + PO |
| O-2 | `NATIVE_EXCEL_QUALIFICATION_PENDING`: native build/test of the changed VBA on supported Windows Excel is required before the VBA changes count as executed. | QA Lead / controlled Windows workstation |
| O-3 | `.github/workflows/xlsm-vba-poc-validation.yml` step name still reads "…Schema 1.0.0 conformance". This is cosmetic only (the step validates 1.1.0); workflows are outside T3b's allowed paths. | Coordinator |
| O-4 | The projection covers the rule graph, as TASK §5 requires. Other entity rows (value lists, master data, findings, policies) are still exported as authored; they must stay `Effective` to pass the schema. Lifecycle filtering for those entities is not in T3b scope. | Future workbook task |
| O-5 | The synthetic `IDENTIFICATION_DIMENSION` subset (TECHNICAL_STANDARD, REGIONAL_IMPLEMENTATION) is conformance content only. The production dimension set and Region derivation stay with T3c U2 and later rule-pack tasks. | Regulatory SME + PO |

There are no blockers to central review. T4, T1b and T2 are not implemented. T3c U2–U9 are not resolved. No historical rule was imported or made Effective.
