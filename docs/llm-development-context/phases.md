# eMAS Assessment Phases

**Status:** Effective implementation guidance  
**Controlled terminology source:** `docs/governance/eMAS_Terminology.md`

## 1. Pre-Sales Assessment

- **Code:** `PRE_SALES`
- **Execution:** CLI or simple launcher
- **Purpose:** Lightweight migration scope, complexity, confidence and clarification assessment before project initiation
- **Typical inputs:** Minimal customer-provided paths and sizing information
- **Outputs:** Complexity band, estimate confidence, scope summary, effort drivers and customer clarifications
- **Approved result language:** Very Low, Low, Medium, High or Very High complexity; High, Medium, Low or Unknown confidence
- **Rules:** Keep lightweight. Do not perform deep validation, decide readiness or imply migration acceptance.

## 2. Pre-Migration Readiness

- **Code:** `PRE_MIGRATION`
- **Execution:** CLI or optional portable WPF
- **Purpose:** Detailed source-data readiness assessment and reusable baseline creation
- **Key checks:** Dossier and sequence structure, mandatory and referenced files, XML readability, access, backup, storage, transfer readiness, zero-byte files and accepted exceptions
- **Outputs:** Detailed findings, cleanup actions, accepted exceptions, decision support and the baseline consumed by Post-Migration Verification
- **Approved result language:** Ready, Ready with Accepted Exceptions or Blocked
- **Rules:** Produce attributable and auditable evidence. Accepted exceptions may change blocker treatment but never erase original findings.

## 3. Post-Migration Verification

- **Code:** `POST_MIGRATION`
- **Execution:** CLI or optional portable WPF
- **Purpose:** Reconcile migrated evidence against the approved Pre-Migration baseline
- **Inputs:** Approved baseline, import report evidence, post-import verification evidence and accepted exceptions
- **Outputs:** Dossier, sequence and available file/size reconciliation; discrepancies; exception treatment; review actions
- **Approved result language:** Reconciled, Reconciled with Accepted Exceptions, Review Required or Not Reconciled
- **Rules:** Always load and compare against the Phase 2 baseline. Preserve source evidence and do not claim formal customer validation or acceptance.

## Terminology control

`Reconciliation` is the principal technical activity within Post-Migration Verification. It is not a separate product phase.

The following legacy wording is not approved for current use:

- `Ready with Exceptions` — use `Ready with Accepted Exceptions`;
- `Post-Migration Reconciliation` as the phase name — use `Post-Migration Verification`;
- `Reconciled with Exceptions` — use `Reconciled with Accepted Exceptions`.
