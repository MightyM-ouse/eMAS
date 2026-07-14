#!/usr/bin/env python3
"""eMAS report-redesign v3.2 adapter for the shared OpenXML population engine.

The adapter preserves the established mapping-driven workbook writer while applying
report-template map version 2.0.0, controlled template version 1.2.0 and the
phase-specific normalized result schemas introduced by Enterprise Requirements v3.2.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

import emas_report_openxml as engine

SUPPORTED_MAPPING_VERSION = "2.0.0"
REQUIRED_TEMPLATE_VERSION = "1.2.0"
SUPPORTED_RESULT_CONTRACT_VERSION = "1.0.0"

# The shared writer intentionally keeps its constants module-scoped. Override them
# once here so every validation path inside the existing engine applies v3.2.
engine.SUPPORTED_MAPPING_VERSION = SUPPORTED_MAPPING_VERSION
engine.REQUIRED_TEMPLATE_VERSION = REQUIRED_TEMPLATE_VERSION


def _resolve_result_schema_path(
    mapping_path: Path,
    mapping: dict[str, Any],
    explicit_path: Path | None,
) -> Path:
    if explicit_path is not None:
        candidate = explicit_path
    else:
        configured = mapping.get("resultSchemaPath")
        if not configured:
            raise engine.ReportError(
                engine.finding(
                    "RPT-RESULT-SCHEMA-002",
                    "The report mapping does not declare resultSchemaPath.",
                    phase=mapping.get("phaseCode"),
                    evidence=str(mapping_path),
                )
            )
        candidate = Path(configured)
        if not candidate.is_absolute():
            repository_root = Path(__file__).resolve().parents[2]
            candidate = repository_root / candidate

    if not candidate.is_file():
        raise engine.ReportError(
            engine.finding(
                "RPT-RESULT-SCHEMA-003",
                "The normalized result schema file was not found.",
                phase=mapping.get("phaseCode"),
                evidence=str(candidate),
            )
        )
    return candidate.resolve()


def _validate_result_schema(
    result: dict[str, Any],
    result_schema: dict[str, Any],
    mapping: dict[str, Any],
) -> None:
    if engine.Draft202012Validator is None:
        raise engine.ReportError(
            engine.finding(
                "RPT-VALIDATE-001",
                "The repository jsonschema dependency is required to validate the normalized result object.",
                phase=mapping.get("phaseCode"),
            )
        )

    validator = engine.Draft202012Validator(result_schema)
    errors = sorted(validator.iter_errors(result), key=lambda item: list(item.path))
    if errors:
        issue = errors[0]
        raise engine.ReportError(
            engine.finding(
                "RPT-RESULT-SCHEMA-001",
                "Normalized result JSON does not conform to the phase result schema.",
                phase=mapping.get("phaseCode"),
                evidence={"path": list(issue.path), "detail": issue.message},
            )
        )

    actual_version = result.get("resultContractVersion")
    if actual_version != SUPPORTED_RESULT_CONTRACT_VERSION:
        raise engine.ReportError(
            engine.finding(
                "RPT-RESULT-SCHEMA-004",
                "Unsupported normalized result contract version.",
                phase=mapping.get("phaseCode"),
                evidence={
                    "expected": SUPPORTED_RESULT_CONTRACT_VERSION,
                    "actual": actual_version,
                },
            )
        )


def _validate_contract_identity_v32(
    result: dict[str, Any],
    mapping: dict[str, Any],
    control: dict[str, str],
) -> None:
    phase = mapping["phaseCode"]
    if result.get("phaseCode") != phase:
        raise engine.ReportError(
            engine.finding(
                "RPT-RESULT-002",
                "Result phase does not match mapping phase.",
                phase=phase,
                evidence={"expected": phase, "actual": result.get("phaseCode")},
            )
        )

    if mapping.get("mappingVersion") != SUPPORTED_MAPPING_VERSION:
        raise engine.ReportError(
            engine.finding(
                "RPT-MAP-002",
                "Unsupported template mapping version.",
                phase=phase,
                evidence=mapping.get("mappingVersion"),
            )
        )

    template = mapping["template"]
    if template.get("templateVersion") != REQUIRED_TEMPLATE_VERSION:
        raise engine.ReportError(
            engine.finding(
                "RPT-TEMPLATE-005",
                "Mapping does not target controlled template version 1.2.0.",
                phase=phase,
                evidence=template.get("templateVersion"),
            )
        )

    expected_control = {
        "TemplateId": template["templateId"],
        "TemplateVersion": REQUIRED_TEMPLATE_VERSION,
        "PhaseCode": phase,
    }
    for key, expected in expected_control.items():
        actual = control.get(key)
        if actual != expected:
            raise engine.ReportError(
                engine.finding(
                    "RPT-TEMPLATE-006",
                    "Workbook Template Control metadata does not match the selected report mapping.",
                    phase=phase,
                    evidence={"property": key, "expected": expected, "actual": actual},
                )
            )


# The v3.2 result schema deliberately excludes workbook binding identity fields such
# as mappingId/templateId/templateVersion. Binding identity comes from the selected
# mapping and the controlled workbook metadata, not from business-result payloads.
engine.validate_contract_identity = _validate_contract_identity_v32


def _derive_final_result(result: dict[str, Any]) -> Any:
    if result.get("finalResult") not in (None, ""):
        return result.get("finalResult")

    preferred_keys = (
        "finalResult",
        "readinessResult",
        "verificationResult",
        "decision",
        "result",
        "value",
    )
    for collection_name in (
        "readinessDecision",
        "reviewAndExecution",
        "executiveMetrics",
        "summaryMetrics",
    ):
        collection = result.get(collection_name)
        if not isinstance(collection, list):
            continue
        for record in collection:
            if not isinstance(record, dict):
                continue
            for key in preferred_keys:
                value = record.get(key)
                if value not in (None, ""):
                    return value
    return None


def export_report_v32(
    result_path: Path,
    mapping_path: Path,
    mapping_schema_path: Path,
    template_path: Path,
    output_path: Path,
    log_path: Path,
    result_schema_path: Path | None = None,
) -> dict[str, Any]:
    started = time.monotonic()
    log = engine.ExecutionLog(log_path)
    mapping: dict[str, Any] = {}
    resolved_result_schema: Path | None = None

    try:
        result = engine.load_json(result_path, "RPT-RESULT-001", "Normalized result JSON")
        mapping = engine.load_json(mapping_path, "RPT-MAP-004", "Template mapping JSON")
        mapping_schema = engine.load_json(
            mapping_schema_path,
            "RPT-MAP-005",
            "Template mapping schema",
        )
        engine.validate_mapping(mapping, mapping_schema)
        resolved_result_schema = _resolve_result_schema_path(
            mapping_path,
            mapping,
            result_schema_path,
        )
        result_schema = engine.load_json(
            resolved_result_schema,
            "RPT-RESULT-SCHEMA-003",
            "Normalized result schema",
        )
        _validate_result_schema(result, result_schema, mapping)
        log.write(
            "Validating normalized result",
            "Phase result schema validation passed",
            phase=mapping.get("phaseCode"),
            resultContractVersion=result.get("resultContractVersion"),
            resultSchema=str(resolved_result_schema),
        )
    except engine.ReportError as exc:
        log.write(
            "Failed",
            exc.issue["Message"],
            code=exc.issue["Code"],
            evidence=exc.issue.get("Evidence"),
        )
        return {
            "Status": "Failed",
            "Phase": mapping.get("phaseCode"),
            "OutputWorkbookPath": str(output_path.resolve()),
            "ExecutionLogPath": str(log_path.resolve()),
            "DurationSeconds": round(time.monotonic() - started, 3),
            "Validation": {
                "OverallStatus": "Invalid",
                "BlockingIssueCount": 1,
                "Findings": [exc.issue],
            },
        }

    response = engine.export_report(
        result_path,
        mapping_path,
        mapping_schema_path,
        template_path,
        output_path,
        log_path,
    )
    response["ResultSchemaPath"] = str(resolved_result_schema)
    response["ResultContractVersion"] = result.get("resultContractVersion")
    if response.get("Status") == "Passed":
        response["FinalResult"] = _derive_final_result(result)
    return response


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--result", required=True, type=Path)
    parser.add_argument("--result-schema", type=Path)
    parser.add_argument("--mapping", required=True, type=Path)
    parser.add_argument("--mapping-schema", required=True, type=Path)
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    arguments = parser.parse_args(argv)

    response = export_report_v32(
        arguments.result,
        arguments.mapping,
        arguments.mapping_schema,
        arguments.template,
        arguments.output,
        arguments.log,
        arguments.result_schema,
    )
    print(json.dumps(response, ensure_ascii=False, separators=(",", ":")))
    return 0 if response["Status"] == "Passed" else 1


if __name__ == "__main__":
    sys.exit(main())
