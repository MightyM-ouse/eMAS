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
