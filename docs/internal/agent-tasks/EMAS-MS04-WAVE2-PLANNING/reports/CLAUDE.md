# Claude/Cursor Report — EMAS-MS04-WAVE2-PLANNING

**Status:** `REPORT PUBLISHED — DESIGN ONLY`
**Role:** Dossier-diversity fixture design
**Task base commit:** `58534391684d254abed4251e7f6deacd759e2b78`
**Author:** Claude (Cowork session)
**Analysis date:** 2026-10-05

This is the complete, previously produced pre-implementation design report, published without re-analysis.

- No repository file, fixture, module, test or expectation was created or modified during the analysis.
- Throwaway probe ZIPs (P1–P8 below) were built from SD-002 in a scratch directory outside the repository and run read-only through the accepted 8-capability chain to confirm feasibility.
- **Probe results are not expectations.** Fixture expectations must still be derived independently before any build (section G).

Three findings change the original plan:

1. **ID collision.** The accepted Sample Data Catalogue v1.1 already reserves `SD-021`…`SD-043` for Waves 2–5:
   - regions: US, Canada, UK, CH, AU, JP, SG;
   - formats: eCTD v4, NeeS, legacy CTD, unsupported schema;
   - contexts: ASMF, DMF;
   - ad-promo;
   - containers.

   This report therefore proposes `SD-044`…`SD-052`, labelled **Wave 1D (Dossier Diversity)**.

2. **Defect (accepted engine): a dossier at the archive root produces false missing-reference findings.**
   - Cause: `eMAS.ReferenceResolution.psm1` line 285, `$xmlRepositoryPath.Substring($dossierPath.Length + 1)`. With dossier path `""` it drops the first character (`0000/index.xml` → `000/index.xml`).
   - Effect: 93 of 94 references become `ResolvedAbsent`, giving **93 false `ReferenceTargetMissing` findings**, and checksum comparison is skipped for all of them.
   - This affects the Windows-qualified RC1.

3. **Defect (accepted engine): ClassificationEvidenceCollection silently writes 0 records for a root-level dossier but reports `Collected`.**
   - Cause: `eMAS.ClassificationEvidenceCollection.psm1`. The mandatory `[string] $DossierPath` (in `New-eMASCecDraft`) and `$ParentPath` (in `Get-eMASCecChildPath`) parameters reject an empty string. The error is not terminating, so coverage still reports `Collected`.

Neither defect is fixed by this task.

---

## A. Current fixture and evidence conventions inspected

**Fixture builds**
- All 19 Wave 1 fixtures were built by `.wave1-work/build_wave1.py` from `ARCHIVE_ROOT = "EXTEDORIN 50mg Tablets EU-FR"`.
- ZIP conventions:
  - fixed entry time `2026-10-04 12:00:00`;
  - every directory written as an explicit entry (stored, sorted by depth then name);
  - files deflated, sorted;
  - Unix permission attributes set;
  - no UTF-8 name flag, because all names are ASCII.
- Each fixture also has a `manifest.json` (base fixture, mutation, ground-truth Region/Format/Spec/Context, SHA-256).
- Expected results are written **before** the fixture is built: catalogue rule BR-12 and `expected-results/SD-xxx.json`.
- A frozen fixture is never edited in place (BR-15). Every fixture stays "Internal Test Material / Redistribution Status Unconfirmed" until permission is recorded (BR-16).
- BR-03 and BR-04: folder names are supporting evidence only, and regional XML must never be made up from memory.

**RepositoryDiscovery (read-only analysis)**
- **Dossier candidate rule:** any directory with at least one child directory named exactly `^\d{4}$`. Candidates nested under an accepted candidate's sequence folder are dropped, and the archive root (`""`) can itself be a candidate.
- **IDs:**
  - `DOS-nnnn` by ordinal sort of candidate paths;
  - `SEQ`, `XML`, `REF`, `FIL` numbered globally across the repository by path, not per dossier;
  - wrappers become `WRP-nnnn`, plus a `WrapperDepth` observation.
- **File-to-dossier assignment:** a file belongs to whichever candidate path it sits under (last match wins, which is the deepest when nested). Files outside every dossier get `DossierId = null`.
- **BackboneXmlInventory:** only looks at `<seq>/index.xml` and `<seq>/m1/eu/eu-regional.xml` per exact sequence folder, plus "Other" XML directly in a sequence or the dossier root.

