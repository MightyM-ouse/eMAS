# Codex Report — EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE

**Status:** `READY_FOR_CHATGPT_REVIEW`

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
| Root-level | PASS, 3/3; historical projection proves 86 records, full additive result proves 101, and coverage equals the full total |
| Wave1D | PASS, 61/61; legacy per-dossier counts/multisets use the historical projection, full repository coverage equals the additive result, and 8/8 fixture hashes are unchanged |
| Focused v4 discovery | PASS, 22/22 fixtures and 2/2 additional checks |
| B3 | PASS, 12/12; historical projection proves 86 records, full additive result proves 101, and coverage equals the full total |
| Frozen hashes | PASS; Wave 1 19/19, Wave1D 8/8, and Wave1E 22/22 fixtures unchanged |

## Central-review follow-up

The centrally authorized harness-only refresh was applied without changing CEC implementation semantics:

- root-level and B3 explicitly prove both the 86-record historical SD-002 projection and the 101-record full additive result;
- their repository `RecordsProduced` assertions use the full additive record count;
- Wave1D legacy count/multiset checks use a historical projection excluding the five T1a types;
- Wave1D repository coverage remains tied to the complete additive CEC collection;
- all other assertions remain unchanged.

## Scope audit

Changed only:

- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`
- `tests/root-level-dossier/Test-eMASRootLevelDossier.ps1`
- `tests/dossier-diversity/Test-eMASDossierDiversity.ps1`
- `tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1`
- `docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/reports/CODEX.md`
- `docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/STATUS.md`

No frozen fixture byte, schema, runtime configuration, workbook, entry script, RepositoryDiscovery, BackboneXmlInventory, reference/checksum capability, FormatDetection, RegionDetection, or interpretation module was modified.

## Open issues and deferred work

- No implementation or Mac regression blocker remains.
- Windows PowerShell 5.1 qualification remains deferred by task; the separately diagnosed RuntimeConfiguration UTF-8 CI issue is unrelated.
- ChatGPT follow-up review and user acceptance remain pending. This implementation worker did not merge PR #47.
