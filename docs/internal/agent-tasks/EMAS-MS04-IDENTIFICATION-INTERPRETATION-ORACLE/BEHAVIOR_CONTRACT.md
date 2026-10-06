# IdentificationInterpretation — Bounded Behavioral Contract (T4a)

**Contract:** `IDI-BEHAVIOR/1.0` for the bounded MS-04 Pre-Sales T4 engine
**Output contract:** `eMAS.MS04.PreSales.Identification/1.0`
**Input contracts:** `eMAS.MS04.PreSales.ScannerObservations/1.0` (unchanged) and Runtime JSON Schema `1.1.0`
**Owner:** T4a oracle (Claude). It was written independently of the T4b implementation.
**Status:** Revision 1.1. Central-review decisions B-1 to B-7 and amendments A-1 to A-3 (REVIEW.md) are incorporated. No open blocker remains (§15).

Each clause has an ID, for example `F1`. The oracle manifest cites these IDs per case. "Accepted" refers to:
- the Identification Rules review (IR-REV) amendments 1–7;
- the T3 runtime-design review (T3-REV) amendments 1–7;
- the T3a review, the T3b review, and the T3c review (T3c-REV);
- the T1a CEC contract.

---

## 1. Scope

The bounded engine reads **one** ScannerObservations document, which must contain ClassificationEvidenceCollection (CEC) evidence, and **one** validated Schema 1.1.0 runtime configuration. It writes **one** Identification/1.0 document.

It:
- evaluates Effective `IDENTIFICATION` rules for the `PRE_SALES` phase;
- produces one result per *(Sequence subject × configured identification dimension)*;
- never reopens source files, never parses XML, never mutates CEC records, never writes into the ScannerObservations document, and never reads the workbook.

---

## 2. Inputs (I)

**I1 — Accepted inputs.**

| Input | Requirement |
|---|---|
| ScannerObservations | `ContractId = eMAS.MS04.PreSales.ScannerObservations/1.0`; `Execution.ScenarioId = MS-04`; `Execution.Phase = PreSales`; `Execution.Capabilities` contains `ClassificationEvidenceCollection`. Uses `Sequences`, `DossierCandidates`, `XmlDocuments`, `ClassificationEvidence` and `CollectionCoverage`. |
| Runtime configuration | Already accepted by the RuntimeConfiguration loader and valid under Schema `1.1.0` (T3a). `configuration.schemaVersion = 1.1.0`. |
| Rule set | Rules with `ruleType = IDENTIFICATION` and a `rulePhases` row with `phase = PRE_SALES`. The governed export already guarantees Effective/date eligibility (T3b), so the engine does not re-filter lifecycle or dates (§14 D-5). |
| Dimensions | Codes of value list `IDENTIFICATION_DIMENSION`, ordered by `sortOrder`, then code. |
| Conflict policy | Exactly one `conflictPolicies` row with `ruleType = IDENTIFICATION`. |
| Confidence policy | `confidencePolicies` rows with `scope = IDENTIFICATION`. Rows of any other scope are ignored (W1). |

**I2 — Failure boundary (fail fast: no output document; an error with a stable code).**

| Code | Condition |
|---|---|
| `IDI-INPUT-001` | Scanner `ContractId` is not ScannerObservations/1.0 |
| `IDI-INPUT-002` | Not MS-04 / PreSales |
| `IDI-INPUT-003` | `ClassificationEvidenceCollection` capability absent |
| `IDI-INPUT-004` | Duplicate `EvidenceId`, or an evidence record references an unknown Sequence/Dossier/XmlDocument |
| `IDI-CONFIG-001` | Runtime config `schemaVersion ≠ 1.1.0` |
| `IDI-CONFIG-002` | Number of IDENTIFICATION conflict policies ≠ 1 |
| `IDI-CONFIG-003` | Two IDENTIFICATION confidence rows share the same (`evidenceStrength`, `corroborationRule`) |
| `IDI-CONFIG-004` | A field used by an IDENTIFICATION rule has no CEC-FIELD-PROJECTION/1 binding (§4); or an operator outside §6 is used; or an operator is applied to an incompatible field type (for example `MATCHES_PATTERN` on a Boolean field) |
| `IDI-CONFIG-005` | A `MATCHES_PATTERN` condition has a null or empty `value1`, a non-String `valueDataType`, or a pattern that is not a valid .NET regular expression (§6.1) |
| `IDI-CONFIG-006` | A `MATCHES_PATTERN` evaluation exceeds the fixed match timeout (§6.1) |

