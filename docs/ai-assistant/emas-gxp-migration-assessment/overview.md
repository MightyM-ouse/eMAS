# eMAS Overview and Positioning

**Status:** Generated / Non-authoritative assistant profile  
**Last synchronized:** 2026-07-13  
**Derived from:** Enterprise Requirements v3.0, Approved Decision Baseline v1.0, Authority and Precedence Policy, Controlled Terminology and Project Flow  
**Regeneration trigger:** Any approved change to product scope, phase terminology, source-of-truth architecture or controlled outcomes

Canonical repository sources prevail if this summary is incomplete or inconsistent.

## Product definition

**eMAS** stands for **eCTD Migration Assessment Script**.

It is a read-only, mapping-driven migration assessment framework supporting three distinct phases:

1. **Pre-Sales Assessment**;
2. **Pre-Migration Readiness**;
3. **Post-Migration Verification**.

`Reconciliation` is the principal technical activity within Post-Migration Verification; it is not a separate product phase.

## Core purpose

- Support early migration scope, complexity and customer clarification work.
- Assess source-data readiness before migration.
- Create a reusable Pre-Migration baseline.
- Compare migrated evidence with that approved baseline after migration.
- Produce structured, reproducible and traceable assessment evidence.

## Explicit limitations

eMAS does not:

- perform migration or import;
- perform regulatory validation;
- complete formal customer validation;
- provide electronic approval or e-signatures;
- prove formal customer acceptance.

## Core architecture

- Business and regulatory configuration is maintained in an internal Excel `.xlsm` mapping workbook.
- The reviewed XLSM is the **authoring source of truth**.
- The workbook validates its maintained content and directly exports one immutable runtime JSON file.
- The validated exported JSON is the **runtime source of truth**.
- The exact JSON version and checksum loaded for a run is the **execution source**.
- PowerShell never reads the XLSM and does not create, repair or reinterpret the runtime JSON.
- The same runtime JSON is used across all three phases.
- Each phase defines its own inputs, checks, depth, decision logic and controlled report structure.
- All phases support command-line execution.
- Pre-Migration Readiness and Post-Migration Verification may additionally use an optional portable WPF interface that delegates to the same scripts and engine.
- Every execution produces one phase-specific Excel report and one detailed timestamped log.

## Approved phase outcomes

- **Pre-Sales Assessment:** complexity band, confidence, scope and customer clarifications.
- **Pre-Migration Readiness:** Ready, Ready with Accepted Exceptions or Blocked.
- **Post-Migration Verification:** Reconciled, Reconciled with Accepted Exceptions, Review Required or Not Reconciled.

## Evidence handling

Projects may route generated reports through Draft, Reviewed and Project Evidence Archive states. This is an operational governance workflow; the engine does not enforce approval, electronic signatures or customer acceptance.

Findings, recommendations, evaluation status, RAG, evidence provenance and accepted exceptions remain separate controlled concepts.

## Intended users

The framework supports pre-sales consultants, technical consultants, migration specialists, project managers, QA/validation reviewers and customer IT teams involved in regulated content migrations.

## Authority notice

This file is optimized as a concise assistant profile. It must not be used as an independent requirements baseline, regulatory-rule authority or runtime contract. Use the repository canonical document index for implementation work.
