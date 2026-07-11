# eMAS Mapping and Configuration Workbook — Content Catalogue

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Mapping Content Catalogue and Rule Chapter  
**Version:** 1.0  
**Status:** Draft for Review  
**Scope:** Actual content to be maintained in the mapping/configuration workbook  
**Classification:** Internal  
**Branding:** EXTEDO | a cormeo brand

---

## 1. Purpose

This document defines the actual business, regulatory and technical content that must be maintained in the eMAS mapping and configuration workbook.

It is the content blueprint for the workbook and identifies:

- required sheets;
- required columns;
- controlled values;
- rule categories;
- example records;
- phase applicability;
- expected JSON sections;
- open design questions.

This document does not create the workbook. It defines what the workbook must contain.

---

## 2. Recommended Workbook Chapters and Sheets

| Chapter | Sheet | Primary content |
|---|---|---|
| Governance | Home | Navigation, instructions and release status |
| Governance | Document_Control | Configuration identity, version and review information |
| Governance | Change_History | Controlled change records |
| Governance | Export_History | JSON export records |
| Global Configuration | Assessment_Profile | Supported phases, scenarios and default settings |
| Master Data | Value_Lists | Controlled dropdown values |
| Regulatory Classification | Regions | Region master data |
| Regulatory Classification | Authorities | Health authority master data |
| Regulatory Classification | Formats | Submission-format master data |
| Regulatory Classification | Dossier_Types | Dossier-type master data |
| Regulatory Classification | Classification_Rules | Region, format and type detection rules |
| Repository Validation | Folder_Rules | Dossier and sequence folder checks |
| Repository Validation | File_Rules | Mandatory, optional and conditional file checks |
| Repository Validation | XML_Detection_Rules | XML and namespace checks |
| Decision Logic | RAG_Rules | Green, Amber, Red, Unknown and Not Assessed criteria |
| Decision Logic | Confidence_Rules | Confidence evaluation |
| Estimation | Effort_Drivers | Pre-sales effort thresholds and scores |
| Decision Logic | Decision_Rules | Readiness and reconciliation outcome rules |
| Actions | Recommendations | Controlled findings and actions |
| Clarification | Questionnaire_Map | Customer questions and missing-information mapping |
| Input Compatibility | Aliases | Approved field and value aliases |
| Validation | Validation_Controls | Workbook validation definitions |
| Validation | Validation_Results | Validation output |
| JSON | JSON_Preview | Read-only runtime JSON preview |

---

# Chapter A — Governance Content

## 3. Home

### 3.1 Purpose

The Home sheet shall provide a professional landing page and controlled navigation.

### 3.2 Required content

- official EXTEDO logo;
- `EXTEDO | a cormeo brand`;
- product name;
- workbook name;
- configuration ID;
- workbook version;
- JSON schema version;
- lifecycle status;
- owner;
- reviewer;
- last validation date;
- last export date;
- concise workbook purpose;
- usage limitations;
- navigation links;
- command buttons:
  - Validate Mapping;
  - Preview JSON;
  - Export Runtime JSON;
  - Clear Validation Results;
  - Open Export Folder.

### 3.3 Key instruction text

> This workbook is an internal eMAS configuration-authoring tool. It maintains reviewed business and regulatory rules and exports one runtime JSON file directly from Excel. PowerShell does not read this workbook and does not generate the JSON.

---

## 4. Document_Control

### 4.1 Required fields

| Field | Description | Example |
|---|---|---|
| ConfigurationId | Stable configuration identifier | EMAS-CONFIG-001 |
| WorkbookTitle | Controlled workbook title | eMAS Mapping and Configuration Workbook |
| MappingVersion | Content version | 1.0 |
| SchemaVersion | JSON structure version | 1.0 |
| Status | Lifecycle status | Reviewed |
| Owner | Business owner | Migration Product Owner |
| PreparedBy | Author | DOMAIN\User |
| PreparedDate | Preparation date | 2026-07-12 |
| ReviewedBy | Reviewer | DOMAIN\Reviewer |
| ReviewedDate | Review date | 2026-07-13 |
| EffectiveFrom | Effective date | 2026-07-14 |
| SupersedesVersion | Prior mapping version | 0.9 |
| SupportedScriptMinVersion | Minimum compatible script | 1.0.0 |
| SupportedScriptMaxVersion | Maximum compatible script | 1.x |
| ChangeSummary | High-level change | Initial controlled baseline |
| ValidationStatus | Last validation outcome | Passed |
| ValidationRunId | Validation reference | VAL-20260712-001 |

