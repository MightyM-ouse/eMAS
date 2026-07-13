# Runtime JSON Consumption Foundation

## Purpose

This note records the phase-neutral PowerShell foundation for consuming one immutable eMAS Runtime JSON file. It is an implementation boundary, not a Runtime JSON template or a source of business or regulatory meaning.

## Repository assessment before implementation

Assessment performed on `implementation/schema-warning-loader` before runtime-loader code was added:

- `engine/core/eMAS.Configuration.Contract.psm1` contained contract metadata and the approved EvaluationStatus list, but no file loading or semantic validation.
- `engine/powershell51/` and `engine/powershell7/` contained runtime-adapter contracts only. They did not duplicate business interpretation.
- `scripts/` contained only planned entry-point documentation. No Pre-Sales, Pre-Migration or Post-Migration entry script existed.
- No shared PowerShell logging module or runtime execution-log implementation existed.
- No Pester suite or other executable PowerShell test harness existed. Python tests covered static runtime-contract boundaries only.
- The authoritative Runtime JSON Schema 1.0.0 and Python semantic validator already defined the current exact schema and build-time conformance evidence. Python and `jsonschema` are not runtime dependencies.
- `build/Build-eMASMappingPoc.ps1` and `build/Test-eMASMappingPoc.ps1` use Excel only for internal POC workbook build/native conformance. They are not runtime phase scripts and are not obsolete runtime workbook readers.
- No runtime PowerShell code was found that opens an XLSM/XLSX mapping workbook, converts workbook rows to JSON or selects separate per-phase JSON files.
- Repository documentation consistently establishes one Excel/VBA-exported JSON consumed by all phases. References to reading `MigrationSummary.xlsx` in Post-Migration are phase evidence-input requirements, not mapping-configuration access.

The implementation therefore extends the established `engine/core` boundary and adds the three already-planned script names. It does not remove or modify internal POC build tooling.

## Loading flow

1. Resolve the caller-supplied path without changing the source file.
2. verify that it is an existing readable file;
3. read strict UTF-8 text and reject empty or malformed JSON;
4. calculate file size and SHA-256 identity from the original bytes;
5. extract metadata through the centralized compatibility contract;
6. run structural checks and schema-version compatibility handling;
7. run generic semantic hooks for controlled codes, uniqueness, references, lifecycle dates, priorities and phase applicability;
8. return a stable wrapper object and record sanitized identity/validation events in the execution log;
9. stop phase orchestration before assessment processing when blocking findings exist.

The loader does not invoke the build-time Python validator and does not claim full JSON Schema Draft 2020-12 validation. Release/build validation remains authoritative for exact schema conformance; the PowerShell layer provides defensive runtime checks.

## Public accessor and validation interface

- `Import-eMASRuntimeConfiguration`
- `Test-eMASRuntimeConfiguration`
- `Get-eMASConfigurationMetadata`
- `Get-eMASConfigurationSection`
- `Get-eMASConfigurationValue`
- `Get-eMASRuleCollection`
- `Get-eMASCodeList`
- `Resolve-eMASConfigurationPath`

Phase scripts receive the stable wrapper and should use these accessors instead of traversing `Raw` directly.

## Validation levels and error behavior

Structural validation covers metadata, supported schema versions, mandatory top-level sections, collection shape, mandatory rule identifiers and duplicate identifiers. File/read/encoding/JSON syntax failures are terminating import errors with stable `CFG-FILE-*` codes.

Semantic hooks return structured `CFG-SEM-*` findings for controlled code values, cross-references, priorities, effective/retired dates, threshold boundaries and phase applicability. Missing optional content returns `$null` or an empty collection. Missing mandatory configuration is blocking and never becomes an implicit pass.

Validation summaries expose overall status, severity counts, blocking count and ordered findings. The supported severity values are `Info`, `Warning` and `Error`.

## Execution-log fields

The configuration load records only technical traceability fields:

- execution ID, phase and active script;
- load start/finish UTC timestamps;
- resolved JSON path and file name;
- file size and SHA-256;
- configuration ID, configuration/mapping version and schema version;
- effective date and configuration status;
- validation status, error count, warning count, information count and blocking count;
- template path when supplied by later phase orchestration.

Configuration content, credentials and customer source evidence are not logged.

## Schema compatibility strategy

All temporary naming assumptions are centralized in `Get-eMASConfigurationLoaderContract` in `engine/core/eMAS.Configuration.Contract.psm1`. The current adapter recognizes authoritative Schema 1.0.0 names while allowing candidate aliases for metadata, rule collections and common identity/reference properties.

Unknown schema versions are blocking. Older versions may only be adapted after an explicit adapter is added to the contract; none are silently inferred.

## Assumptions awaiting Claude's final Runtime JSON

- the metadata section remains one of `configuration`, `metadata` or `configurationMetadata`;
- configuration version maps to the current `mappingVersion` or an explicitly named future equivalent;
- rules remain a top-level enumerable collection or a mapped rule-catalogue equivalent;
- finding-to-recommendation references remain available through a mapped link collection;
- controlled values remain available through a mapped value-list/code-list section;
- phase, RAG, confidence, migration-scenario and lifecycle values remain configuration-owned;
- threshold records continue to expose lower/upper boundaries and inclusivity flags through mapped properties;
- Schema 1.0.0 remains the only supported runtime schema until an approved compatibility decision says otherwise.

These assumptions are technical compatibility placeholders only. They do not define Claude's final template.

## Reconciliation after the final JSON arrives

1. Compare Claude's approved property and section names with the compatibility contract.
2. Update candidate names and explicit collection/reference descriptors in that one contract.
3. Confirm the supported schema-version list and add only approved version adapters.
4. Rebind semantic hooks to approved code-list names and relationship collections without adding business values to PowerShell.
5. Replace or extend synthetic fixtures to reflect the approved structure without copying production regulatory content.
6. Run PowerShell 5.1 and PowerShell 7.6 contract tests plus the authoritative schema/semantic fixture suite.
7. Confirm all three phase entry scripts still stop before assessment work on blocking configuration findings.
8. Record native Windows qualification separately; development tests do not establish release qualification.

## Read-only boundary

The module opens the Runtime JSON for reading, computes identity from the original file and never writes, repairs or enriches it. The only writes are caller-designated execution logs. Source evidence, mapping workbooks, XML, databases and input workbooks are outside this module's write boundary.
