# Claude Report — T2 SubmissionUnit XML Inventory Design (eCTD v4.0)

**Status:** `DESIGN_COMPLETE — READY_FOR_FIXED_SHA_CENTRAL_REVIEW`
**Task:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY` (Roadmap T2). Research and design only; no implementation.
**Worker branch:** `analysis/emas-ms04-ectd4-submissionunit-xml-inventory-design`
**Authoritative base:** `09c6e3bbb37f9811e045214cfb6b9bb575ce669e`
**Coordination parent (verified at launch):** `3e113663c2ffa1e51f6c0c4a9a5c4254d0ee7053`

**Launch checks, recorded before writing:**

| Check | Result |
|---|---|
| `git rev-parse HEAD` | `3e113663c2ffa1e51f6c0c4a9a5c4254d0ee7053` |
| `git merge-base HEAD origin/coordination/emas-ms04-ectd4-submissionunit-xml-inventory` | `3e113663c2ffa1e51f6c0c4a9a5c4254d0ee7053` |
| `git status --short` | clean |
| Base `09c6e3bb` is an ancestor of HEAD | yes |

**Scope of changes:**
- This report and `STATUS.md` are the only repository changes.
- No engine, script, test, fixture, schema, configuration, T4, projection, rule-pack, workbook, reporting or UI file was touched.
- Official artefacts were read in scratch storage outside the repository. Nothing official is committed.

**Labels used in this report:**

| Label | Meaning |
|---|---|
| **[REG]** | Authoritative regulatory fact from a cited official source |
| **[OBS]** | Observation of accepted repository behaviour (implementation evidence, not authority) |
| **[DES]** | eMAS design proposal |
| **[CONFLICT]** | Official sources disagree; both are recorded and the conflict is not reconciled |
| **[GAP]** | An official source exists but could not be inspected; no rule is derived from it |

---

## 1. Executive recommendation

1. **Build a separate, optional `SubmissionUnitXmlInventory` (SUXI) capability.** This confirms the task's default direction.
   - It runs after RepositoryDiscovery (RD) and BackboneXmlInventory (BXI), and before CEC.
   - It parses each `submissionunit.xml` that RD has already placed in a v4 submission-unit folder, exactly once, with the existing safe reader (`private/eMAS.SafeXml.ps1`).
   - It never resolves DTDs, schemas, `xsi:schemaLocation` or the network.
   - BXI stays byte-unchanged. [OBS] BXI never parses `submissionunit.xml` today: it only inventories exact v3 sequences and dossier-root XML, and v4 units are deliberately non-exact (accepted v4-discovery amendment 1). So there is no duplicate parse.
2. **Contract:** `eMAS.MS04.PreSales.ScannerObservations/1.0` stays at 1.0. The change is additive:
   - a new top-level collection `SubmissionUnitXmlDocuments`;
   - new coverage rows;
   - a new capability token `SubmissionUnitXmlInventory`.

   No existing member, record or `XmlDocuments` shape changes.
3. **Facts collected (inventory):**
   - message root and namespace;
   - the two kinds of header implementation-guide markers (ICH IG OID and regional IG OID);
   - `submissionUnit` id and code;
   - per-submission sequence number, id items and code;
   - per-application id items and code.

   Every code keeps `code` and `codeSystem` as separate fields and is checked only against embedded, versioned official code lists.
   - Free text, personal data, product names, Context-of-Use and document lifecycle are **not** collected in the first wave.
4. **CEC: 8 new factual evidence types**, published only from the inventory. CEC never reopens XML:
   - message root element and namespace;
   - recognised IG OID;
   - submission-unit type code, submission type code, application type code;
   - recognised application-id namespace OID;
   - sequence number.

   The first seven are raw `Strong`; the sequence number is `Supporting`. All are `StructuredXml`.
5. **T4 and CEC-FIELD-PROJECTION stay unchanged, and there is no prerequisite.** I verified the three T4 v1 entry points that could be affected; all three are safe by design (§14). All projection and rule use is deferred to a later governed `CEC-FIELD-PROJECTION/2` / T4a task.
6. **Profile identity uses only officially registered IG OIDs** from the ICH, FDA and EU controlled-vocabulary packages.
   - `identifierName`, `xsi:schemaLocation` and the header `id`, `creationTime` and `interactionId` are never profile markers. ICH excludes them or says the Regulatory Authority will not use them.
   - Unknown or unverified OIDs are recorded verbatim, never mapped.
   - Seven official-source conflicts are recorded (§17). None blocks bounded collection.

---

## 2. Source basis and precedence

| Rank | Basis | Used for |
|---|---|---|
| 1 | Effective eMAS requirements and accepted repository decisions (v4 discovery review, T1b C-1…C-7, T4 contract) | Boundaries, fact/interpretation split, CEC conventions |
| 2 | ICH eCTD v4.0 IG v1.7, its XML schema files and CV package v1.0.3 (CV v7) | Message structure, header markers, cardinality, IG-version OIDs, validation-rule identifiers |
| 3 | Regional official guides, CVs and validation criteria (FDA M1 IG v1.9, FDA CV v1.0/v1.1/v1.2, FDA VC v1.6; EU M1 IG draft v1.2, EU CV v3, EU VC v1.1) | Regional OIDs, code systems, regional constraints |
| 4 | Accepted repository behaviour (RD, BXI, CEC, T4 code; Wave 1E fixtures) | Implementation evidence only |
| 5 | Secondary or vendor material | **Not used** |

**Precedence rules:**
- Where a regional guide narrows ICH (for example, FDA application `id.item` [1..1] versus ICH [1..*]), SUXI records what the XML says. It never enforces either cardinality as a rejection; the gap is recorded as a coverage fact.
- Where an official XML **sample** contradicts an official **CV/table**, the CV/table wins for recognition tables and the sample is recorded as [CONFLICT]. ICH IG §6.6 and the EU IG reader notice both say samples are illustrative.

---

## 3. Official source ledger

All sources were accessed **2026-10-07**. The three landing pages were re-verified live on that date:
- ICH eCTD v4.0 page: `https://admin.ich.org/page/ich-electronic-common-technical-document-ectd-v40`
- FDA eCTD v4.0 and Regional M1 standards page (shows "Content current as of 09/29/2026"): `https://www.fda.gov/drugs/electronic-regulatory-submission-and-review/ectd-submission-standards-ectd-v40-and-regional-m1`
- EMA eSubmission eCTD v4 page: `https://esubmission.ema.europa.eu/eCTD%20NMV/eCTD.html`

SHA-256 values identify the exact files read.

| ID | Authority | Exact title / artefact | Version, date | Status (live, 2026-10-07) | Direct artefact | SHA-256 |
|---|---|---|---|---|---|---|
| I1 | ICH M8 | *ICH eCTD v4.0 Implementation Guide* (`ICH_eCTDv4_0_ImplementationGuide_v1_7.pdf` in the IG package zip) | v1.7, revision 5 May 2026, endorsed June 2026 | **Current (ICH)** | `/sites/default/files/inline-files/eCTD_v4.0_Implementation_Guide_v1.7_0.zip` | zip `37c35e3b…9e13f` |
| I2 | ICH M8 | ICH eCTD v4 schema files, same package: `PORP_IN000001UV.xsd`, `PORP_MT000001UV01.xsd`, `MCCI_MT000100UV02.xsd`, `MCAI_MT700201UV02.xsd`, `coreschemas/hl7-r2_datatypes.xsd` | package v1.7 | Current | as I1 | `a43055e6…3fe517` / `769f762c…409cc` / `863a23d5…0592` / `56cc8153…e00148` |
| I3 | ICH M8 | *ICH Code List for eCTD v4.0* (`ICH_eCTDv4_0_CV_v7.xlsx`), CV package v1.0.3 | CV v7, 2026-05 | **Current** | `/sites/default/files/inline-files/eCTD_v4.0_CV_Package_v1.0.3_0.zip` | zip `bdc39e67…796f44` |
| I4 | ICH M8 | *eCTD v4.0 Q&A and CR Document* | v1.10, June 2026 | Current (context only) | ICH page | `45774d0a…5781` |
| F1 | FDA (CDER/CBER) | *FDA Module 1 eCTD v4.0 Implementation Guide* | v1.9, August 2026; support begins 2026-09-28 | **Current** | `fda.gov/media/194432` | `d3b9b7bf…3a712` |
| F1b | FDA | Same title | v1.8, October 2025; support begins 2025-10-20 | **Still listed as supported** | `fda.gov/media/179721` | `c66d68f0…8dc0` |
| F2 | FDA | *FDA Regional CV eCTD v4.0 Package* (`USFDA_Regional_CV_eCTD_4_v1_7_202608.xlsx` + ReadMe) | v1.2, 2026-08; support begins 2026-09-28 | Current | `fda.gov/media/194431` | `ac2d32e3…3472` |
| F2b | FDA | Same, `…_v1_6_1_202606.xlsx` | v1.1, 2026-06; support begins 2026-07-09 | Supported | `fda.gov/media/193527` | `2198d21b…06ab` |
| F2c | FDA | Same, `…_v1_6_202503.xlsx` | v1.0, 2025-03; support begins 2025-03-31 | Supported | `fda.gov/media/179730` | `a2467820…53a6` |
| F3 | FDA | *Specifications for eCTD v4.0 Validation Criteria* | v1.6, 2026-08; support begins 2026-08-28 | Current | `fda.gov/media/194434` | `d3768a7d…9721` |
| F4 | FDA | Supported ICH IG package as listed by FDA | ICH IG package **v1.6** (2/18/2025) and legacy v1.5 (9/16/2024) | FDA-supported ICH versions | `fda.gov/media/193873`, `/180829` | **[GAP]** automated download refused |
| F5 | FDA | *FDA Regional eCTD v4.0 Module 1 Implementation Package* | v1.5.1; supported 9/16/2024 – **9/28/2027** | Supported, ending | `fda.gov/media/91610` | **[GAP]** automated download refused |
| F6 | FDA | *FDA Regional Module 1 XML Samples* v3.0; *Forward Compatibility XML Samples* v1.0 | — | Supportive examples | `fda.gov/media/179729`, `/193528` | **[GAP]** over 10 MB, automated download refused |
| E1 | EMA / EU | *eCTD v4.0 EU Module 1 Implementation Guide* ("DRAFT for Updates 2024"), header OID `2.16.840.1.113883.3.989.5.1.1.6.1.2` | **draft** v1.2, 4 October 2024 | **Current EU IG, still DRAFT** | `eCTD%20NMV/docs/eCTD%20v4.0%20EU%20IG%202024%20draft_1.2.docx` | `f4f2e483…851e` |
| E2 | EMA / EU | *EU eCTD v4.0 – Controlled Vocabularies* (Excel) | **v3, November 2025** | Final | `eCTD%20NMV/docs/EU%20eCTD%20v4.0%20-%20Controlled%20Vocabularies%20v3.xlsx` | `f4e3ff1d…c212` |
| E3 | EMA / EU | *Validation Criteria EU eCTD 4.0* | v1.1, March 2026 (applicable from 15 July 2026) | Final | `eumodule1/docs/Validation%20Criteria%20EU%20eCTD%204.0%20v1.1.xlsx` | `833c3780…ef214` |
| E4 | EMA / EU | *EU eCTD v4.0 Practical Guidance* | v1, December 2025 | Final (recommended practice) | `eCTD%20NMV/docs/EU%20eCTD%20v4.0%20Practical%20Guidance%20v1.pdf` | `b45bab3b…db12` |

