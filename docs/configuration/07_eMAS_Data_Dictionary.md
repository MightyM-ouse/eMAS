# eMAS Logical Data Dictionary

**Version:** 1.0  
**Status:** Effective Logical-Model Contract  
**Effective date:** 2026-07-13  
**Owner:** Product Owner and Technical Architect  
**Decision references:** RM-001–RM-027; JSON-001–JSON-023; REG-003–REG-014  
**Canonical references:** Enterprise Requirements v3.1; Mapping Functional Requirements v3.0; Mapping Technical Requirements v3.0; Mapping Content Catalogue v3.0; Runtime JSON Contract; Normalized Relationship Matrix v1.0

## 1. Purpose

This document freezes the logical entities, fields, keys, data types, requiredness and serialization conventions used by the eMAS mapping workbook and runtime JSON.

It is the field-level companion to the [Normalized Relationship Matrix](06_eMAS_Normalized_Relationship_Matrix.md). The matrix controls relationships and cardinality; this dictionary controls entity and attribute meaning.

Detailed regulatory values, rule content, effort weights, confidence weights, thresholds and exception-role assignments remain subject to the approved SME workflow. Their structures are frozen; their business values are not made Effective by this document.

## 2. Naming and serialization conventions

| Area | Convention |
|---|---|
| Logical entity names | PascalCase words separated with underscores, for example `Rule_Phase_Assignment` |
| Excel table names | `tbl` plus PascalCase, for example `tblRulePhaseAssignments` |
| Workbook columns | PascalCase, for example `RuleId` |
| JSON properties | camelCase, for example `ruleId` |
| Stable identifiers | Uppercase-compatible ASCII code pattern `^[A-Z0-9][A-Z0-9_.-]*$` unless a specific field states otherwise |
| Display text | Unicode string; never used as a foreign key |
| Boolean | `True`/`False` in workbook; JSON Boolean at runtime |
| Date | ISO `YYYY-MM-DD` |
| Date-time | UTC ISO 8601 with `Z` |
| Decimal | Culture-invariant period decimal separator |
| Empty optional value | Empty cell in workbook; omitted or null only where the JSON Schema explicitly permits it |
| Controlled export encoding | UTF-8 without BOM |

## 3. Logical data types

| Type | Definition | Validation |
|---|---|---|
| Identifier | Stable technical ID | Required pattern; immutable after Effective release |
| Code | Controlled technical value | Must resolve to `Value_Lists` or approved master data |
| String | Short human-readable text | Trimmed; length controlled by implementation profile |
| LongText | Description, rationale or guidance | Unicode; no executable expressions |
| SemVer | Semantic version | `MAJOR.MINOR.PATCH`, optional permitted prerelease/build suffix |
| Integer | Whole number | Culture invariant; range constrained by field |
| Decimal | Numeric decimal | Period separator; no locale grouping |
| Boolean | True/False | No Yes/No free-text alternatives |
| Date | Calendar date | ISO 8601 date |
| DateTimeUtc | UTC timestamp | ISO 8601 ending in `Z` |
| Path | Windows or relative path | Used only where allowed; credentials prohibited |
| Pattern | Approved regular expression or pattern syntax | Must be validated; arbitrary code prohibited |
| HashSha256 | SHA-256 digest | Exactly 64 hexadecimal characters |
| EntityType | Code identifying a frozen entity type | Must resolve to the entity inventory |
| JsonValue | Typed scalar or schema-approved object | Interpretation governed by a discriminator and schema |

## 4. Common field profiles

### 4.1 Controlled-content profile

Where an entity declares the controlled-content profile, it includes:

| Field | Type | Required | Meaning |
|---|---|---:|---|
| Status | RuleLifecycleStatus or approved entity status | Yes | Governs eligibility; editable `IsActive` is prohibited |
| EffectiveFrom | Date | Conditional | Inclusive start; required for Effective runtime content |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Conditional | Regulatory, requirement, decision or approved source reference |
| Description | LongText | No | Business meaning |

### 4.2 Ordered-content profile

Where ordering is required:

| Field | Type | Required | Meaning |
|---|---|---:|---|
| Sequence | Integer | Yes | Deterministic order, minimum 0 |
| SortOrder | Integer | Conditional | Display ordering for controlled values or master data |
| Priority | Integer | Conditional | Lower value executes first; normally increments of 100 |

### 4.3 Audit-reference profile

| Field | Type | Required | Meaning |
|---|---|---:|---|
| ApprovalReference | String | Conditional | Controlled approval evidence |
| ChangeControlReference | String | Conditional | External or repository-native change reference |
| Comment | LongText | No | Non-executable note |

## 5. Entity inventory and ownership

