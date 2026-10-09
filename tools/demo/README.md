# MS-04 Mac demo runner

`Invoke-eMASMS04Demo.ps1` runs the existing MS-04 Pre-Sales harnesses and the real `scripts/eMAS-PreSalesAssessment.ps1` with one command. It writes an HTML summary and a JSON manifest for each run.

The runner is an orchestrator only. It does not assess dossiers, generate Runtime JSON or apply business rules. Every check it reports was run by an existing, committed harness or by the Pre-Sales script, each in its own `pwsh -NoProfile -NonInteractive -File` process.

> **Scope:** this is macOS PowerShell 7 *development verification*. A Mac run does not qualify Windows PowerShell 5.1. A green run is not a regulatory compliance statement.

## One-click use in VS Code

Open the repository folder in VS Code and choose **Terminal → Run Task…**:

| Task | What it does | Input needed |
|---|---|---|
| **eMAS: MS-04 Quick Check** | Preflight, committed freeze manifests, focused T2, T4 engine 28/28, T4 oracle 23/23 | None |
| **eMAS: MS-04 Full Regression** | The 15 established gates plus focused T2 | None. Corpora are read from the optional settings file (see below). |
| **eMAS: MS-04 Demo** | The real Pre-Sales evidence and identification routes on a dossier you choose | Dossier path. Runtime JSON and expected outcome are optional. |

The terminal ends with a `RESULT:` banner, followed by the paths to `summary.html` and `run-manifest.json`. In the VS Code terminal, Cmd-click the `file://` link to open the report.

**How VS Code shows the result.** The tasks pass `-ExitCodePolicy Task`. VS Code treats any non-zero exit as "task failed", so under this policy a run that completed without a failure exits 0. That covers `PASS`, `VERIFIED`, `PASS_WITH_SKIPS` and `EXECUTED_UNVERIFIED`. Read the `RESULT:` banner and the report for the actual, qualified result:
- `PASS_WITH_SKIPS` is printed as "not an unqualified PASS".
- `EXECUTED_UNVERIFIED` is printed as "not a PASS".

`FAIL`, `BLOCKED`, `UNVERIFIED` and `INCOMPLETE` still exit non-zero, so VS Code marks them failed. The manifest keeps `OverallStatus` unchanged and records both `ExitCode` and `StrictExitCode`.

The task definitions were exercised by running their exact command lines. Clicking them in the VS Code UI has not been tested.

Prerequisites:
- PowerShell 7 (`pwsh`) on `PATH`;
- a checkout of this repository.

Python, Excel, Docker, npm and extra PowerShell modules are not needed. Nothing is downloaded.

## Command line

```bash
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode QuickCheck
```

```bash
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode FullRegression -Wave1CorpusRoot ~/eMAS-corpora/wave1 -Wave1DCorpusRoot ~/eMAS-corpora/wave1d
```

```bash
pwsh -NoProfile -File tools/demo/Invoke-eMASMS04Demo.ps1 -Mode MS04Demo -SourcePath ~/dossiers/example.zip -RuntimeConfigurationPath ~/configs/runtime.json -ExpectedIdentificationPath ~/configs/expected-identification.json
```

| Parameter | Meaning |
|---|---|
| `-Mode` | `QuickCheck` (default), `FullRegression` or `MS04Demo` |
| `-OutputRoot` | Parent folder for run folders. Default `~/eMAS-MS04-Runs`. |
| `-Wave1CorpusRoot` | External frozen Wave 1 corpus (`fixtures/SD-0nn/fixture.zip` plus `WAVE1_FREEZE_MANIFEST.csv`) |
| `-Wave1FreezeManifestPath` | Overrides `<Wave1CorpusRoot>/WAVE1_FREEZE_MANIFEST.csv` |
| `-Wave1DCorpusRoot` | External Wave1D package (contains `WAVE1D_FREEZE_MANIFEST.csv`) |
| `-SourcePath` | Demo dossier: a folder or a `.zip` |
| `-RuntimeConfigurationPath` | Demo Runtime JSON. Without it, identification is BLOCKED. |
| `-ExpectedIdentificationPath` | Independent expected `Identification/1.0` document. Without it, the demo cannot be VERIFIED. |
| `-SubmissionUnitXmlInventory` | `Include` requests the T2 capability (default `Exclude`) |
| `-ExecutionId` | Demo execution id. Generated if omitted. |
| `-StageTimeoutSeconds` | Per-stage limit (default 1800). The process tree is terminated when it is exceeded. |
| `-UserSettingsPath` / `-NoUserSettings` | Choose or ignore the settings file |
| `-OpenReport` | Open `summary.html` when the run ends. A failure to open never changes the verdict. |
| `-ExitCodePolicy` | `Strict` (default, for scripts and CI) or `Task` (used by the VS Code tasks; see below) |

