# eMAS Test Strategy

**Version:** 3.1  
**Status:** Approved

## 1. Test levels

- unit;
- integration;
- scenario;
- regression;
- performance;
- compatibility;
- security and repository-safety;
- user acceptance;
- release verification.

## 2. Fixture governance

Synthetic fixtures are stored under `tests/fixtures/<category>/<scenario>/` and include source trees, input workbooks, runtime JSON, expected normalized objects, expected findings and expected report extracts.

Fixtures are labelled Illustrative, Golden Fixture or Deprecated.

## 3. Mandatory coverage

- all migration scenarios;
- Green/Amber/Red/Unknown outcomes;
- EvaluationStatus values;
- invalid JSON and schema-version handling;
- duplicate IDs and broken references;
- OR-of-AND conditions;
- every conflict strategy;
- threshold boundary values;
- lifecycle and supersession;
- exception eligibility, expiry, scope and effects;
- deterministic export and hash;
- aliases and comparison keys;
- template validity;
- long path, access, zero-byte and unreadable XML;
- post-migration missing and extra items;
- eCTD v4.0 detect-and-classify;
- de-DE locale JSON export;
- release recall metadata.

## 4. Schema validation

CI validates JSON fixtures against `schemas/eMAS-runtime-config.schema.json`. The runtime PowerShell 5.1 loader performs structural and reference validation because `Test-Json` is unavailable.

## 5. Performance profiles

Small, typical, large and extreme profiles must be supplied by Migration SMEs and used for workbook validation/export, discovery, report generation and reconciliation tests.

## 6. Report validation

Automated checks confirm OpenXML structure, required sheets, named tables, template version and absence of prohibited legacy phrases. Human review covers readability and decision usefulness.

## 7. Skill evaluations

Every operational skill has:

- positive invocation;
- negative routing;
- stop-condition;
- output-completeness scenario.

## 8. CI

Pull requests run schema validation, PowerShell/Pester tests, documentation consistency and safety checks. Release tags run packaging and checksum-manifest verification when release artifacts are complete.

## 9. Release acceptance

Evidence includes requirement and Decision IDs, versions, command, input fixture, expected/actual result, evidence files, reviewer and pass/fail status.
