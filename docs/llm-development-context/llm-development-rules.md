# LLM Development Rules for eMAS

**Version:** 2.0  
**Status:** Effective mandatory guidance  
**Authority rank:** 7 — subordinate to approved canonical requirements, governance, configuration contracts, schemas and architecture

These rules are mandatory when generating code, configuration, schemas, tests, templates or documentation for eMAS.

## Authority and decision rules

- Use `context-index.yaml` to load task-relevant sources.
- Apply the Authority and Precedence Policy before resolving inconsistencies.
- Cite applicable DecisionIds and requirement IDs.
- Distinguish approved, synchronized, implemented, verified and released states.
- Stop when a conflict affects regulatory interpretation, JSON compatibility, the logical model, a phase contract, baseline compatibility, report meaning or evidence traceability.
- Never infer a new business or regulatory requirement from an example, fixture, code comment, generated summary or customer artifact.

## Architecture rules

- Reviewed internal XLSM = authoring source.
- Validated immutable exported JSON = runtime source.
- Exact JSON version/checksum loaded for a run = execution source.
- PowerShell must not read the XLSM or create, repair or reinterpret runtime JSON.
- All phases use the same runtime JSON and shared engine.
- Phase entry scripts own orchestration and follow the applicable Effective phase contract.
- Shared technical behavior belongs in `engine/`.
- WPF is limited to Pre-/Post-Migration, invokes the same scripts and contains no independent rules.
- Source evidence remains read-only.
- Python schema validation remains build/CI-only.
- XLSX report generation must be OpenXML-compatible and must not require Excel on the execution host.

## Phase rules

- Use only: Pre-Sales Assessment, Pre-Migration Readiness and Post-Migration Verification.
- Pre-Sales remains lightweight, CLI/simple-launcher based and customer-friendly; no readiness result or WPF.
- Pre-Sales raw score remains internal by default; raw inventory is optional; a customer-clarification register is required.
- Pre-Migration produces the approved reusable comparison baseline.
- Post-Migration always uses the approved baseline and agreed `MigrationSummary.xlsx` detail.
- Use only controlled phase-result terminology.
- Accepted exceptions never erase original findings, RAG, discrepancies or evidence.

## Configuration and rule-model rules

- Business/regulatory interpretation is authored in XLSM and exported as validated JSON.
- Use normalized rule, phase, condition-group, condition, output, finding, recommendation, relationship, conflict and exception entities.
- Do not use editable `IsActive` as the primary lifecycle control.
- Maintain stable identifiers, explicit relationships and referential integrity.
- Keep findings separate from recommendations.
- Keep `EvaluationStatus`, `RAG`, `ValueSource`, `Confidence` and `ReviewRequired` separate.
- Apply lower-inclusive/upper-exclusive threshold boundaries unless an approved controlled exception states otherwise.

## Classification and regulatory rules

- Keep Region, Authority, TechnicalStandard, RegionalImplementation, ProductDomain, LifecycleContext, ProductClass, ProcedureContext and SourcePresentation independent.
- Do not collapse dimensions into one authoring `DossierType`.
- ASMF is ProcedureContext, not TechnicalStandard.
- Regional implementations layer on technical standards.
- MENA/LATAM-like groupings are not regulatory authorities.
- New regulatory content remains Draft until required SME evidence is recorded.

## Reporting and evidence rules

- Every run produces one controlled phase-specific XLSX report and one timestamped log.
- Record run ID, phase, engine/configuration/schema/template versions, JSON checksum, sanitized inputs, evidence, findings, warnings and final state.
- Controlled templates contain no customer/sample data.
- Include assumptions, limitations, intended use and non-validation wording.
- Generated customer-facing filenames exclude version numbers and internal Confluence identifiers unless a controlled naming contract explicitly requires otherwise.
- Use provenance codes Observed, CustomerProvided, Imported, Derived and Assumed.
- Missing evidence is not Green/Pass.
- Describe eMAS as supporting ALCOA+-aligned traceability; do not claim the tool alone establishes validation/compliance.

## Quality rules

- Prefer explicit, auditable logic.
- Keep changes coherent and reviewable.
- Update affected requirements, schemas, architecture, phase contracts, tests, templates and guidance together.
- Use synthetic or approved Golden Fixtures only.
- Do not publish customer data, internal controlled binaries, credentials, production logs or project evidence.
- Production-ready means implemented, tested, logged, evidenced, compatible and release-controlled—not merely documented.
