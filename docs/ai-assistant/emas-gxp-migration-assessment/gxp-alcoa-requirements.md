# GxP, ALCOA+ and Compliance Aspects in eMAS

eMAS is explicitly designed with **GxP orientation** in mind, particularly for pre-migration and post-migration phases (pre-sales is treated as non-GxP estimation support).

## GxP Orientation
- Pre- and post-migration phases are considered **GxP-controlled**.
- Full traceability is maintained from business requirement → mapping rule → JSON → script execution → findings → report → review.
- Stable identifiers are used throughout:
  - Requirements (e.g., REQ-PS-001)
  - Rules (e.g., RULE-REG-EU-001)
  - Executions (e.g., EXEC-20260711-001)
  - Findings and exceptions

## ALCOA+ Principles
The framework supports **ALCOA+** data integrity expectations:

- **Attributable**: Every execution records user, machine, execution ID, script/JSON versions, and reviewer.
- **Legible**: Structured Excel reports + UTF-8 logs.
- **Contemporaneous**: Timestamped logs and reports created at time of execution.
- **Original**: Assessment works on original source data in a read-only manner.
- **Accurate**: Rule-based classification and validation; findings tagged as Observed, Calculated, Provided, Assumed, or Not Assessed.
- **Complete, Consistent, Enduring, Available**: All evidence (reports + logs) retained in controlled project evidence folders/archives. No central database is required.

Findings and exceptions are explicitly tracked and applied consistently across phases.

## Key Non-Functional Requirements
- **Read-only operation** — No modification, deletion, or movement of source files/folders/data.
- **Portability** — Minimal dependencies (Windows PowerShell 5.1 baseline). No Excel, database, or external modules required at runtime.
- **Security & Privacy**:
  - No credential storage.
  - No internet access required.
  - No external data transmission.
  - Least privilege principle.
- **Performance**: Designed to handle large repositories using streaming/enumeration where possible. Progress feedback provided.
- **Deployment model**:
  - Internal release package.
  - Customer pre-sales package is lightweight and self-contained (scripts + JSON + template + launcher + instructions). It deliberately excludes the mapping workbook and full UI.

## Evidence Retention Model
- No central audit trail repository or database.
- All evidence lives in **controlled project folders**.
- Reports and logs are archived together after review.
- This approach keeps the tool simple while still meeting traceability needs for regulated migrations.

## What eMAS Explicitly Does NOT Do
- Perform the migration itself.
- Conduct regulatory validation.
- Perform formal customer validation.
- Support electronic signatures/approval workflows.
- Replace the need for proper change control, validation protocols, or SOPs around the actual migration project.

It **provides structured, reproducible assessment evidence** that supports those activities.

## Practical Implications for Users of This Skill
When helping design or extend similar tools:
- Prioritize clear separation between configuration authoring (Excel) and execution (JSON + engine).
- Build strong logging and version tracking into every run.
- Design reports with fixed structures that support manual review workflows.
- Tag outputs clearly (e.g., readiness status, reconciliation status) so they can be used in downstream GxP processes.
- Keep the tool focused on **assessment and evidence** rather than trying to become a full migration or validation platform.

This balance of rigor and practicality is one of the strengths of the eMAS design.