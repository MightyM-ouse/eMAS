# Task Status — EMAS-MS04-MAC-DEMO-RUNNER

**State:** `TASK_PREPARED / CLAUDE_IMPLEMENTATION_NOT_STARTED`

| Item | Current state |
|---|---|
| Authorized scope | New bounded Mac PowerShell 7 VS Code runner / HTML+JSON evidence only |
| Accepted demo baseline | `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8` |
| Task-order coordination branch | `coordination/emas-ms04-mac-demo-runner-task` |
| Assigned worker | Claude, single implementation owner |
| Worker branch | `implementation/emas-ms04-mac-demo-runner` (to be created by Claude) |
| Worker PR | Not yet opened; draft into coordination |
| Production engines, CEC, RD, T4, scripts | Unchanged / explicitly forbidden |
| MS-04 development Runtime JSON | Not established; never claim approved configuration |
| External frozen Wave 1/SD-002 corpus | Optional, required to execute mixed test; absent means SKIP |
| Native Windows PS5.1 qualification | Not in this task |
| Existing Windows PS5.1 UTF-8 aggregate CI issue | Open and out of scope |
| User merge approval | Not given for runner implementation |
| Merge | Not authorized |

Next action: launch Claude from `CLAUDE_LAUNCH.md` after verifying this coordination branch HEAD. Claude's report path is `reports/CLAUDE.md`. Central reviews the returned fixed SHA; user decides merge separately.
