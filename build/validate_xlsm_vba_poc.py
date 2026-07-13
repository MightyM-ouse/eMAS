#!/usr/bin/env python3
"""Validate the synthetic eMAS XLSM/VBA proof-of-concept source package."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from generate_emas_mapping_poc_workbook import generate as generate_workbook

from emas_xlsx_poc import (
    apply_fixture_patch,
    build_runtime_json,
    canonical_json_bytes,
    read_xlsx_tables,
    validate_workbook_tables,
)

REQUIRED_MODULES = {
    "modConstants.bas": ("Option Explicit", "EMAS_SCHEMA_VERSION"),
    "modUtilities.bas": ("Option Explicit", "GetTableByName", "JsonEscape"),
    "modWorkbookStructure.bas": ("Option Explicit", "ValidateWorkbookStructure"),
    "modValidation.bas": ("Option Explicit", "ValidateWorkbook"),
    "modJsonBuilder.bas": ("Option Explicit", "BuildRuntimeJson"),
    "modJsonWriter.bas": ("Option Explicit", "WriteUtf8WithoutBom"),
    "modChecksum.bas": ("Option Explicit", "CalculateFileSha256"),
    "modExportHistory.bas": ("Option Explicit", "AppendExportHistory"),
    "modMain.bas": ("Option Explicit", "eMAS_ValidateWorkbook", "eMAS_ExportDevJson"),
}
PROHIBITED_VBA_TOKENS = (
    "ActiveCell",
    "Selection",
    ".Select",
    ".Activate",
    "MappingWorkbookPath",
    " Is Nothing Or ",
)


def source_bundle_sha256(source_definition: Path) -> str:
    source = json.loads(source_definition.read_text(encoding="utf-8"))
    digest = hashlib.sha256()
    paths = [Path("workbook-source.json")] + [Path(item) for item in source.get("parts", [])]
    for relative in paths:
        path = source_definition.parent / relative if relative.name != source_definition.name else source_definition
        digest.update(str(relative).replace("\\", "/").encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_vba_sources(vba_dir: Path) -> list[str]:
    failures: list[str] = []
    for filename, required_tokens in REQUIRED_MODULES.items():
        path = vba_dir / filename
        if not path.is_file():
            failures.append(f"missing VBA module {path}")
            continue
        content = path.read_text(encoding="utf-8-sig")
        for token in required_tokens:
            if token not in content:
                failures.append(f"{filename}: missing required token {token}")
        for token in PROHIBITED_VBA_TOKENS:
            if token.lower() in content.lower():
                failures.append(f"{filename}: prohibited token {token}")
        if "PowerShell".lower() in content.lower():
            failures.append(f"{filename}: PowerShell must not generate or repair runtime JSON")
    return failures


def run_schema_validator(repo_root: Path, json_path: Path) -> tuple[bool, str]:
    command = [sys.executable, str(repo_root / "build" / "validate_emas_schema.py"), "--instance", str(json_path)]
    completed = subprocess.run(command, cwd=repo_root, text=True, capture_output=True)
    output = (completed.stdout + completed.stderr).strip()
    return completed.returncode == 0, output


def validate_package(repo_root: Path, skip_schema: bool = False) -> int:
    source_definition = repo_root / "config" / "authoring" / "poc" / "workbook-source.json"
    fixture_root = repo_root / "config" / "authoring" / "poc" / "fixtures"
    vba_dir = repo_root / "config" / "vba" / "modules"
    manifest_path = repo_root / "config" / "authoring" / "poc" / "poc-manifest.json"

    failures: list[str] = []
    if not source_definition.is_file():
        failures.append(f"missing workbook source definition {source_definition}")
    if failures:
        for failure in failures:
            print(f"[FAIL] {failure}")
        return 1

    generated_workbook_dir = tempfile.TemporaryDirectory()
    workbook = Path(generated_workbook_dir.name) / "eMAS_Mapping_Configuration_POC_Source.xlsx"
    generate_workbook(source_definition, workbook)
    tables = read_xlsx_tables(workbook)
    issues = validate_workbook_tables(tables)
    if issues:
        failures.extend(issue.render() for issue in issues)
    else:
        print(f"[PASS] workbook table and semantic validation ({len(tables)} tables)")

    exported = canonical_json_bytes(build_runtime_json(tables))
    exported_again = canonical_json_bytes(build_runtime_json(read_xlsx_tables(workbook)))
    if exported != exported_again:
        failures.append("reference export is not deterministic")
    else:
        print("[PASS] deterministic reference export")
    if exported.startswith(b"\xef\xbb\xbf"):
        failures.append("expected JSON contains a UTF-8 BOM")
    else:
        print("[PASS] UTF-8 JSON without BOM")

    vba_failures = validate_vba_sources(vba_dir)
    failures.extend(vba_failures)
    if not vba_failures:
        print(f"[PASS] VBA source contract ({len(REQUIRED_MODULES)} modules)")

    fixture_manifest = json.loads((fixture_root / "manifest.json").read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as temp_dir_text:
        temp_dir = Path(temp_dir_text)
        for fixture in fixture_manifest["fixtures"]:
            case_tables = tables
            if fixture.get("patch"):
                patch = json.loads((fixture_root / fixture["patch"]).read_text(encoding="utf-8"))
                case_tables = apply_fixture_patch(tables, patch)
            case_issues = validate_workbook_tables(case_tables)
            actual_valid = not case_issues
            codes = {issue.code for issue in case_issues}
            expected_codes = set(fixture.get("expectedErrorCodes", []))
            ok = actual_valid == bool(fixture["expectedValid"]) and expected_codes.issubset(codes)
            if not ok:
                failures.append(
                    f"{fixture['id']}: expectedValid={fixture['expectedValid']} actualValid={actual_valid} "
                    f"expectedCodes={sorted(expected_codes)} actualCodes={sorted(codes)}"
                )
                continue
            print(f"[PASS] {fixture['id']} workbook validation expectation")
            if actual_valid and not skip_schema:
                instance_path = temp_dir / f"{fixture['id']}.json"
                instance_path.write_bytes(canonical_json_bytes(build_runtime_json(case_tables)))
                schema_ok, schema_output = run_schema_validator(repo_root, instance_path)
                if not schema_ok:
                    failures.append(f"{fixture['id']}: Runtime JSON Schema/semantic validation failed: {schema_output}")
                else:
                    print(f"[PASS] {fixture['id']} Runtime JSON Schema 1.0.0 validation")

    if manifest_path.is_file():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        checks = {
            "workbookSourceBundleSha256": source_bundle_sha256(source_definition),
            "generatedSourceWorkbookSha256": sha256(workbook),
            "expectedJsonSha256": hashlib.sha256(exported).hexdigest(),
        }
        for key, actual in checks.items():
            declared = manifest.get(key)
            if declared != actual:
                failures.append(f"poc-manifest {key} expected {declared}, actual {actual}")
        if not any(key in " ".join(failures) for key in checks):
            print("[PASS] POC manifest checksums and golden JSON hash")
    else:
        failures.append(f"missing POC manifest {manifest_path}")

    generated_workbook_dir.cleanup()

    if failures:
        print("\nPOC validation failures:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("XLSM/VBA POC source and conformance validation passed.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--skip-schema", action="store_true", help="Skip invocation of the repository schema validator.")
    args = parser.parse_args()
    return validate_package(args.repo_root.resolve(), args.skip_schema)

if __name__ == "__main__":
    raise SystemExit(main())
