# Configuration Authoring

This folder contains source-controlled assets for the internal eMAS mapping-authoring application.

## Current assets

- `poc/` — synthetic, reproducible XLSM/VBA proof-of-concept source, fixtures and manifest.
- generated macro-free XLSX input — created locally under `output/poc/`.
- generated macro-enabled POC workbook — created internally under `dist/internal/poc/`.

The reviewed internal `eMAS_Mapping_Configuration.xlsm` remains the authoring source of truth and directly exports `eMAS_Runtime_Config.json`. PowerShell must not read the workbook or generate/repair runtime JSON.

The public repository contains no controlled production workbook. The synthetic POC is generated from reviewable JSON table definitions and reviewed VBA source. It must not be included in customer Pre-Sales packages.

See [the POC README](poc/README.md) and [the POC conformance contract](../../docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md).
