# Build and Packaging

This folder contains deterministic repository initialization, build, validation and packaging scripts.

## Available commands

- `Initialize-eMASRepositoryStructure.ps1` — creates or repairs the approved local folder scaffold without overwriting implementation files.
- `validate_emas_schema.py` — independently validates Runtime JSON Schema 1.0.0, fixture expectations and frozen cross-collection semantics.
- `requirements-schema-validation.txt` — pins the build-only Python dependency used by schema validation.

Install and run schema validation from the repository root:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
```

Python and `jsonschema` are build/CI dependencies only. They are not eMAS customer-package or PowerShell runtime dependencies.

## Planned build commands

- `New-eMASInternalRelease.ps1`
- `New-eMASPreSalesPackage.ps1`
- `Test-eMASReleasePackage.ps1`
- `New-eMASChecksumManifest.ps1`
- `Export-eMASVbaSource.ps1`
- `Import-eMASVbaSource.ps1`

Generated packages belong in local `dist/` and must not be committed. Release notes and manifests belong in `releases/`.

The validator is split into `validate_emas_schema.py`, `emas_schema_model.py` and `emas_schema_semantics.py`; all three form one build-time validation component.
