# Claude Report — EMAS-MS04-ECTD4-DISCOVERY-DESIGN

**Status:** `DESIGN_COMPLETE — RECOMMENDATION READY FOR REVIEW`
**Agent:** Claude (single worker, research and design only)
**Branch:** `analysis/emas-ms04-ectd4-discovery-design`
**Based on:** `coordination/emas-ms04-ectd4-discovery-design` @ `703acbaf968d99ef60830b186ca2f9c3282d665f`, which contains authoritative base `02c29863448ead141616a3c78ee8b558bb4fabfe` (accepted B3)
**Source review date:** 2026-10-06

No engine, script, test, fixture, expectation, contract, FormatDetection or RegionDetection file was changed. Source documents, text extraction and a rule simulator ran in scratch only. This report is the only repository change.

## Executive answers

| Question | Answer |
|---|---|
| Recommended v4 rule (one sentence) | A directory becomes a v4 **submission-unit folder** when its name is 1–6 ASCII digits and it directly contains a file named `submissionunit.xml` (or, as a damaged-package fallback, `sha256.txt` plus an `m1`–`m5` folder) and no `index.xml`. Its **parent directory**, which may be the archive root, is the dossier candidate; the v3/NeeS B3 path is unchanged. |
| Is `DossierCandidates` still the right abstraction? | **Yes, as a physical sequence container**, with no contract change now. For v4 it is **not** an application boundary. Application identity lives in `submissionunit.xml` (FDA uses no application folder; EU grouped transmissions span several application folders with cross-folder document reuse). Application identity must come from a later XML capability, not from re-interpreting `DossierCandidates`. |
| Whole-number vs four-digit naming | **Resolved by source.** The v4 sequence folder is named with the *actual* sequence-number value, a positive integer from 1 to 999999. It has no leading zeros: ICH says "actual value", gives examples `1`, `2`, `999`, and ICH §8.1 converts v3 `0003` to v4 `4`. FDA and EU agree. |
| `submissionunit.xml` placement | Directly inside the sequence-number folder. ICH §5.1, and ICH rule `eCTD4-063` "Submission Unit File is found in the sequence number folder". Only one per package (`eCTD4-061`). |
| `sha256.txt` | Required, in the same folder as `submissionunit.xml` (ICH §5.1, `eCTD4-060`). Used for discovery only as a **secondary** marker for damaged packages. |
| Proposed fixtures | **Wave 1E (v4 physical discovery): SD-053 to SD-074**, 22 scenarios. SD-028 and SD-029 stay reserved for content-valid EU/US v4 fixtures built from genuine regional XML. |

---

## 1. Source ledger

### 1.1 Documents reviewed (current versions verified 2026-10-06)

| # | Authority | Exact title | Version / date | Status | SHA-256 of the file reviewed |
|---|---|---|---|---|---|
| S1 | ICH (M8) | *ICH eCTD v4.0 Implementation Guide* (`ICH_eCTDv4_0_ImplementationGuide_v1_7.pdf`, in the IG package zip) | v1.7, endorsed June 2026 | current (ICH eCTD v4.0 page) | package zip `37c35e3bcd72f2cc69b603794bb2add48cf53d65e71ca4c87bf400848999e13f` |
| S2 | ICH (M8) | *eCTD v4.0 Support Documentation* | v1.6 | current support material | `ba8d8c23061c75590dd20ff224222cf8bf139941d990d821cf378d7caecb6340` |
| S3 | ICH (M8) | *eCTD v4.0 Q&A and Change Request Document* (`ICH_eCTD_v4.0_QA_v1.10.xlsx`) | v1.10, June 2026 | current | zip `45774d0adb1db779dcaa2ae49b6f03b995dc1321a0346541d5bb7dfa2c455781` |
| S4 | FDA (CDER/CBER) | *FDA Module 1 eCTD v4.0 Implementation Guide* | v1.9, August 2026 (support begins 2026-09-28) | current | `d3b9b7bfaa339532d25f4eea6662fefd5f37e969e350ae5f7b4af66b1b73a712` |
| S4b | FDA | Same title | v1.8, October 2025 (`/media/179721`) | **superseded** by v1.9; used only to confirm §4.1 is unchanged | `c66d68f0b1a4ed4150e8c5436bbd90fe06865072b035382582c2106c35818dc0` |
| S5 | FDA | *Specifications for eCTD v4.0 Validation Criteria* | v1.6 (2026-08; support begins 2026-08-28) | current | `d3768a7da7f261c52c25034255da94046570c979c8da5f238d3e7480b1b89721` |
| S6 | FDA | *eCTD v4.0 Technical Conformance Guide* | v1.5 (support begins 2026-07-09) | current; context only | `dccd247940cdf5bc7cbf6a5e31b8f2547ad7f61650ae1a138113feb315f8002e` |
| S7 | EMA / EU | *eCTD v4.0 EU Practical Document* ("EU Practical Guidance") | v1.0, December 2025 | current; *practical / recommended practice* | `b45bab3b48815b3f522f90c3b5ad51a4c0439d270fea16c2a6ad9288d849db12` |
| S8 | EMA / EU | *eCTD v4.0 EU Module 1 Implementation Guide* | **draft** v1.2, October 2024 | current EU IG as published, still marked **DRAFT** | `f4f2e4832c90555700b7bd1dc0ea690aeef6803258dbe60f4fc3e9fcf29c851e` |
| S9 | EMA / EU | *Validation Criteria EU eCTD 4.0* | v1.1 final, March 2026 | current | `833c3780df718bcff9962298ceac1de4dd4791df75523b7398cc70edfe5ef214` |

