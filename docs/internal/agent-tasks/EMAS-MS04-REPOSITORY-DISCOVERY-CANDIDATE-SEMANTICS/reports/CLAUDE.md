# Claude Report — EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS

**Status:** `ANALYSIS_COMPLETE — RECOMMENDATION READY FOR REVIEW`
**Agent:** Claude (single worker, report only)
**Branch:** `analysis/emas-ms04-repository-discovery-candidate-semantics`
**Based on:** `coordination/emas-ms04-repository-discovery-candidate-semantics` @ `7e034b659054774003661fcdbf280b76d20787f7`, which contains authoritative base `bd11d71225c4f5ce52960a01b4ecede27ed8a353`
**Date:** 2026-10-06
**Platform for experiments:** macOS, PowerShell 7.5.2, Python 3.14.4 (scratch only)

No runtime, test, fixture, expectation, contract, FormatDetection or RegionDetection file was changed. Every experiment ran in scratch directories, including a throw-away patched copy of the engine. This report is the only repository change.

## Recommended rule

> **A directory becomes a dossier candidate only if it has at least one direct child directory named exactly `NNNN` that either (a) directly contains a CTD module directory `m1`–`m5` or a backbone file `index.xml` / `submissionunit.xml`, or (b) could not be enumerated (access denied or enumeration error). Nested-sequence suppression is then applied only against candidates promoted this way.**

Working name: **rule B3-FO** ("structural signal in an exact sequence child, fail-open on unreadable children").

---

## 1. Current rule and the SD-051 behaviour

`Get-eMASRepositoryDiscoveryModel` in `engine/powershell51/eMAS.RepositoryDiscovery.psm1` works in two steps:

1. **Raw candidates (lines 341–348).** Every parent path in the entry tree, including the archive root `""`, that has at least one direct `Directory` child whose leaf matches `^\d{4}$`.
2. **Acceptance (lines 350–381).** Raw candidates are taken shallowest first, in ordinal order. A raw candidate is dropped if, below an already accepted candidate, its first path segment matches `^\d{4}$` (a nested sequence root, e.g. SD-014 `0003/0003`). Wrappers are all ancestors of accepted candidates. `DossierId`s are ordinal by path. `CandidateStatus` is always `Candidate`.

**SD-051 (`ProductABC/` + `Archive/2019/annual-report.pdf`)**, verified against the Wave1D characterization:
- `Archive` qualifies as a raw candidate because `2019` matches `^\d{4}$`.
- Both candidates are accepted. `Archive` sorts first, so it becomes `DOS-0001` and the genuine dossier becomes `DOS-0002`.
- `Archive/2019` becomes an exact "sequence".
- BackboneXmlInventory looks for `Archive/2019/index.xml` and `…/m1/eu/eu-regional.xml`, does not find them, and emits `MissingCommonBackbone` and `MissingRegionalBackbone`.
- ClassificationEvidenceCollection emits 5 records for the bogus candidate: `DossierRootPath "Archive"`, `SequenceFolder "2019"`, `CtdModuleFolders []`, and two presence `false` records.
- The PDF is assigned to `Archive`.
- The repository total is 91 records. The genuine dossier itself stays intact (86 records).

### A worse current failure found during this analysis: a year-named wrapper hides a genuine dossier

The same rule also produces **false negatives**. Synthetic case S08 places the unchanged SD-002 dossier at `Exports/2024/ProductABC/`.

Current behaviour, from a full-chain run of the real module:
- `Exports` is accepted first. `Exports/2024/ProductABC` is then dropped as a nested sequence root, because its first segment below `Exports` is `2024`.
- The scan reports `Completed` with:
  - **one bogus dossier `Exports`** (sequence `2024`);
  - **0 references**;
  - 20 evidence records;
  - `MissingCommonBackbone` and `MissingRegionalBackbone`;
  - 5 `NestedSequenceLikePath` observations.
- **The genuine 5-sequence dossier is silently lost.**

This is a stronger argument for changing the rule than SD-051, where the genuine dossier at least survives. Year-named export folders (`Exports/2024/…`, `Submissions/2023/…`) are a realistic customer layout.

