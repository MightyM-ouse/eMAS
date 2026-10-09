# EMAS-MS04-MAC-DEMO-RUNNER — bounded Claude implementation

**Task ID:** `EMAS-MS04-MAC-DEMO-RUNNER`
**Scenario / phase:** `MS-04` / `PreSales`
**Accepted demo baseline (fixed):** `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8` on `demo/end-to-end-mvp` (PR #66 merged).
**Task-order branch:** `coordination/emas-ms04-mac-demo-runner-task`.
**Worker branch (Claude to create from task-order HEAD):** `implementation/emas-ms04-mac-demo-runner`.
**Worker PR base:** `coordination/emas-ms04-mac-demo-runner-task`, **draft only**.
**Role:** Claude is the *sole bounded implementation owner*; ChatGPT is fixed-SHA reviewer; user approves any merge.
**Authorization:** User approved a VS Code one-click macOS demo runner plus HTML evidence report. This authorizes only the bounded new runner and test/docs assets specified below. It does **not** approve worker or demo merges.

## Objective

Eliminate manual sequencing of Mac PowerShell commands for the existing MS-04 Pre-Sales development/demo. Create one portable, **deterministic** PowerShell orchestration entry point with VS Code tasks, machine-readable JSON results, a useful standalone HTML summary, and honest validation states. Reuse existing scripts and harnesses. **Do not build another assessment engine, config generator, workbook, GUI, or regulatory rule pack.**

The user can open the eMAS repository in VS Code and choose **Terminal → Run Task → eMAS: MS-04 Quick Check / Full Regression / Demo**. No need to manually type each module invocation. A future optional macOS double-click `.command` launcher is **not part of this initial task**.

## Confirmed repository facts (inspect HEAD again before coding)

- `scripts/eMAS-PreSalesAssessment.ps1` has an MS-04 `RepositoryDiscovery` parameter set with `-SourcePath`, `-OutputPath`, `-ExecutionId`, `-ScenarioId MS-04`, `-Phase PreSales`, optional `-RuntimeConfigurationPath`, `-IncludeSubmissionUnitXmlInventory`, `-IncludeClassificationEvidenceCollection` and `-IncludeIdentificationInterpretation`; identification mode calls RD→BXI→CEC→T4 and does not implicitly run reference/checksum work.
- Existing focused test scripts: `tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1` (requires `-OutputRoot`; optional `-Wave1CorpusRoot`), `tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1` and `Test-eMASIdentificationOracleConformance.ps1`.
- Existing Wave 1, 1D, 1E, B3, root-level, T1b and eight Wave 1 capability harnesses use **different arguments**. Discover their real parameter contracts before orchestrating them.
- Synthetic, fixed-byte eCTD v4 inputs exist under `tests/fixtures/submissionunit-xml-inventory/**`; physical v4 discovery cases under `tests/fixtures/repository-discovery-ectd4/wave1e/**`; separate synthetic identification oracle inputs/configs under `tests/identification-interpretation/oracle/cases/**`.
- `config/runtime/development` presently has only `.gitkeep`; oracle Runtime JSON is synthetic test policy, **not an approved MS-04 demo/release config**. The Wave 1 SD-002 corpus is external to GitHub. T2's mixed v3/v4 test must SKIP if `-Wave1CorpusRoot` is absent.
- Windows PS5.1 aggregate CI currently has an unrelated RuntimeConfiguration UTF-8 expectation failure; focused SUXI/T4 checks pass, but native PS5.1 T1b full qualification remains open.
- `tests/identification-interpretation/oracle/**` is frozen; T4 projection v1 ignores the eight new T2 CEC types.

## Required implementation

### 1. Single runner

Prefer one PowerShell 7-compatible entry point `tools/demo/Invoke-eMASMS04Demo.ps1` with modes `QuickCheck`, `FullRegression`, `MS04Demo`. It must invoke *existing public harnesses / Pre-Sales script* as child `pwsh -NoProfile -NonInteractive -File` processes, capture stdout/stderr, process exit status, durations and command identity, and not substitute self-invented success output. Keep invocation arguments explicit arrays (no shell-evaluated interpolation, `Invoke-Expression`, or unsafe shell strings). Preserve process failures, exceptions, diagnostics, and skip counts separately.

Prerequisites: PowerShell 7 on macOS, current repository checkout, accessible source/fixture paths and (for identification) a compatible runtime config. Record Git commit SHA, worktree dirty/clean state, OS/architecture, PowerShell version, runner version, source/config references and hashes where applicable. **Do not auto-checkout, pull, reset, install dependencies or modify Git state** during a run.

### 2. Three modes

**QuickCheck (zero mandatory parameters from VS Code):** environment/preflight + frozen manifest checks available from committed fixtures + current T2 focused test + T4 engine 28/28 + accepted oracle 23/23. T2 mixed scenario SKIP is expected without the external frozen SD-002 corpus; this **cannot become an unqualified overall PASS**. Be precise about PASS for the checks actually run, and SKIP in coverage. Do not treat an absent optional external corpus as a fatal startup error.

**FullRegression:** run the established 15 suites/gates **only after deriving actual scripts, required args, and expected artifacts from the repo and reports**. Support explicit optional paths to external Wave1 and Wave1D corpora (`-Wave1CorpusRoot`, `-Wave1DCorpusRoot` or similar); when absent, mark dependent suites SKIP with exact cause, never fabricate a pass or try to download private/frozen data. Preserve historical expected counts and fixture-hash read-only gates. Never silently weaken a test. If a harness unexpectedly fails, mark FAIL and continue independent suites where safe.

**MS04Demo:** invoke the *real* `scripts/eMAS-PreSalesAssessment.ps1` with supplied dossier `-SourcePath`, `-RuntimeConfigurationPath` and optional T2 capability request, obtaining the actual separate `Identification/1.0` output. The source may be an explicit directory or ZIP. Existing evidence-only route may run without Runtime JSON, but then identification is **BLOCKED** and an end-to-end PASS is forbidden. All business-rule interpretations must come from the supplied JSON, not runner logic. Source paths must not be modified. Do not falsely infer T4 v1 consumes T2's new v4 fact types. An independent expected-outcome document/checklist (provided by user or previously approved, never generated from the current actual result) is required before marking business identification **VERIFIED**. Without it, report `EXECUTED_UNVERIFIED` or `BLOCKED`, not PASS. No forced classification, fabricated confidence/RAG, or claim of regulatory compliance.

Prefer practical VS Code `inputs` for the demo source/config paths or optional local **untracked** user settings, but no hard-coded personal paths in tracked files, secrets, or interactive prompt in unattended execution. The QuickCheck VS Code task must truly be one click with no interactive configuration. The demo task should request only essential inputs and be usable by non-developers.

### 3. Evidence outputs

For every run create a unique timestamped directory **outside** the repository/source and runtime-config directories; never overwrite another run or customer evidence. It must contain:
- `run-manifest.json`: machine-readable run/runner identity, exact Git SHA, selected mode, invoked test IDs, command/args (safely normalized), platform, exit codes, PASS/FAIL/SKIP/BLOCKED/UNVERIFIED per stage, actual test counts, elapsed time, immutable input/reference hashes when feasible, output pointers, open limitations.
- `summary.html`: self-contained accessible HTML (readable in a browser without Excel/server) with run overview, per-stage statuses, runtime environment, test details, explicit failed/skipped/blocked reasons, provenance and artifact links. Escape all filesystem names, diagnostics and XML-derived content for HTML; no external fonts/CDNs/scripts. Avoid incorrectly styling amber/red conditions as green.
- Per-stage stdout/stderr and original observed JSON output (when produced), kept separately; never extract or publish unnecessary document content or credentials into the HTML.
- A reliable summary in the terminal with exact paths. Optional automatic opening of the report can be opt-in; failure to open browser must not change test verdicts.

Statuses must be explicit and not conflated: `PASS`, `FAIL`, `SKIP`, `BLOCKED`, and `UNVERIFIED`/equivalent. A subprocess return code 0 **alone** does not establish full validation or no skipped tests. Use the existing T2 structured summary where available. Preserve original logs and report actual partial execution when interrupted.

### 4. Read-only safety and maintainability

- Runner shall not modify the repository, XML/ZIP source, frozen fixtures, existing outputs, committed JSON, templates, protected branches or user settings without consent.
- Emit outputs only to validated external output root; reject paths within source/config/repo, symlinks escaping boundaries, missing required inputs, unsafe path traversal, and attempts to overwrite another run. Record errors clearly without mutating inputs.
- Keep functions small and tests deterministic; separate orchestration, result normalization, and HTML serialization (one helper file okay). No runtime downloads; do not require Python, npm, Excel, Docker, UI frameworks or additional PowerShell modules at runtime.
- Do not claim regulatory source/profile coverage beyond existing T1b/T2 contracts; do not change business rules, scanner contracts or identification projection.
- Mac PowerShell 7 development execution is the immediate objective. Windows PowerShell 5.1 **is not qualified by running the runner on a Mac**. The runner itself need not support native PS5.1 in this first iteration.

## Strict implementation allowlist

- `tools/demo/Invoke-eMASMS04Demo.ps1` (new)
- `tools/demo/private/**` (new, only if justified)
- `tools/demo/README.md` (new)
- `.vscode/tasks.json` (new, if repository lacks it; if present reconcile without replacing user entries)
- `tests/demo-runner/**` (new runner-specific synthetic tests, stubs and expected reports)
- This task's `STATUS.md` and `reports/CLAUDE.md` (report from Claude's implementation only).

