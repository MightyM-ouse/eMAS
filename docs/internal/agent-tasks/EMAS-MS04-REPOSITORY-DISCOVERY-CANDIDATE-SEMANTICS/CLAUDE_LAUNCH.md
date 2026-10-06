# Claude launch

Work on task:

`EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS`

Read:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/TASK.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/STATUS.md`
- the accepted Wave1D Claude/review reports
- current `engine/powershell51/eMAS.RepositoryDiscovery.psm1`
- relevant Wave 1 RepositoryDiscovery expectations and fixture descriptions

This is a **report-only decision task**.

Do not modify runtime code, tests, fixtures, expectations, contracts, FormatDetection, or RegionDetection.

Evaluate the current four-digit-child rule and the alternatives required by TASK.md. Produce one bounded recommended dossier-candidate rule, with a scenario matrix and future-format check.

Publish only:

`docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/reports/CLAUDE.md`

Use branch:

`analysis/emas-ms04-repository-discovery-candidate-semantics`

Open a draft PR into:

`coordination/emas-ms04-repository-discovery-candidate-semantics`

Do not merge.

Return only:
- branch
- commit SHA
- draft PR number/link
- report path
- recommended rule in one sentence
- any unresolved ambiguity
