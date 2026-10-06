# EMAS-MS04-ROOT-LEVEL-DOSSIER

**Task ID:** `EMAS-MS04-ROOT-LEVEL-DOSSIER`  
**Authoritative baseline commit:** `dac1664fee652f701a41204e2527f602077bb42f`  
**Base branch:** `demo/end-to-end-mvp`  
**Phase:** Bounded defect resolution with Mac-first validation  
**Purpose:** Correct root-level dossier handling in `ReferenceResolution` and `ClassificationEvidenceCollection` without changing `FormatDetection`, `RegionDetection`, `RepositoryDiscovery`, or the frozen Wave 1 baseline.

## Baseline

PR #29 materialized the exact previously qualified MS-04 RC1 runtime/test baseline into Git and was merged at `dac1664fee652f701a41204e2527f602077bb42f`.

Before editing, Codex must verify:
1. the branch is based on that commit or a descendant containing it;
2. the eight accepted capability modules, entry script, `eMAS.SafeXml.ps1`, eight harnesses, and eight expectation files are present;
3. package/manifest identities match the recorded RC1 qualification evidence;
4. all eight existing suites pass on Mac before the fix.

If the baseline still cannot be reproduced, stop and report the evidence. Do not import or reconstruct anything else.

## Correct root semantics

A dossier with `RelativePath = ''` means the dossier is the repository/archive root.

- `0000/index.xml` must remain `0000/index.xml`; removing an empty root prefix removes zero characters and no separator.
- Joining the root dossier with a normalized target returns the normalized target unchanged.
- Existing safety rules for traversal, absolute paths, and repository escape remain unchanged.
- A valid root-level dossier must produce the same dossier-relative reference/classification evidence as an equivalent wrapped dossier, except for intentional root-identifying fields.
- A valid root-level dossier must not produce zero classification evidence merely because its root path is empty.
- Legitimate zero-evidence unrelated content remains valid.
- Coverage and `RecordsProduced` must reflect actual collection results.

## In scope

- Reproduce both root-level defects against the accepted pre-fix baseline.
- Add focused synthetic root-level regression coverage without changing frozen Wave 1 fixtures or expectations.
- Apply the smallest compatible fixes to:
  - `engine/powershell51/eMAS.ReferenceResolution.psm1`
  - `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- Update only directly relevant harnesses, or add task-specific files under `tests/root-level-dossier/` and `tests/fixtures/root-level-dossier/` if needed.
- Prove wrapped-dossier behavior remains unchanged.
- Run focused tests, all eight existing suites, freeze-integrity checks, and the composed accepted chain on Mac.
- Publish implementation and test evidence in `reports/CODEX.md`.

## Out of scope

- `FormatDetection` or `RegionDetection`.
- `RepositoryDiscovery` changes, including the separate `Archive/2019` question.
- SD-044+ fixture-wave construction or freeze.
- Changes to frozen Wave 1 ZIPs, manifests, or Wave 1 expectation files.
- Changes to the other six accepted capability modules, entry script, SafeXml, reporting, packaging, schemas, or product contracts.
- Opportunistic refactoring or formatting churn.
- Native Windows PowerShell 5.1 qualification during this Mac implementation stage.

## Ownership

### Codex — implementation owner

**Branch:** `implementation/emas-ms04-root-level-dossier-v2`

Allowed runtime/test files:
- `engine/powershell51/eMAS.ReferenceResolution.psm1`
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- `tests/reference-resolution/Test-eMASReferenceResolution.ps1`
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`
- task-specific files under `tests/root-level-dossier/` and `tests/fixtures/root-level-dossier/`, only if needed
- `docs/internal/agent-tasks/EMAS-MS04-ROOT-LEVEL-DOSSIER/reports/CODEX.md`

Codex must preserve deterministic pre-fix evidence, implement the minimal fix, run Mac regression, push the dedicated branch, and open a draft PR into `demo/end-to-end-mvp`. Do not merge.

### ChatGPT — central review/coordinator

After Codex publishes the implementation PR, ChatGPT reviews the exact GitHub diff, report, test evidence, scope, safety behavior, and baseline integrity. Additional Claude/Hermes review is optional and used only when a specific independent question needs it.

### Windows qualification — deferred stage

Native 64-bit Windows PowerShell 5.1 qualification is intentionally deferred until the Mac implementation baseline is accepted. It remains required before the updated runtime is declared Windows-qualified, but it is not a blocker for completing this Mac defect-resolution stage.

## Mac-stage acceptance criteria

1. Both defects reproduced independently on the pre-fix baseline.
2. Root-level reference paths no longer lose characters or produce false missing-reference findings.
3. Classification evidence collection accepts the empty root and emits the expected non-zero evidence.
4. Wrapped/root projections are equivalent except for intentional root-identifying fields.
5. Traversal, absolute-path, and escape protections remain intact.
6. Legitimate zero-evidence unrelated content remains intact.
7. Focused root-level regression tests pass.
8. All eight existing suites pass against all 19 frozen Wave 1 fixtures on Mac.
9. Frozen Wave 1 fixture and expectation hashes remain unchanged.
10. No forbidden capability or file is changed.
11. ChatGPT review finds no unresolved blocker.

## Decision gate

After the Mac stage passes, the user decides whether to accept the implementation baseline and proceed to native Windows PowerShell 5.1 qualification. Only after Windows qualification is complete should the runtime be called requalified for Windows.
