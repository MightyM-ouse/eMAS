"""Deterministic synthetic result-object factory for report-redesign v3.2 tests.

The generated records exercise structural report binding only. They contain no
customer data, regulatory decisions, effort rates or production evidence.
"""

from __future__ import annotations

from collections import defaultdict
from typing import Any


CONTROLLED_VALUES = {
    "YesNo": "No",
    "RAG": "Green",
    "Confidence": "High",
    "EvaluationStatus": "Evaluated",
    "ValueSource": "Derived",
    "Priority": "Low",
    "Severity": "Low",
    "WorkflowStatus": "Open",
    "ReadinessResult": "Ready",
    "VerificationResult": "Reconciled",
    "ReconciliationStatus": "Matched",
    "ReviewerDisposition": "Confirmed Match",
}


def _placeholder(column: dict[str, Any], index: int) -> Any:
    controlled = column.get("controlledValueList")
    if controlled in CONTROLLED_VALUES:
        return CONTROLLED_VALUES[controlled]

    data_type = str(column.get("dataType") or "String").lower()
    source = str(column.get("sourceField") or "value")

    if data_type in {"integer", "number", "decimal", "double"}:
        return index
    if data_type in {"boolean", "bool"}:
        return True
    if data_type == "date":
        return "2026-07-14"
    if data_type in {"datetime", "timestamp"}:
        return "2026-07-14T12:00:00Z"
    if "checksum" in source.lower() or "sha256" in source.lower():
        return "A" * 64
    if "path" in source.lower() or "location" in source.lower():
        return f"C:\\Synthetic\\Evidence\\Item-{index:03d}"
    if data_type in {"identifier", "id"} or source.lower().endswith("id"):
        return f"SYN-{index:03d}"
    if data_type in {"code", "enum"}:
        return "Information"
    return f"Synthetic {source} {index}"


def _required_default(name: str, definition: dict[str, Any], phase: str) -> Any:
    if "const" in definition:
        return definition["const"]
    if "enum" in definition:
        return definition["enum"][0]

    value_type = definition.get("type")
    if value_type == "array":
        return []
    if value_type == "object":
        return {}
    if value_type == "boolean":
        return False
    if value_type in {"integer", "number"}:
        return 0
    if name == "resultContractVersion":
        return "1.0.0"
    if name == "phaseCode":
        return phase
    return f"Synthetic {name}"


def build_minimal_result(
    phase: str,
    mapping: dict[str, Any],
    result_schema: dict[str, Any],
) -> dict[str, Any]:
    """Build one structurally valid result object for a mapping/schema pair."""

    properties = result_schema.get("properties", {})
    required = result_schema.get("required", [])
    result: dict[str, Any] = {
        name: _required_default(name, properties.get(name, {}), phase)
        for name in required
    }

    # The workbook writer may access optional mapped collections. Initialise every
    # schema property with a safe neutral value so a mapping can evolve without
    # making the fixture brittle.
    for name, definition in properties.items():
        if name not in result:
            result[name] = _required_default(name, definition, phase)

    grouped_targets: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for target in mapping.get("tableMappings", []):
        source = target.get("sourceCollection")
        if source:
            grouped_targets[source].append(target)

    record_index = 1
    for source, targets in grouped_targets.items():
        definition = properties.get(source)
        if not definition:
            # Release-managed/control collections are not business-result fields.
            continue

        active_targets = [
            target
            for target in targets
            if target.get("writeMode")
            not in {"matchRowByLabelColumns", "staticReleaseManaged"}
        ]
        if not active_targets:
            continue

        record: dict[str, Any] = {}
        for target in active_targets:
            for column in target.get("columns", []):
                source_field = column.get("sourceField")
                if source_field and source_field not in record:
                    record[source_field] = _placeholder(column, record_index)
                    record_index += 1

        if definition.get("type") == "object":
            result[source] = record
        else:
            result[source] = [record]

    result["phaseCode"] = phase
    result["resultContractVersion"] = "1.0.0"
    return result
