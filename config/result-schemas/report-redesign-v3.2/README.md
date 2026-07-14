# eMAS Report Redesign v3.2 Result Schemas

These schemas define the normalized phase-result collections required by the controlled report templates and technical template maps aligned on `requirements/report-redesign-v3.2`.

- `pre-sales.result.schema.json`
- `pre-migration.result.schema.json`
- `post-migration.result.schema.json`

They do not replace `config/schema/eMAS-runtime-config.schema.json`. The runtime configuration schema controls the shared immutable mapping JSON; these schemas control normalized phase outputs supplied to the report writer.

## Key boundaries

- Pre-Sales supports the five approved assessment modes, current-system-only customer collection and aggregate-only direct-copy evidence.
- Pre-Migration requires the dossier/sequence baseline, file-type breakdown and baseline integrity collections.
- Post-Migration requires baseline/import/database/post-import comparison collections and all three raw evidence collections.
- Business interpretation remains in the controlled runtime JSON; the result schemas and report-template maps do not define RAG, readiness, reconciliation or effort logic.
