# Shared PowerShell Engine

This folder contains reusable technical processing modules used by all three eMAS phases.

Planned modules:

- configuration/package loading and defensive validation;
- discovery;
- classification and normalization;
- technical validation;
- effort and confidence;
- readiness;
- reconciliation;
- reporting and OpenXML;
- logging;
- common utilities.

The engine conforms to `docs/architecture/eMAS_Solution_Architecture.md` and the applicable phase contract.

The configuration module loads the reviewed immutable runtime JSON, verifies compatibility/integrity and fails fast on configuration errors. It must not read the internal XLSM, generate or repair JSON, or become dependent on the build-only Python schema validator.

Business and regulatory meaning remains configuration-driven. Source evidence remains read-only.