| Entity | Primary key | Owner | Runtime inclusion |
|---|---|---|---|
| Document_Control | DocumentId | Documentation Owner | Configuration metadata |
| Workbook_Control | ConfigurationId | Product Owner | `configuration` |
| Change_History | ChangeId | Documentation Owner | No |
| Change_History_Items | ChangeItemId | Documentation Owner | No |
| Validation_Runs | ValidationRunId | Technical Architect | Release evidence only |
| Validation_Results | ValidationResultId | Technical Architect | No |
| Export_History | ExportId | Configuration Owner | No |
| Value_Lists | ValueListEntryId | Product Owner | `valueLists` |
| Field_Catalogue | FieldCode | Technical Architect | `fieldCatalogue` |
| Field_Operator_Links | FieldOperatorLinkId | Technical Architect | Folded into field definitions |
| Field_Phase_Links | FieldPhaseLinkId | Technical Architect | Folded into field definitions |
| Metric_Catalogue | MetricCode | Migration/Product Owner | `metricCatalogue` |
| Metric_Phase_Links | MetricPhaseLinkId | Migration/Product Owner | Folded into metric definitions |
| Report_Definitions | ReportDefinitionId | Product Owner and QA Lead | `reportTerminology` |
| Aliases | AliasId | Product Owner / relevant SME | `aliases` |
| Regulatory and business master-data entities | Entity-specific code | Product Owner / Regulatory SME | `masterData` |
| Master_Data_Relationships | RelationshipId | Product Owner / Regulatory SME | `relationships` |
| Rules | RuleId | Product Owner / relevant SME | `rules` |
| Rule_Phase_Assignment | RulePhaseId | Product Owner | `rulePhases` |
| Condition_Groups | ConditionGroupId | Product Owner / Technical Architect | `conditionGroups` |
| Rule_Conditions | ConditionId | Product Owner / Technical Architect | `ruleConditions` |
| Rule_Outputs | RuleOutputId | Product Owner | `ruleOutputs` |
| Rule_Supersession | SupersessionId | Product Owner | Schema-approved relationship/history |
| Findings | FindingCode | Product Owner | `findings` |
| Recommendations | RecommendationCode | Product Owner | `recommendations` |
| Finding_Recommendation_Links | LinkId | Product Owner | `findingRecommendationLinks` |
| Conflict_Policies | ConflictPolicyId | Product Owner / Technical Architect | Policy data referenced by rules |
| Exception_Policies | ExceptionPolicyId | Product Owner / relevant SME | `exceptionPolicies` |
| RAG_Policies | RagPolicyId | Product Owner | Policy data |
| Confidence_Policies | ConfidencePolicyId | Product Owner / Migration SME | Policy data |
| Effort_Driver_Definitions | EffortDriverId | Product Owner / Migration SME | Policy data |
| Effort_Driver_Phase_Links | EffortDriverPhaseLinkId | Product Owner / Migration SME | Folded into driver applicability |
| Effort_Thresholds | EffortThresholdId | Product Owner / Migration SME | Policy data |
| Decision_Policies | DecisionPolicyId | Product Owner | Policy data |
| Questionnaire_Map | QuestionnaireMapId | Product Owner | Clarification data |
| Validation_Controls | ValidationControlId | Technical Architect | Normally no |
| Rule_Index | RuleId | Generated | No |
| Technical_Settings | SettingCode | Technical Architect | Approved metadata only |
| JSON_Preview | View only | Technical Architect | No |

# Chapter A — Governance and evidence

## 6. Document_Control — `tblDocumentControl`

One current document-control record governs the workbook document.

| Field | Type | Required | Rules |
|---|---|---:|---|
| DocumentId | Identifier | Yes | Primary key |
| DocumentVersion | SemVer | Yes | Version of the workbook document/specification |
| Status | DocumentStatus | Yes | Draft, InReview, Approved, Final, Effective, Superseded or Archived |
| Owner | String | Yes | Document owner role or identity |
| PreparedBy | String | Yes | Preparing identity |
| PreparedDate | Date | Yes | Preparation date |
| ReviewedBy | String | Conditional | Required for Approved/Final/Effective |
| ReviewedDate | Date | Conditional | Required when ReviewedBy is populated |
| EffectiveFrom | Date | Conditional | Required for Effective |
| ChangeSummary | LongText | Yes | Summary of current revision |

## 7. Workbook_Control — `tblWorkbookControl`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ConfigurationId | Identifier | Yes | Primary key; stable across mapping releases |
| MappingVersion | SemVer | Yes | Business/configuration release version |
| SchemaVersion | SemVer | Yes | Runtime JSON schema version |
| SourceWorkbookVersion | SemVer | Yes | XLSM implementation version |
| MinimumEngineVersion | SemVer | Yes | Minimum compatible PowerShell engine |
| MaximumTestedEngineVersion | SemVer | No | Highest tested compatible engine |
| ExportType | ExportType | Yes | DEV or CONTROLLED |
| Status | RuleLifecycleStatus | Yes | Reviewed for DEV, Effective for CONTROLLED |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| Owner | String | Yes | Configuration owner |
| ApprovalReference | String | Conditional | Required for controlled release |
| ChangeSummary | LongText | Yes | Mapping-release summary |

## 8. Change_History — `tblChangeHistory`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ChangeId | Identifier | Yes | Primary key |
| MappingVersion | SemVer | Yes | Version receiving the change |
| ChangeDateTimeUtc | DateTimeUtc | Yes | Change timestamp |
| ChangedBy | String | Yes | Windows or controlled identity |
| ChangeType | Code | Yes | Controlled change category |
| ChangeReason | LongText | Yes | Reason for change |
| ChangeControlReference | String | Conditional | Required where formal change control applies |
| ReviewedBy | String | Conditional | Reviewer identity |
| ReviewDateTimeUtc | DateTimeUtc | Conditional | Required with ReviewedBy |
| Status | DocumentStatus | Yes | Status of change record |
| Comment | LongText | No | Additional note |

