# eMAS Configuration Documentation

Use these documents in authority order for mapping-workbook, logical-model and runtime-configuration work.

| ID | Document | Status | Purpose |
|---|---|---|---|
| CFG-FUNC | [01 — Mapping Configuration Functional Requirements](01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective | Functional behavior and user-facing workbook controls |
| CFG-TECH | [02 — Mapping Configuration Technical Requirements](02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective | XLSM, VBA, validation, export and compatibility requirements |
| CFG-CAT | [03 — Mapping Configuration Content Catalogue](03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical-model baseline | Entities, controlled values and content boundaries |
| CFG-JSON | [04 — Runtime JSON Contract](04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective runtime contract | Runtime structure, versioning, serialization, validation and compatibility |
| CFG-RULE | [05 — Normalized Rule Model](05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved design baseline | Rule, lifecycle, phase, condition, output and exception behavior |
| CFG-REL | [06 — Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective logical-model contract | Frozen entities, relationships, cardinalities and referential integrity |
| CFG-DICT | [07 — Logical Data Dictionary](07_eMAS_Data_Dictionary.md) | v1.0 Effective logical-model contract | Frozen fields, keys, types, requiredness and serialization conventions |
| CFG-VERIFY | [08 — Schema Validation and Fixture Contract](08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective verification contract | Fixture classes, expected results, semantic error codes and independent validation |

## Required use

For workbook or runtime-model implementation, read all eight documents. CFG-REL and CFG-DICT are normative elaborations of the Effective content catalogue. CFG-VERIFY governs verification of the runtime serialization.

Where earlier prose uses shorthand repeating fields such as `SupportedPhases`, `AllowedOperators`, `DriverCodeOrOverallModel` or `TriggerFieldOrFinding`, the dedicated link entity or typed discriminator defined by CFG-REL and CFG-DICT controls. Shorthand may remain only as a generated display and must not be implemented as comma-separated or ambiguous free text.

The [JSON Schema](../../config/schema/eMAS-runtime-config.schema.json) controls exact machine-readable serialization. The [fixture manifest](../../config/schema/examples/fixture-manifest.json) and independent validator provide the testable semantic contract.

## Content boundary

The structural and verification models are Effective. Detailed regulatory rules, authority relationships, folder/file expectations, effort weights, confidence weights, thresholds and exception-role values still require applicable Product Owner, Migration SME or Regulatory SME approval before Effective configuration export.
