# Codex Report — EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE

**Status:** `IMPLEMENTED_BLOCKED_ON_ADDITIVE_REGRESSION_EXPECTATIONS`

**Implementation branch:** `implementation/emas-ms04-cec-physical-marker-evidence`

**Coordination start:** `2e243a8300465d3a2d4181a01a78e9ddccf4c191`

**Authoritative base:** `8a8c842b45e2cbf12025c15995cf99b0b8012b55`

**Validation platform:** macOS, PowerShell 7.5.2

**Windows PowerShell 5.1:** deferred by task

## Outcome

Implemented bounded, additive physical-marker collection in CEC without reopening the source filesystem. Evidence is derived only from accepted RepositoryDiscovery facts and remains owned by the accepted dossier and regulatory unit.

No format, region, dossier, profile, integrity, readiness, severity, or score interpretation is emitted. Every new record preserves `CandidateValue = null`, `Polarity = null`, and `SourceRuleId = null`.

Historical CEC records retain their existing values and IDs. New records use a separate deterministic sort group after the historical catalogue.

## Evidence catalogue

All five evidence types use the `TechnicalFormat` dimension.

| EvidenceType | Raw Strength | SourceTier | SourceField | Observed value |
|---|---|---|---|---|
| `RegulatoryUnitKind` | `Weak` | `PackageStructure` | `Sequences.SequenceLikeKind` | accepted RepositoryDiscovery unit-kind label |
| `SubmissionUnitMarkerFile` | `Supporting` | `OfficialPhysicalPath` | `Files.RelativePath` | exact direct filename/path for `submissionunit.xml` |
| `TocFileMarker` | `Supporting` | `OfficialPhysicalPath` | `Files.RelativePath` | exact direct recognized filename/path: `ctd-toc.pdf`, `m1-toc.pdf` through `m5-toc.pdf` |
| `ChecksumFileMarker` | `Supporting` | `OfficialPhysicalPath` | `Files.RelativePath` | exact direct filename/path for `index-md5.txt` or `sha256.txt` |
| `UtilityDtdFolderMarker` | `Supporting` | `OfficialPhysicalPath` | `Repository.Entries` | exact direct `util/dtd` relationship, preserving observed case |

The utility marker is omitted when the exact direct relationship is absent. No weaker surrogate record and no absence record is manufactured.

## Directness and ownership

- File markers must be exact direct children of the accepted sequence/submission-unit path and must carry that unit's `SequenceId` and `DossierId`.
- Wrapper, sibling, out-of-range, unrelated numeric, and nested embedded markers are not inherited by another unit.
- Utility evidence requires a direct `util` child of the unit and a direct `dtd` child of that folder.
- Marker names are matched case-insensitively while the observed filename/path casing is preserved.
- Mixed v3/v4 containers retain separate facts per unit.
- Missing or inaccessible inventory does not become negative evidence.

## Representative pre/post CEC counts

| Case | Historical records | New records | Final records | New evidence detail |
|---|---:|---:|---:|---|
| Wave 1 SD-002, v3 | 86 | 15 | 101 | five unit-kind, five `index-md5.txt`, five `util/dtd` |
| Wave1E SD-053, clean v4 | 4 | 3 | 7 | unit-kind, `submissionunit.xml`, `sha256.txt` |
| Wave1E SD-063, damaged v4-like | 4 | 2 | 6 | unit-kind, `sha256.txt`; no fabricated submission marker |
| Wave1E SD-069, mixed v3/v4 | 19 | 5 | 24 | three unit kinds plus the v4 unit's two direct markers |
| Wave1E SD-073, ambiguous | 3 | 2 | 5 | ambiguous unit-kind plus its direct submission marker |
| Synthetic NeeS-like unit | 6 | 4 | 10 | unit-kind, two recognized TOCs, direct `util/DTD` |

## Validation

### Pre-implementation baseline

| Gate | Result |
|---|---|
| Focused CEC | PASS, 19/19 fixtures and 22/22 additional checks |
| Wave 1 eight-suite | PASS, 259/259 checks plus 16/16 freeze gates |
| Root-level | PASS, 3/3 |
| Wave1D | PASS, 61/61 |
| Focused v4 discovery | PASS, 22/22 fixtures and 2/2 additional checks |
| B3 | PASS, 12/12 |

### Final Mac validation

| Gate | Result |
|---|---|
| Focused CEC | PASS, 19/19 fixtures and 38/38 additional checks; Wave 1 19/19 and Wave1E 22/22 hashes verified before and after |
| Wave 1 eight-suite | PASS, 275/275 checks plus 16/16 Wave 1 freeze gates |
| Root-level | FAIL, 2/3; only failure is frozen additive CEC total `Expected=86; Actual=101` |
| Wave1D | FAIL, 44/61; all 17 failures are frozen CEC totals/multisets that omit the new additive records; all non-CEC checks and dossier-relative invariance pass |
| Focused v4 discovery | PASS, 22/22 fixtures and 2/2 additional checks |
| B3 | FAIL, 11/12; only failure is frozen downstream CEC total `Expected=86; Actual=101`; all 11 RepositoryDiscovery semantics checks pass |
| Frozen hashes | PASS; Wave 1 19/19, Wave1D 8/8, and Wave1E 22/22 fixtures unchanged |

## Scope audit

Changed only:

- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`
- `docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/reports/CODEX.md`
- `docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/STATUS.md`

No frozen fixture byte, schema, runtime configuration, workbook, entry script, RepositoryDiscovery, BackboneXmlInventory, reference/checksum capability, FormatDetection, RegionDetection, or interpretation module was modified.

## Blocker

The implementation is complete, but task acceptance criterion 7 cannot be met within the task's allowed-file boundary.

The root-level, Wave1D, and B3 harnesses freeze the pre-addition CEC count/multiset. The required additive evidence correctly changes SD-002-profile results from 86 to 101 records. Making those three composed regressions pass requires versioned additive expectations or historical-projection handling in their own harness/expectation files, which `TASK.md` does not allow this worker to modify. `TASK.md` explicitly says to stop and report if a forbidden change becomes necessary.

Central review and merge acceptance must remain blocked until coordination either:

1. authorizes a follow-up expectation-only task for the three affected suites; or
2. amends this task's allowed files to include those harness/expectation updates.