## 9. Change_History_Items — `tblChangeHistoryItems`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ChangeItemId | Identifier | Yes | Primary key |
| ChangeId | Identifier | Yes | FK to Change_History |
| ObjectType | EntityType | Yes | Frozen entity type |
| ObjectId | Identifier | Yes | Referenced object key |
| ObjectRevision | Integer | Conditional | Required where entity is revisioned |
| SourceTable | String | Yes | Excel table name |
| SourceRow | Integer | Conditional | Source row at time of change |
| PreviousValueSummary | LongText | No | Human-readable prior state |
| NewValueSummary | LongText | Yes | Human-readable new state |

## 10. Validation_Runs — `tblValidationRuns`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ValidationRunId | Identifier | Yes | Primary key |
| StartedAtUtc | DateTimeUtc | Yes | Validation start |
| CompletedAtUtc | DateTimeUtc | Conditional | Required after completion |
| TriggeredBy | String | Yes | Execution identity |
| ConfigurationId | Identifier | Yes | Configuration validated |
| MappingVersion | SemVer | Yes | Mapping version validated |
| SchemaVersion | SemVer | Yes | Schema version validated |
| ValidationProfile | Code | Yes | DEV or CONTROLLED validation profile |
| Result | Code | Yes | Passed, PassedWithWarnings or Failed |
| ErrorCount | Integer | Yes | Minimum 0 |
| WarningCount | Integer | Yes | Minimum 0 |
| BlockingCount | Integer | Yes | Minimum 0 |
| AcknowledgedWarningCount | Integer | Yes | Minimum 0 |

## 11. Validation_Results — `tblValidationResults`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ValidationResultId | Identifier | Yes | Primary key |
| ValidationRunId | Identifier | Yes | FK to Validation_Runs |
| ValidationControlId | Identifier | Yes | FK to Validation_Controls |
| Severity | Severity | Yes | Controlled value |
| EntityType | EntityType | Conditional | Required for row-specific result |
| EntityId | Identifier | Conditional | Required with EntityType |
| SourceTable | String | Conditional | Workbook table |
| SourceRow | Integer | Conditional | Workbook row |
| Message | LongText | Yes | Resolved validation message |
| IsBlocking | Boolean | Yes | Export-blocking indicator |
| AcknowledgedBy | String | Conditional | Allowed only for acknowledgeable warning |
| AcknowledgedAtUtc | DateTimeUtc | Conditional | Required with AcknowledgedBy |
| AcknowledgementReason | LongText | Conditional | Required with acknowledgement |

## 12. Export_History — `tblExportHistory`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ExportId | Identifier | Yes | Primary key |
| ExportDateTimeUtc | DateTimeUtc | Yes | Export timestamp |
| ExportedBy | String | Yes | Windows identity |
| ExportType | ExportType | Yes | DEV or CONTROLLED |
| ConfigurationId | Identifier | Yes | FK to Workbook_Control |
| MappingVersion | SemVer | Yes | Must match validated configuration |
| SchemaVersion | SemVer | Yes | Must match validated configuration |
| SourceWorkbookVersion | SemVer | Yes | Must match validated configuration |
| ValidationRunId | Identifier | Yes | FK to completed eligible Validation_Runs |
| ExportFileName | String | Yes | CONTROLLED = `eMAS_Runtime_Config.json`; DEV includes `DEV` |
| ExportPath | Path | Yes | Export destination |
| ExportResult | Code | Yes | Success or Failure |
| FileSizeBytes | Integer | Conditional | Required on success; minimum 1 |
| ChecksumAlgorithm | Code | Conditional | SHA-256 for controlled release |
| ChecksumValue | HashSha256 | Conditional | Required for controlled release |
| WarningAcknowledgementReference | String | Conditional | Required when warnings were acknowledged |
| ReleaseManifestReference | String | Conditional | Required when packaged for release |

# Chapter B — Controlled catalogues

## 13. Value_Lists — `tblValueLists`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ValueListEntryId | Identifier | Yes | Primary key |
| ListName | Identifier | Yes | Controlled list category |
| Code | Code | Yes | Unique with ListName |
| DisplayValue | String | Yes | User-facing text |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective runtime value |
| EffectiveTo | Date | No | Exclusive end |
| SortOrder | Integer | Yes | Display order |
| Description | LongText | No | Meaning |
| SourceReference | String | Conditional | Required for regulated/externally governed values |

## 14. Field_Catalogue — `tblFieldCatalogue`

| Field | Type | Required | Rules |
|---|---|---:|---|
| FieldCode | Identifier | Yes | Primary key |
| DisplayName | String | Yes | User-facing field name |
| DataType | DataType | Yes | String, Code, Integer, Decimal, Boolean, Date, DateTime or Path |
| ValueSource | ValueSource | Yes | Observed, CustomerProvided, Imported, Derived or Assumed |
| ProducingComponent | String | Yes | Engine module or input source |
| EvaluationOrder | Integer | Yes | Minimum 0 |
| IsSensitive | Boolean | Yes | Controls logging/report handling |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| Description | LongText | Yes | Business meaning |
| SourceReference | String | Conditional | Requirement or approved source |

Allowed operators and phases are maintained only through link entities.

## 15. Field_Operator_Links — `tblFieldOperatorLinks`

| Field | Type | Required | Rules |
|---|---|---:|---|
| FieldOperatorLinkId | Identifier | Yes | Primary key |
| FieldCode | Identifier | Yes | FK to Field_Catalogue |
| OperatorCode | Code | Yes | FK to Operator value list |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | No | Requirement or design reference |

