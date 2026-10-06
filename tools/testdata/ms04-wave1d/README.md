# MS-04 Wave1D dossier-diversity test-data tools

Test-data utilities for task `EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D`. Nothing here is runtime code.

| File | Role |
|---|---|
| `wave1d_spec.py` | Declarative fixture definitions for SD-044 to SD-051: purpose, source profile, new dossier root(s) and synthetic unrelated files. Contains no expected results. |
| `derive_expectations.py` | **Derivation path 1 (transform).** Builds `tests/fixtures/dossier-diversity/wave1d-expectations.json` from the accepted Wave 1 SD-002/SD-010 expectations plus the spec. Never reads built fixtures. |
| `build_wave1d.py` | Deterministic builder (`build`) and package writer (`package`). Uses the Wave 1 ZIP conventions and checks the source fixtures against `WAVE1_FREEZE_MANIFEST.csv`. |
| `oracle_wave1d.py` | **Derivation path 2 (independent oracle).** Works only from the ZIP bytes: dossier and sequence discovery, backbone XML facts, references and MD5 checksums. `calibrate` proves it against accepted Wave 1 fixtures; `check` confirms the expectations. |

Requirements: Python 3.10+ with the standard library only, and PowerShell 7 for the harness.

## Recipe

```bash
# 0. Wave 1 test data extracted from eMAS_MS04_PreSales_Wave1_TestData_v1.zip (SHA-256 280af6f7…)
W1=<extracted>/eMAS_MS04_PreSales_Wave1_TestData_v1

# 1. Expectations first (transform derivation)
python3 tools/testdata/ms04-wave1d/derive_expectations.py --repo-root .

# 2. Oracle calibration against accepted Wave 1
python3 tools/testdata/ms04-wave1d/oracle_wave1d.py calibrate --wave1-root "$W1" --repo-root . --samples SD-001 SD-002 SD-010 SD-016 SD-020

# 3. Two clean builds, which must be byte-identical
python3 tools/testdata/ms04-wave1d/build_wave1d.py build --wave1-root "$W1" --out /tmp/w1dA --status FROZEN
python3 tools/testdata/ms04-wave1d/build_wave1d.py build --wave1-root "$W1" --out /tmp/w1dB --status FROZEN
diff -r /tmp/w1dA /tmp/w1dB

# 4. Independent oracle confirms the expectations (any disagreement → BLOCKED_EXPECTATION_DISAGREEMENT)
python3 tools/testdata/ms04-wave1d/oracle_wave1d.py check --corpus /tmp/w1dA \
  --expectations tests/fixtures/dossier-diversity/wave1d-expectations.json --out /tmp/oracle-report.json

# 5. Package
python3 tools/testdata/ms04-wave1d/build_wave1d.py package --build-dir /tmp/w1dA \
  --expectations-dir tests/fixtures/dossier-diversity --out-zip /tmp/eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1.zip

# 6. Mac regression (composed 8-capability chain)
pwsh -NoProfile -File tests/dossier-diversity/Test-eMASDossierDiversity.ps1 \
  -CorpusRoot /tmp/w1dA -OutputRoot /tmp/w1d-results -Wave1CorpusRoot "$W1"
```

Frozen fixtures must never be rebuilt in place under the same ID. Any change to a fixture needs a new version or a new fixture ID.
