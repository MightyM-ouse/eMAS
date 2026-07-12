# eMAS Repository Structure

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Repository and Source-Control Structure  
**Version:** 1.0  
**Status:** Approved Structure Baseline  
**Date:** 12 July 2026  
**Classification:** Internal design documentation

## 1. Purpose

This document defines the canonical GitHub and local-folder structure for eMAS.

The repository is the controlled source and build repository. It is not the customer delivery package and it is not the project evidence archive. Source code, configuration-authoring assets, schemas, controlled templates, tests, documentation and packaging logic are maintained separately so that each item can be reviewed and versioned independently.

## 2. Repository principles

1. `scripts/` contains phase entry points and orchestration only.
2. `engine/` contains reusable PowerShell processing shared by all phases.
3. `config/authoring/` contains the internal XLSM configuration workbook.
4. `config/runtime/controlled/` contains the reviewed JSON exported directly from Excel.
5. PowerShell must not read the XLSM workbook and must not create the runtime JSON.
6. `templates/controlled/` contains one separate report template for each phase.
7. `ui/` is limited to optional pre-migration and post-migration WPF interfaces.
8. `tests/fixtures/` must contain synthetic or approved test data only.
9. `output/`, `logs/` and `dist/` are generated locations and are not source-controlled.
10. Customer data, project evidence and credentials must never be committed.

## 3. Canonical structure

```text
eMAS/
│
├── .github/
│   ├── workflows/
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
│
├── scripts/
│   ├── eMAS-PreSalesAssessment.ps1
│   ├── eMAS-PreMigrationReadiness.ps1
│   ├── eMAS-PostMigrationVerification.ps1
│   ├── launchers/
│   │   └── Start-eMAS-PreSales.cmd
│   └── README.md
│
├── engine/
│   ├── eMAS.Configuration.psm1
│   ├── eMAS.Discovery.psm1
│   ├── eMAS.Classification.psm1
│   ├── eMAS.Validation.psm1
│   ├── eMAS.Effort.psm1
│   ├── eMAS.Readiness.psm1
│   ├── eMAS.Reconciliation.psm1
│   ├── eMAS.Reporting.psm1
│   ├── eMAS.OpenXml.psm1
│   ├── eMAS.Logging.psm1
│   ├── eMAS.Utilities.psm1
│   ├── eMAS.Engine.psd1
│   └── README.md
│
├── config/
│   ├── authoring/
│   │   ├── eMAS_Mapping_Configuration.xlsm
│   │   └── README.md
│   ├── vba/
│   │   ├── modules/
│   │   ├── classes/
│   │   ├── forms/
│   │   └── README.md
│   ├── schema/
│   │   ├── eMAS_Runtime_Config.schema.json
│   │   ├── eMAS_Execution_Result.schema.json
│   │   └── eMAS_Schema_Compatibility.json
│   ├── runtime/
│   │   ├── controlled/
│   │   │   └── eMAS_Runtime_Config.json
│   │   └── development/
│   │       └── .gitkeep
│   ├── samples/
│   │   └── eMAS_Runtime_Config.sample.json
│   └── README.md
│
├── templates/
│   ├── controlled/
│   │   ├── pre-sales/
│   │   │   └── eMAS_PreSales_Template.xlsx
│   │   ├── pre-migration/
│   │   │   └── eMAS_PreMigration_Template.xlsx
│   │   └── post-migration/
│   │       └── eMAS_PostMigration_Template.xlsx
│   ├── branding/
│   ├── manifest/
│   │   └── eMAS_Template_Manifest.json
│   ├── samples/
│   └── README.md
│
├── ui/
│   ├── pre-migration/
│   ├── post-migration/
│   ├── shared/
│   └── README.md
│
├── docs/
│   ├── index.md
│   ├── requirements/
│   ├── architecture/
│   │   └── decisions/
│   ├── configuration/
│   ├── repository/
│   ├── reporting/
│   ├── development/
│   ├── testing/
│   ├── validation/
│   ├── operations/
│   ├── governance/
│   ├── releases/
│   └── llm-development-context/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── scenarios/
│   │   ├── pre-sales/
│   │   ├── pre-migration/
│   │   └── post-migration/
│   ├── fixtures/
│   │   ├── folder-structures/
│   │   ├── workbooks/
│   │   ├── runtime-config/
│   │   └── accepted-exceptions/
│   ├── expected/
│   ├── performance/
│   ├── Invoke-eMASTests.ps1
│   └── README.md
│
├── build/
│   ├── New-eMASInternalRelease.ps1
│   ├── New-eMASPreSalesPackage.ps1
│   ├── Test-eMASReleasePackage.ps1
│   ├── New-eMASChecksumManifest.ps1
│   ├── Export-eMASVbaSource.ps1
│   ├── Import-eMASVbaSource.ps1
│   ├── package-manifest.json
│   └── README.md
│
├── releases/
│   ├── release-notes/
│   ├── known-limitations/
│   ├── manifests/
│   └── README.md
│
├── output/
│   └── .gitkeep
├── logs/
│   └── .gitkeep
├── dist/
│   └── .gitkeep
│
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── VERSION
├── .gitignore
├── .gitattributes
├── .editorconfig
└── PSScriptAnalyzerSettings.psd1
```