`FieldCode + OperatorCode` must be unique for overlapping effective dates.

## 16. Field_Phase_Links — `tblFieldPhaseLinks`

| Field | Type | Required | Rules |
|---|---|---:|---|
| FieldPhaseLinkId | Identifier | Yes | Primary key |
| FieldCode | Identifier | Yes | FK to Field_Catalogue |
| Phase | Phase | Yes | Explicit phase; `All` prohibited in export |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |

## 17. Metric_Catalogue — `tblMetricCatalogue`

| Field | Type | Required | Rules |
|---|---|---:|---|
| MetricCode | Identifier | Yes | Primary key |
| DisplayName | String | Yes | User-facing name |
| DataType | DataType | Yes | Integer or Decimal |
| Unit | Code | Yes | Controlled unit |
| CalculationSource | String | Yes | Producing component/formula identifier, not executable code |
| RequiredForCompleteBanding | Boolean | Yes | Indicates whether missing metric prevents complete banding |
| RoundingRule | Code | Yes | Controlled rounding rule |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| Description | LongText | Yes | Business meaning |
| SourceReference | String | Conditional | Requirement/approval evidence |

## 18. Metric_Phase_Links — `tblMetricPhaseLinks`

| Field | Type | Required | Rules |
|---|---|---:|---|
| MetricPhaseLinkId | Identifier | Yes | Primary key |
| MetricCode | Identifier | Yes | FK to Metric_Catalogue |
| Phase | Phase | Yes | Explicit supported phase |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |

## 19. Report_Definitions — `tblReportDefinitions`

One row defines one controlled report column or terminology placement.

| Field | Type | Required | Rules |
|---|---|---:|---|
| ReportDefinitionId | Identifier | Yes | Primary key |
| Phase | Phase | Yes | Report phase |
| ReportCode | Identifier | Yes | Stable report contract code |
| DisplayTitle | String | Yes | Report title |
| SheetCode | Identifier | Yes | Stable worksheet code |
| SheetDisplayName | String | Yes | Visible worksheet name |
| ColumnCode | Identifier | Yes | Stable column code |
| ColumnDisplayName | String | Yes | Visible column name |
| DataType | DataType | Yes | Controlled data type |
| Required | Boolean | Yes | Whether column is mandatory |
| Sequence | Integer | Yes | Deterministic column/sheet order |
| TerminologyCode | Code | Conditional | Approved display/result terminology code |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| SourceReference | String | Yes | Report requirement reference |

`ReportCode + SheetCode + ColumnCode` must be unique.

## 20. Aliases — `tblAliases`

| Field | Type | Required | Rules |
|---|---|---:|---|
| AliasId | Identifier | Yes | Primary key |
| AliasScope | Code | Yes | Field, value or approved master-data scope |
| SourceSystem | String | Conditional | Source context; use `Any` only when approved |
| SourceFieldOrValue | String | Yes | Alternate source name/value |
| CanonicalEntityType | EntityType | Yes | Allowed target type from relationship matrix |
| CanonicalCode | Identifier | Yes | Target field/value/master-data code |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Conditional | Evidence for alias |
| Comment | LongText | No | Additional note |

Alias resolution preserves raw evidence and produces a separate canonical value.

# Chapter C — Master data

## 21. Common master-data profile

The following fields apply unless an entity table states otherwise:

| Field | Type | Required | Rules |
|---|---|---:|---|
| `<Entity>Code` | Identifier | Yes | Primary key |
| `<Entity>Name` | String | Yes | Display name |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Conditional | Mandatory for regulatory content |
| Description | LongText | Yes | Business/regulatory meaning |
| SortOrder | Integer | Conditional | Display order |

## 22. Regions — `tblRegions`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RegionCode | Identifier | Yes | Primary key |
| RegionName | String | Yes | Display name |
| RegionType | Code | Yes | Jurisdiction, regional grouping, internal grouping, Other or Unknown |
| Status | RuleLifecycleStatus | Yes | Common master-data profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Conditional | Required for authority-impacting use |
| Description | LongText | Yes | Meaning and limitations |
| SortOrder | Integer | Yes | Display order |

MENA and LATAM-like groupings must use a grouping RegionType and cannot act as authorities.

## 23. Authorities — `tblAuthorities`

| Field | Type | Required | Rules |
|---|---|---:|---|
| AuthorityCode | Identifier | Yes | Primary key |
| AuthorityName | String | Yes | Official or approved display name |
| CountryOrJurisdiction | String | Yes | Jurisdiction description |
| Status | RuleLifecycleStatus | Yes | Common master-data profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Regulatory SME-approved source |
| Description | LongText | Yes | Authority scope |

## 24. Technical_Standards — `tblTechnicalStandards`

| Field | Type | Required | Rules |
|---|---|---:|---|
| TechnicalStandardCode | Identifier | Yes | Primary key |
| TechnicalStandardName | String | Yes | Standard name |
| StandardVersion | String | Conditional | Version where applicable |
| Status | RuleLifecycleStatus | Yes | Common master-data profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Regulatory/standards source |
| Description | LongText | Yes | Standard meaning |

Regional implementations, ASMF and source presentation are prohibited here.