---

## 5. Change_History

### 5.1 Required columns

- ChangeId;
- MappingVersion;
- ChangeDate;
- ChangedBy;
- ChangeType;
- AffectedSheet;
- AffectedRuleIds;
- PreviousValueSummary;
- NewValueSummary;
- ChangeReason;
- ChangeControlReference;
- ReviewedBy;
- ReviewDate;
- Status;
- Comment.

### 5.2 Controlled ChangeType values

- Added;
- Modified;
- Deactivated;
- Superseded;
- Reactivated;
- Corrected;
- Schema Change;
- Code List Change;
- Recommendation Change.

---

## 6. Export_History

### 6.1 Required columns

- ExportId;
- ExportDateTime;
- ExportedBy;
- ConfigurationId;
- MappingVersion;
- SchemaVersion;
- WorkbookStatus;
- ValidationRunId;
- ValidationResult;
- ExportFileName;
- ExportPath;
- ExportResult;
- FileSizeBytes;
- ChecksumAlgorithm;
- ChecksumValue;
- Comment.

---

# Chapter B — Global Configuration and Controlled Values

## 7. Assessment_Profile

### 7.1 Purpose

Defines supported phases, migration scenarios and global defaults shared by all scripts.

### 7.2 Required fields

- ProfileId;
- ProfileName;
- IsActive;
- Phase;
- MigrationScenarioCode;
- Description;
- ClassificationEnabled;
- FolderValidationEnabled;
- FileValidationEnabled;
- XmlDetectionEnabled;
- EffortScoringEnabled;
- ConfidenceEnabled;
- RecommendationsEnabled;
- DefaultConflictStrategy;
- DefaultMissingValueStatus;
- Comment.

### 7.3 Migration scenarios

| Code | Scenario | Typical scope |
|---|---|---|
| SQL_TO_SQL | eCTDmanager MS SQL to MS SQL | Database, archive, index and storage sizing |
| ACCESS_TO_SQL | MS Access to MS SQL | Database conversion and archive sizing |
| ORACLE_TO_SQL | Oracle to MS SQL | Database conversion, archive and technical complexity |
| EXTERNAL_DOSSIER | External eCTD system to eCTDmanager | Dossier and sequence import assessment |
| HYBRID | Database/archive plus dossier migration | Combined assessment |
| ARCHIVE_ONLY | Archive or storage sizing only | Volume and transfer assessment |
| UNKNOWN_REPOSITORY | Incomplete or unidentified source | Clarification and low-confidence assessment |

---

## 8. Value_Lists

### 8.1 Required value-list categories

- LifecycleStatus;
- Phase;
- MigrationScenario;
- RegionCode;
- AuthorityCode;
- FormatCode;
- DossierTypeCode;
- RuleType;
- IndicatorType;
- EvidenceStrength;
- RequirementLevel;
- RAGStatus;
- ConfidenceLevel;
- EffortLevel;
- Severity;
- Operator;
- LogicalOperator;
- ConflictStrategy;
- RecommendationAudience;
- Unit;
- ResultStatus;
- ExceptionCategory;
- QuestionPriority;
- ActionOwnerRole.

### 8.2 Standard controlled values

#### Phase

- PreSales;
- PreMigration;
- PostMigration;
- All.

#### Requirement level

- Mandatory;
- Optional;
- Conditional;
- Prohibited;
- NotApplicable.

#### RAG status

- Green;
- Amber;
- Red;
- Unknown;
- Not Assessed.

#### Confidence

- High;
- Medium;
- Low;
- Unknown.

#### Severity

