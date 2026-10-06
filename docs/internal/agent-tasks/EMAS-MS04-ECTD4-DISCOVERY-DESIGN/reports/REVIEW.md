# ChatGPT Review — EMAS-MS04-ECTD4-DISCOVERY-DESIGN

**Status:** `REVIEW_COMPLETE — READY_FOR_USER_DECISION_WITH_AMENDMENTS`  
**Reviewed Claude commit:** `59f0596f3b7ef6f994655b0d06a93f0414a4050e`  
**Reviewed PR:** #39

## Overall verdict

Claude's research is strong and the core v4-specific structural-discovery direction is correct.

The source review correctly establishes that eCTD v4 must not be treated as a simple widening of the existing four-digit v3/NeeS rule. A submission unit is a distinct physical concept, the sequence folder uses the actual numeric value, and `submissionunit.xml` is the primary physical marker.

I recommend accepting the design **with the amendments below** before implementation.

## Independently verified source points

Central review independently checked the current official ICH, FDA and EU/EMA material.

- ICH currently publishes eCTD v4.0 Implementation Guide v1.7, endorsed June 2026.
- ICH support material shows the submission unit folder name as the sequence number (examples `1`, `2`), with `submissionunit.xml` and `sha256.txt` directly in that folder.
- FDA Regional Module 1 IG v1.9 states that FDA does not use the regionally specified outer folder and requires the sequence-number folder to use the actual sequence number, e.g. `1`.
- EU Practical Guidance v1.0 uses a required first-level folder plus a second-level sequence-number folder; the sequence number is a positive whole number 1..999999, and `submissionunit.xml` / `sha256.txt` are direct contents.
- EU currently publishes Module 1 IG draft v1.2 and Validation Criteria v1.1 final.
- Regulatory-version nuance: ICH's latest harmonized IG is v1.7, while FDA's current submission-standards page still lists ICH IG package v1.6 as the FDA-supported ICH package. The implementation task must not equate "latest ICH" with "regionally adopted version" without checking the regional standards page.

## Accepted core design

For physical discovery:

1. Keep the accepted v3/NeeS B3 path.
2. Introduce a separate v4 submission-unit path for direct numeric children whose names are 1–6 digits.
3. Direct presence of `submissionunit.xml` is the primary v4 structural marker.
4. The parent of one or more classified unit folders remains the existing physical `DossierCandidates` container abstraction.
5. A v4 submission-unit folder must **not** be emitted as `IsExactSequenceFolder = true`, otherwise the current v3 BackboneXmlInventory would create false v3 missing-backbone observations.
6. RepositoryDiscovery remains physical only: no XML parsing, no region inference, no application identity inference.

## Required amendment 1 — no new fail-open candidacy for arbitrary non-four-digit numeric folders

Reject Claude U2 as proposed.

The accepted B3 fail-open rule exists for the already-established four-digit v3/NeeS path. It should **not** be generalized to arbitrary 1–6 digit folders solely because they are unreadable.

Example: an unreadable `Photos/1/` provides no v4 structural evidence. "Unknown is not absent" does not mean "unknown is a v4 submission unit."

Normative rule:

- four-digit unreadable exact sequence: existing B3 fail-open remains unchanged;
- non-four-digit 1–6 digit unreadable folder with no visible v4 marker: retain the repository access/enumeration error, but **do not promote** a dossier candidate.

If a directly listed `submissionunit.xml` is visible but reading the file later fails, candidacy remains because the marker presence is known.

## Required amendment 2 — conflicting v3/v4 backbone markers must remain ambiguous

Reject the proposed U5 precedence that silently keeps a folder containing both `index.xml` and `submissionunit.xml` on the v3 path.

Those are contradictory structural facts. Choosing v3 would cause the current v3 BackboneXmlInventory to run and could manufacture v3-specific missing-backbone findings for an ambiguous package.

Instead:

- promote the parent as a physical candidate;
- record the child using a neutral/ambiguous structural kind, e.g. `ConflictingBackboneMarkers` / `AmbiguousRegulatoryUnitFolder`;
- emit a factual conflict observation;
- set it so the current v3 BackboneXmlInventory does **not** treat it as an exact v3 sequence;
- leave final interpretation to later FormatDetection after structured XML inspection.

No region or format conclusion is allowed from the filename conflict alone.

## Required amendment 3 — damaged v4 fallback is candidate evidence, not confirmed v4

Accept Claude U1 with a stricter meaning.

A numeric folder with:

- no `index.xml`;
- no `submissionunit.xml`;
- direct `sha256.txt`; and
- at least one direct `m1`–`m5` folder

