# ChatGPT Review — EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE

**Status:** `MAC_REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed implementation commit:** `07c4164ec27ddc47cf49810126b316ceb071ad35`  
**Reviewed PR:** #47

## Verdict

T1a is acceptable as the Mac factual physical-marker evidence baseline.

The implementation remains additive, factual, deterministic, and within the amended scope.

## Verified implementation

New evidence types:

- `RegulatoryUnitKind` — Weak / PackageStructure
- `SubmissionUnitMarkerFile` — Supporting / OfficialPhysicalPath
- `TocFileMarker` — Supporting / OfficialPhysicalPath
- `ChecksumFileMarker` — Supporting / OfficialPhysicalPath
- `UtilityDtdFolderMarker` — Supporting / OfficialPhysicalPath

All new records keep:

- `CandidateValue = null`
- `Polarity = null`
- `SourceRuleId = null`

Raw CEC vocabulary remains `Strong / Supporting / Weak`.

No identification, format, region, profile, confidence, score, RAG, severity, effort, readiness, or regulatory-validity conclusion is emitted.

## Regression refresh verification

The follow-up commit correctly uses a historical CEC projection for legacy assertions while retaining the full additive result for current coverage.

For the SD-002 profile:

- historical CEC = 86 records;
- new T1a records = 15;
- full additive CEC = 101 records.

The three previously failing suites now preserve their original semantic checks without weakening non-CEC assertions.

No frozen expectation JSON, fixture ZIP, or freeze manifest was modified.

## Final Mac gates

- focused CEC: PASS — 19/19 fixtures + 38/38 additional checks
- Wave 1: PASS — 275/275 + 16/16 freeze gates
- root-level: PASS — 3/3
- Wave1D: PASS — 61/61
- v4 discovery: PASS — 22/22 + 2/2
- B3: PASS — 12/12
- frozen hashes: PASS — Wave1 19/19, Wave1D 8/8, Wave1E 22/22

## Automatic Windows CI

The GitHub Windows PowerShell 5.1 runtime-contract job still fails only on the pre-existing UTF-8 metadata assertion in RuntimeConfiguration.

macOS, static contracts, and Windows PowerShell 7.6 pass.

That unrelated issue does not invalidate this Mac acceptance gate.

## Recommendation

**Accept and merge PR #47 as the T1a Mac baseline.**

After merge:

- T1a is accepted;
- T4 remains blocked on T3a + T3b;
- T3a and T3c may proceed independently;
- Windows qualification remains deferred.
