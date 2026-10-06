# Claude Report — EMAS-MS04-IDENTIFICATION-RULES

**Status:** `DESIGN_COMPLETE — READY FOR REVIEW`
**Agent:** Claude (single design worker; report only)
**Branch:** `analysis/emas-ms04-identification-rules`
**Based on:** `coordination/emas-ms04-identification-rules` @ `586655718348cf8a5f20847cf1cb5499a97e8ce4`, which includes `REQUIRED_SOURCES.md` and authoritative base `401d99cbe0afbfeb12ffe4dbf5650cb149a1f529`
**Date:** 2026-10-06

No runtime, test, fixture, contract, FormatDetection, RegionDetection, BackboneXmlInventory or ReferenceResolution file was changed. Official sources and prior eMAS artifacts were read locally or in scratch. No internal binary artifact was copied into the repository. This report is the only repository change.

Labels used throughout:
- **[CAN]** — canonical eMAS requirement.
- **[PRIOR]** — prior eMAS design or mapping artifact.
- **[IMPL]** — current implementation evidence.
- **[REG]** — official regulatory source.
- **[eMAS-D]** — Claude design proposal. It is not a requirement until the user accepts it, and rule content stays `Draft` until the required SME approvals (Authority policy §8, §11).

---

## 0. Source basis and precedence

The authority order comes from `docs/governance/00_authority_and_precedence.md` §2 and `CANONICAL_DOCUMENT_INDEX.md` v1.9. No category below substitutes for another.

### 0.1 Canonical eMAS requirements actually reviewed

All are in the repository at this branch's base. The SHA-256 prefix is of the file read.

| Rank | Document | Version / status | SHA-256 (prefix) | Used for |
|---|---|---|---|---|
| — | `docs/CANONICAL_DOCUMENT_INDEX.md` | v1.9 Effective | `2e29f757d6b1` | authority routing |
| Gov | `docs/governance/00_authority_and_precedence.md` | v1.1 Effective (file); index lists v1.0 | `93d05d6e70bc` | hierarchy §2; conflict handling §6; change authority §8; LLM rule §11 |
| 1 | `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md` | v3.1 Effective | `a8e360260881` | §8 classification model (HighestEvidenceScore; Unknown/ManualReview); §9 rule lifecycle; §14.1 Pre-Sales outcomes and optional deep checks |
| 2 | `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md` | v3.0 Effective | `dabd4d5176f5` | FR-CLASS-001…008; FR-CONFLICT-004…006 |
| 3 | `docs/configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md` | v3.0 Effective | `5e130331bc2a` | TR-CLASS-002/004; TR-CONFLICT-005/006; TR-FIELD-005; TR-JSON-005/006 |
| 4 | `docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md` | v3.0 Effective | `8ea4b8c67afe` | §15–24 master data; §25–30 rule tables; §34 conflict policies; §37 confidence policies |
| 3–5 | `docs/configuration/04_eMAS_Runtime_JSON_Contract.md` | v1.2 Effective | `961f7ac639c2` | runtime JSON is exported, immutable, validated; missing evidence → `NotAssessed`/`InsufficientEvidence` |
| 2–5 | `docs/configuration/05_eMAS_Normalized_Rule_Model.md` | v1.1 Approved | `0643e31fb188` | §9 EvaluationStatus; §10 conflict strategies; §13 dimensions |
| 4 | `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md` | v1.0 Effective | `3b0eba24aebb` | `ClassificationCandidate` / `ConfidenceImpact` outputs; EvidenceStrength list |
| 4 | `docs/configuration/07_eMAS_Data_Dictionary.md` | v1.0 Effective | `84ac159a186d` | §44 Confidence_Policies; §55 controlled codes (EvaluationStatus, ConflictStrategy, ValueSource) |
| 6 | `docs/architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md` | v1.1 Effective | `43ce0b2a9c1d` | confidence `High/Medium/Low/Unknown`; EvaluationStatus/RAG/Confidence/ReviewRequired separate; "unknown or conflicting classification … must not be silently forced" |
| 7 | `docs/llm-development-context/ectd-regulatory-expert.md` | Effective guidance (subordinate) | `15dc6a89d0ee` | evidence/conflict guidance; SME boundary |
| ref | `docs/governance/eMAS_Terminology.md` | Effective | — | ASMF = ProcedureContext |

**Binding consequences for this design:**

1. Classification dimensions stay independent. ASMF/DMF are `ProcedureContext` (FR-CLASS-001/003; TR-CLASS-002).
2. Matched candidates, evidence, evidence strength, score and confidence are preserved (FR-CLASS-005; TR-CLASS-004).
3. The default strategy is `HighestEvidenceScore`. Equal top scores or contradictory strong evidence give `Unknown` or `ManualReview` (FR-CLASS-006/007; FR-CONFLICT-005/006).
4. Evidence strength vocabulary is **`Strong`, `Medium`, `Weak`** (FR-CLASS-008).
5. Confidence vocabulary is **`High`, `Medium`, `Low`, `Unknown`** (Requirements §14.1; phase contract).
6. Status uses the controlled **EvaluationStatus** codes (Data Dictionary §55.2).
7. Rule content is authored in the reviewed **XLSM** and exported to validated, immutable runtime JSON. PowerShell must not create or reinterpret it (Authority policy §4).
8. Pre-Sales must not *require* deep XML or checksum checks; they may be optional and proportionate (Requirements §14.1).
9. Regulatory content needs Regulatory SME + Product Owner approval. Confidence weights need Migration SME + Product Owner approval (Authority policy §8).

### 0.2 Prior eMAS design / mapping artifacts actually reviewed

These were all available locally (outside Git). They are treated as **project design input below canonical authority**. Their regulatory claims are not used as normative rules unless independently verified (§0.4).

