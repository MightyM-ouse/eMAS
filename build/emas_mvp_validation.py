"""Structural and semantic checks for the v4.4 MVP workbook model."""
from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass

from emas_mvp_model import GENERATED, PHASES, SHEETS, columns, modules, scenarios


@dataclass(frozen=True)
class Issue:
    severity: str
    code: str
    sheet: str
    record: str
    column: str
    message: str
    why: str
    correction: str
    blocking: bool = True


KEYS = {
    "01_Migration_Scenarios": "ScenarioId", "02_Scenario_Questionnaire": "QuestionId",
    "04_Assessment_Modules": "ModuleId", "05_Scenario_Module_Map": "ScenarioModuleMapId",
    "06_Requirement_Catalogue": "RequirementId", "07_Fields_Evidence": "FieldCode",
    "08_Regulatory_Profiles": "ProfileId", "13_Size_Volume_Metrics": "MetricCode",
    "14_Source_DB_Archive_DMS": "MappingRuleId", "15_RAG_Severity": "RagRuleId",
    "16_Confidence": "ConfidenceRuleId", "17_Effort_Drivers": "EffortDriverId",
    "18_Findings": "FindingCode", "19_Recommendations_Actions": "RecommendationCode",
    "20_PreMigration_Readiness": "ReadinessRuleId",
    "21_PostMigration_Reconciliation": "ReconciliationRuleId",
    "23_Source_References": "SourceId", "25_JSON_Field_Map": "MappingId",
}


