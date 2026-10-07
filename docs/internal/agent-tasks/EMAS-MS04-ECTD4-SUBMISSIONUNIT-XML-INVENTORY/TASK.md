# EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY

**Task ID:** EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY
**Roadmap ID:** T2
**Authoritative base commit:** 09c6e3bbb37f9811e045214cfb6b9bb575ce669e
**Base branch:** demo/end-to-end-mvp
**Coordination branch:** coordination/emas-ms04-ectd4-submissionunit-xml-inventory
**Execution model:** Claude design/research worker → ChatGPT fixed-SHA central review → user design decision
**Task type:** Regulatory source verification and architecture design only
**Implementation:** NOT AUTHORIZED
**Future implementation owner:** Codex, only through a separate bounded task after design acceptance

## Why this task exists

The accepted MS-04 baseline can discover eCTD v4-like physical submission-unit
folders and can collect the physical presence of submissionunit.xml. It does
not parse submissionunit.xml or collect its structured facts.

The accepted Identification Rules roadmap names T2 as
EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY and requires a separate optional
SubmissionUnitXmlInventory capability before eMAS can claim Strong structured
v4 evidence or reliable v4 Region, SpecificationProfile, LifecycleContext, or
application/submission context.

This task establishes the evidence and architecture contract first. It must not
turn regulatory interpretation into parser behavior by assumption.

## Primary objective

Produce a source-backed design for collecting bounded factual evidence from
eCTD v4 submissionunit.xml documents.

The design must identify the exact XML structures that can be collected as
facts, define capture and failure semantics, specify the ScannerObservations
and CEC impact, and make the later implementation mechanically bounded.

The design must keep these layers separate:

1. physical discovery of a candidate submission-unit folder;
2. safe XML capture and factual extraction;
3. CEC publication of source-backed facts;
4. later interpretation and projection into identification dimensions.

## Accepted baseline and constraints

- RepositoryDiscovery already identifies physical v4 submission-unit
  candidates, damaged candidates, conflicting markers, and unplaced markers.
- Physical marker evidence already exists in CEC and is not equivalent to
  parsed structured evidence.
- T1b established the factual-collection pattern for regional XML, but T2 is a
  separate optional capability and must not be implemented as a casual BXI
  extension.
- ScannerObservations remains eMAS.MS04.PreSales.ScannerObservations/1.0 unless
  the design proves an additive-compatible representation is impossible.
- CEC remains fact-only. It does not choose a final format, region, profile,
  application, lifecycle, or submission classification.
- CEC-FIELD-PROJECTION/1 and T4 currently ignore future T2 facts.
- T4, rule-pack, projection, workbook, reporting, and UI changes are deferred
  unless the design demonstrates a strict prerequisite. Any prerequisite must
  be proposed as a separate governed follow-up; it is not implemented here.
- Native Windows PowerShell 5.1 T1b qualification remains a separate open item
  and is not part of T2 design.

## Required research questions

The report must answer all of the following with official-source citations.

### A. XML identity and profile markers

1. What is the exact root element local name and namespace URI?
2. Which interaction, message, realm, profile, implementation-guide, or
   identifier markers establish that a document is an eCTD v4 submission unit?
3. Which OIDs, identifierName values, code systems, schema references, or
   regional implementation-guide markers are normative facts?
4. Which markers identify ICH-level versus regional implementation guides?
5. Which markers are mandatory, optional, repeatable, or version-dependent?
6. Can a profile/version be determined from the document alone, and at what
   confidence, without performing regulatory interpretation?
7. How must unknown, historical, draft, future, or conflicting profile markers
   be represented without guessing?

Every proposed field must include an exact namespace-aware XPath-like location,
element or attribute name, datatype, cardinality, and source citation.

### B. Exact factual extraction candidates

Investigate, rather than assume, whether the following categories are suitable
for factual extraction:

