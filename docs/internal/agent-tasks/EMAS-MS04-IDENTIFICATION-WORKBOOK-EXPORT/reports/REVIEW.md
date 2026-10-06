# ChatGPT Review — EMAS-MS04-IDENTIFICATION-WORKBOOK-EXPORT

**Status:** `REVIEW_PASS — READY_FOR_USER_DECISION`  
**Reviewed Claude implementation:** `ef1e383473162902eeff412a28556e366a6530e9`  
**Reviewed PR:** #53  
**Coordinator synchronization head:** current PR head after documentation/workflow-label synchronization

## Verdict

T3b passes central review as the **source-controlled Schema 1.1.0 workbook/VBA authoring and governed-export baseline**.

The implementation stays inside the accepted boundary:

- workbook authors Schema 1.1.0 Identification content;
- controlled/runtime projection is Effective-only and date-bounded;
- excluded rules lose the complete dependent rule graph;
- `LegacyRuleId` remains authoring-only and is not serialized;
- no historical T3c rule is imported;
- no numeric Identification weight is introduced;
- dimension-scoped candidate resolution is preserved;
- T4 is not implemented;
- native Excel qualification is explicitly not claimed.

## Workbook authoring model

Accepted additions:

- `tblValueLists.SortOrder`;
- `tblFieldCatalogue.MaxEvidenceStrength`;
- `tblRules.LegacyRuleId` as workbook-only traceability;
- `tblRuleOutputs.TargetEntityType`;
- `tblRuleOutputs.EvidenceStrength`;
- `tblRuleOutputs.EvidencePolarity`;
- `tblConflictPolicies.MinimumEvidenceStrengthForValue`;
- `tblConfidencePolicies.ResultConfidence`;
- `tblConfidencePolicies.CorroborationRule`.

`SortOrder` is justified by the canonical Data Dictionary and is required to author the accepted STRONG > MEDIUM > WEAK ordinal contract.

The POC's Schema/Mapping/Workbook versions are coherently moved to the 1.1.0 / 0.2.0 conformance baseline.

## Controlled values

Accepted synthetic POC lists include:

- EVIDENCE_STRENGTH = STRONG / MEDIUM / WEAK;
- CONFIDENCE = HIGH / MEDIUM / LOW / UNKNOWN;
- EVIDENCE_POLARITY = SUPPORTS / CONTRADICTS;
- TIE_BEHAVIOR = UNKNOWN / MANUAL_REVIEW;
- CORROBORATION_RULE = NONE_REQUIRED / INDEPENDENT_SOURCE_CLASS;
- IDENTIFICATION rule type;
- complete authoring lifecycle values.

`Supporting` is correctly absent from executable workbook configuration. The later T4 engine adapter remains responsible for raw CEC `Supporting → MEDIUM` normalization.

The POC `IDENTIFICATION_DIMENSION` list is intentionally a synthetic conformance subset, not a production dimension pack.

## Runtime projection

Central review accepts the projection:

`Status = Effective AND EffectiveFrom <= evaluation date AND (EffectiveTo empty OR evaluation date < EffectiveTo)`

When a rule is excluded, the implementation consistently excludes:

- rule-phase assignments;
- condition groups;
- rule conditions;
- rule outputs;
- RULE_SUPERSESSION relationships whose endpoint is outside the projected rule set.

The independent verifier checks the projected graph instead of merely calling the projection routine again.

This is the required dependency-safe behavior.

## LegacyRuleId

Accepted as workbook-only traceability.

Central review verified the implementation has defence in depth:

1. projection removes the workbook-only column;
2. generic runtime builder excludes it;
3. serialized JSON is scanned for the property and authored values;
4. VBA performs an equivalent pre-return assertion;
5. legacy IDs cannot substitute for governed RuleIds;
6. historical `R-REG/R-FMT/R-TYP` identifiers are not imported as executable RuleIds.

The accepted T3c disposition remains governance input rather than runtime authority.

## Identification policy authoring

Accepted synthetic conformance behavior:

- `MinimumEvidenceStrengthForValue = MEDIUM`;
- Identification confidence uses `ResultConfidence + CorroborationRule`;
- Identification confidence carries no numeric `WeightOrScore`;
- existing non-Identification confidence retains numeric weight behavior.

This proves schema/workbook capability only. It does not approve production regulatory policy rows.

## Central decision — Reviewed rules in DEV

Claude correctly reported the tension between:

- FR-GOV-006 / TR-LIFE-006: Reviewed rules **SHOULD/MAY** enter explicitly marked DEV exports; and
- Runtime JSON Schema 1.0.0/1.1.0: runtime rule status is `Effective` only.

