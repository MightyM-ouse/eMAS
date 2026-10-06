#!/usr/bin/env python3
"""Build deterministic Wave1E eCTD v4 physical-discovery fixtures."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import shutil
import zipfile
from pathlib import Path


FIXED_ZIP_TIME = (2026, 10, 6, 12, 0, 0)
FIXTURE_IDS = [f"SD-{number:03d}" for number in range(53, 75)]
STUB_NOTICE = "eMAS Wave1E synthetic discovery fixture: NOT a valid eCTD v4.0 message"


def stub_xml(sample_id: str, unit_path: str, malformed: bool = False) -> bytes:
    if malformed:
        text = f"<!-- {STUB_NOTICE} -->\n<discovery-stub sample-id=\"{sample_id}\">\n"
    else:
        text = (
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            f"<!-- {STUB_NOTICE} -->\n"
            f"<discovery-stub sample-id=\"{sample_id}\" unit-path=\"{unit_path}\" />\n"
        )
    return text.encode("utf-8")


def add_file(files: dict[str, bytes], path: str, content: str | bytes) -> None:
    files[path] = content if isinstance(content, bytes) else content.encode("utf-8")


def add_unit(
    files: dict[str, bytes],
    sample_id: str,
    unit_path: str,
    modules: tuple[str, ...] = (),
    *,
    include_submission: bool = True,
    include_sha: bool = True,
    mixed_case: bool = False,
    malformed: bool = False,
) -> None:
    submission_name = "SubmissionUnit.XML" if mixed_case else "submissionunit.xml"
    sha_name = "SHA256.TXT" if mixed_case else "sha256.txt"
    module_names = tuple(module.upper() for module in modules) if mixed_case else modules
    submission = stub_xml(sample_id, unit_path, malformed=malformed)
    if include_submission:
        add_file(files, f"{unit_path}/{submission_name}", submission)
    if include_sha:
        digest = hashlib.sha256(submission).hexdigest() if include_submission else "0" * 64
        add_file(files, f"{unit_path}/{sha_name}", digest + "\n")
    for module in module_names:
        add_file(files, f"{unit_path}/{module}/synthetic-content.txt", f"{sample_id} {module} synthetic placeholder\n")


def add_v3_unit(files: dict[str, bytes], sample_id: str, unit_path: str) -> None:
    add_file(files, f"{unit_path}/index.xml", f"<!-- {sample_id} synthetic v3 discovery marker -->\n<ectd />\n")
    add_file(files, f"{unit_path}/m1/synthetic-content.txt", f"{sample_id} m1 synthetic placeholder\n")


def unit(path: str, candidate: str, kind: str, exact: bool, number: int | None) -> dict[str, object]:
    return {
        "relativePath": path,
        "candidatePath": candidate,
        "sequenceLikeKind": kind,
        "isExactSequenceFolder": exact,
        "sequenceNumber": number,
    }


def scenario(
    sample_id: str,
    scenario_id: str,
    title: str,
    files: dict[str, bytes],
    candidates: list[str],
    units: list[dict[str, object]],
    *,
    wrappers: list[str] | None = None,
    observations: dict[str, int] | None = None,
    unplaced_markers: list[str] | None = None,
    source_mode: str = "ZipAndDirectory",
    access_denied_paths: list[str] | None = None,
) -> dict[str, object]:
    return {
        "sampleId": sample_id,
        "scenarioId": scenario_id,
        "title": title,
        "sourceMode": source_mode,
        "files": files,
        "expected": {
            "candidatePaths": candidates,
            "wrapperPaths": wrappers or [],
            "units": units,
            "observationCounts": observations or {},
            "unplacedSubmissionUnitMarkers": unplaced_markers or [],
            "accessDeniedPaths": access_denied_paths or [],
        },
    }


def build_scenarios() -> list[dict[str, object]]:
    scenarios: list[dict[str, object]] = []

    files: dict[str, bytes] = {}
    add_unit(files, "SD-053", "1", ("m1", "m3"))
    scenarios.append(scenario("SD-053", "V4-01", "FDA-like root-level transmission", files, [""], [unit("1", "", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-054", "app/1", ("m1",))
    add_unit(files, "SD-054", "app/2")
    scenarios.append(scenario("SD-054", "V4-02", "FDA-like lifecycle archive with reuse-only unit", files, ["app"], [unit("app/1", "app", "SubmissionUnitFolder", False, 1), unit("app/2", "app", "SubmissionUnitFolder", False, 2)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-055", "ema000123/1", ("m1", "m2"))
    scenarios.append(scenario("SD-055", "V4-03", "EU first-level folder and unit", files, ["ema000123"], [unit("ema000123/1", "ema000123", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-056", "Customer/Export/Set/ema000123/7", ("m1",))
    scenarios.append(scenario("SD-056", "V4-04", "Neutral deep wrappers", files, ["Customer/Export/Set/ema000123"], [unit("Customer/Export/Set/ema000123/7", "Customer/Export/Set/ema000123", "SubmissionUnitFolder", False, 7)], wrappers=["Customer", "Customer/Export", "Customer/Export/Set"], observations={"SubmissionUnitFoldersObserved": 1, "WrapperDepth": 1}))

    files = {}
    add_unit(files, "SD-057", "ema000123/1", ("m1",))
    add_unit(files, "SD-057", "nda123456/1", ("m1",))
    scenarios.append(scenario("SD-057", "V4-05", "Two independent v4 containers", files, ["ema000123", "nda123456"], [unit("ema000123/1", "ema000123", "SubmissionUnitFolder", False, 1), unit("nda123456/1", "nda123456", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 2}))

    files = {}
    add_v3_unit(files, "SD-058", "Legacy/0000")
    add_unit(files, "SD-058", "Modern/1")
    scenarios.append(scenario("SD-058", "V4-06", "Separate v3 and v4 containers", files, ["Legacy", "Modern"], [unit("Legacy/0000", "Legacy", "NumericSequenceDirectory", True, 0), unit("Modern/1", "Modern", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {"Archive/2024/report.pdf": b"synthetic report\n", "Archive/2023/notes.txt": b"synthetic notes\n"}
    scenarios.append(scenario("SD-059", "V4-07", "Unrelated year folders", files, [], []))

    files = {"Archive/2024/data.xml": b"<data />\n", "Data/3/export.xml": b"<export />\n"}
    scenarios.append(scenario("SD-060", "V4-08", "Numeric folders with arbitrary XML", files, [], []))

    files = {}
    add_unit(files, "SD-061", "Pkg/12", include_sha=False)
    scenarios.append(scenario("SD-061", "V4-09", "Minimal submission-unit marker", files, ["Pkg"], [unit("Pkg/12", "Pkg", "SubmissionUnitFolder", False, 12)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-062", "Pkg/1", ("m1",), include_sha=False)
    scenarios.append(scenario("SD-062", "V4-10", "Confirmed unit missing sha256.txt", files, ["Pkg"], [unit("Pkg/1", "Pkg", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-063", "Pkg/1", ("m1",), include_submission=False)
    scenarios.append(scenario("SD-063", "V4-11", "Damaged fallback marker set", files, ["Pkg"], [unit("Pkg/1", "Pkg", "DamagedSubmissionUnitCandidate", False, 1)], observations={"DamagedSubmissionUnitMarkerSet": 1}))

    files = {"V3Pkg/0005/hidden.txt": b"unreadable v3 child\n", "NonV4/5/hidden.txt": b"unreadable non-four-digit child\n"}
    scenarios.append(scenario("SD-064", "V4-12", "Four-digit fail-open and non-four-digit unreadable negative", files, ["V3Pkg"], [unit("V3Pkg/0005", "V3Pkg", "NumericSequenceDirectory", True, 5)], source_mode="DirectoryAccess", access_denied_paths=["V3Pkg/0005", "NonV4/5"]))

    files = {}
    add_unit(files, "SD-065", "3", ("m1",))
    scenarios.append(scenario("SD-065", "V4-13", "Root-level FDA-like unit", files, [""], [unit("3", "", "SubmissionUnitFolder", False, 3)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    submission = stub_xml("SD-066", "<archive-root>")
    files["submissionunit.xml"] = submission
    files["sha256.txt"] = (hashlib.sha256(submission).hexdigest() + "\n").encode("ascii")
    files["m1/synthetic-content.txt"] = b"synthetic root module\n"
    scenarios.append(scenario("SD-066", "V4-13B", "Misplaced archive-root marker", files, [], [], observations={"UnplacedSubmissionUnitMarker": 1}, unplaced_markers=["submissionunit.xml"]))

    files = {}
    add_unit(files, "SD-067", "Pkg/1", ("m1",), mixed_case=True)
    scenarios.append(scenario("SD-067", "V4-14", "Case-variant structural markers", files, ["Pkg"], [unit("Pkg/1", "Pkg", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-068", "Pkg/1", malformed=True)
    scenarios.append(scenario("SD-068", "V4-15", "Malformed discovery-only XML stub", files, ["Pkg"], [unit("Pkg/1", "Pkg", "SubmissionUnitFolder", False, 1)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_v3_unit(files, "SD-069", "App/0000")
    add_v3_unit(files, "SD-069", "App/0003")
    add_unit(files, "SD-069", "App/4")
    scenarios.append(scenario("SD-069", "V4-16", "Mixed v3-to-v4 physical container", files, ["App"], [unit("App/0000", "App", "NumericSequenceDirectory", True, 0), unit("App/0003", "App", "NumericSequenceDirectory", True, 3), unit("App/4", "App", "SubmissionUnitFolder", False, 4)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_v3_unit(files, "SD-070", "App/0999")
    add_unit(files, "SD-070", "App/1000")
    scenarios.append(scenario("SD-070", "V4-17", "Four-digit v4 marker precedence", files, ["App"], [unit("App/0999", "App", "NumericSequenceDirectory", True, 999), unit("App/1000", "App", "SubmissionUnitFolder", False, 1000)], observations={"SubmissionUnitFoldersObserved": 1}))

    files = {}
    add_unit(files, "SD-071", "Pkg/0001")
    scenarios.append(scenario("SD-071", "V4-18", "Leading-zero non-canonical unit name", files, ["Pkg"], [unit("Pkg/0001", "Pkg", "SubmissionUnitFolder", False, None)], observations={"SubmissionUnitFoldersObserved": 1, "NonCanonicalSequenceNumberFolderName": 1}))

    files = {}
    add_unit(files, "SD-072", "fr0034g/fr1762/3", ("m1", "m2", "m3"))
    add_unit(files, "SD-072", "fr0034g/fr1011/156")
    add_unit(files, "SD-072", "fr0034g/fr0345/455")
    candidates = ["fr0034g/fr0345", "fr0034g/fr1011", "fr0034g/fr1762"]
    units = [unit("fr0034g/fr0345/455", "fr0034g/fr0345", "SubmissionUnitFolder", False, 455), unit("fr0034g/fr1011/156", "fr0034g/fr1011", "SubmissionUnitFolder", False, 156), unit("fr0034g/fr1762/3", "fr0034g/fr1762", "SubmissionUnitFolder", False, 3)]
    scenarios.append(scenario("SD-072", "V4-19", "EU grouped-transmission physical layout", files, candidates, units, wrappers=["fr0034g"], observations={"SubmissionUnitFoldersObserved": 3, "WrapperDepth": 3}))

    files = {}
    add_unit(files, "SD-073", "Pkg/1234567")
    submission = stub_xml("SD-073", "Pkg2/0001")
    files["Pkg2/0001/submissionunit.xml"] = submission
    files["Pkg2/0001/index.xml"] = b"<ectd />\n"
    scenarios.append(scenario("SD-073", "V4-20-21", "Out-of-range marker and conflicting backbones", files, ["Pkg2"], [unit("Pkg2/0001", "Pkg2", "AmbiguousRegulatoryUnitFolder", False, None)], observations={"ConflictingBackboneMarkers": 1, "NonCanonicalSequenceNumberFolderName": 1, "UnplacedSubmissionUnitMarker": 1}, unplaced_markers=["Pkg/1234567/submissionunit.xml"]))

    files = {}
    add_unit(files, "SD-074", "Exports/2024/ema000123/1", ("m1",))
    files["Exports/2024/Archive/2019/annual-report.pdf"] = b"synthetic unrelated annual report\n"
    scenarios.append(scenario("SD-074", "V4-22", "Year wrapper above a v4 package", files, ["Exports/2024/ema000123"], [unit("Exports/2024/ema000123/1", "Exports/2024/ema000123", "SubmissionUnitFolder", False, 1)], wrappers=["Exports", "Exports/2024"], observations={"SubmissionUnitFoldersObserved": 1, "WrapperDepth": 1}))

    assert [item["sampleId"] for item in scenarios] == FIXTURE_IDS
    return scenarios


def zip_info(name: str, is_directory: bool = False) -> zipfile.ZipInfo:
    normalized = name.replace("\\", "/") + ("/" if is_directory and not name.endswith("/") else "")
    info = zipfile.ZipInfo(normalized, FIXED_ZIP_TIME)
    info.create_system = 3
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = ((0o40755 if is_directory else 0o100644) << 16)
    return info


def write_fixture_zip(path: Path, files: dict[str, bytes]) -> None:
    directories: set[str] = set()
    for file_path in files:
        parts = file_path.split("/")[:-1]
        for index in range(1, len(parts) + 1):
            directories.add("/".join(parts[:index]))
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for directory in sorted(directories):
            archive.writestr(zip_info(directory, True), b"")
        for file_path in sorted(files):
            archive.writestr(zip_info(file_path), files[file_path])


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8", newline="\n")


def write_package(path: Path, output_root: Path) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for source in sorted(item for item in output_root.rglob("*") if item.is_file()):
            relative = source.relative_to(output_root).as_posix()
            archive.writestr(zip_info(relative), source.read_bytes())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--package-path", required=True, type=Path)
    args = parser.parse_args()
    output_root = args.output_root.resolve()
    package_path = args.package_path.resolve()
    if output_root == package_path or output_root in package_path.parents:
        raise SystemExit("package path must be outside output root")

    fixtures_root = output_root / "fixtures"
    fixtures_root.mkdir(parents=True, exist_ok=True)
    scenarios = build_scenarios()
    freeze_rows: list[dict[str, str]] = []
    expectation_rows: list[dict[str, object]] = []

    for item in scenarios:
        sample_id = str(item["sampleId"])
        sample_root = fixtures_root / sample_id
        if sample_root.exists():
            shutil.rmtree(sample_root)
        sample_root.mkdir(parents=True)
        fixture_path = sample_root / "fixture.zip"
        write_fixture_zip(fixture_path, item["files"])
        fixture_hash = sha256(fixture_path)
        freeze_rows.append({
            "SampleId": sample_id,
            "ScenarioId": str(item["scenarioId"]),
            "FixtureFilename": f"fixtures/{sample_id}/fixture.zip",
            "FixtureSHA256": fixture_hash,
            "SourceMode": str(item["sourceMode"]),
            "Status": "FROZEN",
        })
        expectation_rows.append({
            "sampleId": sample_id,
            "scenarioId": item["scenarioId"],
            "title": item["title"],
            "sourceMode": item["sourceMode"],
            "fixtureSha256": fixture_hash,
            "expected": item["expected"],
        })
        write_text(sample_root / "manifest.json", json.dumps(expectation_rows[-1], indent=2) + "\n")

    manifest_buffer = io.StringIO(newline="")
    writer = csv.DictWriter(manifest_buffer, fieldnames=list(freeze_rows[0].keys()), lineterminator="\n")
    writer.writeheader()
    writer.writerows(freeze_rows)
    write_text(output_root / "WAVE1E_FREEZE_MANIFEST.csv", manifest_buffer.getvalue())
    expectations = {
        "taskId": "EMAS-MS04-ECTD4-DISCOVERY-IMPLEMENTATION",
        "fixtureSet": "Wave1E",
        "contractId": "eMAS.MS04.PreSales.ScannerObservations/1.0",
        "sourceBasis": ["ICH eCTD v4.0 IG v1.7", "FDA Regional M1 IG v1.9 and supported package v1.5.1", "EU Practical Guidance v1.0 and Validation Criteria v1.1"],
        "fixtures": expectation_rows,
    }
    write_text(output_root / "wave1e-expectations.json", json.dumps(expectations, indent=2) + "\n")
    write_text(
        output_root / "README_TEST_DATA.md",
        "# Wave 1E eCTD v4 physical-discovery fixtures\n\n"
        "These deterministic synthetic fixtures test physical RepositoryDiscovery only. "
        "Every submissionunit.xml is explicitly a discovery-only stub, not a valid regulatory message. "
        "SD-028 and SD-029 remain reserved for later content-valid regional fixtures.\n",
    )

    package_path.parent.mkdir(parents=True, exist_ok=True)
    if package_path.exists():
        package_path.unlink()
    write_package(package_path, output_root)
    print(json.dumps({
        "fixtureCount": len(scenarios),
        "outputRoot": str(output_root),
        "packagePath": str(package_path),
        "packageSha256": sha256(package_path),
        "fixtureHashes": {row["SampleId"]: row["FixtureSHA256"] for row in freeze_rows},
    }, indent=2))


if __name__ == "__main__":
    main()
