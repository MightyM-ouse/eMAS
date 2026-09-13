# eMAS — eCTD Migration Assessment Script

eMAS (**eCTD Migration Assessment Script**) is a configurable, read-only migration assessment framework for regulatory-content migrations across different source systems and migration scenarios.

It supports three phases:

- **Pre-Sales Assessment** — establish scope, complexity, confidence, effort drivers and missing information with minimal customer burden;
- **Pre-Migration Readiness** — perform detailed scenario-appropriate assessment and establish a controlled migration baseline;
- **Post-Migration Verification** — reconcile the approved baseline against migration/import and target evidence.

> eMAS is not only an eCTD-folder scanner. Although the product name remains **eCTD Migration Assessment Script**, its migration assessment scope may use source databases, physical archives, DMS exports, regulatory dossier/export folders, ZIP/container repositories, source-system metadata and migration/import evidence, depending on the migration scenario.

## Current v5.0 requirements direction

```text
Migration Project
      ↓
Identify Migration Scenario
      ↓
Determine Available Evidence
      ↓
Select Applicable Assessment Modules
      ↓
Assess Source-System + Regulatory + Technical Migration Risks
      ↓
Pre-Migration Baseline
      ↓
Migration occurs outside eMAS
      ↓
Post-Migration Reconciliation
```

The current MVP architecture is deliberately simple:

```mermaid
flowchart TD
    A[Questionnaire and project context] --> B[Derive and confirm base scenario]
    B --> C[Resolve and validate applicable configuration]
    C --> D[Scenario-specific Runtime JSON]
    D --> E[PowerShell assessment phases]
    E --> F[Excel report and execution log]
```

### Architecture principles

- The immediate MVP is one complete, human-readable, macro-free `.xlsx` Mapping Workbook.
- The workbook contains all configurable migration-assessment requirements and their relationships.
- One derived and confirmed base scenario is deterministically transformed into one scenario-specific Runtime JSON containing all applicable phase configuration.
- The approved MVP uses fifteen bounded assessment modules and an explicit 360-record scenario/phase/module applicability matrix; Hybrid source composition is captured as controlled multi-select values.
- Runtime PowerShell consumes JSON, not the Mapping Workbook.
- Normal runtime does not require Excel desktop, SharePoint, Office Scripts, Power Automate or internet access.
- Excel is the primary human-facing review/reporting experience.
- No dedicated WPF or custom web application is required by the current baseline.
- Source evidence remains read-only.
- eMAS does not execute migration.
- SharePoint, Office Script tenant deployment, Power Automate, formal release governance and GxP-oriented controls are deferred until the workbook-to-JSON MVP works.

## Scenario-driven assessment

The applicable checks depend on the migration scenario and available evidence. Examples include:

| ScenarioId | Base migration scenario | Example assessment focus |
|---|---|---|
| `MS-01` | eCTDmanager SQL Server to SQL Server | DB/archive population, compatibility, readiness, and reconciliation |
| `MS-02` | eCTDmanager Access to SQL Server | legacy extraction, archive correlation, conversion risks, and reconciliation |
| `MS-03` | eCTDmanager Oracle to SQL Server | Oracle mapping, archive correlation, conversion risks, and reconciliation |
| `MS-04` | Regulatory Submission Export to eCTDmanager | repository, dossier, region/format, sequence, XML/reference, and file integrity |
| `MS-05` | Hybrid Migration | coordinated assessment across two or more source mechanisms |
| `MS-06` | Archive or Storage Only | archive discovery, identity limitations, counts, size, and confidence |
| `MS-07` | Scenario Pending or Incomplete | follow-up questions and safe Not Assessed outcomes |
| `MS-08` | Third-Party System or DMS to eCTDmanager | adapter, metadata, document/rendition, relationship, and mapping assessment into the supported target |

Customer relationship, source/target hosting, migration scope, evidence completeness, repository composition, eSUBmanager/DMS dependencies, other integrations, and sequential upgrade are qualifiers. They change applicable rules and confidence without creating duplicate base scenarios.

DMS-to-DMS migration is outside the current MVP scope. It is routed to `MS-07 / NeedsReview` for consultant discussion rather than being treated as `MS-08`.

Not every project executes every assessment module.

## Assessment capability areas

Depending on applicability, eMAS may assess:

- migration scenario and source-system context;
- source DB inventory and relationships;
- archive/physical-object presence and integrity;
- DMS/export metadata and document mappings;
- repository/ZIP/container discovery;
- product/application/dossier grouping;
- region, authority, technical format and specification version;
- application/pathway and dossier/regulatory context;
- sequence/submission-unit and lifecycle evidence;
- XML/reference/file integrity;
- volume, complexity and effort drivers;
- RAG/severity and evidence confidence;
- remediation and accepted exceptions;
- Pre-Migration readiness;
- Post-Migration reconciliation.

## Important regulatory modelling principles

- Region, authority, technical format, specification version, application type, dossier/regulatory context, procedure and lifecycle purpose are separate dimensions.
- ASMF/DMF are not transport formats.
- IND/NDA/ANDA/BLA/MAA/CTA are not eCTD formats.
- eCTD v3 and eCTD v4 require version-appropriate parsing semantics.
- Folder names are supporting evidence, not authoritative identity by themselves.
- Missing evidence must not silently become Green/Pass.
- Severity/RAG and confidence are separate concepts.
- Technical completeness is not the same as formal health-authority validation.

## Phase outcomes

| Phase | Interface | Controlled outcome |
|---|---|---|
| Pre-Sales Assessment | PowerShell/script-based | Scope, complexity, confidence, effort drivers and clarifications |
| Pre-Migration Readiness | PowerShell + controlled Excel assessment workbook | Ready / Ready with Accepted Exceptions / Blocked |
| Post-Migration Verification | PowerShell + controlled Excel reconciliation workbook | Reconciled / Reconciled with Accepted Exceptions / Review Required / Not Reconciled |

## Current requirements references

- [Enterprise Requirements v5.0](docs/requirements/eMAS_Enterprise_Requirements_v5.0.md)
- [Mapping Workbook and Scenario JSON MVP Requirements v4.3](docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md)
- [v5.0 Previous Baseline Carry-Forward Register](docs/requirements/eMAS_v5.0_Previous_Baseline_Carry_Forward.md)

Detailed regulatory, parser, SQL, XPath, workbook-layout and test specifications are intentionally kept outside the enterprise requirements baseline and should be maintained in the appropriate lower-level controlled specifications.

## Repository safety

Do not commit customer data, customer reports, migration evidence, production logs, credentials, project-specific accepted exceptions or uncontrolled production artifacts to the repository.

## Positioning

eMAS converts available migration evidence into structured, reproducible and traceable migration assessment results. It helps determine what is known, what is missing, what may block migration, what requires remediation, and whether the migrated target reconciles with the approved baseline.

It does not perform the migration itself, formal regulatory validation, scientific assessment, electronic approval or customer acceptance.
