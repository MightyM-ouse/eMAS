# Claude Report — EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN (T3)

**Status:** `DESIGN_COMPLETE — READY FOR REVIEW`
**Agent:** Claude (single worker; report only)
**Branch:** `analysis/emas-ms04-identification-rule-runtime-design`
**Based on:** `coordination/emas-ms04-identification-rule-runtime-design` @ `b87620459d3c459812de197de3441d0b6516dc2d`, which contains the authoritative base `8a8c842b45e2cbf12025c15995cf99b0b8012b55` (the accepted Identification Rules decision)
**Date:** 2026-10-06

No schema, workbook, VBA, runtime, PowerShell, test, fixture, CEC, IdentificationInterpretation or prior-mapping file was changed. Every prototype ran from scratch copies using the repository's own validators, unmodified (§12). This report is the only repository change.

## Answers in brief

| Question | Answer |
|---|---|
| Can current Schema 1.0.0 express the design? | **Partially.** It can express identification rules as `Effective` rules with AND/OR condition groups, negation, absence, a `ClassificationCandidate` to a master code, `Aggregate` and `InsufficientEvidence`-on-missing-input. It **cannot** express: dimension-bound candidate targets, per-candidate evidence strength, supporting vs contradicting polarity, a Weak-only floor, or weightless (ordinal) confidence. It also silently accepts several unsafe values (§3). |
| Schema change required? | **Yes.** It is additive only: optional properties on `ruleOutput`, `conflictPolicy`, `confidencePolicy` and `fieldDefinition`, plus identification-scoped semantic checks. Recommended as **Schema 1.1.0 (MINOR)**. Not breaking: all 16 existing fixtures still pass unchanged under a prototype of the extension (§12). |
| Supporting → Medium | In an **engine-side evidence-intake adapter** of `IdentificationInterpretation`, as a fixed, versioned mapping (`EVIDENCE-STRENGTH-NORMALIZATION/1`) keyed on the CEC evidence-contract version and recorded in result provenance. Not in Runtime JSON aliases (proven list-unsafe, §5). |
| Scoring without weights | **Ordinal tier** precedence: each candidate output declares `evidenceStrength`, and the order comes from `EVIDENCE_STRENGTH.sortOrder`. Ties and contradictions are handled by `conflictPolicy.tieBehavior` (constrained). The Weak-only floor is a new `conflictPolicy.minimumEvidenceStrengthForValue`. Confidence uses coded `confidencePolicy.resultConfidence` rows with no numeric weight. `numericScore` stays `null`. |
| Result contract | `eMAS.MS04.PreSales.Identification/1.0`: a separate document linked to the ScannerObservations document, its evidence IDs, rule IDs and runtime-config provenance (§7). |
| Workbook changes | New columns on `tblRuleOutputs`, `tblConflictPolicies`, `tblConfidencePolicies`, `tblFieldCatalogue` and `tblValueLists` (SortOrder); lifecycle/approval columns on `tblRules`; new value lists; CEC field rows; an **Effective-only export filter** (currently absent, proven, §12) (§8). |
| Prior mapping | A bounded **disposition and guard** task: a disposition register for all 39 prior rules, plus validator guards with negative fixtures. No direct import of `eMAS_PreSalesMapping.json` (§10). |

---

## 1. Source basis and authority

| Category | Sources actually used |
|---|---|
| Accepted decisions | `EMAS-MS04-IDENTIFICATION-RULES` Claude report and **ChatGPT review with amendments 1–7, user-accepted** (in `8a8c842`). Binding: one unified capability; canonical dimensions with derived projections; no new executable status vocabulary; raw CEC strength preserved with `Supporting → Medium` only at interpretation; Weak-only floor is a policy decision; no numeric weights without Migration SME + PO; dimension-specific dossier aggregation; Region ≠ RegionalImplementation; separate versioned result contract. |
| Canonical (rank) | Authority & Precedence v1.1 (§2, §4, §6, §8); Enterprise Requirements v3.1 (§8, §9, §14.1); Functional Requirements v3.0 (FR-CLASS-005…008, FR-CONFLICT-004…006); Technical Requirements v3.0 (TR-CLASS-004, TR-FIELD-005, TR-JSON-005/006); Content Catalogue v3.0 (§25–30, §34, §37); Runtime JSON Contract v1.2 (§3 versioning, §9); Normalized Rule Model v1.1 (§9, §10, §27–28); Relationship Matrix v1.0 (REL-OUT-006); Data Dictionary v1.0 (§44, §55); Schema Validation & Fixture Contract v1.0; XLSM/VBA POC Conformance Contract v1.0. |
| Implementation evidence (not authority) | `config/schema/eMAS-runtime-config.schema.json` and `defs/*.schema.json` (Schema 1.0.0); `config/schema/examples/**` (16 fixtures); `build/validate_emas_schema.py`, `emas_schema_semantics.py`, `emas_schema_model.py`; POC `config/authoring/poc/workbook-source*.json`; `build/emas_xlsx_poc*.py`; VBA `config/vba/modules/*.bas`; `engine/core/eMAS.Configuration.Contract.psm1` and `private/eMAS.RuntimeConfiguration.Validation.ps1`. |
| Claude design | Everything marked **[D]**. Proposals only, pending central review and user acceptance; governed content stays Draft. |

