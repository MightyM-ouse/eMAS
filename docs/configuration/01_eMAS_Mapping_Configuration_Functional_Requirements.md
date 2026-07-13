# eMAS Mapping and Configuration Workbook — Functional Requirements

**Project:** eMAS — eCTD Migration Assessment Script  
**Version:** 3.0  
**Status:** Effective Requirements Baseline  
**Scope:** Internal Mapping and Configuration Workbook  
**Classification:** Internal  
**Branding:** EXTEDO | a cormeo brand  
**Owner:** Product Owner  
**Effective date:** 2026-07-13  
**Decision references:** Approved Decision Baseline v1.0; AP-001–AP-012; JSON-001–JSON-023; RM-001–RM-027; REG-003–REG-004

---

## 1. Purpose and authority

This document defines the effective functional requirements for the internal eMAS mapping and configuration workbook.

The workbook is the controlled authoring application for business and regulatory configuration. It shall allow reviewed rules and controlled values to be maintained in Excel, normalized through structured relationship tables, validated, previewed and exported as one runtime JSON file.

The authority and precedence policy applies. The reviewed XLSM is the **authoring source of truth**. The validated immutable JSON exported from the approved XLSM is the **runtime source of truth**. PowerShell shall not read the workbook and shall not create, repair or reinterpret the runtime JSON.

## 2. Scope and boundaries

The workbook shall support:

- controlled master data and terminology;
- normalized rule authoring;
- phase-specific rule behavior;
- condition groups and conditions;
- outputs, findings and recommendations;
- lifecycle, supersession, conflicts and exception policies;
- thresholds, effort drivers and confidence rules;
- field and metric catalogues;
- aliases and report terminology;
- workbook validation;
- deterministic JSON preview and export;
- export history and traceability.

The workbook shall not:

- execute an assessment;
- scan customer source evidence;
- generate customer reports;
- contain project-specific accepted exceptions;
- distribute internal mapping content to customers;
- use PowerShell to convert workbook content to JSON;
- use editable `IsActive` as the primary lifecycle mechanism.

## 3. Functional architecture

The functional flow shall be:

```text
Maintain controlled tables
        ↓
Validate workbook structure and content
        ↓
Build normalized in-memory model
        ↓
Preview runtime JSON
        ↓
Export eMAS_Runtime_Config.json
        ↓
Record export metadata and checksum
```

The workbook shall provide the controls:

- **Validate Mapping**;
- **Preview JSON**;
- **Export Runtime JSON**;
- **Clear Validation Results**;
- **Open Export Folder**.

## 4. Workbook usability requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-UX-001 | MUST | Column headers and technical table names shall be fixed, protected and version-controlled. |
| FR-UX-002 | MUST | Every field with a finite approved value set shall use a dropdown sourced from `Value_Lists`. |
| FR-UX-003 | MUST | Free text shall be limited to descriptions, comments, rationale and controlled text fields. |
| FR-UX-004 | MUST | Numeric, date, Boolean and identifier fields shall use type-specific validation. |
| FR-UX-005 | MUST | The workbook shall provide a Home sheet with navigation, version, status, validation and export controls. |
| FR-UX-006 | MUST | User-maintained tables shall be filterable and use frozen headers. |
| FR-UX-007 | SHOULD | Required and optional fields shall be visually distinguishable. |
| FR-UX-008 | MUST | Protected headers and table names shall not be editable through normal user interaction. |
| FR-UX-009 | MUST | Visible labels may be user-friendly, but technical table and field identifiers shall remain stable. |
| FR-UX-010 | MUST | The workbook shall display validation counts, blocking errors, warnings and export eligibility clearly. |

## 5. Governance, versioning and lifecycle

