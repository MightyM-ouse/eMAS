# eMAS Mapping and Configuration Workbook — Technical Requirements

**Version:** 3.1  
**Status:** Approved  
**Scope:** XLSM logical model, VBA, validation, JSON export and compatibility

## 1. Technology baseline

| Area | Requirement |
|---|---|
| Workbook | Excel `.xlsm` |
| Supported Excel | 2019, 2021 and Microsoft 365 for Windows |
| Bitness | 32-bit and 64-bit |
| Automation | Source-controlled VBA imported into release workbook |
| Runtime export | UTF-8 JSON without BOM |
| Internet/database | Not required |
| Runtime PowerShell conversion | Prohibited |
| Controlled signing | Corporate code-signing certificate and documented re-signing procedure |

## 2. VBA source architecture

Mandatory standard modules:

`modMain`, `modConstants`, `modWorkbookStructure`, `modValidation`, `modRuleValidation`, `modReferenceValidation`, `modConditionValidation`, `modThresholdValidation`, `modConflictValidation`, `modJsonBuilder`, `modJsonWriter`, `modExportHistory`, `modLogging`, `modUtilities`.

Class modules include rule, condition, condition group, phase, finding, recommendation, validation result and JSON object classes.

All source is stored under source control as `.bas`, `.cls` and `.frm`. Release workbooks are built by importing approved source.

## 3. Engineering rules

- `Option Explicit` in all modules;
- no ActiveCell, Selection or fixed coordinates;
- identify data through table and column names;
- build JSON in memory;
- deterministic property and collection order;
- full Unicode escaping;
- UTF-8 without BOM;
- locale-independent dates and decimals;
- errors capture procedure, number, description and object context.

## 4. Condition and conflict contracts

Conditions use the approved operators:

`EQUALS`, `NOT_EQUALS`, `IN_LIST`, `CONTAINS`, `STARTS_WITH`, `ENDS_WITH`, `MATCHES_PATTERN`, `EXISTS`, `MISSING`, `GT`, `GTE`, `LT`, `LTE`, `BETWEEN`.

Same GroupId is AND; separate groups are OR. Maximum depth is two levels for schema 1.0.0.

Conflict strategies:

FirstMatch, MostSpecific, MostSevere, Aggregate, ErrorOnMultipleMatch, HighestEvidenceScore and ManualReview.

Defaults:

- Classification: HighestEvidenceScore.
- Folder/file findings: Aggregate.
- RAG rollup: MostSevere.
- Decisions: ordered FirstMatch with mandatory blocker override.

## 5. Runtime JSON contract

Canonical schema: `schemas/eMAS-runtime-config.schema.json`.

Canonical filename: `eMAS_Runtime_Config.json`.

DEV filename pattern: `eMAS_Runtime_Config.DEV.<timestamp>.json`.

Required top-level sections:

- configuration;
- valueLists;
- fieldCatalogue;
- metricCatalogue;
- masterData;
- relationships;
- rules;
- rulePhases;
- ruleConditionGroups;
- ruleOutputs;
- findings;
- recommendations;
- findingRecommendationLinks;
- exceptionPolicies;
- aliases;
- reportTerminology.

The JSON Schema uses Draft 2020-12 and `additionalProperties:false` for executable entities, with only documented descriptive extension points.

## 6. Versioning

- SchemaVersion and MappingVersion use Semantic Versioning independently.
- schema MAJOR: breaking structure or meaning change;
- schema MINOR: optional additive capability;
- schema PATCH: non-semantic clarification;
- unsupported schema major versions are rejected;
- minimumEngineVersion is mandatory.

## 7. Metadata and deterministic hashing

Configuration metadata contains configurationId, schemaId, schemaVersion, mappingVersion, sourceWorkbookVersion, minimumEngineVersion, exportType, exportId, exportedAtUtc, exportedBy, reviewStatus, effectiveFrom and checksum metadata.

A `rulesContentHash` covers canonicalized business content excluding volatile export fields. The release manifest also records the full-file SHA-256.

## 8. Validation sequence

1. workbook structure;
2. document-control metadata;
3. rebuild Rule_Index;
4. tables and columns;
5. controlled values;
6. unique IDs;
7. lifecycle and dates;
8. phases;
9. fields and operators;
10. condition groups;
11. thresholds;
12. conflicts;
13. findings;
14. recommendations;
15. exception policies;
16. aliases;
17. schema and engine compatibility;
18. normalized object build;
19. JSON build;
20. JSON structural validation;
21. preview;
22. export;
23. checksum and Export_History.

Critical validations are not disableable.

## 9. Locale and compatibility testing

Test exports under at least en-US and de-DE locale. Date fields use true dates with ISO display masks. Numeric threshold fields are validated as numeric values. Validation lists use named ranges.

## 10. Security

The workbook operates offline, embeds no credentials or customer data, protects structure and generated sheets, signs controlled VBA and records export history.