## 2. Current-model capability matrix

Classes: **A** = already expressible · **C** = configuration only · **S** = requires schema/model change · **E** = requires engine-only behaviour · **G** = requires a governance decision. "P##" refers to the prototype probes in §12.

| Capability | Class | Evidence / reason |
|---|---|---|
| Classification rule bound to a canonical dimension | **S** (+C) | `rule.ruleType = IDENTIFICATION` and `conflictGroup = <dimension>` validate (P01). But `conflictGroup` is unvalidated free text (P14), and the candidate output is not dimension-bound (next row). |
| Conditions over CEC evidence fields | **C** (+E) | CEC fields can be registered in `fieldCatalogue` (`producingComponent`, `valueSource = Observed`) and referenced with checked operators (P01, P16, P17). The engine must project CEC records to scalar per-unit field values (§4.2). |
| Candidate output to a specific master-data entity/value | **S** | `ClassificationCandidate.outputCode` is checked only against the **union of all nine master entities** (`emas_schema_semantics.py` L175/194; VBA `modValidation.bas` L221). The same code in Region and RegionalImplementation is accepted (P07). |
| Positive vs contradictory evidence | **S** | No polarity field exists. `outputValue` is untyped and unvalidated (P09). `negate` (P02) expresses forbidden evidence *within* a rule, but not a contradicting rule. |
| Evidence-strength requirement | **S** | No per-rule or per-output strength. `confidencePolicy.evidenceStrength` is not checked against `EVIDENCE_STRENGTH` (P06 accepts `SUPPORTING`). |
| `Supporting → Medium` normalization | **E** | §5. The alias route is expressible but unsafe (P19, P19b). |
| `HighestEvidenceScore` | **A** (strategy) / **E** (semantics) | The enum value exists and validates. **No engine code consumes it** (0 hits in `engine/`, `scripts/`). Its semantics are undefined in runtime terms. |
| Tie → Unknown/ManualReview | **C** + **S** (validation) | `conflictPolicy.tieBehavior` exists but accepts any identifier (P10). It needs a controlled list check. |
| Weak-only floor | **S** + **G** | No field can express it. A numeric `confidencePolicy` row would require a weight (P05/P05b), i.e. smuggling one in. Needs PO approval (amendment 3). |
| Independent-corroboration confidence | **S** + **E** + **G** | `agreementRequirement` is free text, not executable. `weightOrScore` is a required number. Needs coded fields and Migration SME + PO approval (amendment 4). |
| Rule/evidence traceability | **E** (+ result contract) | Rule IDs and field codes are stable. Evidence IDs and per-record raw/normalized strength belong in the result contract (§7). |
| Per-dossier / per-unit scope | **E** + **G** | No scope field. The engine evaluates identification rules per unit (Sequence/SubmissionUnit). Dossier aggregation is dimension-specific engine behaviour whose policy needs PO/SME approval (amendment 5). Unit-kind applicability is config via a `CEC_UNIT_KIND` condition (needs T1a evidence). |
| Applicability to TechnicalStandard / Region / RegionalImplementation / ProcedureContext / LifecycleContext | **S** | Requires `targetEntityType` plus a validator check that `conflictGroup` and the target agree. |
| Multi-value / lifecycle aggregate | **A** (strategy) + **E** | `conflictStrategy = Aggregate` validates (P15). Lifecycle value sets are assembled by the engine. |
| No-value `InsufficientEvidence` outcome | **A** (missing input) + **E** | `evaluationStatusOnMissingInput = InsufficientEvidence` validates (P18). Weak-only → InsufficientEvidence needs the floor. |
| Draft rule content in runtime JSON | **not expressible (by design)** | `rule.status` is `const "Effective"` (P04). Draft stays in the workbook (Authority §4; Req §9). |

## 3. Schema / runtime gap matrix (exact constraints)

| # | Gap | Exact constraint | Consequence |
|---|---|---|---|
| G1 | Candidate not dimension-bound | `ruleOutput` has `additionalProperties: false` and no target-type property; the validator uses `all_master_codes` | Ambiguous outputs (P07) |
| G2 | No per-candidate strength or polarity | Same; `outputValue: {}` is untyped (P09) | Tier precedence and contradictions cannot be expressed safely |
| G3 | Weak-only floor | `conflictPolicy` has no such property; `additionalProperties: false` | Floor cannot be configured |
| G4 | Weightless confidence | `confidencePolicy.weightOrScore` is **required**, `type: number` (P05/P05b) | Any configured identification confidence row would need an unapproved number |
| G5 | Unvalidated controlled references | `ruleType` vs `RULE_TYPE` (P11), `conflictGroup` (P14), `tieBehavior` (P10), `confidencePolicy.evidenceStrength` vs `EVIDENCE_STRENGTH` (P06) | Silent acceptance of unapproved codes |
| G6 | Alias target is list-agnostic | `alias_targets['VALUE_LIST'] = all_controlled_codes` | An alias scoped to EVIDENCE_STRENGTH can resolve to a SEVERITY code (P19b) |
| G7 | Value-list ordering not authorable | Schema `codeValue.sortOrder` exists (P20), but POC `tblValueLists` has no SortOrder column | Tier order cannot be authored |
| G8 | Export does not filter lifecycle | POC `build_runtime_json` exports every row; VBA `modJsonBuilder.bas` has no status filter; schema requires `Effective` | A Draft rule breaks the whole export (§12, POC-3) |
| G9 | Loader pinned to 1.0.0 | `SupportedSchemaVersions = @('1.0.0')`, `SchemaVersionAdapters = @{}` | Any 1.1.0 document is blocked (`CFG-COMPAT-003`) until the loader contract is updated |
| G10 | POC/canonical vocabulary mismatch | POC and base fixture `EVIDENCE_STRENGTH = [HIGH]`, `CONFIDENCE = [HIGH]`, `confidencePolicy.weightOrScore = 100`, `ClassificationCandidate outputValue = 100`, all `sourceReference "ILLUSTRATIVE"` | See §3.1 |

