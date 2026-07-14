# eMAS Report Redesign Working Baseline

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** All three phase-report requirements finalized  
**Purpose:** Capture the finalized report requirements for Pre-Sales, Pre-Migration and Post-Migration before template, JSON and implementation changes are made.

## Delivery sequence

1. Finalize Pre-Sales report requirements. — Completed
2. Finalize Pre-Migration report requirements. — Completed
3. Finalize Post-Migration report requirements. — Completed
4. Consolidate the approved changes into the Enterprise Requirements v3.2 baseline and phase contracts.
5. Update the normalized result-object contracts and report-template mapping JSON.
6. Create the controlled Excel templates.
7. Update demo data, report-generation logic, tests and validation evidence.

## Phase status

| Phase | Requirement status | Template status | JSON status |
|---|---|---|---|
| Pre-Sales Assessment | Finalized in this working baseline | Pending | Pending |
| Pre-Migration Readiness | Finalized in this working baseline | Pending | Pending |
| Post-Migration Verification | Finalized in this working baseline | Pending | Pending |

## Working documents

- `01_eMAS_PreSales_Report_Requirements_v1.0.md` — finalized Pre-Sales workbook purpose, Executive Estimate, dossier/sequence/path inventories, scenario and effort configuration, result-object additions and acceptance criteria.
- `02_eMAS_PreMigration_Report_Requirements_v1.0.md` — finalized Pre-Migration Executive Summary redesign, retained detailed evidence model, dossier/sequence baseline additions, normalized file-type breakdown, configuration requirements and acceptance criteria.
- `03_eMAS_PostMigration_Report_Requirements_v1.0.md` — finalized Post-Migration Executive Summary, Before–Import–Database–After reconciliation, dossier/sequence/file-type comparison, database dossier inventory, import evidence review, discrepancy disposition, raw-evidence preservation and acceptance criteria.

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

### Post-Migration

1. `01_Executive_Summary`
2. `02_Verification_Scope`
3. `03_Overall_Reconciliation`
4. `04_Dossier_Before_&_After`
5. `05_Sequence_Before_&_After`
6. `06_File_Type_&_Size_Comparison`
7. `07_Database_Dossier_Inventory`
8. `08_Import_Evidence_Review`
9. `09_Discrepancies_&_Actions`
10. `10_Accepted_Exceptions`
11. `11_Assumptions_&_Limits`
12. `12_Review_&_Execution`
13. `Import Report Detail`
14. `Post Import Verification`
15. `Database Dossier Extract`

Each phase also produces a separate timestamped UTF-8 execution log.

## Cross-phase consistency rules

- Pre-Sales determines the proposed scenario, workstreams, workload and estimate.
- Pre-Migration confirms readiness and creates the approved immutable comparison baseline.
- Post-Migration consumes that baseline and reconciles it against import, database and post-import evidence.
- Stable dossier and sequence comparison identifiers shall remain compatible across Pre-Migration and Post-Migration.
- Migration Method, Migration Wave, original RAG, Primary RAG Reason, exclusions and accepted exceptions shall be carried forward where applicable.
- RAG, Evaluation Status, Reconciliation Status, Severity, Blocker and Review Required remain separate concepts.
- Raw external evidence remains append-only and shall not be corrected or reinterpreted in place.

## Governance rule

This folder is the finalized working report-design baseline on the report-redesign branch. It does not supersede the current Effective Enterprise Requirements v3.1 until the Product Owner approves the consolidated Enterprise Requirements v3.2 baseline and synchronized phase contracts.

The next controlled work package shall consolidate the three finalized requirements, resolve any cross-phase schema conflicts, update the runtime/result-object and report-mapping JSON contracts, and then create the controlled Excel templates. No existing controlled template or mapping JSON is superseded merely by the presence of these working requirement documents.
