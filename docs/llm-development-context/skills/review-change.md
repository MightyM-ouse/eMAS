---
SkillId: SKILL-006
Title: Review an eMAS Repository Change
Version: 1.0.0
Status: Effective
Owner: Technical Architect and QA Lead
DecisionReferences:
  - SK-008
  - AP-004
  - TEST-001
CanonicalSources:
  - docs/governance/00_authority_and_precedence.md
  - docs/governance/eMAS_Document_Governance.md
  - docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
  - docs/CANONICAL_DOCUMENT_INDEX.md
  - docs/architecture/eMAS_Solution_Architecture.md
  - docs/architecture/phase-contracts/README.md
  - docs/llm-development-context/context-index.yaml
AppliesTo:
  - Pull requests
  - Documentation configuration code template and test changes
  - Release-readiness reviews
Supersedes: null
LastReviewed: 2026-07-13
---

# Review an eMAS Repository Change

## Invoke when

- Reviewing a pull request that changes requirements, configuration, schema, PowerShell, WPF, reports, tests, build/release controls or documentation.
- Performing a pre-merge architecture, traceability, safety or delivery-state review.
- Verifying that requested review comments were addressed without introducing drift.

## Do not invoke when

- Root cause is unknown and defect investigation is required; use `investigate-defect.md` first.
- New regulatory content needs SME authoring/approval rather than code review; use `add-regulatory-classification.md`.
- The task is to implement the change rather than independently assess it; use the relevant implementation skill.

## Required inputs and canonical sources

- Pull request/change set, base branch and complete changed-file list.
- Linked requirement, DecisionIds, issue/defect and acceptance criteria.
- Canonical/context indexes and all task-routed sources.
- Test/validation output, fixtures and release/package impact.
- Prior review comments and author responses where applicable.
- Required owner/SME approvals.

## Preconditions

- The full diff and target branch are available.
- The reviewer can access the governing canonical sources.
- The change scope and claimed delivery state are explicit.
- Automated/manual evidence is available or its absence is visible.
- The reviewer is independent enough to challenge assumptions.

## Procedure

1. **Establish scope.** Record base/head, changed files, stated purpose, requirement/DecisionIds and claimed completion state.
2. **Load routed authority.** Use `context-index.yaml` and the Canonical Document Index; do not rely only on PR description or changed files.
3. **Check authority and terminology.** Identify lower-authority overrides, legacy terms, unapproved decisions or examples treated as requirements.
4. **Check source boundaries.** Verify XLSM/JSON/PowerShell roles, one shared JSON, no PowerShell XLSM access and no JSON repair/reinterpretation.
5. **Check logical/schema integrity.** Review stable IDs, relationships, lifecycle, referential/temporal rules, schema versioning, semantic validation and fixtures.
6. **Check phase conformance.** Apply the specific phase contract, including WPF limits, Pre-Sales depth, baseline creation and Post-Migration baseline/MigrationSummary behavior.
7. **Check reporting.** Verify controlled terminology, semantic separation, exception traceability, disclosure, no customer data and OpenXML/no-Excel constraints.
8. **Check runtime quality.** Review PowerShell 5.1 compatibility, read-only behavior, offline dependency boundary, deterministic behavior, progress, logging and error handling.
9. **Check security/privacy.** Look for credentials, customer evidence, production logs/reports, excessive sensitive logging and unsafe output paths.
10. **Check tests and evidence.** Ensure changed behavior has positive, negative, boundary and regression coverage at the correct layer.
11. **Check synchronization.** Verify affected requirements, contracts, schemas, tests, templates, indexes, changelog and package/release documentation are updated or tracked.
12. **Check delivery-state claims.** Reject statements that documentation alone means implementation, verification or release is complete.
13. **Classify findings.** Use Blocker, Major, Minor or Suggestion and cite exact file/line, governing source, impact and required correction.
14. **Re-review fixes.** Confirm each finding is resolved without regression and identify any remaining risks.
15. **Issue recommendation.** State Approve, Approve with non-blocking follow-up or Request Changes with concise rationale.

## Required outputs

- Review scope and governing-source list.
- Findings ordered by severity with file/line, impact, evidence and required action.
- Traceability/coverage gaps and missing approvals.
- Test/validation assessment.
- Security, privacy, architecture and phase-conformance assessment.
- Delivery-state and release-readiness assessment.
- Final merge recommendation and non-blocking follow-ups.

## Stop conditions

Stop or request required specialist review when:

- the full diff or governing sources are unavailable;
- a regulatory interpretation requires SME judgment;
- a schema/logical-model conflict cannot be resolved by precedence;
- baseline/report meaning changes without approved authority;
- test evidence is unavailable for material behavior;
- customer/confidential data appears in the change;
- the reviewer cannot determine compatibility or release impact;
- unresolved blocker findings remain.

## Validation and evidence

- Cite canonical source and changed file/line for every material finding.
- Verify commands and test output rather than relying only on author statements.
- Re-run focused checks where possible and inspect generated artifacts when reporting changes.
- Confirm all review threads are resolved or explicitly accepted as follow-up.
- Record review date, reviewer role, commit SHA and final recommendation.

## Definition of Done

- Complete diff and routed canonical context were reviewed.
- Authority, architecture, logical model, schema, phases, reports and safety were assessed as applicable.
- Findings are specific, evidenced, prioritized and actionable.
- Required tests and approvals are present or correctly block merge.
- Delivery-state claims match actual evidence.
- Blockers are resolved or the PR is marked Request Changes.
- Final recommendation and residual risks are documented.
- No unresolved review stop condition is hidden.