**Regulatory context.** EU v4 has been optional for new centralised MAAs since 22 December 2025; use is "strongly recommended" from Q1 2027 and mandatory from Q1 2028 (EMA eSubmission eCTD v4 page). The FDA page also lists the *FDA Regional eCTD v4.0 Module 1 Implementation Package v1.5.1* as still supported until 2027-09-28. That package was **not** reviewed; see conflict C4.

### 1.2 Rules and facts used

Page references give the printed page with the PDF page in brackets. In S1 the printed page is the PDF page minus 15.

| ID | Source & location | Fact / rule | Scope | Confidence |
|---|---|---|---|---|
| R1 | S1 §5.1, Fig. 1, p.13 [28] | Submission unit structure: `regionspecifiedfolder/sequencenumber/{sha256.txt, submissionunit.xml, m1..m5}`. | ICH-harmonized | High |
| R2 | S1 §5.1 p.13 | "The Region Specified Folder will be determined by Region/Country … **Some regions may not utilise this folder**." | ICH, regional delegation | High |
| R3 | S1 §5.1 p.13 | "The Sequence Number Folder should be the same for all regions and named with the 'sequencenumber' of the submission unit i.e., **the actual value** of the sequence number e.g., 999." | ICH-harmonized | High |
| R4 | S1 §5.1 p.13 | `submissionunit.xml` **is required** in the second-level (sequence) folder; schema files and the `util` folder are no longer sent. | ICH-harmonized | High |
| R5 | S1 §5.1 p.13 | `sha256.txt` holds the checksum of `submissionunit.xml` and "**must** be included in the sequence folder – i.e., in the same directory as the XML eCTD instance". | ICH-harmonized | High |
| R6 | S1 §5.1 p.13–14 | Folders for modules 1–5 are included only for content in that unit. `m1` follows the regional guide; `m2`–`m5` follow ICH §5.4/§11. "Files previously sent do not need to be sent again." | ICH; `m1` regional | High |
| R7 | S1 §5.1 note p.14 [29]; S3 CR 00300 (incorporated in IG v1.2) | "The submission package should only contain folders when content is provided … should not contain empty folders." **Module folders are therefore not guaranteed.** | ICH-harmonized | High |
| R8 | S1 §5.2 p.14 | "Folder and file names should be written in lower case only." The first-level folder follows the regional guide. | ICH (should) | High |
| R9 | S1 §9.2.12.2 p.69 [84] | `sequenceNumber@value`: "a positive integer … should begin with '1' … should not be greater than '999999'". | ICH-harmonized | High |
| R10 | S1 §8.1 p.27 [42] | Forward compatibility: the first v4 unit for a v3 dossier takes "the next available sequence number … as a **whole number**", e.g. after v3 `0003` the first v4 unit is `4`. After a v4 unit, later v3 messages are rejected (§8, p.26). | ICH-harmonized | High |
| R11 | S1 §12.3 p.122–123 [137–138] | Package validation: `eCTD4-059` `submissionunit.xml` exists (wrong location, name or **mixed case** fails); `eCTD4-060` `sha256.txt` exists (same); `eCTD4-061` only one `submissionunit.xml` per package; `eCTD4-062` checksum valid; `eCTD4-063` "Submission Unit File is found in the sequence number folder … placed in the top-level of the directory of the submission contents package". | ICH-harmonized | High |
| R12 | S1 §5.5 p.16 [31] | No compressed archives for Module 2–5 content; Module 1 is regional. | ICH | High |
| R13 | S2 slides 19, 21, 22 | The submission unit "also known as sequence" contains `submissionunit.xml`, `sha256.txt` and folders; "Folder name is the sequence number (e.g., '1', '2')"; "Folder name is determined by the region" for the first level. Hierarchy: application → submission → submission unit. | ICH explanatory | High |
| R14 | S4 §4.1 p.5–6 [15–16], Fig. 1 | FDA: "The Regionally-specified Folder is **not included** in the FDA Module 1 implementation. This folder **should not be included** in the submission unit package." "The Sequence Number Folder **must be submitted** and named with … the actual value of the sequence number (e.g., 1)." One submission unit per transmission. Fig. 1: `sequencenumber/{sha256.txt, submissionunit.xml, m1..m5}`. Identical in v1.8 (S4b). | FDA-specific | High |
| R15 | S4 §4.1 p.6; §8.3 p.45–46 | FDA grouped submission is **one** submission unit and one sequence folder (the primary application's sequence number). All content sits in that folder and all documents are under ONE application element. | FDA-specific | High |
| R16 | S4 §4.6 p.6 | "Module 1 typically has one folder"; subfolders only if warranted. | FDA-specific | High |
| R17 | S5 `US-eCTD4-503`; `US-eCTD4-528` p.13 | The sequence number in `submissionunit.xml` must match the sequence-folder name (High Error). Empty folder is a Warning. S5 also repeats ICH `eCTD4-059`–`063`. | FDA-specific / ICH-adopted | High |
| R18 | S7 §1.1 p.7 | EU submission unit = (1) First Level Folder (e.g. EMA product number), (2) Second Level Folder, (3) `submissionunit.xml`, (4) `sha256.txt`, (5) `m1` and, as appropriate, `m2`–`m5`. (6) Working documents always go **outside** the v4 package. The guidance "does not require a specific folder and file structuring … the following rules will provide recommended practises". | EU (recommended practice) | High |
| R19 | S7 §1.3 p.8; S8 §5.3 | "The first level folder structure is **required** to identify the content within it". Its **name** (application number, e.g. `ema000123`; NCA examples `de2087`, `fr3456`) is **optional, at applicant discretion**. "Regardless of the naming convention of the root folder, the eCTD tool should independently manage the storing of the sequences." | EU-specific | High |
| R20 | S7 §1.4 p.8; S8 §5.4 | "The second level folder name is the sequence number … a positive whole number between '1' and '999999'. The first submission in eCTD v4.0 format will have sequence number '1'." | EU-specific | High (but see C1) |
| R21 | S7 §1.6 p.9; S8 §5.6 | EU Module 1 is "a single folder with no additional folder structure"; country, language and so on are expressed by keywords. | EU-specific | High (but see C2) |
| R22 | S8 checksums subsection (Fig. 2) | Figure: `fr3456/1/{sha256.txt, submissionunit.xml, m1..m5}`, labelled "Regionally-specified Folder" and "Sequence Number Folder". `sha256.txt` "will be in the sequence number folder"; a mismatch means rejection. | EU-specific | High |
| R23 | S8 §5.3 and §10.3.1, Figs. 3–4 | EU grouped / worksharing, still "under review" in the draft. **Scenario 1:** one transmission with several submission units, one `submissionunit.xml` per application; Fig. 4 shows `fr0034g/{fr1762/3, fr1011/156, fr0345/455}`. Only `fr1762/3` contains `m1`–`m3`; the other units reference those PDFs. **Scenario 2:** several sequences with one `submissionUnit.xml` (e.g. PSUSA). | EU-specific, **draft** | Medium |
| R24 | S9 `eCTD4-EU-065`, `-068`, `-071` | Sequence-folder name matches the sequence number (for single-sequence XMLs); no empty folders; recommended ICH/EU folder and file names are best practice. | EU-specific | High |

### 1.3 Source conflicts (recorded, not reconciled)

- **C1 — First v4 sequence number after v3.** ICH S1 §8.1 says the next available number as a whole number (v3 `0003` → v4 `4`). EU S7 §1.4 and S8 §5.4 say "The first submission in eCTD v4.0 format will have sequence number '1'". Discovery is unaffected, because both are whole-number folders beside v3 `NNNN` folders. Lifecycle interpretation must not assume either.
- **C2 — EU Module 1 folder shape.** S7 §1.6 and S8 §5.6 say a single flat `m1`. The S9 sheet "File Structure & Names" still shows `product-name/1/m1/10-cover/cc/…` with v3-style `m1` subfolders as recommended practice (`eCTD4-EU-071`, BP). Discovery uses only the presence of `m1`–`m5`, so it is unaffected.
- **C3 — Name case.** ICH S1 §5.2 says lower case only, and `eCTD4-059`/`060` reject mixed-case `submissionunit.xml`/`sha256.txt`. The accepted B3 decision uses case-insensitive structural signals. This report keeps case-insensitive **detection** for consistency with B3 and so damaged exports are not lost. Exact-case conformance is a later validation concern (U4).
- **C4 — FDA version coverage.** SOURCES.md pointed to `/media/179721`, which is **v1.8 (Oct 2025)** and superseded by **v1.9 (Aug 2026)**. The FDA page also lists the M1 *package* v1.5.1 as still supported until 2027-09-28. Its IG document was not reviewed, and package and IG version numbering are not obviously the same. §4.1 is identical in v1.8 and v1.9.
- **C5 — First-level folder.** ICH: some regions may not use it (R2). FDA: must not be included (R14). EU: required (R19). This is a real regional difference; the design does not blur it.
- **C6 — EU IG maturity.** The EU IG is still published as **draft v1.2 (Oct 2024)**, and its grouping scenarios are "still under review". The EU Practical Guidance v1.0 (Dec 2025) is the newest EU document and presents itself as recommended practice.

---

## 2. Physical layout models

### 2.1 ICH harmonized (S1 §5.1 Fig. 1; S2 slide 22)

```
<regionspecifiedfolder>/        optional; defined regionally (R2)
  <sequencenumber>/             actual value, 1..999999 (R3, R9)
    submissionunit.xml          required (R4); one per package (R11 eCTD4-061)
    sha256.txt                  required, same folder (R5, R11 eCTD4-060)
    m1/ … m5/                   only where content exists (R6, R7)
```

### 2.2 FDA (S4 v1.9 §4.1 Fig. 1)

```
<sequencenumber>/               e.g. "1"; no regionally specified folder (R14)
  submissionunit.xml
  sha256.txt
  m1/  (typically one folder, R16)   m2/ … m5/ as needed
```

A grouped submission is still **one** folder: the primary application's sequence number (R15). An applicant's or vendor's *archive* of several units is not specified by FDA. It typically holds sibling sequence folders under a tool-managed folder, which is interpretive.

### 2.3 EU (S7 v1.0 §1.1–1.6; S8 draft v1.2 §5, Fig. 2)

```
<first-level folder>/           required as a folder; name recommended = application number
                                (ema000123, de2087, fr3456 …) but optional (R19)
  <sequencenumber>/             1..999999 (R20)
    submissionunit.xml
    sha256.txt
    m1/  (single flat folder, R21; see C2)   m2/ … m5/ as appropriate
```

EU grouped / worksharing Scenario 1 (S8 draft, Fig. 4; still under review):

```
fr0034g/                        grouping / worksharing transmission folder
  fr1762/3/   submissionunit.xml, sha256.txt, m1/ m2/ m3/   (shared PDFs supplied once)
  fr1011/156/ submissionunit.xml, sha256.txt                (no module folders; reuses fr1762/3 files)
  fr0345/455/ submissionunit.xml, sha256.txt                (no module folders; reuses fr1762/3 files)
```

### 2.4 v3 → v4 transition within one application (S1 §8.1; conflict C1)

```
<application folder>/
  0000/ … 0003/   index.xml, m1/ …       (v3.2.2, four-digit)
  4/              submissionunit.xml, sha256.txt, …   (v4; ICH numbering; EU text would say "1")
```

## 3. Terminology mapping

| Concept | eCTD v3.2.2 | eCTD v4.0 (source) | Current eMAS contract | Proposed eMAS meaning for v4 |
|---|---|---|---|---|
| Sequence | `NNNN` folder with `index.xml` | Submission unit, "also known as sequence" (R13), folder = sequence number | `Sequences` (`IsExactSequenceFolder = true` for `NNNN`) | `Sequences` entry with **new** `SequenceLikeKind = SubmissionUnitFolder`, `IsExactSequenceFolder = false` |
| Backbone | `index.xml` + regional XML (+ stf) | single `submissionunit.xml` (R4; "replaces … index, regional and stf XML files") | `XmlDocuments` (v3 roles) | Physical presence only in discovery; parsing deferred |
| Checksum file | `index-md5.txt` | `sha256.txt` (R5) | none | file presence only |
| Application | dossier folder (de facto) | XML: `componentOf … application` (R13); folder = regional or tool-managed (R19) | `DossierCandidates` | **physical container only**, not the application identity |
| Submission | n/a (regional XML) | XML element; region-defined (R13) | none | deferred |
| Region folder | `m1/<region>` | first-level folder (regional, R2/R14/R19) | none | ordinary path: container or wrapper; never interpreted |

## 4. What discovery can and cannot conclude

**From names and structure alone, RepositoryDiscovery can conclude:**
- a numeric folder directly holds a file named `submissionunit.xml` and/or `sha256.txt`;
- which folder contains it;
- which `m1`–`m5` folders are present;
- whether the folder name is canonical (`^[1-9]\d{0,5}$`);
- that several such folders share a parent;
- that a folder could not be read.

**It must defer:**
- whether the XML is well-formed or schema-valid, and its root, namespace, OIDs and versions;
- the region, the specification, and ICH vs regional IG;
- application, submission, context of use and keywords;
- whether the sequence number in the XML matches the folder (`US-eCTD4-503`, `eCTD4-EU-065`);
- checksum validity (`eCTD4-062`) and document references, including EU cross-folder reuse;
- grouped-submission semantics, and v3/v4 lifecycle continuity.

## 5. Design alternatives

| Option | Description | Assessment |
|---|---|---|
| **A** Widen the numeric gate | Change `^\d{4}$` to `^\d{1,6}$` and reuse the B3 signals (`m1`–`m5`, `index.xml`, `submissionunit.xml`). | **Rejected.** v4 units would become `IsExactSequenceFolder = true`. BackboneXmlInventory then probes `index.xml` and `m1/eu/eu-regional.xml` (BXI lines 198–205) and emits **false `MissingCommonBackbone`/`MissingRegionalBackbone`** for every v4 unit. It also widens the module-only signal to 1–6 digits (e.g. `Chapters/2/m1`), and a reuse-only v4 unit with no module folders would still need `submissionunit.xml`. |
| **B** v4-specific structural promotion | A 1–6-digit folder directly containing `submissionunit.xml` is a v4 submission-unit folder; its parent is the container. | **Basis of the recommendation.** It matches R3, R4, R9 and R11 (`eCTD4-063`) in all three sources, does not depend on module folders (R7, R23), keeps B3 separate, and needs no XML parsing. Plain B alone has two gaps: it loses damaged units without `submissionunit.xml`, and it does not settle overlap with four-digit B3 folders or unreadable folders. **B+** adds bounded rules for these. |
| **C** Generic marker-based package roots | Any folder directly containing `submissionunit.xml` or `index.xml` is a package root, regardless of its name. | **Rejected.** All three sources require the sequence-number folder name (R3, R14, R20), so this is broader than the sources. It promotes non-numeric folders, contradicting the accepted B3 test `NonV4Expansion/submission`. It also re-opens web-export `index.xml` false positives everywhere, and promotes an unplaced root-level `submissionunit.xml` that FDA would reject (`eCTD4-063`). |
| **D** Region-aware container inference | Recognise EU first-level names (`ema\d+`, `de\d+` …) or FDA application numbers. | **Rejected.** Uses names as semantics, which TASK.md forbids. EU naming is also optional (R19). |
| **B+ (recommended)** | B, plus: damaged-unit fallback (`sha256.txt` + module folder), marker precedence over the four-digit B3 path, fail-open for unreadable numeric folders, and nested suppression over classified units. | See §7. |

## 6. Scenario matrix (expected RepositoryDiscovery behaviour)

The candidate and wrapper outcomes below were produced by a scratch simulation of the §7 pseudocode, not just reasoned. Kinds: `SU` = SubmissionUnitFolder, `SU-d` = SubmissionUnitFolder with backbone marker missing, `SU-?` = unverified (unreadable), `v3` = exact `NNNN` sequence (B3).

| ID | Layout (abridged) | A | C | **B+ (recommended)** |
|---|---|---|---|---|
| V4-01 | `1/{submissionunit.xml, sha256.txt, m1, m3}` (FDA transmission) | root, as false exact v3 | root | candidate `""` (archive root), `1`=SU |
| V4-02 | `app/1/{su, sha, m1}`, `app/2/{su, sha}` (reuse-only later unit) | both false v3 | `app/1`, `app/2` as separate roots | candidate `app`, `1`=SU, `2`=SU |
| V4-03 | `ema000123/1/{su, sha, m1, m2}` | false v3 | ok | candidate `ema000123`, `1`=SU |
| V4-04 | `Customer/Export/Set/ema000123/7/…` | false v3 | ok | candidate `…/ema000123`; wrappers `Customer`, `Customer/Export`, `Customer/Export/Set` |
| V4-05 | `ema000123/1/…`, `nda123456/1/…` | false v3 ×2 | ok | 2 candidates, isolated |
| V4-06 | `Legacy/0000/index.xml…`, `Modern/1/{su, sha}` | `Modern` false v3 | ok | `Legacy` (`0000`=v3) + `Modern` (`1`=SU) |
| V4-07 | `Archive/2024/report.pdf`, `Archive/2023/notes.txt` | none | none | **none** |
| V4-08 | `Archive/2024/data.xml`, `Data/3/export.xml` | none | none | **none** (only the exact `submissionunit.xml` name counts) |
| V4-09 | `Pkg/12/submissionunit.xml` only | false v3 | ok | candidate `Pkg`, `12`=SU (a valid minimal reuse unit, R6/R7) |
| V4-10 | `Pkg/1/{su, m1}`, no `sha256.txt` | false v3 | ok | candidate `Pkg`, `1`=SU; missing `sha256.txt` is left to validation (`eCTD4-060`) |
| V4-11 | `Pkg/1/{sha256.txt, m1}`, no `submissionunit.xml` | none | none | candidate `Pkg`, `1`=SU-d (damaged; "missing ≠ absent") |
| V4-11b | `Pkg/1/m1` only | none | none | none (too weak outside the four-digit B3 path) |
| V4-12 | `Pkg/5/` unreadable | none | none | candidate `Pkg`, `5`=SU-?, with the access error kept |
| V4-13 | `3/{su, sha, m1}` at archive root | false v3 | ok | candidate `""`, `3`=SU (FDA model R14) |
| V4-13b | `submissionunit.xml` directly at the archive root, no sequence folder | none | **promoted** | **none**; not source-conformant (R3, R14, `eCTD4-063`); open U3 |
| V4-14 | `Pkg/1/{SubmissionUnit.XML, SHA256.TXT, M1}` | false v3 | ok | candidate `Pkg`, `1`=SU (case-insensitive detection; C3/U4) |
| V4-15 | malformed `submissionunit.xml` | false v3 | ok | candidate, `1`=SU; parse failure is a later capability |
| V4-16 | `App/{0000, 0003 (v3), 4 (v4)}` (ICH §8.1) | `4` false v3 | split roots | **one** candidate `App`: `0000`, `0003`=v3, `4`=SU |
| V4-17 | `App/0999/index.xml`, `App/1000/{su, sha}` | `1000` **false v3** | ok | `0999`=v3, `1000`=SU (marker precedence) |
| V4-18 | `Pkg/0001/{su, sha}` (leading zero) | false v3 | ok | `0001`=SU, non-canonical name (observation) |
| V4-19 | EU grouped Scenario 1 (`fr0034g/{fr1762/3, fr1011/156, fr0345/455}`) | 3 × false v3 or lost | ok | 3 candidates (`fr0034g/fr1762`, `…/fr1011`, `…/fr0345`), wrapper `fr0034g` |
| V4-20 | `Pkg/1234567/submissionunit.xml` (7 digits) | none | promoted | **none** (out of range R9/R20) |
| V4-21 | `Pkg/0001/{index.xml, submissionunit.xml}` | v3 | ok | `0001`=v3 (B3 unchanged) + conflicting-marker observation |
| V4-22 | `Exports/2024/ema000123/1/…` + `Exports/2024/Archive/2019/a.pdf` | `1` false v3 | ok | candidate `Exports/2024/ema000123`; wrappers `Exports`, `Exports/2024` |
| B3-R1 | SD-051 shape | — | — | unchanged: `ProductABC` only |
| B3-R2 | accepted B3 test: `Signals/Submission/0001/SubMissionUnit.XML`, `NonV4Expansion/submission/…` | — | `NonV4Expansion/submission` **promoted** (B3 test breaks) | `Signals/Submission` still a candidate (now `0001`=SU), `NonV4Expansion` still not |

**Accepted regression corpora.** None of the 19 Wave 1 or 8 Wave1D fixture ZIPs contains `submissionunit.xml` or `sha256.txt` (scanned: 0 hits). B+ therefore leaves every accepted fixture byte-for-byte identical in discovery output.

## 7. Recommendation (normative proposal)

### 7.1 Plain-English semantics

1. **v4 submission-unit folder.** A directory `U` is a v4 submission-unit folder if:
   - its name is 1–6 ASCII digits; **and**
   - `U` directly contains no file named `index.xml`; **and**
   - **either** `U` directly contains a file named `submissionunit.xml` (`SubmissionUnitFolder`), **or** `U` directly contains `sha256.txt` and at least one directory `m1`–`m5` (`SubmissionUnitFolder`, damaged: backbone marker missing).

   Name matching for these files and folders is case-insensitive.
2. **v3/NeeS path (B3, unchanged).** A directory named exactly `NNNN` that is not a v4 submission-unit folder under rule 1 is evaluated by the accepted B3 rule: a direct `m1`–`m5` folder, or a direct `index.xml`, or an enumeration gap at that exact folder. Consequence: a four-digit folder whose only B3 signal was `submissionunit.xml` is now classified as v4. The accepted B3 tests still pass, because they assert only that the parent is promoted.
3. **Unreadable numeric folders.**
   - Four-digit: B3 fail-open, unchanged.
   - Other 1–6-digit folders with an access or enumeration gap at that exact folder: the parent is promoted with that child recorded as an unverified submission unit. Unknown is not absent.
4. **Container.** The parent `P` of one or more classified folders (v3, SU, SU-d, SU-?) is a dossier candidate. `P` may be the archive root `""`. One container may mix v3 and v4 children (transition, §2.4).
5. **Acceptance.** Shallowest first, in ordinal order. A candidate is dropped when its first segment below an already accepted candidate is one of that candidate's **classified** child folders. This generalises the B3 nested-sequence rule.
6. **Wrappers.** Unchanged: ancestors of accepted candidates (EU grouping folder, deep exports, year folders).
7. **Out of scope:**
   - a `submissionunit.xml` not inside a 1–6-digit folder (e.g. at the archive root or in `seq-1/`) promotes nothing;
   - 7+ digit folders promote nothing;
   - nothing is inferred from XML content or from any name other than the digits rule and the fixed marker names.

### 7.2 Pseudocode

```
D4  = ^\d{4}$          D16 = ^\d{1,6}$          CANON = ^[1-9]\d{0,5}$          MOD = ^m[1-5]$ (ignore case)
gaps = { RelativePath of DISC-ACCESS-001 / DISC-ENUM-001 diagnostics }      # as in accepted B3

classify(U):                                   # U = direct child directory of some P
    name = leaf(U)
    if not D16.match(name): return None
    if U in gaps:
        return 'v3' if D4.match(name) else 'SU?'                    # fail-open, kind records uncertainty
    files = { lower(f) for f in direct files of U };  dirs = direct dirs of U
    if 'index.xml' in files:            return 'v3' if D4.match(name) else None   # v3 marker only on the v3 path
    if 'submissionunit.xml' in files:   return 'SU'
    if 'sha256.txt' in files and any(MOD.match(d) for d in dirs): return 'SU-d'
    if D4.match(name) and any(MOD.match(d) for d in dirs):       return 'v3'      # accepted B3
    return None

raw = { P : {U: k} for each P, U child of P, k = classify(U) is not None }
accepted = []
for P in raw ordered by (depth, ordinal):
    if any(first_segment_below(A, P) in raw[A] for A in accepted if A is ancestor-or-root of P): continue
    accepted.append(P)
sequences: v3 children  -> existing descriptors (IsExactSequenceFolder=true)            # unchanged
           SU/SU-d/SU?  -> SequenceLikeKind='SubmissionUnitFolder', IsExactSequenceFolder=false,
                           SequenceNumber=int(name) when CANON matches else null
observations (additive): SubmissionUnitFoldersObserved (per candidate),
           SubmissionUnitMarkerMissing (SU-d), NonCanonicalSequenceNumberFolderName (D16 but not CANON),
           ConflictingBackboneMarkers (index.xml + submissionunit.xml in one folder)
```

### 7.3 Required elements

| # | Element | Recommendation |
|---|---|---|
| 1 | Plain-English semantics | §7.1 |
| 2 | Pseudocode | §7.2 |
| 3 | Candidate-root semantics | `DossierCandidates` entry = physical container (parent) of ≥ 1 classified sequence or submission-unit folder. It may be `""` (FDA transmission, R14). It is **not** an application identity. |
| 4 | Submission-unit-root semantics | The 1–6-digit folder holding `submissionunit.xml` (R3, R4, R11), recorded in `Sequences` as `SubmissionUnitFolder`. It is not an exact v3 sequence. |
| 5 | Wrapper rules | Unchanged: all non-candidate ancestors. The EU grouping folder (`fr0034g`), customer exports and year folders become wrappers. |
| 6 | Multi-dossier rules | Each container is evaluated independently; IDs ordinal by path as today. EU grouped Scenario 1 gives **several containers** under one wrapper. Its legitimate cross-container document reuse (R23) is a **future ReferenceResolution design issue**, see U6. Discovery must not merge the containers. |
| 7 | Numeric naming | v4: `^\d{1,6}$` detected; canonical `^[1-9]\d{0,5}$`. Leading zeros and `0` are detected but flagged. 7+ digits are ignored. v3: `^\d{4}$` unchanged. |
| 8 | Signals required | `submissionunit.xml` (primary), or `sha256.txt` + `m1`–`m5` (damaged fallback), directly in the numeric folder; or an access gap at that folder. |
| 9 | Signals forbidden | First-level, application, product or region names (`ema…`, `fr…`, `nda…`); `m1/<region>` names; XML content, root, namespace or OID; `sha256.txt` content; any marker deeper than direct children; the numeric value as a date heuristic; file types or sizes. |
| 10 | Access denied | Unreadable 4-digit folder: B3 fail-open, unchanged. Unreadable other 1–6-digit folder: parent promoted with an `SU-?` child, access error retained, no "empty" observation. Unreadable `submissionunit.xml` file: presence comes from the listing, so it is still SU; the read failure surfaces later. |
| 11 | ZIP vs directory | Same predicate over the same entry model as B3 (children map of files and directories). Equivalent structure gives the same result. ZIP entry names are compared case-insensitively, as in B3. |
| 12 | Coexistence with B3 | Rule 2 keeps B3 for every folder that is not a v4 submission-unit folder. The only B3 behaviour change is that a `NNNN` folder whose v3 qualification relied solely on `submissionunit.xml` (or `sha256.txt` + module folders) becomes `SubmissionUnitFolder`. No accepted fixture is affected (0 marker hits). |
| 13 | Contract impact | **No breaking change.** Additive only: a new `SequenceLikeKind` value `SubmissionUnitFolder` and four additive observation codes (§7.2). `IsExactSequenceFolder = false` for v4 units keeps v3 BackboneXmlInventory from producing false missing-backbone findings. CEC already emits format-neutral `SequenceFolder`/`CtdModuleFolders` evidence for every sequence. `DossierCandidates` semantics are documented, not changed. |
| 14 | Files to change later | `engine/powershell51/eMAS.RepositoryDiscovery.psm1` (`Get-eMASRepositoryDiscoveryModel`: classifier, nested rule, sequence descriptors, observations); a new focused test `tests/repository-discovery-ectd4/Test-eMASRepositoryDiscoveryEctd4.ps1`; Wave 1E expectations under `tests/fixtures/repository-discovery-ectd4/`; builder under `tools/testdata/ms04-wave1e/`. **No** change to BackboneXmlInventory, ReferenceInventory/Resolution, CEC, the entry script or contracts. |
| 15 | Fixture/test wave | §8 |
| 16 | Regional limitations | §9 |

## 8. Fixture plan — Wave 1E (v4 physical discovery), SD-053 to SD-074 (design only)

**General rules:**
- Structure only; no claim of regulatory validity.
- `submissionunit.xml` is a **clearly labelled synthetic, well-formed stub**, e.g. `<!-- eMAS Wave1E synthetic discovery fixture: NOT a valid eCTD v4.0 message -->`. It is not a fake ICH/FDA/EU message, because discovery does not parse it.
- `sha256.txt` contains the real SHA-256 of that stub, so later checksum work has a consistent baseline.
- Module content is synthetic PDF markers.
- Builds are deterministic with Wave 1 ZIP conventions, plus a directory-source variant for V4-12 (access denied cannot be represented in a ZIP).
- **SD-028 / SD-029 stay reserved** for content-valid EU/US v4 fixtures, which need genuine official sample XML and a v4 backbone capability. **No v3 fixture is renamed into v4.**

| ID | Scenario | Profile intent | Sources | Tree (abridged) | Expected discovery | Deferred |
|---|---|---|---|---|---|---|
| SD-053 | V4-01 | FDA transmission | R14, R11 | `1/{su, sha, m1/, m3/}` | cand `""`; `1`=SU | region, application |
| SD-054 | V4-02 | FDA lifecycle archive | R6, R7, R14 | `app/1/{su, sha, m1/}`, `app/2/{su, sha}` | cand `app`; `1`, `2`=SU | reuse references |
| SD-055 | V4-03 | EU single unit | R18–R22 | `ema000123/1/{su, sha, m1/, m2/}` | cand `ema000123` | name never interpreted |
| SD-056 | V4-04 | neutral deep wrappers | R2, R19 | `Customer/Export/Set/ema000123/7/…` | 3 wrappers | — |
| SD-057 | V4-05 | two v4 containers | R14, R19 | `ema000123/1/…`, `nda123456/1/…` | 2 candidates, isolated | — |
| SD-058 | V4-06 | v3 dossier + v4 dossier | B3, R4 | `Legacy/0000…` (from SD-002 bytes, re-rooted) + `Modern/1/{su, sha}` | 2 candidates, mixed kinds | — |
| SD-059 | V4-07 | year folders | — | `Archive/2024/report.pdf`, `Archive/2023/notes.txt` | 0 candidates | — |
| SD-060 | V4-08 | numeric + arbitrary XML | — | `Archive/2024/data.xml`, `Data/3/export.xml` | 0 candidates | — |
| SD-061 | V4-09 | minimal unit | R6, R7 | `Pkg/12/su` | cand `Pkg`; `12`=SU | missing `sha256` (validation) |
| SD-062 | V4-10 | missing `sha256.txt` | R5, R11 | `Pkg/1/{su, m1/}` | SU | `eCTD4-060` later |
| SD-063 | V4-11 | missing `submissionunit.xml` | R5 | `Pkg/1/{sha, m1/}` | SU-d + observation | `eCTD4-059` later |
| SD-064 | V4-12 | unreadable unit folder (directory source) | B3 FO | `Pkg/5/` mode 000 | SU-? + access error | — |
| SD-065 | V4-13 | root-level unit | R14 | `3/{su, sha, m1/}` | cand `""` | — |
| SD-066 | V4-13b | unplaced root `submissionunit.xml` | R11 `eCTD4-063` | `{su, sha, m1/}` at root | 0 candidates (U3) | — |
| SD-067 | V4-14 | case variants | C3 | `Pkg/1/{SubmissionUnit.XML, SHA256.TXT, M1/}` | SU (detected) | exact-case conformance |
| SD-068 | V4-15 | malformed stub | — | `Pkg/1/{su (not well-formed), sha}` | SU | parse failure |
| SD-069 | V4-16 | v3→v4 transition | R10, C1 | `App/0000…0003` (v3) + `App/4/{su, sha}` | one cand, mixed kinds | lifecycle |
| SD-070 | V4-17 | four-digit v4 | R9 | `App/0999/index.xml…`, `App/1000/{su, sha}` | `1000`=SU, `0999`=v3 | — |
| SD-071 | V4-18 | leading zero | R3, R9 | `Pkg/0001/{su, sha}` | SU + non-canonical observation | `US-eCTD4-503`/`EU-065` later |
| SD-072 | V4-19 | EU grouped Scenario 1 | R23 (draft) | `fr0034g/{fr1762/3 (m1–m3), fr1011/156, fr0345/455}` | 3 candidates, wrapper `fr0034g` | cross-container reuse (U6) |
| SD-073 | V4-20/21 | out-of-range + conflicting markers | R9 | `Pkg/1234567/su`; `Pkg2/0001/{index.xml, su}` | 0 for 7-digit; `0001`=v3 + conflict observation | — |
| SD-074 | V4-22 | year wrapper above a v4 package | B3 | `Exports/2024/ema000123/1/…`, `Exports/2024/Archive/2019/a.pdf` | cand `Exports/2024/ema000123` | — |

**Tests later:**
- a focused v4 discovery harness, run for ZIP and directory sources;
- the full 8-suite Wave 1 run, root-level dossier, Wave1D, and the B3 focused test, all expected unchanged;
- an assertion that no `MissingCommonBackbone`/`MissingRegionalBackbone` is emitted for any SU folder;
- determinism by building twice.

## 9. Known regional limitations

- Only ICH, FDA and EU sources were reviewed. Other regions (CH, AU, JP, CA; catalogue SD-030 to SD-032) may define the first-level folder differently. The rule ignores first-level names, so it should tolerate them, but this is **unverified**.
- EU material is partly **draft** (C6), and grouping is "under review" (R23).
- The FDA M1 package v1.5.1, still supported, was not reviewed (C4).
- Discovery treats the FDA single-folder grouped submission (R15) and the EU multi-folder grouped transmission (R23) structurally. Their application semantics differ and are deferred.

## 10. Open questions

- **U1 — Damaged-unit fallback strength.** `sha256.txt` + module folder promotes a 1–6-digit folder without `submissionunit.xml`. Accept? The alternative is to require `submissionunit.xml`, which is simpler but loses damaged v4 units.
- **U2 — Fail-open for non-four-digit unreadable folders.** An unreadable `Photos/1/` would promote `Photos`. This is consistent with "unknown ≠ absent" but adds false-positive risk. Accept, or restrict fail-open to four-digit folders?
- **U3 — Unplaced `submissionunit.xml`.** One at the archive root, or in a non-numeric folder, promotes nothing and gives no observation. Should an additive observation be added?
- **U4 — Case.** Detection is case-insensitive (B3-consistent), while ICH and FDA reject mixed case (C3). Should a later validation capability report exact-case nonconformance?
- **U5 — Conflicting markers.** A folder with both `index.xml` and `submissionunit.xml` is kept on the v3 path plus an observation. Confirm the precedence.
- **U6 — Multi-dossier isolation vs EU grouped reuse.** EU Scenario 1 legitimately references files across application folders (R23). The current v3 isolation invariant (no cross-dossier resolution) would flag or miss these. A v4 ReferenceResolution design must decide this before v4 reference capabilities. It is out of scope for discovery.
- **U7 — Application identity.** Application identity needs a later XML-level capability, for example an `Applications` collection derived from `submissionunit.xml`. `DossierCandidates` should not be redefined to mean "application".
- **U8 — First v4 sequence number (C1).** ICH says `next available`; the EU says `1`. This doesn't affect discovery, but lifecycle and gap observations must not assume either.

## 11. Scope confirmation

- Report only. The only changed file is `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/CLAUDE.md`.
- No runtime, test, fixture, expectation, contract, FormatDetection or RegionDetection change.
- The source downloads, text extraction and rule simulator are scratch-only and not committed.
- Implementation requires a separate, user-approved task.
