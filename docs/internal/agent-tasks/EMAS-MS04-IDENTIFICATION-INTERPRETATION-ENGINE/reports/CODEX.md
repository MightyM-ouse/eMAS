# Codex Report — T4b IdentificationInterpretation Engine

**Status:** `IMPLEMENTED — AWAITING T4a CENTRAL ACCEPTANCE AND COORDINATION MERGE`
**Branch:** `implementation/emas-ms04-identification-interpretation-engine`
**Target:** `coordination/emas-ms04-identification-interpretation`
**Date:** 2026-10-06

## Implementation

- Shared-core module: `engine/core/eMAS.IdentificationInterpretation.psm1`.
- Public entry point: `Invoke-eMASIdentificationInterpretation -InputResult <object> -RuntimeConfiguration <object> [-EvidenceSourceSha256 <sha256>] [-OutputPath <path>]`.
- Bounded opt-in orchestration: `scripts/eMAS-PreSalesAssessment.ps1 -IncludeIdentificationInterpretation`.
- Engine tests: `tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1`.
- Read-only oracle harness: `tests/identification-interpretation/engine/Test-eMASIdentificationOracleConformance.ps1`.

## Behavior implemented

- Fixed `EVIDENCE-STRENGTH-NORMALIZATION/1`: `Strong→STRONG`, `Supporting→MEDIUM`, `Weak→WEAK`; unmapped strength becomes unavailable with `UnmappedStrength`.
- Fixed `CEC-FIELD-PROJECTION/1` for the ten T4a fields, including the in-document `XmlId→XmlDocuments.XmlKind` join. No repository file is reopened and no XML is reparsed.
- Three-state field and condition evaluation: Available / AssessedAbsent / Unavailable and True / False / Unknown.
- AND inside groups, OR across groups, negated guards without positive citations, and citations only from true groups.
- Supported bounded operators: `EQUALS`, `NOT_EQUALS`, `IN_LIST`, `CONTAINS`, `STARTS_WITH`, `ENDS_WITH`, `EXISTS`, `MISSING`.
- Hit strength is capped at the weakest cited normalized CEC evidence strength.
- Dimension-scoped candidates retain all rule IDs and raw/normalized evidence citations.
- Ordinal-only precedence `STRONG > MEDIUM > WEAK`; no numeric Identification weight or score.
- Configured final-value floor with `MEDIUM` default; Weak candidates remain visible without a final value.
- Equal best candidates and support contradicted at the best tier produce `Conflict`.
- Confidence comes only from Identification policy rows, including `NONE_REQUIRED` and `INDEPENDENT_SOURCE_CLASS`.
- Separate `eMAS.MS04.PreSales.Identification/1.0` output with the T4a exact shape; no `Outcome`, `SupportStatus`, projections, readiness conclusion, or numeric score.
- Deterministic subject, dimension, candidate, evidence, rule and limiting-factor ordering.
- UTF-8 without BOM output, guarded against Runtime JSON overwrite and source-repository writes.

## Validation

| Gate | Result |
|---|---|
| T4b focused engine | PASS — 21/21 |
| T4a oracle pre-merge trial | PASS — 21/21 |
| Runtime configuration PowerShell | PASS — 28/28 |
| Schema Python tests | PASS — 44/44 |
| Runtime static tests | PASS — 12/12 |
| Schema/semantic validator | PASS — all 43 fixture compositions |
| T3b XLSM/VBA validator | PASS — 53 checks |
| T3b VBA/export tests | PASS — 22/22 |
| Wave 1 RepositoryDiscovery | PASS |
| Wave 1 BackboneXmlInventory | PASS |
| Wave 1 ReferenceInventory | PASS |
| Wave 1 ReferenceResolution | PASS |
| Wave 1 MissingReferenceInterpretation | PASS |
| Wave 1 DeclaredChecksumComparison | PASS |
| Wave 1 ChecksumMismatchInterpretation | PASS |
| Wave 1 ClassificationEvidenceCollection | PASS |
| Root-level dossier | PASS — 3/3 |
| RepositoryDiscovery B3 | PASS — 12/12 |
| eCTD v4 discovery | PASS — 22/22 fixtures and 2/2 additional |
| Report mapping/tests | PASS — 3 maps and 28/28 tests |
| Operational skills | PASS — validator and 3/3 tests |
| macOS PowerShell 7 development execution | PASS |
| Windows PowerShell 7.6 CI | PASS — focused engine 21/21 |
| Windows PowerShell 5.1 CI | Focused engine PASS — 21/21; job remains red only for known unrelated UTF-8 expectation |

The independent oracle trial used the unmodified files on `analysis/emas-ms04-identification-interpretation-oracle` commit `a067baf11f6b964cddab9c805902e236f3599610`. It is not the formal acceptance run because that commit is not yet centrally accepted or merged into the coordination branch.

## Immutability proof

- Focused tests compare scanner and Runtime JSON object serialization before and after interpretation.
- The oracle harness compares scanner/runtime object serialization and exact source-file SHA-256 before and after all 21 cases.
- The engine receives CEC facts and validated configuration objects only; it contains no source traversal, XML parser, workbook reader or network call.

## Blockers / open issues

1. T4a central review still has seven provisional decisions (`B-1` through `B-7`) and its review status remains `BLOCKED_ON_CLAUDE`.
2. The T4a package has not been merged into `coordination/emas-ms04-identification-interpretation`; the formal required post-merge update and oracle run cannot yet be recorded.
3. Windows PowerShell 5.1 executed the focused engine suite successfully (21/21). Its job remains red only at the known unrelated RuntimeConfiguration UTF-8 expectation (`Expected=Synthetic UTF-8 â€“ PrÃ¼fung; Actual=Synthetic UTF-8 – Prüfung`), which this task is forbidden to fix.
4. The external Wave1D SD-044–SD-051 corpus is not present in the available workspace, so that optional broader regression was not rerun; the task-required Wave 1 chain is green.

No oracle file was modified. No T1b/T2 or T3c U2–U9 behavior was implemented.
