# Changelog

All material changes to eMAS source, configuration contracts, templates and controlled documentation are recorded here.

## Unreleased

### Added

- canonical repository and local-folder structure;
- repository and release architecture diagrams;
- central and canonical documentation indexes;
- machine-readable LLM context and authority index;
- permanent repository decision log and approved 171-item decision baseline;
- authority, precedence, source-of-truth and controlled-terminology policies;
- Enterprise Requirements v3.1 and Effective configuration requirements;
- Runtime JSON Contract, Normalized Rule Model, Relationship Matrix and Logical Data Dictionary;
- effective Runtime JSON Schema 1.0.0 synchronized to the frozen logical model;
- Schema Validation and Fixture Contract v1.0;
- synthetic valid, controlled, boundary and invalid JSON fixtures;
- fixture manifest with expected validity and stable semantic error codes;
- independent Python Draft 2020-12 and semantic validator;
- automated schema unit tests and focused GitHub Actions workflow;
- operational LLM skill framework and historical Version 2 supersession records.

### Changed

- all approved AI recommendations are consolidated into current requirements and controlled contracts;
- runtime JSON now explicitly serializes `policies` and `questionnaireMap` in addition to the previously approved normalized collections;
- report terminology has a controlled definitions and phase-results structure;
- CONTROLLED export metadata now has explicit approval, release-manifest and checksum-scope requirements;
- schema validation rejects unknown properties and enforces operator-specific values;
- semantic validation now verifies identity, references, endpoint pairs, rule completeness, output targets, exceptions, aliases, thresholds, decisions and questionnaire triggers;
- valid and boundary fixtures must produce no issue, while invalid fixtures must fail for the expected stable code;
- Python schema tooling is explicitly build/CI-only and is not a PowerShell runtime dependency;
- canonical and machine-readable indexes route schema work through the Effective verification contract.

### Pending implementation and synchronization

- update architecture and phase contracts;
- implement the remaining operational skills;
- implement XLSM/VBA export and validation conformance against the schema fixtures;
- implement PowerShell loader conformance against the schema and semantic fixtures;
- complete the PowerShell/OpenXML report-generation spike and engine contracts;
- populate regulatory and migration content under the approved owner/SME workflow;
- complete report templates, broader scenario/performance tests, release manifest, rollback and recall controls;
- close remaining Version 2 supersession actions;
- enable and verify protected-main repository settings outside source control.

### Security and repository handling

- internal decision workbooks and historical Word binaries remain outside the public repository;
- all schema fixtures are synthetic;
- customer data, project evidence, credentials, production logs and confidential controlled binaries remain prohibited.

## Release history

No controlled software release has been recorded in this repository yet.
