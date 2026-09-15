# Tests

This folder contains controlled automated and scenario testing for schemas, operational skills, workbook/VBA source, scripts, engine modules, runtime configuration and report templates.

## Available tests

- `schema/` — Runtime JSON Schema 1.0.0, manifest, semantic and encoding tests.
- `skills/` — operational skill catalogue and contract tests.
- `vba/` — synthetic workbook generation, table/fixture semantics, deterministic golden hash and VBA source-contract tests.
- `workbook/` — Mapping Workbook MVP contract, baseline, fields/evidence, value lists, regulatory profiles, identification model, dependency closure, Runtime JSON determinism and maintenance tests, plus requirement-contract synchronisation.

Run:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
python build/validate_xlsm_vba_poc.py
python -m unittest discover -s tests/vba -p "test_*.py" -v

python -m pip install -r build/requirements-mvp-workbook.txt
python build/validate_emas_mapping_workbook.py
python -m unittest discover -s tests/workbook -p "test_*.py" -v
```

Native Excel/VBA execution is separately performed with `build/Test-eMASMappingPoc.ps1`; GitHub-hosted Linux CI does not provide supported desktop Excel.

## Planned areas

- `unit/` — isolated PowerShell module and function behavior;
- `integration/` — complete phase execution with controlled inputs;
- `scenarios/` — Pre-Sales, Pre-Migration and Post-Migration scenarios;
- `fixtures/` — synthetic folder structures, workbooks, JSON and exceptions;
- `expected/` — approved expected results;
- `performance/` — large-repository and responsiveness tests.

Test data must be synthetic or specifically approved for repository use. Real customer content must never be committed.
