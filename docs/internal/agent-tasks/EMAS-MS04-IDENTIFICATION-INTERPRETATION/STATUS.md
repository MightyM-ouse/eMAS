# T4 IdentificationInterpretation Coordination

**Roadmap ID:** `T4`  
**Authoritative base:** `cff3456df0852b4c9cc8399d8908bac09bf5720e`  
**Coordination branch:** `coordination/emas-ms04-identification-interpretation`  
**Overall status:** `T4A_ACCEPTED_MERGED_T4B_REFRESH_REQUIRED`  
**Coordination PR:** #54

## Execution model

Two workers may proceed in parallel because their primary file ownership is intentionally separated.

| Workstream | Worker | Role | Merge target |
|---|---|---|---|
| T4a — behavioral contract + independent oracle | Claude | ACCEPTED / MERGED | this coordination branch |
| T4b — IdentificationInterpretation engine | Codex | implementation owner | this coordination branch |
| Central reconciliation | ChatGPT | fixed-SHA review and oracle/engine reconciliation | user merge gate |

## Hard ownership rule

Claude does **not** edit engine implementation files.

Codex does **not** edit T4a oracle fixtures or rewrite expected outcomes.

If the implementation disagrees with the accepted oracle, the conflict is reviewed centrally. The implementation must not silently change the oracle to make tests pass.

## Dependencies

Accepted and merged:

- T1a factual CEC physical-marker evidence;
- T3 Identification runtime design;
- T3a Runtime JSON Schema 1.1.0 / validators / loader;
- T3b Schema 1.1.0 workbook authoring + governed export.

Accepted T3c prior-mapping disposition remains governance input and is not directly imported into T4.

## Integration gate

T4b may begin before T4a is merged, but T4b cannot become `READY_FOR_USER_DECISION` until:

1. T4a is centrally reviewed and merged into this coordination branch — **COMPLETE**;
2. the T4b implementation branch is refreshed from this coordination branch;
3. the T4b implementation passes the accepted 23-case T4a oracle;
4. ChatGPT reconciles any differences;
5. user explicitly approves the final coordination PR.

T4 does not make any production legacy-derived rule Effective.


## Prepared worker branches

- Claude / T4a: `analysis/emas-ms04-identification-interpretation-oracle`
- Codex / T4b: `implementation/emas-ms04-identification-interpretation-engine`

Both branches were created from the coordination head after the task documents were committed.


## T4a accepted baseline

PR #55 merged into this coordination branch.

Merge SHA:

`ce8d56c0df59d7e8635207baec853b07f17462de`

The accepted oracle contains 23 cases, including MATCHES_PATTERN success/failure coverage. T4b must treat these oracle files as read-only.
