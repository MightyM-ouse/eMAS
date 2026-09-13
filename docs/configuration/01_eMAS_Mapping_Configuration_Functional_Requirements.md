# eMAS Mapping Workbook and Scenario JSON MVP Requirements

**Project:** eMAS - eCTD Migration Assessment Script
**Document type:** Detailed Mapping Workbook and Runtime JSON requirements
**Version:** 4.2 MVP
**Status:** Approved MVP design baseline; implementation and verification pending
**Scope:** One human-readable master workbook and deterministic scenario-specific Runtime JSON
**Classification:** Internal
**Prepared:** 13 September 2026
**Parent requirement:** eMAS Enterprise Requirements v5.0
**Decision references:** DEC-2026-013 and DEC-2026-014

## 1. Purpose and MVP decision

This document defines the immediate eMAS MVP. The MVP shall prove two working capabilities before SharePoint integration, formal configuration release workflow, or GxP-oriented controls are implemented:

1. one Mapping Workbook contains all configurable requirements needed by the eMAS migration assessment scripts and is understandable, filterable, and maintainable without reading PowerShell code; and
2. the workbook can be transformed deterministically into Runtime JSON for a selected migration scenario.

The workbook is the human-maintained source for migration assessment meaning. The scenario-specific JSON is the machine-readable source consumed by the runtime. PowerShell shall not read the workbook and shall not generate or repair the configuration JSON.

The MVP is successful only when a reviewer can select a scenario, see every applicable requirement and relationship in Excel, generate the corresponding JSON, and trace each JSON object back to its workbook record.

## 2. MVP boundary

### 2.1 Included in the MVP

| Area | MVP requirement |
|---|---|
| Workbook | One macro-free `.xlsx` master workbook with named sheets and filterable Excel Tables |
| Content | Migration scenarios, assessment modules, evidence fields, regulatory profiles, rule catalogues, findings, actions, RAG, confidence, effort, readiness, reconciliation, sources, and JSON mapping |
| Human use | Plain-language descriptions, controlled values, source-verification details, examples, filters, freeze panes, and navigation |
| Scenario selection | Questionnaire/project context derives one base `ScenarioId`, which is confirmed for each JSON generation |
| JSON generation | Deterministic transformation of active applicable workbook records into one scenario-specific JSON file |
| JSON scope | All applicable Pre-Sales, Pre-Migration, and Post-Migration configuration for the selected scenario |
| Validation | Workbook structure, types, identifiers, references, applicability, rule conditions, and JSON completeness |
| Traceability | Requirement -> module -> rule -> finding/action -> JSON path -> engine capability |
| Runtime boundary | Generic PowerShell operations consume JSON and customer/project evidence offline |

### 2.2 Deferred until after the MVP works

The following are intentionally deferred and shall not block MVP acceptance:

- SharePoint hosting, permissions, co-authoring, and version history;
- Office Script deployment in a Microsoft 365 tenant;
- Power Automate approval or release orchestration;
- formal configuration approval, immutable release packaging, electronic signatures, and GxP validation evidence;
- production checksum manifest, release revocation, and controlled promotion workflow;
- final workbook protection, corporate signing, and retention rules;
- production regulatory content approval for every supported region;
- polished dashboards, optional user interfaces, and customer distribution packaging.

These items may be designed later without changing the fundamental Workbook -> Scenario JSON -> PowerShell boundary.

### 2.3 Explicit exclusions

The Mapping Workbook shall not:

- scan customer files, databases, archives, DMS repositories, or XML;
- contain customer-specific answers, paths, credentials, accepted exceptions, or assessment results;
- execute migration, repair source content, or modify evidence;
- contain PowerShell, VBA, JavaScript, SQL, XPath evaluation code, or other executable expressions in cells;
- claim formal regulatory validation, customer acceptance, or validated-system status;
- treat DMS-to-DMS migration as a supported scenario; such a request requires consultant review and separate scope definition;
- define low-level generic operations such as directory enumeration, ZIP extraction, XML parsing, checksum calculation, logging, or OpenXML report writing.

## 3. MVP operating model

```mermaid
flowchart TD
    A["Questionnaire definitions"] --> C["Derive and confirm ScenarioId"]
    B["Project answers and context"] --> C
    C --> D["Resolve modules and rules"]
    D --> E["Validate complete configuration"]
    E --> F["Generate scenario JSON"]
    F --> G["PowerShell assessment runtime"]
```

One master workbook shall support every scenario. Separate workbooks per scenario are prohibited because they create duplicated rules and inconsistent maintenance.

One JSON generation shall use exactly one confirmed `ScenarioId`, derived from questionnaire context or explicitly selected for testing. The generated file shall contain the rules for all phases applicable to that scenario. Phase scripts may consume only their own section, but shall use the same scenario JSON.

## 4. Design principles

| ID | Priority | Requirement |
|---|---|---|
| MVP-GEN-001 | MUST | The workbook shall describe what eMAS assesses and how evidence is interpreted. |
| MVP-GEN-002 | MUST | PowerShell shall implement only generic technical capabilities and phase orchestration. |
| MVP-GEN-003 | MUST | Every executable workbook record shall have a stable identifier. |
| MVP-GEN-004 | MUST | Human-readable labels and explanations shall accompany technical codes. |
| MVP-GEN-005 | MUST | One row shall represent one atomic record or condition. |
| MVP-GEN-006 | MUST | Multi-value logic shall use relationship rows or condition rows, not comma-separated free text. |
| MVP-GEN-007 | MUST | Region, authority, format, specification version, application/pathway, dossier context, procedure, sequence, and lifecycle shall remain separate dimensions. |
| MVP-GEN-008 | MUST | ASMF/DMF shall not be represented as transport formats. |
| MVP-GEN-009 | MUST | IND, NDA, ANDA, BLA, MAA, and CTA shall not be represented as eCTD formats. |
| MVP-GEN-010 | MUST | Folder labels shall not override stronger structured evidence such as XML, database, or controlled metadata. |
| MVP-GEN-011 | MUST | Missing evidence shall not become Green, Pass, Ready, or Reconciled. |
| MVP-GEN-012 | MUST | Severity/RAG and confidence shall remain independent. |
| MVP-GEN-013 | MUST | Findings and recommended actions shall remain separate reusable objects. |
| MVP-GEN-014 | MUST | Regulatory requirements, reviewed interpretations, and eMAS design decisions shall be distinguishable. |
| MVP-GEN-015 | MUST | Every JSON object shall be traceable to workbook rows and every exported workbook rule shall have a defined JSON path. |

## 5. Migration scenario catalogue

The approved MVP catalogue contains eight base migration scenarios. A scenario represents the principal migration route. Hosting, scope, dependencies, upgrade requirements, repository composition, and evidence completeness are separate qualifiers so they do not create an uncontrolled number of scenario combinations.

| ScenarioId | ScenarioCode | Scenario name | Selection basis | Principal focus |
|---|---|---|---|---|
| `MS-01` | `ECTDMGR_SQL_TO_SQL` | eCTDmanager SQL Server to SQL Server | Existing eCTDmanager source with SQL Server database | DB/archive inventory, compatibility, migration population, readiness, and reconciliation |
| `MS-02` | `ECTDMGR_ACCESS_TO_SQL` | eCTDmanager Access to SQL Server | Existing legacy eCTDmanager source with Access database | Legacy extraction, archive correlation, conversion risks, and reconciliation |
| `MS-03` | `ECTDMGR_ORACLE_TO_SQL` | eCTDmanager Oracle to SQL Server | Existing eCTDmanager source with Oracle database | Oracle source mapping, archive correlation, conversion risks, and reconciliation |
| `MS-04` | `REGULATORY_EXPORT_TO_ECTDMGR` | Regulatory Submission Export to eCTDmanager | Source consists primarily of regulatory submission exports | Repository, ZIP, dossier, region, format, sequence, XML, and file assessment |
| `MS-05` | `HYBRID_MIGRATION` | Hybrid Migration | Two or more primary migration inputs are included in the migration population | Combined DB/archive, export, DMS, or mixed-source assessment and reconciliation |
| `MS-06` | `ARCHIVE_STORAGE_ONLY` | Archive or Storage Only | Physical archive/storage is itself the intended migration input rather than merely the only evidence currently available | Archive discovery, identity limitations, counts, size, and reduced confidence |
| `MS-07` | `SCENARIO_PENDING` | Scenario Pending or Incomplete | Available answers cannot reliably identify another scenario | Missing information, follow-up questions, and safe Not Assessed outcomes |
| `MS-08` | `THIRD_PARTY_DMS_TO_ECTDMGR` | Third-Party System or DMS to eCTDmanager | Content and metadata originate from a third-party system or DMS and the supported target is eCTDmanager | Source adapter, metadata, documents, renditions, relationships, and mapping |

The following are qualifiers rather than separate scenarios:

| Qualifier | Values or examples | Effect |
|---|---|---|
| `CustomerRelationship` | Existing, New, Unknown | Supports business context and questionnaire branching |
| `SourceHosting` | OnPremises, Cloud, Hybrid, Unknown | Activates source-access and infrastructure rules |
| `TargetHosting` | OnPremises, Cloud, Hybrid, ToBeDefined | Activates target dependency and readiness rules |
| `MigrationScope` | AllContent, SelectedContent, Mixed, Unknown | Controls inventory, exclusions, and baseline scope |
| `EvidenceCompleteness` | Complete, Partial, Minimal, Unknown | Controls coverage, confidence, and follow-up |
| `RepositoryComposition` | Single, Multiple, Mixed, Unknown | Controls repository discovery depth |
| `ESubmanagerDependency` | Yes, No, Unknown | Activates storage and exported-submission dependency rules |
| `DmsDependency` | Yes, No, Unknown | Activates DMS assessment where it is not already the primary source |
| `OtherIntegrationDependency` | Yes, No, Unknown | Creates dependency clarification and readiness requirements |
| `SequentialUpgradeRequired` | Yes, No, ToBeDetermined | Activates upgrade-path requirements |

Partial evidence does not automatically produce `MS-07`. When the migration route is known, the applicable base scenario remains selected and `EvidenceCompleteness` records the limitation. Mixed repository content remains a qualifier unless it establishes a Hybrid migration or prevents reliable scenario identification.

`MS-08` does not include DMS-to-DMS migration. When the source and intended target are both DMS platforms, or the target platform is another unsupported third-party system, derivation shall return `MS-07` with `NeedsReview`, identify the requested route as outside the current scenario catalogue, and require discussion with an EXTEDO consultant before further assessment.

## 6. Assessment module catalogue

| ModuleId | Module | Main responsibility |
|---|---|---|
| `MOD-SCENARIO` | Migration Scenario | Derive or confirm scenario and evidence availability |
| `MOD-SOURCE` | Source System | Assess source product, version, environment, and dependencies |
| `MOD-DB` | Database | Inventory database records and supported relationships |
| `MOD-ARCHIVE` | Archive | Locate, count, size, and assess physical objects |
| `MOD-DMS` | DMS | Assess external metadata, documents, renditions, and relationships |
| `MOD-REPOSITORY` | Repository Discovery | Discover folders, ZIPs, nested ZIPs, wrappers, and candidate dossier roots |
| `MOD-CLASSIFY` | Regulatory Classification | Determine region, authority, format, version, application, and dossier context |
| `MOD-SEQUENCE` | Sequence and Lifecycle | Inventory sequence/submission units, gaps, duplicates, and lifecycle |
| `MOD-REFERENCE` | XML and Reference Integrity | Assess backbone XML, regional XML, referenced files, and orphan candidates |
| `MOD-FILE` | File and Technical Integrity | Assess readability, zero-byte, extension, PDF, path, and checksum observations |
| `MOD-VOLUME` | Volume and Complexity | Calculate counts, sizes, diversity, and complexity metrics |
| `MOD-MAPPING` | Migration Mapping | Assess source-to-target fields, identifiers, transformations, and comparison keys |
| `MOD-INTERPRET` | RAG Confidence and Effort | Convert observations into severity, confidence, effort, and actions |
| `MOD-READINESS` | Pre-Migration Readiness | Determine Ready, Ready with Accepted Exceptions, or Blocked |
| `MOD-RECONCILE` | Post-Migration Reconciliation | Compare the approved baseline with target/import evidence |

