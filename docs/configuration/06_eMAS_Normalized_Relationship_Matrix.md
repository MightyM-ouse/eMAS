# eMAS Normalized Relationship Matrix

**Version:** 1.0  
**Status:** Effective Logical-Model Contract  
**Effective date:** 2026-07-13  
**Owner:** Product Owner and Technical Architect  
**Decision references:** RM-001–RM-027; JSON-001–JSON-023; REG-003–REG-014  
**Canonical references:** Enterprise Requirements v3.1; Mapping Functional Requirements v3.0; Mapping Technical Requirements v3.0; Mapping Content Catalogue v3.0; Runtime JSON Contract; Normalized Rule Model

## 1. Purpose

This document freezes the normalized relationship model for the eMAS mapping workbook and runtime JSON configuration.

It defines:

- entity ownership and stable keys;
- foreign-key and polymorphic-reference rules;
- relationship cardinality and mandatory status;
- lifecycle and temporal-validity behavior;
- workbook, export and runtime validation responsibilities;
- JSON section ownership;
- change-control rules for future model revisions.

This contract freezes structure, not detailed regulatory or migration content. Authority mappings, regulatory rules, folder/file expectations, effort weights, confidence weights and exception-role values still require the applicable SME approval before Effective status.

## 2. Frozen modelling rules

1. Every entity has a stable primary key.
2. Repeating relationships use dedicated link entities or the approved generic relationship entity.
3. Comma-separated multi-value fields are prohibited.
4. Workbook display layout does not control the logical model. Multiple tables may share one visible worksheet.
5. Foreign keys reference stable codes or IDs, never display text.
6. Effective or previously released identifiers are immutable and must not be reused.
7. Physical cascade deletion is prohibited.
8. Referenced Effective records are retired or superseded rather than deleted.
9. Draft records may be deleted only when no other row references them.
10. `EffectiveFrom` is inclusive and `EffectiveTo` is exclusive.
11. Every referenced endpoint included in a controlled export must also be Effective for the export date.
12. Project-specific accepted exceptions remain outside the master configuration.
13. PowerShell consumes the exported relationship model but does not repair, infer or rewrite it.

## 3. Validation layers

| Layer | Responsibility |
|---|---|
| XLSM/VBA | Table existence, required columns, uniqueness, references, controlled values, lifecycle, temporal validity and business validation before export |
| JSON Schema | Structural types, required properties, enumerations and supported object shapes |
| Release validator | Cross-collection uniqueness, referential integrity, effective-date alignment, compatibility, checksum and package integrity |
| PowerShell loader | Defensive compatibility and integrity checks before execution; fail-fast on invalid configuration |
| Rule engine | Runtime evaluation only after the configuration has passed loader validation |

A JSON Schema validation pass alone does not prove referential integrity.

## 4. Key and reference conventions

| Convention | Rule |
|---|---|
| Primary keys | PascalCase workbook columns; stable uppercase-compatible values; exported as camelCase JSON properties |
| Composite uniqueness | Enforced where indicated even when a surrogate row ID also exists |
| Controlled codes | Resolved through `Value_Lists` or the relevant master-data entity |
| Polymorphic references | Require both an entity/type discriminator and a code/ID; the allowed target set is fixed in this document |
| Temporal references | A child may not be Effective outside the effective window of its mandatory parent |
| Missing references | Block controlled export |
| Unknown descriptive metadata | May be tolerated only where the Runtime JSON Contract explicitly allows it |
| Unknown executable codes | Block export and engine loading |

## 5. Entity inventory

