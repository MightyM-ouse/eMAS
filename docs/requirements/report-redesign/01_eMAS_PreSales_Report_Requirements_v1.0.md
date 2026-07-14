# eMAS Pre-Sales Report Requirements

**Document version:** 1.0  
**Status:** Finalized Working Requirement  
**Phase code:** `PRE_SALES`  
**Branch:** `requirements/report-redesign-v3.2`  
**Owner:** Product Owner  
**Implementation state:** Requirements frozen; template and JSON changes pending  

## 1. Purpose

The Pre-Sales report shall convert observed migration evidence into a concise and defensible migration-estimation output. It shall answer:

1. Which migration scenario and workstreams are recommended?
2. What is the migration scope and workload?
3. What is the estimated technical effort range?
4. Which dossiers and sequences can use batch import, require individual import, require conversion or depend on application upgrade/database migration activities?
5. What is the confidence in the estimate?
6. Which decisions or clarifications are required before quotation?

The report is an estimation and scoping output. It is not a Pre-Migration readiness decision, migration validation result, regulatory validation result, customer acceptance record or migration execution record.

## 2. Final workbook composition

The final Pre-Sales workbook shall contain exactly four business-report sheets in this order:

1. `01_Executive_Estimate`
2. `02_Dossier_Inventory`
3. `03_Sequence_Inventory`
4. `04_Path_&_Volume_Inventory`

A separate timestamped UTF-8 execution log shall be created for every execution. The log is not an Excel worksheet.

The following previous standalone sheets are removed from the final Pre-Sales design:

- Effort and Recommendations
- Data Quality Findings
- Rules and Scoring
- Raw Inventory

Their required information is redistributed into the executive estimate, dossier inventory, sequence inventory, path/volume inventory, controlled runtime configuration and execution log.

## 3. Core semantic separation

The following concepts shall remain separate throughout the JSON result object, template mapping and workbook:

| Concept | Meaning |
|---|---|
| Evaluation Status | Whether and how an evaluation completed |
| RAG | Quality, completeness or assessment condition for the entity in the Pre-Sales phase |
| Migration Method | How the entity is expected to be migrated |
| Effort Impact | How the entity affects estimated work |
| Confidence | Reliability of the observed or calculated conclusion |
| Value Source | Observed, CustomerProvided, Imported, Derived or Assumed provenance |
| Review Required | Whether qualified review is required |

A valid Green dossier or sequence may still require individual import and may therefore have a high effort impact. Individual import shall not automatically set Amber or Red.

## 4. Sheet 01 — `01_Executive_Estimate`

### 4.1 Purpose

This sheet shall allow a Pre-Sales consultant, migration lead or project manager to understand the proposed migration within approximately two minutes. It shall contain the decision-oriented summary and shall not be overloaded with raw paths, rule-level evidence or technical execution metadata.

### 4.2 Section A — Assessment context

Required fields:

| Field | Requirement |
|---|---|
| CustomerName | Customer or prospective customer name |
| ProjectName | Project, opportunity or assessment name |
| AssessmentReference | Stable customer-safe reference |
| AssessmentDate | Generated date/time |
| AssessmentStatus | Draft, Reviewed or Superseded |
| SourceApplication | eCTDmanager, eSUBmanager, external system or controlled Unknown value |
| SourceApplicationVersion | Current source application version |
| SourceApplicationHotfix | Current source hotfix where applicable |
| TargetApplication | Planned target application |
| TargetApplicationVersion | Planned target application version |
| TargetApplicationHotfix | Planned target hotfix where applicable |

### 4.3 Section B — Recommended migration approach

Required fields:

| Field | Requirement |
|---|---|
| RecommendedMigrationScenario | Configuration-derived customer-facing scenario name |
| ScenarioConfidence | High, Medium, Low or Unknown |
| ScenarioRationale | Concise evidence-based reason for the selected scenario |
| AlternativeScenario | Alternative scenario when evidence is incomplete or conflicting |
| MigrationWorkstreams | Ordered list of required workstreams |
| UpgradeRequired | Yes, No or Unknown |
| UpgradePathSummary | Ordered source-to-target upgrade path where applicable |
| UpgradeHopCount | Number of required sequential upgrade stages |
| DatabaseMigrationRequired | Yes, No or Unknown |
| ArchiveMigrationRequired | Yes, No or Unknown |
| ExportImportRequired | Yes, No or Partial |
| FormatConversionRequired | Yes, No or Partial |
| RecommendedMigrationWaves | Recommended grouping or number of migration waves |
| RecommendedNextStep | Next action after Pre-Sales review |

### 4.4 Approved scenario terminology

The customer-facing scenario for an eCTDmanager migration that also requires sequential upgrade shall be exactly:

`Migration and eCTDmanager Sequential Upgrade`

The equivalent eSUBmanager scenario shall be:

`Migration and eSUBmanager Sequential Upgrade`

The previously proposed wording `eCTDmanager Sequential Upgrade and Migration` is not approved.

The configuration may support additional controlled scenarios, including:

- eCTDmanager Database and Archive Migration
- eSUBmanager Migration
- External Dossier Import
- Hybrid Migration
- Archive-Only Migration
- Conversion and Import
- Assessment Incomplete
- Scenario Not Determined

Customer-facing labels, codes, applicability rules and rationale wording shall be maintained in controlled configuration and shall not be hardcoded in PowerShell.

### 4.5 Migration scenario and workstreams

The report shall distinguish the overall scenario from its workstreams.

Example:

```text
Recommended Scenario:
Migration and eCTDmanager Sequential Upgrade

Required Workstreams:
1. Sequential eCTDmanager upgrade
2. MS SQL database migration
3. Archive and index migration
4. EU batch dossier import
5. Non-EU individual sequence import
6. Legacy format conversion and import
```

The workstream list shall be derived from configuration rules and observed evidence.

### 4.6 Section C — Scope and workload

The sheet shall show, at minimum:

| Metric | Unit |
|---|---|
| TotalDossiers | Count |
| TotalSequences | Count |
| TotalFiles | Count |
| ExportSize | GB/TB |
| ArchiveSize | GB/TB |
| SourceSize | GB/TB |
| DatabaseSize | GB/TB |
| UniqueTransferVolume | GB/TB |
| GreenDossiers | Count |
| AmberDossiers | Count |
| RedDossiers | Count |
| UnknownDossiers | Count |
| GreenSequences | Count |
| AmberSequences | Count |
| RedSequences | Count |
| UnknownSequences | Count |
| BatchEligibleDossiers | Count |
| BatchEligibleSequences | Count |
| IndividualImportDossiers | Count |
| IndividualImportSequences | Count |
| ConversionRequiredDossiers | Count |
| ConversionRequiredSequences | Count |
| ExcludedDossiers | Count |
| UnclassifiedDossiers | Count |
| UpgradeHopCount | Count |

Where a metric cannot be assessed, the report shall show the configured NotAssessed/Unknown presentation rather than zero, Green or Pass.

### 4.7 Section D — Executive effort presentation

The executive summary shall support the following presentation pattern:

```text
Estimated Technical Effort: 32–45 person-days
Most Likely Estimate: 38 person-days
Estimate Confidence: Medium

Primary Drivers:
- 164 sequences require individual import
- 79 sequences are batch eligible
- 2 dossiers require format conversion
- 3 sequential application upgrade steps
- 437 GB estimated unique transfer volume
```

Required fields:

| Field | Requirement |
|---|---|
| OverallComplexity | Very Low, Low, Medium, High or Very High |
| MinimumEffortDays | Minimum technical estimate |
| MostLikelyEffortDays | Most likely technical estimate |
| MaximumEffortDays | Maximum technical estimate |
| Contingency | Percentage or person-days according to configuration |
| EstimateConfidence | High, Medium, Low or Unknown |
| PrimaryEffortDrivers | Ordered top configured drivers |
| EstimateLimitations | Missing evidence, assumptions or exclusions affecting confidence |
| EstimateStatus | Preliminary, Conditional, Ready for Internal Review or Ready for Quotation |
| EstimationOwner | Responsible role or person where internally populated |
| ReviewDate | Internal review date where applicable |

The wording, layout labels, driver count, number formatting, unit formatting and narrative templates shall be controlled by configuration mapping.

### 4.8 Confidential estimation profile

The design shall support separate configuration/export profiles:

1. **Customer Assessment Profile** — scope, workload, scenario, complexity, confidence and non-confidential drivers.
2. **Internal Estimation Profile** — approved productivity baselines, effort components, person-day range and internal estimation notes.

Confidential productivity rates shall not be exposed in the customer package merely by hiding workbook cells or sheets.

The same four-sheet structural design may be used by both profiles, but profile-controlled fields may remain NotAssessed or omitted from the customer-facing execution where approved.

### 4.9 Section E — Required decisions and clarifications

The executive sheet shall include a concise decision/clarification table with these columns:

- Priority
- Area
- DecisionOrClarificationRequired
- Reason
- EffectOnEstimate
- RequiredFrom
- RequiredBeforeQuotation
- Owner
- TargetDate
- Status
- Note

The table shall prioritize only commercially or technically meaningful items. Detailed findings remain in the dossier, sequence or path rows through primary reason, review and recommended-action fields.

### 4.10 Information excluded from the executive sheet

The following shall not be presented as primary executive content:

- full physical paths;
- detailed rule IDs;
- complete finding IDs;
- individual sequence rows;
- file-extension detail;
- full XML/checksum evidence;
- machine name;
- PowerShell version;
- runtime JSON checksum;
- raw numeric scoring weights;
- raw inventory.

These remain available in detailed sheets or the execution log where required.

## 5. Sheet 02 — `02_Dossier_Inventory`

### 5.1 Purpose

Provide one row per dossier with classification, volume, Pre-Sales RAG, migration method, batch/individual/conversion handling and effort contribution.

### 5.2 Required column groups

#### Identification and source

- DossierId
- Product
- DossierName
- DossierPath
- SourceApplication
- SourceApplicationVersion

#### Classification

- Region
- RegionEvidence
- RegionRuleIds
- Authority
- TechnicalStandard
- FormatEvidence
- FormatRuleIds
- RegionalImplementation
- DossierType
- TypeEvidence
- TypeRuleIds
- ClassificationConfidence
- eCTDv4Indicator
- EvaluationStatus
- ValueSource

Classification dimensions shall remain normalized. Technical standard/format and regional implementation shall not be collapsed into one ambiguous value.

Examples of TechnicalStandard/format values include:

- ICH eCTD 3.2.2
- eCTD 4.0
- NeeS
- VNeeS
- Unknown

Paper/scanned packaging, when describing evidence form rather than technical standard, shall remain SourcePresentation rather than TechnicalStandard.

Examples of RegionalImplementation include:

- EU eCTD Module 1
- US FDA Module 1
- UK Module 1
- Canada Module 1

#### Volume

- SequenceCount
- SizeBytes
- DisplaySizeGB
- FileCount
- FolderCount

#### Assessment

- DossierRAG
- PrimaryRAGReason
- RAGRuleIds
- FindingCount
- ManualReviewRequired
- ReviewReason

#### Migration planning

- MigrationWorkstream
- MigrationMethod
- BatchEligible
- IndividualImportRequired
- ConversionRequired
- UpgradeDependency
- EffortUnit
- EffortImpact
- MinimumEffortDays
- MostLikelyEffortDays
- MaximumEffortDays
- RecommendedAction
- Comments

### 5.3 Controlled migration-method values

