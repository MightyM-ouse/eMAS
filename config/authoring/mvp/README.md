# MVP workbook authoring source

`json-field-map.json` is the maintained, source-controlled definition for
`25_JSON_Field_Map`. Each `MappingId` identifies one workbook-column to JSON
property mapping. Edit it during workbook/JSON contract review, then run
`python build/generate_emas_mapping_workbook.py` and
`python build/validate_emas_mapping_workbook.py` from the repository root.

The initial 456 rows are a **draft v0.1 lineage baseline**, not an approved
Runtime JSON export contract. They include proposed mappings for sheets still
awaiting detailed content review. The generator blocks active Runtime JSON
until the requirement-source disposition and later sheet reviews are complete.
Do not insert executable expressions or customer-specific values here.
