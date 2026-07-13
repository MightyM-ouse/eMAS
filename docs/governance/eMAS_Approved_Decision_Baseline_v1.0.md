# eMAS Approved Decision Baseline v1.0

**Status:** Approved  
**Effective date:** 2026-07-13  
**Decision source:** `eMAS_Open_Questions_and_Decision_Register_v2_Claude_Reviewed(1).xlsx`

## Approval statement

The Product Owner reviewed the evidence-based recommendation register and approved adoption of the AI-recommended decision for all 171 tracked items across:

1. Authority, precedence and governance
2. Runtime JSON contract
3. Normalized rule model
4. Operational LLM skills
5. PowerShell engine and functions
6. Requirements and documentation synchronization
7. XLSM, VBA and regulatory content
8. Testing, compatibility and release

Approval establishes the design decision. It does not mean every implementation, PowerShell module, workbook component, template, test or release control is complete.

## Consolidation status

The approved decisions are consolidated into:

- `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md`;
- configuration requirements Versions 3.0;
- Runtime JSON Contract Version 1.2;
- Normalized Rule Model Version 1.1;
- Normalized Relationship Matrix Version 1.0;
- Logical Data Dictionary Version 1.0;
- Schema Validation and Fixture Contract Version 1.0;
- Runtime JSON Schema Version 1.0.0 and its fixture suite;
- Solution Architecture Version 1.0;
- Project Flow Version 2.0;
- Repository Architecture Version 1.1;
- Pre-Sales, Pre-Migration and Post-Migration Phase Contracts Version 1.0.

Enterprise Requirements v3.1 remains the active authority-rank-1 product baseline.

## Immediate canonical decisions

- The authority and precedence policy is Effective.
- Authoring, runtime and execution source terminology is Effective.
- Runtime JSON Schema 1.0.0 is the Effective machine-readable baseline.
- The normalized rule, lifecycle, phase, condition, output, finding, recommendation, conflict and exception models are approved.
- The normalized relationship matrix and logical data dictionary are frozen at Version 1.0.
- The independent schema/semantic fixture contract is Effective.
- Solution Architecture Version 1.0 and all three phase contracts are Effective.
- Evaluation status, RAG and value-source provenance remain separate.
- Technical standard, regional implementation and procedure context remain separate.
- ASMF is ProcedureContext, not TechnicalStandard.
- Windows PowerShell 5.1 remains the runtime baseline unless changed through controlled change.
- Source XLSX generation must run without Microsoft Excel installed and without unapproved external PowerShell modules; the OpenXML implementation spike remains required.
- Python and `jsonschema` are build/CI validation dependencies only, not customer or runtime dependencies.
- Pre-Sales remains CLI/simple-launcher based, lightweight and free of readiness terminology.
- Pre-Migration creates the approved reusable comparison baseline.
- Post-Migration consumes the approved baseline and agreed `MigrationSummary.xlsx` detail.
- Accepted exceptions never erase original findings, RAG, discrepancies or evidence.

## Implementation-state rule

Items classified as `Implementation Pending`, `SME Review Pending`, `Test Pending`, `Release-Control Pending`, `Deferred`, `Obsolete` or `Blocked` retain that delivery state unless completion evidence exists.

Detailed regulatory values, authority relationships, folder/file content, effort weights, confidence weights, thresholds and exception-role content still require the approved owner or SME evidence before Effective configuration status.

Completing architecture and phase contracts does not mean the XLSM/VBA exporter, PowerShell loader/engine, WPF, report templates or release packages implement those contracts. Conformance remains separately tracked.

## Public-repository handling

The detailed internal decision workbook is not committed to the public repository. This sanitized baseline is the repository traceability record. All committed fixtures are synthetic.

## Primary implementation sequence

1. Apply authority, precedence, statuses and terminology. **Completed in PR #5.**
2. Synchronize Enterprise Requirements and configuration requirements. **Completed in PR #6.**
3. Freeze the normalized logical model, relationship matrix and data dictionary. **Completed in PR #7.**
4. Complete and validate JSON Schema 1.0.0 and fixtures. **Completed in PR #8.**
5. Update architecture and phase contracts. **Completed in PR #9.**
6. Implement operational skills.
7. Complete the XLSM/VBA proof of concept and validator conformance.
8. Complete the PowerShell OpenXML/reporting spike, engine contracts and loader/phase conformance.
9. Populate regulatory and migration content under the approved SME workflow.
10. Complete report templates, broader tests, release manifest, rollback and recall controls.
11. Supersede or archive all conflicting Version 2 documentation.

## Related canonical documents

- `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md`
- `docs/configuration/README.md`
- `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
- `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md`
- `docs/configuration/07_eMAS_Data_Dictionary.md`
- `docs/configuration/08_eMAS_Schema_Validation_and_Fixture_Contract.md`
- `config/schema/eMAS-runtime-config.schema.json`
- `config/schema/examples/fixture-manifest.json`
- `docs/architecture/eMAS_Solution_Architecture.md`
- `docs/architecture/eMAS_Project_Flow.md`
- `docs/architecture/eMAS_Repository_Architecture.md`
- `docs/architecture/phase-contracts/README.md`
