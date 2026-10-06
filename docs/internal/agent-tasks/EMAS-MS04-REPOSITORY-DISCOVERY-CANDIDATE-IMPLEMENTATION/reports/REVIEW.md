# ChatGPT Review — EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION

**Status:** `MAC_REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed implementation commit:** `01ff87db9b5fae17c47c11f1342b5e578bcd2798`  
**Reviewed PR:** #37

## Verdict

The bounded B3 RepositoryDiscovery implementation is acceptable as the Mac implementation baseline.

No blocking issue was found in the production change, scope, SD-051 expectation versioning, or Mac regression evidence.

## Verified implementation

The production change is confined to `engine/powershell51/eMAS.RepositoryDiscovery.psm1` and implements the accepted semantics:

- promotion still begins from direct exact four-digit sequence children;
- a parent is promoted only when at least one exact child directly contains case-insensitive `m1`–`m5`, `index.xml`, or `submissionunit.xml`;
- fail-open is limited to an inventory gap recorded on the exact sequence directory itself;
- a deeper unreadable descendant does not promote a structureless numeric parent;
- nested-candidate suppression runs after structural promotion;
- unreadable exact sequences retain their access/enumeration state and no longer also emit `EmptyExactSequenceFolder`;
- the existing four-digit gate is unchanged, so this does not claim eCTD v4 discovery completeness.

## Regression coverage

Reviewed results:

- focused B3 semantics: **12/12 PASS**;
- RepositoryDiscovery accepted regression: **13/13 PASS**;
- Wave 1 eight-suite regression: **275/275 PASS**;
- root-level dossier: **3/3 PASS**;
- Wave1D: **61/61 PASS**.

The focused harness covers:
- year wrapper preserving the genuine nested dossier;
- case-insensitive structural signals;
- structureless and nested-only negative cases;
- exact-sequence fail-open;
- deeper-descendant non-promotion;
- unreadable-not-empty;
- root-level dossier;
- any qualifying sequence promoting the parent;
- ZIP/directory candidate projection consistency for readable structures;
- end-to-end SD-002 projection under `Exports/2024/ProductABC`.

## SD-051 versioning

The historical `wave1d-sd051-characterization.json` is retained unchanged.

The new `wave1d-sd051-normative.v2.json` explicitly supersedes the old characterization and binds to the unchanged frozen SD-051 fixture hash.

Expected B3 behavior is now:
- only `ProductABC` is a dossier candidate;
- `Archive/2019/annual-report.pdf` remains inventoried but unowned;
- false Archive backbone/evidence records disappear;
- the genuine dossier retains 94 references, 93 resolved-present targets, and 86 classification-evidence records.

## Automatic Windows CI failure

The red GitHub Actions result is **not from the B3 implementation**.

The failing job is `windows-powershell-51-contracts`, step `Run dependency-free Runtime JSON configuration tests`.

The single failure is the unrelated runtime-configuration UTF-8 assertion:

`UTF-8 metadata is preserved`

The log shows the expected string was decoded as mojibake while the actual runtime value was correct.

The two files involved in that failing check are byte-identical between the PR base and the PR head:

- `tests/runtime/Test-eMASRuntimeConfiguration.ps1`
- `engine/core/eMAS.RuntimeConfiguration.psm1`

Neither file is changed by PR #37. Windows PowerShell 7.6 and macOS contract jobs pass.

Therefore this CI failure should be tracked separately and does not invalidate the Mac B3 acceptance gate.

## Windows qualification note

The focused B3 harness is intentionally Mac-stage test code and uses PowerShell 7 plus POSIX permission manipulation to create access-denied cases. It is not itself a Windows PS 5.1 qualification harness.

Before final MS-04 Windows qualification, the B3 behavior still needs native Windows PS 5.1 coverage through an appropriate Windows-compatible test path. That remains consistent with the task's explicit Windows deferral.

## Scope

No FormatDetection, RegionDetection, eCTD v4 discovery extension, contract/schema, or other capability module is changed.

## Recommendation

**Accept PR #37 as the Mac B3 RepositoryDiscovery implementation baseline.**

After acceptance:
1. close redundant coordination PR #35 without merge;
2. keep the unrelated Windows UTF-8 CI issue separate;
3. proceed to the already-defined `EMAS-MS04-ECTD4-DISCOVERY-EXTENSION` task before FormatDetection/RegionDetection.