## 2. Method and evidence

1. **Simulator (scratch Python).** Re-implements the candidate step exactly: raw predicate, shallowest-first acceptance with nested suppression, wrapper ancestors. Each rule variant changes only the raw-candidate predicate.
2. **Calibration of the simulator's rule A against the real module.** **0 mismatches**:
   - all 19 Wave 1 fixtures (candidate roots taken from the accepted CEC `DossierRootPath` records; wrappers from the accepted RepositoryDiscovery expectations);
   - all 8 Wave1D fixtures (expectations plus the SD-051 characterization);
   - 15 synthetic cases, run through the real module as ZIP **and** as directory sources.
3. **Synthetic cases** (structure only; RepositoryDiscovery does not parse XML):

| ID | Layout | Purpose |
|---|---|---|
| S01 | `Product/0000/` (empty) | empty single-sequence dossier |
| S02 | `0000/` (empty) at the archive root | empty single-sequence root dossier |
| S03 | `Product/0000/index.xml` only | backbone present, no module folders |
| S04 | `Product/0000/m1..m3/*.pdf`, no `index.xml` | NeeS-like CTD structure |
| S05 | `Product/0001/submissionunit.xml` + `m1/` | eCTD v4-like |
| S05b | `Product/0001/submissionunit.xml` + `content/` | v4-like without CTD module folders |
| S06 | `Website/2019/index.xml` + `about.html` | year folder of a web export (residual false positive) |
| S07 | `Archive/2019`, `2020`, `2021` with documents | pure year folders |
| S08 | `Exports/2024/ProductABC/` (SD-002 bytes) | year-named wrapper hiding a genuine dossier |
| S09 | `Product/0000/m1`, `Product/0001/m2`, no `index.xml` anywhere | damaged dossier, all backbones missing |
| S10 | `Product/0000.zip`, `0001.zip` only | sequences only as ZIPs |
| S11 | `Reports/2019/m1/summary.pdf` | year folder with an `m1` subfolder (residual false positive) |
| S12 | SD-002 sequences at the root + `2019/annual-report.pdf` | year folder *inside* a genuine root dossier |
| S13 | `Product/0000/` (empty) + `Product/0001/letter.pdf` | dossier with no structural signal anywhere |
| S14 | `Product/0000/M1/`, `INDEX.XML` | upper-case module/backbone names |

4. **Real-engine experiment for the recommended predicate.** A scratch copy of `engine/`, `scripts/` and `tests/` was patched with B3 (not committed) and run against the accepted suites, Wave1D and the synthetic cases (section 7).
5. **Accidental access-denied evidence.** One synthetic extraction produced sequence folders without read permission. This exposed a fail-open requirement (section 4, C5).

## 3. Rules evaluated

| ID | Raw-candidate predicate (parent P) |
|---|---|
| **A** | Current: P has ≥ 1 direct `NNNN` directory. |
| **B1** | A, and ≥ 1 exact `NNNN` child directly contains a directory `m1`–`m5`. |
| **B2** | A, and ≥ 1 exact `NNNN` child directly contains a file `index.xml` or `submissionunit.xml`. |
| **B3** | A, and ≥ 1 exact `NNNN` child directly contains (`m1`–`m5` directory) **or** (`index.xml` / `submissionunit.xml` file). |
| **B4** | A, and ≥ 1 exact child has both a module directory and a backbone file. |
| **Bx** | A, and ≥ 1 exact child is non-empty. |
| **C** | Tiered: keep every A candidate, but mark weak ones `CandidateStatus = SequenceContainerOnly` and promote only B3-qualified ones. |
| **D-num** | Reject `NNNN` values that look like years (e.g. `19xx`/`20xx`). |
| **D-min2** | Require ≥ 2 exact sequences. |
| **B3-FO** | B3, plus: a parent is also promoted if any of its exact children could not be enumerated (fail-open). **Recommended.** |

## 4. Scenario matrix

Legend: ✅ required behaviour; ❌ fails it; ⚠ tradeoff or ambiguity. The fixture and synthetic rows were computed by the calibrated simulator. A and B3 were also confirmed with the real engine.

