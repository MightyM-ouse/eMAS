# ChatGPT Review — EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D

**Status:** `MAC_REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed PR:** #32  
**Reviewed commit:** `d6b735fbaa0d63e0b7c716eb4a5d4637ef3eb129`

## Review verdict

The Wave1D implementation is acceptable as the Mac fixture/regression baseline.

No blocking correctness, scope, provenance, determinism, or regression issue was found in the reviewed change.

## What was verified

- PR #32 changes only the task documentation/report plus the allowed Wave1D test, fixture-expectation, and test-data utility paths.
- No `engine/**` runtime module, entry script, RepositoryDiscovery, FormatDetection, RegionDetection, or frozen Wave 1 file is changed.
- SD-044 through SD-050 are normative dossier-diversity fixtures and SD-051 is explicitly characterization-only.
- SD-052 remains deferred.
- The existing Wave 1 baseline passed before and after the Wave1D work: 8/8 suites, 275 checks, 0 failures.
- The root-level dossier harness remains 3/3 PASS.
- The dedicated Wave1D harness reports 60/60 PASS.
- Expectations are transform-derived before fixture build and independently checked from ZIP/XML bytes.
- The oracle was calibrated against accepted Wave 1 cases before being used for Wave1D.
- The recorded expectation correction for SD-051 occurred before scanner execution and narrows an accidental policy assertion rather than tuning expected output to scanner behavior.
- Two clean fixture builds and two package builds are reported byte-identical.
- The Wave1D freeze manifest records stable SHA-256 identities.
- Misleading dossier text, wrapper context, multi-dossier isolation, unrelated content, safe names, and root-level dossier behavior are all covered.
- The Wave1D package is kept outside Git consistently with the existing Wave 1 packaging model, with its hash and internal manifest hash recorded.

## SD-051 decision

SD-051 should be accepted into Wave1D only as `FROZEN_CHARACTERIZATION`.

The current behavior in which `Archive/2019/` becomes a heuristic dossier candidate should **not** be promoted to normative product behavior merely because it is deterministic.

Recommendation: open a separate bounded RepositoryDiscovery semantics task before FormatDetection. That task should decide whether a four-digit child alone is sufficient for a dossier candidate or whether stronger structural evidence is required.

Until that decision is made:
- do not change RepositoryDiscovery inside Wave1D;
- do not describe the `Archive` candidate as a valid regulatory dossier;
- do not let future FormatDetection classify a candidate solely because the four-digit-folder heuristic found it.

## Coordination PR note

PR #32 contains the unchanged coordination files from PR #31 because Claude branched from the coordination branch while targeting `demo/end-to-end-mvp`.

This does not create a functional problem. If PR #32 is accepted, PR #31 becomes redundant and should be closed without a separate merge.

## Deferred work

- Native Windows PowerShell 5.1 qualification remains pending.
- RepositoryDiscovery semantics for SD-051 remains a separate decision/task.
- FormatDetection and RegionDetection remain out of scope.

## Recommendation

**Accept PR #32 as the Mac Wave1D baseline.**

After acceptance:
1. close redundant coordination PR #31 without merge;
2. record Wave1D as Mac-accepted / Windows-pending;
3. open the bounded RepositoryDiscovery semantics task for the SD-051 four-digit-folder case;
4. keep consolidated Windows PowerShell 5.1 qualification for the later Windows checkpoint.
