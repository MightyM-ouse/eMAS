# Security and Confidentiality

## Supported status

eMAS is currently under design and implementation. No controlled software release is declared by this repository unless a versioned release record states otherwise.

## Reporting a security concern

Do not disclose credentials, customer data, confidential configuration or exploitable details in a public issue.

Report the concern through the approved internal EXTEDO security or project-management channel and include:

- affected component and version;
- reproduction conditions;
- impact;
- supporting evidence with sensitive values removed;
- suggested containment where known.

## Repository data restrictions

The repository must not contain:

- customer source data or dossier exports;
- customer reports or migration evidence;
- production execution logs;
- credentials, tokens or connection strings;
- project-specific accepted exceptions;
- confidential customer paths or identifiers;
- uncontrolled release packages.

## Internal configuration assets

The production mapping workbook, reviewed runtime JSON, official internal templates, protected VBA and confidential branding assets may only be stored where repository access classification has been approved.

## Runtime security principles

- eMAS operates read-only against source evidence.
- It must not transmit customer data externally.
- It must not require internet access or a central service.
- It must use least privilege.
- Logs must not contain passwords or credentials.
- Outputs must be written only to the selected approved folder.
