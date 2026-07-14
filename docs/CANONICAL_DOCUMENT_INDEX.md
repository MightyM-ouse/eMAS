# eMAS Canonical Document Index

**Version:** 2.0-report-redesign-branch  
**Status:** Approved working index on `requirements/report-redesign-v3.2`  
**Date:** 2026-07-14  
**Owner:** Documentation Owner

## Purpose

This index routes work on the report-redesign branch to authoritative requirements, approved amendments, configuration contracts, architecture, phase contracts and implementation evidence. Lower numeric authority rank is more authoritative. Branch-approved working baselines become Effective on `main` only after approved merge/promotion.

## Governance and requirements

| ID | Rank/role | Artifact | Version/status | Owner |
|---|---|---|---|---|
| REQ-ENT-V32 | 1 working | [Enterprise Requirements v3.2](requirements/eMAS_Final_Enterprise_Requirements_v3.2.md) | Approved working baseline on report-redesign branch | Product Owner |
| REQ-ENT-V31 | 1 effective-main | [Enterprise Requirements v3.1](requirements/eMAS_Final_Enterprise_Requirements_v3.1.md) | Effective on `main` until v3.2 promotion | Product Owner |
| REQ-REPORT | 1–6 working | [Report Redesign v3.2](requirements/report-redesign/README.md) | Three phase requirements approved and consolidated | Product Owner / SMEs |
| GOV-DEC | Amendment/traceability | [Approved Decision Baseline](governance/eMAS_Approved_Decision_Baseline_v1.0.md) | v1.0 Approved | Product Owner |
| GOV-AMEND-RUNTIME | Approved amendment | [Runtime Profile and Warning Amendment](governance/decisions/DEC-2026-07-13_Runtime_Profile_and_Warning.md) | Effective | Product Owner / Technical Architect |
| GOV-AUTH | Governance | [Authority and Precedence](governance/00_authority_and_precedence.md) | Effective | Product Owner |
| GOV-DOC | Governance | [Document Governance](governance/eMAS_Document_Governance.md) | Effective | Documentation Owner |
| GOV-TERM | Governance | [Controlled Terminology](governance/eMAS_Terminology.md) | Effective with `Warning` and runtime profile | Documentation Owner |

## Configuration and runtime

| ID | Rank | Artifact | Version/status |
|---|---:|---|---|
| CFG-FUNC | 2 | [Mapping Functional Requirements](configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md) | v3.0 Effective |
| CFG-TECH | 3 | [Mapping Technical Requirements](configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md) | v3.0 Effective |
| CFG-CAT | 4 | [Content Catalogue](configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md) | v3.0 Effective logical model |
| CFG-JSON | 3–5 | [Runtime JSON Contract](configuration/04_eMAS_Runtime_JSON_Contract.md) | v1.2 Effective with approved amendments |
| CFG-RULE | 2–5 | [Normalized Rule Model](configuration/05_eMAS_Normalized_Rule_Model.md) | v1.1 Approved |
| CFG-REL | 4 | [Relationship Matrix](configuration/06_eMAS_Normalized_Relationship_Matrix.md) | v1.0 Effective |
| CFG-DICT | 4 | [Logical Data Dictionary](configuration/07_eMAS_Data_Dictionary.md) | v1.0 Effective |
| CFG-VERIFY | 5 | [Schema Validation and Fixture Contract](configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md) | v1.0 Effective |
| CFG-XLSM-POC | 5–8 | [XLSM/VBA POC and Conformance](configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md) | v1.0 Effective POC contract |
| SCHEMA-JSON | 5 | [Runtime JSON Schema](../config/schema/eMAS-runtime-config.schema.json) | 1.0.0 Effective plus amendments |

## Architecture and phase contracts

