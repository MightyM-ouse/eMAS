# ChatGPT Review — EMAS-MS04-REPOSITORY-DISCOVERY-CANDIDATE-SEMANTICS

**Status:** `DECISION_ACCEPTED — IMPLEMENTATION AUTHORIZED AS SEPARATE TASK`  
**Reviewed Claude commit:** `2a5c7098e543d053e73ca61c3d7192995d35b72f`  
**Reviewed PR:** #34

## Overall verdict

Claude's analysis is strong and the core B3 approach is the correct direction for the current v3/NeeS-oriented discovery baseline.

The current rule ("any parent with an exact four-digit child is a dossier") should not remain normative. The newly identified `Exports/2024/ProductABC` failure is more serious than SD-051 because the current shallowest-first rule can hide a genuine dossier while still reporting the scan as completed.

I recommend accepting the **B3 structural-promotion principle**, with the amendments below before implementation.

## Accepted core semantics

For the current four-digit-sequence discovery path, a parent should be promoted to a dossier only when at least one direct exact-sequence child has a direct structural signal:

- module directory `m1` through `m5`, case-insensitive; or
- backbone file `index.xml` or `submissionunit.xml`, case-insensitive; or
- the exact sequence directory itself could not be enumerated, so absence of structure cannot be established safely.

Nested-candidate suppression should then operate only on promoted candidates.

This preserves the accepted Wave 1/Wave1D corpus, removes SD-051's `Archive` false candidate, and avoids a year-wrapper candidate swallowing a deeper genuine dossier.

## Required amendment 1 — fail-open scope

Claude's pseudocode allows fail-open when the exact sequence child **or any descendant** is unreadable.

That is broader than necessary.

Because the allowed structural signals are direct children of the sequence directory, fail-open should trigger when the **exact sequence directory itself cannot be enumerated**. If that directory can be enumerated, its direct structural signals are already knowable. An unrelated unreadable deeper descendant should not by itself promote an otherwise structureless year folder.

Implementation should therefore use the inventory error recorded for the exact sequence path, while still preserving downstream access-denied evidence.

## Required amendment 2 — do not claim eCTD v4 discovery compatibility yet

The report correctly notes uncertainty around v4 sequence naming, but this is now resolved enough to affect the decision.

Official ICH/FDA eCTD v4 material describes the submission-unit directory as the **sequence number** and gives examples such as `1`, `2`, etc. FDA also states that v4 sequence numbers are whole numbers rather than the v3.2.2 four-digit values with leading zeroes.

Therefore the current `^\d{4}$` discovery gate is **not sufficient for general eCTD v4 discovery**.

B3 should be accepted as the fix for the current four-digit/v3/NeeS path, but the project must not claim v4 discovery support from it. A separate explicit v4 discovery-extension decision/test must be completed before FormatDetection can claim eCTD v4 support.

## Decisions on U1–U6

### U1 — empty/structureless numeric repositories

Recommendation: **accept non-promotion for now**, but record this as an explicit known ambiguity for Phase 1.

A completely empty or structureless numeric container is not enough evidence to call something a dossier. Repository inventory still preserves the files/folders. An additive "numeric container not promoted" observation would improve consultant visibility, but it is not required to accept the candidate rule and should not be smuggled into the bounded implementation without its own expectation change.

### U2 — residual false positives with `index.xml` or `m1`

Recommendation: **accept as a bounded residual risk**.

RepositoryDiscovery discovers plausible structures; it does not prove a regulatory format. Future FormatDetection must require a **recognized structured regulatory backbone signature**, not merely "an XML file parsed successfully". Folder names or the mere presence of an `index.xml` filename must never be sufficient for format classification.

### U3 — year-like folder inside a genuine dossier

Recommendation: **defer**.

This is sequence-membership semantics, not dossier-candidate semantics. Fixing it safely is harder because accepted cases such as an empty exact sequence must remain represented. It does not block the B3 candidate fix.

### U4 — case sensitivity

Recommendation: **case-insensitive structural-name matching** for discovery.

This avoids accidental platform-dependent false negatives and does not turn names into regulatory conclusions.

### U5 — eCTD v4 folder naming

Recommendation: **mark current discovery as not yet v4-complete**.

The v4 path needs a separate authoritative sample/spec-based extension because whole-number sequence folder naming differs from the v3 four-digit convention.

### U6 — unreadable sequence reported as empty

Recommendation: **treat as a separate RepositoryDiscovery defect and fix it before Phase 1 qualification**.

`AccessDenied` and `Empty` are not equivalent. This violates the project's state-separation principle. It can be handled in the same future RepositoryDiscovery implementation wave if kept as a separately tested behavior, or immediately afterward as a tiny follow-up.

## Recommended implementation boundary after user acceptance

The implementation task should:

1. implement B3 promotion for the existing exact-four-digit sequence path;
2. fail open only when the exact sequence directory itself cannot be enumerated;
3. keep case-insensitive matching for `m1`–`m5`, `index.xml`, and `submissionunit.xml`;
4. update/version SD-051 expectations rather than editing the frozen characterization in place;
5. add the year-wrapper regression (`Exports/2024/ProductABC`);
6. run Wave 1, root-level, and Wave1D regression;
7. separately test/fix the unreadable-sequence-as-empty defect;
8. make no FormatDetection/RegionDetection change.

A later explicit discovery-extension task must establish real eCTD v4 sequence-folder handling before v4 detection is implemented or claimed.

## User decision

Accepted. The B3 principle is approved with the two amendments above. A separate bounded RepositoryDiscovery implementation task is authorized. eCTD v4 sequence discovery is a separate required task before FormatDetection or RegionDetection may begin.