| Artifact | Location reviewed | Version / date | SHA-256 | Parts reviewed |
|---|---|---|---|---|
| `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v2.0.docx` | `~/Downloads/` (byte-identical copy also in `eMAS-PreSales-Verification/`) | v2.0, 12 Sept 2026, "Bible candidate" | `72e683728996…4b54a` | §10 / §10.1 identification model and rule template; §3.1 v4 indicators; §9.1 NeeS; §32–32.3 evidence classes, priority, states; §38.3 confidence; Appendix G scoring; heading map of all sections |
| `eMAS_PreSalesMapping.json` | `eMAS-PreSales-Verification/` | unversioned; file dated 2026-10-04 | `f470a8542f8f…0a13ed` | `RegionRules` (12), `FormatRules` (17), `TypeRules` (10); metadata |
| `eMAS_Dossier_Classification_Mapping_v2.1_1386873065.xlsx` | `eMAS-PreSales-Verification/` (identical copy in `eMAS-Platform/docs/requirements/`) | v2.1, Confluence 1386873065 | `49d2c53f3b9d…6a0a4f` | `00_README` (detection order, key principle); `01_Field_Model`; `07_Evidence_Indicators`; `08_Decision_Precedence` incl. confidence model; sheet list |
| `eMAS_MS04_PreSales_Sample_Data_Catalogue_v1.1.xlsx` | Wave 1 test-data package copy (identical to `outputs/…/wave1-freeze-v1.1/`) | v1.1 | `5bc44f4b984c…8f452` | `01_Sample_Catalogue` SD-021…043; `02_Region_Format_Coverage`; `07_Open_Decisions` (OD-001/002, D-03/06/07/10) |
| `eMAS-Requirement_Complete_Scenario_Matrix_v1.1_AdPromo.xlsx` | `~/Downloads/` (identical copy in `eMAS-PreSales-Verification/`) | v1.1 AdPromo | `406edbef3afa…850678` | MS-04 column: repository/container discovery, dossier/application grouping and classification rows |

No listed artifact was unavailable. Older versions (Guide v1.0, Scenario Matrix v1.0, Sample Catalogue v1.0) were present but **not** used.

### 0.3 Current implementation evidence reviewed [IMPL]

These describe behaviour, not authority. Reviewed:
- `engine/powershell51/eMAS.RepositoryDiscovery.psm1` at `401d99c`, plus the v4 diff;
- `eMAS.BackboneXmlInventory.psm1`;
- `eMAS.ClassificationEvidenceCollection.psm1` (evidence-type table);
- the B3 decision, implementation and review reports;
- the eCTD v4 discovery design, implementation and review reports;
- `BASELINE_CHANGES.md`;
- Wave 1 / Wave1D / Wave1E expectation sets, as used in my earlier tasks and listed in the repository.

### 0.4 Official regulatory sources [REG]

These are listed in §14. Downloaded 2026-10-06; versions verified on the official pages.

### 0.5 Conflict register

Conflicts are handled per Authority policy §6: the higher source is applied, the conflict is recorded, and nothing is silently merged.

| ConflictId | Higher source | Lower source | Applied | Action |
|---|---|---|---|---|
| CF-ID-01 | FR-CLASS-008 (rank 2): strengths `Strong/Medium/Weak` | CEC implementation (rank 9): `Strong/Supporting/Weak` | Identification uses `Medium` and maps CEC `Supporting` → `Medium` | Mark CEC vocabulary for alignment (T1a) |
| CF-ID-02 | Canonical Index v1.9: Requirements **v3.1** Effective, rank 1 | Authority policy §3 text: "v3.0 remains the primary product baseline" | v3.1 used (the index is the routing authority and is later-synchronised) | Report to Product Owner for text sync |
| CF-ID-03 | Req §8 / FR-CLASS-003: ASMF is ProcedureContext; regional implementations are layered on TechnicalStandard | `eMAS_PreSalesMapping.json` R-FMT-03…07 ("EU eCTD", "US FDA eCTD" … as formats) and R-FMT-11/12 (ASMF, DMF as formats) | Canonical model | Prior mapping needs correction. Classification Mapping v2.1 `08_Decision_Precedence` #9 already agrees with canonical. |
| CF-ID-04 | Classification Mapping v2.1 `08` confidence model ("High = XML … confirms"); Guide v2.0 §38.3 ("one strong indicator only → Medium maximum") | Same workbook `07_Evidence_Indicators`: file **presence** of `index.xml` / `submissionunit.xml` / `sha256.txt` / `*-regional.xml` = "High" | Conservative reading: presence = `Medium`; parsed content = `Strong` | SME decision D-4 |
| CF-ID-05 | BASELINE_CHANGES §2 (accepted task decision): v4 marker set is not enough to conclude v4 | `eMAS_PreSalesMapping.json` R-FMT-02 / R-REG-11: "High when submissionunit.xml present" | BASELINE | Prior mapping needs correction |
| CF-ID-06 | Catalogue §15 master-data Region seeds (EU, US, Canada, UK, Switzerland, GCC, MENA, LATAM, EAEU, RestOfEurope, Other, Unknown) | Guide v2.0 §32 and Sample Catalogue (Australia, Japan, Singapore as regions); Mapping v2.1 field model ("EU/EEA") | Master-data seeds; JP/AU/SG flagged | Decision D-5 |
| CF-ID-07 | Requirements §14.1: deep XML checks are optional in Pre-Sales | A design that *requires* v4/regional XML inventories | Inventories are **optional, proportionate** capabilities; identification degrades to `NotAssessed`/Low without them | — |

---

## 1. Current evidence actually available (base `401d99c`) [IMPL]

### 1.1 Exists today

| Producer | Facts | Notes for identification |
|---|---|---|
| RepositoryDiscovery | Dossier candidates (physical containers). `Sequences` with `SequenceLikeKind` ∈ {`NumericSequenceDirectory` (exact v3/NeeS, B3), `SubmissionUnitFolder`, `DamagedSubmissionUnitCandidate`, `AmbiguousRegulatoryUnitFolder`, plus sequence-like kinds}. Full `Files`/`Entries` inventory. Observations (`SubmissionUnitFoldersObserved`, `DamagedSubmissionUnitMarkerSet`, `ConflictingBackboneMarkers`, `NonCanonicalSequenceNumberFolderName`, `UnplacedSubmissionUnitMarker`, …). Access and enumeration diagnostics. | Physical only. Unit kinds and file names such as `ctd-toc.pdf`, `index-md5.txt` and `sha256.txt` are **not** CEC evidence. |
| BackboneXmlInventory (optional capability) | Only for `IsExactSequenceFolder = true`. Probes `index.xml` and **only `m1/eu/eu-regional.xml`** as regional. Other sequence `.xml` → `XmlKind = Other`. Parsed facts: root, namespace, `dtd-version`, DOCTYPE, public/system id, parse/capture status. | EU-specific regional probe. An FDA `us-regional.xml` is `Other` while the EU path is "Missing". v4 units are excluded by design. |
| ClassificationEvidenceCollection | 13 evidence types: `DossierRootPath` (Weak); `SequenceFolder`, `CtdModuleFolders` (Weak); `Module1RegionalFolder`, `Common/RegionalBackbonePresence`, `Common/RegionalBackbonePath` (`Supporting` = canonical Medium); `XmlRootElement`, `XmlNamespace`, `DtdVersion` (Strong); `DocumentTypeName`, `DtdSystemIdentifier`, `DtdPublicIdentifier` (`Supporting`). `CandidateValue`, `Polarity` and `SourceRuleId` are null. | `Other` XML ignored. `RegionalBackbonePresence` currently means "EU regional path present". `Module1RegionalFolder` is also emitted for v4 units, where `m1` is flat or region-neutral. |

