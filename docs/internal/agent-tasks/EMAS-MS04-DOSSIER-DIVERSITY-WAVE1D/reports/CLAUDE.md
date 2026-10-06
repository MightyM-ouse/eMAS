# Claude Report — EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D

**Status:** `READY_FOR_REVIEW — MAC BASELINE (WINDOWS PS 5.1 DEFERRED)`
**Agent:** Claude (single implementation worker)
**Branch:** `implementation/emas-ms04-dossier-diversity-wave1d`
**Based on:** `coordination/emas-ms04-dossier-diversity-wave1d` @ `a57c453e21c52a2049bd96edc3bfbd97f7f8512a`, which contains authoritative base `793e065db17fed043ea95f9494f0e5f1458f0b72` (root-level dossier fix)
**Date:** 2026-10-06
**Platform:** macOS (Darwin 25.6.0, arm64), PowerShell 7.5.2 (Core), Python 3.14.4. This is **not** Windows PowerShell 5.1 qualification.

## Summary

| Item | Result |
|---|---|
| Baseline gate (8 Wave 1 suites, 19 frozen fixtures, before any change) | **PASS** 8/8, 275 checks, 0 fail |
| Fixtures generated | SD-044, SD-045, SD-046, SD-047, SD-048, SD-049, SD-050 (normative); SD-051 (characterization) |
| SD-052 nested dossier | Deferred, not built (per TASK.md) |
| Expectations | Transform-derived before build; independent oracle **AGREE 8/8** |
| Determinism | Two clean builds byte-identical; package built twice byte-identical |
| Wave1D Mac regression (composed 8-capability chain) | **PASS 60/60**; SD-051 `MATCHES_RECORDED` |
| Wave 1 regression after build | **PASS** 8/8, 275 checks, 0 fail |
| Root-level dossier harness after build | **PASS** 3/3 |
| Wave 1 package, freeze manifest, 19 fixtures, 8 expectation files | Unchanged (hashes identical before and after) |
| Runtime / engine / entry script / RepositoryDiscovery changes | **None** |
| New runtime defect found | **None** |

Wave1D package: `eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1.zip`, SHA-256 **`c99841179e6c168d1f81a967ff4a58ba5383d269735d68e6fef0857181ac2bec`** (42,647,618 bytes). Its internal `PACKAGE_MANIFEST.csv` has SHA-256 `88b0f0dc9d6fcf77410ea66f0687dcaf40a455c39cdbe59ac17c247e3efc52b3`. The package is stored in the controlled Mac workspace (`packages/`, outside Git), next to the Wave 1 packages. It is not committed, because Wave 1 binaries are not committed either.

---

## 1. Baseline gate

1. **Lineage:** `793e065` is an ancestor of the branch base (`git merge-base --is-ancestor`).
2. **RC1 baseline:** the 8 capability modules, `eMAS.SafeXml.ps1`, 8 harnesses and 8 expectation files are present (materialized in `dac1664`, root-level fix in `793e065`).
3. **Wave 1 package:** `eMAS_MS04_PreSales_Wave1_TestData_v1.zip` SHA-256 `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7`, matching the recorded value. `WAVE1_FREEZE_MANIFEST.csv` SHA-256 is `367da81d07ee2f4770cdd3f86e157282f237b01c9d2debac64f81490bd6ced56`.
4. **8 suites before any change:**

| Suite | Exit | PASS | FAIL |
|---|---:|---:|---:|
| repository-discovery | 0 | 15 | 0 |
| backbone-xml-inventory | 0 | 24 | 0 |
| reference-inventory | 0 | 30 | 0 |
| reference-resolution | 0 | 33 | 0 |
| missing-reference-interpretation | 0 | 35 | 0 |
| declared-checksum-comparison | 0 | 39 | 0 |
| checksum-mismatch-interpretation | 0 | 56 | 0 |
| classification-evidence-collection | 0 | 43 | 0 |

5. **Unchanged-state record:** the hashes of the Wave 1 ZIP, the freeze manifest, the 19 fixture ZIPs and the 8 `wave1-expectations.json` files were recorded before any work (29 entries). They are compared after the build in section 7.

