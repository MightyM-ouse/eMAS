# ChatGPT Review — T4a IdentificationInterpretation Oracle

**Status:** `ACCEPTED — READY_FOR_USER_MERGE_DECISION`  
**Reviewed Claude commit:** `5491cce41d70432bf21af3c78f132f09dce3fe2c`  
**Reviewed PR:** #55

## Overall verdict

T4a is accepted as the bounded behavioral-contract and independent-oracle baseline for `IdentificationInterpretation`.

Claude correctly incorporated the central-review decisions and amendments without touching implementation-owned paths.

## Scope verification

Compared with the previously reviewed oracle commit `a067baf11f6b964cddab9c805902e236f3599610`, the follow-up changes are limited to:

- the T4a task documentation;
- oracle README/manifest/static validator/tests;
- new oracle cases `IDO-22` and `IDO-23`.

The existing IDO-01 through IDO-21 case folders are unchanged.

No file under:

- `engine/**`
- `scripts/**`
- `config/**`
- `build/**`

was modified by the follow-up.

## Accepted central decisions

The contract now freezes all seven bounded-T4 decisions:

- **B-1:** fixed `CEC-FIELD-PROJECTION/1` accepted for bounded T4, with selector-governance revisit before T1b/T2 materially expand the field catalogue.
- **B-2:** runtime hit strength is capped by the weakest cited normalized evidence.
- **B-3:** `NotAssessed` always requires review.
- **B-4:** generic Effective MEDIUM physical-v4 rules may evaluate, while production v4 content remains governed and Strong v4 still requires T2.
- **B-5:** lower-tier contradiction retains policy-derived confidence, adds review and a limiting factor.
- **B-6:** `UNKNOWN` and `MANUAL_REVIEW` tie behavior share the same `Identification/1.0` machine result.
- **B-7:** relationship-derived Region is deferred from bounded T4 while U2 remains open.

These decisions are no longer provisional.

## MATCHES_PATTERN amendment

Accepted.

The contract now defines deterministic bounded regex behavior:

- explicit `System.Text.RegularExpressions.Regex`;
- `CultureInvariant`;
- `IgnoreCase` only when `caseSensitive = false`;
- 1-second match timeout;
- unanchored `IsMatch` semantics;
- String fields only;
- invalid patterns fail before evaluation with stable `IDI-CONFIG-005`;
- regex timeout fails with `IDI-CONFIG-006`;
- no PowerShell `-match` semantics;
- numeric comparison operators remain out of scope.

New independent cases:

- **IDO-22:** proves case-insensitive match fires and cites evidence while the case-sensitive equivalent does not fire.
- **IDO-23:** proves invalid regex fails with `IDI-CONFIG-005` and produces no Identification output.

## Provenance clarification

Accepted.

`EvidenceSource.DocumentSha256` is now clearly defined as evidence-document provenance identity:

- exact file-byte hash when the ScannerObservations file hash is known;
- deterministic serialization hash only for an in-memory object when no file hash is supplied;
- never proof of the original customer repository.

## Validation reviewed

Claude reports:

- Runtime Schema 1.1 fixture validation: **43/43 pass**
- Schema unit tests: **44 OK**
- Oracle runtime configurations: **23/23 valid**
- Oracle static validation: **23 cases pass**
- Oracle static/mutation tests: **14/14 OK**

The static oracle validator remains intentionally non-evaluating: it verifies fixture structure, references, ordering, hashes and invariants, but is not a second rule engine.

Windows PowerShell 5.1 was not available for Claude's local regex probe. This is **not a blocker for T4a acceptance** because T4a owns the behavioral contract and static oracle, not the engine implementation. Cross-runtime execution remains a mandatory T4b conformance gate after the accepted oracle is merged.

## Independence

The oracle remains independent of T4b implementation:

- expected outputs are hand-authored;
- no engine implementation file was inspected or modified for the follow-up;
- T4a does not repair T4b behavior.

That separation is required for the oracle to remain useful as an external behavioral judge rather than a second copy of the implementation.

## Final recommendation

**Accept PR #55 as the T4a bounded behavioral-contract + independent-oracle baseline and merge it into `coordination/emas-ms04-identification-interpretation`.**

After that merge, the T4b implementation owner must refresh from the coordination branch and pass the complete accepted 23-case oracle without changing oracle expected outputs.
