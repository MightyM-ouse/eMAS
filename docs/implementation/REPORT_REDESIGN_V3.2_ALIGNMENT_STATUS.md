# eMAS Report Redesign v3.2 Alignment and Implementation Status

**Branch:** `requirements/report-redesign-v3.2`  
**Status:** Approved report contracts aligned; generic report-generation and package-integrity slices implemented and validated; phase evidence processing and release qualification pending  
**Date:** 2026-07-14

## Aligned requirements and controlled artifacts

- Enterprise Requirements v3.2.
- Pre-Sales, Pre-Migration and Post-Migration report requirements v1.1.
- All three phase contracts v1.2.
- Controlled template version `1.2.0`.
- Report-template map version `2.0.0`.
- Normalized result-contract version `1.0.0`.
- Exact workbook structures: Pre-Sales 4 sheets, Pre-Migration 11 sheets, Post-Migration 15 sheets.

Canonical artifacts are maintained under:

```text
templates/controlled/
config/report-mappings/
config/result-schemas/report-redesign-v3.2/
```

The reproducible workbook and mapping generator is:

```text
tools/report-redesign-v3.2/Generate-eMASReportArtifactsV32.py
```

## Implemented generic report-generation slice

The repository now supports a phase-neutral executable path from a validated immutable Runtime JSON and normalized phase-result JSON to a controlled XLSX report and separate timestamped UTF-8 execution log.

Implemented components:

```text
engine/reporting/eMAS.ReportPopulation.psm1
engine/reporting/emas_report_openxml.py
engine/reporting/emas_report_openxml_v32.py
scripts/private/Invoke-eMASPhaseReport.ps1
scripts/eMAS-PreSalesAssessment.ps1
scripts/eMAS-PreMigrationReadiness.ps1
scripts/eMAS-PostMigrationVerification.ps1
```

The implementation:

- validates Runtime JSON before report processing;
- validates normalized results against the mapping-declared phase schema;
- enforces map, template and result-contract compatibility;
- derives technical binding identity from the map and workbook control metadata;
- preserves source templates and protected OpenXML structures;
- reports progress, output paths, versions, row counts and hashes;
- retains initialization-only compatibility when no normalized result is supplied.

This executable slice begins after phase-specific discovery and interpretation have produced the normalized result object.

## Implemented automated verification

Coverage includes:

- exact 4/11/15 workbook sheet order;
- mapping, result-schema and version compatibility;
- all three report-generation paths;
- invalid phase, missing required data and unsupported-version failures;
- template immutability and SHA-256 identity;
- OpenXML integrity and preservation of protected structures and raw headers;
- Windows PowerShell 5.1, Windows PowerShell 7.6 and macOS PowerShell 7.6 runtime contracts;
- end-to-end execution of all three phase entry scripts with deterministic synthetic fixtures.

Green workflows:

```text
.github/workflows/materialize-report-redesign-v3.2.yml
.github/workflows/powershell-runtime-contracts.yml
.github/workflows/end-to-end-report-slice-v3.2.yml
```

## Implemented package-integrity slice

Implemented commands:

```text
build/New-eMASChecksumManifest.ps1
build/Test-eMASReleasePackage.ps1
build/New-eMASPreSalesPackage.ps1
build/New-eMASInternalRelease.ps1
```

The package implementation provides:

- separate restricted customer Pre-Sales and internal three-phase structures;
- one supplied immutable Runtime JSON copied without reinterpretation;
- sorted manifests with relative paths, file sizes and SHA-256 values;
- detection of missing, altered, duplicate, unsafe, prohibited and unmanifested files;
- optional ZIP creation;
- generated instructions and explicit release boundaries;
- Windows PowerShell 5.1 customer-package and PowerShell 7.6 internal-package validation.

Green workflow:

```text
.github/workflows/release-package-contracts.yml
```

## Remaining controlled work

The following cannot be represented as complete by the generic reporting and packaging slices:

1. approval and validation of complete shared Runtime JSON content, including SME-owned rules, thresholds, recommendations and exception policies;
2. complete Pre-Sales customer collection, evidence discovery and EXTEDO internal estimation logic;
3. complete Pre-Migration discovery, readiness evaluation, finding generation and attributable baseline serialization;
4. complete Post-Migration import-report, database and post-import evidence readers and reconciliation logic;
5. production database-extract profiles for supported application and database versions;
6. Windows, NTFS, UNC, performance, large-volume, Office/OpenXML and locale qualification;
7. Microsoft Excel review, signing, controlled release approval and customer acceptance.

These remaining items require approved configuration content, representative controlled evidence, supported environments, SME decisions or formal validation evidence. They must not be inferred or fabricated by repository tooling.
