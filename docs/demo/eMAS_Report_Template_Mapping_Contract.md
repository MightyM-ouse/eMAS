# eMAS Report Template Mapping Contract

**Status:** Draft technical contract for demo/implementation use
**Owner:** Technical Architect
**Related:** GitHub Issue #12; `docs/implementation/TEMPLATE_VALIDATION_REPORT.md`; `docs/architecture/eMAS_Solution_Architecture.md` §9; PowerShell Runtime Profile v1.0
**Files defined by this contract:**

- `config/report-mappings/report-template-map.schema.json`
- `config/report-mappings/pre-sales.template-map.json`
- `config/report-mappings/pre-migration.template-map.json`
- `config/report-mappings/post-migration.template-map.json`

## 1. Purpose

The Reporting/OpenXML module (Solution Architecture §4) must populate the three finalized controlled templates without requiring Microsoft Excel on the execution host, and must not change template meaning or omit required metadata. To do that, it needs an exact, machine-checkable answer to one narrow question per template:

> *For each field the shared PowerShell engine has already computed, which worksheet, which Excel Table, and which table column does it write into — and how (append a new row, update an existing labeled row, or leave the table alone)?*

The three `*.template-map.json` files answer exactly that question, one per phase, against the exact finalized workbook committed in this branch. `report-template-map.schema.json` is the shared shape all three conform to, so tooling can validate any of them the same way.

These files are a **write-location contract**, not a second copy of the business logic. They say *where* a value lands and *how* the write mechanically happens; they never say *what value a field should have* or *why*.

## 2. Runtime business JSON vs. template-mapping JSON

These are two different JSON artifacts with two different jobs, and this contract only concerns the second one:

| | Runtime business JSON (`eMAS_Runtime_Config.json`) | Template-mapping JSON (this contract) |
|---|---|---|
| Governed by | Runtime JSON Contract v1.2, Normalized Rule Model, Runtime JSON Schema 1.0.0 | This contract only; no independent schema-version compatibility claim over runtime content |
| Produced by | The internal XLSM's controlled VBA export | Authored directly against the finalized XLSX templates (this change) |
| Contains | Rules, conditions, outputs, findings, recommendations, policies, value lists, classification/effort/RAG/decision logic | Sheet names, Table names, column names, write mode, row capacity, number formats |
| Consumed by | The shared engine's rule evaluator, classification, effort, readiness and reconciliation modules | The Reporting/OpenXML module only, at the point it writes a normalized result object into the template |
| Changing it | Requires an approved decision, SME review and schema-version assessment | Requires re-authoring against the finalized template if the template's tables/columns change; does not itself alter business meaning |

A PowerShell engine run therefore touches **three** JSON-shaped things, never confusing one for another:

1. the runtime business JSON it loads to know **what the rules and controlled values are**;
2. the **normalized result objects** it computes in memory during evaluation (executionMetadata, findings, dossierInventory, etc. — one array or object per source collection named in the mapping files);
3. this **template-mapping JSON**, read once per phase to know where those result objects physically land in the controlled template.

The mapping files never restate an approved controlled value list's members (e.g. they name `"controlledValueList": "EvaluationStatus"` but never enumerate `Evaluated, NotAssessed, ...`); the list itself, and what a `Warning` means, is owned entirely by the Controlled Terminology and the runtime contract.

## 3. Normalized result object expectations

Each `tableMappings[].sourceCollection` names a normalized collection the engine is expected to hold in memory by the time it reaches the reporting step. Collections are either:

- an **array of objects**, one object per row to write (e.g. `findings`, `dossierInventory`) — used with `writeMode: "appendRows"`;
- an array of objects matched against **pre-authored template rows by label** (e.g. `summaryMetrics` matched by `Area`+`Metric`, `assumptions` matched by `Section`+`Item`) — used with `writeMode: "matchRowByLabelColumns"`;
- a **single object** representing the one decision/scope-summary made per execution (e.g. `readinessDecision`) — used with `writeMode: "singleRowUpdate"`;
- raw, already-produced external rows carried through unchanged (`rawImportReportDetail`, `rawPostImportVerification`) — used with `writeMode: "copyFromExternalSourceAppendOnly"`.

