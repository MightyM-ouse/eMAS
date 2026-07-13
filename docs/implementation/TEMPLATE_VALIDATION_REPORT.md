# Controlled Template Validation Report

**Scope:** `eMAS_PreSales_Template.xlsx`, `eMAS_PreMigration_Template.xlsx`, `eMAS_PostMigration_Template.xlsx`
**Template version after this pass:** 1.1.1 (patch bump from 1.1.0)
**Decision references:** `DEC-2026-07-13-PS-RUNTIME`, `DEC-2026-07-13-EVAL-WARNING`
**Related issue:** GitHub Issue #12
**Environment:** macOS, PowerShell/Excel not available; LibreOffice 26.2.4 installed for round-trip testing
**Status:** Development/QA evidence. Native Microsoft Excel desktop qualification is a **pending release gate**, not claimed as passed here (Windows-only per the approved runtime profile).

## 1. What changed in this pass (v1.1.0 → v1.1.1)

All three templates were corrected at the OOXML package level (direct XML editing, not a full regeneration), so every untouched byte — sheet names, table names, table ranges, column order, wording, `DossierDirecotry` spelling — is preserved exactly.

### 1.1 Cross-table data-validation and conditional-formatting contamination (removed)

On every sheet where two Excel Tables share one worksheet with a small row gap between them (e.g. `EffortDrivers`+`Recommendations`, `Findings`+`Clarifications`, `Findings`+`Actions`, `Exceptions`+`Exclusions`, `Discrepancies`+`Actions`), the first table's list-validation and RAG-color conditional-formatting ranges ran to row 500/1000 and geometrically overlapped the second table's columns. Ranges were trimmed to stop one row before the neighboring table's header row, eliminating every case where a validation or conditional-formatting rule reached a different table.

Representative examples fixed:
- Pre-Sales `02_Scope_&_Effort`: `RAG` dropdown (col J) no longer reaches `tblPreSalesRecommendations.BeforeFinalEstimate`.
- Pre-Sales `05_Findings_&_Clarifications`: `EvaluationStatus`/`RAG`/`ValueSource`/`Confidence` dropdowns (Findings) no longer reach `tblPreSalesClarifications`.
- Pre-Migration `07_Findings_&_Actions` and `08_Exceptions_&_Exclusions`: same pattern, including the RAG conditional-formatting color rule.
- Post-Migration `08_Discrepancies_&_Actions`: `ValueSource` dropdown (col L) no longer reaches `tblPostMigrationActions.Comments`; `Priority` dropdown (col B) no longer reaches `tblPostMigrationActions.DiscrepancyId`.