| ID | Priority | Requirement |
|---|---|---|
| FR-GOV-001 | MUST | The workbook shall maintain `ConfigurationId`, `MappingVersion`, `SchemaVersion` and `SourceWorkbookVersion` separately. |
| FR-GOV-002 | MUST | Rule lifecycle values shall be `Draft`, `InReview`, `Reviewed`, `Effective`, `Superseded` and `Retired`. |
| FR-GOV-003 | MUST | Editable `IsActive` fields shall not control rule lifecycle. |
| FR-GOV-004 | MUST | Runtime eligibility shall be calculated from lifecycle status and effective dates. |
| FR-GOV-005 | MUST | Controlled export shall include only runtime-eligible Effective rules. |
| FR-GOV-006 | SHOULD | Reviewed rules may be included only in explicitly marked DEV exports. |
| FR-GOV-007 | MUST | DEV exports shall contain `DEV` in the filename and shall not be represented as Effective or controlled production configuration. |
| FR-GOV-008 | MUST | Every rule shall contain `RuleId`, `RuleRevision`, `Status`, `EffectiveFrom` and `EffectiveTo`. |
| FR-GOV-009 | MUST | Superseded rules shall have an explicit predecessor/successor relationship and reason. |
| FR-GOV-010 | MUST | Retired and superseded identifiers shall never be reused. |
| FR-GOV-011 | MUST | Change history shall identify changed objects through relationship rows rather than comma-separated values. |
| FR-GOV-012 | MUST | A document status and a rule lifecycle status shall remain separate concepts. |
| FR-GOV-013 | MUST | Controlled export shall require approved/effective workbook metadata according to the export policy. |

Runtime eligibility shall be equivalent to:

```text
Status = Effective
AND EffectiveFrom <= execution date
AND (EffectiveTo is empty OR execution date < EffectiveTo)
```

## 6. Rule identity and normalized model

| ID | Priority | Requirement |
|---|---|---|
| FR-RULE-001 | MUST | Every executable rule shall have a globally unique stable `RuleId`. |
| FR-RULE-002 | MUST | `RuleRevision` shall be an integer and shall identify the revision of the stable rule identity. |
| FR-RULE-003 | MUST | Non-semantic formatting corrections shall not create a new RuleId. |
| FR-RULE-004 | MUST | Clarifications that retain business meaning shall increment RuleRevision. |
| FR-RULE-005 | MUST | A material change to conditions, severity, blocker meaning, output type, phase meaning or threshold value shall create a new RuleId and supersession relationship. |
| FR-RULE-006 | MUST | The workbook shall maintain a generated `Rule_Index` with source table, source row, revision, lifecycle and runtime eligibility. |
| FR-RULE-007 | MUST | `Rule_Index` shall be generated by VBA and shall not be manually maintained. |
| FR-RULE-008 | MUST | Rules, phases, condition groups, conditions and outputs shall be maintained as separate normalized entities. |
| FR-RULE-009 | MUST | Findings, recommendations and finding-to-recommendation links shall remain separate entities. |
| FR-RULE-010 | MUST | Multi-value relationships shall use relationship tables, not comma-separated cells. |

## 7. Phase assignment requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-PHASE-001 | MUST | Phase behavior shall be stored in `Rule_Phase_Assignment`. |
| FR-PHASE-002 | MUST | A rule may have separate behavior for `PRE_SALES`, `PRE_MIGRATION` and `POST_MIGRATION`. |
| FR-PHASE-003 | MUST | Each phase assignment shall support evaluation status on missing input, RAG, severity, blocker status, exception eligibility, decision impact and output sequencing. |
| FR-PHASE-004 | MUST | An `All` workbook convenience value may be offered only when VBA expands it into explicit phase rows before export. |
| FR-PHASE-005 | MUST | The same condition may produce different phase-specific outcomes. |
| FR-PHASE-006 | MUST | Phase assignments shall not redefine the workflow or full assessment depth of a phase. |

