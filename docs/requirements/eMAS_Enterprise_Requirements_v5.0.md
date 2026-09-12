# eMAS Enterprise Requirements Specification

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Enterprise Business, Functional and Technical Requirements Specification  
**Version:** 5.0  
**Status:** Draft Requirements Baseline for Review  
**Classification:** Internal  
**Prepared:** 12 September 2026

---

## 1. Purpose and primary goal

eMAS (**eCTD Migration Assessment Script**) is a configurable, read-only migration assessment framework for regulatory-content migrations across different source systems and migration scenarios.

The product name remains **eCTD Migration Assessment Script**. The broader migration assessment capabilities defined below do not rename or redefine the eMAS acronym.

The primary goal is not merely to analyse an exported eCTD dossier. eMAS shall first determine the migration scenario and available evidence, then select the assessments that are applicable to that scenario. Depending on the source, evidence may include databases, physical archives, DMS exports, application metadata, working/export directories, regulatory dossier packages, ZIP/container repositories, manifests and migration/import evidence.

eMAS supports three phases:

1. **Pre-Sales Assessment** — establish scope, complexity, confidence, effort drivers and missing information with minimal customer burden.
2. **Pre-Migration Readiness** — perform the detailed scenario-appropriate assessment, identify blockers/remediation and establish a controlled migration baseline.
3. **Post-Migration Verification** — reconcile the approved baseline against migration/import and target evidence and identify unexplained differences.

eMAS does not execute the migration and shall not claim formal regulatory validation, scientific assessment, customer validation, electronic approval or customer acceptance solely from its results.

## 2. Core operating model

The required logical flow is:

```text
Migration project
    ↓
Identify migration scenario
    ↓
Determine available source evidence
    ↓
Build migration scope and evidence inventory
    ↓
Select applicable assessment modules/rules
    ↓
Assess source-system + regulatory + technical migration risks
    ↓
Determine complexity/confidence/readiness
    ↓
Establish controlled Pre-Migration baseline
    ↓
Migration occurs outside eMAS
    ↓
Reconcile target against baseline
```

The engine shall not assume that a dossier/export folder exists. Missing evidence shall reduce assessment coverage/confidence and generate clarification or Not Assessed/Unknown states rather than forcing an incorrect workflow.

## 3. Migration scenario model

Scenario identification is a first-class eMAS function and shall occur before deep regulatory-package assessment.

The model shall support at minimum:

| Scenario family | Typical evidence | Principal assessment focus |
|---|---|---|
| Existing EXTEDO customer: on-premises → cloud | DB, archive, application environment, export/working directories, configuration | source-system inventory, DB/archive integrity, volume, dependencies, migration readiness |
| Existing EXTEDO customer: on-premises → on-premises | DB, archive, application environment | compatibility, source integrity, repository inventory, infrastructure/dependency risks |
| Database + archive migration | DB records + physical archive | record/object correlation, missing/multiple/inaccessible objects, counts and integrity |
| New/third-party customer with regulatory exports | dossier/export folders, ZIPs, metadata | repository discovery, regulatory classification, sequences, XML/references/files |
| Third-party system migration | vendor export, metadata, files and optional DB extracts | source-model discovery, metadata completeness, mapping and regulatory relationships |
| DMS-integrated/content migration | DMS export, metadata, documents/renditions | document/metadata mapping, file availability, relationships and migration transformations |
| eCTDmanager + eSUBmanager related scope | DB/archive plus exports/storage information | managed dossier/submission relationships, storage/export dependencies and scope |
| Partial evidence | only DB, only archive, only export, backup or incomplete repository | assessment coverage, missing evidence, confidence and follow-up requirements |
| Mixed/unknown repository | multiple products/formats/regions/containers/sources | topology discovery, separation into migration units, classification and applicable rules |

Scenario dimensions shall include existing/new customer, source product/system, source/target hosting model, DB availability, archive availability, export availability, DMS integration, eSUBmanager/storage dependencies and other source-system dependencies where relevant.

Reusable questionnaire definitions may be controlled configuration. Project/customer answers, detected values and overrides are execution evidence and shall not become reusable Runtime JSON rules.

## 4. Scenario-driven assessment modules

The architecture shall support reusable assessment capabilities rather than one mandatory dossier-scanning pipeline. Modules may include:

