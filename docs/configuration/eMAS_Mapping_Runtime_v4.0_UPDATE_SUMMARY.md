# eMAS Mapping Workbook and Runtime JSON v4.0 — Repository Update Summary

**Source date:** 06 September 2026  
**Status:** Companion summary of the September proposed baseline. It is not a replacement for the original controlled source document.

## Architectural change

The September design replaces the earlier XLSM/VBA-centred export path with a Microsoft 365 architecture:

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
- Phase scripts retain technical discovery, calculations, orchestration, reporting and final phase terminology.
- Power Automate orchestrates release; it is not the business-rule evaluation engine.
- Production Runtime JSON is generated as a complete configuration from an approved state, not incrementally patched.

## Technology baseline

| Layer | Technology | Purpose |
|---|---|---|
| Authoring | Excel for the web / `.xlsx` | SME-friendly rule authoring |
| Repository | SharePoint | Controlled storage, permissions, version history |
| Transformation | Office Scripts / TypeScript | Read, normalize, validate, transform |
| Workflow | Power Automate | Candidate, approval, release and evidence |
| Contract | JSON Schema | Runtime structure/types |
| Runtime artifact | UTF-8 JSON | Shared machine-readable rules |
| Runtime consumer | PowerShell | Offline assessment execution |

## Required 20-sheet mapping baseline

The v4 mapping requirements define these required sheets:

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

The later Integrated Assessment Workbook v4.1 prototype expands the physical workbook to 24 tabs by adding project/dossier/sequence/evidence assessment layers. This must not blur the architecture boundary: assessment data is excluded from Runtime JSON.

## Workbook usability

The workbook is intended to behave like a guided configuration application, with navigation, contextual help, controlled lists, structured Excel Tables, review status and validation feedback. Hidden sheets/navigation are usability features, not security controls.

## DataScope separation

The integrated prototype introduces a useful conceptual separation:

- `RuntimeConfiguration` — reusable configuration eligible for controlled export;
- `AssessmentInput` — customer/project values and evidence inputs;
- `AssessmentDerived` — calculated assessment results;
- optionally `Both` only where explicitly justified by contract.

A blocking validation should prevent assessment/customer data from being mapped into Runtime JSON.

## Configuration validation

At minimum, candidate generation should detect or prevent:

- missing/renamed required structures;
- duplicate stable identifiers;
- missing mandatory values;
- invalid controlled codes/types/operators;
- broken or inactive references;
- ambiguous threshold boundaries;
- conflicting exclusive rules;
- unsupported technical capabilities;
- missing/obsolete source evidence where required;
- active example/test rows in a production candidate;
- schema/mapping incompatibility;
- assessment data being exported as runtime configuration.

`ERROR` conditions block candidate creation. Warnings require an explicit review/disposition model rather than silent success.

## Version concepts remain distinct

Do not conflate:

- SharePoint document version;
- Mapping Version;
- Schema Version;
- workbook/template version;
- Office Script implementation version;
- PowerShell engine/script version;
- Candidate ID;
- Release ID;
- Runtime JSON digest.

## Roles

The design separates responsibilities among Mapping Administrator, Regulatory SME, Migration/Technical SME, Developer, Schema Owner, Reviewer, Release Owner and Consultant. Released artifacts should be read-only to ordinary mapping maintainers.

## Runtime trust

Runtime PowerShell should load the released JSON defensively, validate compatibility and verify the exact payload digest against trusted release evidence before applying rules. It must not repair or reinterpret an invalid configuration during a customer run.

## Repository implication

Files under `config/vba/`, XLSM/VBA POC build scripts and associated POC conformance documentation are historical to this branch's target architecture. Preserve them for traceability until deliberately archived, but do not use them as the implementation authority for the September target.
