# Normalized Rule Model Context

**Status:** Approved guidance

## Rule composition

A rule is not a flat row. It consists of:

- stable rule header;
- explicit phase assignments;
- OR-of-AND condition groups;
- typed outputs;
- finding reference;
- conflict strategy;
- lifecycle and supersession.

## Mandatory separation

- Findings are evidence statements.
- Recommendations are guidance.
- EvaluationStatus is not RAG.
- Exception treatment never changes original evidence.
- Rule lifecycle does not use editable IsActive.
- Master-data relationships use link tables, not comma-separated cells.

## Classification backbone

Use Region, Authority, TechnicalStandard, RegionalImplementation, ProcedureContext, SourcePresentation, ProductDomain, LifecycleContext and ProductClass.

ASMF is ProcedureContext, not TechnicalStandard. eCTD v4.0 v1 support is detect-and-classify only.
