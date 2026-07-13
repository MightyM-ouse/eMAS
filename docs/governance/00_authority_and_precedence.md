# eMAS Authority, Precedence and Source-of-Truth Policy

**Version:** 1.1  
**Status:** Effective  
**Effective date:** 2026-07-13  
**Owner:** Product Owner  
**Decision references:** DEC-2026-001 through DEC-2026-010; AP-001, AP-002, AP-003, AP-004, AP-005, AP-006, AP-010

## 1. Purpose

This policy defines which eMAS artifacts are authoritative, how approved amendments are applied, how conflicts are resolved, which statuses may govern development and how authoring, runtime and execution sources are distinguished.

Use this policy together with:

- [Document Governance and Change Control](eMAS_Document_Governance.md);
- [Controlled Terminology](eMAS_Terminology.md);
- [Decision Log](eMAS_Decision_Log.md);
- [Canonical Document Index](../CANONICAL_DOCUMENT_INDEX.md).

## 2. Authority hierarchy

Apply the following precedence from highest to lowest:

1. Approved Enterprise Requirements.
2. Approved configuration functional requirements.
3. Approved configuration technical requirements.
4. Approved configuration content catalogue.
5. Approved machine-readable JSON Schema.
6. Approved architecture and project-flow documents.
7. LLM development context.
8. Operational LLM skills.
9. Implementation code.
10. Examples, samples and fixtures.

A lower-authority artifact must not override a higher-authority approved artifact.

## 3. Approved amendments and temporary baselines

An approved decision may amend an existing canonical document before the next consolidated revision is published.

- The approved decision baseline and permanent decision log identify the amendment.
- The amendment applies only to the artifacts and behavior stated in the decision.
- It does not create a parallel general requirements hierarchy.
- The canonical document index must show that the affected document is amended or awaiting synchronization.
- The amendment must be incorporated into the next controlled revision of the affected canonical document.

Enterprise Requirements v3.0 therefore remains the primary product baseline, amended by the approved 171-item decision baseline until the next consolidated v3.x revision.

## 4. Source-of-truth terminology

- **Authoring source of truth:** the reviewed internal Excel XLSM mapping workbook used to maintain business and regulatory configuration.
- **Runtime source of truth:** the validated, immutable runtime JSON exported from the approved XLSM.
- **Execution source:** the exact runtime JSON version and checksum loaded for a specific execution.

PowerShell must not read the XLSM and must not create, repair or reinterpret the runtime JSON.

The runtime JSON is authoritative for execution only after successful schema, semantic and compatibility validation.

## 5. Document statuses

Controlled document statuses are:

- Draft;
- InReview;
- Approved or Final;
- Effective;
- Superseded;
- Archived.

Only Approved, Final or Effective documents may govern implementation. A newer Draft or InReview document does not automatically override an older Approved or Effective document.

Rule lifecycle uses a separate vocabulary and must not be merged with document status:

- Draft;
- InReview;
- Reviewed;
- Effective;
- Superseded;
- Retired.

## 6. Conflict handling

When two sources conflict:

1. apply the higher-authority approved source;
2. assign a `ConflictId` and record the affected artifacts;
3. mark the lower-authority artifact for correction or supersession;
4. do not silently merge incompatible statements;
5. stop implementation when the conflict affects:
   - regulatory interpretation;
   - JSON compatibility;
   - phase decision logic;
   - report meaning;
   - evidence traceability.

If the source status or authority cannot be determined, stop and consult the canonical index and responsible owner.

## 7. Examples and fixtures

Every example must be labelled as one of:

- **Illustrative** — explanatory only;
- **Golden Fixture** — approved, versioned and test-referenced;
- **Deprecated** — retained only for history.

Examples never override canonical requirements, schemas or approved configuration.

## 8. Change-authority matrix

| Change type | Owner / required approval |
|---|---|
| Product scope and phase outcomes | Product Owner |
| Regulatory content | Regulatory SME and Product Owner |
| Effort or confidence weights | Migration SME and Product Owner |
| JSON Schema | Technical Architect, Product Owner and PowerShell Lead |
| Shared engine code | PowerShell Lead and technical reviewer |
| Templates and report contracts | Product Owner and QA Lead |
| XLSM or VBA | Technical Architect; Corporate IT for signing and trust controls |
| Testing and release evidence | QA Lead and responsible technical owner |
| Documentation | Documentation Owner and responsible area owner |
| Repository governance | Technical Architect and repository owner |

Detailed change workflow and approval evidence requirements are defined in the document-governance policy.

## 9. Terminology governance

The business glossary remains readable for users, while controlled codes and display terms are governed through [eMAS Controlled Terminology](eMAS_Terminology.md) and approved configuration value lists.

When a display term and code differ, the terminology catalogue must define the relationship explicitly.

## 10. Generated and assistant artifacts

Generated summaries, AI-assistant profiles, search indexes and retrieval context are non-authoritative unless separately approved and indexed as canonical.

They must identify their sources and synchronization date. Canonical requirements always prevail.

## 11. LLM and automation rule

LLMs may summarize or operationalize approved requirements, but they must not create new business or regulatory requirements.

An approved design decision may be applied even when implementation remains pending. An LLM must distinguish:

- approved decision;
- synchronized documentation;
- implemented behavior;
- verified/tested behavior;
- released behavior.

When required context is missing or conflicting, the LLM must stop and identify the unresolved conflict rather than infer an answer.
