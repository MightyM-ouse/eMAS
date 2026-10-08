# Task Status — T2 implementation

**Task:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
**Roadmap:** MS-04 / T2 eCTD v4 SubmissionUnitXmlInventory
**Overall status:** `CLAUDE_REMEDIATION_APPLIED / FIXED_SHA_RE-REVIEW_PENDING`
**Authoritative accepted-design baseline:** `ab06d567ad0f158c0d62b3d396951a90dca81fec`
**Latest demo parent used by worker:** `fd8927f2b5c072c3378efdcf95c2fd93e2a173dd`
**Task-order head:** `7126831414bd613d92d014ae3e7e43f30486eca7`
**Worker branch:** `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`
**Draft PR:** [#65](https://github.com/MightyM-ouse/eMAS/pull/65)

| Gate | Status |
|---|---|
| Central B3 authorization | APPLIED as separate test-only commit `6b77c0e` |
| Corrected pre-edit baseline | PASS, all 15 required gates |
| T2 production scope | IMPLEMENTED within allowlist |
| Focused T-1…T-21 | PASS, 21/21 on macOS PowerShell 7.5.2 |
| Synthetic fixture freeze | PASS, 22/22 files before and after |
| Wave 1 eight-suite regression | PASS |
| T1b / Wave1E / Wave1D / root / B3 | PASS |
| T4 engine / accepted oracle | PASS, 28/28 and 23/23 |
| Historical/T1a/T1b compatibility | PASS; existing records and IDs unchanged in equivalent runs |
| Windows PS7.6 / macOS PS7.6 CI | PASS, focused T2 21/21 on both |
| Native Windows PowerShell 5.1 T2 qualification | PASS, focused T2 21/21; aggregate job red only on known unrelated UTF-8 test |
| FDA v1.5.1 / `.18.6` D-3 | OPEN; `.18.6` remains `UnknownOid` |
| Case-colliding ZIP markers | SUXI: CLOSED by Claude remediation M-1 (fail closed on case, exact-duplicate and backslash aliases); RD/BXI-wide alias risk: OPEN, separate scoped RD task |
| Claude independent review (`9adcdfa`) | CHANGES_REQUIRED; central remediation authorized in comment `6065519912` |
| Claude remediation M-1, M-2, coverage, typed arrays, docs | APPLIED; local focused 22/22 and 15/15 gates PASS (see below) |
| ChatGPT fixed-SHA re-review | PENDING |
| User merge approval | REQUIRED; NOT GIVEN |
| Merge | NOT AUTHORIZED |

## Implementation boundary

The worker adds the optional `SubmissionUnitXmlInventory` capability, exact
source-backed vocabulary recognition, additive ScannerObservations/1.0 facts,
eight factual CEC evidence types, the explicit Pre-Sales switch, focused tests,
synthetic fixtures and CI lanes. RepositoryDiscovery, BackboneXmlInventory,
SafeXml, T4, projection, schemas and all existing frozen fixture bytes remain
unchanged.

## Open items

- Native Windows PowerShell 5.1 focused T2 execution passed 21/21 in CI run
  `37811308221`. The aggregate job remains red only on the known unrelated
  RuntimeConfiguration UTF-8 expectation (27/28), which was not changed.
- FDA M1 v1.5.1 package/sample retrieval remains D-3. No OID was inferred.
- RD's existing case-insensitive inventory hashtable collapses a real ZIP's
  `submissionunit.xml` / `SubmissionUnit.xml` collision before SUXI receives
  the model. SUXI's fail-closed duplicate handling is covered with an
  RD-shaped input that preserves both entries. RD is prohibited scope, so no
  upstream change was made; central review must disposition the limitation.
- PR #65 must remain draft and unmerged until fixed-SHA central review and an
  explicit user decision.

## Claude remediation (2026-10-08)

Author: Claude, acting as bounded corrective implementer under central
authorization [`6065519912`](https://github.com/MightyM-ouse/eMAS/pull/65#issuecomment-6065519912),
starting from reviewed head `9adcdfa`. Codex's evidence above is unchanged and
remains Codex's; the results in this section are Claude's reruns only.

| Item | Status |
|---|---|
| M-1 real-source ZIP/directory marker aliases | FIXED in SUXI only; RD/BXI/SafeXml/CEC unchanged |
| M-2 mixed v3/v4 regression (design SD-090) | ADDED; needs `-Wave1CorpusRoot`, otherwise reported as SKIP, not PASS |
| S-16b IG coverage, partial-row reason codes, absent markers (S-18) | FIXED |
| Typed empty `Submissions[].IdItems` | FIXED |
| S-27 / S-28 / component sequence retention | RECORDED as deviations in `reports/CODEX.md` |
| Focused suite (macOS, pwsh 7.5.2) | PASS 22/22 with corpus; 21 PASS + 1 SKIP without corpus |
| 15 baseline/regression gates (macOS, pwsh 7.5.2) | PASS 15/15; B3 12/12 (86/150); T4 28/28; oracle 23/23 |
| New-head CI (Windows PS5.1, Windows PS7.6, macOS PS7.6) | PENDING at commit time; run IDs are reported in the PR comment for the fixed head |
| Native PS5.1 T1b qualification | OPEN (the PS5.1 CI lane runs only RuntimeConfiguration, T4, oracle and SUXI) |
| RD/BXI-wide path-alias collision | OPEN; needs a separately approved RD task |
| FDA v1.5.1 / `.18.6` D-3 | OPEN |