| Area | Entity | Primary key | Workbook table | Runtime section |
|---|---|---|---|---|
| Governance | Document_Control | DocumentId | `tblDocumentControl` | `configuration` metadata |
| Governance | Workbook_Control | ConfigurationId | `tblWorkbookControl` | `configuration` |
| Governance | Change_History | ChangeId | `tblChangeHistory` | Not exported |
| Governance | Change_History_Items | ChangeItemId | `tblChangeHistoryItems` | Not exported |
| Governance | Validation_Runs | ValidationRunId | `tblValidationRuns` | Configuration/release evidence only |
| Governance | Validation_Results | ValidationResultId | `tblValidationResults` | Not exported |
| Governance | Export_History | ExportId | `tblExportHistory` | Not exported |
| Catalogue | Value_Lists | ValueListEntryId | `tblValueLists` | `valueLists` |
| Catalogue | Field_Catalogue | FieldCode | `tblFieldCatalogue` | `fieldCatalogue` |
| Catalogue | Field_Operator_Links | FieldOperatorLinkId | `tblFieldOperatorLinks` | Normalized into field operator arrays |
| Catalogue | Field_Phase_Links | FieldPhaseLinkId | `tblFieldPhaseLinks` | Normalized into field phase arrays |
| Catalogue | Metric_Catalogue | MetricCode | `tblMetricCatalogue` | `metricCatalogue` |
| Catalogue | Metric_Phase_Links | MetricPhaseLinkId | `tblMetricPhaseLinks` | Normalized into metric phase arrays |
| Catalogue | Report_Definitions | ReportDefinitionId | `tblReportDefinitions` | `reportTerminology` |
| Catalogue | Aliases | AliasId | `tblAliases` | `aliases` |
| Master data | Regions | RegionCode | `tblRegions` | `masterData.regions` |
| Master data | Authorities | AuthorityCode | `tblAuthorities` | `masterData.authorities` |
| Master data | Technical_Standards | TechnicalStandardCode | `tblTechnicalStandards` | `masterData.technicalStandards` |
| Master data | Regional_Implementations | RegionalImplementationCode | `tblRegionalImplementations` | `masterData.regionalImplementations` |
| Master data | Product_Domains | ProductDomainCode | `tblProductDomains` | `masterData.productDomains` |
| Master data | Lifecycle_Contexts | LifecycleContextCode | `tblLifecycleContexts` | `masterData.lifecycleContexts` |
| Master data | Product_Classes | ProductClassCode | `tblProductClasses` | `masterData.productClasses` |
| Master data | Procedure_Contexts | ProcedureContextCode | `tblProcedureContexts` | `masterData.procedureContexts` |
| Master data | Source_Presentations | SourcePresentationCode | `tblSourcePresentations` | `masterData.sourcePresentations` |
| Master data | Master_Data_Relationships | RelationshipId | `tblMasterDataRelationships` | `relationships` |
| Rules | Rules | RuleId | `tblRules` or approved type-specific source tables | `rules` |
| Rules | Rule_Phase_Assignment | RulePhaseId | `tblRulePhaseAssignments` | `rulePhases` |
| Rules | Condition_Groups | ConditionGroupId | `tblConditionGroups` | `conditionGroups` |
| Rules | Rule_Conditions | ConditionId | `tblRuleConditions` | `ruleConditions` |
| Rules | Rule_Outputs | RuleOutputId | `tblRuleOutputs` | `ruleOutputs` |
| Rules | Rule_Supersession | SupersessionId | `tblRuleSupersession` | `relationships` or release history |
| Outputs | Findings | FindingCode | `tblFindings` | `findings` |
| Outputs | Recommendations | RecommendationCode | `tblRecommendations` | `recommendations` |
| Outputs | Finding_Recommendation_Links | LinkId | `tblFindingRecommendationLinks` | `findingRecommendationLinks` |
| Policies | Conflict_Policies | ConflictPolicyId | `tblConflictPolicies` | Controlled rule/policy data |
| Policies | Exception_Policies | ExceptionPolicyId | `tblExceptionPolicies` | `exceptionPolicies` |
| Policies | RAG_Policies | RagPolicyId | `tblRagPolicies` | Controlled rule/policy data |
| Policies | Confidence_Policies | ConfidencePolicyId | `tblConfidencePolicies` | Controlled rule/policy data |
| Effort | Effort_Driver_Definitions | EffortDriverId | `tblEffortDriverDefinitions` | Controlled rule/policy data |
| Effort | Effort_Driver_Phase_Links | EffortDriverPhaseLinkId | `tblEffortDriverPhaseLinks` | Normalized phase applicability |
| Effort | Effort_Thresholds | EffortThresholdId | `tblEffortThresholds` | Controlled rule/policy data |
| Decisions | Decision_Policies | DecisionPolicyId | `tblDecisionPolicies` | Controlled rule/policy data |
| Decisions | Questionnaire_Map | QuestionnaireMapId | `tblQuestionnaireMap` | Controlled clarification data |
| Validation | Validation_Controls | ValidationControlId | `tblValidationControls` | Not exported unless explicitly required by schema |
| Validation | Rule_Index | RuleId | `tblRuleIndex` | Not exported as an authoring table |
| Technical | Technical_Settings | SettingCode | `tblTechnicalSettings` | Export metadata only where approved |
| Technical | JSON_Preview | View only | No authoritative table | Not exported |

