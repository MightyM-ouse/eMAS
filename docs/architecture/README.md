# eMAS Architecture Index

Use these documents in the listed order.

| ID | Document | Status | Purpose |
|---|---|---|---|
| ARCH-SOL | [eMAS Solution Architecture](eMAS_Solution_Architecture.md) | v1.0 Effective | Component boundaries, data flow, common run contract, package profiles, failure behavior and quality attributes |
| ARCH-FLOW | [eMAS Project Flow](eMAS_Project_Flow.md) | v2.0 Effective | End-to-end authoring, validation, execution, phase and evidence flow |
| ARCH-REPO | [eMAS Repository Architecture](eMAS_Repository_Architecture.md) | v1.1 Effective | Mapping of solution responsibilities to repository and release locations |
| PHASES | [eMAS Phase Contracts](phase-contracts/README.md) | v1.0 Effective | Phase-specific inputs, checks, exclusions, results and report/evidence obligations |

## Phase contracts

- [Pre-Sales Assessment](phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md)
- [Pre-Migration Readiness](phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md)
- [Post-Migration Verification](phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md)

## Architecture hierarchy

1. Enterprise Requirements v3.1 controls product scope and outcomes.
2. Effective configuration contracts and Runtime JSON Schema 1.0.0 control interpretation and serialization.
3. Solution Architecture controls system/component boundaries.
4. Project Flow controls end-to-end behavior.
5. Phase contracts control phase-specific behavior.
6. Repository Architecture and Repository Structure control file/component placement.
7. Implementation and templates must conform to all applicable higher-level contracts.

Architecture changes must preserve one XLSM authoring source, one shared runtime JSON, no PowerShell access to XLSM, a shared engine, phase-specific orchestration/templates, WPF only for Pre-/Post-Migration, read-only evidence handling and traceable output.