1. Migration Scenario Assessment;
2. Source-System Assessment;
3. Database Assessment;
4. Archive / Physical Object Assessment;
5. DMS / External Repository Assessment;
6. Repository / Container Discovery;
7. Regulatory Dossier/Application Classification;
8. Sequence / Submission-Unit / Lifecycle Assessment;
9. XML / Reference Integrity Assessment;
10. File / Technical Integrity Assessment;
11. Volume and Complexity Assessment;
12. Migration Mapping Assessment;
13. RAG / Confidence / Effort Assessment;
14. Pre-Migration Readiness;
15. Post-Migration Reconciliation.

Not every scenario shall execute every module. Applicability shall be determined by scenario, available evidence and released configuration. An unavailable module/evidence source shall not automatically fail the whole assessment unless it is mandatory for that scenario/readiness decision.

## 5. Simplified target architecture

```text
Internal Mapping Workbook (.xlsx)
        ↓
SharePoint-controlled authoring/version history
        ↓
Office Script / TypeScript validation and deterministic transformation
        ↓
Reviewed and released immutable Runtime JSON
        ↓
Shared PowerShell assessment engine
        ↓
Pre-Sales | Pre-Migration | Post-Migration
        ↓
Phase/scenario-specific Excel report/workbook + execution log
```

Requirements:

- no dedicated WPF or custom web application is required;
- Excel is the primary human-facing mapping/review/reporting interface;
- SharePoint is the internal collaboration/version-history layer for authoring artifacts;
- PowerShell performs technical assessment and orchestration;
- runtime execution consumes released JSON, not the Mapping Workbook;
- normal runtime shall not require Excel desktop, SharePoint, Office Scripts, Power Automate or internet access;
- business/regulatory meaning shall not be hardcoded in PowerShell where it belongs in controlled configuration.

## 6. Phase requirements

### 6.1 Pre-Sales Assessment

Pre-Sales shall be lightweight and script-based. Its purpose is to establish enough evidence to estimate scope and complexity and to identify missing information.

Depending on the scenario it may assess source-system/environment information, DB/archive/export availability, repository volume, candidate regulatory content, high-level region/format/context, dependencies, obvious structural risks, effort drivers and confidence.

It shall not require exhaustive XML/reference/checksum/archive integrity or reconciliation unless explicitly configured as proportionate for the scenario. It shall not issue migration-readiness or validation-success claims.

Outputs shall include an Excel report and execution log.

### 6.2 Pre-Migration Readiness

Pre-Migration shall perform the detailed assessments required by the identified scenario and available evidence. It shall establish a controlled baseline for Post-Migration.

Applicable checks may include source-system inventory, database/archive correlation, DMS/document mapping, repository/container discovery, dossier/application grouping, region/format/version/application classification, sequence/submission-unit inventory, XML evidence, references, physical-file integrity, lifecycle, metadata, volume, dependencies, remediation and accepted exceptions.

Approved outcomes:

- Ready;
- Ready with Accepted Exceptions;
- Blocked.

### 6.3 Post-Migration Verification

Post-Migration shall be scenario-aware and shall not be limited to source-folder versus target-folder comparison.

Where evidence permits, reconciliation may compare:

- source DB record ↔ target application/object record;
- source archive object ↔ migrated document/object;
- source dossier/application ↔ target dossier/application;
- source sequence/submission unit ↔ target sequence/submission unit;
- source metadata ↔ target metadata;
- source document/file ↔ target document/file;
- source checksum/integrity evidence ↔ target integrity evidence;
- source relationships/lifecycle ↔ target relationships/lifecycle;
- source counts/volume ↔ target counts/volume;
- approved exceptions/exclusions ↔ observed differences.

Approved outcomes:

- Reconciled;
- Reconciled with Accepted Exceptions;
- Review Required;
- Not Reconciled.

## 7. Source-system, database and archive assessment

For supported source systems, eMAS shall be capable of using controlled source-system mappings to assess migration evidence independently of exported regulatory folders.

A supported DB/archive chain may be:

```text
Source DB record
→ stored/archive object identifier
→ controlled identifier normalization
→ expected archive object/path/key
→ physical lookup
→ Found / Missing / Multiple / Invalid / Inaccessible
→ affected application/dossier/sequence/document where known
```

Requirements:

- source-system/version-specific mappings shall be controlled and traceable;
- business/display filenames shall not automatically be treated as physical archive identities;
- false-missing safeguards shall verify mapping, conversion, root, recursion, extension assumptions and access before declaring an object missing;
- DB/archive assessment shall support inventory/count/size and relationship evidence where available;
- exact proprietary SQL/mappings belong in controlled implementation specifications, not generic regulatory rules;
- archive verification shall remain distinct from regulatory dossier validation.

## 8. DMS and external source assessment

Where a migration uses DMS or third-party source evidence, eMAS shall support assessment of available metadata, documents/renditions, identifiers, relationships, ownership/source references, export completeness and mapping requirements.

The framework shall permit source-specific adapters/mappings without changing the canonical assessment/result model. Unsupported source semantics shall be reported as Unknown/Not Assessed rather than guessed.

## 9. Repository and container discovery

When folder/export evidence exists, the engine shall distinguish physical containers from regulatory application/dossier roots and support controlled discovery of ZIPs, nested ZIPs, wrapper folders, duplicate/nested sequence directories, mixed formats, multiple applications/products, backups/temp/system files, unexpected hierarchy and unrecognizable structures.

Original physical path/container context shall be preserved. Source content shall not be modified to make it appear valid.

## 10. Regulatory classification and grouping

Regulatory analysis is one eMAS assessment domain, not the entire product.

Classification dimensions shall remain separate, including Region/Jurisdiction, Authority, Technical Format, Specification Version, Regional Implementation, Application/Pathway Type, Dossier/Regulatory Context, Procedure Context, Regulatory Activity/Submission Type, Application/Dossier Identity, Sequence/Submission Unit, Lifecycle Context and Confidence.

Semantic requirements:

- ASMF/DMF shall not be treated as transport formats;
- IND/NDA/ANDA/BLA/MAA/CTA shall not be treated as eCTD formats;
- region, authority, procedure and application type shall not be collapsed into one field;
- folder labels shall not override stronger structured/source-system identity evidence;
- eCTD v3 and v4 shall use version-appropriate parsers/semantics;
- unknown/ambiguous evidence shall remain Unknown/Manual Review rather than forced classification.

Supported profile configuration shall be extensible across EU, US, Canada, UK, Switzerland, Australia, Japan, Singapore and future regions/formats. A profile is enabled only when parser/rules/source references and validation evidence are release-controlled.

## 11. Sequence, XML, lifecycle and file integrity

Where applicable, eMAS shall support sequence/submission-unit inventory and checks for numeric gaps, duplicates, nested sequences, XML/folder mismatches, application identity conflicts, malformed XML and lifecycle relationships.

A numeric gap such as `0000, 0001, 0003` is an observation, not automatically proof that `0002` is a required missing sequence. Severity/confidence shall increase only when stronger lifecycle/source evidence supports the conclusion.

Applicable file/reference checks may include missing referenced files, orphan candidates, zero-byte/unreadable files, extension/content mismatch, duplicate identity/content, path risks, checksum evidence/mismatch, inaccessible files, absolute/external references and broken lifecycle targets.

For material XML-derived conclusions, provenance should identify the XML file and relevant element/attribute/path/value where available.

## 12. Technical completeness and evidence model

Technical completeness shall be layered and scenario-aware. Applicable layers may include Detect, Identify, Structure, Referential Integrity, Object/Integrity, Lifecycle, explicitly implemented regulatory technical rules and Migration Readiness.

Assessment status, evidence state, severity/RAG and confidence shall remain separate concepts. Missing/inaccessible evidence shall never silently become Green/Pass.

At minimum eMAS shall support:

- Assessed / Not Assessed / Unknown;
- evidence states such as Present / Confirmed Absent / Unavailable / Invalid;
- RAG/severity Green / Amber / Red / Unknown;
- confidence High / Medium / Low / Unknown;
- explicit reasons such as input unavailable, access denied, parse failed, not performed, not applicable, conflicting evidence and insufficient evidence.

## 13. Evidence, findings and traceability

Every material conclusion shall retain enough provenance to explain:

```text
Observed source evidence
→ Evidence reference
→ Applicable RuleId
→ Interpretation
→ Severity
→ Confidence
→ Migration impact
→ Recommendation/action
→ Readiness or reconciliation impact
```

Evidence may originate from physical paths, XML, DB/source-system records, archive lookups, DMS metadata, manifests, customer-provided evidence or migration/import/target evidence.