**ClassificationEvidenceCollection (CEC)**
- 14 evidence types across Region / TechnicalFormat / SpecificationProfile / DossierContext.
- Strength Strong / Supporting / Weak, plus a `SourceTier`.
- `CandidateValue`, `Polarity` and `SourceRuleId` are always null.
- Records are ordered by dossier path, then sequence folder, then XML path, then type order.

**CEC harness and expectations**
- Records are compared as a full multiset.
- Invariance projections come in two flavours: Full, and DossierRelative (which excludes `DossierRootPath`).
- The harness hard-codes SD-001/002/004/005… sample IDs in its extra checks. It **cannot** simply be pointed at a new manifest; Wave 1D needs its own harness.

**Probe results** (SD-002 content, scratch only, read-only engine run)

| Probe | Dossiers / seqs | CE records | Result |
|---|---|---:|---|
| P1 neutral `ProductABC` | 1 / 5 | 86 | identical to SD-002 apart from the dossier root value |
| P2 `FDA-US-ASMF` | 1 / 5 | 86 | identical apart from the dossier root value |
| P3 `CustomerExport/ArchiveSet/ProductABC` | 1 / 5 | 86 | identical; extra `WrapperDepth` (depth 2) |
| P4 two copies | 2 / 10 | 172 | 86 per dossier; 0 references resolved across dossiers; ID ranges contiguous per dossier |
| P4b nested dossier in `Backup/` | 2 / 10 | 172 | isolated |
| P5 unrelated docs + decoy `Misc/m1/eu/eu-regional.xml` | 1 / 5 | 86 | decoy ignored; unrelated files `DossierId = null`; FIL IDs shift |
| P5b `Archive/2019/annual-report.pdf` | **2** / 6 | 91 | **false candidate** `Archive` (DOS-0001); real dossier becomes DOS-0002; `MissingCommonBackbone`/`MissingRegionalBackbone` on `Archive/2019` |
| P6 `Product ABC (Copy 2) & Co_v1.2` | 1 / 5 | 86 | identical apart from the dossier root value |
| P7 root-level (no dossier folder) | 1 / 5 | **0** | **defects 2 and 3** |
| P8 XML inside `ProductABC/0000-Working/` | 1 / 5 | 86 | ignored correctly |

---

## B. Proposed Wave 1D fixture matrix

All fixtures use **SD-002 content byte-for-byte**, except SD-047, whose second dossier uses SD-010 content. Only paths and added unrelated files change. Every number below must be fixed independently before building (section G); the probes only show feasibility.

| New ID (originally proposed as) | Name | Dossiers | Seqs | CE records | Collection / Completion | Before FormatDetection |
|---|---|---:|---:|---:|---|---|
| SD-044 (SD-021) | Neutral dossier root `ProductABC` | 1 | 5 | 86 | Collected / Completed | **Mandatory** |
| SD-045 (SD-022) | Misleading root `FDA-US-ASMF` | 1 | 5 | 86 | Collected / Completed | **Mandatory** |
| SD-046 (SD-023) | Neutral wrappers `CustomerExport/ArchiveSet/ProductABC` | 1 | 5 | 86 | Collected / Completed | **Mandatory** |
| SD-047 (SD-024) | Two dossiers, **asymmetric** (A = SD-002 profile, B = SD-010 profile) | 2 | 9 | 155 | Collected / Completed | **Mandatory** |
| SD-048 (SD-025) | Dossier + unrelated content (no 4-digit names) | 1 | 5 | 86 | Collected / Completed | **Mandatory** |
| SD-049 (SD-026) | Safe ASCII naming variation | 1 | 5 | 86 | Collected / Completed | Recommended |
| **SD-050 (new)** | Dossier at the archive root (no dossier folder) | 1 | 5 | 86 | Collected / Completed | **Mandatory, blocked by defects 2 and 3** |
| **SD-051 (new)** | Unrelated year folder `Archive/2019/` | 2 (current) | 6 | 91 (current) | Collected / Completed | **Mandatory, needs a decision** (J-4) |
| SD-052 (new) | Nested dossier inside another dossier's `Backup/` | 2 | 10 | 172 | Collected / Completed | Optional / later |

---

## C. Detailed design per fixture

