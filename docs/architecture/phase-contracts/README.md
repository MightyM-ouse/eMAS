# eMAS Phase Contracts

These contracts define the externally observable and orchestration-level behavior of the three eMAS phases.

| Phase | Code | Contract |
|---|---|---|
| Pre-Sales Assessment | `PRE_SALES` | [01 — Pre-Sales Assessment Phase Contract](01_eMAS_PreSales_Assessment_Phase_Contract.md) |
| Pre-Migration Readiness | `PRE_MIGRATION` | [02 — Pre-Migration Readiness Phase Contract](02_eMAS_PreMigration_Readiness_Phase_Contract.md) |
| Post-Migration Verification | `POST_MIGRATION` | [03 — Post-Migration Verification Phase Contract](03_eMAS_PostMigration_Verification_Phase_Contract.md) |

## Contract hierarchy

1. Enterprise Requirements v3.1 controls product scope and outcomes.
2. The Effective Solution Architecture controls component boundaries and common run behavior.
3. Runtime JSON Contract v1.2, the frozen logical model and Schema 1.0.0 control shared interpretation and serialization.
4. Each phase contract controls phase-specific inputs, checks, exclusions, outputs and result language.
5. Report design specifications and templates control physical workbook layout.
6. Entry scripts and engine modules implement these contracts.

A phase contract does not authorize new regulatory mappings, weights, thresholds or exception roles. Such content remains subject to the approved owner/SME workflow.
