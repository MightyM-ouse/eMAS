# EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN

**Task ID:** `EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN`  
**Roadmap ID:** T1b  
**Authoritative base commit:** `5d2ab2d1337f3a93a30f999fed3a9e9436724d1a`  
**Base branch:** `demo/end-to-end-mvp`  
**Execution model:** Single worker (Claude) → ChatGPT central review → user decision  
**Task type:** Regulatory evidence design / source-backed inventory only  
**Implementation:** NOT authorized in this task  
**Windows:** Deferred

## Purpose

Define the smallest source-backed regional XML evidence model needed for MS-04 Pre-Sales IdentificationInterpretation, starting with **EU eCTD Module 1 structured XML evidence**.

This task answers:

1. which factual regional XML values eMAS can safely collect;
2. where those values are located in official regional XML structures;
3. which component should parse them;
4. how those values should enter `ScannerObservations/1.0` / Classification Evidence Collection without interpretation;
5. what raw evidence strength/source tier is justified;
6. which Identification dimensions may consume the evidence later.

This task does **not** implement XML parsing and does **not** create Effective regulatory Identification rules.

## Why EU first

The first executable T1b wave is intentionally EU-focused because:

- the accepted sample baseline contains EU regional XML across historical DTD generations;
- T3c explicitly identified typed EU envelope fields as desirable future evidence;
- T4 now provides the governed IdentificationInterpretation engine that can consume stronger structured evidence later;
- a narrow EU-first design is safer than inventing one generic regional parser for incompatible regional Module 1 implementations.

The report shall define an extension pattern for later US/FDA, Canada, UK, Switzerland, GCC and other approved regional implementations, but shall not author normative field mappings for those regions unless official source evidence is fully reviewed and clearly separated as future work.

## Governing repository sources

Read and follow, in precedence order:

