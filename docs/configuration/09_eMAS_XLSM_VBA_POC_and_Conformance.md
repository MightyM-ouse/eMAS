# eMAS XLSM/VBA Proof of Concept and Conformance Contract

**Version:** 1.0  
**Status:** Effective POC Verification Contract  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect and QA Lead  
**Decision references:** XL-001–XL-014; JSON-001–JSON-023; TEST-001–TEST-020; SK-001; SK-002; SK-006  
**Canonical references:** Mapping Technical Requirements v3.0; Runtime JSON Contract v1.2; Relationship Matrix v1.0; Data Dictionary v1.0; Schema Validation and Fixture Contract v1.0; Runtime JSON Schema 1.0.0

## 1. Purpose

This contract defines the source-controlled proof of concept for the internal eMAS XLSM mapping application and how its workbook structure, VBA source, deterministic export mapping and validation behavior are checked against Runtime JSON Schema 1.0.0.

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
| POC validator | `build/validate_xlsm_vba_poc.py` | Orchestrated structure, fixture, schema and source checks |
| XLSM builder | `build/Build-eMASMappingPoc.ps1` | Imports reviewed VBA into the workbook and saves internal XLSM |
| Native test | `build/Test-eMASMappingPoc.ps1` | Executes VBA and produces manual conformance evidence |
| Automated tests | `tests/vba/test_xlsm_vba_poc.py` | Regression checks |

## 2.1 Requirements serialization clarification

Mapping Technical Requirements v3.0 section 16.2 is illustrative and omits the later-approved `policies` and `questionnaireMap` sections. Runtime JSON Contract v1.2 and Runtime JSON Schema 1.0.0 are authoritative for exact serialization. The POC exports both sections. This clarification does not change Schema 1.0.0.

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
- public validation, preview and DEV export entry points.

All modules use `Option Explicit`. They do not use `ActiveCell`, `Selection`, `.Select`, `.Activate` or fixed cell coordinates.

The public POC intentionally blocks controlled-release export. Controlled export requires the internal signing, release-manifest and full qualification process.

## 5. JSON mapping baseline

The exporter produces all Schema 1.0.0 top-level sections in canonical order:

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
8. valid variants pass Schema 1.0.0 and semantic validation;
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
- successful independent Schema 1.0.0 validation;
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
- successful automated POC and Schema 1.0.0 validation;
- native Excel re-execution where VBA behavior changes;
- manifest checksum updates;
- review through the Effective repository-change skill.

## 12. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Established the synthetic XLSM/VBA POC source, fixture-aligned validation and independent Schema 1.0.0 conformance contract |
