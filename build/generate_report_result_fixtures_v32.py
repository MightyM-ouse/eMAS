#!/usr/bin/env python3
"""Generate deterministic synthetic normalized-result fixtures for v3.2 integration tests.

The fixtures contain structural test values only. They are not customer evidence,
production examples, approved mappings, effort estimates or migration decisions.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests" / "reporting"))

from fixture_factory_v32 import build_minimal_result  # noqa: E402


PHASES = {
    "PRE_SALES": "pre-sales",
    "PRE_MIGRATION": "pre-migration",
    "POST_MIGRATION": "post-migration",
}


def generate(output_directory: Path) -> list[Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    for phase, stem in PHASES.items():
        mapping_path = ROOT / "config" / "report-mappings" / f"{stem}.template-map.json"
        mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
        schema_path = ROOT / mapping["resultSchemaPath"]
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        result = build_minimal_result(phase, mapping, schema)

        path = output_directory / f"{stem}.result.valid.json"
        path.write_text(
            json.dumps(result, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        written.append(path)
        print(f"Generated {phase}: {path}")

    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-directory",
        type=Path,
        required=True,
        help="Directory for generated synthetic result JSON files.",
    )
    arguments = parser.parse_args()
    generate(arguments.output_directory.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
