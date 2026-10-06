# Claude Report — T4a IdentificationInterpretation Oracle

**Status:** `ORACLE_AMENDED — READY FOR CENTRAL RE-REVIEW` (revision 1.1: central decisions B-1 to B-7 and amendments A-1 to A-3 applied; no open blocker)
**Agent:** Claude (independent behavioral/oracle owner)
**Branch:** `analysis/emas-ms04-identification-interpretation-oracle`
**Based on:** prepared branch head `eb56581`, from the coordination branch, which contains the authoritative base `cff3456`
**Draft PR target:** `coordination/emas-ms04-identification-interpretation`
**Date:** 2026-10-06

## Revision 1.1 — central-review amendments (REVIEW.md)

I changed only T4a-owned files: this task directory and `tests/identification-interpretation/oracle/**`.

| Item | Change |
|---|---|
| B-1 to B-7 | Frozen in `BEHAVIOR_CONTRACT.md` exactly as decided: B-1 fixed projection accepted for bounded T4 (revisit before T1b/T2); B-2 runtime cap; B-3 `NotAssessed` → review; B-4 generic MEDIUM v4 semantics with the production-governance caveat; B-5 lower-tier contradiction keeps policy confidence and adds review; B-6 same Conflict result for both tie behaviors; B-7 relationship-derived Region deferred. §15 is now "Central decisions (closed)". The manifest's `provisionalPendingBlockers` became `centralDecisions`. |
| A-1 `MATCHES_PATTERN` | New §6.1: explicit `[regex]::new(pattern, options, 1 s timeout).IsMatch(v)`; `CultureInvariant`, plus `IgnoreCase` only when `caseSensitive = false`; unanchored; String fields only; PowerShell `-match` is forbidden. Invalid pattern → `IDI-CONFIG-005` (catch `ArgumentException`, which covers .NET Framework and .NET 5+ `RegexParseException`), validated up front and never treated as False/Unknown. Match timeout → `IDI-CONFIG-006`. GT/GTE/LT/LTE/BETWEEN stay out of scope. |
| A-2 physical v4 | V1 split into the generic engine rule (≤ MEDIUM, never STRONG/HIGH; any value emitted is governed by Effective content) and unchanged production governance (R-FMT-02 RE_MODEL; Strong v4 needs T2). The "final v4 value" wording is removed. |
| A-3 evidence hash | §13 states that `DocumentSha256` is provenance identity: file bytes when file-backed, otherwise a deterministic serialization hash, and never proof of an original customer file. |
| New cases | **IDO-22** (Output): a case-insensitive pattern matches and cites EVD-0004; the same pattern case-sensitive does not fire. **IDO-23** (Failure): an unbalanced-group pattern → `IDI-CONFIG-005`, no output document. |

.NET behavior was checked on PowerShell 7.5.2:
- case-insensitive `IsMatch` → True;
- case-sensitive → False;
- the invalid pattern throws `RegexParseException`;
- `-match` is case-insensitive by default, which is why §6.1 forbids it.

Windows PowerShell 5.1 was not available locally. §6.1 relies only on APIs and options present in .NET Framework 4.5+.

## Independence statement

I did not read or inspect the T4b engine branch, its task files or any implementation. Expected outcomes are derived only from accepted decisions and canonical documents. The only executable code I ran against repository modules was:

1. the existing Pre-Sales entry script, run once on a throw-away synthetic dossier to capture the exact CEC record and coverage envelope;
2. the unmodified T3a validator, used to check each synthetic runtime config.

## Deliverables

| Deliverable | Path |
|---|---|
| Behavioral contract + exact Identification/1.0 shape | `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE/BEHAVIOR_CONTRACT.md` |
| Machine contract (frozen JSON Schema) | `tests/identification-interpretation/oracle/identification-1.0.schema.json` |
| Oracle manifest | `tests/identification-interpretation/oracle/manifest.json` |
| 23 cases × 3 files (22 Output, 1 Failure) | `tests/identification-interpretation/oracle/cases/IDO-01 … IDO-23/` |
| Static validator + tests | `tests/identification-interpretation/oracle/validate_oracle.py`, `test_oracle_static.py` |
| README | `tests/identification-interpretation/oracle/README.md` |

## Source basis