Everything else is **read-only**, especially `scripts/eMAS-PreSalesAssessment.ps1`, `engine/**`, `config/**`, `tests/fixtures/**`, `tests/identification-interpretation/oracle/**`, existing harnesses/tests, `.github/workflows/**`, workbooks/VBA, `docs/architecture/**`, and other phase scripts. If anything cannot be done within this allowlist, **STOP and report a precise blocker** rather than changing scope.

## Tests / acceptance evidence (mandatory)

Before implementation: clean worktree + exact task-order SHA; inspect available corpus and test arguments; run QuickCheck constituent harnesses directly and record genuine PASS/FAIL/SKIP. If a baseline failure appears, STOP instead of silently changing expected outcomes.

Required runner tests:
1. QuickCheck from a clean Mac clone with no external corpora: correct focused outcomes and explicit SD-090 SKIP; HTML and manifest generated outside checkout; no source alteration.
2. FullRegression with missing corpora: dependent suites are SKIP with clear paths/reasons, unaffected suites execute; optional corpora available: exact real harnesses run and fixture hashes stay immutable.
3. MS04Demo without Runtime JSON: identification BLOCKED, no overall demo PASS.
4. MS04Demo with invalid JSON: real loader/validation failure is FAIL/BLOCKED, no fabricated identification JSON.
5. MS04Demo with valid synthetic *test-only* config plus suitable matching dossier/evidence: exercise real Pre-Sales script and compare against independently established expected result; only declare verified when assertion succeeds. If no compatible pair exists, **report BLOCKED; do not author a new regulatory ruleset to force a pass**.
6. Report escaping/injection: raw input path and diagnostic containing `<`, `&`, quote and other metacharacters are escaped; no HTML/JS injection.
7. Failure handling: nonzero process exit, harness-reported failures with zero exit, timeout/interruption and SKIP accounting are preserved; no partial run reported as completed PASS.
8. Output-path guard, source/tree immutability, repeated run unique directories, spaces/Unicode paths, no network dependency.
9. Preserve current 21/21 T2, 28/28 T4 engine, 23/23 oracle baselines; note the external mixed test 1 SKIP in CI and 22/22 local only if real corpus supplied. Test on macOS PowerShell 7 and capture actual commands/versions/counters.

Use honest status words: **designed**, **implemented**, **executed**, **verified**, and **qualified** are different milestones. Report static-only checks as static, not runtime passes.

## Deliverables / publication / next gate

Claude creates its own isolated worker branch/worktree from this task-order branch, implements only allowed files, runs tests and writes `reports/CLAUDE.md` plus `STATUS.md` with fixed worker SHA, changed-file inventory, exact invocations, PASS/FAIL/SKIP/BLOCKED/UNVERIFIED, output path examples, screenshots only if genuinely captured, defects and remaining prerequisites (especially Runtime JSON/corpus). Commit and push **only the worker branch**, open a **draft worker PR into this task-order coordination branch** and stop.

Do **not** mark end-to-end MS-04 complete merely because QuickCheck passes. Do not merge either PR. ChatGPT independently inspects the fixed SHA and test evidence; separate explicit user approval is required before worker and demo merges.

**Future (not authorized here):** macOS `.command` launcher, Windows qualification, full report XLSX, UI/app, scenario expansion, versioned Runtime JSON generation, projection v2, historical RD/BXI alias remediation, FDA D-3 retrieval, unrelated PS5.1 UTF-8 repair.