Paths must be absolute or start with `~/`. Surrounding quotes from pasted paths are removed. Paths containing `..` segments are refused.

### Optional local settings (untracked)

To avoid typing corpus paths, create `~/.config/emas/ms04-demo-runner.json` outside the repository:

```json
{
  "Wave1CorpusRoot": "/Users/me/eMAS-corpora/wave1",
  "Wave1DCorpusRoot": "/Users/me/eMAS-corpora/wave1d",
  "OutputRoot": "/Users/me/eMAS-MS04-Runs"
}
```

Only `OutputRoot`, `Wave1CorpusRoot`, `Wave1FreezeManifestPath` and `Wave1DCorpusRoot` are accepted; the runner refuses any other key. Explicit parameters override the file. The runner only reads this file.

## Results

| Status | Meaning |
|---|---|
| `PASS` | Ran, and the harness's own structured result matched the expected counts. Read-only gates held. |
| `PASS_WITH_SKIPS` | Every executed check passed, but some checks or stages were skipped. This is **not** an unqualified pass. |
| `SKIP` | Not run because an optional external input was not supplied. The reason names it. |
| `BLOCKED` | Not run because a supplied input was invalid, or a prerequisite (such as Runtime JSON) is missing |
| `FAIL` | Covers any of: a non-zero exit, a timeout, an interruption, a harness-reported failure (even with exit code 0), count drift, a changed input, or a verification mismatch |
| `UNVERIFIED` | The process exited 0, but no structured harness result could be read |
| `EXECUTED_UNVERIFIED` | The demo route ran and produced its contract document, but no independent expected outcome verified it |
| `VERIFIED` | The demo's `Identification/1.0` output equals the supplied independent expected document |
| `INCOMPLETE` | The run was interrupted, or the runner itself failed. Stages that did not finish are `NOT_RUN`. |

Exit codes:

| Result | `Strict` (default) | `Task` (VS Code) |
|---|---|---|
| PASS / VERIFIED | 0 | 0 |
| PASS_WITH_SKIPS | 2 | 0 |
| EXECUTED_UNVERIFIED | 3 | 0 |
| UNVERIFIED | 3 | 3 |
| FAIL | 1 | 1 |
| BLOCKED | 4 | 4 |
| INCOMPLETE | 5 | 5 |
| Refused before a run folder was created (unsafe output path, bad settings) | 6 | 6 |

The policy changes only the process exit code. `OverallStatus`, the report and the manifest are identical under both policies, and skipped checks are never counted as passed.

A QuickCheck on a checkout without the external Wave 1 corpus is `PASS_WITH_SKIPS`, because the T2 SD-090 mixed v3/v4 check needs SD-002. That is exit 2 under `Strict` and exit 0 under `Task`.

### Expected counts

Expected counts are listed in `private/eMAS.MS04SuiteCatalog.psd1`. They were taken from the accepted T2 report and confirmed by a direct run.

| Suites | Expected |
|---|---|
| Focused T2 | 21 + 1 SKIP without the corpus; 22/22 with it |
| T4 engine | 28 |
| T4 oracle | 23 |
| T1b | 10 |
| Wave1E | 22 + 2 |
| Wave1D | 61 |
| Root-level | 3 |
| B3 | 12 |
| Wave 1 RD | 13 |
| Wave 1 BXI | 24 |
| Wave 1 RI | 28 |
| Wave 1 RR | 31 |
| Wave 1 MRI | 33 |
| Wave 1 DCC | 37 |
| Wave 1 CMI | 54 |
| Wave 1 CEC | 62 |

Each harness's own freeze-gate counters are also checked, for example 19/19 Wave 1 ZIP hashes.

A different count is reported as `FAIL` (count drift). The runner never relaxes a count silently.

