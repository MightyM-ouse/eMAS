# Scripts

This folder contains the three user-facing phase entry scripts and lightweight launchers.

Planned entry points:

- `eMAS-PreSalesAssessment.ps1`
- `eMAS-PreMigrationReadiness.ps1`
- `eMAS-PostMigrationVerification.ps1`
- `launchers/Start-eMAS-PreSales.cmd`

Entry scripts define parameters, validate phase inputs, select the required shared-engine modules and coordinate report generation. Shared processing logic must remain in `engine/`.
