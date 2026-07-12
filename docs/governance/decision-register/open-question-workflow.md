# Open-Question Decision Workflow

This workflow is used to discuss and approve eMAS open questions one by one before the mapping workbook and dependent documents are finalized.

## 1. Select the next item

Choose the highest-priority unblocked Item ID from the decision register. Follow dependency order rather than worksheet order.

The recommended first sequence is:

1. AP-001 — authority and precedence;
2. AP-002 — source-of-truth terminology;
3. AP-003 — document statuses;
4. AP-004 — conflict and stop procedure;
5. DOC-001 — enterprise baseline confirmation;
6. JSON-021 and DOC-020 — canonical JSON and workbook structures;
7. RM-018 and RM-008 — evaluation/RAG and evidence provenance;
8. DOC-013 and AP-010 — phase terminology and glossary;
9. REG-003 and REG-004 — regulatory taxonomy direction.

## 2. Prepare the decision brief

For the selected Item ID, prepare:

- the exact question;
- current repository state;
- conflicting statements;
- AI recommendation;
- realistic alternatives;
- business and technical impact;
- affected artifacts;
- required approver or SME;
- implementation and compatibility consequences;
- proposed acceptance criteria.

Do not combine unrelated Item IDs into one decision unless the register explicitly identifies them as one shared deliverable.

## 3. Record the decision

Update the controlled decision workbook fields:

- User Decision;
- Decision Rationale / Notes;
- Owner;
- Target Date;
- Status.

The decision should be written as a testable statement. Avoid entries such as `agreed`, `use recommendation` or `follow best practice` without the actual approved behavior.

## 4. Check dependent items

After approval:

- identify items unblocked by the decision;
- identify rows whose recommendation or status must change;
- identify superseded proposals;
- verify whether an SME approval or implementation spike is still required.

## 5. Apply controlled document changes

Update only the artifacts affected by the approved decision. Each change must reference the Item ID.

Typical order:

1. enterprise or functional requirement;
2. technical requirement and content catalogue;
3. architecture or schema;
4. LLM context and operational skill;
5. implementation and tests;
6. user and administrator guidance.

## 6. Verify closure

An item is closed only when:

- the decision is recorded;
- active documents no longer conflict;
- required implementation work is completed or separately tracked;
- required tests exist and pass;
- obsolete documents are identified as superseded;
- downstream traceability is updated.

A decision alone does not close an item when documentation or implementation remains pending.
