# eMAS Core Engine Boundary

This folder is the shared engine core. Files here must parse under Windows PowerShell 5.1 and PowerShell 7.6.

The current implementation contains configuration-contract metadata, a controlled EvaluationStatus helper and the phase-neutral Runtime JSON consumption/validation foundation. Final-schema reconciliation, complete release/package integrity validation and the wider engine behavior listed below remain pending.

Allowed content:

- immutable runtime JSON loading and defensive validation;
- shared evidence, rule, finding, recommendation, effort, readiness, reconciliation, reporting-contract and logging logic;
- version, checksum and compatibility checks;
- stable object contracts used by all phases.

Prohibited content:

- PowerShell 7-only syntax or APIs;
- WPF;
- phase-specific runtime launch assumptions;
- duplicated business or regulatory interpretation in adapter-specific code;
- XLSM reading, JSON generation, JSON repair or customer source mutation.
