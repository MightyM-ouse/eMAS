# Build and Packaging

This folder contains deterministic repository initialization, build, validation and packaging scripts.

## Available commands

- `Initialize-eMASRepositoryStructure.ps1` — creates or repairs the approved local folder scaffold without overwriting implementation files.
- `validate_emas_schema.py` — independently validates Runtime JSON Schema 1.0.0, fixture expectations and frozen cross-collection semantics.
- `emas_schema_model.py` and `emas_schema_semantics.py` — schema validation model and semantic checks.
- `requirements-schema-validation.txt` — pins the build-only Python dependency used by schema validation.
- `validate_operational_skills.py` — validates the Effective skill catalogue, metadata, required sections, procedure/evidence minimums and canonical-source paths.

Run schema validation from the repository root:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_emas_schema.py
python -m unittest discover -s tests/schema -p "test_*.py" -v
```

Run operational-skill validation:

```bash
python build/validate_operational_skills.py
python -m unittest discover -s tests/skills -p "test_*.py" -v
```

Python and `jsonschema` are build/CI dependencies only. They are not eMAS customer-package or PowerShell runtime dependencies. Operational-skill validation uses only the Python standard library.

## Planned build commands

- `New-eMASInternalRelease.ps1`
- `New-eMASPreSalesPackage.ps1`
- `Test-eMASReleasePackage.ps1`
- `New-eMASChecksumManifest.ps1`
- `Export-eMASVbaSource.ps1`
- `Import-eMASVbaSource.ps1`

Generated packages belong in local `dist/` and must not be committed. Release notes and manifests belong in `releases/`.
