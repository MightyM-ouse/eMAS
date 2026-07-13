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

Approval establishes the design decision. It does not mean every implementation, document revision, schema fixture, PowerShell module, workbook component, template or test is complete.

## Immediate canonical decisions

- Enterprise Requirements v3.0 remains the primary solution baseline, amended by this approved decision baseline until the next consolidated v3.x revision.
- The authority and precedence policy is effective.
- Authoring, runtime and execution source terminology is effective.
- The normalized JSON contract and schema path are approved.
- The normalized rule, lifecycle, phase, condition, output, finding, recommendation, conflict and exception models are approved.
- Evaluation status and RAG remain separate.
- The classification taxonomy separates technical standard, regional implementation and procedure context.
- ASMF is a procedure context, not a technical submission format.
- The operational LLM skill structure and mandatory stop conditions are approved.
- Windows PowerShell 5.1 remains the runtime baseline unless later changed through controlled change.
- Source XLSX generation must run without Microsoft Excel installed and without unapproved external PowerShell modules; the OpenXML implementation spike remains required.
- Documentation, schema, workbook/VBA, engine, templates, tests and release controls must now be synchronized to these decisions.

## Implementation-state rule

Items previously classified as `Implementation Pending`, `Documentation Sync Pending`, `SME Decision Required`, `Deferred`, `Duplicate`, `Obsolete` or `Blocked` retain that delivery classification unless the approved recommendation explicitly changes it. The decision is approved; the work item is not automatically complete.

## Public-repository handling

The detailed internal workbook is not committed to the public repository because it contains internal review context and controlled metadata. This sanitized baseline is the repository traceability record. Detailed evidence remains in approved internal storage.

## Primary implementation sequence

1. Apply authority, precedence, statuses and terminology.
2. Synchronize Enterprise Requirements and configuration requirements.
3. Freeze the normalized logical model and relationship matrix.
4. Complete and validate JSON Schema 1.0.0 and fixtures.
5. Update architecture and phase contracts.
6. Implement operational skills.
7. Complete the XLSM/VBA proof of concept.
8. Complete the PowerShell OpenXML/reporting spike and engine contracts.
9. Populate regulatory and migration content under the approved SME workflow.
10. Build tests, CI, release manifest, rollback and recall controls.
11. Supersede or archive all conflicting Version 2 documentation.

## Related canonical documents

- `docs/governance/00_authority_and_precedence.md`
- `docs/governance/eMAS_Terminology.md`
- `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`
- `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
- `config/schema/eMAS-runtime-config.schema.json`
- `docs/llm-development-context/skills/README.md`
