# eMAS Final Enterprise Requirements v3.2

**Version:** 3.2  
**Status:** Approved Working Baseline on `requirements/report-redesign-v3.2`  
**Date:** 2026-07-14  
**Owner:** Product Owner  
**Supersedes for branch implementation:** Enterprise Requirements v3.1 plus the report-redesign v1.0 working documents  
**Promotion boundary:** Becomes the effective authority-rank-1 baseline after approved merge/release governance; until then v3.1 remains the effective baseline on `main`.

## 1. Purpose

The eCTD Migration Assessment Script (eMAS) provides a controlled, read-only and configuration-driven solution for:

1. Pre-Sales Assessment;
2. Pre-Migration Readiness;
3. Post-Migration Verification.

The same reviewed internal mapping workbook exports one immutable runtime JSON consumed by all three phases. PowerShell performs generic technical operations. Business and regulatory interpretation remains controlled by the runtime JSON, schemas, normalized result contracts and report-template mappings.

## 2. Source-of-truth model

- Reviewed internal mapping XLSM: authoring source of truth.
- Validated immutable exported runtime JSON: runtime source of truth.
- Exact runtime JSON version and SHA-256 loaded for a run: execution source.
- Controlled phase XLSX template: physical report layout source.
- Phase template-map JSON: technical result-to-workbook binding source.
- Normalized result JSON/schema: phase output contract.

PowerShell shall not read the mapping workbook or generate, repair, reinterpret or silently default the runtime JSON.

## 3. Runtime profile

- Shared business-engine core: Windows PowerShell 5.1-compatible language/API baseline.
- Pre-Sales customer package: Windows PowerShell 5.1 on Windows.
- Pre-Migration and Post-Migration: PowerShell 7.6 LTS on Windows.
- macOS PowerShell 7.6 LTS may be used for development and pure unit/fixture testing.
- Windows remains the authoritative qualification environment for NTFS, UNC, WPF and Microsoft Excel/OpenXML behavior.

Runtime-specific adapters may optimize technical processing but shall not duplicate or alter business interpretation.

## 4. Common controls

All phases shall:

- remain read-only against customer/source evidence;
- operate offline unless a separately approved integration explicitly requires otherwise;
- validate package, runtime JSON, schema, template and mapping compatibility before scanning;
- keep EvaluationStatus, RAG, Severity, Blocker, Confidence, ValueSource and ReviewRequired separate;
- keep findings separate from recommendations/actions;
- preserve original evidence when exceptions are accepted;
- use controlled terminology and configuration-driven labels;
- create a detailed timestamped UTF-8 log separate from the workbook;
- include run/configuration/schema/mapping/template identity and integrity evidence;
- avoid customer data, credentials, internal Confluence identifiers and confidential rates in filenames or public repositories.

`Warning` is an approved EvaluationStatus for a completed usable evaluation with a recoverable condition requiring attention. It does not independently determine RAG, severity, blocker or phase outcome.

## 5. Pre-Sales Assessment

### 5.1 Purpose and boundary

Pre-Sales collects current-system evidence and, after EXTEDO review, produces migration scope, workload, scenario, complexity, effort range, confidence and quotation clarifications. It is not readiness, migration validation, regulatory validation or acceptance.

### 5.2 Two-stage process

#### Customer Collection

The customer provides only current-system information and evidence required by the selected assessment mode. Target application/version/hotfix, upgrade path, final scenario, migration waves and final effort are not mandatory customer inputs and remain blank with status `Pending EXTEDO Review`.

#### EXTEDO Review

EXTEDO completes target planning, approved upgrade path, scenario/workstreams, migration methods/waves, internal productivity assumptions, effort range and final estimate confidence without requiring a customer rerun solely for target planning.

### 5.3 Assessment modes

- `ExternalExport`
- `ECTDManagerExport`
- `ECTDManagerDatabaseArchive`
- `ECTDManagerHybrid`
- `ArchiveOnly`

The script shall ask only mode-relevant questions.

### 5.4 Evidence depth

- Export roots: detailed dossier/sequence/file/folder/size and high-level classification/structure discovery.
- Archive/index/database/direct-copy sources: aggregate size, source reference, accessibility and provenance only.
- Direct-copy results shall not retain individual files, file/folder counts, extensions, long-path counts, largest-file or zero-byte inventories.
- Additional/staging storage is not requested in customer Pre-Sales unless an approved future mode requires it.

### 5.5 Pre-Sales workbook

Exact sheet order:

1. `01_Executive_Estimate`
2. `02_Dossier_Inventory`
3. `03_Sequence_Inventory`
4. `04_Path_&_Volume_Inventory`

The path/volume sheet contains separate detailed export and aggregate direct-copy tables. Dossier and sequence sheets show a controlled Not Applicable state when export discovery is not in scope.

### 5.6 Approved scenario wording

- `Migration and eCTDmanager Sequential Upgrade`
- `Migration and eSUBmanager Sequential Upgrade`

Scenario, method, effort and RAG remain distinct.

## 6. Pre-Migration Readiness

### 6.1 Purpose

Pre-Migration performs detailed technical/operational checks, determines readiness and creates the immutable attributable baseline consumed by Post-Migration.

Permitted results:

- `Ready`
- `Ready with Accepted Exceptions`
- `Blocked`

Unresolved blockers force `Blocked`.

### 6.2 Pre-Migration workbook

Exact sheet order:

