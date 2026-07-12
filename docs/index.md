# eMAS Documentation Index

This page is the navigation entry point for the eMAS repository documentation.

## Current baseline

| Area | Primary document | Status |
|---|---|---|
| Enterprise requirements | [eMAS Final Enterprise Requirements v3.0](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) | Final requirements baseline |
| Project flow | [eMAS Project Flow](architecture/eMAS_Project_Flow.md) | Final design baseline |
| Repository architecture | [eMAS Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved structure baseline |
| Repository structure | [eMAS Repository Structure](repository/eMAS_Repository_Structure.md) | Approved structure baseline |
| Mapping functional requirements | [Mapping Configuration Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | Draft for review |
| Mapping technical requirements | [Mapping Configuration Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | Draft for review |
| Mapping content catalogue | [Mapping Configuration Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | Draft for review |
| LLM development context | [LLM Development Context](llm-development-context/README.md) | Development guidance |

## Recommended reading order

1. Read the [enterprise requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) for the approved scope and constraints.
2. Review the [project flow](architecture/eMAS_Project_Flow.md) for the end-to-end operating model.
3. Review the [repository architecture](architecture/eMAS_Repository_Architecture.md) to understand how source components map to runtime and release packages.
4. Use the [repository structure](repository/eMAS_Repository_Structure.md) when creating or reorganizing a local clone.
5. Use the three mapping documents when designing or implementing the XLSM workbook and runtime JSON contract.
6. Use the LLM development context only as focused implementation guidance; the enterprise requirements remain authoritative.

## Documentation areas

### Requirements

`docs/requirements/` contains approved product, business, functional, technical and non-functional requirements.

### Architecture

`docs/architecture/` contains operating-flow, system, component, repository and data-flow diagrams. Architecture decision records should be stored under `docs/architecture/decisions/`.

### Configuration

`docs/configuration/` contains the mapping workbook, normalized rule model, VBA, validation and runtime JSON requirements.

### Repository

`docs/repository/` defines the canonical GitHub and local-folder layout, source-control boundaries, release-package boundaries and folder ownership.

### Reporting

`docs/reporting/` is reserved for phase-specific workbook structures, sheet contracts, column definitions and controlled wording.

### Development

`docs/development/` is reserved for PowerShell, VBA, WPF, OpenXML and coding standards.

### Testing and validation

`docs/testing/` contains the test strategy, scenario catalogue and regression coverage. `docs/validation/` contains traceability and controlled release-acceptance documentation.

### Operations

`docs/operations/` contains execution, administration, troubleshooting, customer instructions and evidence-retention guidance.

### Governance

`docs/governance/` contains decision registers, open questions, traceability records and change-history support.

### Releases

`docs/releases/` contains release-facing documentation, including release notes and known limitations. Generated packages are not stored here.

## Source-of-truth rules

- The enterprise requirements baseline controls product scope and architecture decisions.
- The internal mapping workbook controls business and regulatory rule authoring.
- The reviewed runtime JSON exported directly from Excel controls runtime interpretation.
- PowerShell controls generic technical processing and phase-specific orchestration.
- Controlled report templates control workbook presentation and sheet structure.
- The repository structure document controls placement of source and documentation assets.

## Repository safety

Do not commit customer source data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions or other confidential project content.
