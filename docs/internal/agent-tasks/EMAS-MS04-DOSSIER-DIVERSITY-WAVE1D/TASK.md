# EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D

**Task ID:** `EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D`  
**Authoritative base commit:** `793e065db17fed043ea95f9494f0e5f1458f0b72`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT review → user decision  
**Stage:** Mac-first fixture construction, freeze, and regression  
**Windows PowerShell 5.1:** Deferred until the Mac fixture baseline is accepted

## Purpose

Build and validate the first dossier-diversity fixture wave for MS-04 Pre-Sales before any FormatDetection or RegionDetection work.

Wave 1 remains the accepted frozen 19-fixture baseline. This task does **not** rename or modify those fixtures. Instead it adds a separate diversity corpus designed to prove that the accepted scanner behaves consistently when dossier names, wrappers, repository layout, and unrelated content vary.

The task also provides durable regression coverage for the root-level dossier handling fixed at base commit `793e065db17fed043ea95f9494f0e5f1458f0b72`.

## Why this task exists

The accepted Wave 1 corpus is intentionally narrow and most valid fixtures inherit the dossier root name `EXTEDORIN 50mg Tablets EU-FR`. That is useful as a stable baseline but insufficient to prove that future classification logic is not accidentally learning from that folder name.

The new wave therefore changes **container/layout context**, not regulatory content. Structured XML and accepted dossier bytes remain authoritative.

## Baseline gate

Before creating anything:

1. Confirm the work is based on `793e065db17fed043ea95f9494f0e5f1458f0b72` or a descendant containing it.
2. Confirm the repository-native qualified RC1 baseline is present.
3. Run all eight existing Wave 1 automated suites on Mac against the frozen 19-fixture corpus.
4. Record the Wave 1 package identity:
   - `eMAS_MS04_PreSales_Wave1_TestData_v1.zip`
   - SHA-256 `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7`
5. Confirm the frozen source fixtures and existing Wave 1 expectations are unchanged before proceeding.

If the baseline does not pass, stop and report `BLOCKED_BASELINE_REGRESSION`. Do not repair unrelated runtime code in this task.

## Fixture IDs and scope

Use the globally non-conflicting IDs below. Do **not** use SD-021 through SD-043; those identifiers are reserved by the existing sample-data plan.

### Mandatory fixtures

| ID | Fixture | Source profile | Required intent |
|---|---|---|---|
| SD-044 | Neutral dossier root: `ProductABC` | SD-002 | Remove dependence on the historical EXTEDORIN/EU-FR dossier name. |
| SD-045 | Misleading dossier root: `FDA-US-ASMF` | SD-002 | Prove misleading folder text does not alter collected structured evidence. ASMF remains context text, not technical-format evidence. |
| SD-046 | Neutral wrappers: `CustomerExport/ArchiveSet/ProductABC` | SD-002 | Prove wrapper depth/names do not alter dossier-relative regulatory evidence. |
| SD-047 | Asymmetric multi-dossier repository: `ProductABC` + `ProductXYZ` | SD-002 + SD-010 | Prove dossier scoping and prevent cross-dossier evidence/reference leakage. |
| SD-048 | Valid dossier plus unrelated content | SD-002 | Prove unrelated PDFs/XML/text outside valid sequence structure do not become dossier evidence. |
| SD-049 | Safe ASCII naming variation: `Product ABC (Copy 2) & Co_v1.2` | SD-002 | Exercise spaces and portable punctuation without introducing unsafe/reserved path semantics. |
| SD-050 | Dossier at archive root, sequences directly at root | SD-002 | Lock in the accepted empty-root semantics fixed by the root-level dossier task. |
| SD-051 | Valid dossier plus unrelated year folder `Archive/2019/` | SD-002 | Characterize the current four-digit-folder discovery heuristic without changing RepositoryDiscovery. |

### Deferred

**SD-052 nested dossier** remains deferred. Do not add it in this task unless the coordinator explicitly amends TASK.md. The previous planning work identified it as optional/later, and adding it now would expand the acceptance surface without helping the immediate gate.

## Regulatory/evidence rules

