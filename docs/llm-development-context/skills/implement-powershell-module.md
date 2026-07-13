---
SkillId: SKILL-003
Title: Implement or Modify an eMAS PowerShell Module
Version: 1.0.0
Status: Effective
Owner: PowerShell Lead and Technical Architect
DecisionReferences:
  - SK-006
  - FN-001
  - FN-021
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/architecture/eMAS_Solution_Architecture.md
  - docs/architecture/phase-contracts/README.md
  - docs/configuration/04_eMAS_Runtime_JSON_Contract.md
  - docs/configuration/05_eMAS_Normalized_Rule_Model.md
  - docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md
  - config/schema/eMAS-runtime-config.schema.json
AppliesTo:
  - Shared PowerShell engine
  - Phase entry scripts
  - Windows PowerShell 5.1 runtime
Supersedes: null
LastReviewed: 2026-07-13
---

# Implement or Modify an eMAS PowerShell Module

## Invoke when

- Creating or changing a shared engine module for configuration loading, discovery, classification, validation, effort, readiness, reconciliation, reporting, logging or utilities.
- Implementing or modifying a phase entry script that orchestrates shared modules.
- Adding defensive runtime validation, progress reporting, structured result objects or logging behavior.

## Do not invoke when

- Business/regulatory rules or thresholds need to change; modify approved configuration instead.
- The task changes report meaning or workbook contract before code; use `modify-report-contract.md` first.
- The task is only WPF layout/parameter collection and does not change the script interface.

## Required inputs and canonical sources

- Approved requirement, DecisionId or defect with acceptance criteria.
- Effective Solution Architecture and applicable phase contract.
- Runtime JSON Contract, Schema 1.0.0, fixture contract and relevant synthetic fixtures.
- Current module/script interfaces, repository structure and calling code.
- Windows PowerShell 5.1 compatibility constraints.
- Logging, progress, performance, error-handling and security expectations.
- Required unit, integration, scenario and conformance tests.

## Preconditions

- The behavior belongs in technical processing rather than controlled configuration.
- Public function/module ownership and phase applicability are clear.
- Required configuration fields/operators/output types already exist or an approved schema change is complete.
- Test evidence can be created without customer data.
- No unresolved report, baseline or phase-result contract conflict exists.

## Procedure

1. **Resolve authority and layer.** Record requirement/DecisionIds and state why the behavior belongs in PowerShell rather than XLSM/JSON configuration.
2. **Select component ownership.** Place reusable behavior in `engine/`; keep entry scripts limited to parameter validation, run initialization, module selection and orchestration.
3. **Define the interface.** Specify function names, parameters, types, defaults, pipeline behavior, return object shape, errors and logging events before implementation.
4. **Preserve runtime boundaries.** Load only immutable JSON, never read XLSM, never repair/rewrite JSON and never mutate source evidence.
5. **Implement for PowerShell 5.1.** Avoid newer-only cmdlets such as relying on `Test-Json`; avoid internet, Excel installation and unapproved external-module dependencies.
6. **Use explicit execution behavior.** Apply strict error handling, clear parameter validation, deterministic ordering, culture-invariant conversions and bounded resource use.
7. **Return structured data.** Separate observed/derived values, EvaluationStatus, RAG, ValueSource, confidence, ReviewRequired, evidence references and exceptions.
8. **Add progress and logs.** Emit meaningful console progress for long operations and detailed timestamped events without exposing credentials or unnecessary sensitive values.
9. **Implement failure semantics.** Fail fast for configuration/package/template/mandatory-input errors; represent missing optional evidence through configured evaluation status rather than Green.
10. **Preserve phase boundaries.** Invoke only checks permitted by the phase contract and use only approved phase-result terminology.
11. **Add tests.** Cover happy path, invalid configuration, missing mandatory input, optional missing evidence, read-only behavior, deterministic output and phase-specific exclusions.
12. **Run conformance evidence.** Reuse schema fixtures where relevant and add synthetic engine/phase fixtures for the new behavior.
13. **Synchronize documentation.** Update module help, interface contracts, architecture/report/phase documentation and changelog where behavior changes.
14. **Review package impact.** Confirm which modules are included in customer Pre-Sales versus internal Pre-/Post-Migration packages.

## Required outputs

- PowerShell source with comment-based help and defined public interface.
- Structured before/after behavior and affected phase/component summary.
- Unit/integration/conformance tests and synthetic fixtures.
- Console progress, log events and error behavior evidence.
- PowerShell 5.1, offline and no-Excel/no-unapproved-module compatibility evidence.
- Package and documentation impact summary.
- Traceability from requirement/DecisionId to code and tests.

## Stop conditions

Stop when:

- requested business/regulatory interpretation is not present in approved configuration;
- schema/operator/output compatibility is uncertain;
- implementation would require PowerShell to read XLSM or generate/repair JSON;
- source evidence cannot remain read-only;
- a PowerShell 5.1-compatible approach is not established;
- a new external/runtime dependency lacks approval;
- phase result or report meaning would change without an approved contract;
- baseline or MigrationSummary compatibility is unresolved;
- acceptance criteria or test evidence are missing.

## Validation and evidence

- Run parser/static checks appropriate to PowerShell 5.1 and repository standards.
- Run unit and integration tests with synthetic data.
- Verify source hashes/timestamps or equivalent evidence remain unchanged in read-only tests.
- Verify deterministic result ordering and culture-invariant output.
- Verify logs contain run/configuration/schema/template versions and JSON checksum.
- Verify no customer data, credentials or internal workbook enters tests or packages.
- Record commands, results, performance observations and known limitations.

## Definition of Done

- Behavior is placed in the correct entry-script or shared-engine layer.
- No business/regulatory rule is hardcoded when it belongs in configuration.
- PowerShell 5.1, offline, read-only and dependency constraints are met.
- Runtime JSON remains immutable and valid.
- Applicable unit, integration and phase-conformance tests pass.
- Progress, logging and failure behavior meet the architecture/phase contract.
- Package, documentation and traceability updates are complete.
- No unresolved stop condition remains.
