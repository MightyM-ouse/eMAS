# EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE

**Task ID:** `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`  
**Roadmap ID:** T1b implementation  
**Authoritative base commit:** `e9530adb6f2e8b31035ca27f7267d6a2de25081d`  
**Base branch:** `coordination/emas-ms04-regional-xml-evidence-t1b-design`  
**Execution model:** Single worker (Codex) → ChatGPT fixed-SHA central review → user decision  
**Task type:** Bounded PowerShell implementation + synthetic fixtures + regression/re-qualification  
**Implementation:** AUTHORIZED by the accepted T1b design baseline  
**Merge:** NOT authorized; worker opens a draft PR only

## Purpose

Implement the accepted EU-first regional XML evidence design for MS-04 Pre-Sales without changing its regulatory or architectural decisions.

The task adds factual EU Module 1 envelope evidence to the existing scanner pipeline:

```text
eu-regional.xml
  -> BackboneXmlInventory
  -> ScannerObservations/1.0
  -> ClassificationEvidenceCollection
  -> later IdentificationInterpretation projection (separate task)
```

CEC must not reopen source XML.

## Governing accepted design

Read these first and treat them as the accepted implementation contract for this task:

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
2. `docs/governance/00_authority_and_precedence.md`
3. `docs/llm-development-context/llm-development-rules.md`
4. `docs/llm-development-context/skills/implement-powershell-module.md`
5. `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/TASK.md`
6. `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/reports/CLAUDE.md`
7. `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/reports/REVIEW.md`
8. current `BackboneXmlInventory`, `ClassificationEvidenceCollection`, ScannerObservations contract, T4 projection/oracle, and directly relevant tests/fixtures.

The fixed-SHA T1b design was accepted and user-approved. Do not reopen C-1 through C-7 or A-1.

## Closed decisions that MUST be implemented exactly

### EU first-wave scope

Support exactly these EU Module 1 regional profiles in this task:

- DTD `2.0`
- DTD `3.0.1`
- DTD `3.1`

Collect exactly five typed factual envelope fields:

1. `EU_ENVELOPE_COUNTRY` from `envelope/@country`
2. `EU_AGENCY_CODE` from `agency/@code`
3. `EU_PROCEDURE_TYPE` from `procedure/@type`
4. `EU_SUBMISSION_TYPE` from `submission/@type`
5. `EU_SUBMISSION_UNIT_TYPE` from `submission-unit/@type` for profiles where that field is defined

Do not add other regional XML fields in this task.

### Architecture C-1

Use Option A.

- Extend `BackboneXmlInventory`.
- Add a private EU regional-envelope helper, expected at:
  `engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1`.
- Extract envelope facts from the DOM already loaded by BXI.
- Do not perform a second read/parse of the same regional XML.
- CEC consumes upstream facts only and never opens XML.
- Re-qualify the modified BXI/scanner capability.

### ScannerObservations C-6

Keep the contract identifier:

`eMAS.MS04.PreSales.ScannerObservations/1.0`

The change is additive only.

Add an optional `XmlDocuments[].RegionalEnvelope` object owned by BXI. Do not create application identity or new dossier identity semantics.

Increment the scanner implementation version as defined by the accepted design; do not change the ScannerObservations contract version.

### CEC C-2 / C-3 / A-1

Emit these new EvidenceTypes only:

- `EuEnvelopeCountry`
- `EuAgencyCode`
- `EuProcedureType`
- `EuSubmissionType`
- `EuSubmissionUnitType`

For recognized profile-controlled values:

- `SourceTier = StructuredXml`
- raw `Strength = Strong`
- `CandidateValue = null`
- `Polarity = null`
- `SourceRuleId = null`
- `SourceCapability = BackboneXmlInventory`

Use only the existing legacy CEC `Dimension` compatibility hints:

| EvidenceType | Legacy CEC Dimension hint |
|---|---|
| `EuEnvelopeCountry` | `Region` |
| `EuAgencyCode` | `Region` |
| `EuProcedureType` | `DossierContext` |
| `EuSubmissionType` | `DossierContext` |
| `EuSubmissionUnitType` | `DossierContext` |

These are compatibility buckets only. Do not add new Dimension codes and do not use them to select canonical Identification dimensions.

`SourceOrdinal` is added only to new T1b envelope evidence records. Historical CEC records must not gain this property, including as `null`.

Every historical CEC EvidenceId must remain unchanged.

Use `SortGroup = 2` for the new records and deterministic ordering/identity as defined in the accepted design report.

### Profile vocabulary checks C-4 / C-5

Use the source-verified, profile-specific controlled vocabularies documented in the accepted T1b design report.

This is a bounded vocabulary comparison only. It is NOT:

- DTD validation;
- schema validation;
- regulatory validation;
- submission validation.

Do not resolve external DTDs.

Do not silently normalize controlled values.

For the known official-source inconsistency:

- `envelope/@country` follows the accepted DTD/App. 1.1 value `ema`;
- `agency/@code` may contain `EU-EMA`;
- a literal `EU-EMA` used as country is outside the supported profile vocabulary;
- never normalize `ema` and `EU-EMA` into each other.

## Required factual status semantics

Implement the accepted distinctions from the T1b report §11.

At minimum preserve separately:

- known profile-controlled value;
- mandatory field absent;
- field not defined in historical profile;
- source regional XML missing;
- XML parse failed;
- source inaccessible/unavailable;
- unsupported regional profile;
- unrecognized regional structure;
- raw value outside the profile vocabulary;
- cardinality violation / multiple values where one is expected;
- legitimate multiple envelopes;
- values differing across envelopes/lifecycle units.

Use the reason semantics defined in the accepted design, including where applicable:

- `MandatoryFieldAbsent`
- `FieldNotDefinedInProfile`
- `SourceXmlMissing`
- `SourceXmlParseFailed`
- `SourceXmlUnavailable`
- `UnsupportedRegionalProfile`
- `UnrecognizedRegionalStructure`
- `ValueOutsideProfileVocabulary`
- `CardinalityViolation`
- `EnvelopeValuesDiffer`

Do not invent, guess, normalize or collapse values.

Unknown/out-of-vocabulary values may be preserved factually in BXI but must not become supported Strong CEC records.

## XML selection rules

Implement the accepted selector rules from the T1b report §6.

Key constraints:

- match root by namespace URI + local-name, not arbitrary prefix;
- expected EU root namespace is `http://europa.eu.int`;
- envelope descendants are unqualified/no-namespace according to the accepted DTD design;
- support namespace-prefix changes with the same namespace URI;
- preserve document-order envelope ordinal, 1-based;
- no prefix-dependent XPath;
- no external-DTD resolution;
- profile is resolved per XML document, never per dossier.

## Per-field CEC coverage

Add one collection-coverage row per regional XML document and first-wave field as defined by the accepted design.

Use:

`CheckId = RegionalEnvelopeField:<FieldCode>`

with existing coverage columns/status vocabulary.

Do not change the existing repository/XmlDocument coverage rows.

## Deferred decisions / explicit non-goals

Do NOT implement or resolve:

- CEC-FIELD-PROJECTION/2;
- any T4/IdentificationInterpretation consumption of the new evidence;
- Effective Identification rules;
- P-2 canonical authorisation-procedure dimension;
- P-3 cross-version semantic aliases such as `initial-maa` -> `maa`;
- P-4 EU M1 1.4/1.4.1 or 3.0 support;
- P-6 UUID/application grouping;
- P-7 projection-v2 semantics;
- T3c U2-U9;
- relationship-derived Region;
- ASMF/DMF/CEP interpretation;
- ProductDomain/ProductClass inference;
- `submission/@mode`;
- sequence/related-sequence interpretation;
- applicant/product/free-text evidence;
- EU eCTD v4 `submissionunit.xml`;
- US/FDA, Canada, UK, Switzerland, GCC or other regional mappings;
- runtime JSON/schema/workbook changes;
- report-contract changes.

## Allowed production files

Implementation owner may change only the smallest set required from:

- `engine/powershell51/eMAS.BackboneXmlInventory.psm1`
- `engine/powershell51/private/eMAS.EuRegionalEnvelope.ps1` (new)
- `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`
- `.gitattributes` only if required to preserve the existing byte/qualification convention for the modified/new PowerShell source

No other production module is authorized.

## Allowed tests / fixtures

The worker may change directly relevant test and expectation files under:

- `tests/backbone-xml-inventory/**`
- `tests/classification-evidence-collection/**`
- `tests/fixtures/backbone-xml-inventory/**`
- `tests/fixtures/classification-evidence-collection/**`
- `tests/regional-xml-evidence/**` (new if useful)
- `tests/fixtures/regional-xml-evidence/**` (new synthetic fixtures)
- directly affected Wave1/Wave1D expectation files only where new additive records/counts require regeneration, without changing frozen fixture bytes
- directly relevant qualification manifests/hashes only when the repository workflow requires recording the new qualified source version

If another file is genuinely required, stop and explain the need in the task report before changing it.

## Forbidden changes

Do not modify:

- RepositoryDiscovery;
- ReferenceInventory / ReferenceResolution;
- checksum capabilities;
- IdentificationInterpretation;
- T4 behavioral contract or oracle expected semantics;
- runtime JSON/schema;
- workbook/VBA;
- report templates/contracts;
- phase scripts except if a pre-existing test harness requires no code change;
- frozen fixture ZIP bytes;
- unrelated configuration or regulatory mappings.

## Baseline gate before implementation

Before editing production code:

1. confirm the working branch descends from authoritative base `e9530adb6f2e8b31035ca27f7267d6a2de25081d`;
2. confirm the formal TASK.md and STATUS.md are present;
3. run the current accepted BackboneXmlInventory tests;
4. run the current accepted ClassificationEvidenceCollection tests;
5. run all accepted Wave 1 suites;
6. run accepted Wave1D regression where present;
7. run the current T4 focused engine and oracle regressions;
8. record baseline results in `reports/CODEX.md`.

