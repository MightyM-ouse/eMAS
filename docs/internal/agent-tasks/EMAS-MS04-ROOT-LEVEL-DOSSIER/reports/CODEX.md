# Codex Mac Implementation Report

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`

**Agent:** Codex

**Role:** Implementation owner

**Branch:** `implementation/emas-ms04-root-level-dossier-v2`

**Authoritative baseline:** `dac1664fee652f701a41204e2527f602077bb42f`

**Branch start:** `858b56f03d9f25e9af5fc6c1eccfc16584aa90ad`

**Characterization commit:** `a28d736`

**Reviewed implementation commit:** `7066e880bb6fb42ee5b7c9ed8024413c9158357f`

**Overall Mac result:** `PASS`

**Windows PowerShell 5.1 qualification:** Deferred; not performed or claimed in this stage

## Baseline gate

The branch start is a descendant of the authoritative materialized RC1 baseline. All 26 required runtime/test inputs were present and matched the internal Windows qualification-package manifest: eight capability modules, `eMAS.SafeXml.ps1`, the entry script, eight regression harnesses, and eight Wave 1 expectation files.

Recorded package identities:

| Artifact | SHA-256 |
|---|---|
| `eMAS_MS04_PreSales_Runtime_RC1.zip` | `d08f169f71af8400cefbe9b575a01b8d4feedac8449c1d57fd1c5ceefec27aa6` |
| `eMAS_MS04_PreSales_Wave1_TestData_v1.zip` | `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7` |
| `eMAS_MS04_PreSales_WindowsQualification_Internal_v1.zip` | `c5ba45863b970475ed3407d900c343fcb815812b6d4cd3a745bb6c4c8ba63180` |

The pre-fix eight-suite Mac baseline passed completely before implementation.

## Pre-fix characterization

The task-specific harness uses the frozen SD-002 bytes without changing the fixture. It extracts them to a temporary directory and runs the same dossier once as a wrapped repository and once with the dossier itself as the source root.

Pre-fix result: `FAIL`, one pass and two independent failures.

| Check | Pre-fix result |
|---|---|
| Root ReferenceResolution | Failed: expected 93 resolved-present targets, actual 0 |
| Root ClassificationEvidenceCollection | Failed: `DossierPath` rejected the empty string |
| SD-020 legitimate zero-evidence behavior | Passed |

Summary: `/tmp/emas-root-level-prefix.K713rt/focused-prefix/root-level-dossier-test-summary.json`

## Implementation

Only the two authorized modules were changed:

- `ReferenceResolution` now removes no prefix and no separator when the dossier path is empty, preserving `0000/index.xml` rather than reducing it to `000/index.xml`.
- `ClassificationEvidenceCollection` now accepts an empty dossier path and treats any non-empty repository-relative child path as already dossier-relative when the dossier is the repository root.

The changes retain the existing path normalization, traversal, absolute-path, repository-boundary, and target-inventory logic.

Module identities:

| Module | Qualified pre-fix SHA-256 | Mac implementation SHA-256 |
|---|---|---|
| `eMAS.ReferenceResolution.psm1` | `7077d9abd07d94ad2e4fadaa0af21203385cf24eb6ce0fbbbfa3bc9e18755dc0` | `3b47f68b99da91872b1d4400d8362640da00297a26e1a8ac38d96c050b43acf7` |
| `eMAS.ClassificationEvidenceCollection.psm1` | `1b4a23fa6da31e2cf50085e1bda6780160a8eefad291cdf3694dc7f8d371daf6` | `6df39d18b914114b8e623ac385ee5b63ac09610ff910727f5f632caecdc3c40b` |

## Focused Mac validation

Command:

```powershell
pwsh -NoProfile -NonInteractive -File tests/root-level-dossier/Test-eMASRootLevelDossier.ps1 -CorpusRoot <Wave1Root> -OutputRoot <OutputRoot>
```

Post-fix result: `PASS`, 3/3 checks, 0 failures.

- Root-level reference projection equals the wrapped projection; 94 references, 93 resolved present, 0 false absent.
- Root-level classification emits 86 evidence records, one weak `DossierRootPath` record, and repository coverage `Collected` with `RecordsProduced = 86`.
- Wrapped/root classification projections are equivalent after excluding the intentional dossier-root record.
- SD-020 remains `Collected` with zero classification evidence and `RecordsProduced = 0`.

Summary: `/tmp/emas-root-level-prefix.K713rt/focused-postfix/root-level-dossier-test-summary.json`

## Eight-suite Mac regression

Runtime: PowerShell Core 7.5.2 on macOS/Darwin ARM64.

| Suite | Pre-fix | Post-fix |
|---|---|---|
| RepositoryDiscovery | PASS | PASS |
| BackboneXmlInventory | PASS | PASS |
| ReferenceInventory | PASS | PASS |
| ReferenceResolution | PASS | PASS |
| MissingReferenceInterpretation | PASS | PASS |
| DeclaredChecksumComparison | PASS | PASS |
| ChecksumMismatchInterpretation | PASS | PASS |
| ClassificationEvidenceCollection | PASS | PASS |

Overall post-fix result: `8/8 PASS`, zero suite failures. Every suite verified all 19 frozen Wave 1 ZIP identities before and after execution. The unchanged ReferenceResolution regression also passed its unsafe/external href, traversal, absolute path, fragment, and access-denied cases.

Post-fix summaries: `/tmp/emas-root-level-prefix.K713rt/postfix/<suite>/<suite>-test-summary.json`

## Integrity and scope

- All eight Wave 1 expectation hashes remain identical to the qualification manifest.
- All 19 frozen fixture ZIPs passed every suite's pre-test and post-test freeze gates.
- No frozen fixture, freeze manifest, or Wave 1 expectation was changed.
- No change was made to `RepositoryDiscovery`, the other six accepted modules, the entry script, `eMAS.SafeXml.ps1`, configuration, packaging, reporting, schemas, or product contracts.
- `FormatDetection` and `RegionDetection` were not implemented or declared.
- No Windows qualification was performed.
- No merge was performed.
