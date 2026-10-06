# Codex Report — EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION

**Status:** `COMPLETE — MAC_VALIDATED`

## Delivery

- Branch: `implementation/emas-ms04-repository-discovery-b3`
- Base branch: `coordination/emas-ms04-repository-discovery-b3-implementation`
- Base HEAD used: `fb927f468ca98c3756ca68ed0a626e1974cd4f07`
- Authoritative base ancestor verified: `70f1edf9584477d229ef8b321cb7172734669cca`
- Test-first commit: `9306182` (`test(repository-discovery): capture B3 candidate semantics`)
- Implementation commit: `bccf560` (`fix(repository-discovery): qualify dossier candidates by structure`)
- Validation platform: macOS 26.6.2 (25G83), Apple Silicon, PowerShell Core 7.5.2
- Windows qualification: not performed, as directed

## Scope implemented

`RepositoryDiscovery` now promotes a parent only when at least one direct exact `NNNN` directory has one of the accepted direct structural signals:

- a case-insensitive `m1` through `m5` directory;
- a case-insensitive `index.xml` file;
- a case-insensitive `submissionunit.xml` file; or
- an access/enumeration gap on that exact sequence directory itself.

The existing exact-four-digit sequence gate remains unchanged. Candidate qualification occurs before the existing nested-candidate suppression. An access/enumeration gap below an exact sequence does not trigger fail-open, and an unreadable exact sequence retains its repository error without also producing `EmptyExactSequenceFolder`.

No eCTD v4 discovery, `FormatDetection`, `RegionDetection`, engine entry-point, contract, package, or frozen fixture-byte changes were made.

## Test-first reproduction

The focused harness was committed before the production change. Against the original heuristic it reproduced the defect with `6/11` passing and five expected failures:

- the year wrapper suppressed the genuine nested dossier;
- nested-only signals promoted a false candidate;
- a structureless numeric parent was promoted;
- an unreadable exact sequence was incorrectly described as empty; and
- an unreadable deeper descendant incorrectly caused promotion.

## Wave1D expectation versioning

- Added `tests/fixtures/dossier-diversity/wave1d-sd051-normative.v2.json`.
- Updated the active Wave1D harness to apply the normative v2 candidate, ownership, coverage, and fixture-hash assertions for SD-051.
- Retained `wave1d-sd051-characterization.json` unchanged for provenance.
- Retained `WAVE1D_FREEZE_MANIFEST.csv` and all eight Wave1D fixture ZIPs unchanged.
- Historical characterization SHA-256 before/after: `35000996a921a93f73e735a1005e7a5c90e80ab241e7e204a585e08115eab71e`.
- Wave1D freeze-manifest SHA-256 before/after: `f9a18813a23c0749459c5138950e28e99fb828ac0599152b43302001856db460`.

## Baseline gates

Before implementation:

- RepositoryDiscovery regression: `PASS` (10 fixture cases, 3 additional checks; 19 frozen ZIPs verified before and after).
- Eight-suite Wave 1 regression: `PASS` (275/275 including pre/post freeze gates).
- Root-level regression: `PASS` (3/3).
- Wave1D accepted regression: `PASS` (60/60; historical SD-051 characterization matched).
- Focused pre-fix reproduction: `FAIL` as expected (6/11), capturing the assigned defects.

## Final Mac validation

### Focused B3 semantics

`PASS` — 12/12.

The harness covers the bounded case-insensitive structural signals, structureless and nested-only negatives, exact-sequence fail-open, deeper-descendant non-promotion, unreadable-not-empty behavior, root-level discovery, candidate-before-suppression behavior, ZIP/directory determinism, and a year-wrapped SD-002 end-to-end projection with 94 references, 93 resolved-present targets, and 86 classification-evidence records.

### RepositoryDiscovery regression

`PASS` — 10/10 fixture cases plus 3/3 additional checks; all 19 frozen Wave 1 ZIPs verified unchanged before and after.

### Eight-suite Wave 1 regression

`PASS` — 275/275 including 16 pre/post freeze gates (259 suite assertions plus freeze gates).

| Suite | Assertion result |
|---|---:|
| RepositoryDiscovery | 13/13 |
| BackboneXmlInventory | 22/22 |
| ReferenceInventory | 28/28 |
| ReferenceResolution | 31/31 |
| MissingReferenceInterpretation | 33/33 |
| DeclaredChecksumComparison | 37/37 |
| ChecksumMismatchInterpretation | 54/54 |
| ClassificationEvidenceCollection | 41/41 |

### Root-level regression

`PASS` — 3/3.

### Wave1D regression

`PASS` — 61/61; zero normative failures; SD-051 status `SUPERSEDED_BY_NORMATIVE_V2`; SD-002 and SD-010 invariance references passed; all eight Wave1D fixture hashes remained unchanged.

SD-051 final behavior:

- only `ProductABC` is a dossier candidate (`DOS-0001`);
- `Archive` is not promoted;
- `Archive/2019/annual-report.pdf` is inventoried but unowned;
- false Archive backbone/XML/evidence records are absent;
- the genuine dossier retains 94 references, 93 resolved-present targets, and 86 classification-evidence records.

## Blockers and open issues

No implementation blocker remains. Windows qualification is intentionally deferred. eCTD v4 discovery remains a separate future task. As accepted in the governing decision, a non-dossier numeric parent with a direct `m1`–`m5`, `index.xml`, or `submissionunit.xml` signal can remain a residual false positive, while a structureless numeric parent is deliberately not promoted without a collection gap.
