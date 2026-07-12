# Runtime Configuration

```text
runtime/
├── controlled/    Reviewed JSON approved for release
└── development/   Temporary DEV exports
```

The runtime JSON is exported directly by the internal Excel mapping workbook. PowerShell loads this JSON but does not read the workbook and does not generate the JSON.

Controlled JSON must not be manually edited. Development exports must be clearly marked and must not be used as approved release configuration.