## 6. Governance and evidence relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-GOV-001 | Change_History_Items.ChangeId | Change_History.ChangeId | One change to many items | Yes | Orphan items block validation |
| REL-GOV-002 | Change_History_Items.ObjectType + ObjectId | Approved entity inventory + entity key | Polymorphic many-to-one | Yes | Object type must be supported; target must exist at the time of change recording |
| REL-GOV-003 | Validation_Results.ValidationRunId | Validation_Runs.ValidationRunId | One run to many results | Yes | Every result belongs to one run |
| REL-GOV-004 | Validation_Results.ValidationControlId | Validation_Controls.ValidationControlId | One control to many results | Yes | Unknown control blocks validation |
| REL-GOV-005 | Validation_Results.EntityType + EntityId | Approved entity inventory + entity key | Polymorphic many-to-one | Conditional | Mandatory when a result relates to a specific row |
| REL-GOV-006 | Export_History.ConfigurationId | Workbook_Control.ConfigurationId | One configuration to many exports | Yes | Export metadata must match the active workbook configuration |
| REL-GOV-007 | Export_History.ValidationRunId | Validation_Runs.ValidationRunId | One run to zero or more exports | Yes | Export permitted only from a completed eligible run |
| REL-GOV-008 | Export_History.MappingVersion | Workbook_Control.MappingVersion | Version consistency | Yes | Values must be identical for the exported package |
| REL-GOV-009 | Export_History.SchemaVersion | Workbook_Control.SchemaVersion | Version consistency | Yes | Values must be identical for the exported package |
| REL-GOV-010 | Export_History.SourceWorkbookVersion | Workbook_Control.SourceWorkbookVersion | Version consistency | Yes | Values must be identical for the exported package |

## 7. Catalogue relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-CAT-001 | Field_Operator_Links.FieldCode | Field_Catalogue.FieldCode | One field to one or more operators | Yes | At least one operator per executable field |
| REL-CAT-002 | Field_Operator_Links.OperatorCode | Value_Lists[ListName=Operator].Code | Many links to one code | Yes | Operator must be compatible with field DataType |
| REL-CAT-003 | Field_Phase_Links.FieldCode | Field_Catalogue.FieldCode | One field to one or more phases | Yes | Every field must support at least one explicit phase |
| REL-CAT-004 | Field_Phase_Links.Phase | Value_Lists[ListName=Phase].Code | Many links to one phase | Yes | `All` is prohibited in controlled export |
| REL-CAT-005 | Metric_Phase_Links.MetricCode | Metric_Catalogue.MetricCode | One metric to one or more phases | Yes | Every metric must support at least one explicit phase |
| REL-CAT-006 | Metric_Phase_Links.Phase | Value_Lists[ListName=Phase].Code | Many links to one phase | Yes | Controlled phase code required |
| REL-CAT-007 | Report_Definitions.Phase | Value_Lists[ListName=Phase].Code | Many definitions to one phase | Yes | One report contract may contain many ordered columns/sheets |
| REL-CAT-008 | Report_Definitions.DataType | Value_Lists[ListName=DataType].Code | Many definitions to one type | Yes | Report data type must be controlled |
| REL-CAT-009 | Report_Definitions.TerminologyCode | Value_Lists or approved report terminology | Many-to-one | Conditional | Required when controlled display wording is used |
| REL-CAT-010 | Aliases.CanonicalEntityType + CanonicalCode | Field_Catalogue, Value_Lists or approved master-data entity | Polymorphic many-to-one | Yes | Allowed target types are `Field`, `ValueList`, `Region`, `Authority`, `TechnicalStandard`, `RegionalImplementation`, `ProductDomain`, `LifecycleContext`, `ProductClass`, `ProcedureContext`, `SourcePresentation` |

Unique constraints:

- `Value_Lists`: `ListName + Code` unique.
- `Field_Operator_Links`: `FieldCode + OperatorCode` unique.
- `Field_Phase_Links`: `FieldCode + Phase` unique.
- `Metric_Phase_Links`: `MetricCode + Phase` unique.
- `Report_Definitions`: `ReportCode + SheetCode + ColumnCode` unique.
- `Aliases`: active `AliasScope + SourceSystem + SourceFieldOrValue` unique for overlapping effective dates.

## 8. Master-data relationship matrix

`Master_Data_Relationships` is the only approved generic many-to-many master-data link entity. Every row must use one of the frozen relationship types below.

