# eMAS Post-Migration Verification Phase Contract

**Version:** 1.1  
**Status:** Effective Phase Contract  
**Effective date:** 2026-07-13  
**Phase code:** `POST_MIGRATION`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Decision reference:** `DEC-2026-07-13-PS-RUNTIME`  
**Canonical references:** Enterprise Requirements v3.1 §14.3; Solution Architecture v1.0; PowerShell Runtime Profile v1.0; Runtime JSON Contract v1.2; Runtime JSON Schema 1.0.0 plus approved amendments

## 1. Purpose

Compare migrated/import evidence against the approved Pre-Migration baseline, reconcile agreed dossier/sequence/file measures, classify discrepancies and preserve accepted-difference evidence.

Post-Migration Verification is not migration execution, formal regulatory validation, customer acceptance or electronic approval.

## 2. Actors and execution

Execution methods:

- PowerShell 7.6 LTS CLI on Windows using `pwsh.exe`;
- optional portable WPF that invokes the same PowerShell 7.6 Post-Migration entry script.

Development and pure unit/fixture testing may use PowerShell 7.6 LTS on macOS. Windows PowerShell 7.6 execution remains the authoritative phase-qualification gate.

Primary actors are the consultant/migration team, customer reviewers and approved exception owners.

## 3. Required inputs

- approved compatible Pre-Migration baseline;
- `MigrationSummary.xlsx` with the agreed import-report details;
- available post-import verification evidence;
- runtime configuration package;
- controlled Post-Migration report template;
- output root;
- applicable accepted-exception/accepted-difference evidence.

Optional additional evidence may include migration logs or technical extracts explicitly approved for the project. The phase must not depend on uncontrolled interpretation of such evidence.

## 4. Preconditions

- PowerShell 7.6 LTS runtime check passes;
- runtime configuration package passes integrity, schema and semantic validation;
- baseline identity, version and integrity are verifiable;
- `MigrationSummary.xlsx` is readable and contains the required detail structure for the supported import version;
- output/template initialization succeeds;
- selected evidence belongs to the intended project/run scope.

An incompatible or ambiguous baseline must stop reconciliation or produce `Review Required`; it must not be silently converted.

## 5. Required processing

The phase must:

1. initialize run metadata and detailed logging, including exact PowerShell/.NET/runtime-adapter information;
2. load and validate the approved Pre-Migration baseline;
3. read agreed detail from `MigrationSummary.xlsx`;
4. read available post-import verification evidence;
5. normalize comparison identifiers using approved aliases/configuration;
6. compare expected and migrated dossiers;
7. compare expected and migrated sequences;
8. compare file/count/size or other agreed measures where available and reliable;
9. identify matched, missing, extra, warning, error and ambiguous records;
10. preserve raw comparison evidence and ValueSource;
11. classify discrepancies using configured findings, RAG and decision policies;
12. apply accepted-exception/accepted-difference effects without erasing the original discrepancy;
13. determine the permitted reconciliation result;
14. populate the controlled Post-Migration report and timestamped log.

PowerShell 7-specific performance features may be used only through approved runtime adapters and must not change business interpretation or deterministic outcomes.

## 6. MigrationSummary interface

The reader for `MigrationSummary.xlsx` must:

- use controlled sheet/column mappings for supported versions;
- preserve source row identifiers where available;
- distinguish import status, warning and error information;
- report missing mandatory columns or unsupported structure clearly;
- avoid modifying the workbook;
- record the input file name, size, modification timestamp and integrity evidence available to the run.

Template/version-specific reader logic is technical processing. Meaning assigned to statuses and findings remains configuration-driven where applicable.

## 7. Reconciliation result contract

Permitted results:

- `Reconciled`;
- `Reconciled with Accepted Exceptions`;
- `Review Required`;
- `Not Reconciled`.

Result logic must consider unresolved missing/extra/error records, evidence confidence, accepted exceptions, baseline compatibility and mandatory discrepancy policies.

`Review Required` is used when evidence is ambiguous, incomplete or conflicting and a conclusive reconciliation result is not justified.

`Warning` is an approved EvaluationStatus for a completed usable evaluation with a recoverable condition requiring attention. It does not independently determine RAG or reconciliation result.

## 8. Discrepancy and exception contract

For every material comparison item, preserve:

- baseline identifier/value;
- migrated/import identifier/value;
- comparison outcome;
- EvaluationStatus;
- RAG;
- ValueSource;
- confidence and ReviewRequired;
- related finding/recommendation;
- accepted exception/difference and its approved effect;
- evidence references.

Accepted exceptions or differences never remove the underlying discrepancy record.

## 9. Report contract

The controlled Post-Migration report must include, at minimum:

- reconciliation summary and permitted result;
- execution/configuration/baseline metadata;
- MigrationSummary and post-import input metadata;
- dossier reconciliation;
- sequence reconciliation;
- available file/count/size reconciliation;
- missing, extra, warning, error and ambiguous records;
- discrepancy findings and recommendations;
- accepted-exception/accepted-difference register preserving original evidence;
- assumptions, limitations, intended use and non-validation statement;
- review actions and unresolved items;
- optional raw source/detail sheets where controlled by the template.

## 10. Logging and progress

Console output must show baseline loading, MigrationSummary reading, comparison stages, report generation and completion. The log records exact PowerShell 7.6/.NET/adapter information, comparison counts, skipped/unsupported evidence, reader/version decisions, discrepancy totals, exception treatment and generated file paths.

## 11. Failure behavior

Stop before comparison when PowerShell 7.6, configuration, template or required baseline integrity fails.

Use failed-execution or `Review Required` behavior according to the failure point when MigrationSummary or post-import evidence cannot be interpreted reliably. Do not issue `Reconciled` when mandatory evidence was not assessed.

## 12. Acceptance criteria

The phase conforms when:

- CLI and optional WPF use the same PowerShell 7.6 entry script and engine;
- the common business core remains single-sourced and runtime adapters contain no independent interpretation;
- the approved Pre-Migration baseline is always used;
- `MigrationSummary.xlsx` details are read without modification;
- dossier and sequence reconciliation is attributable;
- accepted exceptions preserve original discrepancies and evidence;
- only approved result terminology is used;
- one controlled XLSX report and one timestamped log are generated;
- missing/extra/warning/error/ambiguous records remain reviewable and traceable;
- Windows PowerShell 7.6 qualification evidence is recorded.
