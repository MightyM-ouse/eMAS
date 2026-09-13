# eMAS Decision Log

**Version:** 1.4
**Status:** Effective with approved MVP design amendments
**Effective date:** 2026-09-13
**Owner:** Documentation Owner

## Purpose

This is the permanent repository-native record of approved eMAS decisions. It records the approved outcome, not the full internal review workbook or confidential evidence.

- Decision IDs are stable and must not be reused.
- Changes to canonical requirements and design documents must cite the applicable DecisionId.
- Approval of a decision does not by itself mean the associated implementation, verification or release is complete.
- The detailed reviewed workbook remains controlled supporting evidence outside the public repository.

## Decision records

| DecisionId | Register item | Date | Status | Approved decision | Owner | Primary affected artifacts |
|---|---|---|---|---|---|---|
| DEC-2026-001 | AP-001 | 2026-07-13 | Effective | Adopt the approved authority hierarchy: Enterprise Requirements; configuration functional requirements; configuration technical requirements; content catalogue; JSON Schema; architecture/project flow; LLM context; operational skills; implementation code; examples and fixtures. Lower-authority sources must not override higher-authority approved sources. | Product Owner | Authority policy, canonical index, all controlled documents |
| DEC-2026-002 | AP-002 | 2026-07-13 | Effective | Use three distinct terms: reviewed internal XLSM is the authoring source of truth; validated immutable exported JSON is the runtime source of truth; the exact JSON version and checksum loaded for a run is the execution source. | Product Owner | Requirements, architecture, configuration, LLM context, reports and logs |
| DEC-2026-003 | AP-003 | 2026-07-13 | Effective | Use controlled document statuses Draft, InReview, Approved/Final, Effective, Superseded and Archived. Only Approved/Final or Effective documents may govern implementation. Keep rule lifecycle separate. | Documentation Owner | Document templates, metadata and canonical index |
| DEC-2026-004 | AP-004 | 2026-07-13 | Effective | Apply the higher-authority approved source when documents conflict; record a ConflictId; flag the lower-authority artifact for correction; stop work when regulatory interpretation, JSON compatibility, phase decisions, report meaning or evidence traceability is affected. | Technical Architect | Authority policy, skills, PR reviews and conflict records |
| DEC-2026-005 | AP-005 | 2026-07-13 | Effective | Label every example as Illustrative, Golden Fixture or Deprecated. Examples and samples never override canonical requirements or schemas. | Documentation Owner | Examples, fixtures, sample reports and content catalogue |
| DEC-2026-006 | AP-006 | 2026-07-13 | Effective | Adopt a change-authority matrix by change class, including regulatory, migration-estimation, JSON schema, engine, templates, XLSM/VBA, testing and documentation approvals. | Product Owner | Governance policy, CONTRIBUTING, PR template and release evidence |
| DEC-2026-007 | AP-007 | 2026-07-13 | Effective | Maintain a superseded-document register and archive notices. Do not delete historical documents until traceability confirms that no active requirement or reference is orphaned. External Version 2 Word and Confluence artifacts are included in the register even when binaries are not public. | Documentation Owner | Archive register, documentation index and historical pack notice |
| DEC-2026-008 | AP-008 | 2026-07-13 | Effective | Maintain a human-readable canonical document index and a machine-readable LLM context index containing path, version, status, authority rank, owner and supersession data. | Documentation Owner | `docs/CANONICAL_DOCUMENT_INDEX.md`, `context-index.yaml`, README |
| DEC-2026-009 | AP-009 | 2026-07-13 | Effective | Use this repository decision log as the primary permanent decision record. Confluence may mirror it but is non-authoritative for the repository. | Documentation Owner | Decision log, requirements and pull requests |
| DEC-2026-010 | AP-010 | 2026-07-13 | Effective | Maintain a controlled terminology catalogue as the authority for codes and display terms while retaining a business-facing glossary in enterprise requirements. | Documentation Owner | Terminology catalogue, requirements, JSON, reports and skills |
| DEC-2026-011 | AP-011 | 2026-07-13 | Effective | Classify the AI-assistant overview as a generated, non-authoritative profile derived from canonical sources, source-stamped and regenerated when those sources change. | Documentation Owner | AI-assistant overview and canonical index |
| DEC-2026-012 | AP-012 | 2026-07-13 | Effective | Use protected-main and pull-request governance, CODEOWNERS routing, required review by change class and DecisionId traceability. Repository settings and source-controlled governance files together implement the control. | Technical Architect | Repository settings, CONTRIBUTING, CODEOWNERS and PR template |
| DEC-2026-013 | MVP scenario/questionnaire review | 2026-09-13 | Approved MVP design | Adopt eight base migration scenarios `MS-01` through `MS-08`; model customer relationship, hosting, scope, evidence completeness, repository composition, eSUBmanager/DMS dependencies, other integrations and sequential upgrade as qualifiers rather than scenario identities; use a business-first reusable questionnaire; add explicit scenario-derivation rules; keep actual answers as project evidence; limit Pre-Sales DB/archive questions to availability and approximate scale; perform DB-record-to-archive-object verification only in Pre-Migration/Post-Migration; generate one scenario JSON containing all applicable phases. | Product Owner | Enterprise requirements, Mapping Workbook/JSON MVP requirements, indexes, questionnaire, scenario derivation and JSON examples |
| DEC-2026-014 | MVP scenario-derivation review | 2026-09-13 | Approved MVP design | Derive the base scenario from normalized primary migration input, intended target platform and required classifier fields; add business questions `Q-SCN-021` and `Q-SCN-022`; distinguish Derived, DerivedWithFollowUp, Pending and NeedsReview; do not treat partial eCTDmanager scope or missing evidence as Hybrid/Pending when the route is known; use Hybrid only for multiple migration inputs; retain hosting, eSUBmanager, DMS dependency and upgrades as qualifiers. `MS-08` supports third-party-system/DMS source migration into eCTDmanager only. DMS-to-DMS and unsupported target routes are outside MVP scope and must return `MS-07 / NeedsReview`, block `MS-08` JSON generation and require consultant discussion. | Product Owner | Enterprise requirements, Mapping Workbook/JSON MVP requirements, questionnaire, scenario derivation, JSON contract, validation and acceptance tests |
| DEC-2026-015 | MVP assessment-module applicability review | 2026-09-13 | Approved MVP design | Retain fifteen bounded assessment modules; define Migration Scenario Assessment as runtime confirmation rather than re-derivation; expand module metadata and boundaries; require one explicit mapping for every eight-scenario × three-phase × fifteen-module combination (360 rows); define Required, Conditional, Optional and NotApplicable semantics plus assessment depth, missing-evidence, baseline and reconciliation roles; add Hybrid composition question `Q-SCN-023`; serialize module mappings as traceable JSON objects. Require readiness for `MS-07` Pre-Migration to produce Blocked and prohibit formal reconciliation for unresolved `MS-07`. | Product Owner | Enterprise requirements, Mapping Workbook/JSON MVP requirements, module catalogue, questionnaire, scenario-module matrix, JSON contract, validation and acceptance tests |

