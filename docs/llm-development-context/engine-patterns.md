# Engine and Evidence Patterns

**Status:** Effective implementation guidance

## Shared PowerShell engine

- Use modular technical components for discovery, normalization, evaluation, effort, readiness, reconciliation, reporting and logging.
- Phase-specific scripts select modules, inputs and evaluation depth; they must not duplicate shared business interpretation.
- The engine loads the validated runtime JSON, verifies version compatibility and records its checksum.
- The engine does not read the XLSM, generate JSON or repair invalid configuration.
- Source evidence is read-only.

## Reporting and logging

Every run produces:

- one timestamped UTF-8 execution log;
- one phase-specific controlled Excel report.

Logs and report execution metadata must capture where applicable:

- ExecutionId;
- phase code and display name;
- engine and script version;
- configuration version;
- schema version;
- JSON checksum;
- source inputs and access outcomes;
- checks performed and skipped;
- findings, warnings and errors;
- final phase-specific result;
- start, completion and duration.

A project may route outputs through Draft, Reviewed and Project Evidence Archive states, but the engine does not provide electronic approval or enforce customer validation.

## Evidence semantics

Value-source provenance is limited to:

- Observed;
- CustomerProvided;
- Imported;
- Derived;
- Assumed.

`Calculated` is a legacy synonym of `Derived`.

Evaluation status is recorded separately from provenance and RAG:

- Evaluated;
- NotAssessed;
- NotApplicable;
- Skipped;
- Error;
- InsufficientEvidence;
- Conflict.

RAG is limited to Green, Amber, Red and Unknown.

## Findings, recommendations and exceptions

- Findings describe observed or derived evidence.
- Recommendations describe proposed action and are linked separately.
- Accepted exceptions preserve the original finding and evidence.
- Exception policy may alter blocker or decision treatment only according to approved configuration.

## Traceability and ALCOA+ positioning

Maintain traceability from configuration version and rule ID through evaluation, evidence, finding and report output.

eMAS is designed to support ALCOA+-aligned traceability practices through attributable metadata, legible outputs, contemporaneous logs and preserved provenance. This does not by itself establish system validation, regulatory compliance or formal customer acceptance.