### 3.1 The `HIGH` / numeric-weight inconsistency

**Exact behaviour.**
- `EVIDENCE_STRENGTH` and `CONFIDENCE` are required *lists* (`REQUIRED_VALUE_LISTS`), but have **no required codes** (`REQUIRED_CODES` covers only PHASE, RAG, EVALUATION_STATUS, VALUE_SOURCE and EXPORT_TYPE). Any upper-case identifier is accepted.
- Codes must match `^[A-Z0-9][A-Z0-9_.-]*$`, so canonical display terms are carried as `STRONG`/`Strong`, `MEDIUM`/`Medium` and so on (P06b rejects `Strong` as a code).

**Classification.** These are **illustrative POC values**: synthetic, `sourceReference ILLUSTRATIVE`, workbook classification `SyntheticProofOfConcept`. They are not canonical content. They still create a latent **canonical incompatibility**: the schema and validator would accept a controlled export with `EVIDENCE_STRENGTH = HIGH`, contrary to FR-CLASS-008 (`Strong/Medium/Weak`) and Requirements §14.1 (confidence `High/Medium/Low/Unknown`).

**Smallest safe correction route [D].**
- Add `EVIDENCE_STRENGTH = {STRONG, MEDIUM, WEAK}` and `CONFIDENCE = {HIGH, MEDIUM, LOW, UNKNOWN}` to `REQUIRED_CODES`, with the Data Dictionary §55 synchronised.
- Replace the POC/base-fixture rows in the same task (T3a).
- Add a negative fixture with `EVIDENCE_STRENGTH = HIGH`.

**Compatibility.** No controlled release exists (`config/runtime/` holds only `development/`; POC `tblExportHistory` is empty). The only affected documents are synthetic fixtures. Code-set tightening follows the precedent of the pre-release `Warning` amendment (JSON Contract §3).

## 4. Minimal rule representation [D]

This reuses the existing normalized entities; there is no new DSL. The fields marked † are the only additions.

```json
{ "rules": [{ "ruleId": "ID-TS-V3-001", "ruleRevision": 1, "ruleType": "IDENTIFICATION",
    "title": "ICH eCTD 3.2.2 common backbone", "description": "ectd root + ICH namespace",
    "status": "Effective", "effectiveFrom": "YYYY-MM-DD", "priority": 100,
    "conflictGroup": "TECHNICAL_STANDARD", "conflictStrategy": "HighestEvidenceScore",
    "specificity": 100, "stopProcessing": false,
    "requirementReference": "FR-CLASS-005", "sourceReference": "SRC-ICH-V322#DTD" }],
  "rulePhases": [{ "rulePhaseId": "RPH-ID-TS-V3-001", "ruleId": "ID-TS-V3-001", "phase": "PRE_SALES",
    "evaluationStatusOnMissingInput": "NotAssessed", "isBlocker": false, "exceptionEligible": false, "sequence": 100 }],
  "conditionGroups": [{ "conditionGroupId": "CG-ID-TS-V3-001-A", "ruleId": "ID-TS-V3-001", "groupSequence": 0, "groupOperator": "AND" }],
  "ruleConditions": [
    { "conditionId": "C-1", "ruleId": "ID-TS-V3-001", "conditionGroupId": "CG-ID-TS-V3-001-A", "sequence": 0,
      "fieldCode": "CEC_XML_ROOT_ELEMENT_COMMON", "operator": "EQUALS", "value1": "ectd", "valueDataType": "String",
      "caseSensitive": true, "negate": false },
    { "conditionId": "C-2", "ruleId": "ID-TS-V3-001", "conditionGroupId": "CG-ID-TS-V3-001-A", "sequence": 1,
      "fieldCode": "CEC_XML_NAMESPACE_COMMON", "operator": "EQUALS", "value1": "http://www.ich.org/ectd",
      "valueDataType": "String", "caseSensitive": true, "negate": false }],
  "ruleOutputs": [{ "ruleOutputId": "OUT-ID-TS-V3-001", "ruleId": "ID-TS-V3-001", "phase": "PRE_SALES",
    "outputType": "ClassificationCandidate", "outputCode": "ICH_ECTD_3_2_2", "sequence": 0,
    "targetEntityType": "TECHNICAL_STANDARD", "evidenceStrength": "STRONG", "evidencePolarity": "SUPPORTS" }] }
```

`targetEntityType`, `evidenceStrength` and `evidencePolarity` on the output are the † additions.

