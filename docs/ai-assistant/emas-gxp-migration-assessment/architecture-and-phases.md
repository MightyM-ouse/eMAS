# eMAS Architecture and Phase Details

## High-Level Data Flow
```
Internal Mapping Workbook (XLSM)
        ↓ Validate + Export (VBA)
One Runtime JSON (eMAS_Runtime_Config.json)
        ↓
   +----+----+----+
   |    |    |    |
Pre-Sales   Pre-Migration   Post-Migration
(CLI)       (CLI or WPF)    (CLI or WPF)
   |         |               |
   +---------+---------------+
             ↓
   Shared PowerShell Engine
   (modular: discovery, classification, validation,
    RAG/effort, readiness, reconciliation, reporting, logging)
             ↓
   Phase-specific Excel Report + Timestamped Log
             ↓
   Draft → Reviewed → Project Evidence Archive
```

**Key architectural principle**: Single source of truth (the JSON) + shared engine + phase-specific orchestration. This ensures consistency while allowing different depths of analysis.

## The Three Phases

### 1. Pre-Sales Assessment (Lightweight Scoping)
- **Purpose**: Early estimation and clarification during sales/pre-project phase.
- **Execution**: Command-line only (designed for lightweight customer self-execution).
- **Inputs**: Minimal (source paths/storage info).
- **Processing**:
  - Lightweight discovery of dossiers/sequences.
  - Volume, region, format, dossier type analysis.
  - High-level folder RAG (Red/Amber/Green) assessment.
  - Effort driver estimation and confidence scoring.
- **Outputs**:
  - Complexity rating (Very Low to Very High).
  - Confidence level (High to Unknown).
  - Clarification requests / assumptions.
- **Characteristics**: Fast, low customer burden, feeds into proposal/scoping.

### 2. Pre-Migration Readiness Assessment
- **Purpose**: Detailed technical assessment of source data readiness before migration begins. Produces a baseline for later comparison.
- **Execution**: Command-line **or** optional portable WPF UI.
- **Inputs**: Source/backup/storage paths, more detailed configuration.
- **Processing** (deeper than pre-sales):
  - Detailed discovery and enumeration.
  - Validation of dossiers and sequences.
  - Checks for mandatory files, XML integrity, path issues, zero-byte files.
  - Access/backup/staging/storage verification.
  - Cleanup action generation.
  - Exception handling and readiness determination.
- **Outputs**:
  - Readiness status: **Ready**, **Ready with Exceptions**, or **Blocked**.
  - Baseline data (stored for post-migration comparison).
- **Characteristics**: GxP-oriented, produces auditable evidence of source state.

### 3. Post-Migration Reconciliation
- **Purpose**: Verify that the migration outcome matches expectations by comparing against the pre-migration baseline.
- **Execution**: Command-line **or** optional portable WPF UI.
- **Inputs**: Pre-migration baseline + post-migration evidence (e.g., MigrationSummary workbook or import logs).
- **Processing**:
  - Load baseline and post-import verification data.
  - Compare expected vs. actually migrated dossiers/sequences.
  - Identify discrepancies.
  - Apply exceptions.
  - Generate discrepancy report.
- **Outputs**:
  - Reconciliation status: **Reconciled**, **Reconciled with Exceptions**, **Review Required**, or **Not Reconciled**.
- **Characteristics**: Closes the loop with evidence of migration success/failure points.

## Shared PowerShell Engine
The engine is deliberately **shared** across all phases. It contains reusable modules for:
- Configuration loading and validation (from JSON)
- File system discovery / enumeration
- Classification and rule application
- Validation checks
- RAG status and effort calculation
- Readiness and reconciliation logic
- Report generation (populating controlled Excel templates)
- Detailed logging

Phase-specific scripts orchestrate which modules are used and how deeply.

## Design Decisions & Rationale
- **Why a single JSON?** Ensures all phases work from identical business rules. Avoids configuration drift.
- **Why PowerShell never touches the XLSM?** Separation of concerns + reduced risk. Mapping authors work in Excel; execution uses a clean, validated artifact.
- **Why optional WPF?** Provides a more user-friendly interface for complex pre/post phases while keeping the core logic in reusable PowerShell scripts (no duplication).
- **Why controlled reports + logs?** Supports GxP evidence requirements and creates a clear audit trail without needing a central database.
- **Read-only operation**: Critical for regulated environments — assessment must not alter source data.

## Evidence and Review Workflow
Every execution generates:
- Timestamped UTF-8 execution log (with execution ID, versions, inputs, checks performed, warnings, final result).
- Phase-specific Excel report (fixed structure + branding).
Reports start as **Draft**, move to **Reviewed** after manual consultant review, then are archived with logs in the project evidence folder.

This design supports ALCOA+ principles while remaining practical for migration projects.