### 1.2 Requires a future capability

| Missing evidence | Needed for | Task (§13) |
|---|---|---|
| v4 `submissionunit.xml` facts: root/ns, ICH and regional IG OIDs, `identifierName`, application-id roots, code-system OIDs, sequence-number value, application/submission type codes | Every Strong v4 conclusion | T2 (optional capability) |
| Generic v3 regional backbone facts (`m1/<cc>/<cc>-regional.xml`) | Strong non-EU v3 Region | T1b (optional) |
| Typed envelope fields (EU `country`, procedure and submission type; US `application-type`) | DossierContext; EU vs UK(NI) | T1b |
| CEC physical-marker evidence: unit kind, TOC files, checksum files, `util/` | NeeS; v4 physical support | T1a |
| v4 reference semantics | Never identification evidence | `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS` |

**[eMAS-D]** Identification consumes **only** CEC records and CEC coverage, never `Files`, `Sequences` or XML directly. This keeps one auditable fact boundary and avoids duplicated parsing.

## 2. Dimension mapping to the canonical model

| Scanner dimension | Canonical dimension (Req §8; Rule Model §13) |
|---|---|
| `TechnicalFormat` | `TechnicalStandard` |
| `Region` | `Region` (+ `Authority` later) |
| `SpecificationProfile` | `RegionalImplementation` + version; ICH backbone/IG version |
| `DossierContext` | `ProcedureContext` + application type (+ typed `LifecycleContext`) |

`ProductDomain`, `ProductClass` and `SourcePresentation` are out of Phase-1 identification scope.

## 3. Controlled vocabularies (Phase 1, all Draft master-data usage)

Codes reuse Catalogue §15–22 seeds. Indeterminacy is expressed through `EvaluationStatus` and the `Unknown`/`ManualReview` outcome, never as a pseudo-value in the dimension.

### 3.1 TechnicalFormat (Catalogue §17 codes)

| Code | Phase-1 | Basis |
|---|---|---|
| `ICH_eCTD_3_2_2` | Active | [REG] ICH eCTD Spec v3.2.2 |
| `eCTD_4_0` | Active; physical evidence capped at Low until T2 | [REG] ICH eCTD v4.0 IG v1.7 |
| `NeeS` | Active (EU scope); max Low (no structured source) | [REG] EU NeeS v4.0; [PRIOR] Sample Catalogue: "positive NeeS evidence required; no-XML alone is insufficient" |
| `VNeeS` | Reserved, no rules (deferred) | [REG] Vet GL v3.1: `root…` folder, part-based structure; never discovered by current RepositoryDiscovery |
| `Non_eCTD_Electronic` | Reserved, no rules | [PRIOR] SD-034; R-FMT-10 is itself Low/Medium only |
| `Other` | Reserved, no rules | SD-035 unsupported future schema |

### 3.2 Region (Catalogue §15 seeds)

| Code | Phase-1 rule pack | Note |
|---|---|---|
| `EU` | Active | v3 Strong today. Confidence capped Medium until the envelope is read: UK-NI `xi` [REG EU M1 v3.1.1 App. 2.1]; [PRIOR] SD-023 "EU-format does not automatically mean EU jurisdiction". |
| `US` | Active | v3 Low today (path only); Strong after T1b. v4 after T2. |
| `Canada`, `UK`, `Switzerland`, `GCC`, `EAEU` | Vocabulary only; packs deferred | [PRIOR] Mapping cites `m1/ca/ca-regional.xml`, `ch-backbone`, `gc-backbone`, UK IRP. **Not verified against official sources in this task**, so not used as rules. |
| `Japan`, `Australia`, `Singapore` | Not in master data (CF-ID-06) | D-5 |
| MENA, LATAM, RestOfEurope | Never an identification output | Groupings (Catalogue §15) |

### 3.3 SpecificationProfile (set of `{Component, Version}`)

| Component | Version source | Basis |
|---|---|---|
| `ICH_eCTD_Backbone` | `index.xml` `dtd-version` (`3.2` `#FIXED`) | [REG] ICH v3.2.2 DTD |
| `EU_Module1` | `eu-regional.xml` `dtd-version` (e.g. `2.0`, `3.0.1`, `3.1`). The DTD version, **not** the specification revision: 3.1 vs 3.1.1 is not determinable from XML ([PRIOR] Sample Catalogue D-03). | [REG] EU M1 v3.1.1 DTD |
| `US_FDA_Module1` | `us-regional.xml` `dtd-version` (`3.3`) — after T1b | [REG] FDA M1 spec v2.6; FDA v3 VC v4.6 #1463 |
| `ICH_eCTD4_IG` | ICH IG OID + `identifierName` — after T2 | [REG] ICH v4 IG §9.1.2 |
| `EU_Module1_v4` | Regional IG OID (`…989.5.1.1.6.1.2` = EU M1 IG v1.2) — after T2 | [REG] EU v4 IG draft v1.2 §6 |
| `US_FDA_Module1_v4` | Regional IG OID: not published in the FDA IG text (D-3) | [REG] FDA v4 IG v1.9 §8.1 |
| `EU_NeeS` | No machine-readable version | [REG] NeeS v4.0 |

### 3.4 DossierContext (Catalogue §22 ProcedureContext + application type)

