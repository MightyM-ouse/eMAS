# Claude implementation report — EMAS-MS04-MAC-DEMO-RUNNER

## Identity and governance

| Item | Value |
|---|---|
| Task | `EMAS-MS04-MAC-DEMO-RUNNER` |
| Task-order base (coordination HEAD, verified before branching) | `33ee4bd1193ac0d9733d110bc7b3c33445108f06` |
| Accepted demo baseline (ancestor of the base) | `fd767d48d7400eff489c6cb659eaa7f2cd91aeb8` |
| Worker branch | `implementation/emas-ms04-mac-demo-runner` |
| Implementation commit (all runtime evidence below) | `b6053d11097b1baa9bf5de3d046d5963eb29d3c7` |
| Report commit | the PR head that adds this file and `STATUS.md`; it changes no executable file (the SHA is not self-embedded) |
| Draft PR | into `coordination/emas-ms04-mac-demo-runner-task`; **not merged** |
| Platform | macOS 26 (Darwin 25.6.0) arm64, PowerShell Core 7.5.2, .NET 9.0.6 |

Milestones, using the task's vocabulary:
- **Implemented and executed** on macOS PowerShell 7.5.2.
- **Verified** against the runner's own tests and the accepted harness baselines.
- **Not qualified** on Windows PowerShell 5.1 or 7.6. A Mac run cannot qualify those.
- **End-to-end MS-04 business identification is not verified.** See Blockers.

## Changed files (allowlist only)

| File | Purpose |
|---|---|
| `tools/demo/Invoke-eMASMS04Demo.ps1` | Single PowerShell 7 entry point: modes, plan, stage execution, verdict, terminal summary |
| `tools/demo/private/eMAS.MS04DemoRunner.psm1` | Orchestration helpers and result normalization: path guard, hashing, Git read, child process, counts, verdicts, Identification comparison |
| `tools/demo/private/eMAS.MS04DemoReport.psm1` | HTML serialization only |
| `tools/demo/private/eMAS.MS04SuiteCatalog.psd1` | Data only: harness scripts, exact arguments, expected counts, freeze gates, committed manifests, comparison volatile fields |
| `tools/demo/README.md` | Usage, statuses, exit codes, evidence layout, safety |
| `.vscode/tasks.json` | The three one-click tasks (see note below) |
| `tests/demo-runner/Test-eMASMS04DemoRunner.ps1` | 24 runner-specific checks |
| `tests/demo-runner/stubs/Invoke-StubHarness.ps1` | Synthetic stub harness for process-failure tests |
| this report and `STATUS.md` | Task records |

Nothing else changed. In particular, these are unchanged:
- `scripts/**` and `engine/**`;
- `config/**`, `tests/fixtures/**` and `tests/identification-interpretation/**`;
- existing harnesses, `.github/workflows/**`, schemas, workbooks and `docs/architecture/**`.

The pre-existing `tools/demo/New-eMASDemoReports.ps1` and `tools/demo/data/**` are untouched.

**Note on `.vscode/tasks.json`.** The repository had no `.vscode/` folder, and `.gitignore` (line 45) ignores `.vscode/`. Editing `.gitignore` is outside the allowlist. I therefore force-added the single file with `git add -f .vscode/tasks.json`. Git now tracks that one file, and every other local `.vscode` file (such as user settings) stays ignored. Central review may prefer an explicit `.gitignore` exception instead; that would be a separate, out-of-allowlist change.

## Pre-implementation baseline (direct harness runs, before any runner code)

Run at the clean task-order HEAD `33ee4bd`. Each harness ran as `pwsh -NoProfile -NonInteractive -File …`, outside the runner. Exit code was 0 for every run, and the worktree stayed clean (0 entries).

External corpora (outside GitHub):

