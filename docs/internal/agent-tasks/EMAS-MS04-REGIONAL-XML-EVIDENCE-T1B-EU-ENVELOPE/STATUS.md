# Task Status

**Task ID:** `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`  
**Roadmap ID:** T1b implementation  
**Authoritative base commit:** `e9530adb6f2e8b31035ca27f7267d6a2de25081d`  
**Coordination branch:** `coordination/emas-ms04-regional-xml-evidence-t1b-design`  
**Implementation branch:** `implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`  
**Overall status:** `IMPLEMENTATION_ACCEPTED / ACTIVE_BASELINE`

| Gate | Status |
|---|---|
| T1b design | ACCEPTED |
| User design decision | ACCEPTED |
| Formal implementation task order | CREATED |
| EU first-wave profiles 2.0 / 3.0.1 / 3.1 | FROZEN FOR THIS TASK |
| Five typed envelope fields | FROZEN FOR THIS TASK |
| Option A BXI same-parse architecture | CLOSED / REQUIRED |
| ScannerObservations impact | ADDITIVE 1.0 ONLY |
| Raw CEC evidence | Strong / StructuredXml |
| CEC Dimension behavior | LEGACY HINTS ONLY; NO NEW CODES |
| Historical CEC shape | MUST REMAIN UNCHANGED |
| Historical EvidenceIds | MUST REMAIN UNCHANGED |
| SourceOrdinal | NEW T1B ENVELOPE RECORDS ONLY |
| Profile vocabulary check | ALLOWED; NOT DTD/REGULATORY VALIDATION |
| T4 / CEC-FIELD-PROJECTION/2 | DEFERRED / SEPARATE TASK |
| Baseline reproduction | PASS |
| Implementation | ACCEPTED |
| Focused tests | PASS 10/10; 11/11 fixtures unchanged |
| RC1/BXI re-qualification | PASS |
| Wave 1 regression | PASS |
| Wave1D regression | PASS 61/61 |
| Root-level regression | PASS 3/3; historical 86; full additive 150 |
| T4 regression/oracle | PASS 28/28 and 23/23 |
| Windows PowerShell 5.1 T1b qualification | PENDING / NOT CLAIMED; NON-BLOCKING |
| `ema` versus `EU-EMA` source inconsistency | OPEN / NON-BLOCKING |
| ChatGPT fixed-SHA central review | ACCEPTED at `438d1f3b2c91ac139b37ca3415f735f25b2ce43e` |
| User implementation acceptance | ACCEPTED |
| Implementation PR #60 | MERGED as `b9c28e678bb6becf719565e22f258ce236d6b596` |
| Coordination PR #58 | MERGED into `demo/end-to-end-mvp` as `1213d971a3c6285d2ab8c202bc7dccf47603a6ad` |

## Accepted implementation boundary

Exactly five new factual evidence types are in scope:

- `EuEnvelopeCountry`
- `EuAgencyCode`
- `EuProcedureType`
- `EuSubmissionType`
- `EuSubmissionUnitType`

Supported EU Module 1 profiles for this wave:

- `2.0`
- `3.0.1`
- `3.1`

The implementation must extend the existing BackboneXmlInventory parse, remain read-only, keep CEC fact-only, preserve historical record shape/EvidenceIds, and leave T4 interpretation unchanged.

## Closeout

The implementation was reviewed at fixed worker head
`438d1f3b2c91ac139b37ca3415f735f25b2ce43e`, accepted by the user, and merged
through PR #60 into the coordination head
`b9c28e678bb6becf719565e22f258ce236d6b596`.

The complete T1b coordination head was then reviewed, accepted, and merged by
PR #58 into `demo/end-to-end-mvp` as
`1213d971a3c6285d2ab8c202bc7dccf47603a6ad`.

Native Windows PowerShell 5.1 execution of the T1b-focused/BXI/CEC suites is
still pending and is not claimed. The `ema` versus `EU-EMA` source
inconsistency also remains open. Both items are explicitly non-blocking and
were not auto-fixed during closeout.
