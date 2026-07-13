# Tests

This folder contains controlled automated and scenario testing for scripts, engine modules, runtime configuration and report templates.

## Available tests

- `schema/` — Runtime JSON Schema 1.0.0, fixture-manifest, semantic-validation and UTF-8 encoding tests.

Run:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
```

## Planned areas

- `unit/` — isolated module and function behavior;
- `integration/` — complete phase execution with controlled inputs;
- `scenarios/` — pre-sales, pre-migration and post-migration business scenarios;
- `fixtures/` — synthetic folder structures, workbooks, JSON and exceptions;
- `expected/` — approved expected results;
- `performance/` — large-repository and responsiveness tests.

Test data must be synthetic or specifically approved for repository use. Real customer content must never be committed.
