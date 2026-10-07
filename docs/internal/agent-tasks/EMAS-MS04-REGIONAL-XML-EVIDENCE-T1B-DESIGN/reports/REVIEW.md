# ChatGPT Review — T1b Regional XML Evidence Design

**Status:** `CHANGES_REQUIRED — DESIGN IS SOUND, CENTRAL AMENDMENTS RECORDED`  
**Reviewed Claude commit:** `89c8a5ef069b89a9aee0da90bf7b56b4e0b61d52`  
**Reviewed PR:** #59

## Overall verdict

The T1b design is strong and source-disciplined.

Central review accepts the core direction:

- EU Module 1 first;
- five typed envelope facts;
- official EMA EU M1 specifications as authority;
- historical DTD profiles 2.0 / 3.0.1 / 3.1;
- raw structured facts only;
- no Region / Procedure / Lifecycle conclusion inside scanner or CEC;
- no XML reopening in CEC;
- Option A architecture: extract envelope facts during the existing BackboneXmlInventory parse;
- additive ScannerObservations/1.0 extension;
- raw CEC `Strong` / `StructuredXml` for the five verified typed fields;
- T4 projection remains a later, separate task.

The official v3.1 source independently confirms the core machine-readable structure used by the report: the envelope contains mandatory `submission`, `submission-unit`, `agency` and `procedure` elements; `submission/@type`, `submission-unit/@type`, `agency/@code`, `procedure/@type` and `envelope/@country` are DTD-controlled required attributes.

The report needs a small amendment before acceptance, mainly to avoid making unresolved semantic decisions through the legacy CEC `Dimension` hint and to preserve historical CEC record shape.

## Central decision C-1 — Architecture / P-1

**ACCEPT Option A.**

T1b may modify the RC1-frozen `eMAS.BackboneXmlInventory.psm1`, provided the resulting capability is re-qualified.

Reason:

- BackboneXmlInventory already performs the safe XML parse;
- extracting the envelope during the same parse avoids duplicate XML reads/parses;
- CEC remains source-independent;
- freezing an RC1 file is a qualification baseline, not a permanent architectural prohibition.

Therefore P-1 is closed:

> extend BackboneXmlInventory through a private EU envelope helper and rerun the required RC1/scanner qualification gates.

Do not choose duplicate parsing merely to preserve the previous RC1 file hash.

## Central decision C-2 — CEC Dimension compatibility / P-5

**Do not extend the CEC `Dimension` hint vocabulary in T1b.**

The current CEC `Dimension` field is a legacy/uninterpreted hint, and T4 explicitly ignores it when choosing canonical Identification dimensions.

Adding `Authority`, `ProcedureContext` and `LifecycleContext` here would create unnecessary contract drift and, more importantly, would partially pre-decide P-2/U5 semantics that remain open.

For bounded T1b, use only existing compatibility hints:

| EvidenceType | CEC Dimension hint |
|---|---|
| `EuEnvelopeCountry` | `Region` |
| `EuAgencyCode` | `Region` |
| `EuProcedureType` | `DossierContext` |
| `EuSubmissionType` | `DossierContext` |
| `EuSubmissionUnitType` | `DossierContext` |

These are **compatibility buckets only**. They are not canonical target dimensions and must not be consumed by IdentificationInterpretation.

The later governed `CEC-FIELD-PROJECTION/2` decides the actual canonical target dimension(s).

Therefore P-5 is closed as:

> no new CEC Dimension codes in T1b.

## Required amendment A-1 — historical CEC record shape

The proposal currently adds `SourceOrdinal = null` to every historical CEC record.

Do not do that.

Preserve the exact historical record shape wherever possible.

Required design:

- add an optional `SourceOrdinal` (or `EnvelopeOrdinal`) property **only to the new T1b envelope evidence records**;
- do not add a null property to historical evidence records;
- include the ordinal in the new-record deterministic sort key;
- keep every existing historical EvidenceId unchanged.

This keeps the additive contract genuinely additive instead of rewriting every existing evidence object merely to support multi-envelope traceability.

## Central decision C-3 — raw strength

**ACCEPT all five first-wave facts as raw `Strong` / `StructuredXml`.**

This strength applies to the factual observation:

> the parsed regional XML contains this profile-recognized typed value.

It does **not** mean:

- the submission is regulatory-valid;
- the value proves Region;
- the value proves ProcedureContext;
- the value proves LifecycleContext;
- the XML is DTD-valid as a whole.

Future Identification rules remain responsible for dimension-specific strength/capping and conflict behavior.

## Central decision C-4 — profile vocabulary checks

**ACCEPT profile-specific embedded vocabulary checks.**

The parser remains non-validating and must not resolve external DTDs.

For the three supported profiles, T1b may compare raw values against source-verified Appendix 3 enumerations.

Keep these distinctions:

- raw value present + recognized => factual Strong CEC record;
- raw value present + outside profile vocabulary => preserve raw value in BXI, emit no Strong CEC record, add field-specific coverage reason;
- mandatory field absent => factual assessed absence / coverage issue;
- field not defined in profile => unavailable, never absent;
- XML parse failure / missing / inaccessible => unavailable;
- unsupported DTD profile => unavailable.

