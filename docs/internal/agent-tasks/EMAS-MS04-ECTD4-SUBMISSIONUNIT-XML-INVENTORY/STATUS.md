# Task Status

**Task ID:** EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY
**Roadmap ID:** T2
**Authoritative base commit:** 09c6e3bbb37f9811e045214cfb6b9bb575ce669e
**Coordination branch:** coordination/emas-ms04-ectd4-submissionunit-xml-inventory
**Overall status:** T2_DESIGN_USER_ACCEPTED / MERGED_TO_DEMO / CODEX_TASK_PREPARED

| Gate | Status |
|---|---|
| T1b design and implementation | ACCEPTED / ACTIVE BASELINE |
| T1b baseline promotion PR #58 | MERGED as 1213d971a3c6285d2ab8c202bc7dccf47603a6ad |
| T1b status closeout PR #61 | MERGED as 09c6e3bbb37f9811e045214cfb6b9bb575ce669e |
| T2 task order | CREATED |
| Task-artifact commit | 34e91251781f7f2e62b99e2d3f310b7da48babe4 |
| Coordination PR #62 | MERGED into demo at `ab06d567ad0f158c0d62b3d396951a90dca81fec` |
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
| ChatGPT fixed-SHA central review | ACCEPTED design revision 1.1 at `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e`; F-1/F-2/F-3 resolved |
| F-1 nested CEC identity | RESOLVED IN DESIGN — per-document, per-type SourceOrdinal + SourcePath; SD-085, T-19 |
| F-2 duplicate singleton values | RESOLVED IN DESIGN — typed CodedValue with Observations[]; no CEC emission on MultipleValues; SD-082, T-20 |
| F-3 confirmed-missing submissionunit.xml | RESOLVED IN DESIGN — Exists=false / Missing / InputUnavailable / NotAssessed / SubmissionUnitXmlConfirmedAbsent; SD-063 reuse, T-21 |
| FDA M1 v1.5.1 / samples retrieval (D-3) | OPEN — not complete |
| Native PS5.1 T1b qualification | OPEN — separate item, not complete |
| User design acceptance | APPROVED, exact fixed SHA `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e` |
| Codex implementation task | PREPARED under `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`; implementation worker not yet launched |
| T2 design merge | COMPLETED: PR #63 merge `44ce473c06a643314020c48ce1d6b67258f62fda` → PR #62 merge `ab06d567ad0f158c0d62b3d396951a90dca81fec`; **future implementation merge requires separate approval** |

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

## Design closeout and next gate

Claude report revision 1.1 was accepted by the user at fixed SHA `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e`. The report was merged into T2 coordination through PR #63 (`44ce473c06a643314020c48ce1d6b67258f62fda`), and the coordination design/task documentation was integrated into `demo/end-to-end-mvp` through PR #62 (`ab06d567ad0f158c0d62b3d396951a90dca81fec`). No implementation occurred during either merge.

Next: Codex may implement only under the separate bounded `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION/TASK.md` in a dedicated branch and publish a **draft** worker PR. Implementation remains unmerged without new user approval. FDA v1.5.1 source retrieval (D-3) and native T1b PS5.1 qualification remain OPEN.
