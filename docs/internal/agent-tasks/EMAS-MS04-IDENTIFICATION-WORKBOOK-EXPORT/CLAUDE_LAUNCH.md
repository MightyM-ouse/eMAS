# Claude Launch — T3b Identification Workbook + Export

Work on task:

`EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-identification-workbook-export`

Read first:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- this task's `TASK.md` and `STATUS.md`;
- accepted Identification Rules report/review;
- accepted T3 runtime-design report/review;
- accepted T3a Schema 1.1.0 task/review and current implementation;
- accepted T3c report/review from `coordination/emas-ms04-prior-mapping-disposition` @ `4f34d08de9277028589bd8e4e877cbdc9ead91ad`;
- canonical workbook/Runtime JSON documents 01–09;
- current POC source, Python reference exporter/validator and VBA modules.

Current base:

`demo/end-to-end-mvp @ e83123bba30a6c51727d04290b76a950e9c47d59`

Use branch:

`implementation/emas-ms04-identification-workbook-export-claude`

Implement only the bounded T3b workbook-authoring and export capability defined in TASK.md.

Core requirements:

- migrate synthetic POC authoring/export to Schema 1.1.0;
- add Identification authoring columns/value lists;
- add only synthetic Identification examples;
- controlled projection = runtime-eligible Effective rules only;
- filter the complete dependent rule graph, not only the Rules table;
- Draft/InReview must never leak into controlled output;
- `LegacyRuleId` is workbook-only traceability and must never be exported;
- no direct import of the 39 historical rules;
- no numeric Identification weights;
- keep dimension-scoped candidate resolution;
- keep `Supporting → MEDIUM` normalization out of workbook aliases;
- do not implement T4 or T1b/T2;
- do not resolve T3c open decisions U2–U9.

Update deterministic workbook/VBA/reference-export fixtures and golden hashes.

Run all required automated regression suites.

If native Windows/Excel execution is unavailable, report:
`NATIVE_EXCEL_QUALIFICATION_PENDING`

Open a draft PR into:

`demo/end-to-end-mvp`

Do not merge.

Return only:

- branch
- commit SHA
- draft PR number/link
- report path
- workbook tables/columns changed
- controlled lists added
- runtime-eligibility/dependency-filter approach
- LegacyRuleId non-export proof
- Python reference export result
- VBA/source conformance result
- fixture/regression results
- deterministic JSON SHA-256
- native Excel qualification status
- blocker/open issue