These are non-negotiable:

- This is an **evidence-collection and dossier-layout** test wave, not a classification implementation.
- Structured XML evidence is stronger than folder-name heuristics.
- Folder and wrapper names may be retained as weak/raw context evidence but must not manufacture structured Region, TechnicalFormat, or SpecificationProfile evidence.
- ASMF/DMF are **DossierContext** concepts, not TechnicalFormat values.
- Missing, access denied, parse failed, unsupported, conflicting, and absent evidence remain distinct concepts.
- Do not invent non-EU regulatory XML. All mandatory fixtures are transformations/combinations of already accepted source fixtures.
- Do not claim regulatory validity, submission readiness, or migration readiness from these tests.

## Independent expectation derivation

Expectations must be established **before fixture freeze** and must not be copied from the post-build output of the modules under test.

Use two derivation paths where practical:

1. **Transform derivation**
   - Derive expected dossier-relative facts from the accepted SD-002 and SD-010 expectation files.
   - Apply only the planned container/path transformation.
   - For multi-dossier SD-047, combine the accepted source profiles without merging dossier identities.

2. **Independent oracle/structural derivation**
   - Inspect generated ZIP entry paths and parse the contained XML directly.
   - Do not call eMAS capability modules to decide what the expected XML roots, namespaces, DTD declarations, source file bytes, or dossier-relative paths should be.
   - Use the oracle to confirm the transform-derived expectations.

If the two derivations disagree, stop with `BLOCKED_EXPECTATION_DISAGREEMENT` rather than tuning expectations to make the scanner pass.

## Required invariants

At minimum, validate these invariants:

- SD-044, SD-045, SD-046, SD-048, SD-049 and SD-050 preserve the accepted SD-002 regulatory bytes.
- Their structured XML evidence and dossier-relative evidence remain equivalent to SD-002 except for fields intentionally representing the dossier root/wrapper context.
- SD-045: `FDA`, `US`, and `ASMF` appear only where the raw path/root context legitimately contains those strings; they do not create new structured TechnicalFormat, Region, or SpecificationProfile evidence.
- SD-046: wrapper names do not create regulatory evidence.
- SD-047: every reference target, XML record, sequence identity, and classification-evidence record stays within its owning dossier. No cross-dossier resolution or evidence merge.
- SD-048: unrelated external content and decoy paths do not enter the valid dossier's structured evidence.
- SD-049: path text is preserved safely and does not break PowerShell/path handling.
- SD-050: root dossier path is empty; references remain resolvable; classification evidence remains complete; wrapped/root dossier-relative projections remain equivalent except for intentional root-identifying fields.
- Existing legitimate zero-evidence behavior such as SD-020 remains unchanged.

## SD-051 decision boundary

SD-051 is **characterization**, not a product-policy decision.

Current RepositoryDiscovery may interpret `Archive/2019/` as a dossier/sequence candidate because `2019` matches the four-digit heuristic.

For this task:

- Do not change RepositoryDiscovery.
- Record the actual deterministic current behavior separately from normative expectations.
- Label the result `CHARACTERIZATION_PENDING_DISCOVERY_DECISION`.
- Verify that the genuine `ProductABC` dossier remains independently discoverable and its evidence does not leak into/from the year-folder candidate.
- Do not describe the year-folder candidate as a correct regulatory dossier.
- A future dedicated discovery-semantics task may change this behavior.

## Deterministic fixture generation and freeze

The generated corpus must be reproducible.

Required controls:

- Source SD-002 and SD-010 are read-only.
- Preserve source file bytes below their sequence trees unless a fixture explicitly adds unrelated synthetic files.
- Use deterministic ZIP ordering.
- Use fixed ZIP timestamps.
- Use stable directory entries and permission metadata following the existing Wave 1 convention.
- Use portable ASCII paths for mandatory fixtures.
- Do not create unsafe names, traversal paths, reserved Windows device names, or case-only collisions.
- Build the complete wave twice from a clean scratch location and prove that each corresponding fixture ZIP SHA-256 is identical.
- Generate a freeze manifest containing ID, purpose, source fixture(s), mutation, entry count, ZIP SHA-256, and status.
- Freeze only after independent expectations agree and validation passes.
- Once frozen, no fixture may be edited in place. Any later change requires a new version or fixture ID.

