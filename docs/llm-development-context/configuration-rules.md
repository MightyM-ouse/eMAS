# Configuration & Rules

## Excel Mapping Workbook (.xlsm)
- Single source for all business and regulatory rules.
- Contains validation macros (duplicates, missing values, controlled lists).
- Directly exports one UTF-8 JSON file with metadata (version, timestamp, user, schema).

## Runtime JSON
- Contains: Classification rules, Folder rules, RAG rules, Effort drivers, Recommendations, Region/Format/Dossier type definitions.
- Must remain the single source of truth across all phases.

## Development Rules
- Never suggest PowerShell reading the .xlsm.
- All rule changes must go through the workbook → JSON export flow.
- Maintain referential integrity in master data relationships (Region ↔ Authority ↔ Format).