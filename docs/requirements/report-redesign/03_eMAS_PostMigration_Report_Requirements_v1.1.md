# eMAS Post-Migration Report Requirements

**Document version:** 1.1  
**Status:** Approved Working Requirement  
**Phase code:** `POST_MIGRATION`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Supersedes:** `03_eMAS_PostMigration_Report_Requirements_v1.0.md` on this branch  
**Implementation state:** Template, template map and normalized result schema aligned to v3.2; PowerShell readers/reconciliation/report generation and qualification pending

## 1. Purpose

Post-Migration Verification compares the approved Pre-Migration baseline with independent observed evidence and determines whether the migration is technically reconciled.

The evidence flow is:

`Pre-Migration Baseline -> Import Report -> Target Database -> Post-Import Verification`

The report shall answer:

- whether the approved baseline is compatible and complete;
- whether expected dossiers and sequences appear in import, database and post-import evidence;
- whether agreed file/count/size measures reconcile;
- which differences are matched, accepted, unresolved, unexpected or awaiting review;
- whether import failures/warnings/skips require action;
- whether the target database contains the expected dossier population;
- which actions remain before technical closeout.

The phase does not execute migration, constitute regulatory validation, provide formal customer validation, electronically approve the migration or record customer acceptance.

## 2. Final workbook composition

The controlled workbook contains exactly fifteen sheets in this order:

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

A separate timestamped UTF-8 execution log is mandatory and is not an Excel worksheet.

The template version aligned to this requirement is `1.2.0`. The technical report-template map version is `2.0.0`.

## 3. Evidence-source rules

### 3.1 Pre-Migration baseline

The approved compatible baseline is the authoritative expected state. The phase verifies baseline ID, approval status, schema/mapping/template identity, scope, exclusions, exceptions and integrity evidence before comparison.

### 3.2 Import report

The import report provides migration execution evidence. Raw rows and literal source headers are preserved. Normalized meaning is assigned through controlled reader/status mappings.

### 3.3 Target database extract

The database extract is independent observed evidence. Presence in an import report does not by itself prove that the expected dossier exists correctly in the target database.

Initial implementation accepts a controlled read-only CSV/XLSX database extract. Direct production database connectivity is not required by the report contract and requires a separately approved adapter.

### 3.4 Post-import verification

Post-import file/repository evidence provides observed dossier/sequence/file/count/size measures where available and reliable.

Evidence sources must not be silently substituted for one another. Missing mandatory evidence produces `Verification Incomplete` rather than a conclusive reconciliation result.

## 4. Result terminology

Permitted final results are:

- `Reconciled`
- `Reconciled with Accepted Exceptions`
- `Not Reconciled`
- `Verification Incomplete`

`Verification Incomplete` is used where mandatory evidence is unavailable, incompatible or cannot be interpreted reliably. It is not a reconciliation decision.

ReconciliationStatus remains separate and supports:

- Matched
- Matched Within Tolerance
- Accepted Difference
- Review Required
- Mismatched
- Missing After Migration
- Unexpected After Migration
- Not Compared
- Evidence Missing

RAG meanings:

- Green: expected and observed evidence matches or is within approved tolerance;
- Amber: accepted difference, recoverable difference or reviewer disposition required;
- Red: unresolved mismatch, failed import, missing expected item or closure blocker;
- Unknown: evidence is unavailable or cannot be reliably compared.

## 5. Sheet 01 — `01_Executive_Summary`

The Executive Summary provides the final technical-reconciliation view.

### 5.1 Verification context

At minimum:

- CustomerName / ProjectName / MigrationReference / VerificationReference
- VerificationDate / VerificationStatus
- source and target applications/versions/hotfixes
- MigrationScenario / MigrationCompletionDate
- PreMigrationBaselineId / BaselineStatus / BaselineCompatibilityStatus
- ImportReportReference
- PostImportEvidenceReference
- DatabaseExtractReference
- ConfigurationVersion / TemplateVersion

### 5.2 Final reconciliation result

The most prominent section contains:

- VerificationResult
- VerificationConfidence
- DecisionRationale
- unresolved/accepted/review-pending discrepancy counts
- missing and unexpected dossier/sequence counts
- failed/warning/skipped import counts
- RequiredNextAction / ResponsibleParty / TargetDate

### 5.3 Dossier and sequence summaries

For each population, show baseline, import, database and post-import counts; fully matched, accepted-difference, review-pending, mismatched, missing and unexpected counts; RAG populations; open actions and reviewer-note populations.

### 5.4 File and volume summary