## Expected output package

Create a controlled Mac-side package for later Windows transfer:

`eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1.zip`

It should contain the generated fixture ZIPs, per-fixture metadata/manifest, freeze manifest, expectation package needed by the dedicated harness, and a short README stating that the material is internal test data.

The binary package itself does not need to be committed to Git unless repository policy already permits it. Its SHA-256 and internal manifest hashes **must** be recorded in `reports/CLAUDE.md`.

## Repository deliverables

Claude is the only implementation owner for this task.

**Implementation branch:** `implementation/emas-ms04-dossier-diversity-wave1d`

Allowed repository paths:

- `tests/dossier-diversity/**`
- `tests/fixtures/dossier-diversity/**`
- `tools/testdata/ms04-wave1d/**` for deterministic builder/oracle utilities if needed
- `docs/internal/agent-tasks/EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D/reports/CLAUDE.md`

If an existing repository-native path is clearly more appropriate for a new test-data utility, Claude may use it only if the report explains why. Do not modify runtime/engine code.

Expected repository artifacts include:

- dedicated Mac regression harness for Wave1D;
- machine-readable Wave1D expectations;
- deterministic build/oracle utility or reproducible recipe;
- repository copy of the Wave1D freeze/hash manifest;
- Claude implementation report.

## Forbidden changes

Do not modify:

- any `engine/**` runtime module;
- `scripts/eMAS-PreSalesAssessment.ps1`;
- `RepositoryDiscovery`, `FormatDetection`, or `RegionDetection`;
- any frozen Wave 1 fixture or Wave 1 expectation file;
- accepted Wave 1 freeze manifest;
- runtime/package configuration unrelated to test-data construction;
- product contracts, readiness rules, migration logic, reporting, or UI.

If a mandatory normative fixture exposes a new runtime defect, record the defect and stop that acceptance path. Do not fix runtime code inside this task.

## Mac validation

After building but before freeze:

1. Run the dedicated Wave1D harness over SD-044 through SD-050.
2. Run the SD-051 characterization path separately.
3. Run the composed accepted 8-capability chain over every new fixture.
4. Run all eight existing Wave 1 automated suites over all 19 frozen Wave 1 fixtures.
5. Verify Wave 1 freeze/expectation hashes remain unchanged.
6. Rebuild Wave1D from clean scratch and confirm deterministic ZIP hashes.
7. Ensure the repository working tree is clean after test execution except for intended committed source/test/report files.

This task is Mac-only. Use the available Mac PowerShell environment and record its exact version. Do not claim Windows PowerShell 5.1 qualification.

## Acceptance criteria

The task is ready for ChatGPT review only when:

1. Baseline 8/8 Wave 1 Mac regression passes before changes.
2. SD-044 through SD-050 are generated deterministically and have independently derived expectations.
3. SD-051 is clearly marked as characterization, not normative discovery policy.
4. Dossier-name diversity is represented without modifying Wave 1.
5. Misleading folder text does not alter structured evidence.
6. Multi-dossier scoping shows no cross-dossier leakage.
7. Root-level SD-050 passes with the merged root-path fix.
8. Dedicated Wave1D Mac regression passes for all normative fixtures.
9. All eight original Wave 1 suites still pass after the new wave is built.
10. Source/freeze hashes are recorded and a second clean build reproduces them.
11. No runtime module or forbidden file changes.
12. `reports/CLAUDE.md` contains fixture matrix, derivation method, hashes, test commands, results, open decisions, and any blocker.

## Review and decision gate

After Claude publishes the implementation PR, ChatGPT reviews the GitHub diff, report, fixture design, expectation independence, test results, and scope compliance.

No second general-purpose agent review is required by default.

The user decides whether to accept/merge the Mac Wave1D baseline.

Windows PowerShell 5.1 qualification remains a later consolidated stage after the Mac fixture wave is accepted.
