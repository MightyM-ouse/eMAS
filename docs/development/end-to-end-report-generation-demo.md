# End-to-End Report Generation Demo

## Purpose and status

This demo is the first mapping-driven vertical slice from validated Runtime JSON
through normalized phase results to controlled XLSX reports. It demonstrates
technical feasibility only. It is not production-qualified, regulated validation
evidence, Microsoft Excel qualification, Windows PowerShell qualification or a
customer deployment package.

## Architecture

```text
Runtime JSON -> eMAS.RuntimeConfiguration -> validated wrapper
Normalized phase result JSON + authoritative template-map JSON
Controlled XLSX template 1.1.1
        -> Export-eMASResultToTemplate
        -> standard-library ZIP/XML MVP helper
        -> timestamped XLSX report + execution log
```

The Runtime JSON remains schema 1.0.0 and controls shared interpretation. The
report mapping schema and three template maps are separate technical binding
contracts at mapping version 1.0.0. They do not control phase workflow or contain
business/regulatory interpretation.

## Contract reconciliation

Claude's finalized template mappings did not supersede the Runtime JSON loader's
schema 1.0.0 compatibility map. No loader candidate names or supported schema
versions were changed. The retained assumptions are:

- Runtime JSON property compatibility remains centralized in
  `engine/core/eMAS.Configuration.Contract.psm1`;
- phase result collections are named by each mapping's `sourceCollection` and
  `additionalSourceCollections` values;
- `matchRowByLabelColumns` label values use the mapped `sourceField`, or the
  lower-camel form of the controlled target label when `sourceField` is null;
- template-map version 1.0.0 and controlled template version 1.1.1 are required;
- phase scripts receive the stable validated runtime wrapper and do not traverse
  raw Runtime JSON.

## PowerShell command surface

`engine/reporting/eMAS.ReportPopulation.psm1` exports:

```powershell
Export-eMASResultToTemplate `
  -ResultJsonPath <normalized-result.json> `
  -TemplateMappingPath <phase.template-map.json> `
  -TemplatePath <controlled-template.xlsx> `
  -OutputWorkbookPath <generated-report.xlsx> `
  -ExecutionLogPath <execution.log>
```

Exactly one of `-Result` or `-ResultJsonPath` is accepted through PowerShell
parameter sets. The shared command validates identity, invokes the helper and
returns a structured result. Failures retain `RPT-*` codes.

## Supported write modes

- `appendRows` writes mapped fields in controlled table-column order and expands
  the table reference within declared pre-provisioned capacity.
- `matchRowByLabelColumns` requires one unambiguous controlled label row and
  updates only authorized non-label fields. Additional rows are allowed only
  where the mapping explicitly permits them.
- `singleRowUpdate` requires exactly one normalized result object.
- `copyFromExternalSourceAppendOnly` appends raw rows while preserving workbook
  headers exactly, including `Source.Name` and `DossierDirecotry`.
- `staticReleaseManaged` validates protected control structures and leaves their
  values unchanged.

Rows beyond `maxPreProvisionedRows` fail with `RPT-WRITE-090`. The MVP does not
silently shift following tables, validation ranges or conditional-formatting
ranges.

## Error model

Findings contain `Code`, `Severity`, `Phase`, `MappingTarget`, `Worksheet`,
`Table`, `Column`, `Message`, `Evidence` and `IsBlocking`. Implemented families
include `RPT-MAP-*`, `RPT-RESULT-*`, `RPT-TEMPLATE-*`, `RPT-SHEET-*`,
`RPT-TABLE-*`, `RPT-COLUMN-*`, `RPT-ROW-*`, `RPT-WRITE-*`,
`RPT-PRESERVE-*` and `RPT-VALIDATE-*`.

## Template preservation

The helper calculates the source SHA-256 before generation, copies the template,
modifies only the output package, validates the generated ZIP/XML package and
recalculates the source hash. Before/after snapshots verify:

- worksheet names/order;
- table names and column order;
- formulas;
- data validation;
- conditional formatting;
- workbook relationships;
- static release-managed table values;
- raw evidence headers and template control identity.

Intentional changes are limited to mapped cell values and expected table-range
expansion. Unmapped package parts, drawings, extension parts, relationships and
protected content remain untouched.

## Python boundary

This Python helper is an MVP report-population implementation used behind
the PowerShell command surface. It is not the final qualified production
OpenXML reporting engine.

It uses Python standard-library ZIP/XML handling plus the repository's existing
`jsonschema` validation dependency. It does not use a general workbook
load/save cycle because that could discard protected OOXML features. The helper
does not calculate Excel formulas and does not claim Excel rendering fidelity.

## Demo commands

```powershell
pwsh -NoProfile -File demo/scripts/Invoke-eMASPreSalesDemo.ps1 `
  -RuntimeConfigurationPath tests/fixtures/runtime-config/valid-minimal.json `
  -ResultJsonPath demo/results/pre-sales-result.demo.json `
  -TemplatePath templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx `
  -TemplateMappingPath config/report-mappings/pre-sales.template-map.json `
  -OutputDirectory demo/output
```

Use the corresponding Pre-Migration or Post-Migration wrapper and phase files
for the other reports. Outputs are timestamped and ignored by Git.

## Validation

`tests/reporting/test_report_generation.py` covers positive generation for all
phases, contract/identity failures, all five write modes, source immutability,
package validity and structural preservation. `build/validate_report_mappings.py`
remains the authoritative mapping-to-template validator.

## Known limitations and production work

- Functional proof is macOS/Python only in this task; no local PowerShell
  executable was available for the new wrapper/reporting module.
- Windows PowerShell 5.1 and PowerShell 7.6 execution qualification is pending.
- Microsoft Excel open/save, calculation, locale, bitness and rendering
  qualification is pending.
- Safe row insertion that shifts a following table and its dependent ranges is
  deliberately blocked beyond pre-provisioned capacity.
- Formula evaluation, production signing, release manifests, accessibility,
  performance, rollback/recall and customer packaging remain future work.
- The synthetic fixtures are demonstration evidence, not regulatory content or
  customer data.