| Corpus | Path | Notes |
|---|---|---|
| Wave 1 | `/private/tmp/emas-t1b-wave1-ref` | `WAVE1_FREEZE_MANIFEST.csv` plus a `fixtures` symlink to `02_Working/MS-04-PreSales-Wave1/fixtures` |
| Wave1D | `/private/tmp/emas-ectd4-baseline.e3oYH2/wave1d/eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1` | |

| Harness | Arguments | Result |
|---|---|---|
| RuntimeConfiguration | none | 28 total, 0 failed (not part of the 15 gates; recorded only) |
| T4 engine | none | 28/28 |
| T4 oracle | none | 23/23 (22 output + 1 expected-failure) |
| T2 SUXI | `-OutputRoot` | 22 total: 21 passed, 0 failed, **1 skipped** (SD-090 mixed) |
| T2 SUXI | `-OutputRoot -Wave1CorpusRoot <W1>` | 22/22 |
| T1b | `-OutputRoot` | 10/10; 11/11 fixtures read-only |
| Wave1E | `-OutputRoot` | 22/22 + 2/2 |
| W1 RD / BXI / RI / RR / MRI / DCC / CMI / CEC | `-CorpusRoot <W1> -FreezeManifestPath <W1>/WAVE1_FREEZE_MANIFEST.csv -OutputRoot` | PASS each. Freeze 19/19 before and after. CEC also checks Wave1E 22/22. |
| Wave1D | `-CorpusRoot <W1D> -Wave1CorpusRoot <W1> -OutputRoot` | 61/61 |
| Root-level | `-CorpusRoot <W1> -OutputRoot` | 3/3 |
| B3 | `-CorpusRoot <W1> -OutputRoot` | 12/12 |

No baseline failure appeared, so no expected outcome was changed. The 15 gates were derived from the accepted T2 report (`EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION/reports/CODEX.md`), and the arguments from each harness's `param()` block. The Wave 1 structured counts used by the runner come from these runs' summary JSON:

| Suite | Count fields | Total |
|---|---|---|
| RD | fixtures 10 + additional 3 | 13 |
| BXI | primary 6 + regression 13 + additional 5 | 24 |
| RI | 11 + 8 + 9 | 28 |
| RR | 19 + 12 | 31 |
| MRI | 19 + 14 | 33 |
| DCC | 19 + 18 | 37 |
| CMI | 19 + 35 | 54 |
| CEC | 19 + 43 | 62 |

## What was built

### Runner design

**How each stage runs.** Every stage runs an existing committed harness, or the real `scripts/eMAS-PreSalesAssessment.ps1`, as a child process:
- `pwsh -NoProfile -NonInteractive -File` with a .NET `ProcessStartInfo.ArgumentList`;
- no shell, no `Invoke-Expression`;
- stdin closed;
- working directory inside the run folder;
- `NO_COLOR=1`.

**What is recorded per stage.** stdout and stderr go to files. The manifest also records exit code, duration, start time, timed-out flag and the exact argument array.

**How a stage status is decided.** It comes only from the harness's own structured result:
- the summary JSON when the harness writes one;
- otherwise the harness's final result line for T4 engine and oracle.

That result is cross-checked against three things:
- the `[PASS]`/`[FAIL]`/`[SKIP]` lines;
- the catalog's expected counts;
- the harness's own freeze-gate counters.

An exit code of 0 alone is never a pass. When no structured result can be read, the status is `UNVERIFIED`.

**Statuses.**

| Status | Meaning |
|---|---|
| `PASS` | Ran and matched the expected counts |
| `PASS_WITH_SKIPS` | Every executed check passed, but some were skipped |
| `SKIP` | Optional external input not supplied |
| `BLOCKED` | Supplied input invalid, or prerequisite missing |
| `FAIL` | See causes below |
| `UNVERIFIED` | Exit 0 but no structured result |
| `EXECUTED_UNVERIFIED` | Demo route ran; output not independently verified |
| `VERIFIED` | Demo output matched a supplied independent expected document |
| `INCOMPLETE` | Run interrupted or runner error |
| `NOT_RUN` | Stage never started |

