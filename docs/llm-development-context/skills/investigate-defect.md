---
SkillId: SKILL-007
Title: Investigate an eMAS Defect
Version: 1.0.0
Status: Effective
Owner: Technical Lead and QA Lead
DecisionReferences:
  - SK-009
  - TEST-003
  - TEST-019
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/architecture/eMAS_Solution_Architecture.md
  - docs/architecture/phase-contracts/README.md
  - docs/configuration/04_eMAS_Runtime_JSON_Contract.md
  - docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md
  - docs/llm-development-context/context-index.yaml
AppliesTo:
  - Runtime defects
  - Configuration and schema defects
  - Report template and reconciliation defects
Supersedes: null
LastReviewed: 2026-07-13
---

# Investigate an eMAS Defect

## Invoke when

- A script fails, produces an incorrect phase result, hangs without progress or generates an invalid/incomplete report or log.
- Configuration/schema validation differs between XLSM, independent validator and PowerShell loader.
- Pre-Migration baseline or Post-Migration reconciliation produces missing, extra or inconsistent results.

## Do not invoke when

- The request is a new feature or approved behavior change rather than a deviation from expected behavior.
- The only issue is unapproved regulatory interpretation; route to `add-regulatory-classification.md`.
- Root cause and approved fix are already established; use the applicable implementation skill.

## Required inputs and canonical sources

- Defect reference, expected behavior, actual behavior, affected phase and business impact.
- Reproduction steps, timestamps, screenshots and sanitized logs.
- Script/engine/template/schema/mapping/workbook versions and JSON checksum.
- Input file metadata and minimally necessary sanitized evidence.
- Current code/configuration/template and relevant tests.
- Applicable phase contract, report contract and acceptance criteria.
- Environment details including Windows/PowerShell version, locale, permissions, paths and available storage.

## Preconditions

- Customer data is minimized, masked or replaced with synthetic reproduction evidence.
- Source evidence is preserved read-only.
- The affected version/commit/package can be identified.
- Expected behavior is grounded in an approved requirement or contract.
- Investigation output location is separate from source evidence.

## Procedure

1. **Record the incident envelope.** Capture defect ID, phase, severity, first occurrence, affected versions/checksums, environment and user-visible impact.
2. **Confirm expected behavior.** Cite the governing requirement, architecture/phase/report contract and distinguish defect from enhancement.
3. **Preserve evidence.** Copy only approved diagnostic evidence to a controlled investigation location; record hashes/metadata and avoid modifying originals.
4. **Reproduce safely.** Create the smallest synthetic or masked reproduction that demonstrates the issue without customer-identifiable content.
5. **Classify the likely layer.** Triage configuration/package, schema/semantic validation, input evidence, phase script, shared engine, WPF, OpenXML/template, baseline/MigrationSummary reader, environment or release packaging.
6. **Trace execution.** Follow run initialization, configuration load, phase orchestration, module calls, evidence values, rule outputs, report population and logging.
7. **Compare versions.** Identify whether behavior changes across configuration, engine, schema, template or input versions.
8. **Test hypotheses one at a time.** Record hypothesis, experiment, result and eliminated causes; do not alter production/customer evidence.
9. **Identify root cause.** State the failing component, triggering condition, why controls/tests did not prevent it and whether configuration or code is responsible.
10. **Assess impact.** Identify affected phases, versions, reports, baselines, customers/projects and whether prior outputs require review/recall.
11. **Choose the fix route.** Invoke the configuration, schema, PowerShell, regulatory or report skill appropriate to the root cause.
12. **Define regression coverage.** Add a synthetic test that fails before the fix and passes after, plus negative/boundary cases where applicable.
13. **Verify the fix.** Re-run reproduction, relevant suite, read-only checks, output validation and performance/progress behavior.
14. **Document limitations.** Record residual risk, workarounds, data/report review needs and release/rollback requirements.
15. **Close with evidence.** Link defect, root cause, commit/configuration change, tests, package/release and any affected-output review.

## Required outputs

- Defect investigation record with expected versus actual behavior.
- Sanitized reproduction package and exact reproduction steps.
- Evidence/hypothesis log and confirmed root cause.
- Impact assessment across phases, versions and prior outputs.
- Selected fix skill/path and change requirements.
- Regression tests and verification results.
- Workaround, rollback/recall and residual-risk recommendations.
- Traceability to defect, commit/configuration, tests and release evidence.

## Stop conditions

Stop and escalate when:

- expected behavior is not grounded in an approved source;
- required versions/checksum/logs/reproduction evidence are unavailable;
- investigation would require modifying customer source evidence;
- unmasked customer data or credentials would enter the repository;
- regulatory interpretation is necessary to choose expected behavior;
- baseline/MigrationSummary identity or compatibility cannot be established;
- evidence indicates a security/privacy incident requiring a separate response process;
- a production workaround would bypass configuration/package integrity or validation controls.

## Validation and evidence

- Preserve input/evidence metadata and hashes where permitted.
- Record exact commands, environment, timestamps, results and relevant log lines.
- Demonstrate the defect with a synthetic failing regression test.
- Demonstrate the fix with passing focused and affected-suite tests.
- Verify source evidence remains unchanged.
- Validate generated reports/logs and phase-result terminology.
- Record whether prior outputs need review, withdrawal, regeneration or recall.

## Definition of Done

- Expected and actual behavior are explicitly evidenced.
- Root cause is confirmed rather than merely suspected.
- Scope and prior-output impact are assessed.
- A regression test demonstrates failure-before and pass-after behavior.
- The fix uses the correct governed skill/layer and preserves architecture boundaries.
- Verification, workaround and rollback/recall needs are documented.
- Evidence contains no prohibited customer/confidential content.
- No unresolved stop condition remains or it is formally escalated.
