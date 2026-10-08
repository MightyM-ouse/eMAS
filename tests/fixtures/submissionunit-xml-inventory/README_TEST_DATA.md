# SubmissionUnit XML inventory synthetic fixtures

These files are minimal synthetic derivations of the accepted T2 structure and
controlled-vocabulary tables. They are not copied regulator samples and are not
regulator-validated messages.

- SD-028 and SD-029 exercise the accepted EU and FDA fact sets.
- SD-075 through SD-090 exercise historical, draft, unknown, malformed,
  duplicate, grouped, unavailable, prefixed, ambiguous and mixed cases.
- SD-063 is reused read-only from the frozen Wave1E corpus and is deliberately
  absent from this manifest.

`SUXI_FREEZE_MANIFEST.csv` freezes every synthetic XML source byte used by the
focused harness. The harness verifies hashes before and after execution.
