# Codex worker report — T2 SubmissionUnit XML implementation

## Identity and governance

- Task: `EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-IMPLEMENTATION`
- Worker branch: `implementation/emas-ms04-ectd4-submissionunit-xml-inventory`
- Draft PR: [#65](https://github.com/MightyM-ouse/eMAS/pull/65), targeting
  `coordination/emas-ms04-ectd4-submissionunit-implementation-task`
- Latest demo parent: `fd8927f2b5c072c3378efdcf95c2fd93e2a173dd`
- Task-order head: `7126831414bd613d92d014ae3e7e43f30486eca7`
- Accepted design/demo baseline: `ab06d567ad0f158c0d62b3d396951a90dca81fec`
- Accepted Claude design SHA: `dfdf711bcf5fa2d35501a7ea05626ed83d293d6e`
- Local qualification platform: macOS arm64, PowerShell Core 7.5.2
- Merge status: **not merged; PR remains draft**

The central authorization in PR #65 comment `6064333767` permitted one
out-of-allowlist correction to the B3 test harness. That correction was made
first and committed separately as `6b77c0e`. It adds the five accepted T1b
types to the historical projection and changes only the full additive SD-002
expectation from 101 to 150. Historical evidence remains 86; all other B3
assertions remain intact.

## Corrected pre-edit baseline

B3 passed 12/12 immediately after the authorized correction. The complete
original baseline was then rerun before production edits and all 15 gates
passed:

| Gate | Result |
|---|---|
| Wave 1 RepositoryDiscovery | PASS: 10 fixtures + 3 additional; 19 hashes |
| Wave 1 BackboneXmlInventory | PASS: 6 primary + 13 regression + 5 additional; 19 hashes |
| Wave 1 ReferenceInventory | PASS: 11 primary + 8 regression + 9 additional; 19 hashes |
| Wave 1 ReferenceResolution | PASS: 19 fixtures + 12 additional; 19 hashes |
| Wave 1 MissingReferenceInterpretation | PASS: 19 fixtures + 14 additional; 19 hashes |
| Wave 1 DeclaredChecksumComparison | PASS: 19 fixtures + 18 additional; 19 hashes |
| Wave 1 ChecksumMismatchInterpretation | PASS: 19 fixtures + 35 additional; 19 hashes |
| Wave 1 ClassificationEvidenceCollection | PASS: 19 fixtures + 43 additional; Wave1 19/19 and Wave1E 22/22 hashes |
| T1b regional XML evidence | PASS: 10/10; 11/11 fixtures read-only |
| Wave1E eCTD v4 discovery | PASS: 22/22 fixtures + 2/2 additional |
| Wave1D | PASS: 61/61; 8 frozen hashes |
| Root-level dossier | PASS: 3/3 |
| B3 candidate semantics | PASS: 12/12 |
| T4 focused engine | PASS: 28/28 |
| T4 accepted oracle | PASS: 23/23 |

The first Wave1D command used the raw Wave 1 working directory rather than the
frozen reference corpus and therefore could not find its manifest. This was an
invocation-path error, not a product/test failure; the required command was
rerun with `/private/tmp/emas-t1b-wave1-ref` and passed 61/61.

## Implementation delivered

- Added optional `Invoke-eMASSubmissionUnitXmlInventory`, consuming only RD/BXI
  observations and opening only RD-listed unit markers.
- Reused the existing safe reader with external resolution disabled; BXI, RD
  and SafeXml remain unchanged.
- Added exact-match `ECTD4-SUXI-VOCABULARY/1` for the accepted ICH, FDA and EU
  OIDs/code systems. Code and codeSystem remain separate; no prefix inference.
- Preserved F-1 per-document/per-type `SourceOrdinal` identity plus nested
  `SourcePath`.
- Preserved F-2 duplicate observations without selecting a winner, including
  identical duplicates and duplicate sequence numbers.
- Preserved F-3 RD-confirmed absence as `Exists=false`, `ParseStatus=Missing`,
  `CaptureStatus=InputUnavailable`, `NotAssessed`, reason
  `SubmissionUnitXmlConfirmedAbsent`.
- Added exactly eight factual CEC types at SortGroup 3. The first seven are
  Strong/StructuredXml; sequence number is Supporting/StructuredXml.
- T2 records alone carry `SourceOrdinal`, `SourcePath`,
  `SubmissionUnitXmlId`, and (for the three code types)
  `ObservedCodeSystem`. Interpretation fields and `XmlId` remain null.
- Added explicit `-IncludeSubmissionUnitXmlInventory`; default and
  Identification-only behavior remain unchanged. SUXI plus CEC uses the short
  RD -> BXI -> SUXI -> CEC path unless a deep-check switch is explicit.
- Preserved the SUXI capability token, document model and factual evidence when
  an existing deep-check switch is explicitly combined with SUXI. Focused T-7
  exercises the composed deep chain as well as the short path.
- Added focused CI steps for Windows PowerShell 5.1, Windows PowerShell 7.6 and
  macOS PowerShell 7.6.

## Changed-file scope

Production and orchestration:

- `engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1` (new)
- `engine/powershell51/private/eMAS.Ectd4SubmissionUnit.ps1` (new)
- `engine/powershell51/private/eMAS.Ectd4Vocabulary.ps1` (new)
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1` (additive)
- `scripts/eMAS-PreSalesAssessment.ps1` (explicit switch and bounded routing)

Tests, fixtures, CI and task records:

- `tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1`
- `tests/fixtures/submissionunit-xml-inventory/**`
- `.github/workflows/powershell-runtime-contracts.yml`
- this report and task `STATUS.md`
- centrally authorized B3 harness correction only:
  `tests/repository-discovery-candidate-semantics/Test-eMASRepositoryDiscoveryCandidateSemantics.ps1`

No prohibited engine/core, projection, schema, BXI, RD, SafeXml, legacy fixture,
workbook or oracle file changed.

## Vocabulary source traceability

The exact accepted source artifacts available from the design work were checked
read-only and their file hashes embedded in the registry:

| Artifact | SHA-256 |
|---|---|
| ICH eCTD v4 CV v7 workbook | `5f54a6786580d379f7324d0cfd7d70feaabf78409b67bbf7a4d3b270d434687f` |
| FDA Regional CV v1.2 workbook | `a5aaf5a43b1269ee2899f8e4f2e696d83d495053cac25e6f5ac08d34690d6624` |
| EU controlled vocabularies v3 workbook | `f4e3ff1dff074e402ebffd78d90d283c4937b02ef5cfcaaa98cd8fcb028bc812` |

The accepted source-version result remains: ICH IG 1.7/current, FDA M1 1.9
current with supported older tables, EU M1 1.2 draft plus registered `.6.1.3`
without a published guide. FDA package v1.5.1 and `.18.6` remain unverified D-3;
`.18.6` is tested as `UnknownOid`. No source package is committed.

## Synthetic fixture freeze

The focused suite verified all 22 generated XML files before and after every
run. They are minimal synthetic derivations, not copied regulator samples.
SD-063 is reused read-only from Wave1E and is not duplicated.

| Fixture | File | SHA-256 |
|---|---|---|
| SD-028 | `submissionunit.xml` | `c44c0ea17da5f6fc861c6446d16c4c37a283872decf319e6cbeec083935996f7` |
| SD-029 | `submissionunit.xml` | `a091a3ba261caa56619d541e08dd78103cd3154b10e5c59f3020bb27590ef987` |
| SD-075 | `submissionunit.xml` | `a6584d3f0d99a4dc92ed28444c03f81b296a7df6e9f66227afcc709f785b8c38` |
| SD-076 | `submissionunit.xml` | `e1cda0568ed48e1d716c672f589f9a481fec88ddf8cc0dee44fb5f72341aaed1` |
| SD-077 | `submissionunit.xml` | `0ffae999c79e4490fa2a273357d411b8fc964bc394e1ab344d3dea341a351507` |
| SD-078 | `submissionunit.xml` | `831252bb82701e3ea30e8736f315e791fb5bac326b91d383c7647a02706781cc` |
| SD-079 | `submissionunit.xml` | `5e0ea92a528b1c62b6aea84d81bbd51b92298eeef609f2dc9f4ee92c1f6065f8` |
| SD-080 | `submissionunit.xml` | `ca4480226a128b857975b01e6a8acf3c1b0e2383968d4d449a441ffff89c13dd` |
| SD-081 | `submissionunit.xml` | `612cc7ee21ecb8b345468e14e0930dcfe0649a9dd8bb1a2f2ab5d63ff123b236` |
| SD-082a | `different.xml` | `f7141334b042e1bf18a49b576e1aba9847118ac48dcd9d962f73f102d0b16867` |
| SD-082b | `identical.xml` | `ceac5fe2a92cf8c97e882986de6a412679d1a0baf72bc130886906c6f3735514` |
| SD-082c | `duplicate-sequence.xml` | `d11bfdaa5869674d5afc9b20751e3a4eb6ece4454d7d5f832cda29739898ba4e` |
| SD-083 | `submissionunit.xml` | `a464d45cd7575ca4f3ceca7d89ad3b1de43a5621844a7770c1cf8520269c5909` |
| SD-084 | `submissionunit.xml` | `a1cdd0d7b9a9d08ecbee992393af6191f3178dce9b754e663a9dbac38ea2f1f7` |
| SD-085 | `submissionunit.xml` | `86b9508831b0fe931d939503d1992130f658bffbd8681ed0ada915554063af8f` |
| SD-086a | `sequence-1.xml` | `9d6c37a7c7c26e394aa535d5aefc8be27720fd4f8bfbee8cbc3cdf163198fe50` |
| SD-086b | `sequence-2.xml` | `db0dfe1be0da10869b2e600749722c9e53fe80aafb6ec175780126543bfdc528` |
| SD-087 | `submissionunit.xml` | `c9372979d3c94367378b6728ca65a5d38c21fd5b54f036e804f525d0bb029215` |
| SD-088 | `submissionunit.xml` | `c1a65b24492584e8d9d0f4d93f7c723e49c5a29be303a76e3b32d789cf52095d` |
| SD-089 | `submissionunit.xml` | `e4e4f813cd8b95506e9fdc008f57cc91687212ae1127ec14b73d12ec775b3de9` |
| SD-090a | `eu.xml` | `534d253603f0e9951120d76fa67384e1c800c182ea4b7dcfad8819c5fd7bb547` |
| SD-090b | `fda.xml` | `973e61c5de7c7afeded0876d0dddc2a56a8b11dc8ea36e8cc1f04ae764553368` |

## Final local results

| Suite | Result |
|---|---|
| Focused SUXI T-1…T-21 | PASS 21/21; 22/22 synthetic hashes before/after |
| RepositoryDiscovery | PASS, accepted Wave 1 result |
| BackboneXmlInventory | PASS, accepted Wave 1 result |
| ReferenceInventory | PASS, accepted Wave 1 result |
| ReferenceResolution | PASS, accepted Wave 1 result |
| MissingReferenceInterpretation | PASS, accepted Wave 1 result |
| DeclaredChecksumComparison | PASS, accepted Wave 1 result |
| ChecksumMismatchInterpretation | PASS, accepted Wave 1 result |
| ClassificationEvidenceCollection | PASS, accepted Wave 1 result; Wave1/Wave1E hashes unchanged |
| T1b regional XML evidence | PASS 10/10; 11/11 fixtures read-only |
| Wave1E discovery | PASS 22/22 + 2/2 |
| Wave1D | PASS 61/61; 8 frozen hashes |
| Root-level dossier | PASS 3/3 |
| B3 candidate semantics | PASS 12/12 |
| T4 engine | PASS 28/28 |
| T4 oracle | PASS 23/23 |

The focused suite additionally proves directory/ZIP equivalence, prefix
independence, malformed/wrong-root/wrong-namespace fail-closed behavior,
external DTD/schema non-resolution, draft/unpublished/historical/unknown
profiles, known/unknown/wrong code systems, grouped identities, duplicate code,
sequence and submissionUnit cardinality, case-duplicate marker input, missing
after discovery, native macOS access denial, disabled capability behavior,
source-independent CEC, stable historical evidence, and unchanged T4 semantic
results.

This final rerun was performed after the orchestration composition check was
added. All 15 original baseline gates passed again, in addition to focused T2
21/21 and its pre/post 22-file freeze gates.

## Compatibility and CI status

- Local macOS PowerShell 7.5.2: PASS as above.
- macOS PowerShell 7.6 CI: PASS, including focused T2 21/21.
- Windows PowerShell 7.6 CI: PASS, including focused T2 21/21.
- Native Windows PowerShell 5.1 focused T2 qualification: PASS 21/21.
- The aggregate Windows PowerShell 5.1 job remains red only because its earlier
  RuntimeConfiguration suite fails the pre-existing UTF-8 expectation (27/28);
  the T2 step, T4 engine and T4 oracle all passed. CI run:
  `37811308221`.
- The unrelated Windows PS5.1 RuntimeConfiguration UTF-8 expectation remains
  out of scope and unchanged.

## Compatibility proof and open items

- Historical/T1a/T1b CEC objects and EvidenceIds are property-identical in
  equivalent runs; no T2-only property appears on old records.
- T4 uses projection v1, ignores all eight new types, and produces identical
  semantic `Results` with and without T2 facts. Engine 28/28 and oracle 23/23
  remain green.
- All existing Wave1, Wave1D, Wave1E and T1b bytes remained unchanged.
- D-3 remains open for FDA v1.5.1/package sample retrieval and `.18.6`.
- RepositoryDiscovery currently stores inventory paths in a PowerShell
  hashtable, whose string keys are case-insensitive. Consequently a real ZIP
  containing both `submissionunit.xml` and `SubmissionUnit.xml` reaches SUXI as
  one RD-listed file. SUXI fails closed when the supplied RD/BXI model contains
  both entries, and focused T-20 proves that behavior, but the end-to-end
  collision is not observable without changing the prohibited RD capability.
  No out-of-scope RD change was made; central review must disposition this
  accepted-design/upstream-boundary limitation.
- Fixed review SHA is the final PR head returned with this report; it is not
  self-embedded because changing this file would change that SHA.
- PR #65 remains draft and must not be merged without central fixed-SHA review
  and explicit user approval.

---

## Claude remediation (2026-10-08) — appended; Codex's report above is unchanged

**Author:** Claude, acting as bounded corrective implementer.
**Authorization:** central reconciliation [`6065519912`](https://github.com/MightyM-ouse/eMAS/pull/65#issuecomment-6065519912) of the Claude independent review [`6065356160`](https://github.com/MightyM-ouse/eMAS/pull/65#issuecomment-6065356160).
**Starting head:** `9adcdfa323d0e62fb4ae20c0d8a956c0f33087a4`, re-confirmed as the PR #65 head before editing.

Every result in this section is from Claude's own reruns. Codex's evidence above stays as Codex recorded it.

### Files changed (authorized list only)

| File | Change |
|---|---|
| `engine/powershell51/eMAS.SubmissionUnitXmlInventory.psm1` | M-1 alias guard; field-coverage mechanics |
| `engine/powershell51/private/eMAS.Ectd4SubmissionUnit.ps1` | typed empty `Submissions[].IdItems` |
| `tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1` | M-1 end-to-end checks; M-2 regression; tightened T-1, T-10, T-12, T-19, T-20; SKIP accounting |
| this report and `STATUS.md` | this section |

No fixture, manifest, RD, BXI, SafeXml, CEC, T4, schema, workflow or frozen byte changed. The adversarial ZIPs and the mixed repository are assembled in the test's temp directory from existing immutable bytes.

### M-1 — real-source marker aliases fail closed

RD keys its inventory case-insensitively, after normalising `\` to `/`. Aliases of `submissionunit.xml` therefore reach SUXI as a single RD file record. Before this fix, SUXI parsed whichever ZIP entry came first, without any diagnostic.

**What SUXI now does:**
- **ZIP input:** counts the already-open `ZipArchive.Entries` by normalised key (`\` → `/`, trimmed, `OrdinalIgnoreCase`). It does this before selecting or opening the marker entry.
- **Directory input:** counts the files in the selected unit folder whose names are `submissionunit.xml` under `OrdinalIgnoreCase`.
- **When the count is greater than 1:** the unit takes the existing S-28 shape:
  - `SUXI-DUPLICATE-001` / `DuplicateSubmissionUnitFiles`, `ParseStatus=NotAttempted`, no facts;
  - document and field coverage `NotAssessed`;
  - **zero `Ectd4*` CEC records**;
  - no winner is chosen.
- RD's inventory model is never mutated or re-enumerated, and CEC still never opens XML.

**Tests:** T-20 now runs the full RD → BXI → SUXI → CEC chain over four real archives. The FDA bytes come from SD-029 and the EU bytes from SD-028.

| Variant | Archive entries |
|---|---|
| case alias, FDA first | `1/submissionunit.xml`, then `1/SubmissionUnit.xml` |
| case alias, EU first | the same two entries in reverse order |
| exact duplicate | two entries both named `1/submissionunit.xml` |
| backslash alias | `1/submissionunit.xml` plus `1\submissionunit.xml` |

For each archive, the test checks that the entry names were written verbatim. It also checks that RD still collapses them to one record: if RD changes later, that assertion fails, which flags the separate limitation.

The earlier injected-RD-model check is kept but relabelled. It is no longer presented as end-to-end proof.

**Limits:**
- The directory branch cannot be exercised on the case-insensitive macOS and Windows test file systems. It is covered only by inspection.
- **The RD/BXI-wide alias risk stays OPEN** and needs its own scoped RD task. For example, BXI is also affected for v3 `index.xml`.

### M-2 — mixed v3/v4 regression (design SD-090)

New check "SD-090 (design) mixed v3/v4 repository…" assembles a temporary repository from three frozen sources:
- Wave 1 **SD-002**, hash-verified against `WAVE1_FREEZE_MANIFEST.csv`;
- an `eu-v4/1` unit from SD-028;
- an independent `us-v4/1` unit from SD-029.

It asserts:
- 2 SUXI documents, both `Available`;
- BXI XML documents are present;
- pre-T2 CEC evidence, including its EvidenceIds, is JSON-identical with and without SUXI, and has no T2 properties;
- 17 T2 records (8 EU + 9 US) whose IDs continue the pre-T2 sequence;
- a repeated CEC run gives identical T2 records;
- every `SourcePath` resolves.

SD-002 is internal test material and is not in the repository, so the check needs `-Wave1CorpusRoot`. Without it the check is reported as **SKIP** and counted separately; it is never counted as PASS. CI does not supply the corpus.

**SD-090 label divergence:** in the accepted design, SD-090 names this mixed repository. Codex's committed fixtures `SD-090/eu.xml` and `SD-090/fda.xml` instead hold the EU `.6.1.3` (`RegisteredWithoutPublishedGuide`) case and an unused FDA companion. Those frozen files were not renamed, moved or modified. The mixed regression is built in temp and carries the design label in its test name.

### Coverage and status mechanics

- **S-16b:** `ECTD4_IG_OID` no longer requires a singleton `submissionUnit`. A duplicated unit now gives IG `Collected` with `RecordsProduced` equal to the emitted IG records (2 for the FDA test). Unit and submission fields stay `NotAssessed`.
- **Reason vocabulary:** partial and zero-record field rows both map raw values to §8 reason codes:
  - `Absent` → `MandatoryFieldAbsent`;
  - `MultipleValues` → `CardinalityViolation`;
  - `UnknownOid` / `Empty` → `UnrecognizedProfileMarker`.
  - Example: SD-077's IG row is now `Partial / UnrecognizedProfileMarker / 1`.
- **Absent markers (S-18 consistency):**
  - A parsed, recognised message with no receiver IG items now gives IG `Collected / MandatoryFieldAbsent / 0` (SD-078). Before, it was `NotAssessed`.
  - Other fields with no values follow the same rule, except when the document already records a `CardinalityViolation`. In that case a parent may have been dropped, so absence is not asserted (`NotAssessed / CardinalityViolation`).
  - Missing, unavailable and unparsed XML stays `NotAssessed`.
- **Field counts** equal the emitted CEC evidence, because recognition (`Known` / `WholeNumberInRange` / recognised IG) implies `Occurrences = 1`.

### Typed empty arrays

`Submissions[].IdItems` is now `[]`, not `null`, when a submission has no id items. T-12 checks the compressed JSON and a depth-64 round trip; the CI PS5.1 lane runs the same test.

### Recorded deviations and limitations (not verified conformance)

1. **S-28 capture status.** For duplicate markers the implementation emits `CaptureStatus=InputUnavailable` / `ParseStatus=NotAttempted`. Design S-28 lists `Available`. This is kept as a conservative deviation: no source is selected or read.
2. **S-27 unplaced markers.** No SUXI document or `NotApplicable / UnplacedMarkerNotInventoried` row is emitted for a marker outside a unit folder. The fact survives only as RD's `UnplacedSubmissionUnitMarker` observation.
3. **Component-level sequence retention.** When a `componentOf1` does not contain exactly one `submission`, the component is skipped with `CardinalityViolation`. Its already-read `SequenceNumber` observations are not retained, so the inventory is not fully lossless at that level. No evidence is fabricated.

Changing any of these would add inventory rows or fields, which would change the accepted model. Per the authorization, these are recorded rather than redesigned.

### Claude verification (macOS arm64, Darwin 25.6, PowerShell 7.5.2)

| Command (repository root) | Result |
|---|---|
| `tests/submissionunit-xml-inventory/Test-eMASSubmissionUnitXmlInventory.ps1 -OutputRoot <tmp> -Wave1CorpusRoot /private/tmp/emas-t1b-wave1-ref` | **PASS 22/22**; 22/22 synthetic hashes before and after |
| the same, without `-Wave1CorpusRoot` | 21 PASS, 0 FAIL, 1 SKIP (M-2) |
| Negative control: new tests against the unfixed `9adcdfa` production code | 3 FAIL (T-10 reason leak, T-12 `IdItems` null, T-20 S-16b) |
| Negative control: new tests with only the M-1 ZIP guard removed | T-20 FAIL (`alias-case-fda-first: alias ambiguity was not rejected`) |
| RD, BXI, RI, RR, MRI, DCC, CMI, CEC (Wave 1 frozen corpus `/private/tmp/emas-t1b-wave1-ref`) | PASS each; 19 ZIP hashes; Wave1E 22 hashes |
| T1b regional XML | PASS 10/10; 11/11 read-only |
| Wave1E | PASS 22/22 + 2/2 |
| Wave1D (`-CorpusRoot <Wave1D package> -Wave1CorpusRoot /private/tmp/emas-t1b-wave1-ref`) | PASS 61/61; 8 frozen hashes |
| Root-level | PASS |
| B3 | PASS 12/12, including historical 86 / additive 150 |
| T4 engine / accepted oracle | PASS 28/28 / 23/23 |

The worktree was clean apart from the authorized files. New-head CI results are reported in the PR #65 comment for the fixed SHA, so that this file does not need to embed its own commit's CI.

**Still OPEN:** RD/BXI-wide alias collision (separate RD task), FDA v1.5.1 / `.18.6` D-3, native PS5.1 T1b qualification, and the unrelated PS5.1 RuntimeConfiguration UTF-8 failure.
