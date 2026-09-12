# eMAS — September 2026 Consolidation

**Branch:** `update/2026-09-12-latest-emas`  
**Prepared:** 12 September 2026  
**Status:** Working consolidation for review; not a controlled production release

This folder records the material eMAS design and regulatory changes developed during 3–12 September 2026 that were not present in the repository's July 2026 baseline.

## Why this update exists

The repository previously reflected the July architecture and proof-of-concept, including an internal XLSM/VBA authoring route. September work materially revised the target architecture and greatly expanded the regulatory/migration assessment model.

The current direction is:

- macro-free internal Excel `.xlsx` authoring;
- SharePoint-controlled storage and version history;
- a JSON-first runtime contract independent of workbook presentation;
- explicit Excel-to-JSON field mapping;
- Office Scripts / TypeScript for validated workbook transformation;
- Power Automate for frozen candidate creation, independent approval, release and evidence;
- one immutable released Runtime JSON consumed by all three eMAS phases;
- offline PowerShell runtime that does **not** read or convert the Mapping Workbook;
- phase-specific reports and logs with release/configuration digest traceability;
- expanded dossier, sequence, evidence, technical-completeness and post-migration reconciliation concepts;
- explicit separation of regulatory requirement, eMAS interpretation, migration rule and recommendation.

## September source artifacts reviewed

| Artifact | Date | Role in this consolidation |
|---|---:|---|
| eMAS Enterprise Requirements Specification v4.0 | 06 Sep 2026 | Whole-system architecture and phase baseline |
| eMAS Mapping Workbook and Runtime JSON Requirements v4.0 | 06 Sep 2026 | Mapping/JSON/Microsoft 365 target architecture |
| eMAS Integrated Assessment Workbook v4.1 | 06 Sep 2026 | 24-tab integrated workbook prototype with DataScope separation |
| eMAS Filterable Dossier and Sequence Conditions v1.0 | 07 Sep 2026 | 3,726-condition, 55-profile assessment reference |
| eMAS Regulatory, Technical & Migration Assessment Guide v1.0 | 12 Sep 2026 | Consolidated regulatory and migration assessment guide; sources verified to 12 Sep 2026 |

## Repository treatment

The existing XLSM/VBA proof-of-concept remains useful historical implementation evidence. It is **not** the September target architecture. Files under `config/vba/`, the XLSM/VBA POC documentation and related tests should therefore be interpreted as superseded design-path evidence unless a later approved decision explicitly revives them.

The September materials do not by themselves prove validation, production release, regulatory compliance or customer acceptance. The regulatory guide also requires effective regulatory sources to be re-verified before a controlled release.

## Files in this update folder

- `eMAS_September_2026_Design_Delta.md` — consolidated architecture, workbook, assessment and migration changes.
- `ARTIFACT_MANIFEST.md` — source-artifact inventory and transfer status.

Companion repository summaries are also added under `docs/requirements/`, `docs/configuration/` and `docs/regulatory/`.

## Authority and precedence for this branch

For topics revised in September, use the September 2026 requirements and companion summaries before the July v3/v2 design. Where September sources are silent, retain the existing repository baseline until a controlled decision supersedes it. Conflicts must be recorded and resolved; they must not be silently reconciled in code or configuration.
