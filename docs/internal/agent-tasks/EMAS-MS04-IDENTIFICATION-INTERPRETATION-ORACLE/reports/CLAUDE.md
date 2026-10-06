# Claude Report — T4a IdentificationInterpretation Oracle

**Status:** `ORACLE_COMPLETE — READY FOR CENTRAL REVIEW` (7 design blockers recorded, B-1 to B-7)
**Agent:** Claude (independent behavioral/oracle owner)
**Branch:** `analysis/emas-ms04-identification-interpretation-oracle`
**Based on:** prepared branch head `eb56581`, from the coordination branch, which contains the authoritative base `cff3456`
**Draft PR target:** `coordination/emas-ms04-identification-interpretation`
**Date:** 2026-10-06

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
| 21 cases × 3 files | `tests/identification-interpretation/oracle/cases/IDO-01 … IDO-21/` |
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

## Oracle cases (21)

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
| `python tests/identification-interpretation/oracle/validate_oracle.py` | **Passed: 21 cases** |
| `python -m unittest discover -s tests/identification-interpretation/oracle -p "test_*.py"` | **Ran 10, OK.** This includes 8 mutation tests proving the validator rejects `Outcome`/`SupportStatus`, numeric scores, unknown cited evidence, rewritten raw strength, unknown rules or wrong-dimension candidates, below-floor values, STRONG v4, non-deterministic ordering, and Conflict-with-value. |
| Runtime configs under the T3a validator | 21/21 valid (also checked inside the static validator) |

The static validator does not evaluate rules. It checks structure, references, ordering, invariants and hashes only. It is not wired into CI: workflows are outside T4a's allowed files.

## Unresolved design blockers (central review)

| ID | Question | Provisional default | Cases |
|---|---|---|---|
| B-1 | Accept the fixed `CEC-FIELD-PROJECTION/1` engine table (XmlId→XmlKind join), or add a governed selector later? | Fixed table | All |
| B-2 | Runtime cap of hit strength at the weakest cited normalized raw strength? | Cap applies | IDO-21 |
| B-3 | `ReviewRequired` for `NotAssessed` (including a dimension with no rule)? | `true` | IDO-11, 12, 13, 18 |
| B-4 | Physical-only v4 at MEDIUM: an Evaluated value with review, or `InsufficientEvidence`? | Evaluated + review (T3c MaxStrength MEDIUM; IR §9) | IDO-19 |
| B-5 | Confidence effect of a lower-tier (≥ floor) contradiction? | Review + `LowerTierContradiction`; confidence from policy | None |
| B-6 | Any machine difference between TieBehavior UNKNOWN and MANUAL_REVIEW? | None | None |
| B-7 | Is relationship-derived Region in bounded T4 scope while U2 is open? | Deferred | None |

Provisional cases carry `provisionalPendingBlockers` in the manifest, so only those expected files change if a default is overturned.

## Confirmation

- No file under `engine/**`, `scripts/**`, `config/**` or `build/**` was changed (`git diff` against the coordination base is empty for those paths).
- No schema, validator, workbook, VBA, CEC/scanner, report-mapping or production rule-pack file was changed.
- T3c U2–U9 are not resolved.
- Changed paths are limited to this task directory and `tests/identification-interpretation/oracle/**`.
