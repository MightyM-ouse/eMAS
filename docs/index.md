# eMAS Documentation Index

This page is the repository navigation entry point. Use the [Canonical Document Index](CANONICAL_DOCUMENT_INDEX.md) when authority rank, status, ownership, supersession or LLM context routing matters.

## Governance and routing

| Area | Primary document | Status |
|---|---|---|
| Approved decisions | [Approved Decision Baseline v1.0](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | Approved and consolidated |
| Permanent decisions | [eMAS Decision Log](governance/eMAS_Decision_Log.md) | Effective |
| Authority and precedence | [Authority and Precedence Policy](governance/00_authority_and_precedence.md) | Effective |
| Document governance | [Document Governance and Change Control](governance/eMAS_Document_Governance.md) | Effective |
| Terminology | [Controlled Terminology](governance/eMAS_Terminology.md) | Effective |
| Canonical index | [Canonical Document Index](CANONICAL_DOCUMENT_INDEX.md) | Effective |
| LLM routing | [LLM Context Index](llm-development-context/context-index.yaml) | Effective |
| Superseded documents | [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) | Effective governance record |

## Current effective baseline

| Area | Primary document | Status |
|---|---|---|
| Enterprise requirements | [eMAS Enterprise Requirements v3.1](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | Effective |
| Configuration routing | [Configuration Documentation](configuration/README.md) | Effective |
| Mapping functional requirements | [Mapping Configuration Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective |
| Mapping technical requirements | [Mapping Configuration Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective |
| Mapping content catalogue | [Mapping Configuration Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical-model baseline |
| Runtime JSON contract | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective |
| Normalized rule model | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved baseline |
| Relationship matrix | [Normalized Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective |
| Data dictionary | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective |
| Schema verification | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective |
| Runtime schema | [eMAS Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective |
| Fixture manifest | [Schema Fixture Manifest](../config/schema/examples/fixture-manifest.json) | 1.0.0 Effective verification baseline |
| Project flow | [eMAS Project Flow](architecture/eMAS_Project_Flow.md) | Synchronization pending |
| Repository architecture | [eMAS Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved structure baseline |
| Operational skills | [Operational LLM Skills](llm-development-context/skills/README.md) | Framework approved; implementation pending |

## Required reading order

1. Apply governance, decisions and Enterprise Requirements v3.1.
2. Use the Effective configuration requirements.
3. Apply the Runtime JSON Contract and Normalized Rule Model.
4. Apply the frozen Relationship Matrix and Data Dictionary.
5. Use Runtime JSON Schema 1.0.0 for exact serialization.
6. Use the Schema Validation and Fixture Contract, manifest and independent validator for verification.
7. Review architecture and phase contracts for component behavior.
8. Use LLM context and skills only as subordinate implementation guidance.

## Source-of-truth rules

- Reviewed internal XLSM: authoring source of truth.
- Validated immutable exported JSON: runtime source of truth.
- Exact JSON version and checksum loaded for a run: execution source.
- PowerShell performs generic technical processing and phase orchestration, not business interpretation.
- Controlled report templates govern workbook presentation.

## Schema and verification baseline

Runtime JSON Schema 1.0.0 is synchronized with the frozen logical model. The verification suite includes:

- DEV and CONTROLLED valid fixtures;
- a valid lower-inclusive/upper-exclusive boundary fixture;
- structural and semantic invalid fixtures;
- a manifest containing expected validity and error codes;
- an independent Python validator and unit tests;
- a focused GitHub Actions workflow.

The Python dependency is build/CI-only. XLSM/VBA and PowerShell loader conformance remain separate implementation work.

## Documentation areas

- `docs/requirements/` — product and enterprise requirements.
- `docs/configuration/` — workbook, logical model, JSON and verification contracts.
- `docs/architecture/` — operating and component architecture.
- `docs/reporting/` — phase-specific workbook contracts.
- `docs/development/` — PowerShell, VBA, WPF and OpenXML standards.
- `docs/testing/` and `docs/validation/` — test strategy and evidence.
- `docs/operations/` — execution and administration.
- `docs/governance/` — authority, terminology, decisions and change control.
- `docs/archive/` — superseded material.

## Delivery state

Completed stages:

- governance baseline;
- requirements synchronization;
- logical-model freeze;
- Runtime JSON Schema 1.0.0 and independent fixture validation.

Pending stages include architecture/phase synchronization, operational skills, XLSM/VBA and PowerShell conformance, report generation, detailed SME content and full release controls.

Do not describe a later delivery stage as complete without evidence.

## Repository safety

Do not commit customer source data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions or confidential internal artifacts. Schema fixtures must remain synthetic.
