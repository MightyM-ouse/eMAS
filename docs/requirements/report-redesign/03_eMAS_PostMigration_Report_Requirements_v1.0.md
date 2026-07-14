# eMAS Post-Migration Verification Report Requirements

**Document version:** 1.0  
**Status:** Finalized Working Requirement  
**Phase code:** `POST_MIGRATION`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner, Migration SME, Technical Architect and Validation Representative  
**Implementation state:** Requirements frozen; template, normalized result object, database extract adapter and report-mapping JSON changes pending

## 1. Purpose

The Post-Migration Verification report shall compare the approved Pre-Migration baseline with migration import evidence, target database evidence and post-import verification evidence. It shall provide a traceable technical reconciliation result and a controlled register of discrepancies, accepted differences, reviewer notes and closure actions.

The report shall answer:

1. Did every expected dossier and sequence migrate?
2. Do baseline, import-report, target-database and post-import evidence agree?
3. Which dossiers, sequences, files, file types, sizes and technical checks match, differ or cannot be compared?
4. Which differences are accepted, unresolved, review-pending or covered by approved exceptions?
5. Does the target database contain the expected dossier metadata and sequence population?
6. Which import warnings, failures, skipped items or unclassified messages require action?
7. Is the migration technically reconciled and ready for migration closeout review?

The report does not constitute formal customer acceptance, regulated system validation, business process validation or electronic approval.

## 2. Final workbook composition

The final Post-Migration workbook shall contain the following sheets in this order:

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

A separate timestamped UTF-8 execution log shall be created for every execution. The log is not an Excel worksheet.

The three raw-evidence sheets shall be append-only and shall preserve source headers, row order and values exactly. The reporting engine shall not correct, rename, reorder, reinterpret or overwrite raw evidence.

## 3. Evidence model

The interpreted report shall reconcile four evidence positions:

`Pre-Migration Baseline -> Import Report -> Target Database -> Post-Import Verification`

The approved Pre-Migration baseline remains the authoritative expected state. Import-report, target-database and post-import evidence are independent observed sources. Presence in one observed source shall not automatically prove presence in another.

Required evidence sources are:

- approved compatible Pre-Migration baseline;
- migration import report;
- post-import file-system or package verification evidence;
- target database dossier extract where database verification is in scope;
- approved exclusions;
- carried-forward and newly approved accepted exceptions;
- supplementary project evidence where explicitly referenced.

Missing mandatory evidence shall result in `Verification Incomplete` or an explicit failed-execution state, according to the failure point. It shall not be presented as a completed reconciliation result.

## 4. Sheet 01 — Executive Summary

### 4.1 Purpose

The Executive Summary shall allow the migration lead, project manager and reviewer to determine without reviewing detailed sheets:

- the overall verification result and confidence;
- baseline compatibility and evidence completeness;
- dossier and sequence reconciliation totals;
- file, folder, size, checksum and file-type differences;
- import success, warning, failure and skipped counts;
- database reconciliation totals;
- unresolved discrepancies and accepted differences;
- critical closure actions;
- review and handover status.

It shall not duplicate detailed technical rows, complete rule evidence or raw execution evidence.

### 4.2 Section A — Verification context

The summary shall include:

| Field | Requirement |
|---|---|
| Customer Name | Customer identification |
| Project Name | Migration project name |
| Migration Reference | Stable migration reference |
| Verification Reference | Stable Post-Migration verification reference |
| Verification Date | Generated date and time |
| Source Application | Source application or external system |
| Source Application Version | Source version |
| Target Application | Target application |
| Target Application Version | Target version |
| Target Application Hotfix | Target hotfix where applicable |
| Migration Scenario | Approved migration scenario |
| Migration Completion Date | Migration completion date/time where available |
| Pre-Migration Baseline ID | Baseline identifier used for comparison |
| Pre-Migration Baseline Status | Baseline approval status |
| Baseline Compatibility Status | Compatible, Compatible with Warning, Incompatible or Unknown |
| Import Report Reference | Import evidence identifier/path |
| Post-Import Evidence Reference | Verification evidence identifier/path |
| Database Extract Reference | Database evidence identifier/path |
| Verification Status | Draft, Ready for Review, Reviewed, Technically Reconciled, Technically Reconciled with Accepted Exceptions, Not Reconciled or Superseded |

