# EMAS-MS04-ROOT-LEVEL-DOSSIER

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`  
**Authoritative base commit:** `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`  
**Base branch:** `demo/end-to-end-mvp`  
**Phase:** Bounded defect resolution, regression, review, and qualification  
**Purpose:** Correct root-level dossier handling in `ReferenceResolution` and `ClassificationEvidenceCollection` without changing `FormatDetection`, `RegionDetection`, discovery semantics, or the frozen Wave 1 baseline.

## Source decision

This task implements only the next action approved in `EMAS-MS04-WAVE2-PLANNING`:

- `ReferenceResolution` mishandles an empty dossier path and can drop the first character of a repository-relative XML path, producing false missing-reference findings.
- `ClassificationEvidenceCollection` rejects the empty root path in mandatory string parameters, can emit no evidence for a valid root-level dossier, and can still report `Collected`.
- The two defects must be reproduced independently, fixed narrowly, covered by focused regression tests, and requalified before the blocked root-level dossier fixture can enter a later SD-044+ wave.

The merged planning artifacts and `reports/CONSOLIDATED.md` remain the decision record. This task does not reopen Wave 2 planning.

## Baseline gate

Before editing:

1. Verify the work is based on commit `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`.
2. Verify the complete accepted eight-capability RC1 package is present: modules, entry script, `eMAS.SafeXml.ps1`, eight regression harnesses, eight expectation files, and the 19 frozen Wave 1 ZIP fixtures.
3. Verify those accepted inputs against the internal Windows qualification-package manifest and record the manifest identity and hashes used.
4. Run the existing eight automated suites before modification and record the result.

The accepted capability files were not all tracked at the planning baseline. Do not reconstruct missing files from reports, silently import a different package, or broaden this task into baseline materialization. If the complete qualified package cannot be proven, stop with `BLOCKED_BASELINE_NOT_REPRODUCIBLE` and publish the evidence in the assigned report.

## Correct root semantics

For this task, a dossier with `RelativePath = ''` means the dossier is the repository/archive root.

- A non-empty repository-relative path such as `0000/index.xml` is inside the root dossier.
- Removing a root dossier prefix removes zero characters and no separator; `0000/index.xml` must remain `0000/index.xml`.
- Joining the root dossier with a normalized target returns the normalized target unchanged.
- Existing normalization and safety rules remain in force. Absolute paths, traversal, and paths that escape the repository/dossier remain unsafe.
- A valid root-level dossier must produce the same dossier-relative reference and classification evidence as the equivalent wrapped dossier, except for fields that intentionally identify the dossier root.
- `ClassificationEvidenceCollection` may legitimately report zero evidence for unrelated/non-dossier content such as the existing SD-020 case. It must not report zero evidence merely because a valid dossier path is empty.
- Coverage status and `RecordsProduced` must reflect the records actually collected. No non-terminating parameter-binding failure may be hidden behind `Collected`.

## Scope

### In scope

- Reproduce each root-level defect independently on the accepted pre-fix baseline.
- Add focused synthetic regression coverage for a valid root-level dossier without modifying frozen Wave 1 fixtures or expectations.
- Apply the smallest compatible fixes to:
  - `engine/powershell51/eMAS.ReferenceResolution.psm1`
  - `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- Update only the directly relevant existing harnesses or add a single focused root-level-dossier harness and new synthetic fixture/expectation files.
- Prove wrapped-dossier behavior is unchanged.
- Run the two focused suites, all eight existing automated suites, freeze-integrity checks, and the composed accepted chain.
- Perform native 64-bit Windows PowerShell 5.1 qualification at the reviewed implementation commit.
- Persist implementation, review, and qualification evidence in this task's report directory.

### Out of scope

- `FormatDetection` or `RegionDetection` implementation, tests, contracts, or capability declarations.
- `RepositoryDiscovery` changes, including the separate `Archive/2019` discovery-semantics question.
- Any SD-044+ dossier-diversity wave build, catalogue update, or fixture freeze, including accepting SD-050.
- Changes to frozen Wave 1 ZIPs, manifests, or any of the eight Wave 1 expectation files.
- Changes to the other six accepted capability modules, `scripts/eMAS-PreSalesAssessment.ps1`, `eMAS.SafeXml.ps1`, reporting, packaging, UI, schemas, or product contracts.
- Migration execution, migration readiness, post-migration verification, DMS-to-DMS, database migration, or archive migration.
- Opportunistic refactoring, renaming, formatting churn, or dependency installation.

