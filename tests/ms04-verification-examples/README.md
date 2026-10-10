# MS-04 publishable verification examples

All files in this directory were independently invented for technical verification.
They contain no copied sample content and are not content-valid regulatory dossiers.
Original sample publication permission is unknown; original samples stay local.

The harness uses the real Pre-Sales entry point with outputs outside the repository.
The linked and dangling delete cases both currently return `NoPhysicalHref`:
their distinct structural linkage is checked only by the test's independent XML
inspection. This demonstrates missing lifecycle coverage, not a passing product
lifecycle validator. The wrapper case is shared with the linked-delete example.
The escape example has a physically present sibling target that must remain unsafe.
The no-backbone example records physical numeric-folder candidates and missing probes,
without assigning regulatory invalidity.

Reuse `tests/regional-backbone-recognition/Test-eMASRegionalBackboneRecognition.ps1`
for common/EU/US recognition, missing physical references, path/XML mismatch and
directory/ZIP examples. Reuse the existing T2 fixtures for v4 SubmissionUnit XML.
No frozen fixture, approved oracle or existing expected result is changed.

```powershell
pwsh -NoProfile -File tests/ms04-verification-examples/Test-eMASVerificationExamples.ps1 -OutputRoot <fresh-directory-outside-repository>
```

The same harness supports native Windows PowerShell 5.1. A passing harness means
its stated collection/boundary checks pass; lifecycle validation remains unimplemented.
