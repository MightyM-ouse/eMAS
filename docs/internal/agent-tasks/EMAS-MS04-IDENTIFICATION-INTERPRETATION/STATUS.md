# T4 IdentificationInterpretation Coordination

**Roadmap ID:** `T4`  
**Authoritative base:** `cff3456df0852b4c9cc8399d8908bac09bf5720e`  
**Coordination branch:** `coordination/emas-ms04-identification-interpretation`  
**Overall status:** `READY_FOR_PARALLEL_T4A_T4B`

## Execution model

Two workers may proceed in parallel because their primary file ownership is intentionally separated.

| Workstream | Worker | Role | Merge target |
|---|---|---|---|
| T4a — behavioral contract + independent oracle | Claude | independent specification/oracle owner | this coordination branch |
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

1. T4a is centrally reviewed and merged into this coordination branch;
2. Codex updates its branch from the coordination branch;
3. the T4b implementation passes the independent T4a oracle;
4. ChatGPT reconciles any differences;
5. user explicitly approves the final coordination PR.

T4 does not make any production legacy-derived rule Effective.
