# Build and Packaging

This folder contains deterministic repository initialization, build, validation and packaging scripts.

## Available validation commands

- `validate_emas_schema.py` — Runtime JSON Schema 1.0.0 and semantic fixture validation.
- `validate_operational_skills.py` — Effective operational-skill contract validation.
- `generate_emas_mapping_poc_workbook.py` — standard-library deterministic XLSX generation from the synthetic workbook definition.
- `validate_xlsm_vba_poc.py` — workbook source, VBA contract, fixture, checksum and Schema 1.0.0 conformance validation.
- `Build-eMASMappingPoc.ps1` — internal Windows/Excel build that imports reviewed VBA and saves the POC XLSM.
- `Test-eMASMappingPoc.ps1` — native Excel/VBA deterministic-export and schema-conformance evidence.
- `generate_emas_mapping_workbook.py` — v4.4 MVP, macro-free 28-sheet workbook generator.
- `validate_emas_mapping_workbook.py` — saved-XLSX structure, contents, references and native-feature inspection.

## Mapping Workbook MVP v0.1

The v4.4 MVP is separate from the older synthetic XLSM/VBA POC. Its source is
the approved tables in `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`,
normalized in `build/emas_mvp_model.py`, plus the maintained
`config/authoring/mvp/json-field-map.json` transformation map. The generator and validator do not read
customer files, call cloud services, run Excel, or create active Runtime JSON.

Install the build-only dependency in your local Python environment when needed:

```bash
python -m pip install -r build/requirements-mvp-workbook.txt
```

Regenerate the workbook from the repository root with one command:

```bash
python build/generate_emas_mapping_workbook.py
```

The output is `dist/eMAS_Mapping_Workbook_MVP_v0.1.xlsx`. Select a different
review scenario with `--scenario MS-04`; this rebuilds the Final Config Master
and JSON Preview. Changing `00_Home!D5` in Excel marks those generated views
stale until the builder is rerun.

Validate the saved file and run the workbook tests:

```bash
python build/validate_emas_mapping_workbook.py
python -m unittest discover -s tests/workbook -p "test_*.py" -v
```

The workbook is **MVP Implementation Baseline v0.1 — Draft for workbook content
review**. It contains one explicit blocking validation result for incomplete
source-obligation disposition. Later business/rule sheets are structurally ready
but contain no invented active regulatory logic. Therefore no active scenario
Runtime JSON is emitted. The preview reports review counts and lineage only.

Run repository validation:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
python build/validate_xlsm_vba_poc.py
python -m unittest discover -s tests/vba -p "test_*.py" -v
```

On a controlled Windows workstation with supported desktop Excel:

```powershell
.\build\Build-eMASMappingPoc.ps1
.\build\Test-eMASMappingPoc.ps1
```

Python and `jsonschema` are build/CI dependencies only. The native XLSM uses VBA to create runtime JSON. PowerShell orchestrates internal build/test only and does not construct or repair JSON.

## Planned release commands

- `New-eMASInternalRelease.ps1`
- `New-eMASPreSalesPackage.ps1`
- `Test-eMASReleasePackage.ps1`
- `New-eMASChecksumManifest.ps1`
- `Export-eMASVbaSource.ps1`
- `Import-eMASVbaSource.ps1`

Generated workbooks, evidence and packages belong in local `output/` or `dist/` and must not be committed. Release notes and manifests belong in `releases/`.