Each scenario shall explicitly map every module to `Required`, `Conditional`, `Optional`, or `NotApplicable`. Absence of a mapping is an error.

## 7. Required workbook structure

The MVP workbook shall contain the following sheets in this order. Sheet names are stable contract values.

| Order | Sheet | Maintained or generated | Purpose |
|---:|---|---|---|
| 0 | `00_Home` | Maintained | Purpose, navigation, glossary, selected scenario, and generation instructions |
| 1 | `01_Migration_Scenarios` | Maintained | Supported base-scenario catalogue and stable scenario identity |
| 2 | `02_Scenario_Questionnaire` | Maintained | Non-technical questions used to identify a scenario and missing information |
| 3 | `03_Scenario_Derivation_Rules` | Maintained | Structured rules that convert questionnaire answers into one base scenario, qualifiers, and follow-up status |
| 4 | `04_Assessment_Modules` | Maintained | Reusable assessment capabilities |
| 5 | `05_Scenario_Module_Map` | Maintained | Required/conditional/optional modules for every scenario |
| 6 | `06_Requirement_Catalogue` | Maintained | Complete human-readable inventory of migration-script requirements |
| 7 | `07_Fields_Evidence` | Maintained | Evidence keys, data types, producers, operators, and scope |
| 8 | `08_Regulatory_Profiles` | Maintained | Region/authority/format/version/dossier dimensions and evidence locations |
| 9 | `09_Dossier_Sequence_ID` | Maintained | Dossier, application, sequence, and lifecycle identification rules |
| 10 | `10_Folder_File_Structure` | Maintained | Expected folder/file/container structure rules |
| 11 | `11_Missing_Refs_Integrity` | Maintained | XML references, orphan candidates, checksums, and physical-file integrity |
| 12 | `12_Technical_Observations` | Maintained | PDF, XML, path, schema, extension, encryption, and other technical observations |
| 13 | `13_Size_Volume_Metrics` | Maintained | Counts, sizes, diversity, units, and calculation definitions |
| 14 | `14_Source_DB_Archive_DMS` | Maintained | Source-system, database, archive, DMS, and identifier mapping rules |
| 15 | `15_RAG_Severity` | Maintained | Finding severity, RAG, blocker, and aggregation rules |
| 16 | `16_Confidence` | Maintained | Evidence strength, coverage, conflicts, and confidence rules |
| 17 | `17_Effort_Drivers` | Maintained | Complexity drivers, bands, weights, floors, and double-counting groups |
| 18 | `18_Findings` | Maintained | Reusable finding definitions |
| 19 | `19_Recommendations_Actions` | Maintained | Reusable customer and consultant actions linked to findings |
| 20 | `20_PreMigration_Readiness` | Maintained | Readiness decision rules and baseline requirements |
| 21 | `21_PostMigration_Reconciliation` | Maintained | Scenario-aware comparison rules, keys, tolerances, and outcomes |
| 22 | `22_Value_Lists` | Maintained | Controlled dropdown and runtime code values |
| 23 | `23_Source_References` | Maintained | Regulatory, vendor, product, and internal sources |
| 24 | `24_Final_Config_Master` | Generated | Filterable flattened view of everything included/excluded for a selected scenario |
| 25 | `25_JSON_Field_Map` | Maintained | Explicit workbook-column to JSON-property transformation contract |
| 26 | `26_JSON_Preview` | Generated | Scenario JSON preview and section counts |
| 27 | `27_Validation_Results` | Generated | Blocking errors, warnings, affected record, reason, and correction |

## 8. Common workbook conventions

### 8.1 Identifier and relationship rules

The workbook shall use these stable identifiers where relevant:

- `ScenarioId`;
- `QuestionId`;
- `DerivationRuleId`;
- `ModuleId`;
- `RequirementId`;
- `FieldCode`;
- `ProfileId`;
- `RuleId`;
- `ConditionId`;
- `MetricCode`;
- `FindingCode`;
- `RecommendationCode`;
- `SourceId`;
- `MappingId`.

Identifiers shall be unique, shall not depend on row number, and shall not be reused for a different meaning. Display labels may change without changing identifiers.

### 8.2 Common rule columns

Every executable rule sheet shall use the applicable subset of the following columns.

| Column | Type | Why it is needed |
|---|---|---|
| `RuleId` | Identifier | Stable traceability from workbook through JSON, engine evaluation, log, and report |
| `RequirementId` | Reference | Shows which migration-script requirement the rule implements |
| `ModuleId` | Reference | Connects the rule to scenario applicability through `05_Scenario_Module_Map` |
| `IsActive` | Boolean | Retains draft/history rows while excluding inactive content from MVP JSON |
| `Priority` | Integer | Gives deterministic rule evaluation order |
| `Phase` | Code | Limits behavior to Pre-Sales, Pre-Migration, Post-Migration, or All |
| `ScenarioId` | Code | Supports a scenario-specific override; `ALL` means module-driven applicability |
| `Region` | Code | Filters regional logic without mixing it with authority or format |
| `Authority` | Code | Identifies the responsible authority separately from region |
| `TechnicalFormat` | Code | eCTD v3, eCTD v4, NeeS, VNeeS, non-eCTD, or Unknown |
| `SpecificationVersion` | Text | Selects the version-appropriate rule/parser behavior |
| `ApplicationType` | Code | IND, NDA, ANDA, BLA, MAA, CTA, and other pathways |
| `DossierContext` | Code | ASMF, DMF, investigational, marketing, device, and other regulatory context |
| `ScopeLevel` | Code | Repository, application, dossier, sequence, module, document, or file |
| `ConditionGroup` | Text | Conditions in the same group are ANDed |
| `ConditionSequence` | Integer | Preserves deterministic condition order |
| `FieldCode` | Reference | Identifies the observed or derived evidence evaluated by the condition |
| `Operator` | Code | Defines the supported comparison without executable code |
| `Value1` | Typed scalar | First expected operand |
| `Value2` | Typed scalar | Second operand for range operators |
| `FindingCode` | Reference | Produces a reusable finding without duplicating text |
| `RecommendationCode` | Reference | Links a standard action to the result |
| `RagImpact` | Code | Records risk interpretation separately from evidence and confidence |
| `Severity` | Code | Records seriousness independently from display colour |
| `ConfidenceImpact` | Code | Records how this evidence changes confidence |
| `EffortImpact` | Code/number | Connects the observation to complexity without unsupported hours |
| `EngineCapability` | Code | Names the generic PowerShell capability required to evaluate the rule |
| `SourceId` | Reference | Provides source traceability |
| `SourceSection` | Text | Identifies the precise source location, XML section, table, or internal decision |
| `RequirementBasis` | Code | Distinguishes AuthorityRequirement, ReviewedInterpretation, ProductRequirement, and eMASDesign |
| `BusinessExplanation` | Text | Explains the rule to non-developers |

### 8.3 Condition model

- One row represents one atomic condition.
- Conditions with the same `RuleId` and `ConditionGroup` use AND.
- Different condition groups for the same `RuleId` use OR.
- An unconditional rule uses `ConditionMode=Always` and no condition row.
- Missing, inaccessible, or invalid evidence produces an undetermined evaluation unless a specific missing-evidence policy applies.
- `NotEquals` and `NotExists` shall not become true merely because the evidence could not be read.
- Adding an `Operator` or `EngineCapability` value to `22_Value_Lists` does not implement it in PowerShell.

## 9. Sheet-by-sheet requirements

### 9.1 `00_Home`

This sheet makes the workbook usable without reading this specification.

| Field or area | Required | Why |
|---|---:|---|
| Workbook purpose and boundary | Yes | Prevents the mapping workbook from being mistaken for the assessment engine |
| MVP status | Yes | States what works and what is deferred |
| `SelectedScenarioId` | Yes | Drives `24_Final_Config_Master` and JSON generation |
| Scenario name/description | Calculated | Lets the reviewer confirm the selected code |
| Navigation links | Yes | Provides direct access to every sheet |
| Validation summary | Calculated | Shows errors, warnings, and export eligibility |
| JSON section counts | Calculated | Lets the reviewer compare workbook inclusion with preview |
| Generation instructions | Yes | Explains the exact MVP workflow |
| Glossary | Yes | Explains scenario, module, evidence, finding, RAG, confidence, and JSON |

`00_Home` is authoring-only and is not exported.

### 9.2 `01_Migration_Scenarios`

