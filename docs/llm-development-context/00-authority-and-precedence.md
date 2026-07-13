# eMAS Authority and Precedence

**Version:** 1.0  
**Status:** Effective  
**Effective date:** 13 July 2026  
**Decision references:** DEC-2026-001 through DEC-2026-012

## 1. Purpose

This document defines which eMAS artifacts are authoritative, how draft and approved statuses affect precedence, and what must happen when sources conflict.

## 2. Authority hierarchy

From highest to lowest authority:

1. Approved or Final enterprise requirements.
2. Approved configuration functional requirements.
3. Approved configuration technical requirements.
4. Approved configuration content catalogue and normalized logical model.
5. Approved machine-readable JSON Schema.
6. Approved architecture and project-flow specifications.
7. Approved report, development, test, operations and release specifications.
8. LLM development context.
9. Operational LLM skills.
10. Implementation code and build scripts.
11. Examples, samples and fixtures.

A lower-authority artifact must not override a higher-authority approved artifact.

## 3. Controlled status vocabularies

### 3.1 Document status

Draft, InReview, Approved, Final, Effective, Superseded and Archived.

Only Approved, Final or Effective documents govern implementation. A newer Draft does not override an older Approved, Final or Effective document.

### 3.2 Rule lifecycle

Draft, InReview, Reviewed, Effective, Superseded and Retired.

Only Effective, date-eligible rules enter a controlled runtime configuration.

## 4. Source-of-truth terminology

- **Authoring source of truth:** the reviewed internal XLSM mapping workbook.
- **Runtime source of truth:** the validated, immutable JSON exported from the approved XLSM.
- **Execution source:** the exact runtime JSON version and content hash loaded for one execution.

PowerShell never reads the authoring workbook and never generates the runtime JSON.

## 5. Conflict procedure

When active sources conflict:

1. Assign a Conflict ID.
2. Identify the authority and status of each source.
3. Apply the higher-authority approved source.
4. Flag the lower-authority artifact for correction.
5. Record affected Decision IDs, requirements, schema elements, implementation and tests.
6. Stop work when the conflict affects regulatory interpretation, JSON compatibility, phase decision logic, report meaning or release acceptance.

Conflicts must not be silently merged.

## 6. Example and fixture authority

Examples are `Illustrative` unless explicitly labelled `Golden Fixture` or `Deprecated`. Examples never override canonical requirements.

## 7. Change authority

The approved change-authority matrix is maintained in [`eMAS_Change_Authority_Matrix.md`](../governance/eMAS_Change_Authority_Matrix.md).

## 8. Supersession and archive

Superseded artifacts are retained with an explicit successor reference. Deletion is prohibited until the traceability matrix confirms that no active requirement, decision, test or implementation reference depends on the artifact.
