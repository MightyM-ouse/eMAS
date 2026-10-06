# eMAS Mapping Configuration XLSM/VBA Proof of Concept

**Version:** 0.2.0  
**Status:** Synthetic Proof of Concept  
**Schema:** Runtime JSON Schema 1.1.0 (Identification semantics)  
**Data classification:** Synthetic test data only

## Purpose

This folder contains the source-controlled, non-confidential proof of concept for the internal eMAS mapping workbook and VBA exporter.

The public repository does not contain a controlled production XLSM. It contains:

- a reviewable declarative workbook source defining 43 stable Excel Tables;
- a deterministic standard-library generator for the macro-free XLSX build input;
- exported reviewable VBA source;
- an internal Windows/Excel build script that imports the VBA and generates the XLSM;
- an independent table reader and reference exporter;
- valid, controlled, boundary and invalid workbook-model fixtures;
- an approved deterministic Runtime JSON SHA-256 golden hash;
- automated structural, deterministic and Runtime JSON Schema 1.1.0 conformance checks.

## Files

| Path | Purpose |
|---|---|
| `workbook-source.json` | Reviewable synthetic workbook/sheet/table/header/row definition |
| `poc-manifest.json` | Artifact versions, checksums, classification and native-test state |
| `fixtures/manifest.json` | Workbook-model fixture expectations and stable error codes |
| `fixtures/*.json` | Valid, controlled, boundary and negative table mutations |
| `../../vba/modules/*.bas` | Reviewable VBA implementation source |
| `../../../build/generate_emas_mapping_poc_workbook.py` | Deterministic macro-free XLSX generator |
| `../../../build/Build-eMASMappingPoc.ps1` | Internal Windows/Excel XLSM build |
| `../../../build/Test-eMASMappingPoc.ps1` | Native Excel/VBA execution and conformance evidence |
| `../../../build/validate_xlsm_vba_poc.py` | Independent source, fixture and schema validation |

Generated XLSX and XLSM files belong below local `output/` and `dist/`; neither is committed.

## Schema 1.1.0 Identification authoring (T3b)

| Table | Added column(s) | Notes |
|---|---|---|
| `tblValueLists` | `SortOrder` | Canonical Data Dictionary §13 column; carries the ordinal `EVIDENCE_STRENGTH` precedence STRONG(1) > MEDIUM(2) > WEAK(3) |
| `tblFieldCatalogue` | `MaxEvidenceStrength` | Ceiling for fields used as Identification evidence |
| `tblRules` | `LegacyRuleId` | **Workbook-only** informational traceability. Never a runtime identity and never exported. |
| `tblRuleOutputs` | `TargetEntityType`, `EvidenceStrength`, `EvidencePolarity` | Required on IDENTIFICATION `ClassificationCandidate` outputs only |
| `tblConflictPolicies` | `MinimumEvidenceStrengthForValue` | Synthetic Identification policy uses the accepted `MEDIUM` floor |
| `tblConfidencePolicies` | `ResultConfidence`, `CorroborationRule` | Identification rows carry no `WeightOrScore`; non-Identification rows keep it |

Controlled lists: `EVIDENCE_STRENGTH` (STRONG/MEDIUM/WEAK), `CONFIDENCE` (HIGH/MEDIUM/LOW/UNKNOWN), `EVIDENCE_POLARITY`, `TIE_BEHAVIOR`, `CORROBORATION_RULE`, `IDENTIFICATION_DIMENSION` (TECHNICAL_STANDARD, REGIONAL_IMPLEMENTATION), `RULE_TYPE` + `IDENTIFICATION`, and the full `RULE_LIFECYCLE_STATUS` set. `Supporting` is not an executable code; the engine-side `Supporting → MEDIUM` normalization is not implemented through aliases.

Synthetic rows: one Effective IDENTIFICATION rule `ID-SYN-TS-001` (TECHNICAL_STANDARD → `ICH_ECTD_3_2_2`, STRONG from a STRONG-capped field) and one Draft IDENTIFICATION rule `ID-SYN-RI-001` with `LegacyRuleId = LEGACY-SYN-001` and its own phase, group, condition and output rows. No historical mapping rule is imported.

