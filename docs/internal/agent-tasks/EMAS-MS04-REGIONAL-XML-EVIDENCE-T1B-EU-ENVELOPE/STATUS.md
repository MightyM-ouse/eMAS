# Task Status

**Task ID:** `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`  
**Roadmap ID:** T1b implementation  
**Authoritative base commit:** `e9530adb6f2e8b31035ca27f7267d6a2de25081d`  
**Coordination branch:** `coordination/emas-ms04-regional-xml-evidence-t1b-design`  
**Implementation branch:** `implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`  
**Overall status:** `READY_FOR_CODEX`

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
| Baseline reproduction | PENDING CODEX |
| Implementation | READY |
| Focused tests | PENDING |
| RC1/BXI re-qualification | PENDING |
| Wave 1 regression | PENDING |
| Wave1D regression | PENDING WHERE AVAILABLE |
| T4 regression/oracle | PENDING |
| Windows PowerShell 5.1 evidence | PENDING |
| ChatGPT fixed-SHA central review | BLOCKED ON CODEX PR |
| User implementation acceptance | NOT READY |
| Merge | NOT AUTHORIZED |

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

## Worker launch

Codex reads:

- `TASK.md`
- `CODEX_LAUNCH.md`
- the accepted T1b design report/review referenced by TASK.md

Codex works only on:

`implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`

and opens a draft PR into:

`coordination/emas-ms04-regional-xml-evidence-t1b-design`

Do not merge.

## Next gate

Codex must first reproduce the accepted baseline from the authoritative base, then implement the bounded T1b EU-envelope collection and publish:

`docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/reports/CODEX.md`

ChatGPT then performs a fixed-SHA central review.
