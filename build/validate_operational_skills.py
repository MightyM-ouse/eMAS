#!/usr/bin/env python3
"""Validate the eMAS Operational LLM Skill catalogue and skill contracts."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "docs" / "llm-development-context" / "skills"
CATALOG_PATH = SKILL_DIR / "skill-catalog.json"

REQUIRED_METADATA = [
    "SkillId",
    "Title",
    "Version",
    "Status",
    "Owner",
    "DecisionReferences",
    "CanonicalSources",
    "AppliesTo",
    "Supersedes",
    "LastReviewed",
]

REQUIRED_SECTIONS = [
    "Invoke when",
    "Do not invoke when",
    "Required inputs and canonical sources",
    "Preconditions",
    "Procedure",
    "Required outputs",
    "Stop conditions",
    "Validation and evidence",
    "Definition of Done",
]

SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
SKILL_ID = re.compile(r"^SKILL-\d{3}$")


def load_catalog(path: Path = CATALOG_PATH) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def parse_front_matter(path: Path) -> tuple[dict[str, Any], str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("missing opening YAML front-matter marker")
    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise ValueError("missing closing YAML front-matter marker") from exc

    metadata: dict[str, Any] = {}
    current_key: str | None = None
    for raw in lines[1:end]:
        if raw.startswith("  - "):
            if current_key is None or not isinstance(metadata.get(current_key), list):
                raise ValueError(f"orphan list item: {raw.strip()}")
            metadata[current_key].append(raw[4:].strip())
            continue
        if not raw.strip():
            continue
        if raw.startswith(" ") or ":" not in raw:
            raise ValueError(f"unsupported front-matter syntax: {raw}")
        key, value = raw.split(":", 1)
        key = key.strip()
        value = value.strip()
        current_key = key
        if not value:
            metadata[key] = []
        elif value == "null":
            metadata[key] = None
        else:
            metadata[key] = value.strip('"\'')

    return metadata, "\n".join(lines[end + 1 :])


def section_body(body: str, heading: str) -> str:
    pattern = re.compile(
        rf"^## {re.escape(heading)}\s*$\n(.*?)(?=^## |\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(body)
    return match.group(1).strip() if match else ""


def bullet_count(text: str) -> int:
    return len(re.findall(r"^- ", text, flags=re.MULTILINE))


def numbered_count(text: str) -> int:
    return len(re.findall(r"^\d+\. ", text, flags=re.MULTILINE))


def validate_skill(path: Path, catalog_entry: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    rel = path.relative_to(ROOT).as_posix()
    try:
        metadata, body = parse_front_matter(path)
    except (OSError, ValueError) as exc:
        return [f"{rel}: {exc}"]

    for field in REQUIRED_METADATA:
        if field not in metadata:
            errors.append(f"{rel}: missing metadata field {field}")

    if not SKILL_ID.match(str(metadata.get("SkillId", ""))):
        errors.append(f"{rel}: SkillId must match SKILL-NNN")
    if not SEMVER.match(str(metadata.get("Version", ""))):
        errors.append(f"{rel}: Version must use Semantic Versioning")
    if metadata.get("Status") != "Effective":
        errors.append(f"{rel}: catalogued skill Status must be Effective")
    if not DATE.match(str(metadata.get("LastReviewed", ""))):
        errors.append(f"{rel}: LastReviewed must be YYYY-MM-DD")

    for list_field in ("DecisionReferences", "CanonicalSources", "AppliesTo"):
        value = metadata.get(list_field)
        if not isinstance(value, list) or not value:
            errors.append(f"{rel}: {list_field} must be a non-empty list")

    expected = {
        "SkillId": catalog_entry.get("skillId"),
        "Title": catalog_entry.get("title"),
        "Status": catalog_entry.get("status"),
        "Owner": catalog_entry.get("owner"),
    }
    for field, value in expected.items():
        if metadata.get(field) != value:
            errors.append(
                f"{rel}: metadata {field}={metadata.get(field)!r} does not match catalogue {value!r}"
            )

    h1 = re.search(r"^# (.+)$", body, flags=re.MULTILINE)
    if not h1 or h1.group(1).strip() != metadata.get("Title"):
        errors.append(f"{rel}: H1 title must match front-matter Title")

    headings = re.findall(r"^## (.+)$", body, flags=re.MULTILINE)
    positions: list[int] = []
    for required in REQUIRED_SECTIONS:
        if required not in headings:
            errors.append(f"{rel}: missing section '{required}'")
        else:
            positions.append(headings.index(required))
    if len(positions) == len(REQUIRED_SECTIONS) and positions != sorted(positions):
        errors.append(f"{rel}: required sections are not in the mandated order")

    minimums = {
        "Invoke when": 2,
        "Do not invoke when": 2,
        "Required inputs and canonical sources": 4,
        "Preconditions": 3,
        "Required outputs": 5,
        "Stop conditions": 5,
        "Validation and evidence": 4,
        "Definition of Done": 6,
    }
    for heading, minimum in minimums.items():
        count = bullet_count(section_body(body, heading))
        if count < minimum:
            errors.append(f"{rel}: section '{heading}' needs at least {minimum} bullet items; found {count}")

    procedure_steps = numbered_count(section_body(body, "Procedure"))
    if procedure_steps < 6:
        errors.append(f"{rel}: Procedure needs at least 6 ordered steps; found {procedure_steps}")

    for source in metadata.get("CanonicalSources", []):
        source_path = ROOT / str(source)
        if not source_path.exists():
            errors.append(f"{rel}: canonical source does not exist: {source}")

    forbidden_placeholders = ("SKILL-XXX", "Replace with", "Concrete task example")
    for placeholder in forbidden_placeholders:
        if placeholder in path.read_text(encoding="utf-8"):
            errors.append(f"{rel}: contains template placeholder {placeholder!r}")

    return errors


def validate_repository() -> list[str]:
    errors: list[str] = []
    try:
        catalog = load_catalog()
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{CATALOG_PATH.relative_to(ROOT)}: {exc}"]

    if not SEMVER.match(str(catalog.get("catalogVersion", ""))):
        errors.append("skill-catalog.json: catalogVersion must use Semantic Versioning")
    if catalog.get("status") != "Effective":
        errors.append("skill-catalog.json: status must be Effective")
    if not DATE.match(str(catalog.get("effectiveDate", ""))):
        errors.append("skill-catalog.json: effectiveDate must be YYYY-MM-DD")

    entries = catalog.get("skills")
    if not isinstance(entries, list) or not entries:
        return errors + ["skill-catalog.json: skills must be a non-empty list"]

    seen_ids: set[str] = set()
    seen_files: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict):
            errors.append("skill-catalog.json: every skill entry must be an object")
            continue
        skill_id = str(entry.get("skillId", ""))
        filename = str(entry.get("file", ""))
        if skill_id in seen_ids:
            errors.append(f"skill-catalog.json: duplicate skillId {skill_id}")
        if filename in seen_files:
            errors.append(f"skill-catalog.json: duplicate file {filename}")
        seen_ids.add(skill_id)
        seen_files.add(filename)
        if not filename.endswith(".md") or "/" in filename or "\\" in filename:
            errors.append(f"skill-catalog.json: invalid skill file {filename!r}")
            continue
        path = SKILL_DIR / filename
        if not path.exists():
            errors.append(f"skill-catalog.json: missing skill file {filename}")
            continue
        errors.extend(validate_skill(path, entry))

    actual_files = {
        path.name
        for path in SKILL_DIR.glob("*.md")
        if path.name not in {"README.md", "skill-template.md"}
    }
    unlisted = sorted(actual_files - seen_files)
    missing = sorted(seen_files - actual_files)
    if unlisted:
        errors.append(f"skill-catalog.json: unlisted skill files: {', '.join(unlisted)}")
    if missing:
        errors.append(f"skill-catalog.json: catalogued files not found: {', '.join(missing)}")

    return errors


def main() -> int:
    errors = validate_repository()
    if errors:
        print(f"Operational skill validation failed with {len(errors)} issue(s):")
        for error in errors:
            print(f"- {error}")
        return 1
    catalog = load_catalog()
    print(f"Operational skill validation passed for {len(catalog['skills'])} Effective skills.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
