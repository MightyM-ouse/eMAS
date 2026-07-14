# eMAS Pre-Migration Readiness Phase Contract

**Version:** 1.2  
**Status:** Approved Working Contract on `requirements/report-redesign-v3.2`  
**Phase code:** `PRE_MIGRATION`  
**Runtime:** PowerShell 7.6 LTS on Windows  
**Canonical requirement:** `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md`  
**Detailed report requirement:** `docs/requirements/report-redesign/02_eMAS_PreMigration_Report_Requirements_v1.1.md`

## 1. Purpose

Pre-Migration determines whether the approved migration scope is technically and operationally ready and creates the immutable attributable baseline consumed by Post-Migration Verification.

It does not execute migration, provide regulatory validation, constitute formal customer validation, approve migration electronically or record customer acceptance.

## 2. Entry and interface

The phase is invoked through the PowerShell entry script or an optional portable WPF interface that invokes the same script and shared engine. CLI and WPF shall produce equivalent normalized results for equivalent inputs.

## 3. Inputs

At minimum, as applicable to the approved scope:

- customer/project/migration reference;
- approved source and target system/version context;
- controlled runtime JSON, schema, template and technical map;
- approved source roots and evidence sources;
- transfer, access, backup, storage and staging prerequisites;
- exclusions and candidate exception evidence;
- prior Pre-Sales result where useful but not treated as a readiness baseline;
- output and baseline locations.

Only applicable inputs are required. Missing optional evidence is explicit and does not become Green.

## 4. Startup validation

Before source scanning, the phase validates:

- package and runtime compatibility;
- runtime JSON schema/version/checksum;
- duplicate IDs and required references according to the loader contract;
- phase applicability;
- template version 1.2.0 and map version 2.0.0 compatibility;
- output permissions;
- mandatory input availability.

Failure of these checks stops execution before scanning and produces a clear error/log entry.

## 5. Processing contract

The phase shall:

1. create execution identity and detailed timestamped UTF-8 logging;
2. validate and record current scope/evidence identity;
3. perform read-only access, transfer, backup, storage and staging checks where applicable;
4. discover dossiers and sequences and generate stable comparison IDs;
5. evaluate configured folder/file/XML/reference/path/content checks;
6. create normalized file-type/count/size records;
7. preserve EvaluationStatus, RAG, Severity, Blocker, Confidence, ValueSource and ReviewRequired separately;
8. create findings and separate actions/recommendations;
9. evaluate accepted exceptions without erasing original findings/evidence;
10. determine only `Ready`, `Ready with Accepted Exceptions` or `Blocked`;
11. assign approved MigrationMethod and MigrationWave to each in-scope dossier/sequence or explicit Not Applicable treatment;
12. build the normalized result and attributable Post-Migration baseline;
13. populate the controlled eleven-sheet workbook;
14. write integrity evidence and output locations to the log/result.

Unresolved blockers force `Blocked`.

## 6. Accepted-exception contract

An accepted exception requires stable ExceptionId, affected finding/entity, original EvaluationStatus/RAG/evidence, configured eligibility/policy/effect, approval role/reference/date, supporting evidence, validity/expiry and carry-forward treatment.

An accepted exception may affect the phase decision only as permitted by policy. It never changes or removes the observed finding/evidence and is carried to Post-Migration where required.

## 7. Controlled report

Template version: `1.2.0`  
Template-map version: `2.0.0`

Exact sheet order:

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

## 8. Baseline contract

The baseline includes:

- BaselineId and source ExecutionId;
- approval/status and integrity evidence;
- source scope/root identities;
- stable dossier/sequence comparison IDs;
- normalized classification dimensions;
- expected dossier/sequence/file/folder/size measures;
- normalized file-type/count/size measures;
- MigrationMethod and MigrationWave;
- findings, exclusions and accepted-exception carry-forward;
- assumptions and limitations;
- configuration/schema/mapping/engine/template identities.

The baseline shall be immutable for a completed approved run. Changes create a new baseline/version and preserve supersession traceability.

## 9. Result and failure behavior

Permitted results:

- `Ready`
- `Ready with Accepted Exceptions`
- `Blocked`

Technical execution failure is not reported as a completed readiness decision. Partial evidence is retained and labelled incomplete where safe, but no Ready result is issued.

## 10. Outputs

- controlled Pre-Migration XLSX report;
- normalized phase result JSON;
- immutable attributable comparison baseline and integrity evidence;
- separate timestamped UTF-8 execution log;
- optional manifest/checksum evidence according to package configuration.

## 11. Acceptance criteria

The phase conforms when:

- startup validation stops incompatible runs before scanning;
- source evidence remains read-only;
- only the three approved readiness outcomes are used;
- unresolved blockers force Blocked;
- exceptions preserve original findings/evidence;
- all in-scope dossiers/sequences have stable IDs and approved method/wave or explicit Not Applicable treatment;
- file-type totals reconcile with baseline totals;
- the baseline is attributable, integrity-protected and reusable by Post-Migration;
- the exact eleven-sheet workbook opens without repair;
- normalized results validate against the v3.2 result schema;
- a separate log is produced.
