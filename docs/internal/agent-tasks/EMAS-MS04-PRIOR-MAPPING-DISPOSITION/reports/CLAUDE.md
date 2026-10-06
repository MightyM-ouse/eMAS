# Claude Report — EMAS-MS04-PRIOR-MAPPING-DISPOSITION (T3c)

**Status:** `DISPOSITION_COMPLETE — READY FOR REVIEW`
**Agent:** Claude (single worker; report/governance only)
**Branch:** `analysis/emas-ms04-prior-mapping-disposition`
**Based on:** `coordination/emas-ms04-prior-mapping-disposition` @ `76d1b9f0576a39c0496e6fb05a2c213558a3bc46`. This contains the authoritative base `9d622cfa12bb94464ad5f149aec581bedac12dbc` and accepted T1a `08f4d0d240aac5393cba97f65ce9803fb4fffaa4`.
**Date:** 2026-10-06

This report is the only repository change. No prior mapping file, workbook, schema, validator, PowerShell, CEC, fixture, test or rule content was changed. The prior JSON and the other internal artifacts were read locally and **not** committed. This report is a **redacted** register: it gives rule IDs, categories, canonical targets and disposition reasons. It does not reproduce historical conditions, file or keyword patterns, confidence wording or other payload (§12).

## Answers in brief

| Item | Result |
|---|---|
| Source rule count | **39**, matching T3: `RegionRules` 12, `FormatRules` 17, `TypeRules` 10. No discrepancy (§2). |
| Dispositions | **RE_MODEL 19 · SEED_AS_DRAFT 4 · REJECT 16**. Nothing is kept as-is, and nothing becomes Effective. |
| SEED_AS_DRAFT | `R-FMT-01` (ICH eCTD v3.2.2), `R-TYP-03` (Investigational), `R-TYP-04` (PostMarketing), `R-TYP-06` (Biologic). All four are verified against current official sources (§7). The three Type seeds stay dormant until T1b provides the structured fields they need. |
| Blocked on future v4 XML evidence (T2) | **1** (`R-FMT-02`). `R-REG-11` would also have been, but it is rejected as a duplicate. |
| Blocked on other future evidence | **14** on T1b (non-EU regional backbone fields and EU envelope fields). **2** on a VNeeS physical marker that is not yet approved. |
| Main corrections | Regional implementations were authored as formats. ASMF/DMF were authored as formats. Region and RegionalImplementation were collapsed. Rules claimed a "High" result from file presence alone. v4 physical markers were treated as conclusive. Rules relied on free text or broad groupings. The prior Category/Type axis is not a canonical dimension. Unknown/Other was modelled as a rule. Several regulatory premises are outdated (§6). |
| New regulatory facts found during verification | 1. FDA M1 now uses **coded** application types: `fdaat4` = IND, `fdaat3` = BLA, `fdaat5` = DMF. The literal values the prior rules assume are not valid.<br>2. FDA **Annual Report** is valid for IND and DMF too, so it cannot by itself imply PostMarketing.<br>3. EU M1 IG v3.1.1 lists **IS, LI and NO** as EU M1 destinations. It marks `uk` as "Not to be used anymore" and uses `xi` for UK(NI).<br>4. EU M1 has typed envelope submission types **`asmf` and `pmf`**.<br>5. FDA allows **510k/PMA** codes only as cross-references. |
| Confidentiality check | **PASS**. The prior JSON and binaries are untracked and outside the repo. No 6-word sequence from the prior payload appears in this report (automated check, §12). |

---

## 1. Source basis and precedence

The authority order follows `docs/governance/00_authority_and_precedence.md`. The prior mapping is a **lower-authority historical input**: it supplies intent, never authority.

| Rank | Source | Use here |
|---|---|---|
| Canonical | Enterprise Requirements v3.1 §8 (independent dimensions; ASMF is ProcedureContext; MENA/LATAM are not authorities; Equal top/contradictory → Unknown/ManualReview; new regulatory content stays Draft), §9 (lifecycle Draft → InReview → Reviewed → Effective; only Effective rules are exported; retired IDs are never reused), §23 (scope) | Disposition rules, target dimensions |
| Canonical | Content Catalogue v3.0 §15–24 (Regions, Authorities, Technical_Standards, Regional_Implementations, Product_Domains, Lifecycle_Contexts, Product_Classes, Procedure_Contexts, Source_Presentations, relationship types) | Canonical targets. Codes in the register are the catalogue's illustrative seeds. |
| Accepted decisions | `EMAS-MS04-IDENTIFICATION-RULES` REVIEW (amendments 1–7, v4 decision, v3/NeeS decision, prior-mapping corrections); T3 `EMAS-MS04-IDENTIFICATION-RULE-RUNTIME-DESIGN` REVIEW (Schema 1.1.0, `EVIDENCE-STRENGTH-NORMALIZATION/1`, ordinal tiers, `maxEvidenceStrength`, dimension-scoped targets, **no global code uniqueness**, Effective-only dependency-safe export) | Normative constraints |
| Accepted implementation context | T1a CEC (`08f4d0d`): `SubmissionUnitMarkerFile`, `TocFileMarker`, `ChecksumFileMarker` and `UtilityDtdFolderMarker` are `Supporting` (→ MEDIUM). `RegulatoryUnitKind`, `SequenceFolder`, `CtdModuleFolders` and `DossierRootPath` are `Weak`. Parsed `XmlRootElement`, `XmlNamespace` and `DtdVersion` are `Strong`. BackboneXmlInventory parses ICH index and EU regional backbones only, and captures **no envelope fields**. | Strength ceilings and blockers |
| Official sources (verified 2026-10-06) | See §7 | SEED_AS_DRAFT premises and corrections |
| Historical input (internal, not committed) | `eMAS_PreSalesMapping.json` (SHA-256 `f470a854…a2da13ed`, 39 rules); `eMAS_Dossier_Classification_Mapping_v2.1_1386873065.xlsx` (`49d2c53f…`; contains the same 39 rule IDs); `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v2.0.docx` (`72e68372…`); `eMAS_MS04_PreSales_Sample_Data_Catalogue_v1.1.xlsx` (`5bc44f4b…`); `eMAS-Requirement_Complete_Scenario_Matrix_v1.1_AdPromo.xlsx` (`406edbef…`) | Intent only. All five were available locally. The guide, catalogue and matrix contain no rule IDs; I used them only for context. |

