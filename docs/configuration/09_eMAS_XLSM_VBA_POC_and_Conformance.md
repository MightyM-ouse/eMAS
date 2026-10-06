# eMAS XLSM/VBA Proof of Concept and Conformance Contract

**Version:** 1.1  
**Status:** Effective POC Verification Contract  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect and QA Lead  
**Decision references:** XL-001–XL-014; JSON-001–JSON-023; TEST-001–TEST-020; SK-001; SK-002; SK-006  
**Canonical references:** Mapping Functional Requirements v3.0 (FR-GOV-004–007, FR-EXP-006); Mapping Technical Requirements v3.0; Runtime JSON Contract v1.3; Normalized Rule Model v1.2; Relationship Matrix v1.0; Data Dictionary v1.1; Schema Validation and Fixture Contract v1.1; Runtime JSON Schema 1.1.0

## 1. Purpose

This contract defines the source-controlled proof of concept for the internal eMAS XLSM mapping application and how its workbook structure, VBA source, deterministic export mapping and validation behavior are checked against Runtime JSON Schema 1.1.0. Schema 1.0.0 remains supported by the independent validator and its own fixtures; the POC itself authors 1.1.0.

The POC separates four evidence layers:

1. workbook table structure and synthetic content;
2. reviewable VBA source;
3. independent reference export and fixture validation in CI;
4. native Excel/VBA execution evidence on a supported Windows workstation.

The independent Python layer is a verifier, not the authoring or runtime implementation.

## 2. Controlled POC assets

| Artifact | Path | Role |
|---|---|---|
| Declarative workbook source | `config/authoring/poc/workbook-source.json` | Reviewable sheets, tables, headers and synthetic rows |
| Deterministic XLSX generator | `build/generate_emas_mapping_poc_workbook.py` | Produces the macro-free source workbook using Python standard library |
| POC manifest | `config/authoring/poc/poc-manifest.json` | Versions, checksums, classification and native-test state |
| VBA modules | `config/vba/modules/*.bas` | Reviewable implementation imported into internal XLSM |
| Golden runtime JSON hash | `config/authoring/poc/poc-manifest.json#expectedJsonSha256` | Approved SHA-256 of deterministic DEV export |
| Workbook fixture manifest | `config/authoring/poc/fixtures/manifest.json` | Expected valid/invalid status and error codes |
| Reference table reader/exporter | `build/emas_xlsx_poc.py` | Independent XLSX table extraction and JSON mapping |
| Reference runtime projection | `build/emas_xlsx_poc_projection.py` | Runtime-eligibility projection, independent projection verifier and LegacyRuleId export scan |
| POC validator | `build/validate_xlsm_vba_poc.py` | Orchestrated structure, fixture, schema and source checks |
| XLSM builder | `build/Build-eMASMappingPoc.ps1` | Imports reviewed VBA into the workbook and saves internal XLSM |
| Native test | `build/Test-eMASMappingPoc.ps1` | Executes VBA and produces manual conformance evidence |
| Automated tests | `tests/vba/test_xlsm_vba_poc.py`, `tests/vba/test_identification_workbook_export.py` | Regression, projection, LegacyRuleId and VBA-parity checks |

## 2.1 Requirements serialization clarification

Mapping Technical Requirements v3.0 section 16.2 is illustrative and omits the later-approved `policies` and `questionnaireMap` sections. Runtime JSON Contract and Runtime JSON Schema are authoritative for exact serialization. The POC exports both sections. This clarification does not change the schema.

## 3. Workbook table baseline

The POC source contains stable named tables covering:

- configuration and controlled values;
- field/metric catalogues and normalized link tables;
- all nine classification master-data dimensions;
- typed master-data relationships;
- rules, explicit phase assignments, condition groups, conditions and outputs;
- findings, recommendations and links;
- exception and alias content;
- conflict, RAG, confidence, effort and decision policies;
- questionnaire and report terminology;
- validation results, export history and technical/document controls.

Repeating relationships use link tables. The source contains no editable `IsActive` lifecycle field and no comma-separated relationship lists.

### 3.1 Schema 1.1.0 Identification authoring columns

| Table | Column | Rule |
|---|---|---|
| `tblValueLists` | `SortOrder` | Data Dictionary §13 column. Required for the ordinal `EVIDENCE_STRENGTH` precedence (STRONG < MEDIUM < WEAK in SortOrder). |
| `tblFieldCatalogue` | `MaxEvidenceStrength` | Required for every field used by a non-negated condition of an IDENTIFICATION rule |
| `tblRules` | `LegacyRuleId` | Optional, **workbook-only** T3c traceability. Never a RuleId, never part of uniqueness or supersession, never exported. |
| `tblRuleOutputs` | `TargetEntityType`, `EvidenceStrength`, `EvidencePolarity` | Required on IDENTIFICATION `ClassificationCandidate`; prohibited on other outputs |
| `tblConflictPolicies` | `MinimumEvidenceStrengthForValue` | IDENTIFICATION policies only |
| `tblConfidencePolicies` | `ResultConfidence`, `CorroborationRule` | Required for IDENTIFICATION scope, which carries no `WeightOrScore`; other scopes keep `WeightOrScore` |

