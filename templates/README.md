# Report Templates

This folder contains versioned controlled Excel templates and presentation assets.

```text
templates/
├── controlled/
│   ├── pre-sales/
│   ├── pre-migration/
│   └── post-migration/
├── branding/
├── manifest/
└── samples/
```

Each phase uses a separate controlled workbook structure. Templates define presentation and sheet contracts; PowerShell supplies observed/derived values through the shared OpenXML reporting engine without requiring Excel on the execution host.

All controlled templates must:

- contain no real customer/sample data;
- include execution and configuration metadata;
- keep EvaluationStatus, RAG, ValueSource, Confidence and ReviewRequired separate;
- use normalized classification dimensions;
- preserve original finding/discrepancy and accepted-exception traceability;
- include assumptions, limitations, intended use and non-validation wording;
- keep raw scoring internal by default;
- avoid versions and internal Confluence identifiers in generated filenames.

Pre-Sales includes a customer-clarification register and no readiness terminology. Post-Migration supports the approved baseline and `MigrationSummary.xlsx` detail interface.

Real customer-populated reports must not be committed.
