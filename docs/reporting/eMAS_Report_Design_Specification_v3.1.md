# eMAS Report Design Specification

**Version:** 3.1  
**Status:** Approved

## 1. Template contract

Each phase template has:

- TemplateId;
- TemplateVersion using Semantic Versioning;
- supported engine and schema ranges;
- required worksheets;
- named write targets;
- required tables and columns;
- protected and user-editable areas;
- branding and controlled terminology.

The engine writes only to named tables or named ranges, never to fixed coordinates.

## 2. Common requirements

Every report includes:

- Summary;
- Scope and limitations;
- Findings and recommendations;
- execution details;
- script, schema, mapping, configuration hash and template versions;
- execution ID and timestamps;
- source/evaluation provenance;
- approved positioning statement.

RAG and EvaluationStatus are separate. Original and exception-adjusted values are shown side by side.

## 3. Pre-Sales template

Required logical sections:

- Summary;
- Scope and Volume;
- Complexity and Confidence;
- Classification Estimate;
- Key Drivers;
- Customer Clarifications;
- Assumptions and Limitations;
- Execution Details.

The report must not imply readiness or validation.

## 4. Pre-Migration template

Required logical sections:

- Summary;
- Readiness Decision;
- Required Inputs;
- Access, Backup, Storage and Transfer;
- Dossier and Sequence Readiness;
- Folder, File, XML and Referenced-File Findings;
- Cleanup Actions;
- Accepted Exceptions;
- `Baseline_Data`;
- Assumptions and Limitations;
- Execution Details.

## 5. Post-Migration template

Required logical sections:

- Summary;
- Verification Scope;
- Baseline versus Migrated Counts;
- Dossier Reconciliation;
- Sequence Reconciliation;
- Import Evidence;
- Discrepancies;
- Accepted and Carried-Forward Exceptions;
- Review Support;
- Execution Details;
- raw evidence sheets when configured and permitted.

## 6. Controlled wording

Phase and final-result terminology comes from `docs/governance/eMAS_Terminology.md`.

Customer-facing filenames use stable base names without Confluence IDs:

- `eMAS_PreSalesAssessment.xlsx`
- `eMAS_PreMigrationReadiness.xlsx`
- `eMAS_PostMigrationVerification.xlsx`

Versions remain inside document control and release metadata.

## 7. Validation

Automated checks confirm:

- workbook opens without repair;
- required sheets and named objects exist;
- TemplateId/version are supported;
- fixed source-evidence columns are preserved;
- prohibited overstatement wording is absent;
- formulas contain no broken references.
