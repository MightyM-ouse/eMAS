# Task Status

**Task ID:** `EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D`  
**Authoritative base commit:** `793e065db17fed043ea95f9494f0e5f1458f0b72`  
**Accepted merge commit:** `bd11d71225c4f5ce52960a01b4ecede27ed8a353`  
**Task phase:** Mac baseline accepted; Windows qualification deferred  
**Overall status:** `MAC_ACCEPTED_WINDOWS_PENDING`

| Gate | Role | Status | Deliverable |
|---|---|---|---|
| Coordination | Publish authoritative task | COMPLETE | Task files |
| Claude | Build/freeze SD-044–SD-051 and validate on Mac | COMPLETE | PR #32 + `reports/CLAUDE.md` |
| ChatGPT | Central GitHub review | PASS | `reports/REVIEW.md` |
| User | Accept/reject Mac fixture baseline | ACCEPTED | PR #32 merged |
| Windows PS 5.1 | Consolidated later qualification | DEFERRED | Future Windows stage |
| SD-051 discovery semantics | Separate bounded decision task | IN_PROGRESS | `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS` |

## Accepted results

- SD-044 through SD-050 are accepted as normative Wave1D fixtures.
- SD-051 is accepted only as `FROZEN_CHARACTERIZATION`.
- SD-052 remains deferred.
- Wave1D Mac regression: 60/60 PASS.
- Existing Wave 1 regression: 8/8 suites, 275/275 checks PASS before and after.
- Root-level dossier harness: 3/3 PASS.
- Wave 1 hashes unchanged.
- Wave1D package SHA-256: `c99841179e6c168d1f81a967ff4a58ba5383d269735d68e6fef0857181ac2bec`.
- Windows PowerShell 5.1 qualification remains pending.

## Follow-up

The `Archive/2019` behavior is not accepted as correct product semantics. It is being handled in the separate RepositoryDiscovery candidate-semantics decision task before FormatDetection begins.