Configuration validation (IDI-CONFIG-001 to 005) runs **before** any rule is evaluated. Every `MATCHES_PATTERN` condition of every IDENTIFICATION rule is compiled up front, so an invalid pattern fails the run even if the rule would never be reached. A failed run writes **no** Identification document; an invalid pattern is never treated as False or Unknown. The error message names the `RuleId` and `ConditionId`.

Evidence gaps (unavailable, unmapped, not collected) are **never** failures. They become result content (A1–A3).

**W1 — Non-Identification content is ignored.** Classification rules, numeric `weightOrScore` on non-Identification confidence rows, and `outputValue` on non-Identification outputs never influence Identification results.

---

## 3. Subjects (P1)

**P1 — Subject partitioning.**
- Subjects are the scanner `Sequences`. `SubjectType = "Sequence"`, `SubjectId = SequenceId`, `DossierId` = the Sequence's `DossierId`.
- A subject's evidence context is:
  - the CEC records with `SequenceId = SubjectId`; **plus**
  - dossier-level records with `SequenceId = null` and `DossierId` = the subject's dossier (for example `DossierRootPath`).
- Each subject is evaluated independently.
- Dossier-level aggregation is **deferred** (D-1). Bounded T4 produces no `SubjectType = Dossier` results.

**P3 / D1 — Dimension scoping.**
- A rule contributes only to the dimension given by its output `targetEntityType`. Schema 1.1.0 guarantees this equals `conflictGroup`.
- Candidates are keyed by *(dimension, outputCode)*. Two dimensions may hold the same code string. Their results are independent, and there is **no** global code uniqueness.
- The CEC record field `Dimension` (`TechnicalFormat`, `Region`, …) is an uninterpreted CEC hint. The engine never uses it to choose a dimension.

---

## 4. CEC-to-field projection (`CEC-FIELD-PROJECTION/1`)

The runtime field catalogue has no selector column binding a `FieldCode` to CEC records. The bounded engine therefore uses this **fixed, versioned binding table**, recorded in the output as `FieldProjection {PolicyId, Version}`. Changing it is an engine release, not a workbook edit.

**Decision B-1 (accepted for bounded T4):** this table is a bounded compatibility decision, not a permanent rule that all future CEC fields are hard-coded. Before T1b/T2 materially expand the evidence field catalogue, it should be revisited whether selector metadata becomes governed schema/workbook content.

| FieldCode | CEC `EvidenceType` | Additional selector | Scope | Scalar value |
|---|---|---|---|---|
| `CEC_XML_ROOT_ELEMENT_COMMON` | `XmlRootElement` | `XmlId` → `XmlDocuments.XmlKind = CommonBackbone` | Sequence | `ObservedValue` (string) |
| `CEC_XML_NAMESPACE_COMMON` | `XmlNamespace` | as above | Sequence | `ObservedValue` (string) |
| `CEC_XML_ROOT_ELEMENT_REGIONAL` | `XmlRootElement` | `XmlId` → `XmlKind = RegionalBackbone` | Sequence | `ObservedValue` (string) |
| `CEC_XML_NAMESPACE_REGIONAL` | `XmlNamespace` | `XmlKind = RegionalBackbone` | Sequence | `ObservedValue` (string) |
| `CEC_COMMON_BACKBONE_PRESENCE` | `CommonBackbonePresence` | — | Sequence | `ObservedValue` (boolean) |
| `CEC_DOSSIER_ROOT_PATH` | `DossierRootPath` | — | Dossier of the subject | `ObservedValue` (string) |
| `CEC_UNIT_KIND` | `RegulatoryUnitKind` | — | Sequence | `ObservedValue` (string) |
| `CEC_SUBMISSION_UNIT_MARKER` | `SubmissionUnitMarkerFile` | — | Sequence | `ObservedValue` (string) |
| `CEC_CHECKSUM_FILE_MARKER` | `ChecksumFileMarker` | — | Sequence | `ObservedValue` (string) |
| `CEC_TOC_FILE_MARKER` | `TocFileMarker` | — | Sequence | `ObservedValue` (string) |

