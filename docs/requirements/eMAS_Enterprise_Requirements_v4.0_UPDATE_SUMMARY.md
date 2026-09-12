# eMAS Enterprise Requirements v4.0 — Repository Update Summary

**Source date:** 06 September 2026  
**Purpose:** Make the material Enterprise Requirements v4.0 changes visible in the repository without representing this companion summary as the original controlled source file.

## Revised enterprise baseline

eMAS remains a read-only migration assessment framework covering three distinct phases:

1. Pre-Sales Assessment;
2. Pre-Migration Readiness;
3. Post-Migration Verification.

The September architecture changes the internal configuration-authoring and release model while retaining an offline PowerShell assessment runtime.

## Selected architecture

| Area | September v4 direction |
|---|---|
| Internal authoring | Macro-free Excel `.xlsx` workbook |
| Controlled repository | SharePoint |
| Machine contract | Independently versioned JSON Schema |
| Workbook transformation | Office Scripts / TypeScript |
| Release workflow | Power Automate with frozen candidate, attributable approval and immutable publication |
| Runtime rule artifact | One released Runtime JSON plus separate trusted release evidence |
| Runtime consumer | PowerShell; no Mapping Workbook access or conversion |
| Customer/project runtime | Offline; no Excel, SharePoint, Office Scripts, Power Automate, central DB or Microsoft 365 account required |
| User interface | CLI all phases; optional portable WPF for pre/post migration only |
| Reporting | Separate controlled template per phase |
| Integrity | Exact configuration digest and release identity recorded/verified |

## Authoring/runtime boundary

The Mapping Workbook is an internal business/regulatory rule authoring interface. It is not part of the customer runtime package and is never interpreted by runtime PowerShell.

The common released configuration may contain reusable migration scenarios, controlled codes, classification rules, folder/file expectations, RAG/confidence/effort/decision rules, recommendations, sources and questionnaire field definitions. It must not contain actual customer submission answers or replace phase workflow/orchestration.

## Base review gate

The immediate September implementation step is a usable base workbook for laptop and Excel-for-the-web review. The delivery sequence is:

`base workbook → user/SME observations → corrections → controlled generation pilot → approved runtime integration`

A workbook status, SharePoint upload or JSON preview is not itself a controlled release or regulated electronic signature.

## Reporting and evidence

Material report records should preserve evidence state, assessment status/reason, RAG where applicable, RuleIds, configuration identity/digest and provenance. Known adverse findings must remain visible when a scan is partial. Denied access is not evidence that content is absent. Missing information must never become Green/Pass by default.

Common traceability includes:

- execution ID and timestamp;
- script version;
- Runtime JSON version;
- release ID and exact configuration SHA-256;
- template version;
- source evidence;
- RuleIds;
- warnings/limitations;
- reviewer fields where applicable.

## Phase-specific boundaries

### Pre-Sales

Lightweight scope/volume, high-level classification, folder RAG, file type/volume/complexity drivers, confidence and clarification generation. It is not a readiness decision and does not require exhaustive reference/checksum validation.

### Pre-Migration

Deeper source, access, backup/staging/transfer, dossier/sequence, reference/integrity and remediation assessment. Produces a controlled expected baseline for later reconciliation.

### Post-Migration

Uses the approved baseline plus import/post-import evidence to reconcile expected and observed content, discrepancies and accepted exceptions. It must not claim formal customer validation, migration acceptance or regulatory validation.

## Baseline comparability

Post-migration interpretation should use the same pinned released configuration as the approved baseline by default. If the configuration changes, comparability must be explicitly assessed and approved; version-cell editing or a force flag is insufficient evidence.

## GxP-oriented traceability boundary

The framework is designed to support controlled migration evidence, reproducibility, auditability and validation activities. These controls do not automatically establish system validation, compliance, formal acceptance or electronic-signature status.

## Relationship to older repository content

Where this September direction conflicts with the July XLSM/VBA POC architecture, the September design is the current working target for this branch. The existing POC is retained as historical design/technical evidence until a controlled repository cleanup or archival decision is made.
