# Task Status — EMAS-MS04-MAC-DEMO-RUNNER

**State:** `CLAUDE_IMPLEMENTATION_EXECUTED / DRAFT_PR_AWAITING_CENTRAL_REVIEW`

| Item | Current state |
|---|---|
| Authorized scope | New bounded Mac PowerShell 7 VS Code runner / HTML+JSON evidence only |
| Accepted demo baseline | `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8` (ancestor of the task-order head) |
| Task-order coordination branch | `coordination/emas-ms04-mac-demo-runner-task` at `33ee4bd1193ac0d9733d110bc7b3c33445108f06` |
| Assigned worker | Claude, single implementation owner |
| Worker branch | `implementation/emas-ms04-mac-demo-runner` |
| Implementation commit (evidence) | `b6053d11097b1baa9bf5de3d046d5963eb29d3c7` |
| Worker PR | Draft into the coordination branch; the fixed review SHA is the PR head that adds this file |
| Changed files | `tools/demo/Invoke-eMASMS04Demo.ps1`, `tools/demo/private/**` (2 modules + 1 data catalog), `tools/demo/README.md`, `.vscode/tasks.json` (force-added; `.gitignore` excludes `.vscode/`), `tests/demo-runner/**`, this file, `reports/CLAUDE.md` |
| Production engines, CEC, RD, T4, scripts, config, fixtures, oracle, workflows | Unchanged |
| Pre-implementation direct baseline (macOS, pwsh 7.5.2) | PASS. 15 gates. Focused T2: 21 + 1 SKIP without corpus, 22/22 with it. T4 28/28. Oracle 23/23. |
| QuickCheck, no corpora (repo and fresh GitHub clone) | **EXECUTED: PASS_WITH_SKIPS** (exit 2). T2 21/22 + SD-090 SKIP, T4 28/28, oracle 23/23, freeze manifests 22+22, immutability PASS. |
| FullRegression, no corpora | **EXECUTED: PASS_WITH_SKIPS**. 5 suites PASS; 11 corpus suites SKIP with cause; no 15/15 claim. |
| FullRegression, local external corpora | **EXECUTED: PASS** (exit 0). 15/15 gates + T2 22/22, exact baseline counts, freeze gates held, corpora unchanged. |
| MS04Demo, no Runtime JSON | **BLOCKED** (exit 4). Evidence route executed; identification not executed. |
| MS04Demo, invalid Runtime JSON | **FAIL** (exit 1). Real loader `CFG-FILE-009`; no Identification document. |
| MS04Demo, synthetic oracle (test-only) Runtime JSON | **EXECUTED_UNVERIFIED** (exit 3). Real Identification/1.0 produced; verification BLOCKED. |
| MS-04 business identification VERIFIED | **BLOCKED**. No approved Runtime JSON and no independent dossier-level expected outcome exist; none was authored. |
| Runner test suite | 24/24 PASS with corpora; 23 PASS + 1 SKIP (RT-03) without |
| VS Code tasks | Task `args` executed as no-shell processes from a fresh clone: Quick Check exit 2, Full Regression exit 2, Demo exit 4 (BLOCKED). Not clicked in the VS Code UI. |
| PSScriptAnalyzer | UNVERIFIED (not installed; not installed by Claude). Parser: 0 errors. |
| MS-04 development Runtime JSON | Not established; never claimed as approved |
| External frozen Wave 1 / Wave1D corpora | Optional, local in `/private/tmp`, outside GitHub; absent means SKIP |
| Native Windows PS5.1 / Windows PS7.6 runner qualification | Not in this task; not attempted |
| Existing Windows PS5.1 UTF-8 aggregate CI issue | Open and out of scope |
| User merge approval | Not given |
| Merge | Not authorized; not performed |

Open decisions for central review:
1. Confirm the demo comparison profile. It removes `EvidenceSource.DocumentSha256`, which changes every run on the dossier route, along with the runner-assigned `ExecutionId` fields and the oracle volatile fields.
2. Confirm the force-added `.vscode/tasks.json`, or authorize a `.gitignore` exception.
3. Supply or approve a Runtime JSON and an independent expected `Identification/1.0` document for a named dossier before any MS04Demo VERIFIED claim.

Next action: ChatGPT fixed-SHA central review of the draft PR head. The user decides worker and demo merges separately. The full evidence and exact commands are in `reports/CLAUDE.md`.
