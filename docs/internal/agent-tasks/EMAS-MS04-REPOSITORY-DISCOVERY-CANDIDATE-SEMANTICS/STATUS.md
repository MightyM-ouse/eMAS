# Task Status

**Task ID:** `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS`  
**Authoritative base commit:** `bd11d71225c4f5ce52960a01b4ecede27ed8a353`  
**Task phase:** Semantics decision accepted  
**Overall status:** `DECISION_ACCEPTED_READY_FOR_IMPLEMENTATION_TASK`

| Gate | Role | Status | Deliverable |
|---|---|---|---|
| Wave1D Mac baseline | SD-044–SD-050 normative; SD-051 characterization | ACCEPTED | PR #32 |
| Claude | Analyze candidate rules and recommend semantics | COMPLETE | PR #34 / `reports/CLAUDE.md` |
| ChatGPT | Central review / reconcile recommendation | COMPLETE | `reports/REVIEW.md` |
| User | Accept/reject amended B3 semantics | ACCEPTED | Explicit decision |
| RepositoryDiscovery implementation | Separate bounded follow-up task | READY | `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION` |
| Unreadable-sequence empty-state defect | Resolve before Phase 1 qualification | REQUIRED | Same implementation wave or tiny immediate follow-up |
| eCTD v4 discovery extension | Separate required task before FormatDetection | REQUIRED | `EMAS-MS04-ECTD4-DISCOVERY-EXTENSION` |
| FormatDetection / RegionDetection | Must not start first | BLOCKED | Await RepositoryDiscovery implementation + v4 discovery extension |
| Windows PS 5.1 | Later consolidated qualification | DEFERRED | Future Windows stage |

## Accepted decision

The B3 structural-promotion principle is accepted for the existing four-digit-sequence v3/NeeS discovery path, with these amendments:

1. a parent is promoted only when at least one direct exact four-digit sequence child contains a direct structural signal: `m1`–`m5`, `index.xml`, or `submissionunit.xml`, matched case-insensitively;
2. fail-open applies when the exact sequence directory itself cannot be enumerated, not merely because an arbitrary deeper descendant is unreadable;
3. nested-candidate suppression applies only after structural promotion;
4. empty/structureless numeric containers are not promoted for Phase 1 and remain a known ambiguity;
5. residual false positives with plausible structural names are tolerated at discovery level; later FormatDetection must require recognized structured regulatory backbone evidence;
6. year-like folders inside a genuine dossier remain a deferred sequence-membership question;
7. unreadable must not be reported as empty;
8. this decision does **not** establish eCTD v4 discovery completeness.

## Required sequencing

1. Implement and regress the accepted B3 semantics.
2. Complete a separate authoritative eCTD v4 discovery-extension task.
3. Only then begin FormatDetection/RegionDetection implementation.