## 8. Condition, field and metric requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-COND-001 | MUST | One condition shall be maintained per row. |
| FR-COND-002 | MUST | A condition shall include `ConditionId`, `RuleId`, `GroupId`, `Sequence`, `FieldCode`, `Operator`, `Value1` and optional `Value2`. |
| FR-COND-003 | MUST | Conditions in one group shall evaluate with AND. |
| FR-COND-004 | MUST | Separate groups for one rule shall evaluate with OR. |
| FR-COND-005 | MUST | Schema 1.0.0 shall support a maximum logical nesting depth of two levels. |
| FR-COND-006 | MUST | Arbitrary VBA, PowerShell or expression-language code shall not be stored in cells. |
| FR-COND-007 | MUST | Unsupported fields, operators or value types shall fail validation. |
| FR-COND-008 | SHOULD | Rules shall use controlled derived fields instead of direct RuleId-to-RuleId dependencies. |
| FR-COND-009 | MUST | Circular dependencies shall be prohibited. |
| FR-FIELD-001 | MUST | `Field_Catalogue` shall define every field that a rule may evaluate. |
| FR-FIELD-002 | MUST | Each field shall define code, display name, data type, allowed operators, supported phases, source type, producing component and evaluation order. |
| FR-FIELD-003 | MUST | `Metric_Catalogue` shall define numeric and calculated metrics, units and completeness expectations. |
| FR-FIELD-004 | MUST | Operators shall be validated against field data type. |
| FR-FIELD-005 | MUST | Derived fields shall identify the producing component and evaluation order. |

## 9. Classification and regulatory taxonomy

Classification shall produce independent dimensions:

- Region;
- Authority;
- TechnicalStandard;
- RegionalImplementation;
- ProductDomain;
- LifecycleContext;
- ProductClass;
- ProcedureContext where applicable;
- SourcePresentation where needed to describe packaging rather than a regulatory standard.

| ID | Priority | Requirement |
|---|---|---|
| FR-CLASS-001 | MUST | Classification dimensions shall remain independent and normalized. |
| FR-CLASS-002 | MUST | Regional implementations shall be layered on a technical standard, not treated as mutually exclusive substitutes. |
| FR-CLASS-003 | MUST | ASMF shall be represented as `ProcedureContext`, not `TechnicalStandard`. |
| FR-CLASS-004 | MUST | Paper or scanned content shall be represented as source presentation when it describes packaging rather than technical standard. |
| FR-CLASS-005 | MUST | Classification shall preserve matched candidates, evidence, evidence strength, score and confidence. |
| FR-CLASS-006 | MUST | Classification conflict resolution shall default to `HighestEvidenceScore`. |
| FR-CLASS-007 | MUST | Equal top scores or contradictory strong evidence shall produce `Unknown` or `ManualReview`. |
| FR-CLASS-008 | MUST | Evidence strength shall support `Strong`, `Medium` and `Weak`. |
| FR-CLASS-009 | MAY | A report-level primary dossier type may be derived, but it shall not be maintained as a master authoring dimension. |
| FR-CLASS-010 | MUST | New or changed regulatory content shall remain Draft until reviewed by the required Regulatory SME. |

## 10. Master-data relationships and aliases

| ID | Priority | Requirement |
|---|---|---|
| FR-MD-001 | MUST | The workbook shall maintain explicit master-data relationships with stable relationship identifiers. |
| FR-MD-002 | MUST | Relationships shall include authority-to-region, authority-to-technical-standard, authority-to-regional-implementation, technical-standard-to-region and technical-standard-to-regional-implementation where applicable. |
| FR-MD-003 | MUST | Product, lifecycle, procedure and source-presentation applicability shall use relationship rows. |
| FR-MD-004 | MUST | Relationship cardinality and mandatory/optional status shall be defined. |
| FR-MD-005 | MUST | Incomplete mandatory relationships shall block controlled export. |
| FR-ALIAS-001 | MUST | Aliases shall map approved alternate source names to canonical fields or values. |
| FR-ALIAS-002 | MUST | Aliases shall be scoped, versioned, traceable and validated. |
| FR-ALIAS-003 | MUST | Alias resolution shall not alter raw evidence values. |