| Value | Typed evidence required | Phase-1 |
|---|---|---|
| `MAA` | EU envelope submission/procedure type | after T1b |
| `NDA`, `ANDA`, `BLA`, `IND`, `DMF` | US `application-number@application-type` codes (e.g. `fdaat1` = NDA) [REG FDA M1 spec v2.6 p.7] | after T1b |
| `ASMF` | Typed EU field or v4 code, never folder text [CAN FR-CLASS-003] | deferred |
| v4 types | Regional CV codes in `submissionunit.xml` | after T2 |

Phase-1 result with no typed evidence: `EvaluationStatus = NotAssessed`. Folder text such as `FDA-US-ASMF` (SD-045) can only ever be a Weak candidate.

## 4. Canonical evidence hierarchy

Strength names follow FR-CLASS-008. The class ordering aligns with [PRIOR] Guide v2.0 §10 and §32.1 and Appendix G.

| # | Source class | Strength | May support | Must never determine alone | Polarity |
|---|---|---|---|---|---|
| 1 | Structured XML root/namespace, typed identifiers, OIDs, controlled codes | **Strong** | all four | — | ± (a different root or namespace contradicts) |
| 2 | Declarations: `dtd-version` (Strong where the DTD `#FIXED`s it), DOCTYPE, public/system id, IG `identifierName` | **Medium** | SpecificationProfile; corroboration | TF/Region alone | + / contextual |
| 3 | Regulator-defined physical markers and paths (`index.xml`, `m1/<cc>/<cc>-regional.xml`, `submissionunit.xml`, `sha256.txt`, `index-md5.txt`, `ctd-toc.pdf`, `util/dtd`) — **presence only** | **Medium** | TF; Region (v3 `m1/<cc>` only) | any High result | +; absence is negative only where a source defines it (NeeS) |
| 4 | Lifecycle-consistent structure across sequences | **Medium**, corroboration only | TF, Profile | anything without a class 1/3 anchor | + |
| 5 | Declared metadata outside the scan (customer questionnaire) | separate `ValueSource = CustomerProvided`; not a scan source | Context | — | contextual |
| 6 | Archive, folder or file names | **Weak** | candidate listing | any value | contextual |
| 7 | Free text / product names | **Weak** (no Phase-1 rules) | — | anything | — |

**[eMAS-D] Applicability guard.** `Module1RegionalFolder` is Region evidence only for v3 exact sequences ([REG] ICH v3.2.2 Table 4-1 `m1/xx`). For v4 units, `m1` is flat or region-neutral ([REG] EU Practical §1.6; FDA v4 IG §4.6), so it is not applicable.

## 5. Rule representation

**Authoring path [CAN].** Identification rules are rows in the reviewed XLSM: Catalogue §25 `Rules`, §27 `Condition_Groups`, §28 `Rule_Conditions` and §29 `Rule_Outputs`, with `OutputType = ClassificationCandidate` / `ConfidenceImpact`. They are exported to the validated runtime JSON. The shape below is the **logical content per rule**, not a separate hand-authored file.

```json
{
  "RuleId": "ID-TF-V3-001", "RuleRevision": 1, "RuleType": "Identification", "Status": "Draft",
  "Dimension": "TechnicalStandard", "CandidateValue": "ICH_eCTD_3_2_2",
  "Applicability": { "Subject": "Sequence", "UnitKinds": ["NumericSequenceDirectory"] },
  "RequiredEvidence": [
    { "FieldCode": "CEC.XmlRootElement.CommonBackbone", "Operator": "Equals", "Value1": "ectd" },
    { "FieldCode": "CEC.XmlNamespace.CommonBackbone",   "Operator": "Equals", "Value1": "http://www.ich.org/ectd" }
  ],
  "AnyOfEvidence": [], "ForbiddenEvidence": [],
  "EvidenceStrengthRequirement": "Strong", "Polarity": "Positive",
  "Priority": 100, "ConflictGroup": "TechnicalStandard", "ConflictStrategy": "HighestEvidenceScore",
  "ConfidenceEffect": "MayReachHigh",
  "SourceReferences": ["SRC-ICH-V322#DTD"], "Rationale": "ICH v3.2.2 DTD fixes the ectd root and namespace."
}
```

| Field | Catalogue mapping / semantics |
|---|---|
| `RequiredEvidence` | One `Condition_Group`, `GroupOperator = AND`. |
| `AnyOfEvidence` | OR between groups (Rule Model §27: AND within a group, OR between groups). |
| `ForbiddenEvidence` | `Rule_Conditions.Negate = true`. |
| `FieldCode` | Must be a registered field code. Unknown field codes block export (TR-FIELD-005), so each CEC evidence type must be registered. |
| Operators | `Equals`, `In`, `Present` only. No regular expressions; arbitrary executable expressions are prohibited (Catalogue §28). |
| `Priority` | Explanation ordering only. It never decides between values (§6; Catalogue §34: no row-order resolution). |
| `ConflictStrategy` | `HighestEvidenceScore` (classification default). `Aggregate` for multi-valued `SpecificationProfile`. |
| `ConfidenceEffect` | `MayReachHigh` / `MaxMedium` / `MaxLow`, emitted as a `ConfidenceImpact` output. |

Whether Runtime JSON Schema 1.0.0 can express CEC-record conditions as field codes without a schema change is an **open check (D-7)**. Any schema change needs Technical Architect, Product Owner and PowerShell Lead approval.

## 6. Interpretation pipeline

| Stage | Input | Output |
|---|---|---|
| 1. Intake | CEC records and coverage; runtime-JSON rule pack (id, revision, SHA-256) | Evidence index per sequence/unit → dossier. Each record tagged `Available`, `ParseFailed`, `AccessDenied`, `NotCollected` or `Missing`. |
| 2. Candidates | Index, rules | Rule hits `{RuleId, Subject, Value, Polarity, Strength, EvidenceIds}`. |
| 3. Aggregation | Hits | Per subject × dimension × value: score (§8), positive/negative evidence IDs. |
| 4. Precedence | Aggregates | `HighestEvidenceScore` with a **tier-dominant score** (§8). |
| 5. Conflicts | Top candidates | Tie, or Strong ± contradiction → `Conflict`. |
| 6. Unit result | Stage 5 | EvaluationStatus, outcome, value, confidence (§7). |
| 7. Dossier aggregation | Unit results | Same value → that value. Legitimate difference (v3→v4 transition; DTD versions) → `Aggregate` value set. Otherwise the weakest unit governs. |
| 8. Confidence | Stages 5–7 | §8 |
| 9. Traceability | Everything above | §11 |

