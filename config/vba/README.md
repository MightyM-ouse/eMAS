# VBA Source

Reviewable workbook VBA is stored here so that configuration validation and JSON export logic can be reviewed in Git.

```text
vba/
├── modules/   Standard `.bas` modules
├── classes/   Future `.cls` class modules
└── forms/     Future `.frm` forms and related files
```

## Synthetic POC modules

The current POC includes modules for constants, utilities, workbook-structure validation, semantic validation, deterministic JSON construction, UTF-8 atomic writing, SHA-256, export history and public entry points.

The internal build imports the reviewed modules using `build/Build-eMASMappingPoc.ps1`. Native behavior is tested with `build/Test-eMASMappingPoc.ps1` on a supported Windows/Excel workstation.

All modules use `Option Explicit` and must avoid `ActiveCell`, `Selection`, `.Select`, `.Activate` and fixed cell coordinates. PowerShell is prohibited from generating or repairing the runtime JSON.

Binary XLSM changes must be accompanied by corresponding exported VBA changes, manifest/checksum updates, fixture evidence and a clear change summary. The controlled production workbook must not be committed to the public repository.
