# eMAS Approved Decision Baseline v1.0

**Status:** Approved  
**Effective date:** 2026-07-13  
**Decision source:** `eMAS_Open_Questions_and_Decision_Register_v2_Claude_Reviewed(1).xlsx`

## Approval statement

The Product Owner approved adoption of the AI-recommended decision for all 171 tracked items across governance, runtime JSON, normalized rule/configuration models, operational skills, PowerShell, requirements/documentation, XLSM/VBA/regulatory content and testing/release.

Approval establishes design decisions. It does not automatically complete implementation, testing, SME content approval or controlled release.

## Consolidated effective baselines

- Enterprise Requirements v3.1;
- Mapping Configuration Requirements and Content Catalogue v3.0;
- Runtime JSON Contract v1.2;
- Normalized Rule Model v1.1;
- Normalized Relationship Matrix v1.0;
- Logical Data Dictionary v1.0;
- Runtime JSON Schema 1.0.0 and Schema Validation/Fixture Contract v1.0;
- Solution Architecture v1.0;
- Project Flow v2.0 and Repository Architecture v1.1;
- three Phase Contracts v1.0.

## Canonical decisions

- reviewed internal XLSM = authoring source;
- validated immutable exported JSON = runtime source;
- exact JSON/checksum loaded for a run = execution source;
- PowerShell never reads the XLSM or generates/repairs JSON;
- one shared runtime JSON and shared PowerShell engine serve all phases;
- phase scripts control phase-specific orchestration;
- WPF is limited to Pre-/Post-Migration and invokes the same scripts;
- source evidence remains read-only;
- findings/recommendations, EvaluationStatus/RAG/ValueSource/confidence and original finding/exception treatment remain separate;
- ASMF is ProcedureContext, not TechnicalStandard;
- Python schema tooling is build/CI-only;
- report generation must be OpenXML-compatible and must not require Excel on the execution host.

## Implementation-state rule

Detailed regulatory values, authority relationships, folder/file content, weights, thresholds and exception-role content still require approved owner/SME evidence. Completing architecture contracts does not mean entry scripts, engine modules, WPF, XLSM/VBA, templates or release packages are implemented.

## Primary implementation sequence

1. Authority, precedence, statuses and terminology — **Completed in PR #5**.
2. Enterprise/configuration requirements synchronization — **Completed in PR #6**.
3. Logical-model, relationship-matrix and data-dictionary freeze — **Completed in PR #7**.
4. Runtime JSON Schema 1.0.0 and independent fixture validation — **Completed in PR #8**.
5. Solution Architecture and three phase contracts — **Completed in PR #9**.
6. Implement operational LLM skills.
7. Complete XLSM/VBA proof of concept and schema-fixture conformance.
8. Complete PowerShell/OpenXML spike, engine contracts and loader/phase conformance.
9. Populate regulatory/migration content under SME workflow.
10. Complete controlled templates, broader tests, release manifest, rollback and recall controls.
11. Close remaining Version 2 supersession actions.

## Public-repository handling

The detailed internal decision workbook, controlled internal XLSM and customer/project evidence are not committed to the public repository. Repository fixtures remain synthetic.
