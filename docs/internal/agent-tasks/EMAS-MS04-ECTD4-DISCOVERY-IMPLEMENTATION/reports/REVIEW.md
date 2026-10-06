# ChatGPT Review — EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION

**Status:** `MAC_REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed implementation commit:** `b86304c0d78b70e9d0ef0a1ff2d3796df23b724f`  
**Reviewed PR:** #41

## Verdict

The bounded eCTD v4 RepositoryDiscovery implementation is acceptable as the Mac implementation baseline.

No blocking issue was found in the production change, task scope, Wave1E fixture design/freeze, regression evidence, or downstream isolation.

## Verified scope

Changed implementation is confined to:

- `engine/powershell51/eMAS.RepositoryDiscovery.psm1`;
- new focused v4 tests under `tests/repository-discovery-ectd4/**`;
- new Wave1E fixtures/expectations under `tests/fixtures/repository-discovery-ectd4/**`;
- deterministic builder under `tools/testdata/ms04-wave1e/**`;
- this task's documentation.

No BackboneXmlInventory, ReferenceInventory, ReferenceResolution, ClassificationEvidenceCollection, contract/schema, entry-script, FormatDetection, RegionDetection, or existing frozen Wave1/Wave1D fixture file is changed.

## Source-version gate

The implementation report records pre-code verification against current official ICH/FDA/EU material.

Central review independently reconfirmed the current public source status:

- ICH publishes eCTD v4.0 Implementation Guide v1.7, endorsed June 2026;
- FDA currently lists Regional M1 IG v1.9, FDA-supported ICH IG package v1.6, and legacy Regional M1 package v1.5.1 supported through 2027-09-28;
- EU currently lists Practical Guidance v1, Module 1 IG draft v1.2, and Validation Criteria v1.1 final.

No public source reviewed contradicts the implemented bounded physical-discovery rule.

## Verified classifier behavior

The implementation matches the accepted amended design:

1. Existing four-digit v3/NeeS B3 behavior is preserved.
2. A direct 1–6 digit child with direct `submissionunit.xml` and no `index.xml` is recorded as `SubmissionUnitFolder`.
3. `sha256.txt` + direct `m1`–`m5`, without either backbone marker, becomes `DamagedSubmissionUnitCandidate`.
4. Direct `index.xml` + `submissionunit.xml` becomes `AmbiguousRegulatoryUnitFolder`, not automatic v3.
5. v4/damaged/ambiguous units are `IsExactSequenceFolder = false`, protecting the current v3 BackboneXmlInventory path.
6. Unreadable non-four-digit numeric folders do not create candidacy solely from the access gap.
7. Existing unreadable four-digit B3 fail-open remains.
8. Misplaced/out-of-range `submissionunit.xml` is observed using `UnplacedSubmissionUnitMarker` without creating v4 candidacy.
9. Case-insensitive structural discovery is retained; canonical-number spelling is recorded separately.
10. Nested suppression is based on classified direct units rather than numeric appearance alone.

## Wave1E

Wave1E SD-053 through SD-074 is implemented as deterministic, discovery-only synthetic physical test data.

The fixtures cover:

- FDA-style root placement;
- EU first-level/wrapper structures;
- multiple v4 physical containers;
- v3/v4 coexistence and transition shapes;
- year/numeric false positives;
- damaged marker sets;
- access-denied distinction;
- misplaced marker;
- case variants;
- malformed discovery-only XML;
- four-digit v4 marker precedence;
- non-canonical leading-zero unit names;
- EU grouped-transmission physical layout;
- out-of-range numeric markers;
- conflicting v3/v4 backbone markers;
- nested-suppression behavior.

Every synthetic `submissionunit.xml` is explicitly labelled as not being a valid regulatory v4 message.

## Regression evidence reviewed

- focused v4 discovery: **22/22 fixtures PASS + 2/2 additional checks**;
- readable fixture ZIP/directory equivalence: PASS;
- v4 downstream isolation: PASS;
- Wave1E deterministic build: PASS, byte-identical;
- package SHA-256: `78541a9b508cc9575ee56dc0468601c0e392cb543414f7b14a56b03579c684aa`;
- RepositoryDiscovery: **13/13 PASS**;
- B3: **12/12 PASS**;
- Wave1: **275/275 PASS**, including freeze gates;
- root-level: **3/3 PASS**;
- Wave1D: **61/61 PASS**.

The focused harness also verifies that confirmed/damaged/ambiguous v4 structural units do not enter current v3 backbone/reference processing.

## Automatic Windows CI failure

The GitHub Actions red status is the same unrelated Windows PowerShell 5.1 RuntimeConfiguration UTF-8 assertion seen on the previous B3 task.

The failure is:

`UTF-8 metadata is preserved`

The failing RuntimeConfiguration test and module are byte-identical between PR #41 base and head:

- `tests/runtime/Test-eMASRuntimeConfiguration.ps1`
- `engine/core/eMAS.RuntimeConfiguration.psm1`

Windows PowerShell 7.6, macOS contract tests, and static runtime-contract tests pass.

Therefore this CI failure does not invalidate the bounded v4 Mac acceptance gate. Native Windows v4 RepositoryDiscovery qualification remains deferred as designed.

## Deferred work remains correctly deferred

This PR does not claim:

- v4 XML parsing/interpretation;
- FormatDetection;
- RegionDetection;
- v4 ReferenceResolution completeness;
- regulatory conformance/validity.

The previously identified `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS` task remains required before complete v4 reference/integrity claims.

## Recommendation

**Accept PR #41 as the Mac eCTD v4 physical-discovery baseline.**

After user acceptance:

1. merge PR #41;
2. close redundant coordination PR #40 without merge;
3. keep FormatDetection and RegionDetection blocked only until the merge is complete;
4. then create `EMAS-MS04-IDENTIFICATION-RULES` as the next logical decision task before implementing FormatDetection/RegionDetection;
5. keep `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS` as a separate required downstream gate for v4 reference/integrity coverage.
