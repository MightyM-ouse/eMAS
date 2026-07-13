---
SkillId: SKILL-004
Title: Add or Modify Regulatory Classification Content
Version: 1.0.0
Status: Effective
Owner: Regulatory SME and Product Owner
DecisionReferences:
  - SK-019
  - REG-001
  - REG-014
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/governance/eMAS_Terminology.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md
  - docs/configuration/05_eMAS_Normalized_Rule_Model.md
  - docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md
  - docs/configuration/07_eMAS_Data_Dictionary.md
  - docs/llm-development-context/ectd-regulatory-expert.md
AppliesTo:
  - Regulatory master data
  - Classification evidence and aliases
  - Regulatory relationships and rules
Supersedes: null
LastReviewed: 2026-07-13
---

# Add or Modify Regulatory Classification Content

## Invoke when

- Adding or changing a Region, Authority, TechnicalStandard, RegionalImplementation, ProductDomain, LifecycleContext, ProductClass, ProcedureContext or SourcePresentation value.
- Adding evidence patterns, aliases or relationships used to classify a dossier or submission package.
- Correcting a classification that mixes a procedure, technical standard, regional implementation or source presentation.

## Do not invoke when

- The logical entity/relationship model must change; use `modify-configuration-model.md` first.
- Only schema serialization changes; use `update-json-schema.md`.
- A customer-specific dossier needs a one-time project decision; retain it as project evidence rather than general product configuration.

## Required inputs and canonical sources

- Approved request or identified content gap with affected classification dimension.
- Current Effective controlled terminology, Content Catalogue, Relationship Matrix and Data Dictionary.
- Primary health-authority, standards-body or other authoritative source evidence.
- Source title, publisher/authority, publication/effective date, version and stable reference.
- Regulatory SME and Product Owner review requirements.
- Existing aliases, relationships, evidence strengths, rules and superseded values.
- Explicit applicable phases, jurisdictions and effective-date boundaries.

## Preconditions

- The classification dimension is correctly identified.
- At least one authoritative source is available or the record will remain Draft.
- The proposed value is not a customer-specific convenience label.
- Broad geographic groupings are distinguished from regulatory authorities.
- Required SME ownership and approval route are known.

## Procedure

1. **Identify the dimension.** Decide whether the concept is Region, Authority, TechnicalStandard, RegionalImplementation, ProductDomain, LifecycleContext, ProductClass, ProcedureContext or SourcePresentation.
2. **Prevent taxonomy collapse.** Confirm that a procedure such as ASMF is not entered as a technical standard and that paper/scanned packaging is not treated as a regulatory format.
3. **Collect authoritative evidence.** Record primary source, version, publication/effective date, jurisdiction and relevant scope. Prefer official authority/standards sources over secondary commentary.
4. **Check existing content.** Search canonical values, aliases, relationships and supersession records to avoid duplicates or conflicting meanings.
5. **Assign stable identity.** Create or reuse a stable code/ID independent of display text. Do not reuse retired or superseded IDs.
6. **Define lifecycle.** Create new LLM-generated content as Draft, with effective dates and review status explicit. Do not mark Effective solely because an LLM proposed it.
7. **Define relationships.** Link Region, Authority, TechnicalStandard and RegionalImplementation explicitly using approved relationship types and valid temporal ranges.
8. **Define evidence patterns.** Add attributable indicators, evidence strength, match behavior, phase applicability and conflict behavior without embedding arbitrary code.
9. **Define aliases carefully.** Record source label, canonical target, scope and evidence. Avoid aliases that hide a real ambiguity between dimensions.
10. **Assess classification conflicts.** Apply `HighestEvidenceScore` or the approved strategy; tied/contradictory strong evidence must result in Unknown or ManualReview rather than forced classification.
11. **Add synthetic examples.** Create positive, negative and ambiguous examples that do not contain customer data and are not presented as regulatory authority.
12. **Obtain SME review.** Capture Regulatory SME rationale and Product Owner disposition before promotion to Reviewed/Effective.
13. **Synchronize configuration.** Update affected master data, relationships, rules, aliases, findings/recommendations and documentation.
14. **Record provenance.** Retain evidence references, approver, status, effective dates, supersession and change history.

## Required outputs

- Proposed or updated controlled classification record with stable ID/code.
- Correct dimension assignment and explicit relationships.
- Authoritative evidence summary and source metadata.
- Alias/evidence-pattern/rule impact, including ambiguity behavior.
- Lifecycle status and required approvals.
- Synthetic positive, negative and ambiguous examples.
- SME review record and promotion or rejection decision.
- Traceability to configuration records and tests.

## Stop conditions

Stop when:

- no authoritative evidence is available for promotion beyond Draft;
- Regulatory SME review is required but unavailable;
- the concept cannot be assigned to one normalized dimension;
- a broad grouping is being treated as an authority;
- conflicting official sources cannot be reconciled;
- a technical standard, regional implementation, procedure or presentation is being conflated;
- the proposed content would silently change phase decisions, thresholds or report meaning;
- customer-specific evidence is being generalized without approved justification.

## Validation and evidence

- Verify the stable code is unique and the display text is separate.
- Verify every relationship uses an approved endpoint pair and valid date range.
- Verify ASMF-like procedures and regional implementations are assigned to correct dimensions.
- Verify aliases resolve to an approved canonical target and do not create hidden ambiguity.
- Test positive, negative, tied and contradictory evidence behavior.
- Record source/authority, version/date, SME reviewer, Product Owner decision and effective status.
- Confirm Draft content is excluded from controlled runtime JSON until eligible.

## Definition of Done

- The classification dimension and stable identity are correct.
- Primary authoritative evidence and provenance are recorded.
- Relationships, aliases and evidence patterns are normalized and validated.
- Ambiguous/conflicting evidence produces Unknown or ManualReview as required.
- Regulatory SME and Product Owner approvals are captured before Effective status.
- Synthetic tests cover positive, negative and ambiguous behavior.
- Runtime configuration and documentation are synchronized.
- No unresolved stop condition remains.
