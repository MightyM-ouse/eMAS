# EMAS-MS04-IDENTIFICATION-RULES

**Task ID:** `EMAS-MS04-IDENTIFICATION-RULES`  
**Authoritative base commit:** `401d99cbe0afbfeb12ffe4dbf5650cb149a1f529`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user decision  
**Task type:** Unified identification design / rule semantics only  
**Implementation:** NOT authorized in this task  
**Windows:** Deferred

## Purpose

Define one authoritative identification model for MS-04 Pre-Sales that later implementation can use to determine, from collected evidence:

- `TechnicalFormat`
- `Region`
- `SpecificationProfile`
- `DossierContext`

The rules must be evidence-based, deterministic, explainable, conservative, and compatible with the accepted v3/NeeS and v4 physical-discovery behavior.

The output of this task is the design contract for future FormatDetection / RegionDetection / profile/context identification implementation.

## First required action

Read:

- `BASELINE_CHANGES.md`
- current RepositoryDiscovery implementation;
- current BackboneXmlInventory;
- current ClassificationEvidenceCollection;
- accepted v4 design and implementation reports;
- accepted B3 RepositoryDiscovery reports;
- existing regulatory/technical assessment guide and mapping material present in the repository.

Before proposing rules, write a short "Current evidence actually available" section. Separate what exists today from evidence that would require a future capability.

## Core design question

Given factual evidence records, how does eMAS move from:

`Observed facts`

to:

`Candidate interpretations`

to:

`Final bounded identification result`

without:

- inventing certainty;
- allowing weak folder-name evidence to override structured XML;
- treating one dimension as another;
- creating circular rules;
- conflating discovery with validation;
- silently forcing unknown cases into a known category?

## Required output dimensions

### 1. TechnicalFormat

Define the exact Phase-1 controlled vocabulary and rule boundaries.

At minimum evaluate:

- eCTD v3.x / v3.2.2;
- eCTD v4.0;
- NeeS;
- VNeeS if supported by current project scope;
- other structured submission formats explicitly present in existing eMAS source material;
- Unknown / Indeterminate / Conflicting.

Do not introduce a format solely because it exists in the world. It must be in MS-04 scope or explicitly marked deferred.

Do not classify ASMF/DMF as formats.

### 2. Region

Define the exact Phase-1 region vocabulary and evidence needed to identify it.

At minimum review existing project scope for:

- EU;
- US/FDA;
- Canada;
- UK;
- Switzerland;
- GCC;
- other regions already represented in eMAS mapping/guide material;
- Unknown / Multiple / Conflicting where appropriate.

Important:

- path names alone are not authoritative;
- v4 first-level folder names are regional/tool-managed and may be optional;
- region should be based primarily on structured regulatory evidence where available.

If strong region evidence is currently unavailable for v4 because `submissionunit.xml` is not yet parsed, state the prerequisite capability clearly.

### 3. SpecificationProfile

Define what this dimension means and how it differs from TechnicalFormat.

Examples that must be evaluated carefully:

- ICH eCTD v3.2.2;
- EU regional Module 1 profile/version;
- FDA regional Module 1 profile/version;
- ICH eCTD v4 implementation-guide version versus regionally adopted package/version;
- NeeS profile distinctions where relevant.

Do not collapse "format" and "specification version" into one field if the evidence model benefits from keeping them separate.

### 4. DossierContext

Define what can legitimately be identified as dossier/application context.

Evaluate:

- ASMF / DMF;
- IND / NDA / CTA / MAA or other contexts already in project scope;
- medicinal product / application grouping where relevant;
- Unknown.

Do not infer dossier context from product/folder names unless the rule is explicitly weak and never final on its own.

If dossier context requires XML/application semantics not currently collected, state that clearly.

## Evidence hierarchy

Produce a canonical evidence hierarchy used across all four dimensions.

At minimum evaluate these source classes:

1. structured XML root / namespace / typed identifiers / official controlled fields;
2. XML declarations / DTD/system/public identifiers / schema/version metadata;
3. regulator-defined physical package markers and paths;
4. lifecycle-consistent structural evidence across multiple sequences;
5. declared metadata outside structured XML;
6. archive/folder/file naming heuristics;
7. free text / product names.