- message/root identity and namespace;
- message or submission-unit identifiers;
- ICH implementation-guide identifier and version markers;
- regional implementation-guide identifiers and version markers;
- identifierName and identifier roots/extensions;
- application identifiers and their assigning-authority roots;
- submission-unit sequence number and any display/value representation;
- application type, submission type, submission-unit type, or related codes;
- code, codeSystem, codeSystemName, displayName, and originalText components;
- creation/effective time values when explicitly present and unambiguous;
- lifecycle relationships that are directly asserted by the message;
- region/authority markers that are explicitly encoded rather than inferred;
- other exact elements required to distinguish a supported profile from an
  unsupported or unrecognized structure.

For every candidate, classify it as:

- collect now as a raw fact;
- retain only as diagnostic/provenance;
- defer pending regulatory or privacy review;
- reject because it is interpretive, unstable, free text, personal data, or
  outside MS-04 Pre-Sales scope.

Do not create an evidence type merely because an element exists.

### C. Application, lifecycle, and submission-unit semantics

The report must distinguish:

- physical submission-unit folder;
- submission-unit message identity;
- sequence number;
- application identity;
- submission identity/type;
- submission-unit type;
- lifecycle relationships across submission units;
- Context of Use or document lifecycle relationships;
- regional authority/profile identity.

State which relationships are directly represented in XML and which would
require cross-document or cross-unit interpretation. Do not equate sequence,
submission unit, submission, application, dossier, and lifecycle event unless
an official source explicitly supports that equivalence.

The design must state whether repeated application identifiers or relationships
can be collected independently per submission unit without creating an
application-level aggregate.

### D. Historical and version compatibility

Establish a version matrix covering:

- the current ICH eCTD v4 implementation guide and supported predecessor
  versions that can appear in real exports;
- current and historical FDA regional v4 profiles relevant to accepted or
  transition-period submissions;
- current and historical EU/EMA v4 profiles, including the status of any draft
  versus final implementation guide;
- known differences in marker OIDs, identifierName values, namespaces,
  cardinalities, controlled vocabularies, and sequence-number rules;
- forward-compatible behavior for an otherwise valid but unknown later profile;
- whether schema validation is required, optional, or explicitly out of scope.

Separate these statuses:

- current and supported;
- historical but supported;
- historical and unsupported;
- draft/pilot only;
- unknown or not verified.

Do not silently normalize version aliases or treat a newer value as equivalent
to an older value.

### E. Failure and collection-status semantics

Define deterministic, fact-preserving behavior for at least:

- physical marker absent;
- discovered marker disappears before open;
- access denied;
- input unavailable;
- safe XML parse failure;
- external entity or schema resolution attempt;
- root local-name mismatch;
- namespace mismatch;
- supported structure with missing profile marker;
- unsupported or unknown profile marker;
- duplicate singleton elements;
- unexpected cardinality;
- missing mandatory element or attribute;
- unknown code with a known code system;
- known code with an unexpected code system;
- multiple conflicting identifiers or profile markers;
- schema not evaluated;
- schema validation failure, only if validation is recommended;
- partial collection where some facts remain usable;
- collection not attempted because the capability is disabled.

For each case specify:

- capture status;
- collection status;
- reason code;
- whether any raw fact may still be emitted;
- whether CEC may emit a Strong, Supporting, Weak, or no evidence record;
- whether the condition is a parser fact, coverage fact, or later
  interpretation concern.

Absence, unavailability, parse failure, unsupported profile, invalid value, and
ambiguity must not collapse into one status.

## Required architecture analysis

### SubmissionUnitXmlInventory boundary

The default accepted direction is a separate optional
SubmissionUnitXmlInventory capability. The report must confirm or challenge
that direction using concrete repository and source evidence.

Specify:

- invocation point after RepositoryDiscovery;
- safe-reader reuse and prohibition on network, DTD, or external schema access;
- directory and ZIP behavior;
- document identity and ownership by dossier/submission unit;
- whether one parse can serve both inventory and CEC;
- module/file boundaries and exact future files expected to change;
- how a disabled optional capability is represented;
- idempotence, determinism, stable ordering, and stable IDs;
- protection against reopening arbitrary source paths in CEC;
- preservation of existing BXI behavior and accepted evidence IDs.