| Required scenario | A | B1 | B2 | B3 | B4 | Bx | B3-FO |
|---|---|---|---|---|---|---|---|
| SD-044 genuine dossier discovered | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-045 misleading root text ignored (no name signal) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-046 wrappers preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-047 both dossiers found | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-048 unrelated content not a dossier | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-049 safe-name dossier preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-050 archive-root dossier discovered | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SD-051 `Archive/` not promoted** | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| SD-005 missing common backbone (0004) preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-006 missing regional backbone preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-007 / SD-008 malformed backbones preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-015 empty `0005/` beside valid sequences preserved | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-010 sequence gap preserved (observation only) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-011–SD-014 sequence-like/copy/nested cases unchanged | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SD-016 deep wrappers, SD-020 no dossier | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| S07 arbitrary year folders not dossiers | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **S08 genuine dossier under a year wrapper found** | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| S09 damaged: every backbone missing, modules present | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| S03 backbone only, no module folders | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| S04 NeeS-like (no `index.xml`) | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| S05 / S05b v4-like `submissionunit.xml` | ✅ | ⚠ (S05b ❌) | ✅ | ✅ | ⚠ (S05b ❌) | ✅ | ✅ |
| S14 upper-case names (case-insensitive match) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| S06 year folder containing `index.xml` | ❌ promoted | ✅ | ❌ | ⚠ promoted | ✅ | ❌ | ⚠ promoted |
| S11 year folder containing `m1/` | ❌ promoted | ❌ | ✅ | ⚠ promoted | ✅ | ❌ | ⚠ promoted |
| S01 / S02 completely empty single-sequence repository | promoted | ⚠ rejected | ⚠ rejected | ⚠ rejected | ⚠ rejected | ⚠ rejected | ⚠ rejected |
| S13 dossier with no structural signal anywhere | promoted | ⚠ rejected | ⚠ rejected | ⚠ rejected | ⚠ rejected | promoted | ⚠ rejected |
| Sequence folder unreadable (access denied) | promoted, state kept | ❌ silently dropped | ❌ | ❌ | ❌ | ❌ | ✅ promoted, state kept |
| Deterministic, ZIP = directory | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PS 5.1, no new dependency | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| No contract change | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Option **C (tiers)** has the same discovery coverage as B3, but it fails the "bounded" criterion; see section 5. **D-num** and **D-min2** are rejected in section 5.

**ZIP and directory determinism.** All 15 synthetic cases were run through the real module, under A and under patched B3, as ZIP sources and as extracted directories. The candidate sets were identical in every case.

## 5. Evaluated alternatives and tradeoffs

- **A (current).** Maximally permissive. It produces the SD-051 false positive and the S07 false positives. More seriously, it produces the **S08 false negative**: any four-digit folder above a dossier becomes the "dossier" and swallows the genuine one. Its permissiveness also hides problems: an unreadable or empty folder still becomes a dossier. Rejected as normative semantics.
- **B1 (module folders only).** Format-neutral for CTD layouts and robust to missing or malformed backbones. However, it rejects a sequence that contains only its backbone (S03) and a v4 unit without CTD folders (S05b). Too narrow on its own.
- **B2 (backbone file only).** Rejects NeeS-like dossiers (S04) and damaged dossiers where every backbone is missing (S09). It also ties discovery to eCTD. Rejected.
- **B3 (module folder or backbone file).** The smallest union of B1 and B2:
  - It keeps every accepted fixture and every legitimate synthetic case.
  - It fixes SD-051, S07 and S08.
  - It costs one directory lookup per exact child, using data that is already in memory.
  - Residual false positives need a four-digit folder that also directly contains `index.xml` (S06) or `m1`–`m5` (S11). Downstream capabilities handle these as structurally weak candidates, and FormatDetection must not classify them without backbone evidence (see U2).
  - On its own, B3 drops unreadable dossiers silently.
