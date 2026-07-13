# eMAS Documentation Index

Use the [Canonical Document Index](CANONICAL_DOCUMENT_INDEX.md) when authority rank, ownership, status or supersession matters.

## Governance

- [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md)
- [Authority and Precedence](governance/00_authority_and_precedence.md)
- [Document Governance](governance/eMAS_Document_Governance.md)
- [Controlled Terminology](governance/eMAS_Terminology.md)
- [Decision Log](governance/eMAS_Decision_Log.md)
- [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md)

## Effective product and configuration baseline

- [Enterprise Requirements v3.1](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md)
- [Configuration Documentation](configuration/README.md)
- [Runtime JSON Contract v1.2](configuration/04_eMAS_Runtime_JSON_Contract.md)
- [Normalized Rule Model v1.1](configuration/05_eMAS_Normalized_Rule_Model.md)
- [Normalized Relationship Matrix v1.0](configuration/06_eMAS_Normalized_Relationship_Matrix.md)
- [Logical Data Dictionary v1.0](configuration/07_eMAS_Data_Dictionary.md)
- [Schema Validation and Fixture Contract v1.0](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md)
- [Runtime JSON Schema 1.0.0](../config/schema/eMAS-runtime-config.schema.json)

## Effective architecture

- [Architecture Index](architecture/README.md)
- [Solution Architecture v1.0](architecture/eMAS_Solution_Architecture.md)
- [Project Flow v2.0](architecture/eMAS_Project_Flow.md)
- [Repository Architecture v1.1](architecture/eMAS_Repository_Architecture.md)
- [Phase Contracts](architecture/phase-contracts/README.md)
  - [Pre-Sales Assessment](architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md)
  - [Pre-Migration Readiness](architecture/phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md)
  - [Post-Migration Verification](architecture/phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md)

## Implementation and verification

- [Repository Structure](repository/eMAS_Repository_Structure.md)
- [Schema Package](../config/schema/README.md)
- [Build and Validation](../build/README.md)
- [Tests](../tests/README.md)
- [LLM Development Context](llm-development-context/README.md)
- [Operational Skills](llm-development-context/skills/README.md)

## Source-of-truth rules

- Reviewed internal XLSM = authoring source.
- Validated immutable exported JSON = runtime source.
- Exact JSON version/checksum loaded for a run = execution source.
- Shared PowerShell engine performs generic technical processing.
- Phase contracts control phase-specific orchestration and result language.
- Controlled templates control workbook presentation.

## Completed dependency stages

1. Governance baseline.
2. Requirements synchronization.
3. Logical-model freeze.
4. Schema 1.0.0 and independent fixture validation.
5. Solution architecture and phase contracts.

Pending stages include operational skills, XLSM/VBA implementation and fixture conformance, PowerShell/OpenXML implementation and loader conformance, controlled templates, detailed SME content and full release/rollback controls.

## Repository safety

Customer data, project evidence, credentials, production logs/reports, confidential controlled binaries and project-specific accepted exceptions must not be committed. Test fixtures must remain synthetic.
