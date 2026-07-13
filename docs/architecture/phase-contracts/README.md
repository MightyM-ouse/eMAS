# eMAS Phase Contracts

These contracts define the externally observable and orchestration-level behavior of the three eMAS phases.

| Phase | Code | Contract | Runtime |
|---|---|---|---|
| Pre-Sales Assessment | `PRE_SALES` | [01 — Pre-Sales Assessment Phase Contract](01_eMAS_PreSales_Assessment_Phase_Contract.md) | Windows PowerShell 5.1 on Windows |
| Pre-Migration Readiness | `PRE_MIGRATION` | [02 — Pre-Migration Readiness Phase Contract](02_eMAS_PreMigration_Readiness_Phase_Contract.md) | PowerShell 7.6 LTS on Windows |
| Post-Migration Verification | `POST_MIGRATION` | [03 — Post-Migration Verification Phase Contract](03_eMAS_PostMigration_Verification_Phase_Contract.md) | PowerShell 7.6 LTS on Windows |

PowerShell 7.6 LTS on macOS is approved for development and non-Windows unit/fixture testing. Windows remains the authoritative phase-qualification environment.

## Contract hierarchy

1. Enterprise Requirements v3.1 controls product scope and outcomes, subject to approved amendments.
2. The Effective Solution Architecture controls component boundaries and common run behavior.
3. [PowerShell Runtime Profile v1.0](../eMAS_PowerShell_Runtime_Profile.md) controls development/runtime/qualification allocation.
4. Runtime JSON Contract v1.2, the frozen logical model and Schema 1.0.0 plus approved amendments control shared interpretation and serialization.
5. Each phase contract controls phase-specific inputs, checks, exclusions, outputs and result language.
6. Report design specifications and templates control physical workbook layout.
7. Entry scripts, common engine modules and runtime-specific adapters implement these contracts.

A phase contract does not authorize new regulatory mappings, weights, thresholds or exception roles. Such content remains subject to the approved owner/SME workflow.