The controlled configuration shall support, at minimum:

- Database and Archive Migration
- Batch Dossier Import
- Individual Sequence Import
- Conversion and Import
- Migration and eCTDmanager Sequential Upgrade
- Migration and eSUBmanager Sequential Upgrade
- Manual Technical Review
- Excluded from Scope
- Migration Method Not Determined

Migration-method applicability shall be configuration-driven by evidence such as region, technical standard, regional implementation, source application/version, target application/version and dossier/sequence structure.

### 5.4 Dossier RAG meaning for Pre-Sales

- **Green:** sufficient evidence exists to identify a supported migration method and estimate normally.
- **Amber:** the dossier is estimable but conversion, individual handling, upgrade dependency or clarification increases effort or reduces confidence.
- **Red:** unsupported, materially incomplete or unclassified evidence prevents a reliable dossier estimate.
- **Unknown:** insufficient or conflicting evidence prevents classification.

RAG reason shall be concise, evidence-based and traceable to configuration.

## 6. Sheet 03 — `03_Sequence_Inventory`

### 6.1 Purpose

Provide one row per sequence/submission with classification, volume, high-level structural indicators, Pre-Sales RAG, migration method and effort contribution.

### 6.2 Required columns

#### Identification and classification

- Product
- DossierId
- DossierName
- SequenceId
- SequenceDisplayName
- SequencePath
- Region
- Authority
- TechnicalStandard
- RegionalImplementation
- DossierType
- ClassificationConfidence
- EvaluationStatus
- ValueSource

#### Volume

- SizeBytes
- DisplaySizeMB
- FileCount
- FolderCount

#### Proportionate structural indicators

- IndexXmlPresent
- IndexMd5Present
- Module1Present
- Module2Present
- Module3Present
- Module4Present
- Module5Present
- RegionalXmlPresent
- MissingExpectedItems
- DuplicateIndicator
- EmptySequenceIndicator

Pre-Sales processing shall remain proportionate. These are presence/shape indicators for scoping and estimation and shall not convert the phase into detailed readiness or regulatory validation.

#### Assessment

- SequenceRAG
- PrimaryRAGReason
- RAGRuleIds
- ManualReviewRequired
- ReviewReason

#### Migration planning

- MigrationWorkstream
- MigrationMethod
- BatchEligible
- IndividualImportRequired
- ConversionRequired
- EffortUnit
- EffortImpact
- MinimumEffortDays
- MostLikelyEffortDays
- MaximumEffortDays
- RecommendedAction
- Comments

### 6.3 Example interpretation

| Region | Technical standard | RAG | Migration method |
|---|---|---|---|
| EU | ICH eCTD 3.2.2 | Green | Batch Dossier Import |
| US | ICH eCTD 3.2.2 | Green | Individual Sequence Import |
| EU | NeeS | Amber | Conversion and Import |
| Unknown | Unknown | Red/Unknown according to rule | Manual Technical Review |

This table is illustrative only. Final eligibility shall be determined from approved configuration, not hardcoded assumptions.

## 7. Sheet 04 — `04_Path_&_Volume_Inventory`

### 7.1 Purpose

Provide a traceable inventory of export, source, archive, index, database, storage and staging volumes used to determine migration scope, transfer workload and infrastructure effort.

### 7.2 Required columns

- SourceType
- SourceName
- RootPathOrReference
- SourceApplication
- SourceVersion
- Accessible
- ValueSource
- EvaluationStatus
- TotalSizeBytes
- DisplayTotalSizeGB
- IncludedInMigrationScope
- OverlapGroup
- UniqueSizeBytes
- DisplayUniqueSizeGB
- FileCount
- FolderCount
- LargestFolder
- LargestFile
- LongPathRisk
- SpecialCharacterRisk
- AccessIssueCount
- PathRAG
- PrimaryRAGReason
- TransferMethod
- TransferEffortImpact
- RecommendedAction
- Comments

