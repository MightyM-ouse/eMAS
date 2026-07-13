# eMAS PowerShell Developer Guide

**Version:** 3.1  
**Status:** Approved  
**Runtime baseline:** Windows PowerShell 5.1

## 1. Module packaging

Each shared component is a versioned `.psm1` module with a `.psd1` manifest declaring `ModuleVersion` and `PowerShellVersion = '5.1'`.

Phase scripts import modules by repository-relative path. Customer packaging may generate a merged single-file Pre-Sales script from the same approved module sources.

## 2. Module responsibilities

- Configuration: JSON load, version, checksum, structure and reference checks.
- Discovery: files, folders, counts, sizes, access and path evidence.
- Classification: candidate evidence and dimension resolution.
- Validation: folder, file, XML and referenced-file checks.
- Effort: drivers, thresholds, minimum bands and confidence.
- Readiness: prerequisites, blockers, actions and baseline.
- Reconciliation: keys, expected/observed comparison and discrepancies.
- Reporting: template contract and named-target population.
- Logging: structured events.
- Utilities: normalization, hashing, dates, safe conversion and progress events.

## 3. Configuration loader contract

`Get-EmasConfiguration` shall:

1. confirm file existence;
2. read UTF-8;
3. parse JSON with appropriate depth;
4. enforce supported schema major and minimum engine version;
5. verify controlled checksum;
6. validate mandatory sections;
7. validate IDs, references and operators;
8. return a typed immutable configuration object;
9. log configuration version and hash.

## 4. Stable object contracts

Factory functions construct explicit PSCustomObjects. Dynamic property addition is prohibited after construction.

Required contracts include EvidenceRecord, EvaluationResult, FindingRecord, ExceptionAdjustment, BaselineRecord, ReconciliationRecord, ReportRow and ExecutionContext.

## 5. Logging

One append-only UTF-8 log per execution. Each line contains:

`ISO8601 UTC | Severity | Phase | Component | EventCode | ExecutionId | RuleId/FindingCode | Message`

Severity: DEBUG, INFO, WARN, ERROR.

Error taxonomy:

- ConfigurationError;
- InputError;
- AccessWarning;
- TechnicalError;
- DataQualityFinding;
- Limitation.

## 6. Progress

Use a shared progress event model. CLI renders `Write-Progress` plus periodic INFO output. WPF subscribes to the same events.

## 7. Comparison keys

Normalize dossier identifiers through approved aliases, trim and case-normalize. SequenceKey is DossierKey plus zero-padded sequence number. No fallback fuzzy matching is allowed without an explicit reviewed alias.

## 8. Exceptions

Project exceptions use a controlled XLSX input with named table `Accepted_Exceptions`. Validate policy, scope, finding, approver, evidence, expiry and carry-forward before applying adjustments.

## 9. OpenXML reporting

Populate copies of controlled templates through named tables/ranges. Preserve source evidence and template structure. Do not use Excel COM automation.

## 10. Security

Do not log credentials, file content, connection secrets or confidential business content. Paths and filenames may be logged only under the approved redaction policy.

## 11. Definition of Done

- no business or regulatory interpretation hardcoded in PowerShell;
- modules compatible with 5.1;
- unit and integration tests added;
- structured logging and traceability present;
- all affected phases assessed;
- template and schema compatibility verified;
- source data remains read-only.