## 2. Fixture matrix

All dossier bytes come from the frozen Wave 1 SD-002 (`29b0fae0…e7e6`) and SD-010 (`c6df47a4…9bfc`). Both are verified against `WAVE1_FREEZE_MANIFEST.csv` before they are read. Only container paths change. SD-048 and SD-051 add clearly synthetic unrelated files (a text marker, a PDF marker, and a decoy `<note/>` XML that is not regional vocabulary). No non-EU regulatory XML was created.

| ID | Kind | Source | Layout / mutation | Entries | Files | ZIP SHA-256 |
|---|---|---|---|---:|---:|---|
| SD-044 | Normative | SD-002 | root `ProductABC/` | 248 | 131 | `d7cc608f827a7359b47ce01ffea6dde35b06fa70a7605d1f9d0d0d38cf5a7da5` |
| SD-045 | Normative | SD-002 | root `FDA-US-ASMF/` | 248 | 131 | `1ee82116dc91274323b5a1db157e9e30b55e040fe66c0a1ab097d10226210697` |
| SD-046 | Normative | SD-002 | `CustomerExport/ArchiveSet/ProductABC/` | 250 | 131 | `4cf0109c2f39450ed5ee8728e2f239c16d45f964ae725b729b5ec8e5783e5ffc` |
| SD-047 | Normative | SD-002 + SD-010 | `ProductABC/` (5 seq) + `ProductXYZ/` (4 seq) | 465 | 248 | `e2a2a4639cff9cec6c54181d695d67d66bc488308ac395eef7bfd5aa3863bf07` |
| SD-048 | Normative | SD-002 | SD-044 + `README.txt`, `Customer Notes/meeting-notes.pdf`, `Archive/old-export-log.txt`, decoy `Misc/m1/eu/eu-regional.xml`, `ProductABC/Working Notes/{todo.txt,scan.pdf}` | 260 | 137 | `262fbcb3afe732cd94482f13d99fe80f1617eef0b506aff0f3728d4daa4e1cbf` |
| SD-049 | Normative | SD-002 | root `Product ABC (Copy 2) & Co_v1.2/` | 248 | 131 | `e73843fe8e04c8268d6651a23da3fe0e3b7ce49b51a977f00482aa5749ee1dc6` |
| SD-050 | Normative | SD-002 | sequences `0000`–`0004` at the ZIP root | 247 | 131 | `b827c1a6b8e96a58875cab119d551e5dd29374ddfcff59e7a3b3dde2cc8de96a` |
| SD-051 | **Characterization** | SD-002 | SD-044 + `Archive/2019/annual-report.pdf` | 251 | 132 | `e2c6d859424932a50153c18d06bd23724645bebef06c97ec4c147e6157712ebe` |

Freeze manifest (repository copy): `tests/fixtures/dossier-diversity/WAVE1D_FREEZE_MANIFEST.csv`, SHA-256 `f9a18813a23c0749459c5138950e28e99fb828ac0599152b43302001856db460`. It has these columns: ID, kind, purpose, source fixture(s) and their SHA-256, mutation, entry count, file count, ZIP SHA-256, size and status. Status is `FROZEN`, or `FROZEN_CHARACTERIZATION` for SD-051.

**Build controls:**
- Wave 1 ZIP convention: fixed entry time `2026-10-04 12:00:00`; explicit stored directory entries sorted by depth then name; deflated files sorted by name; Unix `0755`/`0644` attributes. `create_system` is pinned to Unix.
- No wall-clock timestamps in any output.
- Every written ZIP is re-read and each dossier file is compared byte-for-byte with its source.
- Names are checked:
  - ASCII only;
  - no `..`, backslash, colon or leading slash;
  - no empty segment, and no trailing dot or space;
  - no reserved Windows device names;
  - no case-only collisions.

## 3. Expectation derivation (independent, before freeze)

