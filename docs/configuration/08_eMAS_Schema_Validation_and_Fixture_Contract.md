# eMAS Schema Validation and Fixture Contract

**Version:** 1.1  
**Status:** Effective Verification Contract  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect and QA Lead  
**Decision references:** JSON-001–JSON-023; RM-001–RM-027; TEST-001–TEST-020  
**Canonical references:** Runtime JSON Contract v1.3; Normalized Rule Model v1.2; Normalized Relationship Matrix v1.0; Logical Data Dictionary v1.1

## 1. Purpose

This contract defines how eMAS Runtime JSON Schema 1.0.0 and 1.1.0 are independently verified.

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
| Unit tests | `tests/schema/test_schema_fixtures.py`, `tests/schema/test_identification_schema_1_1.py` | Manifest, encoding, schema-version, version-gate and Identification-guard tests |
| CI workflow | `.github/workflows/schema-validation.yml` | Pull-request and main-branch validation |

## 3. Fixture classifications

### 3.1 Valid

A valid fixture must:

- conform to the JSON Schema for its declared `schemaVersion` (1.0.0 or 1.1.0);
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
- `Warning` EvaluationStatus kept separate from RAG/phase result behavior;
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
- output target that does not resolve;
- unknown EvaluationStatus value;
- missing mandatory `Warning` value-list code;
- unknown EvaluationStatus value-list code.

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

Structural failures use error code `SCHEMA_ERROR`, with two stable specializations:

- `SCHEMA_VERSION_FEATURE`: a Schema 1.1.0 property appears in a document that declares `1.0.0` (root `VERSION-GATE-1.0.0` branch);
- `SCHEMA_UNSUPPORTED_VERSION`: `configuration.schemaVersion` is not `1.0.0` or `1.1.0`.

Version dispatch is enforced by JSON Schema itself, so a consumer that runs only JSON Schema also rejects 1.1.0 fields labelled as 1.0.0.

## 5. Semantic validation

The independent semantic validator checks requirements that JSON Schema cannot reliably enforce across collections.

### 5.1 Identity and controlled values

- collection-specific primary-key uniqueness;
- composite-key uniqueness;
- master-data code uniqueness;
- mandatory value-list categories;
- mandatory phase, RAG, evaluation-status including `Warning`, provenance and export codes;
- for Schema 1.1.0: the exact `EVIDENCE_STRENGTH`, `CONFIDENCE`, `EVIDENCE_POLARITY`, `TIE_BEHAVIOR` and `CORROBORATION_RULE` code sets, `IDENTIFICATION_DIMENSION` codes limited to canonical master-data entity types, and `EVIDENCE_STRENGTH.sortOrder` reproducing STRONG > MEDIUM > WEAK.

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

### 5.3.1 Identification rules (Schema 1.1.0)

- `ruleType = IDENTIFICATION` is rejected in a 1.0.0 document;
- `IDENTIFICATION` resolves to `RULE_TYPE`; `conflictGroup` is required and must be an approved `IDENTIFICATION_DIMENSION`;
- each Identification `ClassificationCandidate` requires `targetEntityType`, `evidenceStrength` and `evidencePolarity`; `targetEntityType` must be approved and equal `conflictGroup`;
- `outputCode` must exist in the declared `targetEntityType` collection (dimension-scoped resolution; no global cross-dimension uniqueness);
- `evidenceStrength` and `evidencePolarity` resolve to their lists;
- `evidenceStrength` must not exceed the weakest `maxEvidenceStrength` of the fields used by the rule's non-negated conditions, and each such field must declare a ceiling;
- Identification candidates carry no `outputValue`;
- Identification metadata on any other output is rejected;
- Identification conflict policies: `ruleType` resolves to `RULE_TYPE`, `tieBehavior` to `TIE_BEHAVIOR`, `minimumEvidenceStrengthForValue` to `EVIDENCE_STRENGTH`;
- Identification confidence policies (`scope = IDENTIFICATION`): `evidenceStrength`, `resultConfidence` and `corroborationRule` resolve to their lists and `weightOrScore` is absent;
- `minimumEvidenceStrengthForValue`, `resultConfidence` and `corroborationRule` outside Identification scope are rejected.

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
| `SEM_UNKNOWN_CODE` | Controlled code is not approved for a mandatory controlled list |
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
| `SCHEMA_VERSION_FEATURE` | Schema 1.1.0 property in a document that declares 1.0.0 |
| `SCHEMA_UNSUPPORTED_VERSION` | `schemaVersion` is not a supported version |
| `SEM_VERSION_FEATURE` | `ruleType = IDENTIFICATION` in a document that declares 1.0.0 |
| `SEM_ORDINAL_ORDER` | `EVIDENCE_STRENGTH` sortOrder is missing, duplicated or not STRONG > MEDIUM > WEAK |
| `SEM_CONTROLLED_REFERENCE` | An Identification-scoped value does not resolve to its governing list (path identifies the property) |
| `SEM_IDENTIFICATION_METADATA_REQUIRED` | Required Identification metadata or field ceiling is missing |
| `SEM_IDENTIFICATION_METADATA_SCOPE` | Identification-only property used outside Identification scope |
| `SEM_IDENTIFICATION_DIMENSION` | `conflictGroup` or `targetEntityType` is not an approved `IDENTIFICATION_DIMENSION` |
| `SEM_IDENTIFICATION_DIMENSION_MISMATCH` | `targetEntityType` differs from the rule's `conflictGroup` |
| `SEM_EVIDENCE_STRENGTH_CEILING` | Output `evidenceStrength` exceeds the evidence-field ceiling, or the rule has no positive evidence field |
| `SEM_IDENTIFICATION_NUMERIC_WEIGHT` | Numeric score or weight on an Identification candidate or confidence row |

For Identification candidates, `SEM_OUTPUT_TARGET` means the code does not exist in the declared `targetEntityType`.

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

Schema 1.1.0 fixtures assemble the four 1.0.0 base fragments plus `base/05-identification-1.1.json`. The manifest records `supportedSchemaVersions` `1.0.0` and `1.1.0`. The original 1.0.0 fixtures are unchanged and keep their expectations.

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
| 1.1 | 2026-10-06 | Added Schema 1.1.0 version dispatch, Identification semantic guards, stable error codes and fixtures |
