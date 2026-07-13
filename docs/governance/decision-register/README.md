# eMAS Decision Register

**Status:** Historical review evidence with approved outcome  
**Decision approval date:** 2026-07-13

## Current decision baseline

The evidence-based repository review completed on 12 July 2026 covered 155 existing decision items and identified 16 additional items, resulting in 171 tracked items.

The Product Owner subsequently approved adoption of the AI-recommended decision for all 171 items. The effective public repository record is now:

- [Approved Decision Baseline v1.0](../eMAS_Approved_Decision_Baseline_v1.0.md);
- [eMAS Decision Log](../eMAS_Decision_Log.md);
- [Authority and Precedence Policy](../00_authority_and_precedence.md);
- [Document Governance and Change Control](../eMAS_Document_Governance.md).

The internal reviewed workbook remains supporting evidence outside the public repository. Approval establishes design decisions; it does not automatically complete document synchronization, implementation, testing, SME evidence or release controls.

## Historical review material

- [Review summary](eMAS_Decision_Register_Review_Summary_2026-07-12.md)
- [Historical open-question workflow](open-question-workflow.md)
- [Historical Version 2 documentation notice](../../archive/v2-documentation-pack/README.md)
- [Superseded Document Register](../../archive/SUPERSEDED_DOCUMENT_REGISTER.md)

## Applying approved decisions

When implementing a decision:

1. identify its DecisionId and original register Item ID;
2. apply the authority and precedence policy;
3. update affected canonical artifacts in dependency order;
4. distinguish approved decision from completed implementation;
5. obtain required domain approvals;
6. update tests, traceability, canonical index and supersession records;
7. record remaining work explicitly.

## New unresolved questions

A new issue, conflict or regulatory interpretation not covered by the approved baseline must be treated as unresolved.

Do not infer a new requirement. Create a decision brief or issue containing:

- the exact question;
- conflicting evidence;
- recommendation and alternatives;
- required owner or SME;
- affected artifacts and compatibility impact;
- proposed acceptance criteria.

Implementation must stop when the unresolved matter affects regulatory interpretation, JSON compatibility, phase decision logic, report meaning or evidence traceability.

## Repository handling

This repository is public. Internal Word packs, reviewed decision workbooks, internal branding assets and controlled project evidence are not committed here. Their existence, decision effect and supersession status are represented through sanitized Markdown records.