**Path 1, transform derivation** (`tools/testdata/ms04-wave1d/derive_expectations.py`):
- Reads only the 8 accepted `tests/fixtures/*/wave1-expectations.json` files (their SHA-256s are recorded in `derivationSources`) and the declarative spec.
- Per dossier it copies the accepted SD-002 or SD-010 facts:
  - sequences and parsed backbone XML set;
  - reference, href, common and regional counts, plus per-XML counts;
  - resolution counts;
  - checksum counts;
  - missing-reference and mismatch counts;
  - the full classification-evidence record multiset.
- The only change is the `DossierRootPath` value, set to the new root.
- Discovery expectations (candidate roots, wrapper ancestors) follow from the planned roots.
- **SD-010 reference counts:** the accepted ReferenceInventory file has no SD-010 entry. SD-010 is accepted as "SD-002 with sequence 0001 removed", so its counts are SD-002's accepted per-XML baseline rows for sequences 0000 and 0002–0004: 87 references, 87 hrefs, 67 common and 20 regional. The total is asserted against the accepted ReferenceResolution count (87).
- Generated **before any Wave1D fixture existed**.

**Path 2, independent oracle** (`tools/testdata/ms04-wave1d/oracle_wave1d.py`):
- Uses only Python `zipfile`, `xml.etree` and `hashlib` over the built ZIP bytes. It does not import the spec, read scanner output or call eMAS modules.
- It derives dossier candidates and wrappers from ZIP paths using the four-digit-child rule, and owning dossiers for every file.
- From the XML it derives the backbone documents and their structured facts, the leaf references with xlink hrefs resolved inside the owning dossier, and the MD5 checksum comparison.
- It then builds the classification-evidence records with the accepted type table.
- **Calibration:** run on the frozen Wave 1 SD-001, SD-002, SD-010, SD-016 (wrappers) and SD-020 (no dossier), it reproduces the accepted Wave 1 expectations exactly. All 5 MATCH.

**Agreement:** `check` compares the oracle's results with the transform expectations for every fixture. The result is **AGREE for all 8** on the candidate build, and again on the frozen build.

**One recorded correction.** The first transform output (SHA-256 `8c9b340a0dc1b74d7abf757624175f23527b48fdd1eb376e120e4871538b8876`) disagreed with the oracle on exactly one assertion:
- It said `Archive/2019/annual-report.pdf` in SD-051 must belong to *no* dossier. That encodes a discovery-policy decision, which TASK.md forbids for SD-051.
- The oracle, applying the current heuristic, shows the file belongs to the `Archive` candidate.

The assertion was narrowed to the actual normative intent: the file must not belong to the genuine dossier (`ProductABC`). Which heuristic candidate owns it became characterization. Nothing else changed (one JSON key in one fixture); final expectations are `669848e35479f9e2e4ef8fc9c3a5d5197c3fc59db38fe3183c6e939f103bdd9c`. This happened between the two derivations, before the scanner had been run on any Wave1D fixture, so no expectation was tuned to scanner output.

## 4. Dedicated Wave1D harness

`tests/dossier-diversity/Test-eMASDossierDiversity.ps1` runs the **composed accepted 8-capability chain** for every fixture: the entry script `scripts/eMAS-PreSalesAssessment.ps1` with `-IncludeClassificationEvidenceCollection`. It reloads the persisted contract JSON before checking.

**Gates and global checks:**
- **Freeze gate** before and after the run: every fixture's SHA-256 against `WAVE1D_FREEZE_MANIFEST.csv`. The fixture IDs in the manifest and the expectations must match.
- **Every fixture:**
  - contract ID;
  - the exact 8-capability chain, with no RegionDetection or FormatDetection;
  - no prohibited observation codes;
  - `CandidateValue`, `Polarity` and `SourceRuleId` are null;
  - no prohibited classification fields (`Region`, `TechnicalFormat`, `Confidence`, `RAG`, …).

**Per expected dossier** (located by root path, ID-free):
- sequence set and parsed backbone XML set;
- reference, href, common and regional counts, and per-XML counts;
- ResolvedPresent, ResolvedAbsent, NotApplicable and unresolved counts;
- Matched, Mismatched, NotAssessed and NotApplicable checksum counts;
- `ReferenceTargetMissing` and `DeclaredChecksumMismatch` observations;
- the full classification-evidence multiset, using the same canonical record key as the accepted CEC harness;
- exactly one `DossierRootPath` record, with the value and relative path equal to the root;
- every record path inside its dossier.

