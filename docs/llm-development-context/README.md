# LLM Development Context for eMAS

**Status:** Effective implementation guidance  
**Authority rank:** 7 — subordinate to approved requirements, governance, schemas and architecture

This folder contains focused, high-signal context for LLM-assisted eMAS development.

## Purpose

Help LLMs act as disciplined senior engineers who produce consistent, testable and traceable output aligned with the approved eMAS architecture, controlled terminology and regulated-environment evidence expectations.

## Mandatory authority rules

These files are implementation context, not an independent requirements baseline.

Before using this folder:

1. read the [machine-readable context index](context-index.yaml);
2. apply the [Authority and Precedence Policy](../governance/00_authority_and_precedence.md);
3. use the [Canonical Document Index](../CANONICAL_DOCUMENT_INDEX.md);
4. apply [Controlled Terminology](../governance/eMAS_Terminology.md);
5. identify applicable DecisionIds in the [Decision Log](../governance/eMAS_Decision_Log.md).

The approved source model is:

- reviewed internal XLSM = authoring source of truth;
- validated immutable exported JSON = runtime source of truth;
- exact JSON version and checksum loaded for a run = execution source.

PowerShell never reads the XLSM and never creates, repairs or reinterprets the runtime JSON.

## Decision and delivery boundary

The Product Owner approved the recommended decision for all 171 reviewed items on 13 July 2026.

An LLM must distinguish:

- approved decision;
- documentation synchronization;
- implementation completion;
- verification completion;
- release completion.

Approved design decisions may be implemented even when downstream work remains pending. New issues not covered by the decision baseline remain unresolved and require the stop process in [decision-boundary.md](decision-boundary.md).

## How to use

- Use `context-index.yaml` to select required and optional sources for the task.
- Include only relevant context instead of loading the entire repository.
- Use `llm-development-rules.md` as mandatory constraints.
- Use `decision-boundary.md` to distinguish approved decisions from pending delivery and new unresolved questions.
- Use `ectd-regulatory-expert.md` for classification and regulatory context, but do not promote new regulatory content without required SME evidence.
- Use an operational skill when one exists; every skill must define inputs, ordered procedure, outputs, stop conditions and Definition of Done.

## Files

- `context-index.yaml` — machine-readable authority and task-routing index
- `core-design.md` — fundamental architecture and source-of-truth design
- `phases.md` — approved phase names, scope and outcome terminology
- `configuration-rules.md` — internal XLSM authoring and JSON export rules
- `engine-patterns.md` — shared PowerShell engine and evidence patterns
- `ectd-regulatory-expert.md` — controlled regulatory classification context
- `llm-development-rules.md` — mandatory development constraints
- `decision-boundary.md` — decision, conflict and implementation-state stop rules
- `skills/` — operational skill framework and task procedures

## Prohibited authority assumptions

Do not treat any of the following as authority:

- generated AI-assistant summaries;
- archived Version 2 documentation;
- illustrative examples;
- unapproved new regulatory interpretations;
- customer-specific project evidence;
- code comments that conflict with approved requirements.

Keep outputs explicit, traceable, minimally scoped and consistent with approved repository patterns.
