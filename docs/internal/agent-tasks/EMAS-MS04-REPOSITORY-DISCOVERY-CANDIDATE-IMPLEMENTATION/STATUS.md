# Task Status

**Task ID:** `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION`  
**Authoritative base commit:** `70f1edf9584477d229ef8b321cb7172734669cca`  
**Overall status:** `MAC_ACCEPTED_WINDOWS_PENDING`

| Gate | Status |
|---|---|
| B3 semantics decision | ACCEPTED |
| Codex Mac implementation | COMPLETE |
| Focused B3 regression | PASS — 12/12 |
| RepositoryDiscovery regression | PASS — 13/13 |
| Wave 1 eight-suite regression | PASS — 275/275 |
| Root-level regression | PASS — 3/3 |
| Wave1D normative-v2 regression | PASS — 61/61 |
| ChatGPT central review | PASS |
| User acceptance | ACCEPTED |
| Windows PS 5.1 B3 qualification | DEFERRED |
| Automatic Windows runtime-contract CI | FAIL — unrelated UTF-8 runtime-config assertion; tracked separately |
| eCTD v4 discovery extension | NEXT REQUIRED TASK |
| FormatDetection / RegionDetection | BLOCKED |

## Accepted outcome

PR #37 is accepted as the Mac B3 RepositoryDiscovery implementation baseline.

The implementation includes:
- B3 structural promotion for the existing four-digit v3/NeeS discovery path;
- narrowed fail-open behavior for an unreadable exact sequence directory;
- case-insensitive structural signal matching;
- separation of unreadable from empty;
- SD-051 normative v2 behavior;
- year-wrapper regression coverage.

The automatic Windows PowerShell 5.1 runtime-contract failure is unrelated to this implementation. Native Windows B3 qualification remains deferred to the later consolidated Windows stage.

The next required work is the separate `EMAS-MS04-ECTD4-DISCOVERY-EXTENSION` task before FormatDetection or RegionDetection begins.
