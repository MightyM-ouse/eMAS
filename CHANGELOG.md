# Changelog

All material changes to eMAS source, configuration contracts, templates and controlled documentation are recorded here.

## Unreleased

### Added

- canonical repository and local-folder structure;
- repository and release architecture diagrams;
- central documentation index;
- human-readable canonical document index;
- machine-readable LLM context and authority index;
- permanent repository decision log;
- approved document-governance and change-control policy;
- superseded-document register;
- CODEOWNERS routing;
- source-control safety rules;
- top-level component scaffolding;
- local repository structure initialization script;
- pull-request traceability template;
- evidence-based decision-register review summary and governance workflow;
- approved 171-item decision baseline;
- authority, precedence and source-of-truth policy;
- controlled terminology catalogue;
- Enterprise Requirements v3.1 effective baseline;
- effective Version 3.0 mapping functional requirements;
- effective Version 3.0 mapping technical requirements;
- effective Version 3.0 logical content catalogue;
- approved runtime JSON contract;
- initial JSON Schema Draft 2020-12 baseline;
- approved normalized rule model;
- Version 1.0 Effective normalized relationship matrix;
- Version 1.0 Effective logical data dictionary;
- configuration-document routing index;
- operational LLM skill framework and skill template;
- historical Version 2 documentation-pack supersession notice.

### Changed

- all AI recommendations in the reviewed decision register are adopted as approved design decisions;
- Enterprise Requirements v3.1 consolidates the approved decision baseline and supersedes v3.0 for implementation use;
- mapping functional, technical and content-catalogue documents are synchronized and promoted to Version 3.0 Effective baselines;
- the canonical and machine-readable indexes route logical-model work through the frozen relationship matrix and data dictionary;
- the entity inventory, primary keys, relationship endpoint pairs, cardinalities, temporal-validity rules and runtime ownership are frozen at Version 1.0;
- field names, logical types, requiredness, controlled link entities and serialization conventions are frozen at Version 1.0;
- dedicated `Field_Operator_Links`, `Field_Phase_Links`, `Metric_Phase_Links` and `Effort_Driver_Phase_Links` replace repeated multi-value fields;
- `Validation_Runs` is defined as the parent execution record for validation results and export evidence;
- polymorphic references now require explicit type discriminators and approved target sets;
- the approved normalized JSON model replaces the earlier flat Enterprise v3.0 example;
- authority policy governs statuses, conflicts, approved changes and source-of-truth terminology;
- repository contribution and pull-request workflows require DecisionIds, authority checks, change-class approvals and delivery-state accuracy;
- phase terminology is standardized as Pre-Sales Assessment, Pre-Migration Readiness and Post-Migration Verification;
- result wording uses `Accepted Exceptions` consistently;
- value-source provenance uses Observed, CustomerProvided, Imported, Derived and Assumed;
- evaluation status, RAG and provenance remain separate;
- findings and recommendations remain separate;
- rule lifecycle uses status, effective dates and supersession instead of editable `IsActive`;
- classification separates technical standard, regional implementation, procedure context and source presentation;
- ASMF is governed as procedure context rather than technical submission format;
- runtime JSON serialization is specified as deterministic, culture-invariant UTF-8 without BOM;
- the superseded-document register includes Enterprise v3.0 and configuration v2.0 revisions.

### Pending implementation and synchronization

- synchronize JSON Schema 1.0.0 and golden/negative fixtures with the frozen relationship and field contracts;
- implement semantic referential-integrity validation in workbook, release validation and PowerShell loader layers;
- update architecture and phase contracts;
- implement the remaining operational skills;
- complete XLSM/VBA and PowerShell/OpenXML proof-of-concept work;
- populate regulatory and migration content under the approved owner/SME workflow;
- complete templates, tests, CI, release manifest, rollback and recall controls;
- close remaining supersession actions after active guidance and implementation references are synchronized;
- enable and verify protected-main repository settings outside source control.

### Security and repository handling

- internal decision workbooks and historical Word binaries remain outside the public repository; sanitized status and supersession records are committed instead;
- customer data, project evidence, credentials, production logs and confidential controlled binaries remain prohibited.

## Release history

No controlled software release has been recorded in this repository yet.
