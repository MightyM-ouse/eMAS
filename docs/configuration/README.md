# eMAS Configuration Documentation

Use these documents in authority order for mapping-workbook, logical-model and runtime-configuration work.

| ID | Document | Status | Purpose |
|---|---|---|---|
| CFG-FUNC | [01 — Mapping Configuration Functional Requirements](01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective | Functional behavior and user-facing workbook controls |
| CFG-TECH | [02 — Mapping Configuration Technical Requirements](02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective | XLSM, VBA, validation and export requirements |
| CFG-CAT | [03 — Mapping Configuration Content Catalogue](03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical-model baseline | Entities, controlled values and content boundaries |
| CFG-JSON | [04 — Runtime JSON Contract](04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective | Runtime structure, serialization and compatibility |
| CFG-RULE | [05 — Normalized Rule Model](05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved | Rule, lifecycle, condition, output and exception behavior |
| CFG-REL | [06 — Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective | Relationships, cardinalities and referential integrity |
| CFG-DICT | [07 — Logical Data Dictionary](07_eMAS_Data_Dictionary.md) | v1.0 Effective | Fields, keys, types and requiredness |
| CFG-VERIFY | [08 — Schema Validation and Fixture Contract](08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective | Runtime fixture classes, semantic errors and independent validation |
| CFG-XLSM-POC | [09 — XLSM/VBA POC and Conformance Contract](09_eMAS_XLSM_VBA_POC_and_Conformance.md) | v1.0 Effective POC verification contract | Synthetic workbook source, VBA, fixtures, CI and native Excel qualification |

For workbook implementation, read all nine documents. CFG-REL and CFG-DICT are normative elaborations of the content catalogue. CFG-VERIFY governs runtime JSON verification; CFG-XLSM-POC governs source-controlled workbook/VBA proof and native qualification boundaries.

Repeating fields such as phases and allowed operators use dedicated link tables. Shorthand may appear only as generated display and must not be implemented as comma-separated or ambiguous free text.

Runtime JSON Schema 1.0.0 controls exact property names and required structure. The workbook POC must produce all canonical sections, including `policies` and `questionnaireMap`.

Detailed regulatory rules, authority relationships, folder/file expectations, weights, thresholds and exception-role values still require applicable owner/SME approval before Effective configuration export.
