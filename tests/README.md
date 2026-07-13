# Tests

This folder contains controlled automated and scenario testing for schemas, operational skills, scripts, engine modules, runtime configuration and report templates.

## Available tests

- `schema/` — Runtime JSON Schema 1.0.0, fixture-manifest, semantic-validation and UTF-8 encoding tests.
- `skills/` — operational skill catalogue, front-matter, required-section and UTF-8 JSON tests.

Run:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
```

## Planned areas

- `unit/` — isolated PowerShell module and function behavior;
- `integration/` — complete phase execution with controlled inputs;
- `scenarios/` — Pre-Sales, Pre-Migration and Post-Migration scenarios;
- `fixtures/` — synthetic folder structures, workbooks, JSON and exceptions;
- `expected/` — approved expected results;
- `performance/` — large-repository and responsiveness tests.

Test data must be synthetic or specifically approved for repository use. Real customer content must never be committed.