For each source class define:

- default strength;
- which dimensions it can support;
- which dimensions it must never determine by itself;
- whether it can be positive, negative, or only contextual evidence.

## Rule representation

Design a machine-readable rule shape suitable for later runtime JSON.

At minimum propose fields for:

- `RuleId`
- `Dimension`
- `CandidateValue`
- `RequiredEvidence`
- `ForbiddenEvidence`
- `AnyOfEvidence`
- `EvidenceStrengthRequirement`
- `Polarity`
- `Priority`
- `ConflictGroup`
- `ConfidenceEffect`
- `Applicability`
- `SourceReferences`
- `Rationale`

Keep the model as small as possible. Do not create a miniature rules language merely because JSON is available and humans apparently enjoy inventing configuration DSLs.

## Interpretation pipeline

Define the sequence:

1. evidence collection;
2. candidate generation;
3. positive/negative evidence aggregation;
4. precedence resolution;
5. conflict detection;
6. final dimension conclusion;
7. confidence;
8. explanation / traceability.

For each stage define exact inputs and outputs.

## Candidate and conclusion states

Define controlled states such as:

- `Identified`
- `Probable`
- `Indeterminate`
- `Conflicting`
- `NotAssessed`

Use different names only if clearly better.

The design must explicitly answer:

- Can multiple candidate values survive to the result?
- When is a final value allowed?
- When must the value remain null/unknown?
- How is conflicting strong evidence handled?
- What happens when only weak evidence exists?

## Confidence model

Design a simple, auditable confidence model.

Do not use opaque percentages unless there is a defensible reason.

Prefer a bounded vocabulary such as High / Medium / Low / None, with deterministic rules.

Confidence must reflect **quality and consistency of evidence**, not how strongly an agent "feels".

Required cases:

- one strong structured source;
- multiple mutually reinforcing strong/supporting sources;
- strong source plus conflicting weak source;
- two conflicting strong sources;
- only supporting structural evidence;
- only weak naming/path evidence;
- missing or parse-failed strong source.

## Precedence and conflict rules

Create an explicit matrix.

Examples:

- structured XML says v4 while path resembles v3;
- both `index.xml` and `submissionunit.xml` physically present;
- region path says EU but structured XML identifies FDA;
- DTD version suggests one profile while namespace/root implies another;
- physical v4 marker exists but XML cannot be parsed;
- damaged/v4-like physical fallback without `submissionunit.xml`;
- multiple dossiers in one repository with different regions/formats.

State whether identification is per:

- repository;
- dossier candidate;
- sequence/submission unit;
- or a combination.

The final design should strongly prefer per-dossier conclusions where the evidence supports it, rather than forcing one repository-wide answer.

## v3/NeeS requirements

For accepted v3/NeeS behavior, define rules grounded in:

- `index.xml`;
- common-backbone XML root/namespace;
- DTD/version/system/public identifiers;
- regional backbone XML;
- module path structure;
- physical `m1`–`m5` structure.

Numeric folder shape alone must never be enough for final format identification.

## eCTD v4 requirements

Treat current v4 physical discovery as **supporting structural evidence only**.

The task must decide what structured evidence is required to identify v4 strongly.

At minimum evaluate:

- `submissionunit.xml` root/namespace;
- relevant v4 message/specification identifiers;
- region/application metadata available in v4 XML;
- regionally adopted implementation-guide/profile indicators, if explicit;
- whether the current BackboneXmlInventory should be extended or a separate v4 XML inventory capability should be introduced.

This architectural decision is required in the report.

Do not implement it.

## NeeS / non-eCTD requirement

Define what evidence can distinguish NeeS from:

- an incomplete eCTD package;
- a random CTD-like folder tree;
- a document dump with `m1`–`m5` names.

A folder tree alone may be insufficient. State the minimum evidence needed and when the answer must stay indeterminate.

## Traceability

Every final identification result must be explainable.

Design output fields that allow a consultant to answer:

