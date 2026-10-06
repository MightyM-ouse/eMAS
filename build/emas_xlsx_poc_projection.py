"""Runtime-eligibility projection for the synthetic eMAS XLSM/VBA POC (Schema 1.1.0).

One projection is used for every Runtime JSON export, DEV and CONTROLLED alike:

    Status = Effective AND EffectiveFrom <= evaluation date
    AND (EffectiveTo is empty OR evaluation date < EffectiveTo)

A rule that is not runtime eligible is removed together with its whole dependent graph:
rule phases, condition groups, conditions, outputs and RULE_SUPERSESSION relationships that
reference it. Workbook-only columns (LegacyRuleId) are removed from the projected rows.

`verify_runtime_projection` is written independently of `project_runtime_tables` so that a
faulty exporter (including the VBA exporter) is detected by invariant checks rather than by
re-running the same filter.
"""
from __future__ import annotations

import copy
import re
from typing import Any, Iterable

from emas_xlsx_poc_model import WORKBOOK_ONLY_COLUMNS, PocIssue

RULE_LIFECYCLE_STATUSES = ("Draft", "InReview", "Reviewed", "Effective", "Superseded", "Retired")
RUNTIME_STATUS = "Effective"
NEVER_EXECUTABLE_STATUSES = frozenset({"Draft", "InReview"})
# Deterministic POC evaluation date: the date part of the fixed POC export timestamp.
POC_EVALUATION_DATE = "2026-07-13"
# Rule-graph tables keyed by RuleId.
RULE_DEPENDENT_TABLES = ("tblRulePhaseAssignments", "tblConditionGroups", "tblRuleConditions", "tblRuleOutputs")
# Historical T3c rule-ID pattern. A runtime RuleId must never reuse a legacy identity.
LEGACY_RULE_ID_PATTERN = re.compile(r"^R-(REG|FMT|TYP)-\d{2}$")


def _iso_date(value: Any) -> str:
    return str(value or "").strip()[:10]


def is_runtime_eligible(rule: dict[str, Any], evaluation_date: str) -> bool:
    if rule.get("Status") != RUNTIME_STATUS:
        return False
    start = _iso_date(rule.get("EffectiveFrom"))
    end = _iso_date(rule.get("EffectiveTo"))
    if not start or start > evaluation_date:
        return False
    return not end or evaluation_date < end


def project_runtime_tables(tables: dict[str, list[dict[str, Any]]], evaluation_date: str = POC_EVALUATION_DATE) -> dict[str, list[dict[str, Any]]]:
    projected = copy.deepcopy(tables)
    eligible = {row["RuleId"] for row in tables["tblRules"] if is_runtime_eligible(row, evaluation_date)}
    projected["tblRules"] = [
        {k: v for k, v in row.items() if k not in WORKBOOK_ONLY_COLUMNS["tblRules"]}
        for row in projected["tblRules"] if row["RuleId"] in eligible
    ]
    for table in RULE_DEPENDENT_TABLES:
        projected[table] = [row for row in projected[table] if row["RuleId"] in eligible]
    projected["tblMasterDataRelationships"] = [
        row for row in projected["tblMasterDataRelationships"]
        if row["RelationshipType"] != "RULE_SUPERSESSION" or (row["SourceEntityCode"] in eligible and row["TargetEntityCode"] in eligible)
    ]
    return projected


