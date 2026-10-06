# IdentificationInterpretation Oracle (T4a)

This is an independent, synthetic oracle for the bounded MS-04 Pre-Sales `IdentificationInterpretation` engine (T4b). Expected behavior is defined in [`BEHAVIOR_CONTRACT.md`](../../../docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE/BEHAVIOR_CONTRACT.md). The output shape is frozen in [`identification-1.0.schema.json`](identification-1.0.schema.json).

## Layout

| Path | Content |
|---|---|
| `manifest.json` | Case list, contract clauses exercised (`decisions`), comparison profile, and provisional cases (`provisionalPendingBlockers`) |
| `cases/IDO-nn/scanner-observations.json` | Synthetic `eMAS.MS04.PreSales.ScannerObservations/1.0` input with CEC evidence and coverage |
| `cases/IDO-nn/runtime-config.json` | Synthetic Runtime JSON Schema 1.1.0 configuration; valid under the unmodified T3a validator |
| `cases/IDO-nn/expected-identification.json` | Hand-authored expected `eMAS.MS04.PreSales.Identification/1.0` output |
| `identification-1.0.schema.json` | Frozen machine contract (no `Outcome`, no `SupportStatus`, no numeric score) |
| `validate_oracle.py`, `test_oracle_static.py` | Static package validation (not an engine) |

## Using the oracle (T4b)

For every case:
1. Run the engine on `scanner-observations.json` and `runtime-config.json`.
2. Remove the volatile fields `Execution.EngineVersion`, `Execution.StartedAtUtc` and `Execution.CompletedAtUtc` from both documents.
3. Require semantic JSON equality with `expected-identification.json`.

`EvidenceSource.DocumentSha256` and `RuntimeConfig.Sha256` are SHA-256 hashes of the exact fixture file bytes.

Implementations must not edit these expected files. A disagreement goes to central review (T4 coordination rule).

## Static validation

```bash
python -m pip install -r build/requirements-schema-validation.txt
python tests/identification-interpretation/oracle/validate_oracle.py
python -m unittest discover -s tests/identification-interpretation/oracle -p "test_*.py" -v
```

The validator checks:
- manifest/case completeness;
- the input and output contract IDs;
- that each runtime config is Schema 1.1.0 and valid under the T3a validator;
- Identification/1.0 schema conformance;
- forbidden fields and numeric values;
- input hashes;
- that cited EvidenceIds exist and match the immutable raw strength and tier;
- the fixed normalization;
- that rule IDs exist and output the cited dimension, value and polarity;
- that candidate codes exist in their declared dimension;
- the MEDIUM floor and v4 invariants;
- deterministic ordering and IDs;
- the shuffled-input equivalence case.

It does **not** evaluate rules. All data is synthetic, and the confidence rows are test policy, not approved content.