| Need | Carrier |
|---|---|
| RuleId / revision / lifecycle | `ruleId`, `ruleRevision`; runtime `status = Effective` only. Draft/InReview/Reviewed live in the workbook (§8). |
| Dimension target | `conflictGroup` = master entity type, **validated equal to** `ruleOutput.targetEntityType`† |
| Candidate | `ClassificationCandidate.outputCode` resolved **within** `targetEntityType`† |
| Required / any-of / forbidden | AND within a group; OR between groups; `negate = true` for forbidden (Rule Model §27; P02) |
| Absence evidence | `operator = MISSING` (P13) |
| Strength floor | `ruleOutput.evidenceStrength`† ≤ the minimum `fieldDefinition.maxEvidenceStrength`† of the referenced fields (validator check, §10) |
| Contradiction | `evidencePolarity = CONTRADICTS`† |
| Conflict group / strategy / priority | `conflictGroup`, `conflictStrategy` (`HighestEvidenceScore`; `Aggregate` for version components), `priority` (explanation ordering only) |
| Confidence impact | an existing `ConfidenceImpact` output with a controlled `CONFIDENCE` code as a ceiling (e.g. `MEDIUM` for the Draft EU cap; P12) |
| Phase | `rulePhases.phase = PRE_SALES` |
| Unit/dossier scope | the engine evaluates per unit; optional `CEC_UNIT_KIND` condition (T1a field) |
| Source / requirement refs | `sourceReference`, `requirementReference` |

### 4.1 Validator rules added (scoped to `ruleType = IDENTIFICATION`, so non-breaking)

- `ruleType` ∈ RULE_TYPE.
- `conflictGroup` ∈ new list IDENTIFICATION_DIMENSION, initially `TECHNICAL_STANDARD`, `REGION`, `AUTHORITY`, `REGIONAL_IMPLEMENTATION`, `PROCEDURE_CONTEXT`, `LIFECYCLE_CONTEXT`.
- Every `ClassificationCandidate` has `targetEntityType = conflictGroup`, `evidenceStrength` ∈ EVIDENCE_STRENGTH, `evidencePolarity` present, and `outputCode` ∈ `masterData[targetEntityType]`.
- `tieBehavior` ∈ new list TIE_BEHAVIOR {`UNKNOWN`, `MANUAL_REVIEW`}.
- Identification fields have `producingComponent = CLASSIFICATION_EVIDENCE_COLLECTION` and `valueSource = Observed`.

### 4.2 CEC fields as scalar per-unit projections [D]

The field model is scalar, while CEC is a record set. Each identification field is defined as the value of one CEC evidence type (and XmlKind) for one unit:
- `CEC_XML_ROOT_ELEMENT_COMMON` / `_REGIONAL`
- `CEC_XML_NAMESPACE_COMMON` / `_REGIONAL`
- `CEC_DTD_VERSION_COMMON` / `_REGIONAL`
- `CEC_COMMON_BACKBONE_PRESENCE`
- `CEC_MODULE1_REGIONAL_FOLDER_SINGLE` (Code; null unless exactly one)
- and, after T1a: `CEC_UNIT_KIND`, `CEC_TOC_FILE_PRESENCE`, `CEC_CHECKSUM_FILE`.

List-valued evidence is projected to scalar derivatives, so no new data type is needed. The projection is engine behaviour (E), documented with the field catalogue.

## 5. Evidence normalization decision [D]

**Recommendation:** an `EvidenceStrengthNormalizationAdapter` inside `IdentificationInterpretation` intake.

| Option | Verdict |
|---|---|
| Runtime JSON alias (`canonicalEntityType = VALUE_LIST`) | **Rejected.** It validates (P19) but is list-agnostic: an alias scoped to EVIDENCE_STRENGTH can map to a SEVERITY code (P19b). It also makes a fact-vocabulary compatibility mapping editable business content (a Weak → Strong remap would pass validation). |
| Rule pre-processing layer | Rejected: normalization concerns *evidence*, not rules. |
| **Engine compatibility adapter** | **Chosen.** Fixed table `EVIDENCE-STRENGTH-NORMALIZATION/1`, keyed on the evidence contract (`eMAS.MS04.PreSales.ScannerObservations/1.0` + CEC capability version): `Strong→STRONG`, `Supporting→MEDIUM`, `Weak→WEAK`. Unknown raw values → the record is excluded and listed as `UnavailableEvidence(Reason = UnmappedStrength)`. |

Properties:
- The raw CEC record is never modified; the result carries both `RawStrength` and `NormalizedStrength` per cited evidence ID.
- The adapter id and version go into result provenance.
- A future CEC version that natively emits `Medium` gets a new table version with identity mapping; old evidence keeps resolving through `/1`.
- Changing the table is an engine release, reviewed like contract code (TA + PS Lead), not a workbook edit.

## 6. Scoring and conflict without unapproved weights [D]

**Does `HighestEvidenceScore` currently require decimal weights? No:**
1. No engine code consumes `HighestEvidenceScore`, `confidencePolicies` or `ClassificationCandidate` (0 hits).
2. The schema requires a number only *if* a `confidencePolicy` row exists. The array may be empty.
3. Numeric values in the POC (`weightOrScore 100`, `outputValue 100`) are illustrative and not consumed.

**Deterministic ordinal representation:**

