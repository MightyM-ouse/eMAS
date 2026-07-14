# eMAS Pre-Sales Assessment Phase Contract

**Version:** 1.2  
**Status:** Approved Working Contract on `requirements/report-redesign-v3.2`  
**Phase code:** `PRE_SALES`  
**Runtime:** Windows PowerShell 5.1 on Windows  
**Canonical requirement:** `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.2.md`  
**Detailed report requirement:** `docs/requirements/report-redesign/01_eMAS_PreSales_Report_Requirements_v1.1.md`

## 1. Purpose

Pre-Sales collects proportionate current-system evidence and produces a normalized result for EXTEDO review and final migration estimation. It shall not claim readiness, migration success, regulatory validation, formal customer validation or customer acceptance.

## 2. Entry and user experience

The phase is invoked through a PowerShell entry script or simple Windows launcher. No WPF interface is required.

The customer selects one assessment mode:

- `ExternalExport`
- `ECTDManagerExport`
- `ECTDManagerDatabaseArchive`
- `ECTDManagerHybrid`
- `ArchiveOnly`

The script then requests only evidence required by that mode and displays clear progress throughout execution.

## 3. Customer input boundary

Required common information is limited to current-system context:

- customer/project/reference;
- current application/source system;
- current version/hotfix where known;
- current database type/version only when database evidence is in scope;
- relevant evidence paths or customer-provided aggregate sizes;
- output location.

The customer is not required to provide target application/version/hotfix, upgrade path, migration scenario, waves or final effort. Target fields remain blank with status `Pending EXTEDO Review`.

## 4. Mode-specific evidence

| Mode | Export | Archive | Index | Database |
|---|---:|---:|---:|---:|
| ExternalExport | Detailed | No | No | No |
| ECTDManagerExport | Detailed | No | No | No |
| ECTDManagerDatabaseArchive | No | Aggregate | Aggregate | Aggregate |
| ECTDManagerHybrid | Detailed | Aggregate | Aggregate | Aggregate |
| ArchiveOnly | No | Aggregate | Aggregate | No |

Detailed export discovery may produce dossier/sequence inventories, counts, sizes and high-level classification/structure evidence.

Archive, index and database/direct-copy evidence retains only source type/reference, accessibility, aggregate size, provenance, scope/review status and comments. It shall not retain file/folder inventories, extension breakdown, long-path counts, largest-file or zero-byte details.

Missing evidence remains NotAssessed/Unknown and is never silently converted to zero or Green.

## 5. Processing contract

The phase shall:

1. validate package, runtime configuration, schema, template and map compatibility before scanning;
2. create execution identity and a separate timestamped UTF-8 log;
3. validate current-system and mode-specific inputs;
4. scan source evidence read-only;
5. perform detailed export discovery only where applicable;
6. calculate aggregate direct-copy size without retaining detailed inventory;
7. apply approved runtime rules for classification and evidence-quality conclusions;
8. preserve EvaluationStatus, RAG, Confidence, ValueSource and ReviewRequired separately;
9. build a normalized customer-collection result;
10. leave target-dependent scenario/method/effort fields pending EXTEDO review;
11. populate the controlled four-sheet template when reporting integration is enabled;
12. clearly identify files to share with EXTEDO.

PowerShell shall not read the mapping workbook or generate/repair/reinterpret runtime JSON.

## 6. EXTEDO review stage

The customer result may be consumed internally to complete:

- target application/version/hotfix;
- approved upgrade path;
- scenario/workstreams;
- migration methods and waves;
- internal effort calculation;
- estimate confidence and quotation clarifications.

A customer rerun is not required solely to add target planning.

## 7. Controlled report

Template version: `1.2.0`  
Template-map version: `2.0.0`

Exact sheet order:

1. `01_Executive_Estimate`
2. `02_Dossier_Inventory`
3. `03_Sequence_Inventory`
4. `04_Path_&_Volume_Inventory`

The fourth sheet contains separate detailed-export and aggregate-direct-copy tables. Dossier and sequence sheets use a controlled Not Applicable state when export discovery is not in scope.

## 8. Outputs

A successful customer collection produces:

- controlled Pre-Sales XLSX report when report generation is enabled;
- normalized customer-collection result JSON;
- detailed timestamped UTF-8 execution log;
- optional manifest/checksum evidence according to release configuration.

The result includes current-system context, assessment mode, target-planning status, export evidence, direct-copy evidence, dossier/sequence inventories where applicable, collection summary and configuration/template identity.

## 9. Failure behavior

The phase stops before scanning for incompatible/invalid package, runtime JSON, schema, template or map. It stops with a clear error when mandatory mode-specific evidence is inaccessible or invalid. Partial output is labelled incomplete and never presented as a final estimate.

## 10. Customer-package boundary

The customer package includes only the Pre-Sales launcher/script, required PowerShell 5.1-compatible engine modules, customer-safe controlled runtime JSON/checksum, Pre-Sales template/map, instructions, manifest and output folder.

It excludes mapping XLSM/VBA, confidential rates, Pre-Migration/Post-Migration tools, internal tests and confidential assets.

## 11. Acceptance criteria

The phase conforms when:

- only current-system information is required from the customer;
- target fields remain Pending EXTEDO Review;
- only mode-relevant questions are asked;
- export evidence is detailed and direct-copy evidence is aggregate-only;
- source evidence remains read-only;
- semantic dimensions remain separate;
- the exact four-sheet workbook is generated without repair;
- customer-facing filenames contain no internal IDs or component versions;
- the normalized result validates against the v3.2 result schema;
- a separate log is generated and completion identifies shareable outputs.
