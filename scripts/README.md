# Scripts

This folder contains user-facing phase entry scripts and lightweight launchers.

Phase entry points:

- `eMAS-PreSalesAssessment.ps1`;
- `eMAS-PreMigrationReadiness.ps1`;
- `eMAS-PostMigrationVerification.ps1`.

The three entry scripts implement the first controlled end-to-end report-generation slice. Each script:

1. validates the immutable shared Runtime JSON through the common runtime loader;
2. validates a phase-specific normalized result JSON against the mapping-declared result schema;
3. verifies report-template map version `2.0.0` and controlled template version `1.2.0`;
4. populates the selected controlled workbook through the shared report module;
5. writes a separate timestamped UTF-8 execution log;
6. returns workbook path, log path, hashes, versions, row counts and validation status.

The generic orchestration function is maintained in `private/Invoke-eMASPhaseReport.ps1`.

## Execution modes

### Initialization-only compatibility mode

When `NormalizedResultPath` is omitted, each script validates Runtime JSON and returns the original initialization result without starting assessment/report processing. This mode is retained for existing runtime-contract callers and tests.

### Report-generation mode

When `NormalizedResultPath` is supplied, the script validates Runtime JSON and the normalized phase result, then creates the controlled report and execution log.

Required inputs:

- `RuntimeConfigurationPath` — reviewed immutable shared Runtime JSON;
- `NormalizedResultPath` — phase result object conforming to result-contract version `1.0.0`.

Template, mapping, schema, output and Python paths default to controlled repository locations and may be overridden for controlled testing.

Example:

```powershell
.\scripts\eMAS-PreMigrationReadiness.ps1 `
    -RuntimeConfigurationPath .\config\runtime\development\eMAS_Runtime_Config.json `
    -NormalizedResultPath .\output\pre-migration.result.json `
    -OutputWorkbookPath .\output\PreMigration_Readiness.xlsx
```

## Validated runtime allocation

The synthetic end-to-end contract workflow verifies:

- Pre-Sales report generation under Windows PowerShell 5.1;
- Pre-Migration report generation under PowerShell 7.6 on Windows;
- Post-Migration report generation under PowerShell 7.6 on Windows;
- paths containing spaces;
- generated workbook and UTF-8 execution-log creation;
- map/template/result-contract version reporting.

Workflow:

```text
.github/workflows/end-to-end-report-slice-v3.2.yml
```

## Implementation boundary

This execution slice begins after phase discovery and interpretation have produced the normalized result object. It does not claim that every Pre-Sales collection rule, Pre-Migration assessment rule or Post-Migration evidence reader is implemented.

Entry scripts must:

- conform to Enterprise Requirements v3.2 and the applicable phase contract;
- validate phase parameters and output location;
- load one immutable Runtime JSON through the shared configuration module;
- establish run metadata and logging;
- orchestrate only required shared-engine modules;
- select the correct controlled template and mapping;
- report clear console progress and completion/output paths.

They must not duplicate shared technical logic, hardcode business/regulatory interpretation, read the XLSM, generate or repair Runtime JSON, modify source evidence or treat generated reports as customer acceptance.
