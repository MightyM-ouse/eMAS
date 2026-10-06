# EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION

**Task ID:** `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION`  
**Authoritative base commit:** `70f1edf9584477d229ef8b321cb7172734669cca`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Codex) → ChatGPT review → user decision  
**Stage:** Mac-first bounded implementation  
**Windows PowerShell 5.1:** Deferred to the later consolidated qualification stage

## Accepted design

Implement the user-approved B3 structural-promotion rule for the existing four-digit-sequence v3/NeeS discovery path.

A parent path (including archive root `""`) is promoted to a dossier candidate only when it has at least one direct exact sequence child named exactly four ASCII digits and at least one such child satisfies one of these direct structural conditions:

1. contains a direct directory `m1` through `m5`, case-insensitive; or
2. contains a direct file `index.xml` or `submissionunit.xml`, case-insensitive; or
3. the exact sequence directory itself could not be enumerated, so the absence of direct structural signals cannot safely be established.

Nested-candidate suppression must run only after this structural-promotion step.

## Two mandatory amendments

1. **Narrow fail-open:** fail-open only when the exact sequence directory itself cannot be enumerated. An arbitrary unreadable deeper descendant must not promote an otherwise structureless numeric parent.
2. **Unreadable is not empty:** an exact sequence directory that could not be enumerated must retain its access/enumeration error and must not also produce `EmptyExactSequenceFolder`.

## Explicit non-goals

Do not:
- implement FormatDetection or RegionDetection;
- change eCTD v4 numeric sequence discovery in this task;
- change contract/schema fields;
- add candidate tiers/statuses;
- add a new "not promoted" observation;
- infer from dossier/wrapper/product/region names;
- parse XML content inside RepositoryDiscovery for promotion;
- change numeric-gap semantics;
- fix year-like folders that occur *inside* an already accepted dossier;
- modify frozen Wave 1 fixture bytes.

## Required behavior

The implementation must preserve all accepted Wave 1 and Wave1D normative behavior, except for the intentionally superseded SD-051 discovery semantics.

Required new behavior:

### SD-051

For the existing frozen SD-051 bytes:
- `ProductABC` is the only dossier candidate;
- `Archive` is not a dossier candidate;
- `Archive/2019/annual-report.pdf` remains inventory content with no dossier ownership;
- the genuine dossier becomes `DOS-0001`;
- false missing-backbone observations/evidence from `Archive` disappear;
- genuine dossier reference/evidence projections remain unchanged.

Do **not** edit the accepted historical SD-051 characterization file in place. Add a new versioned normative expectation and update the active regression path to use it, while keeping the original characterization for provenance.

### Year-wrapper regression

Add a focused regression equivalent to:

`Exports/2024/ProductABC/0000...`

using accepted SD-002 regulatory bytes.

Expected:
- `Exports` is not promoted merely because it contains child `2024`;
- the genuine `Exports/2024/ProductABC` dossier is discovered;
- wrapper paths are preserved;
- the dossier has the same dossier-relative regulatory projection as SD-002;
- 94 references / 93 resolved-present and 86 classification-evidence records remain consistent with the accepted SD-002 profile.

### Unreadable exact sequence

For a directory-source test:
- parent qualifies fail-open when the exact `NNNN` directory itself cannot be enumerated;
- existing `DISC-ACCESS-001` or `DISC-ENUM-001` state is preserved;
- no `EmptyExactSequenceFolder` observation is emitted for that unreadable sequence;
- no unrelated deeper unreadable descendant can promote a structureless year-folder parent.

## Allowed files

Implementation owner may change only:

- `engine/powershell51/eMAS.RepositoryDiscovery.psm1`
- directly relevant RepositoryDiscovery test harness/expectation files under `tests/repository-discovery/**`
- versioned Wave1D SD-051 expectation/harness files under `tests/dossier-diversity/**` and `tests/fixtures/dossier-diversity/**`
- a task-specific focused harness/utility under `tests/repository-discovery-candidate-semantics/**` if useful
- this task's Codex report

If another test file is genuinely required, explain it in the report before changing it.

## Forbidden files

Do not modify:

- other `engine/**` capability modules;
- `scripts/eMAS-PreSalesAssessment.ps1`;
- frozen Wave 1 fixture ZIPs or freeze manifest;
- accepted historical Wave1D fixture ZIP hashes;
- FormatDetection / RegionDetection;
- product contracts/schemas;
- packaging/release files unrelated to this test gate.

## Baseline gate

Before implementation:

1. confirm branch descends from `70f1edf9584477d229ef8b321cb7172734669cca`;
2. run the current accepted RepositoryDiscovery suite;
3. run all 8 Wave 1 suites;
4. run root-level-dossier 3/3;
5. run accepted Wave1D regression;
6. reproduce:
   - SD-051 false `Archive` candidate;
   - hidden genuine dossier under `Exports/2024/ProductABC`;
   - unreadable exact sequence also reported as empty.

If any cannot be reproduced as documented, stop and report rather than changing scope.

## Validation after implementation

Must pass on Mac:

1. focused B3 semantics regression;
2. current RepositoryDiscovery accepted regression;
3. all 8 Wave 1 suites, 275 checks;
4. root-level dossier, 3/3;
5. updated Wave1D regression with SD-051 normative-v2 behavior;
6. frozen Wave 1 hashes unchanged;
7. frozen Wave1D fixture ZIP hashes unchanged;
8. no runtime output drift for accepted normative cases other than intended dossier IDs/ownership in SD-051;
9. ZIP and directory source behavior remain deterministic for equivalent readable structures.

## Reporting

Create:

`docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION/reports/CODEX.md`

Include:
- pre-fix reproduction;
- exact code change;
- exact fail-open logic;
- unreadable-vs-empty fix;
- new/updated tests;
- versioning of SD-051 expectation;
- pre/post suite results;
- file/hash integrity;
- unresolved issues.

## Git workflow

Use implementation branch:

`implementation/emas-ms04-repository-discovery-b3`

Open a **draft PR into `demo/end-to-end-mvp`**. Do not merge.

ChatGPT performs the central review. User approval is required before acceptance.

## Separate required eCTD v4 task

This task does not make RepositoryDiscovery eCTD-v4-complete.

Before FormatDetection begins, the separate task `EMAS-MS04-ECTD4-DISCOVERY-EXTENSION` must establish authoritative eCTD v4 repository/sequence layout and implement/test any needed non-four-digit discovery extension.
