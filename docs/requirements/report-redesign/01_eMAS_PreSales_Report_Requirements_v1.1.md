# eMAS Pre-Sales Report Requirements

**Document version:** 1.1  
**Status:** Approved Working Requirement  
**Phase code:** `PRE_SALES`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner  
**Supersedes:** `01_eMAS_PreSales_Report_Requirements_v1.0.md` on this branch  
**Implementation state:** Template, template map and normalized result schema aligned to v3.2; PowerShell integration and qualification pending

## 1. Purpose

The Pre-Sales phase collects proportionate current-system evidence and converts it, after EXTEDO review, into a concise and defensible migration estimate. It shall answer:

1. What current source system and evidence are available?
2. What dossiers, sequences and export volumes are present where export discovery is in scope?
3. Which technical formats, regions and dossier types can be identified from approved evidence?
4. Which migration scenario and workstreams are recommended after EXTEDO target planning?
5. What workload, effort range, estimate confidence and clarifications apply?

The report is an estimation and scoping output. It is not a readiness decision, migration execution record, regulatory validation result, formal customer validation result or customer acceptance record.

## 2. Two-stage operating model

### 2.1 Customer Collection

The customer executes the Windows PowerShell 5.1 package in the customer environment. The package collects only current-system information and evidence required by the selected assessment mode.

The customer is not required to know or provide:

- target application;
- target version or hotfix;
- upgrade path;
- final migration scenario;
- migration waves;
- internal productivity rates;
- final person-day estimate.

Target fields remain blank and the controlled planning status is `Pending EXTEDO Review`.

### 2.2 EXTEDO Review and Final Estimation

EXTEDO reviews the customer result and completes target-dependent planning, including:

- target application/version/hotfix;
- approved upgrade path;
- migration scenario and workstreams;
- dossier/sequence migration methods;
- migration waves;
- internal effort calculation;
- final confidence and quotation clarifications.

The customer does not need to rerun evidence collection solely because EXTEDO completes target planning.

## 3. Assessment modes

The selected `AssessmentMode` controls required questions and processing depth. It is not the same as the final `MigrationScenario`.

| Mode code | Customer-facing purpose | Required evidence |
|---|---|---|
| `ExternalExport` | External-system export assessment | Current external system and export root(s) only |
| `ECTDManagerExport` | eCTDmanager export assessment | Current eCTDmanager details and export root(s) only |
| `ECTDManagerDatabaseArchive` | eCTDmanager database and archive move | Current eCTDmanager details plus archive, index and database aggregate evidence |
| `ECTDManagerHybrid` | eCTDmanager hybrid assessment | Detailed export evidence plus aggregate archive, index and database evidence |
| `ArchiveOnly` | Archive and index move | Current system details plus archive and index aggregate evidence |

The script shall not ask for evidence that is not required by the selected mode.

## 4. Inputs

### 4.1 Common current-system inputs

- CustomerName
- ProjectName
- AssessmentReference, supplied or generated
- CurrentApplication
- CurrentApplicationVersion, optional when unknown
- CurrentApplicationHotfix, optional
- CurrentDatabaseType, only when database evidence is in scope
- CurrentDatabaseVersion, optional when in scope
- OutputRoot

### 4.2 Export evidence

When export discovery is in scope, one or more accessible export roots are required.

Detailed export discovery may collect:

- total size;
- file and folder counts;
- dossier and sequence counts;
- dossier and sequence inventories;
- high-level eCTD 3.x, eCTD 4.0 and NeeS indicators;
- region, authority, technical standard, regional implementation and dossier-type candidates;
- high-level path, empty/zero-byte and structure indicators permitted at Pre-Sales depth.

### 4.3 Direct-copy evidence

Archive, index, database, database backup or equivalent direct-copy evidence shall be supplied either as:

- a path from which aggregate size is calculated; or
- a customer-provided aggregate size.

The result and report retain only:

