# Task Status

**Task ID:** `EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D`  
**Authoritative base commit:** `793e065db17fed043ea95f9494f0e5f1458f0b72`  
**Task phase:** Prepared for single-worker Mac execution  
**Overall status:** `READY_FOR_CLAUDE`

| Gate | Role | Status | Deliverable |
|---|---|---|---|
| Coordination | Publish authoritative task | PREPARED | `TASK.md`, `STATUS.md`, `CLAUDE_LAUNCH.md` |
| Claude | Build/freeze SD-044–SD-051 and validate on Mac | NOT_STARTED | Implementation PR + `reports/CLAUDE.md` |
| ChatGPT | Central GitHub review | BLOCKED_ON_CLAUDE_PR | `reports/REVIEW.md` |
| User | Accept/reject Mac fixture baseline | NOT_READY | Explicit decision |
| Windows PS 5.1 | Consolidated later qualification | DEFERRED | Future Windows stage |

## Baseline

- Base commit includes the accepted root-level dossier fix: `793e065db17fed043ea95f9494f0e5f1458f0b72`.
- Existing accepted Wave 1 corpus: 19 frozen fixtures.
- Existing accepted automated suites: 8.
- Qualified Wave 1 test-data package SHA-256: `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7`.
- FormatDetection: not implemented in this task.
- RegionDetection: not implemented in this task.

## Fixture scope

Mandatory: SD-044 through SD-051.

- SD-044 neutral name
- SD-045 misleading name
- SD-046 wrappers
- SD-047 asymmetric multi-dossier
- SD-048 unrelated content
- SD-049 safe ASCII name variation
- SD-050 root-level dossier
- SD-051 Archive/2019 characterization

SD-052 nested dossier is deferred.

## Current gate

Claude must first prove the existing 8-suite / 19-fixture Mac baseline, then independently derive expectations, build the new wave, validate it, prove deterministic hashes, and publish a draft implementation PR.

Runtime code changes are forbidden. If the fixture wave exposes a new runtime defect, report it instead of fixing it inside this task.
