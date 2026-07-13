# eMAS Mapping and Configuration Workbook — Functional Requirements

**Version:** 3.1  
**Status:** Approved  
**Authority:** Enterprise Requirements v3.1 and approved decisions  
**Scope:** Internal XLSM authoring application

## 1. Purpose

The XLSM is the controlled authoring source for eMAS business and regulatory configuration. It validates maintained data and directly exports one UTF-8 runtime JSON file. PowerShell does not read the workbook.

## 2. Normative workbook inventory

The normalized content catalogue inventory is authoritative and supersedes the flat illustrative sheet list in Enterprise Requirements v3.0 Section 9.3.

### Governance

Home, Document_Control, Change_History, Change_History_Items, Export_History.

### Catalogues and master data

Assessment_Profile, Value_Lists, Field_Catalogue, Metric_Catalogue, Regions, Authorities, Technical_Standards, Regional_Implementations, Procedure_Contexts, Source_Presentations, Product_Domains, Lifecycle_Contexts, Product_Classes and dedicated master-data relationship sheets.

### Rules

Classification_Rules, Folder_Rules, File_Rules, XML_Detection_Rules, RAG_Rules, Confidence_Rules, Effort_Driver_Definitions, Effort_Driver_Bands and Decision_Rules.

### Relationships and outputs

Rule_Phase_Assignment, Rule_Conditions, Rule_Outputs, Rule_Supersession, Findings, Recommendations, Finding_Recommendation_Links, Questionnaire_Map, Exception_Policies and Aliases.

### Technical and generated sheets

Validation_Controls, Validation_Results, JSON_Preview, Rule_Index and Technical_Settings.

## 3. Usability requirements

- **FR-UX-001 MUST:** fixed, protected technical table and column names.
- **FR-UX-002 MUST:** finite values use named-range dropdowns from Value_Lists.
- **FR-UX-003 MUST:** free text is restricted to descriptions, rationale, comments and approved messages.
- **FR-UX-004 MUST:** numeric, Boolean and date fields use typed validation.
- **FR-UX-005 MUST:** locale-safe named ranges, true date cells with ISO display masks and invariant numeric validation.
- **FR-UX-006 MUST:** Home provides Validate, Preview, Export, Clear Results and Open Export Folder controls.

## 4. Governance and lifecycle

- document and configuration metadata are separate from rule lifecycle;
- rules use Draft, InReview, Reviewed, Effective, Superseded and Retired;
- runtime eligibility is Effective and `EffectiveFrom <= today < EffectiveTo`;
- editable `IsActive` is prohibited;
- controlled exports include Effective entities only;
- DEV exports may include Reviewed entities and must be clearly named;
- IDs are never reused;
- supersession relationships are validated for cycles, overlaps and successor references.

## 5. Normalized rule model

Every authoring rule has a common header and relationships to:

- explicit phase assignments;
- OR-of-AND condition groups;
- typed outputs;
- findings;
- conflict strategy;
- lifecycle and supersession.

The workbook shall not store comma-separated multi-value relationships or executable VBA/PowerShell expressions in cells.

## 6. Classification

Classification produces independent results for:

- Region;
- Authority;
- TechnicalStandard;
- RegionalImplementation;
- ProcedureContext;
- SourcePresentation;
- ProductDomain;
- LifecycleContext;
- ProductClass.

The original mixed `Format` list is superseded. ASMF is a ProcedureContext, not a technical format. eCTD v4.0 v1 scope is detect-and-classify only; full structure validation is deferred.

Classification conflict resolution defaults to HighestEvidenceScore. Equal top scores produce result Unknown, EvaluationStatus Conflict and `ManualReviewRequired=true`.

## 7. RAG, evaluation and evidence

- RAG: Green, Amber, Red, Unknown.
- EvaluationStatus: Evaluated, NotAssessed, NotApplicable, Skipped, Error, InsufficientEvidence, Conflict.
- ValueSourceType: Observed, CustomerProvided, Imported, Derived, Assumed.

Missing input never produces Green.

## 8. Findings, recommendations and exceptions

- findings and recommendations are separate;
- links support phase, Primary/Secondary type and sequence;
- recommendation texts keep customer-facing and consultant-facing wording separate;
- exception policies define eligibility, allowed effect, approver role, evidence, expiry, scope and carry-forward;
- project exceptions are external controlled inputs;
- exceptions never erase original findings.

## 9. Thresholds, effort and confidence

Thresholds define lower/upper bounds, inclusivity and unit. Default is lower-inclusive/upper-exclusive. Gaps and overlaps fail validation for complete band sets.

Effort uses weighted drivers plus minimum-band overrides. Raw score remains internal. Reports show final band, confidence, drivers, assumptions and missing information.

Classification confidence is calculated per dimension. Estimate confidence is calculated separately.

## 10. Validation and export

Validation shall cover structure, IDs, references, code lists, lifecycle, dates, phase assignments, field/operator compatibility, conditions, thresholds, conflicts, outputs, findings, recommendations, exceptions, aliases and schema compatibility.

Controlled export is blocked by mandatory validation failures.

The workbook exports deterministic UTF-8 without BOM, invariant-culture JSON. Rule collections are sorted by stable ID and sequence. Controlled release records SHA-256 in the packaging manifest and Export_History.

## 11. Regulatory governance

Every regulatory profile and rule carries an authoritative SourceReference, SME reviewer, review date, effective date and review-due date. LLM-drafted content remains Draft until normal SME approval.
