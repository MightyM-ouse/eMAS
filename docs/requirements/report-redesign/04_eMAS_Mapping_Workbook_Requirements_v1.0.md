# eMAS Simple Mapping Workbook Requirements

**Document version:** 1.0  
**Status:** Draft Implementation Baseline  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Applies to:** Pre-Sales, Pre-Migration and Post-Migration  
**Implementation state:** Workbook and draft runtime JSON created; validation, SME calibration and controlled release pending

## 1. Purpose

The eMAS mapping workbook shall be the internal source of truth for business interpretation. PowerShell may perform generic technical discovery and comparison, but it shall not hardcode region, format, migration method, readiness, reconciliation, effort or report-presentation decisions.

The workbook shall remain simple for business maintenance:

- one focused sheet per use case;
- one row per rule or configuration item;
- stable IDs for all rules, findings, actions and effort drivers;
- dropdown-controlled values where practical;
- a single export map producing one shared runtime JSON for all three phases;
- no duplicate parallel rule models.

The internal workbook is not distributed to customers. Customer-executed packages receive only the approved runtime JSON and controlled report templates.

## 2. Workbook composition

The mapping workbook contains the following sheets:

1. `00_Control`
2. `01_Config`
3. `02_Folder_Structure`
4. `03_Regions`
5. `04_Formats`
6. `05_Dossier_Types`
7. `06_Migration_Scenarios`
8. `07_Migration_Methods`
9. `08_Version_Upgrades`
10. `09_Effort_Rules`
11. `10_Readiness_Rules`
12. `11_Reconciliation_Rules`
13. `12_Findings_Actions`
14. `13_Report_Config`
15. `14_Value_Lists`
16. `15_JSON_Export_Map`

The workbook intentionally avoids separate generic rule, condition, output and phase tables. Each use-case sheet contains the columns needed for that use case and is exported to a dedicated JSON section.

## 3. Control and configuration

### 3.1 `00_Control`

The control sheet records:

- mapping ID and version;
- workbook status and owner;
- effective date;
- minimum engine version;
- runtime JSON schema version;
- requirements baseline;
- controlled template versions;
- validation status;
- JSON export status;
- rule counts and target JSON sections.

### 3.2 `01_Config`

The configuration sheet uses `ConfigKey`, `Value`, `DataType`, `Phase`, `Required` and `Description`.

Initial configuration includes path thresholds, sequence-folder regular expression, report-summary limits, size units, effort-profile behavior, contingency, post-migration tolerance, database-evidence requirements, raw-evidence protection and fallback confidence.

## 4. Classification and technical rules

### 4.1 `02_Folder_Structure`

One row represents one folder, file, path, XML, checksum, reference or access use case. Each row defines:

- scope and applicable format/region;
- evidence type and condition expression;
- result Evaluation Status;
- RAG on match and failure;
- blocker effect;
- finding and action codes;
- customer-understandable primary reason.

Initial rules cover mandatory-root access, numeric sequence folders, eCTD 3.x and eCTD 4.0 backbone evidence, checksums, Module 1, unknown folders, zero-byte files, XML readability, long paths, referenced files and empty sequences.

### 4.2 `03_Regions`

Region rules classify region, authority and regional implementation. Structured XML or metadata evidence has precedence over path/name inference. Path-only inference is Medium confidence and requires review. A final Unknown fallback rule is mandatory.

### 4.3 `04_Formats`

Format rules classify eCTD 4.0, eCTD 3.x, VNeeS, NeeS, paper/scanned and Unknown. eCTD 4.0 rules have precedence over legacy eCTD 3.x rules.

### 4.4 `05_Dossier_Types`

Dossier-type rules classify human, veterinary, ASMF, DMF, CEP, clinical-trial and Unknown content. Customer-provided or structured metadata has precedence over naming inference.

## 5. Migration planning and estimation rules

### 5.1 `06_Migration_Scenarios`

Ordered scenario rules select one primary scenario while retaining all applicable workstreams. Initial scenario values include:

- Migration and eCTDmanager Sequential Upgrade;
- Migration and eSUBmanager Sequential Upgrade;
- Hybrid Migration;
- Database and Archive Migration;
- External Dossier Import;
- Conversion and Import;
- Archive-Only Migration;
- Scenario Not Determined.

