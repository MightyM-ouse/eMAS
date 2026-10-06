# Codex Launch — T1a CEC Physical Marker Evidence

Work on task:

`EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-cec-physical-marker-evidence`

Read:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- accepted Identification Rules Claude report;
- accepted Identification Rules ChatGPT review;
- this task's `TASK.md` and `STATUS.md`;
- current `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`;
- current focused CEC test suite;
- current RepositoryDiscovery v4 output model.

Use branch:

`implementation/emas-ms04-cec-physical-marker-evidence`

This is bounded factual-evidence implementation.

Do not implement IdentificationInterpretation, FormatDetection, RegionDetection, runtime JSON rule changes, scoring, or v4 XML parsing.

Preserve raw CEC `Strong/Supporting/Weak`; do not normalize Supporting to Medium here.

Open a draft PR into:

`demo/end-to-end-mvp`

Do not merge.

Return only:

- branch
- commit SHA
- draft PR number/link
- report path
- new evidence types and strengths
- focused CEC result
- Wave 1 result
- root-level result
- Wave1D result
- v4 discovery result
- B3 result
- frozen-hash result
- blocker/open issue