| Semantics | Representation |
|---|---|
| Strong > Medium > Weak | `ruleOutput.evidenceStrength`†; order from `valueLists.EVIDENCE_STRENGTH[].sortOrder` (schema-supported, P20). The engine compares by `sortOrder`. No numbers in rules. |
| Score preservation (FR-CLASS-005) | Result `ScoreSummary = {ScoreModel: "ORDINAL_TIER/1", BestStrength, CountByStrength, IndependentSourceClassCount, NumericScore: null}` |
| Equal best-strength, contradictory candidates → Conflict | Engine rule; outcome per `conflictPolicy.tieBehavior` ∈ {`UNKNOWN`, `MANUAL_REVIEW`} (validated, §4.1) |
| Weak-only floor | `conflictPolicy.minimumEvidenceStrengthForValue`† (∈ EVIDENCE_STRENGTH). Below the floor → `InsufficientEvidence`, Value null, Confidence `UNKNOWN`, `ReviewRequired`, candidates retained. The **row stays Draft** until PO approval; while absent, the engine defaults to **no value from Weak** (conservative). |
| Corroboration-based confidence | `confidencePolicy`: add optional `resultConfidence`† (∈ CONFIDENCE) and `corroborationRule`† (∈ new list CORROBORATION_RULE {`NONE_REQUIRED`, `INDEPENDENT_SOURCE_CLASS`}). Make `weightOrScore` **required only when `resultConfidence` is absent** (JSON Schema `if/then`). Identification rows then carry no number. Example Draft rows: (STRONG, INDEPENDENT_SOURCE_CLASS → HIGH), (STRONG, NONE_REQUIRED → MEDIUM), (MEDIUM, NONE_REQUIRED → LOW). Content needs Migration SME + PO. |
| Decimal weights | Remain Draft. Not exported for `scope = IDENTIFICATION` until approved. |

## 7. Identification result contract [D]

`eMAS.MS04.PreSales.Identification/1.0` is a separate JSON document. `ScannerObservations/1.0` is untouched.

```json
{
  "ContractId": "eMAS.MS04.PreSales.Identification/1.0",
  "Execution": { "ExecutionId": "...", "Capability": "IdentificationInterpretation", "EngineVersion": "x.y.z",
                 "CompletedAtUtc": "...", "CompletionStatus": "Completed" },
  "EvidenceSource": { "ContractId": "eMAS.MS04.PreSales.ScannerObservations/1.0", "ExecutionId": "...", "DocumentSha256": "..." },
  "RuntimeConfig": { "ConfigurationId": "...", "SchemaVersion": "1.1.0", "MappingVersion": "...", "Sha256": "...", "ExportType": "DEV|CONTROLLED" },
  "Normalization": { "PolicyId": "EVIDENCE-STRENGTH-NORMALIZATION", "Version": "1" },
  "Results": [{
    "IdentificationId": "IDR-0001",
    "SubjectType": "SequenceUnit|Dossier", "SubjectId": "SEQ-0001|DOS-0001", "DossierId": "DOS-0001",
    "Dimension": "TECHNICAL_STANDARD|REGION|AUTHORITY|REGIONAL_IMPLEMENTATION|PROCEDURE_CONTEXT|LIFECYCLE_CONTEXT",
    "EvaluationStatus": "Evaluated|InsufficientEvidence|Conflict|NotAssessed|NotApplicable",
    "Outcome": "Value|ValueSet|Unknown|ManualReview|null",
    "Value": "ICH_ECTD_3_2_2", "ValueSet": null,
    "Confidence": "High|Medium|Low|Unknown", "ReviewRequired": false, "ValueSource": "Derived",
    "SupportStatus": "Supported|Unsupported",
    "Candidates": [{ "Value": "ICH_ECTD_3_2_2", "BestStrength": "STRONG", "Rank": 1,
                     "SupportingRuleIds": ["ID-TS-V3-001"], "ContradictingRuleIds": [],
                     "SupportingEvidence": [{ "EvidenceId": "EVD-0003", "RawStrength": "Strong", "NormalizedStrength": "STRONG" }],
                     "ContradictingEvidence": [] }],
    "ScoreSummary": { "ScoreModel": "ORDINAL_TIER/1", "BestStrength": "STRONG", "CountByStrength": { "STRONG": 2, "MEDIUM": 1, "WEAK": 0 },
                      "IndependentSourceClassCount": 2, "NumericScore": null },
    "UnavailableEvidence": [{ "FieldCode": "CEC_XML_ROOT_ELEMENT_REGIONAL", "Reason": "ParseFailed|AccessDenied|NotCollected|Missing|UnmappedStrength" }],
    "FiredRuleIds": ["ID-TS-V3-001"],
    "LimitingFactors": ["StrongSourceUnavailable", "ConfidenceCappedByRule", "SupportingContradiction", "CapabilityNotAvailable", "BelowEvidenceFloor"]
  }],
  "Projections": [{ "SubjectId": "DOS-0001", "TechnicalFormat": "...", "SpecificationProfile": [ { "Component": "...", "Version": "..." } ],
                    "DossierContext": { "ProcedureContext": null, "LifecycleContext": null, "ApplicationType": null },
                    "DerivedFromIdentificationIds": ["IDR-0001", "IDR-0007"] }]
}
```

