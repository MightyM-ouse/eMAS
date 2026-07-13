# eMAS Authority, Precedence and Source-of-Truth Policy

**Status:** Approved  
**Effective date:** 2026-07-13  
**Decision references:** AP-001, AP-002, AP-003, AP-004, AP-005, AP-006, AP-010

## 1. Purpose

This policy defines which eMAS artifacts are authoritative, how conflicts are resolved, which statuses may govern development, and how authoring, runtime and execution sources are distinguished.

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

## 3. Source-of-truth terminology

- **Authoring source of truth:** the reviewed internal Excel XLSM mapping workbook used to maintain business and regulatory configuration.
- **Runtime source of truth:** the validated, immutable runtime JSON exported from the approved XLSM.
- **Execution source:** the exact runtime JSON version and checksum loaded for a specific execution.

PowerShell must not read the XLSM and must not create the runtime JSON.

## 4. Document statuses

Controlled document statuses are:

- Draft
- InReview
- Approved or Final
- Effective
- Superseded
- Archived

Only Approved, Final or Effective documents may govern implementation. A newer Draft does not automatically override an older Approved or Effective document.

Rule lifecycle uses a separate vocabulary and must not be merged with document status:

- Draft
- InReview
- Reviewed
- Effective
- Superseded
- Retired

## 5. Conflict handling

When two sources conflict:

1. Apply the higher-authority approved source.
2. Assign a ConflictId and record the affected artifacts.
3. Mark the lower-authority artifact for correction or supersession.
4. Do not silently merge incompatible statements.
5. Stop implementation when the conflict affects:
   - regulatory interpretation;
   - JSON compatibility;
   - phase decision logic;
   - report meaning;
   - evidence traceability.

## 6. Examples and fixtures

Every example must be labelled as one of:

- **Illustrative** — explanatory only;
- **Golden Fixture** — approved, versioned and test-referenced;
- **Deprecated** — retained only for history.

Examples never override canonical requirements or schemas.

## 7. Change-authority matrix

| Change type | Owner / required approval |
|---|---|
| Regulatory content | Regulatory SME and Product Owner |
| Effort or confidence weights | Migration SME and Product Owner |
| JSON Schema | Technical Architect, Product Owner and PowerShell Lead |
| Shared engine code | PowerShell Lead and technical reviewer |
| Templates and report contracts | Product Owner and QA Lead |
| XLSM or VBA | Technical Architect; Corporate IT for signing and trust controls |
| Documentation | Documentation Owner and responsible area owner |

## 8. Terminology governance

The business glossary remains readable for users, while controlled codes and display terms are governed through `docs/governance/eMAS_Terminology.md` and the approved configuration value lists.

## 9. LLM and automation rule

LLMs may summarize or operationalize approved requirements, but they must not create new business or regulatory requirements. When required context is missing or conflicting, the LLM must stop and identify the unresolved decision rather than infer an answer.