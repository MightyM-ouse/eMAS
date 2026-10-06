# Codex Launch — eCTD v4 RepositoryDiscovery Implementation

Work on task:

`EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-ectd4-discovery-implementation`

Read and follow:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/CLAUDE.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/REVIEW.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION/TASK.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION/STATUS.md`
- current accepted `engine/powershell51/eMAS.RepositoryDiscovery.psm1`

The ChatGPT review amendments are normative where they differ from Claude's design report.

Use branch:

`implementation/emas-ms04-ectd4-discovery`

Before code, verify the currently supported official source versions required by TASK.md and record any material physical-layout difference.

Mac-first implementation only.

Do not modify FormatDetection, RegionDetection, v4 reference handling, BackboneXmlInventory, contracts, or existing frozen fixture bytes.

Build/freeze Wave1E SD-053–SD-074, run all required regression gates, and open a draft PR into:

`demo/end-to-end-mvp`

Do not merge.

Return only:
- branch
- commit SHA
- draft PR number/link
- report path
- source-version verification result
- focused v4 discovery result
- Wave1E deterministic-build result
- RepositoryDiscovery result
- B3 result
- Wave 1 eight-suite result
- root-level result
- Wave1D result
- any blocker/open issue
