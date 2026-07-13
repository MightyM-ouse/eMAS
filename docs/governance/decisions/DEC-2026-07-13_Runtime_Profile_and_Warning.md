# eMAS Runtime Profile and EvaluationStatus Amendment

**Decision IDs:** `DEC-2026-07-13-PS-RUNTIME`, `DEC-2026-07-13-EVAL-WARNING`  
**Status:** Approved  
**Effective date:** 2026-07-13  
**Owner:** Product Owner  
**Technical approver:** Technical Architect  
**Affected areas:** Enterprise requirements, solution architecture, phase contracts, controlled terminology, Runtime JSON Schema, fixtures, semantic validation, PowerShell loader/engine, report templates and tests

## 1. Purpose

This decision records two approved changes required before continued eMAS implementation:

1. a phase-specific PowerShell runtime profile that preserves a single shared business engine; and
2. addition of `Warning` to the controlled `EvaluationStatus` vocabulary.

This amendment takes precedence over conflicting runtime or EvaluationStatus statements in documents that have not yet been consolidated to their next revision.

## 2. PowerShell runtime decision

### 2.1 Development

PowerShell 7.6 LTS on macOS is approved for:

- source development with Codex, Claude Code and supported local tools;
- pure business-rule unit tests;
- JSON/schema and semantic-fixture tests;
- non-Windows report-package inspection;
- static analysis and documentation generation.

macOS execution is not authoritative for Windows-specific behavior.

### 2.2 Shared engine

The shared business-engine core shall remain compatible with Windows PowerShell 5.1 language and API constraints. It contains shared configuration, evidence, rule, classification, finding, effort, readiness, reconciliation, reporting-contract, logging and common logic.

Runtime-specific adapters may implement technical differences such as enumeration, parallel processing, encoding, Windows information and OpenXML packaging. They shall not duplicate or alter regulatory or business interpretation.

Recommended source boundary:

```text
engine/
├── core/
├── powershell51/
└── powershell7/
```

### 2.3 Pre-Sales Assessment

- Mandatory runtime: Windows PowerShell 5.1 on Windows.
- Entry point uses `powershell.exe`.
- The package shall minimize customer prerequisites.
- The phase remains CLI/simple-launcher only and does not require WPF.
- Release qualification is performed under Windows PowerShell 5.1.

### 2.4 Pre-Migration Readiness

- Mandatory runtime: PowerShell 7.6 LTS on Windows.
- Entry point uses `pwsh.exe`.
- Optional WPF invokes the same PowerShell 7.6 entry script.
- PowerShell 7-specific optimizations are allowed only in the runtime adapter layer.

### 2.5 Post-Migration Verification

- Mandatory runtime: PowerShell 7.6 LTS on Windows.
- Entry point uses `pwsh.exe`.
- Optional WPF invokes the same PowerShell 7.6 entry script.
- The same controlled JSON and shared business-engine core are used.

### 2.6 Qualification

Windows remains mandatory for qualification of:

- Windows PowerShell 5.1 and PowerShell 7.6 parsing/execution;
- NTFS permissions and access-denied behavior;
- UNC paths and mapped drives;
- Windows identity, process architecture and operating-system metadata;
- WPF;
- long Windows paths, file locking and Windows-specific filesystem behavior;
- Microsoft Excel workbook opening and repair validation.

## 3. EvaluationStatus decision

`Warning` is added to the controlled `EvaluationStatus` values:

- Evaluated
- NotAssessed
- NotApplicable
- Skipped
- Warning
- Error
- InsufficientEvidence
- Conflict

### 3.1 Meaning

`Warning` means that evaluation completed and produced a usable result, but one or more recoverable conditions require attention.

It does not automatically determine:

- RAG;
- severity;
- blocker status;
- effort band;
- readiness result;
- reconciliation result.

The related warning/finding, evidence, rule or technical condition and decision impact remain separately traceable.

### 3.2 Compatibility

This is a semantic-code addition. Before controlled release, synchronize:

- controlled terminology;
- enterprise and configuration requirements;
- logical data dictionary and normalized rule model;
- Runtime JSON Schema and compatibility documentation;
- valid, boundary and invalid fixtures;
- independent semantic validator;
- PowerShell loader and runtime validation;
- Excel template dropdowns and validation rules;
- unit, integration and regression tests;
- indexes and LLM development routes.

The implementation shall either publish a new compatible schema minor version or document an explicitly approved in-place compatibility amendment. Silent divergence between templates and runtime JSON is prohibited.

## 4. Template correction requirements

The controlled templates require the following corrections before approval:

1. scope data validation and conditional formatting to the exact owning table/column;
2. remove cross-table validation contamination;
3. enable stop-style validation alerts for manually editable controlled fields;
4. synchronize all template-version metadata;
5. resolve provenance for internal review fields rather than defaulting all review values to `CustomerProvided`;
6. remove local author paths and personal metadata;
7. standardize UTC date-time formatting;
8. complete release metadata only when the templates are approved;
9. verify each workbook in desktop Microsoft Excel without repair, removed tables or removed filters.

## 5. Acceptance gates

This decision is implemented only when:

- phase contracts and architecture reflect the runtime profile;
- all shared business logic remains single-sourced;
- `Warning` is accepted consistently by schema, fixtures, semantic validation, loader, templates and tests;
- Pre-Sales passes Windows PowerShell 5.1 tests;
- Pre-Migration and Post-Migration pass PowerShell 7.6 LTS tests on Windows;
- macOS tests are treated as development evidence, not Windows release authority;
- corrected templates pass package validation and desktop Excel qualification;
- affected canonical indexes and implementation guidance are synchronized.

## 6. Non-decisions

This amendment does not:

- introduce two independent business engines;
- allow PowerShell to read the authoring XLSM;
- change the one-runtime-JSON principle;
- authorize customer data in the public repository;
- make WPF mandatory;
- remove the requirement for Windows qualification;
- claim that the PowerShell engine or controlled templates are already released.
