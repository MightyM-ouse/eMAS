# Task Status

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION`  
**Authoritative base commit:** `e369ae3ebb8394fb7b241bf9fbb60d698ec53690`  
**Overall status:** `MAC_ACCEPTED_WINDOWS_PENDING`

| Gate | Status |
|---|---|
| v4 physical-discovery design | ACCEPTED |
| Codex source-version verification | PASS — NO MATERIAL PHYSICAL-LAYOUT DIFFERENCE |
| Codex Mac implementation | COMPLETE |
| Wave1E SD-053–SD-074 | FROZEN — DETERMINISTIC |
| focused v4 discovery | PASS — 22/22 + 2/2 |
| RepositoryDiscovery | PASS — 13/13 |
| B3 | PASS — 12/12 |
| Wave1 | PASS — 275/275 |
| root-level | PASS — 3/3 |
| Wave1D | PASS — 61/61 |
| ChatGPT central review | PASS |
| User acceptance | ACCEPTED |
| Automatic Windows PS5.1 runtime-contract CI | FAIL — unrelated existing UTF-8 assertion |
| Native Windows v4 qualification | DEFERRED |
| FormatDetection | NEXT PHASE AFTER IDENTIFICATION RULES |
| RegionDetection | NEXT PHASE AFTER IDENTIFICATION RULES |
| v4 ReferenceResolution semantics | REQUIRED LATER |

## Accepted outcome

PR #41 is accepted as the Mac eCTD v4 physical-discovery baseline.

The implementation includes:
- source-verified v4 physical submission-unit discovery;
- confirmed, damaged/v4-like, and ambiguous structural unit kinds;
- misplaced-marker observation;
- preservation of accepted v3/NeeS B3 behavior;
- protection from false v3 BackboneXmlInventory processing;
- deterministic Wave1E SD-053–SD-074.

The automatic Windows PowerShell 5.1 runtime-contract failure is unrelated to this implementation. Native Windows v4 qualification remains deferred to the later consolidated Windows stage.

The next logical task is `EMAS-MS04-IDENTIFICATION-RULES` before FormatDetection/RegionDetection implementation.
