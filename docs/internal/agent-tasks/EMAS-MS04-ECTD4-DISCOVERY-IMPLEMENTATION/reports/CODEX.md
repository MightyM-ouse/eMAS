# Codex Report — EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION

**Status:** `READY_FOR_CHATGPT_REVIEW`

**Implementation branch:** `implementation/emas-ms04-ectd4-discovery`

**Coordination start:** `5198ac7f620b8e7d4544a2bae4cf2f73451b3749`

**Authoritative base:** `e369ae3ebb8394fb7b241bf9fbb60d698ec53690`

**Validation platform:** macOS, PowerShell 7

**Windows PowerShell 5.1:** deferred by task

## Outcome

Implemented the accepted eCTD v4 physical-discovery semantics in RepositoryDiscovery only. The implementation keeps accepted B3 behavior, records confirmed, damaged, and ambiguous v4-like structural units as non-v3 sequence-like records, observes misplaced markers without promotion, and keeps current v3 backbone/reference processing isolated from these units.

No FormatDetection, RegionDetection, BackboneXmlInventory, ReferenceInventory, ReferenceResolution, ClassificationEvidenceCollection, contract/schema, entry-script, or frozen Wave 1/Wave1D fixture file was modified.

## Required source-version verification

Verification was completed on 2026-10-06 before implementation.