### 7.3 Required source types

The controlled source-type list shall support, at minimum:

- Dossier Export / Publishing
- Source / Application Data
- Archive
- Index
- Repository
- Database Data File
- Database Log File
- Database Backup
- Storage
- Migration Staging
- Other Source

### 7.4 Size definitions

The report and configuration shall distinguish:

- **Export Size:** exported dossier/package roots.
- **Archive Size:** archive and index roots.
- **Source Size:** additional source/application content selected for migration.
- **Database Data Size:** database data files or approved customer-provided value.
- **Database Log Size:** database log files where relevant.
- **Database Backup Size:** database backup package size.
- **Unique Transfer Volume:** included non-overlapping transfer scope after overlap treatment.

### 7.5 Unique transfer volume

The report shall not add all observed path sizes blindly. Overlapping/nested roots and duplicate package presentations may otherwise double count transfer scope.

The calculation shall use:

```text
Unique Transfer Volume =
Sum of included source volumes after approved overlap treatment
```

The `IncludedInMigrationScope`, `OverlapGroup` and `UniqueSize` fields shall provide traceability for the value.

## 8. Configuration-mapping requirements

### 8.1 General rule

PowerShell shall perform generic discovery, counting, size calculation, version comparison and report population. Business interpretation, customer-facing labels and estimation logic shall be controlled through the approved runtime configuration.

### 8.2 Scenario configuration

Configuration shall define:

- ScenarioCode
- CustomerFacingScenarioName
- ScenarioDescription
- DetectionConditions
- Priority
- ConfidenceRules
- AlternativeScenario
- ApplicableSourceApplications
- ApplicableTargetApplications
- SourceVersionConditions
- TargetVersionConditions
- RequiredWorkstreams
- RecommendedNextStep
- CustomerFacingRationaleTemplate

Example:

```text
ScenarioCode: EMAS-SCN-ECTDMGR-UPGRADE-MIGRATION
CustomerFacingScenarioName: Migration and eCTDmanager Sequential Upgrade
```

### 8.3 Upgrade-path configuration

For eCTDmanager and eSUBmanager, configuration shall support:

- product/application code;
- source version/hotfix;
- target version/hotfix;
- supported direct-upgrade indicator;
- required intermediate versions;
- ordered upgrade hops;
- database conversion or upgrade dependency;
- archive/index compatibility consideration;
- minimum supported engine/configuration version;
- rationale and recommendation wording.

Upgrade paths shall not be hardcoded in report scripts.

### 8.4 Executive presentation configuration

Configuration shall define:

- metric label;
- metric order;
- display/omit behavior;
- number and unit formatting;
- narrative template;
- top-driver count;
- effort-range wording;
- quotation-blocking logic;
- scenario rationale text;
- recommendation wording;
- profile visibility.

### 8.5 Effort configuration

Configuration shall support:

- DriverCode
- DriverName
- ApplicablePhase
- ApplicableScenario
- ApplicableMigrationMethod
- Unit
- LowerBound
- UpperBound
- Inclusivity flags
- BaseEffort
- PerUnitEffort
- MinimumEffort
- MaximumEffort or cap where approved
- MinimumBandOverride
- ConfidenceImpact
- ContingencyRule
- CustomerFacingExplanation
- ConsultantFacingExplanation
- ProfileVisibility

Example calculation:

```text
Driver: Individual Sequence Import
Unit: Sequence
Observed Quantity: 164
Configured Productivity: 0.12 person-days per sequence
Calculated Effort: 19.68 person-days
```

Exact values are illustrative and shall not become Effective without approved owner/SME evidence.

### 8.6 Effort calculation structure

The design shall support:

```text
Estimated Technical Effort =
    Base Project Effort
  + Environment and Setup Effort
  + Upgrade Effort
  + Database Migration Effort
  + Archive and Source Transfer Effort
  + Batch Import Effort
  + Individual Import Effort
  + Conversion Effort
  + Remediation/Review Allowance
  + Verification Preparation Effort
  + Configured Contingency
```

