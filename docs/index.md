# eMAS Documentation Index

This page is the repository navigation entry point. Use the [Canonical Document Index](CANONICAL_DOCUMENT_INDEX.md) when authority rank, status, ownership, supersession or LLM context routing matters.

## Governance and routing

| Area | Primary document | Status |
|---|---|---|
| Approved decisions | [Approved Decision Baseline v1.0](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | Approved; consolidated into effective requirements |
| Permanent decisions | [eMAS Decision Log](governance/eMAS_Decision_Log.md) | Effective |
| Authority and precedence | [Authority and Precedence Policy](governance/00_authority_and_precedence.md) | Effective |
| Document governance | [Document Governance and Change Control](governance/eMAS_Document_Governance.md) | Effective |
| Terminology | [Controlled Terminology](governance/eMAS_Terminology.md) | Effective |
| Human-readable canonical index | [Canonical Document Index](CANONICAL_DOCUMENT_INDEX.md) | Effective |
| Machine-readable LLM index | [LLM Context Index](llm-development-context/context-index.yaml) | Effective |
| Superseded documents | [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) | Effective governance record |

## Current effective baseline

| Area | Primary document | Status |
|---|---|---|
| Enterprise requirements | [eMAS Enterprise Requirements v3.1](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | Effective |
| Project flow | [eMAS Project Flow](architecture/eMAS_Project_Flow.md) | Approved-decision synchronization pending in a later dependency stage |
| Repository architecture | [eMAS Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved structure baseline |
| Repository structure | [eMAS Repository Structure](repository/eMAS_Repository_Structure.md) | Approved structure baseline |
| Configuration routing | [Configuration Documentation](configuration/README.md) | Effective routing record |
| Mapping functional requirements | [Mapping Configuration Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 / Effective |
| Mapping technical requirements | [Mapping Configuration Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 / Effective |
| Mapping content catalogue | [Mapping Configuration Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 / Effective logical-model baseline; detailed content still requires owner/SME evidence |
| Runtime JSON contract | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | Approved design baseline |
| Normalized rule model | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | Approved design baseline |
| Normalized relationship matrix | [Normalized Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 / Effective logical-model contract |
| Logical data dictionary | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 / Effective logical-model contract |
| Runtime schema | [eMAS Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | Initial approved schema baseline; fixture and semantic-validation synchronization is next |
| LLM development context | [LLM Development Context](llm-development-context/README.md) | Effective subordinate guidance |
| Operational skills | [Operational LLM Skills](llm-development-context/skills/README.md) | Approved framework; skill implementation pending |

## Required reading order

1. Read the [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) and [Decision Log](governance/eMAS_Decision_Log.md).
2. Apply the [Authority and Precedence Policy](governance/00_authority_and_precedence.md).
3. Use [Document Governance](governance/eMAS_Document_Governance.md) for statuses, approvals, examples, supersession and repository workflow.
4. Use [Enterprise Requirements v3.1](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) for product scope, boundaries and phase outcomes.
5. Use [Controlled Terminology](governance/eMAS_Terminology.md) for phase, status, RAG, provenance and classification terms.
6. Use the three Effective configuration requirements for mapping-workbook behavior, technical implementation and logical content.
7. Use the [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) and [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) for runtime and rule behavior.
8. Use the [Normalized Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) and [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) as the frozen structure and field contracts.
9. Use the [JSON Schema](../config/schema/eMAS-runtime-config.schema.json) for exact serialization; track and correct any remaining schema/model gap through controlled schema work.
10. Review architecture and repository structure for component placement and package boundaries.
11. Use LLM context and operational skills only as implementation guidance; they remain subordinate to canonical requirements.

## Source-of-truth rules

- The reviewed internal XLSM is the authoring source of truth for business and regulatory configuration.
- The validated immutable JSON exported from the approved XLSM is the runtime source of truth.
- The exact JSON version and checksum loaded for a run is the execution source.
- PowerShell controls generic technical processing and phase-specific orchestration, not business interpretation.
- Controlled report templates control workbook presentation and sheet structure.
- The repository structure document controls asset placement.

## Logical-model freeze

The following are now frozen at Version 1.0:

- entity inventory and stable keys;
- relationship types, endpoint pairs and cardinalities;
- dedicated phase/operator link entities;
- polymorphic-reference discriminators;
- field names, types and requiredness;
- effective-date and identifier rules;
- runtime JSON ownership by source entity.

Changes require DecisionId traceability, Product Owner and Technical Architect approval, applicable SME approval and schema compatibility analysis.

## Documentation areas

- `docs/requirements/` — product, business, functional, technical and non-functional requirements.
- `docs/architecture/` — operating flow, component, repository and data-flow architecture.
- `docs/configuration/` — mapping workbook, logical model, data dictionary, relationship matrix, runtime JSON and VBA requirements.
- `docs/reporting/` — phase-specific workbook contracts and controlled wording.
- `docs/development/` — PowerShell, VBA, WPF, OpenXML and coding standards.
- `docs/testing/` and `docs/validation/` — test strategy, traceability and release evidence.
- `docs/operations/` — execution, administration, troubleshooting and retention guidance.
- `docs/governance/` — authority, terminology, decisions, change control and review history.
- `docs/archive/` — superseded or historical documentation and registers.
- `docs/ai-assistant/` — generated, non-authoritative assistant profiles.

## Decision and delivery state

The 171 reviewed recommendations are approved and their requirements are consolidated. The normalized relationship matrix and data dictionary are now frozen. Associated work may still be:

- JSON Schema and fixture synchronization pending;
- Implementation Pending;
- SME Review Pending for detailed content;
- Test Pending;
- Release-Control Pending;
- Architecture or guidance synchronization pending;
- Supersession Pending.

Do not describe a design decision or logical-model contract as implemented, verified or released without evidence.

## Superseded requirements

Enterprise Requirements v3.0, configuration v2.0 revisions and the Version 2 Word documentation pack are historical only. Use the [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) for successors and restrictions.

## Repository safety

Do not commit customer source data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions or confidential internal artifacts. The public repository uses sanitized Markdown records for internal decisions and historical binary packs.