- EvidenceId
- SourceType
- SourceReference
- Accessible
- SizeBytes / displayed size
- ValueSource
- IncludedInScope
- EvaluationStatus
- RAG
- ReviewRequired
- Comments

They shall not retain individual archive/database files, file counts, folder counts, extension summaries, long-path counts, largest-file details or zero-byte inventories.

Additional/staging storage is not requested in customer Pre-Sales unless a later approved assessment mode explicitly requires it.

Missing evidence must remain `NotAssessed`/`Unknown`; it must not be converted to zero, Green or Pass.

## 5. Final workbook composition

The controlled Pre-Sales workbook contains exactly four business-report sheets in this order:

1. `01_Executive_Estimate`
2. `02_Dossier_Inventory`
3. `03_Sequence_Inventory`
4. `04_Path_&_Volume_Inventory`

A separate timestamped UTF-8 execution log is mandatory and is not an Excel worksheet.

The template version aligned to this requirement is `1.2.0`. The technical report-template map version is `2.0.0`.

## 6. Core semantic separation

The following concepts remain separate throughout observation, normalized results, mapping and reports:

| Concept | Meaning |
|---|---|
| EvaluationStatus | Whether and how an evaluation completed |
| RAG | Evidence quality/completeness for the Pre-Sales conclusion |
| MigrationMethod | How the entity is expected to be migrated |
| EffortImpact | How the entity contributes to technical workload |
| Confidence | Reliability of an observed or calculated conclusion |
| ValueSource | Observed, CustomerProvided, Imported, Derived or Assumed provenance |
| ReviewRequired | Whether qualified review is required |

A Green dossier or sequence may still require individual import and create high effort. Migration method and effort shall not be inferred directly from RAG.

## 7. Sheet 01 — `01_Executive_Estimate`

The executive sheet shall provide a two-minute decision-oriented view containing:

### 7.1 Assessment context

- customer/project/reference/date/status;
- assessment mode and execution profile;
- current source application/version/hotfix;
- target application/version/hotfix, blank during customer collection;
- EXTEDO review status.

### 7.2 Recommended migration approach

After EXTEDO review:

- RecommendedMigrationScenario
- ScenarioConfidence
- ScenarioRationale
- AlternativeScenario where applicable
- MigrationWorkstreams
- UpgradeRequired / UpgradePathSummary / UpgradeHopCount
- DatabaseMigrationRequired
- ArchiveMigrationRequired
- ExportImportRequired
- FormatConversionRequired
- RecommendedMigrationWaves
- RecommendedNextStep

Approved customer-facing sequential-upgrade terminology is exactly:

- `Migration and eCTDmanager Sequential Upgrade`
- `Migration and eSUBmanager Sequential Upgrade`

Labels and rationale are configuration-driven and are not hardcoded in PowerShell.

### 7.3 Scope and workload

At minimum, where applicable:

- TotalDossiers
- TotalSequences
- TotalFiles for export evidence
- ExportSize
- ArchiveSize
- IndexSize
- DatabaseSize
- UniqueTransferVolume
- dossier and sequence RAG populations
- batch-eligible, individual-import, conversion, excluded and unclassified populations
- UpgradeHopCount

### 7.4 Effort presentation

The internal estimation profile supports:

- OverallComplexity
- MinimumEffortDays
- MostLikelyEffortDays
- MaximumEffortDays
- Contingency
- EstimateConfidence
- PrimaryEffortDrivers
- EstimateLimitations
- EstimateStatus
- EstimationOwner / ReviewDate

The customer profile may show scope, workload, complexity, confidence and non-confidential drivers. Confidential productivity rates are excluded from the customer runtime package and cannot be protected merely by hidden cells.

### 7.5 Decisions and clarifications

A concise table shall include priority, area, required decision/clarification, reason, estimate effect, requested party, before-quotation flag, owner, target date, status and note.

## 8. Sheet 02 — `02_Dossier_Inventory`

One row per discovered dossier when export evidence is in scope. It shall include:

