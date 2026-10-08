# Task Status — T2 implementation

**Task:** `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
**Roadmap:** MS-04 / T2 eCTD v4 SubmissionUnitXmlInventory
**Overall status:** `IMPLEMENTED_AND_LOCALLY_QUALIFIED / FIXED_SHA_REVIEW_PENDING`
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
| Windows PS7.6 / macOS PS7.6 CI | CONFIGURED; remote CI result pending push |
| Native Windows PowerShell 5.1 T2 qualification | PENDING / NOT CLAIMED |
| FDA v1.5.1 / `.18.6` D-3 | OPEN; `.18.6` remains `UnknownOid` |
| Case-colliding ZIP markers | OPEN FOR CENTRAL DISPOSITION; RD collapses case-insensitive path keys before SUXI |
| ChatGPT fixed-SHA review | PENDING |
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

- Native Windows PowerShell 5.1 execution remains pending; the unrelated
  RuntimeConfiguration UTF-8 failure is not part of T2 and was not changed.
- FDA M1 v1.5.1 package/sample retrieval remains D-3. No OID was inferred.
- RD's existing case-insensitive inventory hashtable collapses a real ZIP's
  `submissionunit.xml` / `SubmissionUnit.xml` collision before SUXI receives
  the model. SUXI's fail-closed duplicate handling is covered with an
  RD-shaped input that preserves both entries. RD is prohibited scope, so no
  upstream change was made; central review must disposition the limitation.
- PR #65 must remain draft and unmerged until fixed-SHA central review and an
  explicit user decision.