One row defines one stable base migration scenario. Hosting, scope, evidence completeness, repository composition, eSUBmanager/DMS dependencies, other integrations, and sequential-upgrade needs are qualifiers; they shall not create duplicate scenario identities.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ScenarioId` | Identifier | Yes | Primary key -> `scenario.id` |
| `ScenarioCode` | Code | Yes | Short stable code -> `scenario.code` |
| `ScenarioName` | Text | Yes | Human label -> `scenario.name` |
| `ScenarioFamily` | Code | Yes | Groups variants -> `scenario.family` |
| `BusinessDescription` | Text | Yes | Plain-language boundary and intended use -> `scenario.description` |
| `ExistingECTDManager` | Code | Yes | Yes, No, Partial, or Unknown; supports deterministic derivation |
| `SourceSystemCategory` | Code | Yes | eCTDmanager, RegulatoryExport, ThirdPartySystemOrDMS, ArchiveStorage, Hybrid, or Unknown; the exact third-party/DMS input remains in project context |
| `SourceDatabaseType` | Code | Yes | SQLServer, Access, Oracle, NotApplicable, or Unknown |
| `PrimaryMigrationMethod` | Code | Yes | DatabaseArchive, ExportImport, ArchiveOnly, Adapter, Hybrid, or Unknown |
| `TargetPlatform` | Code | Yes | Target product/platform family without embedding hosting |
| `SupportsMixedScope` | Boolean | Yes | Identifies scenarios that intentionally combine source mechanisms |
| `FallbackScenario` | Boolean | Yes | True only for the safe pending/incomplete route |
| `DisplaySequence` | Integer | Yes | Stable human display and serialization order; never used to hide conflicting derivation matches |
| `IsActive` | Boolean | Yes | Controls selectable/exportable scenarios |
| `SourceId` | Reference | Yes | Basis for scenario definition |
| `Notes` | Text | No | Boundary clarification; never executable logic |

The approved base catalogue is `MS-01` through `MS-08` in Section 5. Qualifier definitions belong in `22_Value_Lists`, questionnaire mappings, and applicable rules. Actual project qualifier values belong to execution input/evidence, not the reusable Mapping Workbook or Runtime JSON.

### 9.3 `02_Scenario_Questionnaire`

This sheet contains reusable question definitions. Actual customer answers belong to an execution input/report and shall not be exported as reusable configuration values.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `QuestionId` | Identifier | Yes | Stable question key -> `questionnaire.questions[].questionId` |
| `SectionCode` | Code | Yes | Groups questions in the approved business-first order |
| `DisplaySequence` | Integer | Yes | Stable display order within the questionnaire |
| `QuestionText` | Text | Yes | Plain-language question |
| `BusinessMeaning` | Text | Yes | Explains why the answer matters |
| `AnswerType` | Code | Yes | Boolean, CodeList, Number, Text, or Size |
| `AnswerListCode` | Reference | Conditional | Dropdown source for CodeList answers |
| `AnswerOwner` | Code | Yes | Customer, EXTEDO, or Derived; customer input focuses on current source information |
| `Phase` | Code | Yes | Limits the question to the relevant phase |
| `ParentQuestionId` | Reference | No | Supports dependent questions without free-form expressions |
| `TriggerOperator` | Code | No | Controlled dependency operator |
| `TriggerValue` | Scalar | No | Required answer that reveals this question |
| `MapsToContextField` | Text | No | Project context/qualifier evaluated by derivation and applicability rules |
| `RequiredWhenShown` | Boolean | Yes | Separates display logic from mandatory-answer logic |
| `MissingAnswerImpact` | Code | Yes | FollowUp, ConfidenceDown, NotAssessed, or Blocker |
| `Guidance` | Text | Yes | Where a non-technical user finds the answer |
| `VerificationGuidance` | Text | Yes | What evidence should be recorded in the project report |
| `PreSalesDetailLevel` | Code | Yes | AvailabilityOnly, ApproximateSize, Summary, Detailed, or NotApplicable |
| `IsActive` | Boolean | Yes | Export eligibility |
| `SourceId` | Reference | Yes | Requirement basis |

Questions shall be reviewed in this order:

| Section | Purpose | Minimum questions |
|---|---|---|
| A - Current source and customer situation | Establish whether eCTDmanager is the current source, what is in scope, and what will actually be supplied for migration | `Q-SCN-001` Dossiers currently in eCTDmanager?; `Q-SCN-002` All, selected, or mixed scope?; `Q-SCN-003` Content from another system/repository?; `Q-SCN-021` Primary migration input? |
| B - Hosting and destination | Capture the target product and hosting qualifiers without multiplying scenario identities | `Q-SCN-004` Source hosting?; `Q-SCN-005` Intended target hosting?; `Q-SCN-022` Intended target platform?; `Q-SCN-006` Target technical environment defined? |
| C - Dependencies and migration shape | Reveal related products, repositories, integrations, and upgrade needs | `Q-SCN-007` eSUBmanager used?; `Q-SCN-008` DMS/external repository used?; `Q-SCN-009` Other integrations?; `Q-SCN-010` Sequential upgrade required? |
| D - Available technical evidence | Determine which assessment modules can run | `Q-SCN-011` Source DB available?; `Q-SCN-012` DB type?; `Q-SCN-013` Archive/storage available?; `Q-SCN-014` Regulatory exports available?; `Q-SCN-015` Third-party metadata available?; `Q-SCN-016` Documents/renditions available? |
| E - Pre-Sales scale | Capture lightweight planning measures only | `Q-SCN-017` Approximate DB size?; `Q-SCN-018` Approximate archive size?; `Q-SCN-019` Approximate export size?; `Q-SCN-020` Approximate dossier/application count? |

The initial reusable question rows shall use the following controlled intent. Exact display wording may be improved without changing `QuestionId` or meaning.

| QuestionId | Question | Controlled answer or type | Display condition | MapsToContextField |
|---|---|---|---|---|
| `Q-SCN-001` | Are the dossiers currently managed in eCTDmanager? | Yes, No, Partially, NotSure | Always | `CurrentContentInECTDManager` |
| `Q-SCN-002` | Is the intended migration scope all content, selected content, or a mixed scope? | AllContent, SelectedContent, Mixed, Unknown | Always | `MigrationScope` |
| `Q-SCN-003` | Is migration content also coming from another system or repository? | Yes, No, Unknown | Always | `MultipleSourceMechanisms` |
| `Q-SCN-021` | What will be the main migration input supplied to EXTEDO? | ECTDManagerDatabaseArchive, RegulatorySubmissionExport, ThirdPartySystem, DMS, ArchiveStorageOnly, MultipleSources, Unknown | Always; business answer confirmed by EXTEDO | `PrimarySourceMechanism` |
| `Q-SCN-004` | How is the current source hosted? | OnPremises, Cloud, Hybrid, Unknown | Always | `SourceHosting` |
| `Q-SCN-005` | What is the intended target hosting model? | OnPremises, Cloud, Hybrid, ToBeDefined | Always | `TargetHosting` |
| `Q-SCN-022` | Which target platform should receive the migrated content? | eCTDmanager, OtherEXTEDOProduct, DMS, ThirdPartySystem, ToBeDefined | Always; business answer confirmed by EXTEDO | `TargetPlatform` |
| `Q-SCN-006` | Is the target technical environment defined? | Yes, Partially, No, Unknown | Always; customer may answer Unknown | `TargetEnvironmentDefined` |
| `Q-SCN-007` | Is eSUBmanager used or in migration scope? | Yes, No, Unknown | Always | `ESubmanagerDependency` |
| `Q-SCN-008` | Is a DMS or external content repository used or in migration scope? | Yes, No, Unknown | Always | `DmsDependency` |
| `Q-SCN-009` | Are other interfaces or integrations relevant to migration? | Yes, No, Unknown | Always | `OtherIntegrationDependency` |
| `Q-SCN-010` | Is a sequential eCTDmanager upgrade expected before or during migration? | Yes, No, ToBeDetermined | When eCTDmanager is current or partial | `SequentialUpgradeRequired` |
| `Q-SCN-011` | Is the source database available for assessment? | Yes, No, Unknown | When primary input is eCTDmanager DB/archive or MultipleSources | `SourceDatabaseAvailable` |
| `Q-SCN-012` | What is the source database type? | SQLServer, Access, Oracle, Other, Unknown, NotApplicable | When database availability is Yes or Unknown | `SourceDatabaseType` |
| `Q-SCN-013` | Is the archive or physical storage available? | Yes, Partial, No, Unknown | When primary input is eCTDmanager DB/archive, ArchiveStorageOnly, or MultipleSources | `ArchiveAvailable` |
| `Q-SCN-014` | Are regulatory submission exports available? | Yes, Partial, No, Unknown | When primary input is RegulatorySubmissionExport or MultipleSources | `RegulatoryExportAvailable` |
| `Q-SCN-015` | Is third-party system metadata available? | Yes, Partial, No, Unknown | When primary input is ThirdPartySystem, DMS, or MultipleSources | `ThirdPartyMetadataAvailable` |
| `Q-SCN-016` | Are the source documents and renditions available? | Yes, Partial, No, Unknown | When primary input is ThirdPartySystem, DMS, or MultipleSources | `SourceDocumentsAvailable` |
| `Q-SCN-017` | What is the approximate source database size? | Size plus unit | When source database is available | `SourceDatabaseApproxBytes` |
| `Q-SCN-018` | What is the approximate archive/storage size? | Size plus unit | When archive/storage is available or partial | `ArchiveApproxBytes` |
| `Q-SCN-019` | What is the approximate regulatory-export size? | Size plus unit | When regulatory exports are available or partial | `RegulatoryExportApproxBytes` |
| `Q-SCN-020` | What is the approximate dossier/application count? | Non-negative integer or Unknown | Always | `ApproxDossierCount` |

Pre-Sales shall ask for availability and approximate sizes, not detailed DB-to-archive object verification. Physical verification of `DB record -> archive key -> physical object` is a Pre-Migration/Post-Migration activity. Target technical fields may remain for EXTEDO to complete. Missing answers shall create follow-up/confidence effects through configuration; they shall not silently invent a scenario. New/non-eCTDmanager customers shall see only questions relevant to their chosen primary migration input; they shall not be asked for eCTDmanager database, archive-path, or infrastructure details unless `MultipleSources` or another database-backed route is explicitly selected.

### 9.4 `03_Scenario_Derivation_Rules`

This sheet converts normalized questionnaire context into one candidate base scenario and an explainable selection status. It contains reusable decision and consistency logic, never customer answers. It evaluates normalized context fields rather than display text so questionnaire wording can change without changing scenario behavior.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `DerivationRuleId` | Identifier | Yes | Stable rule -> `questionnaire.derivationRules[].derivationRuleId` |
| `RulePurpose` | Code | Yes | `SelectScenario`, `ValidateContext`, or `Fallback` |
| `RuleName` | Text | Yes | Human-readable rule name |
| `Priority` | Integer | Yes | Defines deterministic evaluation order; it shall not hide contradictory matches |
| `ConditionGroup` | Text | Yes | Groups AND conditions; different groups for one rule use OR |
| `ConditionSequence` | Integer | Yes | Stable order for review and serialization |
| `InputContextField` | Reference | Yes | Normalized project-context field evaluated by the condition |
| `OriginQuestionId` | Reference | Conditional | Question that produced the context value; blank only for a derived context field |
| `Operator` | Code | Yes | Controlled comparison operator |
| `ExpectedValue` | Scalar | Conditional | Value required for the match |
| `CandidateScenarioId` | Reference | Conditional | Candidate `MS-*` scenario for selection/fallback rules |
| `OnMatchStatus` | Code | Yes | `Derived`, `DerivedWithFollowUp`, `Pending`, or `NeedsReview` |
| `MissingInputAction` | Code | Yes | `Continue`, `FollowUp`, or `UseFallback` |
| `FollowUpQuestionId` | Reference | Conditional | Question required to complete or resolve the selection |
| `ReasonCode` | Code | Yes | Stable machine-readable explanation |
| `ReasonTemplate` | Text | Yes | Human explanation of why the scenario was derived |
| `BaseConfidence` | Code | Yes | High, Medium, Low, or Unknown scenario-selection confidence; separate from assessment confidence |
| `IsActive` | Boolean | Yes | Runtime inclusion |
| `SourceId` | Reference | Yes | Requirement/decision basis |
| `Notes` | Text | No | Boundary and maintenance explanation |

One workbook row represents one atomic condition. Rows sharing `DerivationRuleId` and `ConditionGroup` use AND. Different condition groups for the same rule use OR. A `Fallback` rule is evaluated only after all active validation and selection rules. `MatchEffect` is not required: every complete `SelectScenario` rule proposes its `CandidateScenarioId`.

The approved derivation rules are:

| Priority | Rule ID | Required normalized context | Result |
|---:|---|---|---|
| 10 | `SDR-TARGET-UNSUPPORTED` | `TargetPlatform` is DMS, ThirdPartySystem, or OtherEXTEDOProduct | `MS-07 / NeedsReview`; record `OUTSIDE_SUPPORTED_TARGET` and require consultant discussion |
| 20 | `SDR-MS05-MULTI` | `TargetPlatform=eCTDmanager` and `PrimarySourceMechanism=MultipleSources` | `MS-05 / Derived` |
| 30 | `SDR-MS01-SQL` | `TargetPlatform=eCTDmanager`, `PrimarySourceMechanism=ECTDManagerDatabaseArchive`, `SourceDatabaseType=SQLServer` | `MS-01 / Derived` |
| 31 | `SDR-MS02-ACCESS` | `TargetPlatform=eCTDmanager`, `PrimarySourceMechanism=ECTDManagerDatabaseArchive`, `SourceDatabaseType=Access` | `MS-02 / Derived` |
| 32 | `SDR-MS03-ORACLE` | `TargetPlatform=eCTDmanager`, `PrimarySourceMechanism=ECTDManagerDatabaseArchive`, `SourceDatabaseType=Oracle` | `MS-03 / Derived` |
| 40 | `SDR-MS04-EXPORT` | `TargetPlatform=eCTDmanager` and `PrimarySourceMechanism=RegulatorySubmissionExport` | `MS-04 / Derived` |
| 50 | `SDR-MS08-THIRD` | `TargetPlatform=eCTDmanager` and `PrimarySourceMechanism=ThirdPartySystem` | `MS-08 / Derived` |
| 51 | `SDR-MS08-DMS` | `TargetPlatform=eCTDmanager` and `PrimarySourceMechanism=DMS` | `MS-08 / Derived` |
| 60 | `SDR-MS06-ARCHIVE` | `TargetPlatform=eCTDmanager` and `PrimarySourceMechanism=ArchiveStorageOnly` | `MS-06 / Derived` |
| 900 | `SDR-MS07-FALLBACK` | No supported selection rule matches, a required classifier is unknown, an unsupported DB/source route is supplied, or answers conflict | `MS-07 / Pending` or `MS-07 / NeedsReview` |

The selection status has the following meaning:

| Status | Meaning |
|---|---|
| `Derived` | Required scenario-identity fields are known and mutually consistent |
| `DerivedWithFollowUp` | Base scenario is known, but non-identity evidence or supporting information is incomplete |
| `Pending` | Required scenario-identity information is missing; `MS-07` is selected until clarified |
| `NeedsReview` | Answers conflict or identify an unsupported route; `MS-07` is selected pending consultant review |
| `ConfirmedOverride` | Project-level confirmation selects a different scenario with the derived candidate, reason, confirmer, and date retained as execution evidence |

The transformer shall normalize answers, execute context-validation rules, evaluate every applicable selection rule, and then apply the fallback. Exactly one valid selection match produces that scenario. More than one different selection match is a configuration or input conflict and shall produce `MS-07 / NeedsReview`; priority shall not silently discard the conflict. No match produces `MS-07 / Pending`. An explicit supported scenario with missing non-identity evidence remains selected with `DerivedWithFollowUp`.

Required edge-case behavior:

| Project context | Required outcome |
|---|---|
| eCTDmanager SQL route is known; archive is unavailable | `MS-01 / DerivedWithFollowUp`; evidence completeness is reduced |
| eCTDmanager content is partial, but only selected eCTDmanager dossiers are in scope | `MS-01`, `MS-02`, or `MS-03` according to DB type; not automatically Hybrid |
| eCTDmanager and external/DMS content are both migration inputs | `MS-05` |
| A DMS stores the source, but EXTEDO receives regulatory export packages as the migration input | `MS-04` |
| DMS metadata/documents/renditions are migrated into eCTDmanager | `MS-08` |
| DMS content is intended to migrate into another DMS | `MS-07 / NeedsReview`; DMS-to-DMS is outside current scope and requires consultant discussion |
| DMS is only an eCTDmanager dependency | Keep the applicable `MS-01` to `MS-05` base scenario and set the DMS qualifier/module applicability |
| The archive is merely the only evidence currently available, but the intended migration route is unknown | `MS-07`, not automatically `MS-06` |
| Archive/storage itself is the intended migration input | `MS-06` |
| Sequential upgrade, eSUBmanager, hosting, or mixed formats change | Keep the base scenario; update qualifiers and applicable rules |

Missing archive evidence does not change a known SQL Server migration from `MS-01` to `MS-07`; it changes the evidence-completeness qualifier and module outcomes. Mixed dossier formats inside one regulatory export remain `MS-04`. Multiple primary migration inputs use `MS-05`. `MS-07` is the explicit unresolved or unsupported route, not a catch-all replacement for a known supported scenario with incomplete evidence.

Illustrative grouped JSON produced from the atomic rows for `SDR-MS01-SQL`:

```json
{
  "derivationRuleId": "SDR-MS01-SQL",
  "rulePurpose": "SelectScenario",
  "priority": 30,
  "candidateScenarioId": "MS-01",
  "conditionGroups": [
    {
      "groupId": "G1",
      "all": [
        {
          "contextField": "TargetPlatform",
          "originQuestionId": "Q-SCN-022",
          "operator": "Equals",
          "value": "eCTDmanager"
        },
        {
          "contextField": "PrimarySourceMechanism",
          "originQuestionId": "Q-SCN-021",
          "operator": "Equals",
          "value": "ECTDManagerDatabaseArchive"
        },
        {
          "contextField": "SourceDatabaseType",
          "originQuestionId": "Q-SCN-012",
          "operator": "Equals",
          "value": "SQLServer"
        }
      ]
    }
  ],
  "onMatch": {
    "status": "Derived",
    "reasonCode": "ECTDMGR_SQL_PRIMARY",
    "baseConfidence": "High"
  },
  "onMissing": {
    "action": "FollowUp",
    "questionIds": ["Q-SCN-012", "Q-SCN-021", "Q-SCN-022"]
  }
}
```

### 9.5 `04_Assessment_Modules`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ModuleId` | Identifier | Yes | Primary key -> `modules[].moduleId` |
| `ModuleName` | Text | Yes | Human-readable module name |
| `Purpose` | Text | Yes | Explains what the module assesses |
| `PrimaryEngineComponent` | Code | Yes | Names the generic runtime component |
| `SupportedPhases` | Relationship | Yes | Represented by one row per phase or a controlled child table |
| `ProducesBaselineData` | Boolean | Yes | Identifies Pre-Migration baseline contribution |
| `UsedForReconciliation` | Boolean | Yes | Identifies Post-Migration comparison contribution |
| `IsActive` | Boolean | Yes | Module availability |

