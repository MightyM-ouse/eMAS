# eMAS Superseded Document Register

**Version:** 1.1  
**Status:** Effective  
**Effective date:** 2026-07-13  
**Owner:** Documentation Owner  
**Decision reference:** DEC-2026-007 / AP-007; approved requirements synchronization

## Purpose

This register identifies superseded or historical eMAS artifacts, their approved successors and their permitted use.

Historical artifacts are retained for traceability. They must not be used as current coding instructions, runtime contracts or regulatory-rule authority.

## Register

| Record ID | Historical artifact | Location | Status | Approved successor / governing source | Permitted use | Restriction |
|---|---|---|---|---|---|---|
| SUP-001 | eMAS Version 2 Word documentation pack dated 10 July 2026 | Controlled internal storage; public notice at [v2 documentation pack](v2-documentation-pack/README.md) | Superseded | Enterprise Requirements v3.1, configuration requirements v3.0, Authority Policy, Runtime JSON Contract and Normalized Rule Model | Historical comparison, requirement migration and contradiction analysis | Must not direct implementation; binaries are not published in the public repository |
| SUP-002 | Version 2 Confluence documentation associated with traceability ID 1386873065 | Controlled Confluence/internal archive | Superseded for implementation use | Current canonical index and effective repository requirements | Historical traceability and controlled comparison | Must not override current repository-approved requirements |
| SUP-003 | Open-question workflow created before approval of the 171-item register | `docs/governance/decision-register/open-question-workflow.md` | Historical process reference | Approved Decision Baseline and Decision Log | Evidence of how decisions were reviewed | Do not interpret listed items as still unapproved; delivery work remains tracked separately |
| SUP-004 | Pre-approval decision-boundary wording that treated all AI recommendations as unresolved | Earlier Git history of `docs/llm-development-context/decision-boundary.md` | Superseded | Current decision boundary and Decision Log | Audit history only | Current effective decisions must be distinguished from pending implementation and new unresolved issues |
| SUP-005 | Enterprise Requirements v3.0 dated 11 July 2026 | `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.0.md` | Superseded | [Enterprise Requirements v3.1](../requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | Historical comparison and requirement traceability | Must not be used as the current authority-rank-1 requirements baseline |
| SUP-006 | Mapping functional, technical and content catalogue Version 2.0 revisions | Earlier Git history of the three `docs/configuration/01_...`, `02_...` and `03_...` files | Superseded | Version 3.0 Effective revisions at the same repository paths | Historical comparison and review evidence | Must not direct new XLSM, VBA, JSON or regulatory-content implementation |

## Known obsolete concepts

The following concepts are explicitly superseded and must not be reintroduced unless a new approved decision changes the baseline:

- PowerShell reading the XLSM mapping workbook;
- `MappingWorkbookPath` as a runtime business-configuration input;
- PowerShell extracting workbook content and generating the runtime JSON;
- editable `IsActive` as the primary rule lifecycle control;
- one flat `DossierType` classification dimension;
- `NotAssessed` or `NotApplicable` as RAG values;
- findings and recommendations stored as one combined output;
- one flat rule row containing lifecycle, conditions, phases and outputs;
- ASMF treated as a technical submission format;
- regional implementation treated as a substitute for technical standard;
- separate runtime JSON files for each phase;
- the flat indicative JSON structure formerly shown in Enterprise Requirements v3.0;
- internal Confluence IDs embedded in shipped filenames, report names or customer console output.

## Supersession procedure

Before adding a record:

1. identify the exact historical artifact and version;
2. identify its approved successor;
3. migrate or explicitly reject still-valid content;
4. verify that active references are updated;
5. add a supersession notice to the historical artifact where practical;
6. retain checksum and approval evidence in controlled storage for non-public binaries;
7. update the canonical document index and machine-readable context index.

## Closure condition

A supersession action is complete only when no active document, skill, schema, code comment or user guide relies on the obsolete statement without an explicit historical reference.