Controlled lists authored: `EVIDENCE_STRENGTH`, `CONFIDENCE`, `EVIDENCE_POLARITY`, `TIE_BEHAVIOR`, `CORROBORATION_RULE`, `IDENTIFICATION_DIMENSION`, `RULE_TYPE` (+ `IDENTIFICATION`) and the full `RULE_LIFECYCLE_STATUS` set. `Supporting` is not an executable code.

The Identification rows are synthetic conformance content. No historical mapping rule is imported; T3c dispositions remain governance input.

## 4. VBA source baseline

The POC implements reviewable standard modules for:

- constants and table inventory;
- table and culture-invariant utility functions;
- workbook-structure validation;
- fixture-aligned semantic validation;
- deterministic JSON construction in memory;
- UTF-8-without-BOM atomic write;
- SHA-256 calculation without PowerShell JSON generation;
- export-history recording;
- one runtime-eligibility projection (`modRuntimeProjection.bas`);
- public validation, preview and DEV export entry points.

All modules use `Option Explicit`. They do not use `ActiveCell`, `Selection`, `.Select`, `.Activate` or fixed cell coordinates.

The public POC intentionally blocks controlled-release export. Controlled export requires the internal signing, release-manifest and full qualification process.

## 5. JSON mapping baseline

The exporter produces all Runtime JSON top-level sections (unchanged in Schema 1.1.0) in canonical order:

```json
{
  "configuration": {},
  "valueLists": {},
  "fieldCatalogue": [],
  "metricCatalogue": [],
  "masterData": {},
  "relationships": [],
  "rules": [],
  "rulePhases": [],
  "conditionGroups": [],
  "ruleConditions": [],
  "ruleOutputs": [],
  "findings": [],
  "recommendations": [],
  "findingRecommendationLinks": [],
  "exceptionPolicies": [],
  "aliases": [],
  "policies": {},
  "questionnaireMap": [],
  "reportTerminology": {}
}
```

Link tables are folded into the runtime arrays defined by the Runtime JSON Contract, including field operators/phases, metric phases and effort-driver phases.

### 5.1 Runtime-eligibility projection (FR-GOV-004/005, FR-EXP-006)

The reference exporter and the VBA exporter apply the same projection before serialization:

```text
runtime eligible = Status = Effective
                   AND EffectiveFrom <= evaluation date
                   AND (EffectiveTo is empty OR evaluation date < EffectiveTo)
```

Dependent-graph filtering: if a rule is not runtime eligible, its rows in `tblRulePhaseAssignments`, `tblConditionGroups`, `tblRuleConditions` and `tblRuleOutputs` are excluded, and any `RULE_SUPERSESSION` relationship with an excluded endpoint is excluded. Workbook-only columns (`tblRules.LegacyRuleId`) are dropped. The result has no orphan rows.

Evaluation date: the deterministic POC export uses `2026-07-13` (the date part of the fixed POC export timestamp); normal DEV export uses the current UTC date.

DEV versus CONTROLLED: both use this projection; they differ only in configuration metadata and release controls. Draft and InReview rules are never exported. FR-GOV-006 (Reviewed rules in explicitly marked DEV exports, SHOULD) is not implemented, because Runtime JSON Schema 1.0.0 and 1.1.0 require `rule.status = Effective` and a Reviewed rule would make the DEV file schema-invalid. The public POC still blocks controlled-release export (`eMAS_ExportControlledJson`); the controlled projection is proven through the shared projection, the controlled metadata fixture and the deterministic golden output.

Independent verification: `verify_runtime_projection` re-checks every projected rule against its authored lifecycle and dates (`POC_PROJECTION_DRAFT_LEAK`, `POC_PROJECTION_INELIGIBLE`) and every dependent row and condition-group reference (`POC_PROJECTION_ORPHAN`). `scan_runtime_json_for_legacy` fails if a `legacyRuleId` property or any LegacyRuleId value appears in the serialized JSON (`POC_LEGACY_RULE_ID_EXPORTED`); the VBA builder raises the same condition before returning JSON.

## 6. Fixture coverage

The POC fixture suite covers:

| Case | Expected result |
|---|---|
| Base DEV workbook | Valid |
| Controlled metadata variant | Valid structurally and semantically |
| Semantic Version/date boundary | Valid |
| Duplicate RuleId | `SEM_DUPLICATE_ID` |
| Missing condition FieldCode target | `SEM_BROKEN_REFERENCE` |
| Invalid relationship endpoint pair | `SEM_RELATIONSHIP_ENDPOINT` |
| Field/operator incompatibility | `SEM_OPERATOR_NOT_ALLOWED` |
| Effort-threshold overlap | `SEM_THRESHOLD_OVERLAP` |
| Exception policy targeting an ineligible finding | `SEM_EXCEPTION_INELIGIBLE` |
| Rule output target not resolved | `SEM_OUTPUT_TARGET` |
| Schema 1.1.0 base with Effective Identification rule, Draft rule excluded, MEDIUM floor, weightless and weighted confidence | Valid |
| Same code in two dimensions, resolved by TargetEntityType | Valid |
| Identification strength equal to field ceiling (MEDIUM, CONTRADICTS) | Valid |
| Reviewed, future-dated and expired rules excluded from the projection | Valid |
| Candidate OutputCode outside TargetEntityType | `SEM_OUTPUT_TARGET` |
| TargetEntityType differs from ConflictGroup | `SEM_IDENTIFICATION_DIMENSION_MISMATCH` |
| Unknown EvidenceStrength / EvidencePolarity / ResultConfidence / TieBehavior | `SEM_CONTROLLED_REFERENCE` |
| Output strength exceeds field ceiling | `SEM_EVIDENCE_STRENGTH_CEILING` |
| Identification evidence field without MaxEvidenceStrength | `SEM_IDENTIFICATION_METADATA_REQUIRED` |
| Numeric Identification candidate score or confidence weight | `SEM_IDENTIFICATION_NUMERIC_WEIGHT` |
| Bad EVIDENCE_STRENGTH SortOrder | `SEM_ORDINAL_ORDER` |
| Draft rule in the projection | `POC_PROJECTION_DRAFT_LEAK` |
| Dependent row of an excluded rule in the projection | `POC_PROJECTION_ORPHAN` |
| LegacyRuleId serialized (value or property) | `POC_LEGACY_RULE_ID_EXPORTED` |
| LegacyRuleId reused as RuleId, or historical rule ID used as RuleId | `POC_LEGACY_RULE_ID_AS_RULE_ID` |
| Non-Effective (Reviewed) rule treated as runtime eligible | `POC_PROJECTION_INELIGIBLE` |
| Unknown rule lifecycle status | `POC_RULE_LIFECYCLE` |
| Unapproved Identification dimension | `SEM_IDENTIFICATION_DIMENSION` |
| Identification metadata on a non-Identification output | `SEM_IDENTIFICATION_METADATA_SCOPE` |

Projection-fault fixtures carry `projectionOperations`, which inject an exporter fault into the projected tables so the independent verifier is proven to catch it.

Valid and boundary variants must also pass the independent Runtime JSON Schema and semantic validator.

## 7. Deterministic export evidence

For the synthetic deterministic mode:

- export time, exporter identity and validation-run ID are fixed POC values;
- property and collection order is stable;
- equivalent workbook tables produce byte-identical UTF-8 output without BOM;
- the output SHA-256 must equal the approved golden hash;
- source-definition, generated-workbook and golden-JSON checksums are recorded in `poc-manifest.json`.

Normal non-deterministic DEV execution uses current UTC time, Windows identity and a new validation-run ID.

## 8. Automated CI acceptance

The Linux CI job passes only when:

1. the declarative source generates a deterministic XLSX with the expected checksum;
2. all required tables and critical columns are found;
3. base workbook semantics are valid;
4. two independent reference exports are byte-identical;
5. reference output SHA-256 equals the approved golden hash;
6. UTF-8 BOM is absent;
7. every fixture matches its expected validity/error codes;
8. valid variants pass Schema 1.1.0 and semantic validation, and their runtime projection contains only runtime-eligible Effective rules, has no orphan dependent rows and contains no LegacyRuleId;
9. required VBA modules and entry points exist;
10. prohibited selection/fixed-position VBA patterns are absent;
11. source-definition, generated-workbook and golden-output checksums match the POC manifest.

## 9. Native Excel/VBA acceptance

Before the POC is considered natively executed, the Windows/Excel test must record:

- supported Windows and Excel version;
- generated XLSM checksum;
- successful VBA validation;
- two byte-identical deterministic VBA exports;
- equality with the approved golden JSON SHA-256;
- successful independent Schema 1.1.0 validation;
- generated evidence file path and timestamp.

Native evidence is stored outside source control under `output/` or an approved validation location.

## 10. Delivery-state boundary

The repository implementation completes the declarative workbook source, deterministic XLSX generator, VBA source, build/test scripts and automated conformance harness.

It does not complete:

- controlled production workbook signing;
- corporate certificate/trust deployment;
- supported-Excel and locale qualification;
- full mandatory validation-sequence implementation beyond POC fixture scope;
- controlled configuration release;
- Product Owner or Regulatory SME approval of illustrative content.

Native Excel execution remains a manual qualification gate because GitHub-hosted CI does not provide supported desktop Excel.

## 11. Change control

Any POC table, VBA mapping, fixture or expected-output change requires:

- applicable DecisionIds and requirement references;
- synchronized workbook, VBA, reference exporter and golden output hash;
- updated valid/invalid/boundary fixtures;
- successful automated POC and Runtime JSON Schema validation;
- native Excel re-execution where VBA behavior changes;
- manifest checksum updates;
- review through the Effective repository-change skill.

## 12. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Established the synthetic XLSM/VBA POC source, fixture-aligned validation and independent Schema 1.0.0 conformance contract |
| 1.1 | 2026-10-06 | Migrated the synthetic POC to Schema 1.1.0 Identification authoring; added the shared runtime-eligibility projection with dependent-graph filtering, workbook-only LegacyRuleId, Identification validation and fixtures |
