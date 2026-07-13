# LLM Development Context for eMAS

**Version:** 2.1  
**Status:** Effective implementation guidance  
**Authority rank:** 7 — subordinate to approved requirements, governance, configuration contracts, schemas and architecture

This folder contains focused, high-signal context and Effective operational procedures for disciplined LLM-assisted eMAS development.

## Mandatory authority path

Before implementation:

1. load task-specific sources from [context-index.yaml](context-index.yaml);
2. apply [Authority and Precedence](../governance/00_authority_and_precedence.md);
3. use the [Canonical Document Index](../CANONICAL_DOCUMENT_INDEX.md);
4. apply [Controlled Terminology](../governance/eMAS_Terminology.md);
5. read [Enterprise Requirements v3.1](../requirements/eMAS_Final_Enterprise_Requirements_v3.1.md);
6. apply the Effective configuration and Schema 1.0.0 contracts;
7. apply [Solution Architecture](../architecture/eMAS_Solution_Architecture.md) and the applicable [phase contract](../architecture/phase-contracts/README.md);
8. select the narrowest applicable [Effective operational skill](skills/README.md);
9. identify applicable DecisionIds and acceptance criteria.

## Source boundaries

- reviewed internal XLSM = authoring source;
- validated immutable exported JSON = runtime source;
- exact JSON version and checksum loaded for a run = execution source.

PowerShell never reads the XLSM and never creates, repairs or reinterprets runtime JSON.

## Decision and delivery boundary

The Product Owner approved all 171 reviewed decisions on 13 July 2026. An LLM must distinguish:

- approved decision;
- synchronized requirements/documentation;
- implemented behavior;
- verified behavior;
- released behavior.

Architecture, phase contracts and seven operational skills are Effective. Entry scripts, engine modules, WPF, XLSM/VBA, controlled templates and complete release controls remain separate implementation work until evidence exists.

## Operational skill use

The machine-readable [skill catalogue](skills/skill-catalog.json) routes work to procedures for:

- configuration-model changes;
- JSON Schema changes;
- PowerShell implementation;
- regulatory classification content;
- report contracts/templates;
- repository change review;
- defect investigation.

Every skill defines invocation and non-invocation examples, inputs, preconditions, ordered procedure, required outputs, stop conditions, validation evidence and Definition of Done. Skills are subordinate to canonical sources and never create requirements.

## How to use

- load only the context required for the selected task;
- use [llm-development-rules.md](llm-development-rules.md) as mandatory constraints;
- use [decision-boundary.md](decision-boundary.md) for unresolved conflicts and stop conditions;
- use [phases.md](phases.md) only as a summary; the Effective phase contract prevails;
- use [ectd-regulatory-expert.md](ectd-regulatory-expert.md) for controlled context, but keep LLM-generated regulatory content Draft until SME approval;
- use `review-change.md` before merging material repository changes.

## Files

- `context-index.yaml` — authority, task and skill routing;
- `core-design.md` — concise source-of-truth design context;
- `phases.md` — phase summary routed to Effective contracts;
- `configuration-rules.md` — XLSM and JSON rules;
- `engine-patterns.md` — shared engine and evidence patterns;
- `ectd-regulatory-expert.md` — controlled regulatory classification context;
- `llm-development-rules.md` — mandatory development constraints;
- `decision-boundary.md` — decision and stop rules;
- `skills/README.md` — Effective operational skill catalogue;
- `skills/skill-catalog.json` — machine-readable skill catalogue.

## Validation

```bash
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
```

## Prohibited authority assumptions

Do not treat generated summaries, archived Version 2 documents, illustrative examples, uncontrolled fixtures, unapproved regulatory interpretations, customer-specific evidence or conflicting code comments as authority.

Keep outputs explicit, traceable, minimally scoped and consistent with the Effective Solution Architecture, applicable phase contract and selected operational skill.