`FAIL` covers all of these:
- a non-zero exit;
- a timeout;
- an interruption;
- a harness-reported failure, even with exit code 0;
- count drift;
- a broken freeze gate;
- a changed input;
- a verification mismatch.

**Exit codes.**

| Code | Result |
|---|---|
| 0 | PASS / VERIFIED |
| 1 | FAIL |
| 2 | PASS_WITH_SKIPS |
| 3 | EXECUTED_UNVERIFIED / UNVERIFIED |
| 4 | BLOCKED |
| 5 | INCOMPLETE |
| 6 | Refused before a run directory existed |

### Modes

**QuickCheck** (zero parameters). Stages:
1. Preflight.
2. Runner-native SHA-256 check of the committed `SUXI_FREEZE_MANIFEST.csv` (22) and `WAVE1E_FREEZE_MANIFEST.csv` (22).
3. Focused T2.
4. T4 engine.
5. T4 oracle.
6. Immutability.

**FullRegression.** Preflight, manifests, the 15 established gates, focused T2 and immutability.
- If a corpus is not supplied, the suites that need it are `SKIP` and the reason names the parameter.
- If a corpus is supplied but invalid, those suites are `BLOCKED`.
- Independent suites still run.

**MS04Demo.** Stages:
1. Input validation.
2. Real evidence route (`-IncludeClassificationEvidenceCollection`, plus `-IncludeSubmissionUnitXmlInventory` when requested).
3. Separate real identification route (`-RuntimeConfigurationPath … -IncludeIdentificationInterpretation`).
4. Verification against a user-supplied expected `Identification/1.0` document.
5. Immutability.

Demo behaviour:
- **Without Runtime JSON:** identification is `BLOCKED` and the overall result is `BLOCKED`.
- **Without an expected document:** the best possible result is `EXECUTED_UNVERIFIED`.
- **Runtime JSON content:** the runner never parses it. Only the real loader validates it.

### Evidence per run

Each run writes to a new folder, `<OutputRoot>/<UTC timestamp>-<Mode>-<8 hex>/` (default `~/eMAS-MS04-Runs`). It contains:
- `run-manifest.json`;
- `summary.html`;
- `stages/NN-<ID>/{stdout.log,stderr.log,harness-output/|observed/}`.

The manifest and HTML are rewritten atomically (temp file, then rename) after every stage. A killed run therefore still shows `INCOMPLETE`.

### HTML report

- Self-contained: no scripts, fonts, CDNs or remote resources.
- Restrictive `Content-Security-Policy` meta tag (`default-src 'none'`).
- Every value is HTML-encoded, and artifact links are percent-encoded.
- Light and dark colour schemes.
- Each status shows text and a symbol, not colour alone. Amber and red conditions are never styled green.
- Pre-Sales stdout echoes the full result document, so it stays in `stdout.log` and is not copied into the HTML.

I visually inspected the QuickCheck and MS04Demo reports in the in-app browser at 740 px and 1100–1280 px widths. No screenshots are committed.

### Safety

**Output-path guard.** The guard resolves symbolic links in every existing path component, then compares paths case-insensitively. It rejects any of these with exit 6, before anything is written:
- an output root inside the repository, source, Runtime JSON folder, expected-document folder or a corpus;
- a relative path;
- a path containing `..`;
- a path that is an existing file.

**Immutability gate.** It re-hashes:
- every input;
- the source (file or directory tree);
- `tests/fixtures`, the oracle, `config`, `engine` and `scripts`;
- `git status`, read with `--no-optional-locks` so the index is not refreshed.

**Repository state.** The runner never checks out, pulls, resets, installs or downloads.

**User settings.** Optional local settings are read from `~/.config/emas/ms04-demo-runner.json`, which is untracked and outside the repository. The runner only reads this file and accepts only 4 keys; any other key gives exit 6.