### ScannerObservations impact

Compare at least:

1. a new additive collection dedicated to submission-unit XML observations;
2. extension of XmlDocuments with a new XML kind and typed payload;
3. a separate optional capability result composed into ScannerObservations;
4. another bounded option only if clearly superior.

For each option assess:

- compatibility with ScannerObservations/1.0;
- unknown-member behavior;
- record identity and ownership;
- coverage representation;
- existing consumer impact;
- JSON depth/serialization behavior under PowerShell 5.1;
- whether historical records or tests change;
- whether a contract version bump is actually required.

Recommend one option and provide an exact proposed object shape with field
names, datatypes, nullability, cardinality, ordering, and example values.
Examples must be labelled illustrative unless copied from a cited official
example.

### BXI and CEC impact

The report must explicitly state:

- whether BXI remains unchanged;
- whether any existing XmlDocuments shape changes;
- proposed factual CEC evidence types, if any;
- proposed source capability and source field for each type;
- proposed legacy Dimension compatibility hint, if needed;
- proposed Strength and SourceTier with justification;
- whether SourceOrdinal or a new ordinal/provenance field is needed;
- how historical CEC shape and EvidenceIds remain unchanged;
- field-specific coverage and reason codes;
- which raw facts must not become Strong evidence;
- how code, code system, and display text are kept distinct.

No CandidateValue, Polarity, SourceRuleId, canonical dimension, or final
identification result may be invented in this task.

### T4 and projection impact

The expected outcome is that CEC-FIELD-PROJECTION/1 and T4 remain unchanged
during T2 collection.

The report must explicitly decide whether:

- all projection/rule-pack use can be deferred to a later
  CEC-FIELD-PROJECTION/2 or T4a task; or
- a strictly necessary prerequisite exists.

If a prerequisite exists, document it as a separate proposed task with exact
reason and scope. Do not edit T4, projection, runtime rules, schema, oracle,
workbook, or report contracts here.

## Required source-verification protocol

Read SOURCES.md first. For every normative claim, the report must record:

- stable source ID;
- issuing authority;
- exact title;
- document/package version and publication or endorsement date;
- current status: final, supported, historical, draft, pilot, or superseded;
- canonical landing-page URL and direct document URL when available;
- access date;
- exact section, table, figure, schema component, or printed page;
- verbatim XML name/value no longer than needed for identification;
- fact derived;
- scope: ICH, FDA, EU/EMA, or other;
- confidence and any conflict.

When an official package includes XSDs, controlled vocabularies, examples, or
validation criteria, cite the exact artifact name and version/checksum where
practical.

If two official sources conflict:

1. record both;
2. do not silently reconcile them;
3. identify whether the difference is versioned, regional, draft/final, or
   genuinely unresolved;
4. keep the related eMAS behavior factual or NotAssessed until governed.

Secondary or vendor material may aid discovery but cannot establish a
normative field, cardinality, code, profile, or lifecycle meaning.

## Factual collection versus interpretation

The report must contain two separate tables:

### Factual collection table

Exact XML path, raw value components, profile applicability, cardinality,
capture status, provenance, and proposed ScannerObservations/CEC representation.

### Interpretation/deferred table

Potential meanings such as final format, region, specification profile,
authority, lifecycle context, application grouping, submission classification,
confidence, normalization, aliases, and conflict resolution.

The second table is design input for future governed work only. It must not be
presented as parser output or accepted regulatory semantics.

## Required scenarios and future fixture design

Design, but do not implement, future content-valid fixtures. Preserve the
accepted roadmap intent for SD-028 and SD-029 unless repository allocation
shows those IDs are occupied; if occupied, propose the next available IDs.

Cover at least:

- current official ICH profile with one supported regional profile;
- a second supported region or regional profile;
- historical supported profile;
- unknown later profile marker;
- missing profile marker;
- malformed XML;
- root/namespace mismatch;
- missing mandatory identifier;
- duplicate singleton;
- unknown code in known code system;
- code-system mismatch;
- multiple application identifiers;
- lifecycle references across two submission units;
- access denied/unavailable;
- directory/ZIP equivalent forms;
- conflicting index.xml and submissionunit.xml physical markers;
- mixed v3 and v4 repository;
- two independent v4 applications in one repository.

For each proposed fixture record:

- source basis;
- whether XML is copied from an official example, minimally derived, or wholly
  synthetic;
- transformations performed and why they preserve structure;
- exact expected inventory facts;
- exact expected coverage facts;
- facts intentionally left unknown;
- expected CEC record count/type only when justified;
- fixture immutability and checksum plan.

Do not rename a v3 XML file and call it v4. Do not invent an official-looking
OID, code, namespace, or regulatory relationship.

## Deliverables

Claude may create or update only:

- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/reports/CLAUDE.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/STATUS.md

The report must include:

1. executive recommendation;
2. source basis and precedence;
3. official source ledger;
4. version/profile compatibility matrix;
5. exact XML structure map;
6. factual extraction candidate matrix;
7. lifecycle/application/submission-unit terminology model;
8. failure/status matrix;
9. architecture option matrix;
10. recommended SubmissionUnitXmlInventory object shape;
11. ScannerObservations impact;
12. BXI impact;
13. CEC evidence and coverage proposal;
14. T4/projection deferral decision;
15. fixture/test plan;
16. exact later implementation file allowlist proposal;
17. risks, source conflicts, and open decisions.

## Allowed files

For the Claude design worker:

- this task's reports/CLAUDE.md;
- this task's STATUS.md, limited to worker/report/PR status and exact SHA.

Scratch files may be used outside the repository and must not be committed.

## Forbidden files

Claude must not modify:

- TASK.md, SOURCES.md, or CLAUDE_LAUNCH.md;
- docs/internal/agent-workflow/**;
- any other task directory or agent report;
- engine/**;
- scripts/**;
- tests/**;
- test fixtures, manifests, or expectations;
- config/** or schemas;
- IdentificationInterpretation, CEC-FIELD-PROJECTION, rule packs, or oracle;
- workbook/VBA/reporting/UI/release/package files;
- demo artifacts or generated output.

No production implementation, dependency installation, live regulator
submission, cloud upload of internal data, or merge is authorized.

## Acceptance criteria

Ready for fixed-SHA central review only when:

1. the report is based on the authoritative base SHA;
2. every normative XML field/path/cardinality is traceable to an official
   source;
3. current, historical, draft, and unsupported profiles are separated;
4. root/namespace, implementation-guide markers, OIDs, identifierName values,
   code systems, and code/display components are treated distinctly;
5. factual collection is explicitly separated from regulatory interpretation;
6. application, submission, submission-unit, sequence, dossier, and lifecycle
   concepts are not conflated;
7. failure and coverage semantics distinguish absence, unavailability, parse
   failure, unsupported profile, invalid value, and ambiguity;
8. one bounded SubmissionUnitXmlInventory architecture is recommended;
9. ScannerObservations/1.0 compatibility or a required version change is
   justified field by field;
10. BXI and CEC impacts are explicit and historical shape/IDs are protected;
11. T4 and projection changes are either clearly deferred or isolated as a
    separate prerequisite with proof;
12. future fixtures use official examples or source-traceable minimal
    derivations and do not invent regulatory semantics;
13. exact future implementation/test files are proposed but not modified;
14. only the two allowed task-owned files change on the worker branch;
15. the report records source conflicts and unresolved decisions without
    resolving them by assumption.

## Decision gates

1. Claude publishes the design report in a draft PR to the coordination branch.
2. ChatGPT performs a fixed-SHA central review.
3. The user accepts, rejects, or requests amendments to the design.
4. Only after explicit user acceptance may a separate Codex implementation task
   be created.
5. No T2 design or implementation PR may be merged without a new user decision.
