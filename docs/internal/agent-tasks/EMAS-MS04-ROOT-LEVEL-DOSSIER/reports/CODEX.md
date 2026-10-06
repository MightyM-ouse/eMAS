# Codex Implementation Report

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`

**Agent:** Codex

**Role:** Implementation owner

**Implementation branch:** `implementation/emas-ms04-root-level-dossier`

**Authoritative base commit:** `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`

**Coordination branch start commit:** `001bbe254586c37d0e9d53716f06bb1a14a8a1d0`

**Overall result:** `BLOCKED_BASELINE_NOT_REPRODUCIBLE`

**Implementation performed:** No

## Baseline gate result

The implementation branch was created from `origin/coordination/emas-ms04-root-level-dossier` at `001bbe254586c37d0e9d53716f06bb1a14a8a1d0`. The task's authoritative base commit, `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`, is an ancestor of that coordination commit.

The clean branch does not contain the complete accepted eight-capability RC1 package required by the task's baseline gate. The following required inputs are absent:

- all eight accepted capability modules;
- `engine/powershell51/private/eMAS.SafeXml.ps1`;
- all eight accepted PowerShell regression harnesses;
- all eight Wave 1 expectation files.

The tracked `scripts/eMAS-PreSalesAssessment.ps1` has SHA-256 `c5eecc78ef8f2b2dcf4519b4951ba6bbca74dcb78045be21d5c201f9afa97eeb`, which does not match the internal qualification-package manifest value `b5c39bfbe319a838e87cf276778338bd75a471a6f59356c4fe3d7a640d7f9dbc`.

The only matching capability files found elsewhere were outside this clean branch: in an external qualification ZIP and as untracked files in a different dirty worktree. The task explicitly prohibits reconstructing missing files from reports or silently importing a different package, so neither source was copied into this branch.

## Available package evidence

| Artifact | SHA-256 |
|---|---|
| `eMAS_MS04_PreSales_Runtime_RC1.zip` | `d08f169f71af8400cefbe9b575a01b8d4feedac8449c1d57fd1c5ceefec27aa6` |
| `eMAS_MS04_PreSales_Wave1_TestData_v1.zip` | `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7` |
| `eMAS_MS04_PreSales_WindowsQualification_Internal_v1.zip` | `c5ba45863b970475ed3407d900c343fcb815812b6d4cd3a745bb6c4c8ba63180` |
| Qualification ZIP `PACKAGE_MANIFEST.csv` content | `5735a8bf1730a048264a95b5f7221d4276050d3cc97af8eba2f1e0897edb2c83` |
| External Wave 1 freeze manifest | `367da81d07ee2f4770cdd3f86e157282f237b01c9d2debac64f81490bd6ced56` |

Nineteen frozen Wave 1 fixture ZIPs were present in the external controlled workspace, but the missing runtime and test inputs prevent executing or proving the accepted eight-suite baseline from this branch.

## Test result

No pre-fix characterization, focused regression, or eight-suite run was attempted. The mandatory baseline gate failed before test execution. Running a partial or reconstructed suite would not satisfy the task contract.

## Scope and integrity confirmation

- No runtime module was edited.
- No test or expectation file was edited.
- No frozen Wave 1 fixture or manifest was edited.
- `RepositoryDiscovery`, `FormatDetection`, and `RegionDetection` were not modified or implemented.
- No package or generated result was modified.
- This report is the only task deliverable changed.

## Required unblock action

Materialize the exact qualified RC1 source, harnesses, expectations, and supporting file identities into controlled Git history through a separately authorized change, or provide a repository-native immutable package source explicitly approved for materialization. After that baseline is merged into the task's base lineage, restart this implementation from the resulting fixed commit and rerun the complete baseline gate.