## 25. Regional_Implementations — `tblRegionalImplementations`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RegionalImplementationCode | Identifier | Yes | Primary key |
| RegionalImplementationName | String | Yes | Display name |
| Status | RuleLifecycleStatus | Yes | Common master-data profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Regulatory SME-approved source |
| Description | LongText | Yes | Regional implementation meaning |

The underlying technical standard is resolved through Master_Data_Relationships.

## 26. Product_Domains — `tblProductDomains`

Uses the common master-data profile with:

- `ProductDomainCode` as primary key;
- `ProductDomainName` as display name.

## 27. Lifecycle_Contexts — `tblLifecycleContexts`

Uses the common master-data profile with:

- `LifecycleContextCode` as primary key;
- `LifecycleContextName` as display name.

## 28. Product_Classes — `tblProductClasses`

Uses the common master-data profile with:

- `ProductClassCode` as primary key;
- `ProductClassName` as display name.

## 29. Procedure_Contexts — `tblProcedureContexts`

Uses the common master-data profile with:

- `ProcedureContextCode` as primary key;
- `ProcedureContextName` as display name.

ASMF is represented in this entity, not Technical_Standards.

## 30. Source_Presentations — `tblSourcePresentations`

Uses the common master-data profile with:

- `SourcePresentationCode` as primary key;
- `SourcePresentationName` as display name.

This entity describes source packaging/evidence form, such as structured electronic, unstructured electronic, paper/scanned or mixed.

## 31. Master_Data_Relationships — `tblMasterDataRelationships`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RelationshipId | Identifier | Yes | Primary key |
| RelationshipType | RelationshipType | Yes | Frozen relationship type |
| SourceEntityType | EntityType | Yes | Must match RelationshipType |
| SourceEntityCode | Identifier | Yes | Existing Effective source endpoint |
| TargetEntityType | EntityType | Yes | Must match RelationshipType |
| TargetEntityCode | Identifier | Yes | Existing Effective target endpoint |
| Cardinality | Code | Yes | Documentation/validation code, not free text |
| IsMandatory | Boolean | Yes | Whether relationship is required for supported use |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | SME-approved evidence for regulatory relationships |
| Comment | LongText | No | Additional scope note |

The allowed relationship types and endpoint pairs are defined only by the Normalized Relationship Matrix.

# Chapter D — Rules and evaluation structure

## 32. Rules — `tblRules`

The physical workbook may use approved type-specific authoring tables, but export must normalize them to this entity.

| Field | Type | Required | Rules |
|---|---|---:|---|
| RuleId | Identifier | Yes | Primary key; never reused |
| RuleRevision | Integer | Yes | Minimum 1 |
| RuleType | RuleType | Yes | Controlled rule category |
| Title | String | Yes | Human-readable title |
| Description | LongText | Yes | Business meaning |
| Status | RuleLifecycleStatus | Yes | Draft, InReview, Reviewed, Effective, Superseded or Retired |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| Priority | Integer | Yes | Lower executes first; normally increments of 100 |
| ConflictGroup | Identifier | Conditional | Required when competing rules share conflict resolution |
| ConflictStrategy | ConflictStrategy | Yes | Approved strategy for RuleType |
| Specificity | Integer | Yes | Minimum 0 |
| StopProcessing | Boolean | Yes | Applied only according to conflict policy |
| FindingCode | Identifier | No | Optional primary/default finding FK |
| RequirementReference | String | Yes | Governing requirement ID |
| SourceReference | String | Conditional | Business/regulatory evidence |
| Comment | LongText | No | Non-executable note |

## 33. Rule_Phase_Assignment — `tblRulePhaseAssignments`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RulePhaseId | Identifier | Yes | Primary key |
| RuleId | Identifier | Yes | FK to Rules |
| Phase | Phase | Yes | Explicit phase |
| EvaluationStatusOnMissingInput | EvaluationStatus | Yes | Missing-input behavior |
| RAG | RAG | Conditional | Assigned only where RAG is meaningful |
| Severity | Severity | Conditional | Controlled severity |
| IsBlocker | Boolean | Yes | Phase-specific blocker effect |
| ExceptionEligible | Boolean | Yes | Phase-specific eligibility |
| DecisionImpact | Code | Conditional | Controlled decision effect |
| OutputCode | Identifier | No | Optional phase-level output code |
| Sequence | Integer | Yes | Deterministic ordering |

`RuleId + Phase` must be unique.

## 34. Condition_Groups — `tblConditionGroups`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ConditionGroupId | Identifier | Yes | Primary key |
| RuleId | Identifier | Yes | FK to Rules |
| GroupSequence | Integer | Yes | Deterministic group order |
| GroupOperator | LogicalOperator | Yes | `AND` in schema 1.0.0 |
| Description | LongText | No | Group purpose |

Groups are OR alternatives for the same rule.

## 35. Rule_Conditions — `tblRuleConditions`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ConditionId | Identifier | Yes | Primary key |
| RuleId | Identifier | Yes | FK to Rules; must equal group RuleId |
| ConditionGroupId | Identifier | Yes | FK to Condition_Groups |
| Sequence | Integer | Yes | Order within group |
| FieldCode | Identifier | Yes | FK to Field_Catalogue |
| Operator | Operator | Yes | Must be allowed for field |
| Value1 | JsonValue | Conditional | Required according to operator |
| Value2 | JsonValue | Conditional | Required only for two-value operator such as BETWEEN |
| ValueDataType | DataType | Conditional | Must match field/allowed comparison type |
| CaseSensitive | Boolean | Yes | Relevant to string comparisons |
| Negate | Boolean | Yes | Explicit negation flag |
| Comment | LongText | No | Non-executable note |

