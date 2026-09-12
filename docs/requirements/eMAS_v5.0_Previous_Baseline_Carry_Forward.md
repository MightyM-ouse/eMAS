# eMAS v5.0 — Previous Baseline Carry-Forward Register

**Purpose:** Identify which requirements/concepts from the previous repository baseline remain relevant to the new simplified Excel/SharePoint architecture, which are superseded, and which need controlled review.

**Target branch:** `requirements/v5.0-excel-sharepoint`  
**Prepared:** 12 September 2026

---

## 1. Carry-forward decisions

| Previous concept | v5.0 disposition | Notes |
|---|---|---|
| Three phases: Pre-Sales, Pre-Migration, Post-Migration | Keep | Core product model remains unchanged. |
| Read-only source assessment | Keep | Fundamental safety boundary. |
| Shared PowerShell engine | Keep | Remains the runtime assessment engine. |
| Phase-specific execution depth | Keep | Pre-Sales lightweight; Pre/Post deeper. |
| Phase-specific Excel reports | Keep and strengthen | Excel becomes the primary human review experience. |
| Internal Mapping Workbook | Keep, but macro-free `.xlsx` | Replaces XLSM/VBA production route. |
| SharePoint authoring repository | Keep | Internal collaboration/version history/control. |
| Runtime JSON | Keep | Machine-readable runtime source. |
| JSON-first contract | Keep | JSON schema independent from workbook presentation. |
| Office Scripts / TypeScript | Keep | Validation/transformation only; not migration-rule engine. |
| Power Automate | Keep as optional release orchestration | Not required for customer runtime. |
| Offline-capable runtime | Keep | No Excel/SharePoint/M365/internet runtime dependency. |
| WPF UI | Supersede | No custom WPF required by v5.0. |
| Custom HTML/Web UI | Exclude from current baseline | May be reconsidered only through future approved change. |
| XLSM/VBA production export | Supersede | Historical POC only. |
| Stable RuleIds | Keep | Required for traceability. |
| Rule applicability by phase/scope | Keep | Expanded with scenario/region/format/entity dimensions. |
| Findings and recommendations separated | Keep | Required for clean interpretation/action model. |
| Project exceptions separate from configuration | Keep | Reusable config must not absorb project-specific decisions. |
| RAG/severity and confidence separate | Keep | Fundamental assessment principle. |
| Unknown/Not Assessed states | Keep and strengthen | Missing evidence never becomes Green/Pass. |
| Effort drivers | Keep | Complexity/effort estimation remains required. |
| Source provenance | Keep and strengthen | Precise physical/XML/DB/source references required. |
| Execution logging | Keep | Required for reproducibility and traceability. |
| Configuration digest/release identity | Keep | Required for trusted runtime and baseline comparability. |
| GxP-oriented traceability | Keep | Without claiming validated/compliant state automatically. |

## 2. Regulatory and migration concepts to carry forward

| Concept | v5.0 disposition | Notes |
|---|---|---|
| Region, format, specification version and dossier/application type are separate dimensions | Keep | Prevents semantic collapse. |
| ASMF is dossier/regulatory context, not transport format | Keep | Explicit v5.0 requirement. |
| IND/NDA/ANDA/BLA/MAA/CTA are application/pathway concepts | Keep | Must remain separate from eCTD format. |
| eCTD v3/v4 require different parsers | Keep | Shared canonical evidence model may be used downstream. |
| `index.xml` + regional XML for v3 | Keep | Version/profile-specific parsing required. |
| `submissionunit.xml` / Context of Use / DocumentReference for v4 | Keep | No v3 semantic assumptions. |
| EU/FDA/Canada/UK/CH/AU/JP/SG coverage model | Keep | Actual enabled profiles remain release-controlled. |
| NeeS/legacy/unknown structures | Keep | Unknown preferred over forced classification. |
| Exact XML evidence path/element/attribute capture | Keep and strengthen | First-class traceability requirement. |
| Sequence gap detection | Keep | Gap is observation unless stronger evidence proves defect. |
| Folder/XML sequence mismatch | Keep | Stronger integrity finding. |
| Broken lifecycle target | Keep | Strong technical completeness finding. |
| Missing XML-referenced physical file | Keep | Distinct from orphan file. |
| Orphan/unreferenced physical file | Keep | Separate finding class. |
| ZIP/nested ZIP/wrapper folders | Keep | Repository discovery requirement. |
| Folder-within-folder / nested sequence | Keep | Migration/container anomaly. |
| Multiple products/applications in one source root | Keep | Must split/group by authoritative identity. |
| DB/archive verification | Keep | Supported source-system scenarios only. |
| Archive identifier normalization | Keep | Exact mapping is product/version-specific. |
| Found/Missing/Multiple/Invalid/Inaccessible archive outcomes | Keep | Preserve evidence and false-missing safeguards. |
| Size/volume/path/file metrics | Keep | Required for effort and migration risk. |
| Technical completeness layers | Keep | Detect → Identify → Structure → References → Integrity → Lifecycle → rules → Readiness. |
| Pre-Migration readiness statuses | Keep | Ready / Ready with Accepted Exceptions / Blocked. |
| Post-Migration reconciliation statuses | Keep | Reconciled / Reconciled with Accepted Exceptions / Review Required / Not Reconciled. |
| Baseline comparability | Keep | Post-Migration must use pinned baseline/config or document approved transition. |

