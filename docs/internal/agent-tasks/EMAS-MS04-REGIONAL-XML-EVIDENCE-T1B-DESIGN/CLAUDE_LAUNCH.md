# Claude Launch — T1b Regional XML Evidence Design

Work on:

`EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN`

Repository:

`MightyM-ouse/eMAS`

Use branch:

`analysis/emas-ms04-regional-xml-evidence-t1b-design`

Merge target:

`coordination/emas-ms04-regional-xml-evidence-t1b-design`

Read `TASK.md` and `STATUS.md` first.

This is a **report-only design task**.

Do not implement code.

Primary scope:

**EU eCTD Module 1 structured regional XML evidence for MS-04 Pre-Sales.**

Your job is to define the exact factual XML fields eMAS should collect, prove each normative field from official EU regulatory sources, recommend how those fields should be parsed and represented, and define how CEC can expose them later without interpreting them.

Key constraints:

- T4 IdentificationInterpretation is already accepted and merged.
- CEC stays factual only.
- CEC must not reopen XML.
- raw CEC Strength remains Strong / Supporting / Weak.
- Supporting → MEDIUM happens only inside T4.
- Region and RegionalImplementation remain separate.
- ASMF/DMF are not TechnicalStandard values.
- do not resolve T3c U2–U9.
- do not implement v4 `submissionunit.xml`; that is T2.
- support historical EU regional XML profiles found in the accepted repository samples, not only the newest specification.
- every normative XML field requires an official source with exact version/section/page or DTD/schema declaration.
- if official support is missing, mark the field UNVERIFIED / DO_NOT_IMPLEMENT.

Required architecture decision:

Choose and justify:
- extend BackboneXmlInventory,
- create a new RegionalXmlInventory,
- or another bounded option.

CEC may consume upstream parsed facts, but may not parse/reopen XML itself.

Create only:

`docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/reports/CLAUDE.md`

Open a draft PR into the coordination branch.

Do not merge.

Return:
- branch
- commit SHA
- draft PR
- executive recommendation
- official source ledger summary
- proposed first-wave field count
- architecture recommendation
- ScannerObservations contract impact
- proposed CEC evidence types/strengths
- historical EU version coverage
- unresolved SME/PO decisions
- recommended implementation task
