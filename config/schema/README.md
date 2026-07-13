# eMAS Runtime Schema

## Effective baseline

`eMAS-runtime-config.schema.json` is the effective eMAS runtime configuration schema at **Schema Version 1.0.0**.

It uses JSON Schema Draft 2020-12 and is synchronized with:

- `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`;
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`;
- `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md`;
- `docs/configuration/07_eMAS_Data_Dictionary.md`;
- `docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md`.

## Files

| Path | Purpose |
|---|---|
| `eMAS-runtime-config.schema.json` | Root machine-readable structural contract |
| `defs/*.schema.json` | Local schema resources distributed with the root as one offline package |
| `examples/fixture-manifest.json` | Expected result and error-code contract for every fixture |
| `examples/base/` | Ordered synthetic base fragments assembled by the validator |
| `examples/valid/` | Synthetic base configuration and valid JSON Merge Patch variants |
| `examples/boundary/` | Valid JSON Merge Patch edge and boundary variants |
| `examples/invalid/` | Deliberately invalid JSON Merge Patch variants |
| `../../build/validate_emas_schema.py` | Independent Draft 2020-12 and semantic validator |
| `../../tests/schema/test_schema_fixtures.py` | Automated fixture tests |

The fixture suite uses one synthetic base assembled from ordered fragments plus compact RFC 7396-style JSON Merge Patch variants. The independent validator materializes each variant before validation. No fixture contains customer data, production mappings or approved regulatory content.

## Validation model

JSON Schema validates:

- required top-level sections;
- property names and data types;
- identifier, version, date, date-time and checksum formats;
- controlled enumerations;
- conditional fields such as controlled-release metadata;
- operator-specific condition value requirements;
- prohibited unknown properties.

The independent semantic validator additionally validates:

- duplicate IDs and composite keys;
- mandatory value-list categories and codes;
- cross-collection references;
- relationship-type endpoint pairs;
- rule, phase, group, condition and output completeness;
- field/operator and field/phase compatibility;
- output-target resolution;
- finding, recommendation, exception and alias references;
- effort-threshold gaps and overlaps;
- decision and questionnaire references;
- temporal ranges and supersession cycles.

A JSON Schema pass alone does not prove semantic or referential integrity.

## Commands

Install the build-only dependency:

```bash
python -m pip install -r build/requirements-schema-validation.txt
```

Validate the schema and complete fixture manifest:

```bash
python build/validate_emas_schema.py
```

Validate one runtime file:

```bash
python build/validate_emas_schema.py --instance path/to/eMAS_Runtime_Config.json
```

Run the unit tests:

```bash
python -m unittest discover -s tests/schema -p "test_*.py" -v
```

Python and `jsonschema` are build/CI validation dependencies only. They are not customer-package or PowerShell runtime dependencies.

## Change control

Any schema change requires:

- DecisionId and requirement traceability;
- compatibility assessment under Semantic Versioning;
- synchronized relationship-matrix and data-dictionary review;
- updated valid, invalid and boundary fixtures;
- updated expected error codes where behavior changes;
- successful independent validation and tests.