### 4.3 Section B — Final reconciliation result

The final result shall be prominently displayed and shall include:

- Verification Result;
- Verification Confidence;
- Decision Rationale;
- Unresolved Discrepancy Count;
- Accepted Difference Count;
- Review-Pending Count;
- Missing Dossier Count;
- Missing Sequence Count;
- Unexpected Dossier Count;
- Unexpected Sequence Count;
- Failed Import Count;
- Warning Import Count;
- Required Next Action;
- Responsible Party;
- Target Date.

Permitted final results are:

- `Reconciled`;
- `Reconciled with Accepted Exceptions`;
- `Not Reconciled`;
- `Verification Incomplete`.

The result and rationale shall be configuration-derived and traceable to reconciliation records, discrepancy policies and exception effects.

### 4.4 Section C — Dossier reconciliation summary

Required metrics:

- Baseline Dossiers;
- Import Report Dossiers;
- Database Dossiers;
- Post-Import Verified Dossiers;
- Fully Matched Dossiers;
- Accepted-Difference Dossiers;
- Review-Pending Dossiers;
- Mismatched Dossiers;
- Missing Dossiers;
- Unexpected Dossiers;
- Green, Amber, Red and Unknown Dossiers;
- Dossiers with Reviewer Notes;
- Dossiers with Open Actions.

### 4.5 Section D — Sequence reconciliation summary

Required metrics:

- Baseline Sequences;
- Import Report Sequences;
- Database Sequences;
- Post-Import Verified Sequences;
- Fully Matched Sequences;
- Accepted-Difference Sequences;
- Review-Pending Sequences;
- Mismatched Sequences;
- Missing Sequences;
- Unexpected Sequences;
- Failed Import Sequences;
- Warning Import Sequences;
- Skipped Sequences;
- Green, Amber, Red and Unknown Sequences.

### 4.6 Section E — File and volume reconciliation

Required metrics:

- Baseline and Post-Migration File Count;
- File Count Difference;
- Baseline and Post-Migration Folder Count;
- Folder Count Difference;
- Baseline and Post-Migration Size;
- Size Difference;
- File Types Fully Matched;
- File Types with Accepted Difference;
- File Types with Unresolved Difference;
- Missing Files;
- Unexpected Files;
- Zero-Byte Files Before and After Migration;
- Checksum Coverage Before and After Migration;
- Checksum Differences;
- Largest Unresolved Size Difference.

### 4.7 Section F — Import execution summary

Required metrics:

- Import Report Rows;
- Successful Imports;
- Successful with Warning;
- Failed Imports;
- Skipped Imports;
- Duplicate Imports;
- Retried Imports;
- Cancelled Imports;
- Unclassified Import Messages;
- Import Rows Requiring Review;
- Import Start Time;
- Import End Time;
- Total Import Duration;
- Import Evidence Completeness;
- Raw Import Report Preserved.

Import-message normalization, RAG and reconciliation effects shall be mapping-driven and shall not be hardcoded in PowerShell.

### 4.8 Section G — Database reconciliation summary

Required metrics:

- Expected Dossiers in Database;
- Dossiers Found in Database;
- Missing Database Dossiers;
- Unexpected Database Dossiers;
- Dossier Names Matched;
- Region Values Matched;
- Procedure or Authority Values Matched;
- Format Values Matched;
- Sequence Counts Matched;
- Database Records Requiring Review;
- Database Evidence Confidence.

### 4.9 Section H — Critical discrepancies and closure actions

The summary shall display:

- all unresolved Red discrepancies;
- missing expected dossiers or sequences;
- unexpected dossiers or sequences;
- failed imports;
- database mismatches;
- expired or invalid exceptions;
- review-pending Amber items;
- up to ten lower-severity items ordered by configured priority.

Columns:

- Priority;
- Discrepancy ID;
- Area;
- Dossier;
- Sequence;
- Difference;
- RAG;
- Primary RAG Reason;
- Accepted Exception;
- Required Action;
- Owner;
- Target Date;
- Review Status;
- Reviewer Note.

### 4.10 Section I — Review and handover

Required fields:

- Technical Reconciliation Status;
- Reviewer Name or Role;
- Review Date;
- Open Action Count;
- Open Red Item Count;
- Accepted Exception Count;
- Customer Review Required;
- Migration Closeout Evidence Ready;
- Report Handover Status;
- Final Reviewer Note.

The workbook shall not state customer acceptance unless that acceptance is provided through a separate controlled process.

## 5. Sheet 02 — Verification Scope

The current scope model shall be retained and enhanced.

Required columns:

- Scope Item ID;
- Scope Area;
- Evidence Type;
- Baseline Source;
- Migrated Evidence Source;
- Evidence Version;
- Evidence Generated At;
- Evidence Checksum;
- Comparison Key;
- Mandatory Evidence;
- Evidence Available;
- Included;
- Exclusion ID;
- Exception ID;
- Compatibility Status;
- Value Source;
- Evaluation Status;
- Confidence;
- Review Required;
- Evidence Limitation;
- Comments.

## 6. Sheet 03 — Overall Reconciliation

This sheet replaces the current `03_Baseline_vs_Migrated` title while retaining its traceable comparison model.

Required columns:

- Reconciliation Metric ID;
- Area;
- Metric Code;
- Metric Name;
- Entity Scope;
- Baseline Value;
- Import Report Value;
- Database Value;
- Post-Import Value;
- Absolute Difference;
- Percentage Difference;
- Unit;
- Value Source;
- Evaluation Status;
- Confidence;
- Comparison Rule ID;
- Tolerance;
- Comparison Result;
- Reconciliation Status;
- RAG;
- Primary RAG Reason;
- Accepted Exception;
- Exception ID;
- Review Required;
- Discrepancy ID;
- System Comparison Note;
- Reviewer Note;
- Reviewer Disposition.

## 7. Sheet 04 — Dossier Before & After

This sheet shall provide the authoritative dossier-level reconciliation view.

### 7.1 Identification and classification

- Dossier Comparison ID;
- Stable Comparison ID;
- Baseline Dossier ID;
- Target Database Dossier ID;
- Product;
- Baseline Dossier Name;
- Imported Dossier Name;
- Database Dossier Name;
- Post-Import Dossier Name;
- Region;
- Authority;
- Technical Standard or Format;
- Regional Implementation;
- Primary Dossier Type;
- Migration Method;
- Migration Wave.

### 7.2 Evidence presence

- Baseline Present;
- Import Report Present;
- Database Present;
- Post-Import Evidence Present.

### 7.3 Before-and-after metrics

- Baseline Sequence Count;
- Import Report Sequence Count;
- Database Sequence Count;
- Post-Import Sequence Count;
- Sequence Count Difference;
- Baseline File Count;
- Post-Import File Count;
- File Count Difference;
- Baseline Folder Count;
- Post-Import Folder Count;
- Folder Count Difference;
- Baseline Size;
- Post-Import Size;
- Size Difference;
- Import Status Summary.

### 7.4 Assessment and review

- Pre-Migration RAG;
- Post-Migration RAG;
- Primary RAG Reason;
- Reconciliation Status;
- Discrepancy IDs;
- Accepted Exception;
- Exception IDs;
- Review Required;
- System Comparison Note;
- Reviewer Note;
- Reviewer Disposition;
- Owner;
- Target Date;
- Review Status;
- Recommended Action.

## 8. Sheet 05 — Sequence Before & After

### 8.1 Identification and classification

- Sequence Comparison ID;
- Stable Comparison ID;
- Baseline Dossier ID;
- Target Database Dossier ID;
- Dossier Name;
- Baseline Sequence ID;
- Target Sequence ID;
- Sequence Number or Name;
- Region;
- Technical Standard or Format;
- Regional Implementation;
- Migration Method;
- Migration Wave.

### 8.2 Evidence presence

- Baseline Present;
- Import Report Present;
- Database Present;
- Post-Import Evidence Present.