CEC records do **not** carry `XmlKind`. Common versus regional XML evidence is therefore selected by joining the record's `XmlId` to `ScannerObservations.XmlDocuments[].XmlKind`. This join reads a BackboneXmlInventory fact from the same document; it does not reparse XML.

**P2 — Field state for one subject.** Each bound field is in exactly one state:

| State | Rule |
|---|---|
| **Available(value)** | Exactly one matching record with `CaptureStatus = Available` and a mapped raw strength (N1) |
| **AssessedAbsent** | No matching record, and the collection that would have produced it was assessed (below) |
| **Unavailable(reason, EvidenceId?)** | Anything else (A1) |

When a field counts as *assessed*:

- **XML-derived fields of kind K:**
  1. **No `XmlDocuments` row of kind K for the subject:** the field is AssessedAbsent if the CEC Repository coverage row (`CheckId = ClassificationEvidenceCollection`, `SubjectType = Repository`) has `CollectionStatus ∈ {Collected, Partial}`. Otherwise it is Unavailable.
  2. **The row exists:** read its CEC XmlDocument coverage row.
     - `Collected`: Available or AssessedAbsent.
     - `NotApplicable` (file missing): AssessedAbsent. The presence field is Available(`false`) when CEC emitted it.
     - `NotAssessed`: Unavailable, with `Reason` = the coverage `CaptureStatus` (`ParseFailed`, `AccessDenied`, `InputUnavailable`).
- **Repository-derived fields:** AssessedAbsent when the CEC Repository coverage `CollectionStatus ∈ {Collected, Partial}`. Otherwise Unavailable (`Reason` = its `CaptureStatus`).
- **A matching record with `CaptureStatus ≠ Available`:** Unavailable, `Reason` = that `CaptureStatus`, with `EvidenceId` cited.
- **More than one matching Available record:** Unavailable, `Reason = AmbiguousProjection`. The values are never merged.

---

## 5. Normalization (N)

**N1.** `EVIDENCE-STRENGTH-NORMALIZATION/1` is the fixed table `Strong → STRONG`, `Supporting → MEDIUM`, `Weak → WEAK`. It is recorded in the output `Normalization` block.

**N2.** Raw CEC strength is immutable. Every cited evidence item reports `RawStrength` (copied verbatim), `NormalizedStrength` and `SourceTier` (copied verbatim).

**N3.** A record whose raw strength is not in the table is **never** guessed:
- the record is not used;
- its field becomes Unavailable with `Reason = UnmappedStrength` and the record's `EvidenceId`.

---

## 6. Condition evaluation and rule firing

Conditions are evaluated with three values: **True / False / Unknown**.

| Operator | Available(v) | AssessedAbsent | Unavailable |
|---|---|---|---|
| `EQUALS` / `NOT_EQUALS` | compare `v` to `value1`. Strings: ordinal comparison, case-folded when `caseSensitive = false`. Booleans: equality. | False / True | Unknown |
| `IN_LIST` | `v` ∈ `value1` list | False | Unknown |
| `MATCHES_PATTERN` | String `v`: .NET regex `IsMatch` per §6.1 | False | Unknown |
| `CONTAINS` / `STARTS_WITH` / `ENDS_WITH` | substring test on a string | False | Unknown |
| `EXISTS` | True | False | Unknown |
| `MISSING` | False | True | Unknown |

`GT`, `GTE`, `LT`, `LTE` and `BETWEEN` are outside the bounded Identification field set (REVIEW A-1). A rule using them on a bound field is `IDI-CONFIG-004`.

### 6.1 `MATCHES_PATTERN` (M1–M3)

**M1 — Engine.** The pattern is evaluated with `System.Text.RegularExpressions.Regex`, constructed explicitly as `[regex]::new(value1, options, timeout)` and called with `.IsMatch(v)`. The engine must not use PowerShell's `-match`, `-imatch`, `-cmatch` or `Select-String`: `-match` is case-insensitive by default and does not carry these exact options.

