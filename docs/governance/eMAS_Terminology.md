# eMAS Controlled Terminology

**Status:** Approved  
**Effective date:** 2026-07-13  
**Decision references:** AP-002, AP-010, DOC-013, RM-008, RM-017, RM-018, RM-025, REG-003, REG-004

## Assessment phases

| Code | Display name | Meaning |
|---|---|---|
| `PRE_SALES` | Pre-Sales Assessment | Lightweight scope, complexity, confidence and clarification assessment |
| `PRE_MIGRATION` | Pre-Migration Readiness | Detailed readiness assessment and reusable baseline creation |
| `POST_MIGRATION` | Post-Migration Verification | Reconciliation of migrated evidence against the approved pre-migration baseline |

`Reconciliation` is the principal technical activity within Post-Migration Verification; it is not a separate product phase.

## Approved phase result terms

### Pre-Sales

- Very Low
- Low
- Medium
- High
- Very High

Estimate confidence:

- High
- Medium
- Low
- Unknown

### Pre-Migration

- Ready
- Ready with Accepted Exceptions
- Blocked

### Post-Migration

- Reconciled
- Reconciled with Accepted Exceptions
- Review Required
- Not Reconciled

## Evaluation status

Evaluation status is separate from RAG:

- Evaluated
- NotAssessed
- NotApplicable
- Skipped
- Error
- InsufficientEvidence
- Conflict

## RAG

RAG values are limited to:

- Green
- Amber
- Red
- Unknown

`NotAssessed` and `NotApplicable` are evaluation statuses and must never be stored or presented as RAG values.

## Value-source provenance

Approved value-source types:

- Observed
- CustomerProvided
- Imported
- Derived
- Assumed

`Calculated` is treated as a legacy synonym of `Derived` and is not a separate controlled value. Where operationally required, consultant-entered values must be represented through an explicitly governed source type rather than free-text wording.

## Classification backbone

Classification produces independent dimensions:

- Region
- Authority
- TechnicalStandard
- RegionalImplementation
- ProductDomain
- LifecycleContext
- ProductClass
- ProcedureContext where applicable

A display-level primary dossier type may be derived for reports, but it is not an authoring master dimension.

## Format taxonomy

### TechnicalStandard

Examples include:

- ICH eCTD 3.2.2
- eCTD 4.0
- NeeS
- VNeeS
- Non-eCTD Electronic
- Other
- Unknown

`Paper/Scanned` is governed as source presentation when it describes how source material is packaged rather than a regulatory technical standard.

### RegionalImplementation

Regional implementations are layered on a technical standard, for example:

- EU eCTD Module 1
- US FDA Module 1
- Canada Module 1
- UK Module 1
- Switzerland Module 1
- GCC Module 1
- EAEU Module 1

They must not be treated as mutually exclusive alternatives to the underlying technical standard.

### ProcedureContext

ASMF is a regulatory procedure or dossier context, not a technical submission format. Its technical standard and regional implementation are classified independently. Medical-device technical-file context must likewise be modelled in the appropriate product/procedure dimensions rather than automatically as a submission format.

## Source-of-truth terms

- **Authoring source of truth:** reviewed internal XLSM.
- **Runtime source of truth:** validated immutable JSON exported from the approved XLSM.
- **Execution source:** exact JSON version and checksum used by an execution.

## Prohibited wording

Reports and documentation must not claim that eMAS:

- performs migration;
- performs regulatory validation;
- completes customer validation;
- provides electronic approval;
- proves formal customer acceptance.