Common to all fixtures unless stated:
- **Parent:** SD-002.
- **Byte-identical:** every file below each `000n/` folder, all 248 entries of the SD-002 dossier subtree re-rooted only.
- **CollectionCoverage for CEC:** one Collected row per backbone XML, repository row `Collected`. All other capability coverage is unchanged from SD-002.
- **References:** 94 per SD-002-profile dossier (93 `Matched`, 1 no-href `NotApplicable`). 0 `ReferenceTargetMissing`, 0 `DeclaredChecksumMismatch`.
- **Strength / tier:** as in Wave 1. Structured XML is Strong; declarations are Supporting; official paths and `m1/<folder>` are Supporting; `CtdModuleFolders` and `SequenceFolder` are Weak; `DossierRootPath` is Weak (FolderNameHeuristic).

### SD-044 — Neutral dossier root

| # | Item | Design |
|---|---|---|
| 1–3 | ID / purpose / parent | SD-044. Prove that no evidence depends on the `EXTEDORIN…EU-FR` product or "EU-FR" text. Parent SD-002. |
| 4–5 | Mutation | Rename the root `EXTEDORIN 50mg Tablets EU-FR/` to `ProductABC/`. No other change. |
| 6 | Byte-identical | All file contents. Entry count 248. |
| 7–9 | Discovery | 1 candidate DOS-0001 `ProductABC`; 5 exact sequences 0000–0004; only `ExactSequenceChildrenObserved`. |
| 10–12 | CE effect | Only the `DossierRootPath` value (`ProductABC`) and the `RelativePath` prefixes change. The dossier-relative projection is identical to SD-002 (85 records). |
| 13–15 | Strength / folder / XML | Folder name gives one Weak `DossierContext` record. Structured XML is as SD-002 (see SD-045). |
| 16–17 | Coverage / completion | Collected / Completed. |
| 18 | Negative assertions | No record whose value contains "EXTEDORIN" or "EU-FR". No `CandidateValue`. No Region or TechnicalFormat record from the folder. |
| 19 | Derivation | Section G (transform derivation from SD-002 + oracle derivation from the built ZIP). |
| 20 | Bug caught | Region/format logic reading the product folder (e.g. `EU-FR` → EU). |

### SD-045 — Misleading dossier root (special focus)

Mutation: rename the root to `FDA-US-ASMF/`. Everything else is as SD-044.

Expected evidence (5 sequences; per-sequence values in sequence order 0000→0004):

| Evidence | Expected |
|---|---|
| `DossierRootPath` | **1** record: value `FDA-US-ASMF`, `DossierContext`, **Weak**, `FolderNameHeuristic`, CandidateValue/Polarity/SourceRuleId null |
| `Module1RegionalFolder` | 5 × `["eu"]`, Region, Supporting, OfficialPhysicalPath. The physical `m1/eu` is unchanged; there is no `m1/us`. |
| `XmlRootElement` | 5 × `ectd` (TechnicalFormat) and 5 × `eu-backbone` (Region); Strong, StructuredXml |
| `XmlNamespace` | 5 × `http://www.ich.org/ectd` (TechnicalFormat) and 5 × `http://europa.eu.int` (Region); Strong |
| `DtdVersion` (SpecificationProfile, Strong) | common: 5 × `3.2`; regional: `2.0`, `3.0.1`, `3.0.1`, `3.0.1`, `3.1` (verbatim) |
| `DocumentTypeName` | 5 × `ectd:ectd` (TechnicalFormat) and 5 × `eu:eu-backbone` (Region); Supporting, BackboneDeclaration |
| `DtdSystemIdentifier` | 5 × `util/dtd/ich-ectd-3-2.dtd` and 5 × `../../util/dtd/eu-regional.dtd`; SpecificationProfile, Supporting |

What the test proves:
- "FDA", "US" and "ASMF" appear **only** in the `DossierRootPath` value and the `RelativePath` prefixes.
- All Strong and Supporting records are identical to SD-002 and SD-044. Proven by byte equality of the dossier-relative projection.
- A future interpreter therefore has conflicting Weak and Strong evidence, and must be able to prefer the structured evidence. That interpretation is **not** implemented here.
- ASMF is not technical-format evidence. No `TechnicalFormat` record contains "ASMF"; the token sits only under `DossierContext`.
- Bug caught: folder-name keyword matching overriding XML (FDA → US, ASMF → format).

### SD-046 — Neutral arbitrary wrappers

