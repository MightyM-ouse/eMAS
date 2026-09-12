# eMAS Enterprise Requirements Specification

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Enterprise Business, Functional and Technical Requirements Specification  
**Version:** 5.0  
**Status:** Draft Requirements Baseline for Review  
**Classification:** Internal  
**Branding:** EXTEDO | a cormeo brand  
**Prepared:** 12 September 2026  
**Supersession intent:** Replaces prior UI/XLSM-oriented architecture requirements where explicitly changed below.

---

## 1. Purpose

This document defines the current enterprise requirements for eMAS using a deliberately simplified architecture. eMAS remains a read-only, evidence-based migration assessment framework supporting three phases:

1. Pre-Sales Assessment;
2. Pre-Migration Readiness;
3. Post-Migration Verification.

The architecture shall minimize product complexity. eMAS shall not require a dedicated custom web application or WPF application for normal configuration, assessment review or reconciliation.

## 2. Product definition

eMAS provides structured, reproducible and traceable migration assessment evidence. It does not execute migration and shall not claim formal regulatory validation, scientific assessment, customer validation, electronic approval or customer acceptance solely from assessment results.

| Item | Requirement |
|---|---|
| Pre-Sales interface | PowerShell/script-based execution |
| Pre-Migration interface | PowerShell assessment with controlled Excel assessment workbook/report |
| Post-Migration interface | PowerShell reconciliation with controlled Excel verification workbook/report |
| Internal rule authoring | Macro-free Excel `.xlsx` Mapping Workbook |
| Internal collaboration/version control | SharePoint |
| Workbook validation/transformation | Reviewed Office Scripts / TypeScript |
| Runtime configuration | Released immutable Runtime JSON |
| Runtime engine | Shared PowerShell engine |
| Normal runtime dependency | No Excel desktop, SharePoint, Office Scripts, Power Automate or internet required |
| Source modification | Prohibited |
| Dedicated custom UI | Out of scope for current baseline |

## 3. Target architecture

```text
Regulatory / migration knowledge
        ↓
Internal Mapping Workbook (.xlsx)
        ↓
SharePoint-controlled storage/version history
        ↓
Office Script / TypeScript validation and deterministic transformation
        ↓
Frozen Runtime JSON candidate
        ↓
Controlled review / approval / release evidence
        ↓
Immutable released Runtime JSON
        ↓
Shared PowerShell assessment engine
        ↓
Pre-Sales | Pre-Migration | Post-Migration
        ↓
Phase-specific Excel report/workbook + execution log
```

### 3.1 Architecture principles

1. The Mapping Workbook is an internal authoring interface, not a runtime dependency.
2. PowerShell must never read, interpret, repair or convert the Mapping Workbook during customer/project execution.
3. PowerShell shall consume only an approved released Runtime JSON and trusted release evidence.
4. The same released configuration model shall support all three phases, with phase-specific applicability.
5. PowerShell shall own generic discovery, parsing, measurement, comparison, orchestration, logging and report generation.
6. Regulatory/business interpretation shall remain in controlled configuration where appropriate.
7. Excel shall provide the principal human-facing review experience for mapping administration and generated assessment results.
8. SharePoint shall provide internal collaboration, permissions, version history and controlled storage for authoring artifacts.
9. Custom WPF/web UI development is not required by this baseline.

## 4. Phase separation

### 4.1 Pre-Sales Assessment

Pre-Sales shall remain intentionally lightweight and script-based.

Primary purposes:

- estimate scope and volume;
- identify candidate dossiers/sequences;
- identify high-level region/format/dossier context;
- identify obvious structural observations;
- derive complexity/effort drivers;
- derive confidence;
- generate customer clarification questions.

Pre-Sales shall not require exhaustive reference integrity, checksum verification, archive/database integrity, accepted-exception handling, migration readiness or post-migration reconciliation.

Pre-Sales shall generate a controlled Excel report and execution log.

### 4.2 Pre-Migration Readiness

Pre-Migration shall perform detailed assessment sufficient to establish a controlled migration baseline.

Required capability may include, where applicable:

- repository and container discovery;
- dossier/application grouping;
- region/format/version/application/dossier classification;
- sequence/submission-unit inventory;
- XML parsing and exact evidence capture;
- folder/file structure assessment;
- referenced-file resolution;
- orphan/unreferenced object assessment;
- zero-byte/readability/type/path/integrity checks;
- lifecycle relationship assessment;
- database/archive integrity for supported source-system scenarios;
- volume and sizing metrics;
- remediation/actions;
- accepted project exceptions;
- readiness decision;
- controlled baseline suitable for later reconciliation.