| ID | Rank | Artifact | Version/status |
|---|---:|---|---|
| ARCH-SOL | 6 | [Solution Architecture](architecture/eMAS_Solution_Architecture.md) | v1.0 Effective; v3.2 working amendments apply |
| ARCH-RUNTIME | 6 | [PowerShell Runtime Profile](architecture/eMAS_PowerShell_Runtime_Profile.md) | v1.0 Effective |
| PHASE-PS | 6 | [Pre-Sales Phase Contract](architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md) | v1.2 approved working; PowerShell 5.1 |
| PHASE-PM | 6 | [Pre-Migration Phase Contract](architecture/phase-contracts/02_eMAS_PreMigration_Readiness_Phase_Contract.md) | v1.2 approved working; PowerShell 7.6 LTS |
| PHASE-PO | 6 | [Post-Migration Phase Contract](architecture/phase-contracts/03_eMAS_PostMigration_Verification_Phase_Contract.md) | v1.2 approved working; PowerShell 7.6 LTS |

## Controlled report artifacts

| ID | Artifact | Version/status |
|---|---|---|
| TPL-PS | `templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx` | Template 1.2.0; 4-sheet v3.2 design |
| TPL-PM | `templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx` | Template 1.2.0; 11-sheet v3.2 design |
| TPL-PO | `templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx` | Template 1.2.0; 15-sheet v3.2 design |
| MAP-PS | `config/report-mappings/pre-sales.template-map.json` | Map 2.0.0 |
| MAP-PM | `config/report-mappings/pre-migration.template-map.json` | Map 2.0.0 |
| MAP-PO | `config/report-mappings/post-migration.template-map.json` | Map 2.0.0 |
| MAP-SCHEMA | `config/report-mappings/report-template-map.schema.json` | v3.2 technical binding schema |
| RESULT-SCHEMAS | `config/result-schemas/report-redesign-v3.2/` | Normalized phase result schemas |
| REPORT-REF | `templates/report-redesign-v3.2/` and `config/report-mappings/report-redesign-v3.2/` | Versioned review/reference copies and checksums |

## Key v3.2 decisions

- Pre-Sales customer collection uses mode-driven current-system-only inputs.
- Target fields remain blank/Pending EXTEDO Review during customer collection.
- Export evidence is detailed; archive/index/database direct-copy evidence is aggregate-only.
- Pre-Sales uses 4 sheets, Pre-Migration 11 sheets and Post-Migration 15 sheets.
- Pre-Migration establishes file-type baseline plus explicit migration method/wave.
- Post-Migration compares baseline, import report, target database and post-import evidence.
- Raw import, post-import and database-extract sheets are append-only.
- `Verification Incomplete` is used when mandatory verification evidence is missing or incompatible.

## Implementation and verification evidence

| ID | Artifact | Status/role |
|---|---|---|
| WP-RUNTIME-WARNING | [Runtime/Warning/Template Work Package](implementation/WORK_PACKAGE_Runtime_Profile_Warning_and_Template_Corrections.md) | Approved implementation route |
| ENGINE-RUNTIME | [Runtime engine boundary](../engine/README.md) | Foundation implemented; phase completion pending |
| MAP-WORKBOOK | [Mapping Workbook Requirements](requirements/report-redesign/04_eMAS_Mapping_Workbook_Requirements_v1.0.md) | Simple focused-sheet authoring design |
| REPORT-ARTIFACTS | [Report redesign artifact README](../templates/report-redesign-v3.2/README.md) | Template/map/result-schema alignment evidence after materialization |
| PRESALES-IMPL | `implementation/pre-sales-collection-v3.2` branch | Initial customer collection implementation; must be rebased/aligned to final artifacts |

## Required reading for PowerShell/reporting work

1. Authority/precedence, terminology and approved decisions.
2. Enterprise Requirements v3.2 and applicable report requirement v1.1.
3. Solution Architecture, Runtime Profile and applicable phase contract v1.2.
4. Runtime JSON contract/schema/fixtures and mapping workbook contract.
5. Applicable template, map and normalized result schema.
6. Operational implementation and review skills.

## Delivery-state boundary

On this branch, requirements, phase contracts, report templates, report maps and result schemas are aligned to the approved v3.2 design. Runtime mapping content approval, complete PowerShell integration, baseline/evidence readers, Windows/Excel qualification, package assembly/signing and production release remain pending controlled implementation states.

## Historical/prohibited authority

Archived requirements, generated profiles, uncontrolled samples, unapproved AI output, customer-specific evidence and fixtures as regulatory authority are prohibited.

## Maintenance rule

Update this index whenever an artifact is approved, promoted, superseded, renamed, moved, assigned a new owner/version or added to a task route.