Show baseline and post-migration file/folder/size measures, differences, file-type matches/accepted/unresolved populations, missing/unexpected content, zero-byte and checksum coverage comparisons and largest unresolved difference.

### 5.5 Import and database summaries

Show import status populations, unclassified/review-required rows, duration/evidence completeness and raw-evidence preservation. Show expected/found/missing/unexpected database dossier populations, metadata/sequence-count matches, review population and database evidence confidence.

### 5.6 Critical discrepancies and handover

Display all unresolved Red discrepancies and prioritized Amber items with IDs, entity, difference, reason, exception, action, owner, target date, review status and reviewer note. Show technical reconciliation status, reviewer, open actions, customer-review requirement, closeout-evidence readiness and final note.

## 6. Sheet 02 — `02_Verification_Scope`

One row per evidence/scope item, including:

- ScopeItemId / ScopeArea
- EvidenceType / EvidenceVersion / generated timestamp/checksum
- BaselineSource / ImportEvidenceSource / DatabaseEvidenceSource / PostImportEvidenceSource
- ComparisonKey
- MandatoryEvidence / EvidenceAvailable / CompatibilityStatus
- Included / ExclusionId / ExceptionId
- EvidenceLimitation
- ValueSource / EvaluationStatus / RAG / Confidence / ReviewRequired / Comments

## 7. Sheet 03 — `03_Overall_Reconciliation`

One row per overall reconciliation metric:

- ReconciliationMetricId / Area / MetricCode / MetricName / EntityScope
- BaselineValue
- ImportReportValue
- DatabaseValue
- PostImportValue
- AbsoluteDifference / PercentageDifference / Unit / Tolerance
- ComparisonResult / ReconciliationStatus
- EvaluationStatus / RAG / PrimaryRAGReason
- AcceptedException / ExceptionId
- ReviewRequired / DiscrepancyId
- SystemComparisonNote
- ReviewerNote / ReviewerDisposition

The report writer must not recalculate business interpretation independently from the normalized result.

## 8. Sheet 04 — `04_Dossier_Before_&_After`

One row per dossier comparison. It includes:

### Identification/classification

- DossierComparisonId / StableComparisonId
- BaselineDossierId / TargetDatabaseDossierId
- Product
- baseline/import/database/post-import dossier names
- Region / Authority / TechnicalStandard / RegionalImplementation / PrimaryDossierType
- MigrationMethod / MigrationWave

### Evidence presence and measures

- BaselinePresent / ImportReportPresent / DatabasePresent / PostImportEvidencePresent
- baseline/import/database/post-import sequence counts and differences
- baseline/post-import file/folder/size measures and differences
- ImportStatusSummary

### Assessment and review

- PreMigrationRAG / PostMigrationRAG / PrimaryRAGReason
- ReconciliationStatus
- DiscrepancyIds
- AcceptedException / ExceptionIds
- ReviewRequired
- SystemComparisonNote
- ReviewerNote / ReviewerDisposition
- Owner / TargetDate / ReviewStatus / RecommendedAction

## 9. Sheet 05 — `05_Sequence_Before_&_After`

One row per sequence comparison, including stable identifiers, dossier linkage, region/standard/implementation, method/wave, evidence-presence flags, baseline/post file/folder/size measures, backbone/checksum/reference comparisons, import status/code, pre/post RAG, reason, reconciliation status, discrepancies/exceptions, review/disposition/action fields.

## 10. Sheet 06 — `06_File_Type_&_Size_Comparison`

This sheet corresponds to the Pre-Migration file-type baseline. Required columns include:

- ComparisonId
- dossier and sequence IDs/names
- FileExtension / FileCategory
- baseline/post file counts and differences
- baseline/post total size and difference
- baseline/post largest-file measures
- baseline/post zero-byte, unsupported and encrypted counts
- Tolerance / ReconciliationStatus
- EvaluationStatus / RAG / PrimaryRAGReason
- AcceptedException / ExceptionId / DiscrepancyId
- ReviewRequired
- SystemComparisonNote / ReviewerNote / ReviewerDisposition
- RecommendedAction / Comments

File-type totals must reconcile to approved baseline and post-import populations within configured rules.

## 11. Sheet 07 — `07_Database_Dossier_Inventory`

One interpreted row per target database dossier record, including:

- DatabaseRecordId / TargetDossierId / StableComparisonId
- DossierName / Product / Region / Authority or Procedure
- TechnicalStandard / RegionalImplementation / LifecycleStatus
- SequenceCount / FirstSequence / LastSequence
- CreationDate / ImportDate / LastModifiedDate
- ActiveDeletedStatus / ArchiveRepositoryReference
- SourceQueryExtractReference / ValueSource
- EvaluationStatus / Confidence / BaselineMatchStatus
- RAG / PrimaryRAGReason / ReviewRequired / ReviewerNote / Comments