def validate_model(rows: dict[str, list[dict]], selected: str = "MS-01") -> list[Issue]:
    issues: list[Issue] = []
    cols = columns()
    def add(code, sheet, record, column, message, correction, *, blocking=True):
        issues.append(Issue("Error" if blocking else "Warning", code, sheet, str(record), column,
            message, "May make scenario selection, JSON lineage, or runtime interpretation unsafe." if blocking else "Content remains under workbook review.", correction, blocking))

    if tuple(cols) != SHEETS:
        add("SHEET_CONTRACT", "00_Home", "", "", "The 28-sheet contract differs from v4.4.", "Restore the exact sheet order and names.")
    allowed = defaultdict(set)
    for value in rows["22_Value_Lists"]:
        key = (value["ListCode"], value["Code"])
        if value["Code"] in allowed[value["ListCode"]]:
            add("DUPLICATE_CONTROLLED_CODE", "22_Value_Lists", key, "Code", "Controlled code is duplicated.", "Keep one code per list.")
        allowed[value["ListCode"]].add(value["Code"])
    for sheet, records in rows.items():
        if sheet in GENERATED:
            continue
        required = set(cols[sheet])
        key_field = KEYS.get(sheet)
        seen = set()
        for index, record in enumerate(records, 1):
            rid = str(record.get(key_field, index)) if key_field else str(index)
            for missing in required - set(record):
                add("REQUIRED_COLUMN", sheet, rid, missing, "Model row lacks a required column.", "Add the documented column to this row.")
            if key_field:
                key = record.get(key_field)
                if not key:
                    add("BLANK_ID", sheet, rid, key_field, "Identifier is blank.", "Assign a stable identifier.")
                elif key in seen:
                    add("DUPLICATE_ID", sheet, rid, key_field, "Identifier is duplicated.", "Assign a distinct stable identifier.")
                seen.add(key)
            if record.get("IsActive") is True and record.get("SourceId") and record["SourceId"] not in {s["SourceId"] for s in rows["23_Source_References"]}:
                add("SOURCE_REFERENCE", sheet, rid, "SourceId", "Source reference is unresolved.", "Add an active source record or correct SourceId.")

    active_scenarios = [r for r in rows["01_Migration_Scenarios"] if r["IsActive"]]
    active_modules = [r for r in rows["04_Assessment_Modules"] if r["IsActive"]]
    approved_scenarios = {r["ScenarioId"] for r in scenarios()}
    approved_modules = {r["ModuleId"] for r in modules()}
    if len(active_scenarios) != 8 or {r["ScenarioId"] for r in active_scenarios} != approved_scenarios:
        add("SCENARIO_COUNT", "01_Migration_Scenarios", "", "ScenarioId", "Active scenarios do not match the approved eight.", "Restore MS-01 through MS-08 only.")
    if selected not in approved_scenarios:
        add("SELECTED_SCENARIO", "00_Home", selected, "SelectedScenarioId", "Selected scenario is invalid.", "Select one of MS-01 through MS-08.")
    if len(active_modules) != 15 or {r["ModuleId"] for r in active_modules} != approved_modules:
        add("MODULE_COUNT", "04_Assessment_Modules", "", "ModuleId", "Active modules do not match the approved fifteen.", "Restore the fifteen v4.4 modules.")

    question_ids = {r["QuestionId"] for r in rows["02_Scenario_Questionnaire"]}
    field_ids = {r["FieldCode"] for r in rows["07_Fields_Evidence"]}
    requirement_ids = {r["RequirementId"] for r in rows["06_Requirement_Catalogue"]}
    source_ids = {r["SourceId"] for r in rows["23_Source_References"]}
    namespaces = {
        "ScenarioId": approved_scenarios, "CandidateScenarioId": approved_scenarios,
        "ModuleId": approved_modules, "RequirementId": requirement_ids,
        "QuestionId": question_ids, "OriginQuestionId": question_ids,
        "FollowUpQuestionId": question_ids, "ParentQuestionId": question_ids,
        "FieldCode": field_ids, "InputContextField": field_ids,
        "ActivationContextField": field_ids, "SourceFieldCode": field_ids,
        "TargetFieldCode": field_ids, "SourceId": source_ids,
        "MetricCode": {r["MetricCode"] for r in rows["13_Size_Volume_Metrics"]},
        "FindingCode": {r["FindingCode"] for r in rows["18_Findings"]},
        "RecommendationCode": {r["RecommendationCode"] for r in rows["19_Recommendations_Actions"]},
        "EffortDriverId": {r["EffortDriverId"] for r in rows["17_Effort_Drivers"]},
    }
    primary_ids = set(KEYS.values()) | {"DerivationRuleId", "ListCode"}
    for sheet, records in rows.items():
        if sheet in GENERATED or sheet == "25_JSON_Field_Map":
            continue
        for index, record in enumerate(records, 1):
            if record.get("IsActive") is False:
                continue
            rid = str(record.get(KEYS.get(sheet, ""), index))
            for field, namespace in namespaces.items():
                if field not in record or (field in primary_ids and field == KEYS.get(sheet)):
                    continue
                value = record[field]
                if value in (None, "", "ALL"):
                    continue
                if value not in namespace:
                    add("FOREIGN_KEY", sheet, rid, field, f"Active record references unknown {field}={value}.", "Use an active identifier in the referenced catalogue.")
    map_keys = Counter()
    for m in rows["05_Scenario_Module_Map"]:
        rid = m["ScenarioModuleMapId"]
        triple = (m["ScenarioId"], m["Phase"], m["ModuleId"])
        if m["IsActive"]:
            map_keys[triple] += 1
        if m["ScenarioId"] not in approved_scenarios or m["ModuleId"] not in approved_modules:
            add("MAP_REFERENCE", "05_Scenario_Module_Map", rid, "ScenarioId/ModuleId", "Mapping endpoint is unresolved.", "Use approved active scenario and module IDs.")
        for col in ("Phase", "Applicability", "AssessmentDepth", "DefaultMissingEvidenceOutcome", "PhaseOutcomeImpact", "BaselineContribution", "ReconciliationRole"):
            list_code = col
            if m[col] not in allowed[list_code]:
                add("CONTROLLED_VALUE", "05_Scenario_Module_Map", rid, col, f"{m[col]} is not a controlled {list_code} value.", "Use an active code from 22_Value_Lists.")
        if m["Applicability"] == "Conditional":
            if not m["ActivationContextField"] or not m["ActivationOperator"] or not m["ActivationValue"]:
                add("CONDITIONAL_ACTIVATION", "05_Scenario_Module_Map", rid, "ActivationContextField", "Conditional mapping has incomplete activation.", "Fill context field, operator and value.")
            if m["ActivationContextField"] not in field_ids:
                add("ACTIVATION_FIELD", "05_Scenario_Module_Map", rid, "ActivationContextField", "Activation field is unresolved.", "Add a stable field definition.")
            if m["ActivationOperator"] not in allowed["Operator"]:
                add("ACTIVATION_OPERATOR", "05_Scenario_Module_Map", rid, "ActivationOperator", "Activation operator is unsupported.", "Use a controlled operator.")
            if m["DefaultMissingEvidenceOutcome"] not in ("FollowUp", "NotAssessed", "Blocked", "InsufficientEvidence"):
                add("UNKNOWN_ACTIVATION_OUTCOME", "05_Scenario_Module_Map", rid, "DefaultMissingEvidenceOutcome", "Unknown activation has no safe outcome.", "Use FollowUp, NotAssessed, Blocked or InsufficientEvidence.")
        elif any(m[c] for c in ("ActivationContextField", "ActivationOperator", "ActivationValue")):
            add("SPURIOUS_ACTIVATION", "05_Scenario_Module_Map", rid, "ActivationContextField", "Non-conditional mapping contains activation logic.", "Clear activation fields.")
        if m["ModuleId"] == "MOD-READINESS" and m["Phase"] != "PreMigration" and m["Applicability"] != "NotApplicable":
            add("READINESS_PHASE", "05_Scenario_Module_Map", rid, "Applicability", "Readiness is outside PreMigration.", "Set NotApplicable.")
        if m["ModuleId"] == "MOD-RECONCILE" and (m["Phase"] != "PostMigration" or m["ScenarioId"] == "MS-07") and m["Applicability"] != "NotApplicable":
            add("RECONCILE_PHASE", "05_Scenario_Module_Map", rid, "Applicability", "Reconciliation violates phase or MS-07 boundary.", "Set NotApplicable.")
    expected = {(s, p, m) for s in approved_scenarios for p in PHASES for m in approved_modules}
    if set(map_keys) != expected or any(count != 1 for count in map_keys.values()) or sum(map_keys.values()) != 360:
        add("MAP_360", "05_Scenario_Module_Map", "", "ScenarioModuleMapId", "The active 8 × 3 × 15 matrix is incomplete or duplicated.", "Restore one explicit mapping per combination.")

    for d in rows["03_Scenario_Derivation_Rules"]:
        rid = f"{d['DerivationRuleId']}:{d['ConditionGroup']}:{d['ConditionSequence']}"
        for col, namespace in (("InputContextField", field_ids), ("CandidateScenarioId", approved_scenarios), ("RequirementId", requirement_ids)):
            if d[col] and d[col] not in namespace:
                add("DERIVATION_REFERENCE", "03_Scenario_Derivation_Rules", rid, col, "Derivation reference is unresolved.", "Correct the referenced stable ID.")
        if d["OriginQuestionId"] and d["OriginQuestionId"] not in question_ids:
            add("DERIVATION_QUESTION", "03_Scenario_Derivation_Rules", rid, "OriginQuestionId", "Origin question is unresolved.", "Use an active Q-SCN identifier.")
    condition_keys = Counter((d["DerivationRuleId"], d["ConditionGroup"], d["ConditionSequence"]) for d in rows["03_Scenario_Derivation_Rules"] if d["IsActive"])
    if any(count != 1 for count in condition_keys.values()):
        add("DERIVATION_CONDITION_DUPLICATE", "03_Scenario_Derivation_Rules", "", "ConditionSequence", "Atomic derivation condition key is duplicated.", "Keep one condition per rule/group/sequence.")
    unsupported = [d for d in rows["03_Scenario_Derivation_Rules"] if d["DerivationRuleId"] == "SDR-TARGET-UNSUPPORTED"]
    if {d["ExpectedValue"] for d in unsupported} != {"DMS", "ThirdPartySystem", "OtherEXTEDOProduct"} or any(d["CandidateScenarioId"] != "MS-07" or d["OnMatchStatus"] != "NeedsReview" or d["ReasonCode"] != "OUTSIDE_SUPPORTED_TARGET" for d in unsupported):
        add("UNSUPPORTED_TARGET", "03_Scenario_Derivation_Rules", "SDR-TARGET-UNSUPPORTED", "CandidateScenarioId", "Unsupported targets do not route to MS-07 / NeedsReview.", "Restore the approved OUTSIDE_SUPPORTED_TARGET rule groups.")

    for q in rows["02_Scenario_Questionnaire"]:
        if q["AnswerType"] in ("CodeList", "MultiSelectCodeList") and q["AnswerListCode"] not in allowed:
            add("QUESTION_LIST", "02_Scenario_Questionnaire", q["QuestionId"], "AnswerListCode", "Question answer list is missing.", "Define controlled codes in 22_Value_Lists.")
    for f in rows["07_Fields_Evidence"]:
        if f["DataType"] not in allowed["DataType"] or f["AllowedOperator"] not in allowed["Operator"]:
            add("FIELD_CONTROL", "07_Fields_Evidence", f["FieldCode"], "DataType/AllowedOperator", "Field type or operator is uncontrolled.", "Use approved value lists.")
    for metric in rows["13_Size_Volume_Metrics"]:
        if metric["SourceFieldCode"] not in field_ids or metric["ModuleId"] not in approved_modules:
            add("METRIC_REFERENCE", "13_Size_Volume_Metrics", metric["MetricCode"], "SourceFieldCode/ModuleId", "Metric reference is unresolved.", "Correct field and module IDs.")

    families = {f"REQ-{code}" for code in allowed["RequirementDomain"]}
    actual_families = {"-".join(r["RequirementId"].split("-")[:2]) for r in rows["06_Requirement_Catalogue"]}
    if families != actual_families:
        add("REQUIREMENT_FAMILIES", "06_Requirement_Catalogue", "", "RequirementId", "The 24 mandatory REQ-* families are not all represented.", "Seed at least one atomic requirement in every approved family.")
    for r in rows["06_Requirement_Catalogue"]:
        rid = r["RequirementId"]
        for col in ("RequirementTitle", "RequirementStatement", "BusinessPurpose", "AcceptanceCriterion", "SourceId", "SourceSection"):
            if not r[col]:
                add("REQUIREMENT_ATOMIC_STRUCTURE", "06_Requirement_Catalogue", rid, col, "Requirement identity, purpose, acceptance or source is missing.", "Provide one testable obligation and traceable source.")
        if r["OwningComponent"] == "AssessmentModule" and r["ModuleId"] not in approved_modules:
            add("REQUIREMENT_OWNER", "06_Requirement_Catalogue", rid, "ModuleId", "AssessmentModule owner lacks active module.", "Assign an approved module.")
        if r["OwningComponent"] != "AssessmentModule" and r["ModuleId"]:
            add("FALSE_MODULE_OWNER", "06_Requirement_Catalogue", rid, "ModuleId", "Cross-cutting requirement has a false module owner.", "Leave ModuleId blank.")
        if r["SourceId"] not in source_ids:
            add("REQUIREMENT_SOURCE", "06_Requirement_Catalogue", rid, "SourceId", "Requirement source is unresolved.", "Add a source reference.")
        if r["RuntimeExport"] and not r["JSONPath"]:
            add("REQUIREMENT_JSON_PATH", "06_Requirement_Catalogue", rid, "JSONPath", "Exported requirement lacks JSON path.", "Add the documented requirements[] path.")
        if r["RuntimeExport"] and r["ImplementationDisposition"] == "Deferred":
            add("DEFERRED_RUNTIME_EXPORT", "06_Requirement_Catalogue", rid, "RuntimeExport", "Deferred requirement is marked for active runtime export.", "Complete and verify implementation before exporting.")
        if r["VerificationStatus"] == "Passed" and r["ImplementationStatus"] != "Implemented":
            add("FALSE_VERIFICATION", "06_Requirement_Catalogue", rid, "VerificationStatus", "Requirement is marked Passed without implemented behavior.", "Set NotTested or complete implementation and test evidence.")
        for col in ("RequirementStatus", "ImplementationStatus", "VerificationStatus"):
            if r[col] not in allowed[col]:
                add("REQUIREMENT_STATUS", "06_Requirement_Catalogue", rid, col, "Requirement status is uncontrolled.", "Select from the corresponding independent status list.")

    for row in rows["25_JSON_Field_Map"]:
        if row["SourceSheet"] not in cols or row["SourceColumn"] not in cols[row["SourceSheet"]]:
            add("JSON_MAP_SOURCE", "25_JSON_Field_Map", row["MappingId"], "SourceColumn", "JSON field map references a missing source column.", "Correct source sheet/table/column.")
        if not row["JSONPath"] or not row["JSONProperty"]:
            add("JSON_MAP_TARGET", "25_JSON_Field_Map", row["MappingId"], "JSONPath", "JSON property path is missing.", "Add a root-relative property path.")
        if row["SourceSheet"] in cols and any(part not in cols[row["SourceSheet"]] for part in row["SourceRecordKey"].split("+")):
            add("JSON_MAP_KEY", "25_JSON_Field_Map", row["MappingId"], "SourceRecordKey", "JSON mapping key does not resolve to stable source columns.", "Use one or more existing identifier columns.")

    # The family table is a scope inventory, not a completed source-statement
    # disposition ledger. Treat candidate JSON as blocked until SMEs complete it.
    add("SOURCE_OBLIGATION_RECONCILIATION_PENDING", "06_Requirement_Catalogue", "", "SourceSection",
        "Approved enterprise and retained lower-level statements are not yet individually disposed as Covered, Deferred or Superseded.",
        "Review each normative statement, add atomic requirement rows, and record its disposition before runtime export.")
    for sheet in SHEETS[8:22]:
        if not rows[sheet]:
            add("BUSINESS_RULE_REVIEW_PENDING", sheet, "", "", "Detailed rule content awaits sheet-by-sheet SME review.",
                "Populate only approved, sourced rules; keep draft rows inactive.", blocking=False)
    return issues
