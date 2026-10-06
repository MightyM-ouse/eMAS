"""Semantic validation and fixture mutation for the eMAS XLSM/VBA POC."""
from __future__ import annotations

import copy
import json
from collections import defaultdict
from typing import Any

from emas_xlsx_poc_model import (
    ENTITY_TABLES, KEYS, RELATIONSHIP_ENDPOINTS, REQUIRED_TABLE_COLUMNS, PocIssue, build_runtime_json
)
from emas_xlsx_poc_projection import (
    LEGACY_RULE_ID_PATTERN, POC_EVALUATION_DATE, RULE_LIFECYCLE_STATUSES, project_runtime_tables,
    scan_runtime_json_for_legacy, verify_runtime_projection,
)

IDENTIFICATION = "IDENTIFICATION"
EVIDENCE_STRENGTH_PRECEDENCE = ("STRONG", "MEDIUM", "WEAK")

def canonical_json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=False) + "\n").encode("utf-8")


def validate_workbook_tables(tables: dict[str, list[dict[str, Any]]], projection_patch: dict[str, Any] | None = None) -> list[PocIssue]:
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
        elif row["OutputType"] == "ClassificationCandidate" and rules[row["RuleId"]]["RuleType"] == IDENTIFICATION:
            target_ok = True  # resolved within its declared TargetEntityType by _validate_identification
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

    _validate_lifecycle_and_legacy(tables, add)
    _validate_identification(tables, add, entity_codes)
    if not issues:
        issues.extend(validate_runtime_export(tables, projection_patch))
    return issues


def validate_runtime_export(tables: dict[str, list[dict[str, Any]]], projection_patch: dict[str, Any] | None = None, evaluation_date: str = POC_EVALUATION_DATE) -> list[PocIssue]:
    """Project, verify the projection independently and scan the serialized JSON.

    ``projection_patch`` injects an exporter fault into the projection (fixture use only) so the
    invariant checks can be proven to catch Draft leaks, ineligible rules and orphan rows."""
    projected = project_runtime_tables(tables, evaluation_date)
    if projection_patch:
        projected = apply_fixture_patch(projected, projection_patch)
    issues = verify_runtime_projection(tables, projected, evaluation_date)
    issues.extend(scan_runtime_json_for_legacy(build_runtime_json(projected), tables))
    return issues


def _codes(tables: dict[str, list[dict[str, Any]]], list_name: str) -> set[str]:
    return {str(row["Code"]) for row in tables["tblValueLists"] if row["ListName"] == list_name}


def _validate_lifecycle_and_legacy(tables: dict[str, list[dict[str, Any]]], add: Any) -> None:
    rule_ids = {str(row["RuleId"]) for row in tables["tblRules"]}
    legacy_seen: set[str] = set()
    for idx, row in enumerate(tables["tblRules"], start=1):
        if row["Status"] not in RULE_LIFECYCLE_STATUSES:
            add("POC_RULE_LIFECYCLE", "tblRules", idx, "Status", f"{row['Status']} is not a rule lifecycle status")
        if LEGACY_RULE_ID_PATTERN.match(str(row["RuleId"])):
            add("POC_LEGACY_RULE_ID_AS_RULE_ID", "tblRules", idx, "RuleId", "a historical mapping rule ID cannot be a governed runtime RuleId")
        legacy = row.get("LegacyRuleId")
        if legacy in (None, ""):
            continue
        if str(legacy) in rule_ids:
            add("POC_LEGACY_RULE_ID_AS_RULE_ID", "tblRules", idx, "LegacyRuleId", f"LegacyRuleId {legacy} is also used as a RuleId")
        if str(legacy) == str(row["RuleId"]):
            add("POC_LEGACY_RULE_ID_AS_RULE_ID", "tblRules", idx, "LegacyRuleId", "LegacyRuleId cannot substitute for RuleId")
        legacy_seen.add(str(legacy))


