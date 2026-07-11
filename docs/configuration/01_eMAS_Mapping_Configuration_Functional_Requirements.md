# eMAS Mapping and Configuration Workbook — Functional Requirements

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Functional Requirements Specification  
**Version:** 1.0  
**Status:** Draft for Review  
**Scope:** Internal Mapping and Configuration Workbook  
**Classification:** Internal  
**Branding:** EXTEDO | a cormeo brand

---

## 1. Purpose

This document defines the functional requirements for the internal eMAS mapping and configuration workbook.

The workbook is the controlled internal source for business, regulatory, classification, validation, effort, confidence and recommendation rules used by the eMAS pre-sales, pre-migration and post-migration scripts.

The workbook shall validate its own content and export one runtime JSON file directly from Excel. PowerShell shall not read the workbook and shall not create the JSON.

---

## 2. Scope

The workbook shall support:

- controlled rule maintenance;
- controlled dropdown values;
- version and change history;
- dossier region, format and type classification rules;
- dossier folder-structure rules;
- mandatory, optional and conditional folder and file rules;
- RAG criteria;
- confidence rules;
- effort drivers and thresholds;
- recommendations;
- authority and alias mappings;
- questionnaire and clarification mappings;
- rule validation;
- JSON preview;
- direct JSON export;
- export history;
- traceability from rule to recommendation and requirement.

The workbook shall not:

- execute pre-sales, pre-migration or post-migration assessments;
- scan customer folders;
- read customer source data;
- generate Excel assessment reports;
- invoke PowerShell to create JSON;
- be distributed to customers.

---

## 3. User Roles

| Role | Responsibility |
|---|---|
| Mapping Administrator | Maintains workbook content and code lists |
| Regulatory SME | Reviews region, format, type and authority rules |
| Migration SME | Reviews folder, file, effort and readiness rules |
| Reviewer | Reviews validation results and change history |
| Release Owner | Confirms version/status and exports the runtime JSON |
| Developer | Implements compatible JSON consumption in PowerShell |

---

## 4. Functional Requirements

### 4.1 Workbook control

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-001 | MUST | The workbook shall display product name, workbook title, version, status and branding on the Home sheet. |
| FR-MAP-002 | MUST | The workbook shall maintain a unique configuration ID. |
| FR-MAP-003 | MUST | The workbook shall maintain mapping version and JSON schema version separately. |
| FR-MAP-004 | MUST | The workbook shall maintain owner, reviewer, effective date, status and change summary. |
| FR-MAP-005 | MUST | The workbook shall provide Draft, In Review, Reviewed, Effective, Superseded and Retired statuses. |
| FR-MAP-006 | MUST | Only Reviewed or Effective configurations shall be exportable unless an explicit development override is enabled. |
| FR-MAP-007 | SHOULD | The workbook shall visibly indicate when the file contains unvalidated changes. |
| FR-MAP-008 | MUST | The workbook shall maintain a change history with version, date, author, reviewer, reason and affected rule areas. |

### 4.2 Navigation and usability

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-010 | MUST | The Home sheet shall provide navigation links to all maintained rule sections. |
| FR-MAP-011 | MUST | The workbook shall use consistent tables, headers, filters and frozen rows. |
| FR-MAP-012 | MUST | Controlled fields shall use dropdown lists sourced from Value_Lists. |
| FR-MAP-013 | MUST | Free-text entry shall be limited to comments, descriptions and recommendation text. |
| FR-MAP-014 | SHOULD | Mandatory fields shall be visually distinguishable from optional fields. |
| FR-MAP-015 | SHOULD | Inactive and superseded rules shall remain visible for traceability but be excluded from normal runtime export. |

### 4.3 Rule identification and traceability

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-020 | MUST | Every rule shall have a unique stable RuleId. |
| FR-MAP-021 | MUST | RuleId shall not change when wording or thresholds are updated. |
| FR-MAP-022 | MUST | Each rule shall include RuleVersion, IsActive, Status and Priority. |
| FR-MAP-023 | MUST | Each rule shall identify applicable phase: PreSales, PreMigration, PostMigration or All. |
| FR-MAP-024 | MUST | Each rule shall support requirement references and recommendation references. |
| FR-MAP-025 | SHOULD | Each rule shall support source-reference or rationale fields. |
| FR-MAP-026 | MUST | The workbook shall reject duplicate RuleIds. |

### 4.4 Region classification

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-030 | MUST | The workbook shall maintain a controlled list of supported regions. |
| FR-MAP-031 | MUST | Region rules shall support folder, file, XML namespace, metadata, path and name indicators. |
| FR-MAP-032 | MUST | Region rules shall support strong, medium and weak evidence strength. |
| FR-MAP-033 | MUST | Region rules shall reference authority where applicable. |
| FR-MAP-034 | MUST | Region rules shall support Unknown when evidence is insufficient or conflicting. |
| FR-MAP-035 | SHOULD | Region rules shall support aliases and common customer naming variations. |