## 11. Folder, file and XML rule requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-STRUCT-001 | MUST | Folder rules shall support dossier-root, sequence, module and regional-folder checks. |
| FR-STRUCT-002 | MUST | Requirement levels shall include `Mandatory`, `Optional`, `Conditional`, `Prohibited` and `NotApplicable`. |
| FR-STRUCT-003 | MUST | File rules shall support exact name, pattern, extension, relative path, occurrence count, readability and zero-byte behavior. |
| FR-STRUCT-004 | MUST | XML rules shall support filename, root element, namespace, element path, attribute and expected value. |
| FR-STRUCT-005 | MUST | Folder and file findings shall default to `Aggregate` conflict behavior. |
| FR-STRUCT-006 | MUST | RAG aggregation shall default to `MostSevere`. |
| FR-STRUCT-007 | MUST | Applicability shall use relationship tables for region, authority, technical standard, regional implementation and dossier dimensions. |
| FR-STRUCT-008 | MUST | Multi-value applicability cells shall not be used. |
| FR-STRUCT-009 | MUST | Rule content shall distinguish observed technical evidence from business interpretation. |

## 12. Findings and recommendations

| ID | Priority | Requirement |
|---|---|---|
| FR-FIND-001 | MUST | Reusable findings shall be maintained in `Findings`. |
| FR-FIND-002 | MUST | A finding shall define stable code, title, category, default RAG, default severity and exception eligibility. |
| FR-FIND-003 | MUST | Rules shall reference findings rather than embedding complete finding definitions. |
| FR-REC-001 | MUST | Recommendations shall be maintained separately from findings. |
| FR-REC-002 | MUST | Customer-facing and consultant-facing text shall remain separate. |
| FR-REC-003 | MUST | `Finding_Recommendation_Links` shall support multiple ordered recommendations by phase and link type. |
| FR-REC-004 | MUST | Recommendation aggregation shall remove duplicates while preserving configured order. |
| FR-REC-005 | MUST | Updating recommendation text shall not rewrite historical observed findings. |

## 13. Evaluation status, RAG and provenance

Approved evaluation statuses are:

- `Evaluated`;
- `NotAssessed`;
- `NotApplicable`;
- `Skipped`;
- `Warning`;
- `Error`;
- `InsufficientEvidence`;
- `Conflict`.

Approved RAG values are:

- `Green`;
- `Amber`;
- `Red`;
- `Unknown`.

Approved value-source provenance values are:

- `Observed`;
- `CustomerProvided`;
- `Imported`;
- `Derived`;
- `Assumed`.

| ID | Priority | Requirement |
|---|---|---|
| FR-EVAL-001 | MUST | Evaluation status, RAG and provenance shall be stored and reported separately. |
| FR-EVAL-002 | MUST | `NotAssessed` and `NotApplicable` shall never be stored as RAG values. |
| FR-EVAL-003 | MUST | Missing input shall never be interpreted as Green or Pass. |
| FR-EVAL-004 | MUST | RAG shall be assigned only where business/risk interpretation is meaningful. |
| FR-EVAL-005 | MUST | `Calculated` shall be treated as a legacy synonym of `Derived`, not a separate controlled value. |
| FR-EVAL-006 | MUST | Consultant-entered values shall use an explicitly governed provenance code. |
| FR-EVAL-007 | MUST | `Warning` shall mean a completed usable evaluation with a recoverable condition requiring attention; it shall not independently determine RAG, severity, blocker state, effort band or phase result. |

## 14. Priority and conflict requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-CONFLICT-001 | MUST | Lower numeric values shall represent higher priority. |
| FR-CONFLICT-002 | MUST | Priority values shall normally use increments of 100. |
| FR-CONFLICT-003 | MUST | Executable rules shall support `ConflictGroup`, `ConflictStrategy`, `Specificity` and `StopProcessing`. |
| FR-CONFLICT-004 | MUST | Supported strategies shall include `FirstMatch`, `MostSpecific`, `MostSevere`, `Aggregate`, `ErrorOnMultipleMatch`, `HighestEvidenceScore` and `ManualReview`. |
| FR-CONFLICT-005 | MUST | Classification shall default to `HighestEvidenceScore`. |
| FR-CONFLICT-006 | MUST | Tied classification shall produce `Unknown` or `ManualReview`. |
| FR-CONFLICT-007 | MUST | Folder and file findings shall default to `Aggregate`. |
| FR-CONFLICT-008 | MUST | RAG shall default to `MostSevere`. |
| FR-CONFLICT-009 | MUST | Decision rules shall use ordered `FirstMatch` with mandatory blocker override. |
| FR-CONFLICT-010 | MUST | Unresolved conflicts shall not be silently resolved. |