Final Pre-Migration outcomes are:

- Ready;
- Ready with Accepted Exceptions;
- Blocked.

### 4.3 Post-Migration Verification

Post-Migration shall compare the approved Pre-Migration baseline with migration/import evidence and observed target evidence.

Reconciliation shall support, where evidence permits:

- dossier/application;
- sequence/submission unit;
- document/file;
- metadata;
- integrity;
- lifecycle;
- archive/source-system relationships;
- accepted exceptions and unexplained discrepancies.

Final Post-Migration outcomes are:

- Reconciled;
- Reconciled with Accepted Exceptions;
- Review Required;
- Not Reconciled.

## 5. Read-only and safety requirements

eMAS shall not:

- delete, move or rename source files;
- modify source folders, XML, ZIPs or other source evidence;
- update source or target databases;
- repair customer evidence;
- import dossiers;
- silently extract or overwrite source evidence;
- store credentials in configuration or logs;
- transmit customer data externally during normal runtime;
- require internet access for normal runtime.

Output shall be written only to approved output locations.

## 6. Repository and container discovery

The engine shall distinguish physical containers from regulatory dossier/application roots.

It shall support controlled discovery of conditions such as:

- one or multiple ZIP archives;
- nested ZIPs subject to approved recursion/resource limits;
- partially extracted ZIP plus original archive;
- additional wrapper folders;
- sequence folders directly at a repository root;
- dossier/application wrappers around sequences;
- numeric sequence folder nested inside another sequence folder;
- excessive/unexpected nesting;
- duplicate sequence directories;
- empty folders or sequence folders;
- mixed dossier structures under one root;
- multiple products/applications under one root;
- multiple regulatory formats in one source;
- unexpected root/sequence files;
- backup/archive/temp/system files mixed with dossier content;
- folder names conflicting with structured XML/source metadata;
- no recognizable supported dossier structure.

The engine shall preserve the original physical path and container context. It shall not normalize source content by modifying it.

## 7. Multi-dimensional classification model

Classification dimensions shall remain separate. At minimum:

- Region / Jurisdiction;
- Authority where applicable;
- Technical Format;
- Technical Specification / Version;
- Regional Implementation;
- Application / Pathway Type;
- Dossier / Regulatory Context;
- Procedure Context;
- Regulatory Activity / Submission Type;
- Application / Dossier Identity;
- Sequence / Submission Unit;
- Lifecycle Context;
- Classification State;
- Confidence.

### 7.1 Semantic separation

The following shall not be conflated:

- ASMF/DMF with transport format;
- IND/NDA/ANDA/BLA/MAA/CTA with eCTD format;
- region with authority;
- procedure with application type;
- sequence number with regulatory activity;
- folder/product labels with authoritative application identity.

ASMF shall be represented as a dossier/regulatory context while the technical format is independently identified.

## 8. Evidence hierarchy and provenance

Classification and technical findings shall use context-sensitive evidence authority rather than a single global priority.

Evidence classes may include:

1. authoritative structured metadata;
2. schema/DTD/namespace/root evidence;
3. common-to-regional backbone linkage;
4. official regional/package path conventions;
5. CTD/module/sequence structure;
6. folder/file naming heuristics;
7. controlled customer/source-system metadata.

For every material conclusion, eMAS shall retain sufficient provenance to explain:

```text
Observation
→ Evidence reference
→ Applicable RuleId
→ Interpretation
→ Severity
→ Confidence
→ Migration impact
→ Recommended action
→ Readiness / reconciliation decision
```

Evidence references may include physical paths, XML file/path/element/attribute/value, DB/source-system identity, manifest key, source document/section or observed error.

## 9. Regulatory and format coverage model

The requirements model shall support configuration for multiple regions and formats, including but not limited to:

- EU;
- US/FDA;
- Canada;
- UK;
- Switzerland;
- Australia;
- Japan;
- Singapore;
- other/future regions as Unsupported/Unknown until explicitly configured.

Supported technical format families shall include configuration concepts for:

- eCTD v3.x;
- eCTD v4.0;
- NeeS where applicable;
- legacy/non-eCTD structures;
- unknown/ambiguous structures.

