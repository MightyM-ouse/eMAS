# Shared PowerShell Engine

This folder contains reusable technical processing modules used by all three eMAS phases.

The approved runtime boundary is:

```text
engine/
├── core/
├── powershell51/
└── powershell7/
```

`core` is the single shared business-engine boundary and remains Windows PowerShell 5.1-compatible. `powershell51` and `powershell7` contain runtime-specific technical adapters only.

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

## Runtime adapter rule

Runtime adapters may optimize technical behavior such as file enumeration, encoding, runtime diagnostics, OpenXML packaging or controlled parallel processing. They must not duplicate classification, rule, finding, recommendation, RAG, effort, readiness or reconciliation interpretation.

## Runtime configuration foundation

The centralized compatibility contract is defined in `core/eMAS.Configuration.Contract.psm1`. It exposes the approved Schema 1.0.0 structural boundary, provisional property-name candidates and controlled `EvaluationStatus` compatibility set, including `Warning`.

`core/eMAS.RuntimeConfiguration.psm1` provides the phase-neutral defensive consumption foundation: safe UTF-8 loading, SHA-256 identity, structural checks, semantic hooks, stable accessors and sanitized configuration log events. It does not read the XLSM, generate or repair JSON, scan source evidence or implement phase decision logic.

Claude's final Runtime JSON design remains authoritative for the final property/section binding. Exact JSON Schema validation, controlled-package checksum verification, complete relationship semantics and native Windows qualification remain separate release work.