| Setting | Value |
|---|---|
| Options when `caseSensitive = true` | `RegexOptions.CultureInvariant` |
| Options when `caseSensitive = false` | `RegexOptions.IgnoreCase -bor RegexOptions.CultureInvariant` |
| Options never used | `Multiline`, `Singleline`, `ExplicitCapture`, `IgnorePatternWhitespace`, `RightToLeft`, `ECMAScript`, `NonBacktracking` |
| Match timeout | 1 second per evaluation |
| Match semantics | `IsMatch`: unanchored. Authors anchor explicitly with `^…$` for a full match. |
| Field types | String fields only (`dataType = String`); `valueDataType` must be `String` |

These are the same API, options and semantics on Windows PowerShell 5.1 (.NET Framework 4.x) and PowerShell 7.6 (.NET 8+), so results are deterministic across both. `CultureInvariant` removes the dependence on the machine culture. Exact cross-runtime equality is guaranteed for ASCII patterns and values, which is all the bounded field set (paths, XML names, namespace URIs, markers) and the oracle use. Non-ASCII case-insensitive matching may follow runtime Unicode case tables.

**M2 — Evaluation.** States follow §6:
- Available String value → True or False from `IsMatch`;
- AssessedAbsent → False;
- Unavailable → Unknown;
- `negate` inverts True/False.

A matched, non-negated condition cites its evidence record (E1). Strength follows E2.

**M3 — Failure.**
- An invalid pattern raises `ArgumentException` on construction (`RegexParseException`, a subclass, on .NET 5+). The engine catches `ArgumentException`, which covers both runtimes, and fails fast with `IDI-CONFIG-005` during configuration validation.
- A `RegexMatchTimeoutException` fails the run with `IDI-CONFIG-006`. A pattern that backtracks catastrophically is a configuration defect, not evidence.

`negate = true` inverts True/False; Unknown stays Unknown.

- **Group (AND):** False if any condition is False; otherwise Unknown if any is Unknown; otherwise True.
- **Rule (OR over groups):** **fires** if any group is True. Otherwise it is **not evaluable** if any group is Unknown. Otherwise it **does not fire**.

**P4 — Negated guards.** A condition with `negate = true` is a guard. It affects firing but is **never** cited as evidence and never lowers or raises strength (consistent with the T3a ceiling semantics).

**P5 — OR groups.** Only the groups that evaluated True contribute citations.

**E1 — Citation.** A firing rule cites the Available records bound to the **non-negated** conditions of every True group.
- `MISSING` and AssessedAbsent conditions assert absence. They count as satisfied evidence but have no record to cite.
- Records with an unmapped strength cannot be cited (N3).

**E2 — Hit strength.** Hit strength = the rule output `evidenceStrength`, **capped** at the weakest `NormalizedStrength` among the hit's cited records (no cap when nothing is cited).
- A cap below the declared strength adds `StrengthCappedByEvidence`.
- The cap never raises a strength.
- **Decision B-2 (accepted):** the declared output strength is a ceiling, not permission to overstate weaker evidence observed at run time. The cap is defence in depth alongside the T3a authoring-time `maxEvidenceStrength` guard. It does not mutate the CEC record.

Each firing rule produces one **hit**: *(dimension, value = outputCode, polarity = evidencePolarity, strength, ruleId, cited records)*.

---

## 7. Candidate aggregation (K3)

Hits are grouped per *(subject, dimension, value)* into one candidate:

| Candidate field | Definition |
|---|---|
| `BestSupportStrength` | Strongest `SUPPORTS` hit strength, or `null` |
| `BestContradictionStrength` | Strongest `CONTRADICTS` hit strength, or `null` |
| `SupportingRuleIds` / `ContradictingRuleIds` | Sorted, unique |
| `SupportingEvidence` / `ContradictingEvidence` | Union of cited records, ordered by `EvidenceId` |

Several rules producing the same value give **one** candidate that retains every rule and citation. Candidates with only contradicting hits are listed with `BestSupportStrength = null`.

---

## 8. Precedence, floor and conflict

**S1 — Ordinal precedence only:** `STRONG > MEDIUM > WEAK`, the governed `EVIDENCE_STRENGTH.sortOrder` order.