## 2. Prior-rule population

| Collection | Count | In the T3c population? |
|---|---|---|
| `RegionRules` | 12 (`R-REG-01…12`) | Yes |
| `FormatRules` | 17 (`R-FMT-01…17`) | Yes |
| `TypeRules` | 10 (`R-TYP-01…10`) | Yes |
| **Total identification rules** | **39** | Matches TASK.md and T3. The discrepancy gate is **not triggered**. |
| `FolderRagRules` 31, `EffortDrivers` 31, `ScoringConfig` 18, `OutputContract` 16, `ScenarioCoverage` 31 | — | **Not in scope.** They are assessment/RAG/effort/report content, not identification rules. They are still historical inputs and still may not be imported directly (guard G7). Their disposition belongs to the later RAG/effort content tasks. |

The rule IDs are unique, and the Classification Mapping v2.1 workbook contains the same 39 IDs. The JSON's metadata describes it as customer-runtime content converted from the internal workbook. That is exactly the path the governed model replaces, so no part of it is runtime-eligible.

## 3. Controlled definitions

### 3.1 Dispositions (exactly one per rule)

| Code | Meaning in this register |
|---|---|
| `RE_MODEL` | The intent is useful, but the prior rule has a **dimensional or evidence-semantic defect**. Examples: the wrong canonical target, Region collapsed into RegionalImplementation, or a claimed tier its evidence cannot reach. The replacement is a new rule authored in the governed model, starting as Draft. |
| `SEED_AS_DRAFT` | The value maps **one-to-one** into a canonical dimension. The strongest evidence the prior rule names is a structured, authoritative field that can support that tier. The regulatory premise has been **verified against a current official source**. Overstated secondary branches (names, keywords) are dropped at seeding and capped by the field ceiling. The rule seeds the workbook **as Draft only**. |
| `REJECT` | Not suitable for the governed model. The causes are free-text/keyword-only inference, a broad grouping, a duplicate, a catch-all that the result model already covers, a contradicted premise or a wrong concept. Where the underlying intent is still valid, the FollowUp column records it as a backlog item, never as a rule. |

Moving the prior single "Category/Type" axis to its canonical home (ProductDomain, LifecycleContext or ProductClass) is a dimensional correction (`DIMENSION_WRONG`). For the three Type seeds the move is mechanical and one-to-one, so it does not by itself force `RE_MODEL`.

### 3.2 Rationale codes

I used only the task's controlled set and added no new codes. The **first** code in each row is the primary reason; any further codes are secondary.

| Code | Use |
|---|---|
| `DIMENSION_WRONG` | Wrong canonical entity. This covers RegionalImplementation as format, ASMF/DMF as format, v4 as region, Region collapsed into RegionalImplementation, and the non-canonical Category/Type axis. |
| `EVIDENCE_OVERSTATED` | The claimed tier exceeds what the named evidence can support. Typical cases: presence → High, absence → High, names → Medium, v4 markers → High. |
| `OUTDATED_SOURCE` | The cited source has been superseded, or the premise no longer matches the current specification. |
| `DUPLICATE_OR_SUPERSEDED` | Another rule, or the result model itself (EvaluationStatus, ReviewRequired, tieBehavior), already covers it. |
| `UNCONTROLLED_TEXT_INFERENCE` | Relies only on keywords, folder/product names or document text, with no controlled evidence field. |
| `VALID_INTENT_REMODEL_REQUIRED` | The intent is sound, but it needs a different construct, such as relationship derivation or a candidate/limiting factor. |
| `CURRENT_SOURCE_VERIFIED` | The premise was verified against a current official source (SEED rows). |
| `OUT_OF_SCOPE` | Not a technical-standard identification concept for MS-04. |
| `INSUFFICIENT_BASIS` | No official or structured basis was cited, or the premise is contradicted. |

### 3.3 Other column vocabularies

- **EvidenceClass:**
  - `STRUCTURED_XML` — parsed backbone fields;
  - `ENVELOPE` — typed regional envelope fields such as submission type and destination code;
  - `V4_XML` — the future `SubmissionUnitXmlInventory`;
  - `PHYSICAL_MARKER` — T1a markers;
  - `PACKAGE_STRUCTURE` / `PATH`;
  - `RELATIONSHIP_DERIVED` — approved master-data relationship;
  - `DOCUMENT_CONTENT` — no capability exists;
  - `FREE_TEXT`.

  The suffix *(current)* means the evidence exists after T1a; *(T1b)* / *(T2)* name the future capability.
- **MaxStrength:** the highest normalized tier (`STRONG`, `MEDIUM`, `WEAK`) a replacement rule may claim, given its field ceilings. "(G)" means the value is a further governed policy limit that is not yet approved. "n/a" is used for REJECT rows.
- **SourceVerification:**
  - `VERIFIED_CURRENT` — checked in §7;
  - `REFRESH_REQUIRED` — the cited source is stale or unchecked, and must be verified before any replacement becomes Effective;
  - `VERIFICATION_REQUIRED` — the premise is uncertain;
  - `PREMISE_CONTRADICTED` — the current source contradicts it;
  - `NOT_REQUIRED (REJECT)`.

## 4. 39/39 redacted disposition register

