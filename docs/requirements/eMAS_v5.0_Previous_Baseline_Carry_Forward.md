# eMAS v5.0 — Previous Baseline Carry-Forward Register

**Purpose:** Record only the material decisions carried forward, superseded or still requiring controlled specification.  
**Target branch:** `requirements/v5.0-excel-sharepoint`  
**Prepared:** 12 September 2026

---

## 1. Material carry-forward decisions

| Concept | v5.0 disposition | Reason |
|---|---|---|
| Three phases: Pre-Sales, Pre-Migration, Post-Migration | Keep | Core lifecycle remains valid. |
| Migration scenario identification | Strengthen | Must precede deep dossier/export assessment. |
| Existing/new customer and on-prem/cloud scenarios | Keep/expand | eMAS must cover more than export-folder migrations. |
| DB + archive assessment | Keep/strengthen | First-class assessment path for supported source systems. |
| DMS/third-party source assessment | Keep/expand | Required for non-folder source scenarios. |
| Partial/mixed evidence handling | Strengthen | Assessment must adapt when DB/archive/export/DMS evidence is incomplete. |
| Read-only assessment | Keep | Fundamental safety boundary. |
| Shared PowerShell engine | Keep | Runtime technical engine. |
| Scenario/phase-specific assessment depth | Strengthen | Not every project executes every module. |
| Excel reports/workbooks | Keep/strengthen | Primary human review experience. |
| Mapping Workbook | Keep as macro-free `.xlsx` | Internal authoring/configuration interface. |
| SharePoint | Keep | Collaboration, permissions and version history. |
| Runtime JSON | Keep | Machine-readable released configuration. |
| Office Scripts/TypeScript | Keep | Validation/transformation, not assessment engine. |
| Power Automate | Optional | May support controlled release; never runtime dependency. |
| Offline PowerShell runtime | Keep | Customer/project execution must not depend on M365/internet. |
| WPF/custom web UI | Supersede | Unnecessary complexity for current goal. |
| XLSM/VBA production path | Supersede | Historical POC direction. |
| Stable RuleIds and provenance | Keep | Required for traceability/explainability. |
| RAG and confidence separation | Keep | Severity and certainty are different concepts. |
| Unknown/Not Assessed | Strengthen | Missing evidence never becomes Green/Pass. |
| Pre-Migration baseline | Keep | Required for controlled reconciliation. |
| Scenario-aware Post-Migration reconciliation | Strengthen | May compare DB/object/metadata/relationships, not only folders/files. |
| Regulatory/source provenance | Keep | Authority requirements must remain distinct from eMAS migration rules. |

## 2. Regulatory/content intelligence retained

The following remain relevant when the scenario contains regulatory package/export evidence:

- independent dimensions for region, authority, format/version, application/pathway, dossier/regulatory context, procedure, activity, identity, sequence/submission unit and lifecycle;
- ASMF/DMF are not transport formats;
- IND/NDA/ANDA/BLA/MAA/CTA are not eCTD formats;
- eCTD v3 and v4 use different parsing semantics;
- exact XML evidence should be retained for material conclusions;
- sequence gaps are observations unless stronger lifecycle/source evidence proves a defect;
- missing XML-referenced files and orphan/unreferenced files are separate findings;
- ZIP/nested ZIP/wrapper/nested-sequence/mixed-repository discovery remains required;
- folder labels do not override stronger XML/DB/source-system identity;
- technical completeness is layered and must not be represented as full regulatory validation.

These are assessment modules within eMAS; they do not define the whole product.

## 3. Source-system migration intelligence retained/expanded

v5.0 explicitly retains or adds requirements for:

- source-system inventory and version/context;
- DB/archive availability and scope;
- controlled DB record → stored-object identifier → physical archive lookup;
- Found/Missing/Multiple/Invalid/Inaccessible object outcomes;
- false-missing safeguards before declaring archive content absent;
- DB/archive counts, size and integrity evidence;
- DMS metadata/document/rendition assessment;
- export/working/storage dependencies where applicable;
- partial evidence and unsupported source semantics;
- migration mapping requirements;
- scenario-specific effort drivers and readiness blockers.

Exact proprietary SQL, archive conversion algorithms and source-version mappings remain implementation specifications, not enterprise requirements.

## 4. Items intentionally removed from the current requirements baseline

1. Dedicated WPF application requirements.
2. Dedicated HTML/JavaScript Mapping Studio requirements.
3. XLSM/VBA as production configuration/export architecture.
4. Runtime PowerShell reading Excel directly.
5. Customer/project answers being stored as reusable configuration.
6. Dossier/export-folder scanning as the assumed starting point for every migration.
7. Folder naming as authoritative regulatory identity.
8. A single combined field that conflates region, format and dossier/application type.
9. Mandatory deep regulatory checks during every Pre-Sales execution.
10. RAG used as a substitute for confidence/evidence state.
11. Missing evidence defaulting to Green/Pass.
12. Detailed XPath/SQL/workbook-layout/test-case content duplicated inside the enterprise requirements document.

## 5. Items still requiring lower-level controlled specification

- exact supported migration-scenario catalogue and questionnaire contract;
- exact source-system adapters and supported eCTDmanager/product versions;
- exact DB/archive mappings and false-missing controls;
- exact DMS/source export mappings;
- exact Mapping Workbook sheets/tables/columns;
- exact Runtime JSON schema/compatibility policy;
- exact SharePoint/release workflow;
- exact Office Script validation/transformation contract;
- exact supported regulatory profile/version catalogue;
- exact XML namespace/XPath mappings;
- exact ZIP/container security/resource limits;
- exact RAG/confidence/effort decision rules;
- exact Pre-Migration baseline schema;
- exact Post-Migration comparison keys per scenario;
- exact Excel report/workbook layouts;
- exact exception workflow and test strategy.

## 6. Requirement precedence

1. `eMAS_Enterprise_Requirements_v5.0.md` — current draft enterprise requirements baseline.
2. This register — explains treatment of earlier concepts.
3. Regulatory/technical/migration guides — supporting knowledge/design references.
4. Older v3/v4 requirements and implementation artifacts — historical where superseded.

## 7. Resulting product definition

> eMAS is not an eCTD-folder scanner. It is a scenario-driven, read-only regulatory-content migration assessment framework. It identifies the migration scenario and available evidence, applies the relevant source-system, database, archive, DMS, repository, regulatory and integrity assessments, establishes a controlled Pre-Migration baseline, and reconciles the migrated target against that baseline.