- What did eMAS identify?
- Why?
- Which evidence supported it?
- Which evidence contradicted it?
- Which evidence was unavailable?
- Which exact rule(s) fired?
- What prevented a stronger conclusion?

## Required regulatory/source discipline

Use authoritative official sources for externally verifiable regulatory rules.

For every normative rule, record:

- source authority;
- document title;
- version/date;
- exact section/page;
- rule derived;
- scope;
- whether authoritative regulatory requirement or eMAS design decision.

Use existing eMAS mapping/guide material as project design input, but distinguish it from regulator authority.

Do not silently "repair" source conflicts. Record them.

## Required scenario matrix

At minimum test the proposed model conceptually against:

- clean EU eCTD v3;
- clean FDA eCTD v3;
- physical v3 structure with malformed `index.xml`;
- v3 `index.xml` present but regional XML missing;
- clean physical v4 package with future parseable v4 XML evidence;
- physical v4 marker but malformed `submissionunit.xml`;
- damaged/v4-like fallback only;
- ambiguous `index.xml + submissionunit.xml`;
- EU grouped v4 physical structure;
- mixed v3/v4 lifecycle container;
- NeeS-like module tree;
- random `m1`–`m5` document folder;
- two dossiers in one repository with different formats;
- two dossiers in one repository with different regions;
- strong XML evidence conflicting with weak path evidence;
- no strong evidence available.

For each scenario show:

- available facts;
- candidate values;
- final value/state;
- confidence;
- explanation.

## Required architecture decision

The report must recommend one of:

### Option A
Separate interpretation capabilities:

- FormatDetection
- RegionDetection
- SpecificationProfileDetection
- DossierContextDetection

all consuming one shared identification-rule engine.

### Option B
One unified `IdentificationInterpretation` capability producing all four dimensions.

### Option C
Another bounded architecture.

Evaluate:

- deterministic ordering;
- shared evidence rules;
- traceability;
- avoidance of duplicated XML parsing;
- testability;
- future JSON configuration;
- compatibility with current contract.

Recommend one.

## Current contract impact

Assess whether `eMAS.MS04.PreSales.ScannerObservations/1.0` can accommodate identification results additively or whether a later contract version is required.

Do not change the contract here.

Specify the smallest proposed output structure.

## Required implementation roadmap

End the report with a bounded sequence of implementation tasks.

At minimum decide whether we need, before final identification implementation:

1. a v4 structured XML inventory capability;
2. an identification-rule runtime/config layer;
3. unified identification interpretation;
4. dedicated regional/profile rule packs;
5. content-valid v4 fixtures SD-028/SD-029;
6. later v4 Reference semantics.

Do not bundle everything into one giant implementation task.

## Non-goals

Do not:

- write runtime code;
- modify tests or fixtures;
- implement FormatDetection/RegionDetection;
- implement v4 XML parsing;
- implement v4 ReferenceResolution;
- assign RAG/severity;
- calculate migration effort;
- claim regulatory validity;
- claim migration readiness.

## Allowed files

Create/update only this task's report/status files.

## Deliverable

Create:

`docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/CLAUDE.md`

The report must contain:

- current evidence inventory;
- controlled vocabularies;
- evidence hierarchy;
- rule schema;
- interpretation pipeline;
- precedence/conflict matrix;
- confidence model;
- per-dimension rules;
- v3/NeeS rules;
- v4 rules and evidence prerequisites;
- dossier-context boundaries;
- scenario matrix;
- source ledger;
- architecture recommendation;
- contract impact;
- implementation roadmap;
- open decisions.

## Acceptance gate

Ready for ChatGPT review only when:

1. facts and interpretations are clearly separated;
2. every normative regulatory rule is source-backed;
3. weak evidence cannot override strong structured evidence;
4. unknown/conflicting outcomes are first-class;
5. v4 physical discovery is not treated as final v4 identification;
6. current missing v4 XML evidence is explicitly addressed;
7. ASMF/DMF are not formats;
8. multi-dossier repositories are handled;
9. one clear architecture is recommended;
10. implementation sequencing is bounded and practical.

No implementation starts until ChatGPT review and explicit user acceptance.
