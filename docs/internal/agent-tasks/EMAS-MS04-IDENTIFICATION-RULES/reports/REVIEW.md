# ChatGPT Review — EMAS-MS04-IDENTIFICATION-RULES

**Status:** `REVIEW_COMPLETE — READY_FOR_USER_DECISION_WITH_AMENDMENTS`  
**Reviewed Claude commit:** `7dcef379eb5ca114c83665825a7ec5bbd54be29f`  
**Reviewed PR:** #43

## Overall verdict

Claude completed the source refresh correctly and materially improved the design by applying the canonical authority hierarchy instead of relying on the older mapping artifacts.

The core architecture recommendation is sound:

- one opt-in `IdentificationInterpretation` capability;
- facts remain in evidence collection;
- interpretation is separate;
- per-dossier/per-unit evidence is preserved;
- v4 structured XML is a separate prerequisite for strong v4 identification;
- rules are authored in the controlled workbook and exported to runtime JSON;
- FormatDetection and RegionDetection are not implemented as independent competing engines.

I recommend accepting the design **with the amendments below**.

## Source review verification

The reviewed PR changes only Claude's report.

Claude explicitly reviewed:

- all 12 canonical repository sources listed in `REQUIRED_SOURCES.md`;
- all five prior eMAS design/mapping artifacts when available locally;
- current implementation evidence;
- official ICH, EU and FDA sources.

Central review independently reconfirmed the current public source status:

- ICH publishes eCTD v4.0 Implementation Guide v1.7, endorsed June 2026;
- FDA currently lists Regional eCTD v4.0 Module 1 IG v1.9 and still lists ICH v4 IG package v1.6 as the FDA-supported ICH package;
- FDA's v1.5.1 regional package remains supported through 2027-09-28;
- EU currently lists v4 Validation Criteria v1.1 final, Practical Guidance v1, and Module 1 IG draft v1.2.

## Accepted architecture

### 1. One interpretation capability

Accept:

`IdentificationInterpretation`

It should consume normalized factual evidence, not reopen files or reparse XML.

### 2. Keep canonical master-data dimensions authoritative

Internal rule authoring must use the canonical dimensions:

- `TechnicalStandard`
- `Region`
- `Authority`
- `RegionalImplementation`
- `ProcedureContext`
- `LifecycleContext`
- other canonical dimensions only when in scope.

The MS-04 reporting names may remain:

- `TechnicalFormat`
- `Region`
- `SpecificationProfile`
- `DossierContext`

but two of these are **derived projections**, not new authoring master dimensions:

- `SpecificationProfile` = derived view over TechnicalStandard + RegionalImplementation + observed version components;
- `DossierContext` = derived view over ProcedureContext + LifecycleContext + typed application/procedure metadata.

Do not create a new flat master list that mixes MAA, NDA, ANDA, BLA, IND, DMF and ASMF into one canonical dimension. Those labels come from different regulatory concepts and must stay normalized underneath.

## Amendment 1 — do not create a second core status vocabulary

Do not add `Identified / Probable / Indeterminate / Conflicting / NotAssessed` as a new executable status system.

The canonical model already has:

- `EvaluationStatus`
- result Value / ValueSet
- `Confidence`
- `ReviewRequired`
- conflict outcome

Use those as the machine contract.

Recommended machine behavior:

- usable selected value → `EvaluationStatus = Evaluated`;
- weak-only or inadequate evidence below approved floor → `InsufficientEvidence`;
- tied/contradictory top evidence → `Conflict`;
- capability/input not collected → `NotAssessed`.

A display label such as "Probable" may be derived later for the consultant report, but must not become a parallel governed runtime status unless separately approved.

## Amendment 2 — preserve raw CEC evidence strength

Canonical requirements use:

`Strong / Medium / Weak`

Current accepted CEC records use:

`Strong / Supporting / Weak`

Do **not** rewrite historical evidence or frozen expectations in place.

Instead:

- preserve raw observed strength exactly;
- add a versioned normalization rule at the interpretation boundary:
  - `Supporting → Medium`;
- future CEC revisions may adopt the canonical vocabulary prospectively if done through a bounded versioned task.

This keeps facts immutable while allowing the interpretation layer to obey FR-CLASS-008.

## Amendment 3 — weak-only floor is a policy decision, not an implication of HighestEvidenceScore

Claude's proposed floor:

`Weak-only → InsufficientEvidence / Unknown`

is sensible and consistent with the conservative MS-04 design, but it is not automatically implied by `HighestEvidenceScore`.

Treat it as an explicit classification/confidence policy requiring Product Owner approval.

Recommended acceptance:

- Weak evidence may generate and preserve candidates;
- Weak evidence alone may not produce a final identified value;
- machine result: `EvaluationStatus = InsufficientEvidence`, Value = null, Confidence = Unknown, ReviewRequired = true;
- candidate list remains visible for consultant review.

## Amendment 4 — score semantics must remain unimplemented until governed

FR-CLASS-005 requires score preservation and FR-CLASS-006 defaults conflict resolution to `HighestEvidenceScore`, but the exact numeric weighting is governed content.

Claude's tier-dominant model is a useful design direction, but do not implement numeric weights yet.

Until Migration SME + Product Owner approval:

- Strong > Medium > Weak is the allowed precedence order;
- independent corroboration affects confidence;
- equal best-strength contradictory candidates remain Conflict;
- any decimal `WeightOrScore` values remain Draft/unapproved.

T3 must prove whether the current Runtime JSON model can express the approved scoring policy before implementation.

## Amendment 5 — dossier aggregation must not default to simple minimum confidence

Reject a universal:

`Dossier confidence = minimum confidence of all units`

A single malformed or unavailable historical unit should not automatically collapse a dossier-level identification when multiple other units provide consistent strong evidence.

Use dimension-specific aggregation:

- consistent strong evidence across units supports the dossier conclusion;
- unavailable/parse-failed units are retained as limitations and may reduce confidence according to policy;
- contradictory strong unit values create Conflict;
- legitimate lifecycle transition, such as v3 → v4, produces a multi-value/lifecycle result rather than a false conflict.

The exact confidence reduction policy remains a Product Owner / SME decision.

## Amendment 6 — separate Region from RegionalImplementation

A regional XML backbone can strongly identify a `RegionalImplementation` without necessarily proving the legal jurisdiction/application Region in every case.

Therefore:

- `eu-backbone` + EU namespace may strongly support `EU_Module1`;
- `Region = EU` may require the approved relationship and, where necessary, typed envelope/application evidence;
- the proposed EU `MaxMedium` rule remains Draft until Regulatory SME review.

This is especially important for UK/NI and historical lifecycle cases.

## Amendment 7 — contract output must be explicitly versioned

Do not rely on Runtime JSON rule `TR-JSON-006` to justify adding semantic interpretation output to the scanner observation contract.

That requirement governs Runtime JSON compatibility; it is not permission to mutate the scanner result contract.

Preferred design:

- leave `eMAS.MS04.PreSales.ScannerObservations/1.0` unchanged;
- create a separate, explicitly versioned interpretation result contract, e.g.:
  `eMAS.MS04.PreSales.Identification/1.0`;
- link it to evidence IDs, rule IDs and runtime-config provenance.

Any combined envelope can be decided later by the contract task.

## v4 decision

Accept Claude's conclusion:

- physical v4 discovery remains supporting evidence only;
- a separate `SubmissionUnitXmlInventory` capability is required for Strong v4 evidence and for reliable v4 Region/Profile/Context;
- it must remain factual and separate from interpretation;
- content-valid EU/US v4 fixtures SD-028 and SD-029 belong with that task.

## v3 / NeeS decision

Accept the bounded v3/NeeS direction with two constraints:

1. numeric folder shape and CTD module folders alone never identify a format;
2. NeeS needs positive NeeS evidence such as the controlled TOC pattern plus supporting structure and absence of contradictory eCTD backbone evidence.

## Prior mapping corrections

The prior `eMAS_PreSalesMapping.json` contains rules that conflict with the canonical model, including:

- regional implementations represented as formats;
- ASMF/DMF represented as formats;
- overconfident v4 classification from file presence.

These are now explicitly lower-authority historical design inputs.

Before the production mapping workbook exports identification rules, create a bounded correction task so those obsolete concepts cannot leak back into runtime JSON.

## Recommended implementation sequence after design acceptance

### T1a — CEC physical-marker evidence

Add factual evidence for:

- unit kind;
- NeeS TOC markers;
- checksum-file markers;
- other approved physical indicators.

Preserve raw evidence; normalize `Supporting → Medium` only in the interpretation model unless a separately versioned CEC migration is approved.

### T3 — Identification rule runtime/configuration

Validate:

- workbook rule authoring;
- runtime JSON expressiveness;
- conflict policy;
- evidence normalization;
- traceability;
- score/weight governance;
- separate Identification result contract.

No production rule weights become Effective without required approvals.

### T4 — EU v3 + NeeS identification interpretation

Implement the unified capability against currently available evidence.

Use canonical dimensions internally and derived reporting projections externally.

### T1b — Regional backbone generalisation

Add factual non-EU v3 regional XML/evelope evidence.

### T2 — v4 SubmissionUnit XML inventory

Add factual v4 structured XML evidence and content-valid SD-028/SD-029 fixtures.

### T5 — regional rule packs

One governed pack at a time, using current official sources.

### T6 — v4 Reference semantics

Remains independent from identification.

## Decisions recommended for user acceptance now

The central review recommends the following design decisions:

1. Accept one unified `IdentificationInterpretation` capability.
2. Accept canonical underlying dimensions with derived `SpecificationProfile` and `DossierContext` report projections.
3. Accept Weak-only evidence as candidate-only, not sufficient for a final value.
4. Accept no new executable "Probable" status vocabulary.
5. Accept raw CEC evidence preservation with `Supporting → Medium` normalization at interpretation time.
6. Accept a separate versioned Identification output contract.
7. Reject universal minimum-of-unit dossier confidence; use dimension-specific aggregation.
8. Keep EU Region confidence policy Draft pending Regulatory SME review.
9. Keep numeric scoring/weights Draft pending Migration SME + Product Owner approval.
10. Keep FormatDetection and RegionDetection as non-separate capabilities; the unified interpretation capability replaces that planned split.

## Recommendation

**Accept the Identification Rules design with the central-review amendments above.**

After user acceptance, merge the report/coordination task and create T1a and T3 as the next bounded tasks. T1a and T3 are genuinely separable and may proceed in parallel if desired; T4 waits for both.
