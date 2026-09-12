# eMAS September 2026 Design Delta

**Purpose:** Record material changes from the July 2026 repository baseline to the design discussed and documented during 3–12 September 2026.  
**Status:** Consolidated working design delta for review. This is not a validation record or released runtime configuration.

## 1. Architecture change

The July repository presents an internal XLSM that validates and directly exports runtime JSON through VBA. September requirements replace that route with a macro-free Microsoft 365 authoring and release architecture:

```text
Regulatory / migration knowledge
        ↓
Internal Mapping Workbook (.xlsx)
        ↓
Explicit Excel-to-JSON mapping
        ↓
Office Scripts / TypeScript
        ↓
Power Automate candidate / approval / release
        ↓
Released Runtime JSON + trusted release evidence
        ↓
Offline PowerShell assessment runtime
        ↓
Pre-Sales | Pre-Migration | Post-Migration
```

Runtime PowerShell does not open, interpret or convert the Mapping Workbook. Excel, SharePoint, Office Scripts and Power Automate are internal authoring/release dependencies only.

## 2. JSON-first contract and release integrity

The Runtime JSON Schema is defined independently of physical workbook layout. Workbook columns are explicitly mapped to the contract. Production JSON is generated as a complete configuration rather than patched incrementally.

Execution evidence should identify configuration/mapping version, schema version, release ID, Runtime JSON SHA-256, script version, template version, execution ID/timestamp, source evidence and RuleIds.

## 3. Phase boundaries

### Pre-Sales Assessment
Lightweight scoping, sizing, complexity, confidence and customer clarification. Deep checksum/reference validation, approved-exception management, readiness decisions and post-import reconciliation are not mandatory pre-sales activities.

### Pre-Migration Readiness
Deeper checks can include access, folder/file expectations, XML readability, references, integrity, unsupported structures, backup/staging/transfer readiness and remediation ownership. Produces the expected migration baseline.

### Post-Migration Verification
Reconciles the approved baseline with import and post-import evidence at dossier, sequence/submission, document, metadata, integrity and exception levels. It must not claim formal customer validation or business acceptance.

## 4. Integrated workbook model

The integrated workbook adds project-assessment layers while preserving the runtime boundary. Key assessment areas include Project Assessment / questionnaire, Dossier Assessment, Sequence Assessment, Evidence Log, classification/folder/file rules, RAG/confidence/effort/decision/recommendation rules, validation results and JSON preview.

`DataScope` separates `RuntimeConfiguration`, `AssessmentInput`, and `AssessmentDerived`. Validation must block customer/project assessment rows from Runtime JSON.

## 5. Filterable dossier and sequence condition catalogue

The September reference contains 3,726 condition rows across 55 profiles. Reviewers filter by:

`Region → Format → Format Version → Application / Dossier Type`

Applicable condition dimensions include scope/access, provenance, dossier identity, sequence identity, region/format/type classification, regional/profile version, folder/file structure, XML readability, referenced-file resolution, lifecycle relationships, checksum/integrity, confidence/depth, readiness and post-migration reconciliation.

## 6. Regulatory model is multi-dimensional

Do not collapse region, technical format, pathway/dossier type and lifecycle purpose into one value.

- Region/authority: EU/EMA or NCA, US/FDA, Canada/Health Canada, etc.
- Technical format: eCTD v3.2.2, eCTD v4.0, NeeS, legacy/non-eCTD.
- Application/pathway: MAA, NDA, ANDA, BLA, IND, CTA, etc.
- Dossier/content type: human medicinal product, ASMF, master file, investigational dossier, etc.
- Lifecycle purpose: initial, response, variation/supplement, renewal, update.

ASMF is a regulatory dossier/master-file concept, not a unique transport format. An ASMF can be supplied using eCTD.

## 7. Evidence hierarchy

Prefer reproducible evidence in this order where applicable: backbone/submission-unit metadata; regional XML exact elements/attributes; regional Module 1 structure and identifiers; regulatory documents/forms; physical structure/sequence naming; customer-confirmed metadata with provenance; folder/product heuristics only as weak supporting evidence.

For important conclusions preserve:

`Physical file → XML section/path → element/attribute/value → interpretation → RuleId → finding → severity/confidence → migration action`

## 8. Regional and format coverage

Assessment must extend beyond EU/FDA and can include Canada, UK, Switzerland, Australia, Japan and Singapore plus non-eCTD/legacy contexts such as NeeS, ASMF/DMF and mixed/unknown structures. Do not assume one region's Module 1 XML names apply elsewhere.

Classic eCTD v3.2.2 uses `index.xml` as ICH backbone plus regional Module 1 XML. eCTD v4 must use a version-appropriate RPS/submission-unit evidence model and not be primarily detected by v3 `index.xml/index-md5.txt` patterns.