**S2 — No numeric weights.** No numeric weight or score is read, computed or emitted. Ties are never broken by priority, rule order, specificity or numeric values.

**F1 — Floor.** The floor is `conflictPolicy.minimumEvidenceStrengthForValue`; when it is absent, the engine default is `MEDIUM`. The accepted current floor is `MEDIUM` (T3c-REV amendment 1).

Let **B** = the strongest `BestSupportStrength` over the candidates of the result. The status is decided in this order:

| # | Condition | EvaluationStatus | LimitingFactors |
|---|---|---|---|
| 1 | The dimension has no IDENTIFICATION rule | `NotAssessed` | `NoIdentificationRuleConfigured` (A3) |
| 2 | No SUPPORTS hit, and at least one rule not evaluable | `NotAssessed` | `RuleNotEvaluable` (A2) |
| 3 | No SUPPORTS hit, and every rule evaluable | `InsufficientEvidence` | `NoRuleFired` |
| 4 | B is weaker than the floor | `InsufficientEvidence` | `BelowEvidenceFloor` (**F2**) |
| 5 | More than one candidate has support = B | `Conflict` | `EqualBestStrengthCandidates` (**K1**) |
| 6 | The single top candidate has `BestContradictionStrength ≥ B` | `Conflict` | `SupportContradictedAtBestStrength` (**K2**) |
| 7 | Otherwise | `Evaluated`, `Value` = the top candidate | — |

Modifiers:
- **Rows 4–7:** if any rule of the dimension was not evaluable, also add `RuleNotEvaluable` and list its Unavailable fields. The status does not change.
- **Row 7:** if the selected candidate has `floor ≤ BestContradictionStrength < B`, keep the selected value, add `LowerTierContradiction` and set `ReviewRequired = true` (R1). **Decision B-5:** Confidence is left exactly as the configured confidence policy selects it (C1). There is no automatic downgrade, because the current policy model has no governed contradiction axis. A future explicit contradiction-confidence policy may extend this.
- **F2:** Weak-only evidence keeps every candidate visible but never produces a value.
- **Decision B-6 — TieBehavior** (`UNKNOWN` / `MANUAL_REVIEW`) has no machine effect in Identification/1.0. Both give `EvaluationStatus = Conflict`, null `Value`/`ValueSet`, `Confidence = UNKNOWN` and `ReviewRequired = true`. The value may inform later display or consultant wording only; it never creates a second executable status vocabulary (T3-REV amendment 1).

---

## 9. Confidence (C)

**C1.** Confidence is `UNKNOWN` unless the status is `Evaluated`. For `Evaluated`, it is selected from the IDENTIFICATION confidence rows with `evidenceStrength = B`:
1. if a row with `corroborationRule = INDEPENDENT_SOURCE_CLASS` exists and the corroboration count is ≥ 2, use its `resultConfidence`;
2. otherwise, if a row with `NONE_REQUIRED` exists, use its `resultConfidence`;
3. otherwise use `UNKNOWN`, add `NoConfidencePolicyMatched`, and set `ReviewRequired = true`.

**C2 — Corroboration count** (`ScoreSummary.IndependentSourceClassCount`) is the number of distinct CEC `SourceTier` values among the selected candidate's `SupportingEvidence` whose `NormalizedStrength` is at least the floor.
- Weak evidence (for example folder names) never corroborates.
- Two records of the same tier (root and namespace are both `StructuredXml`) are one class.
- The count is `null` unless the status is `Evaluated`.

**C3.** Confidence values come only from configuration. The engine has no built-in "Strong → High" default. Synthetic oracle confidence rows are test policy, **not** approved production content.

---

## 10. ReviewRequired and ValueSource (R)

**R1.** `ReviewRequired = false` only when **all** of these hold:
- the status is `Evaluated`;
- `B = STRONG`;
- there is no `LowerTierContradiction`;
- a confidence row matched.

In every other case `ReviewRequired = true`, including `Conflict`, `InsufficientEvidence` and `NotAssessed`.

