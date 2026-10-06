# Task Status

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`  
**Authoritative base commit:** `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`  
**Task phase:** Prepared for sequential agent execution  
**Overall status:** `READY_FOR_CODEX_BASELINE_GATE`

| Agent / gate | Role | Status | Deliverable / evidence |
|---|---|---|---|
| Coordination | Publish bounded task and launch prompts | PREPARED | `TASK.md`, `STATUS.md`, `*_LAUNCH.md` |
| Codex | Baseline proof, reproduction, minimal implementation, focused and full regression | NOT_STARTED | `reports/CODEX.md` and implementation PR |
| Claude | Fixed-SHA code and test review | BLOCKED_ON_CODEX_SHA | `reports/CLAUDE.md` |
| Hermes | Independent regression and native Windows PowerShell 5.1 qualification | BLOCKED_ON_CODEX_AND_CLAUDE | `reports/HERMES.md` |
| Consolidation | Reconcile reports and present user decision gate | BLOCKED_ON_ALL_REPORTS | `reports/CONSOLIDATED.md` |
| User | Accept or reject implementation into baseline | NOT_READY | Explicit decision; no automatic merge |

## Baseline

- Accepted contract: `eMAS.MS04.PreSales.ScannerObservations/1.0`
- Accepted scanner version: `0.8.0`
- Accepted capabilities: 8
- Frozen Wave 1 fixtures: 19
- Existing automated suites: 8
- Previous qualification: `PASS_WINDOWS_PS51_AUTOMATED_REGRESSION`
- Planning decision source: `EMAS-MS04-WAVE2-PLANNING` at merge commit `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`

## Current gate

Codex must prove the complete qualified package is present and hash-matched before editing. If that proof fails, set the overall status to `BLOCKED_BASELINE_NOT_REPRODUCIBLE`; do not reconstruct or broaden the baseline.

## Completion rule

This task is not complete when code merely exists. Completion requires persisted Codex, Claude, Hermes, and consolidated reports; passing focused and full regression; unchanged frozen inputs; native Windows PowerShell 5.1 qualification at the reviewed SHA; and an explicit user decision on the implementation PR.
