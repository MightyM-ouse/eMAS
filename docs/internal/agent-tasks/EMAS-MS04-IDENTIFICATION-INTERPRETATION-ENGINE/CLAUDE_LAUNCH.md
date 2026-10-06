# Claude Launch — T4b IdentificationInterpretation Engine Continuation

Work on:

`EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE`

Repository:

`MightyM-ouse/eMAS`

Continue on the existing branch:

`implementation/emas-ms04-identification-interpretation-engine`

Existing draft PR:

`#56` into `coordination/emas-ms04-identification-interpretation`

Read first:

- this task's `TASK.md`
- `STATUS.md`
- `reports/CODEX.md` as historical implementation context
- `reports/REVIEW.md`
- accepted T4a `BEHAVIOR_CONTRACT.md`
- accepted T4a oracle manifest and README
- T1a/T3/T3a/T3b accepted reports/reviews
- current engine module and focused tests
- current Pre-Sales script integration
- current RuntimeConfiguration API

The branch has already been synchronized with the accepted T4a oracle.

Accepted T4a merge SHA:

`ce8d56c0df59d7e8635207baec853b07f17462de`

T4b sync merge SHA:

`15964bf6ec8b0917de6eb0d83d4ed472c9849d2d`

You are now the **single continuation implementation owner**.

The oracle is frozen. Do not modify:

- `tests/identification-interpretation/oracle/**`
- T4a `BEHAVIOR_CONTRACT.md`
- T4a expected outcomes

Implement only the remaining central-review items.

## Required fixes

### 1. MATCHES_PATTERN

Implement exactly the accepted T4a behavior:

- explicit `System.Text.RegularExpressions.Regex`
- `CultureInvariant`
- add `IgnoreCase` only when `caseSensitive = false`
- 1-second timeout
- unanchored `IsMatch`
- String fields only
- validate every Identification MATCHES_PATTERN condition before rule evaluation
- invalid/null/empty/non-String pattern config → `IDI-CONFIG-005`
- timeout → `IDI-CONFIG-006`
- do not use PowerShell `-match`
- do not add GT/GTE/LT/LTE/BETWEEN

Pass accepted oracle cases IDO-22 and IDO-23.

### 2. Identification-only short pipeline

Fix `scripts/eMAS-PreSalesAssessment.ps1`.

When only `-IncludeIdentificationInterpretation` is requested, the execution chain must be:

`RepositoryDiscovery → BackboneXmlInventory → ClassificationEvidenceCollection → IdentificationInterpretation`

It must **not** implicitly execute:

- ReferenceInventory
- ReferenceResolution
- MissingReferenceInterpretation
- DeclaredChecksumComparison
- ChecksumMismatchInterpretation

Those capabilities run only when explicitly requested.

Preserve existing behavior when deeper switches are explicitly selected.

If a safe bounded script refactor cannot achieve this, remove/defer the script integration rather than forcing deep checks.

Add a focused test proving Identification-only mode skips the deep chain.

### 3. Formal accepted-oracle conformance

Run every accepted T4a case:

- 22 output cases
- 1 expected-failure case

Treat oracle files as read-only.

The result must be:

`23/23 PASS`

If an implementation result disagrees with the oracle, fix the engine unless you can demonstrate a genuine contradiction in the accepted contract. Do not edit the oracle.

### 4. CI

Wire the read-only oracle conformance harness into:

- Windows PowerShell 5.1
- Windows PowerShell 7.6
- macOS PowerShell 7.6 development lane

The oracle step must report independently from the known unrelated PS5.1 UTF-8 RuntimeConfiguration failure.

### 5. Provenance wording

Keep the accepted convention:

- exact ScannerObservations file SHA-256 when available
- deterministic serialization hash only for in-memory input without a supplied file hash
- never describe that hash as proof of the original customer repository

## Regression

Run and report:

- focused T4b engine tests
- accepted oracle 23/23
- short-pipeline orchestration test
- RuntimeConfiguration PowerShell tests
- Schema tests
- CEC tests
- T3b POC tests
- scanner regressions affected by script changes
- macOS PS7.6
- Windows PS7.6
- Windows PS5.1 focused T4/oracle results

Do not fix the unrelated Windows PS5.1 UTF-8 expectation in this task.

## Report

Write:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE/reports/CLAUDE.md`

Keep `reports/CODEX.md` unchanged as historical evidence.

Update `STATUS.md`.

Do not merge PR #56.

Return only:

- branch
- commit SHA
- PR #56 link
- engine files changed
- MATCHES_PATTERN implementation summary
- invalid-regex/timeout behavior
- short-pipeline implementation
- focused engine test result
- accepted oracle result
- CI result by runtime
- scanner/config/oracle immutability result
- remaining blocker/open issue