**Normative repository checks:**
- exact candidate roots and wrapper paths;
- `Completed`;
- repository CEC coverage `Collected`, with `RecordsProduced` equal to the total;
- more than 0 records.

**Isolation (all fixtures):**
- sequence, XML, reference and evidence `DossierId`s are mutually consistent;
- every `TargetFileId` belongs to the same dossier;
- the target path equals dossier root + `NormalizedTargetPath`.

**Fixture-specific checks:**
- **SD-045:** `FDA`, `US` and `ASMF` do not appear in any non-root record value or any XML structured field. The root record is `DossierContext`/`Weak`/`FolderNameHeuristic`. No `TechnicalFormat` record contains `ASMF`, and nothing outside `DossierContext` does.
- **SD-047:** dossier identities are distinct, and sequences, XML, references and evidence are split across both dossiers.
- **SD-048:** each unrelated file is inventoried once. Files outside `ProductABC` have `DossierId = null`; `Working Notes/*` belongs to `ProductABC` with no sequence. No unrelated path becomes XML, evidence or a reference target, and the decoy XML is not an `XmlDocument`.
- **SD-049:** the exact root string is discovered, every file entry sits under it, and there are 0 repository errors.
- **SD-050:** a single candidate with root `""`; 0 ResolvedAbsent; normalized paths keep the `0000/` prefix; 0 `ReferenceTargetMissing`.
- **Invariance:** dossier-relative, ID-free and root-free projections must be **identical**: classification records excluding `DossierRootPath`; XML structured fields; references (path, href, normalized target, resolution, checksum, operation); dossier observations excluding wrapper-context `WrapperDepth`. They are compared across:
  - every SD-002-profile dossier: SD-044, 045, 046, 047/ProductABC, 048, 049, 050 and 051/ProductABC, plus the **actual Wave 1 SD-002 run**;
  - SD-047/ProductXYZ and the **actual Wave 1 SD-010 run**.
- **SD-051:** the normative checks on `ProductABC` (above), plus a characterization comparison against `tests/fixtures/dossier-diversity/wave1d-sd051-characterization.json`.

**Two harness defects were fixed during development, before freeze.** Neither involved changing an expectation:
1. Wrapper paths were compared as objects instead of their `.RelativePath`.
2. The invariance projection included SD-046's `WrapperDepth` observation. That observation is wrapper context by design, and TASK.md excludes such fields from equivalence. It is still asserted through the wrapper-path check.

## 5. Results

**Wave1D Mac regression** (final run, from the extracted package, with Wave 1 invariance references):

`PASS — 60/60 checks, 0 fail. Characterization: MATCHES_RECORDED.`

| Fixture | Checks | Result |
|---|---:|---|
| SD-044 | 6 | PASS |
| SD-045 | 7 | PASS (misleading tokens confined to root context) |
| SD-046 | 6 | PASS (wrappers `CustomerExport`, `CustomerExport/ArchiveSet`) |
| SD-047 | 10 | PASS (86 + 69 records, 94 + 87 references, no cross-dossier links) |
| SD-048 | 7 | PASS (decoy and unrelated files produce no evidence) |
| SD-049 | 7 | PASS |
| SD-050 | 7 | PASS (root `""`, 93 ResolvedPresent, 0 absent, 86 records, `Collected`) |
| SD-051 | 8 | PASS (7 normative, centred on genuine `ProductABC`, + 1 characterization) |
| Invariance | 2 | PASS (SD-002 profile, 8 dossiers + Wave 1 SD-002; SD-010 profile, 1 dossier + Wave 1 SD-010) |
| Freeze gates | pre + post | PASS |

### SD-051 characterization — `CHARACTERIZATION_PENDING_DISCOVERY_DECISION`

The observed behaviour of the current RepositoryDiscovery heuristic is listed below. The year-folder candidate is **not** a correct regulatory dossier.

