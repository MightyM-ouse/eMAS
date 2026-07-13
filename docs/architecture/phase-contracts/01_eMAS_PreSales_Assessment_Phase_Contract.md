# eMAS Pre-Sales Assessment Phase Contract

**Version:** 1.1  
**Status:** Effective Phase Contract  
**Effective date:** 2026-07-13  
**Phase code:** `PRE_SALES`  
**Owner:** Product Owner and Technical Architect  
**Decision reference:** `DEC-2026-07-13-PS-RUNTIME`  
**Canonical references:** Enterprise Requirements v3.1 §14.1; Solution Architecture v1.0; PowerShell Runtime Profile v1.0; Runtime JSON Contract v1.2; Runtime JSON Schema 1.0.0 plus approved amendments

## 1. Purpose

Provide a lightweight, customer-friendly assessment of migration scope, volume, complexity, confidence, key effort drivers and clarification needs before project initiation.

Pre-Sales is not a readiness assessment, migration validation, regulatory validation or acceptance activity.

## 2. Actors and execution

| Actor | Responsibility |
|---|---|
| Customer IT | Supplies permitted inputs, executes the package and shares the generated report/log requested by the instructions |
| Consultant / Pre-Sales team | Reviews the report, assumptions, confidence and clarification register |
| Product/technical owners | Maintain approved package, runtime configuration and controlled template |

Execution methods:

- Windows PowerShell 5.1 CLI on Windows using `powershell.exe`;
- optional simple command launcher;
- no PowerShell 7 prerequisite for the customer package;
- no WPF requirement and no Pre-Migration/Post-Migration interface in the customer package.

Development may use PowerShell 7.6 LTS on macOS, but Windows PowerShell 5.1 execution is the authoritative phase-qualification gate.

## 3. Package contract

The package contains only:

- `eMAS-PreSalesAssessment.ps1` and optional launcher;
- required Windows PowerShell 5.1-compatible common-core and adapter modules;
- controlled `eMAS_Runtime_Config.json` and checksum/integrity evidence;
- controlled Pre-Sales XLSX template;
- concise customer execution instructions;
- designated output location.

It excludes the internal XLSM, VBA source, WPF, PowerShell 7-only adapters, other phase scripts, internal tests, governance material and confidential assets.

## 4. Inputs

### 4.1 Required

- customer/application identifier suitable for the report;
- migration scenario or `NotSpecified` where permitted;
- one or more accessible evidence roots appropriate to the selected scenario;
- output root;
- runtime configuration package and controlled template supplied with the release.

### 4.2 Optional or scenario-dependent

- database file/location information or customer-provided database size;
- archive and index roots;
- export or transfer folder roots;
- storage capacity/free-space information;
- application/version details;
- customer-provided counts or sizes when direct access is not available;
- approved exclusions.

Exact parameter names are defined by the script-interface implementation and must map unambiguously to this contract.

## 5. Preconditions

- Windows PowerShell 5.1 runtime check passes;
- package integrity and runtime JSON compatibility pass;
- required evidence roots are accessible read-only;
- output path is writable;
- customer instructions identify which generated files must be shared;
- no credential is embedded in parameters, files or logs.

## 6. Required processing

The phase must:

1. initialize run metadata and timestamped logging, including exact PowerShell edition/version and adapter version;
2. show clear console progress for long-running steps;
3. perform proportionate folder/file discovery and volume calculation;
4. collect or derive permitted storage/database/archive/export measures;
5. evaluate configured classification candidates and preserve supporting evidence;
6. apply high-level folder/structure RAG only at Pre-Sales depth;
7. calculate configured effort drivers, final complexity band and effort confidence;
8. generate assumptions, limitations, missing-information items and customer clarifications;
9. populate the controlled Pre-Sales template through the reporting engine;
10. state the exact report and log files to share at completion.

## 7. Prohibited or non-mandatory processing

Pre-Sales must not:

- determine `Ready`, `Blocked`, `Reconciled` or any equivalent readiness/acceptance result;
- require deep XML validation, referenced-file validation, checksum validation, backup validation or reconciliation;
- perform migration or modify source evidence;
- expose raw internal scoring by default;
- treat missing evidence as Green or Pass;
- include customer-specific or internal Confluence identifiers in output filenames;
- include PowerShell 7-only adapters, Pre-Migration/Post-Migration UI or internal configuration assets.

Deeper technical checks may be introduced only as explicitly optional and proportionate checks that do not change the phase into a readiness assessment.

## 8. Evaluation and result contract

Required customer-facing results:

- complexity: `Very Low`, `Low`, `Medium`, `High` or `Very High`;
- confidence: `High`, `Medium`, `Low` or `Unknown`;
- scope and volume summary;
- key effort drivers;
- assumptions and limitations;
- customer clarification register;
- review-required indicators.

`EvaluationStatus`, `RAG`, `ValueSource`, `Confidence` and `ReviewRequired` remain separate fields/concepts. `Warning` is an approved EvaluationStatus for a completed usable evaluation with a recoverable condition requiring attention; it does not itself set RAG or complexity.

Unknown or conflicting classification evidence must remain visible and must not be silently forced to a known value.

## 9. Report contract

The controlled Pre-Sales report must include, at minimum:

- executive summary;
- execution and configuration metadata;
- source/evidence scope;
- normalized classification dimensions and evidence;
- inventory/volume summary;
- complexity and effort-confidence summary;
- high-level findings with EvaluationStatus, RAG, ValueSource and confidence separated;
- customer-clarification register;
- assumptions, limitations, intended use and non-validation statement;
- optional raw inventory, controlled by package/report settings.

The report must not use `Readiness`, `Ready`, `Validation Passed` or equivalent wording for the phase result.

## 10. Logging and evidence

The log records:

- run and version metadata;
- exact PowerShell edition/version, Windows version, process architecture and adapter version;
- sanitized parameters;
- each major processing step and duration;
- inaccessible locations, skipped checks, warnings and limitations;
- runtime JSON checksum and template version;
- output paths and final completion state.

The script must clearly tell the customer which generated files should be shared with the project team.

## 11. Failure behavior

Stop before assessment when runtime, package/configuration/template integrity fails, mandatory inputs are missing or the output location cannot be initialized.

During assessment, inaccessible optional evidence becomes an explicit evaluation status, assumption, limitation or clarification item according to configuration. It must not be reported as Green.

## 12. Acceptance criteria

The phase conforms when:

- it runs from CLI under Windows PowerShell 5.1 without PowerShell 7 or WPF dependency;
- it remains read-only and offline;
- it uses the shared 5.1-compatible core, applicable adapter and one controlled runtime JSON;
- it completes the required lightweight processing without mandatory deep readiness checks;
- it generates one controlled XLSX report and one timestamped log;
- report terminology contains no readiness/acceptance claim;
- complexity, confidence and clarification outputs are traceable to evidence and configuration;
- completion output identifies files to share;
- Windows PowerShell 5.1 qualification evidence is recorded.