**Decision B-3 (accepted):** `NotAssessed` always requires review. For Pre-Sales it means the consultant lacks enough evidence, capability or configuration to reach the identification conclusion, so it must stay visible for clarification. This covers unavailable required evidence, capability not collected, and a configured dimension with no Identification rule.

**R2.** An `Evaluated` result whose best strength is `MEDIUM` requires review. This is the accepted Identification design §7 mapping of the "Probable" state into the canonical model (IR-REV amendment 1 keeps "Probable" as a display label only).

`ValueSource = "Derived"` when `Value` is set. Otherwise it is `null`.

---

## 11. Unavailable evidence (A)

**A1.**
- `UnavailableEvidence` lists every field referenced by any condition (negated or not) of the dimension's rules that is Unavailable for the subject.
- Each item is `{FieldCode, EvidenceId|null, Reason}`, ordered by `FieldCode`, then `EvidenceId` (null first). Duplicates are removed.
- `Reason ∈ {NotCollected, InputUnavailable, ParseFailed, AccessDenied, UnmappedStrength, AmbiguousProjection}`.

**A2.** A dimension whose rules could not be evaluated, and which has no SUPPORTS hit, is `NotAssessed`. Missing evidence is never treated as a negative finding (Pre-Sales contract §7).

**A3.** Every code in `IDENTIFICATION_DIMENSION` produces a result for every subject. If the dimension has no IDENTIFICATION rule, the result is `NotAssessed` with `NoIdentificationRuleConfigured`. The configured scope stays visible. `NotApplicable` is reserved and never produced by the bounded engine.

---

## 12. Determinism, IDs and ordering (O1)

1. Results are ordered by `SubjectId` (ordinal), then the `IDENTIFICATION_DIMENSION` order. `IdentificationId` = `IDR-0001`, `IDR-0002`, … in that order.
2. Candidates are ordered by `BestSupportStrength` (STRONG, MEDIUM, WEAK, null), then `Value` (ordinal).
3. Rule-ID and evidence-ID lists are ordinal-sorted and unique. `LimitingFactors` are sorted and unique.
4. The output is independent of the order of `ClassificationEvidence`, `CollectionCoverage`, rules, groups and conditions. A re-run on the same inputs is semantically identical.
5. The output is UTF-8 without BOM, with keys in the order of §13.

The oracle compares documents with **semantic JSON equality** after removing the volatile fields `Execution.EngineVersion`, `Execution.StartedAtUtc` and `Execution.CompletedAtUtc`.

---

## 13. `eMAS.MS04.PreSales.Identification/1.0` — exact shape

The machine-readable copy is `tests/identification-interpretation/oracle/identification-1.0.schema.json` (Draft 2020-12, `additionalProperties: false`).

```json
{
  "ContractId": "eMAS.MS04.PreSales.Identification/1.0",
  "Execution": { "Capability": "IdentificationInterpretation", "ExecutionId": "<scanner ExecutionId>",
                 "EngineVersion": "<string>", "StartedAtUtc": "<ISO-8601>", "CompletedAtUtc": "<ISO-8601>",
                 "CompletionStatus": "Completed | CompletedWithEvidenceGaps" },
  "EvidenceSource": { "ContractId": "eMAS.MS04.PreSales.ScannerObservations/1.0", "ExecutionId": "...", "DocumentSha256": "<64 hex>" },
  "RuntimeConfig": { "ConfigurationId": "...", "SchemaVersion": "1.1.0", "MappingVersion": "...", "ExportType": "DEV | CONTROLLED", "Sha256": "<64 hex>" },
  "Normalization": { "PolicyId": "EVIDENCE-STRENGTH-NORMALIZATION", "Version": "1",
                     "Mapping": { "Strong": "STRONG", "Supporting": "MEDIUM", "Weak": "WEAK" } },
  "FieldProjection": { "PolicyId": "CEC-FIELD-PROJECTION", "Version": "1" },
  "Results": [ {
    "IdentificationId": "IDR-0001",
    "SubjectType": "Sequence", "SubjectId": "SEQ-0001", "DossierId": "DOS-0001",
    "Dimension": "TECHNICAL_STANDARD",
    "EvaluationStatus": "Evaluated | InsufficientEvidence | Conflict | NotAssessed",
    "Value": "ICH_ECTD_3_2_2 | null", "ValueSet": null,
    "Confidence": "HIGH | MEDIUM | LOW | UNKNOWN", "ReviewRequired": false, "ValueSource": "Derived | null",
    "Candidates": [ { "Value": "...", "BestSupportStrength": "STRONG|MEDIUM|WEAK|null", "BestContradictionStrength": "...|null",
                      "SupportingRuleIds": [], "ContradictingRuleIds": [],
                      "SupportingEvidence": [ { "EvidenceId": "EVD-0003", "RawStrength": "Strong", "NormalizedStrength": "STRONG", "SourceTier": "StructuredXml" } ],
                      "ContradictingEvidence": [] } ],
    "SupportingEvidenceIds": [], "ContradictingEvidenceIds": [],
    "UnavailableEvidence": [ { "FieldCode": "...", "EvidenceId": "EVD-…|null", "Reason": "..." } ],
    "FiredRuleIds": [],
    "ScoreSummary": { "ScoreModel": "ORDINAL_TIER/1", "BestStrength": "STRONG|MEDIUM|WEAK|null", "TierRank": "1|2|3|null",
                      "CountByStrength": { "STRONG": 0, "MEDIUM": 0, "WEAK": 0 }, "IndependentSourceClassCount": "int|null" },
    "LimitingFactors": []
  } ]
}
```

