# Codex implementation report

## Identity

- Task: `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`
- Authoritative design base: `e9530adb6f2e8b31035ca27f7267d6a2de25081d`
- Implementation branch: `implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`
- Implementation commit: `b1a4feb2a7c7bb3e11665ded2d66c05044a28de0`
- Report publication commit: recorded as the PR head and in the worker return because a commit cannot embed its own SHA
- Draft PR: [#60](https://github.com/MightyM-ouse/eMAS/pull/60)
- Target: `coordination/emas-ms04-regional-xml-evidence-t1b-design`

The implementation branch descends from the authoritative base. The formal task order was present at branch start.

## Pre-change baseline

Baseline ran before production edits on macOS / PowerShell Core 7.5.2.

| Gate | Result |
|---|---|
| BackboneXmlInventory | PASS: 6 primary + 13 regression fixtures; 3 additional checks; 19/19 hashes before and after |
| ClassificationEvidenceCollection | PASS: 19 fixtures; 38 additional checks; Wave 1 19/19 and Wave1E 22/22 hashes before and after |
| Wave 1 accepted eight suites | PASS: all 8 suites |
| Wave1D | PASS: 61/61; 8/8 frozen fixtures unchanged |
| T4 focused engine | PASS: 28/28 |
| T4 accepted oracle | PASS: 23/23 |

Baseline commands used the frozen Wave 1 corpus at `/Users/vinay/Projects/AI/eMAS/02_Working/MS-04-PreSales-Wave1`, its accepted freeze manifest, and the accepted Wave1D corpus. Each accepted Wave 1 harness was invoked with `pwsh -NoProfile -NonInteractive -File`, `-CorpusRoot`, `-FreezeManifestPath`, and an isolated `/private/tmp/emas-t1b-baseline-*` output directory. T4 commands were:

```text
pwsh -NoProfile -NonInteractive -File tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1
pwsh -NoProfile -NonInteractive -File tests/identification-interpretation/engine/Test-eMASIdentificationOracleConformance.ps1
```

## Implementation

BXI now calls a private EU envelope helper with the DOM already loaded by its bounded safe XML reader. No additional source read or XML parse occurs. ScannerObservations remains `eMAS.MS04.PreSales.ScannerObservations/1.0`; the BXI scanner implementation version is `0.3.0`.

The helper supports exactly profiles `2.0`, `3.0.1`, and `3.1`, using exact profile-scoped vocabulary tables accepted in the T1b design. It matches `eu-backbone` by local-name and the `http://europa.eu.int` namespace URI, requires unqualified envelope descendants, preserves 1-based document-order envelope ordinals, and never resolves a DTD.

CEC consumes only `XmlDocuments[].RegionalEnvelope`. It emits exactly:

1. `EuEnvelopeCountry`
2. `EuAgencyCode`
3. `EuProcedureType`
4. `EuSubmissionType`
5. `EuSubmissionUnitType`

Recognized records use `Strong` / `StructuredXml`, retain the accepted legacy `Region` or `DossierContext` compatibility hint, and leave `CandidateValue`, `Polarity`, and `SourceRuleId` null. `SourceOrdinal` exists only on these five new evidence types. New records use sort group 2; historical and T1a sort keys and EvidenceIds are unchanged.

Field coverage distinguishes `MandatoryFieldAbsent`, `FieldNotDefinedInProfile`, `SourceXmlMissing`, `SourceXmlParseFailed`, `SourceXmlUnavailable`, `UnsupportedRegionalProfile`, `UnrecognizedRegionalStructure`, `ValueOutsideProfileVocabulary`, `CardinalityViolation`, and `EnvelopeValuesDiffer`. Unknown values remain raw BXI facts and do not become Strong CEC records. No normalization is performed, including `ema` versus `EU-EMA`.

## Files changed

Production:

- `engine/powershell51/eMAS.BackboneXmlInventory.psm1`
- `engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1`
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`

Tests:

- `tests/backbone-xml-inventory/Test-eMASBackboneXmlInventory.ps1`
- `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1`
- `tests/dossier-diversity/Test-eMASDossierDiversity.ps1`
- `tests/regional-xml-evidence/Test-eMASRegionalXmlEvidence.ps1`

Synthetic read-only fixtures:

- `tests/fixtures/regional-xml-evidence/default-namespace-envelope.xml`
- `tests/fixtures/regional-xml-evidence/eu20.xml`
- `tests/fixtures/regional-xml-evidence/eu301.xml`
- `tests/fixtures/regional-xml-evidence/eu31-duplicate-agency.xml`
- `tests/fixtures/regional-xml-evidence/eu31-missing-unit.xml`
- `tests/fixtures/regional-xml-evidence/eu31-multiple-prefix.xml`
- `tests/fixtures/regional-xml-evidence/eu31-unknown.xml`
- `tests/fixtures/regional-xml-evidence/malformed.xml`
- `tests/fixtures/regional-xml-evidence/missing-profile.xml`
- `tests/fixtures/regional-xml-evidence/root-namespace-mismatch.xml`
- `tests/fixtures/regional-xml-evidence/unsupported-profile.xml`

Report:

- `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/reports/CODEX.md`

No frozen Wave 1, Wave1D, or Wave1E fixture byte was changed. No expectation JSON was changed.

## Post-change qualification

Platform: macOS, PowerShell Core 7.5.2.

### Focused EU-envelope suite

```text
pwsh -NoProfile -NonInteractive -File tests/regional-xml-evidence/Test-eMASRegionalXmlEvidence.ps1 -OutputRoot /private/tmp/emas-t1b-focused-final
```

PASS: 10/10 checks. All 11 new fixture hashes and timestamps matched before and after. The suite covers the three profiles, multiple envelopes, prefix variation, missing/unknown/multiple fields, unsupported and unrecognized structures, evidence shape, field coverage, deterministic identity under reordered input facts, and mocked-source CEC execution.

### BXI and CEC

```text
pwsh -NoProfile -NonInteractive -File tests/backbone-xml-inventory/Test-eMASBackboneXmlInventory.ps1 -CorpusRoot /Users/vinay/Projects/AI/eMAS/02_Working/MS-04-PreSales-Wave1 -FreezeManifestPath /Users/vinay/Projects/AI/eMAS/outputs/01a10828-17e0-7650-be63-84f1930c20ab/wave1-freeze-v1.1/WAVE1_FREEZE_MANIFEST.csv -OutputRoot /private/tmp/emas-t1b-bxi-final
pwsh -NoProfile -NonInteractive -File tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1 -CorpusRoot /Users/vinay/Projects/AI/eMAS/02_Working/MS-04-PreSales-Wave1 -FreezeManifestPath /Users/vinay/Projects/AI/eMAS/outputs/01a10828-17e0-7650-be63-84f1930c20ab/wave1-freeze-v1.1/WAVE1_FREEZE_MANIFEST.csv -OutputRoot /private/tmp/emas-t1b-cec-final
```

- BXI: PASS, 6 primary + 13 regression fixtures, 5 additional checks, 19/19 hashes before and after.
- CEC: PASS, 19 fixtures, 43 additional checks, Wave 1 19/19 and Wave1E 22/22 hashes before and after.
- SD-002 additive CEC total: 150 records = historical 86 + T1a 15 + T1b 49.
- T1b SD-002 field counts: country 10, agency 10, procedure 10, submission type 10, submission-unit type 9.
- Historical and T1a EvidenceIds remain unchanged; the first SD-002 T1b record follows the accepted additive range.

### Wave 1 eight-suite regression

Each command used the same accepted corpus and freeze manifest shown above with an isolated output root:

```text
pwsh -NoProfile -NonInteractive -File tests/repository-discovery/Test-eMASRepositoryDiscovery.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/backbone-xml-inventory/Test-eMASBackboneXmlInventory.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/reference-inventory/Test-eMASReferenceInventory.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/reference-resolution/Test-eMASReferenceResolution.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/missing-reference-interpretation/Test-eMASMissingReferenceInterpretation.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/declared-checksum-comparison/Test-eMASDeclaredChecksumComparison.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/checksum-mismatch-interpretation/Test-eMASChecksumMismatchInterpretation.ps1 ...
pwsh -NoProfile -NonInteractive -File tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1 ...
```

PASS: all 8 accepted suites. Every suite verified 19/19 Wave 1 frozen hashes before and after; CEC additionally verified 22/22 Wave1E hashes before and after.

### Wave1D

```text
pwsh -NoProfile -NonInteractive -File tests/dossier-diversity/Test-eMASDossierDiversity.ps1 -CorpusRoot /private/tmp/emas-ectd4-baseline.e3oYH2/wave1d/eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1 -Wave1CorpusRoot /private/tmp/emas-t1b-wave1-ref -OutputRoot /private/tmp/emas-t1b-wave1d-final
```

PASS: 61/61; 8/8 frozen fixture hashes unchanged. Historical SD-002-profile assertions remain 86 records by excluding both T1a and T1b additive evidence from the legacy projection. `wave1d-expectations.json` was not modified.

### Root-level dossier

```text
pwsh -NoProfile -NonInteractive -File tests/root-level-dossier/Test-eMASRootLevelDossier.ps1 -CorpusRoot /private/tmp/emas-t1b-wave1-ref -OutputRoot /private/tmp/emas-t1b-root-final
```

FAIL: 2/3. Reference resolution and unrelated SD-020 passed. The historical CEC count check expected 86 but observed 135 because this harness excludes the five T1a types but not the five new T1b types. Production behavior is the same accepted additive behavior proven by CEC and Wave1D.

`tests/root-level-dossier/Test-eMASRootLevelDossier.ps1` is outside TASK.md's authorized test paths. The task says to stop and explain before changing any additional file, so it was not modified. Central authorization is required to extend that harness's historical projection with the five T1b evidence types; no non-CEC assertion needs weakening.

### T4 regressions

```text
pwsh -NoProfile -NonInteractive -File tests/identification-interpretation/engine/Test-eMASIdentificationInterpretation.ps1
pwsh -NoProfile -NonInteractive -File tests/identification-interpretation/engine/Test-eMASIdentificationOracleConformance.ps1
```

- Focused engine: PASS 28/28.
- Accepted formal oracle: PASS 23/23 (22 output, 1 expected failure).
- No T4 or oracle file was modified.
- Optional Python static-oracle validation was attempted but could not run locally because `jsonschema` is not installed. Dependencies were not installed without user approval. This does not affect the required PowerShell oracle conformance result.

## Compatibility and integrity evidence

- No second parse: BXI passes its already loaded `$document` directly to `Get-eMASEuRegionalEnvelope`; the helper contains no file, network, `XmlReader`, or `Load` operation.
- No CEC reopen: focused mocked-source test passed with `ResolvedSourcePath` intentionally unavailable; static guards found no XML or source-read API in CEC.
- Determinism: repeated CEC output and reordered envelope-fact input produced identical evidence JSON and IDs.
- Historical compatibility: existing historical record shape has no `SourceOrdinal`; all historical and T1a IDs remain unchanged. Wave1D legacy multisets remain 86 for SD-002-profile dossiers.
- Read-only/hash evidence: 19 Wave 1, 22 Wave1E, 8 Wave1D, and 11 new focused fixtures were verified unchanged by their applicable before/after gates.
- `git diff --check`: PASS (only repository line-ending conversion notices for files governed as CRLF).

## Windows PowerShell 5.1 evidence status

PENDING / NOT CLAIMED. The implementation and harness use `#requires -Version 5.1`-compatible syntax and import/run on local PowerShell Core, but no native Windows PowerShell 5.1 execution of the new BXI/CEC/focused suite was available locally. The repository's current Windows PS5.1 CI job runs runtime and T4 contracts, not the new BXI/CEC regional suite, so a green existing job would not constitute T1b Windows qualification.

## Deferred by task order

No projection v2, Identification rules, canonical procedure dimension, aliases, additional EU profiles, UUID/application grouping, T3c U2-U9, relationship-derived Region, dossier interpretation, free-text evidence, EU eCTD v4 `submissionunit.xml`, non-EU mappings, runtime schema/config, workbook/VBA, report-contract, or entry-script changes were implemented.

## Blockers and open issues

1. Root-level harness scope blocker: the required root-level regression needs a historical projection update in `tests/root-level-dossier/Test-eMASRootLevelDossier.ps1`, but that file is outside the formal authorized list. Current result is 2/3 with the stale count 86 vs 135.
2. Native Windows PowerShell 5.1 T1b qualification is pending and not claimed because the supported CI lane does not execute the new focused/BXI/CEC suite.
3. Native macOS PowerShell 7.6 T1b qualification is likewise not claimed; local execution used PowerShell 7.5.2 and the current 7.6 CI lane does not execute the new suite.
4. Regulatory SME confirmation of the documented `ema` versus `EU-EMA` source inconsistency remains intentionally open and non-blocking; implementation follows the accepted DTD/App. 1.1 rule.