### 9.6 `05_Scenario_Module_Map`

This is the central scenario switchboard.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ScenarioModuleId` | Identifier | Yes | Stable relationship key |
| `ScenarioId` | Reference | Yes | Selected scenario |
| `ModuleId` | Reference | Yes | Applicable capability |
| `Applicability` | Code | Yes | Required, Conditional, Optional, NotApplicable |
| `Phase` | Code | Yes | Explicit phase behavior |
| `RequiredEvidenceKey` | Reference | Conditional | Evidence required to execute the module |
| `ActivationFieldCode` | Reference | Conditional | Evidence used for a conditional module |
| `ActivationOperator` | Code | Conditional | Controlled activation comparison |
| `ActivationValue` | Scalar | Conditional | Expected activation value |
| `MissingEvidenceOutcome` | Code | Yes | NotAssessed, InsufficientEvidence, FollowUp, or Blocked |
| `Reason` | Text | Yes | Explains applicability to reviewers |
| `IsActive` | Boolean | Yes | Relationship eligibility |

Every active scenario shall have a row for every active module. This makes omissions visible and prevents accidental execution by default.

### 9.7 `06_Requirement_Catalogue`

This sheet is the complete, plain-language inventory of what the migration scripts must support.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `RequirementId` | Identifier | Yes | Primary traceability key -> `requirements[].requirementId` |
| `RequirementTitle` | Text | Yes | Short filterable name |
| `RequirementText` | Text | Yes | Testable statement of required behavior |
| `RequirementArea` | Code | Yes | Scenario, source, DB, archive, DMS, repository, regulatory, sequence, reference, file, volume, interpretation, readiness, reconciliation, report |
| `RequirementType` | Code | Yes | Functional, Data, Validation, Interface, or Constraint |
| `Priority` | Code | Yes | Must, Should, May |
| `ModuleId` | Reference | Yes | Owner module |
| `Phase` | Code | Yes | Phase applicability |
| `ScenarioId` | Code | Yes | `ALL` or exact scenario override |
| `EngineOrConfiguration` | Code | Yes | WorkbookRule, EngineCapability, Hybrid, or ReportOnly |
| `AcceptanceCriterion` | Text | Yes | Observable proof that the requirement is met |
| `RuleSheet` | Text | Conditional | Workbook sheet that implements configurable behavior |
| `RuleId` | Reference | Conditional | Direct implementing rule when one-to-one |
| `JSONPath` | Text | Conditional | Expected runtime location |
| `SourceId` | Reference | Yes | Source/decision basis |
| `SourceSection` | Text | Yes | Precise source location |
| `RequirementBasis` | Code | Yes | AuthorityRequirement, ReviewedInterpretation, ProductRequirement, eMASDesign |
| `Status` | Code | Yes | Draft, Reviewed, Implemented, Verified, Deferred |
| `Notes` | Text | No | Limits or explanation |

At minimum, this catalogue shall cover every requirement area listed in Sections 5, 6, and 9 of this document. A requirement without an implementing rule, named engine capability, report field, or explicit Deferred status is incomplete.

### 9.8 `07_Fields_Evidence`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `FieldCode` | Identifier | Yes | Stable evidence key -> `fields[].fieldCode` |
| `DisplayName` | Text | Yes | Human-readable name |
| `Description` | Text | Yes | Exact semantic meaning |
| `DataType` | Code | Yes | String, Integer, Decimal, Boolean, Date, Code, Path, Hash, or Object |
| `EvidenceSourceType` | Code | Yes | Folder, File, XML, DB, Archive, DMS, Manifest, Customer, Derived, Target |
| `ProducerCapability` | Code | Yes | Generic engine function that produces it |
| `ScopeLevel` | Code | Yes | Repository, dossier, sequence, document, or other entity level |
| `AllowedOperator` | Relationship | Yes | One row per valid operator or controlled child table |
| `MissingValueMeaning` | Code | Yes | Absent, Unavailable, Invalid, NotApplicable, or Unknown |
| `Unit` | Code | Conditional | Bytes, Count, Percent, Days, or other unit |
| `ExampleValue` | Scalar | No | Demonstrates expected type only |
| `IsActive` | Boolean | Yes | Runtime inclusion |

### 9.9 `08_Regulatory_Profiles`

This sheet defines independent classification dimensions and where strong evidence can be found.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ProfileId` | Identifier | Yes | Primary key -> `regulatoryProfiles[].profileId` |
| `Region` | Code | Yes | Jurisdiction dimension |
| `Authority` | Code | Yes | Authority dimension |
| `TechnicalFormat` | Code | Yes | eCTD v3, eCTD v4, NeeS, VNeeS, non-eCTD, Unknown |
| `SpecificationVersion` | Text | Yes | Version-specific parsing contract |
| `RegionalImplementation` | Code | Yes | EU, US, CA, UK, CH, AU, JP, SG, or future profile |
| `ApplicationType` | Code | No | IND/NDA/ANDA/BLA/MAA/CTA when applicable |
| `DossierContext` | Code | No | ASMF/DMF and other dossier contexts |
| `ProcedureContext` | Code | No | Centralised, national, mutual recognition, decentralised, or other |
| `BackboneFile` | Text | No | Example `index.xml` |
| `RegionalXmlFile` | Text | No | Example `eu-regional.xml` or `us-regional.xml` |
| `XmlNamespace` | Text | No | Exact namespace/version evidence |
| `XmlElementOrPath` | Text | No | XML element/XPath-like location to inspect |
| `XmlAttribute` | Text | No | Attribute containing the classification evidence |
| `FolderEvidence` | Text | No | Supporting path/folder evidence |
| `EvidenceStrength` | Code | Yes | Strong, Medium, Weak |
| `ParserProfile` | Code | Yes | Version-appropriate parser contract |
| `SourceId` | Reference | Yes | Regulatory source |
| `SourceSection` | Text | Yes | Exact source section |
| `IsActive` | Boolean | Yes | Runtime inclusion |

### 9.10 `09_Dossier_Sequence_ID`

This sheet contains rules that identify applications/dossiers, sequences/submission units, and lifecycle context.

In addition to the common rule columns, include:

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `DetectionTarget` | Code | Yes | Region, Authority, Format, Version, ApplicationType, DossierContext, DossierId, SequenceId, Lifecycle |
| `EvidenceFile` | Text | Conditional | Backbone or regional XML filename |
| `XmlNamespace` | Text | Conditional | Selects version-appropriate XML semantics |
| `XmlElementOrPath` | Text | Conditional | Exact element/section to inspect |
| `XmlAttribute` | Text | Conditional | Exact attribute to read |
| `ExpectedPattern` | Text | Conditional | Controlled filename/folder/value pattern |
| `CandidateValue` | Code | Yes | Classification result proposed by the rule |
| `EvidenceStrength` | Code | Yes | Strong, Medium, Weak |
| `ConflictGroup` | Text | Yes | Identifies mutually competing results |
| `ConflictStrategy` | Code | Yes | HighestEvidenceScore or ManualReview by default |

The rules shall support `index.xml` plus regional XML, eCTD v3/v4 differences, EU and US regional evidence, other supported regions, ASMF/DMF context, IND/NDA/ANDA/BLA/MAA/CTA pathways, numeric sequence patterns, sequence gaps, duplicate/nested sequence folders, XML-folder sequence mismatch, application conflicts, and ambiguous/manual-review outcomes. A gap such as `0000`, `0001`, `0003` shall be an observation, not automatically a regulatory defect.

### 9.11 `10_Folder_File_Structure`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| Common rule columns | Mixed | Yes | Scope, traceability, conditions, outputs, and source |
| `TargetType` | Code | Yes | Container, DossierRoot, SequenceFolder, ModuleFolder, RegionalFolder, File |
| `RelativePathPattern` | Text | Yes | Expected location relative to the assessed root |
| `NamePattern` | Text | No | Exact name or approved pattern |
| `RequirementLevel` | Code | Yes | Mandatory, Optional, Conditional, Prohibited, NotApplicable |
| `MinimumOccurrences` | Integer | No | Lower allowed count |
| `MaximumOccurrences` | Integer | No | Upper allowed count |
| `AllowEmpty` | Boolean | Conditional | Controls empty-folder/file behavior |
| `ContainerDepthLimit` | Integer | Conditional | Bounds nested container discovery |
| `UnexpectedItemPolicy` | Code | Yes | Ignore, Observe, Warn, Error, ManualReview |

The sheet shall cover ZIP and nested ZIP discovery, wrapper folders, folder-within-folder packaging, duplicate/nested sequences, non-consecutive sequences, multiple applications/products, add-promotional-material or similarly unexpected product branches, backup/temp/system files, unknown folders, eCTD sequence roots, module folders, regional Module 1 folders, backbone XML, regional XML, checksum/index files, leaf files, empty folders, and unrecognizable hierarchies.