A region/format/version shall not be treated as fully supported until the required parser, source references, rule catalogue and validation evidence are available.

## 10. eCTD v3 and v4 parsing boundary

The engine shall route packages by format/version before applying format-specific semantics.

For eCTD v3, configuration and parsers may use evidence such as:

- `index.xml`;
- regional Module 1 backbone XML;
- leaf identity;
- lifecycle operation;
- `modified-file` relationship;
- `xlink:href` physical reference;
- checksum metadata;
- regional XML controlled metadata.

For eCTD v4, the engine shall use the v4 submission-unit information model and shall not assume v3 leaf/backbone semantics.

Version-specific parsers shall feed a shared canonical evidence/result model where practical.

## 11. Dossier/application grouping

A physical parent directory shall not automatically be treated as a Product, Dossier or Application.

Grouping shall prefer authoritative identifiers and structured metadata appropriate to the region/source system.

The engine shall support:

- one product → one application;
- one product → multiple applications;
- multiple products in one repository;
- candidate grouping based on authoritative identifiers;
- conflicts between folder label and XML/DB identity;
- additional product/application discovered during scan;
- ambiguous or unknown grouping requiring manual review.

PhysicalPath and CanonicalIdentity shall remain separate concepts with provenance.

## 12. Sequence/submission-unit requirements

The engine shall inventory observed sequences/submission units and distinguish simple numbering observations from proven lifecycle defects.

Examples include:

- continuous numbering;
- numeric gap such as `0000, 0001, 0003`;
- duplicate sequence identity;
- nested sequence directories;
- folder/XML sequence mismatch;
- sequence/application identity mismatch;
- DB inventory vs export mismatch;
- malformed XML;
- later lifecycle reference to an absent prior sequence/leaf.

A numeric gap alone shall not automatically prove invalidity or a missing required source sequence. Severity/confidence shall increase only when stronger lifecycle/source evidence supports the conclusion.

## 13. Folder, file and reference integrity requirements

The detailed engine shall support configurable checks for conditions including:

- expected folder/file presence;
- conditional/optional structures;
- missing XML-referenced files;
- unreferenced/orphan file candidates;
- zero-byte files;
- unreadable/corrupt files;
- extension/content-type mismatch;
- duplicate file/reference identity;
- duplicate binary content;
- same filename with different binary content;
- invalid/unsupported extensions or formats;
- path length/invalid characters;
- inaccessible/locked files;
- missing/unsupported checksum metadata;
- checksum mismatch;
- case-sensitivity risks;
- broken relative paths/path traversal;
- absolute/external references;
- broken lifecycle targets.

Each rule shall identify whether it represents:

- regulatory technical requirement;
- reviewed regulatory interpretation;
- eMAS technical/migration rule;
- migration-risk observation;
- recommendation.

Migration-oriented rules must not be described as authority mandates unless the controlled source supports that statement.

## 14. Archive and source-system integrity

For supported database/archive migration scenarios, eMAS shall support a controlled chain such as:

```text
Source DB record
→ archive/stored-object identifier
→ approved identifier normalization
→ expected archive object/path/key
→ physical lookup
→ Found / Missing / Multiple / Invalid / Inaccessible
→ dossier/sequence/document impact
```

Requirements:

- source-system/version-specific mappings shall be controlled;
- visible business filename shall not automatically be treated as physical archive identity;
- exact SQL and proprietary mappings are implementation-specific and separately controlled;
- false-missing safeguards shall verify mapping, conversion, root, recursive scope, extension assumptions and access before declaring missing;
- archive verification shall remain separate from generic eCTD validation.

## 15. Technical completeness model

Technical completeness shall be represented as layered assessment, not as a synonym for regulatory validation.

Required layers are conceptually:

1. Detect;
2. Identify;
3. Structure;
4. Referential integrity;
5. Object/integrity checks;
6. Lifecycle integrity;
7. explicitly implemented regulatory technical rules;
8. Migration Readiness.

A layer that cannot be executed due to missing evidence shall remain Unknown/Not Assessed with an explicit reason.

## 16. Assessment state, evidence state and RAG

These concepts shall remain separate.

### Assessment Status

At minimum:

- Assessed;
- Not Assessed;
- Unknown.

### Assessment Reason

At minimum:

- NONE;
- INPUT_UNAVAILABLE;
- ACCESS_DENIED;
- PARSE_FAILED;
- NOT_PERFORMED;
- NOT_APPLICABLE;
- CONFLICTING_EVIDENCE;
- INSUFFICIENT_EVIDENCE.

### Evidence State

At minimum:

- Present;
- ConfirmedAbsent;
- Unavailable;
- Invalid.

### RAG / Severity

At minimum:

- Green;
- Amber;
- Red;
- Unknown;
- Not Assessed where required by report model.

Missing/inaccessible evidence shall never silently become Green/Pass.

## 17. Confidence model

Confidence shall answer how strongly the available evidence supports the conclusion and shall remain independent from severity.

The configuration shall support evidence strength/authority and conflict handling. Typical outcomes:

- High;
- Medium;
- Low;
- Unknown.

Strong contradictory evidence shall not be silently resolved. It shall produce Ambiguous/Unknown/Manual Review according to the applicable rule.

Numerical evidence weights, if used, are internal design logic and not regulatory standards. They require validation before production use.

## 18. Rule model

Every executable rule shall have a stable RuleId.

Rules shall support scope/applicability by relevant dimensions such as:

- phase;
- migration scenario;
- region;
- authority;
- format;
- specification version;
- application/dossier type;
- lifecycle context;
- entity level;
- source-system context.

Rules shall support explicit condition groups, expected values/targets, finding impact, confidence impact, recommendation links and source provenance.

Unknown shall be treated as a real classification value, not as a wildcard. If required applicability evidence is unavailable, applicability shall be Undetermined rather than silently Not Applicable.

## 19. Findings, recommendations and ownership

Findings and recommendations shall remain separate controlled concepts.

A material finding shall be able to record:

- FindingId/RuleId;
- entity/scope;
- raw observation;
- evidence reference;
- interpretation category;
- severity;
- confidence;
- migration impact;
- recommendation code;
- owner category;
- action status;
- exception/disposition state;
- configuration and execution identity.

Likely owner categories may include Regulatory Operations/Publishing, Customer IT, Migration Team, Database Team, Application Support, DMS Team, Validation Team and Business Owner.

## 20. Effort and complexity requirements

Effort/complexity drivers shall support factors such as:

- dossier/sequence/document volume;
- total size and largest files;
- region/format diversity;
- unknown classifications;
- missing references/orphans;
- malformed XML/lifecycle breaks;
- missing archive objects;
- legacy/non-eCTD structures;
- DMS/source-system dependencies;
- database/version dependencies;
- manual remediation volume.

Unless a formally approved estimation model exists, eMAS shall present validated complexity/effort bands and drivers rather than unqualified hour estimates.

## 21. Migration scenario model

The configuration shall support scenario dimensions such as:

- existing EXTEDO customer;
- new/third-party customer;
- on-premises → cloud;
- on-premises → on-premises;
- database + archive migration;
- export-only migration;
- archive available / DB unavailable;
- DB available / archive unavailable;
- neither DB nor archive; export only;
- DMS-integrated source;
- mixed sources/environments;
- unsupported/legacy infrastructure.

Reusable business questionnaire definitions may belong in controlled configuration. Actual customer answers, detected values, verification evidence and project overrides shall remain project assessment evidence and shall not be exported into Runtime JSON as reusable rules.

## 22. Mapping Workbook requirements

The internal Mapping Workbook shall use macro-free `.xlsx` format and shall be suitable for Excel for the web and controlled SharePoint storage.

The workbook shall provide a guided, filterable, self-explanatory authoring experience with:

- Home/navigation;
- user guidance;
- document/configuration control;
- structured Excel Tables;
- controlled lists/dropdowns;
- validation feedback;
- source references;
- explicit Excel-to-JSON field mapping;
- review observations/change history;
- JSON preview where useful;
- export/release history mirror where useful.

The workbook is an authoring interface, not the machine contract.

### 22.1 Required logical areas

The current baseline shall support these logical areas, whether implemented as the current 24-sheet model or an approved future equivalent:

1. Home;
2. User_Guide;
3. Document_Control;
4. Assessment_Profile;
5. Classification_Rules;
6. Folder_Rules;
7. File_Rules;
8. RAG_Rules;
9. Effort_Drivers;
10. Confidence_Rules;
11. Decision_Rules;
12. Recommendations;
13. Value_Lists;
14. JSON_Field_Mapping;
15. Schema_Control;
16. Validation_Controls;
17. Validation_Results;
18. JSON_Preview;
19. Export_History;
20. Change_History;
21. Rule_Conditions;
22. Source_References;
23. Questionnaire_Fields;
24. Review_Observations.