1. `01_Executive_Summary`
2. `02_Readiness_Decision`
3. `03_Inputs_Access_&_Transfer`
4. `04_Dossier_Baseline`
5. `05_Sequence_Baseline`
6. `06_File_Type_Breakdown`
7. `07_File_XML_Path_Checks`
8. `08_Findings_&_Actions`
9. `09_Exceptions_&_Exclusions`
10. `10_Assumptions_&_Limits`
11. `11_Execution_Details`

### 6.3 Baseline requirements

The baseline includes stable dossier/sequence comparison IDs, classifications, expected counts/sizes, normalized file-type measures, migration method, migration wave, readiness action, approval status, exclusions, accepted exceptions/carry-forward, limitations and integrity evidence.

Every in-scope dossier and sequence has a method/wave or explicit Not Applicable/exclusion treatment. Method and wave are not inferred from RAG.

## 7. Post-Migration Verification

### 7.1 Purpose and evidence flow

Post-Migration compares:

`Pre-Migration Baseline -> Import Report -> Target Database -> Post-Import Verification`

Each evidence source is independent. Import-report presence does not prove database or post-import presence.

Permitted final results:

- `Reconciled`
- `Reconciled with Accepted Exceptions`
- `Not Reconciled`
- `Verification Incomplete`

Missing/incompatible mandatory evidence produces `Verification Incomplete` and shall not be presented as Reconciled.

### 7.2 Post-Migration workbook

Exact sheet order:

1. `01_Executive_Summary`
2. `02_Verification_Scope`
3. `03_Overall_Reconciliation`
4. `04_Dossier_Before_&_After`
5. `05_Sequence_Before_&_After`
6. `06_File_Type_&_Size_Comparison`
7. `07_Database_Dossier_Inventory`
8. `08_Import_Evidence_Review`
9. `09_Discrepancies_&_Actions`
10. `10_Accepted_Exceptions`
11. `11_Assumptions_&_Limits`
12. `12_Review_&_Execution`
13. `Import Report Detail`
14. `Post Import Verification`
15. `Database Dossier Extract`

### 7.3 Raw evidence

All three raw evidence sheets are append-only. Rows and literal source headers are preserved exactly, including `Source.Name` and `DossierDirecotry`. Normalization and reviewer disposition occur only in interpreted sheets.

### 7.4 Reviewer separation

SystemComparisonNote, ReviewerNote and ReviewerDisposition remain separate. Reviewer input cannot silently replace normalized comparison evidence.

## 8. Mapping workbook and runtime configuration

The mapping workbook shall remain simple to maintain, with focused sheets for configuration, folder structure, regions, formats, dossier types, scenarios, methods, version upgrades, effort, readiness, reconciliation, findings/actions, report configuration, value lists and JSON export mapping.

Each executable rule has a stable ID, applicability/condition, result/effect and traceability fields. Free-text documentation is not treated as executable logic unless converted into a supported normalized condition/operator model.

One shared runtime JSON is used across all phases. Customer-safe and internal profiles may filter confidential content without changing the shared interpretation model.

## 9. Controlled report artifacts

Aligned report artifact versions on this branch:

- Template version: `1.2.0`
- Report-template map version: `2.0.0`
- Pre-Sales, Pre-Migration and Post-Migration normalized result schemas: v3.2 branch baseline

Canonical paths:

- `templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx`
- `templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx`
- `templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx`
- `config/report-mappings/pre-sales.template-map.json`
- `config/report-mappings/pre-migration.template-map.json`
- `config/report-mappings/post-migration.template-map.json`
- `config/report-mappings/report-template-map.schema.json`
- `config/result-schemas/report-redesign-v3.2/`

Template maps contain technical binding facts only. Business rules remain in the runtime configuration.

## 10. Package profiles

### 10.1 Internal mapping authoring package

Contains the reviewed mapping XLSM/VBA, validation/export tooling, schema, value-list guidance and release controls. It is not customer-distributable.

### 10.2 Customer Pre-Sales package

Contains only the Pre-Sales launcher/entry script, Windows PowerShell 5.1-compatible engine modules, customer-safe controlled runtime JSON/checksum, Pre-Sales template/map, instructions, manifest and output folder.

It excludes the mapping workbook/VBA, internal rates, Pre-Migration/Post-Migration assets, internal tests and confidential material.

### 10.3 Internal migration package

Contains internal Pre-Sales review, Pre-Migration and Post-Migration scripts, shared engine/runtime adapters, controlled internal runtime configuration, three templates/maps/result schemas, baseline/evidence/output areas, documentation, manifest and checksums.

## 11. Required outputs

Each phase creates its controlled XLSX report and separate detailed log. Normalized result JSON/baseline/manifest files are produced where required by the phase contract and package profile. Completion messages identify the output files and, for customer Pre-Sales, the files to share with EXTEDO.

## 12. Acceptance and release boundary

The v3.2 design is complete when requirements, phase contracts, templates, maps and result schemas are synchronized. Product implementation is complete only after:

- runtime JSON content is approved and validated;
- all three PowerShell phase implementations are complete;
- reporting integration is complete;
- baseline and evidence readers are compatible;
- Windows runtime/NTFS/UNC tests pass;
- Microsoft Excel/OpenXML qualification passes;
- customer and internal packages are built with manifests/checksums;
- security, privacy, documentation and release controls are approved.

No design or artifact status alone constitutes production release or validation approval.