1. `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md`
2. `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`
3. `docs/configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md`
4. `docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md`
5. `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
6. current Runtime JSON / schema / data dictionary / relationship model
7. accepted T1a CEC design, report and review
8. accepted T3/T3a/T3b reports and reviews
9. accepted T4a behavior contract and T4b engine review
10. current `BackboneXmlInventory` and `ClassificationEvidenceCollection`
11. current EU-containing frozen fixtures / sample packages and their existing scanner observations
12. `docs/llm-development-context/ectd-regulatory-expert.md`

Earlier guides/mapping artifacts are supporting design input only unless another canonical source explicitly promotes them.

## Regulatory source discipline

For every proposed normative EU XML field, use an **official regulatory source**.

Prefer current official EU/EMA/eSubmission specification material, including the applicable EU eCTD Module 1 specification/implementation guide, DTD/schema package documentation, official controlled vocabulary documentation, and official validation criteria where relevant.

For historical DTD variants present in the accepted sample, use the corresponding historical official specification/package where available.

For every field record:

- issuing authority;
- document/package title;
- version/date;
- exact section/page or DTD/schema declaration;
- XML element/attribute name;
- path/parent context;
- cardinality where stated;
- data type / controlled vocabulary where stated;
- version applicability;
- whether the statement is an authoritative regulatory fact or an eMAS design decision.

Do not use blogs, vendor pages or memory as normative authority.

If an official source cannot be obtained or is ambiguous, mark the field `UNVERIFIED / DO_NOT_IMPLEMENT`.

## First required action — current evidence inventory

Before proposing new evidence, document what the current accepted scanner already emits.

At minimum inspect:

- `RepositoryDiscovery`;
- `BackboneXmlInventory`;
- `ClassificationEvidenceCollection`;
- current `ScannerObservations/1.0` shape;
- accepted T1a physical-marker evidence;
- accepted T4 `CEC-FIELD-PROJECTION/1`.

Create a table separating:

- factual evidence already available;
- data already parsed upstream but not projected to CEC;
- data present in regional XML but not currently parsed;
- data that cannot be safely collected without a new capability.

Do not describe a field as "available" merely because it exists in the source XML.

## Fact / interpretation boundary

T1b remains factual evidence collection.

No proposed scanner/CEC evidence record may itself assert:

- Region = EU;
- RegionalImplementation = EU_Module1;
- ProcedureContext = ASMF/MAA/CTA;
- LifecycleContext;
- TechnicalStandard;
- confidence;
- RAG;
- readiness;
- regulatory validity.

Those are later Interpretation outcomes.

For every future CEC record preserve:

- `CandidateValue = null`;
- `Polarity = null`;
- `SourceRuleId = null`.

The raw evidence value must describe what the XML actually says.

## Raw strength vocabulary

The existing CEC raw vocabulary remains:

- `Strong`
- `Supporting`
- `Weak`

Do not replace `Supporting` with `Medium`.

T4 normalizes only at the interpretation boundary:

`Strong → STRONG`  
`Supporting → MEDIUM`  
`Weak → WEAK`

For each proposed regional XML evidence type, recommend a raw CEC strength and justify it.

Do not assume every structured XML value is automatically Strong. Distinguish:

- direct typed controlled regulatory value;
- version/profile metadata;
- descriptive free text;
- inferred relationship;
- merely physical/path context.

## EU first-wave evidence inventory

Evaluate official EU Module 1 XML for factual fields that may support later Identification dimensions.

At minimum investigate whether the official XML provides reliable typed evidence for:

### A. Regional implementation/profile

- regional XML root element;
- namespace, DTD/schema identifiers;
- regional DTD/specification version;
- envelope/package version identifiers where defined.

### B. Authority / destination

- destination authority or agency identifiers;
- country/member-state destination fields;
- any controlled authority code actually carried in the XML.

Do not infer Region from authority in T1b. Record only the typed authority/destination fact.

### C. Procedure/application context

Investigate typed XML fields for:

- submission type;
- submission mode/procedure type;
- application/procedure number or identifier;
- ASMF-related context where structurally explicit;
- any application type/context relevant to MAA/CTA or lifecycle interpretation.

Do not flatten these into a new "DossierType" field.

### D. Lifecycle/submission metadata

Investigate typed fields such as:

- sequence/submission identifiers;
- related sequence/lifecycle references;
- submission description/title only where useful as factual metadata;
- operation/event values where explicitly encoded.

Free-text description/title must not become strong classification evidence.

### E. Product domain/context

Only include product-domain or product-class fields if the EU XML explicitly carries a governed typed value and the project model already has an appropriate canonical dimension.

Do not infer medicinal-product type from names or free text.

## Historical EU versions

The accepted baseline contains historical EU regional XML generations.

The design must explicitly assess compatibility across the versions observed in the repository, including the known historical DTD generations already seen in the baseline.

For every proposed field classify it as:

- stable across versions;
- renamed/moved across versions;
- value vocabulary changed;
- optional in older versions;
- unavailable in specific versions.

Do not design only for the newest EU specification if that would make existing historical dossiers unassessable.

## XML path representation

For every proposed field define a machine-readable selector shape suitable for a future bounded parser.

At minimum specify:

- XML document kind;
- root/namespace or DTD profile prerequisite;
- element path;
- attribute name if applicable;
- expected cardinality;
- value type;
- whitespace/case normalization allowed;
- controlled vocabulary handling;
- version applicability;
- missing/parse-failed behavior.

Do not invent XPath expressions that depend on arbitrary namespace prefixes.

Prefer namespace-URI + local-name semantics where practical.

## Architecture decision required

Recommend one bounded architecture:

### Option A — extend BackboneXmlInventory

Add typed regional fields to the existing BackboneXmlInventory result, then let CEC emit factual evidence from them.

### Option B — new RegionalXmlInventory capability

Create a separate factual parser capability between BackboneXmlInventory and CEC.

### Option C — another bounded architecture

Evaluate each against:

- no duplicate XML parsing;
- ScannerObservations contract stability;
- CEC fact-only boundary;
- testability;
- historical EU versions;
- future FDA/Canada/UK/Swiss/GCC extension;
- Windows PowerShell 5.1 compatibility;
- minimal impact on the accepted T4 short pipeline.

A key constraint: **CEC must not reopen the source XML**.

## ScannerObservations contract impact

Determine whether the new factual XML inventory can fit additively within `eMAS.MS04.PreSales.ScannerObservations/1.0` or requires a new scanner contract version.

Do not change the contract in this task.

Recommend the smallest safe shape.

If additive fields are proposed, define exact ownership and subject identity:

- Dossier;
- Sequence;
- XmlDocument;
- another existing subject type.

Avoid creating application identity semantics that RepositoryDiscovery does not actually know.

## CEC evidence design

For every proposed first-wave field define:

- EvidenceType;
- subject scope;
- SourceTier;
- raw Strength;
- SourceField;
- ObservedValue representation;
- EvidenceId determinism inputs;
- collection status / unavailable semantics;
- whether explicit assessed absence is meaningful;
- whether multiple values are legitimate or ambiguous;
- which canonical Identification dimension(s) may later consume it.

Do not create interpretation rules in this task.

## Missing / parse-failed / inaccessible semantics

Preserve the distinctions:

- field absent in a successfully parsed XML document;
- XML document not present;
- XML parse failed;
- source inaccessible;
- field not supported by this historical profile;
- value present but unknown to current controlled vocabulary;
- multiple conflicting values.

Do not turn any of these into a guessed value.

The report must recommend exact future collection-status/reason semantics using existing vocabularies where possible.

## Evidence-to-identification applicability matrix

Create a non-executable matrix showing which factual evidence types may later support:

- Region;
- Authority;
- RegionalImplementation;
- TechnicalStandard;
- ProcedureContext;
- LifecycleContext;
- ProductDomain;
- ProductClass.

This matrix is design guidance only.

Do not resolve T3c U2–U9 by implication.

In particular:

- Region remains distinct from RegionalImplementation;
- relationship-derived Region remains deferred;
- ASMF/DMF are not TechnicalStandard values;
- physical v4 evidence remains unrelated to this EU-v3 regional XML task.

## Fixture and test strategy

Design the future T1b implementation tests.

At minimum include cases for:

1. clean EU regional XML with a typed field;
2. older EU DTD/profile carrying the equivalent field in an older location;
3. optional field absent but XML parse successful;
4. malformed regional XML;
5. regional XML file missing;
6. unrecognized/unsupported historical profile;
7. unknown controlled value;
8. duplicate/multiple values where cardinality expects one;
9. conflicting typed values across lifecycle units;
10. XML namespace prefix changes with same namespace URI;
11. free-text field must not become Strong identification evidence;
12. CEC candidate/polarity/source-rule fields remain null;
13. deterministic EvidenceIds and ordering;
14. no source XML reopening in CEC;
15. current T4 short pipeline remains valid.

Prefer existing frozen fixtures where they already contain suitable official XML examples.

Do not modify frozen fixture bytes in the design task.

## Required deliverable

Create only:

`docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/reports/CLAUDE.md`

The report must contain:

1. executive recommendation;
2. authoritative source ledger;
3. current evidence inventory;
4. EU XML profile/version inventory observed in repository;
5. proposed first-wave typed field catalogue;
6. exact XML selector/path matrix;
7. historical-version compatibility matrix;
8. architecture decision;
9. proposed ScannerObservations additive shape/version impact;
10. CEC evidence-type catalogue with strength/source-tier rationale;
11. missing/error/ambiguity semantics;
12. evidence-to-identification applicability matrix;
13. future fixture/test matrix;
14. implementation file impact;
15. explicit non-goals;
16. open Regulatory SME/Product Owner decisions;
17. recommended bounded T1b implementation task.

## Allowed files

Create/update only this task's own files:

- `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/**`

No production implementation is authorized.

## Forbidden changes

Do not modify:

- RepositoryDiscovery;
- BackboneXmlInventory;
- CEC;
- IdentificationInterpretation;
- runtime JSON/schema;
- workbook/VBA;
- scanner contracts;
- fixtures;
- tests;
- T4 oracle;
- prior mapping artifacts.

Do not create Effective regulatory rules.

## Git workflow

Use branch:

`analysis/emas-ms04-regional-xml-evidence-t1b-design`

Open a **draft PR into**:

`coordination/emas-ms04-regional-xml-evidence-t1b-design`

Do not merge.

## Acceptance criteria

Ready for ChatGPT review only when:

1. every proposed normative XML field is backed by an official source;
2. current scanner evidence and future evidence are clearly separated;
3. fact and interpretation remain separate;
4. historical EU profile compatibility is explicit;
5. CEC does not reopen XML;
6. no T3c open policy is silently resolved;
7. raw CEC Strength remains Strong/Supporting/Weak;
8. missing, unsupported, malformed and ambiguous states remain distinct;
9. one clear parsing architecture is recommended;
10. implementation scope is small enough for one bounded follow-up task.