### 5.2 `07_Migration_Methods`

Migration-method rules determine project, dossier or sequence handling. Initial methods include database/archive migration, batch dossier import, individual sequence import, conversion and import, sequential upgrade and manual technical review.

Migration Method remains independent from RAG. A Green dossier may still require individual import and create material effort.

### 5.3 `08_Version_Upgrades`

This sheet stores reviewed product-version compatibility paths. It shall not invent upgrade paths. The draft contains generic same-version, approved-path and no-path behavior plus one inactive template row. Product-specific rows require approved compatibility evidence.

### 5.4 `09_Effort_Rules`

Effort rules use stable driver codes and configurable units, thresholds, base days, per-unit days, minimums, maximums, contingency and confidence effects.

The draft includes internal baselines for project setup, upgrade hops, database volume, transfer volume, batch dossiers, individual sequences, conversion sequences, remediation, verification and manual review.

All draft productivity values require Product Owner and Migration SME calibration before controlled release. Customer runtime profiles shall not expose confidential productivity rates or person-day formulas.

## 6. Readiness and reconciliation rules

### 6.1 `10_Readiness_Rules`

Rules determine Ready, Ready with Accepted Exceptions or Blocked from detailed evidence. Initial use cases cover mandatory access, missing/unreadable backbone XML, missing references, checksum gaps, long paths, zero-byte files, backup evidence, staging capacity and valid accepted exceptions.

Evaluation Status, RAG, Blocker and Readiness Effect remain separate fields.

### 6.2 `11_Reconciliation_Rules`

Rules compare the approved Pre-Migration baseline with import report, target database and post-import evidence. Initial use cases cover exact match, tolerance match, accepted difference, missing expected dossier/sequence, unexpected items, failed/warning imports, missing database evidence, missing mandatory evidence and file-type differences.

Reconciliation Status, RAG, Blocker and exception treatment remain separate fields.

## 7. Reusable wording and report presentation

### 7.1 `12_Findings_Actions`

This sheet maintains customer-facing finding text, consultant-facing notes, action text, severity, default RAG, default owner and executive-summary inclusion. Rule sheets reference stable finding and action codes instead of duplicating wording.

### 7.2 `13_Report_Config`

This sheet controls executive-summary labels, order, visibility, profile, formatting, source path and narrative template. It supports configuration-driven presentation of:

- recommended scenario;
- effort range and most-likely estimate;
- estimate confidence and primary drivers;
- readiness result and RAG totals;
- baseline integrity;
- verification result;
- dossier, sequence, import and database reconciliation totals.

PowerShell shall not hardcode executive labels or narrative wording that is maintained in this sheet.

### 7.3 `14_Value_Lists`

This sheet stores controlled dropdown values for phase, RAG, confidence, Evaluation Status, readiness result, verification result, reconciliation status, migration method, region, format and reviewer disposition.

## 8. JSON export

### 8.1 `15_JSON_Export_Map`

The export map defines source sheet, source table, JSON path, export mode, key field and required status.

One shared runtime JSON shall contain:

- global configuration;
- folder-structure rules;
- region, format and dossier-type rules;
- migration scenarios and methods;
- version upgrade paths;
- effort rules;
- readiness rules;
- reconciliation rules;
- findings and actions;
- report presentation configuration;
- controlled value lists.

Only `Active=Yes` rows are exported where an Active column exists. Configuration values are converted according to `DataType`.

## 9. Validation requirements

Before JSON release, validation shall confirm:

- required sheets and columns exist;
- rule IDs and driver codes are unique;
- priorities are valid and fallback rules are last;
- referenced finding and action codes exist;
- controlled values are valid;
- no active version-upgrade template row remains;
- no product-specific upgrade path lacks approval evidence;
- effort values are approved and profile restrictions are enforced;
- JSON export paths are unique and complete;
- all three report requirements can be populated from the resulting runtime object.

## 10. Current draft limitations

The workbook and JSON created from this requirement are implementation drafts. They do not supersede the effective mapping/runtime configuration.

The following require formal review before release:

- product-specific version upgrade paths;
- target-version batch-import capabilities;
- region and format detection tokens;
- confidential productivity rates and thresholds;
- readiness exception policies;
- reconciliation tolerances and severity overrides;
- final template and schema version identifiers.