- Critical;
- High;
- Medium;
- Low;
- Information.

#### Conflict strategy

- FirstMatch;
- HighestPriority;
- MostSevere;
- Aggregate;
- ManualReview.

---

# Chapter C — Regulatory Classification Content

## 9. Regions

### 9.1 Required columns

- RegionCode;
- RegionName;
- IsActive;
- Description;
- DefaultAuthorityCode;
- ExpectedRegionalFolder;
- ExpectedRegionalXml;
- DefaultConfidenceWeight;
- SortOrder;
- Comment.

### 9.2 Initial region values

- EU;
- US;
- Canada;
- UK;
- Switzerland;
- GCC;
- MENA;
- LATAM;
- EAEU;
- Rest of Europe;
- Other;
- Unknown.

### 9.3 Region-detection content

Rules should consider:

- regional XML names;
- XML namespaces;
- m1 regional folder names;
- known authority directories;
- path patterns;
- dossier-title indicators;
- metadata indicators;
- customer-provided region;
- agreement or conflict between indicators.

### 9.4 Example region rules

| RuleId | Target | Indicator | Pattern | Strength | Result |
|---|---|---|---|---|---|
| RULE-REG-EU-001 | Region | RelativePath | `m1/eu` | Strong | EU |
| RULE-REG-EU-002 | Region | FileName | `eu-regional.xml` | Strong | EU |
| RULE-REG-US-001 | Region | FileName | `us-regional.xml` | Strong | US |
| RULE-REG-CA-001 | Region | Namespace | approved Health Canada namespace | Strong | Canada |
| RULE-REG-UNK-001 | Region | NoStrongIndicator | true | None | Unknown |

---

## 10. Authorities

### 10.1 Required columns

- AuthorityCode;
- AuthorityName;
- RegionCode;
- Country;
- IsActive;
- KnownFolderIndicators;
- KnownFileIndicators;
- KnownNamespaceIndicators;
- SupportedFormats;
- Comment.

### 10.2 Example authorities

- EMA;
- FDA;
- Health Canada;
- MHRA;
- Swissmedic;
- GCC-DR;
- Eurasian Economic Commission;
- Other;
- Unknown.

---

## 11. Formats

### 11.1 Required columns

- FormatCode;
- FormatName;
- IsActive;
- Description;
- SequencePattern;
- BackboneFile;
- RegionalXmlExpected;
- ChecksumExpected;
- SupportedRegions;
- Comment.

### 11.2 Initial format values

- ICH eCTD 3.2.2;
- eCTD 4.0;
- EU eCTD;
- US FDA eCTD;
- Canada eCTD;
- UK eCTD;
- Swiss eCTD;
- GCC eCTD;
- EAEU eCTD;
- NeeS;
- VNeeS;
- ASMF-related submission;
- Medical Device Technical File;
- Non-eCTD electronic;
- Paper/Scanned;
- Other;
- Unknown.

### 11.3 Detection content

- numeric sequence patterns;
- presence and structure of index.xml;
- regional XML;
- XML namespace/version;
- module hierarchy;
- leaf-file references;
- NeeS/VNeeS folder patterns;
- medical-device technical-file patterns;
- eCTD 4.0 metadata indicators;
- absence of recognized electronic backbone.

---

## 12. Dossier_Types

### 12.1 Required columns

- DossierTypeCode;
- DossierTypeName;
- IsActive;
- Description;
- StrongIndicators;
- WeakIndicators;
- SupportedFormats;
- SupportedRegions;
- Comment.

### 12.2 Initial dossier types

- Human;
- Veterinary;
- Investigational;
- Post-Marketing;
- Medical Device;
- Biologics;
- Vaccines;
- Blood Products;
- Other;
- Unknown.

### 12.3 Detection content

- customer-provided metadata;
- application/submission type;
- known module patterns;
- dossier naming conventions;
- authority-specific classifications;
- investigational indicators;
- veterinary indicators;
- device technical-file structure;
- biologic/vaccine/blood-product metadata.

---

## 13. Classification_Rules

### 13.1 Required columns