Field availability is mapping-driven by supported target application/version. Unavailable fields are explicit and are not fabricated.

## 12. Sheet 08 — `08_Import_Evidence_Review`

One normalized row per relevant import-report row, preserving source-row reference and raw status/message while adding normalized category/result, EvaluationStatus, RAG and reason, rule/finding/discrepancy references, review/action fields, reviewer note/disposition and comments.

Import warning meaning is configuration-driven; a warning does not automatically become a reconciliation failure.

## 13. Sheet 09 — `09_Discrepancies_&_Actions`

Central discrepancy/action register with:

- DiscrepancyId and entity linkage
- comparison area
- expected/import/database/observed values and difference
- classification/severity
- EvaluationStatus / RAG / PrimaryRAGReason / Blocker
- AcceptedException / ExceptionId
- RequiredAction / Owner / TargetDate
- SystemNote / ReviewerNote / ReviewerDisposition / ReviewStatus
- ClosureEvidenceReference / ClosedBy / ClosedDate

Controlled reviewer dispositions include Confirmed Match, Accepted Difference, Remediation Required, Further Investigation Required, Not Applicable, Duplicate Discrepancy, Deferred with Approval, Rejected and Closed.

## 14. Sheet 10 — `10_Accepted_Exceptions`

Each carried-forward exception retains original Pre-Migration finding/RAG/evidence, policy/effect, approval reference/date, supporting evidence, validity/expiry, carry-forward status, observed difference, coverage status, EvaluationStatus, current RAG, reviewer disposition and comments.

An accepted exception never removes the underlying discrepancy.

## 15. Sheet 11 — `11_Assumptions_&_Limits`

Records baseline/evidence/database/import/post-import limitations, unavailable fields, mapping ambiguity, differing measurement methods, timestamp changes, exclusions and incomplete populations with stable IDs, impact, provenance, confidence, review/owner/status and comments.

## 16. Sheet 12 — `12_Review_&_Execution`

Contains:

- technical reviewer/role/date;
- final disposition and closeout recommendation;
- open-action/exception counts and final reviewer note;
- execution ID/start/end/result;
- engine/runtime/.NET/adapter versions;
- configuration/schema/mapping/template identities;
- baseline/import/post-import/database-extract checksums;
- output paths and environment information.

The release-managed template-control table is read-only at execution time.

## 17. Raw evidence sheets

### `Import Report Detail`

Raw MigrationSummary/import details are copied verbatim. Existing rows are never edited, reordered or deleted. Headers, including literal `Source.Name`, are preserved exactly.

### `Post Import Verification`

Raw post-import verification evidence is copied verbatim. The approved literal header `DossierDirecotry` is preserved exactly.

### `Database Dossier Extract`

The approved database extract is copied verbatim. Raw headers and rows are append-only and are not corrected, normalized or interpreted in place.

All normalization belongs in interpreted sheets.

## 18. Normalized result contract

The result contains, at minimum:

- execution/context/baseline identity;
- verificationDecision;
- verificationScope;
- overallReconciliation;
- dossierComparisons;
- sequenceComparisons;
- fileTypeSizeComparisons;
- databaseDossierInventory;
- importEvidenceReview;
- discrepanciesAndActions;
- acceptedExceptions;
- assumptionsLimits;
- reviewExecution;
- rawImportReportDetail;
- rawPostImportVerification;
- rawDatabaseDossierExtract;
- configuration/template identity.

The result schema aligned to this requirement is `config/result-schemas/report-redesign-v3.2/post-migration.result.schema.json`.

## 19. Acceptance criteria

The report conforms when:

1. the exact fifteen-sheet order is present;
2. only the four approved final outcomes are used;
3. baseline compatibility is verified before comparison;
4. mandatory missing evidence produces Verification Incomplete;
5. every comparison preserves expected and observed evidence/provenance;
6. import, database and post-import evidence remain independent;
7. dossier/sequence/file-type totals reconcile or create traceable discrepancies;
8. accepted exceptions preserve original discrepancies/evidence;
9. reviewer notes/dispositions remain separate from system comparison notes;
10. all three raw evidence sheets are append-only and preserve literal headers;
11. no customer acceptance or formal validation claim is made;
12. source evidence remains read-only;
13. a separate timestamped UTF-8 log is produced;
14. the workbook opens without structural repair;
15. normalized results validate against the aligned result schema.
