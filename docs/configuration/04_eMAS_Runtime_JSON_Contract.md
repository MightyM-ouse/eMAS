# eMAS Runtime JSON Contract

**Status:** Approved design baseline  
**Effective date:** 2026-07-13  
**Decision references:** JSON-001 through JSON-023, AP-002, RM-001, RM-017, RM-018

## 1. Ownership

The Technical Architect owns the JSON Schema. Schema changes require Product Owner and PowerShell Lead approval. Regulatory content changes must not require schema changes unless the structure itself changes.

## 2. Canonical files

- Schema: `config/schema/eMAS-runtime-config.schema.json`
- Valid fixtures: `config/schema/examples/valid/`
- Invalid fixtures: `config/schema/examples/invalid/`
- Controlled runtime file name: `eMAS_Runtime_Config.json`

The schema uses JSON Schema Draft 2020-12.

## 3. Versioning

All versions use Semantic Versioning 2.0.0.

- `schemaVersion`: structure and contract version.
- `mappingVersion`: business/configuration release version.
- `sourceWorkbookVersion`: source XLSM version.
- `minimumEngineVersion`: minimum compatible engine version.
- `maximumTestedEngineVersion`: optional compatibility evidence.

Schema version rules:

- MAJOR: breaking change, including removed/renamed fields, changed types, new mandatory sections or changed code meaning.
- MINOR: backward-compatible optional additions.
- PATCH: clarification or non-structural correction.

Mapping versions evolve independently of schema versions.

## 4. Top-level model

The runtime JSON is normalized and explicitly represents workbook relationships. The canonical top-level sections are:

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
  "reportTerminology": {}
}
```

Enterprise Requirements v3.1 and the effective configuration requirements use this normalized model. The earlier flat indicative structure in Enterprise Requirements v3.0 is superseded.

## 5. Required configuration metadata

The `configuration` object must include:

- configuration identifier;
- schema version;
- mapping version;
- source workbook version;
- minimum engine version;
- export type (`DEV` or `CONTROLLED`);
- export timestamp in UTC;
- exporting Windows identity;
- document/configuration status;
- effective date;
- validation run identifier;
- checksum algorithm and value for controlled releases.

Controlled JSON is immutable after export. PowerShell must never repair, rewrite or enrich it in place.

## 6. Referential integrity

The schema and validators must cover every mandatory relationship, including:

- rule to phase assignment;
- rule to condition group and condition;
- rule to output;
- rule to finding;
- finding to recommendation link;
- condition to field catalogue entry;
- field to data type and allowed operator;
- master-data relationship links;
- predecessor and successor rule supersession;
- exception policy to eligible finding;
- alias to canonical field or value.

Every relationship must define cardinality, mandatory/optional status and validating layer.

## 7. Compatibility and unknown content

The engine must reject:

- invalid JSON syntax;
- unsupported schema major versions;
- missing mandatory sections;
- duplicate identifiers;
- broken mandatory references;
- unknown executable operators;
- invalid controlled values;
- failed checksum for a controlled package.

The engine may warn and continue for:

- unknown descriptive metadata;
- new optional descriptive fields compatible with the supported schema;
- missing optional customer evidence, which becomes an evaluation status such as `NotAssessed` rather than a configuration error.

## 8. Determinism and serialization

JSON export must be:

- UTF-8 without BOM;
- complete and never truncated;
- culture-invariant for decimal, Boolean, date and date-time values;
- deterministic in property and collection ordering where required by the release contract;
- free of locale-specific separators;
- validated before release.

Dates and times must use ISO 8601-compatible representations. Numbers must use a period as the decimal separator regardless of Windows or Excel locale.

## 9. Phase use

The same JSON is used by all three phases. It defines shared interpretation and controlled values; it does not define the complete workflow of each phase.

Phase-specific scripts remain responsible for:

- required inputs;
- assessment depth;
- checks executed;
- performance behaviour;
- report structure;
- final decision/result language.

## 10. Validation layers

- XLSM/VBA performs structural, referential and business validation before export.
- JSON Schema validation runs in CI and release validation.
- The Windows PowerShell 5.1 loader performs defensive structural and compatibility checks because `Test-Json` is not available in Windows PowerShell 5.1.

## 11. Release integrity

Controlled releases must record the JSON file name, mapping version, schema version, source workbook version, file size, SHA-256 checksum, validation result and release manifest reference.
