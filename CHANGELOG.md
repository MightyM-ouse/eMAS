# Changelog

All material changes to eMAS source, configuration contracts, architecture, skills, templates and controlled documentation are recorded here.

## Unreleased

### Added

- Mapping Workbook MVP Implementation Baseline v0.2 (`dist/eMAS_Mapping_Workbook_MVP_v0.2.xlsx`) against CFG-MVP v4.7;
- explicit, source-controlled 28-sheet / 28-table workbook contract with column type metadata, cross-checked against the approved requirement text;
- normalized `08_Regulatory_Profiles` with `tblRegulatoryProfiles` and `tblProfileEvidenceLocators` on one worksheet;
- v4.7 `09_Dossier_Sequence_ID` evidence-interpretation model with two-stage bootstrap and profile-specific identification, candidate acceptance and conflict controls;
- v4.5 `07_Fields_Evidence` semantic dictionary and first-class `22_Value_Lists` code authority with datatype operator, phase, evidence, provenance and identification families;
- maintained-workbook loader that reads Excel Tables by name and never by row position;
- transitive dependency-closure resolver behind `24_Final_Config_Master`, showing inclusions and explained exclusions;
- deterministic XLSX to scenario Runtime JSON transformation with grouped condition rows and nested profile locators;
- sort-safe generated dropdown helper area, type-driven Excel validation across 10 000 maintained rows and prominent staleness banners on the generated views;
- workbook test suite covering contract, baseline, fields, value lists, profiles, identification, closure, JSON determinism and maintenance, plus a requirement-contract synchronisation test and a focused GitHub Actions workflow;
- canonical governance, Enterprise Requirements v3.1 and Effective configuration baselines;
- frozen Normalized Relationship Matrix v1.0 and Logical Data Dictionary v1.0;
- Runtime JSON Schema 1.0.0, synthetic fixture suite and independent semantic validation;
- Effective Solution Architecture and three phase contracts;
- seven Effective operational LLM skills and automated catalogue validation;
- synthetic declarative XLSM/VBA POC source with 43 stable named tables;
- deterministic standard-library XLSX generator;
- nine reviewable VBA modules for validation, deterministic JSON, UTF-8 writing, checksum and export history;
- workbook-model valid, controlled, boundary and negative fixtures;
- independent XLSX table reader/reference exporter and POC semantic validator;
- golden deterministic Runtime JSON SHA-256 and source/workbook checksums;
- Windows/Excel XLSM build and native conformance scripts;
- POC unit tests and focused GitHub Actions workflow;
- XLSM/VBA POC and Conformance Contract v1.0 and focused LLM route.

### Changed

- the Mapping Workbook is now the human-maintained configuration source: template generation, maintained-workbook validation and Runtime JSON transformation are separate responsibilities, and the template generator refuses to overwrite authored content;
- `25_JSON_Field_Map` identifies the exact Excel Table and names the applied transformation instead of describing a worksheet;
- superseded v4.4 field, operator, regulatory-profile and identification columns were removed rather than carried forward, and the affected v0.1 tests were updated to v4.7 with the reason recorded;
- configuration documentation now routes workbook implementation through the POC conformance contract;
- exact Runtime JSON serialization includes `policies` and `questionnaireMap` under Runtime JSON Contract v1.2 and Schema 1.0.0;
- public repository handling separates reviewable synthetic source/VBA from the controlled production XLSM;
- build/test guidance distinguishes automated Linux CI verification from native Windows/Excel qualification;
- delivery-state wording records repository POC/automated conformance as complete without claiming native Excel execution;
- canonical, documentation and LLM indexes include POC assets and the manual qualification gate.

### Pending implementation and qualification

- complete the source-obligation disposition ledger and the Regulatory Profiles review with official ICH and regional-authority sources before any workbook content is treated as approved;
- implement and register engine capabilities so runtime-supported profiles and rules can leave Deferred status;
- execute and review native XLSM/VBA conformance evidence on supported Windows/Excel;
- qualify supported Excel versions, Office bitness and German/English locales;
- implement the complete controlled-workbook validation sequence and production signing;
- implement PowerShell configuration-loader, engine and phase-contract conformance;
- complete the OpenXML report-generation spike and controlled phase templates;
- implement the controlled Pre-Migration baseline format and Post-Migration/MigrationSummary readers;
- populate regulatory/migration content under approved SME workflow;
- complete broader tests, release manifests, rollback/recall controls and Version 2 archive closure.

### Security and repository handling

- internal decision workbooks, controlled production XLSM and historical Word binaries remain outside the public repository;
- customer data, project evidence, credentials, production logs/reports and project-specific exceptions remain prohibited;
- schema, skill and workbook fixtures remain synthetic and non-authoritative for regulatory content.

## Release history

No controlled software release has been recorded in this repository yet.
