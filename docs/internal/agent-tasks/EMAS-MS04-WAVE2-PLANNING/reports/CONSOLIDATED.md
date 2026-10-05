# Consolidated Report — EMAS-MS04-WAVE2-PLANNING

**Status:** `COMPLETE`

**Task ID:** EMAS-MS04-WAVE2-PLANNING

**Source reports:** Codex repository reconciliation, Claude/Cursor dossier-diversity design, and Hermes independent adversarial review.

## Executive decision

The current eight-capability MS-04 Pre-Sales RC1 remains the accepted qualified baseline for the tested Wave 1 scope. Wave 1 stays frozen.

Before any FormatDetection or RegionDetection implementation, eMAS needs a separate dossier-diversity wave and two root-level-dossier defects need a dedicated remediation task.

## Agreed findings

1. **Preserve the qualified baseline.**
   - 8 accepted capabilities.
   - Native 64-bit Windows PowerShell 5.1 qualification passed.
   - 19/19 Wave 1 runtime fixtures passed.
   - 8/8 automated suites passed.
   - No accepted Wave 1 fixture, expectation, or accepted capability module should be changed as part of planning.

2. **The repeated dossier-name pattern is a real coverage gap.**
   - Most valid Wave 1 fixtures inherit `EXTEDORIN 50mg Tablets EU-FR`.
   - Do not rename those frozen fixtures.
   - Add new fixtures with neutral, misleading, wrapped, multi-dossier, unrelated-content, and safe-name variants so future classification cannot depend on the historical root name.

3. **Use new fixture IDs starting at SD-044.**
   - Claude found that SD-021 through SD-043 are already reserved in the sample-data catalogue.
   - The dossier-diversity wave should therefore use SD-044 onward unless a later approved catalogue decision chooses a separate prefix.

4. **Root-level dossier handling has two defect candidates.**
   - ReferenceResolution mishandles an empty dossier path and can produce false missing-reference findings.
   - ClassificationEvidenceCollection can produce zero evidence while still reporting Collected for a root-level dossier.
   - These must be investigated and fixed in a separate bounded task before the root-level fixture is accepted.

5. **The `Archive/2019` case exposes a discovery-semantics gap.**
   - Current discovery can treat an unrelated four-digit folder as a sequence/dossier candidate.
   - This needs an explicit product/contract decision before changing RepositoryDiscovery.
   - Until decided, it should be represented as characterization coverage, not silently "fixed" inside another task.

6. **Do not start generic FormatDetection or RegionDetection yet.**
   - Hermes correctly identified that the current corpus is still EU-heavy and does not adequately cover conflicting strong evidence, malformed/partial inputs, authentic cross-region structures, or true cross-format diversity.
   - Hermes' large matrix is treated as a long-term coverage target, not as a requirement to create hundreds of fixtures immediately.
   - Continue incrementally.

## Approved planning direction

The next fixture wave should include, at minimum:

- SD-044: neutral dossier root (for example `ProductABC`)
- SD-045: deliberately misleading dossier root (for example `FDA-US-ASMF`)
- SD-046: neutral wrapper hierarchy
- SD-047: asymmetric multi-dossier repository
- SD-048: valid dossier plus unrelated content
- SD-049: safe ASCII naming variation
- SD-050: root-level dossier, blocked until root-path defects are resolved
- SD-051: unrelated year-named folder characterization, pending discovery-semantics decision
- SD-052: nested dossier, optional/later

Structured XML evidence remains stronger than folder-name heuristics. Region, TechnicalFormat, SpecificationProfile, and DossierContext remain separate dimensions. ASMF/DMF are contexts, not technical formats.

## Next task

Create a dedicated bounded defect-resolution task for **root-level dossier support**.

That task should:
- reproduce both defects independently;
- define correct empty-root semantics;
- fix only the affected root-path handling;
- add focused regression tests;
- run the full existing Wave 1 regression suite;
- repeat native Windows PowerShell 5.1 qualification if accepted runtime code changes;
- avoid FormatDetection, RegionDetection, or broader discovery redesign.

The `Archive/2019` discovery rule should be handled as a separate decision/task unless the defect-resolution analysis proves it is inseparable.

After root-level dossier handling is resolved, build and freeze the SD-044+ dossier-diversity wave.

## Final planning verdict

**READY for the next bounded defect-resolution task.**

**NOT READY for FormatDetection implementation.**

**NOT READY for RegionDetection implementation.**