Arbitrary VBA, PowerShell and expression-language code is prohibited.

## 36. Rule_Outputs — `tblRuleOutputs`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RuleOutputId | Identifier | Yes | Primary key |
| RuleId | Identifier | Yes | FK to Rules |
| Phase | Phase | Yes | Must exist in Rule_Phase_Assignment |
| OutputType | OutputType | Yes | ClassificationCandidate, Finding, RAG, ConfidenceImpact, EffortImpact, DecisionImpact or ClarificationTrigger |
| OutputCode | Identifier | Yes | Polymorphic target controlled by OutputType |
| OutputValue | JsonValue | Conditional | Allowed only by output target contract |
| Sequence | Integer | Yes | Ordered output sequence |
| Comment | LongText | No | Non-executable note |

## 37. Rule_Supersession — `tblRuleSupersession`

| Field | Type | Required | Rules |
|---|---|---:|---|
| SupersessionId | Identifier | Yes | Primary key |
| SupersededRuleId | Identifier | Yes | FK to predecessor Rules row |
| SupersedingRuleId | Identifier | Yes | FK to successor Rules row |
| EffectiveDate | Date | Yes | Date successor becomes applicable |
| Reason | LongText | Yes | Semantic reason for replacement |
| ApprovedBy | String | Yes | Required approver identity/role |
| ApprovalReference | String | Yes | Controlled evidence |
| Comment | LongText | No | Additional note |

Self-reference, cycles and RuleId reuse are prohibited.

# Chapter E — Findings, recommendations and policies

## 38. Findings — `tblFindings`

| Field | Type | Required | Rules |
|---|---|---:|---|
| FindingCode | Identifier | Yes | Primary key |
| Title | String | Yes | Concise finding title |
| FindingCategory | FindingCategory | Yes | Controlled category |
| Description | LongText | Yes | Evidence/evaluated outcome meaning |
| DefaultEvaluationStatus | EvaluationStatus | Yes | Default only; phase may override |
| DefaultRAG | RAG | Conditional | Omitted where RAG is not meaningful |
| DefaultSeverity | Severity | Conditional | Controlled severity |
| ExceptionEligible | Boolean | Yes | Master eligibility |
| CustomerVisible | Boolean | Yes | Visibility flag |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Requirement/evidence reference |

Findings do not contain full recommendation text.

## 39. Recommendations — `tblRecommendations`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RecommendationCode | Identifier | Yes | Primary key |
| Title | String | Yes | Recommendation title |
| CustomerFacingText | LongText | Yes | Customer-appropriate guidance |
| ConsultantFacingText | LongText | Yes | Internal consultant guidance |
| Priority | Integer | Yes | Ordering priority |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Requirement/evidence reference |
| Comment | LongText | No | Additional note |

## 40. Finding_Recommendation_Links — `tblFindingRecommendationLinks`

| Field | Type | Required | Rules |
|---|---|---:|---|
| LinkId | Identifier | Yes | Primary key |
| FindingCode | Identifier | Yes | FK to Findings |
| RecommendationCode | Identifier | Yes | FK to Recommendations |
| Phase | Phase | Yes | Explicit phase |
| LinkType | LinkType | Yes | Controlled link meaning |
| ApplicabilityConditionReference | Identifier | No | Approved condition/derived-field reference only |
| Sequence | Integer | Yes | Display/application order |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |

## 41. Conflict_Policies — `tblConflictPolicies`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ConflictPolicyId | Identifier | Yes | Primary key |
| RuleType | RuleType | Yes | Applicable rule category |
| ConflictStrategy | ConflictStrategy | Yes | Approved strategy |
| TieBehavior | Code | Yes | Unknown, ManualReview or approved result |
| StopBehavior | Code | Yes | Continue, StopGroup or StopEvaluation as approved |
| DefaultPriorityIncrement | Integer | Yes | Normally 100 |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| Description | LongText | Yes | Policy meaning |

## 42. Exception_Policies — `tblExceptionPolicies`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ExceptionPolicyId | Identifier | Yes | Primary key |
| EligibleFindingCode | Identifier | Yes | FK to exception-eligible Findings |
| AllowedEffect | ExceptionEffect | Yes | Controlled effect |
| RequiredApproverRole | Code | Yes | Controlled role; owner/SME-approved |
| EvidenceRequirement | LongText | Yes | Required project evidence |
| ExpiryRequired | Boolean | Yes | Whether expiry is mandatory |
| MaximumValidityDays | Integer | Conditional | Required when bounded maximum applies |
| CarryForwardToPostMigration | Boolean | Yes | Default False |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Approval evidence |

Actual project exceptions are not stored in this entity.

## 43. RAG_Policies — `tblRagPolicies`

| Field | Type | Required | Rules |
|---|---|---:|---|
| RagPolicyId | Identifier | Yes | Primary key |
| Scope | Code | Yes | Approved assessment scope |
| AggregationStrategy | ConflictStrategy | Yes | Normally MostSevere where applicable |
| GreenDefinition | LongText | Yes | Controlled definition |
| AmberDefinition | LongText | Yes | Controlled definition |
| RedDefinition | LongText | Yes | Controlled definition |
| UnknownDefinition | LongText | Yes | Controlled definition |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| SourceReference | String | Yes | Requirement/approval reference |