| Aspect | Observed |
|---|---|
| Candidates | `DOS-0001 Archive` (heuristic), `DOS-0002 ProductABC` (genuine). The genuine dossier's ID shifts because IDs sort by path. |
| `Archive` | "sequence" `2019`; `index.xml` and `m1/eu/eu-regional.xml` Missing; observations `ExactSequenceChildrenObserved`, `MissingCommonBackbone`, `MissingRegionalBackbone`; 0 references |
| `Archive` evidence (5) | `DossierRootPath` "Archive" (Weak), `SequenceFolder` "2019" (Weak), `CtdModuleFolders` [] (Weak), `CommonBackbonePresence` false (Supporting), `RegionalBackbonePresence` false (Supporting, Region) |
| Owner of `Archive/2019/annual-report.pdf` | `Archive` candidate (not `ProductABC`) |
| Repository | `Completed`; CEC `Collected`, 91 records (86 genuine + 5 heuristic) |
| Genuine `ProductABC` | 86 records, 94 references, dossier-relative projection identical to SD-002; no leakage in either direction |

The independent oracle predicted this behaviour from the ZIP alone (the same 5 records). It also matches probe P5b from the earlier Wave 2 planning report.

## 6. Determinism

**Fixture builds:**
- Candidate build A and candidate build B, each into a fresh empty directory: `diff -r` identical.
- Frozen build A and frozen build B: `diff -r` identical. All 8 fixture ZIPs are byte-identical to the candidate ZIPs; only the manifest status column differs.

**Package:**
- Built twice: `cmp` identical, SHA-256 `c99841179e6c168d1f81a967ff4a58ba5383d269735d68e6fef0857181ac2bec`.
- Contents (21 members): README, freeze manifest, 8 × (`fixture.zip`, `manifest.json`), 2 expectation JSONs and `PACKAGE_MANIFEST.csv`.
- After extraction, all 20 manifest entries verify.

| Package member | SHA-256 |
|---|---|
| `WAVE1D_FREEZE_MANIFEST.csv` | `f9a18813a23c0749459c5138950e28e99fb828ac0599152b43302001856db460` |
| `expectations/wave1d-expectations.json` | `669848e35479f9e2e4ef8fc9c3a5d5197c3fc59db38fe3183c6e939f103bdd9c` |
| `expectations/wave1d-sd051-characterization.json` | `35000996a921a93f73e735a1005e7a5c90e80ab241e7e204a585e08115eab71e` |
| `README_TEST_DATA.md` | `dafd9bc44620c23978e7a274e851e91e4808e1bbaaf00fd298de2ca05637cfad` |
| `PACKAGE_MANIFEST.csv` | `88b0f0dc9d6fcf77410ea66f0687dcaf40a455c39cdbe59ac17c247e3efc52b3` |

## 7. Wave 1 regression after the new wave was built

| Suite | Exit | PASS | FAIL |
|---|---:|---:|---:|
| repository-discovery | 0 | 15 | 0 |
| backbone-xml-inventory | 0 | 24 | 0 |
| reference-inventory | 0 | 30 | 0 |
| reference-resolution | 0 | 33 | 0 |
| missing-reference-interpretation | 0 | 35 | 0 |
| declared-checksum-comparison | 0 | 39 | 0 |
| checksum-mismatch-interpretation | 0 | 56 | 0 |
| classification-evidence-collection | 0 | 43 | 0 |
| *(task-adjacent)* root-level-dossier | 0 | 3 | 0 |

**8/8 PASS: 275 checks, 0 failures, identical to the baseline gate.** The root-level-dossier harness from `793e065` also passes 3/3.

The 29 recorded Wave 1 hashes (the package ZIP, `WAVE1_FREEZE_MANIFEST.csv`, 19 fixture ZIPs and 8 `wave1-expectations.json`) were compared with the values recorded before the work: **identical, 29/29**. The repository working tree contained only the intended new files after every test run.

## 8. Commands