**EU timeline [REG, EMA page]:**
- eCTD v4 is optional for new CAP MAAs from 22 December 2025.
- Use is strongly recommended from Q1 2027 and mandatory from Q1 2028.

**FDA tool [REG, FDA page]:** Lorenz eValidator 25.2 has been active since 8/25/2026. Context only.

**Gaps:**
- **[GAP] F4–F6.** fda.gov refused scripted downloads (HTTP "Not found" to non-browser clients); the sample packages also exceed the fetch-tool size limit. No rule in this report depends on them.
- **Effect of the gaps:** without F5, the FDA v1.5.1 package's regional IG OID is unknown, and without F6 no official grouped-submission example was inspected (§17, R-1).
- **Remedy:** before the implementation task is authorised, a reviewer with browser access should download F4–F6 and confirm the FDA v1.5.1 IG OID (decision D-3).

### 3.1 Clause ledger (normative facts used)

ICH I1 printed page = PDF page − 15. FDA F1 printed page = PDF page − 10. EU E1 is a .docx with no fixed pagination, so E1 is cited by section and the document's own table-of-contents page.

| # | Source / location | Fact derived | Scope | Confidence |
|---|---|---|---|---|
| L1 | I1 §9.1, Table 10 p.30–31; §9.1.2 p.31 | Root `PORP_IN000001UV`; `ITSVersion` must be `"XML_1.0"`; `xmlns` must be `"urn:hl7-org:v3"`; `xsi:schemaLocation` "must reference … PORP_IN000001UV.xsd" | ICH | High |
| L2 | I2 `PORP_IN000001UV.xsd` (element `PORP_IN000001UV`, type `…MCCI_MT000100UV02.Message`) | `receiver` 1..unbounded; `sender` 1..1; `controlActProcess` 1..1; `controlActProcess/subject` 0..unbounded with `submissionUnit` 1..1 | ICH schema | High |
| L3 | I1 §9.1.2 p.31; §9.1.2.1 p.32 | `receiver/device/id/item@root` "should indicate the OID of the ICH eCTD v4.0 IG or the Regional/Module 1 IG used"; `@identifierName` is the version name and "will not be used by the Regulatory Authority". Two `item`s: ICH IG OID and regional IG OID | ICH | High |
| L4 | I1 §4.7.2 p.12 | Header `id`, `creationTime`, `interactionId`, `processingCode`, `processingModeCode`, `acceptAckCode` and `sender.device.id` are **ICH-excluded**: self-closing, no values, ignored by the receiver | ICH | High |
| L5 | I1 §12, eCTD4-084 p.124; revision history p.ii (CR 00770, IG v1.7) | "Message Header requires both valid ICH and Regional IG OID values." **New in IG v1.7** | ICH v1.7 | High |
| L6 | I3 Index rows "ICH eCTD v4.0 IG Version" | IG-version OIDs: `2.16.840.1.113883.3.989.2.2.1.11.1` (IG 1.0), `.11.2` (1.3), `.11.3` (1.4, start 2021-06), `.11.4` (1.5, 2022-05), `.11.5` (1.6, 2024-05), `.11.6` ("Current version", 2026-05, note "IG version 1.7"). No end dates are listed | ICH | High |
| L7 | I1 §4.5.1 p.10; §6.6.1 p.21–22, Table 6 | ICH code-list OIDs are `2.16.840.1.113883.3.989.2.2.1.x.y`, where x = code system and **y = code-system version**. A valid list has no end date; codes from a newer version may not be sent with an older version's OID | ICH | High |
| L8 | I1 §9.2.4 p.40–44; I2 `PORP_MT000001UV01.SubmissionUnit` | Location `controlActProcess/subject/submissionUnit`; one per message. `id@root` [1..1], a UUID; `code@code` [1..1] text with `code@codeSystem` [1..1] OID (regional CV); `title@value` [0..1] free text; `statusCode@code` [0..1] `active`. Schema: `code` 0..1, `componentOf1` 1..unbounded, `componentOf2` 0..unbounded | ICH | High |
| L9 | I1 §9.2.4.2 p.41–42; §9.2.14.2 p.73–74 | `code.displayName`, `code.originalText`, `code@codeSystemName` and `code@codeSystemVersion` are listed as "may not be required" | ICH | High |
| L10 | I1 §9.2.12 p.68–69; I2 `Component1` | `componentOf1/sequenceNumber@value` [1..1] per IG (schema 0..1); a positive integer starting at "1", not above "999999"; unique within an Application; no CV | ICH | High |
| L11 | I1 §12 eCTD4-012…016 p.113–114 | Sequence number required, whole number 1–999999, initial = "1", unique in the application, "one and only one value for the Submission element" | ICH | High |
| L12 | I1 Table 11 p.36–39; I2 `Submission`, `Component5` | `submission/id` (DSET_II) 1..1; `submission/code` 1..1; `submission/componentOf` 1..unbounded, each with one `application` | ICH | High |
| L13 | I1 §12 eCTD4-033…037 p.118 | Submission id root required and a UUID (eCTD4-077); submission code and code system required; code system must be a valid **regional** OID | ICH | High |
| L14 | I1 §9.2.14 p.71–74; eCTD4-038…042 p.118–119 | `application/id/item` [1..*], with `@root` [1..1] OID or UUID and `@extension` [0..1] regional tracking number; `application/code` [1..1] regional CV; "The concept of application element differs among regions" | ICH | High |
| L15 | I1 §4.7.1 p.11 | Region-specific elements: application `reviewProcedure`, `applicationReference`, `holder.applicant`, `informationRecipient.territorialAuthority`; submission `review`, `mode`, `regulatoryReviewTime`, `submissionGroup`; `categoryEvent` | ICH → regional | High |
| L16 | I1 §4.8 "Excluded Business Processes" p.12 | Dossier management, submission lifecycle and grouped submissions are **regional business processes**, not ICH | ICH | High |
| L17 | I1 §12 eCTD4-001/002 p.112 | Regulators validate well-formedness and the ICH RPS schema | ICH | High |
| L18 | F1 §3.6 p.3 | FDA code-list root `2.16.840.1.113883.3.989.5.1.2.2.1`; Application Id OIDs CBER `…5.1.2.2.1.15.1`, CDER `…16.1`, CDRH `…17.1` (CDRH only for `applicationReference`) | FDA | High |
| L19 | F1 §8.1 p.12–13 | "The FDA Module 1 IG OID is required in the Message Header. If … not present, the submission unit will be rejected" | FDA | High |
| L20 | F2 / F2b / F2c Index | FDA IG-version OID: `…5.1.2.2.1.18.9` = "Document version 1.9" (CV 1.2); `.18.8` = 1.8 (CV 1.1); `.18.7` = 1.7 (CV 1.0). Code systems: application type `…1.1.4`, submission type `…12.5`, submission-unit type `…13.2` (unchanged across CV 1.0–1.2) | FDA | High |
| L21 | F1 §8.2.8 p.24–27 | `submission/id/item@root` UUID or OID; `@extension` = first sequence of the regulatory activity. A new activity has one UUID item. For an open v3.2.2 activity, two items: UUID plus Center OID with the v3 sequence (e.g. `"0010"`). Multiple submissions only in grouped submissions | FDA | High |
| L22 | F1 §8.2.10 p.37–40 | FDA constraint: application `id.item` [1..1], root = Center OID, extension = 6-digit application number; one application per submission; application code from FDA CV | FDA | High |
| L23 | F1 §8.3 p.45–46 | Grouped submission = one submission unit with more than one `componentOf1/submission`; each submission has its own sequence number for its application; all content goes under one application element | FDA | High |
| L24 | F1 §8.2.8.4 p.26; §8.2.10.4 p.40 | FDA ignores `submissionGroup`, `mode`, `review`, `regulatoryStatus`, application `informationRecipient.territorialAuthority` and `reviewProcedure` | FDA | High |
| L25 | F3 `US-eCTD4-558` p.17 (effective 02/18/2025); `eCTD4-084` p.58 (effective **TBD** at FDA); `US-eCTD4-503`/`504` p.23 | US regional IG OID required; sequence number must match the folder name; more than one sequence number for the same application number is an error | FDA | High |
| L26 | E1 §6 (TOC p.17) | EU root OID `2.16.840.1.113883.3.989.5.1.1`; EU M1 IG OID `…5.1.1.6.1.2` (IG v1.2); EU CV OID `…5.1.1.6.2.1` (CV v1.0). Change history: IG v1.0 assigned `…5.1.1.6.1.1` | EU (draft) | High (text), draft |
| L27 | E2 Index | EU IG OIDs `…5.1.1.6.1.2` (package Oct 2024) and **`…6.1.3` (package Aug 2025, "New version")**. Code systems on the EMA SPOR root `2.16.840.1.113883.3.6905`: submission-unit type `.1.8.1`; application submission type `.1.11.1` / `.1.11.2`; application legal basis `.1.4.1`; territorial authority `.1.12.1` | EU | High |
| L28 | E1 §9.10 (TOC p.37) | EU `submission/id/item` [1..1], root OID or UUID, extension = EU procedure number for the activity, same for all units of that activity; `submission/code` **[0..1]**, code system `…6905.1.11.x` | EU (draft) | Medium (draft; see C-4) |
| L29 | E1 §9.18 (TOC p.64) | EU `application/id/item` root UUID, extension procedure number; `application/code` = **legal basis** (`…6905.1.4.1`, e.g. `100000116047`) | EU (draft) | Medium |
| L30 | E1 §6, Note; §8 Note | EU: "any displayName value will be ignored"; code and codeSystem are validated, the display name is not | EU | High |
| L31 | E3 `eCTD4-EU-065`, `-072` | EU: the sequence folder must match the sequence number for single-sequence XMLs; UUIDs must be well formed | EU | High |

