# eMAS Controlled Terminology

**Version:** 1.0  
**Status:** Effective  
**Decision references:** DEC-2026-010, DEC-2026-109 through DEC-2026-113

This catalogue is the authoritative source for codes and display terms used in requirements, JSON, logs, reports, skills and user guidance.

## Assessment phases

| Code | Display name | Final result vocabulary |
|---|---|---|
| `PRE_SALES` | Pre-Sales Assessment | Complexity: Very Low, Low, Medium, High, Very High; confidence: High, Medium, Low, Unknown |
| `PRE_MIGRATION` | Pre-Migration Readiness | Ready; Ready with Accepted Exceptions; Blocked |
| `POST_MIGRATION` | Post-Migration Verification | Reconciled; Reconciled with Accepted Exceptions; Review Required; Not Reconciled |

`Post-Migration Reconciliation` may describe the activity, but the controlled phase display name is `Post-Migration Verification`.

## RAG and evaluation

### RAG

- Green
- Amber
- Red
- Unknown

### Evaluation status

- Evaluated
- NotAssessed
- NotApplicable
- Skipped
- Error
- InsufficientEvidence
- Conflict

`NotAssessed` and `NotApplicable` are never RAG values.

## Value source types

- Observed
- CustomerProvided
- Imported
- Derived
- Assumed

`Calculated` is a deprecated synonym for `Derived`. `ConsultantEntered`, where retained operationally, is a subtype of `CustomerProvided`.

## Document statuses

Draft, InReview, Approved, Final, Effective, Superseded, Archived.

## Rule lifecycle

Draft, InReview, Reviewed, Effective, Superseded, Retired.

## Migration scenarios

- `SQL_TO_SQL`
- `ACCESS_TO_SQL`
- `ORACLE_TO_SQL`
- `EXTERNAL_DOSSIER`
- `HYBRID`
- `ARCHIVE_SIZING`
- `UNKNOWN_REPOSITORY`

## Safe positioning statement

> eMAS supports GxP-oriented, ALCOA+-aligned traceability practices; it does not perform regulatory validation, does not replace customer validation, and does not establish electronic approval or formal acceptance.

## Identifier prefixes

`REQ-`, `SRS-`, `FR-`, `TR-`, `ENG-`, `UI-`, `RPT-`, `LOG-`, `TST-`, `DEC-`, `RULE-`, `COND-`, `GRP-`, `OUT-`, `PH-`, `FND-`, `REC-`, `LNK-`, `EXCP-`, `FIELD-`, `METRIC-`, `VAL-`, `ALIAS-`.
