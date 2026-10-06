# Task Status

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-DESIGN`  
**Authoritative base commit:** `02c29863448ead141616a3c78ee8b558bb4fabfe`  
**Overall status:** `DESIGN_ACCEPTED_READY_FOR_IMPLEMENTATION_TASK`

| Gate | Status |
|---|---|
| B3 v3/NeeS RepositoryDiscovery | ACCEPTED / MERGED |
| Claude authoritative source/design analysis | COMPLETE — PR #39 |
| ChatGPT independent source verification | COMPLETE |
| v4 physical-layout model | ACCEPTED WITH AMENDMENTS |
| design/scenario matrix | ACCEPTED WITH AMENDMENTS |
| v4 fixture plan | ACCEPTED WITH AMENDMENTS |
| User decision | ACCEPTED |
| v4 discovery implementation | READY AS SEPARATE TASK |
| v4 ReferenceResolution semantics | REQUIRED BEFORE V4 REFERENCE/INTEGRITY CLAIMS |
| FormatDetection / RegionDetection | BLOCKED_ON_V4_DISCOVERY_IMPLEMENTATION |
| Windows PS 5.1 | DEFERRED |

## Accepted design

The accepted design is the Claude v4 physical-discovery proposal as amended by ChatGPT central review:

1. preserve the accepted v3/NeeS B3 path;
2. add a separate v4 submission-unit structural path for 1–6 digit numeric folders;
3. direct `submissionunit.xml` is the primary v4 physical marker;
4. do not promote arbitrary unreadable non-four-digit numeric folders;
5. `sha256.txt` + direct `m1`–`m5` without `submissionunit.xml` is damaged/v4-like structural evidence only;
6. simultaneous `index.xml` + `submissionunit.xml` is ambiguous/conflicting structural evidence, not automatic v3;
7. misplaced `submissionunit.xml` is observed but does not create a v4 submission-unit candidate;
8. v4 units must not be emitted as `IsExactSequenceFolder = true`;
9. `DossierCandidates` remains a physical container abstraction, not application identity;
10. lifecycle numbering differences are not interpreted in RepositoryDiscovery;
11. currently supported regional source versions must be checked before implementation;
12. FormatDetection and RegionDetection remain blocked until the v4 discovery implementation is accepted;
13. separate v4 reference semantics are required before claiming v4 reference/integrity completeness.

## Next task

Create and execute:

`EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION`

Single implementation worker: Codex.  
ChatGPT central review.  
User approval before merge.  
Mac-first; Windows qualification deferred.
