# Mapping Workbook MVP Implementation Baseline v0.1

**Status:** Draft for workbook content review
**Authority:** CFG-MVP v4.4 on `requirements/mvp-workbook-json`

## POC-to-MVP gap and approach

The existing POC is a synthetic 43-table XLSM/VBA export experiment. It does not
represent the approved eight-scenario catalogue, the 28-sheet workbook contract,
the fifteen bounded modules, the 360 scenario/phase/module decisions, or the
atomic requirement ledger. Its schema and semantic fixture checks remain intact
as regression tests, but its table names and VBA export are not reused as an
authority for the MVP.

The MVP generator reads the approved v4.4 catalogue tables from the source-
controlled requirements and normalizes them in `build/emas_mvp_model.py`. The
model holds stable row identifiers, 55 explicitly sourced atomic requirement
seeds across all 24 mandatory families, 25 field definitions, four approved
approximate PreSales metrics, and controlled values. `build/generate_emas_mapping_workbook.py`
creates the macro-free XLSX; `build/emas_mvp_validation.py` checks the source
model; `build/validate_emas_mapping_workbook.py` opens and checks the saved file.

## Populated versus review-pending content

Approved/reusable baseline content is populated in sheets `01` through `07`,
`13`, `22`, and `23`. `25_JSON_Field_Map` is populated from the maintained
`config/authoring/mvp/json-field-map.json` with explicit column-level lineage.
The required sheets `08` through `12` and `14` through `21` contain final
v4.4 headers, filterable Excel Tables, and controlled-value entry constraints,
but no active detailed regulatory, source-adapter, threshold, readiness, or
reconciliation rule rows. These require the planned sheet-by-sheet SME review.
Sheets `24`, `26`, and `27` are generated review views.

The requirement-family table in CFG-MVP defines minimum coverage topics, not a
fully decomposed atomic source-statement ledger. The 55 seed rows are traceable
to v4.4 sections, but the approved enterprise and retained lower-level source
statements have not each been marked Covered, Deferred, or Superseded. The
validator therefore emits `SOURCE_OBLIGATION_RECONCILIATION_PENDING` as a
blocking result. The workbook is usable for review; it is not eligible for
active Runtime JSON export or production assessment.

One structural ambiguity remains for `07_Fields_Evidence`: v4.4 calls
`AllowedOperator` a relationship and asks for one row per operator or a child
table, while also requiring each `FieldCode` to be unique and exactly 28 sheets.
This baseline stores one primary allowed operator per field and validates
operators against the controlled list. The multi-operator relationship design
needs confirmation during the Fields/Evidence review; no comma-separated
operator list has been introduced.

## Next content review

Begin with `08_Regulatory_Profiles`. Confirm independent region, authority,
technical format, specification version, application and dossier dimensions,
then add exact source citations and parser profiles. Only approved rows should
become active. Continue through the review sequence in CFG-MVP §18, then complete
the source-obligation disposition ledger and scenario JSON/schema work.