- RuleId;
- RuleVersion;
- IsActive;
- Status;
- Priority;
- Phase;
- ClassificationTarget;
- RegionScope;
- AuthorityScope;
- FormatScope;
- TypeScope;
- ConditionGroupId;
- LogicalOperator;
- IndicatorType;
- EvidenceField;
- Operator;
- IndicatorPattern;
- ExpectedValue;
- EvidenceStrength;
- ResultCode;
- ConfidenceImpact;
- ConflictStrategy;
- RecommendationCode;
- RequirementReference;
- SourceReference;
- Comment.

### 13.2 Classification targets

- Region;
- Authority;
- Format;
- DossierType.

### 13.3 Evidence types

- Folder;
- File;
- RelativePath;
- FileExtension;
- XMLRoot;
- XMLNamespace;
- XMLElement;
- XMLAttribute;
- Metadata;
- CustomerProvided;
- DerivedCount;
- DerivedPattern.

---

# Chapter D — Dossier and Repository Validation Content

## 14. Folder_Rules

### 14.1 Purpose

Defines how eMAS checks dossier roots, sequence folders, module folders and authority-specific substructures.

### 14.2 Required columns

- RuleId;
- RuleVersion;
- IsActive;
- Priority;
- Phase;
- Region;
- Authority;
- Format;
- DossierType;
- ParentPathPattern;
- FolderNamePattern;
- RelativePathPattern;
- RequirementLevel;
- ConditionGroupId;
- ConditionExpressionReference;
- MinimumOccurrences;
- MaximumOccurrences;
- AllowEmpty;
- MissingImpact;
- EmptyImpact;
- UnexpectedImpact;
- InaccessibleImpact;
- EffortImpact;
- RecommendationCode;
- Comment.

### 14.3 Folder checks to include

#### Dossier-root checks

- valid dossier root exists;
- dossier root is accessible;
- dossier root contains one or more valid sequence folders where expected;
- no unexpected extra hierarchy prevents sequence detection;
- duplicate dossier-root names are identified;
- nested same-name dossier folders are identified.

#### Sequence-folder checks

- numeric sequence format such as `0000`, `0001`, `0002`;
- allowed authority-specific variations;
- duplicate sequence numbers;
- missing initial sequence where relevant;
- non-contiguous sequence numbering as warning or information;
- empty sequence folder;
- inaccessible sequence folder;
- sequence folder depth.

#### Module checks

- m1 presence by region/format;
- m2 presence where mandatory;
- m3 presence where mandatory;
- m4 presence where mandatory;
- m5 presence where mandatory;
- regional subfolder under m1;
- empty module folder;
- unknown folder under a module;
- prohibited folder location;
- excessive branch depth.

### 14.4 Example folder rules

| RuleId | Scope | Requirement | Impact |
|---|---|---|---|
| RULE-FLD-SEQ-001 | eCTD | Sequence folder matches `^[0-9]{4}$` | Red if no valid sequence exists |
| RULE-FLD-M1-EU-001 | EU eCTD | `m1/eu` mandatory | Red or Amber by phase |
| RULE-FLD-M2-001 | ICH eCTD | `m2` mandatory | Red if absent |
| RULE-FLD-UNKNOWN-001 | All | Unknown folder count exceeds threshold | Amber and effort increase |
| RULE-FLD-EMPTY-001 | All | Mandatory module is empty | Amber or Red by phase |

---

## 15. File_Rules

### 15.1 Required columns

- RuleId;
- RuleVersion;
- IsActive;
- Priority;
- Phase;
- Region;
- Authority;
- Format;
- DossierType;
- RelativeFolderPattern;
- FileNamePattern;
- Extension;
- RequirementLevel;
- MinimumOccurrences;
- MaximumOccurrences;
- MustBeReadable;
- ZeroByteAllowed;
- ChecksumRequired;
- ReferencedFileRequired;
- MissingImpact;
- UnreadableImpact;
- ZeroByteImpact;
- DuplicateImpact;
- RecommendationCode;
- Comment.

### 15.2 File checks to include

