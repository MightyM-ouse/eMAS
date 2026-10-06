# Claude Report — EMAS-MS04 Qualified RC1 Baseline Materialization

**Purpose:** unblock `EMAS-MS04-ROOT-LEVEL-DOSSIER` (Codex result `BLOCKED_BASELINE_NOT_REPRODUCIBLE`).
**Branch:** `baseline/emas-ms04-qualified-rc1-materialization`
**Base:** `demo/end-to-end-mvp` @ `f2e1dc754e2ee6e1fcd52d5dcdf674fbbcc83aa7`
**Materialization commit:** `dc81ca7ad43c66476320d7679362ec0e2f8b3e74`
**Author:** Claude
**Date:** 2026-10-06

**Result:** `MATERIALIZED — BYTE-IDENTICAL — 8/8 SUITES PASS (macOS, pwsh 7.5.2)`

No functional change was made. Every added or replaced file is a byte-for-byte copy from the qualified internal package. The root-level dossier defect is **not** fixed. FormatDetection and RegionDetection are not implemented. RepositoryDiscovery is materialized exactly as qualified, with no change. No frozen Wave 1 fixture or freeze manifest was touched.

---

## 1. Source packages

Local source: `packages/` in the controlled workspace on this Mac (outside the repository).

| Package | SHA-256 (measured) | Recorded value | Result |
|---|---|---|---|
| `eMAS_MS04_PreSales_Runtime_RC1.zip` | `d08f169f71af8400cefbe9b575a01b8d4feedac8449c1d57fd1c5ceefec27aa6` | same | MATCH |
| `eMAS_MS04_PreSales_WindowsQualification_Internal_v1.zip` | `c5ba45863b970475ed3407d900c343fcb815812b6d4cd3a745bb6c4c8ba63180` | same | MATCH |
| `eMAS_MS04_PreSales_Wave1_TestData_v1.zip` | `280af6f7e70fba186637687c45a8aaf661b160e025bde39fc17ae9f88323a5a7` | same | MATCH |

The recorded values come from two places, and the measured hashes match both:
- `PACKAGING_SUMMARY.md`, from the packaging run;
- the Codex root-level-dossier report, section "Available package evidence".

## 2. Manifests

| Manifest | SHA-256 | Recorded | Entries verified |
|---|---|---|---|
| Qualification `PACKAGE_MANIFEST.csv` (authoritative source) | `5735a8bf1730a048264a95b5f7221d4276050d3cc97af8eba2f1e0897edb2c83` | MATCH (Codex report) | 33/33 hash + size |
| Runtime RC1 `PACKAGE_MANIFEST.csv` | `b8e90fd5356b025be84bdebdff9e680a6d25ce55836a5a92e77da775525c8e4b` | — | its 11 engine/script files are identical to the qualification package copies |
| Test-data `PACKAGE_MANIFEST.csv` | `324e815d7908ea782f426e9ab2a0a9e6b19ef50ef6948b0817830f56423c835c` | — | 22/22 |
| Test-data `WAVE1_FREEZE_MANIFEST.csv` | `367da81d07ee2f4770cdd3f86e157282f237b01c9d2debac64f81490bd6ced56` | MATCH (Codex report) | used by every harness's freeze gate |

The manifest files use CRLF row endings. These were stripped when parsing, which does not affect the hash values.

## 3. Files added or replaced (26)

"Before" is the Git blob at `f2e1dc7`. "After" is the blob at `dc81ca7`, which is also the SHA-256 of the file as checked out (see section 4). Every "after" value equals the qualification manifest value.

