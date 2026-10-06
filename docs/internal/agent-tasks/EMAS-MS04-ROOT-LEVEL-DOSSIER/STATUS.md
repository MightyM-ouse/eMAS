# Task Status

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`  
**Authoritative baseline commit:** `dac1664fee652f701a41204e2527f602077bb42f`  
**Task phase:** Mac-first bounded defect resolution  
**Overall status:** `READY_FOR_CODEX_RESTART`

| Gate | Role | Status | Evidence |
|---|---|---|---|
| RC1 baseline materialization | Exact qualified source/tests committed via PR #29 | COMPLETE | Merge commit `dac1664fee652f701a41204e2527f602077bb42f` |
| Codex | Reproduce, minimally fix, focused + full Mac regression | READY_TO_RESTART | `reports/CODEX.md` + implementation PR |
| ChatGPT | Central GitHub review and reconciliation | BLOCKED_ON_CODEX_PR | Chat review |
| Windows PowerShell 5.1 | Native qualification | DEFERRED_UNTIL_MAC_BASELINE_ACCEPTED | Later Windows run |
| User | Accept Mac implementation baseline / authorize Windows qualification | NOT_READY | Explicit decision |

## Accepted baseline

- Contract: `eMAS.MS04.PreSales.ScannerObservations/1.0`
- Scanner version: `0.8.0`
- Accepted capabilities: 8
- Frozen Wave 1 fixtures: 19
- Existing automated suites: 8
- Prior Windows qualification: `PASS_WINDOWS_PS51_AUTOMATED_REGRESSION`
- RC1 source/test baseline is now repository-native via PR #29.

## Current gate

Restart Codex from the materialized baseline. First rerun the eight existing suites on Mac, then reproduce and fix only the two root-level dossier defects.

The previous blocked PR #28 is historical evidence only and was closed without merge.

## Completion rule for this stage

This Mac stage is complete when Codex publishes a bounded implementation PR, focused tests pass, all eight existing suites pass on Mac, frozen inputs remain unchanged, and ChatGPT review finds no unresolved blocker.

Windows PowerShell 5.1 requalification is a later explicit stage.