- index.xml;
- index-md5.txt or equivalent checksum file;
- regional XML;
- XML readability;
- zero-byte file;
- duplicate filename in the same scope;
- same-name ZIP file and folder;
- invalid or unexpected extension;
- missing referenced leaf file;
- orphaned content file;
- checksum presence;
- expected published PDF/content files;
- application forms where applicable;
- authority-specific files.

### 15.3 Example file rules

| RuleId | File | Requirement | Typical impact |
|---|---|---|---|
| RULE-FILE-IDX-001 | index.xml | Mandatory for eCTD sequence | Red if missing |
| RULE-FILE-MD5-001 | index-md5.txt | Expected where applicable | Amber if missing |
| RULE-FILE-REG-EU-001 | eu-regional.xml | Mandatory for EU regional structure | Red/Amber based on phase |
| RULE-FILE-ZERO-001 | Any file | Size must be greater than zero | Amber or Red based on file type |
| RULE-FILE-REF-001 | Referenced leaf | Must exist and be readable | Red in pre-migration |

---

## 16. XML_Detection_Rules

### 16.1 Required columns

- RuleId;
- IsActive;
- Priority;
- Phase;
- FileNamePattern;
- XmlRole;
- RootElement;
- NamespacePattern;
- ElementPath;
- AttributeName;
- Operator;
- ExpectedValue;
- ParserHint;
- EvidenceStrength;
- ClassificationResult;
- RAGImpact;
- RecommendationCode;
- Comment.

### 16.2 XML roles

- Backbone;
- Regional;
- Metadata;
- ChecksumManifest;
- Other.

### 16.3 XML checks

- file can be opened;
- XML is well formed;
- expected root element exists;
- expected namespace exists;
- required regional metadata exists;
- expected referenced-file nodes exist;
- version indicator is recognized;
- authority-specific identifier is recognized.

---

# Chapter E — RAG, Confidence and Decision Content

## 17. RAG_Rules

### 17.1 Required columns

- RuleId;
- IsActive;
- Priority;
- Phase;
- FindingCategory;
- FindingCode;
- ConditionGroupId;
- EvidenceField;
- Operator;
- ExpectedValue;
- RAGResult;
- Severity;
- OverrideAllowed;
- ExceptionCategory;
- RecommendationCode;
- Comment.

### 17.2 Core RAG criteria

#### Green

Use when:

- structure is recognized;
- mandatory sequence structure is present;
- mandatory files are present;
- mandatory modules are present;
- required regional indicators are present;
- no material finding exists.

#### Amber

Use when:

- structure is recognized but incomplete;
- warning-only checksum is missing;
- regional XML is missing but other evidence exists;
- optional or conditional content is incomplete;
- unknown folders require review;
- a mandatory folder is empty but assessment remains possible;
- an inaccessible subfolder creates partial uncertainty;
- long-path or zero-byte findings require review.

#### Red

Use when:

- no valid sequence folders exist;
- index.xml is missing where mandatory;
- mandatory modules are missing;
- hierarchy is materially corrupted;
- required referenced files are missing;
- source is inaccessible at a mandatory root;
- evidence is insufficient for meaningful migration assessment;
- a critical pre-migration blocker exists.

#### Unknown

Use when:

- evidence exists but rules conflict;
- no classification rule matches;
- evidence is too weak to assign a result.

#### Not Assessed

Use when:

- required input was not supplied;
- a check is outside the selected phase;
- a check is not applicable to the identified format or scenario.

### 17.3 Aggregation content

The workbook must define how item-level RAG becomes:

- sequence-level RAG;
- dossier-level RAG;
- repository-level RAG;
- report-summary RAG.

Potential strategies:

- most severe finding wins;
- critical rules override aggregate score;
- weighted aggregation;
- manual review for conflicting outcomes.

---

## 18. Confidence_Rules

### 18.1 Required columns

- RuleId;
- IsActive;
- ClassificationTarget;
- MinimumStrongIndicators;
- MinimumMediumIndicators;
- MinimumTotalIndicators;
- MaximumConflicts;
- RequiredAgreementFields;
- ConfidenceResult;
- ScoreMinimum;
- ScoreMaximum;
- Comment.

