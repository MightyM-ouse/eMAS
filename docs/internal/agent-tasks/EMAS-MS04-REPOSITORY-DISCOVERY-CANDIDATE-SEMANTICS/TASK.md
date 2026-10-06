# EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS

**Task ID:** `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS`  
**Authoritative base commit:** `bd11d71225c4f5ce52960a01b4ecede27ed8a353`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT review → user decision  
**Task type:** Decision/analysis only. No runtime implementation in this task.  
**Required timing:** Must complete before FormatDetection or RegionDetection implementation.

## Purpose

Decide the correct RepositoryDiscovery rule for dossier-candidate detection when a directory contains a four-digit child folder but lacks convincing dossier structure.

The motivating characterization is Wave1D SD-051:

- `ProductABC/` is the genuine dossier.
- `Archive/2019/annual-report.pdf` is unrelated archive content.
- Current RepositoryDiscovery treats `Archive/` as another dossier candidate because it has a direct four-digit child `2019/`.
- That candidate then produces false missing-backbone observations/evidence and renumbers the genuine dossier.

SD-051 is accepted only as `FROZEN_CHARACTERIZATION`. The current behavior is **not** accepted as normative product semantics.

## Current implementation to analyze

In `engine/powershell51/eMAS.RepositoryDiscovery.psm1`, a raw dossier candidate is currently any parent path with at least one direct directory whose name matches `^\d{4}$`.

The task must analyze whether that rule is too permissive and determine the smallest safer alternative without breaking accepted incomplete/damaged dossier cases.

## Important constraints

The decision must preserve the current MS-04 design principles:

- RepositoryDiscovery is inventory/structure discovery. It must remain read-only, offline, deterministic and safe.
- Do not make dossier names, wrapper names, product names, region names, ASMF/DMF text, or free text authoritative.
- Do not parse XML content in RepositoryDiscovery merely to decide whether a dossier exists.
- Do not move FormatDetection or RegionDetection logic into RepositoryDiscovery.
- ASMF/DMF are dossier contexts, not technical formats.
- Missing/parse-failed/access-denied states must remain distinguishable downstream.
- Numeric sequence gaps remain observations only.
- The rule must be future-aware enough not to make v3-only assumptions if a format-neutral structural signal can be used instead.
- Wave 1 and accepted Wave1D behavior must not be silently redefined.

## Evidence base

Use these repository-native sources:

1. Current `engine/powershell51/eMAS.RepositoryDiscovery.psm1`.
2. Existing RepositoryDiscovery Wave 1 expectations/harness.
3. Root-level dossier regression.
4. Wave1D fixtures/expectations/report, especially:
   - SD-044 neutral root
   - SD-045 misleading root
   - SD-046 wrappers
   - SD-047 multi-dossier
   - SD-048 unrelated content
   - SD-049 safe-name variation
   - SD-050 archive-root dossier
   - SD-051 `Archive/2019` characterization
5. Existing damaged/incomplete Wave 1 fixtures:
   - missing common backbone
   - missing regional backbone
   - malformed backbones
   - sequence gap
   - empty sequence folder
   - wrappers
   - unrelated content

Do not modify any of those inputs.

## Decision question

What is the minimum structural evidence required before a parent of one or more exact four-digit directories should be promoted from a generic folder to a dossier candidate?

The answer must balance:

- **false positives:** unrelated year/version folders such as `Archive/2019`;
- **false negatives:** damaged or incomplete dossiers that may be missing one or more backbones;
- **format neutrality:** avoid an unnecessarily EU/eCTD-v3-specific discovery rule;
- **separation of concerns:** discovery should find plausible dossier structures without performing format classification.

## Candidate rule families to evaluate

Evaluate at least these options. You may add another option if evidence supports it.

### A. Current rule

A parent is a dossier candidate if it has at least one direct `NNNN` directory.

This is the current behavior and the SD-051 false-positive baseline.

### B. Four-digit child + at least one structural dossier signal somewhere under an exact sequence child

Examples of format-neutral-ish structural signals to evaluate:

- a direct CTD module directory `m1` through `m5`;
- a known submission backbone filename at sequence root, such as `index.xml` or `submissionunit.xml`;
- another narrowly defined structural signal that does not depend on dossier name, region name, or XML content parsing.

The task must not assume this option is automatically correct. Test it against damaged/incomplete cases.

### C. Candidate tiers rather than immediate promotion

Keep the four-digit parent as a weak sequence-container candidate, but only promote it to a dossier candidate when stronger structural evidence exists.

Analyze whether this can be introduced without forcing downstream contract changes. If it requires broad contract/runtime redesign, say so and reject it for the current bounded scope.

### D. Another bounded alternative

If A-C are inadequate, propose the smallest alternative that satisfies the acceptance matrix.

## Required scenario matrix

For every candidate rule, record whether it would:

- discover SD-044 genuine dossier;
- ignore misleading root text in SD-045;
- preserve wrapper discovery in SD-046;
- find both dossiers in SD-047;
- keep unrelated external content from becoming a dossier in SD-048;
- preserve SD-049;
- discover the root-level dossier in SD-050;
- avoid promoting `Archive/` in SD-051;
- preserve existing damaged dossiers where one backbone is missing;
- preserve malformed-backbone dossiers;
- preserve a dossier containing an empty sequence alongside valid sequences;
- preserve sequence-gap behavior;
- avoid turning arbitrary year folders into dossiers;
- remain deterministic for ZIP and directory sources;
- remain implementable in Windows PowerShell 5.1 without new dependencies.

If a rule would reject a completely empty single-sequence repository, call that out explicitly as an ambiguity/tradeoff rather than hiding it.

## Future-format check

The report must explicitly discuss whether the proposed rule would still allow later detection of:

- eCTD v3.x style submissions;
- eCTD v4-style packages where `submissionunit.xml` may be relevant;
- NeeS-like CTD module structures without an eCTD `index.xml`.

This is not permission to implement those formats. It is only a guard against choosing a discovery rule that obviously blocks them.

## Required recommendation

Produce one recommended rule with:

1. exact plain-English semantics;
2. pseudocode;
3. structural signals allowed;
4. signals explicitly forbidden;
5. behavior for archive root;
6. behavior for wrappers;
7. behavior for multi-dossier repositories;
8. behavior for incomplete/damaged dossiers;
9. behavior for ambiguous/empty cases;
10. expected effect on SD-051;
11. expected effect on accepted Wave 1 + Wave1D;
12. whether a contract/schema change is needed;
13. whether the implementation can remain confined to RepositoryDiscovery + focused tests.

The recommendation must distinguish:

- **normative recommendation**;
- **current behavior**;
- **open ambiguity**.

## No implementation in this task

Do **not** edit:

- `engine/**`;
- `scripts/**`;
- `tests/**`;
- fixture or expectation files;
- product contracts;
- FormatDetection or RegionDetection.

This task is a decision gate only.

If runtime experiments are useful, run them from scratch or temporary copies without committing changes.

## Claude deliverable

Create:

`docs/internal/agent-tasks/EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS/reports/CLAUDE.md`

The report must contain:

- current-rule explanation;
- scenario matrix;
- evaluated alternatives;
- tradeoffs;
- recommended rule;
- pseudocode;
- future-format check;
- implementation impact;
- explicit list of unresolved questions, if any.

Open a draft report-only PR into the coordination branch or `demo/end-to-end-mvp` as directed by the launch file. Do not merge.

## Acceptance criteria

Ready for ChatGPT review when:

1. current SD-051 behavior is explained correctly;
2. at least A/B/C are evaluated;
3. accepted damaged/incomplete fixtures are included in the matrix;
4. root-level and wrapper cases are included;
5. future v4/NeeS compatibility is considered;
6. one bounded rule is recommended;
7. no runtime/test/fixture files are changed;
8. the report makes clear which edge cases remain ambiguous.

## Decision gate

ChatGPT reviews the report and presents the recommended semantics to the user.

Only after explicit user acceptance will a separate implementation task modify RepositoryDiscovery and its focused regression coverage.

FormatDetection and RegionDetection must remain blocked until this decision is accepted.
