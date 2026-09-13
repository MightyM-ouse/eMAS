# eMAS Enterprise Requirements Specification

**Project:** eMAS — eCTD Migration Assessment Script
**Document Type:** Enterprise Business, Functional and Technical Requirements Specification
**Version:** 5.0
**Status:** Approved MVP design baseline; implementation and verification pending
**Classification:** Internal
**Prepared:** 13 September 2026
**Decision references:** DEC-2026-013, DEC-2026-014 and DEC-2026-015

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

The approved MVP base catalogue is:

| ScenarioId | Base migration scenario | Principal assessment focus |
|---|---|---|
| `MS-01` | eCTDmanager SQL Server to SQL Server | DB/archive inventory, compatibility, migration population, readiness and reconciliation |
| `MS-02` | eCTDmanager Access to SQL Server | Legacy extraction, archive correlation, conversion risk and reconciliation |
| `MS-03` | eCTDmanager Oracle to SQL Server | Oracle source mapping, archive correlation, conversion risk and reconciliation |
| `MS-04` | Regulatory Submission Export to eCTDmanager | Repository, dossier, region/format, sequence, XML/reference and file assessment |
| `MS-05` | Hybrid Migration | Combined assessment across two or more primary source mechanisms |
| `MS-06` | Archive or Storage Only | Archive discovery, identity limitations, counts, size and reduced-confidence interpretation |
| `MS-07` | Scenario Pending or Incomplete | Missing/contradictory information, follow-up and safe Not Assessed outcomes |
| `MS-08` | Third-Party System or DMS to eCTDmanager | Source adapter, metadata, documents/renditions, relationships and mapping into the supported target |

Customer relationship, source/target hosting, migration scope, evidence completeness, repository composition, eSUBmanager dependency, DMS dependency, other integrations and sequential upgrade shall be represented as qualifiers rather than separate scenario identities. Qualifiers may change module applicability, rules, follow-up, coverage and confidence.

Reusable questionnaire definitions and scenario-derivation rules are controlled configuration. Project/customer answers, detected values, actual qualifier values and overrides are execution evidence and shall not become reusable Runtime JSON configuration. The questionnaire shall begin with business/current-source questions, then hosting/destination and dependencies, and only then request technical evidence.

The questionnaire shall explicitly capture the primary migration input and intended target platform. When multiple primary inputs select `MS-05`, it shall also capture each included source mechanism as controlled multi-select values so module activation is deterministic. `MS-08` applies only when third-party-system or DMS content is migrating into eCTDmanager. DMS-to-DMS migration is outside the current eMAS MVP scenario catalogue and shall return `MS-07 / NeedsReview`, require consultant discussion and prevent automatic generation of `MS-08` Runtime JSON.

Pre-Sales questions about databases and archives shall be limited by default to availability and approximate scale. Detailed `database record -> archive identifier -> physical object` verification belongs to Pre-Migration and Post-Migration. Partial evidence shall not force `MS-07` when the base migration route is otherwise known; it shall reduce evidence completeness, module coverage and confidence.

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

The MVP module catalogue contains these fifteen stable modules. Each module shall define its business purpose, assessment boundary, evidence/capability domain, permitted phases, inputs, outputs and potential baseline/reconciliation role. Migration Scenario Assessment confirms the previously derived scenario at runtime; it shall not independently re-derive it. Pre-Migration Readiness is a Pre-Migration-only outcome module, and Post-Migration Reconciliation is a Post-Migration-only outcome module.

Not every scenario shall execute every module. Applicability shall be explicit for every scenario, phase and module using Required, Conditional, Optional or NotApplicable. The detailed baseline shall contain one record for every `8 scenarios × 3 phases × 15 modules` combination (360 records), including explicit NotApplicable reasons. Required modules remain visible when evidence is missing; Conditional modules use controlled activation and shall not treat Unknown as false; Optional modules do not affect the formal phase outcome when omitted.

`MOD-READINESS` shall be Required for `MS-07` Pre-Migration so an unresolved or unsupported route produces an explicit Blocked outcome. `MOD-RECONCILE` shall be NotApplicable for `MS-07` Post-Migration because there is no approved comparison basis. An unavailable module/evidence source shall not automatically fail the whole assessment unless its mapping makes it mandatory for that scenario/readiness or reconciliation decision.

## 5. Simplified target architecture and MVP priority

The immediate MVP architecture is:

```text
Master Mapping Workbook (.xlsx)
        ↓
Select one Migration Scenario
        ↓
Validate and deterministically transform applicable configuration
        ↓
Scenario-specific Runtime JSON covering all applicable phases
        ↓
Shared PowerShell assessment engine
        ↓
Pre-Sales | Pre-Migration | Post-Migration
        ↓
Phase/scenario-specific Excel report/workbook + execution log
```

The MVP shall first prove that the Mapping Workbook contains all configurable migration-script requirements in an understandable and maintainable form and that scenario-specific JSON can be generated without loss of traceability.

Requirements:

- no dedicated WPF or custom web application is required;
- Excel is the primary human-facing mapping/review/reporting interface;
- PowerShell performs technical assessment and orchestration;
- runtime execution consumes scenario-specific JSON, not the Mapping Workbook;
- normal runtime shall not require Excel desktop, SharePoint, Office Scripts, Power Automate or internet access;
- business/regulatory meaning shall not be hardcoded in PowerShell where it belongs in configuration;
- SharePoint authoring, Office Script tenant deployment, Power Automate release orchestration and formal GxP-oriented release controls are deferred until the workbook-to-JSON MVP works.

The later target may add SharePoint-controlled authoring/version history and Office Script/TypeScript generation without changing this boundary.

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

This capability covers third-party-system/DMS source assessment for migration into eCTDmanager. It does not authorize or assess DMS-to-DMS migration. A DMS-to-DMS request shall be classified as outside the current scenario catalogue and escalated for consultant review and separate scope definition.

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

The internal Mapping Workbook shall be one macro-free `.xlsx` master workbook. It shall maintain understandable, normalized, and filterable configuration for scenarios, modules, fields/evidence, regulatory profiles, requirements, classification/detection, structure/reference/integrity, source-system/DB/archive/DMS mappings, metrics, findings, recommendations, RAG, confidence, effort, readiness, reconciliation, source provenance, and runtime field mapping.

For one selected `ScenarioId`, the MVP transformer shall resolve applicable modules, requirements, rules, and referenced dependencies and generate one deterministic scenario-specific Runtime JSON file. That JSON shall contain all configuration applicable to Pre-Sales, Pre-Migration, and Post-Migration for the selected scenario. Every exported object shall be traceable to stable workbook identifiers.

The workbook is an authoring interface, not a runtime dependency. PowerShell shall consume JSON and shall not open Excel or generate, repair, or reinterpret configuration JSON.

The exact workbook sheets, columns, relationships, scenario catalogue, qualifier model, questionnaire, derivation rules, module catalogue, scenario/phase applicability, JSON shape, validation rules, and acceptance tests are defined by [Mapping Workbook and Scenario JSON MVP Requirements v4.3](../configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md).

SharePoint authoring, Office Scripts, Power Automate, controlled approvals, immutable production releases, checksums, and GxP-oriented governance remain later-stage requirements and do not block MVP acceptance.

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