### 18.2 Proposed confidence principles

| Confidence | Proposed basis |
|---|---|
| High | At least two independent strong indicators agree and no material conflict exists |
| Medium | One strong indicator or multiple medium indicators agree |
| Low | Only weak or partial evidence exists |
| Unknown | No valid evidence or unresolved conflict prevents classification |

---

## 19. Decision_Rules

### 19.1 Purpose

Defines shared controlled decision terminology while each phase script retains its own orchestration logic.

### 19.2 Required columns

- RuleId;
- IsActive;
- Phase;
- DecisionArea;
- InputMetric;
- Operator;
- ExpectedValue;
- RequiredRAG;
- BlockerFlag;
- ExceptionAllowed;
- DecisionResult;
- RecommendationCode;
- Priority;
- Comment.

### 19.3 Pre-migration decisions

- Ready;
- Ready with Accepted Exceptions;
- Blocked.

Suggested content:

- any unresolved Critical blocker results in Blocked;
- accepted eligible exceptions may convert specific blockers/warnings to Ready with Accepted Exceptions;
- no blockers and all mandatory prerequisites available results in Ready;
- missing mandatory source input results in Blocked or Not Assessed according to scope.

### 19.4 Post-migration decisions

- Reconciled;
- Reconciled with Accepted Exceptions;
- Review Required;
- Not Reconciled.

Suggested content:

- all expected dossiers and sequences present with acceptable import status results in Reconciled;
- only approved differences remain results in Reconciled with Accepted Exceptions;
- warnings or unresolved non-critical differences result in Review Required;
- missing expected dossiers/sequences or critical import errors result in Not Reconciled.

---

# Chapter F — Effort Estimation Content

## 20. Effort_Drivers

### 20.1 Required columns

- DriverId;
- IsActive;
- DriverCategory;
- DriverName;
- Phase;
- MigrationScenario;
- MetricName;
- Operator;
- LowerBound;
- UpperBound;
- LowerInclusive;
- UpperInclusive;
- Unit;
- ScoreImpact;
- EffortLevelImpact;
- ConfidenceImpact;
- RecommendationCode;
- Comment.

### 20.2 Driver categories and content

#### Volume

- dossier count;
- sequence count;
- file count;
- folder count;
- export size;
- archive size;
- index size;
- database size.

#### Repository shape

- maximum folder depth;
- average branch count;
- largest dossier;
- largest sequence;
- largest module;
- unknown-folder count;
- empty-folder count.

#### Regulatory mix

- number of regions;
- number of formats;
- number of dossier types;
- percentage of Unknown classifications;
- mixed-authority count;
- ASMF-related count;
- FDA/EU/other count.

#### Quality and completeness

- Red dossier count;
- Amber dossier count;
- missing index.xml count;
- missing checksum count;
- missing regional XML count;
- missing mandatory-module count;
- zero-byte-file count;
- long-path count.

#### Migration approach

- SQL to SQL;
- Access to SQL;
- Oracle to SQL;
- external dossier import;
- hybrid;
- archive only;
- unknown source.

#### Storage and transfer

- local disk;
- UNC path;
- network latency risk;
- cloud-mounted storage;
- inaccessible roots;
- staging availability;
- backup availability;
- estimated transfer volume.

#### Customer readiness

- unanswered questionnaire count;
- unknown source-system details;
- unconfirmed export completeness;
- missing backup confirmation;
- missing staging confirmation;
- unresolved exclusions;
- unapproved exceptions.

#### Technical risk

- unreadable XML;
- missing referenced files;
- same-name ZIP/folder findings;
- nested duplicate folders;
- invalid sequence naming;
- unsupported format indicators.

### 20.3 Overall effort bands

- Very Low;
- Low;
- Medium;
- High;
- Very High.

The exact score ranges remain to be finalized.

---

# Chapter G — Recommendations and Clarifications

## 21. Recommendations

### 21.1 Required columns