Fixed dimension order: TF → Region → Profile → Context. Earlier conclusions may be used only as **applicability** (e.g. a region rule applies only where TF = v3), never as evidence. This prevents circular rules.

If the optional XML capabilities did not run, the rules that need their evidence report `NotAssessed`, and Weak or Medium rules still evaluate (CF-ID-07).

## 7. Result states mapped to canonical codes

| Identification state [eMAS-D] | `EvaluationStatus` [CAN §55.2] | Outcome | Value | Confidence | `ReviewRequired` |
|---|---|---|---|---|---|
| Identified | `Evaluated` | value | set | High or Medium | false (true if Medium with a contradiction) |
| Probable (Medium-only top) | `Evaluated` | value (HighestEvidenceScore selects it; FR-CLASS-006) | set | **Low** | **true** |
| Indeterminate (Weak-only, or no rule fired with inputs present) | `InsufficientEvidence` | `Unknown` | null | Unknown | true |
| Conflicting (equal top scores, or contradictory Strong) | `Conflict` | `Unknown` or `ManualReview` (configured `TieBehavior`) | null | Unknown | true |
| NotAssessed (required inputs not collected; no pack) | `NotAssessed` | — | null | Unknown | per configuration |
| Multiple (dossier aggregate only) | `Evaluated` | value set (`Aggregate`) | set | min of members | per members |
| *Support status* (separate field, from [PRIOR] Guide §32.3 "Unsupported") | — | `Supported` / `Unsupported` | — | — | Unsupported → true |

**Weak-only floor [eMAS-D, needs Product Owner approval].** Under plain `HighestEvidenceScore`, a Weak-only candidate would still be selected. This design adds a minimum-strength floor: Weak alone gives `InsufficientEvidence`/`Unknown`. The floor is consistent with Guide §32.1 ("Weak: candidate generation only"), Mapping v2.1 `08` #5 ("do not guess region") and the expert context ("path or title text alone is weak … unless an approved rule says otherwise"). It is expressed as `Confidence_Policies.MissingEvidenceBehavior` and `Conflict_Policies` content, not as new engine semantics (D-1).

## 8. Confidence model

There are no numeric percentages ([PRIOR] Sample Catalogue D-07: no approved numeric thresholds). The `HighestEvidenceScore` **score** is a lexicographic tuple `(highest strength, number of independent source classes at that strength or the next lower one)`: Strong ≻ Medium ≻ Weak. Any numeric `WeightOrScore` placed in `Confidence_Policies` must preserve this dominance, and needs Migration SME + Product Owner approval (D-2).

| Case | State | Confidence | Basis |
|---|---|---|---|
| One Strong source only, nothing contradicting | Identified | **Medium** | [PRIOR] Guide §38.3 "one strong indicator only → Medium maximum" |
| Strong + independent corroboration (another class, e.g. official path or declaration), no contradiction | Identified | **High** | [PRIOR] Guide App. G; Mapping v2.1 `08` |
| Strong + contradicting **Weak** | Identified | unchanged (Weak listed; no effect) | Precedence §9 |
| Strong + contradicting **Medium** | Identified | **Medium**, `ReviewRequired` | [eMAS-D] |
| Two conflicting Strong | Conflicting | **Unknown** | [CAN] FR-CLASS-007 |
| Medium-only, consistent | Probable | **Low** | [eMAS-D] |
| Weak-only | Indeterminate | **Unknown** | floor (§7) |
| Strong expected but `ParseFailed`/`AccessDenied`/`Missing`, consistent Medium evidence | Probable | **Low** + `StrongSourceUnavailable(<status>)` | [eMAS-D] |
| Required inputs not collected | NotAssessed | **Unknown** | [CAN] JSON contract: missing evidence → `NotAssessed`/`InsufficientEvidence` |

A rule's `ConfidenceEffect` can only **lower** the ceiling, e.g. the EU-region `MaxMedium`. Dossier confidence is the minimum over contributing units (D-6).

## 9. Precedence and conflict matrix

**Key precedence rule:** within a dimension, the candidate with the highest tier-dominant evidence score wins. A lower strength tier can never create, override or downgrade a result established at a higher tier, and a tie or contradiction at the highest tier present becomes `Conflict` with outcome `Unknown`/`ManualReview` and no value.