**Projections (report-only; no new master dimension, amendment 2):**
- `TechnicalFormat` ← the `TECHNICAL_STANDARD` result.
- `SpecificationProfile` ← `TECHNICAL_STANDARD` version, plus `REGIONAL_IMPLEMENTATION` results and observed version components (an `Aggregate` value set).
- `DossierContext` ← `PROCEDURE_CONTEXT` + `LIFECYCLE_CONTEXT` + typed application metadata, kept as separate fields rather than flattened (amendment 2).

Display labels such as "Probable" are derived only in the report layer (amendment 1). `LimitingFactors` and `Reason` are result-contract vocabularies, versioned with the contract.

## 8. Workbook impact (no files changed)

| Area | Existing table | Change |
|---|---|---|
| Rule authoring | `tblRules`, `tblRulePhaseAssignments`, `tblConditionGroups`, `tblRuleConditions`, `tblRuleOutputs` | Reuse. `tblRuleOutputs` gets new columns `TargetEntityType`, `EvidenceStrength`, `EvidencePolarity`. |
| Lifecycle / approval | `tblRules` (`Status`) | Allow `Draft/InReview/Reviewed/Effective/Superseded/Retired` (RULE_LIFECYCLE_STATUS; Req §9). Add `ReviewedBy`, `ReviewedOn`, `ApprovalReference`, `ApproverRole` (Regulatory SME / PO per Authority §8). Supersession via `RULE_SUPERSESSION` relationships (already in the endpoint map). |
| Export | VBA `modJsonBuilder`; POC `build_runtime_json` | **Export only `Status = Effective`** rules and their dependent rows. Today Draft rows break the export (G8). Draft/excluded counts go in the export history. |
| Policies | `tblConflictPolicies`, `tblConfidencePolicies` | Add `MinimumEvidenceStrengthForValue`; add `ResultConfidence` and `CorroborationRule`. `WeightOrScore` becomes conditional (blank allowed when `ResultConfidence` is set). |
| Field catalogue | `tblFieldCatalogue` (+operators/phases) | CEC field rows (§4.2); new column `MaxEvidenceStrength`. |
| Value lists | `tblValueLists` | Add column `SortOrder`. Lists: `EVIDENCE_STRENGTH {STRONG, MEDIUM, WEAK}`, `CONFIDENCE {HIGH, MEDIUM, LOW, UNKNOWN}`, `RULE_TYPE +IDENTIFICATION`, new `IDENTIFICATION_DIMENSION`, `TIE_BEHAVIOR`, `EVIDENCE_POLARITY {SUPPORTS, CONTRADICTS}`, `CORROBORATION_RULE`. |
| Master data | technical standards, regional implementations, procedure/lifecycle contexts; `tblMasterDataRelationships` | Catalogue §17–22 codes only (Draft until SME). Region ↔ RegionalImplementation relationships kept distinct (amendment 6). |
| Validation | VBA `modValidation.bas`; Python `emas_xlsx_poc_semantics.py`; `build/emas_schema_semantics.py` | §4.1 and §10 guards, kept in lock-step across all three (POC Conformance Contract). |
| Traceability | `SourceReference`, `RequirementReference`; Export_History | Existing columns. The export history records the schema version and Effective/Draft counts. |

## 9. Runtime JSON versioning decision [D]

- **Current 1.0.0 cannot carry the design.** Every container has `additionalProperties: false`, and the prototype rule with the new properties is rejected by 1.0.0 (§12, EXT-1). `TR-JSON-006` concerns descriptive metadata and is not used to justify executable additions (amendment 7).
- **The required change is additive.** It adds optional properties and conditionalises one requirement (`weightOrScore`). The new semantic checks are scoped to `ruleType = IDENTIFICATION`, plus the `REQUIRED_CODES` tightening of §3.1. The prototype extension keeps **16/16 existing fixtures passing** (EXT-0). That prototype covered the `ruleOutput` and `conflictPolicy` additions only. The `confidencePolicy` conditional `weightOrScore` (`if/then`) and `fieldDefinition.maxEvidenceStrength` are designed but **not prototyped**; T3a must prove them with the same fixture suite.
- Per JSON Contract §3 this is **MINOR: Schema 1.1.0**. It is not MAJOR: no removal, rename, type change or mandatory-section change.
- The `REQUIRED_CODES` tightening for EVIDENCE_STRENGTH and CONFIDENCE is a code-set change. It is acceptable pre-release on the `Warning` precedent, because no controlled release exists. **Governance decision D-1** chooses 1.1.0 or an in-place 1.0.0 amendment. I recommend 1.1.0 for explicit traceability.
- **Same-change dependencies:**
  - loader `SupportedSchemaVersions += '1.1.0'` (G9);
  - `minimumEngineVersion` bump;
  - Data Dictionary §44 / §55 synchronised;
  - Rule Model / Catalogue notes;
  - Schema Validation Contract fixtures.

## 10. Prior-mapping correction route [D]

**Task:** `EMAS-MS04-PRIOR-MAPPING-DISPOSITION` (bounded; no Effective content; the prior file is not edited).

