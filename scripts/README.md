# Scripts

This folder contains user-facing phase entry scripts and lightweight launchers.

Phase entry points and launcher status:

- `eMAS-PreSalesAssessment.ps1`;
- `eMAS-PreMigrationReadiness.ps1`;
- `eMAS-PostMigrationVerification.ps1`;
- planned: `launchers/Start-eMAS-PreSales.cmd`.

The three PowerShell entry scripts currently implement run identity, execution-log selection and blocking Runtime JSON validation only. They intentionally stop before assessment processing; phase inputs, discovery, calculations, reporting and final result orchestration remain later work. The command launcher remains planned.

Entry scripts must:

- conform to the applicable Effective phase contract under `docs/architecture/phase-contracts/`;
- validate phase parameters and output location;
- load one immutable runtime JSON through the shared configuration module;
- establish run metadata and logging;
- orchestrate only required shared-engine modules;
- select the correct controlled template;
- report clear console progress and completion/output paths.

They must not duplicate shared technical logic, hardcode business/regulatory interpretation, read the XLSM or generate/repair runtime JSON.