| Situation | Outcome |
|---|---|
| Structured XML says v4, path resembles v3 (`1000` unit) | After T2: v4 Strong wins. Today: `SubmissionUnitFolder` unit kind (Medium) → Probable/Low v4. |
| `index.xml` + `submissionunit.xml` (`AmbiguousRegulatoryUnitFolder`) | Today: v3 Medium + v4 Medium disagree → `Conflict`, outcome `ManualReview`. BXI does not parse `index.xml` in non-exact units (D-8). |
| `m1/eu` path but structured XML says FDA | US (Strong) wins. Identified/Medium with `ReviewRequired`. |
| `dtd-version` vs root/namespace | The version is evaluated only against the component the root/namespace identifies. An unrecognised version → that component `InsufficientEvidence` (`VersionNotRecognised`). It is never re-keyed. |
| Physical v4 marker, `submissionunit.xml` ParseFailed (post-T2) | TF Probable/Low (`StrongSourceUnavailable`). Other dimensions `InsufficientEvidence`. |
| `DamagedSubmissionUnitCandidate` only | TF Weak only → `InsufficientEvidence` (BASELINE §2). |
| Multiple dossiers with different formats or regions | Per-dossier results; repository lists them ([PRIOR] Mapping v2.1 `08` #8; Scenario Matrix "classify each candidate independently"). |
| EU regional backbone without envelope facts | EU Identified, `ConfidenceEffect MaxMedium` (UK-NI). |

## 10. Per-dimension rules (Draft rule-pack outline)

### 10.1 TechnicalFormat / TechnicalStandard

| RuleId | Value | Evidence | Strength | ± | Basis |
|---|---|---|---|---|---|
| ID-TF-V3-001 | ICH_eCTD_3_2_2 | CommonBackbone root `ectd` + ns `http://www.ich.org/ectd` | Strong | + | [REG] ICH v3.2.2 DTD |
| ID-TF-V3-002 | ICH_eCTD_3_2_2 | `CommonBackbonePresence = true` | Medium | + | [REG] Table 4-1 |
| ID-TF-V3-003 | ICH_eCTD_3_2_2 | `ChecksumFile = index-md5.txt` (T1a) | Medium | + | [REG] ICH v3.2.2 (MD5 file; PDF p.96) |
| ID-TF-NEES-001 | NeeS | `TocFile = ctd-toc.pdf` in sequence (T1a) + `CtdModuleFolders` non-empty | Medium | + | [REG] NeeS v4.0 §2.2.2, §2.4.1 |
| ID-TF-NEES-NEG | NeeS | Common or regional backbone present | Medium | − | [REG] NeeS v4.0 §2.1 |
| ID-TF-V4-001 | eCTD_4_0 | (T2) root `PORP_IN000001UV` + ns `urn:hl7-org:v3` + ICH IG OID | Strong | + | [REG] ICH v4 IG §9.1.2; `eCTD4-084` |
| ID-TF-V4-002 | eCTD_4_0 | `UnitKind = SubmissionUnitFolder` (T1a) | Medium | + | [REG] ICH v4 IG §5.1; `eCTD4-059`/`063` |
| ID-TF-V4-003 | eCTD_4_0 | `UnitKind = DamagedSubmissionUnitCandidate` | Weak | + | [IMPL] BASELINE §2 |
| ID-TF-V3-NEG-V4 | ICH_eCTD_3_2_2 | `UnitKind = SubmissionUnitFolder` | Medium | − | [eMAS-D] |

Numeric folder shape alone fires no rule, and neither does `CtdModuleFolders` alone. **NeeS minimum:** `ctd-toc.pdf` plus module folders, and no backbone anywhere in the dossier. Otherwise the result is `InsufficientEvidence`; [PRIOR] Guide §9.1 says the same ("no index.xml … does not itself prove NeeS").

### 10.2 Region

| RuleId | Value | Evidence | Strength | Applicability | Basis |
|---|---|---|---|---|---|
| ID-RG-EU-V3-001 | EU | RegionalBackbone root `eu-backbone` + ns `http://europa.eu.int` | Strong, `MaxMedium` | TF = v3 | [REG] EU M1 v3.1.1 p.10 + DTD |
| ID-RG-US-V3-001 | US | Regional root `fda-regional` + ns `http://www.ich.org/fda` (T1b) | Strong | TF = v3 | [REG] FDA M1 spec v2.6 p.4 |
| ID-RG-V3-PATH | `eu` → EU, `us` → US | `Module1RegionalFolder`, single value | Medium | TF = v3 only | [REG] ICH v3.2.2 Table 4-1 |
| ID-RG-EU-V4-001 | EU | Regional IG OID under `2.16.840.1.113883.3.989.5.1.1` (T2) | Strong | TF = v4 | [REG] EU v4 IG §6 |
| ID-RG-US-V4-001 | US | FDA OID arc `2.16.840.1.113883.3.989.5.1.2` in typed ids or code systems (T2) | Strong | TF = v4 | [REG] FDA v4 IG v1.9 §3 |
| — | any | folder or first-level names | Weak | — | candidates only |

`RegionalBackbonePresence = false` at the EU path is **not** negative evidence for other regions.

### 10.3 SpecificationProfile

Accumulating (`Aggregate`) rules emit `{Component, Version}` per unit, using the §3.3 sources. Each version must be in a Draft recognised-version list; otherwise the component is `InsufficientEvidence`. Example: SD-002 → dossier set {ICH_eCTD_Backbone 3.2; EU_Module1 2.0, 3.0.1, 3.1}. That is lifecycle history, not a conflict.

### 10.4 DossierContext

`NotAssessed` in Phase 1 for every dossier. Future rules (T1b/T2) use typed codes only.

## 11. Traceability output

| Field | Answers |
|---|---|
| `Dimension`, `SubjectType` (Sequence/Dossier), `SubjectId`, `DossierId` | What was identified, and for what |
| `EvaluationStatus`, `Outcome`, `Value`/`ValueSet`, `Confidence`, `ReviewRequired`, `SupportStatus`, `ValueSource = Derived` | What eMAS concluded |
| `Candidates[]` (`Value`, `Score`, `BestStrength`, `RuleIds`, `SupportingEvidenceIds`, `ContradictingEvidenceIds`) | Why; what supported or contradicted it (FR-CLASS-005) |
| `UnavailableEvidence[]` (`FieldCode`, `Reason`) | What was unavailable |
| `FiredRuleIds[]`, `RuntimeConfig` (`Sha256`, rule-pack revision) | Which rules fired |
| `LimitingFactors[]` | What prevented a stronger conclusion |

## 12. Scenario matrix (Phase 1; changes after T1b/T2 noted)

Format: State, then confidence. TF = TechnicalFormat; Context = DossierContext.

| # | Scenario | Key facts | TF | Region | Profile | Context |
|---|---|---|---|---|---|---|
| 1 | Clean EU v3 (SD-002) | `ectd` + ICH ns; `eu-backbone` + EU ns; `m1/[eu]`; DTD 3.2; EU 2.0/3.0.1/3.1 | Identified / **High** (Strong + presence) | Identified / **Medium** (`MaxMedium`, envelope) | Multiple {ICH 3.2; EU M1 2.0, 3.0.1, 3.1} | NotAssessed |
| 2 | Clean FDA v3 | ICH Strong; EU path Missing; `us-regional.xml` = `Other`; `m1/[us]` | Identified / High | **Probable / Low** US; after T1b Identified / High | {ICH 3.2} (+US M1 after T1b) | NotAssessed (after T1b: NDA etc.) |
| 3 | Malformed `index.xml` (SD-007 seq 0004) | ParseFailed; presence true | unit: Probable / Low; dossier Identified / **Low** (min rule; D-6) | unaffected | ICH component for that unit: InsufficientEvidence | NotAssessed |
| 4 | Regional XML missing (SD-006 seq 0004) | regional Missing | Identified / High | unit: Medium path only → Probable / Low; dossier Identified / Low (min rule) | EU component absent for the unit | NotAssessed |
| 5 | Clean v4 with future parseable XML | after T2: root/ns + ICH and regional OIDs | today Probable / Low; after T2 Identified / High | today NotAssessed (`CapabilityNotAvailable:T2`); after T2 Identified | after T2 {ICH v4 IG; EU/US M1 v4} | after T2 typed |
| 6 | Physical v4, malformed `submissionunit.xml` (SD-068) | SU kind; (T2) ParseFailed | Probable / Low | InsufficientEvidence | InsufficientEvidence | NotAssessed |
| 7 | Damaged v4-like only (SD-063) | Damaged kind (Weak) | InsufficientEvidence / Unknown | InsufficientEvidence | — | NotAssessed |
| 8 | Ambiguous `index.xml` + `submissionunit.xml` | both markers (Medium vs Medium) | **Conflict / ManualReview** / Unknown | InsufficientEvidence | — | NotAssessed |
| 9 | EU grouped v4 (SD-072) | 3 containers × SU | 3 dossiers each Probable / Low | each InsufficientEvidence (names Weak) | — | NotAssessed |
| 10 | Mixed v3/v4 container (SD-069) | exact units + SU unit | per unit; dossier **Multiple** {v3, v4} at min confidence | per unit | per unit | NotAssessed |
| 11 | NeeS-like (`ctd-toc.pdf`, `m1`–`m5`, no backbones) | TOC (T1a), modules, backbone absent | Probable / Low NeeS | Probable / Low EU if `m1/eu`, else InsufficientEvidence | {EU_NeeS} | NotAssessed |
| 12 | Random `m1`–`m5` document folder | modules only | InsufficientEvidence / Unknown | InsufficientEvidence | — | NotAssessed |
| 13 | Two dossiers, different formats | `Legacy` v3 + `Modern` SU | per dossier | per dossier | per dossier | NotAssessed |
| 14 | Two dossiers, different regions (EU v3 + FDA v3) | as #1 and #2 | per dossier | EU Identified / Medium; US Probable / Low (High after T1b) | per dossier | NotAssessed |
| 15 | Strong XML vs weak path (SD-045 `FDA-US-ASMF`) | EU Strong; root-name tokens Weak | Identified / High | EU Identified / Medium; "US" Weak candidate listed, no effect | as #1 | NotAssessed; "ASMF" Weak only, never a value and never TF |
| 16 | No strong evidence / no dossier (SD-020) | no dossier candidate | no subject | — | — | — |

## 13. Architecture recommendation and implementation roadmap

### 13.1 Architecture

**Option B: one unified `IdentificationInterpretation` capability.**
- One rule engine, with a fixed internal TF → Region → Profile → Context order.
- Per-dimension and per-region rule packs authored in the XLSM and exported in the runtime JSON.
- Consumes CEC only; opt-in, with the default 8-capability chain unchanged.

Compared with Option A (four detectors) it:
- avoids cross-capability ordering contracts and duplicated intake;
- avoids reusing the `FormatDetection`/`RegionDetection` names, which current harnesses list as prohibited;
- gives one traceability shape.

Option C (interpretation inside CEC) is rejected because it breaks the fact/interpretation boundary (BASELINE §5).

### 13.2 v4 structured XML inventory

- **Required** before any v4 result above Probable / Low, and before any v4 Region, Profile or Context result.
- **Not required** to start the engine for v3/NeeS.
- It must be a **separate, optional** capability (`SubmissionUnitXmlInventory`), not a BXI extension:
  - v4 is an HL7 V3 RPS message (`PORP_IN000001UV`, `urn:hl7-org:v3`) [REG ICH v4 IG §9.1];
  - the accepted v3 BXI baseline stays untouched;
  - v4 units are already isolated.
- It records facts only; CEC gains evidence types for them.

### 13.3 Contract impact

Additive and opt-in:
- an `Interpretations` block with its own id (e.g. `eMAS.MS04.PreSales.Identification/1.0`) holding `Identifications[]` (§11) and runtime-config provenance;
- a new capability name `IdentificationInterpretation` and a coverage row.

The `ScannerObservations/1.0` fact collections are unchanged. Tolerance of unknown top-level members is governed by TR-JSON-006 ("unknown descriptive metadata may be ignored only according to the approved compatibility policy"). This needs confirmation (D-9).

### 13.4 Bounded task sequence

| # | Task | Scope | Gate |
|---|---|---|---|
| T1a | `EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE` | Additive CEC facts: `UnitKind`, `TocFile`, `ChecksumFile`, `UtilDtdFolder`. Align strength vocabulary to `Medium` (CF-ID-01). New expectation versions. | Tech review |
| T3 | `EMAS-MS04-IDENTIFICATION-RULE-RUNTIME` | XLSM rule-table usage plus runtime-JSON export and validation for identification rules (field-code registration; D-7 schema check); deterministic engine tested with synthetic evidence. | Schema authority (TA + PO + PS Lead) |
| T4 | `EMAS-MS04-IDENTIFICATION-INTERPRETATION-V3EU` | Unified capability (opt-in); Draft EU v3 + NeeS packs; new identification expectations for Wave 1 / 1D / 1E. Existing expectation files untouched. | User + Regulatory SME (packs stay Draft until SME) |
| T1b | `EMAS-MS04-REGIONAL-BACKBONE-GENERALISATION` | Optional BXI regional probe by ICH Table 4-1 `m1/<cc>/<cc>-regional.xml`, plus typed envelope fields. Wave 2 SD-021 (genuine FDA v3). | Tech + SME |
| T2 | `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY` | Separate optional v4 fact capability; content-valid SD-028 / SD-029 from official samples. | Tech + SME |
| T5 | Regional packs: US v3; EU/US v4; then CA, UK, CH, GCC (each verified against official sources) | One pack per task. | Regulatory SME + PO → `Effective` |
| T6 | `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS` | Independent; not an identification prerequisite. | — |

T1a ∥ T3 → T4. Then T1b, T2 and T5 independently. FormatDetection/RegionDetection are not built as separate capabilities.

## 14. Official regulatory source ledger [REG]

Downloaded 2026-10-06. Printed page with [PDF page].

| ID | Authority | Title | Version / date | Locations | Rules derived |
|---|---|---|---|---|---|
| SRC-ICH-V322 | ICH M2 | ICH eCTD Specification | V 3.2.2, 16 Jul 2008 (`d8273833…`) | App. 4 Table 4-1 p.4-2/4-3 [31–32]; MD5 file [96]; DTD [121] (`xmlns:ectd` `#FIXED "http://www.ich.org/ectd"`, `dtd-version` `#FIXED "3.2"`) | v3 TF; `m1/xx` regional dir (ISO-3166-1; "only one regional directory needed") |
| SRC-EU-M1-311 | EMA | EU Module 1 eCTD Specification | 3.1.1, Jun 2025 (`ae27b9a2…`) | p.10 root `eu-backbone`; App. 1.1 envelope `country` [16]; App. 2.1 `xi` UK-NI [3]; DTD [56] (`xmlns:eu` `#FIXED "http://europa.eu.int"`, `dtd-version` `#FIXED "3.1"`) | EU Region/Profile; UK-NI cap |
| SRC-FDA-M1-26 | FDA | The eCTD Backbone Files Specification for Module 1 | 2.6 (support from 03/31/2025; FDA page as of 08/27/2026) | [3–4] `NNNN/m1/us/us-regional.xml`, root `fda-regional:fda-regional`, ns `http://www.ich.org/fda`, `dtd-version 3.3`; [7] `application-type` codes | US Region/Profile/Context |
| SRC-FDA-V3VC | FDA | Specifications for eCTD Validation Criteria | 4.6 (support from 8/28/2026) | #2 missing `us-regional.xml`; #1463 unsupported US DTD | US v3 markers |
| SRC-NEES-40 | EU (HMA/EMA) | Harmonised Technical Guidance for NeeS (human) | v4.0, Oct 2013 (`a141e5f9…`) | §2.1 p.4 (no `index.xml` / `eu-regional.xml` / `util`); §2.2.2 p.4 (`ctd-toc.pdf`, `m1..m5-toc.pdf`); §2.4.1 p.5 (four-digit folder) | NeeS |
| SRC-VET-31 | EU vet (VHG) | Guideline on specification for veterinary e-submissions | 3.1, Sep 2023 (`f748aa22…`) | root folder [6] (`root…`, VNeeS checker 1); GTOC in root | VNeeS deferral |
| SRC-ICH-V4 | ICH M8 | ICH eCTD v4.0 Implementation Guide | v1.7, Jun 2026 | §5.1 p.13; §8.1 p.27; §9.1–9.1.2 p.30–32 [45–47]; §12.3 `eCTD4-084` p.124 | v4 TF/Profile/Region |
| SRC-EU-V4-IG | EMA | eCTD v4.0 EU M1 Implementation Guide | **draft** 1.2, Oct 2024 | §6 OIDs (EU root `…989.5.1.1`; EU M1 IG v1.2 `…5.1.1.6.1.2`) | v4 EU |
| SRC-EU-V4-PG | EMA | eCTD v4.0 EU Practical Document | 1.0, Dec 2025 | §1.6 flat `m1`; sample header OIDs | v4 guard |
| SRC-FDA-V4-IG | FDA | FDA Module 1 eCTD v4.0 IG | 1.9, Aug 2026 | §3 OIDs (code lists `…5.1.2.2.1`; CDER `…16.1`; CBER `…15.1`); §4.6; §8.1 (regional OID blank) | v4 US |

**Regulatory source conflicts.**
- **SC-1.** The ICH v1.7 IG sample still shows OID `…11.4` labelled "IG v1.5". The EU Practical Guidance shows `…11.5` for v1.6.
- **SC-2.** The FDA v4 regional IG OID is not stated in the IG text.
- **SC-3.** The EU v4 IG is still a draft.

**Prior-artifact regulatory claims not verified here:**
- Canada `ca-regional.xml`, Switzerland `ch-backbone`, GCC `gc-backbone`;
- UK IRP rules;
- EAEU.

They must be verified in their own pack tasks (T5).

## 15. Open decisions and blockers

| ID | Decision | Owner |
|---|---|---|
| D-1 | Approve the **Weak-only floor**: Weak alone → `InsufficientEvidence`/`Unknown`, as policy content. | Product Owner |
| D-2 | Approve the tier-dominant (lexicographic) score and any `WeightOrScore` values. | Migration SME + PO |
| D-3 | FDA v4 regional IG OID source; ICH v1.7 OID value (SC-1/SC-2). Blocks v4 Profile rules. | Regulatory SME |
| D-4 | CF-ID-04 / Guide "malformed `eu-regional.xml` can still be strong region evidence": accept the conservative rule (presence = Medium; parsed = Strong)? | Regulatory SME |
| D-5 | Region master data: add Japan, Australia and Singapore (CF-ID-06)? | PO + Regulatory SME |
| D-6 | Dossier confidence = minimum over units (rows 3 and 4)? | PO |
| D-7 | Can Runtime JSON Schema 1.0.0 express CEC-evidence field codes, or is a schema change needed? | TA + PO + PS Lead |
| D-8 | Ambiguous units: keep `Conflict/ManualReview`, or add a BXI path for their `index.xml`? | PO |
| D-9 | Contract: opt-in `Interpretations` block under TR-JSON-006 compatibility policy. | TA + PO |
| D-10 | EU region `MaxMedium` until envelope `country` is collected (UK-NI). | Regulatory SME |
| B-1 | No Strong v4 evidence until T2; no Strong non-EU v3 Region until T1b. | — |
| B-2 | All rule packs stay `Draft` until SME approval (Req §9; Authority §8, §11). | — |
| B-3 | Prior-mapping corrections (CF-ID-03/05) should be scheduled so the authoring workbook does not export format/ASMF rules that contradict canonical requirements. | PO |

## 16. Scope confirmation

- Report only. The only changed file is `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/CLAUDE.md`.
- No runtime, test, fixture, contract, BXI, ReferenceResolution, FormatDetection or RegionDetection change. No internal binary mapping asset was added to the repository.
- No claim of regulatory validity, conformance or migration readiness. RAG, severity and effort are out of scope.
