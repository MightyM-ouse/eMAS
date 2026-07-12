---
# AI Assistant & Tooling Documentation for eMAS

This folder contains reference documentation designed to help developers, consultants, and AI tool builders work with or extend the eMAS (eCTD Migration Assessment Script) framework.

## Purpose

eMAS is a professional-grade, mapping-driven, GxP-oriented migration assessment framework. These documents capture its architecture, design decisions, compliance approach, and reusable patterns so that:

- AI assistants and custom tools can be built with accurate understanding of eMAS.
- Similar regulated migration assessment tools can reuse proven patterns.
- Teams can quickly onboard and extend the framework with automation or intelligence layers.

## Contents

- **overview.md** — High-level purpose, positioning, key features, and limitations of eMAS.
- **architecture-and-phases.md** — Detailed data flow, the three assessment phases (Pre-Sales, Pre-Migration, Post-Migration), shared PowerShell engine, and design rationale.
- **gxp-alcoa-requirements.md** — GxP orientation, ALCOA+ data integrity support, evidence handling, non-functional requirements, and what eMAS deliberately does *not* do.
- **design-patterns.md** — Reusable architectural and process patterns extracted from eMAS that are valuable for similar regulated-domain tools.

## Recommended Use

- When building AI agents, prompt libraries, or automation around eMAS.
- When designing extensions (e.g., AI-assisted rule authoring, intelligent report analysis, discrepancy detection).
- As onboarding material for anyone working on eMAS-related projects or similar GxP migration tooling.

These documents are derived from the official eMAS design baseline and are intended to complement (not replace) the existing `architecture/`, `requirements/`, and `configuration/` documentation.

---

**Maintained as part of the eMAS project** — contributions and improvements welcome.