# Codex launch

Work on task:

`EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION`

Read:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/reports/CLAUDE.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/reports/REVIEW.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION/TASK.md`
- `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION/STATUS.md`

Execute only the Codex assignment.

Use branch:

`implementation/emas-ms04-repository-discovery-b3`

Mac validation only in this stage.

Implement the accepted B3 rule with the narrowed fail-open amendment and unreadable-not-empty correction. Add the required SD-051 normative-v2 and `Exports/2024/ProductABC` regressions. Do not implement eCTD v4 discovery, FormatDetection or RegionDetection.

Open a draft PR into `demo/end-to-end-mvp`. Do not merge.

Return only:
- branch
- commit SHA
- draft PR number/link
- report path
- focused B3 test result
- RepositoryDiscovery regression result
- 8-suite Wave 1 result
- root-level result
- Wave1D result
- any blocker/open issue
