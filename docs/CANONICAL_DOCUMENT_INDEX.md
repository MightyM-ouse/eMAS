# eMAS Canonical Document Index

**Version:** 1.0  
**Status:** Approved  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision reference:** DEC-2026-008 / AP-008

## Purpose

This index is the human-readable routing map for eMAS requirements, governance, architecture, configuration, development context and historical material.

Use it together with:

- [Authority and Precedence Policy](governance/00_authority_and_precedence.md);
- [Document Governance and Change Control](governance/eMAS_Document_Governance.md);
- [Controlled Terminology](governance/eMAS_Terminology.md);
- [machine-readable LLM context index](llm-development-context/context-index.yaml).

The authority rank below follows the approved precedence policy. A lower rank number is more authoritative.

## Active and approved sources

| ID | Authority rank | Artifact | Version / status | Owner | Role |
|---|---:|---|---|---|---|
| GOV-DEC | Amendment record | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 / Approved | Product Owner | Records approved amendments pending consolidation into the next v3.x baseline |
| REQ-ENT | 1 | [Final Enterprise Requirements](requirements/eMAS_Final_Enterprise_Requirements_v3.0.md) | v3.0 / Final baseline, amended by GOV-DEC | Product Owner | Product scope, phases, outcomes, boundaries and enterprise requirements |
| GOV-AUTH | Governance control | [Authority and Precedence Policy](governance/00_authority_and_precedence.md) | v1.0 / Effective | Product Owner | Determines authority, source-of-truth terminology and conflict handling |
| GOV-DOC | Governance control | [Document Governance and Change Control](governance/eMAS_Document_Governance.md) | v1.0 / Effective | Documentation Owner | Controls statuses, changes, approvals, examples, supersession and repository workflow |
| GOV-TERM | Governance control | [Controlled Terminology](governance/eMAS_Terminology.md) | v1.0 / Effective | Documentation Owner | Controls phase, result, evaluation, RAG, provenance and classification terms |
| GOV-LOG | Governance evidence | [Decision Log](governance/eMAS_Decision_Log.md) | v1.0 / Effective | Documentation Owner | Permanent repository record of approved decisions |
| CFG-FUNC | 2 | [Mapping Configuration Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v2.0 / Draft requiring approved-decision synchronization | Product Owner | Functional behavior of the internal authoring workbook |
| CFG-TECH | 3 | [Mapping Configuration Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v2.0 / Draft requiring approved-decision synchronization | Technical Architect | Technical constraints for XLSM, VBA, JSON export and validation |
| CFG-CAT | 4 | [Mapping Configuration Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v2.0 / Draft requiring approved-decision synchronization | Product Owner / SMEs | Controlled entities, fields, values and relationship catalogues |
| CFG-JSON | 3-5 | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.0 / Approved design baseline | Technical Architect | Human-readable runtime contract and compatibility policy |
| CFG-RULE | 2-5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.0 / Approved design baseline | Product Owner / Technical Architect | Normalized rule, lifecycle, condition, output, finding and exception model |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 / Initial approved schema baseline | Technical Architect | Machine-readable JSON structure; fixtures and independent validation remain pending |
| ARCH-FLOW | 6 | [Project Flow](architecture/eMAS_Project_Flow.md) | v1.0 / Final design baseline; synchronization pending | Technical Architect | Phase and evidence flow |
| ARCH-REPO | 6 | [Repository Architecture](architecture/eMAS_Repository_Architecture.md) | Approved structure baseline | Technical Architect | Repository, package and evidence boundaries |
| REPO-STRUCT | 6 | [Repository Structure](repository/eMAS_Repository_Structure.md) | Approved structure baseline | Technical Architect | Folder and asset ownership |

## Implementation guidance

These sources are subordinate to approved requirements, governance and architecture.

| ID | Authority rank | Artifact | Status | Use |
|---|---:|---|---|---|
| CTX-INDEX | 7 | [LLM Development Context](llm-development-context/README.md) | Guidance | Entry point for focused LLM context |
| CTX-MACHINE | 7 | [Machine-readable Context Index](llm-development-context/context-index.yaml) | Effective routing metadata | Select required, optional and prohibited context by task |
| CTX-RULES | 7 | [LLM Development Rules](llm-development-context/llm-development-rules.md) | Mandatory guidance | Hard development constraints and stop conditions |
| CTX-DECISION | 7 | [LLM Decision Boundary](llm-development-context/decision-boundary.md) | Mandatory guidance | Distinguishes approved decisions, pending implementation and new unresolved conflicts |
| SKILLS | 8 | [Operational LLM Skills](llm-development-context/skills/README.md) | Approved framework; implementation pending | Task-specific procedures, inputs, outputs, stop conditions and Definition of Done |

## Generated, illustrative and historical artifacts

| ID | Classification | Artifact | Authority |
|---|---|---|---|
| GEN-AI-001 | Generated / Non-authoritative | [AI-assistant eMAS overview](ai-assistant/emas-gxp-migration-assessment/overview.md) | Derived summary only; canonical sources prevail |
| HIST-V2 | Superseded / Archived externally | [Version 2 documentation pack notice](archive/v2-documentation-pack/README.md) | Historical comparison only |
| HIST-REGISTER | Governance record | [Superseded Document Register](archive/SUPERSEDED_DOCUMENT_REGISTER.md) | Identifies successors and restrictions |
| EXAMPLES | Illustrative by default | Examples in requirements, content catalogue and documentation | Never override canonical prose or schema |
| FIXTURES | Golden Fixture only after approval | Versioned test fixtures | Test authority only for identified test IDs and schema version |

## Required reading by task

### Requirements or document synchronization

1. GOV-AUTH
2. GOV-DOC
3. GOV-TERM
4. GOV-DEC and GOV-LOG
5. REQ-ENT
6. affected configuration or architecture documents

### Mapping workbook, rule or regulatory content

1. GOV-AUTH and GOV-TERM
2. REQ-ENT
3. CFG-FUNC, CFG-TECH and CFG-CAT
4. CFG-RULE
5. CFG-JSON and SCHEMA-JSON where export is affected
6. Regulatory SME evidence where required

### Runtime JSON or schema

1. GOV-AUTH and GOV-TERM
2. REQ-ENT
3. CFG-TECH
4. CFG-JSON
5. CFG-RULE
6. SCHEMA-JSON

### PowerShell engine or phase implementation

1. GOV-AUTH, GOV-TERM and CTX-RULES
2. REQ-ENT
3. CFG-JSON, CFG-RULE and SCHEMA-JSON
4. affected architecture and phase contract
5. applicable operational skill and tests

### Testing and release

1. GOV-DOC and change-authority matrix
2. governing requirement and DecisionIds
3. schema, configuration and implementation artifacts under test
4. approved fixtures and expected results
5. release evidence and rollback controls

## Prohibited authority assumptions

Do not use the following as authority unless explicitly promoted and indexed:

- archived Version 2 Word documents or Confluence exports;
- generated assistant profiles;
- AI recommendations not recorded as approved decisions;
- sample workbooks or reports;
- code comments that conflict with requirements;
- the newest file merely because it has a later timestamp;
- customer-specific project evidence as a general product requirement.

## Maintenance rule

Update this index whenever an artifact is:

- approved or made effective;
- renamed or moved;
- superseded or archived;
- assigned a new owner;
- given a new version or authority role;
- added to or removed from an LLM skill's required context.
