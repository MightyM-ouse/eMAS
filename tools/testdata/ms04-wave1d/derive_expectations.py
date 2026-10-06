"""Transform derivation of Wave1D expectations (derivation path 1 of 2).

Reads ONLY:
- the accepted Wave 1 expectation files under tests/fixtures/<capability>/wave1-expectations.json
  (entries for SD-002 and SD-010), and
- the declarative fixture spec (wave1d_spec.py).

It applies only the planned container/path transformation and writes
tests/fixtures/dossier-diversity/wave1d-expectations.json. It never reads a built
Wave1D fixture and never calls an eMAS capability module, so it can (and must)
run before any fixture is built.

Usage: python3 derive_expectations.py --repo-root <repo> [--out <path>]
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import wave1d_spec as spec  # noqa: E402

CAPABILITIES = [
    "repository-discovery",
    "backbone-xml-inventory",
    "reference-inventory",
    "reference-resolution",
    "missing-reference-interpretation",
    "declared-checksum-comparison",
    "checksum-mismatch-interpretation",
    "classification-evidence-collection",
]
RECORD_PROJECTION = ["evidenceType", "dimension", "strength", "sourceTier", "sequenceFolder", "xmlSequenceRelativePath", "observedValue"]
SD045_TOKENS = ["FDA", "US", "ASMF"]


def load_wave1(repo: Path) -> tuple[dict, dict]:
    data, provenance = {}, {}
    for capability in CAPABILITIES:
        path = repo / "tests" / "fixtures" / capability / "wave1-expectations.json"
        raw = path.read_bytes()
        provenance[f"tests/fixtures/{capability}/wave1-expectations.json"] = hashlib.sha256(raw).hexdigest()
        data[capability] = json.loads(raw)
    return data, provenance


def fixture_entry(wave1: dict, capability: str, sample_id: str) -> dict:
    matches = [e for e in wave1[capability]["fixtures"] if e["sampleId"] == sample_id]
    if len(matches) != 1:
        raise RuntimeError(f"{capability}: expected one {sample_id} entry, found {len(matches)}")
    return matches[0]


def reference_inventory_counts(wave1: dict, sample_id: str, sequences: list[str]) -> tuple[dict, list[dict]]:
    """Per-XML reference counts restricted to the profile's sequences.

    The accepted ReferenceInventory baseline lists per-XML counts for SD-002. SD-010 has no
    ReferenceInventory entry, but its accepted definition is "SD-002 with sequence 0001 removed",
    so its counts are the SD-002 per-XML rows for its remaining sequences. The totals are
    cross-checked against the accepted ReferenceResolution count below.
    """
    ri = wave1["reference-inventory"]
    per_xml = []
    for row in ri["baseline"]["perXml"]:
        parts = row["relativePathSuffix"].lstrip("/").split("/", 1)
        if parts[0] in sequences:
            per_xml.append({"sequenceFolder": parts[0], "xmlSequenceRelativePath": parts[1], "xmlKind": row["xmlKind"],
                            "referenceCount": row["referenceCount"], "hrefCount": row["hrefCount"]})
    counts = {
        "referenceCount": sum(r["referenceCount"] for r in per_xml),
        "hrefCount": sum(r["hrefCount"] for r in per_xml),
        "commonReferenceCount": sum(r["referenceCount"] for r in per_xml if r["xmlKind"] == "CommonBackbone"),
        "regionalReferenceCount": sum(r["referenceCount"] for r in per_xml if r["xmlKind"] == "RegionalBackbone"),
    }
    entries = [e for e in ri["fixtures"] if e["sampleId"] == sample_id]
    if entries:  # where an accepted per-fixture entry exists it must agree exactly
        for key, value in counts.items():
            assert entries[0][key] == value, (sample_id, key, entries[0][key], value)
    return counts, per_xml


def source_profile(wave1: dict, sample_id: str) -> dict:
    rd = fixture_entry(wave1, "repository-discovery", sample_id)
    ri, per_xml = reference_inventory_counts(wave1, sample_id, rd["numericSequences"])
    rr = fixture_entry(wave1, "reference-resolution", sample_id)
    assert rr["referenceCount"] == ri["referenceCount"], (sample_id, rr["referenceCount"], ri["referenceCount"])
    assert rr["resolvedPresentCount"] + rr["notApplicableCount"] + rr["resolvedAbsentCount"] + rr["unresolvedCount"] == ri["referenceCount"]
    assert rr["notApplicableCount"] == ri["referenceCount"] - ri["hrefCount"], sample_id
    mri = fixture_entry(wave1, "missing-reference-interpretation", sample_id)
    dcc = fixture_entry(wave1, "declared-checksum-comparison", sample_id)
    cmi = fixture_entry(wave1, "checksum-mismatch-interpretation", sample_id)
    cec = fixture_entry(wave1, "classification-evidence-collection", sample_id)

    # Source profiles must be clean, single-dossier, wrapper-free positives.
    assert rd["candidateRootPaths"] == [spec.WAVE1_ARCHIVE_ROOT] and rd["wrapperPaths"] == [], sample_id
    assert cec["expectedRepositoryCollectionStatus"] == "Collected" and cec["expectedCompletionStatus"] == "Completed", sample_id
    roots = [r for r in cec["records"] if r["evidenceType"] == "DossierRootPath"]
    assert len(roots) == 1 and roots[0]["observedValue"] == spec.WAVE1_ARCHIVE_ROOT, sample_id
    assert rr["resolvedAbsentCount"] == 0 and mri["expectedFindingCount"] == 0, sample_id
    assert dcc["mismatchedCount"] == 0 and cmi["expectedObservations"] == 0, sample_id

    return {
        "sequenceFolders": rd["numericSequences"],
        "xmlDocuments": [
            {"sequenceFolder": c["sequenceFolder"], "xmlSequenceRelativePath": c["xmlSequenceRelativePath"], "xmlKind": c["xmlKind"]}
            for c in cec["xmlCoverage"]
        ],
        "references": {
            "referenceCount": ri["referenceCount"],
            "hrefCount": ri["hrefCount"],
            "commonReferenceCount": ri["commonReferenceCount"],
            "regionalReferenceCount": ri["regionalReferenceCount"],
            "resolvedPresentCount": rr["resolvedPresentCount"],
            "resolvedAbsentCount": rr["resolvedAbsentCount"],
            "notApplicableCount": rr["notApplicableCount"],
            "unresolvedCount": rr["unresolvedCount"],
            "perXml": per_xml,
        },
        "checksums": {
            "matchedCount": dcc["matchedCount"],
            "mismatchedCount": dcc["mismatchedCount"],
            "notAssessedCount": dcc["notAssessedCount"],
            "notApplicableCount": dcc["notApplicableCount"],
        },
        "missingReferenceFindingCount": mri["expectedFindingCount"],
        "checksumMismatchObservationCount": cmi["expectedObservations"],
        "classificationRecords": [{k: r[k] for k in RECORD_PROJECTION} for r in cec["records"]],
    }


def transform_dossier(profile: dict, root: str, source_id: str) -> dict:
    dossier = copy.deepcopy(profile)
    for record in dossier["classificationRecords"]:
        if record["evidenceType"] == "DossierRootPath":
            record["observedValue"] = root  # the only intentional value change
    dossier["classificationRecordCount"] = len(dossier["classificationRecords"])
    return {"rootPath": root, "sourceProfile": source_id, **dossier}


def ancestors(path: str) -> list[str]:
    parts = path.split("/") if path else []
    return ["/".join(parts[:i]) for i in range(1, len(parts))]


def derive(repo: Path) -> dict:
    wave1, provenance = load_wave1(repo)
    profiles = {sample_id: source_profile(wave1, sample_id) for sample_id in spec.SOURCE_FIXTURES}
    fixtures = []
    for fixture in spec.FIXTURES:
        dossiers = [transform_dossier(profiles[source], root, source) for root, source in fixture["dossiers"]]
        roots = sorted(d["rootPath"] for d in dossiers)
        wrappers = sorted({a for root in roots for a in ancestors(root)} - set(roots))
        entry = {
            "sampleId": fixture["sampleId"],
            "kind": fixture["kind"],
            "purpose": fixture["purpose"],
            "sourceFixtures": [s for _, s in fixture["dossiers"]],
            "dossiers": dossiers,
            "negativeAssertions": {},
        }
        if fixture["kind"] == "Normative":
            entry["discovery"] = {"candidateRootPaths": roots, "wrapperPaths": wrappers}
            entry["expectedCompletionStatus"] = "Completed"
            entry["expectedRepositoryCollectionStatus"] = "Collected"
            entry["expectedRepositoryRecordCount"] = sum(d["classificationRecordCount"] for d in dossiers)
        else:
            entry["statusLabel"] = fixture["statusLabel"]
            entry["discovery"] = {"candidateRootPathsMustInclude": roots}
            entry["characterizationFile"] = "wave1d-sd051-characterization.json"
            entry["characterizationNote"] = (
                "Only the genuine dossier is normative. Additional discovery candidates produced by the current "
                "four-digit-folder heuristic are recorded as observed behaviour, not as correct regulatory dossiers."
            )

        if fixture["extraFiles"]:
            def owner(path: str) -> str | None:
                owners = [r for r in roots if r == "" or path.startswith(r + "/")]
                return max(owners, key=len) if owners else None
            if fixture["kind"] == "Normative":
                entry["negativeAssertions"]["unrelatedFiles"] = [
                    {"path": p, "expectedDossierRootPath": owner(p), "mustHaveSequence": False}
                    for p in sorted(fixture["extraFiles"])
                ]
            else:
                # Characterization: which (if any) heuristic candidate owns the file is observed
                # behaviour, not policy. Normative part: it must never belong to a genuine dossier.
                entry["negativeAssertions"]["unrelatedFiles"] = [
                    {"path": p, "mustNotBelongToDossierRootPaths": roots}
                    for p in sorted(fixture["extraFiles"])
                ]
            entry["negativeAssertions"]["unrelatedPathsMustNotProduceEvidence"] = sorted(fixture["extraFiles"])
        if fixture["sampleId"] == "SD-045":
            entry["negativeAssertions"]["folderTokensOnlyInRootContext"] = SD045_TOKENS
            entry["negativeAssertions"]["tokenNotTechnicalFormatEvidence"] = "ASMF"
        if fixture["sampleId"] == "SD-047":
            entry["negativeAssertions"]["noCrossDossierLinks"] = True
        if fixture["sampleId"] == "SD-050":
            entry["negativeAssertions"]["rootDossierPathMustBeEmpty"] = True
        if fixture["sampleId"] == "SD-049":
            entry["negativeAssertions"]["exactRootPathPreserved"] = fixture["dossiers"][0][0]
        fixtures.append(entry)

    groups = {}
    for fixture in spec.FIXTURES:
        for root, source in fixture["dossiers"]:
            groups.setdefault(source, []).append({"sampleId": fixture["sampleId"], "rootPath": root})
    invariance = [
        {"name": f"{source}-profile dossiers", "wave1Reference": source, "members": members}
        for source, members in sorted(groups.items())
    ]

    cec = wave1["classification-evidence-collection"]
    return {
        "contractId": "eMAS.MS04.PreSales.ScannerObservations/1.0",
        "taskId": "EMAS-MS04-DOSSIER-DIVERSITY-WAVE1D",
        "wave": "Wave1D (Dossier Diversity)",
        "derivation": (
            "Transform derivation (tools/testdata/ms04-wave1d/derive_expectations.py): accepted Wave 1 SD-002/SD-010 "
            "expectations with only the planned container/path change applied (DossierRootPath value = new root). "
            "Generated before any Wave1D fixture was built; confirmed independently by tools/testdata/ms04-wave1d/oracle_wave1d.py, "
            "which parses the built ZIP bytes directly without eMAS modules."
        ),
        "derivationSources": provenance,
        "recordProjection": RECORD_PROJECTION,
        "nullFields": cec["nullFields"],
        "prohibitedRecordFields": cec["prohibitedRecordFields"],
        "prohibitedCapabilities": cec["prohibitedCapabilities"],
        "prohibitedObservationCodes": sorted(
            set(cec["prohibitedObservationCodes"]) | set(wave1["checksum-mismatch-interpretation"]["prohibitedObservationCodes"])
        ),
        "findingObservationCodes": {
            "missingReference": wave1["missing-reference-interpretation"]["observationCode"],
            "checksumMismatch": wave1["checksum-mismatch-interpretation"]["observationCode"],
        },
        "fixtures": fixtures,
        "invarianceGroups": invariance,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--out")
    args = parser.parse_args()
    repo = Path(args.repo_root).resolve()
    out = Path(args.out) if args.out else repo / "tests/fixtures/dossier-diversity/wave1d-expectations.json"
    result = derive(repo)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes((json.dumps(result, indent=1) + "\n").encode("utf-8"))
    for f in result["fixtures"]:
        print(f["sampleId"], f["kind"], [(d["rootPath"], d["classificationRecordCount"], d["references"]["referenceCount"]) for d in f["dossiers"]])


if __name__ == "__main__":
    main()
