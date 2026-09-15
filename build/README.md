# Build and Packaging

This folder contains deterministic repository initialization, build, validation and packaging scripts.

## Available validation commands

- `validate_emas_schema.py` — Runtime JSON Schema 1.0.0 and semantic fixture validation.
- `validate_operational_skills.py` — Effective operational-skill contract validation.
- `generate_emas_mapping_poc_workbook.py` — standard-library deterministic XLSX generation from the synthetic workbook definition.
- `validate_xlsm_vba_poc.py` — workbook source, VBA contract, fixture, checksum and Schema 1.0.0 conformance validation.
- `Build-eMASMappingPoc.ps1` — internal Windows/Excel build that imports reviewed VBA and saves the POC XLSM.
- `Test-eMASMappingPoc.ps1` — native Excel/VBA deterministic-export and schema-conformance evidence.
- `generate_emas_mapping_workbook.py` — CFG-MVP v4.7 macro-free 28-sheet workbook **template** generator.
- `validate_emas_mapping_workbook.py` — saved-XLSX structure, contents, references and native-feature inspection.
- `emas_mvp_loader.py` — loads and validates an existing **maintained** workbook without regenerating it.
- `emas_mvp_transform.py` — deterministic maintained-workbook to scenario Runtime JSON transformation.
- `emas_mvp_json_map.py` — generates and loads the maintained `25_JSON_Field_Map` contract.

## Mapping Workbook MVP v0.2

The workbook MVP is separate from the older synthetic XLSM/VBA POC. Its
requirement baseline is CFG-MVP v4.7 in
`docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`.

Responsibilities are separated so the workbook can become the human-maintained
configuration source:

| Step | Script | Purpose |
|---|---|---|
| A | `generate_emas_mapping_workbook.py` | Bootstrap/template generation only |
| B | `emas_mvp_loader.py` | Load and validate an existing maintained workbook |
| C | `emas_mvp_transform.py` | Deterministic Workbook → scenario Runtime JSON |

The column contract lives in `emas_mvp_contract.py` and is cross-checked against
the approved requirement by `tests/workbook/test_requirement_contract_sync.py`,
so requirement drift is reported instead of silently absorbed.

Install the build-only dependency:

```bash
python -m pip install -r build/requirements-mvp-workbook.txt
```

Rebuild the template and inspect the saved file:

```bash
python build/emas_mvp_json_map.py --write
python build/generate_emas_mapping_workbook.py --force
python build/validate_emas_mapping_workbook.py
```

The output is `dist/eMAS_Mapping_Workbook_MVP_v0.2.xlsx`. `--scenario MS-04`
rebuilds the Final Config Master and JSON Preview for another scenario.
**The generator refuses to overwrite an existing workbook unless `--force` is
supplied**, so SME-authored content is never silently deleted. Changing
`00_Home!D5` in Excel marks the generated views `STALE — REGENERATION REQUIRED`.

Work with a maintained workbook:

```bash
python build/emas_mvp_loader.py dist/eMAS_Mapping_Workbook_MVP_v0.2.xlsx
python build/emas_mvp_transform.py --workbook dist/eMAS_Mapping_Workbook_MVP_v0.2.xlsx
python -m unittest discover -s tests/workbook -p "test_*.py" -v
```

The workbook is **MVP Implementation Baseline v0.2 — Draft for workbook content
review**. Two blocking validation results remain by design: the source-obligation
disposition ledger is incomplete, and no regulatory profile is source-verified
and parser-supported for runtime use. No eligible Runtime JSON is therefore
produced; the transformer writes only a clearly labelled blocked candidate.

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
