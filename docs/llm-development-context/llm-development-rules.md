# LLM Development Rules for eMAS

**Status:** Effective mandatory guidance  
**Authority rank:** 7 — subordinate to approved canonical requirements and governance

These rules are mandatory when generating code, configuration, schemas, tests or documentation for eMAS.

## Authority and decision rules

- Use `context-index.yaml` to load task-relevant sources.
- Apply the Authority and Precedence Policy before resolving inconsistencies.
- Cite applicable DecisionIds and requirement IDs.
- Distinguish approved decision, synchronized documentation, implemented behavior, verified behavior and released behavior.
- Stop when a conflict affects regulatory interpretation, JSON compatibility, phase decisions, report meaning or evidence traceability.
- Never infer a new business or regulatory requirement from an example, code comment, generated summary or customer-specific artifact.

## Architecture rules

- The reviewed internal XLSM is the authoring source of truth.
- The validated immutable JSON exported from the approved XLSM is the runtime source of truth.
- The exact JSON version and checksum loaded for a run is the execution source.
- Never suggest PowerShell directly accessing the XLSM workbook.
- PowerShell must not create, repair or reinterpret runtime JSON.
- The same runtime JSON is used by all three phases.
- Keep shared engine logic reusable across phases.
- Keep phase entry scripts focused on orchestration and depth selection.
- Preserve read-only handling of source evidence.

## Phase rules

- Use the controlled phase names: Pre-Sales Assessment, Pre-Migration Readiness and Post-Migration Verification.
- Pre-Sales must remain lightweight and customer-friendly.
- Pre-Migration must produce the reusable baseline for Post-Migration.
- Post-Migration must compare against the approved Phase 2 baseline.
- Use only approved phase result terminology from the controlled terminology catalogue.

## Configuration and rule-model rules

- Business and regulatory rules are maintained through XLSM authoring and validated JSON export.
- Use normalized rule, phase, condition, output, finding, recommendation, conflict and exception entities.
- Do not use editable `IsActive` as the primary lifecycle mechanism.
- Maintain stable identifiers and referential integrity.
- Keep findings separate from recommendations.
- Keep evaluation status separate from RAG.
- Accepted exceptions may change decision treatment but must not erase or rewrite observed findings.
- Apply lower-inclusive and upper-exclusive threshold boundaries unless an approved exception states otherwise.

## Classification and regulatory rules

- Use independent classification dimensions: Region, Authority, TechnicalStandard, RegionalImplementation, ProductDomain, LifecycleContext, ProductClass and ProcedureContext where applicable.
- Do not collapse the normalized dimensions into one authoring `DossierType` field.
- Treat ASMF as ProcedureContext, not TechnicalStandard.
- Treat regional implementations as layers on a technical standard, not mutually exclusive formats.
- Broad groupings such as MENA or LATAM must not be treated as specific regulatory authorities.
- New regulatory content remains Draft until required Regulatory SME approval is recorded.

## Evidence and traceability rules

- Every execution produces a timestamped UTF-8 log and one phase-specific controlled Excel report.
- Record execution ID, engine version, configuration version, schema version, JSON checksum, inputs, checks, findings, warnings and final phase outcome.
- Use approved value-source provenance: Observed, CustomerProvided, Imported, Derived and Assumed.
- `Calculated` is a legacy synonym of `Derived`; `Provided` is not a controlled replacement for `CustomerProvided`.
- `NotAssessed` and `NotApplicable` are evaluation statuses, not provenance and not RAG.
- Describe eMAS as supporting ALCOA+-aligned traceability practices; do not claim that the tool alone establishes validation or compliance.

## Quality rules

- Prefer explicit, auditable logic over clever but opaque code.
- Keep changes minimal, coherent and reviewable.
- Update dependent requirements, schemas, architecture, tests and guidance or track them explicitly.
- Use synthetic or approved Golden Fixtures only.
- Do not publish customer data, internal controlled binaries, credentials, production logs or project evidence in the public repository.
- Production-ready means implemented, tested, logged, evidenced, compatible and release-controlled—not merely documented.