- **Mutation:** prefix the SD-044 dossier with `CustomerExport/ArchiveSet/`, giving dossier root `CustomerExport/ArchiveSet/ProductABC`. Wrapper names contain no region tokens; SD-016 already covers a wrapper containing `EU`.
- **Discovery:** 1 dossier; wrappers `WRP-0001 CustomerExport` and `WRP-0002 CustomerExport/ArchiveSet`; an extra `WrapperDepth` observation with Depth 2. Its ID is `OBS-0002`, which needs confirming in the expectations.
- **CE:** 86 records, dossier-relative identical to SD-044. `DossierRootPath` value is the full path `CustomerExport/ArchiveSet/ProductABC`.
- **Coverage / completion:** Collected / Completed.
- **Negative assertions:** wrapper names do not appear in any record except `DossierRootPath` and `RelativePath`. No extra dossier candidate for a wrapper.
- **Bug caught:** wrapper depth or wrapper names used as classification signals; the dossier root chosen at the wrong level.

### SD-047 — Two dossiers, asymmetric

The second dossier should **not** be invented regulatory content. I recommend:
- **A** = `ProductABC/` with SD-002 content (5 sequences);
- **B** = `ProductXYZ/` with the **SD-010 content** (sequences 0000, 0002, 0003, 0004).

Both are genuine EXTEDORIN-derived EU v3 profiles. The asymmetry (5 vs 4 sequences, 94 vs 87 references, 86 vs 69 CE records) means any evidence leaking from one dossier to the other shows up in the counts. With two identical copies, a leak could go unnoticed. Both dossiers share the same technical profile (EU eCTD v3, historical EU M1), and the design says so explicitly; true cross-profile diversity belongs to the catalogue's region wave (SD-021+), with genuine regional XML.

| Item | Expected |
|---|---|
| Dossiers | DOS-0001 `ProductABC`, DOS-0002 `ProductXYZ` (ordinal path sort) |
| Sequences | 9: SEQ-0001–0005 (A), SEQ-0006–0009 (B) |
| XML | 18: XML-0001–0010 (A), XML-0011–0018 (B) |
| References | 181: REF-0001–0094 (A), REF-0095–0181 (B); 179 Matched, 2 NotApplicable |
| CE | 155: EVD-0001–0086 (A), EVD-0087–0155 (B) |
| Isolation | every reference's `TargetFileId` belongs to a file of the same `DossierId`; every CE record's `DossierId`/`SequenceId`/`XmlId` is consistent; B's dossier-relative projection equals SD-010's |
| Observations | `ExactSequenceChildrenObserved` × 2. B also carries any numeric-gap observation that SD-010 has. |
| Coverage / completion | Collected / Completed |
| Negative assertions | no `XmlId` or `SequenceId` used under the wrong `DossierId`; no A paths inside B records; no merged evidence |

Bug caught: global lookup tables keyed by dossier-relative path, ID collisions, evidence merged across dossiers.

Identical-copy variant: optional, not required, because the probes already showed 0 references resolved across dossiers.

### SD-048 — Valid dossier plus unrelated content

- **Mutation:** SD-044 plus the following unrelated files (none uses a `^\d{4}$` folder name):
  - `README.txt`;
  - `Customer Notes/meeting-notes.pdf` (minimal PDF marker bytes, clearly synthetic);
  - `Archive/old-export-log.txt`;
  - **decoy** `Misc/m1/eu/eu-regional.xml` (a trivial `<note/>`, not regional vocabulary, per BR-04);
  - inside the dossier root, `ProductABC/Working Notes/todo.txt` and `ProductABC/Working Notes/scan.pdf`.
- **Discovery:** still 1 dossier and 5 sequences. Unrelated files outside the dossier get `DossierId = null`.
- **XML:** the decoy XML is **not** in `XmlDocuments` because it is outside any dossier.
- **CE:** 86 records, dossier-relative identical to SD-044. `Working Notes` produces no evidence because it is not a sequence.
- **Coverage / completion:** Collected / Completed.
- **Invariance warning:** **FIL IDs shift** (`Archive/…` and `Customer Notes/…` sort before `ProductABC/…`). Invariance checks must ignore FileId and TargetFileId.
- **Bug caught:** scanning everything for `m1/eu` patterns; treating any PDF or XML as dossier evidence.

### SD-049 — Safe naming variation