Field rules:
- **`CompletionStatus`** = `CompletedWithEvidenceGaps` when any result has a non-empty `UnavailableEvidence`; otherwise `Completed`.
- **`EvidenceSource.DocumentSha256` is provenance identity, not source-file validation (REVIEW A-3):**
  - when the engine reads the ScannerObservations input from a file, or the caller supplies that file's exact SHA-256, the value is the SHA-256 of those exact file bytes. The oracle uses this form; its expected hashes are the hashes of the fixture files.
  - when the engine is invoked on an in-memory ScannerObservations object and no file hash is supplied, the value is the SHA-256 of a deterministic serialization of that object. It is the identity of the evidence document that was interpreted, not proof of an original customer file.
  - In neither case does the hash validate the customer source repository; that remains the scanner's `Repository` provenance.
- **`RuntimeConfig.Sha256`** is the SHA-256 of the exact runtime-configuration file bytes loaded.
- **`SupportingEvidenceIds` / `ContradictingEvidenceIds`** are the sorted unions of the candidate citations. `FiredRuleIds` is the sorted union of candidate rule IDs.
- **`ScoreSummary`:**
  - `TierRank` is the `EVIDENCE_STRENGTH` ordinal position of `BestStrength`. It is a rank, not a score.
  - `CountByStrength` counts SUPPORTS hits by hit strength.
  - There is **no** numeric score field (T3-REV decision 3).
- **`ValueSet`** is always `null` in bounded T4. Aggregate value sets need dossier aggregation (D-1).
- **Forbidden fields:** `Outcome`, `SupportStatus` (T3-REV amendments 1–2), any numeric score/weight, and `Projections`.
- **Report projections:** `TechnicalFormat`, `SpecificationProfile` and `DossierContext` are derived later by the report layer from these results. They are not part of Identification/1.0 and are not authoritative.
- **Vocabularies:** `LimitingFactors` and `Reason` are closed, as listed in the JSON Schema, and versioned with this contract.

---

## 14. Explicitly deferred behavior

| ID | Deferred | Reason / owner |
|---|---|---|
| D-1 | Dossier-level aggregation, `ValueSet`, lifecycle multi-value (v3→v4) | IR-REV amendment 5: the aggregation policy is a PO/SME decision |
| D-2 | Region derived from RegionalImplementation through governed relationships | **Decision B-7: DEFERRED** from bounded T4 while T3c U2 is unresolved. This is a bounded deferral, not cancellation of the accepted relationship concept. A later relationship-derived Region task follows once the Regulatory SME and PO settle the confidence/region policy. The engine must not hard-code EU/US/CA/CH/GCC Region inference. |
| D-3 | v4 structured identification (Strong v4) | Needs T2 `SubmissionUnitXmlInventory` |
| D-4 | Non-EU regional / envelope fields | Needs T1b |
| D-5 | Re-checking rule lifecycle/effective dates at run time | Guaranteed by the governed export (T3b) |
| D-6 | Numeric Identification weights | Not approved (T3a) |
| D-7 | `Reviewed`-in-DEV rules | DEFERRED_BY_DESIGN (T3b review) |
| D-8 | T3c U2–U9 | Remain open; not encoded here |

