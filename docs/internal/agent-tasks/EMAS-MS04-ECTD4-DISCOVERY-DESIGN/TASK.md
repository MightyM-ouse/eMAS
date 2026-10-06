# EMAS-MS04-ECTD4-DISCOVERY-DESIGN

**Task ID:** `EMAS-MS04-ECTD4-DISCOVERY-DESIGN`  
**Authoritative base commit:** `02c29863448ead141616a3c78ee8b558bb4fabfe`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user decision  
**Task type:** Authoritative evidence + design decision only  
**Runtime implementation:** NOT authorized in this task  
**Required timing:** Must be accepted before any eCTD v4 RepositoryDiscovery implementation and before FormatDetection/RegionDetection

## Why this task exists

The accepted B3 RepositoryDiscovery baseline now handles the existing v3/NeeS four-digit sequence path safely.

That baseline must not be generalized to eCTD v4 by assumption.

Current official material shows that eCTD v4 physical packaging is regionally implemented and that the submission-unit directory can use the actual sequence number rather than the v3-style four-digit convention. FDA explicitly uses the actual sequence number (for example `1`), while EU practical guidance introduces an additional first-level product/application folder before the submission-unit content.

Therefore we need a source-backed physical discovery model before changing code.

## Primary objective

Define the smallest safe, deterministic, region-tolerant RepositoryDiscovery extension that can discover plausible eCTD v4 submission-unit/dossier boundaries **without performing FormatDetection or RegionDetection**.

The design must answer:

1. What physical folder/file patterns are normative or reliably expected for eCTD v4?
2. Which of those patterns are ICH-harmonized versus regional?
3. What folder represents the submission unit / sequence?
4. How are sequence numbers named and are leading zeroes allowed?
5. Where must `submissionunit.xml` be located?
6. What role does `sha256.txt` play in discovery?
7. Where are `m1`–`m5` expected physically, and which parts are region-specific?
8. How should FDA-style and EU-style wrappers be represented without hard-coding region names?
9. How should unrelated numeric/year folders be rejected?
10. How should multiple dossiers/submission units in one export be handled?
11. What can RepositoryDiscovery safely conclude from filenames/structure alone?
12. What must remain deferred to Backbone/Format/Region interpretation?

## Authoritative source gate

Use primary/official sources. Start with `SOURCES.md`.

At minimum review the current versions of:

- ICH eCTD v4.0 Implementation Guide package and current ICH eCTD v4.0 page;
- ICH eCTD v4 support documentation / folder-and-file structure material;
- FDA eCTD v4 submission standards and current FDA Regional eCTD v4 Module 1 implementation material;
- FDA eCTD v4 technical conformance material where relevant;
- EU eCTD v4 practical guidance and current EMA/eSubmission implementation material;
- EU eCTD v4 validation/file-structure material where relevant.

If source versions conflict, record the conflict explicitly. Do not silently reconcile it.

Secondary/vendor material may explain context but cannot establish normative discovery rules.

## Required source ledger

For every rule used in the recommendation, record:

- source authority;
- exact document title;
- version/date;
- section/page;
- rule/fact derived;
- whether it is ICH-harmonized, FDA-specific, EU-specific, or interpretive;
- confidence;
- any regional caveat.

No source = no normative rule.

## Required physical-layout models

Produce source-backed tree models for at least:

### ICH/harmonized conceptual model

Show the harmonized submission-unit content without assuming a regional outer wrapper.

### FDA current v4 model

Show the FDA sequence-number folder and the direct placement of:
- `submissionunit.xml`;
- `sha256.txt`;
- content/module directories as applicable.

### EU current v4 model

Show the EU first-level folder and second-level/submission-unit structure from the current practical guidance.

Do not manufacture an EU/FDA equivalence if the regional specifications differ.

## Required design scenarios

Evaluate at least these scenarios:

- V4-01 FDA-like first submission unit using a whole-number sequence folder;
- V4-02 FDA-like later submission unit;
- V4-03 EU-like first-level wrapper + submission-unit folder;
- V4-04 deep neutral wrappers above a valid v4 package;
- V4-05 two separate v4 dossiers/packages in one repository;
- V4-06 v3/NeeS dossier beside a v4 dossier;
- V4-07 unrelated `Archive/2024/` with ordinary documents;
- V4-08 unrelated numeric folder containing an arbitrary XML file;
- V4-09 numeric folder containing `submissionunit.xml` but no other expected structure;
- V4-10 missing `sha256.txt`;
- V4-11 missing/unreadable `submissionunit.xml`;
- V4-12 access denied at the proposed submission-unit directory;
- V4-13 root-level v4 package if allowed by source evidence;
- V4-14 case variants, but only if regional/ICH rules permit or tolerate them;
- V4-15 malformed `submissionunit.xml` (discovery must remain separate from parse validity).

