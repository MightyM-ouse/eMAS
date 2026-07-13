# eMAS Document Governance and Change Control

**Version:** 1.0  
**Status:** Approved  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision references:** AP-003, AP-005, AP-006, AP-007, AP-009, AP-011, AP-012

## 1. Purpose

This document defines the minimum control model for eMAS documentation, decisions, examples, generated assistant content, supersession, repository changes and approval evidence.

It complements the [Authority and Precedence Policy](00_authority_and_precedence.md). The precedence policy determines which source governs; this document determines how controlled sources are created, reviewed, approved, changed and retired.

## 2. Required document-control metadata

Every canonical requirement, architecture, configuration, reporting, development, testing or operations document must state:

- title and stable document identifier;
- version;
- document status;
- owner;
- effective date where applicable;
- decision references;
- canonical source references;
- supersedes and superseded-by references where applicable;
- revision history.

A document lacking required metadata may be used as working material but must not be treated as an approved implementation baseline.

## 3. Controlled document statuses

| Status | Meaning | May govern implementation? |
|---|---|---|
| Draft | Initial working content | No |
| InReview | Submitted for controlled review | No |
| Approved / Final | Approved design or requirement baseline | Yes |
| Effective | Approved and active from a stated date | Yes |
| Superseded | Replaced by an identified successor | No |
| Archived | Retained only for history or evidence | No |

A newer Draft or InReview document never overrides an older Approved, Final or Effective document.

Document status is separate from rule lifecycle. Rule lifecycle remains governed by the normalized rule model.

## 4. Change-authority matrix

| Change class | Minimum required approval |
|---|---|
| Product scope, phase outcomes or business requirements | Product Owner |
| Regulatory classification or controlled regulatory content | Regulatory SME and Product Owner |
| Effort, confidence, threshold or estimation logic | Migration SME and Product Owner |
| Runtime JSON Schema or compatibility policy | Technical Architect, PowerShell Lead and Product Owner |
| Shared PowerShell engine or phase orchestration | PowerShell Lead and technical reviewer |
| Mapping XLSM or VBA | Technical Architect; Corporate IT additionally approves signing and trust controls |
| Controlled report templates or result wording | Product Owner and QA Lead |
| Test strategy, fixtures or release evidence | QA Lead and responsible technical owner |
| Documentation-only clarification with no behavior change | Documentation Owner and responsible area owner |
| Repository governance or release controls | Technical Architect and repository owner |

GitHub review approval demonstrates repository review. Where a domain approval cannot be represented by a GitHub account, the pull request must record the approver role, approval evidence reference and DecisionId.

## 5. Controlled change workflow

1. Identify the governing requirement, DecisionId and affected artifacts.
2. Confirm the source status and authority rank through the canonical index.
3. Create a dedicated branch from the latest `main`.
4. Apply the smallest coherent change set.
5. Update dependent requirements, schemas, architecture, tests and guidance in the same pull request or create explicitly linked follow-up work.
6. Record conflicts instead of silently reconciling them.
7. Obtain approvals required by the change-authority matrix.
8. Verify links, terminology, status metadata and traceability before merge.
9. Merge only through a pull request.
10. Update the decision log, canonical index and superseded-document register when applicable.

## 6. Conflict record

A conflict that cannot be corrected immediately must be recorded with:

- `ConflictId`;
- date detected;
- conflicting artifacts and sections;
- authority rank and status of each artifact;
- affected runtime, report or regulatory behavior;
- interim governing source;
- owner;
- required resolution;
- linked DecisionId or issue;
- closure evidence.

Implementation must stop when the conflict affects regulatory interpretation, JSON compatibility, phase decision logic, report meaning or evidence traceability.

## 7. Examples, fixtures and sample outputs

Every example must carry one of these labels:

- **Illustrative** — explanatory only and never authoritative;
- **Golden Fixture** — approved, versioned and linked to test IDs;
- **Deprecated** — retained only for historical comparison.

Examples, generated reports and sample data never override canonical requirements, the JSON Schema or approved configuration.

## 8. Decision records

The primary permanent repository decision record is [eMAS Decision Log](eMAS_Decision_Log.md).

- Approved decisions receive stable IDs in the form `DEC-YYYY-NNN`.
- Requirement and design changes reference the applicable DecisionId.
- The internal reviewed workbook remains supporting evidence and is not the public canonical record.
- Confluence may mirror decisions, but the repository decision log is authoritative for this repository.

## 9. Supersession and archiving

Before a document is marked Superseded or Archived:

1. identify its successor;
2. verify that valid requirements have been migrated or explicitly rejected;
3. check that no active link or traceability record becomes orphaned;
4. add a supersession banner or archive notice;
5. update the canonical index and superseded-document register;
6. retain the historical artifact and checksum in approved internal storage when the binary cannot be published.

Historical documents must not be deleted solely to remove contradictions.

## 10. Generated and AI-assistant artifacts

Generated assistant profiles, summaries and retrieval aids are non-authoritative unless separately approved as canonical documents.

They must include:

- `Generated / Non-authoritative` status;
- source documents and versions;
- synchronization date;
- regeneration trigger;
- statement that canonical sources prevail.

LLM-generated regulatory content remains Draft until the required SME review is complete.

## 11. Repository controls

The approved repository workflow requires:

- protected `main` where supported by repository settings;
- no direct commits to `main`;
- pull-request review;
- CODEOWNERS routing;
- decision and requirement traceability in pull requests;
- synthetic or approved test data only;
- no customer data, credentials, production logs or project evidence in the public repository.

Repository settings are administered outside source control. `CONTRIBUTING.md`, `CODEOWNERS` and the pull-request template define the source-controlled workflow expectation.

## 12. Completion criteria

A governance change is complete only when:

- the decision is recorded;
- active documents no longer conflict;
- metadata and status are correct;
- dependent implementation is complete or separately tracked;
- required reviewers have approved;
- tests or verification evidence are recorded;
- obsolete artifacts are registered as superseded or archived;
- the canonical index is current.
