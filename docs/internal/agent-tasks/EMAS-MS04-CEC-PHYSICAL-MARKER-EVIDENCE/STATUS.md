# Task Status

**Task ID:** `EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE`  
**Roadmap ID:** T1a  
**Authoritative base:** `8a8c842b45e2cbf12025c15995cf99b0b8012b55`  
**Overall status:** `MAC_ACCEPTED_WINDOWS_PENDING`

| Gate | Status |
|---|---|
| Identification Rules design | ACCEPTED |
| Codex implementation | COMPLETE |
| focused CEC tests | PASS — 19/19 + 38/38 |
| Wave 1 | PASS — 275/275 + 16/16 FREEZE |
| root-level | PASS — 3/3 |
| Wave1D | PASS — 61/61 |
| v4 discovery | PASS — 22/22 + 2/2 |
| B3 | PASS — 12/12 |
| frozen hashes | PASS — W1 19/19, W1D 8/8, W1E 22/22 |
| ChatGPT central review | PASS |
| User merge decision | ACCEPTED |
| Windows PS5.1 | DEFERRED — unrelated RuntimeConfiguration UTF-8 issue |
| T4 IdentificationInterpretation | BLOCKED_ON_T3A_AND_T3B |

## Accepted outcome

PR #47 is accepted as the Mac T1a factual physical-marker evidence baseline.

The accepted implementation preserves the factual/interpretation boundary, keeps raw CEC strength values unchanged, adds the approved five physical-marker evidence types, and retains historical regression expectations through an explicit historical projection while validating the full additive result separately.

Native Windows qualification remains deferred.
