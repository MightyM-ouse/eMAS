# eMAS September 2026 Design Delta

**Purpose:** Record material changes from the repository's July 2026 baseline to the design discussed and documented during 3–12 September 2026.  
**Status:** Consolidated working design delta for review. This is not a validation record or released runtime configuration.

## 1. Architecture change: XLSM/VBA is no longer the target

The July repository presents an internal XLSM that validates and directly exports runtime JSON through VBA. September requirements replace that route with a macro-free Microsoft 365 authoring and release architecture.

### Current target

```text
Regulatory / migration knowledge
        ↓
Internal Mapping Workbook (.xlsx)
        ↓
Explicit Excel-to-JSON mapping
        ↓
Office Scripts / TypeScript
  - read named Excel Tables
  - normalize and validate
  - create complete JSON object
        ↓
Power Automate
  - capture controlled workbook snapshot
  - create frozen candidate
  - coordinate independent review/approval
  - publish unchanged candidate as release
  - preserve release evidence
        ↓
Released Runtime JSON + trusted release evidence
        ↓
Offline PowerShell assessment runtime
        ↓
Pre-Sales | Pre-Migration | Post-Migration
```

Runtime PowerShell does not open, interpret or convert the Mapping Workbook. Excel, SharePoint, Office Scripts and Power Automate are internal authoring/release dependencies only and do not cross into normal customer/project runtime.

## 2. JSON-first contract and release integrity

The Runtime JSON Schema is defined independently of physical workbook layout. Workbook columns are explicitly mapped to the contract. Candidate generation must be deterministic and controlled; production JSON is generated as a complete configuration rather than patched incrementally.

Material execution evidence should identify, as applicable:

- configuration / mapping version;
- schema version;
- release ID;
- exact Runtime JSON SHA-256;
- script version;
- template version;
- execution ID and timestamp;
- source evidence and RuleIds.

A release manifest/evidence record carries governance metadata and the trusted expected digest. It is not a second business-rule configuration.

## 3. Phase boundaries remain explicit

### Pre-Sales Assessment

Purpose: lightweight scoping, sizing, complexity, confidence and customer clarification. It should remain easy for a customer to run and should not require Excel, a central service or editing JSON. Deep checksum/reference validation, approved-exception management, readiness decisions and post-import reconciliation are not mandatory pre-sales activities.

### Pre-Migration Readiness

Purpose: determine whether the agreed migration scope and source data are sufficiently understood and prepared. Deeper checks can include access, folder/file expectations, XML readability, references, integrity, unsupported structures, backup/staging/transfer readiness and remediation ownership. CLI is supported; portable WPF is optional.

### Post-Migration Verification

Purpose: reconcile the approved baseline with import evidence and post-import evidence. The assessment is multi-level: dossier, sequence/submission, document, metadata, integrity and exception reconciliation. It must preserve unresolved discrepancies and accepted exceptions without claiming formal customer validation or business acceptance.

## 4. Integrated workbook model

The September integrated workbook prototype extends simple rule authoring with project-assessment layers while preserving an important boundary: customer/project assessment data must not become Runtime JSON.

Key assessment areas include:

- Project Assessment / pre-sales questionnaire;
- Dossier Assessment — one row per logical dossier/application lifecycle;
- Sequence Assessment — one row per unique sequence/submission;
- Evidence Log — reproducible observed/calculated/customer-provided evidence;
- classification, folder, file, RAG, confidence, effort, decision and recommendation rules;
- validation results and JSON preview.

A `DataScope` concept separates runtime configuration from assessment input/derived evidence. Validation must block any attempt to export customer/project assessment rows into Runtime JSON.

## 5. Filterable dossier and sequence condition catalogue

The filterable September reference contains 3,726 condition rows across 55 profiles, with traceable sources and open/pending items. It is designed so a reviewer can filter by:

`Region → Format → Format Version → Application / Dossier Type`

and receive the applicable assessment conditions across phases.

Important condition dimensions include:

- scope and source access;
- evidence provenance;
- dossier/application identity;
- sequence/submission identity;
- independent Region / Format / Dossier Type classification;
- regional/profile version;
- folder and file structure;
- XML readability;
- referenced-file resolution;
- lifecycle relationships;
- checksum/integrity assessment;
- pre-sales confidence/depth;
- readiness disposition;
- post-migration reconciliation and import-result disposition.

Condition records should preserve their RuleId / row identity, requirement level, trigger, evidence location, operator/expected value, positive/negative/missing-evidence behavior, customer question, source reference and review status.

## 6. Regulatory model is multi-dimensional

