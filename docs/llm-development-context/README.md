# LLM Development Context for eMAS

**Version:** 2.2  
**Status:** Effective implementation guidance  
**Authority rank:** 7 — subordinate to approved requirements, governance, configuration contracts, schemas and architecture

This folder contains focused context and Effective operational procedures for disciplined LLM-assisted eMAS development.

## Mandatory authority path

Before implementation:

1. load task-specific sources from [context-index.yaml](context-index.yaml);
2. apply [Authority and Precedence](../governance/00_authority_and_precedence.md);
3. use the [Canonical Document Index](../CANONICAL_DOCUMENT_INDEX.md);
4. apply [Controlled Terminology](../governance/eMAS_Terminology.md);
5. read [Enterprise Requirements v3.1](../requirements/eMAS_Final_Enterprise_Requirements_v3.1.md);
6. apply Effective configuration and Runtime JSON Schema 1.0.0 contracts;
7. apply [Solution Architecture](../architecture/eMAS_Solution_Architecture.md) and the applicable phase contract;
8. select the narrowest applicable [operational skill](skills/README.md);
9. identify DecisionIds, acceptance criteria and delivery-state boundaries.

## Source boundaries

- reviewed internal XLSM = authoring source;
- validated immutable exported JSON = runtime source;
- exact JSON version/checksum loaded for a run = execution source.

PowerShell never reads the XLSM and never creates, repairs or reinterprets runtime JSON.

## Current implementation state

Governance, requirements, logical model, Schema 1.0.0, architecture, phase contracts and seven operational skills are Effective.

The repository now also contains a synthetic, reproducible XLSM/VBA proof-of-concept source and automated conformance harness. This demonstrates workbook-table structure, fixture behavior, deterministic reference export and Schema 1.0.0 compatibility. Native desktop Excel/VBA execution remains a separate manual qualification gate and must not be claimed without reviewed evidence.

PowerShell engine modules, WPF, controlled report templates and complete release controls remain separate implementation work.

## XLSM/VBA POC route

Use [xlsm-vba-poc-route.yaml](xlsm-vba-poc-route.yaml) for workbook, VBA, deterministic export, fixture or native Excel qualification tasks. It requires configuration/model and schema skills plus independent change review.

## Operational skill use

The machine-readable [skill catalogue](skills/skill-catalog.json) routes configuration, schema, PowerShell, regulatory, reporting, review and defect work. Skills define invocation boundaries, inputs, preconditions, ordered procedure, outputs, stop conditions, evidence and Definition of Done. They do not create requirements or approve regulatory content.

## Validation

```bash
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
python build/validate_xlsm_vba_poc.py
python -m unittest discover -s tests/vba -p "test_*.py" -v
```

Native qualification uses `build/Build-eMASMappingPoc.ps1` and `build/Test-eMASMappingPoc.ps1` on a supported Windows/Excel workstation.

## Prohibited authority assumptions

Do not treat generated summaries, archived Version 2 documents, illustrative examples, uncontrolled fixtures, unapproved regulatory interpretations, customer-specific evidence or conflicting code comments as authority.

Keep outputs explicit, traceable, minimally scoped and consistent with the Effective architecture, applicable phase contract and selected operational skill.
