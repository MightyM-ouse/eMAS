# eMAS Mapping Workbook and Runtime JSON v4.0 — Repository Update Summary

**Source date:** 06 September 2026  
**Status:** Companion summary of the September proposed baseline. It is not a replacement for the original controlled source document.

## Architectural change

```text
JSON Schema
    ↓
Excel-to-JSON field mapping
    ↓
Internal Mapping Workbook (.xlsx, Excel for the web)
    ↓
Office Scripts / TypeScript
    ↓
validated complete JSON object
    ↓
Power Automate candidate / approval / release
    ↓
Versioned Runtime JSON
    ↓
Pre-Sales | Pre-Migration | Post-Migration PowerShell
```

### Mandatory boundaries

- Mapping Workbook is internal and is not distributed to customers.
- Runtime PowerShell does not read or interpret the Mapping Workbook.
- Runtime execution does not require Excel, SharePoint, Office Scripts or Power Automate.
- Runtime JSON structure is defined independently of workbook layout.
- One released Runtime JSON is shared by all phases.
- Power Automate orchestrates release; it is not the business-rule evaluation engine.
- Production Runtime JSON is generated as a complete configuration from an approved state, not incrementally patched.

## Required 20-sheet mapping baseline

1. `Home`
2. `User_Guide`
3. `Document_Control`
4. `Assessment_Profile`
5. `Classification_Rules`
6. `Folder_Rules`
7. `File_Rules`
8. `RAG_Rules`
9. `Effort_Drivers`
10. `Confidence_Rules`
11. `Decision_Rules`
12. `Recommendations`
13. `Value_Lists`
14. `JSON_Field_Mapping`
15. `Schema_Control`
16. `Validation_Controls`
17. `Validation_Results`
18. `JSON_Preview`
19. `Export_History`
20. `Change_History`

The later Integrated Assessment Workbook v4.1 prototype expands the physical workbook to 24 tabs by adding project/dossier/sequence/evidence assessment layers. Assessment data is excluded from Runtime JSON.

## DataScope separation

- `RuntimeConfiguration` — reusable configuration eligible for controlled export;
- `AssessmentInput` — customer/project values and evidence inputs;
- `AssessmentDerived` — calculated assessment results;
- `Both` only where explicitly justified by contract.

A blocking validation should prevent assessment/customer data from being mapped into Runtime JSON.

## Configuration validation

At minimum, candidate generation should detect/prevent missing or renamed required structures, duplicate IDs, missing mandatory values, invalid controlled codes/types/operators, broken references, ambiguous thresholds, unsupported technical capabilities, obsolete evidence, active example/test rows, schema/mapping incompatibility and assessment data leakage into runtime configuration.

`ERROR` conditions block candidate creation. Warnings require explicit review/disposition.

## Runtime trust

Runtime PowerShell should load released JSON defensively, validate compatibility and verify the exact payload digest against trusted release evidence before applying rules. It must not repair or reinterpret an invalid configuration during a customer run.
