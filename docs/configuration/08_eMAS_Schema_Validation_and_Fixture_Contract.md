# eMAS Schema Validation and Fixture Contract

**Version:** 1.0  
**Status:** Effective Verification Contract  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect and QA Lead  
**Decision references:** JSON-001–JSON-023; RM-001–RM-027; TEST-001–TEST-020  
**Canonical references:** Runtime JSON Contract v1.2; Normalized Rule Model v1.1; Normalized Relationship Matrix v1.0; Logical Data Dictionary v1.0

## 1. Purpose

This contract defines how eMAS Runtime JSON Schema 1.0.0 is independently verified.

It controls:

- fixture classifications;
- fixture expected results;
- structural and semantic validation layers;
- stable semantic error codes;
- execution commands;
- acceptance criteria for schema changes.

The validator is independent of the XLSM/VBA exporter and the PowerShell runtime engine. This independence helps detect a shared implementation mistake rather than repeating it across all validation layers.

## 2. Controlled artifacts

| Artifact | Path | Role |
|---|---|---|
| Runtime root schema | `config/schema/eMAS-runtime-config.schema.json` | JSON Schema Draft 2020-12 root contract |
| Schema definitions | `config/schema/defs/*.schema.json` | Local resources distributed with the root as one offline schema package |
| Fixture manifest | `config/schema/examples/fixture-manifest.json` | Expected validity and error codes |
| Synthetic base fragments | `config/schema/examples/base/` | Ordered fragments assembled into the baseline configuration |
| Valid fixtures | `config/schema/examples/valid/` | Positive structural and semantic cases |
| Boundary fixtures | `config/schema/examples/boundary/` | Valid edge and threshold-boundary cases |
| Invalid fixtures | `config/schema/examples/invalid/` | Negative structural and semantic cases |
| Independent validator | `build/validate_emas_schema.py` | Schema plus cross-collection semantic validation |
| Dependency lock | `build/requirements-schema-validation.txt` | Build-only validation dependency |
| Unit tests | `tests/schema/test_schema_fixtures.py` | Manifest, encoding and schema-version tests |
| CI workflow | `.github/workflows/schema-validation.yml` | Pull-request and main-branch validation |

## 3. Fixture classifications

### 3.1 Valid

A valid fixture must:

- conform to JSON Schema 1.0.0;
- satisfy all semantic relationship checks;
- use synthetic data only;
- produce no validation issue.

The suite contains both DEV and CONTROLLED examples. The CONTROLLED example exercises effective status, approval reference, release-manifest reference and checksum metadata.

### 3.2 Boundary

A boundary fixture is valid and exercises one or more edge conditions, such as:

- minimum allowed integer values;
- Semantic Version `0.0.0`;
- leap-day date-time parsing;
- lower-inclusive and upper-exclusive threshold contact;
- open-ended final threshold bands;
- explicit false Boolean values.

Boundary fixtures must pass both structural and semantic validation.

### 3.3 Invalid

An invalid fixture deliberately violates one controlled rule. Its manifest entry must identify at least one expected stable error code.

The initial materialized invalid suite covers:

- missing mandatory top-level content;
- broken field reference;
- duplicate RuleId;
- disallowed relationship endpoint pair;
- operator not allowed for the referenced field;
- overlapping thresholds;
- exception policy referencing an ineligible finding;
- output target that does not resolve.

An invalid fixture passes the test suite only when it fails validation for the expected reason.

## 4. Structural validation

The Draft 2020-12 validator checks:

- schema validity;
- required sections and fields;
- prohibited additional properties;
- primitive and object types;
- identifier and Semantic Version patterns;
- ISO date and date-time formats;
- controlled enumerations;
- conditional CONTROLLED export metadata;
- condition-operator value requirements;
- nested policy and report-terminology structures.

Structural failures use error code `SCHEMA_ERROR`.

## 5. Semantic validation

The independent semantic validator checks requirements that JSON Schema cannot reliably enforce across collections.

### 5.1 Identity and controlled values

- collection-specific primary-key uniqueness;
- composite-key uniqueness;
- master-data code uniqueness;
- mandatory value-list categories;
- mandatory phase, RAG, evaluation-status, provenance and export codes.

### 5.2 Relationships

- frozen RelationshipType endpoint pairs;
- source and target existence;
- duplicate endpoint pairs;
- approved polymorphic target types;
- self-supersession and supersession cycles;
- temporal range validity.

### 5.3 Rules and outputs

- RuleId references;
- one or more explicit rule phases;
- condition-group ownership;
- condition RuleId consistency;
- field and operator compatibility;
- field phase compatibility;
- one or more outputs per rule;
- output phase assignment;
- output target resolution by OutputType.

### 5.4 Findings, policies and reporting

- finding-to-recommendation references;
- exception eligibility;
- alias target resolution;
- effort-driver metric references;
- threshold range, overlap and gap rules;
- decision result and condition references;
- questionnaire trigger references;
- report-definition composite uniqueness.