If the accepted baseline cannot be reproduced, stop and report rather than broadening scope.

## Required focused test matrix

At minimum cover:

1. clean EU 3.1 regional XML with multiple envelopes;
2. EU 3.0.1 equivalent extraction;
3. EU 2.0 equivalent extraction and `submission-unit` = `FieldNotDefinedInProfile`;
4. mandatory field absent in a successfully parsed supported profile;
5. malformed regional XML;
6. regional XML missing;
7. inaccessible/unavailable source where the existing harness can represent it;
8. unsupported/missing `dtd-version`;
9. root/namespace/unqualified-envelope structure mismatch;
10. value outside the declared profile vocabulary, with raw BXI value preserved and no Strong CEC record;
11. duplicate/multiple cardinality violation;
12. legitimate multiple envelopes with distinct ordinals;
13. lifecycle-unit value changes preserved independently;
14. root namespace prefix change with identical namespace URI;
15. default-namespace envelope mismatch treated as unrecognized structure;
16. free-text envelope content is not collected as first-wave evidence;
17. all five new EvidenceTypes;
18. Strong / StructuredXml on recognized typed values;
19. CandidateValue/Polarity/SourceRuleId remain null;
20. legacy Dimension hint set remains unchanged;
21. SourceOrdinal exists only on new envelope records;
22. every historical CEC EvidenceId remains unchanged;
23. deterministic output across repeated runs/input-order variation;
24. CEC succeeds from mocked BXI RegionalEnvelope data when the original XML is unavailable, proving CEC does not reopen XML;
25. source fixture bytes remain unchanged.

## Re-qualification / regression gate after implementation

Run the narrow focused tests first, then the repository's required regression/qualification suites.

Required evidence includes:

- BackboneXmlInventory regression;
- ClassificationEvidenceCollection regression;
- all accepted Wave 1 suites;
- Wave1D regression where available;
- root-level dossier regression if part of the current accepted chain;
- T4 focused engine regression;
- T4 oracle regression;
- frozen fixture hash/integrity checks;
- deterministic ordering/EvidenceId checks;
- read-only source evidence check;
- Windows PowerShell 5.1 compatibility using the repository's supported CI/native lane where available;
- PowerShell 7/macOS regression where used by the current project flow.

Do not claim Windows re-qualification if no Windows PowerShell 5.1 evidence actually ran.

## Implementation report

Create/update only the worker report:

`docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/reports/CODEX.md`

The report must include:

- task ID;
- authoritative base SHA;
- branch and final commit SHA;
- exact files changed;
- pre-change baseline results;
- implementation summary;
- exact five evidence types;
- supported profiles;
- status/vocabulary behavior;
- historical EvidenceId compatibility result;
- deterministic-order result;
- no-second-parse / no-CEC-reopen evidence;
- source read-only/hash result;
- all focused/regression/re-qualification commands and results;
- Windows PS5.1 evidence status;
- deferred items deliberately not implemented;
- blocker/open issue list;
- draft PR number/link.

## Git workflow

Use implementation branch:

`implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`

Open a **draft PR into**:

`coordination/emas-ms04-regional-xml-evidence-t1b-design`

Do not merge.

The worker may commit and push only this dedicated implementation branch.

ChatGPT performs a fixed-SHA central review. User approval is required before implementation is accepted into the coordination baseline.

## Stop conditions

Stop rather than improvise if:

- this TASK conflicts with the accepted T1b design;
- a required official profile/value mapping is ambiguous or absent from the accepted design;
- implementation requires a second XML parse;
- CEC must reopen XML;
- historical EvidenceIds cannot be preserved;
- a breaking ScannerObservations contract change appears necessary;
- a new regulatory/business interpretation is required;
- T4 must change to complete collection;
- unsupported EU profiles must be interpreted;
- PowerShell 5.1 compatibility cannot be maintained;
- source evidence cannot remain read-only.

Record the exact blocker and evidence in the worker report. Do not expand scope.

## Definition of done

Ready for central review only when:

1. exactly five accepted EU envelope facts are implemented for profiles 2.0 / 3.0.1 / 3.1;
2. extraction occurs during the existing BXI XML parse;
3. CEC never reopens XML;
4. ScannerObservations remains additive 1.0;
5. recognized facts emit Strong / StructuredXml evidence with null interpretation fields;
6. no new CEC Dimension codes exist;
7. SourceOrdinal is new-record-only;
8. historical record shape and EvidenceIds are preserved;
9. missing/unsupported/parse-failed/unrecognized/out-of-vocabulary/cardinality states remain distinct;
10. focused tests and required regression/re-qualification gates pass or any unavailable platform gate is explicitly recorded as pending rather than claimed;
11. no forbidden file/scope changed;
12. worker report and draft PR are published.
