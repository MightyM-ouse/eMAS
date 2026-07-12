# LLM Development Rules for eMAS

These rules are mandatory when generating code, configuration, or documentation for eMAS.

## Architecture Rules
- Respect single JSON source of truth.
- Never suggest PowerShell directly accessing the .xlsm workbook.
- Keep shared engine logic reusable across phases.

## Phase Rules
- Pre-Sales must remain lightweight.
- Pre-Migration must produce a usable baseline for Post-Migration.
- Post-Migration must compare against the Phase 2 baseline.

## Configuration Rules
- All business/regulatory rules go through Excel → validated JSON export.
- Maintain master data relationships (Region ↔ Authority ↔ Format).
- Use controlled values and validation from the existing workbook design.

## Evidence & GxP Rules
- Every execution must produce timestamped logs and controlled reports.
- Apply ALCOA+ principles (Attributable, Legible, Contemporaneous, etc.).
- Tag findings clearly (Observed / Calculated / Provided / Assumed).

## General Quality Rules
- Be consistent with existing patterns and naming.
- Prefer explicit, auditable logic over clever but opaque code.
- Keep changes minimal and well-justified.
- Production-ready means: testable, logged, evidenced, and aligned with GxP traceability.