# Runtime Schema Tests

This folder contains independent tests for Runtime JSON Schema 1.0.0 and its synthetic fixture suite.

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
- JSON parsing of every fixture.

The fixtures are synthetic and must not contain customer or production data.
