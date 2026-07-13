# eMAS Pre-Migration Readiness Phase Contract

**Version:** 1.0  
**Status:** Effective Phase Contract  
**Effective date:** 2026-07-13  
**Phase code:** `PRE_MIGRATION`  
**Owner:** Product Owner, Migration SME and Technical Architect  
**Canonical references:** Enterprise Requirements v3.1 §14.2; Solution Architecture v1.0; Runtime JSON Contract v1.2; Runtime JSON Schema 1.0.0

## 1. Purpose

Perform detailed source-data readiness assessment, identify blockers/warnings/preparation actions and create the approved reusable baseline consumed by Post-Migration Verification.

The phase supports migration planning and evidence; it does not migrate data or constitute formal customer validation or acceptance.

## 2. Actors and execution

Execution methods:

- Windows PowerShell 5.1 CLI;
- optional portable WPF that invokes the same entry script and contains no independent business logic.

Primary actors are the consultant/migration team, customer IT/data owners and required exception approvers.

## 3. Inputs

### 3.1 Required

- source dossier/export roots in scope;
- output root;
- migration scenario and application context;
- runtime configuration package;
- controlled Pre-Migration template;
- scope/exclusion information required to identify the assessed population.

### 3.2 Conditional

- archive and index roots;
- database/storage/backup evidence;
- transfer/staging locations;
- customer-provided inventory or application extracts;
- project-specific accepted-exception evidence;
- prior Pre-Sales report as non-authoritative planning context.

Project-specific accepted exceptions are external evidence. They are not written into the master runtime configuration.

## 4. Preconditions

- configuration, checksum, schema and semantic validation pass;
- source evidence is accessible read-only;
- output/template initialization succeeds;
- scope and exclusions are attributable;
- accepted exceptions include required approval/evidence under the configured policy.

## 5. Required processing

The phase must:

1. initialize run metadata and detailed logging;
2. perform detailed discovery of dossiers, sequences, folders and files;
3. evaluate normalized region/authority/technical-standard/regional-implementation/product dimensions where evidence permits;
4. check configured folder and mandatory-file expectations;
5. perform applicable XML readability/structure checks;
6. detect inaccessible, missing, zero-byte, long-path and other configured technical issues;
7. assess database, archive/index, backup, storage, staging and transfer readiness where in scope;
8. preserve original findings, EvaluationStatus, RAG, ValueSource, evidence and confidence;
9. generate cleanup/preparation actions through finding-to-recommendation links;
10. validate and apply accepted-exception effects without erasing original evidence;
11. determine the phase result using configured decision policies and blocker override;
12. create the reusable comparison baseline;
13. populate the controlled Pre-Migration report and timestamped log.

## 6. Accepted-exception contract

An accepted exception may only have an effect allowed by its configured exception policy.

The execution/report must retain:

- original finding and evidence;
- original EvaluationStatus and RAG;
- exception identifier and effect;
- approver role/reference;
- supporting evidence reference;
- validity/expiry information where required;
- carry-forward decision for Post-Migration.

Default carry-forward is False. An exception must never delete or replace the original finding.

## 7. Readiness result contract

Permitted results:

- `Ready`;
- `Ready with Accepted Exceptions`;
- `Blocked`.

Decision evaluation uses ordered configured policies with mandatory blocker override. Missing required evidence, unresolved conflicts or failed critical checks must not be converted to Ready.

## 8. Baseline contract

The Pre-Migration report/evidence package must create an immutable, attributable baseline containing:

- baseline/run identifier;
- source scope and root references;
- stable dossier and sequence comparison identifiers;
- expected counts and agreed comparison measures;
- available file/size measures required by the later comparison;
- explicit exclusions;
- accepted exceptions and carry-forward status;
- unresolved limitations;
- configuration, schema, mapping, engine and template versions;
- integrity evidence sufficient for Post-Migration compatibility verification.

The exact physical storage of baseline data is controlled by the reporting/implementation specification. Any format change requires synchronized Post-Migration reader and compatibility testing.

## 9. Report contract

The controlled Pre-Migration report must include, at minimum:

- readiness summary and permitted result;
- execution/configuration metadata;
- scope, exclusions and limitations;
- normalized classification and inventory summary;
- detailed findings with EvaluationStatus, RAG, ValueSource, confidence and ReviewRequired separated;
- blockers, warnings and preparation actions;
- accepted-exception register preserving original findings;
- baseline/comparison dataset and integrity metadata;
- assumptions, intended use and non-validation statement;
- optional raw inventory where controlled by the template/package.

## 10. Logging and progress

Console and log output must clearly identify major discovery/validation steps, progress and completion. The log records inaccessible paths, skipped checks, rule/evidence references, exception treatment, baseline creation and generated file paths.

## 11. Failure behavior

Stop before assessment for invalid configuration/package/template, inaccessible mandatory source roots or output initialization failure.

Return `Blocked` or an explicit failed-execution state, according to the failure point, when critical evidence cannot be evaluated. A technical execution failure must not be presented as a completed readiness decision.

## 12. Acceptance criteria

The phase conforms when:

- CLI and optional WPF invoke the same orchestration;
- detailed checks are performed without modifying source evidence;
- accepted exceptions preserve original findings/evidence;
- only approved readiness terminology is used;
- a stable compatible baseline is generated;
- one controlled XLSX report and one detailed log are produced;
- all result-driving evidence and policies are traceable.
