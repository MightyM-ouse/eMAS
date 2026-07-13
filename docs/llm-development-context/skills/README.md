# eMAS Operational LLM Skills

**Version:** 1.0.0  
**Status:** Effective Operational Skill Catalogue  
**Owner:** Technical Architect  
**Decision references:** SK-001 through SK-019  
**Effective date:** 2026-07-13

Operational skills convert canonical eMAS requirements and contracts into repeatable task procedures. They do not create requirements, approve regulatory content or override the Authority and Precedence Policy.

## Required use

1. Select the task route in `../context-index.yaml`.
2. Read the governing requirements, configuration contracts, Solution Architecture and applicable phase contract.
3. Select the narrowest applicable skill from the catalogue below.
4. Execute the ordered procedure and produce all required outputs/evidence.
5. Stop when any skill stop condition is met.
6. Use `review-change.md` before merge for material repository changes.

When multiple skills apply, use the dependency order:

```text
Configuration model → JSON Schema → Regulatory content → Report contract → PowerShell implementation → Change review
```

Use `investigate-defect.md` first when the root cause is unknown.

## Effective skill catalogue

| Skill ID | File | Primary use | Accountable owner |
|---|---|---|---|
| SKILL-001 | [Modify Configuration Model](modify-configuration-model.md) | Entities, fields, relationships, lifecycle and normalized structure | Product Owner / Technical Architect |
| SKILL-002 | [Update Runtime JSON Schema](update-json-schema.md) | Serialization, semantic validation, fixtures and compatibility | Technical Architect / QA Lead |
| SKILL-003 | [Implement PowerShell Module](implement-powershell-module.md) | Shared engine modules and phase entry scripts | PowerShell Lead / Technical Architect |
| SKILL-004 | [Add Regulatory Classification](add-regulatory-classification.md) | Evidence-backed regulatory values, aliases, relationships and rules | Regulatory SME / Product Owner |
| SKILL-005 | [Modify Report Contract](modify-report-contract.md) | Controlled XLSX contracts, templates, baseline and MigrationSummary interfaces | Product Owner / Reporting Lead |
| SKILL-006 | [Review Repository Change](review-change.md) | Independent PR, architecture, traceability and safety review | Technical Architect / QA Lead |
| SKILL-007 | [Investigate Defect](investigate-defect.md) | Reproduction, root cause, impact and regression evidence | Technical Lead / QA Lead |

The machine-readable catalogue is [skill-catalog.json](skill-catalog.json).

## Required metadata

Every Effective skill uses YAML front matter containing:

- `SkillId`;
- `Title`;
- Semantic `Version`;
- `Status`;
- `Owner`;
- `DecisionReferences`;
- `CanonicalSources`;
- `AppliesTo`;
- `Supersedes`;
- `LastReviewed`.

## Required sections

Every skill contains, in this order:

1. Invoke when
2. Do not invoke when
3. Required inputs and canonical sources
4. Preconditions
5. Procedure
6. Required outputs
7. Stop conditions
8. Validation and evidence
9. Definition of Done

Each Invoke/Do not invoke section contains at least two concrete examples. Procedures are ordered and auditable. Outputs and Definition of Done are testable rather than aspirational.

## Common mandatory stop conditions

Stop and identify the unresolved decision when:

- a higher-authority source conflicts with the requested change;
- regulatory interpretation lacks required SME evidence;
- the runtime JSON cannot represent the requested behavior;
- schema or engine compatibility is uncertain;
- a phase result, baseline or report meaning would change without approved authority;
- source evidence cannot remain read-only;
- required acceptance criteria, inputs or test evidence are missing;
- customer/confidential data would enter the public repository.

## Regulatory guardrail

LLM-generated regulatory content remains Draft until reviewed by the required Regulatory SME and Product Owner. It must never be exported as Effective configuration solely because an LLM generated it.

## Validation

Run the catalogue validator locally:

```bash
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
```

CI validates front matter, section order, minimum procedure/evidence content, catalogue consistency and canonical-source path existence.

## Adding a skill

Use [skill-template.md](skill-template.md), assign a stable SkillId, add it to `skill-catalog.json`, update context routing and pass the validator. A new skill remains Draft until its owner and Technical Architect approve it.