1. **Disposition register** (internal, outside the public repo per REQUIRED_SOURCES B.5). It covers all 39 prior rules (R-REG-01…12, R-FMT-01…17, R-TYP-01…10). Each rule gets one disposition:
   - `Re-model`: e.g. R-FMT-03…07 → TechnicalStandard + RegionalImplementation; R-FMT-11/12 → ProcedureContext;
   - `Seed as Draft rule` (verified against official sources);
   - `Reject`: free-text-only rules; R-FMT-02/R-REG-11 "High on file presence".

   Each disposition records the canonical reference (FR-CLASS-003, Req §8, amendment 6) and a reviewer.
2. **Structural guards** (validator + workbook, T3a/T3b):
   - **SEM_STRENGTH_EXCEEDS_FIELD:** `ruleOutput.evidenceStrength` must not exceed the minimum `maxEvidenceStrength` of the rule's fields. For example, `CEC_DOSSIER_ROOT_PATH` max WEAK and `CEC_UNIT_KIND` max MEDIUM, so v4 file presence can never be STRONG.
   - **SEM_DIMENSION_TARGET:** the candidate's code must exist in `targetEntityType`'s collection, so ASMF/DMF can only be targeted under `PROCEDURE_CONTEXT`.
   - **SEM_CROSS_DIMENSION_CODE:** a code present in `procedureContexts` or `regionalImplementations` may not also be a `technicalStandards` code.
   - **No direct import:** the prior JSON never feeds the export pipeline; only workbook rows with an approval reference export.
3. **Acceptance tests** (negative fixtures, each expecting a specific error code):
   - ASMF as a technical standard;
   - "EU eCTD" as a technical standard while `EU_MODULE1` is a regional implementation;
   - a STRONG rule over a Weak-capped field;
   - a v4 unit-kind rule at STRONG;
   - a free-text field rule above WEAK;
   - a Draft rule present in an export (must be filtered, not fail);
   - 100% register coverage (39/39), with a reviewer per row.

## 11. Implementation file / task impact (later tasks)

| Area | Files |
|---|---|
| Schema 1.1.0 | `config/schema/eMAS-runtime-config.schema.json`, `defs/rules.schema.json`, `defs/policies.schema.json`, `defs/catalog.schema.json` (fieldDefinition `maxEvidenceStrength`), `examples/**` + manifest |
| Validators | `build/emas_schema_model.py` (`REQUIRED_CODES`, lists), `build/emas_schema_semantics.py`, `build/emas_xlsx_poc_semantics.py`, `config/vba/modules/modValidation.bas` |
| Export | `config/vba/modules/modJsonBuilder.bas`, `build/emas_xlsx_poc_model.py` (Effective filter, new columns), `config/authoring/poc/workbook-source-parts/*` |
| Loader | `engine/core/eMAS.Configuration.Contract.psm1` (`SupportedSchemaVersions`) |
| Docs | Runtime JSON Contract, Normalized Rule Model, Data Dictionary, Content Catalogue, Schema Validation Contract, POC Conformance Contract |
| Engine (T4) | new IdentificationInterpretation module, normalization adapter, `Identification/1.0` writer, tests |

## 12. Prototype evidence (scratch only; repository validators unmodified)

**Environment:** `jsonschema[format]==4.26.0`, the pinned repository requirement, installed to scratch. The baseline repository fixture suite passes: **16/16** `[PASS]`, "Schema and semantic fixture validation passed".

**Schema 1.0.0 probes.** Each probe applies a JSON patch to the official base fixture, then runs the repository's `validate_instance` (schema + `_semantic_issues`).

| Probe | Result | Meaning |
|---|---|---|
| P01 minimal IDENTIFICATION rule (EVIDENCE_STRENGTH/CONFIDENCE canonical codes, RULE_TYPE +IDENTIFICATION, CEC fields, candidate `ICH_ECTD_3_2_2`) | **valid** | expressible today |
| P02 OR via second AND group + `negate` | **valid** | — |
| P03 `groupOperator: OR` | SCHEMA_ERROR ("'AND' was expected") | as designed |
| P04 rule `status: Draft` | SCHEMA_ERROR ("'Effective' was expected") | Draft cannot be exported |
| P05 / P05b confidence policy without / null `weightOrScore` | SCHEMA_ERROR (required; not number) | a weight is forced |
| P06 `evidenceStrength: SUPPORTING` | **valid (gap)** | not list-checked |
| P06b `evidenceStrength: Strong` | SCHEMA_ERROR (pattern) | codes are upper-case |
| P07 same code `EU` in Region and RegionalImplementation, candidate `EU` | **valid (gap)** | dimension ambiguity |
| P08 candidate code missing | SEM_OUTPUT_TARGET | — |
| P09 `outputValue` claims another dimension and junk polarity | **valid (gap)** | untyped |
| P10 arbitrary `tieBehavior` | **valid (gap)** | — |
| P11 `ruleType` not in RULE_TYPE | **valid (gap)** | — |
| P12 / P12b `ConfidenceImpact` = `MEDIUM` / `MAX_MEDIUM` | valid / SEM_OUTPUT_TARGET | ceilings via controlled codes work |
| P13 `MISSING` operator | **valid** | absence expressible |
| P14 arbitrary `conflictGroup` | **valid (gap)** | — |
| P15 `conflictStrategy: Aggregate` | **valid** | multi-value expressible |
| P16 unregistered field | SEM_BROKEN_REFERENCE | — |
| P17 operator not in field's allowedOperators (exercised on the base rule's condition) | SEM_OPERATOR_NOT_ALLOWED | — |
| P18 `evaluationStatusOnMissingInput: InsufficientEvidence` | **valid** | — |
| P19 alias `Supporting` → VALUE_LIST/`MEDIUM` | **valid** | alias route possible… |
| P19b same alias → a SEVERITY code | **valid (gap)** | …but list-unsafe |
| P20 EVIDENCE_STRENGTH with `sortOrder` | **valid** | ordinal tiers authorable in schema |

