# EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE

**Task ID:** `EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE`  
**Roadmap ID:** T1a  
**Authoritative base commit:** `8a8c842b45e2cbf12025c15995cf99b0b8012b55`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Codex) → ChatGPT central review → user merge decision  
**Task type:** Bounded factual-evidence implementation  
**Windows:** Deferred

## Purpose

Extend `ClassificationEvidenceCollection` (CEC) with the factual physical markers required by the accepted MS-04 Identification Rules design, while preserving the fact/interpretation boundary.

This task does **not** identify format, region, profile, or dossier context.

## Governing decisions

Read and follow:

- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/CLAUDE.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/REVIEW.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/STATUS.md`
- `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`
- `docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md`
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
- current accepted RepositoryDiscovery / Wave1E implementation and tests.

The ChatGPT review amendments are normative where they differ from Claude's proposal.

## Non-negotiable boundaries

CEC remains factual only.

Every new record must keep:

- `CandidateValue = null`;
- `Polarity = null`;
- `SourceRuleId = null`;
- no format/region/profile/context conclusion;
- no RAG/severity/effort/readiness meaning.

Do not rewrite or reinterpret previously emitted evidence records.

## Raw strength vocabulary

The accepted current CEC contract uses:

- `Strong`
- `Supporting`
- `Weak`

Preserve that raw vocabulary in this task.

Do **not** replace historical `Supporting` with `Medium`.

The accepted Identification design will later normalize:

`Supporting → Medium`

at the interpretation boundary.

Existing frozen expectations must remain unchanged unless a new additive expectation version is explicitly created.

## Required new factual evidence

Implement the smallest useful additive set.

### 1. Unit kind

Record the RepositoryDiscovery `Sequences.SequenceLikeKind` as factual sequence-level evidence.

Recommended evidence type:

`RegulatoryUnitKind`

Observed values may include current accepted kinds such as:

- `NumericSequenceDirectory`
- `SubmissionUnitFolder`
- `DamagedSubmissionUnitCandidate`
- `AmbiguousRegulatoryUnitFolder`

Use `Weak` raw strength because the label is a physical structural classification produced by RepositoryDiscovery and must not itself become final regulatory identification.

### 2. Direct submission-unit marker

For a sequence/submission-unit folder, record direct physical presence of:

`submissionunit.xml`

Recommended evidence type:

`SubmissionUnitMarkerFile`

Use factual path/name evidence only. Do not parse the XML.

Raw strength: `Supporting`.

This is needed because current v4 physical discovery is supporting evidence, but current CEC does not expose that marker to the future interpretation layer.

### 3. NeeS TOC markers

Record direct sequence-level presence of recognized NeeS TOC filenames required by the accepted design, including at minimum:

- `ctd-toc.pdf`

Also evaluate the officially supported module TOC names already documented by the accepted source pack, but do not invent names not supported by the cited source.

Recommended evidence type:

`TocFileMarker`

ObservedValue should preserve the exact relative filename/path or a deterministic sorted collection.

Raw strength: `Supporting` only for source-backed recognized TOC names.

Random PDF files must not produce this evidence type.

### 4. Checksum-file markers

Record direct physical presence of controlled checksum marker files relevant to current v3/v4 physical structure, at minimum:

- `index-md5.txt`
- `sha256.txt`

Recommended evidence type:

`ChecksumFileMarker`

Preserve exact filename/path.

Raw strength: `Supporting`.

No checksum comparison or integrity conclusion is performed here.

### 5. util/DTD structural marker

Record the physical presence of the accepted direct `util`/DTD-support folder pattern only where the current official source model and existing package structure support it.

Recommended evidence type:

`UtilityDtdFolderMarker`

This is structural evidence only. Do not infer eCTD validity from it.

Raw strength should be `Supporting` only when the exact approved physical relationship is present; otherwise use `Weak` or omit the record. Explain the implemented choice in the report.

## Missing/absence semantics

Do not manufacture negative evidence merely because a marker record is absent.

This task records **observed physical markers**.

Missing/AccessDenied/NotAssessed must remain distinguishable through existing repository/coverage facts.

If the inventory is unavailable or partially inaccessible:

- do not emit false "marker absent" evidence;
- preserve coverage/diagnostic behavior;
- document which marker types could not be assessed.

## Scope of directness

Marker evidence must be tied to the correct physical unit.

Do not count a marker from:

- a nested embedded package;
- a sibling dossier;
- a wrapper directory;
- an unrelated year/numeric folder;

as evidence for another unit.

Use accepted RepositoryDiscovery dossier/unit ownership.

## v3/v4 coexistence

The same physical container may contain:

- v3 exact sequences;
- v4 submission units;
- ambiguous units.

CEC must emit marker facts per unit and preserve their own SequenceId/DossierId.

Do not collapse mixed lifecycle evidence into one repository-wide claim.

## Expected source fields

Prefer evidence derived from already-collected `RepositoryDiscovery` facts:

- `Sequences.SequenceLikeKind`;
- `Files.RelativePath` / `Repository.Entries`;
- accepted dossier/sequence ownership.

CEC must not reopen the source filesystem.

## Existing CEC behavior to preserve

Do not alter the meaning of existing evidence types:

- DossierRootPath
- SequenceFolder
- CtdModuleFolders
- Module1RegionalFolder
- Common/RegionalBackbonePresence
- Common/RegionalBackbonePath
- XmlRootElement
- XmlNamespace
- DtdVersion
- DocumentTypeName
- DtdSystemIdentifier
- DtdPublicIdentifier

No current Strong/Supporting/Weak record may be silently rewritten.

## Required tests

Update the focused CEC test suite:

`tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`

Add bounded assertions for at least:

1. v3 sequence with `index-md5.txt`;
2. clean v4 `SubmissionUnitFolder` with direct `submissionunit.xml` and `sha256.txt`;
3. damaged v4-like unit with `sha256.txt` but no `submissionunit.xml`;
4. ambiguous unit with both backbone markers;
5. NeeS-like sequence with `ctd-toc.pdf`;
6. random PDF must not become TOC evidence;
7. wrapper/nested marker must not leak to the wrong candidate;
8. mixed v3/v4 container preserves per-unit ownership;
9. AccessDenied/partial inventory does not become false absence;
10. CandidateValue/Polarity/SourceRuleId remain null for every new evidence record;
11. raw `Supporting` vocabulary remains unchanged;
12. deterministic ordering and stable EvidenceIds.

Reuse existing frozen Wave1/Wave1D/Wave1E fixtures where possible.

Do not modify frozen fixture bytes.

If a test case cannot be represented with accepted fixtures, create only a small synthetic test-local structure. Do not create a new regulatory-content fixture wave in this task.

## Regression gate

Mac-first.

Record before and after results for:

- CEC focused suite;
- Wave 1 eight-suite regression;
- root-level regression;
- Wave1D;
- focused v4 discovery;
- RepositoryDiscovery B3.

All previously frozen fixture hashes must remain unchanged.

The automatic unrelated Windows PowerShell 5.1 RuntimeConfiguration UTF-8 CI issue is outside scope.

## Allowed files

Implementation may modify only:

- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`;
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`;
- optional new **test-local** support data under `tests/classification-evidence-collection/**`;
- this task's report/status files.

## Forbidden files

Do not modify:

- RepositoryDiscovery implementation;
- BackboneXmlInventory implementation;
- ReferenceInventory / ReferenceResolution;
- checksum capabilities;
- contracts/schemas;
- Runtime JSON/workbook configuration;
- FormatDetection / RegionDetection;
- future IdentificationInterpretation;
- existing Wave1/Wave1D/Wave1E frozen fixture bytes;
- prior mapping artifacts.

If a forbidden change appears necessary, stop and report.

## Report

Create/update:

`docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/reports/CODEX.md`

Include:

- exact evidence types added;
- exact raw Strength and SourceTier for each;
- exact SourceField used;
- pre/post CEC counts for representative v3/v4/NeeS cases;
- proof no candidate/interpretation fields were populated;
- regression results;
- changed file list;
- any unresolved issue.

## Git workflow

Use branch:

`implementation/emas-ms04-cec-physical-marker-evidence`

Open a **draft PR into `demo/end-to-end-mvp`**.

Do not merge.

## Acceptance criteria

Ready for ChatGPT review when:

1. marker facts are additive and deterministic;
2. no interpretation is emitted;
3. raw CEC strength vocabulary is preserved;
4. marker ownership is per correct unit/dossier;
5. existing CEC meanings do not drift;
6. frozen fixture hashes do not change;
7. required Mac regressions pass;
8. scope remains bounded.