| RelationshipType | Source entity | Target entity | Typical cardinality | Mandatory rule |
|---|---|---|---|---|
| AuthorityToRegion | Authorities | Regions | Many authorities to one or more regions | Every Effective authority except `Other` and `Unknown` must have at least one Effective region |
| AuthorityToTechnicalStandard | Authorities | Technical_Standards | Many-to-many | Required before authority-specific standard interpretation becomes Effective |
| AuthorityToRegionalImplementation | Authorities | Regional_Implementations | Many-to-many | Required before authority-specific regional-folder logic becomes Effective |
| TechnicalStandardToRegion | Technical_Standards | Regions | Many-to-many | Required where standard applicability is region constrained |
| TechnicalStandardToRegionalImplementation | Technical_Standards | Regional_Implementations | One standard to many implementations; one implementation normally to one standard/version family | Every Effective regional implementation must resolve to at least one Effective technical standard |
| ProductDomainToTechnicalStandard | Product_Domains | Technical_Standards | Many-to-many | Required when domain constrains supported standard |
| ProductDomainToRegion | Product_Domains | Regions | Many-to-many | Optional unless a rule depends on the relationship |
| LifecycleContextToTechnicalStandard | Lifecycle_Contexts | Technical_Standards | Many-to-many | Required when lifecycle context constrains supported standard |
| ProductClassToTechnicalStandard | Product_Classes | Technical_Standards | Many-to-many | Optional unless a rule depends on the relationship |
| ProcedureContextToTechnicalStandard | Procedure_Contexts | Technical_Standards | Many-to-many | Required for every Effective procedure context with technical-format constraints |
| ProcedureContextToRegionalImplementation | Procedure_Contexts | Regional_Implementations | Many-to-many | Required where the procedure has region-specific implementation behavior |
| SourcePresentationToTechnicalStandard | Source_Presentations | Technical_Standards | Many-to-many | Optional compatibility/interpretation relationship |

Master-data endpoint rules:

1. `SourceEntityType` and `TargetEntityType` must match the frozen entity pair for the selected `RelationshipType`.
2. Both endpoint codes must exist.
3. The same endpoint pair may not have overlapping Effective rows.
4. Broad groupings such as MENA and LATAM must not be used as authority substitutes.
5. Regulatory relationships require Regulatory SME evidence before Effective status.
6. Aliases do not create master-data applicability relationships.

## 9. Rule-model relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-RULE-001 | Rule_Phase_Assignment.RuleId | Rules.RuleId | One rule to one to three phase rows | Yes | At least one explicit phase per runtime-eligible rule; duplicate phase rows prohibited |
| REL-RULE-002 | Rule_Phase_Assignment.Phase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | Controlled phase required; `All` expanded before export |
| REL-RULE-003 | Condition_Groups.RuleId | Rules.RuleId | One rule to zero or more groups | Conditional | Executable rules require at least one group unless the RuleType explicitly permits an unconditional fallback |
| REL-RULE-004 | Rule_Conditions.RuleId | Rules.RuleId | One rule to zero or more conditions | Conditional | Must match the RuleId of the referenced condition group |
| REL-RULE-005 | Rule_Conditions.ConditionGroupId | Condition_Groups.ConditionGroupId | One group to one or more conditions | Yes | Every exported group has at least one condition |
| REL-RULE-006 | Rule_Conditions.FieldCode | Field_Catalogue.FieldCode | Many conditions to one field | Yes | Field must support the rule phase and selected operator |
| REL-RULE-007 | Rule_Conditions.Operator | Value_Lists[ListName=Operator].Code | Many-to-one | Yes | Operator must be linked through Field_Operator_Links |
| REL-RULE-008 | Rule_Outputs.RuleId | Rules.RuleId | One rule to one or more outputs | Yes | Runtime-eligible rule requires at least one output |
| REL-RULE-009 | Rule_Outputs.Phase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | Output phase must also exist in Rule_Phase_Assignment |
| REL-RULE-010 | Rule_Outputs.OutputType + OutputCode | Approved output target | Polymorphic many-to-one | Conditional | Target validation follows the output-type matrix below |
| REL-RULE-011 | Rules.FindingCode | Findings.FindingCode | Many rules to one finding | Optional | Represents the primary/default finding only; phase-specific or additional findings use Rule_Outputs |
| REL-RULE-012 | Rule_Supersession.SupersededRuleId | Rules.RuleId | One predecessor to zero or one effective successor relationship | Yes | Predecessor must be Effective or Superseded; cannot equal successor |
| REL-RULE-013 | Rule_Supersession.SupersedingRuleId | Rules.RuleId | One successor may supersede one or more predecessors | Yes | Cycles and reuse of retired IDs are prohibited |
| REL-RULE-014 | Rules.ConflictStrategy | Conflict_Policies or controlled ConflictStrategy code | Many-to-one | Yes | Must be allowed for the RuleType |

