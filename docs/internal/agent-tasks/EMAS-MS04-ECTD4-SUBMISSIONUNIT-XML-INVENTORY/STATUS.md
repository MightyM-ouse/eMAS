# Task Status

**Task ID:** EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY
**Roadmap ID:** T2
**Authoritative base commit:** 09c6e3bbb37f9811e045214cfb6b9bb575ce669e
**Coordination branch:** coordination/emas-ms04-ectd4-submissionunit-xml-inventory
**Overall status:** CLAUDE_DESIGN_REPORT_PUBLISHED / READY_FOR_FIXED_SHA_CENTRAL_REVIEW

| Gate | Status |
|---|---|
| T1b design and implementation | ACCEPTED / ACTIVE BASELINE |
| T1b baseline promotion PR #58 | MERGED as 1213d971a3c6285d2ab8c202bc7dccf47603a6ad |
| T1b status closeout PR #61 | MERGED as 09c6e3bbb37f9811e045214cfb6b9bb575ce669e |
| T2 task order | CREATED |
| Task-artifact commit | 34e91251781f7f2e62b99e2d3f310b7da48babe4 |
| Coordination PR #62 | OPEN / DRAFT / DO NOT MERGE |
| Claude design/research worker | REPORT PUBLISHED — reports/CLAUDE.md (worker branch analysis/emas-ms04-ectd4-submissionunit-xml-inventory-design, draft PR) |
| Official source verification | DONE — ICH IG v1.7 + schemas + CV v7; FDA M1 IG v1.9/v1.8, CV v1.0–v1.2, VC v1.6; EU M1 IG draft v1.2, CV v3, VC v1.1 (accessed 2026-10-07); FDA samples / M1 pkg v1.5.1 / ICH IG pkg v1.6 = GAP (download refused) |
| Exact XML field/cardinality map | DONE — report §5 |
| Version/profile compatibility matrix | DONE — report §4 |
| Failure/status semantics | DONE — report §8 |
| SubmissionUnitXmlInventory architecture | RECOMMENDED — separate optional SUXI capability; BXI unchanged |
| ScannerObservations impact | ADDITIVE within 1.0 (new SubmissionUnitXmlDocuments member + coverage rows + capability token) |
| BXI/CEC impact | BXI unchanged; CEC +8 factual types (7 Strong, 1 Supporting; StructuredXml); historical shape/EvidenceIds protected |
| T4/projection decision | DEFERRED — no prerequisite (report §14) |
| Fixture/test design | DONE — SD-028, SD-029, SD-075…SD-090 + tests T-1…T-18 |
| ChatGPT fixed-SHA central review | READY |
| User design acceptance | NOT READY |
| Codex implementation task | NOT AUTHORIZED |
| T2 merge | NOT AUTHORIZED |

## Current boundary

This task is design/research only. Claude may publish only the assigned report
and task status. No production, test, fixture, schema, projection, rule-pack,
workbook, reporting, or UI change is authorized.

The current accepted baseline may identify physical submissionunit.xml markers,
but it does not parse the document or claim structured T2 evidence.

## GitHub workflow

- Coordination PR: #62
- Coordination target: demo/end-to-end-mvp
- Claude worker branch: analysis/emas-ms04-ectd4-submissionunit-xml-inventory-design
- Claude worker target: coordination/emas-ms04-ectd4-submissionunit-xml-inventory
- Required worker PR state: draft
- Merge authority: new explicit user decision only

## Next gate

Launch Claude using CLAUDE_LAUNCH.md. Claude opens a draft report PR into the
coordination branch. ChatGPT then reviews one fixed worker SHA. A new user
decision is required before any design merge or Codex implementation task.