## Runtime evidence at `b6053d1` (macOS, pwsh 7.5.2)

The worktree was clean (0 entries) before and after the whole evidence set, and HEAD was unchanged. All runs used `-NoUserSettings` and the default output root `~/eMAS-MS04-Runs`.

### Runner modes

| Run (folder under `~/eMAS-MS04-Runs/`) | Command (`tools/demo/Invoke-eMASMS04Demo.ps1 …`) | Result |
|---|---|---|
| `20261008-225856-QuickCheck-4746dd22` | `-Mode QuickCheck` | **PASS_WITH_SKIPS**, exit 2, 14.3 s (detail below) |
| `20261008-225910-QuickCheck-020135e2` | `-Mode QuickCheck -Wave1CorpusRoot <W1>` | **PASS**, exit 0. T2 22/22, T4 28/28, oracle 23/23. This is QuickCheck coverage only, not full regression. |
| `20261008-225926-FullRegression-f267d9a7` | `-Mode FullRegression` | **PASS_WITH_SKIPS**, exit 2 (detail below) |
| `20261008-225943-FullRegression-4317a6c6` | `-Mode FullRegression -Wave1CorpusRoot <W1> -Wave1DCorpusRoot <W1D>` | **PASS**, exit 0, 96.4 s (table below) |
| `20261008-230119-MS04Demo-a263c5ac` | `-Mode MS04Demo -SourcePath <SD-063 fixture.zip>` | **BLOCKED**, exit 4. Evidence `EXECUTED_UNVERIFIED`. Identification and verification `BLOCKED` (not executed). |
| `20261008-230120-MS04Demo-3990fc9e` | `… -RuntimeConfigurationPath tests/fixtures/runtime-config/invalid-malformed.json` | **FAIL**, exit 1 (detail below) |
| `20261008-230122-MS04Demo-c9aeacdb` | `… -RuntimeConfigurationPath <oracle IDO-01 runtime-config.json> -SubmissionUnitXmlInventory Include` | **EXECUTED_UNVERIFIED**, exit 3 (detail below) |

**QuickCheck without corpus.**
- Freeze manifests: SUXI 22/22 and WAVE1E 22/22 rows verified.
- T2: 21/22 passed, 1 skipped (`[SKIP] SD-090 (design) mixed v3/v4…`).
- T4 engine 28/28; oracle 23/23.
- Immutability PASS.

**FullRegression without corpora.**
- Executed and PASS: T2 (21 + 1 SKIP), T4 28/28, oracle 23/23, T1b 10/10, W1E 24/24.
- 11 suites `SKIP` with the cause stated: W1 RD, BXI, RI, RR, MRI, DCC, CMI, CEC, W1D, ROOT, B3.
- The run does not claim 15/15.

**FullRegression with corpora** (wall time 96.4 s; durations rounded):

| Stage | Result | Freeze gates observed | Duration |
|---|---|---|---|
| T2-SUXI | 22/22 | 22 fixture files | 2.9 s |
| T4-ENGINE | 28/28 | — | 5.4 s |
| T4-ORACLE | 23/23 | — | 6.9 s |
| W1-RD | 13/13 | 19/19 | 4.4 s |
| W1-BXI | 24/24 | 19/19 | 5.8 s |
| W1-RI | 28/28 | 19/19 | 7.5 s |
| W1-RR | 31/31 | 19/19 | 8.5 s |
| W1-MRI | 33/33 | 19/19 | 6.5 s |
| W1-DCC | 37/37 | 19/19 | 10.9 s |
| W1-CMI | 54/54 | 19/19 | 10.1 s |
| W1-CEC | 62/62 | 19/19; Wave1E 22/22 | 12.2 s |
| T1B | 10/10 | 11/11 | 0.4 s |
| W1E | 24/24 | 22 | 1.0 s |
| W1D | 61/61 | — | 8.8 s |
| ROOT | 3/3 | — | 2.0 s |
| B3 | 12/12 | — | 1.8 s |

