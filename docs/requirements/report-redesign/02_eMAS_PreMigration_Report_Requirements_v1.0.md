# eMAS Pre-Migration Readiness Report Requirements

**Document version:** 1.0  
**Status:** Finalized Working Requirement  
**Phase code:** `PRE_MIGRATION`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Implementation state:** Requirements frozen; template, normalized result object and report-mapping JSON changes pending

## 1. Purpose

The Pre-Migration Readiness report shall provide the detailed technical and operational evidence required to decide whether the agreed migration scope can proceed. It shall also create the attributable baseline consumed by Post-Migration Verification.

The report shall answer:

1. Is the agreed migration scope ready to proceed?
2. Which dossiers and sequences are Green, Amber, Red or Unknown, and why?
3. Which unresolved blockers, warnings, preparation actions, exclusions and accepted exceptions exist?
4. What dossier, sequence, file, folder, size and file-type measures form the approved comparison baseline?
5. Which migration method and migration wave apply to each dossier and sequence?
6. Are source access, database, archive, index, backup, staging, storage and transfer prerequisites ready?
7. Which baseline and exception evidence must be carried into Post-Migration Verification?

The report is a migration-readiness and baseline output. It does not perform migration, regulatory validation, formal customer validation, electronic approval or customer acceptance.

## 2. Final workbook composition

The final Pre-Migration workbook shall contain the following sheets in this order:

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

A separate timestamped UTF-8 execution log shall be created for every execution. The log is not an Excel worksheet.

The current detailed report structure shall otherwise be retained. The principal redesign applies to `01_Executive_Summary`, with controlled additions to the dossier and sequence baseline sheets and one new normalized file-type breakdown sheet.

## 3. Sheet 01 — Executive Summary

### 3.1 Purpose

The Executive Summary shall provide a concise operational view of readiness. It shall enable a migration lead to understand, without reviewing the detailed sheets:

- the overall readiness decision;
- the assessed and approved migration scope;
- the Green, Amber, Red and Unknown dossier and sequence populations;
- unresolved blockers, warnings and limitations;
- accepted exceptions and exclusions;
- the confirmed migration scenario, workstreams and waves;
- source, archive, database and transfer volumes;
- baseline integrity and handover status;
- actions that must be completed before migration begins.

The Executive Summary shall not duplicate detailed technical findings, rule evidence or full execution metadata.

### 3.2 Section A — Assessment context

The summary shall include:

| Field | Requirement |
|---|---|
| Customer Name | Customer identification |
| Project Name | Migration project name |
| Migration Reference | Stable project or migration reference |
| Assessment Date | Generated date and time |
| Baseline ID | Stable baseline identifier |
| Baseline Status | Draft, Ready for Review, Reviewed, Approved for Migration Use or Superseded |
| Source Application | Source product or external system |
| Source Application Version | Current source version |
| Source Application Hotfix | Current source hotfix where applicable |
| Target Application | Target product |
| Target Application Version | Planned target version |
| Target Application Hotfix | Planned target hotfix where applicable |
| Approved Migration Scenario | Confirmed migration scenario |
| Configuration Version | Runtime configuration version used |
| Template Version | Controlled template version used |

`Approved for Migration Use` means that the baseline is approved for operational migration use. It shall not imply formal validation or customer acceptance.

### 3.3 Section B — Readiness decision

The readiness result shall be visually prominent and shall contain:

| Field | Requirement |
|---|---|
| Readiness Result | `Ready`, `Ready with Accepted Exceptions` or `Blocked` |
| Decision Confidence | High, Medium, Low or Unknown |
| Decision Rationale | Concise configuration-derived explanation |
| Blocker Count | Unresolved blocker count |
| Warning Count | Usable evaluations requiring attention |
| Accepted Exception Count | Valid accepted exceptions |
| Exclusion Count | Explicit scope exclusions |
| Unresolved Limitation Count | Limitations that remain open |
| Review Required | Yes or No |
| Required Next Action | Immediate action required after review |
| Responsible Party | Responsible role or party |
| Target Date | Required completion date |

Example presentation:

```text
Overall Readiness Result:
Ready with Accepted Exceptions

Decision Confidence:
High

Decision Rationale:
No unresolved blockers remain. Two controlled accepted exceptions cover the residual checksum and long-path findings.

Required Next Action:
Carry the approved baseline and accepted exceptions into migration execution.
```

Decision wording and rationale templates shall be configuration-driven and not hardcoded in PowerShell.

### 3.4 Section C — Dossier readiness summary

The summary shall include:

- Total Dossiers Assessed
- Dossiers Included in Migration
- Dossiers Excluded
- Green Dossiers
- Amber Dossiers
- Red Dossiers
- Unknown Dossiers
- Dossiers with Accepted Exceptions
- Dossiers Requiring Review
- Dossiers Requiring Remediation
- Batch-Import Dossiers
- Individual-Import Dossiers
- Conversion-and-Import Dossiers
- Database/Archive Migration Dossiers

### 3.5 Section D — Sequence readiness summary

The summary shall include:

- Total Sequences Assessed
- Sequences Included in Migration
- Sequences Excluded
- Green Sequences
- Amber Sequences
- Red Sequences
- Unknown Sequences
- Sequences with Accepted Exceptions
- Sequences Requiring Review
- Batch-Eligible Sequences
- Individual-Import Sequences
- Conversion-Required Sequences
- Missing Mandatory-Item Sequences
- Checksum-Warning Sequences
- Referenced-File-Issue Sequences
- Zero-Byte-File Sequences
- Long-Path Sequences

RAG, migration method and exception treatment shall remain separate concepts. A Green sequence may still require individual import. An accepted exception shall not overwrite the original RAG or finding.

### 3.6 Section E — Scope and volume

The summary shall include:

| Metric | Unit or presentation |
|---|---|
| Export Size | GB or TB |
| Source Size | GB or TB |
| Archive Size | GB or TB |
| Index Size | GB or TB |
| Database Size | GB |
| Database Backup Size | GB |
| Total File Count | Count |
| Total Folder Count | Count |
| Unique Transfer Volume | GB or TB |
| Staging Capacity Required | GB or TB |
| Available Staging Capacity | GB or TB |
| Storage Headroom | GB/TB and percentage where available |
| Largest Dossier | Name and size |
| Largest Sequence | Dossier, sequence and size |

The same size definitions and overlap-handling rules established for Pre-Sales shall be used. Overlapping roots shall not be double-counted in Unique Transfer Volume.

### 3.7 Section F — Confirmed migration approach

The summary shall carry the Pre-Sales recommendation forward and confirm it against the deeper Pre-Migration evidence.

Required fields:

| Field | Requirement |
|---|---|
| Confirmed Migration Scenario | Approved scenario after detailed assessment |
| Scenario Changed Since Pre-Sales | Yes, No or Not Assessed |
| Change Reason | Explanation where the scenario changed |
| Confirmed Migration Workstreams | Ordered workstream list |
| Upgrade Path Confirmed | Yes, No or Not Applicable |
| Upgrade Hop Count | Confirmed sequential upgrade stages |
| Database Migration Confirmed | Yes, No or Not Applicable |
| Archive Migration Confirmed | Yes, No or Not Applicable |
| Batch Import Confirmed | Yes, No or Partial |
| Individual Import Confirmed | Yes, No or Partial |
| Conversion Activities Confirmed | Yes, No or Partial |
| Migration Wave Count | Number of approved waves |
| Migration Wave Summary | Ordered wave description |
| Rollback/Recovery Evidence Available | Yes, No or Not Assessed |
| Backup Evidence Available | Yes, No or Not Assessed |

Example:

```text
Confirmed Scenario:
Migration and eCTDmanager Sequential Upgrade

Confirmed Workstreams:
1. Sequential eCTDmanager upgrade
2. MS SQL database migration
3. Archive and index migration
4. EU batch import
5. Non-EU individual sequence import
6. Legacy NeeS conversion and import

Migration Waves:
Wave 1 — Application and database upgrade
Wave 2 — EU batch-eligible dossiers
Wave 3 — Non-EU individual imports
Wave 4 — Legacy conversion dossiers
```

Scenario names, workstreams, wave rules and presentation text shall be configuration-driven and reviewable. The engine shall not invent a migration wave without an applicable controlled rule.

### 3.8 Section G — Critical actions before migration

The summary shall show only the highest-priority open items:

| Column | Requirement |
|---|---|
| Priority | Critical, High, Medium or Low |
| Action ID | Stable action identifier |
| Area | Access, Backup, Database, Archive, Dossier, Sequence, Storage, Transfer, Conversion or other controlled area |
| Required Action | Concise action description |
| Related Dossier | Optional dossier reference |
| Related Sequence | Optional sequence reference |
| Blocker | Yes or No |
| Covered by Exception | Yes or No |
| Owner | Responsible role or party |
| Target Date | Required date |
| Status | Controlled workflow status |

Display rules shall include:

- all unresolved blockers;
- all Red items;
- unresolved High-severity Amber items;
- expired, invalid or incomplete accepted exceptions;
- missing mandatory backup, access, staging or recovery evidence;
- no more than ten additional non-blocking warnings, ordered by configured priority.

### 3.9 Section H — Baseline integrity and handover

The summary shall include:

| Field | Requirement |
|---|---|
| Baseline ID | Stable baseline identifier |
| Baseline Generated At | Timestamp |
| Baseline Dossier Count | Included dossier count |
| Baseline Sequence Count | Included sequence count |
| Baseline File Count | Expected file count where assessed |
| Baseline Size | Expected unique size where assessed |
| Stable Comparison IDs Generated | Yes, No or Partial |
| Exclusions Recorded | Count and status |
| Accepted Exceptions Recorded | Count and status |
| Carry-Forward Exceptions | Count approved for Post-Migration use |
| Baseline Integrity Check | Pass, Warning or Failed using approved terminology |
| Baseline Compatibility Status | Compatible, Review Required or Incompatible |
| Post-Migration Use Status | Ready for Use, Review Required or Not Ready |

The baseline shall retain configuration, schema, mapping, engine and template versions and integrity evidence sufficient for compatibility verification by Post-Migration Verification.

## 4. Sheet 02 — Readiness Decision

The current detailed readiness-decision sheet shall be retained. It shall continue to store exactly one decision row per execution, including:

- Decision ID
- Readiness Result
- Decision Rationale
- Blocker Count
- Warning Count
- Accepted Exception Count
- Exclusion Count
- Required Action
- Responsible Party
- Target Date
- Evaluation Status
- RAG
- Confidence
- Review Required
- Status
- Comments

The Executive Summary shall surface the decision but shall not replace this attributable decision row.

## 5. Sheet 03 — Inputs, Access and Transfer

The existing detailed input, access, backup, staging, storage and transfer check model shall be retained. It shall continue to capture expected and observed values, evidence, evaluation status, RAG, severity, blocker status, required action, owner, target date and review status.

The sheet shall support checks for:

- source-root accessibility;
- archive and index accessibility;
- database and backup evidence;
- staging capacity;
- storage headroom;
- transfer-path availability;
- rollback and recovery evidence;
- permission and long-path constraints;
- source inventory reconciliation;
- migration-package completeness.

## 6. Sheet 04 — Dossier Baseline

### 6.1 Existing content retained

The dossier baseline shall retain:

- Baseline Dossier ID
- Stable Comparison ID
- Product
- Dossier Display Name
- Dossier Path
- normalized classification dimensions;
- Classification Confidence
- Evaluation Status
- Value Source
- Expected Sequence Count
- Expected File Count
- Expected Folder Count
- Expected Size Bytes
- Display Size GB
- RAG
- Review Required
- Included in Migration Scope
- Exclusion ID
- Exception ID
- Finding Count
- Baseline Comments

### 6.2 Required additions

The following columns shall be added:

| Column | Purpose |
|---|---|
| PrimaryRAGReason | Concise explanation of the dossier RAG |
| FindingCodes | Delimited references to applicable findings |
| MigrationMethod | Confirmed method for the dossier |
| MigrationWave | Approved migration wave |
| ReadinessAction | Required dossier-level preparation |
| BaselineApprovalStatus | Draft, Ready for Review, Reviewed, Approved for Migration Use or Superseded |
| CarryForwardExceptionIds | Accepted exceptions approved for Post-Migration use |

Controlled migration-method values shall align with the finalized Pre-Sales model, including:

- Database and Archive Migration
- Batch Dossier Import
- Individual Sequence Import
- Conversion and Import
- Migration and eCTDmanager Sequential Upgrade
- Migration and eSUBmanager Sequential Upgrade
- Manual Technical Review
- Excluded from Scope
- Migration Method Not Determined

## 7. Sheet 05 — Sequence Baseline

### 7.1 Existing content retained

The sequence baseline shall retain:

- Baseline Sequence ID
- Stable Comparison ID
- Baseline Dossier ID
- Sequence Display Name
- Sequence Path
- Expected File Count
- Expected Folder Count
- Expected Size Bytes
- Display Size MB
- Backbone XML Status
- Checksum Status
- Regional XML Status
- Referenced File Status
- Zero-Byte File Count
- Long-Path Count
- Missing Mandatory Items
- Evaluation Status
- Value Source
- RAG
- Confidence
- Review Required
- Included in Migration Scope
- Exclusion ID
- Exception ID
- Finding Count
- Comments

### 7.2 Required additions

