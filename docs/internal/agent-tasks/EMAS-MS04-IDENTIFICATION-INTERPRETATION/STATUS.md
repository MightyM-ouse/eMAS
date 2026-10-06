# T4 IdentificationInterpretation Coordination

**Roadmap ID:** `T4`  
**Authoritative base:** `cff3456df0852b4c9cc8399d8908bac09bf5720e`  
**Coordination branch:** `coordination/emas-ms04-identification-interpretation`  
**Overall status:** `ACCEPTED_FOR_DEMO_MERGE`  
**Coordination PR:** #54

## Execution model

Two workers may proceed in parallel because their primary file ownership is intentionally separated.

| Workstream | Worker | Role | Merge target |
|---|---|---|---|
| T4a — behavioral contract + independent oracle | Claude | ACCEPTED / MERGED | this coordination branch |
| T4b — IdentificationInterpretation engine | Claude | ACCEPTED / MERGED; Codex initial implementation preserved | this coordination branch |
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
2. the T4b implementation branch is refreshed from this coordination branch — **COMPLETE**;
3. the T4b implementation passes the accepted 23-case T4a oracle — **COMPLETE**;
4. ChatGPT reconciles any differences — **T4B COMPLETE; FINAL COORDINATION CHECK PENDING**;
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


## T4b continuation ownership

Codex completed the initial T4b implementation but is unavailable for further work due token limits.

Remaining implementation ownership is transferred to Claude on the existing branch and PR:

- branch: `implementation/emas-ms04-identification-interpretation-engine`
- PR: #56
- accepted-oracle sync merge: `15964bf6ec8b0917de6eb0d83d4ed472c9849d2d`

Claude must treat the accepted T4a oracle as read-only and complete the remaining central-review items before final reconciliation.


## T4b central reconciliation

PR #56 has completed central review.

Reviewed implementation head before coordinator review/status commits:

`4ccdc3da0e8367cf06bb0a48812361c563f11b97`

Central result:

`REVIEW_PASS — READY_FOR_USER_DECISION`

Verified gates:

- focused T4b engine tests: 28/28;
- accepted T4a oracle: 23/23;
- Windows PowerShell 5.1 T4 engine/oracle: PASS;
- Windows PowerShell 7.6 T4 engine/oracle: PASS;
- macOS PowerShell 7.6 T4 engine/oracle: PASS;
- Identification-only short pipeline: PASS;
- accepted oracle remains read-only;
- PS5.1 aggregate job remains red only for the pre-existing UTF-8 RuntimeConfiguration expectation.

PR #56 received explicit user approval and is merged into this coordination branch.

T4b merge SHA:

`9841ffd98c517c16ab4d528a714d092f133e0432`


## Final T4 integration state

Both bounded T4 workstreams are now accepted and merged into the coordination branch:

- T4a behavioral contract + independent oracle: **ACCEPTED / MERGED**
- T4b IdentificationInterpretation engine: **ACCEPTED / MERGED**

The remaining gate is a final coordination-head CI/reconciliation review of PR #54 before any merge into `demo/end-to-end-mvp`.


## Final coordination review

Final review at coordination head `20dfcf2d2baf23435a205c6c90ca03581c7722d5` passed.

Coordination-head CI run `37531517624` confirms:

- Windows PowerShell 5.1 T4 engine: 28/28 PASS;
- Windows PowerShell 5.1 accepted oracle: 23/23 PASS;
- Windows PowerShell 7.6: green;
- macOS PowerShell 7.6: green;
- static runtime contracts: green;
- only the pre-existing PS5.1 UTF-8 RuntimeConfiguration expectation remains red.

Parent PR #54 is ready for explicit user merge decision.


Final post-review documentation head CI completed with the same accepted result profile. No T4-specific failure remains.


## User decision

Accepted. Parent PR #54 is approved for merge into `demo/end-to-end-mvp` as the integrated T4 IdentificationInterpretation baseline.
