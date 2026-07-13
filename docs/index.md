# eMAS Documentation Index

This page is the navigation entry point for the eMAS repository documentation.

## Current approved baseline

| Area | Primary document | Status |
|---|---|---|
| Enterprise requirements | [eMAS Final Enterprise Requirements v3.0](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) | Final baseline, amended by approved decisions pending consolidated v3.x revision |
| Approved decisions | [Approved Decision Baseline v1.0](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | Approved |
| Authority and precedence | [Authority and Precedence Policy](governance/00_authority_and_precedence.md) | Approved |
| Terminology | [Controlled Terminology](governance/eMAS_Terminology.md) | Approved |
| Project flow | [eMAS Project Flow](architecture/eMAS_Project_Flow.md) | Final design baseline; synchronization pending |
| Repository architecture | [eMAS Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved structure baseline |
| Repository structure | [eMAS Repository Structure](repository/eMAS_Repository_Structure.md) | Approved structure baseline |
| Mapping functional requirements | [Mapping Configuration Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | Draft requiring approved-decision synchronization |
| Mapping technical requirements | [Mapping Configuration Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | Draft requiring approved-decision synchronization |
| Mapping content catalogue | [Mapping Configuration Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | Draft requiring approved-decision synchronization |
| Runtime JSON contract | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | Approved design baseline |
| Normalized rule model | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | Approved design baseline |
| Runtime schema | [eMAS Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | Initial approved schema baseline; fixtures and validation pending |
| LLM development context | [LLM Development Context](llm-development-context/README.md) | Development guidance |
| Operational skills | [Operational LLM Skills](llm-development-context/skills/README.md) | Approved framework; skill implementation pending |

## Required reading order

1. Read the [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md).
2. Apply the [Authority and Precedence Policy](governance/00_authority_and_precedence.md).
3. Use the [Enterprise Requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) for product scope, subject to approved amendments.
4. Use [Controlled Terminology](governance/eMAS_Terminology.md) for phase, status, RAG, provenance and classification terms.
5. Use the [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) and [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) for configuration and schema work.
6. Review architecture and repository structure for component placement and package boundaries.
7. Use LLM context and operational skills only as implementation guidance; they remain subordinate to canonical requirements.

## Source-of-truth rules

- The reviewed internal XLSM is the authoring source of truth for business and regulatory configuration.
- The validated immutable JSON exported from the approved XLSM is the runtime source of truth.
- The exact JSON version and checksum loaded for a run is the execution source.
- PowerShell controls generic technical processing and phase-specific orchestration, not business interpretation.
- Controlled report templates control workbook presentation and sheet structure.
- The repository structure document controls asset placement.

## Documentation areas

- `docs/requirements/` — product, business, functional, technical and non-functional requirements.
- `docs/architecture/` — operating flow, component, repository and data-flow architecture.
- `docs/configuration/` — mapping workbook, normalized rule model, runtime JSON and VBA requirements.
- `docs/reporting/` — phase-specific workbook contracts and controlled wording.
- `docs/development/` — PowerShell, VBA, WPF, OpenXML and coding standards.
- `docs/testing/` and `docs/validation/` — test strategy, traceability and release evidence.
- `docs/operations/` — execution, administration, troubleshooting and retention guidance.
- `docs/governance/` — authority, terminology, decisions, open questions and change history.
- `docs/archive/` — superseded or historical documentation.

## Repository safety

Do not commit customer source data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions or confidential internal artifacts. The public repository uses sanitized Markdown records for internal decisions and superseded document packs.