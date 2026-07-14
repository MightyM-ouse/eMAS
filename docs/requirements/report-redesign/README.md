# eMAS Report Redesign Working Baseline

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** Working requirements baseline  
**Purpose:** Capture the finalized report requirements for Pre-Sales, Pre-Migration and Post-Migration before template, JSON and implementation changes are made.

## Delivery sequence

1. Finalize Pre-Sales report requirements.
2. Finalize Pre-Migration report requirements.
3. Finalize Post-Migration report requirements.
4. Consolidate the approved changes into the Enterprise Requirements v3.2 baseline and phase contracts.
5. Update the normalized result-object contracts and report-template mapping JSON.
6. Create the controlled Excel templates.
7. Update demo data, report-generation logic, tests and validation evidence.

## Phase status

| Phase | Requirement status | Template status | JSON status |
|---|---|---|---|
| Pre-Sales Assessment | Finalized in this working baseline | Pending | Pending |
| Pre-Migration Readiness | Finalized in this working baseline | Pending | Pending |
| Post-Migration Verification | Pending discussion | Pending | Pending |

## Working documents

- `01_eMAS_PreSales_Report_Requirements_v1.0.md` — finalized Pre-Sales workbook purpose, sheets, columns, configuration requirements and acceptance criteria.
- `02_eMAS_PreMigration_Report_Requirements_v1.0.md` — finalized Pre-Migration Executive Summary redesign, retained detailed evidence model, dossier/sequence baseline additions, normalized file-type breakdown, configuration requirements and acceptance criteria.
- `03_eMAS_PostMigration_Report_Requirements_v1.0.md` — to be added after detailed review.

## Current frozen workbook direction

### Pre-Sales

1. `01_Executive_Estimate`
2. `02_Dossier_Inventory`
3. `03_Sequence_Inventory`
4. `04_Path_&_Volume_Inventory`

### Pre-Migration

1. `01_Executive_Summary`
2. `02_Readiness_Decision`
3. `03_Inputs_Access_&_Transfer`
4. `04_Dossier_Baseline`
5. `05_Sequence_Baseline`
6. `06_File_Type_Breakdown`
7. `07_File_XML_Path_Checks`
8. `08_Findings_&_Actions`
9. `09_Exceptions_&_Exclusions`
10. `10_Assumptions_&_Limits`
11. `11_Execution_Details`

Each phase also produces a separate timestamped UTF-8 execution log.

## Governance rule

This folder is a controlled working baseline on the report-redesign branch. It does not supersede the current Effective Enterprise Requirements v3.1 until all three phase reports are agreed and the Product Owner approves the consolidated v3.2 baseline.

No controlled template or report-template mapping JSON shall be changed solely from partial discussion notes. Template and JSON implementation starts only after the applicable phase requirement is frozen and checked for consistency with the other phases.
