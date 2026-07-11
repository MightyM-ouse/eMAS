# eMAS Project Flow

**Project:** eMAS — eCTD Migration Assessment Script  
**Document Type:** Project Flow and Architecture Diagram  
**Version:** 1.0  
**Status:** Final Design Baseline  
**Date:** 11 July 2026

This document shows the complete eMAS project flow from internal mapping maintenance through pre-sales, pre-migration and post-migration execution, shared PowerShell processing, reporting, review and evidence retention.

---

## 1. Detailed Project Flow

```mermaid
flowchart TD

    %% =========================================================
    %% CONFIGURATION AUTHORING
    %% =========================================================

    subgraph CONFIG["1. Internal Configuration Authoring"]
        A1["Maintain eMAS Mapping Workbook<br/>(Excel XLSM)"]
        A2["Select Controlled Values<br/>and Maintain Rules"]
        A3["Validate Mapping"]
        A4{"Validation Successful?"}
        A5["Review Validation Findings<br/>and Correct Mapping"]
        A6["Preview Runtime JSON"]
        A7["Export Runtime JSON<br/>Directly from Excel"]
        A8["Record Export History<br/>Version, User and Timestamp"]

        A1 --> A2
        A2 --> A3
        A3 --> A4
        A4 -- "No" --> A5
        A5 --> A2
        A4 -- "Yes" --> A6
        A6 --> A7
        A7 --> A8
    end

    %% =========================================================
    %% CONTROLLED RUNTIME CONFIGURATION
    %% =========================================================

    subgraph RUNTIME["2. Controlled Runtime Configuration"]
        B1["eMAS_Runtime_Config.json"]
        B2["Shared Business Rules"]
        B3["Regions, Formats and Dossier Types"]
        B4["Folder and Mandatory File Rules"]
        B5["RAG, Confidence and Effort Rules"]
        B6["Recommendations and Controlled Values"]

        B1 --> B2
        B2 --> B3
        B2 --> B4
        B2 --> B5
        B2 --> B6
    end

    A7 --> B1

    %% =========================================================
    %% PHASE SELECTION
    %% =========================================================

    B1 --> C1{"Select Assessment Phase"}

    %% =========================================================
    %% PRE-SALES
    %% =========================================================

    subgraph PRESALES["3A. Pre-Sales Assessment"]
        PS1["Prepare Lightweight Customer Package"]
        PS2["Customer Executes<br/>Command Line or Simple Launcher"]
        PS3["Provide Minimum Inputs"]
        PS4["Export, Archive, Storage<br/>and Database Information"]
        PS5["Perform Lightweight Discovery"]
        PS6["Calculate Scope and Volume"]
        PS7["Estimate Region, Format and Type"]
        PS8["Apply High-Level Folder RAG"]
        PS9["Calculate Effort Drivers<br/>and Estimate Confidence"]
        PS10["Generate Customer Clarifications"]

        PS1 --> PS2
        PS2 --> PS3
        PS3 --> PS4
        PS4 --> PS5
        PS5 --> PS6
        PS6 --> PS7
        PS7 --> PS8
        PS8 --> PS9
        PS9 --> PS10
    end

    C1 -- "Pre-Sales" --> PS1

    %% =========================================================
    %% PRE-MIGRATION
    %% =========================================================

    subgraph PREMIG["3B. Pre-Migration Readiness"]
        PM1{"Execution Method"}
        PM2["Command Line"]
        PM3["Optional Portable WPF UI"]
        PM4["Collect Source Paths,<br/>Backup, Storage and Exceptions"]
        PM5["Perform Detailed Discovery"]
        PM6["Validate Dossiers and Sequences"]
        PM7["Check Mandatory Files,<br/>XML, Long Paths and Zero-Byte Files"]
        PM8["Check Access, Backup,<br/>Staging and Storage Readiness"]
        PM9["Generate Cleanup Actions"]
        PM10["Apply Accepted Exceptions"]
        PM11["Determine Readiness Result"]
        PM12["Generate Pre-Migration Baseline"]

        PM1 -- "Command Mode" --> PM2
        PM1 -- "UI Mode" --> PM3
        PM2 --> PM4
        PM3 --> PM4
        PM4 --> PM5
        PM5 --> PM6
        PM6 --> PM7
        PM7 --> PM8
        PM8 --> PM9
        PM9 --> PM10
        PM10 --> PM11
        PM11 --> PM12
    end

    C1 -- "Pre-Migration" --> PM1

    %% =========================================================
    %% POST-MIGRATION
    %% =========================================================

    subgraph POSTMIG["3C. Post-Migration Verification"]
        PO1{"Execution Method"}
        PO2["Command Line"]
        PO3["Optional Portable WPF UI"]
        PO4["Select Pre-Migration Baseline"]
        PO5["Select MigrationSummary Workbook"]
        PO6["Read Import Report Detail"]
        PO7["Read Post Import Verification"]
        PO8["Compare Expected and Migrated Dossiers"]
        PO9["Compare Expected and Migrated Sequences"]
        PO10["Identify Missing, Extra,<br/>Warning and Error Records"]
        PO11["Apply Accepted Exceptions"]
        PO12["Generate Discrepancies"]
        PO13["Determine Reconciliation Result"]

        PO1 -- "Command Mode" --> PO2
        PO1 -- "UI Mode" --> PO3
        PO2 --> PO4
        PO3 --> PO4
        PO4 --> PO5
        PO5 --> PO6
        PO6 --> PO7
        PO7 --> PO8
        PO8 --> PO9
        PO9 --> PO10
        PO10 --> PO11
        PO11 --> PO12
        PO12 --> PO13
    end

    C1 -- "Post-Migration" --> PO1

    %% =========================================================
    %% SHARED ENGINE
    %% =========================================================

    subgraph ENGINE["4. Shared PowerShell Engine"]
        E1["Load and Validate Runtime JSON"]
        E2["Configuration Module"]
        E3["Discovery Module"]
        E4["Classification Module"]
        E5["Validation Module"]
        E6["Effort Module"]
        E7["Readiness Module"]
        E8["Reconciliation Module"]
        E9["Reporting Module"]
        E10["Logging Module"]

        E1 --> E2
        E2 --> E3
        E3 --> E4
        E4 --> E5
        E5 --> E6
        E5 --> E7
        E5 --> E8
        E6 --> E9
        E7 --> E9
        E8 --> E9
        E1 --> E10
        E3 --> E10
        E4 --> E10
        E5 --> E10
        E6 --> E10
        E7 --> E10
        E8 --> E10
        E9 --> E10
    end

    PS5 --> E1
    PM5 --> E1
    PO4 --> E1

    %% =========================================================
    %% PHASE-SPECIFIC ORCHESTRATION
    %% =========================================================

    E6 --> PS6
    E7 --> PM11
    E8 --> PO8

    %% =========================================================
    %% OUTPUT AND REVIEW
    %% =========================================================

    subgraph OUTPUT["5. Controlled Output and Review"]
        O1["Populate Phase-Specific Excel Template"]
        O2["Generate Timestamped Execution Log"]
        O3["Record Script, JSON and Template Versions"]
        O4["Record Source Evidence,<br/>Rules, Warnings and Limitations"]
        O5["Generate Draft Report"]
        O6["Consultant Review"]
        O7["Set Status to Reviewed"]
        O8["Retain Report, Log and Inputs<br/>in Project Evidence Folder"]

        O1 --> O2
        O2 --> O3
        O3 --> O4
        O4 --> O5
        O5 --> O6
        O6 --> O7
        O7 --> O8
    end

    PS10 --> O1
    PM12 --> O1
    PO13 --> O1
    E9 --> O1
    E10 --> O2

    %% =========================================================
    %% PHASE RESULTS
    %% =========================================================

    subgraph RESULTS["6. Phase Results"]
        R1["Pre-Sales:<br/>Very Low to Very High Complexity<br/>High to Unknown Confidence"]
        R2["Pre-Migration:<br/>Ready<br/>Ready with Accepted Exceptions<br/>Blocked"]
        R3["Post-Migration:<br/>Reconciled<br/>Reconciled with Accepted Exceptions<br/>Review Required<br/>Not Reconciled"]
    end

    PS10 --> R1
    PM11 --> R2
    PO13 --> R3

    R1 --> O1
    R2 --> O1
    R3 --> O1
```

