# Codex Repository Reconciliation and Wave 2 Planning Report

**Task ID:** EMAS-MS04-WAVE2-PLANNING

**Agent:** Codex

**Role:** Repository reconciliation / qualification recording / Wave 2 structure planning

**Base commit:** `58534391684d254abed4251e7f6deacd759e2b78`

**Report status:** Completed

**Scope:** MS-04 Pre-Sales planning only

**Implementation performed:** No

## Repository state

The inspected worktree was `/Users/vinay/Projects/AI/eMAS/eMAS-codex` on `demo/end-to-end-mvp`, tracking `origin/demo/end-to-end-mvp`, at the base commit above. Other worktrees existed for `implementation/mvp-mapping-workbook-v0.1` and `implementation/template-corrections`.

The worktree was already dirty. Four tracked documentation/orchestration files were modified, while the accepted capability modules, harnesses, and expectation files were untracked. Git therefore could not independently establish their provenance from HEAD.

## Eight-capability baseline

All accepted modules and corresponding regression harnesses were present:

1. RepositoryDiscovery 0.1.0
2. BackboneXmlInventory 0.2.0
3. ReferenceInventory 0.3.0
4. ReferenceResolution 0.4.0
5. MissingReferenceInterpretation 0.5.0
6. DeclaredChecksumComparison 0.6.0
7. ChecksumMismatchInterpretation 0.7.0
8. ClassificationEvidenceCollection 0.8.0

The eight modules, eight harnesses, eight Wave 1 expectation files, entry script, and `eMAS.SafeXml.ps1` were byte-identical to the hashes in the internal Windows qualification package manifest. The entry point composed the accepted chain in order under contract `eMAS.MS04.PreSales.ScannerObservations/1.0` and scanner version `0.8.0`.

Because these files were untracked, unchanged status was established against the qualification package manifest rather than Git history.

## Files and evidence inspected

The review covered repository status/worktrees; `engine/powershell51`; `scripts/eMAS-PreSalesAssessment.ps1`; the eight regression suites and expectations; ClassificationEvidenceCollection and its test; the frozen Wave 1 workspace, manifests, expectations, and verification report; the Wave 1 scanner contract and acceptance matrix; packaging records; release guidance; the canonical document index; document governance; the runtime profile; and the Pre-Sales phase contract.

The internal qualification package contained execution instructions and `PACKAGE_MANIFEST.csv`. The external packaging summary still described native Windows qualification as pending. No completed Windows logs or generated suite-summary files were located in the inspected workspace.

## Qualification evidence recommendation

Record the completed bounded Windows result under source-controlled `releases/`, not in runtime code or historical per-capability reports:

- create `releases/eMAS_MS04_PreSales_RC1_Windows_PS51_Qualification.md`;
- create `releases/manifests/eMAS_MS04_PreSales_RC1_Windows_PS51_Qualification.json`;
- update `releases/README.md` and `docs/CANONICAL_DOCUMENT_INDEX.md`;
- reconcile the supporting external `packages/PACKAGING_SUMMARY.md` pending status.

The record should identify the Windows/PowerShell/process environment; runtime, test-data, and qualification-package hashes; module/test identities; 19/19 runtime outcome; all eight suite totals; SD-003 and SD-004 positive controls; approvals; and the `TEMP=C:\eT`/`TMP=C:\eT` harness-only path-length note. That note must explicitly state that no production change or customer runtime requirement follows from it.

Do not rewrite older capability reports whose pending statements accurately describe their historical execution context. The broad runtime profile also covers gates beyond this bounded RC1 qualification and should not be overclaimed.

## Proposed dossier-diversity wave

Use a separate `MS-04-PreSales-Wave2-DossierDiversity` corpus with global fixture IDs SD-021 through SD-026. SD-019 remains deferred and SD-020 is already assigned.