---

## 4. Version / profile compatibility matrix

**Recognition** means only that an OID equals a value in an embedded official table. It never means "valid", "supported by eMAS" or "submission is correct".

| Marker / version | Official identifier | Source | Source status | Proposed SUXI recognition |
|---|---|---|---|---|
| ICH IG v1.0 | `2.16.840.1.113883.3.989.2.2.1.11.1` | I3 | Historical; no ICH end date | `RecognizedIchIg` |
| ICH IG v1.3 | `…11.2` | I3 | Historical | `RecognizedIchIg` |
| ICH IG v1.4 | `…11.3` | I3 | Historical | `RecognizedIchIg` |
| ICH IG v1.5 | `…11.4` | I3 | Historical; FDA "legacy" package | `RecognizedIchIg` |
| ICH IG v1.6 | `…11.5` | I3 | Historical at ICH; **FDA-supported ICH package** | `RecognizedIchIg` |
| ICH IG v1.7 | `…11.6` | I3 | **Current ICH** | `RecognizedIchIg` |
| FDA M1 IG v1.9 | `2.16.840.1.113883.3.989.5.1.2.2.1.18.9` | F2 | Current (from 2026-09-28) | `RecognizedRegionalIg` (FDA) |
| FDA M1 IG v1.8 | `…18.8` | F2b | Supported | `RecognizedRegionalIg` (FDA) |
| FDA M1 IG v1.7 | `…18.7` | F2c | In a still-listed CV package; IG v1.7 itself not on the page | `RecognizedRegionalIg` (FDA), source status `Historical` |
| FDA `…18.6` | appears **only** in the F1 §8.1.2 sample, labelled "FDA eCTD v4.0 IG v1.5" | F1 sample | **UNVERIFIED** (no CV row) | `UnknownOid`, **DO_NOT_IMPLEMENT as known** (C-2) |
| FDA M1 package v1.5.1 | unknown | F5 [GAP] | Supported until 2027-09-28 | `UnknownOid` until D-3 |
| EU M1 IG v1.0 | `2.16.840.1.113883.3.989.5.1.1.6.1.1` | E1 change history | Historical | `RecognizedRegionalIg` (EU), source status `Historical` |
| EU M1 IG v1.2 | `…6.1.2` | E1, E2 | **Draft** IG | `RecognizedRegionalIg` (EU), source status **`Draft`** |
| EU `…6.1.3` | E2 Index "New version", August 2025 | E2 | No published IG document | `RecognizedRegionalIg` (EU), source status **`RegisteredWithoutPublishedGuide`** (C-3) |
| Any other OID, including ones under the ICH, FDA or EU arcs | — | — | — | `UnknownOid`, recorded verbatim; **no prefix-based inference** |

**Code systems relevant to first-wave codes** (exact OIDs, versions never merged):

| List | ICH | FDA (F2, F2b, F2c) | EU (E2) |
|---|---|---|---|
| Submission-unit type (`submissionUnit/code`) | regional | `…5.1.2.2.1.13.2` | `…6905.1.8.1` |
| Submission type (`submission/code`) | regional | `…5.1.2.2.1.12.5` | `…6905.1.11.1`, `…6905.1.11.2` |
| Application type (`application/code`) | regional | `…5.1.2.2.1.1.4` | `…6905.1.4.1` (legal basis) |
| Application id namespace (`application/id/item@root`) | OID or UUID | CBER `…15.1`, CDER `…16.1` (CDRH `…17.1` only on `applicationReference`) | UUID (no namespace OID) |

**Version rules [DES]:**
- Each code-system OID version (e.g. EU `.1.11.1` versus `.1.11.2`) is a separate table entry. A code is `Known` only within the version its OID names, following the L7 rule.
- No alias or "newer equals older" normalisation.
- Code values in the embedded tables are copied from the cited official lists, with list name, OID and source file hash recorded per table: `ECTD4-SUXI-VOCABULARY/1`.

**Determining a profile from the document alone:**
- The document alone can say: "the message declares ICH IG OID X and regional IG OID Y, both registered in official list Z".
- It **cannot** say that the message conforms to that profile. Schema validation and business rules are out of scope (§8, row S-14), and `identifierName` is non-authoritative.
- So recognition confidence is limited to "declared and registered". No regulatory interpretation is made.

---

## 5. Namespace-aware XML structure map

**Namespaces:**
- `urn:hl7-org:v3` is the HL7 v3 default namespace (`{v3}` below) [REG L1].
- `http://www.w3.org/2001/XMLSchema-instance` is `{xsi}`.

**Selector rules [DES]:**
- Select by namespace URI plus local name only, walking element children (as T1b does). Prefixes are never used.
- Attributes are unqualified, apart from `xsi:*`.

**Path notation:** `/` is a child step. `[n]` is the 1-based document-order ordinal that SUXI records.

