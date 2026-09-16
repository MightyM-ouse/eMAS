# Configuration Authoring

This folder contains source-controlled assets for eMAS mapping-workbook authoring.

## Current assets

- `poc/` — synthetic, reproducible XLSM/VBA proof-of-concept source, fixtures and manifest.
- `eMAS_Mapping_Workbook_MVP_v1.0.xlsx` — macro-free 28-sheet base workbook for the scenario-JSON MVP.
- generated macro-free XLSX input — created locally under `output/poc/`.
- generated macro-enabled POC workbook — created internally under `dist/internal/poc/`.

For the MVP branch, the macro-free base workbook implements the reviewed sheet and table contract in
[`02_eMAS_Mapping_Workbook_Implementation_Specification_v1.0.md`](../../docs/configuration/02_eMAS_Mapping_Workbook_Implementation_Specification_v1.0.md).
It includes complete scenario/phase/module mappings, an individual-object coverage map, and the generated
coverage matrix required before scenario-specific JSON can be produced. PowerShell must consume generated
JSON rather than read the workbook directly.

The older XLSM/VBA proof of concept remains available as historical implementation evidence. It is not the
MVP authoring baseline on `requirements/mvp-workbook-json`.

The base workbook is an implementation scaffold, not a controlled production configuration and not a
customer deliverable. Detailed regulatory and migration rules still require controlled population and review.

See [the POC README](poc/README.md) and [the POC conformance contract](../../docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md).