Rules shall prevent unintended double counting of the same migration unit.

## 9. Result-object and JSON implications

Template and JSON implementation shall introduce or extend normalized collections sufficient to populate the four sheets, including:

- assessmentContext
- migrationScenarioDecision
- migrationWorkstreams
- executiveMetrics
- effortEstimate
- effortComponents
- decisionClarifications
- dossierInventory
- sequenceInventory
- pathVolumeInventory
- executionDetails/log metadata

Representative new fields include:

- recommendedMigrationScenario
- scenarioConfidence
- scenarioRationale
- alternativeScenario
- migrationMethod
- batchEligible
- individualImportRequired
- conversionRequired
- upgradeRequired
- upgradePathSummary
- upgradeHopCount
- effortUnit
- minimumEffortDays
- mostLikelyEffortDays
- maximumEffortDays
- estimateConfidence
- primaryRagReason
- uniqueTransferVolume
- overlapGroup
- includedInMigrationScope

The final schema and template-map changes shall be designed only after Pre-Migration and Post-Migration report requirements are also reviewed for shared-field consistency.

## 10. Reporting and usability requirements

- The executive sheet shall be suitable for direct Pre-Sales and internal quotation discussion.
- Detailed sheets shall use filters, frozen headers and readable units.
- Long text shall wrap without making the workbook unusable.
- RAG formatting shall be consistent and accessible.
- Generated cells shall be protected according to template policy.
- Internal review/note fields may be editable only where explicitly approved.
- Report filenames shall not contain internal Confluence IDs or embedded component versions.
- The workbook shall open without a repair prompt.
- The workbook shall not require Microsoft Excel to be installed during script execution.
- The execution log shall preserve full technical traceability that is intentionally omitted from the executive sheet.

## 11. Pre-Sales phase boundaries

The report shall not:

- produce Ready, Blocked, Reconciled or acceptance wording;
- claim regulatory validation;
- perform migration/import;
- modify source evidence;
- require mandatory deep referenced-file or checksum validation;
- expose confidential estimation rates in the customer profile;
- treat missing evidence as Green or zero;
- silently force unknown/conflicting classification into a known result.

## 12. Acceptance criteria

The Pre-Sales report requirement is satisfied when:

1. the workbook contains the four approved sheets in the approved order;
2. Sheet 01 identifies a configuration-derived recommended migration scenario and workstreams;
3. the exact approved label `Migration and eCTDmanager Sequential Upgrade` is used where applicable;
4. the executive sheet presents effort range, most likely effort, confidence and top drivers where the active profile permits it;
5. dossier and sequence sheets distinguish RAG, migration method and effort impact;
6. dossier rows include normalized classification, volume, primary RAG reason and migration planning;
7. sequence rows include volume, proportionate structure indicators, primary RAG reason and migration planning;
8. path/volume rows distinguish source types, total size, included scope, overlap and unique transfer size;
9. executive wording and estimation behavior are controlled through configuration mapping;
10. confidential productivity baselines are not exposed in the customer profile;
11. missing evidence is represented as Unknown/NotAssessed according to controlled terminology;
12. the workbook remains an estimation report and makes no readiness, validation or acceptance claim;
13. a timestamped execution log is created separately;
14. template, JSON, demo data and implementation tests are updated only after controlled design approval.

## 13. Implementation hold point

This document freezes the Pre-Sales report requirement only. Do not yet replace the controlled Pre-Sales template or report mapping in isolation.

The next steps are:

1. finalize Pre-Migration report requirements;
2. finalize Post-Migration report requirements;
3. reconcile shared fields and terminology across all three phases;
4. approve Enterprise Requirements v3.2 and revised phase contracts;
5. create the controlled templates, template-map JSON, result schemas, demo inputs and automated tests.
