# Codex Launch — T4b IdentificationInterpretation Engine

Work on:

`EMAS-MS04-IDENTIFICATION-INTERPRETATION-ENGINE`

Repository:

`MightyM-ouse/eMAS`

Base:

`coordination/emas-ms04-identification-interpretation`

Read this task's `TASK.md` and `STATUS.md` first, plus the accepted Identification Rules, T3 runtime-design, T3a/T3b reviews, T1a CEC contract, RuntimeConfiguration API, canonical docs and Pre-Sales phase contract.

Use branch:

`implementation/emas-ms04-identification-interpretation-engine`

You are the **single engine implementation owner**.

Claude is independently producing T4a oracle fixtures. You may begin the core engine in parallel, but do not finalize the task until T4a is accepted and merged into the coordination branch.

Hard constraints:

- shared-core, Windows PowerShell 5.1-compatible engine;
- consume CEC facts + validated Schema 1.1.0 runtime config only;
- never reopen source/reparse XML;
- preserve raw CEC evidence;
- normalization Strong→STRONG, Supporting→MEDIUM, Weak→WEAK;
- ordinal only, no numeric Identification weights;
- floor = configured MEDIUM baseline;
- dimension-scoped candidates;
- no Outcome;
- no SupportStatus;
- Weak-only candidates retained but no final value;
- ties/contradictions at best tier become Conflict;
- separate Identification/1.0 output;
- do not modify Claude oracle files;
- do not implement T1b/T2 or T3c U2–U9.

Open a draft PR into:

`coordination/emas-ms04-identification-interpretation`

Do not merge.

When T4a is merged:
1. update your branch from the coordination branch;
2. run every independent oracle case;
3. fix implementation defects rather than changing the oracle;
4. report any genuine oracle/design contradiction for central review.

Return only the items requested in TASK.md.