### 9.12 `11_Missing_Refs_Integrity`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| Common rule columns | Mixed | Yes | Standard rule identity and interpretation |
| `CheckType` | Code | Yes | XmlReference, OrphanCandidate, Checksum, PhysicalPresence, DuplicateReference, ExternalReference |
| `SourceXmlFile` | Text | Conditional | XML document containing the reference |
| `XmlElementOrPath` | Text | Conditional | Element containing the link/checksum |
| `ReferenceAttribute` | Text | Conditional | Attribute such as href or checksum value |
| `ResolutionBase` | Code | Conditional | SequenceRoot, XmlDirectory, DossierRoot, ArchiveRoot |
| `NormalizationPolicy` | Code | Conditional | Path separator, URI decoding, case, extension, identifier normalization |
| `ChecksumAlgorithm` | Code | Conditional | MD5, SHA1, SHA256, or source-declared algorithm |
| `ExpectedState` | Code | Yes | Present, Absent, Match, Unique, Internal, Readable |
| `FailureState` | Code | Yes | Missing, Mismatch, Multiple, Invalid, Inaccessible, External |

Missing referenced files and orphan candidates shall be reported separately. The rules shall also cover absolute/external references, broken lifecycle targets, duplicate references, zero-byte/unreadable referenced files, checksum mismatches, inaccessible targets, and provenance containing source file, element/path, attribute, and observed value.

### 9.13 `12_Technical_Observations`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| Common rule columns | Mixed | Yes | Standard rule linkage |
| `ObservationType` | Code | Yes | PDFVersion, Encryption, Signature, XmlWellFormed, Namespace, Schema, ExtensionMismatch, PathLength, IllegalName, DuplicateContent, Symlink, Unreadable |
| `TargetExtension` | Text | No | Limits a check to PDF/XML/etc. |
| `ExpectedValue` | Scalar | No | Expected technical characteristic |
| `MinimumValue` | Scalar | No | Lower permitted threshold |
| `MaximumValue` | Scalar | No | Upper permitted threshold |
| `ComparisonUnit` | Code | No | Version, Characters, Bytes, Count |
| `TechnicalImpact` | Text | Yes | Explains migration relevance without claiming authority validation |

The sheet shall support malformed XML, unexpected namespaces/schema versions, invalid constructs, PDF version, encrypted/password-protected files, unreadable files, extension/content mismatch, zero-byte files, excessive path length, illegal names, duplicate content candidates, and platform-specific path risks.

### 9.14 `13_Size_Volume_Metrics`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `MetricCode` | Identifier | Yes | Primary key -> `metrics[].metricCode` |
| `MetricName` | Text | Yes | Human-readable measure |
| `ModuleId` | Reference | Yes | Owning assessment module |
| `ScopeLevel` | Code | Yes | Repository, DB, archive, DMS, dossier, sequence, file |
| `EvidenceSourceType` | Code | Yes | Where it is measured |
| `Aggregation` | Code | Yes | Count, Sum, DistinctCount, Min, Max, Average, Percent |
| `SourceFieldCode` | Reference | Yes | Raw evidence used for calculation |
| `Unit` | Code | Yes | Bytes, GB, Count, Percent |
| `Phase` | Code | Yes | Phase applicability |
| `ScenarioId` | Code | Yes | `ALL` or scenario override |
| `StoreDetail` | Boolean | Yes | Controls whether only aggregate or item-level evidence is retained |
| `EffortDriverId` | Reference | No | Connects volume to complexity |
| `IsActive` | Boolean | Yes | Runtime inclusion |

Required metrics include DB size/count, archive size/object count, export/storage size, dossier/application count, sequence/submission-unit count, document/file/folder count, ZIP/nested-ZIP count, total bytes, missing/multiple/inaccessible count, region/format/version diversity, unknown classifications, malformed XML, broken references, and reconciliation differences.

### 9.15 `14_Source_DB_Archive_DMS`

This sheet holds source-specific mapping configuration without storing executable proprietary SQL.

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `MappingRuleId` | Identifier | Yes | Stable mapping identity -> `sourceMappings[]` |
| `RequirementId` | Reference | Yes | Requirement traceability |
| `ModuleId` | Reference | Yes | Source, DB, Archive, DMS, or Mapping module |
| `ScenarioId` | Code | Yes | Applicable scenario |
| `SourceSystem` | Code | Yes | Product/vendor/source family |
| `SourceVersionFrom` | Text | No | Minimum supported version |
| `SourceVersionTo` | Text | No | Maximum supported version |
| `SourceEntity` | Text | Yes | Application, dossier, sequence, document, rendition, archive object |
| `SourceIdentifierField` | Text | Yes | Logical identifier, not executable query text |
| `IdentifierFormat` | Code | Yes | GUID, SHA-derived name, path, database key, vendor key |
| `NormalizationPolicy` | Code | Yes | Named conversion policy applied before lookup |
| `TargetEntity` | Text | Yes | ArchiveObject, MigratedDocument, TargetDossier, etc. |
| `TargetLookupField` | Text | Yes | Logical target key |
| `ComparisonKey` | Code | Yes | Stable reconciliation key |
| `LookupStatusMap` | Code | Yes | Found/Missing/Multiple/Invalid/Inaccessible mapping |
| `FalseMissingSafeguard` | Code | Yes | Named safeguard profile |
| `AdapterKey` | Code | Yes | Engine adapter implementing the technical read |
| `Phase` | Code | Yes | Phase applicability |
| `SourceId` | Reference | Yes | Product/vendor/internal specification |
| `BusinessExplanation` | Text | Yes | Explains the mapping to reviewers |
| `IsActive` | Boolean | Yes | Runtime inclusion |

False-missing safeguards shall verify identifier mapping, conversion, root selection, recursion, extension assumptions, case behavior, duplicate candidates, and access before declaring an object missing. Business/display filename shall not automatically be treated as archive identity. Archive verification shall remain distinct from regulatory dossier validation.

For DMS sources migrating into eCTDmanager, the same structure shall support document ID, version/rendition ID, metadata fields, relationships, ownership/source reference, export completeness, and unsupported semantics returning Unknown or Not Assessed. These mapping rows shall not be interpreted as DMS-to-DMS migration support.

### 9.16 `15_RAG_Severity`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `RagRuleId` | Identifier | Yes | Stable rule -> `interpretation.ragRules[]` |
| `FindingCode` | Reference | Yes | Finding being interpreted |
| `Phase` | Code | Yes | Allows phase-specific risk treatment |
| `ScenarioId` | Code | Yes | `ALL` or override |
| `EvidenceState` | Code | Yes | Present, ConfirmedAbsent, Unavailable, Invalid, Conflict |
| `EvaluationStatus` | Code | Yes | Assessed, NotAssessed, NotApplicable, Unknown, Error |
| `Severity` | Code | Yes | Info, Low, Medium, High, Critical |
| `RAG` | Code | Yes | Green, Amber, Red, Unknown |
| `IsBlocker` | Boolean | Yes | Readiness decision effect |
| `AggregationStrategy` | Code | Yes | MostSevere, Aggregate, FirstMatch, ManualReview |
| `Rationale` | Text | Yes | Explains the interpretation |
| `SourceId` | Reference | Yes | Basis for the rule |

`NotAssessed` and `NotApplicable` are statuses, not colours. Missing, inaccessible, invalid, or conflicting mandatory evidence shall not resolve to Green.

### 9.17 `16_Confidence`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ConfidenceRuleId` | Identifier | Yes | Stable rule -> `interpretation.confidenceRules[]` |
| `ModuleId` | Reference | Yes | Assessment area |
| `ScenarioId` | Code | Yes | Scenario scope |
| `EvidenceStrength` | Code | Yes | Strong, Medium, Weak, None |
| `RequiredEvidenceCoverage` | Decimal | No | Coverage threshold where meaningful |
| `ConflictCountFrom` | Integer | No | Lower boundary |
| `ConflictCountTo` | Integer | No | Upper boundary |
| `UnavailableEvidenceImpact` | Code | Yes | DownOneLevel, Low, Unknown, NoChange |
| `ResultConfidence` | Code | Yes | High, Medium, Low, Unknown |
| `ReasonTemplate` | Text | Yes | Human-readable explanation |
| `Priority` | Integer | Yes | Deterministic selection |
| `SourceId` | Reference | Yes | Basis |

Classification confidence, assessment coverage, and effort-estimate confidence shall remain separately reportable even if they share the same controlled levels.

### 9.18 `17_Effort_Drivers`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `EffortDriverId` | Identifier | Yes | Stable driver -> `interpretation.effortDrivers[]` |
| `DriverName` | Text | Yes | Human-readable driver |
| `ScenarioId` | Code | Yes | Scenario scope |
| `ModuleId` | Reference | Yes | Owning assessment area |
| `MetricCode` | Reference | Yes | Measured value |
| `Operator` | Code | Yes | Threshold comparison |
| `LowerBound` | Decimal | No | Inclusive lower boundary |
| `UpperBound` | Decimal | No | Exclusive upper boundary by default |
| `Unit` | Code | Yes | Same unit as the metric |
| `ScoreImpact` | Decimal | Yes | Internal weighted contribution |
| `MinimumBand` | Code | No | Mandatory complexity floor |
| `DoubleCountGroup` | Text | No | Prevents duplicate scoring of one cause |
| `CustomerExplanation` | Text | Yes | Explains the driver without exposing arbitrary maths |
| `RecommendationCode` | Reference | No | Suggested planning action |
| `IsActive` | Boolean | Yes | Runtime inclusion |

Effort shall report validated complexity bands and drivers unless an approved hours model exists. Thresholds shall reject overlaps, gaps where complete coverage is intended, inverted ranges, and unit mismatches.

### 9.19 `18_Findings`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `FindingCode` | Identifier | Yes | Stable result code -> `findings[]` |
| `FindingTitle` | Text | Yes | Short report label |
| `Category` | Code | Yes | Filterable domain |
| `Description` | Text | Yes | Meaning of the finding |
| `DefaultSeverity` | Code | Yes | Default seriousness |
| `DefaultRAG` | Code | Yes | Default colour when assessed |
| `ExceptionEligible` | Boolean | Yes | Whether project governance may accept it |
| `ReportAudience` | Code | Yes | Customer, Consultant, Both |
| `IsActive` | Boolean | Yes | Runtime inclusion |
| `SourceId` | Reference | Yes | Basis |

### 9.20 `19_Recommendations_Actions`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `RecommendationCode` | Identifier | Yes | Stable action -> `recommendations[]` |
| `FindingCode` | Reference | Yes | Finding addressed |
| `Phase` | Code | Yes | Phase-specific action |
| `ScenarioId` | Code | Yes | Scenario scope |
| `CustomerText` | Text | Yes | Clear customer-facing action |
| `ConsultantNote` | Text | No | Internal interpretation guidance suitable for runtime packaging |
| `NextAction` | Text | Yes | Concrete next step |
| `ResponsibilityCategory` | Code | Yes | Customer, EXTEDO, Joint, RegulatorySME, MigrationTeam |
| `Sequence` | Integer | Yes | Ordered output |
| `IsActive` | Boolean | Yes | Runtime inclusion |
| `SourceId` | Reference | Yes | Basis |

Changing recommendation wording shall not change the identity or evidence of a historical finding.

### 9.21 `20_PreMigration_Readiness`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ReadinessRuleId` | Identifier | Yes | Stable decision rule -> `phaseRules.preMigration[]` |
| `ScenarioId` | Code | Yes | Scenario scope |
| `ModuleId` | Reference | Yes | Assessment area contributing to readiness |
| `ConditionGroup` | Text | Yes | AND/OR grouping |
| `FieldCode` | Reference | Yes | Readiness evidence or derived metric |
| `Operator` | Code | Yes | Controlled comparison |
| `Value1` | Scalar | No | Expected value |
| `Outcome` | Code | Yes | Ready, ReadyWithAcceptedExceptions, Blocked |
| `BlockerOverride` | Boolean | Yes | Forces Blocked when unresolved |
| `RequiredBaselineEntity` | Code | No | Dossier, sequence, document, archive object, DB record, DMS record |
| `RequiredComparisonKey` | Code | No | Key to preserve for Post-Migration |
| `MissingEvidenceOutcome` | Code | Yes | NotAssessed, FollowUp, or Blocked |
| `FindingCode` | Reference | Yes | Decision evidence |
| `RecommendationCode` | Reference | Yes | Remediation action |
| `Priority` | Integer | Yes | Ordered first-match with blocker override |