- **B4 (both signals).** Too strict: it loses S03, S04, S05b and S09.
- **Bx (non-empty).** Does not fix SD-051, S07 or S08, because year folders contain files.
- **C (tiers).** `CandidateStatus` exists in the contract, but nothing reads it: ReferenceInventory, ReferenceResolution and CEC iterate every `DossierCandidates` entry, and BackboneXmlInventory iterates every exact sequence. Tiering would require:
  - status-aware filtering in at least four capability modules;
  - a defined meaning for the new status in the contract;
  - re-baselined coverage counts.

  That is a broad redesign. **Rejected for this bounded scope.** It could be reconsidered if a future task needs to surface weak containers.
- **D-num (reject year-like numbers).** Uses the *value* of a folder name as semantics. Legitimate long-lived dossiers can reach sequences such as `2019`, so this would create false negatives that structure cannot correct. It also breaks the "names are not authoritative" principle. Rejected.
- **D-min2 (≥ 2 sequences).** Rejects every initial single-sequence submission. Rejected.
- **B3-FO.** B3 plus fail-open for children that cannot be enumerated. This keeps the "access denied ≠ absent" principle: an unreadable sequence must never silently remove a dossier. **Recommended.**

## 6. Recommendation (normative)

### 6.1 Plain-English semantics

1. A directory `P` (including the archive root `""`) is a **raw dossier candidate** if it has at least one direct child directory whose name is exactly four ASCII digits (`NNNN`). Call these P's *exact children*.
2. `P` is **promoted** if at least one exact child `P/NNNN`:
   - directly contains a directory named `m1`, `m2`, `m3`, `m4` or `m5` (case-insensitive); **or**
   - directly contains a file named `index.xml` or `submissionunit.xml` (case-insensitive); **or**
   - could not be enumerated: inventory reported access denied or an enumeration error for `P/NNNN` or one of its descendants.
3. Promoted candidates are accepted shallowest first, in ordinal order. A promoted candidate is dropped only if its first segment below an **already accepted** candidate is `NNNN` (unchanged nested-sequence rule, now applied to promoted candidates only).
4. Everything else is unchanged: sequence detection under each candidate, sequence-like kinds, observations, wrapper derivation, ID assignment and file ownership.
5. Non-promoted parents are ordinary folders. Their files have `DossierId = null`, exactly like other unrelated content (SD-020, SD-048). They can be wrappers of deeper candidates.

### 6.2 Pseudocode

```
children = ChildrenMap(entries)                  # existing: parent -> direct entries (files and directories)
unreadable = { e.RelativePath for e in repository.Errors
               if e.Code in ('DISC-ACCESS-001', 'DISC-ENUM-001') }

def has_structural_signal(seq_path):
    if any(u == seq_path or u.startswith(seq_path + '/') for u in unreadable):
        return True                              # fail-open: unknown is not absent
    for c in children.get(seq_path, []):
        leaf = Leaf(c.RelativePath)
        if c.EntryKind == 'Directory' and re.fullmatch('m[1-5]', leaf, IGNORECASE): return True
        if c.EntryKind == 'File' and leaf.lower() in ('index.xml', 'submissionunit.xml'): return True
    return False

raw = []
for parent, kids in children.items():
    exact = [k for k in kids if k.EntryKind == 'Directory' and re.fullmatch(r'\d{4}', Leaf(k.RelativePath))]
    if exact and any(has_structural_signal(k.RelativePath) for k in exact):
        raw.append(parent)

accepted = []                                    # unchanged acceptance; uses promoted candidates only
for depth in 0..max_depth(raw):
    for p in ordinal_sorted(x for x in raw if depth(x) == depth):
        if not any(first_segment_below(a, p) matches r'\d{4}' for a in accepted if is_ancestor_or_root(a, p)):
            accepted.append(p)
# remainder of Get-eMASRepositoryDiscoveryModel unchanged
```

### 6.3 Structural signals allowed

These are checked only *directly* inside an exact `NNNN` child, by name, and are case-insensitive:
- directories `m1`–`m5`;
- files `index.xml` and `submissionunit.xml`;
- inventory errors (access denied or enumeration failure) for that child or its subtree.

### 6.4 Signals explicitly forbidden

