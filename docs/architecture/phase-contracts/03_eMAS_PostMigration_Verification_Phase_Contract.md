# eMAS Post-Migration Verification Phase Contract

**Version:** 1.2  
**Status:** Approved Working Contract on `requirements/report-redesign-v3.2`  
**Phase code:** `POST_MIGRATION`  
**Runtime:** PowerShell 7.6 LTS on Windows  
**Canonical requirement:** `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md`  
**Detailed report requirement:** `docs/requirements/report-redesign/03_eMAS_PostMigration_Report_Requirements_v1.1.md`

## 1. Purpose

Post-Migration compares the approved compatible Pre-Migration baseline with independent import-report, target-database and post-import evidence and determines technical reconciliation.

The phase does not execute migration, provide regulatory validation, constitute formal customer validation, electronically approve the migration or record customer acceptance.

## 2. Evidence sequence

The phase uses four distinct evidence positions:

`Pre-Migration Baseline -> Import Report -> Target Database -> Post-Import Verification`

The Pre-Migration baseline is the authoritative expected state. The other three are independent observed evidence. One source shall not be silently substituted for another.

## 3. Inputs

At minimum:

- approved compatible Pre-Migration baseline and integrity evidence;
- controlled runtime JSON, schema, template and map;
- MigrationSummary/import-report detail where in scope;
- target database dossier extract where required;
- post-import verification evidence;
- approved exclusions and carried-forward exceptions;
- reviewer/closeout context and output locations.

Initial database support accepts a controlled read-only CSV/XLSX extract. Direct production database connectivity requires a separately approved adapter and qualification.

## 4. Startup validation

Before comparison, the phase validates:

- package/runtime/schema/configuration compatibility;
- template version 1.2.0 and map version 2.0.0;
- baseline ID, approval status, schema/version and checksum;
- baseline scope and comparison-key compatibility;
- mandatory evidence availability and interpretable structure;
- output permissions.

Missing or incompatible mandatory evidence produces `Verification Incomplete`; it shall not produce a reconciliation conclusion.

## 5. Processing contract

The phase shall:

1. create execution identity and detailed timestamped UTF-8 logging;
2. load the approved baseline read-only;
3. preserve raw import-report, post-import and database-extract rows/header text exactly;
4. normalize import statuses/messages through controlled mappings;
5. normalize database dossier records through version-aware mappings;
6. compare dossier presence and agreed metadata across baseline/import/database/post evidence;
7. compare sequence presence and agreed technical measures;
8. compare file-type counts/sizes and other approved baseline measures;
9. preserve expected, import, database and observed values and provenance;
10. classify discrepancies without erasing evidence;
11. apply accepted-exception policies while preserving the underlying discrepancy;
12. keep system comparison notes separate from reviewer notes/dispositions;
13. determine only `Reconciled`, `Reconciled with Accepted Exceptions`, `Not Reconciled` or `Verification Incomplete`;
14. populate the controlled fifteen-sheet workbook and normalized result;
15. write integrity/output evidence to the log/result.

## 6. Controlled result terminology

Final results:

- `Reconciled`
- `Reconciled with Accepted Exceptions`
- `Not Reconciled`
- `Verification Incomplete`

Row-level ReconciliationStatus remains separate and supports Matched, Matched Within Tolerance, Accepted Difference, Review Required, Mismatched, Missing After Migration, Unexpected After Migration, Not Compared and Evidence Missing.

RAG remains separate from ReconciliationStatus and reviewer disposition.

## 7. Controlled report

Template version: `1.2.0`  
Template-map version: `2.0.0`

Exact sheet order:

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

## 8. Raw evidence contract

The three raw evidence tables are append-only. The engine shall not edit, reorder, delete, normalize or reinterpret rows in place and shall preserve literal source headers exactly, including `Source.Name` and `DossierDirecotry`.

Normalized interpretations belong only in interpreted sheets/result collections.

## 9. Reviewer contract

SystemComparisonNote records engine-derived comparison evidence. ReviewerNote and ReviewerDisposition are controlled reviewer inputs. Reviewer input shall not silently overwrite source evidence, normalized discrepancy classification or accepted-exception traceability.

## 10. Failure behavior

- incompatible baseline: stop or produce Verification Incomplete according to controlled policy;
- missing mandatory evidence: Verification Incomplete;
- failed import or missing expected entity: preserve discrepancy and apply configured blocker/RAG rules;
- parse/reader failure: preserve available raw evidence/logs and do not issue a reconciliation conclusion;
- workbook population failure: retain normalized result/log and mark report generation failed.

## 11. Outputs

- controlled Post-Migration XLSX report;
- normalized phase result JSON;
- preserved raw import/post/database evidence in controlled report tables;
- discrepancy/action and review records;
- separate timestamped UTF-8 execution log;
- optional manifest/checksum evidence according to package configuration.

## 12. Acceptance criteria

The phase conforms when:

- the approved baseline is validated before comparison;
- all four evidence positions remain distinct;
- missing mandatory evidence produces Verification Incomplete;
- expected and observed values/provenance remain traceable;
- discrepancies and exceptions preserve original evidence;
- system and reviewer notes remain separate;
- all three raw evidence tables are append-only and preserve literal headers;
- source evidence remains read-only;
- only the four approved final results are used;
- the exact fifteen-sheet workbook opens without repair;
- normalized results validate against the v3.2 result schema;
- a separate log is produced.