The baseline shall record the expected migration population, comparison keys, exclusions, accepted exceptions, unavailable evidence, and limitations at the entity levels applicable to the scenario.

### 9.22 `21_PostMigration_Reconciliation`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ReconciliationRuleId` | Identifier | Yes | Stable comparison rule -> `phaseRules.postMigration[]` |
| `ScenarioId` | Code | Yes | Scenario scope |
| `SourceEntity` | Code | Yes | DB record, archive object, dossier, sequence, metadata, file, relationship, count |
| `TargetEntity` | Code | Yes | Target object being compared |
| `ComparisonKey` | Code | Yes | Identity used for matching |
| `SourceFieldCode` | Reference | Yes | Expected/baseline value |
| `TargetFieldCode` | Reference | Yes | Observed target value |
| `ComparisonType` | Code | Yes | Exists, Equals, SetEquals, CountEquals, HashEquals, RelationshipEquals, Tolerance |
| `ToleranceValue` | Decimal | No | Permitted difference when justified |
| `ToleranceUnit` | Code | No | Count, Percent, Bytes, Days |
| `ApprovedExceptionTreatment` | Code | Yes | Preserve, ExcludeFromDecision, AcceptDifference, NotAllowed |
| `MissingOutcome` | Code | Yes | ReviewRequired or NotReconciled |
| `DifferenceOutcome` | Code | Yes | ReconciledWithAcceptedExceptions, ReviewRequired, NotReconciled |
| `FindingCode` | Reference | Yes | Difference result |
| `RecommendationCode` | Reference | Yes | Investigation/remediation |
| `Priority` | Integer | Yes | Deterministic evaluation |

Rules shall support DB record to target object, archive object to migrated document, dossier/application identity, sequence/submission unit, metadata, files, checksums, relationships/lifecycle, counts/volume, and approved exceptions. The approved outcomes are Reconciled, Reconciled with Accepted Exceptions, Review Required, and Not Reconciled.

### 9.23 `22_Value_Lists`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `ListCode` | Identifier | Yes | Identifies the controlled list -> `valueLists` |
| `Code` | Code | Yes | Stable machine value |
| `Label` | Text | Yes | Human display value |
| `Description` | Text | Yes | Exact meaning |
| `SortOrder` | Integer | Yes | Stable display/serialization order |
| `Usage` | Code | Yes | AuthoringOnly, Runtime, Both |
| `IsActive` | Boolean | Yes | Dropdown/runtime eligibility |

At minimum, lists shall include phase, scenario family, primary source mechanism, target platform, derivation-rule purpose, derivation status, missing-input action, applicability, module, region, authority, technical format, application type, dossier context, procedure, lifecycle, evidence source/state, evaluation status, RAG, severity, confidence, operator, data type, scope level, finding category, effort band, decision outcome, comparison type, requirement basis, engine capability, and status.

### 9.24 `23_Source_References`

| Column | Type | Required | Why / JSON mapping |
|---|---|---:|---|
| `SourceId` | Identifier | Yes | Primary key -> `sources[].sourceId` |
| `SourceType` | Code | Yes | AuthorityPublication, VendorDocument, ProductRequirement, InternalDecision, Example |
| `SourceTitle` | Text | Yes | Exact title |
| `SourceVersion` | Text | Yes | Edition/version or Unknown |
| `SourceDate` | Date | No | Issue/publication date |
| `Reference` | Text | Yes | URL, document identifier, or repository reference |
| `AuthorityOrOwner` | Text | Yes | Issuing authority or accountable owner |
| `VerificationStatus` | Code | Yes | Unverified, Verified, Example |
| `VerifiedBy` | Text | Conditional | Required only when actually verified |
| `VerifiedOn` | Date | Conditional | Required only when actually verified |
| `Notes` | Text | No | Scope and limitations |
| `IsActive` | Boolean | Yes | Runtime/reference eligibility |

Each rule shall additionally record the precise source section in its own row because the same source may support several different conclusions.

### 9.25 `24_Final_Config_Master`

This generated sheet is the reviewer’s filterable answer to: “What exactly will be included in JSON for this scenario, and why?” It shall not be manually edited.

| Column | Why |
|---|---|
| `SelectedScenarioId` | Confirms the generation context |
| `Phase` | Shows which phase consumes the record |
| `ModuleId` and `ModuleApplicability` | Shows the scenario-module decision |
| `RequirementId` and `RequirementText` | Shows the human requirement |
| `SourceSheet` and `SourceRecordId` | Locates the exact workbook row |
| `RecordType` | Scenario, Module, Requirement, Field, Profile, Rule, Finding, Recommendation, Source, ValueList |
| `InclusionStatus` | Included, Excluded, Conditional, Error |
| `InclusionReason` | Explains the join/filter decision |
| `JSONPath` | Shows the destination in JSON |
| `ReferencedBy` | Shows dependency that caused inclusion |
| `ValidationStatus` | Valid, Warning, Error |
| `EngineCapability` | Shows the runtime feature needed |

The sheet shall show excluded records as well as included records. Otherwise, a reviewer cannot distinguish intentional exclusion from a broken join.

### 9.26 `25_JSON_Field_Map`

| Column | Type | Required | Why |
|---|---|---:|---|
| `MappingId` | Identifier | Yes | Stable mapping record |
| `SourceSheet` | Text | Yes | Workbook origin |
| `SourceTable` | Text | Yes | Exact Excel Table |
| `SourceColumn` | Text | Yes | Exact column header |
| `SourceRecordKey` | Text | Yes | Stable primary key, never row number |
| `JSONPath` | Text | Yes | Root-relative target path |
| `JSONProperty` | Text | Yes | Exact property name |
| `DataType` | Code | Yes | Required JSON type |
| `Transformation` | Code | Yes | Named transform such as Trim, ToBoolean, ToNumber, GroupConditions, ResolveReference |
| `NullPolicy` | Code | Yes | Error, Omit, Null, EmptyArray |
| `InclusionRule` | Code | Yes | ActiveAndApplicable, ReferencedDependency, AuthoringOnly |
| `SortKey` | Text | Yes | Deterministic array order |
| `SchemaVersion` | Text | Yes | Contract compatibility |
| `ExampleInput` | Text | No | Review example |
| `ExampleOutput` | Text | No | Review example |
| `Notes` | Text | No | Join/grouping explanation |

The mapping sheet documents a controlled transformation. It shall not contain executable JavaScript or PowerShell. A mapping row without a matching source column or JSON property is a blocking error.

### 9.27 `26_JSON_Preview`

| Column or area | Required behavior |
|---|---|
| Scenario header | Shows `ScenarioId`, scenario name, mapping version, and schema version |
| Section counts | Shows modules, requirements, rules by family, findings, recommendations, sources, and value lists |
| JSON text | Shows the complete candidate JSON or a clearly linked generated file |
| Traceability links | Opens matching `24_Final_Config_Master` rows |
| Stale indicator | Becomes stale whenever an included source table changes |
| Validation state | Shows Eligible or Blocked with the related validation run |

Preview and exported JSON shall use the same transformation logic.

### 9.28 `27_Validation_Results`

| Column | Why |
|---|---|
| `ValidationId` | Stable result identity |
| `Severity` | Error, Warning, Info |
| `ControlCode` | Identifies the failed validation |
| `SheetName` and `RecordId` | Locates the issue |
| `ColumnName` | Identifies the field to correct |
| `Message` | Explains the problem |
| `WhyItMatters` | Explains the JSON/runtime impact |
| `CorrectiveAction` | Tells the maintainer what to change |
| `Blocking` | Controls export eligibility |
| `SelectedScenarioId` | Distinguishes global from scenario-specific validation |

## 10. Minimum configurable requirement coverage

The following coverage is mandatory before the workbook can claim to contain all migration-script requirements.

| Requirement family | Minimum workbook coverage |
|---|---|
| Scenario | All scenario families, scenario dimensions, questionnaire derivation, fallback behavior, and module applicability |
| Source systems | Supported products/versions, adapters, dependencies, unsupported semantics, and evidence availability |
| Database | Connectivity/readability evidence, inventory entities, logical IDs, counts/size, and comparison keys |
| Archive | Object identity, normalization, path/key lookup, Found/Missing/Multiple/Invalid/Inaccessible, size/count, and false-missing safeguards |
| DMS | Document/version/rendition IDs, metadata, relationships, ownership/source reference, file availability, export completeness, supported target=eCTDmanager, and DMS-to-DMS consultant-review boundary |
| Repository | Folders, ZIPs, nested ZIPs, wrappers, multiple roots, mixed content, backups/temp/system content, and original container context |
| Regulatory classification | Separate region, authority, format, specification, regional implementation, application, dossier/procedure, lifecycle, and confidence |
| Sequence/lifecycle | Numeric patterns, gaps, duplicates, nesting, XML/folder mismatch, application conflict, lifecycle references, and manual review |
| Folder/file structure | Expected roots, modules, regional folders, mandatory/optional/conditional/prohibited items, names, counts, and empty behavior |
| XML/reference | Backbone/regional XML, namespace, exact element/attribute/path, missing targets, orphans, external references, malformed XML, and lifecycle targets |
| File integrity | Presence, readability, zero-byte, extension mismatch, duplicate candidates, checksum, PDF characteristics, path/name risks |
| Metrics | DB/archive/export/DMS/dossier/sequence/document/file counts and sizes, diversity, missing counts, and comparison totals |
| RAG/severity | Independent evaluation status, evidence state, severity, RAG, blocker, and aggregation |
| Confidence | Evidence strength, coverage, contradiction, unavailable evidence, classification confidence, and estimate confidence |
| Effort | Source complexity, volume, diversity, integrity issues, mappings, remediation, dependencies, bands, floors, and double counting |
| Findings/actions | Stable findings, customer text, consultant notes, responsibility, next action, and phase/scenario applicability |
| Pre-Migration | Required inputs, blockers, remediation, exceptions, baseline population, and comparison keys |
| Post-Migration | Scenario-specific expected-vs-observed comparison for records, objects, dossiers, sequences, metadata, files, hashes, relationships, and counts |
| Reporting | Phase outcomes, limitations, traceability IDs, and safe wording without validation/acceptance claims |

## 11. Scenario-to-sheet-to-JSON connection

| Workbook source | Join path | JSON destination |
|---|---|---|
| `01_Migration_Scenarios` | Selected `ScenarioId` | `scenario` |
| `02_Scenario_Questionnaire` | Active reusable question definitions | `questionnaire.questions[]` |
| `03_Scenario_Derivation_Rules` | Active rules that convert project context to one base scenario | `questionnaire.derivationRules[]` |
| `04_Assessment_Modules` | Via `05_Scenario_Module_Map` | `modules[]` |
| `06_Requirement_Catalogue` | Module + phase + scenario | `requirements[]` |
| `07_Fields_Evidence` | Referenced by included rules/modules | `catalogues.fields[]` |
| `08_Regulatory_Profiles` | Referenced by included classification rules | `catalogues.regulatoryProfiles[]` |
| Rule/mapping sheets `09`-`14` | Requirement + module + scenario + scope | `rules.<family>[]` and `sourceMappings[]` |
| Interpretation sheets `15`-`17` | Finding/metric/module references | `interpretation.*` |
| `18_Findings` | Referenced by included rules | `findings[]` |
| `19_Recommendations_Actions` | Referenced by included findings/rules | `recommendations[]` |
| `20_PreMigration_Readiness` | Selected scenario | `phaseRules.preMigration[]` |
| `21_PostMigration_Reconciliation` | Selected scenario | `phaseRules.postMigration[]` |
| `22_Value_Lists` | Runtime lists and referenced codes | `valueLists` |
| `23_Source_References` | Referenced by included objects | `sources[]` |
| `24_Final_Config_Master` | Generated lineage view | Not exported |
| `25_JSON_Field_Map` | Transformation contract | Not exported |
| `26_JSON_Preview` | Generated representation | Same structure as exported JSON |
| `27_Validation_Results` | Validation evidence | Not exported in Runtime JSON |

## 12. Scenario-specific JSON contract

### 12.1 Canonical top-level structure

