# eMAS Software Requirements Specification

**Version:** 3.1  
**Status:** Approved  
**Authority:** Enterprise Requirements v3.1 and approved decision log

## 1. Functional areas

| Prefix | Area |
|---|---|
| SRS-GEN | Global behaviour |
| SRS-PS | Pre-Sales |
| SRS-PM | Pre-Migration |
| SRS-POST | Post-Migration |
| SRS-CFG | Configuration |
| SRS-JSON | Runtime JSON |
| SRS-ENG | Shared engine |
| SRS-RPT | Reports and logs |
| SRS-UI | WPF |
| SRS-SEC | Security and privacy |

## 2. Global requirements

- **SRS-GEN-001 MUST:** remain read-only against customer source evidence.
- **SRS-GEN-002 MUST:** support command-line execution for all phases.
- **SRS-GEN-003 MUST:** load one runtime JSON through `-ConfigPath`.
- **SRS-GEN-004 MUST:** record execution, engine, schema, mapping and template versions.
- **SRS-GEN-005 MUST:** use controlled codes and display terms from the terminology catalogue.
- **SRS-GEN-006 MUST:** represent unavailable input as NotAssessed or Unknown according to the evaluation contract, never Green.
- **SRS-GEN-007 MUST:** stop on invalid controlled configuration and continue with explicit limitations for unavailable optional customer evidence.

## 3. Pre-Sales

- **SRS-PS-001 MUST:** remain lightweight.
- **SRS-PS-002 MUST:** collect accessibility, counts, sizes, dossier/sequence indicators and high-level classification evidence.
- **SRS-PS-003 MUST:** calculate complexity band and estimate confidence.
- **SRS-PS-004 MUST:** generate customer clarification items.
- **SRS-PS-005 MUST NOT:** perform deep referenced-file, checksum, XML integrity or migration-readiness validation.
- **SRS-PS-006 MUST:** support the seven controlled MigrationScenario codes.

## 4. Pre-Migration

- **SRS-PM-001 MUST:** execute the approved detailed readiness matrix.
- **SRS-PM-002 MUST:** assess access, backup, staging, storage, long-path, zero-byte, XML, referenced-file, sequence and structural findings.
- **SRS-PM-003 MUST:** apply exception policies and project exception evidence without changing original findings.
- **SRS-PM-004 MUST:** generate a `Baseline_Data` named table using the frozen baseline contract.
- **SRS-PM-005 MUST:** produce Ready, Ready with Accepted Exceptions or Blocked.

## 5. Post-Migration

- **SRS-POST-001 MUST:** consume the controlled Pre-Migration baseline.
- **SRS-POST-002 MUST:** use normalized DossierKey and SequenceKey comparison keys.
- **SRS-POST-003 MUST:** reconcile expected, import and post-import evidence.
- **SRS-POST-004 MUST:** preserve accepted exceptions, carried-forward exceptions and original discrepancies separately.
- **SRS-POST-005 MUST:** produce Reconciled, Reconciled with Accepted Exceptions, Review Required or Not Reconciled.

## 6. Configuration

- **SRS-CFG-001 MUST:** validate fixed tables, columns, data types, IDs, references, lifecycle, phase assignments, conditions, outputs, thresholds, conflicts, findings, recommendations, exception policies and compatibility.
- **SRS-CFG-002 MUST:** block controlled export for structural or referential errors.
- **SRS-CFG-003 MUST:** export deterministic, invariant-culture UTF-8 JSON.
- **SRS-CFG-004 MUST:** preserve lifecycle history in the XLSM and export only Effective runtime entities.
- **SRS-CFG-005 MUST:** use dedicated relationship tables; comma-separated multi-value relationships are prohibited.

## 7. Runtime JSON

- **SRS-JSON-001 MUST:** validate against the approved schema in CI and through loader structural/reference checks.
- **SRS-JSON-002 MUST:** reject unknown executable properties and operators.
- **SRS-JSON-003 MUST:** permit only documented descriptive extension points.
- **SRS-JSON-004 MUST:** use ISO 8601 UTC timestamps and ISO dates.
- **SRS-JSON-005 MUST:** use invariant decimal serialization.
- **SRS-JSON-006 MUST:** record rulesContentHash separately from volatile export metadata.

## 8. Engine

- **SRS-ENG-001 MUST:** package the ten approved modules as versioned `.psm1` modules with `.psd1` manifests.
- **SRS-ENG-002 MUST:** expose typed contracts for configuration, evidence, evaluation, finding, exception, baseline, reconciliation and report rows.
- **SRS-ENG-003 MUST:** emit shared progress events usable by console and WPF.
- **SRS-ENG-004 MUST:** use structured UTF-8 logging with ISO UTC timestamp, severity, phase, component, event code and identifiers.
- **SRS-ENG-005 MUST:** use the approved error taxonomy.
- **SRS-ENG-006 MUST:** write reports only through named template contracts.

## 9. Reports

- **SRS-RPT-001 MUST:** use separate controlled templates for each phase.
- **SRS-RPT-002 MUST:** include summary, scope, findings, limitations and execution details.
- **SRS-RPT-003 MUST:** show original and exception-adjusted result values side by side where exceptions apply.
- **SRS-RPT-004 MUST:** avoid claims of regulatory validation, formal acceptance or migration completion.
- **SRS-RPT-005 MUST:** open without repair.

## 10. WPF

- **SRS-UI-001 MUST:** remain optional and limited to Pre-Migration and Post-Migration.
- **SRS-UI-002 MUST:** invoke the same entry scripts and shared engine.
- **SRS-UI-003 MUST NOT:** contain separate business or regulatory decision logic.

## 11. Security and repository safety

- **SRS-SEC-001 MUST:** exclude credentials, file-content excerpts and confidential customer evidence from logs and source control.
- **SRS-SEC-002 MUST:** allow technical paths and filenames only where necessary for traceability and subject to approved redaction policy.
- **SRS-SEC-003 MUST:** digitally sign controlled VBA releases using the corporate process.
- **SRS-SEC-004 MUST:** retain recalled and superseded artifacts with explicit markers; never silently delete them.

## 12. Verification

Each requirement shall map to design artifacts, code/configuration, tests and evidence in the traceability matrix.
