# eMAS Regulatory Assessment Principles — 12 September 2026

**Companion to:** eMAS Regulatory, Technical & Migration Assessment Guide v1.0  
**Regulatory source review date in source guide:** 12 September 2026  
**Purpose:** Repository-facing summary of the regulatory principles that materially affect eMAS design. This is not the full source guide and is not an authority validation rule set.

## 1. Fundamental boundary

eMAS is a read-only migration assessment framework. “Technical completeness” in eMAS must not be represented as equivalent to:

- formal health-authority validation;
- scientific assessment;
- customer validation;
- migration acceptance;
- business acceptance.

A migration finding must be labelled according to its actual basis: regulatory requirement, regulatory interpretation, eMAS detection/business rule, technical recommendation or migration-risk observation.

## 2. Evidence chain

The core traceability pattern is:

```text
Authoritative regulatory source
        ↓
Regulatory interpretation
        ↓
Physical / XML evidence
        ↓
eMAS RuleId
        ↓
Finding
        ↓
Severity + Confidence
        ↓
Migration action / recommendation
```

A rule should retain the exact evidence location whenever practical, not merely “check XML”.

## 3. Keep classification dimensions separate

Do not store a single ambiguous “dossier format/type” value. At minimum distinguish:

| Dimension | Examples |
|---|---|
| Region / authority | EU, US/FDA, Canada, UK, Switzerland, Australia, Japan, Singapore |
| Technical format | eCTD v3.2.2, eCTD v4.0, NeeS, legacy/non-eCTD |
| Application/pathway type | MAA, NDA, ANDA, BLA, IND, CTA |
| Dossier/content type | Human medicinal product, ASMF, master file, investigational dossier |
| Lifecycle purpose | Initial, response, variation/supplement, renewal, update |

### ASMF

ASMF is a regulatory master-file/dossier concept, not a unique electronic transport format. An ASMF may itself be supplied in eCTD. Therefore an ASMF conclusion must not overwrite the separate technical-format or region fields.

## 4. CTD/eCTD model

CTD Modules 2–5 provide the harmonised scientific organisation. Module 1 is regional. For migration assessment this means that scientific content can be structurally similar across regions while application identifiers, authority metadata, procedure details and Module 1 layout differ.

One long-lived dossier/application can contain many regulatory activities and many sequences/submission units. A response sequence is not automatically a new dossier.

## 5. eCTD v3.2.2 evidence

For classic v3.2.2 packages:

- `index.xml` is the ICH backbone and carries leaf/file relationships and lifecycle information;
- regional Module 1 XML provides authority/region-specific administrative metadata;
- sequence directories and physical modules provide supporting structural evidence;
- `index-md5.txt`/checksums are format/integrity evidence where applicable to the relevant implementation and phase.

Region must not be inferred merely because `index.xml` exists. The same ICH backbone concept is used across multiple regional implementations.

## 6. EU regional assessment

For EU eCTD, eMAS should examine the applicable EU Module 1 structure and the version-matched `eu-regional.xml` rather than relying on an “EU” folder name alone. Procedure/application context, envelope metadata, submission context and country/procedure evidence must be extracted from the exact supported EU regional profile.

“EU” is not synonymous with “EMA”. Centralised, decentralised, mutual-recognition and national procedures have different authority/procedure contexts. eMAS should preserve those distinctions when evidence supports them.

## 7. US regional assessment

For FDA eCTD, use the applicable version of `us-regional.xml` / FDA regional Module 1 profile and authoritative application identifiers. IND, NDA, ANDA, BLA and master-file contexts must not be inferred from file naming alone when stronger application metadata is available.

Application number, submission type/subtype and regulatory activity context are version/profile-specific extraction concerns. Implement parsers and rules against an explicit supported profile rather than assuming EU-style element names.

## 8. Additional regional profiles

The source guide discusses Canada, UK, Switzerland, Australia, Japan and Singapore in addition to EU and US. eMAS should use region-specific physical/XML evidence and versioned sources for each supported profile. Never generalise one region's Module 1 hierarchy or XML tag names to all others.

## 9. Non-eCTD and legacy formats

eMAS must recognize that not every regulatory package is eCTD. Relevant contexts include:

- NeeS;
- VNeeS where applicable;
- CTD folder/electronic structures without an eCTD backbone;
- ASMF/master-file content delivered in different technical formats;
- legacy or mixed packages;
- unknown structures requiring manual assessment.

Absence of eCTD XML combined with CTD folders can be useful evidence for a non-eCTD format, but it can also represent an incomplete export or working copy. Confidence must reflect that ambiguity.

## 10. Dossier/application identity

Multiple physical sequence folders should be grouped into a logical dossier/application using the strongest available regulatory identifiers. Folder/product names are candidate labels, not authoritative identifiers by themselves.

Identity evidence can include application/procedure numbers and regional metadata, supported by customer-confirmed metadata with provenance where necessary.

## 11. Sequence identity and gaps

Classic v3 sequence folder naming is useful physical evidence, but eMAS must assess continuity in context.

Example:

```text
0000
0001
0003
```

The absence of `0002` in the scanned export is a finding, not automatic proof of an invalid dossier. It may reflect a genuinely missing package, selected migration scope, incomplete history or an export omission. Compare against lifecycle/inventory evidence and adjust confidence/readiness appropriately.

## 12. XML/file correlation

When XML references a leaf/document, eMAS should resolve the reference against the correct package/context and record:

- referencing XML;
- XML path/element/attribute where relevant;
- referenced path;
- resolution result;
- lifecycle operation/target where applicable;
- evidence scope and missing-history limitations.

Unresolved references are stronger findings than orphan files, but both are relevant to migration completeness.

## 13. eCTD v4 boundary

eCTD v4 uses a different RPS/submission-unit information model. It should not be detected primarily through the classic v3 `index.xml` / `index-md5.txt` pattern. eMAS must use a version-appropriate v4 evidence model and controlled vocabulary/profile sources.

## 14. Technical assessment layers

A defensible technical-completeness assessment can progress through:

1. Detect physical/electronic evidence.
2. Identify region, format/version, dossier/application and sequence/submission unit.
3. Assess expected structure.
4. Resolve references.
5. Assess integrity/readability within agreed depth.
6. Assess lifecycle relationships when history is available.
7. Apply source-backed regulatory technical rules for the supported profile.
8. Determine migration readiness and required remediation/exception handling.

A layer that cannot be executed due to missing evidence must remain Unknown/Not Assessed with reason.

## 15. RAG vs confidence

Severity and confidence are independent:

- **Severity/RAG:** effect/risk of the observed condition.
- **Confidence:** strength and completeness of evidence supporting the conclusion.

Do not convert missing evidence to Green. Do not lower severity merely because confidence is low; instead record both dimensions.

## 16. Source currency

The source guide states that regulatory sources were verified against authoritative sites available on 12 September 2026. Before controlled release of rules, confirm that the exact authority specification/version is still effective for the targeted profile and historical date range.

## 17. What belongs in runtime rules

A maintained regulatory/migration rule should be capable of linking:

- stable RuleId;
- region/authority;
- format and version;
- application/dossier type;
- phase/applicability;
- physical evidence location;
- XML file/path/element/attribute where relevant;
- condition/operator/expected value;
- regulatory source and source version;
- eMAS interpretation;
- severity impact;
- confidence impact;
- migration impact;
- recommendation;
- review status and JSON mapping.

This provides the bridge from regulatory knowledge to deterministic, reviewable migration assessment without hardcoding regulatory conclusions in PowerShell.
