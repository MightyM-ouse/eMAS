# eMAS Architecture Index

| Document | Purpose |
|---|---|
| [eMAS Project Flow](eMAS_Project_Flow.md) | End-to-end configuration, execution, assessment, reporting, review and evidence-retention flow |
| [eMAS Repository Architecture](eMAS_Repository_Architecture.md) | Mapping of repository folders to source components, runtime boundaries, release packaging and evidence controls |

## Architecture hierarchy

1. The enterprise requirements define approved scope and constraints.
2. The project-flow document defines how eMAS operates across the three phases.
3. The repository-architecture document defines where each implementation and documentation component belongs.
4. The canonical folder tree is maintained in [eMAS Repository Structure](../repository/eMAS_Repository_Structure.md).

All architecture changes must preserve the following decisions:

- one internal XLSM mapping workbook;
- one runtime JSON exported directly from Excel;
- no PowerShell access to the mapping workbook;
- one shared PowerShell engine;
- phase-specific orchestration and report templates;
- optional WPF only for pre-migration and post-migration;
- read-only processing and traceable evidence.
