# Claude Launch — EMAS-MS04-MAC-DEMO-RUNNER

Repository: `MightyM-ouse/eMAS`

Read the source-controlled task specification before any edit:

`docs/internal/agent-tasks/EMAS-MS04-MAC-DEMO-RUNNER/TASK.md`

**Current accepted demo commit:** `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8`
**Task coordination branch:** `coordination/emas-ms04-mac-demo-runner-task`
**Create implementation branch:** `implementation/emas-ms04-mac-demo-runner` from the exact current coordination HEAD (NOT directly from an earlier demo SHA).
**Draft worker PR target:** `coordination/emas-ms04-mac-demo-runner-task`.

You are the **single bounded implementation agent**. This is not another architecture/design cycle. Implement a one-click, PowerShell-7-on-Mac runner with three modes (QuickCheck, FullRegression, MS04Demo), VS Code tasks, HTML/JSON evidence and runner-only tests. Reuse existing PowerShell entry points, oracle and immutable fixtures.

Read first, in order:
1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`.
2. This task's `TASK.md`, `STATUS.md`, and this launch file.
3. `scripts/eMAS-PreSalesAssessment.ps1` and relevant harness parameter contracts.
4. `tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1`, `tests/identification-interpretation/engine/**`, existing Wave1/1D/1E/B3/T1b regression scripts, fixture manifests.
5. `config/runtime/README.md`, `tests/identification-interpretation/oracle/README.md`, and the accepted T2 report.

**Do not** modify scanner, XML collectors, CEC, T4, Runtime JSON or schemas, tests/oracle fixtures, report engine, GitHub workflows, or existing frozen data. Do not invent a demo ruleset. Stop and report if a prerequisite needs out-of-allowlist modifications.

Hard gates:
- QuickCheck must work without external corpora or interactive parameters, with honest SKIP handling.
- FullRegression must accurately run available suites and SKIP externally blocked ones, not claim 15/15 when some cannot run.
- MS04Demo requires a real compatible Runtime JSON and independently verifiable expected output to be called successful; otherwise BLOCKED or UNVERIFIED.
- Each run produces unique safe external artifacts: `summary.html`, `run-manifest.json`, individual stage logs/JSON.
- VS Code tasks named `eMAS: MS-04 Quick Check`, `eMAS: MS-04 Full Regression`, `eMAS: MS-04 Demo`.
- No hidden runtime downloads, no unsafe source/output writes, no inflated test counts or status.
- Mac PowerShell 7 execution is *development verification*, not Windows PS5.1 qualification.

Run and document actual checks. Record exact worker HEAD, paths, command lines, tests, fixture hashes, and which end-to-end demos were verified versus blocked. Update only task-owned `STATUS.md` and `reports/CLAUDE.md` alongside permitted new runner/test files.

Open **one draft PR** into the coordination branch. **Do not merge**. Return worker SHA, PR URL, test/result summary and remaining blockers for ChatGPT fixed-SHA central review.
