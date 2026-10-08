# Task Status — T2 implementation

**Task:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
**Roadmap:** MS-04 / T2 eCTD v4 SubmissionUnitXmlInventory
**Overall status:** `BLOCKED_BEFORE_IMPLEMENTATION / BASELINE_B3_PROJECTION_SCOPE`
**Authoritative design and accepted demo baseline:** `ab06d567ad0f158c0d62b3d396951a90dca81fec`
**Accepted Claude design SHA:** `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e`
**Task-order coordination branch:** `coordination/emas-ms04-ectd4-submissionunit-implementation-task`
**Worker implementation branch:** `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`

| Gate | Status |
|---|---|
| Claude T2 design revision 1.1 | ACCEPTED BY USER |
| Design PR #63 | MERGED to coordination: `44ce473c06a643314020c48ce1d6b67258f62fda` |
| Design coordination PR #62 | MERGED to demo: `ab06d567ad0f158c0d62b3d396951a90dca81fec` |
| Implementation task scope | BOUNDED; documented in TASK.md |
| Codex worker | LAUNCHED on isolated branch; stopped before production edits on required baseline failure |
| Source packages / D-3 | FDA M1 1.5.1/sample verification OPEN; do not recognise unverified OID |
| Native Windows PS5.1 T1b qualification | OPEN; separate |
| T2 PowerShell implementation | NOT STARTED; no production file changed |
| T2 focused tests T-1…T-21 | NOT RUN |
| Historical/T1b record and ID compatibility | MUST BE TESTED |
| BXI, RD, T4/projection | UNCHANGED BY CONTRACT |
| Codex draft PR | PENDING blocked-report publication |
| ChatGPT fixed-SHA implementation review | PENDING CODEX |
| User implementation merge approval | REQUIRED; NOT GIVEN |
| Merge of implementation | NOT AUTHORIZED |

## Worker deliverables

Codex owns its bounded implementation branch and creates `reports/CODEX.md` with baseline reproduction, exact file diff, focused/regression and native-PS5.1 evidence, fixture hashes, compatibility checks, and known gaps. Only a draft PR into this coordination branch is allowed.

## Stop conditions

Scope expansion, missing official authority for a new recognition mapping, historical regression, unexpected output change or missing required test evidence must be reported, not silently corrected through unrelated edits. The next merge gate belongs to the user.

## Current blocker

The latest-demo pre-edit baseline reproduces 14 of 15 required gates. `Test-eMASRepositoryDiscoveryCandidateSemantics.ps1` fails 1 of 12 checks because its historical CEC projection excludes the five T1a physical-marker types but not the five accepted T1b regional-envelope types: expected 86, actual 135. That harness is outside this task's strict allowlist. TASK.md requires the worker to stop on an unexpected baseline failure or required out-of-allowlist change, so no T2 production implementation has begun. Central authorization is required before that test-only projection can be amended.