This is **not a T3b blocker**.

For the current MS-04 baseline, both DEV and CONTROLLED runtime projections remain **Effective-only**.

Rationale:

- FR-GOV-006 and TR-LIFE-006 are SHOULD-level capability, not MUST;
- allowing Reviewed rules now would require weakening the accepted runtime schema or creating a second DEV runtime-rule contract;
- T3b was explicitly prohibited from reopening T3a schema semantics;
- Effective-only DEV is conservative and does not create uncontrolled executable content.

If Reviewed-in-DEV becomes necessary, handle it as a separate bounded Technical Architect + Product Owner schema/contract decision. Do not smuggle it into T4.

Therefore O-1 is **DEFERRED_BY_DESIGN**, not open/blocking.

## Other reported open items

### Native Excel

`NATIVE_EXCEL_QUALIFICATION_PENDING` remains valid.

Source/CI conformance does not prove Excel/VBA execution.

This is not a T3b repository-baseline blocker because the T3b task explicitly allowed native execution to remain pending, but native Windows/Excel evidence is required before final workbook/VBA qualification.

### Non-rule entity lifecycle projection

T3b is accepted as a **rule-graph lifecycle projection**.

Value lists, master data, findings and policies remain exported as authored and must themselves satisfy the Runtime JSON schema/semantic contract.

A future need for independent lifecycle projection of those entity types must be handled in a separate bounded workbook-governance task. It is not part of T3b.

### Synthetic dimensions

The two-dimension POC subset is conformance data only. It does not resolve T3c U2–U9 and must not be treated as the production Identification dimension set.

## Validation evidence

Claude reported and central review confirmed the intended suite coverage:

- POC validator: 53 checks PASS;
- POC fixtures: 38/38 PASS;
- VBA tests: 22 PASS;
- Schema tests: 44 PASS;
- static runtime tests: 12 PASS;
- reporting tests: 28 PASS;
- controlled-template validation: PASS;
- operational-skill validation: PASS;
- PowerShell runtime harness on macOS: 28/28 PASS;
- workbook generation is deterministic;
- reference JSON SHA-256 is stable.

GitHub CI at the reviewed worker head:

- XLSM/VBA POC validation: PASS;
- macOS PowerShell contracts: PASS;
- Windows PowerShell 7.6 contracts: PASS;
- static runtime contracts: PASS;
- Windows PowerShell 5.1 fails only on the previously diagnosed UTF-8 metadata expectation, after all relevant configuration tests pass.

The PS5.1 failure is unrelated to T3b.

## Coordinator synchronization

The worker correctly left coordinator-owned index/workflow files untouched.

Central review synchronized:

- `docs/CANONICAL_DOCUMENT_INDEX.md`;
- `docs/index.md`;
- `docs/configuration/README.md`;
- the cosmetic XLSM/VBA CI step label from Schema 1.0.0 to Schema 1.1.0.

The canonical index now reflects POC Contract v1.1, Schema 1.1 Identification support and ten VBA modules.

## Native qualification boundary

Do not call T3b "Windows-qualified" or "Excel-qualified".

Accepted state is:

`SOURCE_AND_AUTOMATED_CONFORMANCE_ACCEPTED / NATIVE_EXCEL_PENDING`

The later native gate must execute:

- `build/Build-eMASMappingPoc.ps1`;
- `build/Test-eMASMappingPoc.ps1`;

on supported Windows desktop Excel and prove two byte-identical VBA exports equal to the approved golden JSON hash.

## Recommendation

**Accept and merge PR #53 as the T3b source-controlled workbook/export baseline.**

After merge:

- T3b is accepted;
- T4 `IdentificationInterpretation` becomes unblocked for bounded implementation;
- native Excel qualification remains a later qualification gate;
- Reviewed-in-DEV remains explicitly deferred unless separately approved.


## User decision

Accepted. PR #53 is approved for merge as the T3b source-controlled workbook/export baseline.

Accepted qualification wording remains:

`SOURCE_AND_AUTOMATED_CONFORMANCE_ACCEPTED / NATIVE_EXCEL_PENDING`

The refreshed coordinator-head CI confirms the same expected profile: XLSM/VBA POC, macOS PowerShell, Windows PowerShell 7.6 and static runtime contracts pass; Windows PowerShell 5.1 fails only on the previously diagnosed UTF-8 metadata expectation. This unrelated failure is not a T3b blocker.

After merge, T4 IdentificationInterpretation is unblocked for bounded implementation. Native Excel/VBA qualification remains a later explicit gate.
