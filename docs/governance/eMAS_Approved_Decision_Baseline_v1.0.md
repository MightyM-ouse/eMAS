# eMAS Approved Decision Baseline v1.0

**Status:** Approved  
**Effective date:** 2026-07-13  
**Decision source:** `eMAS_Open_Questions_and_Decision_Register_v2_Claude_Reviewed(1).xlsx`

## Approval statement

The Product Owner approved adoption of the reviewed recommendations for all 171 tracked items across governance, runtime JSON, normalized rules, operational skills, PowerShell, documentation, XLSM/VBA/regulatory content and testing/release.

Approval establishes design decisions. It does not automatically complete implementation, native qualification, SME content approval or controlled release.

## Consolidated baselines

Approved decisions are consolidated into Enterprise Requirements v3.1, configuration requirements v3.0, Runtime JSON Contract v1.2, Normalized Rule Model v1.1, Relationship Matrix/Data Dictionary v1.0, Schema/Fixture Contract v1.0, Runtime JSON Schema 1.0.0, Solution Architecture/phase contracts and Operational Skills v1.0.0.

The XLSM/VBA POC and Conformance Contract v1.0 now controls the synthetic repository proof of concept and its automated/native evidence boundaries.

## Immediate canonical decisions

- reviewed internal XLSM = authoring source;
- validated immutable exported JSON = runtime source;
- exact loaded JSON/checksum = execution source;
- PowerShell never reads XLSM or generates/repairs JSON;
- Schema 1.0.0 and the frozen logical model control runtime serialization;
- operational skills are subordinate procedures;
- EvaluationStatus, RAG, ValueSource, confidence and review state remain separate;
- normalized classification dimensions remain separate and ASMF is ProcedureContext;
- Windows PowerShell 5.1 and offline/read-only runtime boundaries remain;
- XLSX reporting must not require Excel on the execution host;
- LLM-generated regulatory content remains Draft until required approval;
- accepted exceptions never erase original findings or evidence.

## XLSM/VBA POC state

Implemented in the repository:

- synthetic declarative 43-table workbook source;
- deterministic macro-free XLSX generation;
- nine reviewable VBA modules;
- fixture-aligned workbook semantic validation;
- deterministic reference export and golden JSON SHA-256;
- valid, controlled, boundary and negative cases;
- Runtime JSON Schema 1.0.0 conformance automation;
- Windows/Excel build and native-test scripts;
- automated unit tests and CI workflow.

Still required before controlled workbook release:

- reviewed native Excel/VBA execution evidence;
- Excel 2019/2021/Microsoft 365 and 32/64-bit qualification;
- German/English locale qualification;
- full controlled-workbook validation coverage;
- corporate signing/trust deployment;
- controlled release manifest and approval.

## Implementation-state rule

Approved, documented, implemented, automatically verified, natively qualified and released are distinct states. Detailed regulatory values, authority relationships, folder/file content, weights, thresholds and exception roles still require owner/SME evidence.

## Primary implementation sequence

1. Authority, precedence and terminology — **completed in PR #5**.
2. Requirements synchronization — **completed in PR #6**.
3. Logical-model freeze — **completed in PR #7**.
4. Schema 1.0.0 and independent fixtures — **completed in PR #8**.
5. Architecture and phase contracts — **completed in PR #9**.
6. Operational skills — **completed in PR #10**.
7. XLSM/VBA repository POC and automated conformance — **implemented in PR #11; native Excel qualification pending**.
8. PowerShell OpenXML/reporting spike, engine contracts and loader/phase conformance.
9. Regulatory/migration content under SME workflow.
10. Controlled templates, broader tests, release manifest, rollback and recall controls.
11. Version 2 archive closure.

## Public-repository handling

The detailed internal decision workbook, controlled production XLSM and customer/project evidence are not committed. All POC and test fixtures remain synthetic.

## Related documents

- `docs/configuration/09_eMAS_XLSM_VBA_POC_and_Conformance.md`
- `config/authoring/poc/README.md`
- `config/vba/README.md`
- `config/schema/eMAS-runtime-config.schema.json`
- `docs/llm-development-context/xlsm-vba-poc-route.yaml`
