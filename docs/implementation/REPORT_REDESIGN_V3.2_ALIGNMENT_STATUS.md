# eMAS Report Redesign v3.2 Alignment and Implementation Status

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** Approved report contracts aligned; generic report-generation and package-integrity slices implemented and validated; phase evidence processing and release qualification pending  
**Date:** 2026-07-14

## 1. Aligned requirements and contracts

- `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md`
- Pre-Sales Report Requirements v1.1
- Pre-Migration Report Requirements v1.1
- Post-Migration Report Requirements v1.1
- Pre-Sales Phase Contract v1.2
- Pre-Migration Phase Contract v1.2
- Post-Migration Phase Contract v1.2
- requirements, phase-contract and canonical routing indexes

## 2. Aligned controlled report artifacts

| Phase | Template version | Map version | Result contract | Workbook structure |
|---|---:|---:|---:|---:|
| Pre-Sales Assessment | 1.2.0 | 2.0.0 | 1.0.0 | 4 sheets |
| Pre-Migration Readiness | 1.2.0 | 2.0.0 | 1.0.0 | 11 sheets |
| Post-Migration Verification | 1.2.0 | 2.0.0 | 1.0.0 | 15 sheets |

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

The reproducible workbook/map generator is maintained at:

```text
tools/report-redesign-v3.2/Generate-eMASReportArtifactsV32.py
```

## 3. Implemented generic report-generation slice

The repository now contains a phase-neutral executable path from a validated Runtime JSON and normalized phase-result JSON to a controlled XLSX report and timestamped UTF-8 log.

Implemented components:

```text
engine/reporting/eMAS.ReportPopulation.psm1
engine/reporting/emas_report_openxml.py
engine/reporting/emas_report_openxml_v32.py
scripts/private/Invoke-eMASPhaseReport.ps1
scripts/eMAS-PreSalesAssessment.ps1
scripts/eMAS-PreMigrationReadiness.ps1
scripts/eMAS-PostMigrationVerification.ps1
```

The implementation:

- validates the immutable shared Runtime JSON before assessment/report processing;
- validates normalized phase results against the mapping-declared result schema;
- enforces map version `2.0.0`, template version `1.2.0` and result-contract version `1.0.0`;
- derives technical binding identity from the selected map and controlled workbook rather than from business-result payloads;
- preserves source templates, workbook relationships, formulas, validations, conditional formatting and protected raw-evidence headers;
- writes clear progress messages, output paths, versions, row counts and SHA-256 values;
- preserves initialization-only compatibility when no normalized result is supplied.

This slice begins after phase-specific discovery and interpretation have produced the normalized result object.

## 4. Implemented automated verification

Automated coverage includes:

- exact 4/11/15 workbook sheet order;
- template/map/result-contract version compatibility;
- mapping and normalized-result schema validation;
- all three report-generation paths;
- invalid phase, missing required data and unsupported-version failures;
- source-template immutability and SHA-256 identity;
- OpenXML ZIP integrity and protected structure preservation;
- raw import/post-import/database-extract header preservation;
- Windows PowerShell 5.1, Windows PowerShell 7.6 and macOS PowerShell 7.6 runtime contracts;
- end-to-end phase entrypoint execution using deterministic synthetic fixtures.

Relevant workflows:

```text
.github/workflows/materialize-report-redesign-v3.2.yml
.github/workflows/powershell-runtime-contracts.yml
.github/workflows/end-to-end-report-slice-v3.2.yml
```

The current branch passes the report-contract, runtime-contract and end-to-end report-slice workflows.

## 5. Implemented release-package integrity slice

Implemented commands:

```text
build/New-eMASChecksumManifest.ps1
build/Test-eMASReleasePackage.ps1
build/New-eMASPreSalesPackage.ps1
build/New-eMASInternalRelease.ps1
```

The package implementation provides:

- separate restricted customer Pre-Sales and internal three-phase package structures;
- one supplied immutable Runtime JSON copied without reinterpretation;
- deterministic sorted file manifests with file size and SHA-256;
- independent detection of missing, altered, duplicate, unsafe, prohibited and unmanifested files;
- optional ZIP creation;
- generated package instructions and explicit release boundaries;
- Windows PowerShell 5.1 customer-package and PowerShell 7.6 internal-package CI validation.

Package-contract workflow:

```text
.github/workflows/release-package-contracts.yml
```

The current branch passes both package-build and package-integrity jobs using synthetic repository fixtures.

## 6. Approved phase designs carried by the implementation

### Pre-Sales

- five mode-driven customer collection options;
- current-system information only during customer collection;
- target application/version/hotfix blank and `Pending EXTEDO Review`;
- detailed discovery only for export evidence;
- archive, index and database/direct-copy evidence retained as aggregate size/provenance only;
- separate customer collection and EXTEDO review/final-estimation stages;
- exact four-sheet controlled workbook.

### Pre-Migration

- exact eleven-sheet controlled workbook;
- redesigned Executive Summary;
- stable dossier and sequence comparison IDs;
- explicit `MigrationMethod` and `MigrationWave` baseline fields;
- normalized file-type/count/size baseline;
- attributable exceptions, exclusions and baseline integrity/handover evidence.

### Post-Migration

- exact fifteen-sheet controlled workbook;
- independent baseline, import-report, target-database and post-import evidence positions;
- dossier and sequence before/after comparison;
- file-type/count/size comparison;
- interpreted database dossier inventory;
- append-only raw import, post-import and database-extract evidence sheets;
- separate system comparison notes and reviewer notes/dispositions;
- `Verification Incomplete` for missing or incompatible mandatory evidence.

## 7. Remaining controlled implementation and qualification work

The following work cannot be represented as complete by the generic report slice alone:

1. approval and validation of complete shared Runtime JSON mapping content, including SME-owned rules, thresholds, recommendations and exception policies;
2. implementation and approval of the complete Pre-Sales customer collector, evidence discovery and EXTEDO internal estimation workflow;
3. implementation and approval of Pre-Migration source discovery, readiness evaluation, finding generation and attributable baseline serialization;
4. implementation and approval of Post-Migration import-report, database and post-import evidence readers and reconciliation logic;
5. production-grade database extract profiles for supported application/database versions;
6. Windows, NTFS, UNC, performance, large-volume, Office/OpenXML and locale qualification on supported environments;
7. native Microsoft Excel review, code signing, package signing, controlled release approval and customer acceptance.

These remaining items require approved configuration content, representative controlled evidence, supported target environments, SME decisions or formal validation evidence. The repository must not infer or fabricate them.
