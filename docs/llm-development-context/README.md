# LLM Development Context for eMAS

This folder contains focused, high-signal context for LLMs when developing or extending eMAS.

## Purpose

Help LLMs act as disciplined senior engineers who produce consistent, production-ready output aligned with eMAS architecture, GxP-oriented traceability expectations and eCTD regulatory realities.

## Authority and limitations

These files are implementation context, not an independent requirements baseline.

- Approved repository requirements and architecture control implementation.
- The internal mapping workbook is the controlled business and regulatory rule-authoring application.
- The reviewed JSON exported from the workbook controls runtime interpretation.
- AI recommendations and decision-register review columns are proposals until approved by the user or required SME.
- When context conflicts with an approved requirement, stop and report the conflict rather than silently resolving it.
- Use [decision-boundary.md](decision-boundary.md) whenever a task may depend on an unresolved decision.

The current review status and open-question process are documented under [docs/governance/decision-register](../governance/decision-register/README.md).

## How to use

- Include only the relevant files or sections in system prompts or retrieval context.
- Use `llm-development-rules.md` as hard constraints.
- Use `decision-boundary.md` to identify when work must stop for a decision.
- Use `ectd-regulatory-expert.md` when working on mapping, classification rules or regional configuration, but do not treat unapproved regulatory values as final mapping content.

## Files

- `core-design.md` — fundamental architecture and design decisions
- `phases.md` — the three assessment phases with clear rules
- `configuration-rules.md` — Excel mapping workbook and JSON export
- `engine-patterns.md` — shared PowerShell engine and evidence standards
- `ectd-regulatory-expert.md` — eCTD regulatory context for regions, authorities, formats and relationships
- `llm-development-rules.md` — mandatory development constraints
- `decision-boundary.md` — stop conditions and handling of unresolved decisions

Keep outputs concise, rule-based, traceable and consistent with approved repository patterns.