### 4.5 Format classification

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-040 | MUST | The workbook shall maintain supported dossier formats. |
| FR-MAP-041 | MUST | Format rules shall support eCTD 3.2.2, eCTD 4.0, regional eCTD, NeeS, VNeeS, ASMF-related structures, medical-device technical files, paper/non-electronic and Unknown. |
| FR-MAP-042 | MUST | Format rules shall support sequence-pattern, XML, file, folder and metadata indicators. |
| FR-MAP-043 | MUST | Format rules shall support authority-specific conditions. |
| FR-MAP-044 | MUST | Conflicting format evidence shall result in controlled conflict handling rather than silent selection. |

### 4.6 Dossier type classification

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-050 | MUST | The workbook shall maintain controlled dossier types. |
| FR-MAP-051 | MUST | Supported types shall include Human, Veterinary, Investigational, Post-Marketing, Medical Device, Biologics, Vaccines, Blood Products, Other and Unknown. |
| FR-MAP-052 | MUST | Type rules shall support metadata, path, folder, file and customer-provided indicators. |
| FR-MAP-053 | MUST | Type classification shall be independent from region and format unless a conditional rule explicitly links them. |

### 4.7 Folder-structure rules

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-060 | MUST | The workbook shall define valid dossier-root and sequence-folder patterns. |
| FR-MAP-061 | MUST | Folder rules shall support Mandatory, Optional, Conditional and Prohibited expectations. |
| FR-MAP-062 | MUST | Folder rules shall support region, format, type and phase applicability. |
| FR-MAP-063 | MUST | Folder rules shall support parent-child path relationships. |
| FR-MAP-064 | MUST | Folder rules shall define the consequence of missing, unexpected, empty or inaccessible folders. |
| FR-MAP-065 | MUST | Folder rules shall support m1 to m5 and authority-specific regional structures. |
| FR-MAP-066 | SHOULD | Folder rules shall support depth, branch-count and unknown-folder thresholds. |

### 4.8 File rules

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-070 | MUST | The workbook shall define mandatory, optional, conditional and prohibited files. |
| FR-MAP-071 | MUST | File rules shall support exact filename, wildcard, regex-like pattern, extension and relative path. |
| FR-MAP-072 | MUST | File rules shall support files such as index.xml, index-md5.txt, regional XML, checksum files and leaf content. |
| FR-MAP-073 | MUST | File rules shall define missing-file impact, unreadable-file impact and zero-byte-file impact. |
| FR-MAP-074 | SHOULD | File rules shall support minimum/maximum occurrence counts. |
| FR-MAP-075 | SHOULD | File rules shall support referenced-file expectations where applicable. |

### 4.9 XML detection rules

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-080 | MUST | XML rules shall support filename, root element, namespace, element and attribute indicators. |
| FR-MAP-081 | MUST | XML rules shall identify parser hint and expected evidence strength. |
| FR-MAP-082 | MUST | XML unreadability shall be configurable as warning, Amber or Red depending on context. |
| FR-MAP-083 | SHOULD | XML rules shall support expected values and value patterns. |

### 4.10 RAG rules

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-090 | MUST | The workbook shall support Green, Amber, Red, Unknown and Not Assessed. |
| FR-MAP-091 | MUST | RAG rules shall define severity, finding code and recommendation code. |
| FR-MAP-092 | MUST | RAG rules shall support phase-specific impact. |
| FR-MAP-093 | MUST | Missing required evidence shall never be automatically treated as Green. |
| FR-MAP-094 | MUST | Not Assessed shall be used where input is unavailable or not applicable. |
| FR-MAP-095 | MUST | Unknown shall be used where evidence exists but interpretation is inconclusive. |
| FR-MAP-096 | MUST | The workbook shall validate all RAG values against the approved code list. |

### 4.11 Confidence rules

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-100 | MUST | The workbook shall support High, Medium, Low and Unknown confidence. |
| FR-MAP-101 | MUST | Confidence rules shall consider number, strength and agreement of evidence indicators. |
| FR-MAP-102 | MUST | Conflicting evidence shall reduce confidence. |
| FR-MAP-103 | SHOULD | Confidence rules shall support weighted evidence. |
| FR-MAP-104 | MUST | Each classification result shall be traceable to matched rules and evidence. |

