# eMAS Repository Architecture

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Source Repository and Release Architecture  
**Version:** 1.0  
**Status:** Approved Structure Baseline  
**Date:** 12 July 2026

## 1. Purpose

This document shows how the eMAS source repository maps to configuration authoring, runtime execution, testing, controlled reporting and release packaging.

The repository is organized around two separations:

- business and regulatory rule authoring versus runtime execution;
- internal source assets versus generated customer or consultant packages.

## 2. Repository component architecture

```mermaid
flowchart TB
    subgraph REPO["eMAS GitHub Repository"]
        subgraph ENTRY["Execution Entry Points"]
            S1["scripts/<br/>Pre-Sales"]
            S2["scripts/<br/>Pre-Migration"]
            S3["scripts/<br/>Post-Migration"]
        end

        subgraph ENG["Shared Runtime Engine"]
            E1["Configuration"]
            E2["Discovery"]
            E3["Classification"]
            E4["Validation"]
            E5["Effort"]
            E6["Readiness"]
            E7["Reconciliation"]
            E8["Reporting / OpenXML"]
            E9["Logging / Utilities"]
        end

        subgraph CONF["Configuration Source"]
            C1["config/authoring/<br/>Internal XLSM"]
            C2["config/vba/<br/>Reviewable VBA Source"]
            C3["config/schema/<br/>JSON Contracts"]
            C4["config/runtime/controlled/<br/>Reviewed Runtime JSON"]
        end

        subgraph REPORT["Controlled Presentation"]
            T1["templates/controlled/<br/>Pre-Sales"]
            T2["templates/controlled/<br/>Pre-Migration"]
            T3["templates/controlled/<br/>Post-Migration"]
            U1["ui/<br/>Optional WPF"]
        end

        subgraph QUALITY["Quality and Governance"]
            Q1["tests/"]
            Q2["docs/"]
            Q3["build/"]
            Q4["releases/"]
        end
    end

    C1 -->|"Exported and reviewed separately"| C2
    C1 -->|"Validate and export"| C4
    C3 -->|"Validate contract"| C4

    C4 --> E1
    S1 --> E1
    S2 --> E1
    S3 --> E1

    E1 --> E2
    E2 --> E3
    E3 --> E4
    E4 --> E5
    E4 --> E6
    E4 --> E7
    E5 --> E8
    E6 --> E8
    E7 --> E8
    E8 --> E9

    T1 --> E8
    T2 --> E8
    T3 --> E8
    U1 --> S2
    U1 --> S3

    Q1 --> S1
    Q1 --> S2
    Q1 --> S3
    Q1 --> ENG
    Q1 --> CONF
    Q1 --> REPORT
    Q2 --> Q3
    Q3 --> Q4
```

## 3. Configuration-to-runtime boundary

```mermaid
flowchart LR
    A["config/authoring/<br/>eMAS Mapping XLSM"] --> B["Workbook Validation"]
    B --> C["JSON Preview"]
    C --> D["Direct UTF-8 JSON Export"]
    D --> E["config/runtime/controlled/<br/>eMAS_Runtime_Config.json"]
    F["config/schema/<br/>Runtime JSON Schema"] --> E

    E --> G["Shared PowerShell Engine"]
    G --> H["Pre-Sales"]
    G --> I["Pre-Migration"]
    G --> J["Post-Migration"]

    X["PowerShell"] -.->|"must not read"| A
    X -.->|"must not generate"| D
```

The workbook is the internal authoring application. The exported JSON is the runtime contract. PowerShell loads only the JSON and applies phase-specific orchestration through the shared engine.

## 4. Source-to-release flow

```mermaid
flowchart TD
    A["Approved source branch"] --> B["Pull request review"]
    B --> C["Merge to main"]
    C --> D["Run unit and integration tests"]
    D --> E["Validate runtime JSON and templates"]
    E --> F["Build internal controlled package"]
    E --> G["Build customer pre-sales package"]
    F --> H["Release manifest and checksums"]
    G --> H
    H --> I["Controlled release archive"]

    G --> J["Customer execution"]
    J --> K["Phase-specific report"]
    J --> L["Timestamped execution log"]

    K --> M["Project evidence folder"]
    L --> M

    N["Repository output/, logs/, dist/"] -.->|"local generated content only"| D
```

## 5. Repository and evidence boundaries

```mermaid
flowchart LR
    subgraph SOURCE["Source-Controlled"]
        A1["PowerShell source"]
        A2["VBA source"]
        A3["Schemas"]
        A4["Controlled templates"]
        A5["Synthetic tests"]
        A6["Documentation"]
    end

    subgraph GENERATED["Generated but not committed"]
        B1["output/"]
        B2["logs/"]
        B3["dist/"]
        B4["Development JSON exports"]
    end

    subgraph PROHIBITED["Must never enter repository"]
        C1["Customer source data"]
        C2["Project migration evidence"]
        C3["Credentials"]
        C4["Production logs and reports"]
        C5["Project-specific exceptions"]
    end

    SOURCE -->|"Build process"| GENERATED
```

## 6. Folder-to-architecture mapping

| Architecture responsibility | Repository location |
|---|---|
| Phase orchestration | `scripts/` |
| Shared technical processing | `engine/` |
| Mapping authoring | `config/authoring/` |
| Reviewable workbook code | `config/vba/` |
| Runtime contracts | `config/schema/` |
| Reviewed runtime rules | `config/runtime/controlled/` |
| Phase report presentation | `templates/controlled/` |
| Optional execution interface | `ui/` |
| Automated and controlled testing | `tests/` |
| Packaging and checksum generation | `build/` |
| Requirements, design and operating guidance | `docs/` |
| Release notes and manifests | `releases/` |
| Local generated artifacts | `output/`, `logs/`, `dist/` |

## 7. Architectural constraints

- Entry scripts must not duplicate business or shared technical logic.
- The WPF interface must invoke the same pre-migration and post-migration scripts used in command-line mode.
- The UI must not maintain an independent rule set.
- Runtime JSON must be validated against the supported schema and engine compatibility rules.
- Separate controlled templates must be used for pre-sales, pre-migration and post-migration.
- Test fixtures must be synthetic, approved and free of customer-identifiable information.
- Generated reports and logs belong in a project evidence location, not in the source repository.

See [eMAS Repository Structure](../repository/eMAS_Repository_Structure.md) for the complete folder tree and source-control rules.