The tree represents the target structure. A folder appears in GitHub only after it contains a tracked file; therefore, placeholder `README.md` or `.gitkeep` files may be used until implementation files are added.

## 4. Folder responsibilities

| Folder | Responsibility | Must not contain |
|---|---|---|
| `.github/` | Pull-request templates, issue templates and controlled CI workflows | Runtime business rules or customer data |
| `scripts/` | User-facing phase entry scripts and lightweight launchers | Duplicated shared engine logic |
| `engine/` | Reusable technical processing modules | Phase-specific report wording embedded across multiple modules |
| `config/authoring/` | Internal XLSM rule-authoring application | Customer project exceptions or customer evidence |
| `config/vba/` | Exported `.bas`, `.cls` and `.frm` source for review | Unreviewable binary-only VBA changes |
| `config/schema/` | Runtime JSON and compatibility schemas | Generated customer outputs |
| `config/runtime/controlled/` | Reviewed runtime JSON released with eMAS | Manually edited JSON |
| `config/runtime/development/` | Temporary DEV exports | Approved production configuration |
| `templates/controlled/` | Versioned phase-specific Excel templates | Customer-populated reports |
| `templates/samples/` | Synthetic examples for documentation and tests | Real customer data |
| `ui/` | Optional parameter collection and execution interface | Independent assessment or business logic |
| `docs/` | Requirements, architecture, configuration, development, test and operating documentation | Generated logs or customer evidence |
| `tests/` | Unit, integration, scenario, regression and performance tests | Production customer datasets |
| `build/` | Deterministic packaging, validation and checksum generation | Hand-maintained release binaries |
| `releases/` | Release notes, known limitations and manifests | Full generated release packages |
| `output/`, `logs/`, `dist/` | Local generated content | Committed execution evidence |

## 5. Source repository versus delivery packages

### 5.1 Internal controlled release

```text
eMAS_<Version>/
├── scripts/
├── engine/
├── config/
│   └── eMAS_Runtime_Config.json
├── templates/
├── ui/
├── docs/
├── RELEASE_NOTES.md
├── KNOWN_LIMITATIONS.md
└── checksums.sha256
```

The internal package may contain all three phases and the optional WPF interfaces. It must not contain the configuration-authoring workbook unless the package is specifically intended for authorized configuration administrators.

### 5.2 Customer pre-sales package

```text
eMAS_PreSales_Package_<Version>/
├── eMAS-PreSalesAssessment.ps1
├── engine/
├── eMAS_Runtime_Config.json
├── eMAS_PreSales_Template.xlsx
├── Start-eMAS-PreSales.cmd
├── Instructions.pdf
└── Output/
```

The customer package is generated by the build process. It must remain lightweight and must not contain:

- the internal mapping workbook;
- VBA authoring source;
- pre-migration or post-migration interfaces;
- internal test fixtures;
- internal governance or development documentation.

## 6. Version and traceability expectations

Every controlled release must identify:

- eMAS release version;
- PowerShell script and engine version;
- runtime JSON configuration ID and version;
- JSON schema version;
- report template version;
- build timestamp;
- source commit or tag;
- checksum manifest;
- release notes and known limitations.

## 7. Branch and review model

Changes should be developed on a dedicated branch and reviewed through a pull request before merging to `main`.

Recommended branch prefixes:

- `feature/`
- `fix/`
- `docs/`
- `config/`
- `test/`
- `release/`

Binary workbook changes should be accompanied by exported VBA source and a clear change summary so that reviewers can inspect the implementation rather than relying only on the binary diff.

## 8. Confidentiality boundary

The repository must not contain real customer export folders, migration evidence, credentials, production logs, customer reports or project-specific accepted exceptions.

Because configuration-authoring assets and controlled business rules are internal, they must only be committed to a repository with an approved access classification. Public repositories may contain architecture and sample documentation, but not the production mapping workbook, production runtime JSON, official internal templates or confidential branding assets.
