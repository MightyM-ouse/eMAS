# Core Design

## Fundamental Architecture
- Business + regulatory rules live in internal Excel .xlsm workbook (with VBA validation).
- Workbook exports one runtime JSON (`eMAS_Runtime_Config.json`).
- PowerShell engine **never** reads the .xlsm directly.
- Same JSON drives all three phases.
- Shared PowerShell engine with phase-specific orchestration.

## Key Design Principles
- Single source of truth (JSON)
- Separation of mapping (Excel) and execution (JSON + PowerShell)
- Read-only operation
- Controlled evidence (Draft → Reviewed → Archive)
- Portability and minimal dependencies

## Why This Matters for Development
Any change to rules, classification logic, or reporting must respect the JSON contract and shared engine. Do not suggest direct Excel access from PowerShell or per-phase configuration files.