| Path | Action | Before SHA-256 | After SHA-256 (= manifest) | Bytes |
|---|---|---|---|---:|
| `engine/powershell51/eMAS.BackboneXmlInventory.psm1` | Added | — | `7ccdcebde4d9826e730fbdbc04f507e497713e0e3aadbc7ab97599a3827caa3a` | 26913 |
| `engine/powershell51/eMAS.ChecksumMismatchInterpretation.psm1` | Added | — | `3c258756c3d41ed732992f85ee7a5375d6cd8e9f1eb4ffc75d6e2a334dcf6da0` | 16589 |
| `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1` | Added | — | `1b4a23fa6da31e2cf50085e1bda6780160a8eefad291cdf3694dc7f8d371daf6` | 24497 |
| `engine/powershell51/eMAS.DeclaredChecksumComparison.psm1` | Added | — | `12e742f97b800503a497f04c898c535720f1214222be63b62cac6b422d0048a5` | 21834 |
| `engine/powershell51/eMAS.MissingReferenceInterpretation.psm1` | Added | — | `540bd9bffc3b6afb6a70221c88a4dc40591e6460bf3b76050eb6b83b8df45140` | 13903 |
| `engine/powershell51/eMAS.ReferenceInventory.psm1` | Added | — | `efcd01391a9cafd659ec4c359790d54bded7cda4a6038401be0e55f9a730b1ff` | 23012 |
| `engine/powershell51/eMAS.ReferenceResolution.psm1` | Added | — | `7077d9abd07d94ad2e4fadaa0af21203385cf24eb6ce0fbbbfa3bc9e18755dc0` | 22837 |
| `engine/powershell51/eMAS.RepositoryDiscovery.psm1` | Added | — | `2ba9e3d030fcec8bf3079f5c7d2f017e77571186f6d2488acf27b28ab2ecbab1` | 38953 |
| `engine/powershell51/private/eMAS.SafeXml.ps1` | Added | — | `a3e9d7216876886aaa59b5e77564e43f574eb0bbe6155868678fc322af6206c7` | 2477 |
| `scripts/eMAS-PreSalesAssessment.ps1` | **Replaced** | `bcaf192a24ffa8453e82a7988f61e6e269b8be287ded0c157e79aa5f1328274a` | `b5c39bfbe319a838e87cf276778338bd75a471a6f59356c4fe3d7a640d7f9dbc` | 9424 |
| `tests/backbone-xml-inventory/Test-eMASBackboneXmlInventory.ps1` | Added | — | `8340e198c16ce9e944b8798ec3e3bd321d11a255381963d81ed16a847f337ce9` | 26437 |
| `tests/checksum-mismatch-interpretation/Test-eMASChecksumMismatchInterpretation.ps1` | Added | — | `9918df19e5f9d6a30b975bfc1a08044b599a8120ab2ba240d11450194e957d83` | 35200 |
| `tests/classification-evidence-collection/Test-eMASClassificationEvidenceCollection.ps1` | Added | — | `b54f971fe8404472ee04aef4f38789f83a2c7446a1e3908de8f218843f43d513` | 32983 |
| `tests/declared-checksum-comparison/Test-eMASDeclaredChecksumComparison.ps1` | Added | — | `0ab772aa10b0ca481dcc8ca68ee319122d76794364a34a81a0ab5f8befa17324` | 34730 |
| `tests/fixtures/backbone-xml-inventory/wave1-expectations.json` | Added | — | `0379908ef63c4996bdeb848e7f82723b181dc85dc3e59ae7eaf947620cf47d01` | 4854 |
| `tests/fixtures/checksum-mismatch-interpretation/wave1-expectations.json` | Added | — | `b3eab7b19ff7306746d8c175032c359cc4772ea62cf3b59bab06165ee180b858` | 16165 |
| `tests/fixtures/classification-evidence-collection/wave1-expectations.json` | Added | — | `13884602a809ea34eb1017a1ecd34f8235fc46e3dc1268fda8ec8d869685c123` | 395528 |
| `tests/fixtures/declared-checksum-comparison/wave1-expectations.json` | Added | — | `3f3f9fc23bad322c604edb081b8a6d08af770a62f38d0fcc206b01c24fc22681` | 7317 |
| `tests/fixtures/missing-reference-interpretation/wave1-expectations.json` | Added | — | `93117fe3313940333c035aedd1600a68f20c4d82ad8c8b74c77e27d164f7eee6` | 4638 |
| `tests/fixtures/reference-inventory/wave1-expectations.json` | Added | — | `51186d03dbe22d3015b0902165767c961b41cc0190e3cd90ff279b396238f910` | 7143 |
| `tests/fixtures/reference-resolution/wave1-expectations.json` | Added | — | `ba87f6dde61b43a7199a1dc49bef4c22c5e4967083952d9f99d65164f934c1f4` | 6335 |
| `tests/fixtures/repository-discovery/wave1-expectations.json` | Added | — | `41e85114b02b343dbcbf79dfae7a7844e93404032edb0068a7d72151fc6f586c` | 4616 |
| `tests/missing-reference-interpretation/Test-eMASMissingReferenceInterpretation.ps1` | Added | — | `ff3c242421663f832fc2f1b21d583fd71f4f76c138552a99cf651883773801e8` | 27915 |
| `tests/reference-inventory/Test-eMASReferenceInventory.ps1` | Added | — | `e2fd233f05c5b79c3dc4d75be5145766bc25c63eb26ceb9debb332899d44782f` | 28159 |
| `tests/reference-resolution/Test-eMASReferenceResolution.ps1` | Added | — | `6fad3514095803af3e754136c9e006b92bdc73070722c8f095b436c6c15dc95c` | 35575 |
| `tests/repository-discovery/Test-eMASRepositoryDiscovery.ps1` | Added | — | `346c800002e4a2abcfaa31b3d6dd527847ee960660ca51c52b506ea13c35d24b` | 20101 |

The Codex report saw `c5eecc78…` for `scripts/eMAS-PreSalesAssessment.ps1`. That is the CRLF checkout of the old blob `bcaf192…`. The old file also differs in content: it predates the RepositoryDiscovery parameter set. So the replacement is a real version change, not just a line-ending difference.

### Supporting config change: `.gitattributes`

The repository rules are `*.ps1 text eol=crlf` and `*.psm1 text eol=crlf`. Every `.ps1`/`.psm1` file in the qualified package uses LF. Under the existing rules:
- the committed blobs would have been byte-identical to the package;
- every checkout would have been CRLF, so the SHA-256 of the checked-out file would not match the manifest.

