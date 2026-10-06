# IdentificationInterpretation Oracle (T4a)

This is an independent, synthetic oracle for the bounded MS-04 Pre-Sales `IdentificationInterpretation` engine (T4b). Expected behavior is defined in [`BEHAVIOR_CONTRACT.md`](../../../docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE/BEHAVIOR_CONTRACT.md). The output shape is frozen in [`identification-1.0.schema.json`](identification-1.0.schema.json).

## Layout

| Path | Content |
|---|---|
| `manifest.json` | 23 cases: contract clauses exercised (`decisions`), `expectation` (`Output` or `Failure`), the closed central decisions a case depends on (`centralDecisions`), and the comparison profile |
| `cases/IDO-nn/scanner-observations.json` | Synthetic `eMAS.MS04.PreSales.ScannerObservations/1.0` input with CEC evidence and coverage |
| `cases/IDO-nn/runtime-config.json` | Synthetic Runtime JSON Schema 1.1.0 configuration; valid under the unmodified T3a validator |
| `cases/IDO-nn/expected-identification.json` | `Output` cases: hand-authored expected `eMAS.MS04.PreSales.Identification/1.0` output |
| `cases/IDO-nn/expected-failure.json` | `Failure` cases (IDO-23): the stable error code, the failing `RuleId`/`ConditionId`, and `OutputDocument: null` |
| `identification-1.0.schema.json` | Frozen machine contract (no `Outcome`, no `SupportStatus`, no numeric score) |
| `validate_oracle.py`, `test_oracle_static.py` | Static package validation (not an engine) |

## Using the oracle (T4b)

For every `Output` case:
1. Run the engine on `scanner-observations.json` and `runtime-config.json`, reading both **from the fixture files**.
2. Remove the volatile fields `Execution.EngineVersion`, `Execution.StartedAtUtc` and `Execution.CompletedAtUtc` from both documents.
3. Require semantic JSON equality with `expected-identification.json`.

For every `Failure` case, the engine must fail with the stated stable `ErrorCode` before evaluating rules, and write no Identification document. IDO-23 is an invalid `MATCHES_PATTERN` regex → `IDI-CONFIG-005`.

`EvidenceSource.DocumentSha256` and `RuntimeConfig.Sha256` are SHA-256 hashes of the exact fixture file bytes. This is the file-backed form of the provenance identity (contract §13). For an in-memory input with no supplied file hash, the contract allows a deterministic-serialization hash instead; the oracle always uses the file-backed form.

`MATCHES_PATTERN` uses explicit .NET `Regex` with `CultureInvariant` (plus `IgnoreCase` when `caseSensitive = false`), unanchored `IsMatch`, and a 1-second timeout. It never uses PowerShell `-match` (contract §6.1).

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
- that `MATCHES_PATTERN` conditions are well-formed;
- that failure cases carry a stable contract error code, point at a real rule condition, and expect no output document;
- that every cited contract clause exists in the behavioral contract;
- the MEDIUM floor and v4 invariants;
- deterministic ordering and IDs;
- the shuffled-input equivalence case.

It does **not** evaluate rules. The Python `re` syntax check on patterns is a sanity approximation of fixture intent only; the normative semantics are .NET. All data is synthetic, and the confidence rows are test policy, not approved content.
