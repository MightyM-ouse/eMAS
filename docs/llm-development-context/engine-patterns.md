# Engine & Evidence Patterns

## Shared PowerShell Engine
- Modular design: discovery, classification, validation, RAG/effort, readiness, reconciliation, reporting, logging.
- Phase-specific scripts only orchestrate which modules run and at what depth.
- Reusable modules ensure consistent behavior across phases.

## Reporting & Logging
- Every run produces timestamped UTF-8 log + phase-specific controlled Excel report (fixed structure + branding).
- Report workflow: Draft → Reviewed → Project Evidence Archive.
- Logs must capture: Execution ID, versions, inputs, checks performed, warnings, final result.

## GxP / ALCOA+ Alignment
- All findings tagged (Observed / Calculated / Provided / Assumed / Not Assessed).
- Full traceability from rule → execution → evidence.
- Read-only operation on source data.