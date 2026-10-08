# Authoritative Source Starter — T2 SubmissionUnit XML Inventory

This file is a routing index, not evidence that a version is current. Claude
must verify the live official landing page, applicable version, status, exact
section, and direct artifact before using any claim.

## Authority order

1. effective canonical eMAS requirements and approved repository decisions;
2. current official ICH eCTD v4 specification package;
3. current official regional implementation guides, controlled vocabularies,
   schemas, examples, and validation criteria;
4. accepted repository behavior as implementation evidence only;
5. secondary/vendor material for discovery only, never normative rules.

Conflicts follow docs/governance/00_authority_and_precedence.md and must be
recorded rather than silently reconciled.

## Canonical repository sources

Review at minimum:

- docs/CANONICAL_DOCUMENT_INDEX.md
- docs/governance/00_authority_and_precedence.md
- docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md
- docs/architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md
- docs/internal/agent-workflow/AGENT_WORKFLOW.md
- docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/CLAUDE.md
- docs/internal/agent-tasks/EMAS-MS04-IDENTIFICATION-RULES/reports/REVIEW.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-DESIGN/**
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION/**
- docs/internal/agent-tasks/EMAS-MS04-CEC-PHYSICAL-MARKER-EVIDENCE/**
- docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-DESIGN/**
- docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/**
- current RepositoryDiscovery, BXI, CEC, T4, and relevant test contracts.

Repository code and fixtures describe current behavior. They are not regulatory
authority.

## ICH official sources

### ICH eCTD v4 landing page

https://admin.ich.org/page/ich-electronic-common-technical-document-ectd-v40

Use it to locate and verify the current official package. The accepted
repository source ledger records ICH eCTD v4.0 Implementation Guide v1.7,
endorsed June 2026, but Claude must verify whether that remains current at
execution time.

Inspect all applicable official package artifacts, including:

- implementation guide;
- normative or published XML schemas;
- controlled vocabularies/code lists;
- validation criteria;
- support documentation;
- official examples or sample submissionunit.xml documents;
- change history and compatibility notes.

Required topics include message root and namespace, interaction/profile
identity, submission-unit structure, identifier semantics, sequence number,
application/submission concepts, lifecycle relationships, code systems,
cardinality, and conformance/failure rules.

## FDA official sources

### FDA eCTD v4 submission standards and Regional M1

https://www.fda.gov/drugs/electronic-regulatory-submission-and-review/ectd-submission-standards-ectd-v40-and-regional-m1

Use the current documents linked by FDA, including as applicable:

- FDA Regional eCTD v4.0 Module 1 Implementation Guide;
- FDA technical conformance guide;
- FDA validation criteria;
- FDA controlled vocabularies/code lists;
- FDA official examples or pilot material;
- implementation timelines and supported-version statements.

The accepted repository ledger records FDA Regional M1 v1.9 from August 2026.
That is a research lead, not permission to assume it remains current or final.

Verify which OIDs and code-system roots are stated directly, which are absent,
and which values apply to CDER, CBER, or another center. Do not infer an FDA
regional implementation-guide OID when the official text leaves it blank.

## EU / EMA official sources

### EU eCTD v4 project and document page

https://esubmission.ema.europa.eu/eCTD%20NMV/eCTD.html

Use the current official materials linked there, including as applicable:

- EU eCTD v4.0 Module 1 Implementation Guide;
- EU eCTD v4 practical guidance;
- EU validation criteria;
- EU controlled vocabularies/code lists;
- official examples;
- implementation roadmap, pilot, or support-status statements.

The accepted repository ledger records an EU Module 1 draft v1.2 from October
2024 and practical guidance v1.0 from December 2025. Claude must verify their
current status and any successor. Draft material must remain labelled draft.

Verify exact OID arcs and identifierName values against the current official
artifacts. Do not treat a sample header as a universal normative requirement
unless the specification says so.

## Additional official sources

Use another regulator's official v4 material only when needed to test the
ICH-versus-regional boundary. Record its authority and status. Do not broaden
the first implementation recommendation into a universal regional parser.

## Source capture rules

For every source used:

- record URL, title, version/date, status, access date, and exact section/page;
- prefer canonical landing pages plus direct artifact links;
- record artifact filename and checksum when downloaded;
- distinguish normative schema/code-list content from explanatory examples;
- do not commit copyrighted packages unless repository policy and licensing
  permit it;
- do not upload internal/confidential sample dossiers;
- quote only the minimum XML token or phrase needed for precision;
- preserve conflicts, gaps, and superseded versions in the ledger.

No official source or exact location means no normative extraction rule.
