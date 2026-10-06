"""Deterministic builder for the MS-04 Wave1D dossier-diversity corpus.

Usage:
  python3 build_wave1d.py build   --wave1-root <Wave1TestDataRoot> --out <EmptyDir> [--status CANDIDATE|FROZEN]
  python3 build_wave1d.py package --build-dir <BuildDir> --expectations-dir <Dir> --out-zip <Path>

Rules (TASK.md "Deterministic fixture generation and freeze"):
- SD-002 and SD-010 are read-only inputs, verified against WAVE1_FREEZE_MANIFEST.csv before use.
- Bytes below the sequence trees are copied unchanged; only container paths change and,
  where the spec says so, clearly synthetic unrelated files are added.
- ZIP layout follows the Wave 1 convention (fixed time, explicit stored directory
  entries sorted by depth then name, deflated files sorted by name, Unix attributes).
- No wall-clock timestamps or absolute paths are written, so two clean builds are identical.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath

sys.path.insert(0, str(Path(__file__).resolve().parent))
import wave1d_spec as spec  # noqa: E402

WINDOWS_RESERVED = re.compile(r"^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$", re.IGNORECASE)
PACKAGE_ROOT = "eMAS_MS04_PreSales_Wave1D_DossierDiversity_v1"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def load_zip_model(path: Path) -> tuple[dict[str, bytes], set[str]]:
    files: dict[str, bytes] = {}
    directories: set[str] = set()
    with zipfile.ZipFile(path) as archive:
        for item in archive.infolist():
            name = item.filename.replace("\\", "/")
            pure = PurePosixPath(name)
            if pure.is_absolute() or ".." in pure.parts:
                raise RuntimeError(f"Unsafe ZIP entry in source: {name}")
            if item.is_dir():
                directories.add(name.rstrip("/") + "/")
            else:
                files[name] = archive.read(item)
    return files, directories


def all_directories(files: dict[str, bytes], directories: set[str]) -> list[str]:
    result = {directory.rstrip("/") + "/" for directory in directories}
    for name in files:
        parts = PurePosixPath(name).parts[:-1]
        for index in range(1, len(parts) + 1):
            result.add("/".join(parts[:index]) + "/")
    return sorted(result, key=lambda value: (value.count("/"), value))


def zip_bytes(files: dict[str, bytes], directories: set[str]) -> bytes:
    target = io.BytesIO()
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in all_directories(files, directories):
            item = zipfile.ZipInfo(name, spec.FIXED_ZIP_TIME)
            item.create_system = 3
            item.compress_type = zipfile.ZIP_STORED
            item.external_attr = (0o40755 << 16) | 0x10
            archive.writestr(item, b"")
        for name in sorted(files):
            item = zipfile.ZipInfo(name, spec.FIXED_ZIP_TIME)
            item.create_system = 3
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = 0o100644 << 16
            archive.writestr(item, files[name])
    return target.getvalue()


def read_wave1_freeze_manifest(wave1_root: Path) -> dict[str, str]:
    manifest = wave1_root / "WAVE1_FREEZE_MANIFEST.csv"
    with manifest.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    id_column = next(c for c in rows[0] if c.lower() in ("sampleid", "sample_id", "id"))
    hash_column = next(c for c in rows[0] if "sha256" in c.lower().replace("-", "").replace("_", ""))
    return {row[id_column].strip(): row[hash_column].strip().lower() for row in rows if row[hash_column].strip()}


def load_source_dossier(wave1_root: Path, sample_id: str, frozen: dict[str, str]) -> tuple[dict[str, bytes], set[str], str]:
    path = wave1_root / "fixtures" / sample_id / "fixture.zip"
    actual = sha256_file(path)
    if frozen.get(sample_id) != actual:
        raise RuntimeError(f"{sample_id} does not match WAVE1_FREEZE_MANIFEST.csv ({actual})")
    files, directories = load_zip_model(path)
    prefix = spec.WAVE1_ARCHIVE_ROOT + "/"
    outside = [n for n in list(files) + sorted(directories) if not (n == prefix or n.startswith(prefix))]
    if outside:
        raise RuntimeError(f"{sample_id} has entries outside '{spec.WAVE1_ARCHIVE_ROOT}': {outside[:3]}")
    relative_files = {name[len(prefix):]: data for name, data in files.items()}
    relative_dirs = {name[len(prefix):] for name in directories if name != prefix}
    return relative_files, relative_dirs, actual


def validate_entry_names(sample_id: str, names: list[str]) -> None:
    lowered: dict[str, str] = {}
    for name in names:
        if not name.isascii():
            raise RuntimeError(f"{sample_id}: non-ASCII entry {name!r}")
        if "\\" in name or ":" in name or name.startswith("/"):
            raise RuntimeError(f"{sample_id}: unsafe entry {name!r}")
        for part in name.rstrip("/").split("/"):
            if part in ("", ".", "..") or part != part.strip() or part.endswith("."):
                raise RuntimeError(f"{sample_id}: unsafe path segment {part!r} in {name!r}")
            if WINDOWS_RESERVED.match(part):
                raise RuntimeError(f"{sample_id}: reserved Windows name {part!r}")
        key = name.lower()
        if key in lowered and lowered[key] != name:
            raise RuntimeError(f"{sample_id}: case-only collision {name!r} / {lowered[key]!r}")
        lowered[key] = name


def build_fixture(fixture: dict, sources: dict) -> tuple[bytes, dict]:
    files: dict[str, bytes] = {}
    directories: set[str] = set()
    for root, source_id in fixture["dossiers"]:
        source_files, source_dirs, _ = sources[source_id]
        if root:
            directories.add(root + "/")
        for relative, data in source_files.items():
            target = spec.join_root(root, relative)
            if target in files:
                raise RuntimeError(f"{fixture['sampleId']}: duplicate entry {target}")
            files[target] = data
        for relative in source_dirs:
            directories.add(spec.join_root(root, relative.rstrip("/")) + "/")
    for relative, data in fixture["extraFiles"].items():
        if relative in files:
            raise RuntimeError(f"{fixture['sampleId']}: synthetic file collides with dossier entry {relative}")
        files[relative] = data

    entry_names = all_directories(files, directories) + sorted(files)
    validate_entry_names(fixture["sampleId"], entry_names)
    payload = zip_bytes(files, directories)

    # Byte-preservation proof: re-read the ZIP and compare every dossier file to its source.
    rebuilt, _ = load_zip_model_bytes(payload)
    for root, source_id in fixture["dossiers"]:
        for relative, data in sources[source_id][0].items():
            if rebuilt[spec.join_root(root, relative)] != data:
                raise RuntimeError(f"{fixture['sampleId']}: bytes changed for {relative}")

    stats = {
        "EntryCount": len(entry_names),
        "FileCount": len(files),
        "DirectoryCount": len(entry_names) - len(files),
    }
    return payload, stats


def load_zip_model_bytes(payload: bytes) -> tuple[dict[str, bytes], set[str]]:
    files: dict[str, bytes] = {}
    directories: set[str] = set()
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        for item in archive.infolist():
            if item.is_dir():
                directories.add(item.filename)
            else:
                files[item.filename] = archive.read(item)
    return files, directories


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def command_build(args: argparse.Namespace) -> None:
    wave1_root = Path(args.wave1_root).resolve()
    out = Path(args.out).resolve()
    if out.exists() and any(out.iterdir()):
        raise SystemExit(f"Output directory must be empty: {out}")
    frozen = read_wave1_freeze_manifest(wave1_root)
    sources = {sample_id: load_source_dossier(wave1_root, sample_id, frozen) for sample_id in spec.SOURCE_FIXTURES}

    rows = []
    for fixture in spec.FIXTURES:
        payload, stats = build_fixture(fixture, sources)
        sample_id = fixture["sampleId"]
        zip_path = out / "fixtures" / sample_id / "fixture.zip"
        zip_path.parent.mkdir(parents=True, exist_ok=True)
        zip_path.write_bytes(payload)
        source_ids = [source_id for _, source_id in fixture["dossiers"]]
        source_hashes = [sources[source_id][2] for source_id in source_ids]
        status = args.status if fixture["kind"] == "Normative" else f"{args.status}_CHARACTERIZATION"
        manifest = {
            "SampleId": sample_id,
            "Wave": "Wave1D (Dossier Diversity)",
            "Kind": fixture["kind"],
            "StatusLabel": fixture.get("statusLabel"),
            "Purpose": fixture["purpose"],
            "SourceFixtures": source_ids,
            "SourceFixtureSHA256": source_hashes,
            "MutationPerformed": fixture["mutation"],
            "DossierRoots": [root for root, _ in fixture["dossiers"]],
            "SyntheticUnrelatedFiles": sorted(fixture["extraFiles"]),
            **stats,
            "FixtureSHA256": sha256_bytes(payload),
            "FixtureSizeBytes": len(payload),
            "BuildRecipeVersion": spec.BUILD_RECIPE_VERSION,
            "BuildDate": spec.BUILD_DATE,
            "Status": status,
            "Provenance": "Internal test material derived from EXTEDORIN Wave 1 fixtures; redistribution status unconfirmed.",
        }
        write_text(zip_path.parent / "manifest.json", json.dumps(manifest, indent=2) + "\n")
        rows.append([
            sample_id, fixture["kind"], fixture["purpose"], "+".join(source_ids), "+".join(source_hashes),
            fixture["mutation"], str(stats["EntryCount"]), str(stats["FileCount"]),
            manifest["FixtureSHA256"], str(len(payload)), status,
        ])
        print(f"{sample_id} entries={stats['EntryCount']} files={stats['FileCount']} sha256={manifest['FixtureSHA256']}")

    buffer = io.StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(["SampleId", "Kind", "Purpose", "SourceFixtures", "SourceFixtureSHA256", "Mutation",
                     "EntryCount", "FileCount", "ZipSHA256", "ZipSizeBytes", "Status"])
    writer.writerows(rows)
    write_text(out / "WAVE1D_FREEZE_MANIFEST.csv", buffer.getvalue())


README_TEXT = """# eMAS MS-04 Pre-Sales Wave1D Dossier-Diversity Test Data v1

