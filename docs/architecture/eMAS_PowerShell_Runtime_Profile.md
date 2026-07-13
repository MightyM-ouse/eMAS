# eMAS PowerShell Runtime Profile

**Version:** 1.0  
**Status:** Effective Architecture Amendment  
**Effective date:** 2026-07-13  
**Owner:** Technical Architect  
**Decision reference:** `DEC-2026-07-13-PS-RUNTIME`  
**Canonical references:** Enterprise Requirements v3.1; Solution Architecture v1.0; three Effective phase contracts

## 1. Runtime matrix

| Scope | Required runtime | Required platform | Authority |
|---|---|---|---|
| Development and pure unit/fixture tests | PowerShell 7.6 LTS | macOS permitted | Development evidence only |
| Shared business-engine core | Windows PowerShell 5.1-compatible language and APIs | Cross-edition source | Common implementation baseline |
| Pre-Sales Assessment | Windows PowerShell 5.1 | Windows | Mandatory customer runtime and release gate |
| Pre-Migration Readiness | PowerShell 7.6 LTS | Windows | Mandatory consultant runtime and release gate |
| Post-Migration Verification | PowerShell 7.6 LTS | Windows | Mandatory consultant runtime and release gate |
| WPF | PowerShell 7.6 LTS with Windows-supported UI implementation | Windows | Optional Pre-/Post-Migration only |
| Microsoft Excel compatibility | n/a | Windows with supported desktop Excel | Mandatory report qualification gate |

## 2. Design principle

Use one shared business engine with runtime-specific technical adapters.

```text
scripts/
├── eMAS-PreSalesAssessment.ps1
├── eMAS-PreMigrationReadiness.ps1
└── eMAS-PostMigrationVerification.ps1

engine/
├── core/
│   ├── eMAS.Configuration.psm1
│   ├── eMAS.Evidence.psm1
│   ├── eMAS.Rules.psm1
│   ├── eMAS.Classification.psm1
│   ├── eMAS.Findings.psm1
│   ├── eMAS.Effort.psm1
│   ├── eMAS.Readiness.psm1
│   ├── eMAS.Reconciliation.psm1
│   ├── eMAS.Reporting.Contract.psm1
│   ├── eMAS.Logging.psm1
│   └── eMAS.Common.psm1
├── powershell51/
│   ├── eMAS.Discovery.PS51.psm1
│   ├── eMAS.Reporting.PS51.psm1
│   └── eMAS.Compatibility.PS51.psm1
└── powershell7/
    ├── eMAS.Discovery.PS7.psm1
    ├── eMAS.Reporting.PS7.psm1
    ├── eMAS.ParallelProcessing.PS7.psm1
    └── eMAS.Compatibility.PS7.psm1
```

The adapter folders may contain technical differences only. Configuration meaning, rules, classification, findings, recommendations, RAG, effort, readiness and reconciliation logic remain in the common core and controlled runtime JSON.

## 3. Source compatibility rules

### 3.1 Common core

The common core shall:

- parse under Windows PowerShell 5.1;
- avoid PowerShell 7-only operators and syntax;
- avoid .NET APIs unavailable in the supported Windows PowerShell 5.1 environment;
- use explicit encoding and culture behavior;
- use stable object schemas;
- treat missing/null properties defensively;
- remain testable under both PowerShell editions.

Examples prohibited in the common core:

```powershell
$value ?? 'default'
$condition ? 'yes' : 'no'
command1 && command2
ForEach-Object -Parallel
```

### 3.2 PowerShell 7 adapter

The PowerShell 7 adapter may use PowerShell 7.6 LTS functionality for:

- safe controlled parallel processing;
- modern .NET filesystem APIs;
- improved UTF-8 behavior;
- migration-phase performance improvements;
- PowerShell 7-specific diagnostics.

Such use must not alter business results compared with the common engine contract.

## 4. Entry-point requirements

### 4.1 Pre-Sales

The entry script shall contain:

```powershell
#requires -Version 5.1
```

It is executed with `powershell.exe` and must not require PowerShell 7, Excel, WPF or unapproved external modules.

### 4.2 Pre-Migration and Post-Migration

The entry scripts shall contain:

```powershell
#requires -Version 7.6
```

They are executed with `pwsh.exe`. Launchers must detect a missing or unsupported runtime and return a clear corrective message before configuration or source processing begins.

## 5. Runtime evidence

Every execution records:

- `PSEdition`;
- complete PowerShell version;
- .NET runtime description where available;
- process architecture;
- operating system and version;
- executing identity and machine;
- phase code;
- engine and adapter versions;
- runtime-compatibility result.

## 5.1 Runtime configuration consumption foundation

