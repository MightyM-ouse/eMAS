# Codex launch — T2 implementation

**Repository:** `MightyM-ouse/eMAS`
**Task ID:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
**Task-order coordination branch:** `coordination/emas-ms04-ectd4-submissionunit-implementation-task`
**Accepted baseline:** `ab06d567ad0f158c0d62b3d396951a90dca81fec` (design PR #63 and coordination PR #62 integrated)
**Worker branch:** `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`
**Worker PR target:** `coordination/emas-ms04-ectd4-submissionunit-implementation-task` (**draft**, no merge)

## Before any change

1. Fetch the newest task-order coordination branch and confirm this `TASK.md`, `STATUS.md` and launch file are present; record its exact commit SHA.
2. Check `git status --short` is empty and the task-order branch descends from `ab06d567ad0f158c0d62b3d396951a90dca81fec`.
3. Create a separate worktree/worker branch from the checked task-order head; do not reuse stale worker branches or work directly on demo.
4. Read `docs/internal/agent-workflow/AGENT_WORKFLOW.md`, then this task's `TASK.md` and the **accepted** T2 design report `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/reports/CLAUDE.md` (revision 1.1).
5. Run existing baseline suites and record exact results in `reports/CODEX.md` before editing.

## Implementation instruction

Implement **exactly** the optional read-only `SubmissionUnitXmlInventory` capability specified by the accepted design, including source-backed ICH/FDA/EU vocabulary registry, ScannerObservations/1.0 additive collection, eight factual CEC evidence types, F-1/F-2/F-3 corrections, and the explicit Pre-Sales switch.

Follow the **exact allowed file list** and mandatory **T-1…T-21** tests in TASK.md. Preserve BXI, RD, SafeXml, T4 and projection unchanged. No regulatory classification or new region rules. No app, workbook, scenario architecture or report redesign.

Key tests: grouped-submission SourceOrdinal uniqueness and SourcePath, duplicate singleton observations (identical and different), RD-confirmed missing marker SD-063, malformed/unknown/draft code status, PS5.1 + PS7.6 JSON compatibility, ZIP/directory equivalence, historical/T1b evidence stability, and T4 unchanged output.

Do not claim full native Windows PS5.1 qualification unless actually executed under that runtime. Keep FDA v1.5.1 OID/source retrieval open unless independently verified and approved. The old PS5.1 UTF-8 CI defect remains separate.

## Publication and handoff

Update ONLY this task's `STATUS.md` and a new `reports/CODEX.md` in addition to the explicitly permitted code/tests/docs.

Commit/push the dedicated implementation worker branch, open one **draft PR targeting `coordination/emas-ms04-ectd4-submissionunit-implementation-task`**, and do **not merge**. Return:
- worker branch and HEAD SHA;
- parent/task-order head and demo accepted baseline;
- draft PR URL/number;
- changed files and fixture hash/immutability proof;
- test commands and PASS/FAIL/SKIP counts by runtime;
- historical/T1b EvidenceId property compatibility;
- T4 engine 28/28 and oracle 23/23 status;
- unresolved blockers and open D-3/native PS5.1 items.

Wait for ChatGPT fixed-SHA central review and **explicit user approval** before any implementation merge.
