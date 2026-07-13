# eMAS Assessment Phases

**Version:** 2.0  
**Status:** Effective implementation guidance  
**Controlled terminology source:** `docs/governance/eMAS_Terminology.md`  
**Authoritative phase contracts:** `docs/architecture/phase-contracts/`

This file is a concise implementation routing summary. The Effective phase contracts prevail for inputs, checks, exclusions, outputs and failure behavior.

## Pre-Sales Assessment

- **Code:** `PRE_SALES`
- **Execution:** CLI or simple launcher; no WPF requirement
- **Purpose:** Lightweight scope, complexity, confidence and clarification assessment before project initiation
- **Inputs:** Minimal accessible evidence roots and customer-provided size/context information
- **Primary outputs:** Complexity band, effort confidence, scope/volume summary, key drivers, assumptions and customer clarification register
- **Report rules:** No readiness terminology; raw score internal by default; raw inventory optional; include intended-use/non-validation statement
- **Do not:** Perform mandatory deep readiness/reconciliation checks or imply validation/acceptance

## Pre-Migration Readiness

- **Code:** `PRE_MIGRATION`
- **Execution:** CLI or optional portable WPF invoking the same script
- **Purpose:** Detailed source readiness assessment and reusable baseline creation
- **Checks:** Dossier/sequence structure, mandatory and referenced evidence, XML/technical integrity, access, storage, backup, staging/transfer and accepted exceptions as applicable
- **Results:** Ready, Ready with Accepted Exceptions or Blocked
- **Baseline:** Stable comparison identifiers, expected measures, scope/exclusions, exception carry-forward, limitations and integrity metadata
- **Exception rule:** Never erase original findings, RAG or evidence

## Post-Migration Verification

- **Code:** `POST_MIGRATION`
- **Execution:** CLI or optional portable WPF invoking the same script
- **Purpose:** Reconcile migrated/import evidence against the approved Pre-Migration baseline
- **Required evidence:** Approved baseline, `MigrationSummary.xlsx` detail, available post-import verification and applicable accepted exceptions
- **Results:** Reconciled, Reconciled with Accepted Exceptions, Review Required or Not Reconciled
- **Evidence rule:** Preserve baseline values, migrated values, discrepancy category, EvaluationStatus, RAG, ValueSource, confidence, ReviewRequired and exception treatment
- **Do not:** Claim formal customer validation or acceptance

## Common rules

- all phases use the same immutable Runtime JSON Schema 1.0.0 configuration;
- phase scripts orchestrate shared engine modules;
- `EvaluationStatus`, `RAG`, `ValueSource`, `Confidence` and `ReviewRequired` remain separate;
- every run creates one controlled XLSX report and one timestamped log;
- source evidence remains read-only;
- business/regulatory meaning is configuration-driven;
- missing optional evidence is not automatically Green;
- legacy wording `Ready with Exceptions`, `Post-Migration Reconciliation` as a phase name and `Reconciled with Exceptions` is prohibited.
