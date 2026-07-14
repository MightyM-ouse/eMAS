# Runtime Configuration

```text
runtime/
├── controlled/    Reviewed JSON approved for release
└── development/   Temporary DEV exports
```

The runtime JSON is exported directly by the internal Excel mapping workbook. PowerShell loads this JSON but does not read the workbook and does not generate the JSON.

Controlled JSON must not be manually edited. Development exports must be clearly marked and must not be used as approved release configuration.

## Pre-Sales customer collection

`Invoke-eMASPreSalesAssessment.ps1` can run without a runtime JSON, but classification is deliberately conservative. Without executable mapping data, region and dossier type remain `Unknown` and require EXTEDO review.

For testing, place a development export at:

```text
config/runtime/development/eMAS_Runtime_Config.json
```

and pass its path explicitly:

```powershell
-RuntimeConfigPath "C:\eMAS\config\runtime\development\eMAS_Runtime_Config.json"
```

### Fields currently consumed by customer collection

Global configuration:

```json
{
  "config": {
    "SequenceFolderRegex": "^\\d{4}$",
    "MaxPathLength": 240
  }
}
```

Executable region rules must include `matchTokens`, `pathTokens` or `tokens`. `ConditionExpression` remains useful documentation, but the customer script does not execute free-text expressions.

```json
{
  "rules": {
    "regions": [
      {
        "RuleId": "REG-EU-PATH",
        "Active": "Yes",
        "Priority": 100,
        "matchTokens": ["\\EU\\", "/EU/", "EMA"],
        "ResultRegion": "EU",
        "Authority": "EMA / EU National Authority",
        "RegionalImplementation": "EU eCTD Module 1",
        "Confidence": "Medium"
      }
    ]
  }
}
```

Executable dossier-type rules must include `matchTokens` or `pathTokens`.

```json
{
  "rules": {
    "dossierTypes": [
      {
        "RuleId": "TYP-ASMF",
        "Active": "Yes",
        "Priority": 100,
        "matchTokens": ["ASMF"],
        "PrimaryDossierType": "ASMF",
        "ProductDomain": "Substance",
        "Confidence": "Medium"
      }
    ]
  }
}
```

The customer collection stage does not calculate target application, target version, upgrade path, final migration scenario, migration waves, productivity rates or final effort estimate. Those sections remain `Pending EXTEDO Review`.