Do not call this DTD validation or regulatory validation.

## Central decision C-5 — Centralised Procedure country inconsistency

The report correctly found an official-source inconsistency in EU M1 v3.1:

- narrative text says the Centralised Procedure envelope country should be `EU-EMA`;
- the DTD enumeration permits `ema`;
- `EU-EMA` is an agency code.

For machine parsing, **follow the DTD/App. 1.1 controlled value**.

Keep the source conflict documented for Regulatory SME review, but it does not block T1b evidence collection.

A literal `EU-EMA` in `envelope/@country` is therefore outside the supported DTD vocabulary and must not be normalized silently.

## Central decision C-6 — ScannerObservations version

**ACCEPT additive ScannerObservations/1.0 extension.**

The new `XmlDocuments[].RegionalEnvelope` object is optional and owned by BackboneXmlInventory.

Do not create an application identity or new dossier identity.

Increment the scanner implementation version, not the ScannerObservations contract major/minor identifier.

## Central decision C-7 — T4 impact / P-7

T1b evidence collection does **not** require a T4 contract change.

The five new evidence types may be collected while `CEC-FIELD-PROJECTION/1` continues to ignore them.

A separate later task must define governed projection/consumption semantics before any Effective Identification rule uses these fields.

That later task must handle:

- multi-envelope values;
- field-specific coverage/unavailable reasons;
- dimension-scoped target mapping;
- `UnrecognizedValue` / ambiguity semantics;
- no relationship-derived Region until U2/B-7 is settled.

P-7 remains future work, not a blocker for T1b collection.

## Non-blocking open decisions

The following remain intentionally open and do **not** block first-wave factual collection:

- P-2: where authorisation procedure belongs canonically;
- P-3: cross-version aliases such as `initial-maa` vs `maa`;
- P-4: EU 1.4.x / 3.0 support;
- P-6: envelope UUID/application grouping;
- U2–U9 regulatory interpretation policy;
- relationship-derived Region;
- ProcedureContext semantics for ASMF/PMF/CEP.

## Required report amendment

Claude should update only the task-owned report/status files to:

1. record C-1 through C-7;
2. remove P-1 and P-5 from the unresolved blocker list;
3. replace the proposed new CEC Dimension codes with the compatibility mapping in C-2;
4. change the `SourceOrdinal` design so only new envelope evidence records receive it;
5. state explicitly that profile vocabulary checking is not DTD/regulatory validation;
6. mark the EU-EMA vs ema source conflict as non-blocking for collection;
7. change the implementation prerequisite from “after P-1 and P-5” to “after central acceptance of this amended design”.

## Acceptance after amendment

After the report is amended:

- no production code is changed;
- PR #59 remains draft;
- ChatGPT performs a short fixed-SHA re-review;
- if the amendment matches this review, T1b design can be accepted and merged into the coordination branch;
- only then should the bounded implementation task be created.


## Fixed-SHA re-review

**Reviewed amended commit:** `5eee04bbb059da5b62394d35aae8bfc0d26d413d`  
**Result:** `ACCEPTED — READY_FOR_USER_MERGE_DECISION`

The required amendments are correctly applied.

Central re-review confirms:

- C-1 through C-7 are recorded and consistent with the central review;
- P-1 is closed: Option A is the approved architecture and BXI re-qualification is mandatory;
- P-5 is closed: no new CEC `Dimension` codes are introduced;
- the legacy compatibility mapping is exactly:
  - `EuEnvelopeCountry -> Region`;
  - `EuAgencyCode -> Region`;
  - `EuProcedureType -> DossierContext`;
  - `EuSubmissionType -> DossierContext`;
  - `EuSubmissionUnitType -> DossierContext`;
- the report clearly states these hints are not canonical Identification target dimensions;
- `SourceOrdinal` exists only on new T1b envelope evidence records;
- historical CEC record shape and historical EvidenceIds are preserved;
- profile-vocabulary comparison is explicitly distinguished from DTD/regulatory validation;
- the `ema` / `EU-EMA` source conflict remains documented and non-blocking;
- the bounded implementation task now begins only after central acceptance of this design;
- remaining P-2/P-3/P-4/P-6/P-7 and S-1…S-5 decisions are correctly treated as non-blocking for first-wave factual collection;
- no production code, fixture, test, schema, workbook or T4 file was modified by the amendment.

### Final design verdict

**T1b EU regional-envelope design is accepted.**

The approved first-wave collection baseline is:

- EU M1 DTD profiles `2.0`, `3.0.1`, `3.1`;
- five typed envelope facts;
- Option A extraction during the existing BXI parse;
- additive `ScannerObservations/1.0` shape;
- raw `Strong / StructuredXml` factual evidence;
- CEC remains fact-only and never reopens XML;
- T4 projection/interpretation remains a separate later task.

### Recommendation

Accept and merge PR #59 into `coordination/emas-ms04-regional-xml-evidence-t1b-design` as the T1b design baseline.

After that merge, create the bounded implementation task:

`EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`.
