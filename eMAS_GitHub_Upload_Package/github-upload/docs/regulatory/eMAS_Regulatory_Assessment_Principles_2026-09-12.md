# eMAS Regulatory Assessment Principles — 12 September 2026

**Purpose:** Repository-facing summary of regulatory principles that materially affect eMAS design. This is not an authority validation rule set.

## Fundamental boundary

eMAS is a read-only migration assessment framework. “Technical completeness” must not be represented as equivalent to formal health-authority validation, scientific assessment, customer validation, migration acceptance or business acceptance.

## Evidence chain

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

## Keep classification dimensions separate

| Dimension | Examples |
|---|---|
| Region / authority | EU, US/FDA, Canada, UK, Switzerland, Australia, Japan, Singapore |
| Technical format | eCTD v3.2.2, eCTD v4.0, NeeS, legacy/non-eCTD |
| Application/pathway type | MAA, NDA, ANDA, BLA, IND, CTA |
| Dossier/content type | Human medicinal product, ASMF, master file, investigational dossier |
| Lifecycle purpose | Initial, response, variation/supplement, renewal, update |

ASMF is a regulatory master-file/dossier concept, not a unique transport format. An ASMF may itself be supplied in eCTD.

## CTD/eCTD model

CTD Modules 2–5 provide harmonised scientific organisation. Module 1 is regional. One long-lived dossier/application can contain many regulatory activities and many sequences/submission units. A response sequence is not automatically a new dossier.

## eCTD v3.2.2 evidence

For classic v3.2.2 packages, `index.xml` is the ICH backbone carrying leaf/file relationships and lifecycle information; regional Module 1 XML provides authority-specific metadata; sequence directories/modules provide supporting structural evidence. Region must not be inferred merely because `index.xml` exists.

## EU regional assessment

For EU eCTD, examine the applicable EU Module 1 structure and version-matched `eu-regional.xml` rather than relying on an “EU” folder name. Preserve distinctions between centralised, decentralised, mutual-recognition and national procedures where evidence supports them.

## US regional assessment

For FDA eCTD, use the applicable version of `us-regional.xml` / FDA regional Module 1 profile and authoritative application identifiers. IND, NDA, ANDA, BLA and master-file contexts must not be inferred from file naming alone when stronger metadata is available.

## Additional profiles and non-eCTD

Use region-specific, versioned evidence for Canada, UK, Switzerland, Australia, Japan, Singapore and other supported profiles. Recognize NeeS/VNeeS, CTD folder structures without eCTD backbone, master files in different formats, legacy/mixed packages and unknown structures requiring manual assessment.

## Dossier/application identity

Group physical sequences into a logical dossier/application using the strongest available regulatory identifiers. Folder/product names are candidate labels, not authoritative identifiers by themselves.

## Sequence identity and gaps

A sequence set such as `0000`, `0001`, `0003` is a finding, not automatic proof of invalidity. It may represent a missing package, selected migration scope, unavailable history or export omission. Compare against lifecycle/inventory evidence.

## XML/file correlation

When XML references a leaf/document, record the referencing XML, XML path/element/attribute, referenced path, resolution result, lifecycle operation/target where applicable and evidence-scope limitations. Unresolved references and orphan files are both migration-relevant findings.

## eCTD v4 boundary

eCTD v4 uses a different RPS/submission-unit information model. It should not be detected primarily through classic v3 `index.xml` / `index-md5.txt` patterns.

## Technical assessment layers

1. Detect physical/electronic evidence.
2. Identify region, format/version, dossier/application and sequence/submission unit.
3. Assess expected structure.
4. Resolve references.
5. Assess integrity/readability within agreed depth.
6. Assess lifecycle relationships when history is available.
7. Apply source-backed regulatory technical rules for the supported profile.
8. Determine migration readiness and required remediation/exception handling.

Unavailable evidence must remain Unknown/Not Assessed with reason.

## RAG vs confidence

Severity/RAG describes effect/risk; confidence describes strength/completeness of evidence. Missing evidence must not silently become Green.

## Runtime-rule traceability

A maintained rule should be capable of linking stable RuleId, region/authority, format/version, application/dossier type, phase, physical/XML evidence, condition/operator/expected value, source/version, interpretation, severity/confidence impact, migration impact, recommendation, review status and JSON mapping.
