# ChatGPT Review — EMAS-MS04-PRIOR-MAPPING-DISPOSITION

**Status:** `REVIEW_PASS — READY_FOR_USER_DECISION_WITH_AMENDMENTS`  
**Reviewed Claude commit:** `9948d21e68b8dd7dd4f104b6d94b99708257f5b7`  
**Reviewed PR:** #50

## Verdict

T3c is acceptable as the controlled legacy-rule disposition baseline.

Claude correctly treated the prior mapping as historical design input rather than authority, covered all 39 identification rules exactly once, preserved confidentiality, and separated reusable intent from obsolete dimensional/evidence semantics.

Accepted disposition totals:

- `RE_MODEL`: 19
- `SEED_AS_DRAFT`: 4
- `REJECT`: 16

No legacy rule is accepted as-is and none becomes Effective.

## Source verification

Central review independently reconfirmed the key current regulatory baseline used by the report:

- FDA currently supports eCTD v3.2.2 and v4.0 and lists US Module 1 specification v2.6 / application-type list v1.1;
- FDA Module 1 uses coded application-type values and official examples confirm `fdaat5` for DMF;
- EU Module 1 v3.1.1 is the current mandatory EU M1 specification from 1 December 2025;
- the EU M1 v3.1 release introduced `xi` for UK(NI) and clarified the former `uk` handling.

The report is therefore justified in rejecting literal-text and stale regional assumptions and in requiring refreshed authoritative sources before any affected replacement becomes Effective.

## Accepted canonical corrections

Accept:

1. regional Module 1 implementations are `RegionalImplementation`, not TechnicalStandard;
2. Region and RegionalImplementation remain separate;
3. ASMF / DMF are context/application concepts, not formats;
4. physical v4 markers cannot produce Strong/final v4 identification alone;
5. free-text/path/product-name evidence cannot produce a final value by itself;
6. the old Category/Type axis must be split into canonical dimensions;
7. Unknown/Other fallback logic belongs to result/status behavior, not catch-all identification rules;
8. candidate codes resolve inside their declared dimension; no global code uniqueness.

## Disposition acceptance

### SEED_AS_DRAFT

Accept all four as Draft-only seeds:

- `R-FMT-01` — eCTD v3.2.2;
- `R-TYP-03` — Investigational;
- `R-TYP-04` — PostMarketing;
- `R-TYP-06` — Biologic.

The three Type seeds remain dormant until T1b supplies the structured fields they require.

### RE_MODEL / REJECT

Accept the remaining dispositions as backlog/governance decisions, not executable rules.

A RE_MODEL item must receive a new governed RuleId.

A REJECT item may remain as a product/backlog note where the underlying business intent is useful, but must not be imported into runtime content.

## Amendment 1 — U10 is already closed

The report lists the Weak-only floor as unresolved U10.

That is no longer open.

The accepted Identification Rules design already established:

- Weak evidence may produce candidates;
- Weak evidence alone may not produce a final identified value.

Therefore the normalized minimum evidence strength for a final value is:

`MEDIUM`

for the current MS-04 Identification policy.

T3b should author this as governed policy content and keep candidates visible for review.

## Amendment 2 — do not reopen T3a for G9

T3c guard G9 states that Region derived from RegionalImplementation must cite an approved relationship.

Accept the rule, but assign enforcement as follows:

- T3b: workbook/content validation must require an approved relationship reference for such Region rules;
- T4: runtime interpretation must resolve Region through the governed relationship;
- T3a does **not** need to be widened retroactively.

T3a already enforces dimension-scoped candidates and the schema boundary. Relationship-derived Region is content/engine semantics.

## Amendment 3 — T1b EU envelope extension is recommended

U1 should be carried forward with a **recommended YES**:

T1b should include typed EU envelope fields required for:

- submission type;
- destination/agency code;
- ASMF/PMF context where source-backed;
- EU lifecycle context where source-backed.

This is not required to accept T3c, but it should be included when T1b is formally scoped.

## Amendment 4 — keep U2–U9 open

Do not resolve the following by inference inside T3c/T3b:

- Region-from-RegionalImplementation confidence by region;
- EEA region taxonomy;
- UK(NI) versus GB;
- ProcedureContext values for DMF/PMF/VAMF/CEP;
- non-eCTD electronic target dimension;
- VNeeS marker;
- ProductDomain derivation;
- device/vaccine/blood-product scope.

These need explicit Regulatory SME / Product Owner decisions.

## Amendment 5 — legacy cross-reference

Recommended T3b behavior for U11:

- workbook field: `LegacyRuleId`;
- authoring/traceability only;
- not exported as executable runtime identity;
- new rules receive fresh governed RuleIds.

This keeps historical traceability without allowing legacy IDs to become runtime authority.

## Production migration gate

T3c acceptance does not make any historical rule runtime-ready.

Production migration of legacy-derived rules remains blocked until:

- T3a accepted;
- T3b accepted;
- source refresh completed where required;
- needed T1b/T2 evidence capabilities exist;
- required Regulatory SME + Product Owner approvals are recorded.

## Recommendation

**Accept T3c with the central-review amendments above and merge PR #50 into its coordination branch.**

T3c does not block T4 test-engine implementation, but it blocks production migration of legacy rule content.
