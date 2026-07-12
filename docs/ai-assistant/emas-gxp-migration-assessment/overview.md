# eMAS Overview and Positioning

**eMAS** stands for **eCTD Migration Assessment Script**.

It is a **read-only, mapping-driven migration assessment framework** designed to support three distinct phases of migration work in regulated pharmaceutical environments (particularly eCTD-related systems and submissions):

1. **Pre-sales migration scoping**
2. **Pre-migration readiness assessment**
3. **Post-migration reconciliation**

## Core Purpose
- Provide structured, GxP-oriented, traceable assessment evidence.
- Support early estimation and customer clarification (pre-sales).
- Assess source data readiness before migration.
- Verify that migration outcomes match expectations after the fact.

**Important limitations (explicitly stated in the project):**
- eMAS does **not** perform the actual migration.
- It does **not** perform regulatory validation.
- It does **not** support formal customer validation or electronic approval (no e-signing).

It produces controlled evidence that can be reviewed and archived as part of project documentation.

## Key Design Highlights
- Business and regulatory rules are maintained in an internal **Excel .xlsm mapping workbook**.
- The workbook includes validation macros and directly exports **one runtime JSON file**.
- PowerShell **never reads the mapping workbook** and does not create the JSON.
- The **same JSON** is used across all three phases.
- Each phase defines its own inputs, checks, assessment depth, decision logic, and report structure.
- All phases support **command-line execution**.
- Pre-migration and post-migration phases optionally support a **portable WPF interface** (which delegates to the same PowerShell logic).
- Every execution produces:
  - A phase-specific controlled **Excel report** (with branding, e.g., EXTEDO).
  - A detailed **timestamped execution log**.
- Reports follow a workflow: **Draft → Reviewed → Project Evidence Archive**.
- Logs are included in the evidence archive.

## Branding / Origin
Developed with branding for **EXTEDO | a cormeo brand** — a company specializing in regulatory information management and eCTD solutions.

## Intended Users / Context
Primarily for consultants, migration specialists, and IT teams working on eCTD system migrations or similar regulated content migrations in pharma, where traceability, auditability, and controlled evidence are required.

This framework exemplifies professional-grade tooling for the "assessment layer" of regulated system migrations.