All corpus and repository-tree hashes were unchanged after the run.

**MS04Demo with invalid Runtime JSON.**
- Evidence: `EXECUTED_UNVERIFIED`.
- Identification: `FAIL`. The real Pre-Sales script exited 1 with `CFG-FILE-009 Runtime configuration contains malformed JSON…`, and no Identification document was written.
- Verification: `BLOCKED`.

**MS04Demo with the synthetic oracle config.**
- A real `Identification/1.0` document was produced:
  - `ConfigurationId=ORACLE_IDO_01`, `ExportType=DEV`, Runtime JSON SHA-256 `d02d0c14…7751b`;
  - 1 result: TECHNICAL_STANDARD `InsufficientEvidence`, `UNKNOWN`.
- The report states that the export is not an approved release configuration, and that T4 projection v1 does not consume the T2 types.
- Verification: `BLOCKED` (no expected document).
- Evidence stage observed: `CompletedWithCollectionGaps`, 1 dossier, 1 sequence, 6 evidence records, 1 SUXI document, 0 `Ectd4*` records. These are factual scanner counts only; the runner does not interpret them.

### Repository tree hashes (the same before and after every run above)

| Tree | Files | SHA-256 (runner tree digest) |
|---|---|---|
| `tests/fixtures` | 104 | `0e9f7151…a5ae5b` |
| oracle | 74 | `175dc02d…333097` |
| `config` | 124 | `781bf731…c8da0` |
| `engine` | 27 | `f4b4d8fb…2caea4` |
| `scripts` | 5 | `d4b6b661…b5f36` |

### Runner test suite

```bash
pwsh -NoProfile -NonInteractive -File tests/demo-runner/Test-eMASMS04DemoRunner.ps1 -OutputRoot ~/eMAS-MS04-Runs/_runner-tests-b6053d1-corpora -Wave1CorpusRoot <W1> -Wave1DCorpusRoot <W1D>
```

| Variant | Result |
|---|---|
| With corpora | **24 total, 24 passed, 0 failed, 0 skipped**, exit 0 |
| Without corpora | **24 total, 23 passed, 0 failed, 1 skipped** (RT-03 SKIP: corpora not supplied), exit 0 |

Mapping to the task's required tests:

| Task test | Runner checks | Covered | Result |
|---|---|---|---|
| 1 | RT-01, plus the fresh clone below | QuickCheck without corpora: 21+1 SKIP / 28 / 23; HTML and manifest outside the checkout; IMMUTABILITY PASS | PASS |
| 2 | RT-02 | FullRegression without corpora: 11 SKIP with cause, 5 executed, exactly 15 established gates listed | PASS |
| 2 | RT-03 | With corpora: 16 harness stages executed, T2 22/22, corpora unchanged | PASS with corpora, SKIP without |
| 2 | RT-04 | Supplied but missing corpus path: dependent suites and preflight BLOCKED, T1b still PASS | PASS |
| 3 | RT-05 | No Runtime JSON, passed as empty strings exactly as VS Code sends them: identification BLOCKED, no `identification.json` | PASS |
| 4 | RT-06 | Invalid JSON: real loader `CFG-FILE-009` preserved, identification FAIL, no document fabricated | PASS |
| 5 | RT-07 | Valid synthetic test-only config: real script runs, `EXECUTED_UNVERIFIED`, never VERIFIED; source ZIP hash unchanged | PASS |
| 5 | RT-08 | Mismatching independent expected document gives verification FAIL with path-level differences | PASS |
| 5 | RT-09 | Comparator: volatile fields and key order ignored; value and array-order changes detected; verdict VERIFIED only on equality; a failed gate overrides VERIFIED | PASS |
| 5 | RT-24 | Directory source runs; directory tree unchanged | PASS |
| 6 | RT-10 | Hostile `<script>`, `<img onerror>`, `<svg>`, `<iframe>`, `<?xml`, `& " '` in paths, diagnostics, ids and XML-derived values are all encoded; CSP present; links percent-encoded | PASS |
| 6, 8 | RT-11 | End-to-end source and output paths with spaces, Unicode (`ü`, `試験`) and `<b>&"'` | PASS |
| 7 | RT-12 | Non-zero exit after printed passes is FAIL; stderr preserved verbatim | PASS |
| 7 | RT-13 | `[FAIL]` with exit 0 is FAIL ("despite process exit code 0") | PASS |
| 7 | RT-14 | Timeout (3 s) kills the process tree; FAIL | PASS |
| 7 | RT-15 | SKIP gives PASS_WITH_SKIPS; no result line gives UNVERIFIED; fewer tests than baseline gives FAIL (count drift) | PASS |
| 7 | RT-16 | Arguments such as `$(whoami)`, `;echo pwned`, `&&`, `\|`, `*`, backticks, quotes and Unicode arrive verbatim; no shell evaluation | PASS |
| 7 | RT-17 | Interruptions (detail below) | PASS |
| 8 | RT-18 | Output guard: 9 rejection cases including the symlink escape into the repository and an upper-cased repository path; runner exits 6 and creates nothing in the repository | PASS |
| 8 | RT-19 | Unique run directories; an existing directory is never reused; 50 ids generated in the same second are distinct | PASS |
| — | RT-20 | Unsupported settings key or missing explicit settings file gives exit 6 with no run directory | PASS |
| 8 | RT-21 (static only) | No web or download cmdlets, `Invoke-Expression`, shell launch or URLs in runner files | PASS |
| — | RT-22 (static only) | VS Code tasks: the three labels, `type: process`, no personal paths, Quick Check needs no input | PASS |
| 8, 9 | RT-23 | HEAD, `git status`, `tests/fixtures` and oracle unchanged by the whole suite | PASS |

RT-17 interruption detail:
- **SIGINT** gives `Interrupted` / `INCOMPLETE` and exit 5. The running stage is FAIL ("Interrupted while running"), the remaining stages are NOT_RUN, and the child harness is killed.
- **SIGKILL** leaves the last saved manifest at `InProgress` / `INCOMPLETE`.

### Clean Mac clone (task test 1)

The branch was cloned fresh from GitHub at `b6053d1` into `/private/tmp/emas fresh clone ü/eMAS`, a path with a space and Unicode. Scripts are CRLF via `.gitattributes`. No corpora and no settings file were present.
- **QuickCheck:** **PASS_WITH_SKIPS**, exit 2, worktree clean at start, clone unchanged afterwards. Evidence: `~/eMAS-MS04-Runs/_fresh-clone/20261008-225908-QuickCheck-f4825c06/`.
- **VS Code task definitions:** I executed the exact `args` of each task in `.vscode/tasks.json` as a no-shell process, with `${workspaceFolder}` and the `${input:*}` answers substituted. This is not a click in the VS Code UI.

| Task | Result |
|---|---|
| Quick Check | exit 2, PASS_WITH_SKIPS |
| Full Regression | exit 2, PASS_WITH_SKIPS (no settings file, so corpus suites SKIP) |
| Demo (SD-063 ZIP, empty optional answers) | exit 4, BLOCKED |

### Static checks

- The PowerShell language parser reports 0 parse errors in all 6 new PowerShell files.
- PSScriptAnalyzer is **not installed** on this Mac, and I did not install it, so analyzer status is **UNVERIFIED**.

## Defects found and fixed during development

None of these remain at `b6053d1`. All were found by running the code.

