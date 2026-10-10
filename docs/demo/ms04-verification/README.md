# MS-04 technical verification evidence

Reports here use anonymized input identifiers and technical counts only. Original
sample publication permission has not been established. Detailed scanner output,
original XML/PDFs, source manifests and the input-name mapping stay outside Git.

The frozen accepted demo commit is an implementation baseline, not a qualified
regulatory baseline. Scanner completion is not identification success, regulatory
compliance, migration readiness or release approval. Optional capabilities and
partial/unsupported coverage must be reported explicitly.

Reusable local directory-input verification:

```powershell
pwsh -NoProfile -File tools/verification/Invoke-eMASLocalSampleVerification.ps1 -SourceRoot <local-input-root> -OutputRoot <fresh-directory-outside-repository> -ExpectedInputCount 15 -VerificationDate 2026-10-10
```

This runs the actual entry point twice per input: the historical CEC/deep-check
route and an explicit deep-check route with SUXI enabled. It reads and hashes
originals, writes only outside the repository/source, and creates a local-only
mapping and detailed scans. Only manually reviewed, allowlisted aggregate output
is suitable for publication. The current batch comprises directory inputs; use
the existing regional harness for directory/ZIP equivalence verification.

Synthetic lifecycle/boundary examples live in `tests/ms04-verification-examples`.
Reuse the accepted regional and T2 suites for already covered XML behaviors.