### 9.1 Output-target matrix

| OutputType | OutputCode target | OutputValue rule |
|---|---|---|
| ClassificationCandidate | Code in the classification dimension identified by the rule/output context | Optional score or structured candidate metadata only as defined by schema |
| Finding | Findings.FindingCode | Optional override metadata; complete finding text is not embedded |
| RAG | Value_Lists[ListName=RAG].Code | OutputValue normally omitted |
| ConfidenceImpact | Confidence policy/effect code | Numeric or coded value according to the approved policy |
| EffortImpact | Effort_Driver_Definitions.DriverCode or approved effect code | Numeric or coded value according to the approved effort model |
| DecisionImpact | Approved decision-impact code | Must be valid for the output phase |
| ClarificationTrigger | Questionnaire_Map.QuestionCode | OutputValue omitted unless schema explicitly permits a parameter |

### 9.2 Condition rules

- Within one condition group, conditions use AND.
- Separate groups for the same rule use OR.
- Schema 1.0.0 supports no deeper nesting.
- `Value1` and `Value2` are interpreted using `ValueDataType` and the referenced field definition.
- `BETWEEN` requires both values.
- `EXISTS` and `MISSING` prohibit values.
- Unknown fields, operators or incompatible value types block export.

## 10. Finding, recommendation and policy relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-OUT-001 | Finding_Recommendation_Links.FindingCode | Findings.FindingCode | One finding to zero or more links | Yes | Referenced finding must be Effective for controlled export |
| REL-OUT-002 | Finding_Recommendation_Links.RecommendationCode | Recommendations.RecommendationCode | One recommendation to zero or more links | Yes | Referenced recommendation must be Effective |
| REL-OUT-003 | Finding_Recommendation_Links.Phase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | Link applies only to one explicit phase |
| REL-OUT-004 | Exception_Policies.EligibleFindingCode | Findings.FindingCode | One finding to zero or more policies | Yes | Finding must be exception eligible |
| REL-OUT-005 | Exception_Policies.AllowedEffect | Value_Lists[ListName=ExceptionEffect].Code | Many-to-one | Yes | Effect must be approved for the phase/decision context |
| REL-OUT-006 | Confidence_Policies.EvidenceStrength | Value_Lists[ListName=EvidenceStrength].Code | Many-to-one | Yes | Weight/score requires owner approval evidence |
| REL-OUT-007 | RAG_Policies.AggregationStrategy | Value_Lists[ListName=ConflictStrategy].Code | Many-to-one | Yes | Only RAG-compatible strategies permitted |

An exception changes decision treatment only. It never deletes or rewrites the finding, evidence, original RAG or original evaluation status.

## 11. Effort, threshold and decision relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-EFF-001 | Effort_Driver_Definitions.MetricCode | Metric_Catalogue.MetricCode | Many drivers to one metric | Conditional | Required for metric-based drivers |
| REL-EFF-002 | Effort_Driver_Phase_Links.EffortDriverId | Effort_Driver_Definitions.EffortDriverId | One driver to one or more phases | Yes | Explicit phases required |
| REL-EFF-003 | Effort_Driver_Phase_Links.Phase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | Only approved effort-applicable phases permitted |
| REL-EFF-004 | Effort_Thresholds.ThresholdScopeType + ThresholdScopeCode | Effort_Driver_Definitions or OverallEffortModel | Polymorphic many-to-one | Yes | Scope type is `Driver` or `OverallModel`; code must resolve |
| REL-EFF-005 | Effort_Thresholds.BandCode | Value_Lists[ListName=EffortBand].Code | Many-to-one | Yes | Bands use lower-inclusive, upper-exclusive default |
| REL-DEC-001 | Decision_Policies.Phase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | One explicit phase per policy row |
| REL-DEC-002 | Decision_Policies.ResultCode | Approved phase-result code | Many-to-one | Yes | Result must be valid for the selected phase |
| REL-DEC-003 | Decision_Policies.RequiredConditionReference | Condition_Groups or approved derived field | Polymorphic many-to-one | Yes | Free-text executable expressions prohibited |
| REL-DEC-004 | Questionnaire_Map.TriggerType + TriggerCode | Field_Catalogue or Findings | Polymorphic many-to-one | Yes | TriggerType is `Field` or `Finding` |
| REL-DEC-005 | Questionnaire_Map.SupportedPhase | Value_Lists[ListName=Phase].Code | Many-to-one | Yes | Question must be valid for the phase |