Findings and recommendations shall remain separate. Project-specific accepted exceptions shall not erase original findings/evidence and shall not be stored as reusable configuration.

Regulatory requirements, reviewed regulatory interpretations, eMAS technical/migration rules and recommendations shall be explicitly distinguishable. eMAS shall not present a migration design choice as an authority mandate.

## 14. RAG, confidence, complexity and effort

Severity/RAG answers how serious an observed condition is. Confidence answers how strongly evidence supports the conclusion. They shall remain independent.

Complexity/effort drivers may include source-system type/version, DB/archive size and integrity, DMS dependencies, repository/dossier/sequence/document volume, region/format diversity, unknown classifications, malformed XML/lifecycle breaks, missing objects/references, legacy structures, mapping complexity and expected remediation.

Unless an approved estimation model exists, eMAS shall report validated complexity/effort bands and drivers rather than unsupported hour estimates.

## 15. Mapping Workbook and Runtime JSON

The internal Mapping Workbook shall be macro-free `.xlsx`, suitable for Excel for the web and SharePoint. It shall maintain normalized, filterable configuration for scenarios, fields, master data, relationships, classification/detection rules, structure/reference/integrity rules, source-system applicability, findings, recommendations, RAG, confidence, effort, decisions, questionnaire definitions, source provenance and runtime field mapping.

The workbook is an authoring interface, not a runtime dependency. Office Scripts/TypeScript shall validate and deterministically transform reviewed workbook content into a Runtime JSON candidate. Runtime JSON shall be schema-validated, versioned, immutable for an execution and identifiable by checksum/release metadata.

Power Automate may support controlled release orchestration but is not a customer/runtime dependency.

## 16. Read-only, security and runtime boundaries

eMAS shall not delete, move, rename or repair source files; modify source XML/ZIPs; update source or target DB/DMS; import dossiers; overwrite source evidence; store credentials in configuration/logs; or transmit customer data externally during normal runtime.

Output shall be written only to approved output locations. The PowerShell runtime shall support offline execution and operate without Excel installed or unapproved external modules.

## 17. Reporting and logging

Each execution shall create a phase/scenario-appropriate controlled Excel output and timestamped log. Reports shall identify phase, scenario, scope, available/missing evidence, configuration identity, findings, recommendations, confidence, limitations and final phase outcome where applicable.

Pre-Migration workbooks shall support review of baseline, findings, remediation and exceptions. Post-Migration workbooks shall support expected-versus-observed reconciliation and discrepancy review. Excel may provide navigation, filters, dashboard summaries and protected/generated fields without becoming the technical assessment engine.

Logs shall record ExecutionId, timestamps, machine/user context, phase/scenario, parameters, engine/configuration versions and checksum, steps, warnings/errors, final result and output paths without unnecessary sensitive data.

## 18. Baseline and Post-Migration comparability

The Pre-Migration baseline shall identify the expected migration population and comparison keys at the levels applicable to the scenario. It shall record exclusions, accepted exceptions, unavailable evidence and limitations.

Post-Migration shall use the approved baseline and pinned configuration where practicable. If configuration changes are required, the transition shall be explicitly controlled and documented rather than silently changing comparison semantics.

## 19. GxP-oriented traceability and governance

eMAS shall support traceability such as:

```text
Requirement → Design → Rule → Runtime JSON → Engine Function → Test → Execution Evidence → Report Result → Review Record
```

This supports ALCOA+-aligned traceability but does not itself establish regulatory compliance or validated-system status.

Regulatory sources and internal migration design decisions shall be separately governed. Stable identifiers shall not be reused for different semantic objects.

## 20. Requirement precedence and simplification

For v5.0:

1. This document is the current draft enterprise requirements baseline.
2. Detailed regulatory/technical guides provide supporting knowledge but do not override explicit enterprise requirements.
3. Older XLSM/VBA, WPF and custom-UI requirements are historical where they conflict with this baseline.
4. Detailed parser mappings, SQL, XPath catalogues, workbook column contracts, report layouts and test cases belong in lower-level controlled specifications rather than being duplicated here.

The governing simplification principle is:

> Identify the migration scenario first; use only the evidence and assessment modules relevant to that scenario; keep the assessment intelligence configurable; keep runtime read-only and portable; use Excel for human review rather than building an additional application layer.
