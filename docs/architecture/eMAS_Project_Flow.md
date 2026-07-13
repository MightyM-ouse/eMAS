# eMAS Project Flow

**Version:** 2.0  
**Status:** Effective Architecture Flow  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect  
**Canonical references:** Enterprise Requirements v3.1; Solution Architecture v1.0; Runtime JSON Contract v1.2; Runtime JSON Schema 1.0.0; three Effective phase contracts

## 1. End-to-end controlled flow

```mermaid
flowchart TD
    subgraph AUTHORING[1. Internal configuration authoring]
        A1[Maintain reviewed internal XLSM]
        A2[Maintain normalized master data, relationships, rules and policies]
        A3[Run workbook validation]
        A4{Valid?}
        A5[Correct findings]
        A6[Preview deterministic JSON]
        A7[Export eMAS_Runtime_Config.json]
        A8[Record version, exporter, UTC timestamp and SHA-256]
        A1 --> A2 --> A3 --> A4
        A4 -- No --> A5 --> A2
        A4 -- Yes --> A6 --> A7 --> A8
    end

    subgraph RELEASE[2. Configuration and release verification]
        B1[Validate against Runtime JSON Schema 1.0.0]
        B2[Run independent semantic validator and fixtures]
        B3{Verification successful?}
        B4[Reject release and correct source]
        B5[Build controlled runtime package]
        B6[Record manifest and checksums]
        B1 --> B2 --> B3
        B3 -- No --> B4
        B3 -- Yes --> B5 --> B6
    end

    A8 --> B1

    subgraph PHASES[3. Phase execution]
        C0{Select phase}
        C1[Pre-Sales Assessment\nCLI or simple launcher]
        C2[Pre-Migration Readiness\nCLI or optional WPF]
        C3[Post-Migration Verification\nCLI or optional WPF]
        C0 --> C1
        C0 --> C2
        C0 --> C3
    end

    B6 --> C0

    subgraph COMMON[4. Common startup and shared engine]
        D1[Validate parameters and output path]
        D2[Load immutable runtime JSON]
        D3[Verify schema version, checksum and semantic integrity]
        D4[Create run ID and initialize log]
        D5[Read source evidence without modification]
        D6[Discovery and normalization]
        D7[Rule, conflict and policy evaluation]
        D8[Preserve EvaluationStatus, RAG, ValueSource, confidence and evidence]
        D9[Populate controlled XLSX through OpenXML]
        D10[Finalize timestamped log]
        D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7 --> D8 --> D9 --> D10
    end

    C1 --> D1
    C2 --> D1
    C3 --> D1

    subgraph OUTPUT[5. Review and evidence]
        E1[Phase-specific report]
        E2[Timestamped execution log]
        E3[Draft consultant/customer review state]
        E4[Reviewed evidence state]
        E5[Project evidence location]
        E1 --> E3 --> E4 --> E5
        E2 --> E5
    end

    D9 --> E1
    D10 --> E2
```

## 2. Phase-specific flow

### 2.1 Pre-Sales Assessment

```mermaid
flowchart LR
    A[Minimal customer inputs] --> B[Lightweight discovery]
    B --> C[Scope and volume summary]
    C --> D[Configured classification candidates]
    D --> E[High-level structure findings]
    E --> F[Complexity band and effort confidence]
    F --> G[Customer clarification register]
    G --> H[Pre-Sales report and log]
```

Rules:

- remains lightweight and customer-friendly;
- does not determine readiness or reconciliation;
- raw score remains internal by default;
- raw inventory is optional;
- report includes assumptions, limitations, intended use and non-validation wording;
- completion output identifies the report and log to share.

### 2.2 Pre-Migration Readiness

```mermaid
flowchart LR
    A[Detailed source and project inputs] --> B[Detailed discovery]
    B --> C[Structure, XML, file and infrastructure checks]
    C --> D[Findings and preparation actions]
    D --> E[Accepted-exception treatment]
    E --> F[Ready / Ready with Accepted Exceptions / Blocked]
    F --> G[Stable approved comparison baseline]
    G --> H[Pre-Migration report and log]
```

Rules:

- original findings, RAG and evidence remain visible after exception treatment;
- baseline records stable identifiers, scope, exclusions, limitations and integrity metadata;
- CLI and WPF invoke the same phase entry script.

### 2.3 Post-Migration Verification

```mermaid
flowchart LR
    A[Approved Pre-Migration baseline] --> D[Normalize comparison identifiers]
    B[MigrationSummary.xlsx details] --> D
    C[Post-import verification evidence] --> D
    D --> E[Compare dossiers and sequences]
    E --> F[Compare agreed file/count/size measures]
    F --> G[Missing, extra, warning, error and ambiguous records]
    G --> H[Accepted-difference treatment]
    H --> I[Reconciled / Reconciled with Accepted Exceptions / Review Required / Not Reconciled]
    I --> J[Post-Migration report and log]
```

Rules:

- the approved baseline is mandatory;
- `MigrationSummary.xlsx` is read without modification using controlled mappings;
- original discrepancies and evidence remain visible after accepted-difference treatment;
- CLI and WPF invoke the same phase entry script.

## 3. Shared engine call model

```mermaid
flowchart TB
    ENTRY[Phase entry script] --> CONFIG[Configuration and package validation]
    CONFIG --> DISCOVERY[Discovery]
    DISCOVERY --> CLASSIFY[Classification and normalization]
    CLASSIFY --> VALIDATE[Technical validation]
    VALIDATE --> EFFORT[Effort and confidence]
    VALIDATE --> READY[Readiness]
    VALIDATE --> RECON[Reconciliation]
    EFFORT --> REPORT[Reporting / OpenXML]
    READY --> REPORT
    RECON --> REPORT
    ENTRY --> LOG[Logging and utilities]
    CONFIG --> LOG
    DISCOVERY --> LOG
    CLASSIFY --> LOG
    VALIDATE --> LOG
    EFFORT --> LOG
    READY --> LOG
    RECON --> LOG
    REPORT --> LOG
```

Only modules required by the selected phase are invoked. Entry scripts do not duplicate shared behavior, and the WPF interface does not contain assessment logic.

## 4. Failure paths

```mermaid
flowchart TD
    A[Start run] --> B{Runtime package valid?}
    B -- No --> X[Stop with clear error]
    B -- Yes --> C{Mandatory phase inputs accessible?}
    C -- No --> X
    C -- Yes --> D{Template/output initialized?}
    D -- No --> X
    D -- Yes --> E[Execute assessment]
    E --> F{Execution failure?}
    F -- Yes --> G[Record failed state in log; do not claim successful result]
    F -- No --> H[Generate report and log]
```

Missing optional evidence encountered after startup is represented using configured evaluation status, assumptions, limitations and review requirements; it is not silently treated as Green.

## 5. Controlled flow rules

- The internal XLSM validates and exports one runtime JSON directly.
- PowerShell never reads the XLSM or generates/repairs runtime JSON.
- The same JSON is used by all phases.
- Runtime JSON Schema 1.0.0 and semantic validation are checked before controlled release and defensively at runtime.
- Pre-Sales uses CLI/simple launcher only; WPF is limited to Pre- and Post-Migration.
- Every phase produces one controlled XLSX report and one detailed timestamped log.
- Report generation must not require Excel on the execution host.
- Source evidence is read-only.
- Accepted exceptions never erase original findings or discrepancies.
- Generated evidence remains outside the source repository.

## 6. Revision history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-11 | Initial project-flow baseline |
| 2.0 | 2026-07-13 | Synchronized flow with Solution Architecture v1.0, Schema 1.0.0, independent configuration validation and the three Effective phase contracts |
