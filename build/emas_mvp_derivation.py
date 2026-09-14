"""Reference evaluation of the approved atomic scenario-derivation rows.

This is build/test behavior for the workbook baseline, not a PowerShell runtime
or a place to store project answers in the reusable workbook.
"""
from __future__ import annotations

from collections import defaultdict

from emas_mvp_model import derivation_rules


def _matches(group: list[dict], context: dict) -> bool:
    for condition in group:
        actual = context.get(condition["InputContextField"])
        if actual is None or actual == "Unknown" or actual == "ToBeDefined":
            return False
        if condition["Operator"] == "Equals" and actual != condition["ExpectedValue"]:
            return False
        if condition["Operator"] == "Contains" and condition["ExpectedValue"] not in actual:
            return False
    return True


def derive_scenario(context: dict, rules: list[dict] | None = None) -> dict:
    rules = rules if rules is not None else derivation_rules()
    grouped = defaultdict(lambda: defaultdict(list))
    metadata = {}
    for rule in rules:
        if not rule["IsActive"]:
            continue
        rid = rule["DerivationRuleId"]
        grouped[rid][rule["ConditionGroup"]].append(rule)
        metadata[rid] = rule
    def matched(rule_id: str) -> bool:
        return any(_matches(conditions, context) for conditions in grouped[rule_id].values())

    validations = sorted((rid for rid, row in metadata.items() if row["RulePurpose"] == "ValidateContext"), key=lambda rid: metadata[rid]["Priority"])
    for rid in validations:
        if matched(rid):
            return {"scenarioId": "MS-07", "status": "NeedsReview", "reasonCode": metadata[rid]["ReasonCode"],
                "matchedRuleIds": [rid], "followUpQuestionIds": ["Q-SCN-022"], "consultantDiscussionRequired": True}

    selections = sorted((rid for rid, row in metadata.items() if row["RulePurpose"] == "SelectScenario"), key=lambda rid: metadata[rid]["Priority"])
    candidates = [rid for rid in selections if matched(rid)]
    unique = {metadata[rid]["CandidateScenarioId"] for rid in candidates}
    if len(unique) > 1:
        return {"scenarioId": "MS-07", "status": "NeedsReview", "reasonCode": "CONFLICTING_ROUTE",
            "matchedRuleIds": candidates, "followUpQuestionIds": ["Q-SCN-021", "Q-SCN-022"], "consultantDiscussionRequired": True}
    if not unique:
        missing = [qid for field, qid in (("PrimarySourceMechanism", "Q-SCN-021"), ("TargetPlatform", "Q-SCN-022")) if context.get(field) in (None, "", "Unknown", "ToBeDefined")]
        if context.get("PrimarySourceMechanism") == "ECTDManagerDatabaseArchive" and context.get("SourceDatabaseType") in (None, "", "Unknown"):
            missing.append("Q-SCN-012")
        return {"scenarioId": "MS-07", "status": "Pending" if missing else "NeedsReview",
            "reasonCode": "NO_SUPPORTED_ROUTE" if missing else "OUTSIDE_SUPPORTED_SOURCE",
            "matchedRuleIds": ["SDR-MS07-FALLBACK"], "followUpQuestionIds": missing or ["Q-SCN-021"],
            "consultantDiscussionRequired": not bool(missing)}
    scenario = next(iter(unique))
    if scenario == "MS-05":
        included = context.get("IncludedSourceMechanisms") or []
        allowed = {"ECTDManagerDatabaseArchive", "RegulatorySubmissionExport", "ThirdPartySystem", "DMS", "ArchiveStorage"}
        if not isinstance(included, list) or len(set(included) & allowed) < 2:
            return {"scenarioId": "MS-05", "status": "DerivedWithFollowUp", "reasonCode": "HYBRID_COMPOSITION_INCOMPLETE",
                "matchedRuleIds": candidates, "followUpQuestionIds": ["Q-SCN-023"],
                "consultantDiscussionRequired": False, "runtimeJsonEligible": False}
    missing_evidence = scenario in ("MS-01", "MS-02", "MS-03") and context.get("ArchiveAvailable") in ("No", "Partial", "Unknown", None)
    return {"scenarioId": scenario, "status": "DerivedWithFollowUp" if missing_evidence else "Derived",
        "reasonCode": metadata[candidates[0]]["ReasonCode"], "matchedRuleIds": candidates,
        "followUpQuestionIds": ["Q-SCN-013"] if missing_evidence else [],
        "consultantDiscussionRequired": False}
