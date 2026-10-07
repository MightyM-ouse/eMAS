# Task Status

**Task ID:** EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY
**Roadmap ID:** T2
**Authoritative base commit:** 09c6e3bbb37f9811e045214cfb6b9bb575ce669e
**Coordination branch:** coordination/emas-ms04-ectd4-submissionunit-xml-inventory
**Overall status:** DESIGN_TASK_CREATED / READY_FOR_CLAUDE

| Gate | Status |
|---|---|
| T1b design and implementation | ACCEPTED / ACTIVE BASELINE |
| T1b baseline promotion PR #58 | MERGED as 1213d971a3c6285d2ab8c202bc7dccf47603a6ad |
| T1b status closeout PR #61 | MERGED as 09c6e3bbb37f9811e045214cfb6b9bb575ce669e |
| T2 task order | CREATED |
| Claude design/research worker | READY TO LAUNCH |
| Official source verification | PENDING CLAUDE |
| Exact XML field/cardinality map | PENDING CLAUDE |
| Version/profile compatibility matrix | PENDING CLAUDE |
| Failure/status semantics | PENDING CLAUDE |
| SubmissionUnitXmlInventory architecture | PENDING CLAUDE |
| ScannerObservations impact | PENDING CLAUDE |
| BXI/CEC impact | PENDING CLAUDE |
| T4/projection decision | EXPECTED DEFERRED; PENDING DESIGN PROOF |
| Fixture/test design | PENDING CLAUDE |
| ChatGPT fixed-SHA central review | BLOCKED ON CLAUDE REPORT |
| User design acceptance | NOT READY |
| Codex implementation task | NOT AUTHORIZED |
| T2 merge | NOT AUTHORIZED |

## Current boundary

This task is design/research only. Claude may publish only the assigned report
and task status. No production, test, fixture, schema, projection, rule-pack,
workbook, reporting, or UI change is authorized.

The current accepted baseline may identify physical submissionunit.xml markers,
but it does not parse the document or claim structured T2 evidence.

## Next gate

Launch Claude using CLAUDE_LAUNCH.md. Claude opens a draft report PR into the
coordination branch. ChatGPT then reviews one fixed worker SHA. A new user
decision is required before any design merge or Codex implementation task.
