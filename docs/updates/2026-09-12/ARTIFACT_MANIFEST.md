# September 2026 Artifact Manifest

This manifest records the recent eMAS artifacts used to prepare the `update/2026-09-12-latest-emas` branch.

## Source artifacts

| Artifact | Date | Status / use | Repository action |
|---|---:|---|---|
| `eMAS_Final_Enterprise_Requirements_v4.0.md` | 06 Sep 2026 | Revised proposed enterprise baseline | Material changes incorporated into requirement summary and design delta |
| `eMAS_Mapping_Workbook_and_Runtime_JSON_Requirements_v4.0.md` | 06 Sep 2026 | Proposed mapping/runtime architecture baseline | Material changes incorporated into configuration summary and design delta |
| `eMAS_Integrated_Assessment_Workbook_v4.1.xlsx` | 06 Sep 2026 | Draft integrated assessment/configuration workbook | Workbook structure and DataScope design incorporated into design delta |
| `eMAS_Filterable_Dossier_and_Sequence_Conditions_v1.0.xlsx` | 07 Sep 2026 | Draft filterable condition reference: 3,726 rows / 55 profiles | Condition-model and coverage concepts incorporated into design delta |
| `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v1.0.docx` | 12 Sep 2026 | Final consolidated regulatory/technical guide for controlled review/adoption | Core regulatory principles incorporated into regulatory companion summary |

## Transfer note

The recent XLSX/DOCX source artifacts above reside in the ChatGPT File Library. The GitHub connector available for this update can write repository content, but it does not expose the raw bytes of File Library references. Therefore this branch does **not** pretend that reconstructed partial binaries are the original files.

Instead, this branch commits source-grounded Markdown companions that capture the material requirements, design changes and regulatory principles available from those artifacts. The exact original binaries should be added later from their controlled source location if they are required as repository attachments.

This distinction is intentional: a partial reconstruction must not be named or represented as an original controlled workbook/document.

## Earlier source material locally available during consolidation

The July v2 documentation pack and Enterprise Requirements v3.0 were also available as reference material. Equivalent or superseding content already exists in the repository. They remain useful for historical context where September sources do not supersede them.

## Status boundary

Inclusion in this branch means “captured for review,” not “approved production baseline.” Regulatory sources that were verified on 12 September 2026 should be checked again for effective version/status before a controlled runtime release.