### 8.3 Before-and-after metrics

- Baseline File Count;
- Post-Import File Count;
- File Count Difference;
- Baseline Folder Count;
- Post-Import Folder Count;
- Folder Count Difference;
- Baseline Size;
- Post-Import Size;
- Size Difference;
- Baseline Backbone XML Status;
- Post-Import Backbone XML Status;
- Baseline Checksum Status;
- Post-Import Checksum Status;
- Baseline Referenced-File Status;
- Post-Import Referenced-File Status;
- Import Status;
- Import Status Code.

### 8.4 Assessment and review

- Pre-Migration RAG;
- Post-Migration RAG;
- Primary RAG Reason;
- Reconciliation Status;
- Discrepancy IDs;
- Accepted Exception;
- Exception IDs;
- Review Required;
- System Comparison Note;
- Reviewer Note;
- Reviewer Disposition;
- Owner;
- Target Date;
- Review Status;
- Recommended Action.

## 9. Sheet 06 — File Type & Size Comparison

This sheet shall correspond directly to the Pre-Migration `06_File_Type_Breakdown` dataset.

Required columns:

- Comparison ID;
- Dossier ID;
- Dossier Name;
- Sequence ID;
- Sequence Name;
- File Extension;
- File Category;
- Baseline File Count;
- Post-Migration File Count;
- File Count Difference;
- Baseline Total Size;
- Post-Migration Total Size;
- Size Difference;
- Baseline Largest File;
- Post-Migration Largest File;
- Baseline Zero-Byte Count;
- Post-Migration Zero-Byte Count;
- Baseline Unsupported Count;
- Post-Migration Unsupported Count;
- Baseline Encrypted Count;
- Post-Migration Encrypted Count;
- Tolerance;
- Reconciliation Status;
- RAG;
- Primary RAG Reason;
- Accepted Exception;
- Exception ID;
- Discrepancy ID;
- Review Required;
- System Comparison Note;
- Reviewer Note;
- Reviewer Disposition;
- Recommended Action.

## 10. Sheet 07 — Database Dossier Inventory

This new interpreted sheet shall record dossier information from the target application database or approved application extract.

Required columns:

- Database Record ID;
- Target Dossier ID;
- Stable Comparison ID;
- Dossier Name;
- Product;
- Region;
- Authority or Procedure;
- Technical Standard or Format;
- Regional Implementation;
- Lifecycle Status;
- Sequence Count;
- First Sequence;
- Last Sequence;
- Creation Date;
- Import Date;
- Last Modified Date;
- Active or Deleted Status;
- Archive or Repository Reference;
- Source Query or Extract Reference;
- Value Source;
- Evaluation Status;
- Confidence;
- Baseline Match Status;
- RAG;
- Primary RAG Reason;
- Review Required;
- Reviewer Note;
- Comments.

The mapping configuration shall define mandatory, optional and unavailable fields by supported application and version.

Initial implementation shall accept a controlled read-only CSV or XLSX database extract. Direct production-database connectivity is not required for the first implementation. A future approved adapter may automate the extract without changing this report contract.

## 11. Sheet 08 — Import Evidence Review

The current normalized interpretation of raw import evidence shall be retained and enhanced.

Required columns:

- Import Evidence ID;
- Source Row Reference;
- Source Name;
- Source Dossier;
- Source Sequence;
- Destination Dossier;
- Destination Sequence;
- Import Start Time;
- Import End Time;
- Duration;
- Raw Status;
- Raw Status Code;
- Raw Message;
- Normalized Category;
- Normalized Result;
- RAG;
- Primary RAG Reason;
- Rule ID;
- Finding Code;
- Discrepancy ID;
- Review Required;
- Recommended Action;
- Reviewer Note;
- Reviewer Disposition;
- Comments.

Every interpreted row shall retain a stable reference to its original row in `Import Report Detail`.

## 12. Sheet 09 — Discrepancies & Actions

This sheet shall be the central discrepancy, action and disposition register.

Required columns:

- Discrepancy ID;
- Entity Type;
- Dossier ID;
- Dossier Name;
- Sequence ID;
- Comparison Area;
- Expected Value;
- Import Value;
- Database Value;
- Observed Value;
- Difference;
- Classification;
- Severity;
- RAG;
- Primary RAG Reason;
- Blocker;
- Accepted Exception;
- Exception ID;
- Required Action;
- Owner;
- Target Date;
- System Note;
- Reviewer Note;
- Reviewer Disposition;
- Review Status;
- Closure Evidence Reference;
- Closed By;
- Closed Date.

Controlled reviewer disposition values:

- Confirmed Match;
- Accepted Difference;
- Remediation Required;
- Further Investigation Required;
- Not Applicable;
- Duplicate Discrepancy;
- Deferred with Approval;
- Rejected;
- Closed.

Reviewer-entered fields shall remain visually distinguishable from system-generated fields and shall not be overwritten when the report is refreshed unless the controlled refresh policy explicitly permits it.

## 13. Sheet 10 — Accepted Exceptions

The current exception model shall be retained.

Each exception shall preserve:

- original Pre-Migration finding and evidence;
- original Evaluation Status and RAG;
- exception ID;
- approved exception effect;
- approver role and approval reference;
- supporting evidence reference;
- validity and expiry information;
- carry-forward status;
- whether the observed Post-Migration difference is within the approved exception;
- final reviewer disposition.

An accepted exception shall never remove the underlying discrepancy or overwrite the original finding.

## 14. Sheet 11 — Assumptions & Limits

The existing sheet shall be retained.

It shall explicitly record limitations where:

- the database extract was unavailable;
- import-report rows could not be mapped to a stable comparison ID;
- post-import evidence was incomplete;
- different size-allocation methods were used;
- file timestamps changed during transfer;
- exclusions prevented a complete population comparison;
- database fields were unavailable for a supported application version;
- comparison tolerances were applied;
- verification evidence was customer-provided rather than observed by the engine.

## 15. Sheet 12 — Review & Execution

### 15.1 Review fields

- Technical Reviewer;
- Reviewer Role;
- Review Date;
- Final Disposition;
- Open Action Count;
- Approved Exception Count;
- Migration Closeout Recommendation;
- Final Reviewer Note.

### 15.2 Execution fields

- Execution ID;
- Engine Version;
- Mapping Version;
- Runtime Schema Version;
- Template Version;
- PowerShell Version;
- .NET Version;
- Runtime Adapter Information;
- Source Evidence Checksums;
- Baseline Checksum;
- Import Report Checksum;
- Post-Import Evidence Checksum;
- Database Extract Checksum;
- Output Paths;
- Start Time;
- End Time;
- Execution Result.

## 16. Raw evidence sheets

### 16.1 Import Report Detail

Rows shall be copied verbatim from the supplied migration import report. Existing headers, including any approved literal spelling, shall be preserved exactly.

### 16.2 Post Import Verification

Rows shall be copied verbatim from the supplied post-import verification evidence. Existing headers, including any approved literal spelling, shall be preserved exactly.

### 16.3 Database Dossier Extract

Rows shall be copied verbatim from the approved database or application extract. Normalization shall occur only in `07_Database_Dossier_Inventory`.

Raw evidence sheets shall be protected as append-only evidence. They shall not be edited, corrected, reordered or deduplicated by the reporting engine.

## 17. RAG and reconciliation semantics

### 17.1 Post-Migration RAG

| RAG | Meaning |
|---|---|
| Green | Expected and observed evidence matches or is within approved tolerance |
| Amber | Accepted difference, recoverable difference or reviewer disposition required |
| Red | Unresolved mismatch, missing expected item, failed import or closeout blocker |
| Unknown | Required evidence is unavailable or cannot be reliably compared |

RAG shall remain separate from Reconciliation Status, Evaluation Status, Severity and Review Required.

### 17.2 Reconciliation Status values

- Matched;
- Matched Within Tolerance;
- Accepted Difference;
- Review Required;
- Mismatched;
- Missing After Migration;
- Unexpected After Migration;
- Not Compared;
- Evidence Missing.