| Ref | Selector (from document root) | Kind | Card. (IG / schema) | Datatype | Source |
|---|---|---|---|---|---|
| X1 | `{v3}PORP_IN000001UV` | root element | 1 | — | L1 |
| X2 | `X1/@ITSVersion` | attr | 1 (must be `XML_1.0`) | token | L1 |
| X3 | `X1/@{xsi}schemaLocation` | attr | IG "must"; **never resolved** | string | L1 |
| X4 | `X1/{v3}receiver[r]` | element | 1..* (schema) | — | L2 |
| X5 | `X4/{v3}device/{v3}id/{v3}item[i]/@root` | attr | 2 items expected (ICH + regional) | OID | L3, L5, L19 |
| X6 | `X4/{v3}device/{v3}id/{v3}item[i]/@identifierName` | attr | expected | free text | L3 (non-authoritative) |
| X7 | `X1/{v3}controlActProcess/{v3}subject[s]/{v3}submissionUnit` | element | IG: exactly 1 (eCTD4-005) | — | L2, L8 |
| X8 | `X7/{v3}id/@root` | attr | 1..1 | UUID | L8 |
| X9 | `X7/{v3}code/@code` · `X7/{v3}code/@codeSystem` | attr pair | 1..1 each | code · OID | L8 |
| X10 | `X7/{v3}title/@value` | attr | 0..1 | free text | L8 |
| X11 | `X7/{v3}statusCode/@code` | attr | 0..1 (`active`) | token | L8 |
| X12 | `X7/{v3}componentOf1[k]` | element | 1..* (more than 1 only for grouped/worksharing) | — | L2, L23, L28 |
| X13 | `X12/{v3}sequenceNumber/@value` | attr | IG 1..1 per submission; schema 0..1 | integer | L10, L11 |
| X14 | `X12/{v3}submission/{v3}id/{v3}item[j]/@root` · `/@extension` | attr pair | ≥1 item; root 1..1, extension 0..1 | UUID/OID · text | L12, L13, L21, L28 |
| X15 | `X12/{v3}submission/{v3}code/@code` · `/@codeSystem` | attr pair | ICH 1..1 (EU text 0..1, C-4) | code · OID | L12, L13, L28 |
| X16 | `X12/{v3}submission/{v3}componentOf[a]/{v3}application` | element | 1..* (schema); FDA 1 per submission | — | L12, L22 |
| X17 | `X16/{v3}id/{v3}item[m]/@root` · `/@extension` | attr pair | ICH 1..*; FDA 1..1 | OID/UUID · text | L14, L22, L29 |
| X18 | `X16/{v3}code/@code` · `/@codeSystem` | attr pair | 1..1 | code · OID | L14, L22, L29 |
| X19 | `*/{v3}code/{v3}displayName`, `/@displayName`, `originalText`, `@codeSystemName` | elem/attr | "may not be required"; EU ignores | text | L9, L30 |

---

## 6. Factual extraction candidate matrix

### 6.1 Factual collection table (first wave)

| Candidate | Selector | Raw components kept separately | Profiles | Classification | Inventory field | CEC |
|---|---|---|---|---|---|---|
| Root local name and namespace | X1 | local name; namespace URI | all | **Collect now** | `Structure.RootLocalName`, `.RootNamespaceUri` | `Ectd4MessageRootElement`, `Ectd4MessageNamespace` |
| `ITSVersion` | X2 | raw value | all | **Diagnostic** | `Structure.ItsVersion` | none |
| `xsi:schemaLocation` | X3 | raw string (≤256 chars) | all | **Diagnostic only**; never resolved | `Structure.SchemaLocationDeclared` | none |
| IG markers | X5 (+X6) | `Root`; `IdentifierName` diagnostic; recognition | all | **Collect now** (root); identifierName diagnostic | `ProfileMarkers[]` | `Ectd4ImplementationGuideOid` (recognised only) |
| Submission-unit id | X8 | root; root format (UUID/other) | all | **Collect now as identity fact (inventory only)** | `SubmissionUnit.IdRoot` | none (identity, D-5) |
| Submission-unit type code | X9 | code; codeSystem; recognition; displayName presence | all | **Collect now** | `SubmissionUnit.Code` | `Ectd4SubmissionUnitTypeCode` |
| Submission-unit status | X11 | raw | all | **Diagnostic** | `SubmissionUnit.StatusCode` | none |
| Sequence number | X13 | raw text; parsed integer; value status | all | **Collect now** | `Submissions[k].SequenceNumber` | `Ectd4SequenceNumber` (Supporting) |
| Submission id items | X14 | per item: root, root format, extension | all | **Collect now (inventory only)** | `Submissions[k].IdItems[]` | none (identity, D-5) |
| Submission type code | X15 | code; codeSystem; recognition | all | **Collect now** | `Submissions[k].Code` | `Ectd4SubmissionTypeCode` |
| Application id items | X17 | per item: root, root format, root recognition, extension | all | **Collect now** (root recognition → CEC; extension inventory only) | `Submissions[k].Applications[a].IdItems[]` | `Ectd4ApplicationIdNamespaceOid` (recognised registered root only) |
| Application type code | X18 | code; codeSystem; recognition | all | **Collect now** | `Submissions[k].Applications[a].Code` | `Ectd4ApplicationTypeCode` |
| Folder-name / sequence comparison | RD unit folder name vs X13 | `Equal`/`Different`/`NotComparable` | all | **Collect now (inventory fact)** | `Submissions[k].SequenceNumber.MatchesUnitFolderName` | none |
| Counts of `contextOfUse` / `document` | X7/component, X16/component | integers | all | **Diagnostic** | `Diagnostics.ContextOfUseCount`, `.DocumentCount` | none |

### 6.2 Evaluated and not collected now

| Element | Classification | Reason |
|---|---|---|
| Header `id`, `creationTime`, `interactionId`, `processingCode`, `processingModeCode`, `acceptAckCode`, `sender/device/id` | **Reject** | ICH-excluded and valueless (L4) |
| `profileId` (schema-optional) | **Reject** (presence diagnostic only) | Not used by ICH; no meaning |
| `submissionUnit/title`, `document/title` | **Reject** | Free text (L8; FDA says title must not contain reviewable info) |
| `callBackContact/contactParty` (person name, telecom) | **Reject** | Personal data |
| `holder/applicant/sponsorOrganization/name`, `manufacturedProduct/name` | **Reject** for now | Organisation and product names; free text / commercially sensitive |
| `application/informationRecipient/territorialAuthority/governingAuthority` (EU) | **Defer (wave 2)** | Explicit typed authority marker (EU CV `…6905.1.12.1`), but defined only in **draft** E1 §9.4/§9.20, and FDA ignores it (L24). Needs a stable EU IG |
| `contextOfUse/primaryInformationRecipient/territorialAuthority` | **Defer** | Context-of-Use level; draft EU |
| `submission/subject3/mode`, `subject5/submissionGroup`, `subject2/review` (+ `effectiveTime`) | **Defer** | Regional, EU-draft-defined; FDA ignores them |
| `relatedContextOfUse`, `derivedFrom/documentReference`, forward-compatibility leaf references (root `…2.2.1.13.1`) | **Defer to the reference-semantics task** | Document lifecycle across units; needs cross-unit resolution (accepted v4-discovery downstream gate `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS`) |
| `keywordDefinition`, keywords | **Defer** | Sender-defined vocabulary; content metadata |
| `applicationReference` | **Defer** | Cross-application relation; EU generic-reference semantics |
| Header IG `identifierName` | **Diagnostic only** | "will not be used by the Regulatory Authority" (L3); labels conflict with CVs (C-1, C-2) |

### 6.3 Interpretation / deferred table (future governed work only, not parser output)

| Possible meaning | Would need | Status |
|---|---|---|
| Final format = eCTD v4.0 | Projection v2 + rules over root/namespace/IG OID + physical markers | Deferred (T4a/projection v2) |
| Region / RegionalImplementation from regional IG OID or application-id namespace | Governed OID→master-data relationship; T3c U2 | Deferred; **no arc/prefix inference** |
| Authority (FDA CDER vs CBER) from application namespace OID | Governed mapping | Deferred |
| Specification profile / IG generation | Governed mapping of recognised IG OIDs | Deferred |
| ProcedureContext / LifecycleContext from submission or unit type codes | Governed code→context mapping (T3c U5) | Deferred |
| Application grouping across units (same application id) | Cross-unit aggregation design | Deferred (D-5) |
| Regulatory-activity grouping (same submission id) | Cross-unit aggregation | Deferred |
| Sequence continuity / first-number rule | Lifecycle rules; C-6 | Deferred |
| Cross-version code aliases (e.g. EU `.11.1` vs `.11.2`) | Master-data alias policy | Deferred |
| Confidence, conflict resolution, normalisation | T4 policy | Deferred |

---

## 7. Terminology model

| Concept | Representation | Direct in one XML? | Source |
|---|---|---|---|
| Physical submission-unit folder | RD `Sequences[]` row, `SequenceLikeKind = SubmissionUnitFolder` (or `AmbiguousRegulatoryUnitFolder`), folder name = sequence value | Physical only (RD) | [OBS]; L23 |
| Submission-unit message identity | `submissionUnit/id@root` (UUID, unique per unit) | **Yes** | L8 |
| Sequence number | `componentOf1[k]/sequenceNumber@value`, **per submission**; unique within an application; may differ per submission in a grouped unit | **Yes** | L10, L11, L23 |
| Submission (regulatory activity) | `componentOf1[k]/submission` with `id` items and `code`; the id stays the same across all units of the activity (EU remark; FDA `US-eCTD4-563`) | Identity yes; **membership of other units is cross-document** | L12, L21, L28 |
| Submission-unit type | `submissionUnit/code` (regional CV) | **Yes** | L8 |
| Submission type | `submission/code` (regional CV) | **Yes** | L13 |
| Application | `submission/componentOf[a]/application`; `id/item` (root + extension) and `code`; region-specific meaning (FDA: application type; EU: legal basis) | Identity yes; **"same application" across units is cross-document** | L14, L22, L29 |
| Dossier (eMAS) | RD `DossierCandidates` = a physical container, **not** an application (accepted U7) | No | [OBS] |
| Lifecycle across units | Shared submission id / application id / CoU ids across messages | **No**, cross-document | L16 |
| Context of Use / document lifecycle | `relatedContextOfUse`, `documentReference` | References are in the XML; targets are in other units | I1 §9.2.7–9.2.8 |
| Regional authority / profile | Regional IG OID (header); FDA Center namespace OID; EU territorial authority (deferred) | Marker yes; meaning **no** | L3, L18, L26 |

