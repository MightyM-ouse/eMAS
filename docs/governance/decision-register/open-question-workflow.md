# Open-Question Decision Workflow

**Status:** Historical for the original 171-item review; reusable for new unresolved questions  
**Superseded outcome:** All 171 reviewed recommendations were approved on 2026-07-13. See [Approved Decision Baseline](../eMAS_Approved_Decision_Baseline_v1.0.md) and [Decision Log](../eMAS_Decision_Log.md).

This workflow documents how the original open questions were reviewed and remains the approved process for any genuinely new issue not covered by the current decision baseline.

## 1. Confirm that the question is genuinely unresolved

Before opening a new decision:

1. consult the [Canonical Document Index](../../CANONICAL_DOCUMENT_INDEX.md);
2. apply the [Authority and Precedence Policy](../00_authority_and_precedence.md);
3. search the [Decision Log](../eMAS_Decision_Log.md);
4. verify whether the matter is instead approved but still pending synchronization, implementation, SME evidence, testing or release control.

Do not reopen an approved decision merely because implementation is incomplete.

## 2. Select and identify the item

Assign a stable Item ID or issue reference. Follow dependency order rather than document or worksheet order.

A new question is required when:

- no approved source or DecisionId covers the behavior;
- two approved sources conflict and authority cannot safely resolve the result;
- a regulatory interpretation requires new SME judgment;
- a breaking compatibility choice is not covered by the approved JSON policy;
- a change would alter phase outcome meaning or customer-facing controlled terminology.

## 3. Prepare the decision brief

Include:

- the exact question;
- current repository state;
- governing source and authority rank;
- conflicting statements or missing evidence;
- recommendation;
- realistic alternatives;
- business, regulatory and technical impact;
- affected artifacts;
- required approver or SME;
- implementation and compatibility consequences;
- proposed acceptance criteria.

Do not combine unrelated items unless they are one inseparable decision or shared deliverable.

## 4. Record the decision

The approved decision must be written as a testable statement and recorded in:

- the controlled internal decision evidence;
- [eMAS Decision Log](../eMAS_Decision_Log.md) using the next DecisionId;
- affected requirements or design documents;
- the canonical index when authority, status or routing changes.

Avoid entries such as `agreed`, `use recommendation` or `follow best practice` without the approved behavior.

## 5. Check dependencies and delivery state

After approval:

- identify items unblocked by the decision;
- identify superseded proposals and documents;
- confirm whether SME approval evidence is still required;
- create or link implementation, synchronization, test and release work;
- retain the original delivery state until the work is complete.

## 6. Apply controlled changes

Typical order:

1. governance and terminology;
2. enterprise or functional requirement;
3. technical requirement and content catalogue;
4. architecture, logical model or schema;
5. LLM context and operational skills;
6. implementation and tests;
7. user, administrator and release guidance;
8. supersession and archive records.

Each pull request must cite the DecisionId and applicable requirement IDs.

## 7. Verify closure

A decision-related item is closed only when:

- the decision is permanently recorded;
- active documents no longer conflict;
- implementation work is complete or separately tracked with an accurate state;
- required SME and technical approvals exist;
- required tests pass;
- obsolete documents are registered as superseded or archived;
- downstream traceability and canonical indexes are updated.

A decision alone does not prove implementation, verification or release completion.
