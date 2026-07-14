# eMAS Pre-Migration Report Requirements

**Document version:** 1.1  
**Status:** Approved Working Requirement  
**Phase code:** `PRE_MIGRATION`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Supersedes:** `02_eMAS_PreMigration_Report_Requirements_v1.0.md` on this branch  
**Implementation state:** Template, template map and normalized result schema aligned to v3.2; PowerShell integration, baseline serialization and qualification pending

## 1. Purpose

Pre-Migration Readiness provides detailed technical and operational evidence to decide whether the approved migration scope is ready to proceed and creates the attributable baseline consumed by Post-Migration Verification.

It shall answer:

- what evidence and scope were assessed;
- whether the scope is `Ready`, `Ready with Accepted Exceptions` or `Blocked`;
- which blockers, warnings, actions, exclusions and exceptions apply;
- which dossiers and sequences form the approved baseline;
- which migration method and wave apply to each in-scope entity;
- which file-type/count/size measures must be carried forward for later reconciliation;
- whether baseline integrity and handover requirements are satisfied.

The phase does not execute migration, provide regulatory validation, constitute formal customer validation, electronically approve the migration or record customer acceptance.

## 2. Final workbook composition

The controlled workbook contains exactly eleven sheets in this order:

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

A separate timestamped UTF-8 execution log is mandatory and is not an Excel worksheet.

The template version aligned to this requirement is `1.2.0`. The technical report-template map version is `2.0.0`.

## 3. Semantic separation

EvaluationStatus, RAG, Severity, Blocker, Confidence, ValueSource, ReviewRequired, MigrationMethod, MigrationWave, workload and accepted-exception effects remain separate concepts.

An accepted exception may alter decision treatment only where its configured policy permits. It never erases the original finding, evidence, EvaluationStatus or RAG.

## 4. Sheet 01 — `01_Executive_Summary`

The Executive Summary provides a concise operational view without duplicating detailed evidence rows.

### 4.1 Assessment context

At minimum:

- CustomerName / ProjectName / MigrationReference
- AssessmentDate
- BaselineId / BaselineStatus
- SourceApplication / version / hotfix
- TargetApplication / version / hotfix
- ApprovedMigrationScenario
- ConfigurationVersion / TemplateVersion

### 4.2 Readiness decision

The most prominent section contains:

- ReadinessResult
- DecisionConfidence
- DecisionRationale
- BlockerCount
- WarningCount
- AcceptedExceptionCount
- ExclusionCount
- ReviewPendingCount
- RequiredNextAction
- ResponsibleParty
- TargetDate

Permitted results are only:

- `Ready`
- `Ready with Accepted Exceptions`
- `Blocked`

Unresolved blockers force `Blocked`. Missing mandatory evidence, unresolved conflicts or failed critical checks must not be converted to Ready.

### 4.3 Dossier and sequence readiness summaries

The sheet shows baseline populations and Green/Amber/Red/Unknown counts, accepted-exception/review-pending/open-action populations and migration-method/wave summaries.

### 4.4 Scope and volume

At minimum, where in scope:

- dossier/sequence/file/folder counts;
- export/archive/index/database and unique-transfer volume;
- file-type population counts;
- zero-byte/unreadable/unsupported/encrypted counts;
- long-path and missing-reference counts;
- transfer/staging/backup indicators.

### 4.5 Approved migration approach

The summary presents scenario, ordered workstreams, method populations, waves and dependencies. Migration method and wave are approved baseline data and are not inferred from RAG.

### 4.6 Critical actions and handover

All unresolved blockers and the highest-priority readiness actions are shown with entity, reason, owner, target date, status and exception reference. Baseline integrity, approval/handover status and Post-Migration carry-forward readiness are shown explicitly.

## 5. Sheet 02 — `02_Readiness_Decision`

This sheet records the complete decision trail, including:

- decision ID and result;
- decision confidence and rationale;
- blocker/warning/exception/exclusion/review-pending counts;
- blocker override result;
- required next action, owner and target date;
- EvaluationStatus, RAG, ValueSource and ReviewRequired;
- policy/rule references;
- reviewer and decision status fields.

A technical execution failure is not presented as a completed readiness decision.

## 6. Sheet 03 — `03_Inputs_Access_&_Transfer`

One row per source, input, access, backup, storage, staging or transfer requirement. Columns include stable check ID, scope/type/reference, mandatory/applicable flags, accessibility/availability, observed and required values, units, provenance, EvaluationStatus, RAG and reason, blocker, finding/action references, review requirement, owner, target date and comments.

Only in-scope evidence is required. Missing optional evidence is explicit and does not become Green.

## 7. Sheet 04 — `04_Dossier_Baseline`

One row per baseline dossier. Required groups include:

### Identification and classification

- DossierBaselineId / StableComparisonId
- Product / DossierDisplayName / source path/reference
- Region / Authority / TechnicalStandard / RegionalImplementation
- ProductDomain / LifecycleContext / ProductClass / ProcedureContext / SourcePresentation
- classification evidence, rule IDs and confidence

### Measures

- SequenceCount
- FileCount
- FolderCount
- SizeBytes and display size
- first/last sequence where available

### Readiness and migration planning