## 15. Threshold, effort and confidence requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-THR-001 | MUST | Thresholds shall define lower bound, upper bound, inclusivity flags and unit. |
| FR-THR-002 | MUST | The default convention shall be lower-inclusive and upper-exclusive. |
| FR-THR-003 | MUST | Gaps, overlaps, inverted ranges and duplicate bands shall fail validation where complete coverage is required. |
| FR-THR-004 | MUST | Open-ended lowest and highest bands shall be supported. |
| FR-EFF-001 | MUST | Effort shall use a hybrid model combining weighted score and mandatory minimum-band overrides. |
| FR-EFF-002 | MUST | Critical conditions may impose a minimum effort band. |
| FR-EFF-003 | MUST | Effort confidence shall be calculated separately. |
| FR-EFF-004 | MUST | Customer-facing reports shall show final band, confidence, key drivers, assumptions and missing information. |
| FR-EFF-005 | SHOULD | Raw numeric score shall remain internal unless explicitly approved for disclosure. |
| FR-EFF-006 | MUST | Rules shall prevent double counting of the same underlying driver where configured. |

## 16. Exception policy requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-EXC-001 | MUST | The master workbook shall maintain exception policies, not project-specific accepted exceptions. |
| FR-EXC-002 | MUST | Policies shall define eligible finding, allowed effect, required role, evidence requirement, expiry and carry-forward behavior. |
| FR-EXC-003 | MUST | Accepted exceptions shall never erase or replace the original finding, original RAG or evidence. |
| FR-EXC-004 | MUST | Supported effects shall include `AcknowledgeOnly`, `RemoveBlock`, `ExcludeFromScope`, `AcceptDifference` and `DowngradeDecisionImpact`. |
| FR-EXC-005 | MUST | `CarryForwardToPostMigration` shall default to False. |
| FR-EXC-006 | MUST | Actual project exceptions shall remain in project evidence. |
| FR-EXC-007 | MUST | Adjusted decision treatment shall remain traceable separately from the original finding. |

## 17. Report definitions and controlled terminology

| ID | Priority | Requirement |
|---|---|---|
| FR-RPT-001 | MUST | Report terminology shall use the controlled terminology catalogue. |
| FR-RPT-002 | MUST | Phase result terms shall be maintained separately from rule findings. |
| FR-RPT-003 | MUST | Report definitions shall identify required sheets, columns, codes and phase applicability. |
| FR-RPT-004 | MUST | Pre-Sales results shall use complexity and confidence terminology, not readiness terminology. |
| FR-RPT-005 | MUST | Pre-Migration results shall be `Ready`, `Ready with Accepted Exceptions` or `Blocked`. |
| FR-RPT-006 | MUST | Post-Migration results shall be `Reconciled`, `Reconciled with Accepted Exceptions`, `Review Required` or `Not Reconciled`. |
| FR-RPT-007 | MUST | Configuration and report wording shall not claim migration execution, regulatory validation, formal customer validation, electronic approval or customer acceptance. |

## 18. Validation and export requirements