- stable DossierId, product, display name and path;
- current source application/version;
- normalized region/authority/technical-standard/regional-implementation/type dimensions;
- evidence, rule IDs, confidence, EvaluationStatus and ValueSource;
- sequence/file/folder counts and size for export evidence;
- DossierRAG and PrimaryRAGReason;
- review requirement and review reason;
- migration workstream/method, batch eligibility, individual-import/conversion and upgrade dependency after EXTEDO review;
- qualitative and internal effort contribution fields controlled by execution profile;
- recommended action and comments.

For modes without export discovery, the sheet remains structurally present and contains a controlled Not Applicable indication rather than fabricated rows.

## 9. Sheet 03 — `03_Sequence_Inventory`

One row per discovered sequence when export evidence is in scope. It shall include stable IDs, dossier linkage, classification, size/file/folder counts, high-level backbone/checksum indicators, EvaluationStatus, RAG and reason, confidence/provenance/review fields and target-dependent migration planning after EXTEDO review.

Pre-Sales does not require deep XML schema validation, complete referenced-file validation, mandatory checksum validation or regulatory validation.

For modes without export discovery, the sheet remains structurally present with a controlled Not Applicable indication.

## 10. Sheet 04 — `04_Path_&_Volume_Inventory`

This sheet contains two controlled tables.

### 10.1 Detailed export evidence

`tblPreSalesExportEvidence` includes export root, accessibility, aggregate size, file/folder/dossier/sequence counts, high-level path indicators, EvaluationStatus, RAG, reason, provenance, review requirement and comments.

### 10.2 Aggregate direct-copy evidence

`tblPreSalesDirectCopyEvidence` includes source type/reference, accessibility, aggregate size, ValueSource, scope flag, EvaluationStatus, RAG, review requirement and comments only.

## 11. Normalized result contract

The customer-collection result contains, at minimum:

- phaseCode / execution / executionProfile;
- assessmentMode;
- assessmentContext;
- currentSystem;
- targetPlanning with blank target fields and `Pending EXTEDO Review`;
- exportEvidence;
- directCopyEvidence;
- dossierInventory;
- sequenceInventory;
- collectionSummary;
- migrationScenarioDecision and effortEstimate pending or completed according to profile;
- runtime/template identity and review status.

The result schema aligned to this requirement is `config/result-schemas/report-redesign-v3.2/pre-sales.result.schema.json`.

## 12. Package boundary

The customer package contains only the Pre-Sales entry script/launcher, required Windows PowerShell 5.1-compatible engine modules, customer-safe controlled runtime JSON and checksum, Pre-Sales template, Pre-Sales template map, concise instructions and output location.

It excludes the internal mapping XLSM, VBA, internal productivity rates, Pre-Migration/Post-Migration scripts or interfaces, internal tests, governance records and confidential assets.

## 13. Outputs

A successful customer collection creates:

- phase-specific XLSX report when report generation is enabled;
- normalized result JSON for EXTEDO review;
- detailed timestamped UTF-8 execution log;
- optional manifest/checksum evidence according to package configuration.

Completion output clearly identifies the files that must be shared with EXTEDO.

## 14. Acceptance criteria

The phase conforms when:

1. only current-system information is mandatory for the customer;
2. target fields remain blank/Pending EXTEDO Review during customer collection;
3. mode selection requests only applicable evidence;
4. detailed discovery is limited to export evidence;
5. direct-copy evidence retains aggregate size and provenance only;
6. missing evidence is not converted to zero or Green;
7. source evidence remains read-only;
8. the workbook contains the exact four-sheet order;
9. dossier/sequence sheets are Not Applicable when export discovery is out of scope;
10. RAG, EvaluationStatus, method, effort, confidence and provenance remain separate;
11. confidential estimation baselines are absent from the customer package;
12. output names contain no internal Confluence IDs or embedded component versions;
13. one timestamped log is produced separately;
14. the workbook opens without structural repair;
15. the result JSON validates against the aligned normalized result schema.