The following columns shall be added:

| Column | Purpose |
|---|---|
| Product | Product name for filtering and reconciliation |
| DossierDisplayName | Human-readable dossier name |
| Region | Normalized region |
| Authority | Normalized authority where available |
| TechnicalStandard | eCTD, NeeS, VNeeS or other controlled standard |
| RegionalImplementation | EU, FDA, UK, Canada or other controlled implementation |
| PrimaryRAGReason | Concise explanation of sequence RAG |
| FindingCodes | Delimited finding references |
| MigrationMethod | Batch, individual, conversion or other approved method |
| MigrationWave | Approved migration wave |
| ReadinessAction | Required sequence-level preparation |
| BaselineApprovalStatus | Approval status of the baseline row |
| CarryForwardExceptionIds | Accepted exceptions approved for Post-Migration use |

## 8. Sheet 06 — File Type Breakdown

### 8.1 Purpose

A normalized file-type breakdown sheet shall be added to provide dossier- and sequence-level file composition without creating one column per extension.

The sheet shall support:

- file-type counts and sizes for each dossier and sequence;
- identification of unsupported, encrypted, unreadable or zero-byte files;
- file-type-specific RAG and reason;
- later comparison or investigation during Post-Migration Verification where the evidence is available.

### 8.2 Columns

| Column | Requirement |
|---|---|
| RecordId | Stable row identifier |
| DossierId | Dossier reference |
| DossierName | Human-readable dossier name |
| SequenceId | Sequence reference; blank only for a dossier aggregate row |
| FileExtension | Normalized extension including controlled handling for no extension |
| FileCategory | Controlled category |
| FileCount | Number of files |
| TotalSizeBytes | Total size in bytes |
| DisplaySizeMB | Human-readable size |
| LargestFileSizeMB | Largest file in the group |
| ZeroByteCount | Count of zero-byte files |
| UnreadableFileCount | Count of unreadable files |
| UnsupportedFileCount | Count unsupported by the configured migration method |
| EncryptedFileCount | Count of detected encrypted files where technically assessable |
| EvaluationStatus | Controlled evaluation status |
| RAG | Green, Amber, Red or Unknown |
| PrimaryRAGReason | Concise reason |
| FindingCodes | Applicable findings |
| RuleIds | Applied rule references |
| ReviewRequired | Yes or No |
| RecommendedAction | Required action |
| Comments | Review notes |

Controlled file categories shall include:

- PDF
- XML
- Office Document
- Image
- Archive
- Text
- Media
- Executable
- Unknown
- Other

The detailed extension and the broader file category shall both be retained.

## 9. Sheet 07 — File, XML and Path Checks

The current technical-check sheet shall be retained and renumbered. It shall continue to hold detailed technical evidence for:

- mandatory files;
- XML presence and readability;
- backbone and regional XML;
- checksums;
- referenced files;
- zero-byte files;
- long paths;
- inaccessible paths;
- duplicate or nested folder conditions;
- unsupported or unexpected technical content;
- other configuration-driven file, XML and path checks.

It shall preserve entity type, entity ID, expected value, observed value, evidence reference, EvaluationStatus, RAG, confidence, severity, blocker, rule, finding, recommendation and review status.

## 10. Sheet 08 — Findings and Actions

The current findings and preparation-action model shall be retained. Findings and recommendations shall remain separate but linked.

Every result-driving finding shall preserve:

- original evidence;
- EvaluationStatus;
- original RAG;
- severity;
- blocker status;
- confidence;
- ValueSource;
- rule references;
- linked recommendation codes;
- responsible owner;
- target date;
- action status;
- review fields.

## 11. Sheet 09 — Exceptions and Exclusions

The current accepted-exception and exclusion model shall be retained.

An accepted exception shall preserve:

- original finding and evidence;
- original EvaluationStatus and RAG;
- exception identifier;
- approved exception effect;
- approver role or reference;
- supporting evidence reference;
- validity or expiry where required;
- carry-forward decision for Post-Migration.

An exception shall never delete, replace or overwrite the original finding. Default carry-forward remains False unless explicitly approved.

Exclusions shall identify the excluded entity, scope effect, reason, owner, approval/evidence and whether it must be evaluated during Post-Migration reconciliation.

## 12. Sheet 10 — Assumptions and Limits

The current assumptions and limitations sheet shall be retained and shall include:

- assumption or limitation ID;
- category;
- description;
- affected scope or entity;
- effect on readiness;
- effect on baseline completeness;
- evidence source;
- owner;
- required resolution;
- target date;
- status;
- review note.