- **Mutation:** root becomes `Product ABC (Copy 2) & Co_v1.2/`, using only ASCII: space, parentheses, ampersand, dots, underscore, hyphen.
- **Excluded:** no `..`, slashes, colons, drive letters, UNC, URL or reserved Windows names; no trailing dot or space; no names that differ only by case.
- **CE:** 86 records; `DossierRootPath` value equals the string byte-for-byte; paths keep the same casing and spaces.
- **Coverage / completion:** Collected / Completed.
- **Bug caught:** fragile path normalisation; the `& (` characters breaking PowerShell path handling (e.g. `-Path` wildcard expansion instead of `-LiteralPath`); trimming of spaces.
- **Unicode** (e.g. `Prüfung`) is optional and later. It needs the ZIP UTF-8 name flag and a check on Windows PowerShell 5.1.

### SD-050 — Dossier at the archive root (new)

- **Purpose:** customers often ZIP the sequences directly. In that case there is **no folder name evidence at all**, which is the strongest proof that classification must not need one.
- **Mutation:** remove the root folder, so `0000/…0004/` sit at the ZIP root. File bytes are identical.

**Expected (correct semantics):**
- 1 dossier, DOS-0001, RelativePath `""`, 5 sequences;
- 94 references, 93 `ResolvedPresent` with checksum `Matched`, **0** `ReferenceTargetMissing`;
- CE: 86 records, with `DossierRootPath` value `""`. Whether it should be `""` or the record omitted is decision J-3;
- Collected / Completed.

**Current behaviour (probe P7):**
- 93 references `ResolvedAbsent` with `NormalizedTargetPath` such as `000/m1/eu/eu-regional.xml`;
- 93 false `ReferenceTargetMissing` findings;
- CE writes 0 records while coverage says `Collected`.

This fixture will **fail until defects 2 and 3 are fixed**. It is the most valuable fixture in the wave.

### SD-051 — Unrelated year-named folder (new)

- **Mutation:** SD-044 plus `Archive/2019/annual-report.pdf`.
- **Current behaviour (probe P5b):**
  - `Archive` becomes candidate **DOS-0001** and the real dossier shifts to **DOS-0002**;
  - `Archive/2019` becomes an "exact sequence";
  - `MissingCommonBackbone` and `MissingRegionalBackbone` observations appear on it;
  - CE gives `Archive` 5 Weak/Supporting records (DossierRootPath `Archive`, SequenceFolder `2019`, `CtdModuleFolders []`, both presences `false`);
  - the real dossier still has 86 correct records.
- **Purpose:**
  - record this heuristic before FormatDetection;
  - require that a future FormatDetection does **not** classify a candidate with no backbone as eCTD;
  - show that IDs depend on unrelated folder names.
- **Needs a product decision (J-4):** keep this as an accepted characterization, or treat it as a RepositoryDiscovery defect.

### SD-052 — Nested dossier (optional)

- **Mutation:** `Export/ProductABC/` (SD-002 content) plus `Export/ProductABC/Backup/ProductOLD/` (SD-002 content).
- **Current behaviour:** 2 dossiers, files assigned to the deepest candidate, 172 CE records, isolated.
- **Note:** ProductABC is listed as a wrapper of ProductOLD.
- Later priority.

---

## D. Expected ClassificationEvidence deltas (against SD-002 at 86 records)

| Fixture | Changes | Unchanged |
|---|---|---|
| SD-044 / 045 / 049 | `DossierRootPath` value; `RelativePath` prefix on all 86 | all 85 other records, dossier-relative |
| SD-046 | as above; root value is the full wrapper path | 85 records |
| SD-047 | +69 records for DOS-0002 (= SD-010 profile) | A = 86 identical to SD-044 (IDs too); B dossier-relative = SD-010 |
| SD-048 | `DossierRootPath`; FIL IDs elsewhere (not in CE) | 85 records |
| SD-050 | `DossierRootPath` `""` (decision); `RelativePath` without prefix | 85 records |
| SD-051 | +5 records for `Archive` (current behaviour); real dossier's DossierId/SequenceId/XmlId shift | real dossier's 85 records, ID-free projection |

Counts by dimension for an SD-002-profile dossier: Region 30, TechnicalFormat 35, SpecificationProfile 20, DossierContext 1.

## E. Invariants