For each, state expected RepositoryDiscovery behavior only.

## Design alternatives to compare

At minimum compare:

### A. Extend numeric folder syntax only

Broaden the existing v3 `NNNN` gate to generic positive integers while reusing B3 signals.

### B. v4-specific structural promotion

Treat a numeric folder as a v4 submission-unit candidate only when `submissionunit.xml` is directly present, with wrapper/dossier inference around it.

### C. Generic regulatory-package structural promotion

Discover candidate package roots from direct regulatory backbone markers independent of numeric-width rules, while preserving v3/NeeS B3 separately.

### D. Another bounded alternative

Propose only if source evidence demonstrates a safer/simpler model.

Do not assume one option is correct before the matrix is complete.

## Critical design constraints

The recommendation must preserve:

- read-only/offline/deterministic behavior;
- no absolute-path leakage;
- ZIP/directory equivalence where structure is equivalent;
- no XML content parsing merely to decide physical candidacy;
- no region inference from path names;
- no dossier/product/application name inference;
- access denied ≠ absent ≠ empty ≠ parse failed;
- current v3/NeeS B3 behavior unchanged;
- wrapper discovery;
- multi-dossier isolation.

## Important distinction: package candidate vs dossier

The report must explicitly decide whether eCTD v4 physical evidence identifies:

- a **dossier/application root**;
- a **submission-unit/sequence root**;
- or only a **regulatory package candidate** from which a dossier boundary must be inferred.

Do not force v3's physical hierarchy onto v4 terminology if the source model does not support that equivalence.

If the current contract's `DossierCandidates` abstraction cannot represent v4 cleanly without semantic distortion, say so. That may require a later bounded contract decision, but do not modify the contract here.

## v4 XML boundary

RepositoryDiscovery may use the **presence/path/name** of `submissionunit.xml` as physical evidence if supported by the source.

It must not in this task:
- parse the XML root/namespace;
- interpret `ContextOfUse`;
- interpret `DocumentReference`;
- infer region/specification/version from XML;
- validate regulatory correctness.

Those belong to later capabilities.

## Test-fixture design requirement

Design the future fixture wave but do not implement it.

For each proposed fixture specify:
- fixture ID range;
- region/profile intent;
- authoritative source(s);
- exact directory tree;
- which files may be synthetic placeholders;
- which XML must be structurally representative;
- expected RepositoryDiscovery candidate/wrapper ownership;
- what must remain unknown until later capabilities.

Do **not** create a renamed v3 fixture and call it v4.

## Required recommendation

Produce one preferred design with:

1. plain-English physical discovery semantics;
2. pseudocode;
3. candidate-root semantics;
4. submission-unit-root semantics;
5. wrapper rules;
6. multi-dossier rules;
7. numeric sequence naming rules;
8. structural signals required;
9. structural signals forbidden;
10. access-denied behavior;
11. ZIP/directory behavior;
12. expected coexistence with v3/NeeS B3;
13. contract impact;
14. exact implementation files expected to change later;
15. exact fixture/test wave to build later;
16. known regional limitations.

## No implementation

Do not modify:

- `engine/**`;
- `scripts/**`;
- `tests/**`;
- existing fixtures/expectations;
- contracts/schemas;
- FormatDetection;
- RegionDetection.

Scratch experiments are allowed but must not be committed.

## Deliverable

Create only:

`docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/reports/CLAUDE.md`

The report must include:

- source ledger;
- ICH/FDA/EU physical layout trees;
- terminology mapping;
- option matrix;
- scenario matrix;
- recommended discovery semantics;
- pseudocode;
- fixture plan;
- contract/implementation impact;
- open questions.

## Acceptance criteria

Ready for ChatGPT review when:

1. all normative rules are traceable to official sources;
2. FDA and EU physical differences are represented rather than blurred together;
3. whole-number vs four-digit sequence naming is explicitly resolved by source;
4. `submissionunit.xml` placement is sourced;
5. v3/NeeS regression compatibility is addressed;
6. unrelated year/numeric folders are tested conceptually;
7. package-root vs dossier-root semantics are explicit;
8. one bounded implementation recommendation exists;
9. no runtime/test/fixture changes are committed;
10. uncertainties are clearly separated from requirements.

## Decision gate

ChatGPT reviews the fixed report and reduces it to a user decision.

Only after explicit user acceptance will a separate implementation task be created.

FormatDetection and RegionDetection remain blocked until both this design and the subsequent v4 discovery implementation are accepted.