The exact sheet/Table contract shall be versioned and may evolve under controlled change without changing the principle that normalized configuration is distinct from project evidence.

## 23. SharePoint requirements

SharePoint shall be used as the controlled internal repository for the Mapping Workbook and associated authoring/release records where available.

It shall support, according to internal governance:

- permissions;
- version history;
- controlled collaboration;
- review state;
- recoverability/audit history;
- storage of approved authoring artifacts and release evidence.

SharePoint document version is not the same as MappingVersion, SchemaVersion, Runtime Configuration Version or ReleaseId.

## 24. Runtime JSON requirements

Runtime JSON shall be independently defined from workbook presentation.

It shall:

- be governed by an independently versioned JSON Schema;
- use stable identifiers;
- contain reusable configuration only;
- exclude customer/project assessment answers and raw project evidence;
- be deterministic for equivalent approved content where required;
- be complete rather than incrementally patched for normal production generation;
- be immutable after release;
- be stored as UTF-8 according to the controlled contract;
- record configuration/release identity and digest information as defined by the release contract.

PowerShell shall not repair incompatible or invalid Runtime JSON during project execution.

## 25. Office Script / TypeScript requirements

Reviewed Office Scripts/TypeScript shall perform controlled workbook processing such as:

- reading named Tables/fields;
- normalizing values;
- validating mandatory structures;
- validating identifiers and controlled values;
- validating references;
- validating mapping/schema compatibility;
- preventing project assessment data from entering runtime configuration;
- constructing the complete candidate JSON object;
- generating validation results/preview evidence.

Office Scripts/TypeScript shall not become the hidden business-rule evaluation engine for migration assessment. Runtime business-rule evaluation remains in the PowerShell engine using the released configuration.

## 26. Release and integrity requirements

The internal release process shall support:

- exact controlled workbook snapshot where required;
- validation result identity;
- candidate configuration identity;
- exact Runtime JSON SHA-256;
- attributable review/approval according to internal process;
- immutable publication/release;
- trusted release evidence separate from business-rule content.

Normal runtime shall verify supported configuration/schema compatibility and the expected configuration digest according to the release contract.

## 27. Shared PowerShell engine requirements

The engine shall provide reusable modules/functions for:

- configuration load/validation;
- discovery;
- container/ZIP inspection;
- candidate-root detection;
- classification;
- XML parsing;
- sequence/submission inventory;
- file/reference/integrity assessment;
- DB/archive assessment where supported;
- volume metrics;
- RAG/confidence/effort evaluation;
- readiness;
- reconciliation;
- reporting;
- logging;
- common utilities.

The engine shall:

- remain usable without Excel installed;
- avoid unapproved external modules;
- validate runtime configuration before substantive scanning;
- use stable internal object schemas;
- handle unavailable evidence defensively;
- distinguish configuration error, technical error, unavailable evidence and business finding;
- preserve raw adverse findings when later decision logic or exceptions are applied;
- never overwrite source evidence.

## 28. Excel report/workbook requirements

Each phase shall use a separate controlled Excel template/workbook optimized for its purpose.

### 28.1 Common usability expectations

Reports/workbooks should provide, where appropriate:

- Home/Summary page;
- clear navigation;
- dashboard-style summary metrics;
- filterable tables;
- dossier/sequence drill-down sheets;
- findings/evidence tables;
- RAG and confidence presentation;
- remediation/action tracking;
- exception/disposition tracking;
- review fields;
- clear instructions and glossary;
- controlled calculated/protected fields where practical.

Excel is the human review interface; technical discovery and rule execution remain in PowerShell.

### 28.2 Common traceability

Every report shall record applicable identifiers such as:

- ExecutionId;
- phase;
- execution timestamp;
- engine/script version;
- Runtime JSON configuration/release identity;
- exact configuration SHA-256;
- schema/mapping version;
- template version;
- source scope;
- RuleIds;
- findings;
- evidence references;
- warnings/errors/limitations;
- final controlled outcome.

## 29. Logging requirements

Every execution shall create a timestamped log containing, as applicable:

