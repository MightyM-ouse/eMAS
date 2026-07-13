# eMAS Windows PowerShell 5.1 Adapter Boundary

This folder contains technical adapters for Windows PowerShell 5.1.

Use this adapter for Pre-Sales Assessment on Windows. Adapter code may handle 5.1-specific filesystem, encoding, diagnostics and packaging details, but must call the shared core for configuration meaning and assessment interpretation.

Adapter code must not:

- introduce PowerShell 7 syntax;
- require Excel or WPF;
- duplicate business rules, regulatory mappings, RAG logic, effort logic, readiness logic or reconciliation logic;
- read the XLSM or generate runtime JSON.
