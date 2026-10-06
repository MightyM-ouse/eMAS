# Claude launch

Work on task `EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D`.

Read:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- `docs/internal/agent-tasks/EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D/TASK.md`
- `docs/internal/agent-tasks/EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D/STATUS.md`

Execute only the Claude assignment as the single worker.

Use implementation branch:

`implementation/emas-ms04-dossier-diversity-wave1d`

Build and validate SD-044 through SD-051 exactly as defined in TASK.md. Derive expectations independently before freeze, preserve frozen Wave 1, perform Mac-only validation, and create the deterministic Wave1D test-data package/manifests.

Do not modify runtime/engine code. Do not implement or modify RepositoryDiscovery, FormatDetection, or RegionDetection. SD-051 is characterization only. SD-052 is deferred. Do not perform or claim Windows PowerShell 5.1 qualification.

Publish `reports/CLAUDE.md`, push the dedicated branch, and open a **draft PR into `demo/end-to-end-mvp`**. Do not merge.

Return only:

- branch
- commit SHA
- draft PR number/link
- report path
- generated fixture IDs
- Wave1D package SHA-256
- dedicated Wave1D Mac test result
- existing 8-suite Wave 1 Mac regression result
- any blocker/open decision