Single-table sheets that merely overshot their own table's row range into blank space before an unrelated (non-overlapping-column) table further down were also trimmed to the table's own body for tidiness (no functional change, since those never overlapped another table's columns).

Verified: an automated overlap scan (row+column intersection against every Table's declared `ref`) finds **zero** ranges touching more than one table, in all three workbooks, after the fix (zero before the fix found 8–9 contaminating ranges per workbook).

### 1.2 Stop-style validation alerts (enabled)

Every data validation in all three templates is `type="list"` (controlled dropdowns). Before this pass:
- Pre-Sales (natively Excel-authored) omitted `showErrorMessage` entirely, which Excel treats as "no alert" — invalid manually-typed values were silently accepted.
- Pre-Migration and Post-Migration explicitly set `showErrorMessage="0"` — alerts were explicitly disabled.

All list validations in all three workbooks now carry `showErrorMessage="1" errorStyle="stop"`, so a manually-typed value outside the approved controlled list is rejected with a Stop alert. Two validations per workbook-pair that existed but had no `promptTitle`/`errorTitle`/`error` at all (`OriginalEvaluationStatus` and `ExceptionEffect` in Pre-Migration; `OriginalEvaluationStatus` and `AcceptedEffect` in Post-Migration) were completed with the same messaging convention used by every sibling validation.

### 1.3 Template-version metadata (synchronized)

Each workbook had **two** disagreeing "TemplateVersion" cells (a quick-reference cell showing `1.0.0` and the Template Control table showing `1.1.0`). Both are now `1.1.1` in all three workbooks, and each `ChangeSummary` cell documents this round's changes.

### 1.4 Review-field `ValueSource` provenance (corrected)

`ReportStatus`, `ReviewedBy`, `ReviewDate` and `ReviewComments` are internal/consultant-entered fields but were hardcoded to `CustomerProvided` (implying the customer supplied them). Per the Controlled Terminology guidance that consultant-entered values must use an existing governed source type rather than an invented one, these four cells now use `Observed` — the same value already used elsewhere in the same table for other execution-identity fields recorded by the person running the assessment. No new controlled value was introduced.

### 1.5 UTC date-time formatting (corrected and standardized)

- Pre-Sales and Post-Migration Executive Summary sheets had a "Generated At UTC" cell with **General** number format (no date styling at all), while the same field elsewhere in the same workbook was correctly formatted. Both now reuse the workbook's existing datetime style.
- Post-Migration's `11_Review_&_Execution` sheet had its own `GeneratedAtUTC` cell on a *different*, no-seconds datetime style than the one just fixed on the Executive Summary sheet — now unified to the same style.
- The underlying datetime format code is standardized to `yyyy-mm-dd hh:mm:ss` (seconds included) consistently across all three workbooks; the date-only code is standardized to `yyyy-mm-dd`. Pre-Sales' escaped format-code spelling (`yyyy\-mm\-dd`) was normalized to the same unescaped form used by the other two, with no display difference.

### 1.6 Local file path and personal author metadata (removed, Pre-Sales only)

`xl/workbook.xml` contained a Windows `x15ac:absPath` pointing at `C:\Users\CHakka\Downloads\files (2)\`, and `docProps/core.xml` contained `<cp:lastModifiedBy>Chakka, Vinay</cp:lastModifiedBy>`. Both were removed. Pre-Migration and Post-Migration (openpyxl-authored) never contained this residue.

### 1.7 Not touched (verified, no defect found)

- `DossierDirecotry` spelling in `Post Import Verification` — preserved exactly.
- All sheet names, table names, table `ref` ranges, and column order — byte-identical to the pre-correction files (diffed programmatically, see §3).
- No macros, no VBA project, no external links, no formula cells, no cached formula-error values — none existed before or after.
- No worksheet-level `AutoFilter` exists anywhere outside the Tables' own AutoFilter — nothing to conflict with, and none was introduced.
- Intended-use, limitation and non-validation wording on every sheet — untouched.

## 2. Files changed

| File | Change |
|---|---|
| `templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx` | Corrected per §1 |
| `templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx` | Corrected per §1 |
| `templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx` | Corrected per §1 |
| `build/validate_controlled_templates.py` | New validation tool (used to produce §3/§4) |
| `docs/implementation/TEMPLATE_VALIDATION_REPORT.md` | This report |

No schema, requirements, PowerShell, fixture or governance file was read for context only — none were modified.

## 3. Table and sheet inventory (unchanged by this pass)

| Workbook | Sheets | Tables |
|---|---:|---:|
| Pre-Sales | 8 | 11 |
| Pre-Migration | 10 | 13 |
| Post-Migration | 13 | 15 |

Verified programmatically identical (sheet names, table names, table `ref` ranges, and `tableColumn` name/order) between the pre-correction and post-correction files for all three workbooks.

## 4. Validations performed and results

Run via `python3 build/validate_controlled_templates.py`.

| Validation | Pre-Sales | Pre-Migration | Post-Migration |
|---|---|---|---|
| ZIP CRC integrity | PASS | PASS | PASS |
| XML well-formedness (every package part) | PASS | PASS | PASS |
| Relationship targets resolve | PASS | PASS | PASS |
| Table name uniqueness | PASS (11) | PASS (13) | PASS (15) |
| Table range validity / column-count match | PASS | PASS | PASS |
| Worksheet AutoFilter vs Table AutoFilter overlap | PASS (none exist) | PASS (none exist) | PASS (none exist) |
| Data-validation cross-table overlap | PASS (0 found) | PASS (0 found) | PASS (0 found) |
| Conditional-formatting cross-table overlap | PASS (0 found) | PASS (0 found) | PASS (0 found) |
| Stop-style alert on every `type="list"` validation | PASS | PASS | PASS |
| Macro / VBA project scan | PASS (none) | PASS (none) | PASS (none) |
| External-link scan | PASS (none) | PASS (none) | PASS (none) |
| Formula / cached formula-error scan | PASS (none) | PASS (none) | PASS (none) |
| Personal-path / author / customer-data scan | PASS (none) | PASS (none) | PASS (none) |
| LibreOffice 26.2.4 headless open/save round-trip | PASS | PASS | PASS |
| Sheets/tables preserved after round-trip | PASS (8/11) | PASS (10/13) | PASS (13/15) |

**Overall: PASS** for every automated macOS-available check.

## 5. SHA-256 (final, committed files)

```
896000d303bab73396160109ea37cf8bd496eab68aba4ca55aeae091bacb0a76  templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx
7c7b8a909e1a7b5834525070b0efbcd82ffc624c41215ab29a64f10b6b2fcac6  templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx
bbdbd638d5fe80e0ad821fc66d6ce2f602a84c381b3cb89d5bc27d6aa090cf0d  templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx
```

## 6. Remaining limitations / pending gates

- **Microsoft Excel desktop qualification is pending** (not performed, not claimed). Per `DEC-2026-07-13_Runtime_Profile_and_Warning.md` §2.6 and the PowerShell Runtime Profile, native Excel open/save/reopen-without-repair verification is a Windows-only release gate and remains outstanding.
- General (non-date) number formatting of the large pre-provisioned "growth reserve" row ranges (rows beyond each table's current sample row, up to 500/1000) is inconsistent in places (a formatted sample row followed by unformatted reserve rows for size/count columns). This is not a UTC/date-time defect and was left untouched; per the Solution Architecture, finalizing cell formatting for engine-appended rows is the Reporting/OpenXML module's responsibility at generation time, not a static template concern.
- `EffectiveDate`, `MinimumEngineVersion`, `SchemaVersion`, `MappingVersion` and `SourceWorkbookVersion` metadata fields remain intentionally blank — they are populated only at controlled release / by the runtime engine, per the Template Control section's own field descriptions.
- Template `Status` remains `Draft for Review` in all three workbooks; this pass does not change release/approval status.