### Runtime-eligibility projection

Every Runtime JSON export (DEV and CONTROLLED) uses one projection:

```text
Status = Effective AND EffectiveFrom <= evaluation date AND (EffectiveTo empty OR evaluation date < EffectiveTo)
```

A non-eligible rule is excluded together with its rule phases, condition groups, conditions, outputs and `RULE_SUPERSESSION` relationships, so the output has no orphan rows. The deterministic POC evaluation date is `2026-07-13`; normal DEV export uses the current UTC date. Reviewed rules are **not** exported in DEV either, because Runtime JSON Schema 1.0.0/1.1.0 requires `rule.status = Effective`.

Implementation: `build/emas_xlsx_poc_projection.py` (reference) and `config/vba/modules/modRuntimeProjection.bas` (VBA). `verify_runtime_projection` checks the projection independently (Draft leak, ineligible rule, orphan rows) and `scan_runtime_json_for_legacy` proves `LegacyRuleId` is absent from the serialized JSON. VBA additionally refuses to return JSON containing a `legacyRuleId` property or any `LegacyRuleId` value.

## Source and runtime boundaries

- `workbook-source.json` is a synthetic reproducible source-control artifact, not a controlled production authoring workbook.
- The generated internal XLSM is the POC authoring application.
- VBA validates the workbook and directly creates Runtime JSON in native execution.
- The generated and independently validated `eMAS_Runtime_Config.json` is the runtime source used by scripts.
- PowerShell invokes the deterministic workbook generator and desktop Excel for internal build/test; it does not construct, repair or reinterpret Runtime JSON.
- Python is used only for reproducible workbook generation and independent build/CI verification.

## Automated conformance

Run from the repository root:

```bash
python -m pip install -r build/requirements-schema-validation.txt
python build/validate_xlsm_vba_poc.py
python -m unittest discover -s tests/vba -p "test_*.py" -v
```

The automated check proves:

- the source definition generates a deterministic XLSX with 43 named tables;
- required named tables and critical columns exist;
- the synthetic table model passes workbook semantic validation;
- the independent reference export is deterministic;
- reference export exactly matches the approved golden JSON SHA-256 in `poc-manifest.json`;
- output is UTF-8 without BOM;
- valid and boundary cases pass;
- invalid cases fail with expected semantic codes;
- valid cases pass Runtime JSON Schema 1.1.0 and independent semantic validation;
- the runtime projection contains only runtime-eligible Effective rules, has no orphan rows and contains no `LegacyRuleId`;
- VBA modules contain required entry points and prohibited selection/unsafe short-circuit patterns are absent;
- source-definition, generated-workbook and golden JSON checksums match the POC manifest.

## Native Excel/VBA build and test

On a controlled Windows workstation with supported desktop Excel:

```powershell
.\build\Build-eMASMappingPoc.ps1
.\build\Test-eMASMappingPoc.ps1
```

The build temporarily requires Excel's **Trust access to the VBA project object model** setting so reviewed `.bas` files can be imported. Enable it only in the controlled build environment and disable it after the build.

The native test:

1. opens the generated XLSM;
2. runs workbook validation;
3. runs deterministic VBA export twice;
4. compares both exports;
5. compares the VBA export with the approved golden JSON SHA-256;
6. validates the export through the independent Schema 1.1.0 validator;
7. writes environment and checksum evidence below `output/`.

Native Excel execution is unavailable on GitHub-hosted Linux CI and remains a required manual qualification gate before controlled workbook release.

## POC limitations

- Production workbook signing is not included.
- Controlled production export is intentionally disabled in the public POC entry point.
- Full Excel 2019/2021/Microsoft 365, 32/64-bit and German/English locale qualification remains separate validation work.
- Regulatory master data is illustrative synthetic content and is not approved regulatory content.
- The POC VBA validator covers fixture-aligned critical cases; the controlled workbook must implement and qualify the complete mandatory validation sequence.
- Native Excel/VBA execution has not been claimed until `Test-eMASMappingPoc.ps1` evidence is reviewed. Current status: `NATIVE_EXCEL_QUALIFICATION_PENDING`.
- Identification rows are synthetic conformance content, not approved regulatory or confidence policy content.
