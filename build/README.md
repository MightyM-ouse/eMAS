# Build and Packaging

This folder contains deterministic repository initialization, build, validation and packaging scripts.

## Available validation commands

- `validate_emas_schema.py` — Runtime JSON Schema 1.0.0 and semantic fixture validation.
- `validate_operational_skills.py` — Effective operational-skill contract validation.
- `generate_emas_mapping_poc_workbook.py` — standard-library deterministic XLSX generation from the synthetic workbook definition.
- `validate_xlsm_vba_poc.py` — workbook source, VBA contract, fixture, checksum and Schema 1.0.0 conformance validation.
- `Build-eMASMappingPoc.ps1` — internal Windows/Excel build that imports reviewed VBA and saves the POC XLSM.
- `Test-eMASMappingPoc.ps1` — native Excel/VBA deterministic-export and schema-conformance evidence.

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
