# Codex worker report — blocked pre-edit baseline

## Identity

- Task: `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
- Latest demo baseline: `fd8927f2b5c072c3378efdcf95c2fd93e2a173dd`
- Task-order head: `7126831414bd613d92d014ae3e7e43f30486eca7`
- Accepted design/demo baseline: `ab06d567ad0f158c0d62b3d396951a90dca81fec`
- Worker branch: `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`
- Worker parent: latest `origin/demo/end-to-end-mvp`
- Platform: macOS, PowerShell Core 7.5.2
- Implementation status: **NOT STARTED — formal baseline stop condition**

The latest demo commit is a documentation-only merge with the task-order head as a parent. Its tree is byte-identical to the designated task-order head, and both descend from the accepted baseline. The worker worktree was clean before baseline execution.

## Governing material read

- repository-native agent workflow;
- implementation `CODEX_LAUNCH.md`, `TASK.md`, and `STATUS.md`;
- accepted T2 Claude design report revision 1.1, including F-1/F-2/F-3 and T-1 through T-21;
- accepted T2 source ledger;
- authority/precedence policy, LLM development rules, and PowerShell module implementation guidance.

No live source mapping was added or reinterpreted. D-3 remains open exactly as accepted.

## Pre-edit baseline results

All commands ran from the clean isolated worker worktree. Output was written only under `/private/tmp/emas-t2-baseline-*`.

| Gate | Result |
|---|---|
| Wave 1 RepositoryDiscovery | PASS: 10 fixtures + 3 additional checks; 19 hashes before/after |
| Wave 1 BackboneXmlInventory | PASS: 6 primary + 13 regression fixtures + 5 additional checks; 19 hashes before/after |
| Wave 1 ReferenceInventory | PASS: 11 primary + 8 regression fixtures + 9 additional checks; 19 hashes before/after |
| Wave 1 ReferenceResolution | PASS: 19 fixtures + 12 additional checks; 19 hashes before/after |
| Wave 1 MissingReferenceInterpretation | PASS: 19 fixtures + 14 additional checks; 19 hashes before/after |
| Wave 1 DeclaredChecksumComparison | PASS: 19 fixtures + 18 additional checks; 19 hashes before/after |
| Wave 1 ChecksumMismatchInterpretation | PASS: 19 fixtures + 35 additional checks; 19 hashes before/after |
| Wave 1 ClassificationEvidenceCollection | PASS: 19 fixtures + 43 additional checks; Wave 1 19/19 and Wave1E 22/22 hashes before/after |
| T1b regional XML evidence | PASS: 10/10; 11/11 focused fixture hashes/timestamps unchanged |
| Wave1E eCTD v4 RepositoryDiscovery | PASS: 22/22 fixtures + 2/2 additional checks |
| Wave1D | PASS: 61/61; 8 frozen hashes unchanged |
| Root-level dossier | PASS: 3/3 |
| B3 candidate semantics | **FAIL: 11/12** |
| T4 focused engine | PASS: 28/28 |
| T4 accepted oracle | PASS: 23/23 |

## Blocking failure

Command:

```text
pwsh -NoProfile -NonInteractive -File tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1 -CorpusRoot /private/tmp/emas-t1b-wave1-ref -OutputRoot /private/tmp/emas-t2-baseline-b3
```

Failure:

```text
year-wrapped SD-002 historical classification-evidence count differs. Expected=86; Actual=135
```

Cause: `tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1` defines its historical projection by excluding only the five T1a physical-marker evidence types. It does not exclude the five accepted T1b evidence types (`EuEnvelopeCountry`, `EuAgencyCode`, `EuProcedureType`, `EuSubmissionType`, `EuSubmissionUnitType`). The 49-record difference is therefore the accepted T1b additive evidence, not a T2 production defect.

The B3 harness is outside this task's strict production/test allowlist. TASK.md requires a stop on an unexpected baseline failure and on any required change outside the allowlist. The worker therefore did not modify the harness, did not weaken an assertion, and did not begin T2 implementation.

## Exact changes in this blocked run

- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION/STATUS.md`
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION/reports/CODEX.md`

No engine, script, test, fixture, workflow, schema, T4, projection, or frozen source file changed.

## Required central decision

Authorize a test-only update to `tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1` that extends its historical projection to exclude the same five accepted T1b evidence types, without weakening any other B3 assertion. After that amendment, rerun the complete baseline before any T2 production edit.

## Open items retained

- FDA v1.5.1 OID/source retrieval (D-3): open; no mapping may be invented.
- Native Windows PowerShell 5.1 T1b/T2 qualification: open and not claimed.
- Unrelated Windows PS5.1 RuntimeConfiguration UTF-8 CI defect: out of scope and untouched.
- Draft PR and fixed-SHA implementation review: pending because implementation has not started.