## Evidence layout

Each run creates a new folder, `<OutputRoot>/<UTC yyyyMMdd-HHmmss>-<Mode>-<random>/`. An existing folder is never reused.

```text
run-manifest.json      machine-readable record: Git SHA and worktree state, platform, inputs with SHA-256
                       before/after, every command line, exit codes, durations, counts, statuses, limitations
summary.html           self-contained report: no scripts, fonts or remote resources; all text HTML-encoded
stages/NN-<ID>/        stdout.log, stderr.log, harness-output/ (harness summary JSON) or observed/ (Pre-Sales JSON)
```

`run-manifest.json` and `summary.html` are rewritten after every stage. A run that is killed therefore still shows `INCOMPLETE`, never a pass. Ctrl+C or SIGINT stops the running child process, marks the remaining stages `NOT_RUN`, and exits with code 5.

## Safety

The runner never writes to the repository, the dossier, the Runtime JSON, the expected document, the corpora or Git state. It does not checkout, pull, reset, install or download.

**Output folder.** The output root must resolve, after symbolic links, outside all of these:
- the repository;
- the source;
- the Runtime JSON folder;
- the expected-document folder;
- each corpus.

Otherwise the runner exits with code 6 before creating anything.

**Immutability check.** The last stage, `IMMUTABILITY`, re-hashes:
- every input;
- `tests/fixtures`, the oracle, `config`, `engine` and `scripts`;
- `git status` (read with `--no-optional-locks`).

Any change is reported as `FAIL`.

**Child processes.** They start with an explicit argument list and no shell, and their working directory is inside the run folder. `NO_COLOR=1` is set so that error text stays plain.

**Content in the report.** The HTML shows:
- stage results;
- `[FAIL]`/`[SKIP]` lines and stderr tails;
- counts;
- the identification results table as emitted by the engine.

Pre-Sales stdout echoes the full result document. It is kept in `stdout.log` only and is not copied into the HTML.

## MS04Demo specifics

- **Evidence route:** `-IncludeClassificationEvidenceCollection`, plus `-IncludeSubmissionUnitXmlInventory` when T2 is requested. It writes `ScannerObservations/1.0`.
- **Identification route:** a separate invocation with `-RuntimeConfigurationPath` and `-IncludeIdentificationInterpretation`. It writes `Identification/1.0`. The real loader validates the Runtime JSON; the runner only checks that the file exists.
- **No Runtime JSON in the repository.** There is no approved MS-04 Runtime JSON here, and `config/runtime/development` is empty. The oracle Runtime JSON files under `tests/identification-interpretation/oracle/cases/**` are synthetic test policy. Using one gives `EXECUTED_UNVERIFIED`, never an approved result.
- **T2 facts and identification.** IdentificationInterpretation projection v1 does not consume the eight T2 evidence types.
- **How VERIFIED is decided.** The observed and expected documents are compared as JSON:
  - object key order is ignored;
  - array order is significant.

  These fields are removed from both documents first:
  - the oracle's volatile fields: `Execution.EngineVersion`, `StartedAtUtc` and `CompletedAtUtc`;
  - the runner-assigned `Execution.ExecutionId` and `EvidenceSource.ExecutionId`;
  - `EvidenceSource.DocumentSha256`. It hashes the in-memory, timestamped evidence document, so it differs between otherwise identical runs.

  The expected document must come from you or from an approved source. The runner never generates it from actual output.
- **Verification outcomes.**

  | Expected document | Verification stage | Overall result |
  |---|---|---|
  | Not supplied | `SKIP` | `EXECUTED_UNVERIFIED` |
  | Supplied, but missing, not JSON, or not `Identification/1.0` | `BLOCKED` | `BLOCKED` |
  | Supplied and different from the output | `FAIL` | `FAIL` |
  | Supplied and equal to the output | `VERIFIED` | `VERIFIED`, only if no other stage is `BLOCKED` or `FAIL` |

## Tests

```bash
pwsh -NoProfile -File tests/demo-runner/Test-eMASMS04DemoRunner.ps1 -OutputRoot /tmp/emas-demo-runner-tests
```

Add `-Wave1CorpusRoot` and `-Wave1DCorpusRoot` to include the corpus-backed full regression check. Without them it reports SKIP.
