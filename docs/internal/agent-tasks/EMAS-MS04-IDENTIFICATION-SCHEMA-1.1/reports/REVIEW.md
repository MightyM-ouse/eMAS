# ChatGPT Review — EMAS-MS04-IDENTIFICATION-SCHEMA-1.1

**Status:** `REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed implementation commit:** `c5f21c4dd4d85a023ef494c959a786bfc6de9433`  
**Reviewed PR:** #51  
**Coordinator documentation-sync head:** `0712c9cc29071cb7342d5de0df003432b40f3458`

## Verdict

T3a is accepted by central review as the bounded Schema 1.1.0 / validator / loader implementation, subject only to explicit user merge approval.

The implementation matches the accepted T3 design and central-review amendments.

## Accepted design choices

### One schema tree

Accept the single-schema approach:

- `schemaVersion = 1.0.0` and `1.1.0` are explicitly supported;
- 1.1-only executable properties are structurally rejected when the document declares 1.0.0;
- `ruleType = IDENTIFICATION` is semantically rejected in 1.0.0;
- no compatibility adapter rewrites a 1.0.0 document.

This is smaller and safer than duplicating the complete schema.

### Dimension-scoped candidate resolution

Accepted.

Identification candidates resolve:

`targetEntityType + outputCode`

inside the declared canonical master-data dimension.

No global cross-dimension code uniqueness rule is introduced.

### Evidence strength

Accepted controlled vocabulary:

- `STRONG`
- `MEDIUM`
- `WEAK`

with governed ordinal order.

The raw CEC `Supporting` value remains outside Runtime JSON Identification semantics and will be normalized later by the T4 engine adapter.

### Evidence ceiling

Accepted.

An Identification candidate cannot claim a stronger tier than the weakest positive evidence field that may satisfy the rule.

Central review confirms the implemented semantics:

- negated conditions are applicability/guard conditions and do not themselves provide positive evidence;
- `MISSING` is an explicit absence assertion and therefore counts as evidence;
- when different OR branches can fire but the output has one fixed strength, the rule is conservatively capped by the weakest positive field across those branches.

If future rule authoring needs branch-dependent strengths, that requires an explicit future model extension rather than weakening this guard.

### Numeric Identification weights

Accept the Schema 1.1.0 prohibition.

No numeric candidate score or Identification confidence weight is approved today.

If Product Owner + Migration SME later approve numeric weights, a future schema revision may deliberately relax this rule. That future possibility does not justify allowing unapproved weights now.

### Confidence policy

Accepted:

- Identification confidence may use `resultConfidence` + `corroborationRule`;
- non-Identification scopes retain their existing numeric `weightOrScore` requirement;
- schema capability does not make any production confidence row Effective.

## Version compatibility verification

Central review confirms:

- original 16 Schema 1.0.0 fixtures remain unchanged;
- 1.1-only fields are rejected by bare JSON Schema when labelled 1.0.0;
- loader accepts 1.0.0 and 1.1.0;
- loader rejects unsupported versions;
- loader emits `CFG-COMPAT-004` for 1.1 Identification features inside 1.0.0;
- source Runtime JSON remains read-only.

## Validation evidence

At the reviewed implementation:

- schema fixture validation: 43/43 PASS;
- schema Python tests: 44 PASS;
- runtime Python tests: 12 PASS;
- PowerShell runtime harness on macOS: 28/28 PASS;
- XLSM/VBA POC validation: PASS;
- VBA tests: PASS;
- reporting tests: PASS;
- operational-skill tests: PASS.

GitHub CI on the final coordinator head:

- Runtime schema validation: PASS;
- XLSM VBA POC validation: PASS;
- macOS PowerShell 7.6 contracts: PASS;
- Windows PowerShell 7.6 contracts: PASS;
- static runtime contracts: PASS;
- Windows PowerShell 5.1: the six new T3a version/compatibility tests PASS, then the job fails only at the previously diagnosed UTF-8 metadata assertion.

The PS5.1 failure is therefore not introduced by T3a.

## Canonical documentation

Claude synchronized the four changed canonical contracts.

Central review additionally synchronized the three index/navigation files that were outside the worker's allowed scope:

- `docs/CANONICAL_DOCUMENT_INDEX.md`
- `docs/index.md`
- `docs/configuration/README.md`

This is a coordinator-only documentation sync, not a worker scope violation.

## Open item — minimumEngineVersion

The existing loader has no engine-version constant and no enforcement of `minimumEngineVersion`.

T3a must not invent that policy, so this is **not a T3a blocker**.

However, before controlled production Runtime JSON / final qualification, create a separate bounded technical task to define and enforce an engine-version compatibility contract if the project still requires `minimumEngineVersion` to be executable rather than descriptive metadata.

Do not bury this inside T3b or T4.

## Scope audit

No workbook/VBA/export implementation, CEC behavior, RepositoryDiscovery, BackboneXmlInventory, IdentificationInterpretation, report mappings, or prior mapping content is changed.

## Recommendation

**Accept and merge PR #51 as the T3a Schema 1.1.0 baseline.**

After merge:

- T3a is accepted;
- T3b workbook/export becomes the next required implementation task;
- T3c can be accepted independently;
- T4 remains blocked until T3b is accepted.