## 18. Configuration-mapping requirements

The following shall be configuration-driven and shall not be hardcoded in PowerShell:

- Executive Summary metric labels, order and visibility;
- final-result decision policies;
- evidence mandatory/optional status;
- baseline compatibility rules;
- stable comparison key rules;
- comparison tolerances;
- reconciliation status assignment;
- RAG assignment and Primary RAG Reason;
- import-message normalization;
- database-field mappings by application and version;
- discrepancy classification and severity;
- blocker rules;
- accepted-exception effects;
- reviewer disposition value lists;
- critical-item selection and ordering;
- customer-facing rationale and action text;
- file-type categories;
- raw evidence preservation rules.

The mapping shall contain no executable script code and shall be validated against the runtime schema and semantic rules before processing begins.

## 19. Normalized result-object additions

The Post-Migration normalized result object shall support at minimum:

- `verificationContext`;
- `verificationDecision`;
- `summaryMetrics`;
- `verificationScope`;
- `overallReconciliation`;
- `dossierBeforeAfter`;
- `sequenceBeforeAfter`;
- `fileTypeSizeComparison`;
- `databaseDossierInventory`;
- `importEvidenceReview`;
- `discrepanciesAndActions`;
- `acceptedExceptions`;
- `assumptionsAndLimitations`;
- `reviewAndExecution`;
- `rawImportReportDetail`;
- `rawPostImportVerification`;
- `rawDatabaseDossierExtract`.

Each interpreted reconciliation record shall retain stable IDs and evidence references sufficient to trace it to the baseline and all applicable observed evidence.

## 20. Compatibility with Pre-Migration

Post-Migration shall consume the approved Pre-Migration baseline and shall compare compatible fields without reinterpretation.

The following fields shall be carried forward where applicable:

- Baseline ID and status;
- Stable Comparison IDs;
- dossier and sequence classification;
- expected dossier, sequence, file, folder and size measures;
- file-type breakdown;
- Migration Method;
- Migration Wave;
- original Pre-Migration RAG;
- Primary RAG Reason;
- exclusions;
- accepted exceptions and carry-forward status;
- configuration, schema, mapping, engine and template versions;
- baseline integrity evidence.

An incompatible baseline shall stop or produce `Verification Incomplete` according to configured policy. It shall not be silently converted or ignored.

## 21. Acceptance criteria

The Post-Migration report requirement is satisfied when:

1. one controlled XLSX report and one detailed timestamped log are generated;
2. the Executive Summary provides the final reconciliation result, evidence completeness, dossier/sequence totals, import summary, database summary, critical discrepancies and handover status;
3. every dossier and sequence can be traced across baseline, import report, database and post-import evidence where those sources are in scope;
4. before-and-after file counts, folder counts, sizes and technical statuses are shown;
5. file-type counts and sizes reconcile to the Pre-Migration breakdown;
6. target database dossier information is represented through an interpreted inventory and preserved raw extract;
7. system-generated notes and reviewer notes are separate;
8. reviewer disposition, owner, target date and review status are supported;
9. original findings, original RAG and accepted exceptions are preserved;
10. missing, unexpected, failed, mismatched, accepted-difference and review-required states are distinguishable;
11. raw evidence is preserved verbatim and protected against alteration;
12. result-driving rules, tolerances and mappings are traceable;
13. the report does not claim formal customer acceptance or regulatory validation;
14. the normalized result object and report mapping validate successfully;
15. compatibility tests confirm that the Post-Migration reader consumes the finalized Pre-Migration baseline correctly.

## 22. Implementation sequence

After approval of all three phase requirements, implementation shall proceed in this order:

1. consolidate Enterprise Requirements v3.2 and update phase contracts;
2. update the normalized result-object and runtime schema;
3. add database extract and import-message mapping contracts;
4. update the Post-Migration report-mapping JSON;
5. create the controlled Post-Migration Excel template;
6. update the shared reporting engine and evidence adapters;
7. update demo data and generate representative reports;
8. add schema, semantic, compatibility, template and regression tests;
9. validate the generated workbook against this requirement and the approved Pre-Migration baseline contract.