**Conclusions:**
- No two of these concepts are equated.
- Application and submission identifiers can be **collected independently per submission unit**: each SUXI record holds its own items, with no application-level aggregate, merge or deduplication across units.
- Repeated identical identifiers across units are left as repeated facts.

---

## 8. Failure, coverage and reason-code matrix

**Status vocabularies:**
- **Reused:** `CaptureStatus` (`Available`, `InputUnavailable`, `AccessDenied`, `ParseFailed`, `NotCollected`); `ParseStatus` (`Parsed`, `ParseFailed`, `Missing`, `NotAttempted`); `CollectionStatus` (`Collected`, `Partial`, `NotAssessed`, `NotApplicable`).
- **New, inventory only:** `StructureStatus`, `ProfileStatus`, marker/value `Recognition`, `ValueStatus`.
- **Coverage rows:**
  - document level: `CheckId = SubmissionUnitXmlInventory`, `SubjectType = SubmissionUnitXml`;
  - field level: `CheckId = SubmissionUnitXmlField:<FieldCode>`.

| # | Situation | Capture / Parse | Collection (doc / field) | Reason code | Raw facts kept? | CEC record? | Kind |
|---|---|---|---|---|---|---|---|
| S-1 | Unit folder has no `submissionunit.xml` (`DamagedSubmissionUnitCandidate`) | Available / Missing | NotApplicable | `SubmissionUnitXmlAbsent` | Folder only (RD) | none | coverage |
| S-2 | Marker listed by RD disappears before open | InputUnavailable / NotAttempted | NotAssessed | `SourceXmlUnavailable` | none | none | coverage |
| S-3 | Access denied | AccessDenied / NotAttempted | NotAssessed | `SourceXmlAccessDenied` | none | none | coverage |
| S-4 | Other read error / ZIP entry unavailable | InputUnavailable / NotAttempted | NotAssessed | `SourceXmlUnavailable` | diagnostic code (`XML-READ-001`, `XML-ZIP-ENTRY-001`) | none | coverage |
| S-5 | Not well formed / safe-reader failure | ParseFailed / ParseFailed | NotAssessed | `SourceXmlParseFailed` | parse error code, line, position | none | parser |
| S-6 | External entity, DTD or schema reference present | Parsed (resolver null; nothing fetched) | Collected | `ExternalReferenceNotResolved` (diagnostic) | `HasDocumentType`, schemaLocation string | facts as normal | parser |
| S-7 | Root local name is not `PORP_IN000001UV` (e.g. Wave 1E `discovery-stub`) | Available / Parsed | NotAssessed | `UnrecognizedRootElement` | root name + ns | **none** | parser |
| S-8 | Namespace is not `urn:hl7-org:v3` | Available / Parsed | NotAssessed | `UnrecognizedNamespace` | root name + ns | none | parser |
| S-9 | Recognised structure, no receiver IG items | Available / Parsed | Partial | `ProfileMarkersAbsent` | other facts | root/ns/type codes; no IG record | parser |
| S-10 | IG OID not in tables (incl. FDA `.18.6`) | Available | field: NotAssessed | `UnrecognizedProfileMarker` | OID verbatim | none for that marker | parser |
| S-11 | Only ICH or only regional marker recognised | Available | Partial | `IncompleteProfileMarkers` | all markers | recognised ones only | parser |
| S-12 | Conflicting markers (two regional families, or two ICH IG OIDs) | Available | Partial | `ConflictingProfileMarkers` | all markers + ordinals | each recognised one, with `SourceOrdinal`; **no resolution** | parser |
| S-13 | Draft or unpublished profile OID (EU `.6.1.2`, `.6.1.3`) | Available | Collected | `ProfileSourceDraft` / `ProfileSourceUnpublished` (informational) | marker + source status | yes (recognition ≠ support) | parser |
| S-14 | Schema not evaluated | — | doc row always carries `SchemaValidation = NotEvaluated` | `SchemaNotEvaluated` | — | — | coverage (constant) |
| S-15 | Schema validation failure | **Not applicable**: validation is out of scope (regulator step, L17) | — | — | — | — | — |
| S-16 | Duplicate singleton (two `submissionUnit`, two `code` on one element) | Available | field: NotAssessed | `CardinalityViolation` | all values (`Values[]`) | none for that field | parser |
| S-17 | Unexpected cardinality that is allowed by the schema but not the IG (e.g. FDA two application `id.item`) | Available | Collected | `RegionalCardinalityExceeded` (informational) | all items | per-item records (recognised roots) | parser |
| S-18 | Mandatory element or attribute missing (e.g. no `submissionUnit/code`, no `sequenceNumber`) | Available | field: Collected | `MandatoryFieldAbsent` | `ValueStatus = Absent` | none | parser (assessed absence) |
| S-19 | Unknown code in a known code-system version | Available | field: NotAssessed | `CodeOutsideCodeSystem` | code + codeSystem kept | **none** | parser |
| S-20 | Known code with an unexpected code system for that element (e.g. EU submission-type OID on `submissionUnit/code`) | Available | field: NotAssessed | `CodeSystemNotExpectedForElement` | both kept | none | parser |
| S-21 | Unknown code system | Available | field: NotAssessed | `UnrecognizedCodeSystem` | both kept | none | parser |
| S-22 | Multiple distinct application ids / submission ids in one message | Available | Collected | — (legitimate: grouped) | each with ordinals | per-element records with `SourceOrdinal` | parser |
| S-23 | Sequence number not a whole number 1–999999 | Available | field: NotAssessed | `SequenceNumberOutOfRange` / `SequenceNumberNotInteger` | raw text | none | parser |
| S-24 | Sequence number ≠ unit folder name | Available | Collected | `SequenceNumberDiffersFromFolder` (informational) | both | sequence record still emitted | parser |
| S-25 | Some fields usable, others not | Available | doc: Partial | aggregate of field reasons | usable facts | usable records only | coverage |
| S-26 | Capability not requested | not run | **no rows**; capability token absent | `CapabilityNotRun` (implicit) | none | none | coverage |
| S-27 | Marker outside a unit folder (`UnplacedSubmissionUnitMarker`) | — | doc row NotApplicable | `UnplacedMarkerNotInventoried` | RD observation only | none | coverage |
| S-28 | Two marker files differing only in case in one folder | Available | NotAssessed | `DuplicateSubmissionUnitFiles` | file list | none | coverage |
| S-29 | Unit is `AmbiguousRegulatoryUnitFolder` (both `index.xml` and `submissionunit.xml`) | parsed normally | Collected | `AmbiguousUnitFolder` (informational) | facts | records (the unit stays ambiguous at RD) | parser |

All of these stay distinct: absence (S-1, S-18), unavailability (S-2–S-4), parse failure (S-5), unsupported structure or profile (S-7–S-10), invalid value (S-19–S-23) and ambiguity (S-12, S-16).

---

## 9. Architecture option comparison

| Criterion | **A. Separate SUXI capability (recommended)** | B. Extend BXI | C. Extend RD |
|---|---|---|---|
| Duplicate parsing | None. BXI does not open `submissionunit.xml` [OBS], so SUXI is the single parser | None, but BXI would gain a new non-v3 document class | RD would parse XML, violating RD's physical-only rule (accepted v4-discovery design) |
| Ownership | New module owns its collection | BXI is keyed on exact v3 sequences, which v4 units are deliberately not | — |
| BXI / T1b stability | BXI unchanged; T1b behaviour and qualification untouched | BXI change and re-qualification again, right after T1b | — |
| Optionality | Natural (switch plus capability token) | Hard to make optional inside BXI | — |
| T4 short pipeline | Unchanged unless requested | Changes BXI output in every run | — |
| Future regions (CA, CH, JP) | Profile table in the SUXI helper | BXI grows further | — |
| PS5.1 | Same APIs as BXI (safe reader, ZipArchive) | same | — |
| Cost | Duplicates BXI's file/ZIP entry-opening safety logic (about 120 lines) | — | — |

**Recommendation: A.**
- **Invocation point:** after BXI and before CEC. The pipeline is RD → BXI → **SUXI (optional)** → [reference/checksum chain, optional] → CEC → Identification.
- **Inputs:** SUXI consumes the RD `Sequences` rows of kind `SubmissionUnitFolder` and `AmbiguousRegulatoryUnitFolder`, plus RD `Files`. It does not depend on BXI output.
- **Paths:** SUXI opens only `<unit RelativePath>/submissionunit.xml`, as listed by RD (case-insensitive match, exact spelling preserved). It applies the existing BXI path-safety rules: stay inside `SourcePath`, no reparse points, ZIP entry by exact listed name.
- **Reader:** the shared `private/eMAS.SafeXml.ps1` (`XmlResolver = $null`, entity expansion capped at 1024). No schema or network access.
- **Disabled capability:** not run means no collection, no rows and no token (S-26).
- **Determinism:** `SubmissionUnitXmlId` = `SUX-nnnn`, in ordinal order of the RD unit `RelativePath`.
  - Envelope-style ordinals follow document order.
  - Repeated runs on the same bytes are identical.
  - SUXI is idempotent: if the capability token is already present it fails with `SUXI-INPUT-002`, mirroring `CEC-INPUT-004`.