- ExecutionId;
- start/end time;
- user/machine identity;
- PowerShell/OS version;
- phase and parameters;
- configuration/schema/template/script identity;
- configuration checksum;
- major processing steps and elapsed time;
- warnings;
- recoverable errors;
- fatal errors;
- final outcome;
- output paths.

Logs shall not include passwords or unnecessary sensitive content.

## 30. Baseline and reconciliation comparability

Post-Migration shall use the approved Pre-Migration baseline by default.

The baseline shall pin the applicable configuration/script/template/execution identity. If a different configuration release is used for post-migration interpretation, eMAS/project governance shall explicitly assess and document comparability rather than silently comparing outcomes derived under different rule sets.

## 31. Exceptions

Project accepted exceptions shall remain separate from reusable configuration.

An exception may alter blocker/decision treatment but shall not erase:

- original observation;
- original evidence;
- original severity;
- original confidence;
- original rule result.

Accepted exceptions shall be attributable and traceable to the baseline/reconciliation decision.

## 32. GxP-oriented traceability

eMAS shall support reproducibility, traceability, evidence retention, controlled rule/configuration versions, exception management and review evidence appropriate to its intended use.

A preferred traceability model is:

```text
Requirement
→ controlled design/configuration rule
→ Runtime JSON
→ engine function
→ test evidence
→ execution evidence
→ report result
→ review/disposition
```

These controls do not by themselves establish validated-state or regulatory compliance claims.

## 33. Security, privacy and repository controls

- Least privilege shall apply.
- Customer data, production logs, migration evidence and project-specific exceptions shall not be committed to the public source repository.
- Credentials shall not be stored in source-controlled configuration.
- Normal runtime shall remain offline-capable.
- The internal Mapping Workbook shall not be distributed as part of a customer Pre-Sales package unless explicitly approved for a separate purpose.
- Runtime/customer packages shall contain only the artifacts required for their intended phase.

## 34. Performance and safe failure

The engine shall use memory-conscious enumeration and avoid loading unnecessary content for large repositories.

Safe behavior shall include:

- incompatible Runtime JSON: stop before substantive assessment;
- missing mandatory input: stop with corrective information;
- missing optional evidence: continue with explicit Not Assessed/Unknown state;
- access denied: record Unavailable/ACCESS_DENIED, not ConfirmedAbsent;
- parse failure: preserve non-parser evidence where safe, mark parser-derived checks Not Assessed, and continue where policy permits;
- conflicting strong evidence: retain conflict and require appropriate review;
- unsupported region/version: report Unsupported/Unknown rather than coercing to a nearby supported profile;
- container/ZIP limits exceeded: stop/skip the affected assessment safely and record reason.

## 35. Explicitly superseded prior requirements

The following prior architecture requirements are superseded by this baseline:

1. XLSM/VBA as the production mapping/export route;
2. mandatory or optional WPF as the intended Pre-/Post-Migration user interface;
3. custom HTML/web application as a current requirement;
4. runtime PowerShell reading/interpreting the Mapping Workbook;
5. project/customer assessment evidence being part of reusable Runtime JSON;
6. ASMF being represented as a technical format;
7. folder-name-only classification as authoritative evidence.

Historical POC implementation artifacts may remain in the repository for traceability, but they shall not override this requirements baseline.

## 36. Open controlled decisions

The following require later controlled specification/approval before implementation is considered production-ready:

- exact 24-sheet/Table/column contract;
- exact Runtime JSON schema version and compatibility policy;
- exact Office Script/TypeScript implementation and qualification scope;
- exact SharePoint approval/release workflow;
- exact supported region/format/version matrix per release;
- exact XML extraction mappings for each regional/version profile;
- exact ZIP/container safety limits;
- exact source-system DB/archive mappings by supported product/version;
- exact RAG/decision thresholds and effort/confidence models;
- exact phase-specific Excel report templates;
- end-to-end validation strategy and release evidence model.

---

## 37. Final product principle

The current eMAS baseline shall optimize for simplicity:

- **PowerShell performs the assessment.**
- **Excel presents and manages human-readable configuration/results.**
- **SharePoint controls internal collaboration/versioning.**
- **Runtime JSON isolates production execution from authoring tools.**
- **Pre-Sales remains lightweight and script-based.**
- **Pre-Migration and Post-Migration remain deeper, evidence-driven PowerShell assessments reviewed through controlled Excel workbooks.**

Any future custom UI shall require a separate approved business case and requirements change rather than being assumed by the current architecture.