## Ownership and allowed files

Only the implementation owner may modify runtime/test files. Review and qualification agents are read-only except for their own reports.

### Codex — implementation owner

**Branch:** `implementation/emas-ms04-root-level-dossier`  
**Deliverable:** `reports/CODEX.md` plus the bounded implementation and focused regression changes.

Allowed runtime/test files:

- `engine/powershell51/eMAS.ReferenceResolution.psm1`
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- `tests/reference-resolution/Test-eMASReferenceResolution.ps1`
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`
- New task-specific files under `tests/root-level-dossier/` and `tests/fixtures/root-level-dossier/`, only if needed for focused synthetic coverage
- `docs/internal/agent-tasks/EMAS-MS04-ROOT-LEVEL-DOSSIER/reports/CODEX.md`

Codex must first commit a failing characterization or otherwise preserve deterministic pre-fix evidence in the report, then implement the minimal fix and record post-fix results. Do not edit task coordination files or another agent's report. Push the dedicated branch and open a PR into the task coordination branch when authorized by the repository workflow. Do not merge.

### Claude — fixed-SHA reviewer

**Input:** The exact Codex implementation commit SHA  
**Deliverable:** `reports/CLAUDE.md`

Review the two defect reproductions, empty-root semantics, changed code, focused tests, safety behavior, compatibility with Windows PowerShell 5.1, and scope compliance. Confirm that the new regression would fail on the accepted pre-fix code and pass on the reviewed commit. Confirm that frozen inputs were not changed and that `FormatDetection`, `RegionDetection`, and `RepositoryDiscovery` were untouched. Remain read-only except for your report. Do not fix code or merge.

### Hermes — independent qualification

**Input:** The exact Codex implementation commit SHA after Claude review  
**Deliverable:** `reports/HERMES.md`

Independently rerun the focused tests, all eight automated suites, freeze-integrity verification, and composed-chain checks. Perform native 64-bit Windows PowerShell 5.1 qualification and record OS/runtime, commands, fixture/suite counts, hashes, exit status, and result paths. Include adversarial checks for empty root, wrapped-root parity, traversal/absolute-path rejection, and valid zero-evidence unrelated content. Remain read-only except for your report. If native Windows PowerShell 5.1 is unavailable, report `BLOCKED_WINDOWS_QUALIFICATION` rather than substituting another runtime or claiming qualification. Do not merge.

## Acceptance criteria

The task is ready for user review only when all of the following are true:

1. Both defects are reproduced independently against the accepted pre-fix package.
2. A valid root-level dossier preserves repository-relative XML paths and resolves present reference targets without false missing-reference findings.
3. `ClassificationEvidenceCollection` accepts the empty root path, emits the expected non-zero evidence for the valid dossier, and reports accurate coverage and record counts.
4. Wrapped-dossier and root-dossier projections are equivalent except for intentional root-identifying fields.
5. Absolute paths, traversal, and escape attempts remain rejected.
6. Existing legitimate zero-evidence behavior remains intact.
7. The two focused suites pass.
8. All eight existing automated suites pass against all 19 frozen Wave 1 fixtures.
9. Frozen Wave 1 fixture and expectation hashes are identical before and after testing.
10. Native 64-bit Windows PowerShell 5.1 qualification passes at the exact reviewed commit.
11. Claude reports no unresolved correctness, regression, security, compatibility, or scope blocker.
12. The implementation diff contains no changes to forbidden files or capabilities.

## Decision gate

No agent may approve or merge on the user's behalf. After Codex, Claude, and Hermes reports are persisted, the coordinator reconciles them and updates `STATUS.md`. The user decides whether the implementation PR is accepted into `demo/end-to-end-mvp`. Only after acceptance may a separate task build and freeze the SD-044+ dossier-diversity wave.