- **CEC isolation:** CEC reads only `SubmissionUnitXmlDocuments`. It never opens a path from it. A static test enforces that CEC has no XML-reader calls.
- **Accepted cost:** the duplicated entry-opening logic. A later shared-helper refactor of BXI and SUXI is optional and out of scope (BXI unchanged).

---

## 10. Recommended SubmissionUnitXmlInventory object shape

New **top-level** member of ScannerObservations, owned by SUXI: `SubmissionUnitXmlDocuments` (array, ordered by `SubmissionUnitXmlId`). Values below are **illustrative**, not copied from an official example.

```json
{
  "SubmissionUnitXmlId": "SUX-0001",
  "DossierId": "DOS-0001",
  "SequenceId": "SEQ-0003",
  "UnitFolderKind": "SubmissionUnitFolder",
  "FileId": "FIL-0042",
  "RelativePath": "1/submissionunit.xml",
  "Exists": true,
  "CaptureStatus": "Available",
  "ParseStatus": "Parsed",
  "ParseErrorCode": null, "ParseErrorLineNumber": null, "ParseErrorLinePosition": null, "Diagnostic": null,
  "SchemaValidation": "NotEvaluated",
  "Structure": {
    "RootLocalName": "PORP_IN000001UV", "RootNamespaceUri": "urn:hl7-org:v3",
    "ItsVersion": "XML_1.0", "SchemaLocationDeclared": "urn:hl7-org:v3 PORP_IN000001UV.xsd",
    "HasDocumentType": false,
    "StructureStatus": "Recognized | UnrecognizedRootElement | UnrecognizedNamespace | NotAttempted"
  },
  "VocabularyId": "ECTD4-SUXI-VOCABULARY/1",
  "ProfileStatus": "MarkersRecognized | IncompleteProfileMarkers | ConflictingProfileMarkers | ProfileMarkersAbsent | UnrecognizedProfileMarker | NotAttempted",
  "ProfileMarkers": [
    { "MarkerOrdinal": 1, "Root": "2.16.840.1.113883.3.989.2.2.1.11.6", "IdentifierName": "…",
      "Recognition": "RecognizedIchIg | RecognizedRegionalIg | UnknownOid | Empty",
      "Family": "ICH | FDA | EU | null", "SourceListVersion": "ICH CV v7", "SourceStatus": "Current | Historical | Draft | RegisteredWithoutPublishedGuide | null" }
  ],
  "SubmissionUnit": {
    "IdRoot": "…uuid…", "IdRootFormat": "Uuid | NotUuid | Absent",
    "Code": { "Code": "…", "CodeSystem": "2.16.840.1.113883.3.6905.1.8.1", "Recognition": "Known | CodeOutsideCodeSystem | CodeSystemNotExpectedForElement | UnrecognizedCodeSystem | Absent | MultipleValues", "DisplayNamePresent": false },
    "StatusCode": "active",
    "SubmissionCount": 1
  },
  "Submissions": [
    { "SubmissionOrdinal": 1,
      "SequenceNumber": { "Raw": "1", "Value": 1, "ValueStatus": "WholeNumberInRange | SequenceNumberNotInteger | SequenceNumberOutOfRange | Absent | MultipleValues", "MatchesUnitFolderName": "Equal | Different | NotComparable" },
      "IdItems": [ { "ItemOrdinal": 1, "Root": "…", "RootFormat": "Uuid | Oid | Other", "Extension": "…|null" } ],
      "Code": { "Code": "…", "CodeSystem": "…", "Recognition": "…", "DisplayNamePresent": false },
      "Applications": [
        { "ApplicationOrdinal": 1,
          "IdItems": [ { "ItemOrdinal": 1, "Root": "…", "RootFormat": "Oid", "RootRecognition": "RecognizedNamespaceOid | NotRecognized", "Extension": "…|null" } ],
          "Code": { "Code": "…", "CodeSystem": "…", "Recognition": "…", "DisplayNamePresent": false } } ] } ],
  "Diagnostics": { "ContextOfUseCount": 12, "DocumentCount": 9, "ProfileIdPresent": false, "ReasonCodes": [] }
}
```

**Rules [DES]:**
- **Field types:** all strings, except the ordinals, `Value`, `SubmissionCount`, the counts and the booleans.
- **Nullability:** any member is `null` when its source is absent. Arrays are empty, never null.
- **`Extension` values (application, procedure or tracking numbers):**
  - kept in the inventory only;
  - never published to CEC;
  - capped at 64 characters;
  - free-text `title`/`name` values are never stored (§6.2).
- **`IdentifierName`:** stored for traceability, capped at 128 characters. Non-authoritative.
- **Serialisation depth:** maximum nesting is 7. Writers use `ConvertTo-Json -Depth 64`, as all existing modules do, so PS5.1 is safe.
- **Unrecognised structure:** when `StructureStatus` is anything other than `Recognized`, only `Structure` and diagnostics are filled. `ProfileMarkers`, `SubmissionUnit` and `Submissions` are empty or null. No fact is guessed.

---

## 11. ScannerObservations compatibility decision

| Option | Fit with 1.0 | Unknown-member behaviour | Identity / ownership | Coverage | Existing consumers | Historical records/tests | Version bump |
|---|---|---|---|---|---|---|---|
| **1. New top-level `SubmissionUnitXmlDocuments` (recommended)** | Additive | Existing modules read named members and ignore unknown ones [OBS: RD/BXI/CEC/T4 use explicit property access] | `SUX-` ids, owned by SUXI | new CheckIds | none affected | none change | **No** |
| 2. Add `XmlKind = SubmissionUnit` to `XmlDocuments` | Additive in form | **Breaks semantics**: BXI's coverage, missing-backbone observations, the CEC XML loop, ReferenceInventory and T4 `XmlKind` joins all iterate `XmlDocuments`. Two writers for one collection; `XmlId` continuity risk | Mixed ownership | overlaps BXI rows | Risk to BXI/CEC/T4 | Possibly | Arguably needed |
| 3. Separate capability result document composed in | New contract | — | — | — | Every consumer would need composition | — | Yes |

**Decision:** Option 1. The contract stays `ScannerObservations/1.0`, following the accepted additive precedents (T1a markers, Wave 1E, T1b `RegionalEnvelope`).

**Field-by-field justification:**
- **New member:** `SubmissionUnitXmlDocuments` (optional).
- **New coverage rows:** new `CheckId` values only.
- **Capability token:** `Execution.Capabilities += 'SubmissionUnitXmlInventory'`, added only when run.
- **ScannerVersion:** the SUXI module sets its own scanner-name segment, as each capability does today.
- **Unchanged:** no existing member is renamed, retyped or re-ordered.

---

## 12. BXI impact

- **BXI is unchanged** (byte-identical). The T1b-qualified behaviour and RC1 re-qualification state are untouched.
- **`XmlDocuments` shape and content are unchanged.** `submissionunit.xml` is not added to `XmlDocuments`.
- **CEC dependency:** CEC still requires the RD + BXI capabilities. SUXI does not change that check.

---

## 13. CEC evidence and coverage proposal

CEC appends T2 types after the T1b types and emits them only when the `SubmissionUnitXmlInventory` capability token and `SubmissionUnitXmlDocuments` are present.

| EvidenceType [DES] | Emitted when | ObservedValue | Strength | SourceTier | Legacy `Dimension` hint | SourceField |
|---|---|---|---|---|---|---|
| `Ectd4MessageRootElement` | `StructureStatus = Recognized` | `PORP_IN000001UV` | **Strong** | StructuredXml | `TechnicalFormat` | `SubmissionUnitXmlDocuments.Structure.RootLocalName` |
| `Ectd4MessageNamespace` | same | `urn:hl7-org:v3` | **Strong** | StructuredXml | `TechnicalFormat` | `….Structure.RootNamespaceUri` |
| `Ectd4ImplementationGuideOid` | per marker with `Recognition` ∈ {RecognizedIchIg, RecognizedRegionalIg} | the OID | **Strong** | StructuredXml | `SpecificationProfile` | `….ProfileMarkers.Root` |
| `Ectd4SubmissionUnitTypeCode` | `Code.Recognition = Known` | the code | **Strong** | StructuredXml | `DossierContext` | `….SubmissionUnit.Code.Code` |
| `Ectd4SubmissionTypeCode` | per submission, `Known` | the code | **Strong** | StructuredXml | `DossierContext` | `….Submissions.Code.Code` |
| `Ectd4ApplicationTypeCode` | per application, `Known` | the code | **Strong** | StructuredXml | `DossierContext` | `….Submissions.Applications.Code.Code` |
| `Ectd4ApplicationIdNamespaceOid` | per application id item with `RootRecognition = RecognizedNamespaceOid` | the OID (never the extension) | **Strong** | StructuredXml | `Region` | `….Applications.IdItems.Root` |
| `Ectd4SequenceNumber` | per submission, `WholeNumberInRange` | integer as string | **Supporting** | StructuredXml | `DossierContext` | `….Submissions.SequenceNumber.Value` |

