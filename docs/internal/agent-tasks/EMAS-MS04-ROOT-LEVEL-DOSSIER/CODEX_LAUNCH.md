# Codex launch

Read `docs/internal/agent-workflow/AGENT_WORKFLOW.md` and this task's `TASK.md`.

Restart the bounded root-level dossier implementation from the new repository-native RC1 baseline at `dac1664fee652f701a41204e2527f602077bb42f`.

Use branch `implementation/emas-ms04-root-level-dossier-v2`.

First prove the materialized baseline and run all eight existing suites on Mac. Then reproduce both root-level defects, add focused synthetic regression coverage, minimally fix only `ReferenceResolution` and `ClassificationEvidenceCollection`, and rerun focused plus all eight Wave 1 suites.

Publish `reports/CODEX.md` and open a draft PR into `demo/end-to-end-mvp`.

Do not touch frozen Wave 1 inputs, `RepositoryDiscovery`, `FormatDetection`, or `RegionDetection`. Do not perform or claim Windows PowerShell 5.1 qualification in this stage. Do not merge.