NotAssessed and NotApplicable are prohibited as RAG values.

## 44. Confidence_Policies — `tblConfidencePolicies`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ConfidencePolicyId | Identifier | Yes | Primary key |
| Scope | Code | Yes | Classification, effort or approved scope |
| EvidenceStrength | EvidenceStrength | Yes | Controlled strength |
| WeightOrScore | Decimal | Yes | Requires owner/SME approval |
| AgreementRequirement | LongText | Yes | Required evidence agreement rule |
| MissingEvidenceBehavior | Code | Yes | Controlled behavior |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Approval evidence |

## 45. Effort_Driver_Definitions — `tblEffortDriverDefinitions`

| Field | Type | Required | Rules |
|---|---|---:|---|
| EffortDriverId | Identifier | Yes | Primary key |
| DriverCode | Identifier | Yes | Unique stable driver code |
| DriverName | String | Yes | Display name |
| Category | Code | Yes | Controlled effort category |
| MetricCode | Identifier | Conditional | FK to Metric_Catalogue for metric-based driver |
| Weight | Decimal | Yes | Migration/Product Owner approved |
| Cap | Decimal | No | Maximum contribution |
| Floor | Decimal | No | Minimum contribution |
| MinimumBandOverrideEligible | Boolean | Yes | Whether driver can impose a minimum band |
| DoubleCountGroup | Identifier | No | Prevents double counting within group |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Approval evidence |

Supported phases are maintained through Effort_Driver_Phase_Links.

## 46. Effort_Driver_Phase_Links — `tblEffortDriverPhaseLinks`

| Field | Type | Required | Rules |
|---|---|---:|---|
| EffortDriverPhaseLinkId | Identifier | Yes | Primary key |
| EffortDriverId | Identifier | Yes | FK to Effort_Driver_Definitions |
| Phase | Phase | Yes | Explicit phase |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |

## 47. Effort_Thresholds — `tblEffortThresholds`

| Field | Type | Required | Rules |
|---|---|---:|---|
| EffortThresholdId | Identifier | Yes | Primary key |
| ThresholdScopeType | Code | Yes | Driver or OverallModel |
| ThresholdScopeCode | Identifier | Yes | DriverCode or approved overall-model code |
| BandCode | EffortBand | Yes | Controlled band |
| LowerBound | Decimal | No | Open lower bound allowed |
| UpperBound | Decimal | No | Open upper bound allowed |
| LowerInclusive | Boolean | Yes | Default True |
| UpperInclusive | Boolean | Yes | Default False |
| Unit | Code | Yes | Controlled unit |
| MinimumBandOverride | EffortBand | No | Optional override band |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Approval evidence |

Gaps, overlaps and duplicate bands fail validation for complete band sets.

## 48. Decision_Policies — `tblDecisionPolicies`

| Field | Type | Required | Rules |
|---|---|---:|---|
| DecisionPolicyId | Identifier | Yes | Primary key |
| Phase | Phase | Yes | Explicit phase |
| ResultCode | Code | Yes | Valid result for selected phase |
| Priority | Integer | Yes | Lower evaluated first |
| RequiredConditionType | Code | Yes | ConditionGroup or DerivedField |
| RequiredConditionReference | Identifier | Yes | Resolves according to type |
| MandatoryBlockerOverride | Boolean | Yes | Enforces blocker precedence |
| ExceptionBehavior | Code | Yes | Controlled behavior |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Requirement/approval reference |

## 49. Questionnaire_Map — `tblQuestionnaireMap`

| Field | Type | Required | Rules |
|---|---|---:|---|
| QuestionnaireMapId | Identifier | Yes | Primary key |
| TriggerType | Code | Yes | Field or Finding |
| TriggerCode | Identifier | Yes | FK selected by TriggerType |
| QuestionCode | Identifier | Yes | Stable question code |
| CustomerQuestion | LongText | Yes | Customer-facing question |
| Reason | LongText | Yes | Why question is needed |
| Priority | Integer | Yes | Display priority |
| SupportedPhase | Phase | Yes | Explicit phase |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| EffectiveFrom | Date | Conditional | Required for Effective |
| EffectiveTo | Date | No | Exclusive end |
| SourceReference | String | Yes | Requirement reference |

# Chapter F — Validation and technical entities

## 50. Validation_Controls — `tblValidationControls`

| Field | Type | Required | Rules |
|---|---|---:|---|
| ValidationControlId | Identifier | Yes | Primary key |
| ValidationCategory | Code | Yes | Structural, reference, lifecycle, semantic, compatibility or release |
| EntityType | EntityType | Yes | Entity evaluated |
| Severity | Severity | Yes | Controlled severity |
| IsCritical | Boolean | Yes | Critical controls cannot be disabled |
| Parameter1 | String | No | Structured parameter, not executable code |
| Parameter2 | String | No | Structured parameter, not executable code |
| MessageTemplate | LongText | Yes | Controlled message template |
| Status | RuleLifecycleStatus | Yes | Controlled-content profile |
| SourceReference | String | Yes | Requirement/test reference |

## 51. Rule_Index — `tblRuleIndex`

Generated only; manual editing prohibited.

