# eMAS Enterprise Requirements Specification

**Project:** eMAS — eCTD Migration Assessment Script  
**Version:** 3.1  
**Status:** Final / Effective  
**Effective date:** 13 July 2026  
**Classification:** Internal  
**Decision baseline:** All decisions in `docs/governance/eMAS_Decision_Log.md`

## 1. Purpose

This specification is the authoritative enterprise baseline for eMAS. It incorporates the approved decision register and supersedes Version 3.0 where the two differ.

## 2. Product definition

eMAS is a read-only, mapping-driven migration assessment framework supporting:

1. Pre-Sales Assessment;
2. Pre-Migration Readiness;
3. Post-Migration Verification.

eMAS does not perform migration, repair customer data, perform regulatory validation, replace customer validation, establish electronic approval or constitute formal acceptance.

## 3. Authoritative architecture

### REQ-ARCH-001

Business and regulatory rules shall be maintained in an internal, reviewed Excel XLSM workbook.

### REQ-ARCH-002

The XLSM shall validate its content and directly export one UTF-8 runtime JSON configuration.

### REQ-ARCH-003

PowerShell shall not read the XLSM and shall not generate the runtime JSON.

### REQ-ARCH-004

The same reviewed runtime JSON shall be used by all three assessment phases.

### REQ-ARCH-005

The JSON shall define shared interpretation, controlled values and rules; each phase shall retain its own orchestration, input depth, checks, decision logic, performance behaviour and report contract.

### REQ-ARCH-006

Shared technical processing shall be implemented once in reusable PowerShell modules.

### REQ-ARCH-007

Pre-Migration and Post-Migration may use an optional portable WPF interface. WPF shall collect inputs and invoke the same entry scripts; it shall not contain separate assessment logic.

## 4. Source-of-truth model

- Authoring source of truth: approved internal XLSM.
- Runtime source of truth: validated immutable JSON exported from the approved XLSM.
- Execution source: exact JSON version and content hash loaded for a run.

## 5. Phase contracts

### 5.1 Pre-Sales Assessment

- execution: command line or simple launcher;
- customer-facing and intentionally lightweight;
- performs accessibility, count/size, dossier/sequence detection, high-level classification, complexity and confidence assessment;
- avoids deep XML, referenced-file and readiness validation;
- result: complexity band, estimate confidence, scope and clarification items.

### 5.2 Pre-Migration Readiness

- execution: command line or optional WPF;
- performs detailed source checks, backup/access/storage checks, folder/file/XML checks, exception treatment and baseline creation;
- result: Ready, Ready with Accepted Exceptions, or Blocked;
- produces the controlled baseline consumed by Post-Migration.

### 5.3 Post-Migration Verification

- execution: command line or optional WPF;
- compares migrated evidence against the controlled Pre-Migration baseline;
- applies approved project exceptions without erasing original findings;
- result: Reconciled, Reconciled with Accepted Exceptions, Review Required, or Not Reconciled.

## 6. Configuration and rule model

### REQ-CFG-001

The mapping workbook shall use a normalized model separating:

- rule definitions;
- phase assignments;
- condition groups and conditions;
- outputs;
- findings;
- recommendations and links;
- lifecycle and supersession;
- exception policies;
- field and metric catalogues;
- master-data relationships.

### REQ-CFG-002

Editable `IsActive` shall not control rule lifecycle. Runtime eligibility shall be derived from Effective status and effective dates.

### REQ-CFG-003

Findings and recommendations shall be separate entities.

### REQ-CFG-004

Evaluation status and RAG shall be separate. RAG values are Green, Amber, Red and Unknown only.

### REQ-CFG-005

Accepted exceptions shall never erase or replace original findings or original result values.

### REQ-CFG-006

Thresholds shall default to lower-inclusive and upper-exclusive.

### REQ-CFG-007

Effort shall use a hybrid model combining weighted scores with mandatory minimum-band overrides. Effort confidence shall be calculated separately.

## 7. Runtime JSON

### REQ-JSON-001

The canonical runtime filename shall be `eMAS_Runtime_Config.json`.

### REQ-JSON-002

The JSON shall conform to `schemas/eMAS-runtime-config.schema.json`, JSON Schema Draft 2020-12.

### REQ-JSON-003

SchemaVersion and MappingVersion shall use Semantic Versioning independently.

### REQ-JSON-004

Controlled runtime JSON shall contain only Effective, date-eligible entities plus minimum traceability metadata.

### REQ-JSON-005

Controlled release packaging shall record SHA-256 and the engine shall verify the configured checksum before execution.

### REQ-JSON-006

Invalid syntax, unsupported schema major versions, missing mandatory sections, broken mandatory references, unknown executable operators and failed controlled checksums shall stop execution.

## 8. Evidence and reporting

### REQ-EVD-001

Every material result shall be traceable to execution ID, source evidence, rule ID, script version, JSON version/hash, template version, timestamp, evaluation status and limitation where applicable.

### REQ-EVD-002

Value source types shall be Observed, CustomerProvided, Imported, Derived or Assumed.

### REQ-EVD-003

Every execution shall produce one phase-specific XLSX report and one detailed timestamped UTF-8 log.

### REQ-EVD-004

Reports shall use controlled templates and terminology. Confluence IDs shall not appear in customer-facing filenames or console output.

## 9. Technology baseline

- Windows PowerShell 5.1 is the mandatory v1 runtime.
- Excel is not required during script execution.
- No external PowerShell module dependency is permitted unless an approved exception changes this baseline.
- XLSX generation shall be implemented through template-based OpenXML part editing using built-in .NET capabilities; an OpenXML SDK assembly may be packaged only if the approved spike demonstrates that raw APIs cannot satisfy workbook-validity requirements.
- Excel authoring support: Excel 2019, Excel 2021 and Microsoft 365 for Windows, 32-bit and 64-bit.

## 10. Governance

Canonical authority, statuses, conflict handling, change authority, terminology, Decision IDs and supersession are controlled by the governance documents referenced in `docs/CANONICAL_DOCUMENT_INDEX.md`.

## 11. Acceptance

The solution is acceptable when:

1. all three phases use the same validated JSON;
2. PowerShell never reads the mapping workbook or creates JSON;
3. source data remains read-only;
4. phase contracts and controlled result terms are implemented;
5. schema, configuration, templates, engine and reports are versioned and traceable;
6. required unit, integration, scenario, compatibility, performance and release tests pass;
7. reports open without repair and avoid validation overstatement;
8. customer and project evidence are not committed to the public source repository.