## Consolidation evidence

DEC-2026-001 through DEC-2026-012 and the reviewed 171-item register were consolidated into the following earlier effective requirements:

- Enterprise Requirements v3.1;
- Mapping Configuration Functional Requirements v3.0;
- Mapping Configuration Technical Requirements v3.0;
- Mapping Configuration Content Catalogue v3.0.

For the `requirements/mvp-workbook-json` branch, DEC-2026-013 through DEC-2026-015 are consolidated into Enterprise Requirements v5.0 and Mapping Workbook and Scenario JSON MVP Requirements v4.3. These approvals close the base-scenario, questionnaire, scenario-derivation, assessment-module and scenario-module-map design reviews only. They do not complete workbook construction, JSON transformation, schema synchronization, PowerShell, templates, tests or release controls.

## Implementation-state rule

The decisions above are effective. Related work remains in its tracked state until completed and verified. Common states include:

- Implementation Pending;
- SME Review Pending;
- Test Pending;
- Release-Control Pending;
- Architecture or guidance synchronization pending;
- Supersession Pending.

A pull request must not describe an item as complete merely because its design decision is approved.

## Adding decisions

For each new decision:

1. allocate the next sequential DecisionId;
2. record the source Item ID or issue;
3. state the exact approved behavior;
4. record owner and approval date;
5. identify affected artifacts;
6. update the canonical index or terminology catalogue where applicable;
7. link implementation and verification work.
