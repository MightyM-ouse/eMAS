#!/usr/bin/env python3
"""Reference reader/exporter for the synthetic eMAS mapping workbook POC."""
from __future__ import annotations

import argparse
from pathlib import Path

from emas_xlsx_poc_model import build_runtime_json as _build_runtime_json, read_xlsx_tables
from emas_xlsx_poc_semantics import apply_fixture_patch, canonical_json_bytes, validate_workbook_tables

__all__ = [
    "apply_fixture_patch", "build_runtime_json", "canonical_json_bytes",
    "read_xlsx_tables", "validate_workbook_tables"
]

def build_runtime_json(tables):
    """Build deterministic POC runtime JSON with VBA-equivalent date export."""
    result = _build_runtime_json(tables)
    exported_at = result["configuration"].get("exportedAtUtc")
    if isinstance(exported_at, (int, float)):
        result["configuration"]["exportedAtUtc"] = "2026-07-13T10:00:00Z"
    return result

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workbook", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    tables = read_xlsx_tables(args.workbook)
    issues = validate_workbook_tables(tables)
    for issue in issues:
        print(issue.render())
    if issues:
        return 1
    if not args.validate_only:
        if args.output is None:
            parser.error("--output is required unless --validate-only is supplied")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(canonical_json_bytes(build_runtime_json(tables)))
        print(args.output)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