```bash
W1=<extracted eMAS_MS04_PreSales_Wave1_TestData_v1>
PK=<extracted eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1>
python3 tools/testdata/ms04-wave1d/derive_expectations.py --repo-root .
python3 tools/testdata/ms04-wave1d/oracle_wave1d.py calibrate --wave1-root "$W1" --repo-root . --samples SD-001 SD-002 SD-010 SD-016 SD-020
python3 tools/testdata/ms04-wave1d/build_wave1d.py build --wave1-root "$W1" --out <emptyA> --status FROZEN   # and again into <emptyB>; diff -r
python3 tools/testdata/ms04-wave1d/oracle_wave1d.py check --corpus <emptyA> --expectations tests/fixtures/dossier-diversity/wave1d-expectations.json --out oracle-report.json
python3 tools/testdata/ms04-wave1d/build_wave1d.py package --build-dir <emptyA> --expectations-dir tests/fixtures/dossier-diversity --out-zip eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1.zip
pwsh -NoProfile -NonInteractive -File tests/dossier-diversity/Test-eMASDossierDiversity.ps1 -CorpusRoot "$PK" -OutputRoot <out> \
  -ExpectationsPath "$PK/expectations/wave1d-expectations.json" -CharacterizationPath "$PK/expectations/wave1d-sd051-characterization.json" -Wave1CorpusRoot "$W1"
pwsh -NoProfile -NonInteractive -File tests/<suite>/Test-eMAS<Suite>.ps1 -CorpusRoot "$W1" -FreezeManifestPath "$W1/WAVE1_FREEZE_MANIFEST.csv" -OutputRoot <out>   # x8
pwsh -NoProfile -NonInteractive -File tests/root-level-dossier/Test-eMASRootLevelDossier.ps1 -CorpusRoot "$W1" -OutputRoot <out>
```

## 9. Repository changes (allowed paths only)

| Path | Purpose |
|---|---|
| `tests/dossier-diversity/Test-eMASDossierDiversity.ps1` | Dedicated Wave1D Mac harness |
| `tests/fixtures/dossier-diversity/wave1d-expectations.json` | Transform-derived expectations, confirmed by the oracle |
| `tests/fixtures/dossier-diversity/wave1d-sd051-characterization.json` | Recorded SD-051 behaviour (not normative) |
| `tests/fixtures/dossier-diversity/WAVE1D_FREEZE_MANIFEST.csv` | Repository copy of the freeze/hash manifest |
| `tools/testdata/ms04-wave1d/{wave1d_spec,build_wave1d,derive_expectations,oracle_wave1d}.py`, `README.md` | Deterministic builder, derivation, oracle and recipe |
| `docs/internal/agent-tasks/EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D/reports/CLAUDE.md` | This report |

**Not touched:**
- `engine/**`;
- `scripts/eMAS-PreSalesAssessment.ps1`;
- RepositoryDiscovery, FormatDetection and RegionDetection;
- Wave 1 fixtures, expectations and freeze manifest;
- `TASK.md`, `STATUS.md`, `REVIEW.md`;
- product contracts, readiness rules, reporting and UI.

## 10. Blockers and open decisions

**Blockers:** none. No new runtime defect was found. SD-050 passes with the merged root-path fix.

**Open decisions (for the user):**
1. **SD-051 discovery semantics.** The current heuristic makes any folder with a four-digit child (e.g. `Archive/2019/`) a dossier candidate. That yields false `MissingCommonBackbone`/`MissingRegionalBackbone` observations and 5 weak or supporting evidence records, and renumbers the genuine dossier. Before FormatDetection, decide whether to:
   - accept this as documented behaviour, with a rule that FormatDetection must never classify a candidate that has no backbone; or
   - open a dedicated RepositoryDiscovery semantics task (e.g. require backbone or `m1`–`m5` presence).

   Either choice needs a new characterization or expectation version, not an in-place edit.
2. **Coverage attribution.** Repository-level coverage rows cannot say which dossier in a multi-dossier repository had a gap. This is unchanged behaviour, noted for later.
3. **Windows PowerShell 5.1:** deferred. The Wave1D package is ready for the consolidated Windows stage.
4. **Provenance:** all Wave1D fixtures are EXTEDORIN-derived and inherit "Internal test material / redistribution unconfirmed".