- Any dossier, wrapper, product, company or region name, and any free text such as `FDA`, `US`, `EU`, `ASMF` or `DMF`.
- The numeric value of `NNNN` (no year heuristics).
- File contents: no XML parsing, DOCTYPE, namespace or DTD, and no checksum.
- Regional subfolder names (`m1/eu`, `m1/us`, …); only the presence of `m1`–`m5` counts.
- File types or sizes elsewhere (e.g. "contains PDFs").
- Signals deeper than the exact child's direct children.
- `index-md5.txt`, `util/`, or other v3-only artefacts. They are not needed, and they would make discovery more v3-specific.

### 6.5 Behaviour by situation

| Situation | Behaviour |
|---|---|
| Archive root | Root `""` is a candidate when root-level `NNNN` children carry a signal (SD-050 unchanged). Empty root-level sequences alone are not enough (S02, see U1). |
| Wrappers | Unchanged: all ancestors of accepted candidates. Year-named wrappers no longer swallow dossiers (S08 gets wrappers `Exports`, `Exports/2024`). |
| Multi-dossier | Each parent is evaluated independently; SD-047 unchanged. IDs stay ordinal by path, so removing a false candidate renumbers the genuine one (SD-051: `DOS-0002` → `DOS-0001`). |
| Incomplete / damaged | One signalling sequence is enough to promote the whole dossier. Missing or malformed backbones (SD-005 to SD-008), empty extra sequences (SD-015), gaps (SD-010), sequence-like items (SD-011 to SD-014) and NeeS-like structures remain as today. Downstream missing, parse-failed and access-denied states are untouched. |
| Unreadable sequence | Fail-open: promoted, with the access error preserved. |
| Empty or structureless | A dossier whose every exact child is empty, or contains only unrelated files (S01, S02, S13), is **not** promoted. Its content becomes unowned inventory (see U1). |

### 6.6 Expected effect on SD-051

- 1 candidate, `ProductABC` = `DOS-0001`, 5 sequences.
- No `MissingCommonBackbone` or `MissingRegionalBackbone`.
- 86 classification records, repository CEC `Collected` (86).
- `Archive/2019/annual-report.pdf` has `DossierId = null`.

Confirmed with the scratch-patched engine. The frozen SD-051 fixture bytes do not change. The implementation task must **supersede** `wave1d-sd051-characterization.json` with a new version, for example by promoting SD-051 to a normative expectation v2. It must not edit the existing file in place.

### 6.7 Expected effect on accepted Wave 1 and Wave1D

**No change for any accepted normative fixture.** The candidate sets are identical for all 19 Wave 1 fixtures and SD-044 to SD-050, so all downstream output is identical as well.

Scratch-patched engine (B3 predicate) results:

| Suite | Result |
|---|---|
| Wave 1, 8 suites | 15/24/30/33/35/39/56/43: **275/275 PASS** |
| Root-level dossier | **3/3 PASS** |
| Wave1D | **59/59 normative checks PASS**; the single non-pass is the SD-051 characterization check reporting drift, as intended |

The fail-open branch never triggers on these corpora (they have no inventory errors), so B3 and B3-FO behave identically there.

### 6.8 Contract or schema change

**None.** No field, status value, observation code or collection changes. Behaviour differs only in which entries appear in `DossierCandidates`, and therefore in file ownership, sequences and IDs in the affected repositories. That is a semantic change and must be versioned in the expectations, but the schema is unchanged.

### 6.9 Implementation scope

The change can stay inside RepositoryDiscovery plus focused tests:
- **Predicate:** about 15 lines in the raw-candidate loop of `Get-eMASRepositoryDiscoveryModel`. It uses the existing `$childrenMap`, which holds files and directories. It needs only `-match`, `ToLowerInvariant()` and `-contains`, so it is PS 5.1 compatible with no new dependency.
- **Fail-open:** pass the existing repository error list (or the set of unreadable paths) into `Get-eMASRepositoryDiscoveryModel`. Today the function receives only `Entries`. This is an internal signature change, not a contract change.
- **Focused tests:** S01 to S14-style synthetic structures (built deterministically, like Wave1D), a versioned SD-051 expectation, and a full re-run of the 8 Wave 1 suites, the root-level harness and Wave1D.

