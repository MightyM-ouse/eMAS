# eMAS Design Patterns and Rationale

This reference captures the key architectural and process design patterns used in eMAS that are worth reusing or adapting in similar regulated migration assessment tools.

## 1. Mapping-Driven Configuration with Validated Export
**Pattern**: Author and validate complex business + regulatory rules in Excel (with VBA macros for validation, duplicate detection, controlled values, etc.), then export a clean, versioned runtime artifact (JSON).

**Why it works well**:
- Domain experts (who understand regulatory rules) can work comfortably in Excel.
- Validation happens at the point of authoring.
- Execution layer receives a clean, machine-readable contract (JSON) with metadata (version, timestamp, user, schema).
- Avoids the complexity and risk of having the execution engine interpret Excel directly.

**Reusable takeaway**: For rule-heavy assessment tools in regulated domains, Excel + validated export is often more practical and maintainable than pure code-based rule engines or low-code platforms.

## 2. Single Runtime Configuration Across All Phases
**Pattern**: One JSON file serves pre-sales, pre-migration, and post-migration.

**Benefits**:
- Guarantees consistent rule application.
- Simplifies maintenance (change a rule once).
- Enables comparison and traceability between phases (e.g., pre-migration baseline vs post-migration reconciliation uses the same rule set).

**Trade-off managed**: Phase-specific behavior is achieved through different orchestration scripts and depth of checks, not through different configurations.

## 3. Shared Engine + Phase-Specific Orchestration
**Pattern**: Core logic (discovery, classification, validation, reporting, logging) lives in reusable PowerShell modules. Thin phase-specific scripts control which modules run and with what parameters/inputs.

**Benefits**:
- Avoids code duplication.
- Ensures consistent behavior where it matters (e.g., same RAG logic, same logging format).
- Makes it easier to add new phases or assessment types in the future.

## 4. Portable UI That Delegates to Scripts
**Pattern**: Optional WPF interface for pre-migration and post-migration that collects inputs and invokes the same PowerShell scripts used by CLI. No duplicate business logic in the UI layer.

**Benefits**:
- Single source of truth for logic.
- CLI remains lightweight and automatable.
- UI can be added/updated without risking logic drift.
- Easier to support both technical users (CLI) and less technical users (WPF).

## 5. Controlled Evidence with Simple Workflow
**Pattern**: Every run produces timestamped logs + structured Excel reports. Reports have a simple status workflow (Draft → Reviewed) and are archived with logs in a project evidence folder. No complex document management system or e-signature required for the assessment tool itself.

**Why effective in GxP context**:
- Meets traceability needs without over-engineering.
- Keeps the tool focused and portable.
- Evidence is self-contained and easy to include in broader project validation packages.
- Manual review step provides the human accountability layer.

## 6. Explicit "What We Do Not Do" Boundaries
**Pattern**: Clearly document (in README, requirements, and positioning) what the tool deliberately does **not** cover:
- Actual migration execution
- Regulatory validation
- Formal customer validation / approval
- e-signing

**Value**: Prevents scope creep, manages expectations, and positions the tool correctly within the larger GxP ecosystem (it feeds evidence into those other processes rather than trying to replace them).

## 7. Customer vs Internal Packaging
**Pattern**: Different distribution packages for different audiences.
- Internal team: Full package (mapping workbook, full UI, configuration tools).
- Customer (pre-sales): Lightweight, self-contained package (scripts + JSON + report template + launcher + instructions). Deliberately excludes authoring tools.

**Benefit**: Reduces support burden and protects intellectual property in the mapping rules while still enabling customer self-service for scoping.

## Recommendations for Future / Similar Tools
- Consider adding AI augmentation **on top of** this architecture rather than replacing it (e.g., LLM assistance for rule authoring in the Excel workbook, intelligent analysis of logs/reports, automated suggestion of exceptions, or natural language interfaces to query assessment results).
- Maintain the strong separation between configuration and execution.
- Keep evidence generation and logging as first-class citizens.
- Design for both CLI automation and optional guided UI.

These patterns make eMAS a strong reference implementation for professional-grade, compliance-aware migration assessment tooling in regulated industries.