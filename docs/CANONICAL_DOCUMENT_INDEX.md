# eMAS Canonical Document Index

**Version:** 1.8 MVP scenario alignment
**Status:** Approved MVP design baseline; implementation pending
**Prepared date:** 2026-09-13
**Owner:** Documentation Owner
**Decision reference:** DEC-2026-008 / AP-008 and DEC-2026-013; requirements, scenario model, questionnaire, logical-model, schema, architecture, skills and historical XLSM/VBA POC synchronization

## Purpose

This index routes eMAS work to authoritative requirements, architecture, verification contracts and implementation evidence. Lower numeric authority rank is more authoritative. Operational skills and implementation artifacts remain subordinate.

## Governance and requirements

| ID | Rank/role | Artifact | Version/status | Owner |
|---|---|---|---|---|
| REQ-ENT | 1 | [Enterprise Requirements](requirements/eMAS_Enterprise_Requirements_v5.0.md) | v5.0 Approved MVP-aligned branch baseline | Product Owner |
| GOV-DEC | Amendment/traceability | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 Approved | Product Owner |
| GOV-AUTH | Governance | [Authority and Precedence](governance/00_authority_and_precedence.md) | v1.0 Effective | Product Owner |
| GOV-DOC | Governance | [Document Governance](governance/eMAS_Document_Governance.md) | v1.0 Effective | Documentation Owner |
| GOV-TERM | Governance | [Controlled Terminology](governance/eMAS_Terminology.md) | v1.0 Effective | Documentation Owner |

## Configuration and runtime

| ID | Rank | Artifact | Version/status | Owner |
|---|---:|---|---|---|
| CFG-MVP | 2 | [Mapping Workbook and Scenario JSON MVP Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v4.1 Approved MVP design baseline; implementation pending | Product Owner |
| CFG-TECH | Reference | [Mapping Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 historical reference pending MVP reconciliation | Technical Architect |
| CFG-CAT | Reference | [Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 reference pending MVP reconciliation | Product Owner / SMEs |
| CFG-JSON | Reference | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 reference pending scenario-JSON synchronization | Technical Architect |
| CFG-RULE | 2–5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved | Product Owner / Technical Architect |
| CFG-REL | 4 | [Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective | Product Owner / Technical Architect |
| CFG-DICT | 4 | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective | Product Owner / Technical Architect |
| CFG-VERIFY | 5 | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective | Technical Architect / QA Lead |
| CFG-XLSM-POC | Historical | [XLSM/VBA POC and Conformance Contract](configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md) | Historical POC; not current MVP direction | Technical Architect / QA Lead |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective | Technical Architect |
| SCHEMA-FIX | 5 | [Runtime Fixture Manifest](../config/schema/examples/fixture-manifest.json) | 1.0.0 Effective | Technical Architect / QA Lead |

## Architecture and phase contracts

| ID | Rank | Artifact | Version/status |
|---|---:|---|---|
| ARCH-SOL | 6 | [Solution Architecture](architecture/eMAS_Solution_Architecture.md) | v1.0 Effective |
| ARCH-FLOW | 6 | [Project Flow](architecture/eMAS_Project_Flow.md) | v2.0 Effective |
| ARCH-REPO | 6 | [Repository Architecture](architecture/eMAS_Repository_Architecture.md) | v1.1 Effective |
| PHASE-PS | 6 | [Pre-Sales Phase Contract](architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md) | v1.0 Effective |
| PHASE-PM | 6 | [Pre-Migration Phase Contract](architecture/phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md) | v1.0 Effective |
| PHASE-PO | 6 | [Post-Migration Phase Contract](architecture/phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md) | v1.0 Effective |

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
| POC-SOURCE | [Synthetic workbook source](../config/authoring/poc/README.md) | Implemented source-controlled POC |
| POC-VBA | [Reviewable VBA source](../config/vba/README.md) | Nine POC modules; native qualification pending |
| BUILD-POC | `build/generate_emas_mapping_poc_workbook.py`, `build/validate_xlsm_vba_poc.py` | Deterministic build/CI verification |
| BUILD-XLSM | `build/Build-eMASMappingPoc.ps1` | Internal Windows/Excel XLSM build |
| TEST-XLSM-NATIVE | `build/Test-eMASMappingPoc.ps1` | Manual native qualification gate |
| TEST-POC | `tests/vba/test_xlsm_vba_poc.py` | Automated POC regression evidence |
| CI-POC | `.github/workflows/xlsm-vba-poc-validation.yml` | Automated Linux source/schema conformance |
| BUILD-SCHEMA | `build/validate_emas_schema.py` | Independent Runtime JSON validation |
| BUILD-SKILLS | `build/validate_operational_skills.py` | Operational-skill validation |

## Required reading by task

### MVP workbook and scenario JSON

1. REQ-ENT and CFG-MVP.
2. GOV-AUTH and GOV-TERM where they do not conflict with the explicit MVP deferral.
3. CFG-RULE, CFG-CAT, CFG-REL and CFG-DICT as design input pending reconciliation.
4. Define and review the scenario-specific JSON schema before transformer implementation.
5. Use CFG-VERIFY and the review skill before merge.

### PowerShell or reporting

1. governance, requirements and Effective configuration contracts;
2. Solution Architecture and applicable phase contract;
3. Runtime Schema/fixture contract;
4. applicable implementation skill and change review.

## Delivery-state boundary

The existing XLSM/VBA POC source and conformance harness remain historical implementation evidence. The workbook/JSON MVP defined in CFG-MVP is requirements work and shall not be described as implemented, verified, approved, or released until its acceptance tests pass.

## Historical and prohibited authority

Archived requirements, generated profiles, uncontrolled samples, unapproved AI output, customer-specific evidence and fixtures as regulatory authority are prohibited.

## Maintenance rule

Update this index whenever an artifact is approved, made Effective, superseded, renamed, moved, assigned a new owner/version or added to a task route.
