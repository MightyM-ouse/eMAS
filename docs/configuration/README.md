# eMAS Configuration Documentation

## Current branch focus

This branch defines the eMAS MVP:

1. one complete, human-readable Mapping Workbook containing all configurable migration-assessment requirements; and
2. deterministic generation of one Runtime JSON file for a selected migration scenario.

Use [Mapping Workbook and Scenario JSON MVP Requirements v4.5](01_eMAS_Mapping_Configuration_Functional_Requirements.md) as the current workbook/JSON requirements baseline for this branch. It defines the approved `MS-01` through `MS-08` catalogue, project qualifiers, business-first questionnaire, explicit scenario-derivation rules, fifteen bounded assessment modules, all 360 scenario/phase/module mappings, the atomic 24-family Requirement Catalogue, the Fields/Evidence semantic dictionary and controlled Value Lists, phase-aware JSON objects, and the DMS-to-DMS exclusion/consultant-review route.

The immediate flow is:

```text
Master Mapping Workbook
        -> select ScenarioId
        -> resolve applicable modules and rules
        -> validate references and completeness
        -> generate scenario-specific Runtime JSON
        -> PowerShell consumes JSON without reading Excel
```

## Supporting configuration documents

| ID | Document | Use in this branch |
|---|---|---|
| CFG-MVP | [01 - Mapping Workbook and Scenario JSON MVP Requirements](01_eMAS_Mapping_Configuration_Functional_Requirements.md) | Primary MVP requirements, sheets, columns, relationships, JSON shape, scenarios, validation, and acceptance |
| CFG-TECH | [02 - Mapping Configuration Technical Requirements](02_eMAS_Mapping_Configuration_Technical_Requirements.md) | Historical technical reference; XLSM/VBA and formal release provisions do not override CFG-MVP |
| CFG-CAT | [03 - Mapping Configuration Content Catalogue](03_eMAS_Mapping_Configuration_Content_Catalogue.md) | Reference catalogue for normalized entities and controlled terminology; reconcile before implementation |
| CFG-JSON | [04 - Runtime JSON Contract](04_eMAS_Runtime_JSON_Contract.md) | Previous shared JSON contract; synchronize to the scenario-specific MVP structure before coding |
| CFG-RULE | [05 - Normalized Rule Model](05_eMAS_Normalized_Rule_Model.md) | Reusable rule/condition principles where compatible with CFG-MVP |
| CFG-REL | [06 - Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md) | Reference for referential integrity; reconcile entity names with CFG-MVP |
| CFG-DICT | [07 - Logical Data Dictionary](07_eMAS_Data_Dictionary.md) | Previous field dictionary; update after sheet-by-sheet MVP review |
| CFG-VERIFY | [08 - Schema Validation and Fixture Contract](08_eMAS_Schema_Validation_and_Fixture_Contract.md) | Reference for later schema/fixture work |
| CFG-XLSM-POC | [09 - XLSM/VBA POC and Conformance Contract](09_eMAS_XLSM_VBA_POC_and_Conformance.md) | Historical POC only; not the MVP implementation direction |

## MVP precedence rule

Where an older configuration document requires XLSM/VBA, SharePoint workflow, approval/release governance, WPF, or one non-scenario-specific runtime configuration, the MVP requirements in CFG-MVP control this branch. Those older details are retained only as design input for later reconciliation.

Detailed regulatory rules, source-system adapters, thresholds, and comparison keys are content-population work. They shall be reviewed sheet by sheet and must not be guessed merely to fill the workbook.