- EvaluationStatus
- DossierRAG
- PrimaryRAGReason
- FindingCodes / RuleIds
- Blocker / ReviewRequired
- MigrationWorkstream
- MigrationMethod
- MigrationWave
- ReadinessAction
- BaselineApprovalStatus
- CarryForwardExceptionIds
- ValueSource / Confidence / Comments

Stable identifiers must remain reproducible and attributable. Every in-scope dossier must have an approved method and wave or an explicit `NotApplicable`/exclusion treatment.

## 8. Sheet 05 — `05_Sequence_Baseline`

One row per baseline sequence/submission, linked to its dossier. It includes stable IDs, classification, sequence number/name/path, file/folder/size measures, backbone/checksum/reference indicators, EvaluationStatus, RAG and reason, finding/rule references, migration method/wave, readiness action, baseline approval status, accepted-exception carry-forward and reviewer fields.

Every in-scope sequence must have an approved method/wave or explicit Not Applicable treatment.

## 9. Sheet 06 — `06_File_Type_Breakdown`

This normalized table supports readiness analysis and later Post-Migration comparison.

Required columns:

- RecordId
- DossierId / DossierName
- SequenceId / SequenceName
- FileExtension
- FileCategory
- FileCount
- TotalSizeBytes / DisplaySizeMB
- LargestFileSizeMB
- ZeroByteCount
- UnreadableFileCount
- UnsupportedFileCount
- EncryptedFileCount
- EvaluationStatus
- RAG
- PrimaryRAGReason
- FindingCodes / RuleIds
- ReviewRequired
- RecommendedAction
- Comments

Controlled file categories include PDF, XML, Office Document, Image, Archive, Text, Media, Executable, Unknown and Other.

Counts and volumes shall reconcile with dossier, sequence and overall scope totals within approved rules.

## 10. Sheet 07 — `07_File_XML_Path_Checks`

One row per normalized technical check. It includes entity linkage, check/rule/finding codes, evidence reference, observed/expected value, EvaluationStatus, RAG, severity, blocker, reason, recommendation/action, exception linkage, review/owner/target fields and comments.

Checks may include configured folder/file expectations, XML readability/structure, referenced files, zero-byte content, encryption, unreadable content, unsupported types and long paths.

## 11. Sheet 08 — `08_Findings_&_Actions`

This sheet contains separate finding and action tables.

Findings preserve evidence, original EvaluationStatus/RAG/severity/blocker status, affected entities and rule references. Actions contain recommendation/action code, customer-facing action, owner, target date, status, closure evidence and comments. A finding can link to multiple ordered actions.

## 12. Sheet 09 — `09_Exceptions_&_Exclusions`

Separate accepted-exception and exclusion tables are required.

### Accepted exception

Retains original finding/RAG/evidence, policy and permitted effect, approval role/reference/date, supporting evidence, validity/expiry, carry-forward decision, reviewer status and comments.

### Exclusion

Retains exclusion ID, entity/scope, reason, authority, approved-by/date, baseline effect, Post-Migration treatment and comments.

Exceptions and exclusions are project evidence, not master runtime configuration content.

## 13. Sheet 10 — `10_Assumptions_&_Limits`

Records assumptions, limitations, missing evidence and methodology constraints with stable IDs, scope, statement, impact, ValueSource, confidence, review requirement, owner/status and comments.

## 14. Sheet 11 — `11_Execution_Details`

Includes execution ID, timestamps, engine/runtime/.NET versions, runtime adapter, schema/mapping/configuration/template versions, JSON path/size/SHA-256, input evidence identity and checksums, output paths, processing counts, warnings/errors, result and environment information required for traceability.

The release-managed template-control table is read-only at execution time.

## 15. Baseline contract

The normalized result and evidence package create an immutable attributable baseline containing:

- BaselineId and source ExecutionId;
- approved source scope/root references;
- stable dossier and sequence comparison IDs;
- expected counts and agreed measures;
- normalized file-type/count/size measures;
- migration method and wave;
- exclusions and accepted exceptions/carry-forward;
- assumptions and unresolved limitations;
- configuration/schema/mapping/engine/template identities;
- integrity evidence and baseline approval status.

Post-Migration must reject or explicitly flag an incompatible baseline. Physical baseline storage changes require synchronized reader and compatibility testing.

The result schema aligned to this requirement is `config/result-schemas/report-redesign-v3.2/pre-migration.result.schema.json`.

## 16. Acceptance criteria

The report conforms when:

1. the exact eleven-sheet order is present;
2. only the three approved readiness outcomes are used;
3. blockers force Blocked;
4. accepted exceptions never erase findings/evidence;
5. every RAG has a meaningful evidence-based reason;
6. stable dossier and sequence identifiers are attributable;
7. all in-scope dossiers/sequences have migration method and wave or explicit Not Applicable treatment;
8. file-type totals reconcile with baseline totals;
9. findings/rules/exceptions/exclusions link to entity IDs;
10. source and target versions are recorded when available or explicitly unavailable;
11. baseline integrity and handover status are visible;
12. a separate timestamped UTF-8 log is generated;
13. no confidential commercial rates are exposed;
14. source evidence remains read-only;
15. the workbook opens without structural repair;
16. normalized results validate against the aligned result schema.