With human approval, `.gitattributes` gains a block of 18 exact paths marked `-text`: the 9 engine files, the entry script and the 8 harnesses. Nothing else changes:
- no glob was added;
- the existing CRLF policy still applies to every other file;
- the 8 expectation JSONs needed no override, because they are LF and `*.json` is already `eol=lf`.

`.gitattributes` SHA-256 is `0c7f4de3…` before and `c0080ab1…` after.

## 4. Byte-identity verification

1. Each of the 33 extracted qualification-package files was verified against `PACKAGE_MANIFEST.csv` (hash and size): 33/33.
2. The 11 runtime-package engine/script files were compared with `cmp` against the qualification copies: all identical.
3. Commit `dc81ca7` was cloned fresh with `git clone --no-hardlinks` into a new directory. For every manifest entry, both the checked-out file and `git show HEAD:<path>` were hashed and compared to the manifest:
   - the **26 materialized files and `tests/fixtures/runtime-config/valid-minimal.json`: 27/27 MATCH**, both in the committed objects and in the checked-out files.

### Pre-existing tracked files (not modified; noted for the gate)

These five files were already in Git at `f2e1dc7`. They are outside the materialization scope and were left untouched.

| Path | Git blob vs manifest | Checked-out file (macOS) |
|---|---|---|
| `scripts/private/Initialize-eMASPhaseRuntime.ps1` | blob = manifest `e84ffa7d…` | CRLF `ea276425…` (repository `eol=crlf` policy) |
| `engine/core/eMAS.RuntimeConfiguration.psm1` | blob = manifest `54289f49…` | CRLF `ea0175b5…` |
| `engine/core/private/eMAS.RuntimeConfiguration.Helpers.ps1` | blob = manifest `d6e43d55…` | CRLF `8531c607…` |
| `engine/core/private/eMAS.RuntimeConfiguration.Validation.ps1` | blob = manifest `a8f59207…` | CRLF `392c2bb2…` |
| `engine/core/eMAS.Configuration.Contract.psm1` | blob `56173503…` = package file with line endings normalized; the package copy itself (`ecfb3837…`) has mixed CRLF/LF | CRLF `09b7edc7…` |

Content is identical in every case. Only the working-tree line endings differ, and PowerShell does not treat those as meaningful. A baseline gate should compare these five using the Git blob (`git show HEAD:<path>`) or with line endings normalized. Only `Initialize-eMASPhaseRuntime.ps1` is loaded on a scan path. The `engine/core` files load only with `-RuntimeConfigurationPath` or in initialization mode.

`README_WINDOWS_QUALIFICATION.md` is package documentation and was not materialized.

## 5. Mac regression (8 suites)

How the suites were run:
- **Checkout:** the fresh clone of `dc81ca7`, i.e. the exact committed bytes.
- **Engine:** PowerShell 7.5.2 on macOS (arm64), `pwsh -NoProfile -NonInteractive -File <harness>`.
- **Corpus:** extracted `eMAS_MS04_PreSales_Wave1_TestData_v1`, passed as `-CorpusRoot`, with `-FreezeManifestPath …/WAVE1_FREEZE_MANIFEST.csv`.
- **Outputs:** written outside the repository.

| Suite | Exit | PASS | FAIL | OverallStatus | Accepted count |
|---|---:|---:|---:|---|---:|
| repository-discovery | 0 | 15 | 0 | PASS | 15 |
| backbone-xml-inventory | 0 | 24 | 0 | PASS | 24 |
| reference-inventory | 0 | 30 | 0 | PASS | 30 |
| reference-resolution | 0 | 33 | 0 | PASS | 33 |
| missing-reference-interpretation | 0 | 35 | 0 | PASS | 35 |
| declared-checksum-comparison | 0 | 39 | 0 | PASS | 39 |
| checksum-mismatch-interpretation | 0 | 56 | 0 | PASS | 56 |
| classification-evidence-collection | 0 | 43 | 0 | PASS | 43 |

**8/8 PASS: 275 checks, 0 failures, all exit 0.** The counts equal the accepted qualification-package smoke counts (15/24/30/33/35/39/56/43).

After the run, the clone's working tree was clean (`git status --porcelain` empty), so the harnesses wrote nothing into the repository.

This is a macOS development run. It is **not** a Windows PowerShell 5.1 qualification run, and it does not replace one.

## 6. Scope confirmation

- Only the 26 package files and the scoped `.gitattributes` block were changed, plus this report in a separate commit.
- No module, harness, expectation or entry-script content differs from the qualified package.
- The root-level dossier defects (ReferenceResolution line 285, CEC empty `DossierPath`) are **not** fixed.
- FormatDetection and RegionDetection were not added. RepositoryDiscovery is the qualified version, unmodified.
- Frozen Wave 1 fixtures, `WAVE1_FREEZE_MANIFEST.csv` and the catalogue were not touched and are not in Git.
- PR opened as **draft** into `demo/end-to-end-mvp`. Not merged.

## 7. Next step

After human review and merge, restart `EMAS-MS04-ROOT-LEVEL-DOSSIER` from the resulting `demo/end-to-end-mvp` commit and rerun the full baseline gate. For the five pre-existing files in section 4, the gate should compare Git blobs.