| ID | Priority | Requirement |
|---|---|---|
| FR-VAL-001 | MUST | Critical validations shall always run and shall not be disableable. |
| FR-VAL-002 | MUST | Validation controls shall use structured parameters and shall not contain free-text executable conditions. |
| FR-VAL-003 | MUST | Validation shall cover structures, identifiers, references, statuses, operators, phase assignments, thresholds, conflicts, findings, recommendations, exception policies, master-data relationships and compatibility. |
| FR-VAL-004 | MUST | Mandatory validation failures shall block export. |
| FR-VAL-005 | MUST | Acknowledgeable warnings shall record user, timestamp, warning code, reason and export filename. |
| FR-VAL-006 | MUST | Every validation result shall identify control, severity, entity and actionable message. |
| FR-EXP-001 | MUST | Excel/VBA shall generate one UTF-8 JSON file directly. |
| FR-EXP-002 | MUST | Controlled runtime filename shall be `eMAS_Runtime_Config.json`. |
| FR-EXP-003 | MUST | JSON shall be UTF-8 without BOM and use culture-invariant serialization. |
| FR-EXP-004 | MUST | The workbook shall provide formatted preview and section counts. |
| FR-EXP-005 | MUST | Exported JSON shall never be truncated. |
| FR-EXP-006 | MUST | Controlled export shall include only runtime-eligible Effective rules. |
| FR-EXP-007 | MUST | The workbook shall calculate and record SHA-256 after controlled export. |
| FR-EXP-008 | MUST | Export history shall record filename, path, user, timestamp, versions, validation run, file size, checksum and result. |
| FR-EXP-009 | MUST | Controlled JSON shall be immutable after export. |
| FR-EXP-010 | MUST | PowerShell shall not create, repair or rewrite the JSON. |

## 19. Security, release and repository handling

| ID | Priority | Requirement |
|---|---|---|
| FR-SEC-001 | MUST | Customer data and project evidence shall not be stored in the mapping workbook. |
| FR-SEC-002 | MUST | Credentials, secrets and personal data not required for configuration shall not be exported. |
| FR-SEC-003 | MUST | The internal XLSM, VBA source and controlled configuration shall follow approved repository and internal-storage classification. |
| FR-SEC-004 | MUST | Macro signing and trusted-location handling shall follow the approved corporate process before controlled release. |
| FR-REL-001 | MUST | Controlled releases shall include workbook version, mapping version, schema version, JSON checksum, validation result and release reference. |
| FR-REL-002 | MUST | The internal mapping workbook shall not be included in the customer pre-sales package. |
| FR-REL-003 | MUST | Generated temporary JSON and uncontrolled exports shall not be committed to the public repository. |

## 20. Acceptance criteria

The functional requirements are satisfied when:

1. controlled values use dropdowns and fixed protected headers;
2. rule identity, lifecycle, phase assignments, conditions and outputs are normalized;
3. findings and recommendations are separate and linked;
4. evaluation status, RAG and provenance are separate;
5. classification uses the approved normalized dimensions;
6. ASMF is represented as ProcedureContext;
7. lifecycle eligibility is calculated without editable IsActive;
8. conflicts, thresholds and exception policies validate according to the approved defaults;
9. critical validation failures block export;
10. the workbook exports exactly one deterministic `eMAS_Runtime_Config.json` directly from Excel/VBA;
11. the JSON is UTF-8 without BOM and culture-invariant;
12. SHA-256 and export metadata are recorded;
13. PowerShell does not read the workbook or create JSON;
14. controlled terminology is applied consistently;
15. new regulatory content remains subject to the approved SME workflow.

## 21. Delivery state and remaining implementation work

The design decisions in this document are Effective. The following remain implementation or content-population work rather than unresolved architecture decisions:

- final regulatory master-data values and relationships require documented Regulatory SME review;
- final effort weights, thresholds and confidence weights require approved product/migration-owner evidence;
- exact exception approver roles require approved governance content;
- XLSM/VBA implementation, signing, test fixtures and release validation remain to be completed;
- independent JSON Schema validation and representative golden fixtures remain required.

## 22. Revision history

| Version | Date | Change |
|---|---|---|
| 2.0 | 2026-07-12 | Draft normalized workbook requirements before approval of the decision register |
| 3.0 | 2026-07-13 | Effective baseline synchronized to approved governance, terminology, normalized rule model and runtime JSON contract |