Missing evidence shall not be reported as Green or Pass.

## 13. Sheet 11 — Execution Details

The current execution and configuration traceability sheet shall be retained and renumbered.

It shall include:

- Execution ID;
- start and end timestamps;
- executing identity and machine;
- operating system;
- exact PowerShell, .NET and runtime-adapter versions;
- script and engine version;
- schema, mapping, source workbook, JSON and template versions;
- runtime JSON path, size and SHA-256 checksum;
- parameters and source roots;
- output paths;
- processing durations;
- warning and error counts;
- baseline ID and integrity evidence;
- final execution state.

## 14. Configuration and result-object requirements

The configuration and normalized result objects shall be extended only as required to support the finalized report. Business interpretation and presentation shall remain configuration-driven.

Required or extended collections include:

```text
summaryMetrics
readinessDecision
inputChecks
dossierBaseline
sequenceBaseline
fileTypeBreakdown
fileXmlPathChecks
findings
actions
acceptedExceptions
exclusions
assumptions
limitations
baselineIntegrity
executionDetails
```

Required new or extended fields include:

```text
primaryRagReason
findingCodes
migrationMethod
migrationWave
readinessAction
baselineApprovalStatus
carryForwardExceptionIds
confirmedMigrationScenario
scenarioChangedSincePreSales
confirmedMigrationWorkstreams
upgradePathConfirmed
upgradeHopCount
migrationWaveSummary
rollbackRecoveryEvidenceAvailable
backupEvidenceAvailable
baselineCompatibilityStatus
postMigrationUseStatus
```

The report-template mapping JSON shall bind normalized result fields to the controlled template only. It shall not contain business rules, readiness logic, RAG logic, exception-policy logic or migration-wave interpretation.

## 15. Configuration-driven presentation

The runtime configuration shall control, as applicable:

- readiness decision policies and rationale templates;
- summary metric labels and order;
- display/visibility of summary metrics;
- scenario names and workstream text;
- migration-method eligibility;
- migration-wave rules and labels;
- RAG aggregation and Primary RAG Reason templates;
- critical-action display rules and limits;
- baseline-integrity and compatibility terminology;
- file categories and file-type handling;
- finding-to-recommendation relationships;
- accepted-exception effects and carry-forward policy.

PowerShell shall perform generic technical discovery, calculation, comparison and report population. It shall not hardcode business or regulatory interpretation that belongs in controlled configuration.

## 16. Phase boundaries

The Pre-Migration report may determine only:

- `Ready`;
- `Ready with Accepted Exceptions`;
- `Blocked`.

It shall not:

- claim that migration was executed;
- claim migration success;
- claim formal validation or customer acceptance;
- silently convert missing evidence to Green;
- erase findings through accepted exceptions;
- modify source data or source workbooks;
- treat the prior Pre-Sales report as the authoritative baseline.

The approved Pre-Migration baseline is the authoritative expected population for Post-Migration Verification.

## 17. Acceptance criteria

The Pre-Migration report requirement is satisfied when:

1. the workbook contains the eleven sheets in the approved order;
2. the Executive Summary presents the readiness result, rationale, scope, RAG populations, confirmed migration approach, critical actions and baseline handover status;
3. the existing detailed decision, input, technical check, finding, exception, assumption and execution models are retained;
4. dossier and sequence baselines contain stable comparison IDs, counts, size measures, RAG, Primary RAG Reason, migration method, migration wave and baseline approval status;
5. file-type counts and sizes are available through the normalized File Type Breakdown sheet;
6. accepted exceptions preserve original findings, original RAG and evidence;
7. exclusions and carry-forward decisions are explicit;
8. baseline integrity and Post-Migration compatibility evidence are generated;
9. report wording uses only approved Pre-Migration terminology;
10. all business interpretation and executive presentation are controlled through configuration rather than hardcoded PowerShell;
11. one controlled XLSX report and one timestamped UTF-8 execution log are produced;
12. the report remains read-only and does not claim formal validation, migration execution or customer acceptance.

## 18. Implementation sequence

After all three phase-report requirements are finalized and the consolidated Enterprise Requirements v3.2 baseline is approved:

1. update the Pre-Migration phase contract;
2. extend the normalized result-object contract;
3. update runtime configuration/schema content where business interpretation is required;
4. update `pre-migration.template-map.json`;
5. create the controlled Pre-Migration Excel template;
6. update demo inputs and expected results;
7. update report generation and compatibility readers;
8. add unit, integration, scenario, template and regression tests;
9. generate controlled validation evidence.
