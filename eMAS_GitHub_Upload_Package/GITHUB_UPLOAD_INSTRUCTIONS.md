# GitHub Upload Instructions

Repository: `MightyM-ouse/eMAS`

Recommended branch: `update/2026-09-12-latest-emas`

## What to upload

Upload the **contents of the `github-upload/` folder** into the repository root while preserving the directory structure.

The package contains only the September delta and companion documentation needed to bring the July repository baseline up to the current September design direction. Existing repository files not present in `github-upload/` should remain unchanged.

## Expected paths

- `README.md`
- `docs/updates/2026-09-12/README.md`
- `docs/updates/2026-09-12/ARTIFACT_MANIFEST.md`
- `docs/updates/2026-09-12/eMAS_September_2026_Design_Delta.md`
- `docs/requirements/eMAS_Enterprise_Requirements_v4.0_UPDATE_SUMMARY.md`
- `docs/configuration/eMAS_Mapping_Runtime_v4.0_UPDATE_SUMMARY.md`
- `docs/regulatory/eMAS_Regulatory_Assessment_Principles_2026-09-12.md`

## Suggested Git workflow

```bash
git checkout main
git pull
git checkout -b update/2026-09-12-latest-emas
# copy contents of github-upload/ into repository root
git status
git add README.md docs/
git commit -m "Consolidate September 2026 eMAS requirements and regulatory design updates"
git push -u origin update/2026-09-12-latest-emas
```

If the branch already exists, check it out instead of creating it.

## Historical source reference folder

The ZIP also includes `source-reference/`. These files are supplied for review/history only. Do not automatically upload them into the active canonical documentation tree. They are July v2/v3 source material and can be archived separately if required.

## Latest binary source artifacts still to add from controlled source

The following exact source binaries were referenced in September work but were not available as raw bytes while this ZIP was built:

1. `eMAS_Final_Enterprise_Requirements_v4.0.md`
2. `eMAS_Mapping_Workbook_and_Runtime_JSON_Requirements_v4.0.md`
3. `eMAS_Integrated_Assessment_Workbook_v4.1.xlsx`
4. `eMAS_Filterable_Dossier_and_Sequence_Conditions_v1.0.xlsx`
5. `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v1.0.docx`

Do not substitute reconstructed files and label them as originals. Add the exact controlled copies later if the repository should retain source attachments.
