# Runtime Schema Tests

This folder contains independent tests for Runtime JSON Schema 1.0.0 and 1.1.0 and the synthetic fixture suite.

Run from the repository root:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
```

The tests verify:

- fixture-manifest expectations;
- stable expected error codes;
- schema version declaration;
- UTF-8 encoding without BOM;
- JSON parsing of every fixture;
- Schema 1.1.0 version dispatch: 1.1.0 properties rejected as 1.0.0 by JSON Schema alone, unsupported versions rejected;
- Identification guards: dimension-scoped candidate resolution, controlled references, evidence-strength ceiling, ordinal order and no numeric Identification weights;
- loader-contract and validator agreement on supported versions.

The fixtures are synthetic and must not contain customer or production data.