- RecommendationCode;
- IsActive;
- Title;
- FindingCategory;
- Severity;
- Phase;
- CustomerFacingText;
- ConsultantFacingText;
- RecommendedNextAction;
- SuggestedOwnerRole;
- DefaultPriority;
- RequiresCustomerClarification;
- FollowUpQuestionId;
- Comment.

### 21.2 Recommendation categories

- Missing Input;
- Folder Structure;
- Missing Mandatory File;
- XML Issue;
- Classification Uncertainty;
- Access and Permission;
- Long Path;
- Zero-Byte File;
- Referenced File;
- Backup and Staging;
- Storage and Transfer;
- Data Cleanup;
- Accepted Exception;
- Import Warning;
- Import Error;
- Reconciliation Difference.

### 21.3 Example recommendation

| Field | Example |
|---|---|
| RecommendationCode | REC-FILE-IDX-001 |
| Title | Provide or regenerate missing backbone XML |
| Severity | Critical |
| Phase | PreMigration |
| CustomerFacingText | The sequence does not contain the required backbone XML file. Please confirm whether the export is complete. |
| ConsultantFacingText | Treat as a migration blocker until source completeness is confirmed. |
| RecommendedNextAction | Request corrected export or approve exclusion through the project process. |
| SuggestedOwnerRole | Customer Technical Owner |

---

## 22. Questionnaire_Map

### 22.1 Required columns

- QuestionId;
- IsActive;
- Phase;
- MigrationScenario;
- TriggerFindingCode;
- TriggerMetric;
- Operator;
- TriggerValue;
- QuestionText;
- Reason;
- Priority;
- OwnerRole;
- EstimateImpact;
- ReadinessImpact;
- Comment.

### 22.2 Question topics

- source system and version;
- source database type;
- export completeness;
- archive and index locations;
- database size;
- number of environments;
- supported regions and formats;
- known exclusions;
- backup availability;
- staging availability;
- accepted exceptions;
- customer access restrictions;
- expected migration window;
- transfer method.

---

# Chapter H — Aliases and Compatibility

## 23. Aliases

### 23.1 Required columns

- AliasId;
- IsActive;
- AliasType;
- SourceName;
- CanonicalName;
- SourceSystem;
- Phase;
- CaseSensitive;
- Priority;
- Comment.

### 23.2 Alias types

- ColumnName;
- RegionName;
- AuthorityName;
- FormatName;
- DossierTypeName;
- StatusValue;
- FolderName;
- FileName.

### 23.3 Important source-preservation rule

Aliases are for interpretation only. The original source value must remain unchanged in evidence and raw-data sheets.

The source column `DossierDirecotry` must remain supported exactly as provided in the source template.

---

# Chapter I — Validation Content

## 24. Validation_Controls

### 24.1 Required columns

- ValidationControlId;
- IsActive;
- ValidationCategory;
- TargetSheet;
- TargetTable;
- TargetColumn;
- ValidationType;
- Severity;
- Condition;
- Message;
- CorrectiveAction;
- BlocksExport;
- Comment.

### 24.2 Required validation controls

- required sheet exists;
- required table exists;
- required column exists;
- required value populated;
- unique RuleId;
- unique RecommendationCode;
- valid foreign-key reference;
- valid enum value;
- active referenced object;
- numeric value within range;
- threshold overlap;
- threshold gap;
- valid operator;
- valid unit;
- valid phase;
- valid conflict strategy;
- valid status transition;
- missing recommendation reference;
- orphan alias;
- incompatible schema/script version;
- duplicate active rule;
- invalid condition group;
- unsupported nested condition depth.

---

## 25. Validation_Results

### 25.1 Required columns

- ValidationRunId;
- ValidationDateTime;
- ValidatedBy;
- ValidationId;
- Severity;
- Sheet;
- Table;
- RowNumber;
- ObjectId;
- Field;
- Message;
- CorrectiveAction;
- BlocksExport;
- Status;
- Comment.

---

# Chapter J — JSON Content Mapping

## 26. Workbook-to-JSON mapping

