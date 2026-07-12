# Build and Packaging

This folder contains deterministic build, validation and packaging scripts.

Planned build commands:

- `New-eMASInternalRelease.ps1`
- `New-eMASPreSalesPackage.ps1`
- `Test-eMASReleasePackage.ps1`
- `New-eMASChecksumManifest.ps1`
- `Export-eMASVbaSource.ps1`
- `Import-eMASVbaSource.ps1`

Generated packages belong in local `dist/` and must not be committed. Release notes and manifests belong in `releases/`.