| ID | Proposed layout | Expected boundary |
|---|---|---|
| SD-021 | `ProductABC/` | Neutral name; dossier-relative technical, region, and specification evidence matches SD-002. |
| SD-022 | `FDA-US-ASMF/` | Misleading name remains weak raw DossierContext evidence and does not create a region, format, or candidate value. |
| SD-023 | `Inbound/Batch-01/Transfer/ProductABC/` | Wrappers affect full paths only, not dossier-relative evidence. |
| SD-024 | `Repository/ProductABC/` plus `Repository/ProductXYZ/` | Two deterministic, independently scoped dossiers with no cross-dossier evidence leakage. |
| SD-025 | `ProductABC/` plus neutral unrelated files | One valid dossier; unrelated content does not force classification. |
| SD-026 | `Inbound Files (QA)/Product ABC - Batch_01/` | Portable spaces and selected punctuation round-trip safely. |

Follow the Wave 1 control order: author expectations first, derive content from frozen SD-002 without altering it, build deterministic ZIPs, independently verify each mutation, then freeze the six hashes. Use a separate full-chain harness and separate expectation file.

Single-dossier fixtures should retain SD-002's dossier-relative ClassificationEvidenceCollection profile: 86 records with `DossierContext=1`, `Region=30`, `SpecificationProfile=20`, and `TechnicalFormat=35`. The two-dossier fixture should contain two independently scoped profiles.

## Proposed files

Qualification files:

- `releases/eMAS_MS04_PreSales_RC1_Windows_PS51_Qualification.md`
- `releases/manifests/eMAS_MS04_PreSales_RC1_Windows_PS51_Qualification.json`
- updates to `releases/README.md`, `docs/CANONICAL_DOCUMENT_INDEX.md`, and the supporting external packaging summary

Wave 2 controlled workspace under `02_Working/MS-04-PreSales-Wave2-DossierDiversity/`:

- `README.md`
- deterministic builder and independent verifier
- source register, fixture JSON/CSV manifests, and `WAVE2_FREEZE_MANIFEST.csv`
- expected-result JSON for SD-021 through SD-026
- each `fixtures/SD-xxx/fixture.zip` and `manifest.json`
- per-fixture verification JSON, summary JSON/CSV, and verification report

Repository regression additions:

- `tests/dossier-diversity/Test-eMASDossierDiversityWave2.ps1`
- `tests/fixtures/dossier-diversity/wave2-expectations.json`
- a documentation-only update to `tests/README.md`

No existing Wave 1 expectation file should change.

## Risks and open questions

- **Folder-name evidence:** ClassificationEvidenceCollection currently records dossier roots as weak `FolderNameHeuristic` evidence in `DossierContext`, with no populated candidate value. The new wave can prove isolation; later detection logic must define actual precedence.
- **Multi-dossier behavior:** current data structures scope sequences and XML by `DossierId`, but no frozen physical two-dossier case proves deterministic boundaries or absence of cross-link leakage.
- **Wrapper handling:** SD-016 proves recursive discovery but includes `EU` in the wrapper. A neutral wrapper fixture is still required.
- **Fixture independence:** below the changed root/layout, dossier bytes must remain identical to SD-002; each fixture must introduce only its declared mutation.
- **Expected-result derivation:** expectations must come from the accepted contract and independently derived dossier-relative SD-002 facts, never from the scanner under test.
- **ZIP determinism:** normalize or explicitly control entry order, separators, timestamps, and attributes before freezing hashes.
- **Portable names:** define an allowlist and exclude Windows-invalid characters, reserved device names, trailing spaces/dots, and ambiguous path segments.
- **Windows path length:** deep wrappers may reproduce the qualification-harness extraction limit; use the documented short-TEMP setup without turning it into a production requirement.
- **Evidence retention:** preserve final Windows logs and suite summaries in an approved internal evidence store and reference their hashes from the release record.
- **Git provenance:** accepted files matched the qualification manifest but were not tracked at the inspected base commit; controlled source history remains necessary.

## Scope confirmation

- No accepted production module needs modification.
- No accepted test needs modification for this planning task.
- No frozen Wave 1 fixture or Wave 1 expectation needs modification.
- FormatDetection was not implemented.
- RegionDetection was not implemented.
- No capability implementation was performed.
