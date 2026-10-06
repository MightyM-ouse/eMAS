# Claude Launch — T4a IdentificationInterpretation Oracle

Work on:

`EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE`

Repository:

`MightyM-ouse/eMAS`

Base:

`coordination/emas-ms04-identification-interpretation`

Read this task's `TASK.md` and `STATUS.md` first, then the accepted Identification Rules, T3 runtime-design, T3a and T3b reports/reviews, T1a CEC contract, canonical configuration docs and Pre-Sales phase contract.

Your role is **independent behavioral/oracle owner**, not engine developer.

Use branch:

`analysis/emas-ms04-identification-interpretation-oracle`

Create the exact bounded behavioral contract and synthetic oracle fixtures defined in TASK.md.

Hard constraints:

- do not read or adapt to Codex implementation;
- do not modify `engine/**`;
- CEC facts remain immutable;
- normalize only at interpretation boundary: Strong→STRONG, Supporting→MEDIUM, Weak→WEAK;
- minimum final-value strength = MEDIUM;
- no numeric Identification weights/scores;
- no Outcome field;
- no SupportStatus field;
- dimension-scoped candidates only;
- Weak-only retains candidates but no final value;
- equal best incompatible evidence = Conflict;
- no T1b/T2/T3c U2–U9 decisions;
- physical v4 markers alone never prove Strong/final v4.

Open a draft PR into:

`coordination/emas-ms04-identification-interpretation`

Do not merge.

Return only the items requested in TASK.md.
