# LLM Development Context for eMAS

**Version:** 2.0  
**Status:** Effective implementation guidance  
**Authority rank:** 7 — subordinate to approved requirements, governance, configuration contracts, schemas and architecture

This folder contains focused, high-signal context for disciplined LLM-assisted eMAS development.

## Mandatory authority path

Before implementation:

1. load task-specific sources from [context-index.yaml](context-index.yaml);
2. apply [Authority and Precedence](../governance/00_authority_and_precedence.md);
3. use the [Canonical Document Index](../CANONICAL_DOCUMENT_INDEX.md);
4. apply [Controlled Terminology](../governance/eMAS_Terminology.md);
5. read [Enterprise Requirements v3.1](../requirements/eMAS_Final_Enterprise_Requirements_v3.1.md);
6. apply the Effective configuration and Schema 1.0.0 contracts;
7. apply [Solution Architecture](../architecture/eMAS_Solution_Architecture.md) and the applicable [phase contract](../architecture/phase-contracts/README.md);
8. identify applicable DecisionIds.

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

Architecture and phase contracts are now Effective. Entry scripts, engine modules, WPF, XLSM/VBA, templates and complete release controls remain separate implementation work until evidence exists.

## How to use

- load only the context required for the selected task;
- use [llm-development-rules.md](llm-development-rules.md) as mandatory constraints;
- use [decision-boundary.md](decision-boundary.md) for unresolved conflicts and stop conditions;
- use [phases.md](phases.md) only as a summary; the Effective phase contract prevails;
- use [ectd-regulatory-expert.md](ectd-regulatory-expert.md) for controlled context, but do not promote new regulatory content without SME evidence;
- use an operational skill when available; each skill must define inputs, procedure, outputs, stop conditions and Definition of Done.

## Files

- `context-index.yaml` — authority and task routing;
- `core-design.md` — concise source-of-truth design context;
- `phases.md` — phase summary routed to Effective contracts;
- `configuration-rules.md` — XLSM and JSON rules;
- `engine-patterns.md` — shared engine and evidence patterns;
- `ectd-regulatory-expert.md` — controlled regulatory classification context;
- `llm-development-rules.md` — mandatory development constraints;
- `decision-boundary.md` — decision and stop rules;
- `skills/` — operational task procedures.

## Prohibited authority assumptions

Do not treat generated summaries, archived Version 2 documents, illustrative examples, uncontrolled fixtures, unapproved regulatory interpretations, customer-specific evidence or conflicting code comments as authority.

Keep outputs explicit, traceable, minimally scoped and consistent with the Effective Solution Architecture and applicable phase contract.
