# Contributing to eMAS

## Governing sources

Before changing eMAS, read:

1. [Authority and Precedence Policy](docs/governance/00_authority_and_precedence.md);
2. [Document Governance and Change Control](docs/governance/eMAS_Document_Governance.md);
3. [Canonical Document Index](docs/CANONICAL_DOCUMENT_INDEX.md);
4. [Controlled Terminology](docs/governance/eMAS_Terminology.md);
5. the applicable requirement, DecisionId, schema, architecture and test contract.

A lower-authority file, example, generated assistant profile or code comment must not override an approved governing source.

## Branching

Create a dedicated branch from the latest `main`.

Recommended prefixes:

- `feature/`;
- `fix/`;
- `docs/`;
- `governance/`;
- `config/`;
- `test/`;
- `release/`.

Do not commit directly to `main`.

## Pull requests

Every pull request must identify:

- affected eMAS phase or shared component;
- applicable DecisionIds and decision-register Item IDs;
- applicable requirement IDs;
- affected rule, configuration, schema or template versions;
- change class and required approver roles;
- tests performed and evidence produced;
- known limitations or linked follow-up work;
- documentation, compatibility and supersession impact.

Use the repository pull-request template and keep the change focused.

Approval of a design decision does not mean implementation, synchronization, testing or release is complete. State the actual delivery state precisely.

## Required review by change class

| Change class | Minimum approval evidence |
|---|---|
| Product scope or phase outcome | Product Owner |
| Regulatory content | Regulatory SME and Product Owner |
| Effort, confidence or threshold logic | Migration SME and Product Owner |
| Runtime JSON Schema | Technical Architect, PowerShell Lead and Product Owner |
| Shared engine code | PowerShell Lead and technical reviewer |
| XLSM/VBA | Technical Architect; Corporate IT for signing/trust controls |
| Templates or controlled report wording | Product Owner and QA Lead |
| Tests or release evidence | QA Lead and responsible technical owner |
| Documentation-only clarification | Documentation Owner and area owner |

CODEOWNERS routes repository review. When a required domain approver is not represented by a GitHub account, record the role, approval evidence and DecisionId in the pull request.

## Conflict and stop rule

Do not silently merge conflicting requirements.

Stop and record a `ConflictId` when a conflict affects:

- regulatory interpretation;
- JSON compatibility;
- phase decision logic;
- report meaning;
- evidence traceability.

Apply the higher-authority approved source only when its status and authority are clear. Flag the lower-authority artifact for correction or supersession.

## Architecture constraints

Contributions must preserve these decisions:

- the reviewed internal XLSM is the authoring source of truth;
- the workbook validates and exports one immutable runtime JSON directly;
- the exact JSON version and checksum loaded for a run is the execution source;
- PowerShell does not read the workbook or create, repair or reinterpret the JSON;
- all three phases use the same runtime JSON;
- shared technical processing belongs in `engine/`;
- entry scripts contain phase orchestration only;
- WPF is optional and limited to Pre-Migration Readiness and Post-Migration Verification;
- source processing remains read-only;
- each phase uses a separate controlled report template;
- evaluation status remains separate from RAG;
- findings remain separate from recommendations;
- accepted exceptions never erase observed findings.

## Configuration and workbook changes

Binary XLSM changes must include:

- exported `.bas`, `.cls` and `.frm` source where applicable;
- configuration version and schema version impact;
- validation results;
- JSON export evidence;
- affected RuleIds and relationship tables;
- reviewer rationale and required SME evidence.

Do not manually edit controlled runtime JSON.

Examples and fixtures must be labelled `Illustrative`, `Golden Fixture` or `Deprecated`.

## Documentation changes

Canonical documents must contain required control metadata, including version, status, owner, decision references, canonical references and revision history.

When a document is superseded:

- identify the successor;
- update the canonical index;
- update the superseded-document register;
- ensure active links and traceability are not orphaned;
- preserve controlled historical evidence.

Generated assistant summaries are non-authoritative and must identify their source documents and synchronization date.

## Testing

Add or update the smallest appropriate set of tests:

- unit;
- integration;
- scenario;
- regression;
- performance;
- JSON/schema validation;
- report-template validation;
- compatibility and release verification where applicable.

Test fixtures must be synthetic or explicitly approved for repository use. A fixture is authoritative only when labelled and approved as a Golden Fixture for identified test IDs and schema version.

## Repository safety

Never commit customer data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions, confidential internal workbooks or uncontrolled generated packages.
