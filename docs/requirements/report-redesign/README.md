# eMAS Report Redesign v3.2

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** Approved working baseline; templates, technical maps and normalized result schemas aligned  
**Enterprise consolidation:** [eMAS Final Enterprise Requirements v3.2](../eMAS_Final_Enterprise_Requirements_v3.2.md)

## Approved phase requirements

| Phase | Requirement | Status | Workbook |
|---|---|---|---:|
| Pre-Sales Assessment | [Pre-Sales Report Requirements v1.1](01_eMAS_PreSales_Report_Requirements_v1.1.md) | Approved | 4 sheets |
| Pre-Migration Readiness | [Pre-Migration Report Requirements v1.1](02_eMAS_PreMigration_Report_Requirements_v1.1.md) | Approved | 11 sheets |
| Post-Migration Verification | [Post-Migration Report Requirements v1.1](03_eMAS_PostMigration_Report_Requirements_v1.1.md) | Approved | 15 sheets |
| Mapping workbook | [Mapping Workbook Requirements v1.0](04_eMAS_Mapping_Workbook_Requirements_v1.0.md) | Approved design | Simple focused-sheet model |

Earlier v1.0 phase documents remain in this folder for traceability but are superseded for branch implementation by the v1.1 documents.

## Controlled artifact alignment

- Template version: `1.2.0`
- Report-template map version: `2.0.0`
- Three normalized phase result schemas aligned to the redesigned workbooks
- Separate timestamped UTF-8 execution logs remain outside the workbooks

Canonical controlled assets:

```text
templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx
templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx
templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx

config/report-mappings/pre-sales.template-map.json
config/report-mappings/pre-migration.template-map.json
config/report-mappings/post-migration.template-map.json
config/report-mappings/report-template-map.schema.json

config/result-schemas/report-redesign-v3.2/
```

A versioned reference copy and artifact README are maintained under `templates/report-redesign-v3.2/` and `config/report-mappings/report-redesign-v3.2/`.

## Approved cross-phase changes

### Pre-Sales

- mode-driven customer collection;
- current-system information only;
- target planning blank and `Pending EXTEDO Review` during customer collection;
- detailed discovery only for export evidence;
- aggregate-only archive/index/database direct-copy evidence;
- no unnecessary additional/staging-storage questions;
- separate customer collection and EXTEDO review/final-estimation stages.

### Pre-Migration

- redesigned Executive Summary;
- exact eleven-sheet structure;
- stable dossier/sequence comparison identifiers;
- explicit MigrationMethod and MigrationWave baseline fields;
- normalized file-type breakdown for later reconciliation;
- attributable exception/exclusion and baseline handover evidence.

### Post-Migration

- four-position comparison: baseline, import, database and post-import evidence;
- dossier and sequence before/after comparison;
- file-type/count/size comparison;
- interpreted database dossier inventory;
- third protected raw database-extract sheet;
- separate system comparison notes and reviewer dispositions;
- `Verification Incomplete` when mandatory evidence is missing or incompatible.

## Next implementation sequence

1. finalize and approve shared runtime JSON content exported by the mapping workbook;
2. integrate the Pre-Sales customer collector and EXTEDO review/estimation with template version 1.2.0;
3. implement the Pre-Migration readiness and baseline writer;
4. implement Post-Migration import/database/post-import readers and reconciliation;
5. complete cross-phase tests and Windows qualification;
6. build separate customer Pre-Sales and internal migration packages with manifests/checksums.

## Governance boundary

Requirements, templates and mapping contracts do not by themselves constitute completed implementation, validation or release. Runtime content approval, PowerShell completion, qualification and package release are separately controlled states.
