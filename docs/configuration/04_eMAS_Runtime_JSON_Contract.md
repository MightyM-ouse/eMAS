# eMAS Runtime JSON Contract

**Version:** 1.2  
**Status:** Effective Runtime Contract  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect  
**Decision references:** JSON-001 through JSON-023, AP-002, RM-001, RM-017, RM-018  
**Canonical logical-model references:** Normalized Relationship Matrix v1.0; Logical Data Dictionary v1.0  
**Verification reference:** Schema Validation and Fixture Contract v1.0

## 1. Ownership

The Technical Architect owns Runtime JSON Schema 1.0.0. Schema changes require Product Owner and PowerShell Lead approval. Regulatory content changes must not require schema changes unless the structure itself changes.

The [Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) controls cross-entity semantics, endpoint pairs, cardinality and temporal validity. The [Logical Data Dictionary](07_eMAS_Data_Dictionary.md) controls fields, keys, logical types and requiredness. The JSON Schema controls exact serialization. The [Schema Validation and Fixture Contract](08_eMAS_Schema_Validation_and_Fixture_Contract.md) controls independent verification.

## 2. Canonical files

- Root schema: `config/schema/eMAS-runtime-config.schema.json`
- Schema definitions: `config/schema/defs/*.schema.json`
- Fixture manifest: `config/schema/examples/fixture-manifest.json`
- Valid fixtures: `config/schema/examples/valid/`
- Boundary fixtures: `config/schema/examples/boundary/`
- Invalid fixtures: `config/schema/examples/invalid/`
- Independent validator: `build/validate_emas_schema.py`
- Unit tests: `tests/schema/test_schema_fixtures.py`
- Controlled runtime file name: `eMAS_Runtime_Config.json`

The schema uses JSON Schema Draft 2020-12.

## 3. Versioning

All versions use Semantic Versioning 2.0.0.

- `schemaVersion`: runtime structure and contract version.
- `mappingVersion`: business/configuration release version.
- `sourceWorkbookVersion`: source XLSM implementation version.
- `minimumEngineVersion`: minimum compatible engine version.
- `maximumTestedEngineVersion`: optional compatibility evidence.

Schema-version rules:

- MAJOR: incompatible removal, rename, type change, mandatory-section change, relationship/cardinality change or code-meaning change.
- MINOR: backward-compatible optional structure.
- PATCH: clarification or non-structural correction.

Schema 1.0.0 was completed before the first controlled software release. The synchronization work therefore finalizes the 1.0.0 baseline rather than introducing a post-release breaking change.

The approved `Warning` EvaluationStatus is an in-place Schema 1.0.0 compatibility amendment because the schema has not yet been used in a controlled release. It changes the accepted controlled-code set before release, requires synchronized fixtures and validators, and must not be treated as a silent runtime divergence.

Mapping versions evolve independently. Relationship-matrix or data-dictionary changes require schema compatibility analysis even when top-level sections do not change.

## 4. Canonical top-level model

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

`policies` contains conflict, RAG, confidence, effort-driver, effort-threshold and decision-policy collections. `questionnaireMap` contains controlled clarification triggers. `reportTerminology` contains ordered report definitions and phase-result codes.

Dedicated workbook link entities may be folded into runtime parent arrays where explicitly defined, including field/operator, field/phase, metric/phase and effort-driver/phase links. The frozen relationship matrix remains authoritative for source relationships.

## 5. Configuration metadata

The `configuration` object includes:

- configuration ID;
- schema version fixed to `1.0.0`;
- mapping, workbook and engine versions;
- DEV or CONTROLLED export type;
- UTC export timestamp and exporting identity;
- Reviewed or Effective status;
- validation-run ID;
- optional maximum-tested engine version.

A CONTROLLED export additionally requires:

- Effective status and effective date;
- approval reference;
- release-manifest reference;
- SHA-256 algorithm and value;
- checksum scope `CanonicalConfigurationExcludingChecksumFields`.

Controlled JSON is immutable after export. PowerShell must never repair, rewrite or enrich it in place.

## 6. Serialization rules

Runtime JSON must be:

- UTF-8 without BOM;
- complete and never truncated;
- culture invariant for numbers, Booleans, dates and date-times;
- free of locale-specific separators;
- deterministic in property and collection ordering where required by the release contract;
- validated before release.

