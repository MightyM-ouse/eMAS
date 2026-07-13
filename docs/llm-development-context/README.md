# LLM Development Context for eMAS

**Version:** 1.0  
**Status:** Approved guidance

This folder contains focused context and operational skills for developing eMAS consistently with the approved v3.1 baseline.

## Authority

Before acting, load:

1. [`00-authority-and-precedence.md`](00-authority-and-precedence.md);
2. [`context-index.yaml`](context-index.yaml);
3. the canonical sources required by the applicable operational skill.

LLM context and skills never override approved requirements, configuration specifications or the JSON Schema.

## Core context

- `00-authority-and-precedence.md`
- `core-design.md`
- `phases.md`
- `configuration-rules.md`
- `runtime-json-contract.md`
- `normalized-rule-model.md`
- `engine-patterns.md`
- `ectd-regulatory-expert.md`
- `llm-development-rules.md`
- `decision-boundary.md`

## Operational skills

See [`skills/README.md`](skills/README.md).

## Mandatory boundary

- AI proposals are not approvals.
- LLM-generated regulatory content remains Draft until normal SME approval.
- Do not hardcode business or regulatory interpretation in PowerShell.
- Stop for unresolved canonical conflicts or unsupported regulatory interpretation.
