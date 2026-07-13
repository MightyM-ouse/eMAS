# Work Package — Runtime Profile, Warning Synchronization and Template Corrections

**Status:** Approved implementation work package  
**Decision references:** `DEC-2026-07-13-PS-RUNTIME`, `DEC-2026-07-13-EVAL-WARNING`  
**Primary development environment:** macOS with PowerShell 7.6 LTS  
**Release qualification environments:** Windows PowerShell 5.1 and PowerShell 7.6 LTS on Windows

## 1. Objective

Complete the approved runtime split, synchronize `Warning` across the runtime contract and correct the three controlled report templates without creating separate business engines or requirement drift.

## 2. Workstreams

### WS-1 — Runtime architecture and repository structure

Implement:

```text
engine/
├── core/
├── powershell51/
└── powershell7/
```

Acceptance:

- common core parses under Windows PowerShell 5.1;
- runtime adapters contain technical behavior only;
- no business/regulatory interpretation is duplicated;
- all phases consume the same controlled runtime JSON;
- entry scripts enforce the phase runtime before processing.

### WS-2 — EvaluationStatus `Warning` synchronization

Update together:

- `docs/governance/eMAS_Terminology.md`;
- Enterprise Requirements and configuration requirements;
- Runtime JSON Contract;
- Normalized Rule Model;
- Logical Data Dictionary;
- Runtime JSON Schema/common definitions;
- value-list seed data;
- valid/boundary/invalid fixtures;
- independent semantic validator;
- PowerShell configuration loader;
- report templates;
- unit/integration/regression tests;
- canonical and LLM indexes.

Meaning:

> `Warning` means evaluation completed with a usable result, but a recoverable condition requires attention. It does not independently determine RAG, severity or phase outcome.

Acceptance:

- a valid fixture containing `Warning` passes;
- an unknown status fails with a stable error code;
- removal of mandatory `Warning` from an effective controlled list fails if the chosen compatibility model makes it mandatory;
- loader, schema validator and template dropdowns use the same exact display/code mapping;
- no template-only vocabulary exists.

### WS-3 — Controlled template corrections

Correct:

1. cross-table data-validation ranges;
2. cross-table conditional-formatting ranges;
3. stop-style validation alerts;
4. template version consistency;
5. internal review provenance handling;
6. local author paths and personal metadata;
7. UTC date-time formatting;
8. release-control metadata;
9. Post-Migration raw-sheet preservation.

Required files:

- `eMAS_PreSales_Template.xlsx`;
- `eMAS_PreMigration_Template.xlsx`;
- `eMAS_PostMigration_Template.xlsx`.

Acceptance:

- no validation rule reaches a different table;
- each controlled field has one intended validation rule;
- invalid manual controlled values trigger a Stop alert;
- no local path, user name or customer data remains;
- all version fields agree;
- raw headers match `MigrationSummary.xlsx`, including `DossierDirecotry`;
- desktop Microsoft Excel opens, saves and reopens without repair or removed features.

### WS-4 — PowerShell configuration loader

Implement the first shared-engine vertical slice:

- file existence/readability/size checks;
- SHA-256 verification;
- immutable JSON loading;
- supported schema/mapping/engine compatibility;
- required sections and controlled values;
- duplicate identifier and reference checks;
- stable configuration/technical error codes;
- stop before source scanning on invalid configuration;
- runtime/adapter metadata logging.

Runtime coverage:

- common loader behavior under Windows PowerShell 5.1;
- PowerShell 7.6 compatibility;
- no `Test-Json` dependency in the common 5.1-compatible core;
- PowerShell 7-specific helpers isolated in the adapter layer.

### WS-5 — CI and qualification matrix

Add CI jobs for:

- macOS or Linux PowerShell 7.6 pure unit/fixture tests;
- Windows PowerShell 5.1 common-core and Pre-Sales tests;
- Windows PowerShell 7.6 Pre-Migration/Post-Migration tests;
- schema and semantic fixture tests;
- report package/XML/table validation;
- runtime-specific adapter tests.

Manual gates:

- NTFS/UNC/access-denied testing on Windows;
- supported desktop Excel repair/open/save/reopen test;
- WPF test when introduced;
- large repository performance testing.

## 3. Recommended agent allocation

### Codex

- repository structure;
- PowerShell modules and tests;
- schema/fixture/semantic-validator synchronization;
- CI workflows;
- traceability and pull-request preparation.

### Claude Code

- Excel template corrections and workbook inspection;
- independent review of requirements and report contracts;
- cross-check of controlled wording and metadata;
- secondary review of PowerShell/module boundaries.

### Human/Product Owner

- approve controlled terminology and compatibility choice;
- review template usability;
- confirm release status/effective dates;
- approve final PR and Windows/Excel qualification evidence.

## 4. Local workflow

```bash
git clone https://github.com/MightyM-ouse/eMAS.git
cd eMAS
git fetch origin
git checkout decision/runtime-profile-warning-status
```

Create focused child branches from the decision branch when parallel work is required. Merge child branches back through reviewed pull requests or reviewed commits; do not let Claude and Codex modify the same file concurrently.

Recommended ownership split:

- Codex: schema, fixtures, validators, PowerShell and CI;
- Claude: XLSX templates and template validation report;
- one integration branch owner: resolves contract/version changes.

## 5. Definition of Done

The work package is complete when:

- all approved documents and implementation assets agree on the runtime profile;
- `Warning` is synchronized across schema, configuration, templates, loader and tests;
- the common business engine remains single-sourced;
- all automated tests pass;
- Windows PowerShell 5.1 Pre-Sales qualification passes;
- Windows PowerShell 7.6 Pre-/Post-Migration qualification passes;
- all three templates pass desktop Excel qualification;
- no customer data or confidential controlled binaries are committed;
- review evidence and release limitations are recorded;
- the implementation PR is approved and merged.