1. Structured XML records (root, namespace, DTD version, DOCTYPE name, system id) for every SD-002-profile dossier equal SD-002's, value for value, in every fixture.
2. Folder or wrapper text appears only in `DossierRootPath.ObservedValue` and in `RelativePath`.
3. `CandidateValue`, `Polarity` and `SourceRuleId` are null in every record. Capabilities contain no RegionDetection or FormatDetection.
4. Per dossier: every `SequenceId`/`XmlId` on a CE record belongs to the record's `DossierId`, and every reference target file belongs to the same dossier.
5. Frozen Wave 1 fixtures and `WAVE1_FREEZE_MANIFEST.csv` stay untouched; Wave 1D gets its own manifest.
6. Comparison projections must ignore `FileId`, `TargetFileId` and, for SD-051, `DossierId`/`SequenceId`/`XmlId` (because IDs shift with unrelated names). They compare the dossier-relative path, type, value, dimension, strength and tier.

## F. Negative assertions

- No `Region`, `TechnicalFormat`, `Detected*`, `Classification`, `PrimaryRegion` or `Confidence` fields; no RAG or severity.
- No record whose `EvidenceType` is anything other than `DossierRootPath` carries the tokens `FDA`, `US`, `ASMF`, `EU-FR` or `EXTEDORIN`, other than in `RelativePath`.
- No evidence from the decoy `Misc/m1/eu/eu-regional.xml`, `Working Notes/*` or `README.txt`.
- No `ReferenceTargetMissing` and no `DeclaredChecksumMismatch` in any fixture. SD-050 is the critical case.
- A CE result with 0 records and `Collected` is only valid for no-dossier inputs (as SD-020). Any fixture with a dossier must have more than 0 records.

## G. Independent expectation derivation

Follow the Wave 1 rules (BR-12: expectations before the build; nothing taken from the module under test).

1. **Two independent derivations, which must agree:**
   - **Transform derivation:** take the accepted SD-002 (and SD-010) CEC expectation records and apply only the planned path change. Expected dossier-relative records equal the source records.
   - **Oracle derivation:** extend `independent-oracle/oracle.py` so it parses XML directly from the **built fixture ZIP** and derives the dossier root and sequences directly from ZIP entry paths. That replaces the Wave 1 reliance on accepted RepositoryDiscovery output, and gives a fully independent check of discovery, including the `""` root and multiple dossiers. It then applies the CEC mapping table.