```json
{
  "configuration": {
    "configurationId": "EMAS-MVP",
    "mappingVersion": "0.1.0",
    "schemaVersion": "0.1.0-mvp",
    "scenarioId": "MS-04"
  },
  "scenario": {},
  "modules": {
    "included": [],
    "conditional": []
  },
  "evidenceRequirements": [],
  "questionnaire": {
    "questions": [],
    "derivationRules": [],
    "outputContract": {
      "derivedScenarioId": "String",
      "confirmedScenarioId": "String",
      "derivationStatus": "Derived|DerivedWithFollowUp|Pending|NeedsReview|ConfirmedOverride",
      "scenarioSelectionConfidence": "High|Medium|Low|Unknown",
      "matchedDerivationRuleIds": [],
      "candidateScenarioIds": [],
      "qualifiers": {},
      "missingQuestionIds": [],
      "followUpQuestionIds": [],
      "reasonCodes": [],
      "nextAction": "String",
      "runtimeJsonEligible": "Boolean"
    }
  },
  "catalogues": {
    "fields": [],
    "regulatoryProfiles": []
  },
  "requirements": [],
  "rules": {
    "repositoryDiscovery": [],
    "regulatoryClassification": [],
    "dossierSequenceIdentification": [],
    "folderFileStructure": [],
    "referenceIntegrity": [],
    "technicalObservations": [],
    "sizeVolumeMetrics": []
  },
  "sourceMappings": [],
  "interpretation": {
    "ragSeverityRules": [],
    "confidenceRules": [],
    "effortDrivers": []
  },
  "findings": [],
  "recommendations": [],
  "phaseRules": {
    "preSales": [],
    "preMigration": [],
    "postMigration": []
  },
  "policies": {
    "missingEvidence": {},
    "conflict": {},
    "falseMissingSafeguards": []
  },
  "valueLists": {},
  "sources": []
}
```

The MVP JSON shall contain no generation timestamp inside the canonical content because identical workbook content and `ScenarioId` must produce identical bytes. Run time, generator version, and file hash may be logged externally during the MVP.

### 12.2 Inclusion algorithm

For a selected `ScenarioId`, the transformer shall:

1. validate that the selected `ScenarioId` identifies exactly one active base scenario, whether selected directly or produced by the approved derivation rules;
2. load all scenario-module mappings for all supported phases;
3. include Required, Optional, and Conditional modules; exclude NotApplicable modules while recording the reason in `24_Final_Config_Master`;
4. include active requirements for the included modules where `ScenarioId` is `ALL` or the selected scenario;
5. include active rules that implement those requirements and match the scenario/module/phase scope;
6. include every referenced evidence field, metric, regulatory profile, finding, recommendation, source, and runtime value-list entry;
7. include scenario-specific Pre-Migration and Post-Migration rules;
8. reject unresolved or inactive references;
9. sort objects and condition groups by defined keys rather than worksheet row position;
10. serialize using UTF-8, invariant numbers, JSON booleans, explicit arrays, and stable property order;
11. validate section counts against `24_Final_Config_Master`;
12. write one file named `eMAS_Runtime_<ScenarioId>_<MappingVersion>.json`.

Questionnaire answers and actual qualifier values are project evidence and shall not be embedded in the reusable scenario configuration. The JSON contains the question catalogue, derivation rules, qualifier vocabulary, and output contract so the consuming application can collect context and produce a traceable scenario-selection result.

### 12.3 Project scenario-selection result

The project scenario-selection result is execution evidence, not reusable configuration. It records the derived and confirmed scenario without copying customer answers into the master Runtime JSON. An illustrative result is:

```json
{
  "scenarioSelection": {
    "derivedScenarioId": "MS-01",
    "confirmedScenarioId": "MS-01",
    "status": "DerivedWithFollowUp",
    "scenarioSelectionConfidence": "Medium",
    "matchedDerivationRuleIds": ["SDR-MS01-SQL"],
    "candidateScenarioIds": ["MS-01"],
    "qualifiers": {
      "targetHosting": "Cloud",
      "eSubmanagerDependency": "Yes",
      "evidenceCompleteness": "Partial"
    },
    "missingQuestionIds": ["Q-SCN-018"],
    "followUpQuestionIds": ["Q-SCN-018"],
    "reasonCodes": ["ECTDMGR_SQL_PRIMARY", "ARCHIVE_SIZE_NOT_PROVIDED"],
    "nextAction": "CollectMissingEvidence",
    "runtimeJsonEligible": true
  }
}
```

For an attempted DMS-to-DMS migration, the result shall use `derivedScenarioId=MS-07`, `status=NeedsReview`, `scenarioSelectionConfidence=Unknown`, and `reasonCodes=["DMS_TO_DMS_OUT_OF_SCOPE"]`. It shall identify consultation as the next action and shall not generate an `MS-08` Runtime JSON until a supported migration route is confirmed.

```json
{
  "scenarioSelection": {
    "derivedScenarioId": "MS-07",
    "confirmedScenarioId": null,
    "status": "NeedsReview",
    "scenarioSelectionConfidence": "Unknown",
    "matchedDerivationRuleIds": ["SDR-TARGET-UNSUPPORTED"],
    "candidateScenarioIds": [],
    "qualifiers": {
      "primarySourceMechanism": "DMS",
      "targetPlatform": "DMS"
    },
    "missingQuestionIds": [],
    "followUpQuestionIds": [],
    "reasonCodes": ["DMS_TO_DMS_OUT_OF_SCOPE"],
    "nextAction": "ConsultEXTEDO",
    "runtimeJsonEligible": false
  }
}
```

## 13. JSON examples by migration scenario

The examples below show the required scenario-specific shape. Rule arrays contain IDs for brevity; the generated JSON shall contain the complete referenced objects.

### 13.1 `MS-01` - eCTDmanager SQL Server to SQL Server

```json
{
  "configuration": {"scenarioId": "MS-01", "mappingVersion": "0.1.0"},
  "scenario": {"code": "ECTDMGR_SQL_TO_SQL", "sourceSystemCategory": "eCTDmanager", "sourceDatabaseType": "SQLServer", "primaryMigrationMethod": "DatabaseArchive"},
  "supportedQualifiers": ["CustomerRelationship", "SourceHosting", "TargetHosting", "MigrationScope", "EvidenceCompleteness", "ESubmanagerDependency", "DmsDependency", "OtherIntegrations", "SequentialUpgrade"],
  "modules": {"included": ["MOD-SCENARIO", "MOD-SOURCE", "MOD-DB", "MOD-ARCHIVE", "MOD-VOLUME", "MOD-MAPPING", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-REPOSITORY", "MOD-CLASSIFY"]},
  "evidenceRequirements": ["source.productVersion", "database.available", "archive.available", "database.totalBytes", "archive.totalBytes"],
  "sourceMappings": ["MAP-ECTDMGR-DB-APPLICATION", "MAP-ECTDMGR-DB-ARCHIVE-OBJECT"],
  "phaseRules": {"preSales": ["RULE-EFF-DBSIZE"], "preMigration": ["RULE-RDY-DBARCHIVE"], "postMigration": ["RULE-REC-DB-TARGET", "RULE-REC-ARCHIVE-TARGET"]}
}
```

### 13.2 `MS-02` - eCTDmanager Access to SQL Server

```json
{
  "configuration": {"scenarioId": "MS-02", "mappingVersion": "0.1.0"},
  "scenario": {"code": "ECTDMGR_ACCESS_TO_SQL", "sourceSystemCategory": "eCTDmanager", "sourceDatabaseType": "Access", "primaryMigrationMethod": "DatabaseArchive"},
  "modules": {"included": ["MOD-SCENARIO", "MOD-SOURCE", "MOD-DB", "MOD-ARCHIVE", "MOD-VOLUME", "MOD-MAPPING", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-REPOSITORY", "MOD-CLASSIFY"]},
  "evidenceRequirements": ["source.productVersion", "database.available", "database.type", "archive.available", "database.totalBytes", "archive.totalBytes"],
  "sourceMappings": ["MAP-ACCESS-APPLICATION", "MAP-ACCESS-ARCHIVE-OBJECT"],
  "phaseRules": {"preSales": ["RULE-EFF-ACCESS-SCALE"], "preMigration": ["RULE-RDY-ACCESS-CONVERSION"], "postMigration": ["RULE-REC-ACCESS-SQL", "RULE-REC-ARCHIVE-TARGET"]}
}
```

### 13.3 `MS-03` - eCTDmanager Oracle to SQL Server

```json
{
  "configuration": {"scenarioId": "MS-03", "mappingVersion": "0.1.0"},
  "scenario": {"code": "ECTDMGR_ORACLE_TO_SQL", "sourceSystemCategory": "eCTDmanager", "sourceDatabaseType": "Oracle", "primaryMigrationMethod": "DatabaseArchive"},
  "modules": {"included": ["MOD-SCENARIO", "MOD-SOURCE", "MOD-DB", "MOD-ARCHIVE", "MOD-VOLUME", "MOD-MAPPING", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-REPOSITORY", "MOD-CLASSIFY"]},
  "evidenceRequirements": ["source.productVersion", "database.available", "database.type", "archive.available", "database.totalBytes", "archive.totalBytes"],
  "sourceMappings": ["MAP-ORACLE-APPLICATION", "MAP-ORACLE-ARCHIVE-OBJECT"],
  "phaseRules": {"preSales": ["RULE-EFF-ORACLE-SCALE"], "preMigration": ["RULE-RDY-ORACLE-CONVERSION"], "postMigration": ["RULE-REC-ORACLE-SQL", "RULE-REC-ARCHIVE-TARGET"]}
}
```

### 13.4 `MS-04` - Regulatory Submission Export to eCTDmanager

```json
{
  "configuration": {"scenarioId": "MS-04", "mappingVersion": "0.1.0"},
  "scenario": {"code": "REGULATORY_EXPORT_TO_ECTDMGR", "sourceSystemCategory": "RegulatoryExport", "sourceDatabaseType": "NotApplicable", "primaryMigrationMethod": "ExportImport"},
  "supportedQualifiers": ["CustomerRelationship", "SourceHosting", "TargetHosting", "MigrationScope", "EvidenceCompleteness", "RepositoryComposition", "ESubmanagerDependency", "DmsDependency", "OtherIntegrations"],
  "modules": {"included": ["MOD-SCENARIO", "MOD-REPOSITORY", "MOD-CLASSIFY", "MOD-SEQUENCE", "MOD-REFERENCE", "MOD-FILE", "MOD-VOLUME", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": []},
  "rules": {"repositoryDiscovery": ["RULE-ZIP", "RULE-NESTED-ZIP", "RULE-WRAPPER"], "regulatoryClassification": ["RULE-EU-XML", "RULE-US-XML"], "dossierSequenceIdentification": ["RULE-SEQUENCE-PATTERN", "RULE-SEQUENCE-GAP"], "referenceIntegrity": ["RULE-MISSING-REFERENCE", "RULE-ORPHAN-CANDIDATE"]},
  "catalogues": {"regulatoryProfiles": ["PROFILE-EU-ECTD3", "PROFILE-EU-ECTD4", "PROFILE-US-ECTD3", "PROFILE-US-ECTD4"]}
}
```

### 13.5 `MS-05` - Hybrid Migration

```json
{
  "configuration": {"scenarioId": "MS-05", "mappingVersion": "0.1.0"},
  "scenario": {"code": "HYBRID_MIGRATION", "sourceSystemCategory": "Hybrid", "sourceDatabaseType": "Unknown", "primaryMigrationMethod": "Hybrid", "supportsMixedScope": true},
  "modules": {"included": ["MOD-SCENARIO", "MOD-SOURCE", "MOD-REPOSITORY", "MOD-VOLUME", "MOD-MAPPING", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-DB", "MOD-ARCHIVE", "MOD-DMS", "MOD-CLASSIFY", "MOD-SEQUENCE", "MOD-REFERENCE", "MOD-FILE"]},
  "evidenceRequirements": ["source.mechanisms", "source.scopeByMechanism", "evidence.availabilityByMechanism"],
  "policies": {"conflict": {"strategy": "ManualReview"}, "unsupportedSemanticsOutcome": "NotAssessed"}
}
```

### 13.6 `MS-06` - Archive or Storage Only

