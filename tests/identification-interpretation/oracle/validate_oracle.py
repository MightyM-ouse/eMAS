#!/usr/bin/env python3
"""Static validation of the T4a IdentificationInterpretation oracle package.

This checks the fixture package itself: structure, contract IDs, references, ordering and
forbidden fields. It deliberately does NOT evaluate rules or recompute expected results;
it is not a second Identification engine.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ORACLE = Path(__file__).resolve().parent
REPO = ORACLE.parents[2]
sys.path.insert(0, str(REPO / "build"))

from jsonschema import Draft202012Validator  # noqa: E402

import validate_emas_schema as RUNTIME  # noqa: E402

SCANNER_CONTRACT = "eMAS.MS04.PreSales.ScannerObservations/1.0"
OUTPUT_CONTRACT = "eMAS.MS04.PreSales.Identification/1.0"
NORMALIZATION = {"Strong": "STRONG", "Supporting": "MEDIUM", "Weak": "WEAK"}
STRENGTH_ORDER = {"STRONG": 0, "MEDIUM": 1, "WEAK": 2, None: 3}
MASTER = {"REGION": ("regions", "regionCode"), "AUTHORITY": ("authorities", "authorityCode"),
          "TECHNICAL_STANDARD": ("technicalStandards", "technicalStandardCode"),
          "REGIONAL_IMPLEMENTATION": ("regionalImplementations", "regionalImplementationCode"),
          "PRODUCT_DOMAIN": ("productDomains", "productDomainCode"), "LIFECYCLE_CONTEXT": ("lifecycleContexts", "lifecycleContextCode"),
          "PRODUCT_CLASS": ("productClasses", "productClassCode"), "PROCEDURE_CONTEXT": ("procedureContexts", "procedureContextCode"),
          "SOURCE_PRESENTATION": ("sourcePresentations", "sourcePresentationCode")}
FORBIDDEN_KEYS = {"Outcome", "SupportStatus", "NumericScore", "Score", "Weight", "WeightOrScore", "OutputValue", "Projections", "Probable"}
# The only numeric values allowed in an expected document are ordinal ranks and counts.
NUMERIC_ALLOWED_KEYS = {"TierRank", "STRONG", "MEDIUM", "WEAK", "IndependentSourceClassCount"}
VOLATILE = ("EngineVersion", "StartedAtUtc", "CompletedAtUtc")


def load(path: Path) -> Any:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raise ValueError(f"{path}: UTF-8 BOM is not allowed")
    return json.loads(raw.decode("utf-8"))


def _walk(value: Any, path: str = "$"):
    if isinstance(value, dict):
        for key, child in value.items():
            yield path, key, child
            yield from _walk(child, f"{path}.{key}")
    elif isinstance(value, list):
        for i, child in enumerate(value):
            yield from _walk(child, f"{path}[{i}]")


def _sorted_unique(values: list[str]) -> bool:
    return values == sorted(set(values))


def validate_case(entry: dict[str, Any], schema_validator: Draft202012Validator, runtime_schema: Any, runtime_registry: Any) -> list[str]:
    errors: list[str] = []
    cid = entry["id"]
    folder = ORACLE / entry["path"]
    files = {name: folder / name for name in ("scanner-observations.json", "runtime-config.json", "expected-identification.json")}
    for name, path in files.items():
        if not path.is_file():
            errors.append(f"{cid}: missing {name}")
    if errors:
        return errors
    obs, cfg, exp = (load(files[n]) for n in files)
    e = lambda msg: errors.append(f"{cid}: {msg}")  # noqa: E731

    # Input contracts
    if obs.get("ContractId") != SCANNER_CONTRACT or obs["Execution"].get("ContractId") != SCANNER_CONTRACT:
        e("scanner input does not declare ScannerObservations/1.0")
    if obs["Execution"].get("Phase") != "PreSales" or obs["Execution"].get("ScenarioId") != "MS-04":
        e("scanner input is not MS-04 PreSales")
    if "ClassificationEvidenceCollection" not in obs["Execution"].get("Capabilities", []):
        e("scanner input lacks ClassificationEvidenceCollection")
    if cfg["configuration"].get("schemaVersion") != "1.1.0":
        e("runtime config is not Schema 1.1.0")
    runtime_issues = RUNTIME.validate_instance(runtime_schema, cfg, runtime_registry)
    for issue in runtime_issues:
        e(f"runtime config invalid: {issue.render()}")

    # Output contract shape (frozen JSON Schema) and forbidden content
    for err in schema_validator.iter_errors(exp):
        e(f"expected output violates Identification/1.0 schema at {list(err.absolute_path)}: {err.message}")
    for path, key, value in _walk(exp):
        if key in FORBIDDEN_KEYS:
            e(f"forbidden field {key} at {path}")
        if isinstance(value, (int, float)) and not isinstance(value, bool) and key not in NUMERIC_ALLOWED_KEYS:
            e(f"numeric value at {path}.{key} is not an ordinal rank or count")

    # Provenance integrity
    if exp["EvidenceSource"]["DocumentSha256"] != hashlib.sha256(files["scanner-observations.json"].read_bytes()).hexdigest():
        e("EvidenceSource.DocumentSha256 does not match the scanner input")
    if exp["RuntimeConfig"]["Sha256"] != hashlib.sha256(files["runtime-config.json"].read_bytes()).hexdigest():
        e("RuntimeConfig.Sha256 does not match the runtime config")
    if exp["RuntimeConfig"]["ConfigurationId"] != cfg["configuration"]["configurationId"]:
        e("RuntimeConfig.ConfigurationId mismatch")
    if exp["EvidenceSource"]["ExecutionId"] != obs["Execution"]["ExecutionId"] or exp["Execution"]["ExecutionId"] != obs["Execution"]["ExecutionId"]:
        e("ExecutionId does not link to the scanner input")
    for key in VOLATILE:
        if exp["Execution"].get(key) is not None:
            e(f"volatile field Execution.{key} must be null in the oracle")

    # Reference integrity
    evidence = {r["EvidenceId"]: r for r in obs["ClassificationEvidence"]}
    sequences = {s["SequenceId"]: s for s in obs["Sequences"]}
    rules = {r["ruleId"]: r for r in cfg["rules"] if r["ruleType"] == "IDENTIFICATION"}
    outputs = {o["ruleId"]: o for o in cfg["ruleOutputs"] if o["ruleId"] in rules}
    dims = sorted(cfg["valueLists"]["IDENTIFICATION_DIMENSION"], key=lambda r: (r.get("sortOrder", 0), r["code"]))
    dim_order = {r["code"]: i for i, r in enumerate(dims)}
    fields = {f["fieldCode"] for f in cfg["fieldCatalogue"]}

    expected_keys = []
    for i, res in enumerate(exp["Results"], start=1):
        where = res["IdentificationId"]
        if res["IdentificationId"] != f"IDR-{i:04d}":
            e(f"{where}: IdentificationIds must be sequential IDR-0001..")
        if res["Dimension"] not in dim_order:
            e(f"{where}: Dimension {res['Dimension']} is not in IDENTIFICATION_DIMENSION")
        seq = sequences.get(res["SubjectId"])
        if seq is None:
            e(f"{where}: SubjectId {res['SubjectId']} is not a scanner Sequence")
        elif seq["DossierId"] != res["DossierId"]:
            e(f"{where}: DossierId does not match the scanner Sequence")
        expected_keys.append((res["SubjectId"], dim_order.get(res["Dimension"], 99)))
        collection, key = MASTER[res["Dimension"]]
        codes = {row[key] for row in cfg["masterData"][collection]}
        values = [c["Value"] for c in res["Candidates"]]
        if res["Value"] is not None and res["Value"] not in values:
            e(f"{where}: Value is not one of the candidates")
        order = [(STRENGTH_ORDER[c["BestSupportStrength"]], c["Value"]) for c in res["Candidates"]]
        if order != sorted(order) or len(set(values)) != len(values):
            e(f"{where}: candidates must be unique and ordered by support strength then Value")
        cited_support, cited_contra = set(), set()
        for c in res["Candidates"]:
            if c["Value"] not in codes:
                e(f"{where}: candidate {c['Value']} does not exist in {res['Dimension']} master data")
            for ids_key in ("SupportingRuleIds", "ContradictingRuleIds"):
                if not _sorted_unique(c[ids_key]):
                    e(f"{where}: {ids_key} must be sorted and unique")
                polarity = "SUPPORTS" if ids_key == "SupportingRuleIds" else "CONTRADICTS"
                for rid in c[ids_key]:
                    out = outputs.get(rid)
                    if out is None:
                        e(f"{where}: rule {rid} is not an IDENTIFICATION rule in the runtime config")
                    elif (out["targetEntityType"], out["outputCode"], out["evidencePolarity"]) != (res["Dimension"], c["Value"], polarity):
                        e(f"{where}: rule {rid} does not output {polarity} {res['Dimension']}/{c['Value']}")
            for ev_key, bucket in (("SupportingEvidence", cited_support), ("ContradictingEvidence", cited_contra)):
                ids = [x["EvidenceId"] for x in c[ev_key]]
                if not _sorted_unique(ids):
                    e(f"{where}: {ev_key} must be ordered by EvidenceId and unique")
                for item in c[ev_key]:
                    record = evidence.get(item["EvidenceId"])
                    if record is None:
                        e(f"{where}: cited {item['EvidenceId']} does not exist in the scanner input")
                        continue
                    if item["RawStrength"] != record["Strength"] or item["SourceTier"] != record["SourceTier"]:
                        e(f"{where}: cited {item['EvidenceId']} raw strength/tier differs from the immutable CEC record")
                    if NORMALIZATION.get(item["RawStrength"]) != item["NormalizedStrength"]:
                        e(f"{where}: cited {item['EvidenceId']} normalization differs from EVIDENCE-STRENGTH-NORMALIZATION/1")
                    if record.get("SequenceId") not in (None, res["SubjectId"]):
                        e(f"{where}: cited {item['EvidenceId']} belongs to another subject")
                    bucket.add(item["EvidenceId"])
        if res["SupportingEvidenceIds"] != sorted(cited_support) or res["ContradictingEvidenceIds"] != sorted(cited_contra):
            e(f"{where}: result evidence ID lists must be the sorted union of candidate citations")
        fired = {rid for c in res["Candidates"] for rid in c["SupportingRuleIds"] + c["ContradictingRuleIds"]}
        if res["FiredRuleIds"] != sorted(fired):
            e(f"{where}: FiredRuleIds must be the sorted union of candidate rule IDs")
        for item in res["UnavailableEvidence"]:
            if item["FieldCode"] not in fields:
                e(f"{where}: unavailable FieldCode {item['FieldCode']} is not in the field catalogue")
            if item["EvidenceId"] is not None and item["EvidenceId"] not in evidence:
                e(f"{where}: unavailable {item['EvidenceId']} does not exist in the scanner input")
        ua_order = [(u["FieldCode"], u["EvidenceId"] or "") for u in res["UnavailableEvidence"]]
        if ua_order != sorted(ua_order):
            e(f"{where}: UnavailableEvidence must be ordered by FieldCode then EvidenceId")
        if not _sorted_unique(res["LimitingFactors"]):
            e(f"{where}: LimitingFactors must be sorted and unique")
        summary = res["ScoreSummary"]
        best = summary["BestStrength"]
        tops = [c["BestSupportStrength"] for c in res["Candidates"] if c["BestSupportStrength"]]
        if best != (min(tops, key=STRENGTH_ORDER.get) if tops else None):
            e(f"{where}: ScoreSummary.BestStrength must equal the best candidate support strength")
        # Accepted floor and v4 invariants (structural assertions, not rule evaluation)
        if res["EvaluationStatus"] == "Evaluated" and STRENGTH_ORDER[best] > STRENGTH_ORDER["MEDIUM"]:
            e(f"{where}: Evaluated below the MEDIUM final-value floor")
        if res["EvaluationStatus"] == "Evaluated" and best == "STRONG" and res["ReviewRequired"] and "LowerTierContradiction" not in res["LimitingFactors"]:
            e(f"{where}: STRONG Evaluated result without contradiction must not require review")
        if res["EvaluationStatus"] == "Evaluated" and best == "MEDIUM" and not res["ReviewRequired"]:
            e(f"{where}: MEDIUM-best Evaluated result requires review")
        if res["Value"] == "ECTD_4_0" and (best == "STRONG" or res["Confidence"] == "HIGH"):
            e(f"{where}: physical v4 marker evidence may not yield STRONG/HIGH v4")
    if expected_keys != sorted(expected_keys):
        e("Results must be ordered by SubjectId then IDENTIFICATION_DIMENSION order")
    return errors


def strip_volatile(document: Any) -> Any:
    document = json.loads(json.dumps(document))
    document["EvidenceSource"].pop("DocumentSha256", None)
    return document


def validate_package() -> list[str]:
    manifest = load(ORACLE / "manifest.json")
    schema = load(ORACLE / "identification-1.0.schema.json")
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    runtime_schema_path = REPO / "config" / "schema" / "eMAS-runtime-config.schema.json"
    runtime_schema = RUNTIME.load_json(runtime_schema_path)
    registry = RUNTIME.build_schema_registry(runtime_schema_path)
    errors: list[str] = []
    ids = [c["id"] for c in manifest["cases"]]
    if ids != sorted(set(ids)):
        errors.append("manifest case IDs must be unique and ordered")
    on_disk = sorted(p.name for p in (ORACLE / "cases").iterdir() if p.is_dir())
    if on_disk != ids:
        errors.append(f"case folders {on_disk} differ from manifest {ids}")
    if manifest.get("outputContractId") != OUTPUT_CONTRACT or manifest.get("inputContractId") != SCANNER_CONTRACT:
        errors.append("manifest contract IDs are wrong")
    for entry in manifest["cases"]:
        errors.extend(validate_case(entry, validator, runtime_schema, registry))
        if "equivalentTo" in entry:
            this = strip_volatile(load(ORACLE / entry["path"] / "expected-identification.json"))
            other = strip_volatile(load(ORACLE / "cases" / entry["equivalentTo"] / "expected-identification.json"))
            if this != other:
                errors.append(f"{entry['id']}: expected output must equal {entry['equivalentTo']} apart from the input document hash")
            a = load(ORACLE / entry["path"] / "scanner-observations.json")
            b = load(ORACLE / "cases" / entry["equivalentTo"] / "scanner-observations.json")
            key = lambda r: json.dumps(r, sort_keys=True)  # noqa: E731
            if sorted(a["ClassificationEvidence"], key=key) != sorted(b["ClassificationEvidence"], key=key) or a["ClassificationEvidence"] == b["ClassificationEvidence"]:
                errors.append(f"{entry['id']}: must contain the same evidence as {entry['equivalentTo']} in a different order")
    return errors


def main() -> int:
    errors = validate_package()
    manifest = load(ORACLE / "manifest.json")
    for error in errors:
        print(f"[FAIL] {error}")
    if errors:
        return 1
    print(f"Identification oracle static validation passed: {len(manifest['cases'])} cases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