Dates use `YYYY-MM-DD`. Date-times use UTC ISO 8601 with `Z`. Workbook PascalCase columns map to schema-defined camelCase properties. Runtime controlled-list names and technical codes use stable uppercase-compatible identifiers; display values remain separate.

## 7. Structural validation

JSON Schema validates:

- mandatory top-level sections;
- object and primitive types;
- required fields;
- prohibited unknown properties;
- identifier, Semantic Version, date, date-time and checksum formats;
- controlled enumerations;
- CONTROLLED export conditional metadata;
- operator-specific condition values;
- policy and report-terminology object shapes.

Schema validation alone does not prove referential integrity.

## 8. Semantic validation

Independent semantic validation covers every mandatory relationship in the frozen matrix, including:

- primary and composite uniqueness;
- mandatory value-list categories and codes;
- master-data relationship endpoint types and existence;
- rule-to-phase, group, condition and output completeness;
- condition field, operator and phase compatibility;
- output target resolution by OutputType;
- finding-to-recommendation links;
- exception policy to eligible finding;
- alias to approved canonical target;
- threshold ranges, gaps and overlaps;
- decision-policy and questionnaire references;
- effective-date ranges and supersession cycles.

The independent validator emits stable machine-readable error codes documented in the verification contract.

## 9. Compatibility and failure behavior

The exporter, release validator and engine loader must reject:

- invalid JSON syntax or schema structure;
- unsupported schema version;
- missing mandatory sections;
- duplicate identifiers or composite keys;
- broken mandatory references;
- disallowed relationship endpoint pairs;
- invalid temporal ranges;
- unknown executable operators or output types;
- invalid controlled values;
- failed controlled-package checksum.

Missing optional customer evidence is not a configuration error. It produces the configured evaluation status, such as `NotAssessed` or `InsufficientEvidence`.

`Warning` is a valid configured evaluation status for a completed usable evaluation with a recoverable condition requiring attention. It does not independently determine RAG, severity, blocker status, effort band, readiness result or reconciliation result.

## 10. Phase use

The same JSON is used by all three phases. It defines shared interpretation, controlled values and policy data; it does not define the complete workflow of each phase.

Phase scripts remain responsible for:

- required input parameters;
- assessment depth and checks;
- performance behavior;
- report structure;
- final phase result terminology.

## 11. Validation layers

| Layer | Responsibility |
|---|---|
| XLSM/VBA | Structural, referential, temporal and business validation before export |
| JSON Schema | Exact machine-readable object shape and primitive constraints |
| Independent Python validator | Cross-collection semantic validation and fixture expectation enforcement |
| Release validation | Complete schema, semantic, compatibility, checksum and package checks |
| PowerShell loader | Defensive fail-fast validation before execution |

Python and `jsonschema` are build/CI dependencies only. They are not customer-package or PowerShell runtime dependencies.

The same negative and boundary fixtures should be reused as conformance evidence for XLSM/VBA and PowerShell-loader implementation.

## 12. Fixtures and expected results

`fixture-manifest.json` identifies every fixture, expected validity and expected semantic error code.

- Valid fixtures must produce no issue.
- Boundary fixtures are valid and must produce no issue.
- Invalid fixtures must fail for their expected reason.
- All fixtures must be synthetic and UTF-8 without BOM.

## 13. Release integrity

Controlled releases record:

- runtime file name;
- schema, mapping, workbook, relationship-matrix and data-dictionary versions;
- minimum and tested engine versions;
- file size and SHA-256 checksum;
- validation result;
- fixture/validator version where applicable;
- release-manifest reference.

## 14. Synchronization state

Runtime JSON Schema 1.0.0, the fixture manifest, valid/invalid/boundary fixtures and the independent semantic validator are synchronized with the frozen relationship matrix and data dictionary.

This completes schema-contract synchronization. It does not mean the XLSM/VBA exporter or PowerShell loader has implemented every validation rule; those remain separate delivery stages.

## 15. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Initial approved runtime JSON contract |
| 1.1 | 2026-07-13 | Bound runtime serialization and semantic validation to the frozen relationship matrix and data dictionary |
| 1.2 | 2026-07-13 | Finalized Schema 1.0.0 top-level serialization, fixture classes, independent semantic validation and verification boundaries |
| 1.2a | 2026-07-13 | Applied approved in-place Schema 1.0.0 compatibility amendment for `Warning` EvaluationStatus before controlled release |