### 4.12 Effort drivers

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-110 | MUST | The workbook shall maintain effort-driver categories, thresholds, scores and recommendations. |
| FR-MAP-111 | MUST | Driver categories shall include volume, size, repository shape, regulatory mix, quality/completeness, migration approach, storage/transfer, customer readiness and technical risk. |
| FR-MAP-112 | MUST | Thresholds shall support numeric and categorical values. |
| FR-MAP-113 | MUST | Threshold rules shall define unit, operator, lower bound, upper bound and score impact. |
| FR-MAP-114 | MUST | Overall effort outputs shall support Very Low, Low, Medium, High and Very High. |
| FR-MAP-115 | MUST | Pre-sales effort scoring shall remain estimation support and shall not determine migration readiness. |

### 4.13 Recommendations

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-120 | MUST | Each recommendation shall have a unique RecommendationCode. |
| FR-MAP-121 | MUST | Recommendations shall support customer-facing text, consultant-facing text and next action. |
| FR-MAP-122 | MUST | Recommendations shall support severity and phase applicability. |
| FR-MAP-123 | MUST | Rules referencing a missing recommendation shall fail validation. |
| FR-MAP-124 | SHOULD | One rule may reference one primary and multiple secondary recommendations. |

### 4.14 Questionnaire and clarification mapping

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-130 | MUST | The workbook shall map missing or ambiguous evidence to clarification questions. |
| FR-MAP-131 | MUST | Each question shall include question ID, text, reason, priority, owner role and impact area. |
| FR-MAP-132 | SHOULD | Questions shall support phase and migration-scenario applicability. |

### 4.15 Aliases and source-column mappings

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-140 | MUST | The workbook shall maintain approved aliases for input column names and known labels. |
| FR-MAP-141 | MUST | Alias use shall not modify original source values. |
| FR-MAP-142 | MUST | Ambiguous aliases shall fail validation. |
| FR-MAP-143 | MUST | Original misspellings required by source templates, including DossierDirecotry, shall be preserved where required. |

### 4.16 Workbook validation

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-150 | MUST | The workbook shall provide a Validate Mapping function. |
| FR-MAP-151 | MUST | Validation shall detect missing sheets, columns and required values. |
| FR-MAP-152 | MUST | Validation shall detect duplicate IDs and duplicate active rules. |
| FR-MAP-153 | MUST | Validation shall detect invalid references, statuses, RAG values, confidence values, operators and units. |
| FR-MAP-154 | MUST | Validation results shall show severity, sheet, row, object ID, message and corrective action. |
| FR-MAP-155 | MUST | Critical validation errors shall block JSON export. |
| FR-MAP-156 | SHOULD | Warnings may permit export only after explicit confirmation. |

### 4.17 JSON preview and export

| ID | Priority | Requirement |
|---|---|---|
| FR-MAP-160 | MUST | The workbook shall provide Preview JSON and Export Runtime JSON functions. |
| FR-MAP-161 | MUST | JSON shall be generated directly by VBA within Excel. |
| FR-MAP-162 | MUST | The workbook shall export one UTF-8 JSON file. |
| FR-MAP-163 | MUST | JSON shall contain configuration metadata, code lists, active rules, recommendations and schema version. |
| FR-MAP-164 | MUST | PowerShell shall not be invoked during JSON export. |
| FR-MAP-165 | MUST | Export history shall record file name, path, timestamp, user, workbook version, schema version and result. |
| FR-MAP-166 | MUST | Inactive, Superseded and Retired rules shall be excluded from runtime JSON unless explicitly required for history metadata. |
| FR-MAP-167 | SHOULD | The workbook shall support a checksum or hash value for the exported JSON. |

### 4.18 Open questions

| ID | Open question | Impact |
|---|---|---|
| OQ-FR-001 | Should only Effective configurations be exportable, or should Reviewed also be allowed? | Release governance |
| OQ-FR-002 | Can one rule reference multiple recommendations, and how should primary/secondary order work? | JSON and reporting |
| OQ-FR-003 | Should warning-level validation findings require explicit user confirmation before export? | Export control |
| OQ-FR-004 | Should superseded rules be included in a non-runtime history section of the JSON? | Traceability and file size |
| OQ-FR-005 | Should accepted-exception categories and override permissions be maintained in this workbook or separately? | Pre/post-migration governance |
| OQ-FR-006 | Should the workbook support multilingual recommendation text? | Future international use |
| OQ-FR-007 | Should report-sheet enablement and output-column visibility be configuration-driven? | Reporting scope |

---

## 5. Functional Acceptance Criteria

The functional design is acceptable when:

1. all rule categories can be maintained through controlled tables;
2. all selectable values are controlled through Value_Lists;
3. all active rules have unique stable IDs;
4. invalid references and duplicate IDs are detected;
5. JSON preview reflects the active workbook content;
6. one valid UTF-8 JSON file can be exported directly from Excel;
7. PowerShell is not used for JSON creation;
8. export history is recorded;
9. the same JSON can be consumed by all three eMAS phases;
10. phase-specific script logic remains outside the mapping workbook.