Threshold validation must reject gaps, overlaps and duplicate bands where a complete band set is required. Effort-driver weights, caps, floors and threshold values require Migration/Product Owner approval before Effective status.

## 12. Generated and validation relationships

| ID | Source and field | Target and field | Cardinality | Required | Validation rule |
|---|---|---|---|---:|---|
| REL-VAL-001 | Rule_Index.RuleId | Rules.RuleId | Exactly one generated index row per rule | Yes | Rule_Index is rebuilt and never manually maintained |
| REL-VAL-002 | Validation_Controls.EntityType | Frozen entity inventory | Many-to-one | Yes | Unknown entity type prohibited |
| REL-VAL-003 | Technical_Settings.DataType | Value_Lists[ListName=DataType].Code | Many-to-one | Yes | Secrets and credentials prohibited |

`JSON_Preview` is a non-authoritative view and has no inbound foreign-key relationships.

## 13. Runtime JSON relationship ownership

| JSON section | Relationship ownership |
|---|---|
| `configuration` | Document_Control, Workbook_Control and export metadata |
| `valueLists` | Value_Lists grouped by ListName |
| `fieldCatalogue` | Field_Catalogue plus Field_Operator_Links and Field_Phase_Links |
| `metricCatalogue` | Metric_Catalogue plus Metric_Phase_Links |
| `masterData` | Effective master-data entities |
| `relationships` | Master_Data_Relationships and schema-approved supersession links |
| `rules` | Rules |
| `rulePhases` | Rule_Phase_Assignment |
| `conditionGroups` | Condition_Groups |
| `ruleConditions` | Rule_Conditions |
| `ruleOutputs` | Rule_Outputs |
| `findings` | Findings |
| `recommendations` | Recommendations |
| `findingRecommendationLinks` | Finding_Recommendation_Links |
| `exceptionPolicies` | Exception_Policies |
| `aliases` | Aliases |
| `reportTerminology` | Report_Definitions and approved terminology |

The JSON Schema controls exact serialization. This matrix controls cross-entity semantics and references.

## 14. Controlled-export closure checks

Before controlled export, validation must prove:

1. all primary keys are present and unique;
2. every mandatory relationship resolves;
3. composite unique constraints hold;
4. no relationship cycle exists where prohibited;
5. every included entity is runtime eligible for the export date;
6. every mandatory referenced parent is also included or intentionally represented as required catalogue data;
7. rule phases, conditions and outputs are complete;
8. output targets resolve according to OutputType;
9. master-data endpoint types match RelationshipType;
10. findings and recommendations remain separate;
11. exception policies reference exception-eligible findings;
12. threshold bands are coherent;
13. SME-controlled content contains approval evidence;
14. the generated JSON passes schema and semantic validation;
15. checksum and release metadata are recorded.

## 15. Change control

The relationship model is frozen at Version 1.0.

A proposed change requires:

- a DecisionId and requirement reference;
- impact analysis against XLSM tables, VBA, JSON Schema, PowerShell loader, engine, tests and report contracts;
- Product Owner and Technical Architect approval;
- Regulatory or Migration SME approval when domain meaning changes;
- MAJOR schema-version assessment when a relationship, required endpoint, cardinality or code meaning changes incompatibly;
- updated valid and invalid fixtures;
- updated data dictionary and canonical indexes.

Adding approved content rows without changing entity structure or relationship meaning does not change this matrix version.

## 16. Acceptance criteria

This matrix is implemented when:

- every listed entity exists in the workbook design or is explicitly mapped to an approved physical equivalent;
- all dedicated link entities are present;
- no repeating relationship is stored as comma-separated text;
- all validation rules are implemented and tested;
- runtime JSON preserves the approved relationships;
- invalid-reference, duplicate, temporal and cycle fixtures fail as expected;
- the PowerShell loader rejects invalid controlled configurations;
- the XLSM, JSON Schema and implementation documentation reference this Version 1.0 contract.

## 17. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Frozen normalized entity, cardinality, reference, temporal and runtime-ownership model |