```json
{
  "configuration": {"scenarioId": "MS-06", "mappingVersion": "0.1.0"},
  "scenario": {"code": "ARCHIVE_STORAGE_ONLY", "sourceSystemCategory": "ArchiveStorage", "sourceDatabaseType": "NotApplicable", "primaryMigrationMethod": "ArchiveOnly"},
  "modules": {"included": ["MOD-SCENARIO", "MOD-ARCHIVE", "MOD-REPOSITORY", "MOD-VOLUME", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-CLASSIFY", "MOD-SEQUENCE", "MOD-REFERENCE", "MOD-FILE"]},
  "evidenceRequirements": ["archive.available", "archive.totalBytes", "archive.objectCount", "archive.identifierSemantics"],
  "policies": {"lookupOutcomes": ["Found", "Missing", "Multiple", "Invalid", "Inaccessible"], "falseMissingSafeguards": ["CheckMapping", "CheckConversion", "CheckRoot", "CheckRecursion", "CheckExtension", "CheckAccess"]}
}
```

### 13.7 `MS-07` - Scenario Pending or Incomplete

```json
{
  "configuration": {"scenarioId": "MS-07", "mappingVersion": "0.1.0"},
  "scenario": {"code": "SCENARIO_PENDING", "sourceSystemCategory": "Unknown", "sourceDatabaseType": "Unknown", "primaryMigrationMethod": "Unknown", "fallbackScenario": true},
  "modules": {"included": ["MOD-SCENARIO", "MOD-INTERPRET"], "conditional": ["MOD-SOURCE", "MOD-DB", "MOD-ARCHIVE", "MOD-DMS", "MOD-REPOSITORY", "MOD-CLASSIFY", "MOD-VOLUME"]},
  "policies": {"missingEvidence": {"evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Low", "action": "FollowUp"}},
  "phaseRules": {"preSales": ["RULE-PENDING-FOLLOWUP"], "preMigration": ["RULE-PENDING-BLOCKED"], "postMigration": ["RULE-PENDING-NOT-RECONCILABLE"]}
}
```

### 13.8 `MS-08` - Third-Party System or DMS to eCTDmanager

```json
{
  "configuration": {"scenarioId": "MS-08", "mappingVersion": "0.1.0"},
  "scenario": {"code": "THIRD_PARTY_DMS_TO_ECTDMGR", "sourceSystemCategory": "ThirdPartySystemOrDMS", "sourceDatabaseType": "Unknown", "primaryMigrationMethod": "Adapter", "targetPlatform": "eCTDmanager"},
  "modules": {"included": ["MOD-SCENARIO", "MOD-SOURCE", "MOD-DMS", "MOD-VOLUME", "MOD-MAPPING", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"], "conditional": ["MOD-DB", "MOD-ARCHIVE", "MOD-REPOSITORY", "MOD-CLASSIFY", "MOD-SEQUENCE", "MOD-REFERENCE", "MOD-FILE"]},
  "sourceMappings": ["MAP-VENDOR-APPLICATION-ID", "MAP-DMS-DOCUMENT", "MAP-DMS-VERSION", "MAP-DMS-RENDITION", "MAP-DMS-METADATA", "MAP-DMS-RELATIONSHIP"],
  "policies": {"unsupportedSemanticsOutcome": "NotAssessed", "unsupportedTargetOutcome": "NeedsReview", "dmsToDmsSupported": false},
  "phaseRules": {"preMigration": ["RULE-RDY-ADAPTER-EVIDENCE"], "postMigration": ["RULE-REC-THIRD-PARTY-OBJECT", "RULE-REC-DMS-METADATA"]}
}
```

## 14. Validation requirements

JSON generation shall be blocked when any of the following is true:

- a required sheet, Table, column, or selected scenario is missing;
- an identifier is blank, duplicated, unstable, or unresolved;
- an active record references an inactive or nonexistent dependency;
- a scenario lacks a module mapping;
- a requirement has no implementation/deferred disposition;
- a rule refers to an unsupported field, operator, data type, engine capability, or parser profile;
- condition grouping is incomplete or inconsistent;
- numeric thresholds overlap, invert, or use mismatched units;
- a required source or exact source section is missing;
- a classification rule collapses prohibited dimensions;
- a Not Assessed/Unavailable state is mapped to Green or Pass;
- an included finding lacks its referenced recommendation where required;
- a JSON mapping points to a missing column/property or incompatible type;
- `24_Final_Config_Master` and generated JSON section counts disagree;
- generated JSON is not valid JSON or fails the MVP schema;
- a DMS-to-DMS, third-party-to-third-party, or otherwise unsupported target route is presented as `MS-08` instead of `MS-07 / NeedsReview`;
- a second generation from unchanged workbook content and the same scenario produces different canonical bytes.

Warnings may identify draft/unverified source content, example values, optional missing descriptions, or conditional modules without available project evidence. Warnings shall remain visible and shall not be silently converted into successful evidence.

## 15. Engine capability boundary

The workbook may reference only named generic capabilities implemented by the engine, for example:

- `FileExists`, `FolderExists`, `EnumerateDirectory`, `EnumerateZip`, `EnumerateNestedZip`;
- `XmlWellFormed`, `XmlElementExists`, `XmlAttributeEquals`, `XmlNamespaceEquals`, `ResolveXmlReference`;
- `CountItems`, `SumBytes`, `DistinctCount`, `CompareValue`, `CompareSet`, `CompareHash`;
- `CalculateChecksum`, `DetectZeroByte`, `DetectExtensionMismatch`, `ReadPdfVersion`;
- `ReadDatabaseAdapter`, `ReadArchiveAdapter`, `ReadDmsAdapter`, `NormalizeIdentifier`, `LookupPhysicalObject`;
- `ClassifyCandidates`, `DetectSequenceGap`, `AggregateRag`, `CalculateConfidence`, `CalculateEffortBand`;
- `EvaluateReadiness`, `BuildBaseline`, `ReconcileEntities`, `GenerateReport`, `WriteLog`.

The workbook configures parameters and interpretation for these capabilities. It does not implement them. Any rule requiring an unimplemented capability shall be marked `Deferred` or shall block JSON generation for scenarios that require it.

## 16. MVP acceptance tests

| TestId | Test | Expected result |
|---|---|---|
| `MVP-AT-001` | Select `MS-01` | Final Config Master shows SQL Server DB/archive/source/readiness/reconciliation content and excludes irrelevant DMS/export-only rules |
| `MVP-AT-002` | Select `MS-04` | Repository/regulatory/sequence/XML/file rules are included; eCTDmanager DB/archive mappings are excluded |
| `MVP-AT-003` | Select `MS-07` | Missing or conflicting scenario inputs remain Not Assessed/Unknown and generate follow-up requirements |
| `MVP-AT-004` | Filter Final Config Master by Phase/Module/Region | Reviewer sees all applicable requirements and source rows |
| `MVP-AT-005` | Trace one JSON rule | Rule resolves to RequirementId, source sheet/row ID, finding, recommendation, source, and engine capability |
| `MVP-AT-006` | Change one rule value | Only the expected JSON object and dependent canonical content change |
| `MVP-AT-007` | Generate twice without changes | Canonical JSON bytes are identical |
| `MVP-AT-008` | Remove a referenced finding/source/field | Generation is blocked with an actionable validation result |
| `MVP-AT-009` | Create a sequence gap fixture | Gap is reported as an observation and interpreted by configured context, not automatically as a defect |
| `MVP-AT-010` | Provide inaccessible evidence | Result is Unavailable/Not Assessed or Blocked by policy; never Green |
| `MVP-AT-011` | Compare all scenario JSON outputs | Each contains only applicable modules/rules plus required dependencies |
| `MVP-AT-012` | Run PowerShell with workbook absent | Runtime loads the selected scenario JSON and does not require Excel |
| `MVP-AT-013` | Set target=eCTDmanager, primary input=eCTDmanager DB/archive, and DB type=Access | Derivation selects `MS-02` with an explainable reason |
| `MVP-AT-014` | Set eCTDmanager=Partially, scope=SelectedContent, primary input=eCTDmanager DB/archive, and DB type=SQLServer | Derivation selects `MS-01`; partial source population alone does not create Hybrid |
| `MVP-AT-015` | Set primary input=MultipleSources and target=eCTDmanager | Derivation selects `MS-05` |
| `MVP-AT-016` | Derive SQL Server scenario with archive unavailable | Scenario remains `MS-01 / DerivedWithFollowUp`; evidence completeness is reduced and archive-dependent modules follow missing-evidence policy |
| `MVP-AT-017` | Set primary input=DMS and target=eCTDmanager | Derivation selects `MS-08` |
| `MVP-AT-018` | Set primary input=DMS and target=DMS | Derivation returns `MS-07 / NeedsReview`, reason `DMS_TO_DMS_OUT_OF_SCOPE`, and requires consultant discussion; `MS-08` JSON generation is blocked |
| `MVP-AT-019` | Set eCTDmanager SQL as primary input and DMS dependency=Yes without DMS content in migration scope | Derivation remains `MS-01`; the DMS dependency affects qualifiers/modules only |
| `MVP-AT-020` | Leave target platform or primary migration input unknown | Derivation returns `MS-07 / Pending` with the exact follow-up question IDs |

## 17. MVP definition of done

The MVP is complete when:

1. all 28 required sheets exist with the specified stable names and columns;
2. every migration-script requirement is represented in `06_Requirement_Catalogue` and linked to a rule, engine capability, report-only behavior, or explicit deferral;
3. every supported scenario has complete phase-by-phase module applicability;
4. a reviewer can filter `24_Final_Config_Master` and understand why each record is included or excluded;
5. scenario-specific JSON can be generated for all scenarios in Section 5;
6. every JSON object is traceable to workbook records;
7. invalid or incomplete workbook content blocks generation with actionable messages;
8. unchanged input and scenario selection produce identical canonical JSON;
9. the PowerShell runtime consumes JSON without reading Excel;
10. SharePoint, formal release governance, and GxP controls remain clearly deferred rather than being falsely represented as complete.

## 18. Planned review sequence

The workbook shall be reviewed and populated in this order:

1. Migration Scenarios and qualifier vocabulary;
2. Scenario Questionnaire;
3. Scenario Derivation Rules;
4. Assessment Modules and Scenario-Module Map;
5. Requirement Catalogue;
6. Fields/Evidence and Value Lists;
7. Regulatory Profiles and Dossier/Sequence Identification;
8. Folder/File Structure;
9. Missing References/File Integrity;
10. Size/Volume and Technical Observations;
11. Source-System/DB/Archive/DMS rules;
12. RAG/Severity and Confidence;
13. Effort Drivers;
14. Findings and Recommendations/Actions;
15. Pre-Migration Readiness;
16. Post-Migration Reconciliation;
17. Source References;
18. Final Config Master and JSON Field Map;
19. scenario-by-scenario JSON preview, validation, and acceptance testing.

Each review step shall answer four questions:

1. What information must this sheet contain?
2. Are the columns understandable and sufficient, and why is each needed?
3. How does each row connect to other sheets and the Final Config Master?
4. How does the row appear in scenario-specific JSON?

## 19. Revision history

| Version | Date | Change |
|---|---|---|
| 3.0 | 13 July 2026 | Previous XLSM/VBA and governance-oriented functional baseline |
| 4.0 MVP | 13 September 2026 | Refocused the immediate implementation on a complete human-readable master workbook and deterministic scenario-specific Runtime JSON; added exact sheets, columns, relationships, coverage, JSON shape, scenario examples, validation, and acceptance tests; deferred SharePoint/GxP release controls |
| 4.1 MVP | 13 September 2026 | Applied the approved eight-scenario `MS-*` catalogue; separated project qualifiers from scenario identity; defined the business-first questionnaire; added `03_Scenario_Derivation_Rules`; replaced scenario JSON examples and expanded derivation acceptance tests |
| 4.2 MVP | 13 September 2026 | Approved deterministic scenario derivation based on primary migration input and target platform; added `Q-SCN-021` and `Q-SCN-022`; refined rule columns, selection statuses, conflict/fallback behavior, project selection-result JSON and edge cases; explicitly excluded DMS-to-DMS migration and routed it to `MS-07 / NeedsReview` with consultant discussion |
