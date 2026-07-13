---
SkillId: SKILL-XXX
Title: Replace with skill title
Version: 1.0.0
Status: Draft
Owner: Replace with accountable owner
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
AppliesTo:
  - Replace with component or phase
Supersedes: null
LastReviewed: 2026-07-13
---

# Skill title

## Invoke when

- Concrete task example 1.
- Concrete task example 2.

## Do not invoke when

- Counter-example 1 and the correct skill to use.
- Counter-example 2 and the correct skill to use.

## Required inputs and canonical sources

- Approved requirement or defect reference.
- Applicable canonical documents.
- Current implementation and tests.
- Acceptance criteria.

## Preconditions

- Required decisions are approved.
- No unresolved authority conflict exists.
- Required files and evidence are available.

## Procedure

1. Identify the requested behaviour and affected phase/component.
2. Confirm the governing requirement and authority level.
3. Identify configuration, schema, code, report and test impact.
4. Apply the smallest auditable change.
5. Add or update validation and tests.
6. Produce traceability and evidence.

## Required outputs

- Change summary.
- Files and requirements affected.
- Behaviour before and after.
- Validation and test evidence.
- Risks, limitations and unresolved questions.

## Stop conditions

Stop when:

- canonical sources conflict;
- regulatory interpretation is not approved;
- JSON compatibility is uncertain;
- the requested behaviour cannot be represented by approved configuration;
- phase decision or report meaning would change without approval;
- acceptance criteria are missing.

## Validation and evidence

- Record requirement IDs, rule IDs, schema/configuration versions and test IDs where applicable.
- Preserve source evidence and read-only behaviour.
- Record commands, results and known limitations.

## Definition of Done

- The change follows the authority and precedence policy.
- Business/regulatory logic is not hardcoded in PowerShell.
- The runtime contract remains valid.
- Applicable tests pass.
- Documentation and traceability are synchronized.
- No unresolved stop condition remains.