Each column entry's `sourceField` is the dot-path property name expected on that in-memory object (camelCase, e.g. `findingId`, `dossierPath`). A `null` `sourceField` marks a column that is pre-authored template text the engine only *reads* (to locate a labeled row), never writes.

Two collections are common to all three phases and are expected on every execution regardless of phase: `executionMetadata` (run/version/configuration identity) and `reviewMetadata` (the four consultant-completed Review fields). Both feed the *same* physical `tblXExecution` table, split by row label — they are not two separate tables.

Two collections were added beyond the phase's originally-listed baseline because a table exists in the finalized workbook and needs a source: `recommendations` (Pre-Sales) and `actions` (Pre-Migration and Post-Migration both have an Actions table; Pre-Migration's was in the original required list, Post-Migration's was not but needed the same treatment). This is called out explicitly in each affected `tableMappings[].notes` field rather than silently added.

## 4. Write modes

| `writeMode` | Meaning | Used for |
|---|---|---|
| `appendRows` | One new Excel Table row per array element, in array order | Findings, dossiers, sequences, checks, discrepancies, exceptions, exclusions, actions, recommendations, and similar per-record tables |
| `matchRowByLabelColumns` | Locate an existing row by its `labelColumns` values (e.g. Area+Metric), then write the remaining columns into that row in place | Summary, Assumptions, Execution/Review tables — all pre-authored with a fixed or partially-fixed row set |
| `singleRowUpdate` | Exactly one row exists and is always updated, never appended to | Pre-Migration's readiness Decision table (one decision per execution) |
| `copyFromExternalSourceAppendOnly` | Rows are copied verbatim from an already-produced external file; no field transformation | Post-Migration's two raw evidence sheets only |
| `staticReleaseManaged` | The reporting engine never writes this table at runtime | Every workbook's Template Control table |

`allowAppendAdditionalRows` (only meaningful for `matchRowByLabelColumns`) is `true` only for the Assumptions tables, which explicitly invite project-specific rows beyond their standard boundary statements; it is `false` everywhere else, including Summary and Execution/Review, whose row sets are fixed by template design.

### Row-insertion mechanics (not business logic)

Five tables in these templates share a worksheet with a second table positioned a fixed 5 rows below (EffortDrivers→Recommendations, Findings→Clarifications, Findings→Actions, Exceptions→Exclusions, Discrepancies→Actions). Each such table's `rowCapacity.rowInsertionBehavior` is `insertAndShiftFollowingTable`: if the engine has more result rows than the pre-provisioned capacity (5), it must perform a genuine OpenXML row insertion — expanding the first table's own `ref`, shifting the second table's `ref` and data down by the same row count, and updating any dependent data-validation/conditional-formatting ranges — before appending further rows. This is exactly the same operation Excel performs natively when a user types into the row directly below a Table; it is a technical write mechanic, stated here because the engine must reproduce it programmatically without Excel, not because it encodes any business meaning about *how many* findings, effort drivers, exceptions or discrepancies are meaningful.

