# ChatGPT Review — EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE

**Status:** `IMPLEMENTATION_LOGIC_PASS — NARROW_EXPECTATION_REFRESH_REQUIRED`  
**Reviewed Codex commit:** `bcb6937b1d87a1083db302800bbcbfd0eef9c700`  
**Reviewed PR:** #47

## Verdict

The T1a CEC implementation matches the accepted factual-evidence design.

Verified:

- five new evidence types are additive and factual;
- raw CEC strength remains `Strong/Supporting/Weak`;
- all new records keep `CandidateValue`, `Polarity`, and `SourceRuleId` null;
- evidence is owned by the accepted dossier/unit and does not reopen the source filesystem;
- direct marker logic prevents wrapper/nested leakage;
- historical EvidenceIds are preserved by sorting new evidence after the accepted catalogue;
- frozen Wave1/Wave1D/Wave1E fixture hashes are unchanged;
- focused CEC, Wave1, and v4 discovery regressions pass.

## Remaining failures

Root-level, Wave1D, and B3 fail only because they freeze the pre-T1a CEC count/multiset. The canonical SD-002-profile CEC result is intentionally additive: 86 historical records + 15 new physical-marker records = 101.

This is not a product regression.

## Authorized follow-up

Codex may update only:

- `tests/root-level-dossier/Test-eMASRootLevelDossier.ps1`
- `tests/dossier-diversity/Test-eMASDossierDiversity.ps1`
- `tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1`

Use a historical projection that excludes the five new T1a evidence types for legacy count/multiset assertions. Keep repository coverage assertions tied to the full additive result.

Do not modify Wave1D expectation JSON, frozen fixtures, freeze manifests, implementation semantics, or any unrelated assertion.

## Windows CI

The automatic Windows PowerShell 5.1 failure is the same unrelated RuntimeConfiguration UTF-8 assertion previously diagnosed. macOS, static, and Windows PowerShell 7.6 contract jobs pass.

## Merge gate

PR #47 is **not ready to merge yet**. Rerun the required Mac regressions after the narrow harness refresh and return the updated commit/results.
