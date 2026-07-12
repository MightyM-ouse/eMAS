# eMAS Decision Register Review Summary

**Review date:** 12 July 2026  
**Scope:** Repository, requirements, configuration model, LLM context, external technical evidence and decision register  
**Decision status:** Review evidence only; user decisions remain pending unless already established by authoritative repository evidence

## Review results

- 155 existing decision items were reviewed.
- 16 additional items were identified, producing a total of 171 items.
- AI review content was added for proposal, rationale, repository evidence, external evidence, proposed status, owner, priority, implementation blocking, confidence, SME approval and merge/obsolete notes.
- Existing user-decision fields were not changed.
- The reviewed workbook reported zero formula errors after recalculation.

## Additional items identified

| Area | Added items |
|---|---|
| Authority and governance | AP-011, AP-012 |
| Runtime JSON | JSON-021, JSON-022, JSON-023 |
| Rule model | RM-026, RM-027 |
| LLM skills | SK-019 |
| Engine and functions | FN-020, FN-021 |
| Documentation | DOC-020, DOC-021 |
| XLSM/VBA | XL-014 |
| Regulatory | REG-014 |
| Test and release | TEST-019, TEST-020 |

## Main findings

### Repository evidence already establishes several design constraints

The repository consistently states that:

- the internal XLSM workbook validates and exports one runtime JSON directly;
- PowerShell does not read the XLSM and does not create the JSON;
- all three phases use the same runtime JSON;
- the runtime JSON supplies shared interpretation rather than complete phase workflow;
- the shared PowerShell engine performs generic technical processing;
- pre-sales remains lightweight;
- pre-migration produces a reusable baseline;
- post-migration reconciles against that baseline;
- source evidence remains read-only.

These constraints may be used during documentation synchronization without waiting for new mapping-content decisions.

### Material conflicts remain open

The review identified conflicts that require an approved decision before full cleanup:

1. **Source-of-truth terminology:** some LLM context describes JSON as the single source of truth while enterprise requirements describe the workbook as the reviewed rule-authoring source.
2. **Evaluation status versus RAG:** enterprise narrative wording and the normalized configuration documents are not fully aligned.
3. **Evidence provenance vocabulary:** enterprise requirements, content catalogue and LLM context use different value sets.
4. **Phase and result terminology:** some context uses `Ready with Exceptions` or `Post-Migration Reconciliation` while the enterprise baseline uses more specific result language.
5. **Runtime JSON structure:** the enterprise indicative structure and the normalized technical model require reconciliation.
6. **Workbook structure:** the enterprise sheet list and the expanded content-catalogue model differ.
7. **Regulatory taxonomy:** technical standards, regional implementations, procedures and source-presentation categories are mixed in the current format list.
8. **OpenXML implementation:** generating valid XLSX without Excel and without external PowerShell modules requires an early technical spike.

## Highest-priority decision gates

The following groups should be resolved before broad document cleanup or mapping-workbook implementation:

1. authority and precedence;
2. source-of-truth terminology;
3. document statuses and conflict handling;
4. canonical runtime JSON contract;
5. normalized rule, output, lifecycle, conflict and exception behavior;
6. evidence provenance and RAG/evaluation boundaries;
7. regulatory taxonomy direction;
8. implementation feasibility of the no-Excel/no-external-module XLSX requirement.

## Safe changes adopted now

The current repository update intentionally adopts only non-controversial governance changes:

- record the review and its findings;
- establish that AI proposals are not approvals;
- link unresolved work to decision-register Item IDs;
- prevent LLMs from silently resolving open questions;
- document that the Version 2 Word pack is historical and superseded for implementation use;
- keep internal binary artifacts out of the public repository;
- add governance navigation to the documentation index.

No unresolved regulatory value, rule weight, threshold, exception role, JSON structure or workbook table design is approved by this update.

## Recommended decision sequence

1. AP-001: authority hierarchy.
2. AP-002: authoring, runtime and execution source terminology.
3. AP-003 and AP-004: statuses, conflict and stop procedure.
4. DOC-001: confirm the enterprise requirements baseline.
5. JSON-021 and DOC-020: settle the canonical JSON and workbook structural pictures.
6. RM-018 and RM-008: settle evaluation/RAG and provenance vocabularies.
7. DOC-013 and AP-010: settle terminology and glossary control.
8. REG-003 and REG-004: settle taxonomy dimensions before regulatory rule population.
9. Complete the FN-021 OpenXML feasibility spike.
10. Synchronize requirements, architecture, context, skills, schemas, implementation and tests.

## Source classes used by the review

The external review used authoritative sources including:

- JSON Schema documentation;
- RFC 8259;
- Microsoft Learn and Microsoft Support;
- FDA eCTD guidance;
- EMA eSubmission information;
- Semantic Versioning.

External guidance remains supporting evidence. It does not become an eMAS requirement without an approved decision.
