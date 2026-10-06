# Task Status

**Task ID:** `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS`  
**Authoritative base commit:** `bd11d71225c4f5ce52960a01b4ecede27ed8a353`  
**Task phase:** Semantics analysis and central review complete  
**Overall status:** `READY_FOR_USER_DECISION_WITH_AMENDMENTS`

| Gate | Role | Status | Deliverable |
|---|---|---|---|
| Wave1D Mac baseline | SD-044–SD-050 normative; SD-051 characterization | ACCEPTED | PR #32 |
| Claude | Analyze candidate rules and recommend semantics | COMPLETE | PR #34 / `reports/CLAUDE.md` |
| ChatGPT | Central review / reconcile recommendation | COMPLETE | `reports/REVIEW.md` |
| User | Accept/reject amended B3 semantics | READY | Explicit decision |
| RepositoryDiscovery implementation | Separate follow-up task | BLOCKED_ON_USER_DECISION | Future implementation PR |
| Unreadable-sequence empty-state defect | Must be resolved before Phase 1 qualification | OPEN | RepositoryDiscovery implementation/follow-up |
| eCTD v4 discovery extension | Required before claiming v4 detection | OPEN | Future authoritative-sample/spec task |
| FormatDetection / RegionDetection | Must not start first | BLOCKED | Await discovery decisions |
| Windows PS 5.1 | Later consolidated qualification | DEFERRED | Future Windows stage |

## Central-review recommendation

Accept the B3 structural-promotion principle for the current exact-four-digit sequence path, with two amendments:

1. fail-open only when the exact sequence directory itself cannot be enumerated, not merely because an arbitrary deeper descendant is unreadable;
2. do not treat this rule as eCTD v4-complete because v4 sequence folders may use whole-number names rather than v3-style four-digit names.

Case-insensitive structural-name matching is recommended.

SD-051 remains characterization until the implementation task produces a versioned normative expectation.