The September regulatory guide establishes a critical design rule: do not collapse region, transport format, regulatory pathway/dossier type and lifecycle purpose into one value.

Examples:

- **Region/authority:** EU/EMA or NCA, US/FDA, Canada/Health Canada, etc.
- **Technical format:** eCTD v3.2.2, eCTD v4.0, NeeS, legacy/non-eCTD.
- **Application/pathway:** MAA, NDA, ANDA, BLA, IND, CTA, etc.
- **Dossier/content type:** human medicinal product, ASMF, master file, investigational dossier, etc.
- **Lifecycle purpose:** initial, response, variation/supplement, renewal, update.

### ASMF rule

ASMF is a regulatory dossier/master-file concept, **not** a unique transport format. An ASMF can be supplied using eCTD. eMAS must therefore store and infer dossier type separately from technical format and region.

## 7. Evidence hierarchy for identification

Folder names are useful hints but should not be treated as authoritative on their own. Identification should preferentially use reproducible evidence such as:

1. backbone or submission-unit metadata;
2. regional XML and its exact elements/attributes;
3. regional Module 1 structure and authoritative identifiers;
4. regulatory documents/forms where applicable;
5. physical structure and sequence naming;
6. customer-confirmed metadata with provenance;
7. folder/product-name heuristics as weak supporting evidence only.

For important conclusions, preserve the chain:

`Physical file → XML section/path → element/attribute/value → interpretation → RuleId → finding → severity/confidence → migration action`

## 8. Regional and format coverage

The regulatory guide expands the assessment perspective beyond EU and FDA. It covers or discusses EU, US, Canada, UK, Switzerland, Australia, Japan and Singapore, together with non-eCTD/legacy contexts such as NeeS, ASMF/DMF and mixed or unknown structures.

The system must not assume that one region's Module 1 XML structure or metadata names apply to another region. Regional parsing is profile-specific and version-aware.

For classic eCTD v3.2.2, `index.xml` provides the ICH backbone while regional Module 1 XML provides region-specific administrative/regulatory metadata. For eCTD v4.0, do not use the v3 `index.xml/index-md5.txt` pattern as primary identification evidence; v4 uses its own submission-unit/RPS model.

## 9. Sequence and lifecycle assessment

Sequence discovery must distinguish physical package naming from regulatory continuity. A gap such as:

```text
0000
0001
0003
```

must be recorded and assessed against available lifecycle/inventory evidence; it must not automatically be treated as proof that `0002` is missing from the required migration scope. Possible explanations include selected exports, unavailable history or genuine omission. Confidence and readiness impact depend on evidence.

Lifecycle assessment should preserve document/reference operations and relationships where technically detectable. Missing earlier sequences may make some lifecycle relationships Not Assessed rather than falsely passing or failing them.

## 10. Technical completeness model

Technical completeness is an eMAS assessment concept, not a claim that the dossier passed an authority's complete official validation rule set.

A layered model is appropriate:

1. Detect — what evidence is present?
2. Identify — region, application/dossier, format/version, sequences.
3. Structural assessment — expected physical components.
4. Referential assessment — XML/document references resolve.
5. Integrity assessment — readability, checksum/hash where in scope, internal consistency.
6. Lifecycle assessment — sequence/document relationships are coherent where history is available.
7. Regulatory technical assessment — applicable source-backed technical expectations.
8. Migration readiness — can the agreed content be migrated reliably, with exceptions/actions recorded?

Each layer needs an explicit Not Assessed / Unknown path when evidence is unavailable.

## 11. Folder and packaging findings

The September work reinforces that folder handling cannot be reduced to “does m1–m5 exist?”. The assessment design must account for:

- export roots that are only containers, with actual dossier roots deeper in the tree;
- ZIP packages at unexpected levels;
- same-name nested folders;
- folder-within-folder packaging introduced by export/copy operations;
- unknown or additional product/container folders;
- invalid sequence-like names;
- empty folders/sequences where relevant to the phase;
- sequence gaps and duplicates;
- region/format-specific expected structures;
- non-eCTD structures such as NeeS/VNeeS/legacy packages.

Folder RAG and deeper content/readiness findings should remain distinguishable so that a folder-layout warning is not misrepresented as a regulatory invalidity.

## 12. Missing references and file integrity

Pre-migration depth may include:

- missing XML-referenced files;
- orphan/unreferenced files;
- malformed or unreadable XML;
- zero-byte/corrupt files;
- path/filename constraints;
- invalid or suspicious extensions / extension-to-content mismatch where detectable;
- unsupported document formats;
- checksums/hashes when the applicable format and assessment depth support them;
- duplicate-content indicators;
- unresolved lifecycle targets.

