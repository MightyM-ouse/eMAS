# LLM Development Context for eMAS

This folder contains focused, high-signal context for LLMs when developing or extending eMAS.

## Purpose
Help LLMs act as disciplined senior engineers who produce consistent, production-ready output aligned with eMAS architecture, GxP requirements, and eCTD regulatory realities.

## How to Use
- Include relevant files (or sections) in system prompts or RAG context.
- Use `llm-development-rules.md` as hard constraints.
- Use `ectd-regulatory-expert.md` when working on mapping, classification rules, or regional configuration.

## Files
- `core-design.md` — Fundamental architecture and design decisions
- `phases.md` — The three assessment phases with clear rules
- `configuration-rules.md` — Excel mapping workbook and JSON export
- `engine-patterns.md` — Shared PowerShell engine and evidence standards
- `ectd-regulatory-expert.md` — eCTD regulatory knowledge (regions, authorities, formats, relationships)
- `llm-development-rules.md` — Strict rules LLMs must follow for production quality

Keep responses concise, rule-based, and consistent with existing patterns.