---

## 2. Simplified Executive Flow

```mermaid
flowchart LR
    A["Internal Mapping Workbook<br/>XLSM"] -->|Validate and Export| B["One Runtime JSON"]

    B --> C["Pre-Sales<br/>Command Line"]
    B --> D["Pre-Migration<br/>Command Line or WPF"]
    B --> E["Post-Migration<br/>Command Line or WPF"]

    C --> F["Shared PowerShell Engine"]
    D --> F
    E --> F

    F --> G["Phase-Specific Processing"]
    G --> H["Controlled Excel Report"]
    G --> I["Timestamped Execution Log"]

    H --> J["Draft"]
    J --> K["Reviewed"]
    K --> L["Project Evidence Archive"]
    I --> L
```

---

## 3. Key Flow Rules

- The internal Excel mapping workbook validates and exports one runtime JSON directly.
- PowerShell does not read the mapping workbook and does not generate the JSON.
- The same JSON is used by all three assessment phases.
- The pre-sales phase remains lightweight and command-line driven for customer execution.
- Pre-migration and post-migration support command-line execution and an optional portable WPF interface.
- The WPF interface invokes the same PowerShell scripts and does not contain separate business logic.
- Each phase defines its own input requirements, checks, assessment depth, decision logic and report structure.
- Every run creates a phase-specific Excel report and a detailed timestamped execution log.
- Reports follow the lifecycle `Draft → Reviewed` and are retained with supporting evidence in the project folder.
