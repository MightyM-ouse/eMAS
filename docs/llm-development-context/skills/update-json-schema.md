---
SkillId: SKILL-002
Title: Update the eMAS Runtime JSON Schema
Version: 1.0.0
Status: Effective
Owner: Technical Architect and QA Lead
DecisionReferences:
  - SK-005
  - JSON-001
  - JSON-023
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/configuration/04_eMAS_Runtime_JSON_Contract.md
  - docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md
  - docs/configuration/07_eMAS_Data_Dictionary.md
  - docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md
  - config/schema/eMAS-runtime-config.schema.json
  - config/schema/examples/fixture-manifest.json
AppliesTo:
  - Runtime JSON Schema
  - Semantic validator
  - Valid invalid and boundary fixtures
Supersedes: null
LastReviewed: 2026-07-13
---

# Update the eMAS Runtime JSON Schema

## Invoke when

- Adding or changing a runtime collection, property, type, required field, enumeration, conditional rule or serialization constraint.
- Changing semantic cross-collection validation, stable error codes or fixture expectations.
- Publishing a new compatible or breaking Runtime JSON Schema version.

## Do not invoke when

- Only approved configuration records change and the existing schema already represents them; use the configuration-content workflow.
- The logical model itself is unresolved; use `modify-configuration-model.md` first.
- A PowerShell loader defect is being fixed without schema change; use `investigate-defect.md` and `implement-powershell-module.md`.

## Required inputs and canonical sources

- Approved requirement/DecisionIds and logical-model change, if any.
- Current Runtime JSON Contract, Relationship Matrix, Data Dictionary and Schema Validation/Fixture Contract.
- Root schema, all local definition schemas, fixture manifest and independent validator implementation.
- Current minimum engine compatibility and controlled-export requirements.
- Explicit expected valid, invalid and boundary behaviors.
- Acceptance criteria for XLSM/VBA and PowerShell-loader conformance impact.

## Preconditions

- Logical entities, fields, requiredness, cardinalities and serialization names are approved.
- Compatibility classification and intended schema version are defined.
- Stable semantic error behavior is understood.
- Test data can remain synthetic and non-authoritative for regulatory content.
- No unresolved conflict exists between the Runtime JSON Contract and frozen logical model.

## Procedure

1. **Resolve authority and scope.** Record the governing requirement/DecisionIds and affected JSON paths.
2. **Classify compatibility.** Apply Semantic Versioning: breaking structure/meaning changes require MAJOR, additive optional structure requires MINOR and non-structural correction requires PATCH.
3. **Update governing contracts first.** Synchronize the Runtime JSON Contract, Relationship Matrix and Data Dictionary before or with schema changes.
4. **Modify the root and local schemas.** Keep the package offline, Draft 2020-12 compatible and free of remote runtime dependencies.
5. **Enforce structural constraints.** Define required properties, types, formats, enumerations, conditionals and `additionalProperties` behavior explicitly.
6. **Update semantic validation.** Add cross-collection uniqueness, reference, endpoint, temporal, phase, operator, output-target, threshold or policy checks that JSON Schema cannot enforce reliably.
7. **Assign stable errors.** Reuse existing error codes without changing their meaning; add a documented code only when a distinct validation condition is required.
8. **Create positive evidence.** Add or update at least one valid fixture demonstrating the supported structure.
9. **Create negative evidence.** Add an invalid fixture for each new rejection behavior and declare expected error codes in the manifest.
10. **Create boundary evidence.** Cover minimum/maximum, inclusive/exclusive, nullability, optionality, date/time, version or collection-boundary behavior as applicable.
11. **Run independent checks.** Meta-validate all schemas, run the complete fixture manifest and run schema unit tests.
12. **Assess consumers.** Record required XLSM/VBA export changes, PowerShell loader changes, engine compatibility changes, documentation and release-manifest changes.
13. **Synchronize routing.** Update schema README, canonical/context indexes and changelog when version/status or paths change.

## Required outputs

- Updated schema package and documented schema version.
- Updated Runtime JSON Contract and logical contracts, or evidence that they are unaffected.
- Updated semantic validator and stable error-code documentation.
- Valid, invalid and boundary fixtures with manifest expectations.
- Compatibility matrix covering prior schema, exporter and engine versions.
- Validation command output and CI evidence.
- Downstream XLSM/VBA and PowerShell conformance actions.

## Stop conditions

Stop when:

- the logical model is not approved or is internally inconsistent;
- a breaking change lacks approved versioning/migration treatment;
- an existing error code would acquire a different meaning;
- a remote schema/runtime dependency would be introduced;
- fixture content would expose customer data or be mistaken for approved regulatory content;
- exporter or loader compatibility cannot be assessed;
- structural and semantic ownership is ambiguous;
- required acceptance criteria are missing.

## Validation and evidence

- Run `python build/validate_emas_schema.py`.
- Run `python -m unittest discover -s tests/schema -p "test_*.py" -v`.
- Confirm every schema file passes Draft 2020-12 meta-validation.
- Confirm valid/boundary cases produce no issue and every invalid case produces its expected code.
- Confirm fixture files are UTF-8 without BOM and synthetic.
- Record schema/configuration versions, changed JSON paths, error codes, fixture IDs and commands/results.

## Definition of Done

- Schema version and compatibility classification are approved and consistent.
- Root/local schemas, Runtime JSON Contract and logical contracts are synchronized.
- Semantic validation and stable error-code documentation are updated.
- Valid, invalid and boundary fixtures cover all changed behavior.
- Independent validation and unit tests pass.
- Exporter/loader compatibility actions are implemented or explicitly tracked.
- Documentation, indexes and change history are synchronized.
- No unresolved stop condition remains.