| Source | Current/support status verified | Physical-layout conclusion |
|---|---|---|
| [ICH eCTD v4.0](https://ich.org/page/ich-electronic-common-technical-document-ectd-v40) | Implementation Guide v1.7, endorsed June 2026 | No contradiction: the accepted structural rule remains a numeric submission-unit folder with `submissionunit.xml` at its root. |
| [FDA eCTD v4.0 and Regional M1 standards](https://www.fda.gov/drugs/electronic-regulatory-submission-and-review/ectd-submission-standards-ectd-v40-and-regional-m1) | FDA Regional M1 IG v1.9; FDA support began 2026-09-28; FDA-supported ICH IG package remains v1.6 | No contradiction with the bounded 1–6 digit direct-child marker rule. |
| FDA legacy-supported Regional M1 package | v1.5.1 remains in its published support window through 2027-09-28 | The official v1.5.1 package (`8641a627ec217d96bf1971e307e1121b792d4dffb1aaa2c788a7d531e3b382c1`) states that FDA omits a regionally specified folder and shows the actual numeric sequence folder directly under the transmission. This is not a material physical-layout difference for discovery. |
| [EU eCTD v4 implementation material](https://esubmission.ema.europa.eu/eCTD%20NMV/eCTD.html) | Practical Guidance v1.0 (December 2025); EU Module 1 IG v1.2 draft (October 2024); Validation Criteria v1.1 final (March 2026) | No material contradiction. EU grouping/first-level folders remain wrappers; discovery still relies only on the numeric unit and direct fixed marker names. |

**Result:** `PASS — no currently supported official source reviewed introduced a material physical-layout difference requiring a stop or design change.`

## Implemented classifier and precedence

For each direct child directory whose leaf is `^\d{1,6}$`:

1. An access/enumeration gap promotes only an exact four-digit B3 child; a non-four-digit unreadable folder is retained in diagnostics but does not promote.
2. Direct `index.xml` plus direct `submissionunit.xml` records `AmbiguousRegulatoryUnitFolder`, `IsExactSequenceFolder = false`, with `ConflictingBackboneMarkers`.
3. Direct `submissionunit.xml` without `index.xml` records `SubmissionUnitFolder`, `IsExactSequenceFolder = false`.
4. No backbone marker, but direct `sha256.txt` plus direct `m1`–`m5`, records `DamagedSubmissionUnitCandidate`, `IsExactSequenceFolder = false`.
5. Otherwise, the accepted four-digit B3 signal rule remains in force. Once a B3 physical container is promoted, all its direct `NNNN` children remain in the accepted exact-sequence inventory.

Canonical v4 numbering is `^[1-9]\d{0,5}$`. Structurally detected leading-zero names remain non-exact and receive `NonCanonicalSequenceNumberFolderName`. A direct `submissionunit.xml` outside a 1–6 digit folder receives `UnplacedSubmissionUnitMarker` and does not create candidacy.

Nested candidacy is suppressed only when the first segment below an accepted candidate is one of that candidate's classified direct unit folders. A numeric-looking but unclassified segment does not suppress a deeper independent candidate.

Exact new structural kinds:

- `SubmissionUnitFolder`
- `DamagedSubmissionUnitCandidate`
- `AmbiguousRegulatoryUnitFolder`

Exact new observation codes:

- `SubmissionUnitFoldersObserved`
- `DamagedSubmissionUnitMarkerSet`
- `NonCanonicalSequenceNumberFolderName`
- `ConflictingBackboneMarkers`
- `UnplacedSubmissionUnitMarker`

## Wave1E freeze

The deterministic builder created and froze SD-053 through SD-074. Every `submissionunit.xml` is an explicitly labelled discovery-only synthetic stub; no fixture claims regulatory validity.

| Sample | SHA-256 |
|---|---|
| SD-053 | `f312440c90f09fe8a170669cd392107e3b96b82c3a82fee1f537218ffe17e926` |
| SD-054 | `18e9251870311fed47710a21340ae378003712dee7f930cdba2db81e0cfc0c10` |
| SD-055 | `6ea4261d0a01dc8e87c33b39c6af418ff6a881a5160717a863dc151d41bdb4e9` |
| SD-056 | `5a7eb752b5256cdb01a3552e0d8be04fea3eacd09963b5bea6fb873e8f064474` |
| SD-057 | `159f09d294ae88f2ac11376ccc036a75436d7514d5814c96775c9c7761538632` |
| SD-058 | `b0faef0afca7418414506df7f8626ca3baf8172747091018bb1481bdd273c712` |
| SD-059 | `80ea04154c2467ce8ef290534beea8084450c9b3f4228aad56436b28f1b07987` |
| SD-060 | `a56cffcf88dc3decb2bec884f1a8e9364ceea37026fb64d4a9a6e2942a1f4baf` |
| SD-061 | `28ac1da4cc5dbc0822b44341f5a5a7f6747eee0f101d4dedc81c5d2c0f5e6a60` |
| SD-062 | `00c4d4173774b6a7a30af30648a86b6ff5e3c06c6a17b3dd1f69ba834a5ef782` |
| SD-063 | `760af9a19f62ff17fd2e2da6bc7c5616bd72875a8c5ceb6e0342d0b63f8b51da` |
| SD-064 | `894ddf95094355c9a2e524752c77972d1d5dd0a5d488a62a2ba8ee09b9264134` |
| SD-065 | `0c74cc4c111005f95c2880b8e05e2254f46c1d8756bf880f02617627b2f1d422` |
| SD-066 | `c0dd0d8040b93f6d25e07c9b52e35706f02fcf31cb785b8ed1e2c3c8315d553f` |
| SD-067 | `17189fc7a5fa5319ba56e5a6ed1cea38c7697a4e8d0a507d5a30bf63f6bdf012` |
| SD-068 | `995abcb311d0334df0d9d13cd2c1e88f6306c3f03cf8f9694911e70878517050` |
| SD-069 | `00dc92126cdf3ca206a63fd0b87e9e34e568829a718eaf2931c7794345e8cda3` |
| SD-070 | `b0cf5b321aa815d81ebe96774b6af714c2d3ae4724d1b86de2d37d3fdcaa9c1f` |
| SD-071 | `ffd7705a99a3652310123cfa25f894525e94186cc24aabb7672fe20ff2817b0d` |
| SD-072 | `dacbb828b06985de302736c2d20f122b0f0ea1a3f7f8624f9e8f7a3e093ab005` |
| SD-073 | `e3afe4d725bbf3c9f696015bb1fef51f8d7731048ea5665475405526ddd6a02a` |
| SD-074 | `7e80912088ff984484816c6bd5f95f88c0376966afe520d39d5afbaa78a4527a` |

Two independent builds were byte-identical to each other and to the committed Wave1E tree. The outer package SHA-256 in both builds is:

`78541a9b508cc9575ee56dc0468601c0e392cb543414f7b14a56b03579c684aa`

## Validation evidence

### Pre-implementation baseline at authoritative base

| Gate | Result |
|---|---|
| RepositoryDiscovery | PASS, 13/13 |
| Focused B3 | PASS, 12/12 |
| Wave 1 eight-suite | PASS, 259/259 checks plus 16/16 freeze gates (275/275 total) |
| Root-level | PASS, 3/3 |
| Wave1D | PASS, 61/61 |

### Final Mac validation

| Gate | Result |
|---|---|
| Focused eCTD v4 discovery | PASS, 22/22 Wave1E fixtures and 2/2 nested-suppression checks; 21 readable fixtures pass ZIP/directory equivalence; 22 pre/post fixture hashes unchanged |
| v4 downstream isolation | PASS; special v4/damaged/ambiguous sequence IDs produce no v3 backbone documents, no false v3 missing-backbone observations, and no v3 reference extension |
| Wave1E deterministic build | PASS; two builds and committed corpus byte-identical; package SHA-256 identical |
| RepositoryDiscovery | PASS, 13/13; 19 frozen fixtures verified before and after |
| Focused B3 | PASS, 12/12 |
| Wave 1 eight-suite | PASS, 259/259 checks plus 16/16 freeze gates (275/275 total) |
| Root-level | PASS, 3/3 |
| Wave1D | PASS, 61/61; 8 frozen fixtures unchanged |

## Scope audit

Changed only:

- `engine/powershell51/eMAS.RepositoryDiscovery.psm1`
- `tests/repository-discovery-ectd4/**`
- `tests/fixtures/repository-discovery-ectd4/**`
- `tools/testdata/ms04-wave1e/**`
- this task's report and status

The accepted Wave 1 and Wave1D freeze gates passed before and after every applicable suite. Existing frozen fixture bytes are unchanged.

## Open issues and deferred work

- No implementation blocker.
- Windows PowerShell 5.1 qualification is intentionally deferred.
- v4 XML interpretation, FormatDetection, RegionDetection, and v4 ReferenceResolution semantics remain separate future tasks.
- Central ChatGPT review and user acceptance remain pending; this branch must not be merged by the implementation worker.