1. **Empty arrays and StrictMode.** An empty array returned from a function became `$null`, and StrictMode then threw on `.Count`. This caused a runner error during the first demo runs. The runner-error path correctly recorded `INCOMPLETE`.
2. **Double-wrapped array.** A comma-return combined with `@()` at the call site wrapped an empty array as a one-element array. That marked successful evidence stages FAIL with no reason. Fixed before commit.
3. **JSON depth.** `ConvertTo-Json -Depth 128` exceeded PowerShell's maximum of 100 during verification. It surfaced as `INCOMPLETE` with the error recorded.
4. **Ctrl+C exit code.** pwsh exits 0 when Ctrl+C stops a `-File` script. The runner now writes the evidence and exits 5 explicitly.
5. **Trailing separator.** `Get-eMASRealPath` returned a trailing separator for a not-yet-existing tail (caught by RT-18).
6. **ANSI codes.** Child error output contained ANSI codes. Fixed with `NO_COLOR=1` for children, and escape codes are stripped in report diagnostics. Raw logs are kept as produced.

Test-only fixes from the first full suite pass:
- RT-05 needed `[AllowEmptyString()]`.
- RT-11's expectation was wrong: `HtmlEncode` correctly writes `ü` as `&#252;`, so the check now decodes the HTML and compares.
- RT-16's stub needed `PositionalBinding = $false`.

## Remaining blockers and open items

1. **MS-04 business identification cannot be VERIFIED. This is BLOCKED.**
   - There is no approved MS-04 Runtime JSON: `config/runtime/development` holds only `.gitkeep`.
   - There is no independently established expected `Identification/1.0` outcome for any committed dossier.
   - The oracle cases are observation-level (`scanner-observations.json`), not dossier-level, so no compatible dossier + Runtime JSON + expected-outcome set exists.
   - As instructed, I did not author a ruleset or an expected result.
   - The VERIFIED path is proven only through the comparator and verdict units (RT-09) and the mismatch case (RT-08).
   - To unblock: the user or central supplies an approved Runtime JSON and an independent expected document for a named dossier.
2. **Comparison-profile decision for central review.** On the dossier route, `EvidenceSource.DocumentSha256` hashes the in-memory, timestamped evidence document, so it changes on every run. I observed this directly: two identical runs differed only in that field and the oracle's volatile fields. The demo comparison therefore removes it, along with the runner-assigned `ExecutionId` fields and the oracle's three volatile fields. Central review should confirm or change this profile. The source hash is recorded separately in the manifest.
3. **External corpora are local and temporary.**
   - Wave 1 is at `/private/tmp/emas-t1b-wave1-ref`, which symlinks to `02_Working/MS-04-PreSales-Wave1/fixtures`.
   - Wave1D is at `/private/tmp/emas-ectd4-baseline.e3oYH2/wave1d/…`.
   - `/private/tmp` can be cleared on reboot. A durable location should be set in `~/.config/emas/ms04-demo-runner.json`.
   - CI has no corpora, so the SD-090 mixed check and the 11 corpus suites remain SKIP there.
4. **`.vscode/tasks.json` is force-added** (see Changed files). Central review should confirm this, or authorize a `.gitignore` exception.
5. **SIGKILL limitation.** A runner killed with SIGKILL cannot terminate a child that is still running. That harness may finish and write only into its own stage folder. The manifest stays `INCOMPLETE`.
6. **Out of scope and unchanged:**
   - Windows PowerShell 5.1 and 7.6 qualification of the runner (not attempted; the runner needs PowerShell 7);
   - native PS5.1 T1b qualification;
   - the unrelated PS5.1 RuntimeConfiguration UTF-8 CI expectation;
   - the RD/BXI path-alias limitation;
   - FDA D-3;
   - the `.command` launcher, XLSX report and UI.
7. **No CI change.** The runner's tests are not wired into `.github/workflows/**`, which is outside the allowlist. They were run locally only.

The PR stays draft. Neither the worker nor the demo branch is merged. ChatGPT reviews the fixed PR head, and the user decides any merge.
