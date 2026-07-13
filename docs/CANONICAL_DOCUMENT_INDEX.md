# eMAS Canonical Document Index

**Version:** 1.7  
**Status:** Effective  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision reference:** DEC-2026-008 / AP-008; requirements, logical-model, schema, architecture, skills, XLSM/VBA POC, runtime-profile and EvaluationStatus synchronization

## Purpose

This index routes eMAS work to authoritative requirements, approved amendments, architecture, verification contracts and implementation evidence. Lower numeric authority rank is more authoritative. Operational skills and implementation artifacts remain subordinate.

## Governance and requirements

| ID | Rank/role | Artifact | Version/status | Owner |
|---|---|---|---|---|
| REQ-ENT | 1 | [Enterprise Requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | v3.1 Effective; amended pending consolidation | Product Owner |
| GOV-DEC | Amendment/traceability | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 Approved | Product Owner |
| GOV-AMEND-RUNTIME | Approved amendment | [Runtime Profile and Warning Amendment](governance/decisions/DEC-2026-07-13_Runtime_Profile_and_Warning.md) | Effective; synchronized implementation pending | Product Owner / Technical Architect |
| GOV-AUTH | Governance | [Authority and Precedence](governance/00_authority_and_precedence.md) | v1.0 Effective | Product Owner |
| GOV-DOC | Governance | [Document Governance](governance/eMAS_Document_Governance.md) | v1.0 Effective | Documentation Owner |
| GOV-TERM | Governance | [Controlled Terminology](governance/eMAS_Terminology.md) | Effective with `Warning` and runtime profile | Documentation Owner |

## Configuration and runtime

| ID | Rank | Artifact | Version/status | Owner |
|---|---:|---|---|---|
| CFG-FUNC | 2 | [Mapping Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective; `Warning` amendment synchronized for schema/runtime scope | Product Owner |
| CFG-TECH | 3 | [Mapping Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective; `Warning` amendment synchronized for schema/runtime scope | Technical Architect |
| CFG-CAT | 4 | [Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical model; `Warning` amendment synchronized for schema/runtime scope | Product Owner / SMEs |
| CFG-JSON | 3–5 | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective with in-place Schema 1.0.0 `Warning` compatibility amendment | Technical Architect |
| CFG-RULE | 2–5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved; `Warning` amendment synchronized for schema/runtime scope | Product Owner / Technical Architect |
| CFG-REL | 4 | [Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective | Product Owner / Technical Architect |
| CFG-DICT | 4 | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective; `Warning` semantic-code amendment synchronized for schema/runtime scope | Product Owner / Technical Architect |
| CFG-VERIFY | 5 | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective; `Warning` fixtures and semantic checks added for schema/runtime scope | Technical Architect / QA Lead |
| CFG-XLSM-POC | 5–8 | [XLSM/VBA POC and Conformance Contract](configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md) | v1.0 Effective POC verification contract | Technical Architect / QA Lead |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective with approved in-place `Warning` compatibility update | Technical Architect |
| SCHEMA-FIX | 5 | [Runtime Fixture Manifest](../config/schema/examples/fixture-manifest.json) | 1.0.0 Effective with valid, boundary and invalid `Warning` fixtures | Technical Architect / QA Lead |

## Architecture and phase contracts

| ID | Rank | Artifact | Version/status |
|---|---:|---|---|
| ARCH-SOL | 6 | [Solution Architecture](architecture/eMAS_Solution_Architecture.md) | v1.0 Effective; runtime amendment applies |
| ARCH-RUNTIME | 6 | [PowerShell Runtime Profile](architecture/eMAS_PowerShell_Runtime_Profile.md) | v1.0 Effective amendment |
| ARCH-FLOW | 6 | [Project Flow](architecture/eMAS_Project_Flow.md) | v2.0 Effective |
| ARCH-REPO | 6 | [Repository Architecture](architecture/eMAS_Repository_Architecture.md) | v1.1 Effective |
| PHASE-PS | 6 | [Pre-Sales Phase Contract](architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md) | v1.1 Effective; Windows PowerShell 5.1 |
| PHASE-PM | 6 | [Pre-Migration Phase Contract](architecture/phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md) | v1.1 Effective; PowerShell 7.6 LTS on Windows |
| PHASE-PO | 6 | [Post-Migration Phase Contract](architecture/phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md) | v1.1 Effective; PowerShell 7.6 LTS on Windows |

## Operational skills

| ID | Rank | Artifact | Status |
|---|---:|---|---|
| SKILL-CAT | 8 | [Operational Skill Catalogue](llm-development-context/skills/README.md) | v1.0.0 Effective |
| SKILL-CONFIG | 8 | [Modify Configuration Model](llm-development-context/skills/modify-configuration-model.md) | Effective |
| SKILL-SCHEMA | 8 | [Update Runtime JSON Schema](llm-development-context/skills/update-json-schema.md) | Effective |
| SKILL-REVIEW | 8 | [Review Repository Change](llm-development-context/skills/review-change.md) | Effective |
| POC-ROUTE | 7–8 | [XLSM/VBA POC Route](llm-development-context/xlsm-vba-poc-route.yaml) | Effective route |

## Implementation and verification evidence

| ID | Artifact | Status/role |
|---|---|---|
| WP-RUNTIME-WARNING | [Runtime/Warning/Template Work Package](implementation/WORK_PACKAGE_Runtime_Profile_Warning_and_Template_Corrections.md) | Approved implementation route |
| POC-SOURCE | [Synthetic workbook source](../config/authoring/poc/README.md) | Implemented source-controlled POC |
| POC-VBA | [Reviewable VBA source](../config/vba/README.md) | Nine POC modules; native qualification pending |
| BUILD-POC | `build/generate_emas_mapping_poc_workbook.py`, `build/validate_xlsm_vba_poc.py` | Deterministic build/CI verification |
| BUILD-XLSM | `build/Build-eMASMappingPoc.ps1` | Internal Windows/Excel XLSM build |
| TEST-XLSM-NATIVE | `build/Test-eMASMappingPoc.ps1` | Manual native qualification gate |
| TEST-POC | `tests/vba/test_xlsm_vba_poc.py` | Automated POC regression evidence |
| CI-POC | `.github/workflows/xlsm-vba-poc-validation.yml` | Automated Linux source/schema conformance |
| BUILD-SCHEMA | `build/validate_emas_schema.py` | Independent Runtime JSON validation |
| ENGINE-RUNTIME | [Runtime engine contract boundary](../engine/README.md) (`engine/core`, `engine/powershell51`, `engine/powershell7`) | Initial runtime boundary and configuration-loader/runtime-adapter contract source; functional loader pending |
| CI-RUNTIME | `.github/workflows/powershell-runtime-contracts.yml` | Initial Windows PowerShell 5.1, Windows PowerShell 7.6 and macOS PowerShell 7.6 development contract workflow |
| BUILD-SKILLS | `build/validate_operational_skills.py` | Operational-skill validation |

## Required reading by task

### XLSM/VBA POC or workbook export

1. GOV-AUTH, GOV-TERM, GOV-DEC, GOV-AMEND-RUNTIME and REQ-ENT.
2. CFG-FUNC, CFG-TECH, CFG-CAT, CFG-JSON, CFG-RULE, CFG-REL, CFG-DICT and CFG-VERIFY.
3. CFG-XLSM-POC and SCHEMA-JSON.
4. SKILL-CONFIG and SKILL-SCHEMA.
5. POC-ROUTE and implementation assets.
6. SKILL-REVIEW before merge.

### PowerShell or reporting

1. governance, requirements and GOV-AMEND-RUNTIME;
2. Solution Architecture, ARCH-RUNTIME and applicable phase contract;
3. Runtime Schema/fixture contract;
4. WP-RUNTIME-WARNING;
5. applicable implementation skill and change review.

## Delivery-state boundary

The runtime profile and `Warning` terminology are approved. Schema, fixtures, semantic validation and the initial configuration-loader/runtime-adapter contract boundary are synchronized for the schema/runtime scope. Template dropdown/report validation, functional PowerShell loader implementation and broader regression evidence must still be synchronized before controlled release. The repository POC source and automated conformance harness are implemented. Native supported-Excel execution, Office bitness/locale qualification, production signing and controlled workbook release remain pending.

## Historical and prohibited authority

Archived requirements, generated profiles, uncontrolled samples, unapproved AI output, customer-specific evidence and fixtures as regulatory authority are prohibited.

## Maintenance rule

Update this index whenever an artifact is approved, made Effective, superseded, renamed, moved, assigned a new owner/version or added to a task route.