may promote its parent as a **damaged/v4-like structural candidate** so that incomplete packages are not silently lost.

However:

- RepositoryDiscovery must not call this confirmed eCTD v4;
- the sequence/unit kind must make the missing primary marker explicit;
- later FormatDetection must not classify the dossier as v4 from this fallback alone.

This preserves the Pre-Sales objective of surfacing incomplete packages while keeping facts separate from interpretation.

## Required amendment 4 — misplaced marker should be observable but not promoted

For a `submissionunit.xml` directly at archive root or inside a non-numeric folder:

- do not promote a v4 submission-unit candidate;
- add an additive factual observation such as `UnplacedSubmissionUnitMarker`.

The source structure is wrong, but silently ignoring a strong regulatory filename would reduce consultant visibility.

## Decisions on Claude U1–U8

| Question | Central-review decision |
|---|---|
| U1 `sha256.txt` + module fallback | **Accept with amendment:** damaged/v4-like candidate only, never sufficient for final v4 classification. |
| U2 unreadable non-four-digit numeric folder | **Reject promotion.** Preserve error only. B3 fail-open stays limited to existing four-digit path. |
| U3 unplaced `submissionunit.xml` | **Observe, do not promote.** |
| U4 mixed case | **Detect case-insensitively; preserve exact spelling; later conformance layer may flag non-canonical case.** |
| U5 both `index.xml` and `submissionunit.xml` | **Do not choose v3. Treat as ambiguous/conflicting structural unit.** |
| U6 EU grouped cross-container reuse | **Separate mandatory v4 ReferenceResolution design before claiming v4 reference/integrity support.** Does not block physical discovery implementation. |
| U7 application identity | **Accept.** Do not redefine `DossierCandidates` as application identity. Derive application identity later from v4 XML. |
| U8 first v4 sequence number conflict | **Do not enforce lifecycle numbering in RepositoryDiscovery.** Detect 1..999999 structure only; later region/lifecycle interpretation handles the rule. |

## Regional/version amendment

Before implementation, the worker must verify the physical folder rules against every **currently supported regional version in scope**, not just the newest document.

For FDA specifically:

- Regional M1 IG v1.9 is current;
- the older Module 1 package v1.5.1 remains supported until 2027-09-28;
- FDA currently lists ICH IG package v1.6 as its supported ICH package even though ICH itself has published v1.7.

If v1.5.1 or FDA's supported ICH v1.6 differ materially on physical discovery, the fixture matrix must represent that. If they do not, record the equivalence.

## Fixture-plan adjustments

Wave 1E SD-053–SD-074 is a good range.

Required changes:

- SD-064 must not assert that unreadable non-four-digit `Pkg/5` is automatically a v4 candidate. Add a separate four-digit unreadable case for existing B3 fail-open and a non-four-digit unreadable negative case.
- SD-066 should assert `UnplacedSubmissionUnitMarker` while still producing no v4 unit candidate.
- SD-073 conflicting markers must expect an ambiguous structural unit, not v3 precedence.
- keep SD-071 leading-zero case detectable but non-canonical; do not treat it as regulatory-valid.
- keep SD-028/SD-029 reserved for later content-valid regional XML fixtures.

## Downstream gate discovered by this review

The current v3 ReferenceInventory/ReferenceResolution isolation model is not sufficient for all v4 cases.

ICH supports document reuse across submission units, and EU grouped/worksharing structures may reuse files across physical application folders. Therefore:

`EMAS-MS04-ECTD4-REFERENCE-SEMANTICS`

must be completed before eMAS claims v4 reference completeness/file-integrity support.

This task does **not** need to block the bounded physical RepositoryDiscovery implementation.

## Implementation boundary after user acceptance

A separate implementation task may then:

1. extend RepositoryDiscovery with a v4 submission-unit classifier;
2. preserve B3 unchanged for v3/NeeS;
3. use `submissionunit.xml` as the primary marker;
4. use the bounded damaged-marker fallback above;
5. add the ambiguous conflicting-marker path;
6. add unplaced-marker observations;
7. keep v4 units out of v3 `IsExactSequenceFolder` processing;
8. build/freeze Wave 1E using source-backed synthetic physical fixtures;
9. run Wave 1, root-level, Wave1D, B3 and new v4 discovery regression on Mac;
10. make no FormatDetection/RegionDetection/ReferenceResolution implementation changes.

## Recommendation

**Accept the v4 physical-discovery design with these amendments and authorize a separate implementation task.**

FormatDetection/RegionDetection remain blocked until the v4 physical discovery implementation is accepted.

The v4 reference-semantics task is a separate downstream prerequisite before final v4 reference/integrity claims.