## 6. Stable semantic error codes

The validator emits machine-readable codes before the path and message. Initial codes include:

| Code | Meaning |
|---|---|
| `SCHEMA_ERROR` | JSON Schema or format failure |
| `SEM_SCHEMA_VERSION` | Unsupported or inconsistent schema version |
| `SEM_REQUIRED_VALUE_LIST` | Mandatory controlled list missing |
| `SEM_REQUIRED_CODE` | Mandatory controlled code missing |
| `SEM_DUPLICATE_ID` | Duplicate primary identifier |
| `SEM_DUPLICATE_COMPOSITE` | Duplicate composite key |
| `SEM_BROKEN_REFERENCE` | Required reference cannot be resolved |
| `SEM_RELATIONSHIP_ENDPOINT` | RelationshipType uses a disallowed endpoint pair |
| `SEM_TEMPORAL_RANGE` | Effective end is not later than effective start |
| `SEM_SUPERSESSION_CYCLE` | Self-reference or cycle in rule supersession |
| `SEM_CONDITION_RULE_MISMATCH` | Condition and condition group belong to different rules |
| `SEM_OPERATOR_NOT_ALLOWED` | Field does not permit the selected operator |
| `SEM_FIELD_PHASE` | Field does not support the rule phase |
| `SEM_RULE_INCOMPLETE` | Rule is missing required phases, groups, conditions or outputs |
| `SEM_OUTPUT_PHASE` | Output phase is not assigned to the rule |
| `SEM_OUTPUT_TARGET` | OutputCode does not resolve for its OutputType |
| `SEM_EXCEPTION_INELIGIBLE` | Exception policy targets a non-eligible finding |
| `SEM_ALIAS_TARGET` | Alias canonical target does not resolve |
| `SEM_THRESHOLD_RANGE` | Threshold lower bound is not below upper bound |
| `SEM_THRESHOLD_OVERLAP` | Threshold bands overlap |
| `SEM_THRESHOLD_GAP` | Complete threshold bands contain a gap |
| `SEM_DECISION_RESULT` | Decision result is invalid for the selected phase |

New codes require test coverage and documentation. Existing code meaning must not be silently changed.

## 7. Fixture manifest

`fixture-manifest.json` is the fixture expectation contract. Each entry identifies either:

- a standalone `path`;
- ordered synthetic `fragments` that are merged into a complete base configuration; or
- ordered `fragments` plus an RFC 7396-style JSON Merge Patch `patch`.

Each entry also contains:

- `expectedValid` Boolean;
- one or more `expectedErrorCodes` for invalid variants.

The validator assembles fragments and applies patches in memory before schema and semantic validation. Fragment and patch files are never runtime configuration files by themselves.

The validator fails when:

- a valid or boundary fixture produces any issue;
- an invalid fixture unexpectedly passes;
- an invalid fixture does not produce its expected error code;
- a fixture is missing or cannot be parsed.

## 8. Execution

Local or CI validation:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
```

Single-instance validation:

```bash
python build/validate_emas_schema.py --instance path/to/eMAS_Runtime_Config.json
```

The validator returns exit code `0` only when expectations are met.

## 9. Independence and runtime boundary

Python and the pinned `jsonschema` dependency are used only for repository build, CI and independent release validation.

They are not:

- part of the customer Pre-Sales package;
- a PowerShell runtime dependency;
- used by PowerShell to generate or repair JSON;
- a replacement for XLSM/VBA pre-export validation;
- a replacement for defensive PowerShell loader validation.

The same semantic rules and fixtures should be re-used as conformance evidence when XLSM/VBA and the PowerShell loader are implemented.

## 10. Acceptance criteria

Schema synchronization is complete when:

1. JSON Schema Draft 2020-12 meta-validation passes;
2. all valid fixtures pass structural and semantic validation;
3. all boundary fixtures pass;
4. every invalid fixture fails for its expected code;
5. fixtures are UTF-8 without BOM and contain synthetic data only;
6. schema top-level sections match the Runtime JSON Contract;
7. field names and requiredness match the Data Dictionary;
8. relationship semantics match the Relationship Matrix;
9. CI runs the independent validator and unit tests;
10. the schema, fixture manifest and validator are version-controlled together.

## 11. Change control

A change to schema structure, semantic validation or fixture expectations requires:

- DecisionId and requirement references;
- schema compatibility assessment;
- synchronized updates to this contract, the Runtime JSON Contract, relationship matrix or data dictionary where affected;
- valid, invalid and boundary fixture updates;
- successful local and CI verification;
- Technical Architect and applicable Product Owner, PowerShell Lead or SME approval.

## 12. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-13 | Established the independent schema, fixture and semantic-validation verification contract for Runtime JSON Schema 1.0.0 |
