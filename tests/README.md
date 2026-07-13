# Tests

This folder contains controlled automated and scenario testing for schemas, operational skills, workbook/VBA source, scripts, engine modules, runtime configuration and report templates.

## Available tests

- `schema/` — Runtime JSON Schema 1.0.0, manifest, semantic and encoding tests.
- `runtime/` — PowerShell runtime profile, configuration-loader, runtime-adapter and phase-bootstrap contract tests. `Test-eMASRuntimeConfiguration.ps1` is dependency-free because the repository does not currently use Pester.
- `fixtures/runtime-config/` — synthetic provisional compatibility fixtures for Runtime JSON consumption tests; these are not the final Runtime JSON template or production rule content.
- `skills/` — operational skill catalogue and contract tests.
- `vba/` — synthetic workbook generation, table/fixture semantics, deterministic golden hash and VBA source-contract tests.
- `reporting/` — mapping-driven XLSX generation, write-mode, negative-contract and OpenXML preservation tests.

Run:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
python -m unittest discover -s tests/runtime -p "test_*.py" -v
pwsh -NoProfile -File tests/runtime/Test-eMASRuntimeConfiguration.ps1
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
python build/validate_xlsm_vba_poc.py
python -m unittest discover -s tests/vba -p "test_*.py" -v
python build/validate_report_mappings.py
python -m unittest discover -s tests/reporting -p "test_*.py" -v
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
