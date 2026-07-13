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
- [XLSM/VBA POC and Conformance Contract v1.0](configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md)
- [Runtime JSON Schema 1.0.0](../config/schema/eMAS-runtime-config.schema.json)

## Effective architecture and skills

- [Architecture Index](architecture/README.md)
- [Solution Architecture v1.0](architecture/eMAS_Solution_Architecture.md)
- [Project Flow v2.0](architecture/eMAS_Project_Flow.md)
- [Repository Architecture v1.1](architecture/eMAS_Repository_Architecture.md)
- [Phase Contracts](architecture/phase-contracts/README.md)
- [Operational Skill Catalogue](llm-development-context/skills/README.md)
- [Machine-readable Skill Catalogue](llm-development-context/skills/skill-catalog.json)
- [XLSM/VBA POC task route](llm-development-context/xlsm-vba-poc-route.yaml)

## Implementation and verification

- [Synthetic XLSM/VBA POC source](../config/authoring/poc/README.md)
- [Reviewable VBA source](../config/vba/README.md)
- [Schema Package](../config/schema/README.md)
- [Build and Validation](../build/README.md)
- [Tests](../tests/README.md)
- [LLM Development Context](llm-development-context/README.md)

## Source-of-truth rules

- Reviewed internal XLSM = authoring source.
- Validated immutable exported JSON = runtime source.
- Exact JSON version/checksum loaded for a run = execution source.
- Shared PowerShell engine performs generic technical processing.
- Phase contracts control phase orchestration/result language.
- Controlled templates control workbook presentation.
- Operational skills control repeatable task procedure/evidence.

## Dependency-stage status

1. Governance baseline — completed.
2. Requirements synchronization — completed.
3. Logical-model freeze — completed.
4. Schema 1.0.0 and independent fixture validation — completed.
5. Solution architecture and phase contracts — completed.
6. Operational skills and catalogue validation — completed.
7. XLSM/VBA POC source and automated conformance harness — completed; native Windows/Excel execution and qualification evidence remain pending.

Next implementation work covers the PowerShell OpenXML/reporting spike, engine contracts and configuration-loader/phase conformance. Controlled production workbook signing, complete Excel/locale qualification, detailed SME content and full release/rollback controls remain pending.

## Repository safety

Customer data, project evidence, credentials, production logs/reports, confidential controlled binaries and project-specific accepted exceptions must not be committed. POC and test data must remain synthetic.
