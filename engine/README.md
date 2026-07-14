# Shared PowerShell Engine

This folder contains reusable technical processing modules used by all three eMAS phases.

The approved runtime boundary is:

```text
engine/
├── core/
├── powershell51/
├── powershell7/
└── reporting/
```

`core` is the single shared business-engine boundary and remains Windows PowerShell 5.1-compatible. `powershell51` and `powershell7` contain runtime-specific technical adapters only.

Planned and implemented module areas include:

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

The engine conforms to `docs/architecture/eMAS_Solution_Architecture.md`, Enterprise Requirements v3.2 and the applicable phase contract.

The configuration module loads the reviewed immutable runtime JSON, verifies compatibility/integrity and fails fast on configuration errors. It must not read the internal XLSM, generate or repair JSON, or become dependent on the build-only Python schema validator.

Business and regulatory meaning remains configuration-driven. Source evidence remains read-only.

## Runtime adapter rule

Runtime adapters may optimize technical behavior such as file enumeration, encoding, runtime diagnostics, OpenXML packaging or controlled parallel processing. They must not duplicate classification, rule, finding, recommendation, RAG, effort, readiness or reconciliation interpretation.

## Runtime configuration foundation

The centralized compatibility contract is defined in `core/eMAS.Configuration.Contract.psm1`. It exposes the approved Schema 1.0.0 structural boundary, provisional property-name candidates and controlled `EvaluationStatus` compatibility set, including `Warning`.

`core/eMAS.RuntimeConfiguration.psm1` provides the phase-neutral defensive consumption foundation: safe UTF-8 loading, SHA-256 identity, structural checks, semantic hooks, stable accessors and sanitized configuration log events. It does not read the XLSM, generate or repair JSON, scan source evidence or implement phase decision logic.

The final Runtime JSON design remains authoritative for property and section binding. Exact JSON Schema validation, controlled-package checksum verification, complete relationship semantics and native Windows qualification remain separate release gates.

## Reporting and OpenXML v3.2

`reporting/eMAS.ReportPopulation.psm1` exposes the phase-neutral `Export-eMASResultToTemplate` command.

The command now binds to:

- report-template map version `2.0.0`;
- controlled template version `1.2.0`;
- normalized result-contract version `1.0.0`;
- the phase-specific result schemas under `config/result-schemas/report-redesign-v3.2/`.

`reporting/emas_report_openxml_v32.py` is the v3.2 contract adapter. It validates the normalized result against the mapping-declared result schema before workbook population, verifies mapping/template/control identity, preserves protected workbook structures and invokes the shared OpenXML writer.

The business-result object deliberately does not carry `mappingId`, `templateId` or `templateVersion`. Those technical binding identities are taken from the selected mapping and controlled workbook metadata.

Automated structural coverage is maintained in `tests/reporting/test_report_generation.py`. It validates all three phases, exact 4/11/15 sheet structures, result-schema enforcement, template immutability, raw evidence headers, OpenXML integrity and the PowerShell command surface.

This implementation is suitable for repository-level contract and synthetic fixture testing. Supported Windows, NTFS, UNC and Microsoft Excel qualification, signing and controlled release approval remain mandatory before production release.
