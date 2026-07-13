# LLM Decision and Delivery Boundary

**Status:** Effective implementation guidance  
**Decision references:** DEC-2026-004, DEC-2026-009, Approved Decision Baseline v1.0

This file prevents AI-assisted development from confusing approved decisions with completed implementation or from inventing behavior for genuinely new unresolved questions.

## 1. Current baseline

The Product Owner approved the recommended decision for all 171 items in the reviewed register on 13 July 2026.

Treat those decisions as approved design direction when they are represented in:

- the Approved Decision Baseline;
- the permanent Decision Log;
- affected approved governance, terminology, JSON or rule-model documents.

Do not require the user to reapprove a decision solely because its implementation remains pending.

## 2. Mandatory delivery-state distinction

For every task, distinguish:

1. **Decision approved** — the intended behavior is authorized.
2. **Documentation synchronized** — affected canonical documents reflect the decision.
3. **Implemented** — code, workbook, schema, template or skill exists.
4. **Verified** — required tests and evidence pass.
5. **Released** — release controls, manifest and approvals are complete.

Never claim a later state based only on an earlier one.

## 3. Mandatory authority rules

- Apply the canonical index and authority hierarchy.
- Cite the applicable DecisionId and requirement IDs.
- A lower-authority file, example, generated summary or code comment must not override an approved governing source.
- Do not resolve conflicts by selecting the newest, longest or most detailed file without applying authority and status.
- Preserve the authoring/runtime/execution source model.
- Do not convert project-specific evidence into a general product requirement.

## 4. When work may proceed

Work may proceed when:

- the governing decision is approved;
- the required authoritative sources are available;
- the requested change is within the approved behavior;
- required SME evidence already exists or the change is non-regulatory scaffolding;
- compatibility and downstream impacts can be determined.

Implementation may proceed even when dependent documents or tests are still pending, provided those pending items are explicitly tracked and the pull request does not claim closure.

## 5. Mandatory stop conditions

Stop and identify the blocking issue when:

- no approved decision covers the requested behavior;
- required authoritative context is missing;
- two approved sources conflict and authority cannot safely resolve the behavior;
- a new regulatory interpretation or controlled value requires SME judgment;
- a breaking JSON compatibility choice is not covered by the approved policy;
- phase result meaning or customer-facing controlled terminology would change;
- exception treatment, evidence meaning or report interpretation is ambiguous;
- required approval evidence is absent.

Implementation must also stop when a conflict affects:

- regulatory interpretation;
- JSON compatibility;
- phase decision logic;
- report meaning;
- evidence traceability.

## 6. Allowed work while blocked

An LLM may:

- identify and record the conflict;
- summarize evidence;
- prepare a decision brief;
- present recommendation and alternatives;
- draft non-authoritative scaffolding or an illustrative example;
- define acceptance criteria and affected artifacts;
- create a linked implementation plan that does not choose the unresolved behavior.

## 7. Prohibited work while blocked

An LLM must not:

- invent regulatory rules or authority relationships;
- choose new effort weights or thresholds without approved authority;
- select exception approvers or evidence requirements without approval;
- define an unapproved breaking JSON contract;
- hardcode unresolved business meaning in PowerShell;
- alter observed findings to reflect an exception;
- collapse evaluation status and RAG;
- treat ASMF as a technical format;
- publish internal controlled artifacts to a public repository;
- mark work implemented, verified or released without evidence.

## 8. Required blocked response

State:

1. the ConflictId, issue or new decision reference;
2. the unresolved question;
3. the governing sources and their status;
4. the relevant evidence and conflict;
5. the recommended decision;
6. realistic alternatives;
7. downstream implementation and compatibility impact;
8. the exact user or SME decision required.
