# ChatGPT Review — T4b IdentificationInterpretation Engine

**Status:** `CHANGES_REQUIRED — WAIT FOR T4A AMENDMENT/MERGE`  
**Reviewed Codex commit:** `4461547099b50ae99451602df51d85e003cfa6b6`  
**Reviewed PR:** #56

## Overall verdict

The core implementation is promising and materially aligned with the accepted T3/T3a/T3b design.

Central review confirms at the reviewed SHA:

- shared-core module exists and is PowerShell 5.1-oriented;
- CEC facts are not reopened or reparsed;
- raw evidence is preserved;
- Strong/Supporting/Weak normalization is engine-side;
- candidates are dimension-scoped;
- ordinal precedence is used with no numeric Identification score;
- MEDIUM floor behavior is implemented;
- equal-best and best-tier contradictions become Conflict;
- output uses separate `Identification/1.0`;
- no `Outcome` or `SupportStatus`;
- input/config immutability tests exist;
- focused engine tests pass 21/21 on macOS, Windows PowerShell 7.6 and Windows PowerShell 5.1;
- Windows PS5.1 overall CI remains red only at the known unrelated UTF-8 RuntimeConfiguration expectation.

The pre-merge 21/21 oracle trial is useful evidence, but it is not the formal gate because T4a is not yet accepted/merged.

T4b is **not ready for merge**.

## Required change E-1 — T4a final oracle gate

T4a has central-review amendments pending.

Codex must not finalize against the current provisional oracle.

After PR #55 is amended, accepted and merged into the coordination branch:

1. update this implementation branch from `coordination/emas-ms04-identification-interpretation`;
2. treat oracle files as read-only;
3. run the complete accepted oracle;
4. report the fixed accepted oracle commit/SHA;
5. fix implementation defects, never expected oracle output.

## Required change E-2 — MATCHES_PATTERN

The T4b TASK requires `MATCHES_PATTERN` as a bounded Identification operator.

The reviewed implementation rejects it through `IDI-CONFIG-004`.

Add support for valid string regex matching with:

- case-sensitive / case-insensitive behavior from the condition;
- deterministic .NET regex semantics compatible with Windows PowerShell 5.1 and PowerShell 7.6;
- safe failure with a stable configuration error for an invalid regex;
- focused engine test coverage;
- conformance to the amended T4a oracle case.

Do not broaden the task into numeric GT/GTE/LT/LTE/BETWEEN operators.

## Required change E-3 — Pre-Sales orchestration must not force deep checks

The current `-IncludeIdentificationInterpretation` integration causes the script to traverse:

RepositoryDiscovery → BackboneXmlInventory → ReferenceInventory → ReferenceResolution → MissingReferenceInterpretation → DeclaredChecksumComparison → ChecksumMismatchInterpretation → CEC → Identification

even when the caller requested only Identification.

That makes Identification implicitly depend on reference/checksum processing.

This conflicts with the Pre-Sales phase contract, which says referenced-file/checksum/deep validation must not become mandatory for the phase.

Required fix:

- when Identification is requested **without explicit deep-check switches**, use the shortest factual chain needed:
  `RepositoryDiscovery → BackboneXmlInventory → ClassificationEvidenceCollection → IdentificationInterpretation`;
- only execute reference/missing/checksum capabilities when the caller explicitly requests them;
- preserve existing behavior for callers who explicitly request the deeper switches;
- keep the Identification output as the separate terminal document.

If clean orchestration would require a risky broad script refactor, remove/defer the T4 script integration and leave the shared-core engine as the T4 baseline rather than making deep checks mandatory by accident.

Add a focused test proving Identification-only mode does not invoke/reference the deep-check capabilities.

## Required change E-4 — formal oracle CI

After T4a is merged, add the read-only oracle conformance harness to CI.

At minimum run it on:

- Windows PowerShell 5.1;
- Windows PowerShell 7.6;
- macOS PowerShell 7.6 development lane.

The known unrelated PS5.1 UTF-8 failure may remain, but the oracle step itself must report separately and pass.

## Central decisions inherited from T4a

Implement/follow the accepted T4a decisions after its amendment:

- B-1 fixed `CEC-FIELD-PROJECTION/1` accepted for bounded T4;
- B-2 runtime strength cap accepted;
- B-3 NotAssessed => ReviewRequired true;
- B-4 generic MEDIUM physical-v4 rule may evaluate if explicitly Effective, but production v4 rule content remains blocked by T2/governance;
- B-5 lower-tier contradiction sets review/limiting factor without automatic confidence rewrite;
- B-6 UNKNOWN and MANUAL_REVIEW tie behavior share the same Identification/1.0 machine result;
- B-7 relationship-derived Region is deferred from bounded T4.

Do not hard-code a special `ECTD_4_0` exception into the engine.

## Non-blocking provenance clarification

When `EvidenceSourceSha256` is not supplied, the module computes an in-memory object serialization hash.

Document this as evidence-source identity, not as an original source-file checksum.

When an exact ScannerObservations file hash is available, prefer passing that exact hash.

## Regression required after follow-up

Report:

- focused T4b engine tests;
- accepted T4a oracle conformance;
- RuntimeConfiguration tests;
- Schema tests;
- CEC tests;
- T3b POC tests;
- relevant scanner integration tests;
- macOS PS7.6;
- Windows PS7.6;
- Windows PS5.1 focused T4 tests/oracle gate.

Do not fix the unrelated PS5.1 UTF-8 assertion inside T4.

## Recommendation

Do **not** merge PR #56 yet.

First amend/accept/merge T4a. Then Codex refreshes from the coordination branch, implements E-2 through E-4, reruns the formal oracle gate, and returns a new fixed SHA for central review.
