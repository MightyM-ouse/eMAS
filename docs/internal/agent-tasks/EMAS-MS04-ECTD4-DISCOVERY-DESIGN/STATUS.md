# Task Status

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-DESIGN`  
**Authoritative base commit:** `02c29863448ead141616a3c78ee8b558bb4fabfe`  
**Overall status:** `READY_FOR_USER_DECISION_WITH_AMENDMENTS`

| Gate | Status |
|---|---|
| B3 v3/NeeS RepositoryDiscovery | ACCEPTED / MERGED |
| Claude authoritative source/design analysis | COMPLETE — PR #39 |
| ChatGPT independent source verification | COMPLETE |
| v4 physical-layout model | PASS WITH AMENDMENTS |
| design/scenario matrix | PASS WITH AMENDMENTS |
| v4 fixture plan | PASS WITH AMENDMENTS |
| User decision | READY |
| v4 discovery implementation | BLOCKED_ON_USER_DECISION |
| v4 ReferenceResolution semantics | REQUIRED BEFORE V4 REFERENCE/INTEGRITY CLAIMS |
| FormatDetection / RegionDetection | BLOCKED_ON_V4_DISCOVERY_IMPLEMENTATION |
| Windows PS 5.1 | DEFERRED |

## Central-review decision

Recommended for acceptance with these amendments:

1. do not fail-open/promote arbitrary unreadable non-four-digit numeric folders;
2. treat simultaneous `index.xml` + `submissionunit.xml` as ambiguous, not v3;
3. `sha256.txt` + module fallback is damaged/v4-like candidate evidence only, never sufficient for final v4 classification;
4. misplaced `submissionunit.xml` is observed but does not create a submission-unit candidate;
5. check currently supported regional source versions before implementation, including FDA legacy-supported material;
6. create a later v4 reference-semantics task for cross-submission-unit/cross-container reuse.

No runtime implementation is authorized until the user accepts the amended design.