def verify_runtime_projection(source: dict[str, list[dict[str, Any]]], projected: dict[str, list[dict[str, Any]]], evaluation_date: str = POC_EVALUATION_DATE) -> list[PocIssue]:
    """Independent invariant checks over a runtime projection."""
    issues: list[PocIssue] = []
    source_rules = {row["RuleId"]: row for row in source["tblRules"]}
    projected_ids: set[str] = set()
    for idx, row in enumerate(projected["tblRules"], start=1):
        rule_id = row.get("RuleId")
        projected_ids.add(rule_id)
        authored = source_rules.get(rule_id, row)
        status = authored.get("Status")
        if status in NEVER_EXECUTABLE_STATUSES:
            issues.append(PocIssue("POC_PROJECTION_DRAFT_LEAK", "tblRules", idx, "Status", f"{status} rule {rule_id} entered the runtime projection"))
        elif not is_runtime_eligible(authored, evaluation_date):
            issues.append(PocIssue("POC_PROJECTION_INELIGIBLE", "tblRules", idx, "Status", f"rule {rule_id} ({status}, {authored.get('EffectiveFrom')}..{authored.get('EffectiveTo') or ''}) is not runtime eligible on {evaluation_date}"))
        for column in WORKBOOK_ONLY_COLUMNS["tblRules"]:
            if row.get(column) not in (None, ""):
                issues.append(PocIssue("POC_LEGACY_RULE_ID_EXPORTED", "tblRules", idx, column, f"workbook-only {column} is present in the runtime projection"))
    for rule_id, authored in source_rules.items():
        if is_runtime_eligible(authored, evaluation_date) and rule_id not in projected_ids:
            issues.append(PocIssue("POC_PROJECTION_INELIGIBLE", "tblRules", 0, "RuleId", f"runtime-eligible rule {rule_id} is missing from the projection"))
    for table in RULE_DEPENDENT_TABLES:
        for idx, row in enumerate(projected[table], start=1):
            if row.get("RuleId") not in projected_ids:
                issues.append(PocIssue("POC_PROJECTION_ORPHAN", table, idx, "RuleId", f"row belongs to rule {row.get('RuleId')} that is not in the runtime projection"))
    group_ids = {row["ConditionGroupId"] for row in projected["tblConditionGroups"]}
    for idx, row in enumerate(projected["tblRuleConditions"], start=1):
        if row.get("ConditionGroupId") not in group_ids:
            issues.append(PocIssue("POC_PROJECTION_ORPHAN", "tblRuleConditions", idx, "ConditionGroupId", f"condition group {row.get('ConditionGroupId')} is not in the runtime projection"))
    for idx, row in enumerate(projected["tblMasterDataRelationships"], start=1):
        if row.get("RelationshipType") == "RULE_SUPERSESSION":
            for side in ("SourceEntityCode", "TargetEntityCode"):
                if row.get(side) not in projected_ids:
                    issues.append(PocIssue("POC_PROJECTION_ORPHAN", "tblMasterDataRelationships", idx, side, f"supersession references rule {row.get(side)} outside the runtime projection"))
    # Runtime policy references into the rule graph must stay resolvable after projection.
    for idx, row in enumerate(projected.get("tblDecisionPolicies", []), start=1):
        if row.get("RequiredConditionType") == "CONDITION_GROUP" and row.get("RequiredConditionReference") not in group_ids:
            issues.append(PocIssue("POC_PROJECTION_ORPHAN", "tblDecisionPolicies", idx, "RequiredConditionReference", "condition group is not in the runtime projection"))
    for idx, row in enumerate(projected.get("tblFindingRecommendationLinks", []), start=1):
        reference = row.get("ApplicabilityConditionReference")
        if reference and reference in {r["ConditionGroupId"] for r in source["tblConditionGroups"]} and reference not in group_ids:
            issues.append(PocIssue("POC_PROJECTION_ORPHAN", "tblFindingRecommendationLinks", idx, "ApplicabilityConditionReference", "condition group is not in the runtime projection"))
    return issues


def _strings(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, child in value.items():
            yield f"key:{key}"
            yield from _strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from _strings(child)
    elif isinstance(value, str):
        yield value


def scan_runtime_json_for_legacy(runtime_json: Any, source: dict[str, list[dict[str, Any]]]) -> list[PocIssue]:
    """LegacyRuleId must not appear in Runtime JSON, neither as a property nor as any serialized value."""
    legacy_values = {str(row["LegacyRuleId"]) for row in source["tblRules"] if row.get("LegacyRuleId") not in (None, "")}
    issues: list[PocIssue] = []
    for text in _strings(runtime_json):
        if text.lower() == "key:legacyruleid":
            issues.append(PocIssue("POC_LEGACY_RULE_ID_EXPORTED", "RuntimeJson", 0, "legacyRuleId", "workbook-only LegacyRuleId property was serialized"))
        elif any(value and value in text for value in legacy_values):
            issues.append(PocIssue("POC_LEGACY_RULE_ID_EXPORTED", "RuntimeJson", 0, "", f"a LegacyRuleId value was serialized in {text!r}"))
    return issues
