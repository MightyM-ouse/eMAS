# Codex Launch — T3a Identification Schema 1.1

Work on task:

`EMAS-MS04-IDENTIFICATION-SCHEMA-1.1`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-identification-schema-1-1`

Read first:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- accepted T3 Claude report;
- accepted T3 ChatGPT review;
- this task's `TASK.md` and `STATUS.md`;
- Runtime JSON Contract;
- Normalized Rule Model;
- Data Dictionary;
- Schema Validation and Fixture Contract;
- current schema/validators/fixtures;
- current PowerShell RuntimeConfiguration contract/loader.

Use branch:

`implementation/emas-ms04-identification-schema-1-1`

Implement only the bounded Schema 1.1.0 + semantic validators + loader support defined in TASK.md.

Current project baseline also includes accepted T1a at `08f4d0d240aac5393cba97f65ce9803fb4fffaa4`. T1a is already complete; do not modify CEC behavior as part of this task.

Important:

- preserve 1.0.0 compatibility;
- 1.1-only executable fields must not silently validate as 1.0.0;
- use dimension-scoped candidate resolution;
- do not add global cross-dimension code uniqueness;
- do not implement workbook/export changes;
- do not implement IdentificationInterpretation;
- do not add production numeric Identification weights;
- do not touch the unrelated Windows PS5.1 UTF-8 assertion.

Open a draft PR into:

`demo/end-to-end-mvp`

Do not merge.

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
