# eMAS Report Redesign v3.2 Alignment Status

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** Requirements and controlled report contracts aligned; implementation and release qualification pending  
**Date:** 2026-07-14

## Aligned requirements and contracts

- `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md`
- Pre-Sales Report Requirements v1.1
- Pre-Migration Report Requirements v1.1
- Post-Migration Report Requirements v1.1
- Pre-Sales Phase Contract v1.2
- Pre-Migration Phase Contract v1.2
- Post-Migration Phase Contract v1.2
- requirements, phase-contract and canonical routing indexes

## Aligned controlled artifacts

| Phase | Template version | Map version | Workbook structure |
|---|---:|---:|---:|
| Pre-Sales Assessment | 1.2.0 | 2.0.0 | 4 sheets |
| Pre-Migration Readiness | 1.2.0 | 2.0.0 | 11 sheets |
| Post-Migration Verification | 1.2.0 | 2.0.0 | 15 sheets |

Canonical paths:

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

A reproducible Python/openpyxl generator and validation workflow are maintained under:

```text
tools/report-redesign-v3.2/
.github/workflows/materialize-report-redesign-v3.2.yml
```

## Approved Pre-Sales changes

- five mode-driven customer collection options;
- current-system information only during customer collection;
- target application/version/hotfix blank and `Pending EXTEDO Review`;
- no unnecessary evidence questions;
- detailed discovery only for export evidence;
- archive, index and database/direct-copy evidence retained as aggregate size/provenance only;
- separate customer collection and EXTEDO review/final-estimation stages;
- exact four-sheet controlled workbook.

## Approved Pre-Migration changes

- exact eleven-sheet controlled workbook;
- redesigned Executive Summary;
- stable dossier and sequence comparison IDs;
- explicit MigrationMethod and MigrationWave baseline fields;
- normalized file-type/count/size baseline;
- attributable exceptions, exclusions and baseline integrity/handover evidence.

## Approved Post-Migration changes

- exact fifteen-sheet controlled workbook;
- independent baseline, import-report, target-database and post-import evidence positions;
- dossier and sequence before/after comparison;
- file-type/count/size comparison;
- interpreted database dossier inventory;
- append-only raw import, post-import and database-extract evidence sheets;
- separate system comparison notes and reviewer notes/dispositions;
- `Verification Incomplete` for missing or incompatible mandatory evidence.

## Remaining controlled implementation work

This alignment does not constitute product release. The following remain pending:

1. approval and validation of complete shared runtime mapping content;
2. integration of the Pre-Sales customer collector and EXTEDO review/estimation with template version 1.2.0;
3. implementation of Pre-Migration readiness and baseline serialization;
4. implementation of Post-Migration evidence readers and reconciliation;
5. cross-phase unit, fixture, Windows, NTFS, UNC and Microsoft Excel/OpenXML qualification;
6. separate customer Pre-Sales and internal migration packages, manifests, checksums and release approval.
