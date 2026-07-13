---
SkillId: SKILL-001
Title: Modify the eMAS Configuration Model
Version: 1.0.0
Status: Effective
Owner: Product Owner and Technical Architect
DecisionReferences:
  - SK-001
  - SK-004
  - RM-001
  - RM-027
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md
  - docs/configuration/05_eMAS_Normalized_Rule_Model.md
  - docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md
  - docs/configuration/07_eMAS_Data_Dictionary.md
  - docs/configuration/04_eMAS_Runtime_JSON_Contract.md
  - docs/architecture/eMAS_Solution_Architecture.md
AppliesTo:
  - Mapping workbook logical model
  - Normalized entities and relationships
  - Runtime configuration content structure
Supersedes: null
LastReviewed: 2026-07-13
---

# Modify the eMAS Configuration Model

## Invoke when

- Adding, removing or changing a normalized entity, field, key, relationship, lifecycle attribute or controlled-list category.
- Changing how rules, phases, condition groups, conditions, outputs, findings, recommendations, aliases, policies or master data relate to one another.
- Replacing an ambiguous repeating field with a dedicated link entity or typed reference.

## Do not invoke when

- Only JSON serialization or schema constraints change without a logical-model change; use `update-json-schema.md`.
- Only approved regulatory values or evidence-backed classifications are being added; use `add-regulatory-classification.md`.
- Only the physical report workbook layout changes; use `modify-report-contract.md`.

## Required inputs and canonical sources

- Approved requirement, DecisionId, defect reference or change request describing the intended behavior.
- Current Enterprise Requirements, Content Catalogue, Normalized Rule Model, Relationship Matrix and Data Dictionary.
- Runtime JSON Contract, Schema 1.0.0, fixture manifest and independent semantic validator.
- Current workbook table design, JSON serialization and implementation/test locations affected by the change.
- Explicit acceptance criteria, compatibility expectation and accountable owner.
- Regulatory or Migration SME evidence when the change includes domain meaning rather than structure alone.

## Preconditions

- The requested behavior is approved or is clearly classified as a new decision requiring approval.
- Structural change and content change are distinguished.
- No unresolved authority or terminology conflict exists.
- The affected entities, keys, relationships and runtime collections can be identified.
- Required Product Owner, Technical Architect and SME roles are available for review.

## Procedure

1. **Resolve authority.** Record the requirement/DecisionIds and confirm that no lower-authority document or example is being treated as the source of the change.
2. **Classify the change.** Identify whether it affects entity inventory, field semantics, identifier rules, relationship cardinality, lifecycle, controlled values, runtime serialization or only workbook presentation.
3. **Map current impact.** List the affected entities, primary/composite keys, foreign keys, relationship types, phase applicability, temporal rules and runtime collections.
4. **Design the normalized change.** Prefer stable identifiers, dedicated link entities and explicit typed discriminators. Do not introduce comma-separated relationships, editable `IsActive` lifecycle control or ambiguous polymorphic references.
5. **Assess compatibility.** Classify the change as non-breaking, backward-compatible additive or breaking. Identify required mapping/schema version action and data migration or supersession behavior.
6. **Update the logical contracts.** Change the Content Catalogue, Relationship Matrix and Data Dictionary together. Update the Normalized Rule Model when rule/lifecycle/output behavior changes.
7. **Update workbook requirements.** Define table/header, validation, dropdown, protection, import/export and human-usability impact without weakening the normalized logical model.
8. **Assess runtime impact.** Determine whether the Runtime JSON Contract or Schema 1.0.0 must change. When they do, invoke `update-json-schema.md` before implementation is considered complete.
9. **Update validation rules.** Add or modify referential, uniqueness, temporal, controlled-list and cross-entity semantic checks.
10. **Create evidence cases.** Add valid, invalid and boundary cases that demonstrate the new model, including at least one broken-reference or cardinality case where applicable.
11. **Synchronize consumers.** Identify PowerShell loader/engine, phase contract, report contract, VBA, templates, tests, documentation indexes and migration scripts that must be updated or explicitly tracked.
12. **Review and record.** Produce a change-impact matrix, compatibility decision, owner approvals, validation results and unresolved implementation items.

## Required outputs

- Approved logical-model change summary and traceability references.
- Updated entity/field/relationship definitions with stable identifiers and cardinalities.
- Compatibility and versioning assessment.
- Workbook, JSON Schema, PowerShell, reporting and test impact matrix.
- Updated validation rules and synthetic evidence cases.
- Migration, supersession or deprecation plan where existing content is affected.
- Explicit list of downstream work that remains implementation pending.

## Stop conditions

Stop when:

- a higher-authority source conflicts with the requested model;
- the change introduces regulatory meaning without required SME evidence;
- stable identity, cardinality or ownership cannot be determined;
- the behavior cannot be represented without arbitrary executable expressions or ambiguous free text;
- a breaking change is proposed without approved versioning and migration treatment;
- runtime JSON compatibility is uncertain;
- phase outcome or report meaning would change without an approved requirement;
- acceptance criteria or accountable owner are missing.

## Validation and evidence

- Verify primary and composite uniqueness, foreign-key integrity and approved endpoint pairs.
- Verify temporal ranges, supersession rules and no identifier reuse.
- Verify repeating relationships use link entities rather than delimited cells.
- Validate the resulting JSON structure and semantic rules with the independent validator.
- Record affected requirement IDs, DecisionIds, entity/field IDs, schema/configuration versions and fixture/test IDs.
- Preserve a before/after model extract and the commands/results used for validation.

## Definition of Done

- Authority, terminology and approval requirements are satisfied.
- Content Catalogue, Relationship Matrix and Data Dictionary are synchronized.
- Rule Model, Runtime JSON Contract and Schema are updated or formally confirmed unaffected.
- Workbook and runtime consumers have an implemented change or a tracked downstream item.
- Valid, invalid and boundary evidence covers the change.
- Compatibility, migration and supersession treatment is documented.
- Documentation indexes and change history are synchronized.
- No unresolved stop condition remains.