## 9. Sequence and lifecycle assessment

A gap such as `0000`, `0001`, `0003` is a finding, not automatic proof that `0002` must be in the migration scope. Possible explanations include selected exports, unavailable history or genuine omission. Confidence/readiness impact depends on supporting evidence.

Lifecycle assessment should preserve detectable reference operations/relationships. Missing history can make some relationships Not Assessed.

## 10. Technical completeness model

Technical completeness is an eMAS assessment concept, not a claim of passing an authority's complete validation-rule set.

1. Detect evidence.
2. Identify region/application/format/version/sequences.
3. Structural assessment.
4. Referential assessment.
5. Integrity assessment.
6. Lifecycle assessment.
7. Source-backed regulatory technical assessment.
8. Migration readiness and remediation/exception handling.

Each layer requires explicit Unknown/Not Assessed behavior when evidence is unavailable.

## 11. Folder and packaging findings

Assessment should account for export roots that are only containers, ZIP packages at unexpected levels, same-name nested folders, folder-within-folder packaging, additional product/container folders, invalid sequence-like names, empty folders/sequences, sequence gaps/duplicates, region-specific expected structures and non-eCTD structures.

Folder RAG and deeper regulatory/readiness findings should remain distinguishable.

## 12. Missing references and file integrity

Pre-migration checks may include missing XML-referenced files, orphan files, malformed/unreadable XML, zero-byte/corrupt files, path/filename constraints, suspicious extensions/content mismatch, unsupported formats, checksums/hashes where applicable, duplicate-content indicators and unresolved lifecycle targets.

Each finding should state what was checked, what evidence was unavailable, and whether the action is a regulatory mandate, eMAS rule or technical recommendation.

## 13. Archive/database evidence

Where eCTDmanager database/archive assessment is in scope, logical records can be correlated with physical archive content using stable identifiers/hashes/derived archive names according to the approved source-system model. Record presence, absence, duplicates and mismatches without modifying archive content.

## 14. RAG and confidence are separate

Severity/RAG answers how significant a finding is. Confidence answers how strong the evidence is. Missing evidence must not become Green. Low confidence does not automatically lower severity.

## 15. Source and recommendation traceability

Every material rule should retain, as applicable: RuleId/category, region/authority, format/version, dossier/application type, source/version, physical location, XML path/element/attribute, expected condition/detection logic, positive/negative evidence, severity/RAG impact, confidence impact, migration impact, recommendation/action, review status and JSON mapping.

## 16. Migration scenario coverage

Relevant dimensions include existing/new customer, on-prem→cloud/on-prem→on-prem, DB availability, archive/index availability, system export availability, eSUBmanager usage, DMS integration, direct archive/storage migration, regulatory dossier export migration and incomplete/unknown repositories.

The questionnaire should derive a scenario when evidence is sufficient and generate follow-up questions when key data is missing.

## 17. Post-migration reconciliation depth

Reconciliation should cover:

```text
Migration reconciliation
├── Dossier / application
├── Sequence / submission
├── Document
├── Metadata
├── Integrity
└── Accepted exception / discrepancy disposition
```

Comparison points can include counts, identifiers, file/document identity, size, hashes where in scope, XML presence/references, metadata, lifecycle relationships, orphan/missing items and import warnings/errors.

## 18. GxP-oriented controls without overstatement

Support traceability, reproducibility, evidence retention, auditability, rule/source/version control, execution evidence, exception management, attributable review and validation of automated rules. These controls do not by themselves make eMAS validated or compliant.

## 19. Immediate repository implications

1. Treat XLSM/VBA authoring as historical POC, not current target architecture.
2. Preserve useful JSON/schema/test concepts only where compatible with the September contract.
3. Add Microsoft 365 authoring/release design before new workbook-export implementation.
4. Expand regulatory rules beyond EU/FDA and keep region, format and dossier type separate.
5. Implement version/profile-aware XML extraction.
6. Keep assessment input/derived evidence outside Runtime JSON.
7. Make RuleId/source/evidence/recommendation traceability first-class.
8. Preserve Unknown and Not Assessed as meaningful outcomes.
9. Separate lightweight pre-sales checks from deeper readiness checks.
10. Design post-migration around an approved baseline and multi-level reconciliation.

## 20. Controlled decisions still required

- final companion version naming;
- final workbook sheet/Table/column contract;
- final Runtime JSON schema version/compatibility policy;
- exact regulatory profiles/version ranges/XML extraction mappings;
- final RAG/readiness decision policy per phase;
- final Office Script/Power Automate release-evidence contract;
- source-system-specific archive/database rules;
- end-to-end validation strategy.
