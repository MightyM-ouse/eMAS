# eMAS Operational LLM Skills

**Status:** Approved framework  
**Decision references:** SK-001 through SK-019

Operational skills convert canonical requirements into repeatable task procedures. They do not create requirements and must comply with `docs/governance/00_authority_and_precedence.md`.

## Required metadata

Every skill uses YAML front matter containing:

- `SkillId`
- `Title`
- `Version` using SemVer
- `Status`
- `Owner`
- `CanonicalSources`
- `AppliesTo`
- `Supersedes`
- `LastReviewed`

## Required sections

Every skill must contain:

1. Invoke when
2. Do not invoke when
3. Required inputs and canonical sources
4. Preconditions
5. Ordered procedure
6. Required outputs
7. Stop conditions
8. Validation and evidence
9. Definition of Done

Each `Invoke when` and `Do not invoke when` section contains at least two concrete examples.

## Mandatory stop conditions

Stop and identify the unresolved decision when:

- a higher-authority source conflicts with the requested change;
- regulatory interpretation is not approved;
- the runtime JSON cannot represent the requested behaviour;
- schema compatibility is uncertain;
- phase decision or report meaning would change without an approved requirement;
- required input evidence or acceptance criteria are missing.

## Regulatory guardrail

LLM-generated regulatory content remains Draft until reviewed by the required Regulatory SME and Product Owner. It must never be exported as Effective configuration solely because an LLM generated it.

## Initial skill catalogue

- `modify-configuration-model.md`
- `update-json-schema.md`
- `implement-powershell-module.md`
- `add-regulatory-classification.md`
- `modify-report-contract.md`
- `review-change.md`
- `investigate-defect.md`

Use `skill-template.md` for all new skills.