**V1 — Physical v4 markers (Decision B-4, wording per REVIEW A-2).**

*Generic engine rule:*
- Physical marker evidence (`SubmissionUnitMarkerFile`, `ChecksumFileMarker`, unit kind) is raw `Supporting`/`Weak`. Under N1 + E2 it cannot exceed `MEDIUM`.
- It cannot create a `STRONG` hit, and therefore cannot produce STRONG/HIGH v4 identification by itself.
- Whether a MEDIUM value is emitted is governed entirely by Effective runtime rule and policy content. If a validated Runtime JSON deliberately contains an Effective Identification rule whose physical v4 marker produces a MEDIUM hit, the engine returns `Evaluated`, the configured v4 TechnicalStandard value, the policy-derived MEDIUM-tier confidence, and `ReviewRequired = true` (IDO-19).
- The engine contains no v4-specific code and does not hard-code `eCTD_4_0` business meaning.

*Production content governance (unchanged by this contract):*
- physical v4 evidence is capped at MEDIUM;
- physical evidence alone never produces STRONG/HIGH v4 identification;
- R-FMT-02 remains RE_MODEL and source-refresh controlled;
- strong, reliable v4 identification requires T2 `SubmissionUnitXmlInventory`;
- no production v4 rule becomes Effective merely because the generic engine supports MEDIUM semantics. The oracle's v4 rules are synthetic.

---

## 15. Central decisions (closed)

All seven questions raised in revision 1.0 were decided by central review (REVIEW.md). No open blocker remains for bounded T4.

| ID | Decision | Clause | Cases |
|---|---|---|---|
| B-1 | **Accepted for bounded T4:** fixed, versioned `CEC-FIELD-PROJECTION/1` table with the XmlId → XmlKind join. Revisit governed selector metadata before T1b/T2 expand the field catalogue. | §4 | All |
| B-2 | **Accepted:** hit strength = min(declared, weakest cited normalized strength); `StrengthCappedByEvidence`. | E2 | IDO-21 |
| B-3 | **Accepted:** `NotAssessed` → `ReviewRequired = true`, including a dimension with no rule. | R1 | IDO-11, 12, 13, 18 |
| B-4 | **Accepted with production-governance caveat:** generic MEDIUM v4 semantics are allowed; production v4 stays blocked by T2/governance. | V1 | IDO-19 |
| B-5 | **Accepted:** lower-tier contradiction keeps the value, adds `LowerTierContradiction` and review; confidence comes from policy unchanged. | §8 row 7 | (no case) |
| B-6 | **Accepted:** `UNKNOWN` and `MANUAL_REVIEW` give the same Conflict result. | §8 | IDO-06, IDO-07 |
| B-7 | **Deferred** from bounded T4: no relationship-derived Region. | D-2 | (none) |

Amendments from the same review:

| ID | Change | Clause | Cases |
|---|---|---|---|
| A-1 | `MATCHES_PATTERN` defined with deterministic .NET regex semantics; an invalid pattern fails with `IDI-CONFIG-005` | §6.1, I2 | IDO-22, IDO-23 |
| A-2 | Physical-v4 wording split into the generic engine rule and production governance | V1 | IDO-19 |
| A-3 | `EvidenceSource.DocumentSha256` provenance semantics | §13 | All |

Cases governed by a decision carry `centralDecisions` in `manifest.json`.

## 16. Revision history

| Revision | Date | Change |
|---|---|---|
| 1.0 | 2026-10-06 | Initial bounded behavioral contract, Identification/1.0 shape, 21 oracle cases, 7 open blockers |
| 1.1 | 2026-10-06 | Central decisions B-1 to B-7 frozen; `MATCHES_PATTERN` (§6.1) with `IDI-CONFIG-005`/`006`; physical-v4 wording; evidence-source hash semantics; IDO-22 and IDO-23 |