**Extension prototype** (scratch copy of `config/schema` with the optional `ruleOutput.targetEntityType`/`evidenceStrength`/`evidencePolarity` and `conflictPolicy.minimumEvidenceStrengthForValue`):

| Probe | Result |
|---|---|
| EXT-0: repository fixture manifest under the extended schema | **16/16 PASS**, identical to 1.0.0 (backward compatible) |
| EXT-1: identification rule using the new properties | 1.0.0: SCHEMA_ERROR ("Additional properties are not allowed …"); extension: **valid** |

**POC export prototype** (repository `build_runtime_json` and `validate_workbook_tables`, driven from the workbook-source tables):

| Probe | Result |
|---|---|
| POC-0: baseline POC workbook | 0 workbook issues |
| POC-1: identification rows (Effective, 1.0.0 columns) | 0 workbook issues; export valid under 1.0.0 and the extension |
| POC-2: plus `TargetEntityType`/`EvidenceStrength`/`EvidencePolarity` columns | Workbook validator accepts unknown columns; exporter emits camel-cased properties. 1.0.0 rejects (additionalProperties); extension valid. |
| POC-3: rule with `Status = Draft` | Exported **anyway** (no filter), then SCHEMA_ERROR in both schemas, proving gap G8 |

## 13. Open governance decisions and blockers

| ID | Decision | Owner (Authority §8) |
|---|---|---|
| D-1 | Schema **1.1.0 MINOR** vs in-place pre-release 1.0.0 amendment | Technical Architect + PO + PowerShell Lead |
| D-2 | Approve the new optional properties and identification-scoped validator checks (§4.1, §10) | TA + PO |
| D-3 | Weak-only floor value (`minimumEvidenceStrengthForValue = MEDIUM`) | Product Owner |
| D-4 | Ordinal confidence rows (`resultConfidence`/`corroborationRule`) and any numeric weights | Migration SME + PO |
| D-5 | Dimension-specific dossier aggregation policy, including the effect of unavailable units | PO + SME |
| D-6 | EU Region `MaxMedium` (ConfidenceImpact ceiling) | Regulatory SME |
| D-7 | Whether DEV exports may contain synthetic `Effective`-labelled identification rules for T4 testing (the current fixtures already do this with `sourceReference ILLUSTRATIVE`) | PO + QA Lead |
| D-8 | Normalization in an engine adapter (not config); change control for the table | TA + PS Lead |
| D-9 | `REQUIRED_CODES` tightening for EVIDENCE_STRENGTH/CONFIDENCE (§3.1) | TA + PO |
| B-1 | T4 is blocked until T3a (schema/validators/loader) and T3b (workbook/export) are accepted, plus T1a for NeeS/v4 fields | — |
| B-2 | No regulatory rule content becomes Effective without Regulatory SME + PO | — |

## 14. Recommended bounded implementation tasks

| Order | Task | Scope | Acceptance |
|---|---|---|---|
| T3a | `EMAS-MS04-RUNTIME-SCHEMA-1.1-IDENTIFICATION` | Schema 1.1.0 optional properties (§6, §9); identification-scoped semantic checks (§4.1, §10 guards); `REQUIRED_CODES` for EVIDENCE_STRENGTH/CONFIDENCE; fixtures (valid identification, all negative guards); loader `SupportedSchemaVersions`; doc sync | Existing 16 fixtures unchanged-PASS; new positive and negative fixtures PASS; loader accepts 1.0.0 and 1.1.0 |
| T3b | `EMAS-MS04-WORKBOOK-IDENTIFICATION-AUTHORING` | POC workbook columns/lists/SortOrder; lifecycle/approval columns; **Effective-only export**; VBA and Python POC validation parity; conformance tests | POC Draft rule excluded (not failing); export validates against 1.1.0; VBA/Python parity |
| T3c | `EMAS-MS04-PRIOR-MAPPING-DISPOSITION` | 39-rule disposition register (internal) + guard fixtures | §10 acceptance tests; no prior content Effective |
| T4 | `EMAS-MS04-IDENTIFICATION-INTERPRETATION-V3EU` (after T1a, T3a, T3b) | Engine: normalization adapter, ordinal evaluation, conflict/floor, per-unit + dimension-specific aggregation, `Identification/1.0` writer; synthetic DEV rule pack (D-7) | Deterministic results on Wave 1/1D/1E; no change to the ScannerObservations output |

T3a ∥ T3c; T3b after T3a; T4 last. Regional rule packs (T5) remain separate, SME-gated tasks.

## 15. Scope confirmation

- Report only. The only changed file is `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN/reports/CLAUDE.md`.
- No schema, workbook, VBA, runtime, PowerShell, test, fixture, CEC or prior-mapping change. Prototypes ran in scratch and are not committed.
- No production numeric weights are proposed. All identification rule content remains Draft pending the approvals above.