The finding must identify what was actually checked, what evidence was unavailable and whether a migration-oriented action is a regulatory mandate, eMAS rule or technical recommendation.

## 13. Archive/database evidence

Where eCTDmanager database/archive assessment is in scope, logical records can be correlated with physical archive content using stable identifiers/hashes/derived archive names according to the approved source-system model. The assessment should record presence, absence, duplicates and mismatches without modifying archive content. Proprietary SQL or implementation-specific commands are not part of the general requirements baseline unless separately controlled.

## 14. RAG and confidence are separate

Severity/RAG answers “how significant is the finding?” Confidence answers “how strong is the evidence?”. Do not use one as a proxy for the other.

Examples:

- Red / High confidence — confirmed missing required referenced file with reproducible XML evidence.
- Red / Low confidence — severe suspected condition but source history is incomplete.
- Amber / High confidence — confirmed review/remediation item that does not automatically block migration.
- Green / Low confidence should be avoided when required evidence is missing; use Unknown/Not Assessed instead.

## 15. Source and recommendation traceability

Every material maintained rule should be able to retain, as applicable:

- Rule ID and category;
- region / authority;
- format and version;
- dossier/application type;
- requirement/evidence source;
- source version/date;
- physical file/location;
- XML path / element / attribute;
- expected condition and detection logic;
- positive/negative evidence;
- severity/RAG impact;
- confidence impact;
- migration impact;
- recommendation/action;
- review/validation status;
- JSON field mapping.

A migration-oriented rule must not be presented as an EMA/FDA/ICH requirement unless the cited source actually establishes it.

## 16. Migration scenario coverage

The assessment strategy changes according to scenario and available evidence. Relevant dimensions include:

- existing vs new customer;
- on-premises to cloud vs on-premises to on-premises;
- source DB available/unavailable;
- archive/index available/unavailable;
- system export available;
- eSUBmanager usage where relevant;
- DMS integration;
- direct archive/storage migration;
- regulatory dossier export migration;
- incomplete/unknown repository.

The questionnaire should derive a scenario where evidence is sufficient and generate follow-up questions where key data is missing.

## 17. Post-migration reconciliation depth

Reconciliation should be evidence-based at several levels rather than only comparing totals:

```text
Migration reconciliation
├── Dossier / application
├── Sequence / submission
├── Document
├── Metadata
├── Integrity
└── Accepted exception / discrepancy disposition
```

Potential comparison points include counts, identifiers, file/document identity, size, hashes where in scope, XML presence/references, metadata values, lifecycle relationships, orphan/missing items and import warnings/errors.

Baseline comparability matters: if the configuration/rule release differs between approved pre-migration baseline and post-migration interpretation, the change must be assessed and documented rather than silently comparing conclusions made under different rule sets.

## 18. GxP-oriented controls without overstatement

Because eMAS can support regulated migration evidence, the design should support traceability, reproducibility, evidence retention, auditability, rule/source/version control, execution evidence, exception management, attributable review and validation of automated rules. These controls do not automatically make eMAS validated or compliant. Formal validation requires an approved intended use, controlled requirements/design, risk assessment, test evidence, configuration/code control, review/approval and operational procedures appropriate to the organization's quality system.

## 19. Immediate repository implications

1. Treat the XLSM/VBA authoring route as historical POC, not current target architecture.
2. Preserve useful JSON schema/model/test ideas only where they remain compatible with the September contract.
3. Add Microsoft 365 authoring/release design before implementing new workbook-export code.
4. Expand regulatory rules beyond EU/FDA and keep region, format and dossier type separate.
5. Implement version/profile-aware XML extraction rather than global element assumptions.
6. Keep assessment input/derived evidence outside Runtime JSON.
7. Make RuleId/source/evidence/recommendation traceability first-class.
8. Preserve Unknown and Not Assessed as meaningful outcomes.
9. Separate lightweight pre-sales checks from deeper readiness checks.
10. Design post-migration around an approved baseline and multi-level reconciliation.

## 20. Items still requiring controlled decisions

The September artifacts contain draft/proposed content as well as reviewed regulatory guidance. Before production implementation or release, resolve at least:

- the exact companion version naming between Enterprise Requirements v4.0 and Mapping/Runtime requirements;
- final workbook sheet/Table/column contract;
- final Runtime JSON schema version and compatibility policy;
- exact regulatory profiles/version ranges and XML extraction mappings;
- final RAG/readiness decision policy per phase;
- final Office Script and Power Automate release evidence contract;
- migration/archive source-system specifics that are not generic regulatory rules;
- validation strategy for the implemented end-to-end solution.
