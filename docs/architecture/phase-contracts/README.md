# eMAS Phase Contracts

These contracts define the externally observable and orchestration-level behavior of the three eMAS phases.

| Phase | Code | Contract | Runtime | Report structure |
|---|---|---|---|---:|
| Pre-Sales Assessment | `PRE_SALES` | [01 — Pre-Sales Assessment Phase Contract v1.2](01_eMAS_PreSales_Assessment_Phase_Contract.md) | Windows PowerShell 5.1 on Windows | 4 sheets |
| Pre-Migration Readiness | `PRE_MIGRATION` | [02 — Pre-Migration Readiness Phase Contract v1.2](02_eMAS_PreMigration_Readiness_Phase_Contract.md) | PowerShell 7.6 LTS on Windows | 11 sheets |
| Post-Migration Verification | `POST_MIGRATION` | [03 — Post-Migration Verification Phase Contract v1.2](03_eMAS_PostMigration_Verification_Phase_Contract.md) | PowerShell 7.6 LTS on Windows | 15 sheets |

PowerShell 7.6 LTS on macOS is approved for development and non-Windows unit/fixture testing. Windows remains the authoritative phase-qualification environment.

## Contract hierarchy on the report-redesign branch

1. [Enterprise Requirements v3.2](../../requirements/eMAS_Final_Enterprise_Requirements_v3.2.md) controls the approved working product baseline on `requirements/report-redesign-v3.2`.
2. Enterprise Requirements v3.1 remains effective on `main` until v3.2 promotion.
3. The Effective Solution Architecture controls component boundaries and common run behavior.
4. [PowerShell Runtime Profile v1.0](../eMAS_PowerShell_Runtime_Profile.md) controls development/runtime/qualification allocation.
5. Runtime JSON Contract, frozen logical model and Runtime JSON Schema plus approved amendments control shared interpretation and serialization.
6. Each phase contract controls phase-specific inputs, processing, exclusions, outputs and result language.
7. Report requirements, template version 1.2.0 and report-template maps version 2.0.0 control physical workbook layout and binding.
8. Entry scripts, shared engine modules and runtime-specific adapters implement these contracts.

## Approved v3.2 cross-phase changes

- mode-driven current-system-only customer Pre-Sales collection;
- detailed export versus aggregate direct-copy evidence;
- explicit Pre-Migration file-type baseline, migration method and wave;
- four-position Post-Migration comparison including target database evidence;
- third append-only raw database extract;
- `Verification Incomplete` for missing/incompatible mandatory verification evidence.

A phase contract does not authorize new regulatory mappings, weights, thresholds or exception roles. Such content remains subject to the approved owner/SME workflow.
