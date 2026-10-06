# Claude Launch — MS-04 Unified Identification Rules

Work on task:

`EMAS-MS04-IDENTIFICATION-RULES`

Repository:

`MightyM-ouse/eMAS`

Base your work on:

`coordination/emas-ms04-identification-rules`

Read first:

- `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/BASELINE_CHANGES.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/TASK.md`
- `docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/STATUS.md`

Then review current accepted implementation and reports for:

- RepositoryDiscovery B3;
- eCTD v4 physical RepositoryDiscovery;
- BackboneXmlInventory;
- ClassificationEvidenceCollection;
- accepted Wave1/Wave1D/Wave1E expectations;
- existing eMAS regulatory/technical guide and mapping material.

Important recent baseline:

`demo/end-to-end-mvp @ 401d99cbe0afbfeb12ffe4dbf5650cb149a1f529`

The v4 physical discovery implementation is merged. Treat BASELINE_CHANGES.md as mandatory handover context.

This is a **research/design task only**.

Do not modify runtime code, tests, fixtures, contracts, FormatDetection, RegionDetection, BackboneXmlInventory or ReferenceResolution.

Use official authoritative regulatory sources for normative rules. Distinguish regulatory requirements from eMAS design decisions.

Use branch:

`analysis/emas-ms04-identification-rules`

Open a draft PR into:

`coordination/emas-ms04-identification-rules`

Do not merge.

Return only:

- branch
- commit SHA
- draft PR number/link
- report path
- recommended identification architecture
- proposed controlled vocabularies for TechnicalFormat / Region / SpecificationProfile / DossierContext
- confidence model
- key precedence rule in one sentence
- whether v4 structured XML inventory is required before implementation
- proposed implementation task sequence
- unresolved decisions/blockers