| Source | Use |
|---|---|
| Identification Rules report + review (amendments 1–7) | Unified capability; canonical status model; Weak-only floor; raw-strength preservation; dimension-specific aggregation (deferred); Region ≠ RegionalImplementation; separate output contract |
| T3 runtime-design report + review | Identification/1.0 minimal concepts; no `Outcome`/`SupportStatus`; `ORDINAL_TIER/1` naming; `EVIDENCE-STRENGTH-NORMALIZATION/1`; no numeric weights |
| T3a review | Dimension-scoped resolution; ceiling semantics (negated = guard, `MISSING` = evidence, weakest across OR branches); no numeric Identification weights |
| T3b review | Effective-only governed export; synthetic policy rows are not production content; Reviewed-in-DEV deferred |
| T3c review | MEDIUM final-value floor (amendment 1); physical v4 cannot give Strong/final; U2–U9 open; Region via relationship assigned to T4 (B-7) |
| T1a CEC module + a live probe | Exact record fields (`EvidenceId`, `EvidenceType`, `Strength`, `SourceTier`, `CaptureStatus`, `XmlId`, …) and coverage (`CollectionStatus`) |
| Enterprise Requirements v3.1 §8; FR-CLASS-005…008; Pre-Sales phase contract §7 | Status/RAG/confidence separation; unknowns stay visible; missing evidence is not a negative finding |

## Contract shape summary

- **Top level:** `ContractId`, `Execution`, `EvidenceSource` (scanner contract, ExecutionId, document SHA-256), `RuntimeConfig` (ID, 1.1.0, mapping version, export type, SHA-256), `Normalization` (policy, version and fixed mapping), `FieldProjection` (`CEC-FIELD-PROJECTION/1`), `Results`.
- **Per result:**
  - `IdentificationId`, `SubjectType` (`Sequence`), `SubjectId`, `DossierId`, `Dimension` (canonical code);
  - `EvaluationStatus` (`Evaluated` / `InsufficientEvidence` / `Conflict` / `NotAssessed`);
  - `Value`, `ValueSet` (always null in bounded T4), `Confidence`, `ReviewRequired`, `ValueSource`;
  - `Candidates` (raw and normalized strength per cited evidence item);
  - `SupportingEvidenceIds`, `ContradictingEvidenceIds`, `UnavailableEvidence`, `FiredRuleIds`;
  - `ScoreSummary` (`ORDINAL_TIER/1`, `BestStrength`, `TierRank`, `CountByStrength`, `IndependentSourceClassCount`; **no numeric score**);
  - `LimitingFactors` (closed vocabulary).
- **Absent by design:** `Outcome`, `SupportStatus` and `Projections`. TechnicalFormat, SpecificationProfile and DossierContext are derived only by the report layer.

## Decisions encoded

| Area | Encoded behavior |
|---|---|
| Normalization | `Strong→STRONG`, `Supporting→MEDIUM`, `Weak→WEAK`. Raw values are copied verbatim. An unmapped raw strength makes the field Unavailable with `UnmappedStrength` and the EvidenceId; nothing is guessed. |
| Floor | `minimumEvidenceStrengthForValue`, default `MEDIUM`. If best support is below it → `InsufficientEvidence`, Value null, Confidence `UNKNOWN`, `ReviewRequired = true`, candidates kept. |
| Precedence | Ordinal STRONG > MEDIUM > WEAK only. No priority, order or numeric tie-break. |
| Conflict | More than one candidate at the best strength, or the top candidate contradicted at ≥ its support strength → `Conflict`, Value null, `ReviewRequired = true`. TieBehavior has no machine effect. |
| Confidence | Only from IDENTIFICATION policy rows keyed on best strength: the `INDEPENDENT_SOURCE_CLASS` row when ≥ 2 distinct CEC `SourceTier` values at or above the floor, otherwise `NONE_REQUIRED`, otherwise `UNKNOWN`. |
| ReviewRequired | False only for a `STRONG` Evaluated result with no lower-tier contradiction and a matched policy row. A `MEDIUM`-best Evaluated result requires review (accepted IR §7 "Probable" mapping). |
| Availability | Three field states: Available / AssessedAbsent / Unavailable, taken from CEC coverage. `MISSING` fires only on assessed absence. Not collected → `NotAssessed`. |
| Guards / OR | Negated conditions affect firing but are never cited and never change strength. Only True groups are cited. |
| Dimensions | Results per `IDENTIFICATION_DIMENSION` code; dimension-scoped candidates; same code in two dimensions → independent results. A configured dimension with no rule → `NotAssessed` (`NoIdentificationRuleConfigured`); `NotApplicable` is not produced. |
| v4 | Physical markers can never yield STRONG or HIGH v4 (raw `Supporting`/`Weak` plus the runtime cap). The MEDIUM-only value question is B-4. |
| Determinism | Fixed orderings and IDs; semantic equality after removing three volatile execution fields; a shuffled-input equivalence case. |

## Oracle cases (23)