**Strength and tier rationale [DES]:**
- **Strong** means only "the parsed message contains this registered, typed value at this element". It is a direct controlled code or registered OID at an IG-specified location.
- Strong does **not** mean the message is valid, schema-conformant, or proves a region, profile or context (as T1b C-3).
- The sequence number is a typed administrative integer with no controlled vocabulary, so it is `Supporting`.
- Every type uses `StructuredXml`, so one message cannot corroborate itself under T4 `INDEPENDENT_SOURCE_CLASS`.
- **Never Strong:** `identifierName`, `displayName`, `schemaLocation`, titles, extensions, unrecognised codes or OIDs, counts.

**Code, codeSystem and display stay distinct:**
- `ObservedValue` holds the **code** only.
- A new property, **`ObservedCodeSystem`** (the OID), exists only on the three code types.
- Display text is never published; only `DisplayNamePresent` is kept in the inventory.

**Record shape and ID protection** (T1b A-1 pattern):
- These properties exist **only** on new T2 records:
  - `SourceOrdinal` (1-based, document order of the marker, submission or application element);
  - `SubmissionUnitXmlId`;
  - `ObservedCodeSystem`.
- Historical records keep their exact shape.
- **`XmlId = null`** on every T2 record, because T4 `IDI-INPUT-004` requires any non-null `XmlId` to exist in `XmlDocuments`. `SequenceId` and `DossierId` are the RD unit's ids, which exist.
- `SubjectType = SubmissionUnitXml`.
- `CandidateValue`, `Polarity` and `SourceRuleId` are always `null`.
- `SourceCapability = SubmissionUnitXmlInventory`.
- **Sort order:** `SortGroup = 3`, after T1b's group 2, with key (`SortGroup`, `DossierPath`, `SequenceFolder`, `SubmissionUnitXmlId`, `typeIndex`, `SourceOrdinal (D4)`). Every historical `EVD-nnnn` is unchanged; new IDs continue after the maximum.

**Coverage:**
- **Rows:** one document row and five field rows per SUXI document, all with `SubjectType = SubmissionUnitXml`.
  - Document row: `CheckId = SubmissionUnitXmlInventory`.
  - Field rows: `CheckId = SubmissionUnitXmlField:<FieldCode>` for `ECTD4_IG_OID`, `ECTD4_SU_TYPE`, `ECTD4_SUBMISSION_TYPE`, `ECTD4_APPLICATION_TYPE` and `ECTD4_SEQUENCE_NUMBER`.
- **Reason codes:** as in §8.
- **Isolation rule:** T2 gaps **must not** change the existing CEC `Repository`/`XmlDocument` rows (`CheckId = ClassificationEvidenceCollection`). Otherwise T4 v1 would turn today's `AssessedAbsent` states into `Unavailable` (§14).

---

## 14. T4 / projection deferral decision

**Decision: defer all projection and rule use. No prerequisite exists.**

I checked T4 v1 (`engine/core/eMAS.IdentificationInterpretation.psm1` at the base) at three points:

1. **Input validation** (`Assert-eMASIdentificationInputs`) rejects only unknown `SequenceId`/`DossierId`/`XmlId` references and duplicate `EvidenceId`s.
   - T2 records carry valid RD ids and `XmlId = null`, so they pass.
2. **Field projection** (`CEC-FIELD-PROJECTION/1`) selects by fixed `EvidenceType`.
   - The eight new types are not in the table, so they are ignored.
   - A rule naming a T2 field fails with `IDI-CONFIG-004` until projection v2 exists.
3. **Coverage** is read only from `CheckId = ClassificationEvidenceCollection`.
   - New `CheckId`s are invisible.
   - The CEC repository row must not be degraded by T2 (rule in §13).

**Optional capability:** the T4 Identification-only short pipeline (RD → BXI → CEC → Identification) does not include SUXI unless it is explicitly requested. Even when included, T4 results are byte-identical apart from volatile fields; this is a required test (§15, T-17).

**Later governed task (`CEC-FIELD-PROJECTION/2` / T4a revision) must define:**
- selector bindings for the T2 types (subject: the v4 unit `Sequence`);
- multi-submission and multi-application set semantics;
- `ObservedCodeSystem`-aware matching;
- field coverage reasons;
- recognition-to-dimension mapping under governed master data (no OID-arc inference);
- confidence caps.

---

## 15. Source-traceable fixture and test plan

**Allocation:**
- **SD-028** (EU content-valid) and **SD-029** (US content-valid) keep their reservation.
- The remaining cases use **SD-075…SD-090**. [OBS] SD-001…SD-074 are allocated or referenced.

**Fixture rules:**
- **Construction:** every fixture XML is a **minimal derivation** from the official structure tables. It is not a copy of any copyrighted sample:
  - ICH Table 10/11 and §9.2.4/9.2.12–9.2.14;
  - FDA §8.1–8.2.10;
  - EU §8.1, §9.10 and §9.18.
- **Values:**
  - codes and code-system OIDs are copied verbatim from I3, F2 and E2;
  - UUIDs are generated deterministically and are well formed (EU `eCTD4-EU-072`);
  - application numbers are visibly synthetic (`999999`; EU procedure-number form `ZZ/H/9999/001/DC`).
- **Prohibited:**
  - no renamed v3 file is presented as v4;
  - no invented OID is used where the case is not "unknown OID";
  - "unknown" cases use OIDs under a private test arc, clearly labelled, which **must not** collide with ICH, FDA or EU arcs (decision D-6).
- **Freezing:** every fixture is frozen with a SHA-256 manifest, following the Wave 1E pattern. Each file carries a header comment "eMAS synthetic T2 fixture — not a regulator-validated message".

| ID | Scenario | Basis | Expected inventory facts | Expected coverage | Left unknown | CEC (where justified) |
|---|---|---|---|---|---|---|
| SD-028 | EU single MAA unit: ICH `.11.6` + EU `.6.1.2` | E1 §8.1/9.10/9.18 + E2 codes | root/ns Recognized; 2 markers recognised (EU source status Draft); SU type `100000155047`@`…1.8.1`; submission `100000155689`@`…1.11.2`; app legal basis `100000116047`@`…1.4.1`; app root UUID (NotRecognized namespace); seq 1, matches folder | doc Collected; `ProfileSourceDraft` | region, procedure | 8 types (no app-namespace record: UUID) |
| SD-029 | FDA unit: ICH `.11.5` + FDA `.18.9` | F1 §8.1–8.2.10 + F2 codes | FDA submission-unit type code @ `.13.2`; submission @ `.12.5`; app @ `.1.4`; app root CDER `.16.1` RecognizedNamespaceOid, extension `999999` | Collected | Center meaning | 8 types incl. `Ectd4ApplicationIdNamespaceOid` |
| SD-075 | Second regional profile: FDA `.18.8` (v1.8) | F2b | marker RecognizedRegionalIg (Supported) | Collected | — | IG OID record |
| SD-076 | Historical ICH `.11.4` + FDA `.18.7` | I3, F2c | both recognised (Historical) | Collected | — | 2 IG records |
| SD-077 | Unknown later marker (test-arc OID) | D-6 | `UnknownOid` | Partial / `UnrecognizedProfileMarker` | profile | no IG record |
| SD-078 | No receiver IG items | L3 | `ProfileMarkersAbsent` | Partial | profile | root/ns/codes only |
| SD-079 | Malformed XML | L17 | ParseFailed + line/pos | NotAssessed | all | none |
| SD-080 | Wrong root and namespace (incl. Wave 1E `discovery-stub`) | [OBS] | UnrecognizedRootElement | NotAssessed | all | none |
| SD-081 | Missing `submissionUnit/code` and missing `sequenceNumber` | L8, L10 | `Absent` | field Collected / `MandatoryFieldAbsent` | — | none for those |
| SD-082 | Duplicate `submissionUnit/code` | L8 | `MultipleValues` | `CardinalityViolation` | — | none for field |
| SD-083 | Unknown code in known FDA `.13.2` | F2 | `CodeOutsideCodeSystem` | NotAssessed | — | none |
| SD-084 | EU submission-type OID on `submissionUnit/code` | E2 | `CodeSystemNotExpectedForElement` | NotAssessed | — | none |
| SD-085 | Grouped FDA unit: 2 submissions × 1 application each, distinct sequence numbers | L23 | 2 Submissions, ordinals 1–2 | Collected | grouping meaning | records ×2 with `SourceOrdinal` |
| SD-086 | Two units of one EU activity (seq 1 and 2, same submission id) | L28 | identical submission id facts per unit, **no aggregate** | Collected | lifecycle link | per unit |
| SD-087 | Access denied / unavailable (directory, permission-staged at test time) | [OBS] BXI pattern | none | NotAssessed / `SourceXmlAccessDenied` | all | none |
| SD-088 | Directory and ZIP forms of SD-028 | Wave 1E pattern | identical inventory and CEC (except volatile fields) | — | — | identical |
| SD-089 | Conflicting markers: `index.xml` + `submissionunit.xml` in one folder (RD `AmbiguousRegulatoryUnitFolder`) | v4-discovery amendment 2 | parsed; `AmbiguousUnitFolder` | Collected | format | records; RD unit stays ambiguous |
| SD-090 | Mixed repository: v3 EXTEDORIN-derived dossier + SD-028 unit + independent SD-029 application | composition | v3 BXI unchanged; 2 SUXI docs in 2 candidates | per doc | application identity | historical v3 EVD unchanged |

