# Claude Report — T1b Regional XML Evidence Design (EU Module 1)

**Status:** `READY_FOR_CENTRAL_REVIEW`
**Task:** `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN` (report only; no code, fixture, test, schema or workbook change)
**Base:** `5d2ab2d1337f3a93a30f999fed3a9e9436724d1a` (`demo/end-to-end-mvp`, T4 integrated)
**Branch:** `analysis/emas-ms04-regional-xml-evidence-t1b-design`, draft PR [MightyM-ouse/eMAS#59](https://github.com/MightyM-ouse/eMAS/pull/59)

Conventions used in this report:
- **[REG]** marks an authoritative regulatory fact from the cited official source.
- **[DES]** marks an eMAS design decision proposed here.
- **[OBS]** marks an observation in the accepted repository corpus.

---

## 1. Executive recommendation

1. **Collect five typed EU envelope fields in the first wave.** Every field is a DTD-enumerated attribute value that is mandatory in its profile:

   | # | Field | XML location | Profiles |
   |---|---|---|---|
   | 1 | Envelope destination | `envelope/@country` | all |
   | 2 | Receiving agency | `agency/@code` | all |
   | 3 | Authorisation procedure type | `procedure/@type` | all |
   | 4 | Regulatory activity (submission) type | `submission/@type` | all |
   | 5 | Submission unit type | `submission-unit/@type` | 3.0.1 and 3.1 only |

   - Each field is verified against official EMA EU M1 specifications for all three EU DTD generations present in the corpus: `2.0`, `3.0.1` and `3.1`.
   - The regional profile facts are **already collected**. Regional root element, namespace, `dtd-version`, DOCTYPE name and system identifier are emitted today by BackboneXmlInventory and CEC, so no new work is needed there.
   - Free-text, identifier and relational envelope elements stay out of the first wave:
     - applicant, invented name, INN and description;
     - tracking/high-level numbers and UUID;
     - sequence and related-sequence.

2. **Architecture: Option A, extend BackboneXmlInventory (BXI)** through a new private helper, `engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1`.
   - BXI already loads the full DOM of every `eu-regional.xml` with the safe reader and discards everything but root metadata.
   - Reading the envelope from that same DOM is the only option with **no duplicate XML parsing**.
   - CEC consumes the new upstream facts and **never reopens XML**.
   - Cost: BXI is an RC1 byte-frozen file (`.gitattributes`, `-text`), so the change needs RC1 re-qualification (PO decision P-1).

3. **ScannerObservations contract:** an **additive** change that stays `eMAS.MS04.PreSales.ScannerObservations/1.0`.
   - Each XmlDocument gets one nullable `RegionalEnvelope` object.
   - CEC gets five new evidence types, assigned after all historical types so every existing `EVD-nnnn` keeps its number.
   - New per-field coverage rows are added. No existing field changes meaning.

4. **Raw CEC strength:** all five types are `Strong`, `SourceTier = StructuredXml`. That tier is deliberately the same as the regional root/namespace evidence from the same document, so one XML file can never corroborate itself into `INDEPENDENT_SOURCE_CLASS` confidence.
   - `CandidateValue`, `Polarity` and `SourceRuleId` stay `null`.
   - No record asserts Region, RegionalImplementation, ProcedureContext, LifecycleContext or TechnicalStandard.

5. **T4 impact is zero until a separate projection task.** The new fields are not in the frozen T4 `CEC-FIELD-PROJECTION/1`, so the engine cannot consume them yet; a rule that tries fails with `IDI-CONFIG-004`.
   - Consumption needs a later `CEC-FIELD-PROJECTION/2` / T4a contract revision, which must add:
     - multi-envelope set semantics;
     - per-field coverage;
     - an `UnrecognizedValue` reason.
   - The accepted T4 short pipeline (RD → BXI → CEC → Identification) is unaffected. It even gains the facts automatically, because they ride inside BXI.

---

## 2. Authoritative source ledger

All sources come from the official EMA eSubmission website, EU Module 1 page (`https://esubmission.ema.europa.eu/eumodule1/index.htm`, accessed 2026-10-06). SHA-256 values identify the exact files read.

| ID | Issuing authority | Document / package | Version / date | SHA-256 (file read) | Status on EMA page |
|---|---|---|---|---|---|
| S1 | EMA (eSubmission) | EU Module 1 web page: version list, status and links | accessed 2026-10-06 | — | — |
| S2 | EMA / eSubmission Expert Group | *EU Module 1 eCTD Specification* (`EU M1 eCTD Spec v2.0_February 2013.rtf`) | v2.0, February 2013 (DTD `2.0`) | `a8dc4b144e48aea6766165d09874f8637624bd0f3f37cc33f95b9efea9363a37` | Historical (reference only) |
| S3 | EMA | *EU Module 1 eCTD Specification* (`docs/EU M1 eCTD Spec v3.0.1.pdf`), 60 pp. | v3.0.1, May 2016 (DTD `3.0.1`) | `9e1702b9c8be4e59e87126ed4b1c5f28062cbc027a088288d39c8c6a6292ec85` | Historical |
| S4 | EMA / eSubmission Expert Group | *EU Module 1 eCTD Specification* (`EU M1 eCTD Spec v3.0.4.pdf`), 62 pp. | v3.0.4, February 2021 (DTD still `3.0.1`) | `86941d5b83cab84ff2cec6316af340d0266e34114614ca07eb626129d502d325` | Historical |
| S5 | EMA | *EU M1 eCTD Spec v3.1 – June 2024 – final version*, 64 pp. | v3.1, 18.06.2024 (DTD `3.1`) | `3f8b87d4924eeace4ad578b1d1976b44d61f54223f18e158d0632ada32997388` | "Can be used until 30 November 2025" |
| S6 | EMA | *Release notes for version 3.1.1 of the EU eCTD M1 Specification (minor update)* | June 2025 | — | v3.1.1 mandatory from 1 December 2025 |

### Clauses relied on

| Clause | S2 (v2.0) | S3 (v3.0.1) | S4 (v3.0.4) | S5 (v3.1) |
|---|---|---|---|---|
| Envelope narrative (one envelope per receiving MS; one for CP) | § "Envelope" (TOC p.10) | p.9 | p.9 | § "Envelope", pp.10–11 |
| Appendix 1.1 Envelope Element Description (constraint/occurrence table) | TOC p.14 | pp.14–20 | pp.14–21 | pp.16–23 |
| `country` | App. 1.1 | p.14 | p.14 | p.16 |
| `submission/@type` values | App. 1.1 | p.15 | p.15 | pp.17–19 |
| `submission/@mode` | App. 1.1 | p.17 | — | p.19 |
| `submission-unit/@type` values | n/a (element absent) | p.19 | p.20 | p.22 |
| `agency/@code` | App. 1.1 + App. 2.4 (TOC p.44) | p.19; App. 2.4 p.48 | p.20; App. 2.4 p.50 | p.22; App. 2.4 pp.52–53 |
| `procedure/@type` | App. 1.1 | p.19 | p.20 | pp.22–23 |
| `related-sequence` | App. 1.1 (Optional, Repeatable) | p.20 (Mandatory, Repeatable) | p.21 | p.23 (Mandatory, Repeatable) |
| Appendix 2.1 Destination codes | TOC p.41 | p.46 | p.48 | p.50 |
| Appendix 3 `eu:eu-backbone` ATTLIST (`xmlns:eu` FIXED `http://europa.eu.int`; `dtd-version` FIXED) | App. 3, `eu-regional.dtd` | p.52 | p.54 | p.56 |
| Appendix 3 `eu-envelope.mod` ELEMENT/ATTLIST declarations | App. 3, `eu-envelope.mod` | pp.56–58 | pp.58–60 | pp.60–62 |

**Notes on the sources:**
- S2 is an RTF document, which has no fixed pagination. Its citations use section headings and the document's own table-of-contents page numbers.
- S5 cites RMS vocabulary IDs for the enumerations:
  - Application Submission Type;
  - Submission Mode 100000155553;
  - Applicants Submission Unit Type 100000155046;
  - EU Regulatory Authorisation Procedure 100000154442;
  - EU Territorial Authority 100000160680.

  The RMS itself was **not** consulted. The design uses the **DTD enumerations** printed in Appendix 3 as the normative value lists, and RMS equivalence is recorded as `UNVERIFIED` (not needed for T1b).
- S6 lists only Implementation Guide text changes (super-grouping, number examples, an EDQM tracking exception). There is **no DTD or envelope change**, and S1 states "DTD: v3.1 (unchanged from v3.1)". The `3.1` profile therefore covers instances authored under both IG v3.1 and v3.1.1.

**Non-normative corroboration [OBS]:** the corpus ships DTD copies under `util/dtd/`. After removing comments and whitespace, the envelope declarations are **token-identical** to the official appendices:

| Corpus copy | Official appendix |
|---|---|
| DTD `2.0` `eu-envelope.mod` | S2 App. 3 |
| DTD `3.0.1` | S3 App. 3 and S4 App. 3 |
| DTD `3.1` | S5 App. 3 |

The `eu:eu-backbone` `dtd-version` FIXED values (`2.0`, `3.0.1`, `3.1`) also match. The design uses the official appendices as the authority; the corpus copies only confirm that the samples conform.

**Not used as authority:**
- vendor files in the corpus (`RegulatoryActivities.xml`, `ValidationReport_*.pdf`);
- the EU Validation Criteria spreadsheets (not needed for any proposed field);
- memory or secondary web sources.

---

## 3. Current evidence inventory (what exists today)

| Category | Item | Where | Status |
|---|---|---|---|
| **A. Factual evidence already available in CEC** | `RegionalBackbonePresence` (bool), `RegionalBackbonePath`, `Module1RegionalFolder` | CEC from RD/BXI (Supporting / OfficialPhysicalPath) | Available |
| | Regional `XmlRootElement` (`eu-backbone`), `XmlNamespace` (`http://europa.eu.int`) | CEC from BXI `RootElement` / `NamespaceUri` (Strong / StructuredXml) | Available |
| | Regional `DtdVersion` (`2.0`/`3.0.1`/`3.1`) | CEC from BXI `DeclaredVersion` (Strong / StructuredXml) | Available |
| | Regional `DocumentTypeName` (`eu:eu-backbone`), `DtdSystemIdentifier` (`../../util/dtd/eu-regional.dtd`) | CEC from BXI (Supporting / BackboneDeclaration) | Available |
| | Physical markers (T1a) | CEC | Available; unrelated to EU envelope |
| **B. Parsed upstream but not projected to CEC** | `RootAttributes` (incl. `xmlns:*`, `xml:lang`), `XmlDeclarationVersion`, `DeclaredEncoding`, `Standalone`, `PublicId` (null in EU) | BXI `XmlDocuments[]` | Present in ScannerObservations; no CEC type. Not needed for first wave |
| | Parse diagnostics (`ParseErrorCode`, line/position) | BXI | Used only for coverage |
| **C. Present in regional XML, not parsed today** | Entire `eu-envelope` subtree: `envelope/@country`, `identifier`, `submission/@type`/`@mode`/`number`, `procedure-tracking`/`tracking`/`number`, `submission-unit/@type`, `applicant`, `agency/@code`, `procedure/@type`, `invented-name`, `inn`, `sequence`, `related-sequence`, `submission-description` | `m1/eu/eu-regional.xml` | **Not available.** BXI loads the DOM, then discards it after root metadata |
| | `m1-eu` leaf metadata: country/language/PI-document attributes | same | Not available; deferred (§15) |
| **D. Cannot be collected safely without a new capability** | DTD validation of the instance, so enumeration and cardinality are proven by a validating parser | — | BXI deliberately runs `XmlResolver = $null` (no external DTD load), so values are *read*, not *validated* |
| | Interpretation of tracking-number formats (for example `FR/H/…/MR`) | — | Inference, not fact. Excluded |
| | Application identity across sequences via envelope UUID | — | RD has no application-identity concept. Excluded |
| | v4 `submissionunit.xml` | T2 | Out of scope |

A T4 consequence today: `CEC-FIELD-PROJECTION/1` projects only `CEC_XML_ROOT_ELEMENT_REGIONAL` and `CEC_XML_NAMESPACE_REGIONAL` for regional XML. No envelope field reaches Identification.

---

## 4. EU XML profile/version inventory observed in the repository

The corpus is SD-001…SD-020, all derived from one EXTEDORIN EU-FR dossier. Wave1D SD-044…051 (derived from SD-002) has the same regional XML.

| dtd-version | Official spec generation | `eu-regional.xml` instances | Envelopes | Observed values [OBS] |
|---|---|---|---|---|
| `2.0` | EU M1 v2.0 (S2) | 18 (sequence 0000) | 1 per doc | country `fr`; agency `FR-ANSM`; procedure `national`; submission `initial-maa`; no `submission-unit`, no `identifier`; `tracking` (not `procedure-tracking`); 0 `related-sequence` |
| `3.0.1` | EU M1 v3.0.1 → v3.0.4 (S3, S4) | 54 (sequences 0001–0003) | 18 docs × 1; 36 docs × 3 (fr, nl, de) | agency `FR-ANSM`/`NL-MEB`/`DE-BFARM`; procedure `national` (18 docs) and `mutual-recognition` (108 envelopes); submission `maa`/`var-type1a`; mode `single` (54); unit `initial`/`response` |
| `3.1` | EU M1 v3.1/v3.1.1 (S5, S6) | 16 (sequence 0004; 1 deliberately malformed, SD-008) | 2 per doc (fr, de) | `var-type1a`, mode `single`, unit `response`, `mutual-recognition` |

Corpus facts relevant to the design:
- **Multi-envelope documents are normal** (MRP, one envelope per receiving Member State). Country and agency legitimately differ between envelopes in one document.
- **Procedure type changes along the lifecycle:** `national` in 0000–0001, then `mutual-recognition` from 0002. This is a genuine lifecycle fact, not a conflict.
- **Mixed profiles inside one dossier:** 2.0 → 3.0.1 → 3.1 across sequences. Profile must be resolved **per document**, never per dossier.
- **Failure states already present in fixtures:**
  - SD-006: regional XML missing in 0004;
  - SD-008: regional XML malformed in 0004;
  - SD-012: "0004 - PSUR" folder, not an exact sequence.
- **The xlink namespace is the EU DTD's own FIXED value**, `http://www.w3c.org/1999/xlink` (not `w3.org`) [REG S2/S3/S5 App. 3]. It must not be "corrected".

Profiles that are **not** in the corpus get `UnsupportedRegionalProfile` until separately verified (§11, P-4):
- EU M1 v1.4/1.4.1 and v3.0;
- any `dtd-version` not in {2.0, 3.0.1, 3.1}.

---

## 5. Proposed first-wave typed field catalogue

All five are **[REG]** DTD-enumerated attributes on mandatory elements. Raw values only; interpretation is not part of this catalogue.

| FieldCode [DES] | XML [REG] | Meaning per official spec [REG] | Constraint / occurrence [REG] | Profiles |
|---|---|---|---|---|
| `EU_ENVELOPE_COUNTRY` | `envelope/@country` | "The country to which the envelope applies (or 'ema' or respectively 'edqm')" | Mandatory, unique per envelope; `envelope` Mandatory, Repeatable | 2.0, 3.0.1, 3.1 |
| `EU_AGENCY_CODE` | `envelope/agency/@code` | "The identification of the receiving agency (see Appendix 2.4)" | Mandatory, unique | 2.0, 3.0.1, 3.1 |
| `EU_PROCEDURE_TYPE` | `envelope/procedure/@type` | "The type of procedure for the submission" | Mandatory, unique | 2.0, 3.0.1, 3.1 |
| `EU_SUBMISSION_TYPE` | `envelope/submission/@type` | 2.0: "type of submission material"; 3.x: "type of regulatory activity" | Mandatory, unique | 2.0, 3.0.1, 3.1 (vocabulary changed) |
| `EU_SUBMISSION_UNIT_TYPE` | `envelope/submission-unit/@type` | "describes the content at a lower level (a 'sub-activity')" | Mandatory, unique (3.x) | 3.0.1, 3.1 only |

**Evaluated and excluded from the first wave [DES]:**

| Element | Reason | Earliest wave |
|---|---|---|
| `submission/@mode` | Optional; variation/extension only; no canonical consumer today | Wave 2 candidate (Supporting) |
| `sequence`, `related-sequence` | Lifecycle *relations*. 2.0 vs 3.x semantics differ (2.0 leaves related blank for new activities; 3.x sets it equal to the sequence) [REG S2/S5]. Belongs with `LifecycleRelationships`, not classification | Wave 2, with a relation design |
| `identifier` (UUID, 3.x) | Application identity; RD has no application concept (TASK constraint) | Needs PO decision (P-6) |
| `submission/number`, `procedure-tracking/number`, `tracking/number` | Identifiers. Their format implies procedure/agency only by **inference** | Not as classification evidence |
| `applicant`, `invented-name`, `inn`, `submission-description` | Free text / product names; possibly sensitive; must not become strong evidence | Not proposed; if ever collected, `Weak` and a free-text tier |
| `m1-eu` country/language attributes | Document-level, not submission-level; many elements | Deferred |

**Proposed first-wave field count: 5.** No new work is needed for the 3 profile facts that already exist (root, namespace, `dtd-version`).

---

## 6. XML selector / path matrix

**Namespace model [REG S2/S3/S5 App. 3]:**
- The root `eu:eu-backbone` is in namespace `http://europa.eu.int`.
- The DTD declares **no default namespace**, so `eu-envelope` and all descendants are in **no namespace**.

**Selector rules [DES]:**
- Use namespace-URI + local-name. Never match prefixes, so `eu:` vs `x:` makes no difference.
- Walk element children; no XPath and no namespace manager. This works the same on PS5.1 and PS7.
- Prerequisite P: root local-name `eu-backbone` **and** root namespace `http://europa.eu.int` **and** `dtd-version` ∈ {`2.0`,`3.0.1`,`3.1`}.
  - Root or namespace mismatch: `UnrecognizedRegionalStructure`.
  - Any other `dtd-version`, or a missing `dtd-version`: `UnsupportedRegionalProfile`.
- Envelope set: root → child `{}eu-envelope` (exactly one expected) → children `{}envelope` (1..n). Envelope order = document order, so `EnvelopeOrdinal` runs 1..n.

| FieldCode | Relative selector (from `envelope`) | Card. | Value type | Normalization [DES] | Vocabulary source |
|---|---|---|---|---|---|
| `EU_ENVELOPE_COUNTRY` | attribute `country` (no ns) | 1 | token | Trim XML whitespace (#x20/#x9/#xD/#xA, per XML 1.0 §3.3.3 for enumerated attributes, because a non-validating read gets CDATA). **Case-sensitive**; no case folding | `%env-countries;` of the document's profile |
| `EU_AGENCY_CODE` | child `{}agency` (1) → attribute `code` | 1 | token | same | `ATTLIST agency code` |
| `EU_PROCEDURE_TYPE` | child `{}procedure` (1) → attribute `type` | 1 | token | same | `ATTLIST procedure type` |
| `EU_SUBMISSION_TYPE` | child `{}submission` (1) → attribute `type` | 1 | token | same | `ATTLIST submission type` |
| `EU_SUBMISSION_UNIT_TYPE` | child `{}submission-unit` (1) → attribute `type` | 1 (3.x) | token | same | `ATTLIST submission-unit type` |

**Vocabulary sizes per profile** (taken from the verified DTD appendices):

| Field | 2.0 | 3.0.1 | 3.1 |
|---|---|---|---|
| country | 32 | 33 (+`edqm`) | 34 (+`xi`) |
| agency code | 33 | 34 (`AT-AGES`→`AT-BASG`, `IE-IMB`→`IE-HPRA`, +`EU-EDQM`) | 34 (unchanged) |
| procedure type | 4 | 4 | 4 |
| submission type | 26 | 51 | 52 (+`article-18`) |
| submission-unit type | — (element not defined) | 8 | 9 (+`re-examination`) |

The implementation embeds these lists as a versioned table, `EU-M1-ENVELOPE-VOCABULARY/1`. The lists are copied from S2/S3/S5 Appendix 3, with the source page recorded per list.

---

## 7. Historical-version compatibility matrix

| Field | 2.0 → 3.0.1 | 3.0.1 → 3.1 | Classification |
|---|---|---|---|
| `EU_ENVELOPE_COUNTRY` | same location; +`edqm` | same location; +`xi`. `uk` stays in the DTD but S5 App. 2.1 says "Not to be used anymore" | **Stable location; vocabulary extended**. Usage guidance is not a DTD constraint, so `uk` stays an in-vocabulary fact |
| `EU_AGENCY_CODE` | same location; 2 codes **renamed** (`AT-AGES`→`AT-BASG`, `IE-IMB`→`IE-HPRA`), +`EU-EDQM` | unchanged | **Stable location; vocabulary changed** (rename), not a pure extension. A 2.0 document with `AT-BASG` is out of vocabulary for 2.0 |
| `EU_PROCEDURE_TYPE` | unchanged | unchanged | **Stable** |
| `EU_SUBMISSION_TYPE` | same location. 9 values removed (incl. `initial-maa`, `supplemental-info`, `corrigendum`, `reformat`, `referral`, `fum`, `specific-obligation`) and 34 added (incl. `maa`, `psusa`, `pam-*`, `referral-*`, `cep`, `none`). The meaning shifts from "submission material" to "regulatory activity" | +`article-18` | **Vocabulary changed; semantics shifted**. `corrigendum` and `reformat` **moved** from submission type (2.0) to submission-unit type (3.x) |
| `EU_SUBMISSION_UNIT_TYPE` | **element introduced** in 3.0 / 3.0.1 | +`re-examination` | **Unavailable in 2.0** (`FieldNotDefinedInProfile`), never "absent" |
| (context) `related-sequence` | Optional → **Mandatory**; meaning for an initial activity changed | unchanged | Wave 2 only |
| (context) `tracking` → `procedure-tracking` | **renamed** | unchanged | Not collected |

Consequences [DES]:
- **Raw values are never normalized across versions.** `initial-maa` (2.0) and `maa` (3.x) stay distinct facts. Any equivalence is an Interpretation/master-data alias decision (P-3), not scanner logic.
- **Vocabulary checks are per document profile.** A value is "known" only for the profile that the same document's `dtd-version` declares.

---

## 8. Architecture decision

| Criterion | **A. Extend BXI** | B. New RegionalXmlInventory capability | C. CEC-side or post-hoc parser |
|---|---|---|---|
| No duplicate XML parsing | ✅ reuses the DOM already loaded by `Read-eMASSafeXmlDocument` | ❌ re-opens and re-parses every `eu-regional.xml` (ZIP + path safety + parser duplicated) | ❌ CEC reopening XML is forbidden |
| ScannerObservations stability | additive nullable property per XmlDocument | additive collection plus a new capability token | — |
| CEC fact-only boundary | ✅ CEC maps upstream facts | ✅ | ❌ |
| Testability | private helper testable on an in-memory `XmlDocument`; BXI integration tests | separate module, but more duplicated I/O to test | — |
| Historical EU versions | profile table inside the helper | same | — |
| Future US/CA/CH/GCC | helper per regional profile (`eMAS.<Region>RegionalEnvelope.ps1`) behind one dispatch keyed on (root ns, local-name, version) | same, in one module | — |
| PS5.1 | ✅ same APIs as today | ✅ | — |
| T4 short pipeline | ✅ unchanged chain; facts arrive with BXI | ❌ adds a stage to the short chain, or the facts are missing in it | — |
| Cost / risk | BXI is **RC1 byte-frozen**: requalification needed (P-1) | Leaves BXI frozen | — |

**Recommendation: Option A [DES].**
- **Edit to BXI:** dot-source the helper and, for `XmlKind = RegionalBackbone` with `ParseStatus = Parsed`, call `Get-eMASEuRegionalEnvelope -Document $document` before the DOM is released.
  - `Read-eMASXmlMetadata` gains one optional output property; the parse path is otherwise unchanged.
  - The kind-gated path `m1/eu/eu-regional.xml` is unchanged.
- **Helper:** owns the profile table, the selector walk, vocabulary checks and status codes. It contains no interpretation.
- **Fallback if the PO refuses to touch the RC1 file:** Option B with an explicit accepted cost of one duplicate parse per regional document. It is not recommended.

---

## 9. Proposed ScannerObservations additive shape / version impact

**Contract:** stays `eMAS.MS04.PreSales.ScannerObservations/1.0`. The change is additive and optional, which follows the T1a/Wave1E additive-evidence precedent and TR-JSON-007.
- `Execution.Capabilities` is unchanged; envelope collection is part of `BackboneXmlInventory`.
- `ScannerVersion` for BXI goes from `0.2.0` to `0.3.0`.
- Consumers detect support by the presence of the property.
- **Ownership:** BXI.
- **Subject:** the existing `XmlDocument` (`XmlId`), with `DossierId`/`SequenceId` already present. No application or Dossier identity is created.

New property on every `XmlDocuments[]` item (null for all non-regional kinds, and absent from older scanners):

```json
"RegionalEnvelope": {
  "ProfileFamily": "EU_M1",
  "ProfileVersion": "3.1",
  "ProfileStatus": "Supported | UnsupportedRegionalProfile | UnrecognizedRegionalStructure | NotAttempted",
  "VocabularyId": "EU-M1-ENVELOPE-VOCABULARY/1",
  "EnvelopeCount": 2,
  "Envelopes": [
    { "EnvelopeOrdinal": 1,
      "Fields": [
        { "FieldCode": "EU_ENVELOPE_COUNTRY", "Value": "fr",
          "ValueStatus": "Known | OutsideProfileVocabulary | Absent | NotDefinedInProfile | MultipleValues",
          "Occurrences": 1 }
      ] }
  ]
}
```

Rules [DES]:
- **Field order:** `Fields` is in the fixed catalogue order of §5. `Envelopes` follows document order.
- **`Value`:** the trimmed attribute value. It is `null` when `ValueStatus` is `Absent`, `NotDefinedInProfile` or `MultipleValues`. For `MultipleValues`, `Values[]` lists every value instead.
- **`ProfileStatus = NotAttempted`:** used when the document is missing, failed to parse or was inaccessible. BXI's existing `ParseStatus`/`CaptureStatus` keep carrying the reason, so no envelope status duplicates it.
- **No interpretation fields:** no Region, profile label or procedure conclusion appears anywhere in the object.

---

## 10. CEC evidence-type catalogue

These are new types appended to `eMASCecTypeOrder`, in this order, after `UtilityDtdFolderMarker`:

| EvidenceType [DES] | Subject | SourceTier | Raw Strength | SourceField | ObservedValue | CEC `Dimension` hint (P-5) | May later support (§12) |
|---|---|---|---|---|---|---|---|
| `EuEnvelopeCountry` | XmlDocument (+ SequenceId) | `StructuredXml` | **Strong** | `XmlDocuments.RegionalEnvelope.EU_ENVELOPE_COUNTRY` | token, e.g. `fr` | `Authority` | Authority (destination); Region **deferred** |
| `EuAgencyCode` | XmlDocument | `StructuredXml` | **Strong** | `…EU_AGENCY_CODE` | e.g. `FR-ANSM` | `Authority` | Authority |
| `EuProcedureType` | XmlDocument | `StructuredXml` | **Strong** | `…EU_PROCEDURE_TYPE` | e.g. `mutual-recognition` | `ProcedureContext` | ProcedureContext (if master data models authorisation procedure, P-2); Authority (`centralised` ↔ EMA) |
| `EuSubmissionType` | XmlDocument | `StructuredXml` | **Strong** | `…EU_SUBMISSION_TYPE` | e.g. `var-type1a`, `asmf` | `ProcedureContext` | ProcedureContext (`asmf`/`pmf`/`cep`: U5 open), LifecycleContext |
| `EuSubmissionUnitType` | XmlDocument | `StructuredXml` | **Strong** | `…EU_SUBMISSION_UNIT_TYPE` | e.g. `response` | `LifecycleContext` | LifecycleContext |

**Strength rationale [DES]:**
- **Why Strong:** each value is a direct, typed, DTD-enumerated, mandatory regulatory value written by the applicant in the regional backbone.
  - That is the same evidential class as the existing Strong `DtdVersion`/`XmlNamespace`.
  - It is stronger than physical paths (Supporting) or folder names (Weak).
- **What Strong does not mean:** Strong describes the *fact*, not its weight for a given dimension. For example, how strongly an agency code supports Region is an Interpretation rule decision (U2, deferred).
- **Why `StructuredXml` and not a new tier:** T4 C2 counts distinct `SourceTier` values for `INDEPENDENT_SOURCE_CLASS`. A separate tier would let the envelope corroborate the root namespace of the **same file**, inflating confidence.
- **Fields not proposed:** `mode` would be Strong too if added, but it is not proposed. Sequence and related-sequence would be `Supporting`. Free text would be `Weak` with a free-text tier.

**Invariants:**
- `CandidateValue = null`, `Polarity = null`, `SourceRuleId = null`, `CaptureStatus = Available` (records are emitted only for `ValueStatus = Known`; §11).
- `RelativePath`, `SequenceFolder` and `SequenceRelativePath` are as for the existing regional evidence.
- `SourceCapability = BackboneXmlInventory`.

**Additive record property:** `SourceOrdinal` (int, 1-based `EnvelopeOrdinal`; `null` for every historical type). It keeps multi-envelope records distinct and traceable.

**Deterministic EvidenceId:**
- New drafts use `SortGroup = 2`. Historical types use 0 and 1, so all existing `EVD-nnnn` numbers are preserved, following the T1a precedent.
- Sort key = `SortGroup, DossierPath, SequenceFolder, SequenceRelativePath, typeIndex, RelativePath, SourceOrdinal (D4)`.
- IDs continue the global `EVD-` sequence.
- Input-order independence holds because BXI orders documents ordinally and envelopes follow document order.

**Multiplicity:**
- One record per (document, envelope, field) with `Known` value. A 3-envelope MRP document yields three country, three agency, three procedure, three submission-type and three unit records.
- CEC does **not** collapse or deduplicate, because that would be interpretation.
- Different country/agency values across envelopes are legitimate. Different procedure/submission/unit values across envelopes of one document are recorded as-is; resolving them is a T4 projection concern (§11).

**Coverage:** one new `CollectionCoverage` row per (regional XmlDocument, FieldCode):
- `CheckId = RegionalEnvelopeField:<FieldCode>`, `SubjectType = XmlDocument`, `SubjectId = XmlId`.
- Existing `CaptureStatus` / `CollectionStatus` / `ReasonCode` columns.
- The rows use a new CheckId, so T4 v1 (which reads only `CheckId = ClassificationEvidenceCollection`) ignores them, and the existing repository and XmlDocument coverage rows are unchanged.

---

## 11. Missing / error / ambiguity semantics

| # | Situation | BXI `RegionalEnvelope` | CEC records | Field coverage row (`CollectionStatus` / `CaptureStatus` / `ReasonCode`) | Future T4 state |
|---|---|---|---|---|---|
| 1 | Field present, value in profile vocabulary | `Known` | 1 per envelope | `Collected` / `Available` / null | Available |
| 2 | Field absent in a parsed doc, field **optional** in profile (none of the 5 today; applies to `mode` later) | `Absent` | none | `Collected` / `Available` / null | **AssessedAbsent** (meaningful) |
| 3 | Field absent, field **mandatory** in profile (non-conformant instance) | `Absent` | none | `Collected` / `Available` / `MandatoryFieldAbsent` | AssessedAbsent (a factual absence; never a guessed value) |
| 4 | Field **not defined in profile** (`submission-unit` in 2.0) | `NotDefinedInProfile` | none | `NotAssessed` / `NotCollected` / `FieldNotDefinedInProfile` | **Unavailable**, never AssessedAbsent |
| 5 | Regional XML **missing** (SD-006) | `null` (document `Exists=false`) | none | `NotApplicable` / `InputUnavailable` / `SourceXmlMissing` | Unavailable(NotCollected), matching existing XmlDocument row semantics |
| 6 | Regional XML **parse failed** (SD-008) | `ProfileStatus = NotAttempted` | none | `NotAssessed` / `ParseFailed` / `SourceXmlParseFailed` | Unavailable(ParseFailed) |
| 7 | **Inaccessible** / read error | `NotAttempted` | none | `NotAssessed` / `AccessDenied` or `InputUnavailable` / `SourceXmlUnavailable` | Unavailable |
| 8 | **Unsupported profile** (`dtd-version` ∉ {2.0, 3.0.1, 3.1} or missing) | `UnsupportedRegionalProfile`, `Envelopes = []` | none | `NotAssessed` / `NotCollected` / `UnsupportedRegionalProfile` | Unavailable(NotCollected) |
| 9 | **Unrecognized structure** (root/ns mismatch, no `eu-envelope`, or `envelope` elements in a namespace) | `UnrecognizedRegionalStructure` | none | `NotAssessed` / `NotCollected` / `UnrecognizedRegionalStructure` | Unavailable |
| 10 | **Unknown controlled value** (not in this profile's enumeration; e.g. `maa` in a 2.0 doc, `EU-EMA` used as a country, wrong case) | `OutsideProfileVocabulary`, raw `Value` kept | **none** (no Strong record for an unverified token) | `NotAssessed` / `Available` / `ValueOutsideProfileVocabulary` | Unavailable(**UnrecognizedValue**, new reason, P-7) |
| 11 | **Multiple values where cardinality is 1** inside one envelope (e.g. two `agency` children) | `MultipleValues`, `Values[]` | none | `NotAssessed` / `Available` / `CardinalityViolation` | Unavailable(AmbiguousProjection) |
| 12 | **Multiple envelopes** (legitimate) | n envelopes | n records | `Collected` | Set-valued; needs projection v2 (P-7) |
| 13 | **Conflicting values across envelopes** of one document (e.g. two submission types) | each recorded | n records | `Collected` / `Available` / `EnvelopeValuesDiffer` (informational) | Projection v2 decides; v1 rule would be `AmbiguousProjection` |
| 14 | **Conflicting values across lifecycle units** (procedure `national` → `mutual-recognition`) | per document | per sequence | per document | Per-sequence results; dossier aggregation remains T4 D-1 |

**Reason codes:**
- Reused: `SourceXmlMissing`, `SourceXmlParseFailed`, `SourceXmlUnavailable`.
- New: `MandatoryFieldAbsent`, `FieldNotDefinedInProfile`, `UnsupportedRegionalProfile`, `UnrecognizedRegionalStructure`, `ValueOutsideProfileVocabulary`, `CardinalityViolation`, `EnvelopeValuesDiffer`.
- No guessed or normalized value is ever produced.

**Note on rows 3 and 10:** the official v3.1 narrative (S5 p.10) says the Centralised Procedure envelope country should be "set to 'EU-EMA'". The DTD enumeration and the Appendix 1.1 table allow only `ema`, and `EU-EMA` is an **agency** code. The design follows the DTD, so a literal `EU-EMA` country is `OutsideProfileVocabulary`. This inconsistency is recorded for SME confirmation (S-3).

---

## 12. Evidence-to-identification applicability matrix (design guidance only; non-executable)

Legend:
- ● direct factual support is plausible;
- ◐ only through governed relationships, or only partially;
- ○ not applicable;
- **D** deferred / blocked by an open decision.

| Evidence | Region | Authority | RegionalImplementation | TechnicalStandard | ProcedureContext | LifecycleContext | ProductDomain | ProductClass |
|---|---|---|---|---|---|---|---|---|
| Regional `XmlRootElement`/`XmlNamespace` *(existing)* | D (U2) | ○ | ● | ○ | ○ | ○ | ○ | ○ |
| Regional `DtdVersion` *(existing)* | ○ | ○ | ● (profile generation) | ○ | ○ | ○ | ○ | ○ |
| `EuEnvelopeCountry` | **D** (U2, U3 IS/LI/NO, U4 `uk`/`xi`) | ● (destination) | ◐ | ○ | ○ | ○ | ○ | ○ |
| `EuAgencyCode` | **D** (relationship-derived; T4 B-7) | ● | ◐ | ○ | ◐ (`EU-EDQM` ↔ CEP: U5) | ○ | **D** (U8: H/V agencies) | ○ |
| `EuProcedureType` | ○ | ◐ (`centralised` ↔ EMA) | ○ | ○ | ◐ (P-2: authorisation procedure vs ProcedureContext) | ○ | ○ | ○ |
| `EuSubmissionType` | ○ | ○ | ○ | **○ — ASMF/DMF are never TechnicalStandard** | ◐ (`asmf`/`pmf`/`cep`: **U5**) | ● | ○ | ○ |
| `EuSubmissionUnitType` | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ |

Guardrails:
- **Region vs RegionalImplementation:** these stay distinct. No EU evidence type asserts `EU` as a Region.
- **Region inference:** relationship-derived Region stays deferred (T4 D-2 / B-7).
- **v4 evidence:** physical v4 evidence is unrelated to this EU v3 task.

---

## 13. Future fixture / test matrix

**Fixture strategy:**
- Reuse the frozen SD fixtures, read-only, for real official-DTD instances.
- Add **synthetic minimal** regional XMLs authored from the S2/S3/S5 declarations. These are new, small, contain no customer names, and live under a new `tests/fixtures/regional-xml-evidence/` folder in the implementation task.
- No frozen bytes are modified.

| # | Case | Fixture | Expected |
|---|---|---|---|
| 1 | Clean typed field (3.1, 2 envelopes) | SD-002 seq 0004 | 5 types × 2 envelopes; `Known`; Strong/StructuredXml; `SourceOrdinal` 1, 2 |
| 2 | Older profile (2.0); `tracking` not `procedure-tracking`; no unit | SD-002 seq 0000 | 4 types; unit row `FieldNotDefinedInProfile` |
| 3 | Field absent, parse OK. All five first-wave fields are mandatory, so this is a synthetic 3.1 doc without `submission-unit` | synthetic | `Absent`; row `Collected`/`MandatoryFieldAbsent`; no record, no guessed value. The *optional*-field variant (§11 row 2) is added with `mode` in wave 2 |
| 4 | Malformed regional XML | SD-008 seq 0004 | `NotAttempted`; rows `NotAssessed`/`ParseFailed` |
| 5 | Regional XML missing | SD-006 seq 0004 | Property null; rows `NotApplicable`/`SourceXmlMissing` |
| 6 | Unsupported profile (`dtd-version="1.4"`, `"3.0"`, absent) | synthetic | `UnsupportedRegionalProfile`; no records |
| 7 | Unknown controlled value (`maa` in a 2.0 doc; `EU-EMA` as a country; `fr-ansm` lower case) | synthetic | `OutsideProfileVocabulary`; raw value kept in BXI; no CEC record |
| 8 | Duplicate element (two `agency`) | synthetic | `MultipleValues`; `CardinalityViolation` |
| 9 | Conflicting typed values across lifecycle units | SD-002 0000 (`national`) vs 0002 (`mutual-recognition`) | Both facts kept per sequence |
| 10 | Prefix change (`x:eu-backbone xmlns:x="http://europa.eu.int"`) | synthetic | Identical facts to the `eu:` version |
| 10b | Envelope in a default namespace | synthetic | `UnrecognizedRegionalStructure` |
| 11 | Free text not collected | any | No record has `applicant`/`invented-name`/`inn`/`submission-description` values; no Strong record from free text |
| 12 | Interpretation fields null | all | `CandidateValue`/`Polarity`/`SourceRuleId` null on every new record |
| 13 | Deterministic IDs and order | SD-002 + shuffled synthetic | Every historical EvidenceId (Wave 1 + T1a physical-marker records) is byte-identical to the current expectations; new IDs follow the existing maximum; repeat runs and shuffled input are identical |
| 14 | No XML reopen in CEC | Mocked BXI result with `RegionalEnvelope` but no source on disk | CEC succeeds; static check that the CEC module has no XML reader calls |
| 15 | T4 short pipeline still valid | entry script with `-IncludeIdentificationInterpretation` | T4 focused tests 28/28 and oracle 23/23 unchanged; new types ignored by projection v1 |
| 16 | Vocabulary renames (`AT-AGES` in 2.0 is `Known`; `AT-AGES` in 3.1 is `OutsideProfileVocabulary`) | synthetic | per-profile checks |
| 17 | PS5.1 parity | CI windows-powershell-51 lane | identical JSON to PS7.6 |

**Expectation-file impact:** `tests/fixtures/{backbone-xml-inventory,classification-evidence-collection,dossier-diversity,…}/*expectations.json` must be regenerated. Per EU regional document the counts grow by 5 × envelopes (4 × for 2.0) records plus 5 coverage rows. Historical IDs are unchanged.

---

## 14. Implementation file impact (for the follow-up task)

| File | Change |
|---|---|
| `engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1` | **New:** profile table, vocabulary `EU-M1-ENVELOPE-VOCABULARY/1`, selector walk, status codes |
| `engine/powershell51/eMAS.BackboneXmlInventory.psm1` | Dot-source the helper; add `RegionalEnvelope` per XmlDocument; `ScannerVersion` 0.3.0. **RC1-frozen file** (P-1) |
| `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1` | 5 types, `SortGroup = 2`, `SourceOrdinal`, field coverage rows |
| `tests/backbone-xml-inventory/**`, `tests/classification-evidence-collection/**`, new `tests/regional-xml-evidence/**` | Tests per §13 |
| `tests/fixtures/*/…expectations.json` | Regenerated counts and new records |
| `tests/fixtures/regional-xml-evidence/**` | New synthetic XMLs |
| `.gitattributes` / RC1 package manifest | Only if the PO approves re-qualification |
| **Not changed** | RepositoryDiscovery, IdentificationInterpretation, T4 oracle/contract, runtime schema/workbook, Pre-Sales script |

---

## 15. Explicit non-goals

- No code, fixture, test, schema, workbook or contract change in this task.
- No Region/RegionalImplementation/ProcedureContext/LifecycleContext conclusion in scanner or CEC.
- No Effective Identification rules; no resolution of T3c **U2–U9**.
- No `CEC-FIELD-PROJECTION/2` / T4 change (a separate task).
- No v4 `submissionunit.xml` (T2); no US/FDA, Canada, UK, Swiss or GCC normative mappings.
- No DTD validation, no tracking-number pattern inference, no UUID application identity.
- No `m1-eu` leaf metadata, applicant, product names or descriptions.
- No EU M1 v1.4.x or v3.0 profile support until officially verified (P-4).

**Extension pattern for other regions [DES]:** one private helper per regional profile family, dispatched on (root namespace URI, root local-name, version attribute). Each helper has:
- its own versioned vocabulary table;
- its own official source ledger;
- an `XmlKind`/path decision made in RD/BXI, not CEC.

Each region needs its own source-verified design task.

---

## 16. Open Regulatory SME / Product Owner decisions

| ID | Decision | Owner |
|---|---|---|
| P-1 | Approve modifying RC1-frozen `eMAS.BackboneXmlInventory.psm1` (Option A) with RC1 re-qualification, or accept Option B's duplicate parse | PO + Technical Architect |
| P-2 | Does the authorisation procedure (`centralised`/`national`/`mutual-recognition`/`decentralised`) belong in `ProcedureContext` master data, or in a separate dimension/attribute? | Regulatory SME + PO |
| P-3 | Cross-version alias policy for raw submission types (e.g. 2.0 `initial-maa` ~ 3.x `maa`): master-data aliases, not scanner logic | Regulatory SME + PO |
| P-4 | Verify and support EU M1 v1.4/1.4.1 and v3.0 (`dtd-version` values not in the corpus) in a later wave? | PO |
| P-5 | Extend the CEC `Dimension` hint vocabulary with `Authority`, `ProcedureContext`, `LifecycleContext` (today: Region, TechnicalFormat, SpecificationProfile, DossierContext) | PO + Technical Architect |
| P-6 | Is the envelope UUID (`identifier`, 3.x) wanted as an application-grouping fact, given RD has no application identity? | PO |
| P-7 | Commission `CEC-FIELD-PROJECTION/2` (T4a contract revision): set-valued envelope fields, per-field coverage, new reason `UnrecognizedValue` | PO + central review |
| S-1 (U2) | Confidence limit for Region derived from agency/country | Regulatory SME + PO |
| S-2 (U3/U4) | IS/LI/NO, `uk` vs `xi` (UK(NI)) mapping to Region | Regulatory SME (EU/UK) + PO |
| S-3 | Confirm `ema` (DTD) vs "EU-EMA" (S5 p.10 narrative) for the CP envelope country | Regulatory SME |
| S-4 (U5) | ProcedureContext treatment of `asmf`, `pmf`, `cep` (EDQM) | Regulatory SME + PO |
| S-5 (U8) | ProductDomain from H/V agencies | Regulatory SME + PO |

---

## 17. Recommended bounded T1b implementation task

**`EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`** (single worker, after P-1 and P-5 are decided)

1. **Implement the helper and the BXI change** for profiles 2.0 / 3.0.1 / 3.1:
   - add `eMAS.EuRegionalEnvelope.ps1`;
   - add the BXI `RegionalEnvelope` property with the five first-wave fields;
   - apply the status semantics of §11.
2. **Extend CEC** with the 5 Strong/StructuredXml types, `SortGroup = 2`, `SourceOrdinal` and the per-field coverage rows. CEC still never reopens XML.
3. **Tests and fixtures:**
   - tests per §13;
   - new synthetic fixtures;
   - regenerated expectation files;
   - historical EvidenceIds proven unchanged.
4. **Regression:**
   - Wave 1 chain;
   - Wave1D (where the corpus is available);
   - the T4 engine (28/28) and oracle (23/23), proving zero T4 impact;
   - PS5.1 / PS7.6 / macOS CI.
5. **Out of scope:** T4 projection v2, Effective rules, other regions, `mode` / sequence / related-sequence / UUID (wave 2).

Size: one new private helper (~250 lines), about 40 lines in BXI, about 60 lines in CEC, plus tests and fixtures. That is bounded for one task.
