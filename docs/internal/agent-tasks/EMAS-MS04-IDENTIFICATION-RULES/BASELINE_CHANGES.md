# Current Baseline and Important Changes

**For task:** `EMAS-MS04-IDENTIFICATION-RULES`  
**Authoritative base:** `401d99cbe0afbfeb12ffe4dbf5650cb149a1f529`

Claude must treat this file as the current handover summary before analysing identification rules.

## What changed recently

### 1. RepositoryDiscovery B3 is accepted for v3/NeeS

The existing v3/NeeS discovery path now promotes a parent only when a direct four-digit child contains credible structural signals, with the accepted fail-open rule limited to an unreadable exact four-digit sequence directory.

Important consequences:

- unrelated year folders such as `Archive/2019` are no longer promoted merely because they are four digits;
- unreadable is distinct from empty;
- nested-candidate suppression happens only after actual structural promotion;
- case-insensitive physical marker detection is allowed while conformance remains a later concern.

### 2. eCTD v4 physical discovery is now accepted and merged

Merge commit:

`401d99cbe0afbfeb12ffe4dbf5650cb149a1f529`

RepositoryDiscovery now recognises separate physical v4-like unit kinds:

- `SubmissionUnitFolder`
- `DamagedSubmissionUnitCandidate`
- `AmbiguousRegulatoryUnitFolder`

Important factual observations now include:

- `SubmissionUnitFoldersObserved`
- `DamagedSubmissionUnitMarkerSet`
- `NonCanonicalSequenceNumberFolderName`
- `ConflictingBackboneMarkers`
- `UnplacedSubmissionUnitMarker`

A confirmed physical v4 submission-unit folder:

- has a 1–6 digit direct child name;
- directly contains `submissionunit.xml`;
- is not simultaneously an `index.xml` folder;
- is recorded with `IsExactSequenceFolder = false`.

A damaged/v4-like candidate may exist when `submissionunit.xml` is missing but `sha256.txt` plus a direct CTD module folder is present. This is **not** enough to conclude eCTD v4.

A folder containing both `index.xml` and `submissionunit.xml` is intentionally **ambiguous**, not forced to v3.

### 3. Wave1E is frozen

Wave1E contains SD-053 through SD-074 and covers physical v4 discovery only.

Outer package SHA-256:

`78541a9b508cc9575ee56dc0468601c0e392cb543414f7b14a56b03579c684aa`

The fixtures are synthetic discovery fixtures. They do **not** claim regulatory-valid eCTD v4 XML.

SD-028 and SD-029 remain reserved for future content-valid EU/US v4 fixtures.

### 4. Current BackboneXmlInventory remains v3-oriented

This is critical.

The current BackboneXmlInventory processes only `IsExactSequenceFolder = true` sequences and probes v3-style:

- `index.xml`
- `m1/eu/eu-regional.xml`

v4 submission-unit folders deliberately do not enter that path.

Therefore the current system has **physical v4 evidence**, but it does **not yet parse or inventory v4 `submissionunit.xml` as structured regulatory evidence**.

Any identification design that requires strong v4 XML evidence must explicitly identify the required evidence-capability extension. Do not pretend that current evidence already provides it.

### 5. Current ClassificationEvidenceCollection remains factual

Accepted dimensions:

- `TechnicalFormat`
- `Region`
- `SpecificationProfile`
- `DossierContext`

Current evidence values remain factual and uninterpreted.

Existing fields such as:

- `CandidateValue`
- `Polarity`
- `SourceRuleId`

remain null at collection time.

Current hierarchy concept:

- structured XML = strongest;
- declarations / official structured attributes = supporting to strong depending on source;
- physical package structure = supporting/weak;
- folder/product names = weak only.

The identification layer must consume facts. It must not rewrite evidence history.

### 6. v4 Reference semantics are explicitly deferred

A separate future task is required:

`EMAS-MS04-ECTD4-REFERENCE-SEMANTICS`

Reason:

- v4 may reuse documents across submission units;
- EU grouped/worksharing layouts may reuse documents across physical application folders;
- current v3 isolation assumptions cannot simply be extended.

This does not block identification-rule design, but identification rules must not claim reference completeness as evidence for v4 format/region until that future work exists.

### 7. FormatDetection and RegionDetection do not exist yet

Do not design around imaginary implementation.

The task is to define the **unified identification model first**, then implementation will follow.

### 8. Windows qualification remains deferred

Current accepted Mac baselines are clean.

The existing GitHub Windows PowerShell 5.1 RuntimeConfiguration UTF-8 CI failure is unrelated to RepositoryDiscovery and remains a separate issue.

Do not widen this task into Windows qualification.

## Existing accepted capability chain

Current accepted capabilities are:

1. `RepositoryDiscovery`
2. `BackboneXmlInventory`
3. `ReferenceInventory`
4. `ReferenceResolution`
5. `MissingReferenceInterpretation`
6. `DeclaredChecksumComparison`
7. `ChecksumMismatchInterpretation`
8. `ClassificationEvidenceCollection`

The v4 work extended RepositoryDiscovery behavior; it did not create a new final identification capability.

## Non-negotiable interpretation principles

- facts/evidence remain separate from interpretations;
- missing, access denied, parse failed and not collected remain distinct;
- structured XML outranks physical path/name evidence;
- physical marker presence may support a candidate but is not automatically regulatory validity;
- ASMF/DMF are dossier contexts, not technical formats;
- sequence-number gaps are observations, not compliance conclusions;
- no identification rule may claim migration readiness or regulatory validity;
- unknown/indeterminate is a valid outcome and must not be coerced into a best guess.
