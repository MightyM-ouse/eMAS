# MVP workbook authoring source

`json-field-map.json` is the maintained, source-controlled definition for
`25_JSON_Field_Map`. Each `MappingId` identifies one workbook-column to JSON
property mapping and names the exact Excel **Table**, not merely the worksheet,
so the transformer never resolves a record by worksheet row position.

Regenerate it after a contract change, then rebuild and inspect the workbook:

```bash
python build/emas_mvp_json_map.py --write
python build/generate_emas_mapping_workbook.py --force
python build/validate_emas_mapping_workbook.py
```

The current 495 rows are a **draft v0.2 lineage baseline for CFG-MVP v4.7**, not
an approved Runtime JSON export contract. They include proposed mappings for
sheets still awaiting detailed content review. `GroupConditions` marks the atomic
condition columns that are grouped back into one rule object, `NestChildTable`
marks profile evidence locators that project as a nested array, and
`SplitListCode` marks controlled-domain references that expand into their active
runtime entries.

Do not insert executable expressions or customer-specific values here.