| PriorRuleId | PriorCategory | Disposition | CanonicalTarget | EvidenceClass | MaxStrength | RationaleCode | SourceVerification | RequiredReviewer | FollowUp |
|---|---|---|---|---|---|---|---|---|---|
| `R-REG-01` | Region | **RE_MODEL** | RegionalImplementation `Canada_Module1`; Region `Canada` only via approved relationship | STRUCTURED_XML (T1b) | STRONG (RI) / MEDIUM (Region, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (CA) + PO | T1b → T5-CA |
| `R-REG-02` | Region | **REJECT** | — (intent: Region `EAEU`, backlog) | FREE_TEXT | n/a | `UNCONTROLLED_TEXT_INFERENCE`, `INSUFFICIENT_BASIS` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T5-EAEU backlog |
| `R-REG-03` | Region | **RE_MODEL** | RegionalImplementation `EU_Module1`; Region `EU` only via approved relationship | STRUCTURED_XML (current) + ENVELOPE (T1b-EU) | STRONG (RI) / MEDIUM (Region, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (EU) + PO | T4 (merge with R-FMT-03) |
| `R-REG-04` | Region | **RE_MODEL** | RegionalImplementation `GCC_Module1`; Region `GCC` only via approved relationship | STRUCTURED_XML (T1b) | STRONG (RI) / MEDIUM (Region, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (GCC) + PO | T1b → T5-GCC |
| `R-REG-05` | Region | **REJECT** | — (broad grouping; Req v3.1 §8) | FREE_TEXT / PATH | n/a | `UNCONTROLLED_TEXT_INFERENCE`, `INSUFFICIENT_BASIS` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T5 authority packs |
| `R-REG-06` | Region | **REJECT** | — (broad grouping; Req v3.1 §8) | FREE_TEXT / PATH | n/a | `UNCONTROLLED_TEXT_INFERENCE`, `INSUFFICIENT_BASIS` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T5 authority packs |
| `R-REG-07` | Region | **REJECT** | — (EEA handling is decision U3) | FREE_TEXT / PATH | n/a | `INSUFFICIENT_BASIS`, `OUTDATED_SOURCE` | PREMISE_CONTRADICTED (EU M1 IG v3.1.1 App. 2.1) | Regulatory SME (EU) + PO | Decision U3 |
| `R-REG-08` | Region | **RE_MODEL** | RegionalImplementation `Switzerland_Module1`; Region `Switzerland` only via approved relationship | STRUCTURED_XML (T1b) | STRONG (RI) / MEDIUM (Region, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (CH) + PO | T1b → T5-CH |
| `R-REG-09` | Region | **RE_MODEL** | Region `UK` (RI choice is decision U4) | ENVELOPE (T1b-EU) + DOCUMENT_CONTENT (no capability) | MEDIUM (G); path/name WEAK | `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE`, `INSUFFICIENT_BASIS` | REFRESH_REQUIRED (EU M1 code change verified) | Regulatory SME (UK) + PO | Decision U4 → T1b → T5-UK |
| `R-REG-10` | Region | **RE_MODEL** | RegionalImplementation `US_FDA_Module1`; Region `US` only via approved relationship | STRUCTURED_XML (T1b) | STRONG (RI) / MEDIUM (Region, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | VERIFIED_CURRENT (FDA M1 v2.6) | Regulatory SME (US) + PO | T1b → T5-US |
| `R-REG-11` | Region | **REJECT** | — (intent covered by R-FMT-02) | PHYSICAL_MARKER | n/a | `DUPLICATE_OR_SUPERSEDED`, `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | NOT_REQUIRED (REJECT) | PO (acknowledge) | See R-FMT-02 |
| `R-REG-12` | Region | **REJECT** | — (`Other` is a master-data value; unknown is an EvaluationStatus) | FREE_TEXT / PATH | n/a | `INSUFFICIENT_BASIS`, `DUPLICATE_OR_SUPERSEDED` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T5 authority packs |
| `R-FMT-01` | Format | **SEED_AS_DRAFT** | TechnicalStandard `ICH_eCTD_3_2_2` | STRUCTURED_XML (current) | STRONG (structured fields); presence-only MEDIUM | `CURRENT_SOURCE_VERIFIED`, `EVIDENCE_OVERSTATED` | VERIFIED_CURRENT (ICH eCTD Spec v3.2.2; FDA standards page) | Regulatory SME + PO | T3b Draft seed → T4 |
| `R-FMT-02` | Format | **RE_MODEL** | TechnicalStandard `eCTD_4_0` | PHYSICAL_MARKER (current) → V4_XML (T2) | MEDIUM now; STRONG only with T2 | `EVIDENCE_OVERSTATED` | REFRESH_REQUIRED | Regulatory SME + PO | T2 → T5 |
| `R-FMT-03` | Format | **RE_MODEL** | RegionalImplementation `EU_Module1`, layered on `ICH_eCTD_3_2_2` | STRUCTURED_XML (current) | STRONG | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (EU) + PO | T4 (merge with R-REG-03) |
| `R-FMT-04` | Format | **RE_MODEL** | RegionalImplementation `US_FDA_Module1`, layered on `ICH_eCTD_3_2_2` | STRUCTURED_XML (T1b) | STRONG | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | VERIFIED_CURRENT (FDA M1 v2.6) | Regulatory SME (US) + PO | T1b → T5-US |
| `R-FMT-05` | Format | **RE_MODEL** | RegionalImplementation `Canada_Module1`, layered on `ICH_eCTD_3_2_2` | STRUCTURED_XML (T1b) | STRONG | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | REFRESH_REQUIRED | Regulatory SME (CA) + PO | T1b → T5-CA |
| `R-FMT-06` | Format | **RE_MODEL** | RegionalImplementation `Switzerland_Module1`, layered on `ICH_eCTD_3_2_2` | STRUCTURED_XML (T1b) | STRONG | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | REFRESH_REQUIRED | Regulatory SME (CH) + PO | T1b → T5-CH |
| `R-FMT-07` | Format | **RE_MODEL** | RegionalImplementation `GCC_Module1`, layered on `ICH_eCTD_3_2_2` | STRUCTURED_XML (T1b) | STRONG; authority/name evidence WEAK | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | REFRESH_REQUIRED | Regulatory SME (GCC) + PO | T1b → T5-GCC |
| `R-FMT-08` | Format | **RE_MODEL** | TechnicalStandard `NeeS` | PHYSICAL_MARKER (current) + absent backbone | MEDIUM | `EVIDENCE_OVERSTATED` | REFRESH_REQUIRED | Regulatory SME (EU) + PO | T4 (EU v3 + NeeS) |
| `R-FMT-09` | Format | **RE_MODEL** | TechnicalStandard `VNeeS` (ProductDomain `Veterinary` via relationship) | PATH (no VNeeS marker yet) | WEAK now; MEDIUM only after an approved VNeeS marker | `EVIDENCE_OVERSTATED`, `INSUFFICIENT_BASIS` | REFRESH_REQUIRED | Regulatory SME (vet) + PO | Decision U7 → marker task → T5-VET |
| `R-FMT-10` | Format | **RE_MODEL** | Candidate only: TechnicalStandard `Non_eCTD_Electronic` or SourcePresentation (decision U6) | PACKAGE_STRUCTURE (current) | WEAK (candidate / limiting factor only) | `EVIDENCE_OVERSTATED`, `VALID_INTENT_REMODEL_REQUIRED` | REFRESH_REQUIRED | Migration SME + PO | Decision U6 → T4 limiting factor |
| `R-FMT-11` | Format | **RE_MODEL** | ProcedureContext `ASMF` | ENVELOPE (T1b-EU); text WEAK | STRONG via typed envelope field; otherwise WEAK | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | VERIFIED_CURRENT (EU M1 IG v3.1.1) | Regulatory SME (EU) + PO | Decision U1 → T1b → T5-EU |
| `R-FMT-12` | Format | **RE_MODEL** | ProcedureContext (US DMF; new master-data value, decision U5) | STRUCTURED_XML (T1b) | STRONG via coded application type; otherwise WEAK | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `OUTDATED_SOURCE` | VERIFIED_CURRENT (FDA application-type list v1.1) | Regulatory SME (US) + PO | Decision U5 → T1b → T5-US |
| `R-FMT-13` | Format | **REJECT** | — (intent: ProductDomain `MedicalDevice`, backlog) | FREE_TEXT | n/a | `DIMENSION_WRONG`, `UNCONTROLLED_TEXT_INFERENCE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decision U9 backlog |
| `R-FMT-14` | Format | **REJECT** | — (device premarket pathway; not a technical standard) | FREE_TEXT | n/a | `DIMENSION_WRONG`, `OUT_OF_SCOPE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decision U9 backlog |
| `R-FMT-15` | Format | **REJECT** | — (device premarket pathway; not a technical standard) | FREE_TEXT | n/a | `DIMENSION_WRONG`, `OUT_OF_SCOPE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decision U9 backlog |
| `R-FMT-16` | Format | **REJECT** | — (intent: EAEU implementation, backlog) | FREE_TEXT / PATH | n/a | `UNCONTROLLED_TEXT_INFERENCE`, `INSUFFICIENT_BASIS` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T5-EAEU backlog |
| `R-FMT-17` | Format | **REJECT** | — (superseded by EvaluationStatus + ReviewRequired) | n/a | n/a | `DUPLICATE_OR_SUPERSEDED` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T3a tieBehavior guard |
| `R-TYP-01` | Type | **RE_MODEL** | ProductDomain `Human`, relationship-derived | RELATIONSHIP_DERIVED; text WEAK | MEDIUM (relationship, G) | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED`, `VALID_INTENT_REMODEL_REQUIRED` | VERIFICATION_REQUIRED (EU M1 agencies are H/V) | Regulatory SME + PO | Decision U8 → T4/T5 |
| `R-TYP-02` | Type | **RE_MODEL** | ProductDomain `Veterinary`, relationship-derived from VNeeS | RELATIONSHIP_DERIVED (needs VNeeS marker); text WEAK | WEAK now; MEDIUM after marker | `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | REFRESH_REQUIRED | Regulatory SME (vet) + PO | Decision U7 → T5-VET |
| `R-TYP-03` | Type | **SEED_AS_DRAFT** | LifecycleContext `Investigational` (US scope) | STRUCTURED_XML (T1b) | STRONG via coded application type; text WEAK | `CURRENT_SOURCE_VERIFIED`, `DIMENSION_WRONG`, `OUTDATED_SOURCE` | VERIFIED_CURRENT (FDA M1 v2.6; application-type v1.1) | Regulatory SME (US) + PO | T3b Draft seed (dormant until T1b) |
| `R-TYP-04` | Type | **SEED_AS_DRAFT** | LifecycleContext `PostMarketing` (per submission unit) | STRUCTURED_XML (T1b) + ENVELOPE (T1b-EU) | STRONG via coded submission type plus application type | `CURRENT_SOURCE_VERIFIED`, `DIMENSION_WRONG`, `EVIDENCE_OVERSTATED` | VERIFIED_CURRENT (FDA M1 v2.6 Table 2; EU M1 IG v3.1.1) | Regulatory SME (US, EU) + PO | T3b Draft seed (dormant until T1b) |
| `R-TYP-05` | Type | **REJECT** | — (intent: ProductDomain `MedicalDevice`, backlog) | FREE_TEXT | n/a | `UNCONTROLLED_TEXT_INFERENCE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decision U9 backlog |
| `R-TYP-06` | Type | **SEED_AS_DRAFT** | ProductClass `Biologic` (US scope) | STRUCTURED_XML (T1b) | STRONG via coded application type; text WEAK | `CURRENT_SOURCE_VERIFIED`, `DIMENSION_WRONG` | VERIFIED_CURRENT (FDA application-type v1.1; FDA CBER BLA page) | Regulatory SME (US) + PO | T3b Draft seed (dormant until T1b) |
| `R-TYP-07` | Type | **REJECT** | — (intent: ProductClass `Vaccine`, backlog) | FREE_TEXT | n/a | `UNCONTROLLED_TEXT_INFERENCE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decision U9 backlog |
| `R-TYP-08` | Type | **REJECT** | — (intent: ProductClass `BloodProduct`; PMF part goes to decision U5) | FREE_TEXT | n/a | `UNCONTROLLED_TEXT_INFERENCE` | NOT_REQUIRED (REJECT) | PO (acknowledge) | Decisions U5, U9 |
| `R-TYP-09` | Type | **REJECT** | — (covered by R-FMT-11/12; CEP is decision U5) | FREE_TEXT + STRUCTURED (duplicated) | n/a | `DUPLICATE_OR_SUPERSEDED`, `DIMENSION_WRONG` | NOT_REQUIRED (REJECT) | PO (acknowledge) | See R-FMT-11/12 |
| `R-TYP-10` | Type | **REJECT** | — (`Other` is a master-data value; unknown is an EvaluationStatus) | FREE_TEXT | n/a | `DUPLICATE_OR_SUPERSEDED`, `INSUFFICIENT_BASIS` | NOT_REQUIRED (REJECT) | PO (acknowledge) | T3a tieBehavior guard |

Total: 39 rows; every prior ID appears exactly once (checked by script, §12).

## 5. Summary counts

### 5.1 By disposition

| Disposition | Count |
|---|---|
| RE_MODEL | 19 |
| SEED_AS_DRAFT | 4 |
| REJECT | 16 |
| **Total** | **39** |

### 5.2 By prior category

| Prior category | RE_MODEL | SEED_AS_DRAFT | REJECT | Total |
|---|---|---|---|---|
| Region | 6 | 0 | 6 | 12 |
| Format | 11 | 1 | 5 | 17 |
| Type | 2 | 3 | 5 | 10 |

### 5.3 By canonical target

Counts cover non-rejected rows only, using each row's primary target.

| Canonical target | Count | Rules |
|---|---|---|
| RegionalImplementation (Region only via relationship) | 10 | R-REG-01, 03, 04, 08, 10; R-FMT-03…07 |
| TechnicalStandard | 5 | R-FMT-01, 02, 08, 09, 10 (the last is a candidate only) |
| ProcedureContext | 2 | R-FMT-11, 12 |
| ProductDomain | 2 | R-TYP-01, 02 |
| LifecycleContext | 2 | R-TYP-03, 04 |
| Region | 1 | R-REG-09 |
| ProductClass | 1 | R-TYP-06 |
| **Total non-rejected** | **23** | |

After re-modelling, the 10 RegionalImplementation rows reduce to **6 distinct targets**, because rule pairs collapse: `R-REG-03`+`R-FMT-03` (EU), `R-REG-10`+`R-FMT-04` (US), `R-REG-01`+`R-FMT-05` (CA), `R-REG-08`+`R-FMT-06` (CH) and `R-REG-04`+`R-FMT-07` (GCC). Each pair also needs a separate relationship-governed Region rule. The workbook should hold one replacement rule per target, with both prior IDs in its legacy cross-reference.

### 5.4 Required counts

| Measure | Count | Rules |
|---|---|---|
| Need an official-source refresh before any replacement becomes Effective | **15** | R-REG-01, 03, 04, 08, 09; R-FMT-02, 03, 05, 06, 07, 08, 09, 10; R-TYP-01, 02 |
| Already verified current (§7) | 8 | R-FMT-01, R-TYP-03, 04, 06 (SEED); R-REG-10, R-FMT-04, 11, 12 (RE_MODEL premise only) |
| Blocked on future v4 XML evidence (T2) | **1** | R-FMT-02 |
| Blocked on T1b (non-EU backbone fields / EU envelope fields) | 14 | R-REG-01, 04, 08, 09, 10; R-FMT-04, 05, 06, 07, 11, 12; R-TYP-03, 04, 06 |
| Blocked on an unapproved VNeeS physical marker | 2 | R-FMT-09, R-TYP-02 |
| **Rejected** because of dimension misuse | **5** | R-REG-11, R-FMT-13, 14, 15, R-TYP-09 |
| Dimension corrected in RE_MODEL | 14 | All RE_MODEL rows tagged `DIMENSION_WRONG` |
| Re-modelled because evidence strength was overstated | **19** | Every RE_MODEL row |
| Rejected with evidence overstated | 1 | R-REG-11 |
| Seeded with an overstated branch removed | 2 | R-FMT-01, R-TYP-04 |
| Rejected for uncontrolled text inference | 8 | R-REG-02, 05, 06; R-FMT-13, 16; R-TYP-05, 07, 08 (primary or secondary) |
| Implementable on current evidence (no capability blocker) | 6 | R-REG-03, R-FMT-01, 03, 08, 10, R-TYP-01. R-TYP-01 is held by decision U8. |

Note: a row may carry several rationale codes, so the required counts above are not mutually exclusive.

## 6. Canonical correction themes

1. **RegionalImplementation authored as a technical format.** R-FMT-03…07 named regional Module 1 variants as formats. They become `RegionalImplementation` values layered on `ICH_eCTD_3_2_2` through `TechnicalStandardToRegionalImplementation` (Content Catalogue §17–18).
2. **Region collapsed with RegionalImplementation.** R-REG-01/03/04/08/10 inferred Region straight from the presence of a regional backbone. A regional backbone strongly identifies the **implementation**. Region follows only through an approved relationship, with a governed confidence limit (Identification REVIEW, amendment 6).
3. **ASMF/DMF as formats.** R-FMT-11/12, and the duplicate R-TYP-09, become `ProcedureContext`. EU M1 IG v3.1.1 confirms `asmf` (and `pmf`) as **typed envelope submission types**, a structured Strong-capable basis once envelope fields are captured. FDA confirms DMF as coded application type `fdaat5`.
4. **Presence/absence treated as conclusive.** Many rules claimed a High result from the mere presence of a backbone or marker file (or, for NeeS, from absence). Under T1a and the accepted normalization these are MEDIUM at most. STRONG needs parsed structured fields (root, namespace, DTD version, typed attributes).
5. **v4 physical markers.** R-FMT-02 and R-REG-11 claimed High from v4 files. Physical v4 markers cap at MEDIUM. STRONG v4 requires `SubmissionUnitXmlInventory` (T2).
6. **Free text and broad groupings.** Country/authority names, folder names, product terms and the MENA/LATAM/"Rest of Europe"/"Other" groupings cannot produce a final value (Req v3.1 §8; Weak-only floor). They are rejected, and the intent goes to authority-specific packs (T5).
7. **Non-canonical Category/Type axis.** The prior Type list mixed ProductDomain (Human, Veterinary, devices), LifecycleContext (Investigational, PostMarketing), ProductClass (Biologic, Vaccine, BloodProduct) and ProcedureContext (ASMF/DMF/CEP). Each surviving intent now targets exactly one canonical dimension.
8. **Unknown/Other as rules.** R-FMT-17, R-REG-12 and R-TYP-10 are replaced by the result model: Conflict or InsufficientEvidence, a null value, ReviewRequired, and constrained `tieBehavior`. `Other` remains a master-data value that a rule may target.
9. **Outdated premises:**
   - FDA application types are coded (`fdaat1…`);
   - the EU M1 citation (v3.1, June 2024) is superseded by IG v3.1.1 (June 2025);
   - the EEA states use EU M1;
   - `uk` has been withdrawn in favour of `xi` (UK(NI));
   - Canada still cites a 2012 consultation document;
   - the GCC and Swiss specification versions need a refresh.
10. **Dimension-scoped resolution, not global uniqueness.** Codes such as `Other`/`Unknown`, and potentially `EAEU` (Region versus RegionalImplementation) or `UK`, can exist in several dimensions. Each candidate must resolve only inside its declared `targetEntityType`. This register does **not** recommend global code uniqueness (T3 REVIEW amendment 3).

## 7. Official-source verification (SEED_AS_DRAFT and verified premises)

All sources were retrieved on 2026-10-06. Each row separates the **regulatory fact** from the **eMAS design decision** (D) the seed would encode.

| Rule | Official source (title / version / section) | Regulatory fact | eMAS design decision (Draft) |
|---|---|---|---|
| R-FMT-01 | ICH M2 *eCTD Specification* **v3.2.2, 16 July 2008**. FDA *eCTD Submission Standards for eCTD v3.2.2 and Regional M1* (page updated 2026-08-27) lists ICH eCTD 3.2.2 as current. EU M1 IG **v3.1.1** (June 2025) is titled "eCTD 3.2.2 – EU M1". | eCTD v3.2.2 is the current ICH v3 specification. Its backbone is `index.xml` with root `ectd:ectd`, namespace `http://www.ich.org/ectd` and DTD version 3.2. | `TechnicalStandard = ICH_eCTD_3_2_2` at STRONG only from the parsed root, namespace and DTD fields. File presence alone stays MEDIUM. The prior "some master files" applicability is dropped, because ProcedureContext is a separate dimension. |
| R-TYP-03 | FDA *The eCTD Backbone Files Specification for Module 1* **v2.6 (2025-03-31)** §III.A (application-number has an `application-type` attribute coded from `application-type.xml`). FDA `application-type.xml` **v1.1** (AsOf 20121101; FDA lists support from 2015-06-15): `fdaat4` = "Investigational New Drug (IND)". | A US IND sequence carries `application-type="fdaat4"` in `us-regional.xml` (DTD 3.3). The literal non-coded value the prior rule assumed is not valid under DTD 3.3. | `LifecycleContext = Investigational` at STRONG from the coded application type (US scope only). Clinical-trial keywords stay WEAK. The EU branch is excluded because the EU M1 envelope type list does not represent clinical-trial applications (to be re-verified by the EU SME). |
| R-TYP-04 | FDA M1 v2.6 **Table 2** (submission types and valid application types). FDA `submission-type.xml` **v1.3** (AsOf 20200727). EU M1 IG v3.1.1 envelope `submission/@type` value list (§ envelope; DTD `ATTLIST submission`). | US: Efficacy, CMC, Labeling and REMS supplements and PMR/PMC are valid only for NDA, ANDA or BLA (with variations by type). **Annual Report and Product Correspondence are also valid for IND and DMF.** EU: types such as `var-type1a/1ain/1b/2`, `var-nat`, `extension`, `renewal`, `psusa`, `pam-*` and `pass107*` are post-authorisation activities. `maa` is an initial application. | `LifecycleContext = PostMarketing` at STRONG only when a post-authorisation submission type **combines** with a marketed application type (US: not `fdaat4`/`fdaat5`). Evaluated per submission unit, with dossier aggregation per Identification REVIEW amendment 5. The prior "annual report ⇒ post-marketing" branch is removed. |
| R-TYP-06 | FDA CBER *Biologics License Applications (BLAs) for CBER-Regulated Products* (page updated 2026-09-08; PHS Act, 42 U.S.C. 262; 21 CFR 600–680). FDA `application-type.xml` v1.1: `fdaat3` = "Biologic License Application (BLA)". | A BLA is the request to introduce a **biological product** into interstate commerce. | `ProductClass = Biologic` at STRONG from `fdaat3` (US scope). Vaccine and blood-product subclasses are **not** derivable from the BLA code alone (see R-TYP-07/08 REJECT). |
| R-REG-10 / R-FMT-04 (RE_MODEL premise) | FDA M1 v2.6 §II: root `fda-regional:fda-regional`, `dtd-version="3.3"`, namespace `http://www.ich.org/fda`, file `m1/us/us-regional.xml`. | These are the current US regional backbone identifiers. | RegionalImplementation `US_FDA_Module1` at STRONG from these fields once T1b parses them. Region `US` only via relationship (G). |
| R-FMT-11 (RE_MODEL premise) | EU M1 IG v3.1.1 envelope `submission/@type`: `asmf` = Active Substance Master File; `pmf` = Plasma Master File. | ASMF is a typed EU submission context. | ProcedureContext `ASMF` at STRONG from the typed envelope field. Text-based ASMF terms stay WEAK. PMF needs a master-data decision (U5). |
| R-FMT-12 (RE_MODEL premise) | FDA `application-type.xml` v1.1: `fdaat5` = "Drug Master File (DMF)". | A US DMF is a coded application type. | ProcedureContext (US DMF) at STRONG once T1b captures it. A new ProcedureContext master-data value is needed (U5). |
| R-REG-07 (REJECT; premise contradicted) | EU M1 IG v3.1.1 **Appendix 2.1** (destination codes): `is`, `li` and `no` are listed alongside the EU states, and agencies IS-IMCA, LI-LLV and NO-NOMA appear in the agency list. | Iceland, Liechtenstein and Norway submit through EU M1. | "Rest of Europe" must not capture IS/LI/NO. How EEA destinations map to Region is decision U3. |
| R-REG-09 (RE_MODEL) | EU M1 IG v3.1.1 Appendix 2.1: `uk` is "Not to be used anymore"; `xi` is used for UK Northern Ireland. The agency list notes that `UK-MHRA` refers to UK(NI) in an EU eCTD submission. | UK(NI) appears in EU M1 under `xi`. Great Britain national submissions are outside EU M1. | The Region `UK` rule needs decision U4 (NI versus GB, and which RegionalImplementation). The prior gov.uk IRP citation must be refreshed by the UK SME. |
| R-FMT-14/15 (REJECT; supporting fact) | FDA `application-type.xml` v1.1 comment: the IDE, PMA and 510k codes "should only be used in the cross-reference-application-number element". | Device premarket pathways appear in drug eCTD only as cross-references. | Not a TechnicalStandard and not an MS-04 identification target (U9). |

**Not verified (marked REFRESH_REQUIRED, never assumed):**
- Health Canada's current Canadian M1 specification/DTD;
- the GCC M1 specification (the prior cites v1.5, 2021);
- Swissmedic's CH M1 specification (the prior cites v1.5);
- the current EU status of NeeS acceptance;
- VNeeS guidance and any mandated folder marker;
- the eCTD v4 IG versions, re-confirmed at T2 (the earlier `EMAS-MS04-ECTD4-DISCOVERY-DESIGN` report verified them at that time);
- whether EU M1 implies the human domain. The EU M1 agency list marks agencies H/V, so "EU M1 ⇒ Human" is **not** safe without further evidence (U8).

The ICH website did not render for automated retrieval. I used the FDA and EU official pages as current corroboration of v3.2.2.

## 8. Guard-to-failure mapping

These are the guards T3a/T3b must implement. T3c does not edit validators.

| Guard | Owner | Prior failures it prevents | Negative fixture pattern (synthetic; no prior payload) |
|---|---|---|---|
| **G1 Dimension-scoped candidate target**: `outputCode` must exist in the declared `targetEntityType`, and `targetEntityType` must match the rule's identification dimension group. **No global code uniqueness.** | T3a | R-FMT-03…07, 11, 12; R-REG-11; R-TYP-09; R-FMT-13…15; the Category/Type axis | `targetEntityType=TECHNICAL_STANDARD` with a ProcedureContext-only code → reject. The same code string legitimately present in two dimensions → accept. |
| **G2 Field `maxEvidenceStrength` ceiling**: a rule's output strength must be ≤ the minimum ceiling of its required evidence fields. | T3a (schema/validator); T3b (field catalogue rows) | Every presence/absence → High rule (R-REG-01/03/04/08/10, R-FMT-01…08); names → Medium (R-TYP-01/02, R-FMT-07/09/10) | A STRONG output that requires only a `*MarkerFile`/path field → reject. |
| **G3 No final value from Weak-only evidence** (`conflictPolicy.minimumEvidenceStrengthForValue`; the floor value is a governed decision) | T3a (capability); PO (value) | R-REG-02/05/06/07/12, R-FMT-10/16, R-TYP-05/07/08 | A Weak-only candidate → InsufficientEvidence and a null value. |
| **G4 v4 physical markers capped below STRONG** (`SubmissionUnitMarkerFile`, `ChecksumFileMarker` and v4 `RegulatoryUnitKind` ceilings at MEDIUM/WEAK) | T3a/T3b (G2 instance) | R-FMT-02, R-REG-11 | An eCTD_4_0 STRONG rule on marker fields only → reject. |
| **G5 Draft-only new/changed regulatory rules**; Effective needs recorded Regulatory SME + PO evidence | T3b (lifecycle/approval columns) | All 23 non-rejected rows | Draft → Effective without approval evidence → validation error. |
| **G6 Effective-only, dependency-safe export** | T3b | Stops the 4 seeds and 19 re-models leaking into runtime JSON (T3 POC-3 proved Draft rows leak today) | A Draft rule with outputs/conditions → absent from export, with no orphan rows. |
| **G7 No direct legacy JSON import**: no importer, and every new rule carries a fresh RuleId. Prior IDs are kept only as an informational legacy cross-reference, never as runtime IDs (Req v3.1 §9). | T3b (content process) + review | Whole prior file, including the 5 non-identification collections | Import attempt / runtime RuleId matching `R-(REG|FMT|TYP)-nn` → content review failure. |
| **G8 Constrained `tieBehavior` / Unknown as status** | T3a | R-FMT-17, R-REG-12, R-TYP-10 | `tieBehavior` outside `UNKNOWN`/`MANUAL_REVIEW` → reject. A candidate code `UNKNOWN` used as a final-value fallback → reject. |
| **G9 Region via relationship only**: a Region output from a RegionalImplementation must cite an approved `…ToRegion` relationship row | T3a (semantic check) / T4 (engine) | R-REG-01/03/04/08/10 | A Region output from backbone evidence without a relationship row → reject. |

## 9. Rules blocked on future evidence capabilities

| Capability | Status | Rules | What it must provide |
|---|---|---|---|
| **T2 `SubmissionUnitXmlInventory`** | Planned | R-FMT-02 | Parsed v4 submission-unit XML (ICH/regional IG identifiers, context of use) for STRONG `eCTD_4_0` and v4 Region/RegionalImplementation |
| **T1b Regional backbone generalisation** | Planned for non-EU backbones | R-REG-01/04/08/10, R-FMT-04…07, R-FMT-12, R-TYP-03/04/06 | Parsed US/CA/CH/GCC regional roots, namespaces and DTDs, plus typed US `application-type` and `submission-type` attributes |
| **T1b scope extension: EU envelope fields** | **Not yet in scope (decision U1)** | R-FMT-11, R-TYP-04 (EU branch), R-REG-09, plus optional destination evidence for R-REG-03 | Typed EU `envelope/submission/@type` and destination/agency codes |
| **VNeeS physical marker** | **Not planned (decision U7)** | R-FMT-09, R-TYP-02 | An approved, source-verified VNeeS physical marker. Without it the rules stay WEAK. |
| None (current evidence) | Available after T1a | R-FMT-01, R-FMT-03 + R-REG-03 (EU_Module1; Region via relationship), R-FMT-08 (NeeS via TOC marker), R-FMT-10 (limiting factor) | Covered by the T4 EU v3 + NeeS scope |

## 10. Follow-up sequence

1. **T3c acceptance.** This register becomes the controlled legacy content backlog. Rejected intents are recorded as backlog items, not rules.
2. **T3a (Schema 1.1.0).** Implement G1, G2, G3 (capability), G4 (through G2), G8 and G9 with the synthetic negative fixtures in §8. There is no global code-uniqueness check.
3. **T3b (workbook/export).** Implement G5–G7: lifecycle and approval columns, a `LegacyRuleId` informational column, and Effective-only dependency-safe export. Seed `R-FMT-01` as Draft first. The `R-TYP-03/04/06` seeds may be entered as Draft only once their T1b fields exist in the field catalogue; until then they stay in the backlog.
4. **T4 EU v3 + NeeS rule pack (Draft → review).** Re-model `R-FMT-01` (seed), `R-FMT-03`+`R-REG-03` (EU_Module1 plus relationship-governed Region EU), `R-FMT-08` (NeeS) and `R-FMT-10` (limiting factor). Refresh the EU M1 citation to IG v3.1.1. The Regulatory SME and PO must approve before Effective.
5. **T1b.** Then the regional packs (T5-US, CA, CH, GCC) re-model their RegionalImplementation/Region pairs, plus `R-FMT-11/12` and the Type seeds, one governed pack at a time with refreshed sources.
6. **T2.** Then the `R-FMT-02` re-model can reach STRONG from v4 XML.
7. **Decisions U3–U9** unlock the remaining backlog: EEA, UK, master-data values, VNeeS, ProductDomain derivation, and device/vaccine/blood-product scope.

No step makes any legacy-derived rule Effective automatically.

## 11. Unresolved SME/PO decisions and blockers

| ID | Decision | Owner | Affects |
|---|---|---|---|
| U1 | Extend T1b to capture typed EU envelope fields (submission type, destination/agency code)? | Technical Architect + PO | R-FMT-11, R-TYP-04 (EU), R-REG-09, R-REG-03 |
| U2 | The Region-from-RegionalImplementation confidence limit for each region. This extends the existing EU MaxMedium decision to US/CA/CH/GCC. | Regulatory SME + PO | 5 RegionalImplementation/Region pairs |
| U3 | How IS/LI/NO, which submit via EU M1, map to Region: `EU`, a new `EEA` value, or `RestOfEurope`? What, if anything, `RestOfEurope` means? | Regulatory SME (EU) + PO | R-REG-07 backlog, R-REG-03 |
| U4 | UK: how UK(NI) (`xi` in EU M1) relates to Great Britain national submissions, and whether a `UK_Module1` RegionalImplementation exists. | Regulatory SME (UK) + PO | R-REG-09 |
| U5 | ProcedureContext master data: add US DMF, EU PMF and possibly VAMF? How to treat CEP (an EDQM certificate, not a dossier context)? | Regulatory SME + PO | R-FMT-11/12, R-TYP-08/09 |
| U6 | The R-FMT-10 target: TechnicalStandard `Non_eCTD_Electronic` or SourcePresentation `ElectronicUnstructured`? | Migration SME + PO | R-FMT-10 |
| U7 | Approve and verify a VNeeS physical marker task? | Regulatory SME (vet) + PO | R-FMT-09, R-TYP-02 |
| U8 | May ProductDomain be relationship-derived from TechnicalStandard/RegionalImplementation, and at what cap, given that EU M1 covers H/V agencies? | Regulatory SME + PO | R-TYP-01, 02 |
| U9 | Are medical devices, vaccine and blood-product subclasses in MS-04 identification scope, and with which evidence capability? | PO | R-FMT-13…15, R-TYP-05/07/08 |
| U10 | The Weak-only floor value (existing open decision) | PO | G3 |
| U11 | The legacy cross-reference column name and visibility in exported JSON (recommended: workbook-only, not exported) | PO + Technical Architect | G7 |

**Blockers:**
- **B1:** guards G1–G4, G8 and G9 need T3a acceptance.
- **B2:** Draft seeding needs T3b.
- **B3:** 14 rows need T1b, and 4 of them need decision U1.
- **B4:** R-FMT-02 STRONG needs T2.
- **B5:** no legacy-derived rule becomes Effective without Regulatory SME and PO approval, and the 15 refresh-required rows need their sources refreshed first.

## 12. Confidentiality and verification evidence

- **Not committed:** `eMAS_PreSalesMapping.json`, the Classification Mapping v2.1 workbook, the guide `.docx`, the Sample Data Catalogue and the Scenario Matrix. They stay outside the repository; only their short SHA-256 prefixes appear in §1.
- **Redaction:** the register contains no prior condition text, file/folder/keyword patterns, confidence wording, recommended-output strings or prior source URLs. Official sources are cited by public title and version.
- **Automated check (scratch, not committed):** I ran a 6-word sliding-window comparison of this report against every string value in the 39 prior rules. Result: **0 shared 6-word sequences**. A second check confirmed that every one of the 39 prior IDs appears exactly once in the register.
- **Diff scope:** one file changed: `docs/internal/agent-tasks/EMAS-MS04-PRIOR-MAPPING-DISPOSITION/reports/CLAUDE.md`.
- **Scratch only:** the generator, the detailed internal working register and the extracted official-source text are kept in the session scratchpad and not committed.