def _validate_identification(tables: dict[str, list[dict[str, Any]]], add: Any, entity_codes: dict[str, set[str]]) -> None:
    """Workbook-authoring Identification checks (Schema 1.1.0). The exported JSON is additionally
    validated by the independent T3a schema/semantic validator."""
    strengths = _codes(tables, "EVIDENCE_STRENGTH")
    dimensions = _codes(tables, "IDENTIFICATION_DIMENSION") & set(ENTITY_TABLES)
    rank = {code: i for i, code in enumerate(EVIDENCE_STRENGTH_PRECEDENCE)}

    def controlled(table: str, idx: int, field: str, value: Any, list_name: str) -> bool:
        if value not in _codes(tables, list_name):
            add("SEM_CONTROLLED_REFERENCE", table, idx, field, f"{value!r} does not resolve to {list_name}")
            return False
        return True

    rows = {str(r["Code"]): r for r in tables["tblValueLists"] if r["ListName"] == "EVIDENCE_STRENGTH"}
    orders = [rows[c].get("SortOrder") for c in EVIDENCE_STRENGTH_PRECEDENCE if c in rows]
    if set(rows) != set(EVIDENCE_STRENGTH_PRECEDENCE) or any(o in (None, "") for o in orders) or orders != sorted(orders) or len(set(orders)) != len(orders):
        add("SEM_ORDINAL_ORDER", "tblValueLists", 0, "SortOrder", "EVIDENCE_STRENGTH must be STRONG, MEDIUM, WEAK with unique ascending SortOrder")

    rules = {row["RuleId"]: row for row in tables["tblRules"]}
    id_rules = {rid for rid, row in rules.items() if row["RuleType"] == IDENTIFICATION}
    rule_index = {row["RuleId"]: i for i, row in enumerate(tables["tblRules"], start=1)}
    for rid in sorted(id_rules):
        controlled("tblRules", rule_index[rid], "RuleType", IDENTIFICATION, "RULE_TYPE")
        group = rules[rid].get("ConflictGroup")
        if group not in dimensions:
            add("SEM_IDENTIFICATION_DIMENSION", "tblRules", rule_index[rid], "ConflictGroup", f"{group!r} is not an approved IDENTIFICATION_DIMENSION")

    ceilings: dict[str, str] = {}
    for idx, field in enumerate(tables["tblFieldCatalogue"], start=1):
        ceiling = field.get("MaxEvidenceStrength")
        if ceiling not in (None, "") and controlled("tblFieldCatalogue", idx, "MaxEvidenceStrength", ceiling, "EVIDENCE_STRENGTH"):
            ceilings[field["FieldCode"]] = ceiling
    evidence_fields: dict[str, set[str]] = defaultdict(set)
    for row in tables["tblRuleConditions"]:
        if row["RuleId"] in id_rules and not row["Negate"]:
            evidence_fields[row["RuleId"]].add(row["FieldCode"])
    for rid, used in evidence_fields.items():
        for code in sorted(used):
            if code not in ceilings:
                add("SEM_IDENTIFICATION_METADATA_REQUIRED", "tblFieldCatalogue", 0, "MaxEvidenceStrength", f"field {code} is Identification evidence for {rid} and needs MaxEvidenceStrength")

    metadata = ("TargetEntityType", "EvidenceStrength", "EvidencePolarity")
    for idx, row in enumerate(tables["tblRuleOutputs"], start=1):
        rule = rules.get(row["RuleId"])
        if rule is None:
            continue
        candidate = rule["RuleType"] == IDENTIFICATION and row["OutputType"] == "ClassificationCandidate"
        present = [m for m in metadata if row.get(m) not in (None, "")]
        if not candidate:
            if present:
                add("SEM_IDENTIFICATION_METADATA_SCOPE", "tblRuleOutputs", idx, present[0], "Identification metadata is only valid on IDENTIFICATION ClassificationCandidate outputs")
            continue
        for m in metadata:
            if m not in present:
                add("SEM_IDENTIFICATION_METADATA_REQUIRED", "tblRuleOutputs", idx, m, f"IDENTIFICATION candidate requires {m}")
        if row.get("OutputValue") not in (None, ""):
            add("SEM_IDENTIFICATION_NUMERIC_WEIGHT", "tblRuleOutputs", idx, "OutputValue", "IDENTIFICATION candidates carry no numeric score")
        target = row.get("TargetEntityType")
        if target not in (None, ""):
            if target not in dimensions:
                add("SEM_IDENTIFICATION_DIMENSION", "tblRuleOutputs", idx, "TargetEntityType", f"{target!r} is not an approved IDENTIFICATION_DIMENSION")
            else:
                if target != rule.get("ConflictGroup"):
                    add("SEM_IDENTIFICATION_DIMENSION_MISMATCH", "tblRuleOutputs", idx, "TargetEntityType", f"{target} differs from ConflictGroup {rule.get('ConflictGroup')}")
                if row["OutputCode"] not in entity_codes.get(target, set()):
                    add("SEM_OUTPUT_TARGET", "tblRuleOutputs", idx, "OutputCode", f"{row['OutputCode']} does not exist in {target}")
        if row.get("EvidencePolarity") not in (None, ""):
            controlled("tblRuleOutputs", idx, "EvidencePolarity", row["EvidencePolarity"], "EVIDENCE_POLARITY")
        strength = row.get("EvidenceStrength")
        if strength in (None, "") or not controlled("tblRuleOutputs", idx, "EvidenceStrength", strength, "EVIDENCE_STRENGTH"):
            continue
        used = evidence_fields.get(row["RuleId"], set())
        capped = [ceilings[c] for c in used if c in ceilings and ceilings[c] in rank]
        if not used:
            add("SEM_EVIDENCE_STRENGTH_CEILING", "tblRuleOutputs", idx, "EvidenceStrength", "rule has no positive evidence field")
        elif capped and strength in rank and rank[strength] < max(rank[c] for c in capped):
            add("SEM_EVIDENCE_STRENGTH_CEILING", "tblRuleOutputs", idx, "EvidenceStrength", f"{strength} exceeds the evidence-field ceiling")

    for idx, row in enumerate(tables["tblConflictPolicies"], start=1):
        floor = row.get("MinimumEvidenceStrengthForValue")
        if row["RuleType"] == IDENTIFICATION:
            controlled("tblConflictPolicies", idx, "RuleType", IDENTIFICATION, "RULE_TYPE")
            controlled("tblConflictPolicies", idx, "TieBehavior", row["TieBehavior"], "TIE_BEHAVIOR")
            if floor not in (None, ""):
                controlled("tblConflictPolicies", idx, "MinimumEvidenceStrengthForValue", floor, "EVIDENCE_STRENGTH")
        elif floor not in (None, ""):
            add("SEM_IDENTIFICATION_METADATA_SCOPE", "tblConflictPolicies", idx, "MinimumEvidenceStrengthForValue", "only valid on IDENTIFICATION conflict policies")

    for idx, row in enumerate(tables["tblConfidencePolicies"], start=1):
        ordinal = [k for k in ("ResultConfidence", "CorroborationRule") if row.get(k) not in (None, "")]
        if row["Scope"] != IDENTIFICATION:
            if ordinal:
                add("SEM_IDENTIFICATION_METADATA_SCOPE", "tblConfidencePolicies", idx, ordinal[0], "only valid on IDENTIFICATION confidence policies")
            if row.get("WeightOrScore") in (None, ""):
                add("SEM_IDENTIFICATION_METADATA_REQUIRED", "tblConfidencePolicies", idx, "WeightOrScore", "non-Identification confidence rows keep the mandatory numeric weight")
            continue
        controlled("tblConfidencePolicies", idx, "EvidenceStrength", row["EvidenceStrength"], "EVIDENCE_STRENGTH")
        for key, list_name in (("ResultConfidence", "CONFIDENCE"), ("CorroborationRule", "CORROBORATION_RULE")):
            if row.get(key) in (None, ""):
                add("SEM_IDENTIFICATION_METADATA_REQUIRED", "tblConfidencePolicies", idx, key, f"IDENTIFICATION confidence requires {key}")
            else:
                controlled("tblConfidencePolicies", idx, key, row[key], list_name)
        if row.get("WeightOrScore") not in (None, ""):
            add("SEM_IDENTIFICATION_NUMERIC_WEIGHT", "tblConfidencePolicies", idx, "WeightOrScore", "numeric Identification confidence weights are not approved")


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
