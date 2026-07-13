---
SkillId: SKILL-XXX
Title: Replace with skill title
Version: 0.1.0
Status: Draft
Owner: Replace with accountable owner
DecisionReferences:
  - Replace with approved DecisionId
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - Replace with task-specific canonical source
AppliesTo:
  - Replace with component or phase
Supersedes: null
LastReviewed: 2026-07-13
---

# Replace with skill title

## Invoke when

- Concrete task example 1.
- Concrete task example 2.

## Do not invoke when

- Counter-example 1 and the correct skill to use.
- Counter-example 2 and the correct skill to use.

## Required inputs and canonical sources

- Approved requirement, DecisionId or defect reference.
- Applicable canonical documents selected through `context-index.yaml`.
- Current implementation/configuration/templates and tests.
- Explicit acceptance criteria and accountable owner.

## Preconditions

- Required decisions are approved or the task is explicitly Draft investigation.
- No unresolved authority conflict exists.
- Required files and evidence are available.

## Procedure

1. Identify the requested behavior and affected phase/component.
2. Confirm the governing requirement, DecisionIds and authority level.
3. Identify configuration, schema, code, report, test and release impact.
4. Apply the smallest explicit and auditable change.
5. Add or update validation, negative cases and boundary cases.
6. Produce traceability and evidence.

## Required outputs

- Change/investigation summary.
- Files, requirements and versions affected.
- Behavior before and after.
- Validation and test evidence.
- Risks, limitations and unresolved questions.

## Stop conditions

Stop when:

- canonical sources conflict;
- regulatory interpretation is not approved;
- JSON/logical-model compatibility is uncertain;
- requested behavior cannot be represented by approved configuration;
- phase decision, baseline or report meaning would change without approval;
- source evidence cannot remain read-only;
- acceptance criteria or required evidence are missing.

## Validation and evidence

- Record requirement IDs, DecisionIds, rule/field IDs, schema/configuration versions and test IDs where applicable.
- Preserve source evidence and read-only behavior.
- Record commands, results and known limitations.
- Use synthetic or approved Golden Fixtures only.

## Definition of Done

- Authority and precedence are satisfied.
- Architecture and applicable phase contract are followed.
- Business/regulatory logic is not hardcoded in PowerShell.
- Runtime and reporting contracts remain valid.
- Applicable positive, negative, boundary and regression tests pass.
- Documentation and traceability are synchronized.
- No unresolved stop condition remains.
