# Task Status — EMAS-MS04-MAC-DEMO-RUNNER

**State:** `CLAUDE_IMPLEMENTATION_COMPLETE / WORKER_STOPPED / DRAFT_PR_AWAITING_CENTRAL_REVIEW`

| Item | Current state |
|---|---|
| Authorized scope | New bounded Mac PowerShell 7 VS Code runner / HTML+JSON evidence only |
| Accepted demo baseline | `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8` (ancestor of the task-order head) |
| Task-order coordination branch | `coordination/emas-ms04-mac-demo-runner-task` at `33ee4bd1193ac0d9733d110bc7b3c33445108f06` |
| Continuation authority | Central handoff [`6070807590`](https://github.com/MightyM-ouse/eMAS/pull/67#issuecomment-6070807590) |
| Assigned worker | Claude, single implementation owner |
| Worker branch | `implementation/emas-ms04-mac-demo-runner` |
| Implementation SHA (all final evidence) | `753995d40f2bb1be895c57145b75dbb840229a2f`. Supersedes `b6053d1`, which has the same runner plus the two handoff fixes below. |
| Worker PR | [#68](https://github.com/MightyM-ouse/eMAS/pull/68), **draft**, into the coordination branch. The fixed review SHA is its head, which adds only this file and `reports/CLAUDE.md` on top of `753995d`. |
| Changed files | `tools/demo/Invoke-eMASMS04Demo.ps1`, `tools/demo/private/**` (2 modules + data catalog), `tools/demo/README.md`, `.vscode/tasks.json` (force-added; `.gitignore` excludes `.vscode/`), `tests/demo-runner/**`, this file, `reports/CLAUDE.md` |
| Production engines, CEC, RD, T4, scripts, config, fixtures, oracle, corpora, workflows | Unchanged; read-only hashes identical before and after |
| Runner test suite (macOS 26.6.2 arm64, pwsh 7.5.2) | **26/26 PASS** with corpora; **25 PASS + 1 SKIP** (RT-03, corpora absent) without |
| QuickCheck, no corpora (repo and fresh GitHub clone) | **PASS_WITH_SKIPS**: T2 21/22 + SD-090 SKIP, T4 28/28, oracle 23/23. Strict exit 2; Task exit 0 with explicit banner. |
| FullRegression, no corpora | **PASS_WITH_SKIPS**. 5 suites PASS; 11 corpus suites SKIP with cause. |
| FullRegression, local external corpora | **PASS**. 15/15 gates + T2 22/22; exact baseline counts; freeze gates held. |
| MS04Demo: no Runtime JSON / invalid JSON / synthetic IDO-01 / invalid expected / mismatching expected | **BLOCKED** / **FAIL** (`CFG-FILE-009`) / **EXECUTED_UNVERIFIED** (verification SKIP) / **BLOCKED** / **FAIL** |
| Handoff item 3: VS Code `PASS_WITH_SKIPS` UX | **RESOLVED**. `-ExitCodePolicy Task` in the tasks: completed runs without a failure exit 0, while OverallStatus, the strict code, the banner and the HTML stay qualified. RT-25. |
| Handoff item 4: MS04Demo verdict precedence | **RESOLVED**. Not supplied → EXECUTED_UNVERIFIED (verification SKIP). Supplied but unusable → BLOCKED. Mismatch → FAIL. VERIFIED only with no BLOCKED or FAIL stage. RT-26, RT-09. |
| VS Code tasks | Task-command simulation in the fresh clone: Quick Check exit 0, Full Regression exit 0 (both PASS WITH SKIPS), Demo exit 4 (BLOCKED). **GUI click not validated.** |
| MS-04 business identification VERIFIED | **BLOCKED**. No approved Runtime JSON and no independent dossier-level expected outcome; none was authored. |
| PSScriptAnalyzer | UNVERIFIED (not installed). Parser: 0 errors. |
| Native Windows PS5.1 / Windows PS7.6 runner qualification | Not in this task; not attempted |
| Existing Windows PS5.1 UTF-8 aggregate CI issue | Open and out of scope |
| User merge approval | Not given |
| Merge | Not authorized; not performed |

Open decisions for central review:
1. Confirm the demo comparison profile. It removes `EvidenceSource.DocumentSha256` (varies on every dossier run), the runner-assigned `ExecutionId` fields and the oracle volatile fields.
2. Confirm the force-added `.vscode/tasks.json`, or authorize a `.gitignore` exception.
3. Confirm the `-ExitCodePolicy Task` UX decision for the VS Code tasks.
4. Supply or approve a Runtime JSON and an independent expected `Identification/1.0` document for a named dossier before any MS04Demo VERIFIED claim.

**Worker stop state.** Claude has stopped. Next: ChatGPT fixed-SHA central review of the PR #68 head, then a separate user merge decision. Full evidence, commands and report locations are in `reports/CLAUDE.md`, in the "Continuation" section.