**INTERNAL USE ONLY - DO NOT DISTRIBUTE TO CUSTOMERS.**

Internal regression test data for task EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D.
All dossier bytes are derived from the frozen Wave 1 fixtures SD-002 and SD-010
(EXTEDORIN material, redistribution status unconfirmed). Only container paths
change; a few clearly synthetic unrelated files are added in SD-048 and SD-051.

Nothing here demonstrates regulatory validity, submission readiness or
migration readiness. SD-051 is characterization only
(CHARACTERIZATION_PENDING_DISCOVERY_DECISION), not discovery policy.

Contents:
- fixtures/SD-044 ... SD-051/fixture.zip and manifest.json
- WAVE1D_FREEZE_MANIFEST.csv
- expectations/ (expectations consumed by tests/dossier-diversity/Test-eMASDossierDiversity.ps1)
- PACKAGE_MANIFEST.csv (SHA-256 of every file above)

Run (from the repository root):
  pwsh -NoProfile -File tests/dossier-diversity/Test-eMASDossierDiversity.ps1 \\
    -CorpusRoot <this folder> -OutputRoot <results folder> [-Wave1CorpusRoot <Wave 1 test-data folder>]
"""


def command_package(args: argparse.Namespace) -> None:
    build_dir = Path(args.build_dir).resolve()
    expectations_dir = Path(args.expectations_dir).resolve()
    members: dict[str, bytes] = {"README_TEST_DATA.md": README_TEXT.encode("utf-8")}
    members["WAVE1D_FREEZE_MANIFEST.csv"] = (build_dir / "WAVE1D_FREEZE_MANIFEST.csv").read_bytes()
    for fixture in spec.FIXTURES:
        folder = build_dir / "fixtures" / fixture["sampleId"]
        for name in ("fixture.zip", "manifest.json"):
            members[f"fixtures/{fixture['sampleId']}/{name}"] = (folder / name).read_bytes()
    for path in sorted(expectations_dir.glob("*.json")):
        members[f"expectations/{path.name}"] = path.read_bytes()
    lines = ["RelativePath,SHA256,SizeBytes"]
    lines += [f"{name},{sha256_bytes(data)},{len(data)}" for name, data in sorted(members.items())]
    members["PACKAGE_MANIFEST.csv"] = ("\n".join(lines) + "\n").encode("utf-8")
    files = {f"{PACKAGE_ROOT}/{name}": data for name, data in members.items()}
    payload = zip_bytes(files, {PACKAGE_ROOT + "/"})
    out_zip = Path(args.out_zip).resolve()
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    out_zip.write_bytes(payload)
    print(f"{out_zip.name} sha256={sha256_bytes(payload)} size={len(payload)} members={len(members)}")
    print(f"PACKAGE_MANIFEST.csv sha256={sha256_bytes(members['PACKAGE_MANIFEST.csv'])}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--wave1-root", required=True)
    build.add_argument("--out", required=True)
    build.add_argument("--status", choices=["CANDIDATE", "FROZEN"], default="CANDIDATE")
    package = sub.add_parser("package")
    package.add_argument("--build-dir", required=True)
    package.add_argument("--expectations-dir", required=True)
    package.add_argument("--out-zip", required=True)
    args = parser.parse_args()
    {"build": command_build, "package": command_package}[args.command](args)


if __name__ == "__main__":
    main()