## 7. Future-format check (guard only; nothing implemented)

- **eCTD v3.x:** every v3 sequence carries `index.xml` at the sequence root and `m1`–`m5` folders. Promoted by either signal, and still promoted when a backbone is missing or malformed (SD-005 to SD-008).
- **eCTD v4-style packages:** `submissionunit.xml` at the root of a `NNNN` folder promotes, with or without CTD folders (S05, S05b). **Assumption to verify later:** whether real v4 exports use four-digit folder names at all. If they don't, the limiting factor is the existing four-digit gate, which this recommendation leaves unchanged; a v4 task would need its own discovery extension. B3 makes this no harder.
- **NeeS-like CTD structures:** `m1`–`m5` folders without `index.xml` promote (S04, S09). Lower-case `m1`–`m5` is the ICH convention; matching is case-insensitive (S14).
- **Legacy or paper-like structures without `NNNN` folders:** never candidates, now or under the recommendation (e.g. S10 ZIP-only sequences). Unchanged and out of scope.

## 8. Current behaviour vs recommendation vs open ambiguity

| Topic | Current behaviour | Normative recommendation | Open |
|---|---|---|---|
| `Archive/2019` | dossier candidate | not a candidate | — |
| Year wrapper above a dossier (S08) | genuine dossier lost | genuine dossier found | — |
| Year folder containing `index.xml` or `m1` | candidate | candidate (residual) | U2 |
| Empty or structureless dossier | candidate | not a candidate, content unowned | U1 |
| Year folder *inside* a genuine dossier (S12) | extra "sequence" | unchanged (still a sequence) | U3 |
| Unreadable sequence folder | candidate, error kept (also reported as `EmptyExactSequenceFolder`) | candidate, error kept | U6 |

## 9. Unresolved questions

- **U1 — Empty or structureless dossiers are not promoted.**
  - Affected: an export containing only `Product/0000/` (empty, S01/S02), or only empty and PDF-only sequences (S13). These stop being dossiers. Their files remain in the inventory with `DossierId = null` and no observation says why.
  - Options:
    - (a) accept;
    - (b) add an *additive* observation, e.g. `NumericFolderParentNotPromoted` with the parent path. This is a new observation code; harness counts and the "unrelated observation" assertions would need versioning.
  - My recommendation is (a) now and (b) as an optional follow-up. **This needs a user decision.**
- **U2 — Residual false positives.** A year folder that directly contains `index.xml` (a web export, S06) or `m1`–`m5` (S11) is still promoted. Removing this would require content parsing, which TASK.md forbids. Proposed guard: FormatDetection must never classify a candidate without a successfully parsed backbone. This is a FormatDetection acceptance criterion.
- **U3 — Sequence membership is out of scope.** A year folder sitting *next to* genuine sequences in the same dossier (S12: `2019/` at the root of a root-level dossier, or `ProductABC/2019/`) is still an exact sequence of that dossier. Fixing it would need per-sequence signals. That would conflict with SD-015 (an empty `0005/` that must stay a sequence) and change Sequences and observations broadly. **Separate decision if wanted.**
- **U4 — Case-insensitive names.** Recommended to avoid false negatives on case-variant exports (S14) and to match PowerShell's default `-match`. Confirm.
- **U5 — v4 folder naming.** Not verified against real v4 exports; see section 7.
- **U6 — Fail-open on unreadable children.** Recommended so access-denied never silently removes a dossier. Side finding, not part of this decision: today an unreadable sequence folder is *also* reported as `EmptyExactSequenceFolder`, which conflates "unreadable" with "empty". A future RepositoryDiscovery task could fix this.

## 10. Scope confirmation

- Report only. The single changed file is `docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/reports/CLAUDE.md`.
- The scratch engine patch, simulator and synthetic ZIPs were not committed.
- No change to RepositoryDiscovery, FormatDetection, RegionDetection, tests, fixtures, expectations or contracts.
- The implementation of B3-FO requires an explicit user decision and a separate task.