| Case | Covers | Expected |
|---|---|---|
| IDO-01 | Strong single candidate | Evaluated ICH_ECTD_3_2_2, MEDIUM (single source class) |
| IDO-02 | Supporting → MEDIUM | Evaluated, cited `Supporting/MEDIUM`, LOW, review |
| IDO-03 | Weak-only | InsufficientEvidence, candidate kept, `BelowEvidenceFloor` |
| IDO-04 | Strong vs Medium | Evaluated Strong candidate; both candidates listed |
| IDO-05 | Medium vs Weak | Evaluated Medium candidate, LOW, review |
| IDO-06 | Equal best different values | Conflict, `EqualBestStrengthCandidates` |
| IDO-07 | Support + equal contradiction | Conflict, `SupportContradictedAtBestStrength` |
| IDO-08 | `OTHER` in two dimensions | Two independent Evaluated results |
| IDO-09 | Independent-source corroboration | HIGH (2 source tiers) |
| IDO-10 | Single-source Strong | LOW from its explicit synthetic row (not HIGH) |
| IDO-11 | Unmapped raw strength | NotAssessed, `UnmappedStrength` with EvidenceId *(B-3)* |
| IDO-12 | XML access denied | NotAssessed, `AccessDenied` fields *(B-3)* |
| IDO-13 | `MISSING`: assessed absence vs ParseFailed | SEQ-0001 Evaluated; SEQ-0002 NotAssessed *(B-3)* |
| IDO-14 | Negated guard | Evaluated STRONG; guard record not cited |
| IDO-15 | OR groups | Only the fired group's record cited |
| IDO-16 | Shuffled evidence/coverage order | Equal to IDO-09 apart from the input hash |
| IDO-17 | Same value from two rules | One candidate with both rules |
| IDO-18 | Configured dimension without rules | NotAssessed `NoIdentificationRuleConfigured` *(B-3)* |
| IDO-19 | Physical v4 marker only | Not STRONG/HIGH; MEDIUM Evaluated with review *(B-4)* |
| IDO-20 | Ordinal summary; non-Identification numeric rows ignored | Counts 1/1/1, no numeric score |
| IDO-21 | Declared STRONG on raw Supporting | Capped to MEDIUM, `StrengthCappedByEvidence` *(B-2)* |
| IDO-22 | `MATCHES_PATTERN`, case-insensitive vs case-sensitive | Evaluated ICH_ECTD_3_2_2 from the case-insensitive rule only; namespace evidence cited |
| IDO-23 | Invalid `MATCHES_PATTERN` regex | Failure `IDI-CONFIG-005`, no output document |

All inputs are synthetic. No customer data, prior rule payloads or R-REG/FMT/TYP logic is used. Confidence rows are synthetic test policy, explicitly not approved content.

## CEC projection contract

`CEC-FIELD-PROJECTION/1` binds 10 field codes, including:
- common and regional XML root and namespace;
- common backbone presence;
- dossier root path;
- unit kind;
- the submission-unit, checksum and TOC markers.

**Gap (B-1):** the runtime field catalogue has no selector column, and CEC records do not carry `XmlKind`. The binding is therefore a fixed, versioned engine table. Common versus regional XML is selected by an explicit `XmlId → XmlDocuments.XmlKind` join inside the same ScannerObservations document; this is not reparsing. CEC `Dimension` hints are never used to choose a dimension.

## Static validation result

| Command | Result |
|---|---|
| `python tests/identification-interpretation/oracle/validate_oracle.py` | **Passed: 23 cases** (revision 1.1) |
| `python -m unittest discover -s tests/identification-interpretation/oracle -p "test_*.py"` | **Ran 14, OK.** Mutation tests prove the validator rejects: `Outcome`/`SupportStatus`; numeric scores; unknown cited evidence; rewritten raw strength; unknown rules or wrong-dimension candidates; below-floor values; STRONG v4; non-deterministic ordering; Conflict-with-value; unstable failure codes; an output for a failure case; a wrong pattern-rule attribution. A further test checks that every central decision is closed in the contract. |
| Runtime configs under the T3a validator | 23/23 valid (also checked inside the static validator) |
| T3a Schema 1.1 fixture suite (`python build/validate_emas_schema.py`) | 43/43 passed |

The static validator does not evaluate rules. It checks structure, references, ordering, invariants and hashes only. It is not wired into CI: workflows are outside T4a's allowed files.

## Design blockers

None open. B-1 to B-7 are closed as recorded in REVIEW.md and frozen in `BEHAVIOR_CONTRACT.md` §15. B-7 is closed as **DEFERRED** from bounded T4.

## Confirmation

- No file under `engine/**`, `scripts/**`, `config/**` or `build/**` was changed (`git diff` against the coordination base is empty for those paths).
- No schema, validator, workbook, VBA, CEC/scanner, report-mapping or production rule-pack file was changed.
- T3c U2–U9 are not resolved.
- Changed paths are limited to this task directory and `tests/identification-interpretation/oracle/**`.