The initial source boundary is implemented as:

```text
engine/
├── core/eMAS.Configuration.Contract.psm1
├── powershell51/eMAS.RuntimeAdapter.PS51.Contract.psm1
└── powershell7/eMAS.RuntimeAdapter.PS7.Contract.psm1
```

The compatibility contract and phase-neutral loader foundation establish:

- Schema 1.0.0 as the current runtime JSON compatibility boundary;
- the required top-level runtime JSON sections;
- approved EvaluationStatus values, including `Warning`;
- rejection of unknown EvaluationStatus values at the configuration-contract boundary;
- runtime adapter phase ownership for Pre-Sales versus Pre-/Post-Migration.

`eMAS.RuntimeConfiguration.psm1` now provides defensive UTF-8 loading, file SHA-256 identity, stable wrapper/accessors, minimum structural checks, phase-neutral semantic hooks and structured validation results. The three phase entry scripts invoke this layer and stop before assessment processing on blocking findings.

This foundation does not perform exact Draft 2020-12 JSON Schema validation at runtime, controlled-package checksum verification, source scanning, business or regulatory interpretation, or phase decision logic. Property-name assumptions remain centralized for reconciliation with the final approved Runtime JSON design. Build/release schema validation, complete semantic conformance, final-schema reconciliation and native Windows qualification remain pending.

## 6. Testing matrix

| Test area | macOS PS 7.6 | Windows PS 5.1 | Windows PS 7.6 |
|---|---:|---:|---:|
| JSON/schema fixtures | Required during development | Compatibility where applicable | Required |
| Semantic validator | Required during development | Required for future common loader behavior | Required |
| Shared rule engine | Required | Required | Required |
| Classification and effort | Required | Required | Required |
| Pre-Sales end-to-end | Development support only | **Mandatory** | Optional compatibility |
| Pre-Migration end-to-end | Development support only | Not a release target | **Mandatory** |
| Post-Migration end-to-end | Development support only | Not a release target | **Mandatory** |
| NTFS/UNC/Windows identity | Not applicable | Mandatory for Pre-Sales | Mandatory for Pre-/Post-Migration |
| WPF | Not applicable | Not applicable | Mandatory when included |
| Excel report opening | Not applicable | Windows desktop Excel | Windows desktop Excel |

## 7. CI and pull-request gates

Every material PowerShell pull request should run:

1. cross-platform static and unit tests under PowerShell 7.6 LTS;
2. Windows PowerShell 5.1 common-core and Pre-Sales tests;
3. Windows PowerShell 7.6 Pre-Migration/Post-Migration tests;
4. schema, fixture and semantic-validation tests;
5. report-package structural validation;
6. Windows-specific integration tests when the changed code touches discovery, paths, permissions, WPF or report generation.

A macOS-only pass cannot authorize release.

The repository includes `.github/workflows/powershell-runtime-contracts.yml` as the initial automated CI plan for:

- static runtime contract tests;
- dependency-free Runtime JSON loading/validation and phase-bootstrap tests;
- Windows PowerShell 5.1 contract import and EvaluationStatus checks;
- PowerShell 7.6 contract import and EvaluationStatus checks on Windows;
- PowerShell 7.6 shared-contract import, schema validation and pure contract tests on macOS.

The hosted macOS image controls which PowerShell patch is preinstalled. CI therefore applies an explicit major/minor guard and fails unless the runner is on the approved 7.6 LTS line; it does not install or qualify a substitute runtime. These jobs provide automated contract evidence only. They do not replace Windows release qualification, NTFS/UNC testing, WPF testing or desktop Microsoft Excel qualification.

## 8. Packaging

### Customer Pre-Sales package

Contains only the Pre-Sales entry script/launcher, common core, PowerShell 5.1 adapters, controlled JSON, checksum evidence, controlled Pre-Sales template and concise instructions.

### Internal Pre-/Post-Migration package

Contains the relevant entry script, common core, PowerShell 7 adapters, controlled JSON, controlled template, optional WPF and operating instructions.

Do not include unused runtime adapters in the customer package.

## 9. Acceptance criteria

The runtime profile conforms when:

- the common core parses and tests successfully in Windows PowerShell 5.1 and PowerShell 7.6;
- Pre-Sales runs end-to-end in Windows PowerShell 5.1;
- Pre-Migration and Post-Migration run end-to-end in PowerShell 7.6 LTS on Windows;
- runtime-specific adapters contain no independent business interpretation;
- all phases consume the same controlled JSON;
- logs identify the exact runtime and adapter;
- Windows-specific behavior is qualified on Windows;
- templates open without repair in supported Microsoft Excel versions.
