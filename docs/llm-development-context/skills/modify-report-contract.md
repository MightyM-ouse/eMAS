---
SkillId: SKILL-005
Title: Modify an eMAS Report Contract or Controlled Template
Version: 1.0.0
Status: Effective
Owner: Product Owner and Reporting Lead
DecisionReferences:
  - SK-007
  - FN-020
  - FN-021
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/governance/eMAS_Terminology.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/architecture/eMAS_Solution_Architecture.md
  - docs/architecture/phase-contracts/README.md
  - docs/configuration/04_eMAS_Runtime_JSON_Contract.md
  - docs/configuration/07_eMAS_Data_Dictionary.md
AppliesTo:
  - Controlled XLSX report contracts
  - Phase-specific templates
  - Baseline and MigrationSummary interfaces
Supersedes: null
LastReviewed: 2026-07-13
---

# Modify an eMAS Report Contract or Controlled Template

## Invoke when

- Adding, removing, renaming or changing the meaning of a report sheet, table, column, status, result, metadata field or customer-facing section.
- Changing Pre-Migration baseline content or the Post-Migration reader/interface that consumes it.
- Changing generated filename rules, raw-inventory visibility, clarification registers or accepted-exception presentation.

## Do not invoke when

- Only low-level OpenXML implementation changes without observable report-contract change; use `implement-powershell-module.md`.
- Business/regulatory rule content changes while the report structure remains unchanged; use the configuration or regulatory skill.
- A one-time customer report needs manual formatting; do not change the controlled product template for project-specific preference.

## Required inputs and canonical sources

- Approved requirement/DecisionId and affected phase contract.
- Current controlled template, manifest, report design specification and sample/golden output if available.
- Data Dictionary, Runtime JSON Contract and engine output model.
- Current naming, metadata, baseline and reconciliation compatibility requirements.
- Expected audience, intended use and disclosure restrictions.
- Acceptance criteria for OpenXML generation without Excel.

## Preconditions

- The requested report meaning is approved.
- Required data exists in the runtime configuration or engine output model.
- Phase result terminology is controlled and unchanged unless explicitly approved.
- Baseline/reader compatibility impact is identified.
- No real customer data is present in the controlled template or test fixture.

## Procedure

1. **Resolve authority and phase.** Record requirement/DecisionIds and select the applicable phase contract.
2. **Classify the change.** Distinguish presentation-only changes from semantic, baseline, interface or disclosure changes.
3. **Map data lineage.** For each changed field, identify source collection/field, ValueSource, calculation owner, evaluation/RAG/confidence behavior and evidence reference.
4. **Preserve semantic separation.** Keep `EvaluationStatus`, `RAG`, `ValueSource`, `Confidence` and `ReviewRequired` as separate columns/concepts.
5. **Apply phase boundaries.** Pre-Sales must not use readiness wording; Pre-Migration must expose baseline/exception traceability; Post-Migration must expose expected/migrated/discrepancy evidence.
6. **Design the contract.** Define sheet/table/column names, order, types, mandatory/optional status, controlled values, freeze/filter/format behavior and maximum practical data volume.
7. **Protect intended use.** Include assumptions, limitations, review requirements and non-validation/non-acceptance wording.
8. **Control disclosure.** Keep raw internal scoring hidden by default; make raw inventory optional where permitted; separate consultant and customer text where required.
9. **Control naming.** Exclude internal Confluence identifiers and version strings from generated customer-facing filenames unless a controlled naming requirement explicitly overrides this.
10. **Assess baseline compatibility.** For any Pre-Migration baseline change, define versioning, integrity metadata and synchronized Post-Migration reader/test changes.
11. **Assess MigrationSummary compatibility.** Define supported sheet/column mappings, required fields and unsupported-version behavior without modifying the source workbook.
12. **Update template and manifest.** Remove sample/customer data, preserve branding controls and record template version/checksum.
13. **Implement or route code.** Invoke `implement-powershell-module.md` for OpenXML/reporting changes.
14. **Test generated output.** Validate opening, sheet/table names, data types, row counts, formatting, formulas where permitted, large-volume behavior and no Excel dependency.
15. **Synchronize documentation.** Update report specification, phase contract/architecture if meaning changed, user guidance, indexes and changelog.

## Required outputs

- Updated report contract and controlled blank template/manifest.
- Before/after sheet/column and data-lineage matrix.
- Phase terminology and disclosure assessment.
- Baseline/MigrationSummary compatibility decision where applicable.
- OpenXML implementation requirements and tests.
- Generated synthetic sample and validation evidence.
- Template version/checksum and change traceability.

## Stop conditions

Stop when:

- report meaning or phase result changes without approved requirement;
- a requested field has no controlled source or calculation owner;
- baseline compatibility with Post-Migration is uncertain;
- MigrationSummary structure is unsupported or ambiguous;
- the template contains customer/project data;
- the change requires Excel installation or an unapproved runtime module;
- missing evidence would be displayed as Green/Pass;
- raw internal scoring or sensitive data would be disclosed without approval;
- acceptance criteria for generated XLSX are missing.

## Validation and evidence

- Generate the workbook through the intended OpenXML path on a host without Excel dependency.
- Verify every required sheet/table/column and controlled value.
- Verify metadata includes run/configuration/schema/template versions and JSON checksum.
- Verify original findings/discrepancies remain after exception treatment.
- Verify Pre-Sales lacks readiness language and includes clarification/limitation sections.
- Verify Pre-Migration baseline and Post-Migration reader remain compatible.
- Verify generated files contain no sample/customer data or internal identifiers.
- Record commands, file hashes, row/column checks and visual review evidence.

## Definition of Done

- The report contract is approved and phase compliant.
- Data lineage exists for every changed field.
- Controlled template and manifest are updated and free of customer data.
- OpenXML generation works without Excel or unapproved modules.
- Baseline/MigrationSummary compatibility is implemented and tested where affected.
- Synthetic generated output passes structural and visual review.
- Documentation, versioning and traceability are synchronized.
- No unresolved stop condition remains.
