"""Semantic validation and fixture mutation for the eMAS XLSM/VBA POC."""
from __future__ import annotations

import copy
import json
from collections import defaultdict
from typing import Any

from emas_xlsx_poc_model import (
    ENTITY_TABLES, KEYS, RELATIONSHIP_ENDPOINTS, REQUIRED_TABLE_COLUMNS, PocIssue
)

def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=False) + "\n").encode("utf-8")


def validate_workbook_tables(tables: dict[str, list[dict[str, Any]]]) -> list[PocIssue]:
    issues: list[PocIssue] = []
    def add(code: str, table: str, row: int, field: str, message: str) -> None:
        issues.append(PocIssue(code, table, row, field, message))

    for table, columns in REQUIRED_TABLE_COLUMNS.items():
        if table not in tables:
            add("POC_REQUIRED_TABLE", table, 0, "", "required table is missing")
            continue
        actual = set(tables[table][0].keys()) if tables[table] else set(columns)
        for column in columns:
            if column not in actual:
                add("POC_REQUIRED_COLUMN", table, 0, column, "required column is missing")
    if issues:
        return issues

    for table, key in KEYS.items():
        seen: set[str] = set()
        for idx, row in enumerate(tables.get(table, []), start=1):
            value = str(row.get(key, ""))
            if value in seen:
                add("SEM_DUPLICATE_ID", table, idx, key, f"duplicate identifier {value}")
            seen.add(value)

    fields = {row["FieldCode"]: row for row in tables["tblFieldCatalogue"]}
    allowed = defaultdict(set)
    for row in tables["tblFieldAllowedOperators"]:
        allowed[row["FieldCode"]].add(row["Operator"])
    groups = {row["ConditionGroupId"]: row for row in tables["tblConditionGroups"]}
    rules = {row["RuleId"]: row for row in tables["tblRules"]}
    for idx, row in enumerate(tables["tblRuleConditions"], start=1):
        if row["RuleId"] not in rules:
            add("SEM_BROKEN_REFERENCE", "tblRuleConditions", idx, "RuleId", "rule does not exist")
        if row["ConditionGroupId"] not in groups:
            add("SEM_BROKEN_REFERENCE", "tblRuleConditions", idx, "ConditionGroupId", "condition group does not exist")
        if row["FieldCode"] not in fields:
            add("SEM_BROKEN_REFERENCE", "tblRuleConditions", idx, "FieldCode", "field does not exist")
        elif row["Operator"] not in allowed[row["FieldCode"]]:
            add("SEM_OPERATOR_NOT_ALLOWED", "tblRuleConditions", idx, "Operator", "operator is not allowed for the field")

    entity_codes = {etype: {row[key] for row in tables[table]} for etype, (table, key) in ENTITY_TABLES.items()}
    for idx, row in enumerate(tables["tblMasterDataRelationships"], start=1):
        expected = RELATIONSHIP_ENDPOINTS.get(row["RelationshipType"])
        actual = (row["SourceEntityType"], row["TargetEntityType"])
        if expected != actual:
            add("SEM_RELATIONSHIP_ENDPOINT", "tblMasterDataRelationships", idx, "RelationshipType", f"expected {expected}, received {actual}")
        for side in ("Source", "Target"):
            etype, code = row[f"{side}EntityType"], row[f"{side}EntityCode"]
            if etype == "RULE":
                exists = code in rules
            else:
                exists = code in entity_codes.get(etype, set())
            if not exists:
                add("SEM_BROKEN_REFERENCE", "tblMasterDataRelationships", idx, f"{side}EntityCode", f"{etype} code {code} does not exist")

    findings = {row["FindingCode"]: row for row in tables["tblFindings"]}
    recommendations = {row["RecommendationCode"]: row for row in tables["tblRecommendations"]}
    for idx, row in enumerate(tables["tblFindingRecommendationLinks"], start=1):
        if row["FindingCode"] not in findings:
            add("SEM_BROKEN_REFERENCE", "tblFindingRecommendationLinks", idx, "FindingCode", "finding does not exist")
        if row["RecommendationCode"] not in recommendations:
            add("SEM_BROKEN_REFERENCE", "tblFindingRecommendationLinks", idx, "RecommendationCode", "recommendation does not exist")
    for idx, row in enumerate(tables["tblExceptionPolicies"], start=1):
        finding = findings.get(row["EligibleFindingCode"])
        if finding is None:
            add("SEM_BROKEN_REFERENCE", "tblExceptionPolicies", idx, "EligibleFindingCode", "finding does not exist")
        elif not finding["ExceptionEligible"]:
            add("SEM_EXCEPTION_INELIGIBLE", "tblExceptionPolicies", idx, "EligibleFindingCode", "finding is not exception eligible")

    master_codes = {code for codes in entity_codes.values() for code in codes}
    rag_codes = {row["Code"] for row in tables["tblValueLists"] if row["ListName"] == "RAG"}
    question_codes = {row["QuestionCode"] for row in tables["tblQuestionnaireMap"]}
    for idx, row in enumerate(tables["tblRuleOutputs"], start=1):
        if row["RuleId"] not in rules:
            add("SEM_BROKEN_REFERENCE", "tblRuleOutputs", idx, "RuleId", "rule does not exist")
            continue
        target_ok = True
        if row["OutputType"] == "Finding":
            target_ok = row["OutputCode"] in findings
        elif row["OutputType"] == "ClassificationCandidate":
            target_ok = row["OutputCode"] in master_codes
        elif row["OutputType"] == "RAG":
            target_ok = str(row["OutputCode"]).upper() in rag_codes
        elif row["OutputType"] == "ClarificationTrigger":
            target_ok = row["OutputCode"] in question_codes
        if not target_ok:
            add("SEM_OUTPUT_TARGET", "tblRuleOutputs", idx, "OutputCode", "output target does not resolve")

    grouped = defaultdict(list)
    for idx, row in enumerate(tables["tblEffortThresholds"], start=1):
        grouped[(row["ThresholdScopeType"], row["ThresholdScopeCode"], row["Unit"])].append((idx, row))
    for key, rows in grouped.items():
        rows.sort(key=lambda x: float("-inf") if x[1]["LowerBound"] in ("", None) else float(x[1]["LowerBound"]))
        for (prev_idx, prev), (cur_idx, cur) in zip(rows, rows[1:]):
            prev_upper = prev["UpperBound"]
            cur_lower = cur["LowerBound"]
            if prev_upper in ("", None) or cur_lower in ("", None):
                add("SEM_THRESHOLD_OVERLAP", "tblEffortThresholds", cur_idx, "LowerBound", f"open-ended previous band overlaps for {key}")
                continue
            if float(cur_lower) < float(prev_upper) or (float(cur_lower) == float(prev_upper) and prev["UpperInclusive"] and cur["LowerInclusive"]):
                add("SEM_THRESHOLD_OVERLAP", "tblEffortThresholds", cur_idx, "LowerBound", f"band overlaps previous band for {key}")

    phases_by_rule = defaultdict(set)
    for row in tables["tblRulePhaseAssignments"]:
        phases_by_rule[row["RuleId"]].add(row["Phase"])
    groups_by_rule = defaultdict(int)
    for row in tables["tblConditionGroups"]:
        groups_by_rule[row["RuleId"]] += 1
    outputs_by_rule = defaultdict(int)
    for row in tables["tblRuleOutputs"]:
        outputs_by_rule[row["RuleId"]] += 1
    for rule_id in rules:
        if not phases_by_rule[rule_id] or not groups_by_rule[rule_id] or not outputs_by_rule[rule_id]:
            add("SEM_RULE_INCOMPLETE", "tblRules", 0, "RuleId", f"rule {rule_id} lacks phase, group or output")

    return issues


def apply_fixture_patch(tables: dict[str, list[dict[str, Any]]], patch: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    result = copy.deepcopy(tables)
    for operation in patch.get("operations", []):
        table = operation["table"]
        action = operation["action"]
        if action == "append":
            result[table].append(copy.deepcopy(operation["row"]))
        elif action == "duplicate":
            key_field = operation["keyField"]
            key_value = operation["keyValue"]
            target = next((row for row in result[table] if row.get(key_field) == key_value), None)
            if target is None:
                raise KeyError(f"{table} {key_field}={key_value}")
            result[table].append(copy.deepcopy(target))
        elif action == "set":
            key_field = operation["keyField"]
            key_value = operation["keyValue"]
            target = next((row for row in result[table] if row.get(key_field) == key_value), None)
            if target is None:
                raise KeyError(f"{table} {key_field}={key_value}")
            target[operation["field"]] = operation["value"]
        elif action == "delete":
            key_field = operation["keyField"]
            key_value = operation["keyValue"]
            result[table] = [row for row in result[table] if row.get(key_field) != key_value]
        else:
            raise ValueError(f"Unsupported fixture action {action}")
    return result
