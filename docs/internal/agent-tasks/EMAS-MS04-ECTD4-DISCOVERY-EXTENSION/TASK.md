# EMAS-MS04-ECTD4-DISCOVERY-EXTENSION

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-EXTENSION`  
**Authoritative base commit:** `70f1edf9584477d229ef8b321cb7172734669cca`  
**Base branch:** `demo/end-to-end-mvp`  
**Task type:** Required eCTD v4 discovery-extension gate before FormatDetection  
**Execution model:** Sequential, single worker after B3 RepositoryDiscovery implementation is accepted  
**Current status:** Blocked until `EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-IMPLEMENTATION` is accepted

## Purpose

Establish and implement the RepositoryDiscovery behavior required for genuine eCTD v4 repository/submission-unit structures before eMAS is allowed to implement or claim eCTD v4 FormatDetection.

The accepted B3 rule applies to the existing four-digit-sequence v3/NeeS path. It is **not** sufficient to establish general eCTD v4 discovery.

## Mandatory evidence gate

Before changing code, the worker must establish the v4 physical/discovery model from authoritative sources, prioritizing current official ICH and regional implementation guidance.

At minimum resolve:

- how eCTD v4 submission-unit/sequence directories are named;
- whether leading-zero four-digit names are required, optional, or inappropriate;
- where `submissionunit.xml` sits relative to the submission-unit directory;
- which physical CTD/module structures are reliable discovery signals;
- whether multiple submission units/dossiers can coexist in one export;
- wrapper-folder behavior;
- what can be determined from structure without performing FormatDetection;
- regional differences that affect physical discovery.

Do not infer these rules from v3.2.2 or from folder names.

## Source requirements

The report must cite authoritative sources precisely enough to audit the decision:
- ICH eCTD v4 implementation/specification material;
- relevant FDA/eCTD v4 implementation guidance where used;
- additional official regional guidance only where needed.

Secondary blogs or vendor material may explain a point but must not define normative discovery behavior.

## Test-data requirement

Before claiming v4 discovery support, create or obtain an authoritative-structure test fixture whose layout is traceable to the source material.

Synthetic fixture bytes are acceptable when the **structure** is derived from official specifications and clearly labelled synthetic. Do not pretend a renamed v3 dossier is a v4 submission.

The fixture must test at least:
- a first v4 submission unit using the authoritative numeric naming convention;
- a later submission unit;
- wrappers;
- unrelated numeric/year folders;
- root-level vs wrapped placement where legitimate;
- `submissionunit.xml` structural signal;
- no accidental v3-only assumptions.

## Separation of concerns

RepositoryDiscovery may use safe physical structure to identify plausible candidate boundaries.

It must not:
- parse v4 regulatory meaning to classify format/region;
- infer region from path names;
- treat product/dossier text as authoritative;
- implement ContextOfUse/DocumentReference interpretation;
- claim regulatory validity.

Those belong to later v4 inventory/FormatDetection capabilities.

## Required output

The task must produce:

1. an authoritative v4 physical-layout decision;
2. a scenario/acceptance matrix;
3. versioned v4 test fixture(s);
4. the smallest RepositoryDiscovery extension needed for v4, if any;
5. Mac regression showing no drift in accepted v3/NeeS Wave 1/Wave1D behavior;
6. a report stating exactly what v4 discovery is and is not supported.

## FormatDetection gate

`FormatDetection` and `RegionDetection` must not begin until:

1. the B3 RepositoryDiscovery implementation is accepted; and
2. this eCTD v4 discovery-extension task is accepted.

## Windows

Native Windows PowerShell 5.1 qualification remains part of the later consolidated MS-04 release qualification unless this task discovers a platform-specific issue requiring earlier verification.