## 3. Previous items explicitly not carried forward as current requirements

The following are not part of the v5.0 target architecture:

1. XLSM/VBA as production authoring/export implementation.
2. WPF UI as the intended Pre-Migration/Post-Migration interface.
3. Dedicated custom HTML/JavaScript mapping application.
4. Runtime PowerShell consuming Excel directly.
5. Customer/project answers being exported into reusable Runtime JSON.
6. Folder naming being treated as authoritative regulatory identity.
7. A single ambiguous “Dossier Format” value combining region, transport format and application type.
8. Pre-Sales performing mandatory deep readiness/reconciliation checks.
9. RAG being used as a substitute for evidence confidence.
10. Missing/unavailable evidence defaulting to Green/Pass.

## 4. Previous implementation assets that may remain in the repository but are historical

These can remain for traceability and design history but should not be interpreted as current implementation authority:

- XLSM/VBA POC files;
- VBA source modules;
- XLSM build/qualification scripts;
- POC-specific conformance tests;
- older architecture documents describing XLSM→VBA→JSON;
- old WPF-specific implementation notes;
- older mapping requirements that contradict the macro-free `.xlsx` + SharePoint + TypeScript/Office Script direction.

## 5. Items requiring controlled review before implementation

The following concepts are relevant but require a controlled implementation decision/specification before production use:

- exact Mapping Workbook sheet/Table/column contract;
- exact Runtime JSON schema and compatibility policy;
- exact SharePoint library/site/review workflow;
- exact Office Script/TypeScript validation contract;
- exact Power Automate role, if retained;
- exact supported regulatory region/version profile list;
- exact regional XML XPath/namespace mappings;
- exact ZIP/container limits and security controls;
- exact DB/archive mappings for each supported eCTDmanager/source-system version;
- exact severity/RAG thresholds;
- exact confidence scoring/caps;
- exact effort/complexity scoring model;
- exact Pre-Migration Excel template;
- exact Post-Migration Excel template;
- exact approved exception workflow;
- exact validation/test strategy.

## 6. Requirement precedence for the new branch

For the `requirements/v5.0-excel-sharepoint` branch:

1. `eMAS_Enterprise_Requirements_v5.0.md` is the current draft requirements baseline.
2. This Carry-Forward Register explains treatment of prior baseline concepts.
3. The eMAS Regulatory, Technical & Migration Assessment Guide v2.0 is a supporting regulatory/technical knowledge source and design reference; it does not override explicit enterprise requirements.
4. Older v3.x/v4.x requirements remain historical where superseded.
5. Existing implementation artifacts remain subordinate to the requirements baseline.

## 7. Summary

The v5.0 branch intentionally preserves the difficult regulatory/migration logic while simplifying the product architecture:

```text
Keep the assessment intelligence.
Remove the unnecessary application/UI layer.
Use Excel for human interaction.
Use SharePoint for controlled collaboration.
Use Runtime JSON for deterministic runtime configuration.
Use PowerShell for the actual assessment.
```
