#!/usr/bin/env python3
"""Validate the eMAS Runtime JSON schema package (1.0.0 and 1.1.0) and synthetic fixtures."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

try:
    from jsonschema import Draft202012Validator, FormatChecker
    from referencing import Registry, Resource
except ImportError as exc:
    raise SystemExit(
        "Missing build dependency 'jsonschema'. Install with: "
        "python -m pip install -r build/requirements-schema-validation.txt"
    ) from exc

from emas_schema_model import ValidationIssue, _json_path
from emas_schema_semantics import _semantic_issues

def build_schema_registry(schema_path: Path) -> Registry:
    registry = Registry()
    schema_root = schema_path.parent
    for candidate in sorted(schema_root.rglob('*.schema.json')):
        document = load_json(candidate)
        Draft202012Validator.check_schema(document)
        resource = Resource.from_contents(document)
        registry = registry.with_resource(document['$id'], resource)
    return registry

VERSION_GATE_SCHEMA_PATH = ('allOf', 0)

def _schema_issue_code(error: Any) -> str:
    """Return a stable code for a JSON Schema error.

    Errors raised by the root VERSION-GATE-1.0.0 branch (allOf[0]) mean a Schema 1.1.0 property was used in a
    document labelled 1.0.0. An enum failure on configuration.schemaVersion means an unsupported version.
    Every other structural failure keeps the historical SCHEMA_ERROR code.
    """
    if tuple(error.absolute_schema_path)[:2] == VERSION_GATE_SCHEMA_PATH:
        return 'SCHEMA_VERSION_FEATURE'
    if list(error.absolute_path) == ['configuration', 'schemaVersion'] and error.validator == 'enum':
        return 'SCHEMA_UNSUPPORTED_VERSION'
    return 'SCHEMA_ERROR'

def validate_instance(schema: dict[str, Any], instance: Any, registry: Registry | None=None) -> list[ValidationIssue]:
    validator = Draft202012Validator(schema, format_checker=FormatChecker(), registry=registry or Registry())
    schema_errors = sorted(validator.iter_errors(instance), key=lambda error: list(error.absolute_path))
    if schema_errors:
        return [ValidationIssue(_schema_issue_code(error), _json_path(error.absolute_path), error.message) for error in schema_errors]
    if not isinstance(instance, dict):
        return [ValidationIssue('SCHEMA_ERROR', '$', 'root must be an object')]
    return _semantic_issues(instance)

def load_json(path: Path) -> Any:
    with path.open('r', encoding='utf-8') as handle:
        return json.load(handle)

def apply_merge_patch(base: Any, patch: Any) -> Any:
    """Apply RFC 7396-style JSON Merge Patch semantics to a copied value."""
    if not isinstance(patch, dict):
        return patch
    result = dict(base) if isinstance(base, dict) else {}
    for key, value in patch.items():
        if value is None:
            result.pop(key, None)
        else:
            result[key] = apply_merge_patch(result.get(key), value)
    return result

def load_fixture_item(fixture_root: Path, item: dict[str, Any]) -> tuple[str, Any]:
    if 'path' in item:
        return (str(item['path']), load_json(fixture_root / item['path']))
    if 'fragments' in item:
        instance: Any = {}
        for fragment in item['fragments']:
            instance = apply_merge_patch(instance, load_json(fixture_root / fragment))
        label = ' + '.join(item['fragments'])
        if 'patch' in item:
            instance = apply_merge_patch(instance, load_json(fixture_root / item['patch']))
            label += f" + {item['patch']}"
        return (label, instance)
    base_path = fixture_root / item['base']
    patch_path = fixture_root / item['patch']
    instance = apply_merge_patch(load_json(base_path), load_json(patch_path))
    return (f"{item['base']} + {item['patch']}", instance)

def validate_fixture_manifest(schema_path: Path, manifest_path: Path) -> int:
    schema = load_json(schema_path)
    Draft202012Validator.check_schema(schema)
    registry = build_schema_registry(schema_path)
    manifest = load_json(manifest_path)
    fixture_root = manifest_path.parent
    failures = 0
    for item in manifest['fixtures']:
        label_path, instance = load_fixture_item(fixture_root, item)
        issues = validate_instance(schema, instance, registry)
        actual_valid = not issues
        expected_valid = bool(item['expectedValid'])
        codes = {issue.code for issue in issues}
        expected_codes = set(item.get('expectedErrorCodes', []))
        ok = actual_valid == expected_valid and expected_codes.issubset(codes)
        label = 'PASS' if ok else 'FAIL'
        print(f'[{label}] {label_path} expectedValid={expected_valid} actualValid={actual_valid}')
        for issue in issues:
            print(f'  - {issue.render()}')
        if not ok:
            missing = sorted(expected_codes - codes)
            if missing:
                print(f"  - Missing expected error codes: {', '.join(missing)}")
            failures += 1
    return failures

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--schema', type=Path, default=Path('config/schema/eMAS-runtime-config.schema.json'), help='Path to the runtime JSON Schema.')
    parser.add_argument('--manifest', type=Path, default=Path('config/schema/examples/fixture-manifest.json'), help='Path to the fixture manifest.')
    parser.add_argument('--instance', type=Path, help='Validate one runtime JSON instance instead of the fixture suite.')
    args = parser.parse_args()
    schema = load_json(args.schema)
    Draft202012Validator.check_schema(schema)
    registry = build_schema_registry(args.schema)
    if args.instance:
        issues = validate_instance(schema, load_json(args.instance), registry)
        for issue in issues:
            print(issue.render())
        return 1 if issues else 0
    failures = validate_fixture_manifest(args.schema, args.manifest)
    if failures:
        print(f'Fixture validation failed: {failures} fixture expectation(s) did not match.')
        return 1
    print('Schema and semantic fixture validation passed.')
    return 0
if __name__ == '__main__':
    sys.exit(main())
