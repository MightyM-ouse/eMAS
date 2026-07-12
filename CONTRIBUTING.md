# Contributing to eMAS

## Branching

Create a dedicated branch from the latest `main`.

Recommended prefixes:

- `feature/`
- `fix/`
- `docs/`
- `config/`
- `test/`
- `release/`

Do not commit directly to `main`.

## Pull requests

Every pull request should identify:

- affected eMAS phase or shared component;
- applicable requirement IDs;
- affected rule, configuration, schema or template versions;
- tests performed and evidence produced;
- known limitations or follow-up work.

Use the repository pull-request template and keep the change focused.

## Architecture constraints

Contributions must preserve these decisions:

- the internal XLSM workbook exports one runtime JSON directly;
- PowerShell does not read the workbook or create the JSON;
- all three phases use the same runtime JSON;
- shared technical processing belongs in `engine/`;
- entry scripts contain phase orchestration only;
- WPF is optional and limited to pre-migration and post-migration;
- source processing remains read-only;
- each phase uses a separate controlled report template.

## Configuration and workbook changes

Binary XLSM changes should include:

- exported `.bas`, `.cls` and `.frm` source where applicable;
- configuration version and schema version impact;
- validation results;
- JSON export evidence;
- affected RuleIds and relationship tables;
- reviewer rationale.

Do not manually edit controlled runtime JSON.

## Testing

Add or update the smallest appropriate set of tests:

- unit;
- integration;
- scenario;
- regression;
- performance;
- JSON/schema validation;
- report-template validation.

Test fixtures must be synthetic or explicitly approved for repository use.

## Repository safety

Never commit customer data, customer reports, migration evidence, credentials, production logs, project-specific accepted exceptions or uncontrolled generated packages.
