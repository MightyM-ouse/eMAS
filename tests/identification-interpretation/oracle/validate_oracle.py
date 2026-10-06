#!/usr/bin/env python3
"""Static validation of the T4a IdentificationInterpretation oracle package.

This checks the fixture package itself: structure, contract IDs, references, ordering and
forbidden fields. It deliberately does NOT evaluate rules or recompute expected results;
it is not a second Identification engine.
"""
from __future__ import annotations

import hashlib
import json
import re
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
FAILURE_CODES = {"IDI-INPUT-001", "IDI-INPUT-002", "IDI-INPUT-003", "IDI-INPUT-004",
                 "IDI-CONFIG-001", "IDI-CONFIG-002", "IDI-CONFIG-003", "IDI-CONFIG-004", "IDI-CONFIG-005", "IDI-CONFIG-006"}
CENTRAL_DECISIONS = {f"B-{i}" for i in range(1, 8)}
CONTRACT = REPO / "docs" / "internal" / "agent-tasks" / "EMAS-MS04-IDENTIFICATION-INTERPRETATION-ORACLE" / "BEHAVIOR_CONTRACT.md"


def _pattern_conditions(cfg: dict[str, Any]) -> list[dict[str, Any]]:
    id_rules = {r["ruleId"] for r in cfg["rules"] if r["ruleType"] == "IDENTIFICATION"}
    return [c for c in cfg["ruleConditions"] if c["ruleId"] in id_rules and c["operator"] == "MATCHES_PATTERN"]


def _python_regex_ok(pattern: str) -> bool:
    """Sanity approximation only (Python re, not .NET); used to keep fixture intent unambiguous."""
    try:
        re.compile(pattern)
        return True
    except re.error:
        return False


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
    failure = entry.get("expectation") == "Failure"
    if entry.get("expectation") not in ("Output", "Failure"):
        errors.append(f"{cid}: expectation must be Output or Failure")
    expected_name = "expected-failure.json" if failure else "expected-identification.json"
    other_name = "expected-identification.json" if failure else "expected-failure.json"
    files = {name: folder / name for name in ("scanner-observations.json", "runtime-config.json", expected_name)}
    for name, path in files.items():
        if not path.is_file():
            errors.append(f"{cid}: missing {name}")
    if (folder / other_name).exists():
        errors.append(f"{cid}: {other_name} must not exist for a {entry.get('expectation')} case")
    if errors:
        return errors
    obs, cfg, exp = (load(files[n]) for n in files)
    e = lambda msg: errors.append(f"{cid}: {msg}")  # noqa: E731
    unknown_decisions = set(entry.get("centralDecisions", [])) - CENTRAL_DECISIONS
    if unknown_decisions:
        e(f"unknown central decisions {sorted(unknown_decisions)}")
    contract_text = CONTRACT.read_text(encoding="utf-8")
    for clause in entry.get("decisions", []):
        if not re.search(rf"\b{re.escape(clause)}\b", contract_text):
            e(f"clause {clause} is not defined in the behavioral contract")

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

    patterns = _pattern_conditions(cfg)
    for c in patterns:
        if c.get("valueDataType") != "String" or not isinstance(c.get("value1"), str) or not isinstance(c.get("caseSensitive"), bool):
            e(f"MATCHES_PATTERN condition {c['conditionId']} must have a String value1/valueDataType and a boolean caseSensitive")

    if failure:
        expected_failure = exp.get("ExpectedFailure", {})
        if set(exp) != {"ExpectedFailure"} or set(expected_failure) != {"ErrorCode", "RuleId", "ConditionId", "OutputDocument"}:
            e("expected-failure.json must contain exactly ExpectedFailure{ErrorCode, RuleId, ConditionId, OutputDocument}")
            return errors
        if expected_failure["ErrorCode"] not in FAILURE_CODES:
            e(f"failure code {expected_failure['ErrorCode']} is not a stable contract code")
        if expected_failure["OutputDocument"] is not None:
            e("a failure case must expect no output document")
        condition = next((c for c in cfg["ruleConditions"] if c["conditionId"] == expected_failure["ConditionId"]), None)
        if condition is None or condition["ruleId"] != expected_failure["RuleId"]:
            e("failure ConditionId/RuleId do not identify a condition of that rule in the runtime config")
        elif expected_failure["ErrorCode"] == "IDI-CONFIG-005":
            if condition["operator"] != "MATCHES_PATTERN":
                e("IDI-CONFIG-005 must point at a MATCHES_PATTERN condition")
            elif _python_regex_ok(condition["value1"]):
                e("IDI-CONFIG-005 fixture pattern must be syntactically invalid")
        return errors
    for c in patterns:
        if isinstance(c.get("value1"), str) and not _python_regex_ok(c["value1"]):
            e(f"MATCHES_PATTERN condition {c['conditionId']} in an Output case must be a valid pattern")

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
    if not any(c.get("expectation") == "Failure" for c in manifest["cases"]):
        errors.append("manifest must contain at least one Failure case")
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
