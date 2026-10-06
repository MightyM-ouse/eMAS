# EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION`  
**Authoritative base commit:** `e369ae3ebb8394fb7b241bf9fbb60d698ec53690`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Codex) → ChatGPT central review → user decision  
**Stage:** Mac-first bounded implementation  
**Windows PowerShell 5.1:** Deferred to later consolidated qualification

## Purpose

Implement the accepted eCTD v4 physical-discovery design, without implementing FormatDetection, RegionDetection, v4 XML interpretation, or v4 reference semantics.

This task extends only RepositoryDiscovery and its focused test-data wave.

## Governing design

Read and follow:

- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/CLAUDE.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/REVIEW.md`

The ChatGPT review amendments are normative where they differ from Claude's proposal.

## Required source verification before code

Before implementation, verify from current official regional material that the physical rules used here remain valid for currently supported versions in scope.

At minimum record in the Codex report:

- current ICH eCTD v4 IG version;
- FDA Regional M1 IG current version;
- FDA currently supported ICH IG package version;
- FDA legacy-supported Module 1 package/version still in support and whether its physical sequence-folder rules materially differ;
- current EU Practical Guidance and EU validation/implementation material used.

If a currently supported regional version materially contradicts the accepted physical-discovery rules below, stop and report instead of coding around it.

## Accepted physical-discovery semantics

### A. Preserve v3/NeeS B3

Existing four-digit v3/NeeS B3 behavior remains the baseline except where an explicit v4/conflict marker below requires neutral handling.

### B. Confirmed v4 submission-unit structural folder

A direct child directory `U` of a candidate parent is a v4 submission-unit structural folder when:

- its leaf name is 1–6 ASCII digits;
- it directly contains `submissionunit.xml`, matched case-insensitively;
- it does not also directly contain `index.xml`.

Record it as a new non-v3 sequence-like kind, e.g.:

`SubmissionUnitFolder`

Requirements:

- `IsExactSequenceFolder = false`;
- `IsSequenceLike = true`;
- canonical numeric name = `^[1-9]\d{0,5}$`;
- non-canonical names such as `0001` may still be structurally detected but must produce a factual non-canonical-name observation;
- RepositoryDiscovery does not parse the XML.

### C. Damaged / v4-like structural fallback

If a 1–6-digit child:

- has no direct `index.xml`;
- has no direct `submissionunit.xml`;
- directly contains `sha256.txt`; and
- directly contains at least one `m1`–`m5` directory,

the parent may be promoted so the incomplete package is not silently lost.

Use a distinct factual kind, e.g.:

`DamagedSubmissionUnitCandidate`

This is **not confirmed v4**. FormatDetection later must not classify v4 from this fallback alone.

It must also remain `IsExactSequenceFolder = false` so current v3 BackboneXmlInventory does not manufacture v3 missing-backbone findings.

### D. Conflicting backbone markers

If a 1–6-digit folder directly contains both:

- `index.xml`; and
- `submissionunit.xml`,

do not choose v3 or v4.

Promote the parent as a physical candidate and record the child with a neutral kind such as:

`AmbiguousRegulatoryUnitFolder`

Requirements:

- `IsExactSequenceFolder = false`;
- emit a factual `ConflictingBackboneMarkers` observation;
- do not send this folder through current v3 BackboneXmlInventory as an exact v3 sequence;
- final interpretation is deferred.

### E. Access denied

- Existing unreadable four-digit B3 fail-open behavior remains unchanged.
- Do **not** promote an unreadable non-four-digit numeric folder merely because it is unreadable.
- Preserve its existing access/enumeration diagnostic.
- If `submissionunit.xml` is visible in the directory inventory but reading/parsing the file fails later, candidacy remains because marker presence was established.

### F. Misplaced submission-unit marker

A `submissionunit.xml` that is:

- directly at archive root; or
- directly in a non-numeric folder; or
- otherwise not directly inside a 1–6-digit candidate unit folder

must not create a v4 candidate by itself.

Emit an additive factual observation:

`UnplacedSubmissionUnitMarker`

with the marker path in `ObservedValue`.

### G. Container semantics

The parent of one or more classified v3/v4/ambiguous/damaged child units is the existing physical `DossierCandidates` container.

Do not reinterpret `DossierCandidates` as application identity.

The archive root `""` may be the physical container.

### H. Nested-candidate suppression

Generalize the accepted nested-sequence suppression so a deeper candidate is suppressed only when its first segment below an already accepted candidate is one of that accepted candidate's **classified direct unit folders**.

Do not suppress merely because a path segment looks numeric.

### I. v3/v4 transition

A physical container may legitimately contain both:

- accepted v3 exact `NNNN` sequences; and
- v4 submission-unit folders such as `4`.

RepositoryDiscovery records structure only. It does not validate lifecycle numbering.

## Required observations

Add only factual, additive observations needed for this implementation:

- `SubmissionUnitFoldersObserved`
- `DamagedSubmissionUnitMarkerSet`
- `NonCanonicalSequenceNumberFolderName`
- `ConflictingBackboneMarkers`
- `UnplacedSubmissionUnitMarker`

Names may be adjusted slightly if existing conventions require it, but the report must map exact implemented names to these meanings.

No RAG, format, region, validity, or recommendation is emitted here.

## Wave 1E fixture implementation

Build and freeze Wave 1E under reserved IDs **SD-053 through SD-074**.

Use source-backed synthetic physical structures only.

Rules:

- synthetic `submissionunit.xml` must be clearly labelled as a discovery-only stub, not a fake valid regulatory message;
- `sha256.txt` should contain the actual SHA-256 of the stub when present;
- module content may be synthetic placeholders;
- builds must be deterministic;
- do not rename v3 fixtures and call them v4;
- keep SD-028 and SD-029 reserved for later content-valid regional v4 XML fixtures.

Required scenarios include:

- FDA-like root-level unit;
- later/reuse-only unit with no module folders;
- EU first-level wrapper + unit;
- neutral deep wrappers;
- two v4 containers;
- v3 and v4 side-by-side;
- unrelated year folders;
- numeric folder with arbitrary XML only;
- minimal `submissionunit.xml` unit;
- missing `sha256.txt`;
- damaged fallback `sha256.txt + m1` with missing `submissionunit.xml`;
- unreadable four-digit B3 case;
- unreadable non-four-digit negative case;
- misplaced `submissionunit.xml`;
- case variants;
- malformed XML stub;
- v3→v4 mixed container;
- four-digit folder carrying v4 marker;
- leading-zero non-canonical name;
- EU grouped-transmission physical layout;
- 7-digit out-of-range folder;
- conflicting `index.xml + submissionunit.xml`;
- year wrapper above a v4 package.

The expected matrix must reflect the accepted amendments, not Claude's pre-review U2/U5 behavior.

## Required downstream safety assertions

For every v4, damaged-v4-like, or ambiguous unit folder:

- `IsExactSequenceFolder = false`;
- current BackboneXmlInventory must not emit `MissingCommonBackbone` or `MissingRegionalBackbone` solely because that folder is v4/ambiguous;
- v3 ReferenceInventory/ReferenceResolution must not be newly extended to v4 in this task;
- no format or region conclusion is emitted.

## Regression gate

Before implementation, record baseline results from `e369ae3ebb8394fb7b241bf9fbb60d698ec53690`:

- RepositoryDiscovery;
- focused B3 candidate semantics;
- Wave 1 eight-suite regression;
- root-level regression;
- Wave1D.

After implementation, on Mac:

1. focused v4 discovery harness PASS;
2. deterministic Wave1E build twice with identical fixture/package hashes;
3. RepositoryDiscovery accepted regression PASS;
4. focused B3 semantics unchanged PASS;
5. Wave 1 eight-suite regression remains PASS;
6. root-level remains PASS;
7. Wave1D remains PASS;
8. all frozen Wave 1/Wave1D fixture hashes unchanged;
9. no existing normative output drift outside intentional new v4 fixture coverage;
10. ZIP/directory discovery equivalence for equivalent readable Wave1E structures.

## Allowed files

Implementation owner may modify only:

- `engine/powershell51/eMAS.RepositoryDiscovery.psm1`;
- new focused tests under `tests/repository-discovery-ectd4/**`;
- new Wave1E expectations/metadata under `tests/fixtures/repository-discovery-ectd4/**`;
- new deterministic fixture builder under `tools/testdata/ms04-wave1e/**`;
- task report/status files for this task.

If an existing regression harness must be changed only to invoke the new fixture wave, document why first.

## Forbidden files

Do not modify:

- BackboneXmlInventory implementation;
- ReferenceInventory / ReferenceResolution implementation;
- checksum capabilities;
- ClassificationEvidenceCollection implementation;
- entry scripts;
- contracts/schemas;
- FormatDetection;
- RegionDetection;
- existing frozen Wave 1/Wave1D fixture bytes;
- release/package files unrelated to the focused test wave.

If implementation proves that one of these must change, stop and report instead of widening scope.

## Report

Create/update:

`docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION/reports/CODEX.md`

Include:

- source-version verification;
- pre-fix baseline;
- exact classifier/precedence logic;
- exact sequence-like kinds and observation codes added;
- Wave1E fixture list and hashes;
- deterministic-build evidence;
- pre/post regressions;
- proof that v4/ambiguous folders bypass v3 exact-sequence backbone probing;
- unresolved issues.

## Git workflow

Use branch:

`implementation/emas-ms04-ectd4-discovery`

Open a **draft PR into `demo/end-to-end-mvp`**.

Do not merge.

ChatGPT performs central review. User approval is required before merge.

## Explicit downstream gates

Until this task is accepted:

- FormatDetection = BLOCKED
- RegionDetection = BLOCKED

After this task is accepted:

- create `EMAS-MS04-IDENTIFICATION-RULES` before FormatDetection/RegionDetection implementation;
- create `EMAS-MS04-ECTD4-REFERENCE-SEMANTICS` before claiming complete v4 reference/file-integrity support.

Windows PS 5.1 qualification remains deferred to the consolidated release stage.