**Additional tests (not fixtures):**

| ID | Test |
|---|---|
| T-1 | Prefix change (`x:PORP_IN000001UV` with the same namespace) gives identical facts |
| T-2 | Free text and personal data never reach the inventory or CEC (title, contact, names) |
| T-3 | `CandidateValue`/`Polarity`/`SourceRuleId` are null; `XmlId` is null on T2 records |
| T-4 | Historical CEC records are property-identical (Wave 1, T1a, T1b expectations), with no `SourceOrdinal`/`SubmissionUnitXmlId`/`ObservedCodeSystem` added |
| T-5 | Deterministic IDs and order under shuffled input |
| T-6 | CEC contains no XML reader (static check); CEC works on a result with no source on disk |
| T-7 | The capability is not run unless requested; no rows, no token |
| T-8 | A second run fails with `SUXI-INPUT-002` |
| T-9 | DOCTYPE / external entity present: nothing fetched (resolver null), `ExternalReferenceNotResolved` |
| T-10 | Draft and unpublished EU markers carry source status, and recognition is not called "supported" |
| T-11 | FDA `.18.6` is **not** recognised (C-2) |
| T-12 | `ConvertTo-Json -Depth 64` round-trip is identical on PS5.1 and PS7.6 |
| T-13 | Wave 1E regression: RD output is byte-identical; SUXI over the Wave 1E stubs gives 22× `UnrecognizedRootElement` |
| T-14 | Wave 1, Wave1D, root-level and B3 regressions are unchanged |
| T-15 | T1b EU envelope expectations are unchanged |
| T-16 | T4 engine tests 28/28 and oracle 23/23 are unchanged |
| T-17 | The T4 short pipeline with and without SUXI gives identical Identification output |
| T-18 | The code-list tables match the source artefact hashes (table provenance test) |

---

## 16. Exact later implementation file allowlist (proposal; nothing modified here)

| File | Change |
|---|---|
| `engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1` | **New:** capability `Invoke-eMASSubmissionUnitXmlInventory` |
| `engine/powershell51/private/eMAS.Ectd4SubmissionUnit.ps1` | **New:** selector walk, structure/profile/code recognition, status codes |
| `engine/powershell51/private/eMAS.Ectd4Vocabulary.ps1` | **New:** `ECTD4-SUXI-VOCABULARY/1` tables (IG OIDs; 3 code lists × versions; namespace OIDs) with source/hash metadata |
| `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1` | 8 types, `SortGroup = 3`, new-record-only properties, `SubmissionUnitXml` coverage rows |
| `scripts/eMAS-PreSalesAssessment.ps1` | Explicit `-IncludeSubmissionUnitXmlInventory` switch only; default chains unchanged |
| `tests/submissionunit-xml-inventory/**` | **New** tests T-1…T-18 |
| `tests/fixtures/submissionunit-xml-inventory/**` | **New** frozen fixtures SD-028, SD-029, SD-075…SD-090 + manifest |
| `tests/classification-evidence-collection/**`, `tests/fixtures/classification-evidence-collection/*expectations*.json` | Only if needed to add T2 assertions; historical expectations must stay byte-identical |
| `.github/workflows/powershell-runtime-contracts.yml` | Add SUXI tests on the three PowerShell lanes |
| `engine/powershell51/README.md`, task report/status | Docs |

**Not changed:**
- `eMAS.BackboneXmlInventory.psm1`, `eMAS.RepositoryDiscovery.psm1`, `private/eMAS.SafeXml.ps1` (reused unchanged), `private/eMAS.EuRegionalEnvelope.ps1`;
- `engine/core/**` (T4, RuntimeConfiguration), the oracle, CEC-FIELD-PROJECTION;
- `config/**`, schemas, workbook/VBA, reporting.

---

## 17. Risks, source conflicts and unresolved decisions

### 17.1 Source conflicts (recorded, not reconciled)

| ID | Conflict | Sources | Nature | eMAS behaviour |
|---|---|---|---|---|
| C-1 | EU IG sample labels ICH OID `.11.1` as "ICH eCTD v4.0 IG v1.3"; ICH CV says `.11.1` = IG 1.0 and `.11.2` = 1.3. The same EU IG §8.1 sample elsewhere pairs `.11.4` with "IG v1.5" | E1 §8.1 + later sample vs I3 | Sample vs registry | Recognition uses the OID → I3 table only; `identifierName` is diagnostic |
| C-2 | FDA IG v1.9 sample uses `…18.6` labelled "FDA eCTD v4.0 IG v1.5"; FDA CVs list only `.18.7`/`.18.8`/`.18.9` | F1 §8.1.2 vs F2–F2c | Sample vs registry; unverified OID | `.18.6` = `UnknownOid` until verified (D-3) |
| C-3 | EU CV v3 registers IG OID `…6.1.3` (August 2025, "New version"); EMA publishes only IG **draft v1.2** | E2 vs EMA page | Registry ahead of document | Recognised with `SourceStatus = RegisteredWithoutPublishedGuide` |
| C-4 | EU `submission/code` [0..1] vs ICH [1..1] (eCTD4-034) and schema `minOccurs = 1` | E1 §9.10 vs I1, I2 | Draft regional vs ICH/schema | Absence = `MandatoryFieldAbsent` (assessed absence), not rejection |
| C-5 | FDA application `code@codeSystem` table example `…1.1.2` vs FDA sample and CV `…1.1.4` | F1 §8.2.10 p.39 vs p.41, F2 | Internal FDA inconsistency | Only CV-listed `…1.1.4` is a known code system |
| C-6 | First v4 sequence number: ICH §8.1 forward compatibility ("next available … whole number") vs ICH eCTD4-014 / EU ("starts with 1") | I1 §8.1 vs §12, E1/E4 | Carried over from v4 discovery C1 | Inventory records the raw value; no rule applied |
| C-7 | EU CV v3 XPATH for submission type reads `…/submissionUnit/componentOf/submission/…`; the schema element is `componentOf1` | E2 vs I2 | Typo in CV metadata | Schema path used |
| C-8 | Application cardinality: ICH `id.item` [1..*] vs FDA [1..1] | I1 vs F1 | Regional constraint | Collect all items; `RegionalCardinalityExceeded` informational |
| C-9 | eCTD4-084 (both IG OIDs mandatory) exists from ICH IG v1.7; FDA lists it with effective date TBD and supports ICH IG v1.6; FDA `US-eCTD4-558` already requires the US OID | I1, F3 | Versioned | Marker absence is a fact (S-9); never an error decision |

### 17.2 Risks

| ID | Risk | Mitigation |
|---|---|---|
| R-1 | [GAP] FDA samples, M1 package v1.5.1 and the FDA-hosted ICH IG v1.6 package were not inspected (automated download refused) | D-3: manual retrieval and hash before implementation; until then the v1.5.1 OID stays unknown |
| R-2 | EU IG is still draft; EU structures may change | Only ICH-level elements and CV-registered EU codes are collected; EU-only structures deferred |
| R-3 | Embedded code tables go stale (new CV versions) | Versioned tables plus a provenance test (T-18); unknown versions → `UnrecognizedCodeSystem`, never guessed |
| R-4 | Identifier values (application/procedure numbers) are commercially sensitive | Inventory only, length-capped, never in CEC; D-5 |
| R-5 | Duplicated entry-opening logic between BXI and SUXI | Accepted; optional future shared helper |

### 17.3 Unresolved user / SME decisions

| ID | Decision | Owner | Blocking? |
|---|---|---|---|
| D-1 | Accept Option A (separate SUXI) and the additive 1.0 shape | User + central review | Design acceptance |
| D-2 | Accept the 8 CEC types and their strengths (7 Strong, 1 Supporting) | Central review | Design acceptance |
| D-3 | Manually obtain FDA F4–F6 and confirm the FDA M1 v1.5.1 IG OID and the `…18.6` meaning | User / FDA SME | Blocks *recognising* v1.5.1 only; not collection |
| D-4 | Should EU draft or unpublished IG OIDs be recognised (with source status) or treated as unknown? Recommendation: recognise + status | Regulatory SME + PO | No |
| D-5 | Retaining application/submission id `Extension` values in the inventory (business-sensitive) vs root/format only | PO | No (default: keep, capped, inventory only) |
| D-6 | A private eMAS test OID arc for "unknown marker" fixtures | Technical Architect | Fixture authoring only |
| D-7 | Wave-2 scope: EU territorial authority, `mode`, `submissionGroup` once the EU IG is final | PO + Regulatory SME | No |
| D-8 | `CEC-FIELD-PROJECTION/2` scope and timing (§14) | PO + central review | No (deferred) |

**Blocking decisions for this design: none.** The only item that blocks implementation is D-1/D-2 acceptance. D-3 limits FDA v1.5.1 recognition, not collection.
