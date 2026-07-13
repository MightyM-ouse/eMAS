# eMAS Runtime JSON Contract

**Version:** 1.1  
**Status:** Approved design baseline  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect  
**Decision references:** JSON-001 through JSON-023, AP-002, RM-001, RM-017, RM-018  
**Canonical logical-model references:** Normalized Relationship Matrix v1.0; Logical Data Dictionary v1.0

## 1. Ownership

The Technical Architect owns the JSON Schema. Schema changes require Product Owner and PowerShell Lead approval. Regulatory content changes must not require schema changes unless the structure itself changes.

The [Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) controls cross-entity semantics, endpoint pairs, cardinality and temporal validity. The [Logical Data Dictionary](07_eMAS_Data_Dictionary.md) controls entity fields, keys, logical types and requiredness. The JSON Schema controls exact machine-readable serialization.

## 2. Canonical files

- Schema: `config/schema/eMAS-runtime-config.schema.json`
- Valid fixtures: `config/schema/examples/valid/`
- Invalid fixtures: `config/schema/examples/invalid/`
- Controlled runtime file name: `eMAS_Runtime_Config.json`
- Relationship contract: `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md`
- Field contract: `docs/configuration/07_eMAS_Data_Dictionary.md`

The schema uses JSON Schema Draft 2020-12.

## 3. Versioning

All versions use Semantic Versioning 2.0.0.

- `schemaVersion`: structure and contract version.
- `mappingVersion`: business/configuration release version.
- `sourceWorkbookVersion`: source XLSM version.
- `minimumEngineVersion`: minimum compatible engine version.
- `maximumTestedEngineVersion`: optional compatibility evidence.

Schema version rules:

- MAJOR: breaking change, including removed/renamed fields, changed types, new mandatory sections, changed relationship/cardinality meaning or changed code meaning.
- MINOR: backward-compatible optional additions.
- PATCH: clarification or non-structural correction.

Mapping versions evolve independently of schema versions. A relationship-matrix or data-dictionary change requires explicit schema compatibility analysis even when the JSON top-level sections do not change.

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

Enterprise Requirements v3.1 and the Effective configuration requirements use this normalized model. The earlier flat indicative structure in Enterprise Requirements v3.0 is superseded.

Dedicated authoring link entities may be folded into their runtime parent representation where the schema defines an array, for example field/operator, field/phase and metric/phase links. The relationship matrix controls the source relationship even when serialization is nested.

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

The schema and semantic validators must cover every mandatory relationship in the frozen relationship matrix, including:

- rule to explicit phase assignment;
- rule to condition group and condition;
- rule to output and output target;
- optional primary rule finding and additional finding outputs;
- finding to recommendation link;
- condition to field catalogue entry and allowed operator;
- field and metric to explicit supported phases;
- master-data relationship endpoint types and codes;
- predecessor and successor rule supersession;
- exception policy to eligible finding;
- alias to an allowed canonical field, value or master-data target;
- validation run to validation results and export evidence where applicable.

Every relationship must comply with the frozen cardinality, mandatory/optional, temporal and validating-layer rules. JSON Schema validation alone is insufficient for cross-collection referential integrity.

## 7. Compatibility and unknown content

The engine must reject:

- invalid JSON syntax;
- unsupported schema major versions;
- missing mandatory sections;
- duplicate identifiers or violated composite uniqueness;
- broken mandatory references;
- disallowed relationship endpoint pairs;
- invalid effective-date alignment;
- unknown executable operators or output types;
- invalid controlled values;
- failed checksum for a controlled package.

The engine may warn and continue for:

- unknown descriptive metadata explicitly permitted by the schema;
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

Dates and times must use ISO 8601-compatible representations. Numbers must use a period as the decimal separator regardless of Windows or Excel locale. Workbook PascalCase columns map deterministically to schema-defined camelCase properties.

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

- XLSM/VBA performs structural, referential, temporal and business validation before export.
- JSON Schema validation runs in CI and release validation.
- A semantic release validator checks the complete frozen relationship matrix, composite uniqueness and cross-collection references.
- The Windows PowerShell 5.1 loader performs defensive structural, semantic and compatibility checks because `Test-Json` is not available in Windows PowerShell 5.1.

The same invalid-reference and boundary fixtures should be applied, where practical, to workbook validation, release validation and the PowerShell loader.

## 11. Release integrity

Controlled releases must record the JSON file name, mapping version, schema version, source workbook version, relationship-matrix version, data-dictionary version, file size, SHA-256 checksum, validation result and release manifest reference.

## 12. Synchronization state

The relationship matrix and data dictionary are frozen. The current JSON Schema remains the initial approved baseline and must be reconciled against the frozen contracts through the next schema-fixture stage. Any identified mismatch is a tracked implementation gap; it must not be resolved by silently weakening the frozen logical model.

## 13. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Initial approved runtime JSON contract |
| 1.1 | 2026-07-13 | Bound runtime serialization and semantic validation to the frozen relationship matrix and data dictionary |