2. **Counts for other capabilities** (references, matched, missing) come from the Wave 1 per-fixture expectations of the source profile, multiplied or combined as needed. Cross-dossier isolation is checked by path-prefix rules in the oracle.
3. **For SD-050 and SD-051,** the expected results state the correct or decided semantics, not current output. SD-050's 93 references must be ResolvedPresent.
4. The build script records SHA-256 of every source subtree before and after, and checks that file bytes are identical (as Wave 1's verification step did).

## H. Multi-dossier analysis

- **DossierId:** deterministic `DOS-nnnn` by ordinal sort of candidate paths, so it depends on names. An unrelated `Archive/` sorts before `ProductABC/` and renumbers the real dossier (SD-051).
- **Sequence → dossier:** taken directly from the candidate that owns the sequence folder. Correct and isolated (P4, P4b).
- **SEQ, XML, REF, FIL IDs:** repository-global ordinals by path, not dossier-scoped. They are contiguous per dossier only because paths sort by dossier. Not ambiguous, because every record also carries its `DossierId`.
- **ReferenceResolution:** dossier-scoped (`dossierPath + normalised target`, then a global path lookup). P4 showed **0 references resolved across dossiers**, even for identical copies. **Except for a root dossier `""`**, which is defect 2.
- **CEC:** isolated via `DossierId` and the dossier path in its sort key. P4 and P4b gave per-dossier projections identical to single-dossier runs. **Except for a root dossier `""`**, which is defect 3.
- **Contract:** the contract can represent multiple dossiers (`dossierCandidates[]`, DossierId on every record). The coverage rows for CEC and the other capabilities are per repository, not per dossier, so "Partial" cannot say which dossier had the gap. That is a limitation, not a defect.
- **Nested dossiers:** files go to the deepest candidate, and the parent dossier is reported as a wrapper of the child. Acceptable, but undocumented.
- **Real limitations found:**
  - root-level dossier: defects 2 and 3;
  - year-named or other 4-digit unrelated folders create false dossier candidates and false missing-backbone observations, and renumber the real dossier (SD-051);
  - coverage cannot attribute a gap to a dossier.

## I. Files that would eventually be created or updated

Nothing has been created by this task.

**New fixture area** (Wave 1 untouched):
- `02_Working/MS-04-PreSales-Wave1D/`
  - `fixtures/SD-044…SD-052/fixture.zip` and `manifest.json`
  - `expected-results/SD-0xx.json`
  - `manifests/fixtures.csv`, `manifests/fixtures.json`
  - `verification/WAVE1D_VERIFICATION_REPORT.md`
  - `README.md`
- `.wave1d-work/build_wave1d.py` (reuses Wave 1 ZIP conventions; reads SD-002 and SD-010 frozen ZIPs read-only)
- `…/wave1d-freeze-v1.0/WAVE1D_FREEZE_MANIFEST.csv`

**Catalogue:** `eMAS_MS04_PreSales_Sample_Data_Catalogue_v1.2.xlsx` (new rows SD-044…052 and a change-history entry; v1.1 kept).

**Tests** (existing harnesses unchanged):
- `tests/dossier-diversity/Test-eMASDossierDiversity.ps1`
- `tests/fixtures/dossier-diversity/wave1d-expectations.json`
- an extended oracle under the Wave 1D output folder

**Docs:**
- `DOSSIER_DIVERSITY_FIXTURE_DESIGN.md`
- `…_TEST_RESULTS.md` and the summary JSON

**Separate defect tasks** (not this wave):
- `eMAS.ReferenceResolution.psm1` line 285 (empty dossier path);
- `eMAS.ClassificationEvidenceCollection.psm1` (`DossierPath` / `ParentPath` parameters rejecting empty strings, and non-terminating draft errors).

## J. Risks and open decisions

1. **ID allocation:** use SD-044+ under the catalogue, or a separate prefix (e.g. `DD-001`)? I recommend SD-044+ with a catalogue v1.2 update.
2. **Defects 2 and 3** affect the Windows-qualified RC1: a customer export zipped at sequence level would show about 93 false missing-reference findings. Decide whether to log this as an RC1 known issue now, and when to fix it. A fix must be followed by the full Wave 1 regression and a new Windows 5.1 run.
3. **Root-level `DossierRootPath`:** emit it with `ObservedValue ""` (recommended; it keeps counts stable and states that no folder evidence exists), or omit it.
4. **SD-051 semantics:** accept a 4-digit unrelated folder as a dossier candidate (documented heuristic), or tighten RepositoryDiscovery, for example by requiring backbone or `m1`–`m5` presence. Either way, FormatDetection must not classify a candidate with no backbone.
5. **Provenance:** all Wave 1D fixtures are EXTEDORIN-derived and inherit "redistribution unconfirmed". They are internal only.
6. **Windows paths:** keep wrapper and name lengths short (MAX_PATH 260 on Windows 5.1), and avoid case-only differences and Unicode in mandatory fixtures.
7. **FIL and ID drift** with unrelated content means invariance must use ID-free projections. Otherwise the tests would be brittle.
8. **Second-dossier diversity** is limited to the EU v3 profile until genuine US/CA/etc. material exists (catalogue SD-021+, BR-04).

## K. Recommendation

**Mandatory before FormatDetection:**
- SD-044 (neutral root)
- SD-045 (misleading root)
- SD-046 (neutral wrappers)
- SD-047 (asymmetric two dossiers)
- SD-048 (unrelated content)
- **SD-050 (root-level dossier)** — requires defects 2 and 3 to be fixed first, as a separate approved task
- **SD-051 (year folder)** — once decision J-4 is made, so FormatDetection has a defined rule for candidates with no backbone

**Recommended:** SD-049 (safe ASCII naming).

**Optional / later:**
- SD-052 (nested dossier)
- an identical-copy multi-dossier variant
- a Unicode naming variant
- every real cross-region diversity fixture (catalogue SD-021…027, which need genuine regional XML)

**Suggested next step:** approve the ID range and decisions J-2, J-3 and J-4, then open a separate defect task for ReferenceResolution and CEC with empty dossier paths, before building Wave 1D.

## Scope confirmation

- Design only; no fixtures implemented.
- No FormatDetection or RegionDetection implemented.
- No accepted PowerShell module, test, expectation or frozen Wave 1 fixture modified.
- This publication changes only `docs/internal/agent-tasks/EMAS-MS04-WAVE2-PLANNING/reports/CLAUDE.md`.
