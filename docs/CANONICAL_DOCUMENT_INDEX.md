# eMAS Canonical Document Index

**Version:** 1.5  
**Status:** Effective  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision reference:** DEC-2026-008 / AP-008; approved requirements, logical-model, schema-verification, architecture and operational-skill synchronization

## Purpose

This index routes eMAS work to the correct authoritative, architectural, verification and implementation sources. A lower authority-rank number is more authoritative; governance controls and approved amendments apply according to their defined role.

## Governance and requirements

| ID | Rank/role | Artifact | Version/status | Owner |
|---|---|---|---|---|
| REQ-ENT | 1 | [Enterprise Requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | v3.1 Effective | Product Owner |
| GOV-DEC | Amendment/traceability | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 Approved | Product Owner |
| GOV-AUTH | Governance | [Authority and Precedence](governance/00_authority_and_precedence.md) | v1.0 Effective | Product Owner |
| GOV-DOC | Governance | [Document Governance](governance/eMAS_Document_Governance.md) | v1.0 Effective | Documentation Owner |
| GOV-TERM | Governance | [Controlled Terminology](governance/eMAS_Terminology.md) | v1.0 Effective | Documentation Owner |
| GOV-LOG | Governance evidence | [Decision Log](governance/eMAS_Decision_Log.md) | v1.0 Effective | Documentation Owner |

## Configuration and runtime

| ID | Rank | Artifact | Version/status | Owner |
|---|---:|---|---|---|
| CFG-FUNC | 2 | [Mapping Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective | Product Owner |
| CFG-TECH | 3 | [Mapping Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective | Technical Architect |
| CFG-CAT | 4 | [Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical model | Product Owner / SMEs |
| CFG-JSON | 3–5 | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective | Technical Architect |
| CFG-RULE | 2–5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved | Product Owner / Technical Architect |
| CFG-REL | 4 | [Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective | Product Owner / Technical Architect |
| CFG-DICT | 4 | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective | Product Owner / Technical Architect |
| CFG-VERIFY | 5 | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective | Technical Architect / QA Lead |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective | Technical Architect |
| SCHEMA-FIX | 5 | [Fixture Manifest](../config/schema/examples/fixture-manifest.json) | 1.0.0 Effective verification baseline | Technical Architect / QA Lead |

## Architecture and phase contracts

| ID | Rank | Artifact | Version/status | Owner |
|---|---:|---|---|---|
| ARCH-SOL | 6 | [Solution Architecture](architecture/eMAS_Solution_Architecture.md) | v1.0 Effective | Technical Architect |
| ARCH-FLOW | 6 | [Project Flow](architecture/eMAS_Project_Flow.md) | v2.0 Effective | Technical Architect |
| ARCH-REPO | 6 | [Repository Architecture](architecture/eMAS_Repository_Architecture.md) | v1.1 Effective | Technical Architect |
| PHASE-PS | 6 | [Pre-Sales Phase Contract](architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md) | v1.0 Effective | Product Owner / Technical Architect |
| PHASE-PM | 6 | [Pre-Migration Phase Contract](architecture/phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md) | v1.0 Effective | Product Owner / Migration SME / Technical Architect |
| PHASE-PO | 6 | [Post-Migration Phase Contract](architecture/phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md) | v1.0 Effective | Product Owner / Migration SME / Technical Architect |
| REPO-STRUCT | 6 | [Repository Structure](repository/eMAS_Repository_Structure.md) | Approved | Technical Architect |

## Operational skill contracts

| ID | Rank | Artifact | Version/status | Owner |
|---|---:|---|---|---|
| SKILL-CAT | 8 | [Operational Skill Catalogue](llm-development-context/skills/README.md) | v1.0.0 Effective | Technical Architect |
| SKILL-MACHINE | 8 | [Machine-readable Skill Catalogue](llm-development-context/skills/skill-catalog.json) | v1.0.0 Effective | Technical Architect |
| SKILL-CONFIG | 8 | [Modify Configuration Model](llm-development-context/skills/modify-configuration-model.md) | v1.0.0 Effective | Product Owner / Technical Architect |
| SKILL-SCHEMA | 8 | [Update Runtime JSON Schema](llm-development-context/skills/update-json-schema.md) | v1.0.0 Effective | Technical Architect / QA Lead |
| SKILL-POWERSHELL | 8 | [Implement PowerShell Module](llm-development-context/skills/implement-powershell-module.md) | v1.0.0 Effective | PowerShell Lead / Technical Architect |
| SKILL-REGULATORY | 8 | [Add Regulatory Classification](llm-development-context/skills/add-regulatory-classification.md) | v1.0.0 Effective | Regulatory SME / Product Owner |
| SKILL-REPORT | 8 | [Modify Report Contract](llm-development-context/skills/modify-report-contract.md) | v1.0.0 Effective | Product Owner / Reporting Lead |
| SKILL-REVIEW | 8 | [Review Repository Change](llm-development-context/skills/review-change.md) | v1.0.0 Effective | Technical Architect / QA Lead |
| SKILL-DEFECT | 8 | [Investigate Defect](llm-development-context/skills/investigate-defect.md) | v1.0.0 Effective | Technical Lead / QA Lead |

Operational skills are subordinate procedures. They never override requirements, configuration contracts, schemas, architecture or phase contracts.

## Verification and implementation guidance

| ID | Role | Artifact | Status |
|---|---|---|---|
| BUILD-SCHEMA | Implementation verification | `build/validate_emas_schema.py` | Effective independent validator |
| TEST-SCHEMA | Verification evidence | `tests/schema/test_schema_fixtures.py` | Effective automated test |
| CI-SCHEMA | Verification control | `.github/workflows/schema-validation.yml` | Effective workflow |
| BUILD-SKILLS | Implementation verification | `build/validate_operational_skills.py` | Effective independent validator |
| TEST-SKILLS | Verification evidence | `tests/skills/test_operational_skills.py` | Effective automated test |
| CI-SKILLS | Verification control | `.github/workflows/operational-skills-validation.yml` | Effective workflow |
| CTX-INDEX | Guidance | [LLM Development Context](llm-development-context/README.md) | Subordinate guidance |
| CTX-MACHINE | Routing | [Machine-readable Context Index](llm-development-context/context-index.yaml) | Effective |
| CTX-RULES | Mandatory guidance | [LLM Development Rules](llm-development-context/llm-development-rules.md) | Effective |
| CTX-DECISION | Mandatory guidance | [LLM Decision Boundary](llm-development-context/decision-boundary.md) | Effective |

## Historical and non-authoritative material

| ID | Classification | Artifact | Restriction |
|---|---|---|---|
| GEN-AI-001 | Generated/non-authoritative | [AI-assistant overview](ai-assistant/emas-gxp-migration-assessment/overview.md) | Summary only |
| HIST-REQ30 | Superseded | [Enterprise Requirements v3.0](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) | Historical comparison only |
| HIST-V2 | Superseded | [Version 2 pack notice](archive/v2-documentation-pack/README.md) | Historical comparison only |
| HIST-REGISTER | Governance record | [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) | Successor/restriction record |
| FIXTURES | Verification authority only | `config/schema/examples/` entries listed by the manifest | Not regulatory-content authority |

## Required reading by task

### Configuration-model work

1. GOV-AUTH, GOV-TERM, GOV-DEC and REQ-ENT
2. CFG-CAT, CFG-RULE, CFG-REL, CFG-DICT and CFG-JSON
3. ARCH-SOL and applicable phase contract
4. SKILL-CONFIG
5. SKILL-REVIEW before merge

### JSON Schema work

1. governance and REQ-ENT
2. CFG-JSON, CFG-REL, CFG-DICT and CFG-VERIFY
3. SCHEMA-JSON and SCHEMA-FIX
4. SKILL-SCHEMA
5. BUILD-SCHEMA, TEST-SCHEMA and SKILL-REVIEW

### PowerShell or WPF

1. governance, REQ-ENT and CTX-RULES
2. CFG-JSON, CFG-RULE, CFG-REL, CFG-DICT, CFG-VERIFY and SCHEMA-JSON
3. ARCH-SOL and applicable phase contract
4. SKILL-POWERSHELL and SKILL-REVIEW
5. ARCH-REPO and relevant tests

### Regulatory content

1. governance and REQ-ENT
2. CFG-CAT, CFG-RULE, CFG-REL and CFG-DICT
3. applicable primary evidence and SME review
4. SKILL-REGULATORY and SKILL-REVIEW

### Reporting

1. governance, REQ-ENT and applicable phase contract
2. CFG-JSON, CFG-DICT and ARCH-SOL
3. SKILL-REPORT, then SKILL-POWERSHELL for implementation
4. SKILL-REVIEW before merge

### Defect investigation

1. governing requirement/architecture/phase/report contract
2. SKILL-DEFECT
3. root-cause-specific implementation skill
4. SKILL-REVIEW before merge

### Testing and release

1. GOV-DOC and applicable DecisionIds
2. governing requirement/configuration/architecture/skill contracts
3. CFG-VERIFY, SCHEMA-JSON and SCHEMA-FIX
4. implementation under test
5. release manifest, checksum and rollback evidence

## Prohibited authority assumptions

Do not use archived requirements, generated profiles, unapproved AI recommendations, uncontrolled samples, code comments, customer-specific evidence, fixtures outside the manifest or fixtures as regulatory authority.

## Maintenance rule

Update this index whenever an artifact is approved, made Effective, superseded, renamed, moved, assigned a new owner/version or added to a task route.
