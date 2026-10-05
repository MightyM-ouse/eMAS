# EMAS-MS04-WAVE2-PLANNING

**Task ID:** EMAS-MS04-WAVE2-PLANNING

**Base commit:** `58534391684d254abed4251e7f6deacd759e2b78`

**Phase:** Planning and cross-agent reconciliation

**Purpose:** Prepare the next fixture/test baseline before FormatDetection or RegionDetection.

## Shared constraints

- Scope is MS-04, Regulatory Submission Export to eCTDmanager, Pre-Sales technical assessment only.
- The current eight-capability RC1 is qualified on native 64-bit Windows PowerShell 5.1 against 19 frozen Wave 1 fixtures and eight automated suites.
- Frozen Wave 1 fixtures and their expectations must not be modified.
- Accepted production modules and tests must not be modified.
- FormatDetection and RegionDetection must not be implemented.
- Do not expand into migration execution, migration readiness, post-migration verification, DMS-to-DMS, database migration, or archive migration.
- This task is report-only. Allowed files are this task directory and the shared `AGENT_WORKFLOW.md` when explicitly assigned.
- Forbidden files include `engine/`, `scripts/`, `tests/`, configuration, packages, generated results, and fixture content.
- No agent may edit another agent's report. No automatic merge is permitted.

## Accepted baseline

- Contract: `eMAS.MS04.PreSales.ScannerObservations/1.0`
- Capabilities: RepositoryDiscovery, BackboneXmlInventory, ReferenceInventory, ReferenceResolution, MissingReferenceInterpretation, DeclaredChecksumComparison, ChecksumMismatchInterpretation, ClassificationEvidenceCollection
- Scanner version: `0.8.0`
- Windows result: `PASS_WINDOWS_PS51_AUTOMATED_REGRESSION`

## Assignments

### Codex

- **Role:** Repository reconciliation, qualification-recording recommendation, and Wave 2 structure planning
- **Status:** Completed analysis; published by the workflow-setup task
- **Deliverable:** `reports/CODEX.md`
- **Validation:** Report retains repository findings, baseline confirmation, inspected files, proposed structure/files, risks, and scope confirmations.

### Claude/Cursor

- **Role:** Dossier-diversity fixture design
- **Status:** Analysis completed externally; awaiting publication
- **Deliverable:** `reports/CLAUDE.md`
- **Scope:** Publish the already-completed design covering a neutral root, misleading root, arbitrary wrappers, multiple dossiers, a valid dossier with unrelated content, and safe naming variations.
- **Restrictions:** Design only. Do not redo the analysis, implement fixtures, modify production code, or modify frozen Wave 1.

### Hermes

- **Role:** Independent adversarial review
- **Status:** Analysis completed externally; awaiting publication
- **Deliverable:** `reports/HERMES.md`
- **Scope:** Publish the already-completed review of classification blind spots, false-positive/false-negative implementations, cross-dossier leakage, evidence precedence, and minimum format/region coverage needed before future detection logic.
- **Restrictions:** Review only. Do not redo the analysis or implement code.

## Consolidation

- **Deliverable:** `reports/CONSOLIDATED.md`
- **Status:** Not started; blocked until all three reports are available.
- Consolidation must reconcile the persisted reports without silently changing an agent's findings.

## Decision gate

The user reviews all three reports and the consolidation before authorizing any fixture implementation. No report author may authorize implementation or merge on the user's behalf.
