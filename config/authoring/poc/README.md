# eMAS Mapping Configuration XLSM/VBA Proof of Concept

**Version:** 0.1.0  
**Status:** Synthetic Proof of Concept  
**Schema:** Runtime JSON Schema 1.0.0  
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
- automated structural, deterministic and Runtime JSON Schema 1.0.0 conformance checks.

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
- valid cases pass Runtime JSON Schema 1.0.0 and independent semantic validation;
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
6. validates the export through the independent Schema 1.0.0 validator;
7. writes environment and checksum evidence below `output/`.

Native Excel execution is unavailable on GitHub-hosted Linux CI and remains a required manual qualification gate before controlled workbook release.

## POC limitations

- Production workbook signing is not included.
- Controlled production export is intentionally disabled in the public POC entry point.
- Full Excel 2019/2021/Microsoft 365, 32/64-bit and German/English locale qualification remains separate validation work.
- Regulatory master data is illustrative synthetic content and is not approved regulatory content.
- The POC VBA validator covers fixture-aligned critical cases; the controlled workbook must implement and qualify the complete mandatory validation sequence.
- Native Excel/VBA execution has not been claimed until `Test-eMASMappingPoc.ps1` evidence is reviewed.
