# eMAS Pre-Sales Customer Collection v0.1

## Status

Initial functional implementation on branch `implementation/pre-sales-collection-v3.2`.

This version performs customer-side evidence collection and produces:

- normalized result JSON;
- timestamped UTF-8 execution log.

Excel report generation is deliberately marked `PendingUpdatedTemplateMapping` until the revised four-sheet v3.2 template mapping is approved.

## Supported modes

| Mode | Detailed export discovery | Archive size | Index size | Database size |
|---|---:|---:|---:|---:|
| `ExternalExport` | Yes | No | No | No |
| `ECTDManagerExport` | Yes | No | No | No |
| `ECTDManagerDatabaseArchive` | No | Yes | Yes | Yes |
| `ECTDManagerHybrid` | Yes | Yes | Yes | Yes |
| `ArchiveOnly` | No | Yes | Yes | No |

Only evidence required by the selected mode is requested.

## Data collection boundaries

### Export roots

The script records detailed aggregate and inventory evidence:

- size;
- file and folder counts;
- dossier and sequence counts;
- dossier and sequence inventories;
- high-level eCTD/NeeS structure indicators;
- configured region and dossier-type classification;
- long-path count at export-root level.

### Direct-copy evidence

Archive, index and database evidence records only:

- source type and reference;
- accessibility;
- aggregate size;
- value source;
- review status and comments.

The output does not retain individual archive, index or database files, file counts, folder counts, extensions, long paths, largest files or zero-byte details.

## Target planning boundary

The customer is not asked for target application information. The result contains blank target fields and the controlled status `Pending EXTEDO Review`.

The customer collection does not determine:

- final migration scenario;
- approved migration method;
- target version or hotfix;
- sequential upgrade path;
- migration waves;
- final effort range.

## Interactive execution

```powershell
.\scripts\Invoke-eMASPreSalesAssessment.ps1
```

The script displays the five assessment modes and asks only the relevant questions.

## Non-interactive examples

### External-system export

```powershell
.\scripts\Invoke-eMASPreSalesAssessment.ps1 `
  -Mode ExternalExport `
  -CustomerName "Example Pharma" `
  -ProjectName "Migration Assessment" `
  -CurrentApplication "Legacy RIMS" `
  -CurrentVersion "12.4" `
  -ExportRoot "D:\MigrationExport" `
  -RuntimeConfigPath ".\config\runtime\development\eMAS_Runtime_Config.json" `
  -OutputRoot ".\output" `
  -NonInteractive
```

### eCTDmanager database and archive using paths

```powershell
.\scripts\Invoke-eMASPreSalesAssessment.ps1 `
  -Mode ECTDManagerDatabaseArchive `
  -CustomerName "Example Pharma" `
  -ProjectName "Database and Archive Move" `
  -CurrentVersion "25.02" `
  -CurrentHotfix "HF1" `
  -ArchiveRoot "D:\eCTDmanager\Archive" `
  -IndexRoot "D:\eCTDmanager\Index" `
  -DatabasePath "D:\SQLBackup\eCTDmanager.bak" `
  -OutputRoot ".\output" `
  -NonInteractive
```

### eCTDmanager database and archive using customer-provided aggregate sizes

```powershell
.\scripts\Invoke-eMASPreSalesAssessment.ps1 `
  -Mode ECTDManagerDatabaseArchive `
  -CustomerName "Example Pharma" `
  -ProjectName "Database and Archive Move" `
  -CurrentVersion "25.02" `
  -ArchiveSizeGB 312.84 `
  -IndexSizeGB 18.20 `
  -DatabaseSizeGB 38.19 `
  -OutputRoot ".\output" `
  -NonInteractive
```

## Result files

```text
eMAS_PreSalesCollection_<AssessmentReference>_<Timestamp>.result.json
eMAS_PreSalesCollection_<AssessmentReference>_<Timestamp>.log
```

The result JSON is the input for the later EXTEDO review and report-generation stage.