| Workbook content | JSON section |
|---|---|
| Document_Control | configuration |
| Value_Lists | valueLists |
| Regions | regions |
| Authorities | authorities |
| Formats | formats |
| Dossier_Types | dossierTypes |
| Classification_Rules | classificationRules |
| Folder_Rules | folderRules |
| File_Rules | fileRules |
| XML_Detection_Rules | xmlDetectionRules |
| RAG_Rules | ragRules |
| Confidence_Rules | confidenceRules |
| Effort_Drivers | effortDrivers |
| Decision_Rules | decisionRules |
| Recommendations | recommendations |
| Questionnaire_Map | questionnaireMap |
| Aliases | aliases |

The following shall not be included as executable runtime content:

- Validation_Results;
- JSON_Preview;
- VBA code;
- workbook formulas;
- hidden technical notes;
- Export_History;
- inactive or retired rules.

---

# Chapter K — Open Questions

## 27. Rule behaviour

| ID | Open question |
|---|---|
| OQ-CONT-001 | Should lower numeric priority mean earlier execution, or should higher number mean higher priority? |
| OQ-CONT-002 | Which conflict strategy applies by default to classification, RAG, confidence, effort and decisions? |
| OQ-CONT-003 | Should Red always override Amber and Green, or may accepted exceptions alter the displayed RAG? |
| OQ-CONT-004 | How many nested AND/OR condition levels are required? |
| OQ-CONT-005 | Should classification choose one result only or support multiple classifications with confidence? |

## 28. Thresholds and scoring

| ID | Open question |
|---|---|
| OQ-CONT-010 | What are the approved dossier, sequence, file-count and size thresholds for effort bands? |
| OQ-CONT-011 | Should overall effort be a weighted score, a highest-driver result or a hybrid model? |
| OQ-CONT-012 | Are threshold boundaries inclusive by default? |
| OQ-CONT-013 | Should different migration scenarios use separate thresholds? |
| OQ-CONT-014 | Should effort scores be visible in customer-facing pre-sales reports or internal only? |

## 29. Folder and file rules

| ID | Open question |
|---|---|
| OQ-CONT-020 | Is index-md5.txt mandatory or warning-only for every supported eCTD format? |
| OQ-CONT-021 | Which modules are mandatory by region, format and dossier type? |
| OQ-CONT-022 | How should non-contiguous sequence numbering affect RAG and effort? |
| OQ-CONT-023 | What unknown-folder count or percentage should trigger Amber or Red? |
| OQ-CONT-024 | When should an empty module be Amber versus Red? |
| OQ-CONT-025 | Which file extensions should be considered prohibited, unsupported or informational? |

## 30. Exceptions and overrides

| ID | Open question |
|---|---|
| OQ-CONT-030 | Which findings may be overridden by an accepted exception? |
| OQ-CONT-031 | Should an accepted exception change the original finding status or only the final decision? |
| OQ-CONT-032 | Should exception categories be maintained in this workbook? |
| OQ-CONT-033 | What evidence and review fields are required for an accepted exception? |

## 31. Lifecycle and JSON

| ID | Open question |
|---|---|
| OQ-CONT-040 | Can Reviewed configurations be exported, or only Effective configurations? |
| OQ-CONT-041 | Should superseded rule metadata be included in JSON for traceability? |
| OQ-CONT-042 | Should recommendation rationale and source references be exported to JSON? |
| OQ-CONT-043 | Should report configuration be included in the same JSON? |
| OQ-CONT-044 | Which schema changes are considered backward compatible? |

---

## 32. Content Completion Criteria

The mapping/configuration content is ready for workbook implementation when:

1. all master code lists are approved;
2. all required sheet columns are finalized;
3. rule priority semantics are approved;
4. conflict handling is approved;
5. conditional-rule representation is approved;
6. region, format and type rules are populated;
7. folder and file matrices are populated by region/format/type;
8. RAG criteria are approved;
9. confidence rules are approved;
10. effort thresholds and scoring are approved;
11. recommendation texts are reviewed;
12. accepted-exception behaviour is approved;
13. JSON property names and schema are frozen;
14. validation controls are defined;
15. sample valid and invalid rule sets are available for testing.