Every other `appendRows` table is alone or last on its sheet (`rowInsertionBehavior: appendWithinPreProvisionedRange`) and can simply grow up to `maxPreProvisionedRows` (typically 500–1000, matching the template's own data-validation extent) with no coordination required.

## 5. Template protection rules

Every mapping file's `protectedTables` array lists tables the reporting engine must not treat as an ordinary append target:

- **`readOnly`** — the workbook's Template Control table in all three phases. It carries release-managed identity/version/status metadata (`TemplateId`, `TemplateVersion`, `PhaseCode`, `Status`, `ChangeSummary`, `RequiredSheetNames`, `RequiredTableNames`) set only when the template itself is authored or released. The engine may *read* `TemplateVersion`/`RequiredTableNames` from it to verify compatibility before writing, but must never write to it.
- **`appendOnly`** with **`preserveHeadersExactly: true`** — Post-Migration's two raw evidence sheets (`Import Report Detail`, `Post Import Verification`) only. Rows may only be appended or copied verbatim from the external source; existing rows must never be edited, reordered or deleted, and column headers — including the literal `Source.Name` header and the preserved historical spelling `DossierDirecotry` — must never be renamed, reordered or "corrected" by any tooling, formatter or spell-checker.

Every actual Excel Table in all three workbooks is accounted for by exactly one `tableMappings` entry or `protectedTables` entry — this is enforced by `build/validate_report_mappings.py` (no orphaned table, and no table silently skipped).

## 6. Validation performed

`build/validate_report_mappings.py` (requires the `jsonschema` package; degrades gracefully with a warning if unavailable) checks, for each of the three mapping files:

- the file is valid JSON;
- it validates against `report-template-map.schema.json` (itself a valid Draft 2020-12 schema);
- `template.templateVersion` equals the `TemplateVersion` recorded in the actual finalized workbook's Template Control table (**1.1.1** in all three, confirmed);
- `requiredSheetOrder` matches the workbook's actual worksheet order exactly;
- every `tableMappings`/`protectedTables` `sheetName`+`tableName` pair exists in the workbook;
- every mapped `targetColumn` exists in that Excel Table, and every actual Excel Table column is covered by the mapping (no gaps, no typos, no wrong-table target);
- no duplicate `targetColumn` mapping within one table (unless the schema's `additionalSourceCollections` mechanism explicitly documents a shared table, as with Execution/Review);
- every actual Excel Table on every sheet is covered by exactly one mapping or protection entry.

All three files pass every check as committed.

## 7. Known demo limitations

- **No PowerShell reporting-engine implementation exists yet.** This contract defines *where* the engine must write; it does not itself implement the OpenXML writer, the row-insertion-and-shift mechanic described in §4, or the normalized-result-object construction. That is separate implementation work (Solution Architecture §4, Reporting/OpenXML module; WS-4 in the runtime-profile work package).
- **Row-insertion-and-shift is documented, not exercised.** No automated test currently drives more than 5 rows through `tblPreSalesEffortDrivers`, `tblPreSalesFindings`, `tblPreMigrationFindings`, `tblPreMigrationExceptions` or `tblPostMigrationDiscrepancies` to prove the shift mechanic end-to-end; it is a structural fact about the finalized templates, verified by inspection, not by execution.
- **`format` values are number-format codes already present in the finalized templates**, restated here for engine reference; they were not independently re-verified for every numeric column in every table (only the date/datetime columns, `SizeBytes`/`DisplaySizeGB`-style columns, and the `Generated At UTC` columns were directly confirmed against the workbook's `styles.xml`). A column without a stated `format` should be treated as using the template's existing default style for that cell, not as unformatted.
- **`controlledValueList` names are mapping-file conveniences**, not a second registry: several (e.g. `EffortConfidenceImpact`, `WorkflowStatus`, `ReconciliationRecordStatus`, `ExceptionStatus`, `SourceType`, `Unit`) are read directly off each column's existing data-validation dropdown in the finalized template rather than from a previously-named catalogue entry; they should be cross-checked against the eventual Value_Lists / Field_Catalogue synchronization work (Approved Decision Baseline §"Approved amendment implementation gate") before being treated as stable identifiers outside this mapping.
- **No customer data, sample values or fixtures are included.** This is a structural, schema-level contract only.
- This document and the JSON files it describes have not been reviewed or approved by the Product Owner or QA Lead; per the repository's change-authority matrix, template and report-contract changes require that review before being treated as effective.
