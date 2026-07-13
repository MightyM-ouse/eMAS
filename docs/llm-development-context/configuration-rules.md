# Configuration and Rules

**Status:** Effective development context  
**Canonical sources:**

- `docs/governance/00_authority_and_precedence.md`
- `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`

## Excel mapping workbook

- The reviewed internal XLSM is the authoring source of truth for business and regulatory configuration.
- It uses controlled values, normalized relationship tables, validation macros, JSON preview and export history.
- It directly exports one UTF-8 runtime JSON file.
- PowerShell never reads the XLSM and never creates or repairs the JSON.

## Runtime JSON

- The validated immutable JSON is the runtime source of truth for all three phases.
- The execution source is the exact JSON version and checksum loaded for a run.
- The JSON uses the approved normalized contract and contains configuration metadata, controlled values, catalogues, master data, relationships, rules, phases, conditions, outputs, findings, recommendations, exception policies, aliases and report terminology.
- The JSON defines shared interpretation, not the complete workflow of each phase.

## Mandatory modelling rules

- Keep rule identity, lifecycle, phase assignments, conditions, outputs, findings and recommendations separate.
- Keep evaluation status separate from RAG.
- Use lifecycle and effective dates; do not use editable `IsActive` as the primary control.
- Accepted exceptions never erase original findings or evidence.
- Use lower-inclusive and upper-exclusive threshold bands by default.
- Use the approved hybrid effort model.
- Maintain referential integrity across all master-data and rule relationships.
- Treat ASMF as procedure context, not a technical format.
- Classify technical standard and regional implementation independently.

## Development rules

- All business/regulatory rule changes follow XLSM → validation → JSON export.
- Do not manually edit controlled JSON.
- Do not embed executable VBA, PowerShell or arbitrary expression text in workbook cells.
- Stop when required canonical sources conflict or when the configuration cannot represent the requested behaviour.