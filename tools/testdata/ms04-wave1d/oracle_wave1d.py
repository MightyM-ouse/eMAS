"""Independent structural oracle for Wave1D (derivation path 2 of 2).

Derives every fact directly from fixture ZIP bytes with Python's zipfile,
xml.etree and hashlib. It does NOT import wave1d_spec.py, does NOT read
eMAS scanner output and does NOT call any eMAS capability module.

Rules applied (the accepted, documented MS-04 conventions):
- dossier candidate: any directory (including the archive root "") with at least one
  child directory named exactly NNNN (four digits); candidates located inside another
  candidate's sequence folder are dropped. Wrappers are non-candidate ancestors.
- backbone documents per sequence: <seq>/index.xml (CommonBackbone) and
  <seq>/m1/eu/eu-regional.xml (RegionalBackbone).
- references: unqualified <leaf> elements; href from the xlink namespace
  http://www.w3c.org/1999/xlink, resolved relative to the XML's folder inside its own dossier.
- checksum: declared MD5 compared with MD5 of the resolved target bytes.
- classification-evidence record mapping: same type table as the accepted Wave 1 CEC oracle.

Usage:
  python3 oracle_wave1d.py calibrate --wave1-root <Wave1Root> --repo-root <repo>
  python3 oracle_wave1d.py check --corpus <BuildDirOrPackageRoot> --expectations <wave1d-expectations.json> --out <report.json>
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import posixpath
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

XLINK_HREF = "{http://www.w3c.org/1999/xlink}href"
SEQUENCE = re.compile(r"^\d{4}$")
DOCTYPE = re.compile(r'<!DOCTYPE\s+([^\s\[>]+)(?:\s+(?:PUBLIC\s+"([^"]*)"\s+"([^"]*)"|SYSTEM\s+"([^"]*)"))?', re.S)
TYPE_SPEC = {
    "DossierRootPath": ({"*": "DossierContext"}, "Weak", "FolderNameHeuristic"),
    "SequenceFolder": ({"*": "TechnicalFormat"}, "Weak", "PackageStructure"),
    "CtdModuleFolders": ({"*": "TechnicalFormat"}, "Weak", "PackageStructure"),
    "Module1RegionalFolder": ({"*": "Region"}, "Supporting", "OfficialPhysicalPath"),
    "CommonBackbonePresence": ({"*": "TechnicalFormat"}, "Supporting", "OfficialPhysicalPath"),
    "RegionalBackbonePresence": ({"*": "Region"}, "Supporting", "OfficialPhysicalPath"),
    "CommonBackbonePath": ({"*": "TechnicalFormat"}, "Supporting", "OfficialPhysicalPath"),
    "RegionalBackbonePath": ({"*": "Region"}, "Supporting", "OfficialPhysicalPath"),
    "XmlRootElement": ({"CommonBackbone": "TechnicalFormat", "RegionalBackbone": "Region"}, "Strong", "StructuredXml"),
    "XmlNamespace": ({"CommonBackbone": "TechnicalFormat", "RegionalBackbone": "Region"}, "Strong", "StructuredXml"),
    "DtdVersion": ({"*": "SpecificationProfile"}, "Strong", "StructuredXml"),
    "DocumentTypeName": ({"CommonBackbone": "TechnicalFormat", "RegionalBackbone": "Region"}, "Supporting", "BackboneDeclaration"),
    "DtdSystemIdentifier": ({"*": "SpecificationProfile"}, "Supporting", "BackboneDeclaration"),
    "DtdPublicIdentifier": ({"*": "SpecificationProfile"}, "Supporting", "BackboneDeclaration"),
}
BACKBONES = [("CommonBackbone", "index.xml"), ("RegionalBackbone", "m1/eu/eu-regional.xml")]


def child_dirs(dirs: set[str], parent: str) -> list[str]:
    prefix = "" if parent == "" else parent + "/"
    return sorted({d[len(prefix):] for d in dirs if d.startswith(prefix) and d != parent and "/" not in d[len(prefix):]})


def join(root: str, rel: str) -> str:
    return rel if root == "" else f"{root}/{rel}"


def xml_facts(raw: bytes) -> tuple[str, dict]:
    try:
        root = ET.fromstring(raw)
    except ET.ParseError:
        return "ParseFailed", {}
    tag, ns, local = root.tag, "", root.tag
    if tag.startswith("{"):
        ns, local = tag[1:].split("}", 1)
    facts = {"XmlRootElement": local, "XmlNamespace": ns}
    if "dtd-version" in root.attrib:
        facts["DtdVersion"] = root.attrib["dtd-version"]
    match = DOCTYPE.search(raw.decode("utf-8", "replace"))
    if match:
        facts["DocumentTypeName"] = match.group(1)
        if match.group(2):
            facts["DtdPublicIdentifier"] = match.group(2)
        system_id = match.group(3) or match.group(4)
        if system_id:
            facts["DtdSystemIdentifier"] = system_id
    return "Parsed", facts


def analyse_zip(path: Path) -> dict:
    with zipfile.ZipFile(path) as archive:
        files = {i.filename: archive.read(i) for i in archive.infolist() if not i.is_dir()}
        explicit_dirs = {i.filename.rstrip("/") for i in archive.infolist() if i.is_dir()}
    dirs = set(explicit_dirs)
    for name in files:
        parts = name.split("/")[:-1]
        dirs.update("/".join(parts[:i]) for i in range(1, len(parts) + 1))
    dirs.add("")

    raw_candidates = sorted(d for d in dirs if any(SEQUENCE.match(c) for c in child_dirs(dirs, d)))
    candidates = []
    for cand in raw_candidates:
        inside_sequence = any(
            cand.startswith(join(other, seq) + "/") or cand == join(other, seq)
            for other in raw_candidates if other != cand
            for seq in child_dirs(dirs, other) if SEQUENCE.match(seq)
        )
        if not inside_sequence:
            candidates.append(cand)
    ancestors = {"/".join(c.split("/")[:i]) for c in candidates if c for i in range(1, len(c.split("/")))}
    wrappers = sorted(ancestors - set(candidates))

    def owner(file_path: str) -> str | None:
        owners = [c for c in candidates if c == "" or file_path.startswith(c + "/")]
        return max(owners, key=len) if owners else None

    dossiers = []
    for root in candidates:
        own_files = {p: b for p, b in files.items() if owner(p) == root}
        sequences = [s for s in child_dirs(dirs, root) if SEQUENCE.match(s)]
        records, xml_docs, per_xml = [], [], []
        refs = collections.Counter()
        checks = collections.Counter()
        records.append(("DossierRootPath", None, None, root))
        for seq in sequences:
            seq_path = join(root, seq)
            records.append(("SequenceFolder", seq, None, seq))
            kids = child_dirs(dirs, seq_path)
            records.append(("CtdModuleFolders", seq, None, sorted(k for k in kids if re.fullmatch(r"m[1-5]", k))))
            if "m1" in kids:
                records.append(("Module1RegionalFolder", seq, None, child_dirs(dirs, seq_path + "/m1")))
            for kind, rel in BACKBONES:
                full = f"{seq_path}/{rel}"
                prefix = "Common" if kind == "CommonBackbone" else "Regional"
                present = full in own_files
                status, facts = ("Missing", {}) if not present else xml_facts(own_files[full])
                xml_docs.append({"sequenceFolder": seq, "xmlSequenceRelativePath": rel, "xmlKind": kind, "status": status})
                records.append((prefix + "BackbonePresence", seq, rel, present))
                if present:
                    records.append((prefix + "BackbonePath", seq, rel, rel))
                for key in ["XmlRootElement", "XmlNamespace", "DtdVersion", "DocumentTypeName", "DtdSystemIdentifier", "DtdPublicIdentifier"]:
                    if key in facts:
                        records.append((key, seq, rel, facts[key]))
                if status != "Parsed":
                    continue
                leaves = [e for e in ET.fromstring(own_files[full]).iter() if e.tag == "leaf"]
                per_xml.append({"sequenceFolder": seq, "xmlSequenceRelativePath": rel, "xmlKind": kind,
                                "referenceCount": len(leaves), "hrefCount": sum(1 for e in leaves if e.get(XLINK_HREF) is not None)})
                xml_dir = posixpath.dirname(f"{seq}/{rel}")
                for leaf in leaves:
                    refs["referenceCount"] += 1
                    refs["commonReferenceCount" if kind == "CommonBackbone" else "regionalReferenceCount"] += 1
                    href = leaf.get(XLINK_HREF)
                    if href is None:
                        refs["notApplicableCount"] += 1
                        checks["notApplicableCount"] += 1
                        continue
                    refs["hrefCount"] += 1
                    target_rel = posixpath.normpath(posixpath.join(xml_dir, href))
                    if target_rel.startswith("..") or "%" in href or ":" in href or "\\" in href:
                        refs["unresolvedCount"] += 1
                        checks["notAssessedCount"] += 1
                        continue
                    target = join(root, target_rel)
                    if target not in own_files:
                        refs["resolvedAbsentCount"] += 1
                        checks["notAssessedCount"] += 1
                        continue
                    refs["resolvedPresentCount"] += 1
                    declared = leaf.get("checksum")
                    if not declared or (leaf.get("checksum-type") or "").lower() != "md5":
                        checks["notAssessedCount"] += 1
                    elif hashlib.md5(own_files[target]).hexdigest() == declared.lower():
                        checks["matchedCount"] += 1
                    else:
                        checks["mismatchedCount"] += 1

        def dim(r):
            mapping = TYPE_SPEC[r[0]][0]
            return mapping.get("*") or mapping["CommonBackbone" if r[2] == "index.xml" else "RegionalBackbone"]

        record_dicts = [{"evidenceType": r[0], "dimension": dim(r), "strength": TYPE_SPEC[r[0]][1], "sourceTier": TYPE_SPEC[r[0]][2],
                         "sequenceFolder": r[1], "xmlSequenceRelativePath": r[2], "observedValue": r[3]} for r in records]
        for key in ["referenceCount", "hrefCount", "commonReferenceCount", "regionalReferenceCount",
                    "resolvedPresentCount", "resolvedAbsentCount", "notApplicableCount", "unresolvedCount"]:
            refs.setdefault(key, 0)
        for key in ["matchedCount", "mismatchedCount", "notAssessedCount", "notApplicableCount"]:
            checks.setdefault(key, 0)
        dossiers.append({
            "rootPath": root,
            "sequenceFolders": sequences,
            "xmlDocuments": xml_docs,
            "references": {**dict(refs), "perXml": per_xml},
            "checksums": dict(checks),
            "missingReferenceFindingCount": refs["resolvedAbsentCount"],
            "checksumMismatchObservationCount": checks["mismatchedCount"],
            "classificationRecords": record_dicts,
        })
    return {
        "zipSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "candidateRootPaths": candidates,
        "wrapperPaths": wrappers,
        "fileOwners": {p: owner(p) for p in sorted(files)},
        "xmlFilesOutsideDossiers": sorted(p for p in files if p.endswith(".xml") and owner(p) is None),
        "dossiers": dossiers,
    }


def canon(records: list[dict]) -> collections.Counter:
    return collections.Counter(json.dumps(r, sort_keys=True) for r in records)


def record_diff(expected: list[dict], actual: list[dict]) -> list[str]:
    e, a = canon(expected), canon(actual)
    return [f"missing {k}" for k in (e - a)] + [f"unexpected {k}" for k in (a - e)]


def compare_dossier(sample: str, exp: dict, got: dict) -> list[str]:
    problems = []
    if exp["sequenceFolders"] != got["sequenceFolders"]:
        problems.append(f"{sample}/{exp['rootPath']!r}: sequences {exp['sequenceFolders']} != {got['sequenceFolders']}")
    exp_xml = sorted((x["sequenceFolder"], x["xmlSequenceRelativePath"], x["xmlKind"]) for x in exp["xmlDocuments"])
    got_xml = sorted((x["sequenceFolder"], x["xmlSequenceRelativePath"], x["xmlKind"]) for x in got["xmlDocuments"] if x["status"] == "Parsed")
    if exp_xml != got_xml:
        problems.append(f"{sample}/{exp['rootPath']!r}: parsed backbone XML set differs")
    for key, value in exp["references"].items():
        if key == "perXml":
            if sorted(map(json.dumps, value)) != sorted(map(json.dumps, got["references"]["perXml"])):
                problems.append(f"{sample}/{exp['rootPath']!r}: per-XML reference counts differ")
        elif got["references"].get(key) != value:
            problems.append(f"{sample}/{exp['rootPath']!r}: references.{key} {value} != {got['references'].get(key)}")
    for key, value in exp["checksums"].items():
        if got["checksums"].get(key) != value:
            problems.append(f"{sample}/{exp['rootPath']!r}: checksums.{key} {value} != {got['checksums'].get(key)}")
    for key in ("missingReferenceFindingCount", "checksumMismatchObservationCount"):
        if exp[key] != got[key]:
            problems.append(f"{sample}/{exp['rootPath']!r}: {key} {exp[key]} != {got[key]}")
    problems += [f"{sample}/{exp['rootPath']!r}: CEC {d}" for d in record_diff(exp["classificationRecords"], got["classificationRecords"])]
    return problems


def command_check(args: argparse.Namespace) -> None:
    corpus = Path(args.corpus).resolve()
    expectations = json.loads(Path(args.expectations).read_text(encoding="utf-8"))
    report = {"oracle": "tools/testdata/ms04-wave1d/oracle_wave1d.py", "fixtures": [], "problems": []}
    for fixture in expectations["fixtures"]:
        sample = fixture["sampleId"]
        result = analyse_zip(corpus / "fixtures" / sample / "fixture.zip")
        problems = []
        disc = fixture["discovery"]
        if "candidateRootPaths" in disc:
            if disc["candidateRootPaths"] != result["candidateRootPaths"]:
                problems.append(f"{sample}: candidates {disc['candidateRootPaths']} != {result['candidateRootPaths']}")
            if disc["wrapperPaths"] != result["wrapperPaths"]:
                problems.append(f"{sample}: wrappers {disc['wrapperPaths']} != {result['wrapperPaths']}")
        else:
            missing = [p for p in disc["candidateRootPathsMustInclude"] if p not in result["candidateRootPaths"]]
            if missing:
                problems.append(f"{sample}: genuine dossier(s) not discoverable: {missing}")
        by_root = {d["rootPath"]: d for d in result["dossiers"]}
        for exp in fixture["dossiers"]:
            if exp["rootPath"] not in by_root:
                problems.append(f"{sample}: dossier {exp['rootPath']!r} not derived")
                continue
            problems += compare_dossier(sample, exp, by_root[exp["rootPath"]])
        negative = fixture.get("negativeAssertions", {})
        for item in negative.get("unrelatedFiles", []):
            if item["path"] not in result["fileOwners"]:
                problems.append(f"{sample}: unrelated file {item['path']} absent from ZIP")
            elif "mustNotBelongToDossierRootPaths" in item:
                if result["fileOwners"][item["path"]] in item["mustNotBelongToDossierRootPaths"]:
                    problems.append(f"{sample}: {item['path']} owned by genuine dossier {result['fileOwners'][item['path']]!r}")
            elif result["fileOwners"].get(item["path"], "<absent>") != item["expectedDossierRootPath"]:
                problems.append(f"{sample}: owner of {item['path']} {result['fileOwners'].get(item['path'], '<absent>')!r} != {item['expectedDossierRootPath']!r}")
        for token in negative.get("folderTokensOnlyInRootContext", []):
            for d in result["dossiers"]:
                for r in d["classificationRecords"]:
                    if r["evidenceType"] != "DossierRootPath" and token in json.dumps(r["observedValue"]):
                        problems.append(f"{sample}: token {token} found in source {r['evidenceType']} value")
        extra = [d for d in result["dossiers"] if d["rootPath"] not in {e["rootPath"] for e in fixture["dossiers"]}]
        report["fixtures"].append({
            "sampleId": sample,
            "kind": fixture["kind"],
            "zipSha256": result["zipSha256"],
            "candidateRootPaths": result["candidateRootPaths"],
            "wrapperPaths": result["wrapperPaths"],
            "xmlFilesOutsideDossiers": result["xmlFilesOutsideDossiers"],
            "dossierRecordCounts": {d["rootPath"]: len(d["classificationRecords"]) for d in result["dossiers"]},
            "additionalCandidatesPredicted": [
                {"rootPath": d["rootPath"], "sequenceFolders": d["sequenceFolders"],
                 "classificationRecords": d["classificationRecords"],
                 "backboneStatus": d["xmlDocuments"]} for d in extra
            ],
            "result": "AGREE" if not problems else "DISAGREE",
            "problems": problems,
        })
        report["problems"] += problems
        print(f"{sample}: {'AGREE' if not problems else 'DISAGREE'} candidates={result['candidateRootPaths']} "
              f"records={ {d['rootPath']: len(d['classificationRecords']) for d in result['dossiers']} }")
        for p in problems:
            print("   ", p)
    report["overall"] = "AGREE" if not report["problems"] else "BLOCKED_EXPECTATION_DISAGREEMENT"
    Path(args.out).write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")
    print("overall:", report["overall"])
    sys.exit(0 if not report["problems"] else 1)


def command_calibrate(args: argparse.Namespace) -> None:
    """Prove the oracle reproduces accepted Wave 1 expectations for the source profiles."""
    wave1 = Path(args.wave1_root).resolve()
    repo = Path(args.repo_root).resolve()
    cec = json.loads((repo / "tests/fixtures/classification-evidence-collection/wave1-expectations.json").read_text())
    rr = json.loads((repo / "tests/fixtures/reference-resolution/wave1-expectations.json").read_text())
    dcc = json.loads((repo / "tests/fixtures/declared-checksum-comparison/wave1-expectations.json").read_text())
    rd = json.loads((repo / "tests/fixtures/repository-discovery/wave1-expectations.json").read_text())
    failures = 0
    for sample in args.samples:
        result = analyse_zip(wave1 / "fixtures" / sample / "fixture.zip")
        get = lambda doc: next(e for e in doc["fixtures"] if e["sampleId"] == sample)  # noqa: E731
        problems = []
        if result["candidateRootPaths"] != get(rd)["candidateRootPaths"] or result["wrapperPaths"] != get(rd)["wrapperPaths"]:
            problems.append(f"discovery {result['candidateRootPaths']} / {result['wrapperPaths']}")
        if len(result["dossiers"]) == 1:
            d = result["dossiers"][0]
            problems += record_diff([{k: r[k] for k in d["classificationRecords"][0]} for r in get(cec)["records"]], d["classificationRecords"])
            for key in ("referenceCount", "resolvedPresentCount", "resolvedAbsentCount", "notApplicableCount"):
                if d["references"][key] != get(rr)[key]:
                    problems.append(f"{key} {d['references'][key]} != {get(rr)[key]}")
            for key in ("matchedCount", "mismatchedCount"):
                if d["checksums"][key] != get(dcc)[key]:
                    problems.append(f"{key} {d['checksums'][key]} != {get(dcc)[key]}")
        else:
            total = sum(len(d["classificationRecords"]) for d in result["dossiers"])
            if total != get(cec)["expectedRecordCount"]:
                problems.append(f"record total {total} != {get(cec)['expectedRecordCount']}")
        failures += bool(problems)
        print(f"calibrate {sample}: {'MATCH' if not problems else 'DIFF'} {problems[:5]}")
    sys.exit(1 if failures else 0)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    cal = sub.add_parser("calibrate")
    cal.add_argument("--wave1-root", required=True)
    cal.add_argument("--repo-root", required=True)
    cal.add_argument("--samples", nargs="+", default=["SD-002", "SD-010"])
    chk = sub.add_parser("check")
    chk.add_argument("--corpus", required=True)
    chk.add_argument("--expectations", required=True)
    chk.add_argument("--out", required=True)
    args = parser.parse_args()
    {"calibrate": command_calibrate, "check": command_check}[args.command](args)


if __name__ == "__main__":
    main()
