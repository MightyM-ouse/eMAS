# Claude Report — T4b IdentificationInterpretation Engine Continuation

**Status:** `READY_FOR_CENTRAL_REVIEW`
**Branch:** `implementation/emas-ms04-identification-interpretation-engine`
**PR:** [MightyM-ouse/eMAS#56](https://github.com/MightyM-ouse/eMAS/pull/56) (draft, not merged)
**Implementation commit:** `ccce071a33aba8e4d11dac009801e74deee88189`
**Accepted T4a oracle:** `ce8d56c0df59d7e8635207baec853b07f17462de` (read-only)

The historical record of the initial implementation is in `CODEX.md`, which is unchanged. This report covers only the central-review items E-2 to E-4 and the continuation handoff.

## 1. Files changed

| File | Change |
|---|---|
| `engine/core/eMAS.IdentificationInterpretation.psm1` | `MATCHES_PATTERN`; the strength-order/floor invariant code is renumbered; EngineVersion is now `0.2.0` |
| `scripts/eMAS-PreSalesAssessment.ps1` | Identification-only short pipeline |
| `tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1` | 7 focused tests: 6 for the pattern operator, 1 for the short pipeline |
| `tests/identification-interpretation/engine/Test-eMASIdentificationOracleConformance.ps1` | Runs `Failure` cases as well as output cases |
| `.github/workflows/powershell-runtime-contracts.yml` | Oracle step on all three PowerShell lanes; trigger path `tests/identification-interpretation/**` |

Nothing under `tests/identification-interpretation/oracle/**`, the T4a `BEHAVIOR_CONTRACT.md`, `engine/powershell51/**`, `engine/powershell7/**`, `config/**`, `build/**` or the test fixtures changed. The T4a files are byte-identical to `ce8d56c`. The other paths are unchanged from `cff3456`.

## 2. E-2 — `MATCHES_PATTERN` (contract §6.1, I2)

**Implementation:**
- `New-eMASIdentificationPatternRegex` constructs `System.Text.RegularExpressions.Regex` with explicit options and a timeout:
  - always `RegexOptions.CultureInvariant`;
  - `RegexOptions.IgnoreCase` added only when `caseSensitive = false`;
  - no other options;
  - match timeout of `[TimeSpan]::FromSeconds(1)`.
- `Test-eMASIdentificationPatternMatch` calls `.IsMatch(value)`. Matching is unanchored, so authors anchor with `^…$`.
- No PowerShell `-match`, `-imatch`, `-cmatch` or `Select-String` is used. A focused test checks the three pattern functions with the PowerShell parser (AST) to enforce this.

**Evaluation states (M2):**
- An Available String value gives True or False.
- An Available value that is not a String gives False.
- AssessedAbsent gives False.
- Unavailable gives Unknown.
- `negate` inverts True/False. A negated pattern is a guard and is never cited as evidence (P4).

**Failure handling (I2, M3):**

| Situation | Code | When |
|---|---|---|
| Field `dataType` is not `String` | `IDI-CONFIG-004` | Configuration validation |
| `value1` is null, empty or not a string, or `valueDataType` is not `String` | `IDI-CONFIG-005` | Configuration validation |
| Construction throws `ArgumentException` (`RegexParseException` on .NET 5+) | `IDI-CONFIG-005` | Configuration validation |
| `RegexMatchTimeoutException` during `IsMatch` | `IDI-CONFIG-006` | Evaluation; the run fails |

- Every `MATCHES_PATTERN` condition of every active Pre-Sales IDENTIFICATION rule is compiled before any rule is evaluated. A rule that would never be reached still fails the run.
- The exception check walks `InnerException`, because PowerShell can wrap constructor exceptions in `MethodInvocationException`. That keeps the check the same on PS5.1 and PS7.6.
- Each message names the `RuleId` and `ConditionId`.
- No Identification document is written: validation runs before the output path is used.

**Code renumbering:** the initial implementation used `IDI-CONFIG-005` for the engine-internal "EVIDENCE_STRENGTH must order STRONG < MEDIUM < WEAK / invalid floor" guard. The contract now reserves `005` for invalid patterns, so that guard moves to `IDI-CONFIG-007`. The contract does not specify this code; it is an engine-internal invariant on already validated input.

## 3. E-3 — Identification-only short pipeline

`scripts/eMAS-PreSalesAssessment.ps1` decides the chain after BackboneXmlInventory:

```text
$deepCheckRequested = ReferenceInventory | ReferenceResolution | MissingReferenceInterpretation
                      | DeclaredChecksumComparison | ChecksumMismatchInterpretation   (explicit switches)
Identification and not deepCheckRequested:
    RepositoryDiscovery → BackboneXmlInventory → ClassificationEvidenceCollection → IdentificationInterpretation
otherwise:
    the existing chain, unchanged
```

- The accepted CEC module needs only the RepositoryDiscovery and BackboneXmlInventory capabilities (`CEC-INPUT-003`). The short chain therefore uses CEC unchanged.
- Adding `-IncludeClassificationEvidenceCollection` next to Identification also uses the short chain, because it is not a deep switch.
- When a caller explicitly sets a deep switch, the existing order runs as before, and Identification still writes the terminal `OutputPath`.
- Modes without Identification (CEC alone, or any single capability) keep their earlier behaviour. CEC alone still traverses the deep chain, as accepted in T1a; changing that is outside T4b.
- `scripts/eMAS-PreSalesAssessment.ps1` is a path in the RC1 baseline `.gitattributes` list (`-text`, LF). That file already diverged from the RC1 package when T4b first added the opt-in switch. This bounded change is the integration TASK.md allows.

**Focused test:** "Pre-Sales Identification-only mode skips reference and checksum capabilities".
- It mirrors the entry script with the real RepositoryDiscovery, BackboneXmlInventory, CEC, RuntimeConfiguration and Identification modules.
- The five deep capability modules are replaced by tracing stubs that record each call and pass the previous result through.
- It asserts:
  1. `-IncludeIdentificationInterpretation` alone returns and persists Identification/1.0 and calls **no** deep capability;
  2. `-IncludeClassificationEvidenceCollection -IncludeIdentificationInterpretation` also calls none;
  3. `-IncludeDeclaredChecksumComparison -IncludeIdentificationInterpretation` calls all five, in order: ReferenceInventory, ReferenceResolution, MissingReferenceInterpretation, DeclaredChecksumComparison, ChecksumMismatchInterpretation.

## 4. E-4 — Accepted oracle and CI

**Harness** (`Test-eMASIdentificationOracleConformance.ps1`):
- reads `manifest.json` and each fixture **from the oracle files**;
- passes the exact scanner-file SHA-256 as `EvidenceSourceSha256`;
- removes only `EngineVersion`, `StartedAtUtc` and `CompletedAtUtc`, then compares semantic JSON.

For `Failure` cases, the harness requires:
- the stated `ErrorCode` as the message prefix;
- the `RuleId` and `ConditionId` in the message;
- no output file, even though an `OutputPath` is supplied.

After every case, it re-checks the scanner object, the config object and the fixture file hashes. Oracle files are only read.

**CI:** the step `Run accepted T4a oracle conformance (read-only, 23 cases)` runs with `if: always()` in:
- `windows-powershell-51-contracts`;
- `windows-powershell-76-contracts`;
- `macos-powershell-76-development-contracts`.

It reports as its own step, so the known PS5.1 UTF-8 assertion in `Test-eMASRuntimeConfiguration.ps1` cannot hide it. The engine-test steps on the 7.6 lanes now also use `if: always()`. The oracle JSON is `eol=lf` in `.gitattributes`, so Windows checkouts keep the fixture hashes.

## 5. Results

### Local (macOS, PowerShell 7.5.2 / Python 3.11)

The local development pwsh is 7.5.2. The 7.6 lanes are checked in CI (§5.2).

| Check | Result |
|---|---|
| Focused T4b engine tests | **PASS — 28/28** (21 existing + 7 new) |
| Accepted T4a oracle | **PASS — 23/23** (22 output, 1 expected-failure) |
| Short-pipeline orchestration test | PASS (included in the 28) |
| Oracle static validation / unittest | PASS — 23 cases / 14 OK |
| RuntimeConfiguration PowerShell | PASS — 28/28 |
| Schema fixture validation | PASS — 43/43 |
| Schema Python tests | PASS — 44 OK |
| Runtime static tests | PASS — 12 OK |
| T3b XLSM/VBA validator / VBA+export tests | PASS / 22 OK |
| Report mappings / reporting tests | PASS / 28 OK |
| Operational skills | PASS — validator, 3 OK |
| Wave 1 RepositoryDiscovery → CEC (8 suites, frozen corpus) | PASS — all 8 |
| Root-level dossier / RD B3 / eCTD v4 discovery | PASS / 12/12 / 22/22 + 2/2 |
| Dossier diversity (Wave1D SD-044–SD-051) | NOT RUN — external corpus not in workspace (same as CODEX.md) |
| T3b native Excel POC (`build/Test-eMASMappingPoc.ps1`) | NOT RUN — needs Windows desktop Excel |

### CI by runtime

Workflow **PowerShell runtime contracts**, run `37530248171`, head `ccce071`:

| Lane | RuntimeConfiguration | T4b engine tests | Accepted T4a oracle | Job |
|---|---|---|---|---|
| Windows PowerShell 5.1 | 27/28: only the known unrelated `UTF-8 metadata is preserved` assertion fails | **PASS 28/28** | **PASS 23/23** | red, from the known UTF-8 step only |
| Windows PowerShell 7.6 | PASS 28/28 | **PASS 28/28** | **PASS 23/23** | green |
| macOS PowerShell 7.6 (development) | PASS 28/28 | **PASS 28/28** | **PASS 23/23** | green; schema/runtime Python also green |
| Static runtime contracts (Ubuntu) | — | — | — | green |

Because the oracle runs as its own `if: always()` step, its result is visible even on the PS5.1 job.

## 6. Immutability

- `git diff ce8d56c -- tests/identification-interpretation/oracle docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE` is empty.
- `git diff cff3456 -- engine/powershell51 engine/powershell7 config build templates tests/fixtures tests/classification-evidence-collection` is empty.
- On every oracle case, the harness confirms that the scanner input object, the runtime-configuration object and both fixture file hashes are unchanged.
- The focused tests also confirm that scanner evidence and config are not mutated, and that raw CEC strength is not rewritten.

## 7. Provenance

This follows contract §13 / REVIEW A-3:
- **Script path and oracle harness:** use the exact ScannerObservations file hash when one is supplied.
- **In-memory input without a file hash:** use the SHA-256 of a deterministic serialization, as the evidence-document identity.
- **What it is not:** in neither case is the hash proof of the original customer repository; that remains the scanner's `Repository` provenance.

## 8. Open items

- **No blocker** for central review.
- **`IDI-CONFIG-007`** is an engine-internal code that the T4a contract does not list (§2). Central review may want it recorded in a later contract revision.
- **Known PS5.1 UTF-8 failure:** out of scope and unchanged.
- **Wave1D dossier-diversity regression:** needs the external corpus.
- **Native Excel POC:** needs Windows Excel.
