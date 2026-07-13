# eMAS Decision Log

**Version:** 1.0  
**Status:** Approved  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner

## Purpose

This is the permanent repository-native record of approved eMAS decisions. It records the approved outcome, not the full internal review workbook or confidential evidence.

- Decision IDs are stable and must not be reused.
- Changes to canonical requirements and design documents must cite the applicable DecisionId.
- Approval of a decision does not by itself mean the associated implementation or document synchronization is complete.
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

## Implementation-state rule

The decisions above are effective. Related work remains in its tracked state until completed and verified. Common states include:

- Documentation Sync Pending;
- Implementation Pending;
- SME Review Pending;
- Test Pending;
- Release-Control Pending;
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
