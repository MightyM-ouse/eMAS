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
python -m unittest discover -s tests/reporting -p "test_*.py" -v
```

On a controlled Windows workstation with supported desktop Excel:

```powershell
.\build\Build-eMASMappingPoc.ps1
.\build\Test-eMASMappingPoc.ps1
```

Python and `jsonschema` are build/CI dependencies for schema and report-contract validation. The native XLSM uses VBA to create Runtime JSON. PowerShell orchestrates internal build/test only and does not construct or repair Runtime JSON.

## Report-generation dependency

The current mapping-driven OpenXML report adapter uses Python 3 and the dependency declared in:

```text
build/requirements-reporting.txt
```

Install it with:

```powershell
python -m pip install -r .\build\requirements-reporting.txt
```

This dependency is included in the package instructions and remains subject to supported-environment qualification.

## Implemented package commands

### Customer Pre-Sales package

```powershell
.\build\New-eMASPreSalesPackage.ps1 `
    -RuntimeConfigurationPath C:\Controlled\eMAS_Runtime_Config.json `
    -DestinationRoot .\dist\eMAS-PreSales-Customer `
    -PackageVersion 3.2.0 `
    -SourceCommit <commit-sha> `
    -CreateArchive `
    -Force
```

This creates a restricted customer package containing only the Pre-Sales entry point, required shared runtime/report modules, controlled Pre-Sales template and contracts, one supplied immutable Runtime JSON, instructions and integrity tooling.

### Internal three-phase package

```powershell
.\build\New-eMASInternalRelease.ps1 `
    -RuntimeConfigurationPath C:\Controlled\eMAS_Runtime_Config.json `
    -DestinationRoot .\dist\eMAS-Internal-Release `
    -PackageVersion 3.2.0 `
    -SourceCommit <commit-sha> `
    -CreateArchive `
    -Force
```

This creates an internal package containing all three phase entry points, shared engine, controlled templates, maps, result schemas, selected governing requirements/contracts, the supplied immutable Runtime JSON and integrity tooling.

### Manifest and independent validation

```powershell
.\build\New-eMASChecksumManifest.ps1 `
    -RootPath .\dist\eMAS-Internal-Release `
    -PackageType InternalRelease `
    -PackageVersion 3.2.0

.\build\Test-eMASReleasePackage.ps1 `
    -RootPath .\dist\eMAS-Internal-Release `
    -ExpectedPackageType InternalRelease
```

The manifest contains sorted relative paths, file sizes and SHA-256 values. The validator rejects missing, altered, duplicate, unmanifested, unsafe or prohibited files and enforces package-type-specific minimum contents.

Package-contract CI is maintained in `.github/workflows/release-package-contracts.yml` and builds both packages using synthetic repository fixtures.

## Remaining release gates

Generated workbooks, evidence and packages belong in local `output/` or `dist/` and must not be committed. Release notes and manifests approved for a release belong in `releases/`.

The package builders do not establish:

- supported Windows/Office qualification;
- native Excel execution qualification;
- code signing or certificate trust;
- approved production Runtime JSON content;
- customer acceptance;
- formal release authorization.

`Export-eMASVbaSource.ps1` and `Import-eMASVbaSource.ps1` remain planned maintenance utilities for native workbook source control.
