# Configuration

This folder separates configuration authoring, reviewable VBA source, runtime schemas and exported runtime JSON.

```text
config/
├── authoring/   Internal XLSM mapping workbook
├── vba/         Exported .bas, .cls and .frm source
├── schema/      Runtime JSON contracts and compatibility metadata
├── runtime/     Controlled and development JSON exports
└── samples/     Synthetic configuration examples
```

Rules:

- The XLSM workbook is internal and must not be distributed to customers.
- The workbook validates and exports the runtime JSON directly.
- PowerShell must not read the workbook or create the JSON.
- Controlled JSON must not be edited manually.
- Project-specific exceptions must not be stored in the master configuration.