| Field | Type | Required | Rules |
|---|---|---:|---|
| RuleId | Identifier | Yes | PK/FK to Rules |
| RuleRevision | Integer | Yes | Copied from Rules |
| RuleType | RuleType | Yes | Copied from Rules |
| SourceTable | String | Yes | Physical authoring table |
| SourceRow | Integer | Yes | Current source row |
| Status | RuleLifecycleStatus | Yes | Copied from Rules |
| EffectiveFrom | Date | Conditional | Copied from Rules |
| EffectiveTo | Date | No | Copied from Rules |
| RuntimeEligible | Boolean | Yes | Calculated |
| PhaseCount | Integer | Yes | Calculated |
| ConditionCount | Integer | Yes | Calculated |
| OutputCount | Integer | Yes | Calculated |
| FindingCode | Identifier | No | Primary/default finding |
| ValidationState | Code | Yes | Current validation result |

## 52. Technical_Settings — `tblTechnicalSettings`

| Field | Type | Required | Rules |
|---|---|---:|---|
| SettingCode | Identifier | Yes | Primary key |
| SettingValue | String | Yes | Non-secret technical value |
| DataType | DataType | Yes | Controlled type |
| EnvironmentScope | Code | Yes | Workbook, DEV export or controlled release as approved |
| IsSecret | Boolean | Yes | Must always be False; secrets prohibited |
| Description | LongText | Yes | Setting purpose |
| SourceReference | String | Yes | Technical requirement reference |

## 53. JSON_Preview

`JSON_Preview` is a generated read-only view, not an authoritative data entity.

It displays:

- ConfigurationId;
- MappingVersion;
- SchemaVersion;
- SourceWorkbookVersion;
- ExportType and status;
- ValidationRunId and validation state;
- section counts;
- formatted JSON preview.

The worksheet display may be truncated. The exported JSON must never be truncated.

## 54. Required controlled-value categories

The following ListName values are mandatory in `Value_Lists`:

- DocumentStatus;
- RuleLifecycleStatus;
- Phase;
- MigrationScenario;
- DataType;
- Operator;
- LogicalOperator;
- ConflictStrategy;
- EvidenceStrength;
- EvaluationStatus;
- RAG;
- Severity;
- Confidence;
- ValueSource;
- RequirementLevel;
- EffortBand;
- ExceptionEffect;
- LinkType;
- RuleType;
- OutputType;
- FindingCategory;
- Unit;
- RelationshipType;
- ExportType;
- phase-result code lists;
- change and validation categories required by the workbook.

## 55. Mandatory code boundaries

### 55.1 Phase

- PRE_SALES;
- PRE_MIGRATION;
- POST_MIGRATION.

### 55.2 Evaluation status

- Evaluated;
- NotAssessed;
- NotApplicable;
- Skipped;
- Warning;
- Error;
- InsufficientEvidence;
- Conflict.

`Warning` indicates a completed usable evaluation with a recoverable condition requiring attention. It is not a RAG value and does not independently determine severity, blocker status, effort band or phase result.

### 55.3 RAG

- Green;
- Amber;
- Red;
- Unknown.

### 55.4 Value source

- Observed;
- CustomerProvided;
- Imported;
- Derived;
- Assumed.

`Calculated` is a legacy synonym of Derived and is not exported.

### 55.5 Rule lifecycle

- Draft;
- InReview;
- Reviewed;
- Effective;
- Superseded;
- Retired.

### 55.6 Conflict strategy

- FirstMatch;
- MostSpecific;
- MostSevere;
- Aggregate;
- ErrorOnMultipleMatch;
- HighestEvidenceScore;
- ManualReview.

### 55.7 Exception effect

- AcknowledgeOnly;
- RemoveBlock;
- ExcludeFromScope;
- AcceptDifference;
- DowngradeDecisionImpact.

## 56. Runtime inclusion rules

A controlled export includes only:

- Effective entities valid for the export date;
- required controlled values and catalogues;
- runtime-eligible rules with complete phase, condition and output structures;
- referenced Effective findings, recommendations, policies and relationships;
- approved report terminology;
- configuration and compatibility metadata.

It excludes:

- Draft, InReview, Superseded and Retired runtime rows;
- workbook UI state, formulas and comments;
- project-specific accepted exceptions;
- validation result details not required by the schema;
- secrets, credentials and VBA source.

## 57. Data-quality acceptance criteria

The data dictionary is implemented when:

1. every entity and field is represented in the XLSM design or explicitly mapped to an approved physical equivalent;
2. workbook table and column names are stable and protected;
3. all primary keys and composite unique constraints are validated;
4. all field types are enforced;
5. repeating phase/operator relationships use link tables;
6. all polymorphic references carry a discriminator and resolve to an allowed target;
7. effective-date semantics are consistent;
8. controlled JSON serialization matches the schema;
9. invalid field, type, code, relationship and temporal fixtures fail;
10. the PowerShell loader consumes only the validated runtime representation.

## 58. Change control

This dictionary is frozen at Version 1.0.

A field addition, removal, rename, type change, requiredness change, key change or semantic code change requires:

- DecisionId and requirement reference;
- impact analysis against XLSM/VBA, relationship matrix, JSON Schema, PowerShell, tests and reports;
- Product Owner and Technical Architect approval;
- applicable SME approval;
- schema-version compatibility assessment;
- updated fixtures and indexes.

Adding approved content rows without changing field structure or meaning does not change this dictionary version.

## 59. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Frozen logical entity, field, key, type, requiredness and serialization contract |
