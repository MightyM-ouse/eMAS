# Core Design

**Status:** Effective development context  
**Canonical authority:** `docs/governance/00_authority_and_precedence.md`

## Fundamental architecture

- Business and regulatory rules are maintained in the reviewed internal Excel `.xlsm` workbook.
- The workbook validates the configuration and exports one runtime JSON file: `eMAS_Runtime_Config.json`.
- PowerShell never reads the `.xlsm` and never creates the runtime JSON.
- The same reviewed JSON is used by all three phases.
- Shared technical operations are implemented once in the PowerShell engine; phase entry scripts orchestrate phase-specific depth and workflow.

## Source terminology

- **Authoring source of truth:** reviewed internal XLSM.
- **Runtime source of truth:** validated immutable JSON exported from the approved XLSM.
- **Execution source:** exact JSON version and checksum loaded for an execution.

Do not call the JSON the only or universal source of truth without this qualification.

## Key design principles

- separation of rule authoring, runtime configuration and execution;
- read-only processing of source evidence;
- one runtime JSON shared across all phases;
- phase-specific inputs, checks, results and report templates;
- explicit rule, evidence, version and execution traceability;
- portability and minimal runtime dependencies;
- controlled report lifecycle from Draft to Reviewed and retained project evidence.

## Development impact

Any change to rules, classification, effort, confidence, RAG, decisions or report terminology must be represented in the approved configuration model and runtime JSON contract. Do not introduce direct Excel access, per-phase runtime configuration files or hardcoded business/regulatory interpretation in PowerShell.

Stop and record a conflict when a requested change contradicts a higher-authority approved source or changes regulatory interpretation, JSON compatibility, phase decision logic or report meaning.