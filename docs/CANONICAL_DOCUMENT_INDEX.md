# eMAS Canonical Document Index

**Version:** 1.3  
**Status:** Effective  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision reference:** DEC-2026-008 / AP-008; approved requirements, logical-model and schema-verification synchronization

## Purpose

This index is the human-readable routing map for eMAS requirements, governance, configuration, architecture, implementation guidance and historical material.

Use it with the Authority and Precedence Policy, Document Governance, Controlled Terminology and the machine-readable LLM context index.

A lower authority-rank number is more authoritative. Governance controls and approved amendments apply according to their defined role.

## Active and effective sources

| ID | Authority rank | Artifact | Version / status | Owner | Role |
|---|---:|---|---|---|---|
| REQ-ENT | 1 | [Enterprise Requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | v3.1 Effective | Product Owner | Product scope, phases, outcomes and boundaries |
| GOV-DEC | Amendment / traceability | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 Approved | Product Owner | Approved decisions and delivery sequence |
| GOV-AUTH | Governance | [Authority and Precedence Policy](governance/00_authority_and_precedence.md) | v1.0 Effective | Product Owner | Authority, source-of-truth and conflict rules |
| GOV-DOC | Governance | [Document Governance](governance/eMAS_Document_Governance.md) | v1.0 Effective | Documentation Owner | Status, approval, change and supersession control |
| GOV-TERM | Governance | [Controlled Terminology](governance/eMAS_Terminology.md) | v1.0 Effective | Documentation Owner | Controlled phase, status, RAG, provenance and taxonomy terms |
| GOV-LOG | Governance evidence | [Decision Log](governance/eMAS_Decision_Log.md) | v1.0 Effective | Documentation Owner | Permanent decision record |
| CFG-FUNC | 2 | [Mapping Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective | Product Owner | Workbook functional behavior |
| CFG-TECH | 3 | [Mapping Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective | Technical Architect | XLSM, VBA, export and compatibility constraints |
| CFG-CAT | 4 | [Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical model | Product Owner / SMEs | Entities, values and content boundaries |
| CFG-JSON | 3-5 | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective | Technical Architect | Runtime structure, serialization and validation |
| CFG-RULE | 2-5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved | Product Owner / Technical Architect | Rule, lifecycle, phase, condition, output and exception behavior |
| CFG-REL | 4 | [Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective | Product Owner / Technical Architect | Frozen relationships, cardinalities and integrity rules |
| CFG-DICT | 4 | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective | Product Owner / Technical Architect | Frozen fields, keys, types and requiredness |
| CFG-VERIFY | 5 | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective | Technical Architect / QA Lead | Fixture classes, expected results and semantic error codes |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective | Technical Architect | Machine-readable runtime structure |
| SCHEMA-FIX | 5 | [Fixture Manifest](../config/schema/examples/fixture-manifest.json) | 1.0.0 Effective verification baseline | Technical Architect / QA Lead | Expected validity and error-code contract |
| ARCH-FLOW | 6 | [Project Flow](architecture/eMAS_Project_Flow.md) | v1.0 Synchronization pending | Technical Architect | Phase and evidence flow |
| ARCH-REPO | 6 | [Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved | Technical Architect | Repository and package boundaries |
| REPO-STRUCT | 6 | [Repository Structure](repository/eMAS_Repository_Structure.md) | Approved | Technical Architect | Folder and asset ownership |

## Implementation and verification assets

| ID | Authority rank | Artifact | Status | Use |
|---|---:|---|---|---|
| BUILD-SCHEMA | Implementation evidence | `build/validate_emas_schema.py` | Effective independent validator | Draft 2020-12 and semantic validation |
| TEST-SCHEMA | Verification evidence | `tests/schema/test_schema_fixtures.py` | Effective automated test | Manifest, encoding and version verification |
| CI-SCHEMA | Verification control | `.github/workflows/schema-validation.yml` | Effective workflow | Pull-request and main schema validation |
| CTX-INDEX | 7 | [LLM Development Context](llm-development-context/README.md) | Guidance | Focused LLM context entry point |
| CTX-MACHINE | 7 | [Machine-readable Context Index](llm-development-context/context-index.yaml) | Effective routing metadata | Task-specific context selection |
| CTX-RULES | 7 | [LLM Development Rules](llm-development-context/llm-development-rules.md) | Mandatory guidance | Development constraints and stop rules |
| CTX-DECISION | 7 | [LLM Decision Boundary](llm-development-context/decision-boundary.md) | Mandatory guidance | Approved versus pending state |
| SKILLS | 8 | [Operational LLM Skills](llm-development-context/skills/README.md) | Framework approved; implementation pending | Task procedures and Definition of Done |

## Generated, illustrative and historical artifacts

| ID | Classification | Artifact | Authority |
|---|---|---|---|
| GEN-AI-001 | Generated / Non-authoritative | [AI-assistant overview](ai-assistant/emas-gxp-migration-assessment/overview.md) | Derived summary only |
| HIST-REQ30 | Superseded | [Enterprise Requirements v3.0](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) | Historical comparison only |
| HIST-V2 | Superseded / Archived externally | [Version 2 pack notice](archive/v2-documentation-pack/README.md) | Historical comparison only |
| HIST-REGISTER | Governance record | [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) | Successor and restriction record |
| EXAMPLES | Illustrative by default | Requirement and catalogue examples | Never override canonical sources |
| FIXTURES | Golden verification fixtures | `config/schema/examples/` entries listed by the manifest | Verification authority for Schema 1.0.0 only |

## Required reading by task

### Mapping workbook or regulatory content

1. GOV-AUTH, GOV-TERM and REQ-ENT
2. CFG-FUNC, CFG-TECH and CFG-CAT
3. CFG-RULE, CFG-REL and CFG-DICT
4. CFG-JSON and SCHEMA-JSON
5. applicable SME evidence

### Runtime JSON or schema

1. GOV-AUTH, GOV-TERM and REQ-ENT
2. CFG-TECH and CFG-JSON
3. CFG-RULE, CFG-REL and CFG-DICT
4. CFG-VERIFY
5. SCHEMA-JSON and SCHEMA-FIX
6. BUILD-SCHEMA and TEST-SCHEMA for implementation verification

### PowerShell engine or phase implementation

1. GOV-AUTH, GOV-TERM, CTX-RULES and REQ-ENT
2. CFG-JSON, CFG-RULE, CFG-REL and CFG-DICT
3. SCHEMA-JSON, CFG-VERIFY and applicable fixtures
4. affected architecture and phase contract
5. applicable operational skill and tests

### Testing and release

1. GOV-DOC and applicable DecisionIds
2. governing requirements and configuration contracts
3. CFG-VERIFY, SCHEMA-JSON and SCHEMA-FIX
4. implementation assets under test
5. release evidence and rollback controls

## Prohibited authority assumptions

Do not use the following as current authority unless explicitly promoted and indexed:

- Enterprise Requirements v3.0 or archived Version 2 documents;
- generated assistant profiles;
- unapproved AI recommendations;
- sample workbooks or reports;
- code comments that conflict with requirements;
- customer-specific project evidence;
- a fixture outside the manifest;
- a fixture as regulatory-content authority.

## Maintenance rule

Update this index whenever an artifact is approved, made Effective, superseded, renamed, moved, assigned a new owner/version or added to an LLM task route.
