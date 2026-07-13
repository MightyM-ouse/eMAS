# eMAS Release and Recall Procedure

**Version:** 1.0  
**Status:** Approved

## 1. Release manifests

### Internal controlled release

Records product version, engine modules, runtime JSON version and SHA-256, schema version, mapping version, templates, optional WPF, instructions, known limitations and checksums.

### Customer Pre-Sales release

Contains only the approved lightweight subset and its checksum manifest.

## 2. Version and tags

Product releases use Git tags `eMAS-vX.Y.Z`. The manifest maps product version to component versions.

## 3. Defective release recall

1. Mark the defective release and configuration checksum `Recalled`.
2. Retain the artifact; do not delete it.
3. Identify affected executions through logs and manifests.
4. Classify impact by affected rules, reports and decisions.
5. Notify affected consultants/projects.
6. Issue a corrected incremented release.
7. Provide re-execution or re-baselining instructions.
8. Maintain recall and corrective-action records.
9. Optionally configure the loader to warn on known recalled checksums.

## 4. Rollback

Rollback uses a previously approved compatible release only. Compatibility and project impact must be assessed before re-execution.
