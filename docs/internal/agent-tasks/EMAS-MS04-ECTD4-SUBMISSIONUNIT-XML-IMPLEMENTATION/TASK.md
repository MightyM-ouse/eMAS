# EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION

**Task ID:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
**Roadmap:** T2 implementation, MS-04 Pre-Sales
**Authoritative accepted-design merge baseline:** `ab06d567ad0f158c0d62b3d396951a90dca81fec` (`demo/end-to-end-mvp`, design PR #63 -> coordination PR #62)
**Task-order branch:** `coordination/emas-ms04-ectd4-submissionunit-implementation-task`
**Worker branch (create AFTER reading this task):** `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`
**Worker PR target:** the task-order coordination branch above
**Execution:** one Codex implementation worker -> fixed-SHA central review -> explicit user acceptance -> integration decision
**Authorization:** user accepted T2 design at `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e` and requested a bounded Codex task. **No implementation merge is authorized.**

## Goal and acceptance boundary

Deliver an optional, read-only `SubmissionUnitXmlInventory` (SUXI) for eCTD v4 `submissionunit.xml` in the current MS-04 Pre-Sales PowerShell pipeline. Collect source-backed structured facts and publish exactly eight additional *factual* CEC evidence types. Do **not** add identification decisions, regulatory validation, new migration scenarios, a platform application, or a workbook redesign.

Pipeline: `RepositoryDiscovery -> BackboneXmlInventory -> [SubmissionUnitXmlInventory (optional)] -> [optional existing reference/checksum chain] -> ClassificationEvidenceCollection -> [IdentificationInterpretation if requested]`.

This task is the **evidence-collection** component of the focused MS-04 demo, not proof that T4 yet interprets the new v4 facts. T4/projection v2 remains a separate future decision.

## Governing read order

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`.
2. This `TASK.md`, `STATUS.md`, and `CODEX_LAUNCH.md`.
3. Accepted source-ledger/design: `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/reports/CLAUDE.md` revision 1.1 (accepted fixed SHA `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e`), including §§0, 4–6, 8–17.
4. `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/SOURCES.md`; official-source gaps must remain visible.
5. The current `RepositoryDiscovery`, `BackboneXmlInventory`, `ClassificationEvidenceCollection`, `SafeXml`, `IdentificationInterpretation`, relevant tests/fixture manifests, and `scripts/eMAS-PreSalesAssessment.ps1`.
6. Applicable PowerShell implementation skill and existing runtime-contract CI.

The accepted design is binding. Do not silently revisit or expand it. Where design prose and examples differ, derive the smallest consistent behavior from explicit status/field rules, record the ambiguity in CODEX.md, and **stop** if it would change data/contract semantics rather than guessing.

## Closed implementation decisions

### Ownership and safe parsing
- New `engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1` with `Invoke-eMASSubmissionUnitXmlInventory`.
- Reuse the existing safe XML reader, no DTD/entity expansion, external schema/network resolution or schema validation. Parse **each discovered v4 unit's XML exactly once in SUXI**; BXI does not parse these inputs. CEC consumes the resulting in-memory facts and never opens source paths.
- Input is RepositoryDiscovery's own `Sequences` and `Files` observations for `SubmissionUnitFolder` and `AmbiguousRegulatoryUnitFolder` plus damaged candidates for confirmed absence. Include directory and ZIP inputs, path containment, reparse-point safety, case/duplicate handling, deterministic document order and fail-closed input checks.
- BXI, RD and the shared safe reader **remain byte-unchanged**. Do not invent additional dossier/application aggregation.
- Capability runs only when the explicit CLI switch is set. Default and identification-only chains must retain existing behavior. A second SUXI invocation is rejected with the accepted `SUXI-INPUT-002` code.

### ScannerObservations/1.0 output
- Retain `eMAS.MS04.PreSales.ScannerObservations/1.0` without a version bump.
- Add only optional top-level `SubmissionUnitXmlDocuments`, SUXI-specific coverage rows and `Execution.Capabilities += SubmissionUnitXmlInventory` when run. Never write to `XmlDocuments`, or change existing members.
- Use the exact source-backed field paths/types, `StructureStatus`, `ProfileStatus`, cardinality/status vocabularies, source ordering and example-shape **rules** in accepted design §§5, 8, 10–11. Examples containing ellipsis/piped enum alternatives are illustrative prose, **not directly parseable JSON**.
- Keep code and `codeSystem` distinct; match only versioned, officially documented embedded vocabularies. Record unrecognized OIDs/codes verbatim but never infer a region/profile by prefix or treat a registration match as dossier validity.
- Respect ICH/FDA/EU source provenance and statuses (historical, current, draft, registered-without-published-guide). Preserve all nine recorded source conflicts. EU draft is explicitly not a final approved regulatory guide.
- FDA supported-but-unverified v1.5.1 and `…18.6`: keep **UnknownOid** until D-3 verified by an official artifact; do not infer or silently add a registry mapping. No unavailable FDA sample may be described as inspected.

### Lossless ambiguity, absence and deterministic identity (F-1/F-2/F-3)
- For repeated nested records, new T2 `SourceOrdinal` increments per `(SubmissionUnitXmlId, EvidenceType)` across the **entire document**, with a distinct nested `SourcePath` (e.g. `S2/A1/I1`). Preserve per-parent local ordinals separately and guarantee unique deterministic evidence IDs even for grouped submissions.
- All three code fields have `Occurrences` and an `Observations[]` array preserving **every** raw (code, codeSystem) occurrence in document order, even identical duplicates. `Occurrences > 1`: parent Code/CodeSystem are null, Recognition is MultipleValues, no Strong code CEC record. Sequence-number duplicates use analogous `Observations[]`, no Supporting record.
- Confirmed missing `submissionunit.xml` in a damaged RD unit: `Exists=false; FileId=null; ParseStatus=Missing; CaptureStatus=InputUnavailable; CollectionStatus=NotAssessed; Reason=SubmissionUnitXmlConfirmedAbsent`. This differs from a file disappearing after RD, access denied, and switch-disabled state. Never call it NotApplicable.
- Preserve separately invalid/wrong root or namespace, missing marker, conflicting marker, duplicate singleton submissionUnit, unsupported vocab, parse failures, path unavailable, and unattempted capability. No fabricated facts on unsuccessful parses.

### Exactly eight new CEC factual types
`Ectd4MessageRootElement`, `Ectd4MessageNamespace`, `Ectd4ImplementationGuideOid`, `Ectd4SubmissionUnitTypeCode`, `Ectd4SubmissionTypeCode`, `Ectd4ApplicationTypeCode`, `Ectd4ApplicationIdNamespaceOid`, `Ectd4SequenceNumber`.

- First seven are `Strong / StructuredXml` on **recognized** structured facts; sequence number is `Supporting / StructuredXml` only when a single valid typed value is available. Recognition does not assert regulatory conformance.
- CEC reads only SUXI output, not source XML; new records carry T2-only `SourceOrdinal`, `SourcePath`, `SubmissionUnitXmlId`, and `ObservedCodeSystem` where applicable. `XmlId=null`, `CandidateValue=null`, `Polarity=null`, `SourceRuleId=null`. Never add new properties to historical or T1b records.
- `SortGroup=3` after historical/T1b groups, with stable `EVD-` IDs; existing evidence objects and IDs remain unchanged in equivalent runs. Preserve existing CEC repository/XmlDocument coverage semantics. New SUXI coverage uses `SubmissionUnitXmlInventory` and `SubmissionUnitXmlField:<FieldCode>`, without contaminating T4 v1 coverage rows.
- No T4 or field-projection changes. T4 v1 must ignore the new facts without changing identification results.

## Strict production-file allowlist

- `engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1` (new)
- `engine/powershell51/private/eMAS.Ectd4SubmissionUnit.ps1` (new)
- `engine/powershell51/private/eMAS.Ectd4Vocabulary.ps1` (new)
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1` (minimal additive changes)
- `scripts/eMAS-PreSalesAssessment.ps1` (optional `-IncludeSubmissionUnitXmlInventory` switch and bounded orchestration only)

Optional narrowly scoped docs/testing files:
- `engine/powershell51/README.md`, this task's `STATUS.md`, and `reports/CODEX.md` (new).
- `tests/submissionunit-xml-inventory/**`, `tests/fixtures/submissionunit-xml-inventory/**` with generated **synthetic** immutable fixtures and SHA-256 manifest.
- Directly relevant additive `tests/classification-evidence-collection/**` and expectation *extensions* without rewriting or weakening historical expectations.
- `.github/workflows/powershell-runtime-contracts.yml` to add focused SUXI test lanes on Windows PS5.1, Windows PS7.6 and macOS PS7.6; existing jobs remain.

**Everything else is forbidden absent a new explicitly approved task scope:** in particular `engine/powershell51/eMAS.RepositoryDiscovery.psm1`, `eMAS.BackboneXmlInventory.psm1`, `private/eMAS.SafeXml.ps1`, `engine/core/**`, `config/**`, schemas, JSON contract, Identification/T4/projection/oracle, legacy fixtures, workbook/VBA, other phase scripts, XLSX/report/UI, and unrelated documentation. Frozen Wave 1/1D/1E and T1b source/fixture bytes must not change. Do not commit downloaded official packages.

## Test/verification plan (minimum)

1. **Before edits**: record exact base SHA, parent/branch, clean worktree, reproduction of accepted BXI/CEC/T1b, Wave 1/1D/1E, root-level/B3 and T4 engine/oracle tests (including platform limitations). Fail/stop on unexpected baseline failure; do not weaken existing tests.
2. Implement **all accepted T-1 through T-21** design tests. The report's §16 mentions T-1…T-18 in an older sentence; revision 1.1 adds T-19/20/21 and these **are mandatory**. Add cases SD-028/029 and SD-075…090 as minimally derived synthetic v4 messages, with source-ledger/fixture-ID traceability and hashes; **reuse frozen SD-063 read-only** for F-3.
3. Validate namespace-prefix independence, root/namespace gating, safe reader protections, unknown/historical/draft IG OIDs, versioned vocabulary recognition, grouped submission application/item ordinal collisions, both identical and different duplicate code pairs, duplicated sequence number and submissionUnit, lossless JSON round-trip on PS5.1/PS7.6, absent-after-discovery versus RD-confirmed absence, access denied, disabled switch, malformed XML, directory-versus-ZIP equivalence, mixed v3/v4 repositories, and no free-text or personally identifying output.
4. Regression: BXI, CEC, T1b, existing RD/v4 Wave1E, Wave1/1D, B3/root-level, checksum/reference where affected, T4 engine 28/28 and accepted oracle 23/23. Assert historical/T1b CEC records are property-identical, IDs stable and T4 identification output unchanged apart from documented volatile metadata.
5. CI/read-only: verify frozen manifests and no changed fixtures/source data; check no external XML access; no customer data; no unreviewed copyright artifacts. Record all commands, environments, test counts, errors and commit hash.
6. **Native Windows PS5.1**: execute new SUXI-focused, BXI, CEC and compatibility tests under native Windows PowerShell 5.1, if available; distinguish PS7-on-Windows from PS5.1. An existing PS5.1 CI failure in the unrelated UTF-8 RuntimeConfiguration expectation is an **open failure**, not a new T2 PASS. Native T1b PS5.1 qualification remains a separate open item and must not be silently closed.

## Deliverables and stop conditions

- New SUXI source/helpers, minimal CEC and Pre-Sales orchestration edits, synthetic fixtures, frozen manifest, complete focused/regression test evidence.
- `docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION/reports/CODEX.md` must record: baseline SHA and state; changed files; design traceability; exact fixture IDs and SHA; case/test outcomes on each platform; historical EvidenceId equivalence; T4 unchanged proof; source-ledger exceptions and unresolved D-3, PS5.1 open items; blocking and nonblocking issues; final worker SHA and PR.
- When a required change falls outside the allowlist, an authoritative source contradicts the frozen design, source OIDs cannot be confirmed, a real file safety issue is found, or historical evidence changes: **STOP, report, and request central review**. No unauthorized repair or guess.
- Codex commits only on its worker branch and publishes one **draft PR into the task-order coordination branch**. ChatGPT reviews a fixed SHA and the user must explicitly approve **any merge of implementation**. No agent-initiated merge, rebase to an unrelated baseline, or future T4/projection implementation.

## Next governance gate

Task prepared; Codex may be launched only after verifying the task-order branch/head and baseline. Implementation is confined to a draft worker PR until the central review and a **new explicit user merge decision**.
