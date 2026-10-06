# Claude Launch — T3a Identification Schema 1.1

Work on task:

`EMAS-MS04-IDENTIFICATION-SCHEMA-1.1`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-identification-schema-1-1`

Read first:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- accepted Identification Rules review;
- accepted T3 Claude report;
- accepted T3 ChatGPT review;
- this task's `TASK.md` and `STATUS.md`;
- Runtime JSON Contract;
- Normalized Rule Model;
- Data Dictionary;
- Schema Validation and Fixture Contract;
- current schema/validators/fixtures;
- current PowerShell RuntimeConfiguration contract/loader.

Current project baseline includes accepted T1a at:

`08f4d0d240aac5393cba97f65ce9803fb4fffaa4`

T1a is complete. Do not modify CEC behavior.

The completed T3c analysis PR #50 may be read for context, especially its guard mapping and legacy-rule findings, but it is not normative until central review/user acceptance. Do not implement its open decisions U1–U11 in T3a.

Use branch:

`implementation/emas-ms04-identification-schema-1-1-claude`

This is a bounded implementation task.

Implement only:

- Schema 1.1.0;
- required semantic validator guards;
- 1.0.0 compatibility;
- PowerShell loader support;
- schema fixtures/tests;
- required canonical documentation synchronization.

Important:

- preserve Schema 1.0.0 compatibility;
- 1.1-only executable fields must not silently validate as 1.0.0;
- use dimension-scoped candidate resolution;
- do not add global cross-dimension code uniqueness;
- no workbook/export implementation;
- no IdentificationInterpretation;
- no production numeric Identification weights;
- do not fix the unrelated Windows PS5.1 UTF-8 assertion unless your own changes touch that failure;
- do not change accepted T1a CEC behavior.

Open a draft PR into:

`demo/end-to-end-mvp`

Do not merge.

Write the report to:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-SCHEMA-1.1/reports/CLAUDE.md`

Return only:

- branch
- commit SHA
- draft PR number/link
- report path
- Schema 1.1.0 version-dispatch approach
- fields and semantic guards added
- schema fixture result
- 1.0.0 compatibility result
- loader 1.0.0/1.1.0 result
- static/runtime contract results
- canonical docs sync result
- blocker/open issue
