#!/usr/bin/env python3
"""Builds the three normalized result JSON files (one per phase) from the
shared Aurelis seed data in aurelis-demo-input.json. These files are the
exact input contract consumed by engine/reporting/emas_report_openxml.py
together with each phase's config/report-mappings/*.template-map.json.

Row-count discipline: the current MVP writer (engine/reporting/
emas_report_openxml.py::append_rows) rejects any appendRows collection whose
record count exceeds its mapping's rowCapacity.maxPreProvisionedRows, because
safe row-insertion-and-shift for tables sharing a sheet is documented as not
yet implemented. The five affected tables (capacity 5 rows each) are:
  Pre-Sales:        effortDrivers, findings
  Pre-Migration:    findings, exceptions
  Post-Migration:   discrepancies
This script keeps every one of those collections at or under 5 records.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEED = json.loads((HERE / "aurelis-demo-input.json").read_text(encoding="utf-8"))

PROJECT = SEED["project"]
DOSSIERS = {d["dossierId"]: d for d in SEED["dossiers"]}
DOSSIER_ORDER = [d["dossierId"] for d in SEED["dossiers"]]
SEQUENCES_BY_DOSSIER: dict[str, list] = {}
for s in SEED["sequences"]:
    SEQUENCES_BY_DOSSIER.setdefault(s["dossierId"], []).append(s)
DISCLOSURE = SEED["disclosure"]
SOURCE_PROFILE = SEED["sourceProfile"]

EXCEL_EPOCH = datetime(1899, 12, 30, tzinfo=timezone.utc)


def excel_dt(dt: datetime) -> float:
    delta = dt - EXCEL_EPOCH
    return round(delta.days + delta.seconds / 86400, 6)


def excel_date_only(date_str: str) -> int:
    y, m, d = (int(x) for x in date_str.split("-"))
    return (datetime(y, m, d) - datetime(1899, 12, 30)).days


def fictional_sha256(label: str) -> str:
    return hashlib.sha256(label.encode("utf-8")).hexdigest().upper()


PRESALES_START = datetime(2026, 6, 18, 9, 14, 22, tzinfo=timezone.utc)
PREMIGRATION_START = datetime(2026, 7, 7, 8, 5, 11, tzinfo=timezone.utc)
POSTMIGRATION_START = datetime(2026, 7, 13, 10, 42, 37, tzinfo=timezone.utc)

PRESALES_DURATION_S = 1874.6
PREMIGRATION_DURATION_S = 5216.3
POSTMIGRATION_DURATION_S = 3122.9


def execution_and_review_rows(*, phase_label, start, duration_s, powershell_version,
                               entry_script, entry_script_version, warning_count, error_count,
                               execution_id, output_workbook_path, log_path, input_paths,
                               report_status="Draft", reviewed_by=None, review_date=None,
                               review_comments=DISCLOSURE):
    generated_at = start + timedelta(seconds=duration_s)
    execution_rows = [
        {"section": "Execution", "field": "ExecutionId", "value": execution_id},
        {"section": "Execution", "field": "GeneratedAtUTC", "value": excel_dt(generated_at)},
        {"section": "Execution", "field": "ExecutedBy", "value": PROJECT["executionAccount"]},
        {"section": "Execution", "field": "ComputerName", "value": PROJECT["migrationStagingEnvironment"]},
        {"section": "Execution", "field": "OperatingSystem", "value": "Windows Server 2022 Standard, 21H2, Build 20348"},
        {"section": "Execution", "field": "PowerShellVersion", "value": powershell_version},
        {"section": "Version", "field": "EngineVersion", "value": "1.0.0-mvp"},
        {"section": "Version", "field": "EntryScriptVersion", "value": entry_script_version},
        {"section": "Version", "field": "TemplateVersion", "value": "1.1.1"},
        {"section": "Version", "field": "ReportWorkbookVersion", "value": "1.1.1"},
        {"section": "Version", "field": "SchemaVersion", "value": "1.0.0"},
        {"section": "Version", "field": "MappingVersion", "value": "1.0.0"},
        {"section": "Version", "field": "SourceWorkbookVersion", "value": "3.4.2"},
        {"section": "Configuration", "field": "RuntimeJSONFilename", "value": "eMAS_Runtime_Config.json"},
        {"section": "Configuration", "field": "RuntimeJSONPath", "value": rf"{PROJECT['stagingRoot']}\config\eMAS_Runtime_Config.json"},
        {"section": "Configuration", "field": "RuntimeJSONSizeBytes", "value": 486117},
        {"section": "Configuration", "field": "RuntimeJSONSHA256", "value": fictional_sha256(f"eMAS_Runtime_Config-{phase_label}-2026")},
        {"section": "Configuration", "field": "MinimumEngineVersion", "value": "1.0.0"},
        {"section": "Scope", "field": "InputPathsOrWorkbooks", "value": input_paths},
        {"section": "Output", "field": "OutputWorkbookPath", "value": output_workbook_path},
        {"section": "Output", "field": "LogPath", "value": log_path},
        {"section": "Execution", "field": "ExecutionDurationSeconds", "value": round(duration_s, 1)},
        {"section": "Execution", "field": "WarningCount", "value": warning_count},
        {"section": "Execution", "field": "ErrorCount", "value": error_count},
        {"section": "Execution", "field": "FinalExecutionStatus", "value": "Completed"},
    ]
    review_rows = [{"section": "Review", "field": "ReportStatus", "value": report_status}]
    if reviewed_by:
        review_rows.append({"section": "Review", "field": "ReviewedBy", "value": reviewed_by})
    if review_date:
        review_rows.append({"section": "Review", "field": "ReviewDate", "value": excel_date_only(review_date)})
    review_rows.append({"section": "Review", "field": "ReviewComments", "value": review_comments})
    return execution_rows, review_rows


def write_json(path: Path, payload) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


# ===========================================================================
# PRE-SALES
# ===========================================================================
def build_pre_sales() -> dict:
    execution_id = "AUR-MIG-26-041-PRESALES-001"
    input_paths = "; ".join([PROJECT["primarySourceRoot"], PROJECT["archiveRootPublished"], PROJECT["archiveRootHistorical"], PROJECT["databaseReference"]])
    execution_rows, review_rows = execution_and_review_rows(
        phase_label="presales", start=PRESALES_START, duration_s=PRESALES_DURATION_S,
        powershell_version="5.1.19041.4894", entry_script="eMAS-PreSalesAssessment.ps1",
        entry_script_version="1.0.0", warning_count=6, error_count=0,
        execution_id=execution_id,
        output_workbook_path=r"artifacts\demo\aurelis-therapeutics\Aurelis_PreSales_Assessment_AUR-MIG-26-041.xlsx",
        log_path=rf"{PROJECT['stagingRoot']}\logs\eMAS-PreSalesAssessment-{execution_id}.log",
        input_paths=input_paths, report_status="Draft",
    )

    dossier_inventory = []
    sequence_inventory = []
    for dossier_id in DOSSIER_ORDER:
        d = DOSSIERS[dossier_id]
        rag = d["preSalesRag"]
        eval_status = "Warning" if rag in ("Amber", "Red") else "Evaluated"
        finding_count = {"AUR-END-EU-017": 1, "AUR-CAL-UN-018": 1, "AUR-MYE-EU-014": 1,
                          "AUR-HEP-CA-011": 1, "AUR-ORB-EU-012": 1, "AUR-VIR-UK-016": 1}.get(dossier_id, 0)
        evidence = {
            "AUR-END-EU-017": "Legacy NeeS structure; regional Module 1 XML incomplete for two historical sequences.",
            "AUR-CAL-UN-018": "Regional classification initially unresolved pending confirmation of a historical export; provisionally treated as EU.",
            "AUR-MYE-EU-014": "Checksum evidence unavailable for three historical sequences; source inventory otherwise complete.",
            "AUR-HEP-CA-011": "Long file paths and non-standard historical folder naming observed in early sequences.",
            "AUR-ORB-EU-012": "Archive-stored dossier; the historical archive location was temporarily inaccessible during initial discovery.",
            "AUR-VIR-UK-018": "",
            "AUR-VIR-UK-016": "Regional XML evidence incomplete for one historical UK sequence; confirmation required.",
        }.get(dossier_id, "Structure and evidence consistent with expected eCTD layout.")
        dossier_inventory.append({
            "dossierId": dossier_id,
            "product": d["name"],
            "dossierDisplayName": d["name"],
            "dossierPath": d["path"],
            "region": "EU" if dossier_id == "AUR-CAL-UN-018" else d["region"],
            "authority": {"EU": "EMA", "US": "FDA", "UK": "MHRA", "Canada": "Health Canada"}.get(d["region"], "EMA"),
            "technicalStandard": "NeeS" if d["format"] in ("NeeS legacy", "Legacy export transitioning to eCTD") else "ICH eCTD 3.2.2",
            "regionalImplementation": "EU eCTD Module 1" if dossier_id == "AUR-CAL-UN-018" else {
                "EU": "EU eCTD Module 1", "US": "US FDA Module 1", "UK": "UK Module 1", "Canada": "Canada Module 1",
            }.get(d["region"], "EU eCTD Module 1"),
            "productDomain": "Human" if "Veterinary" not in d["type"] else "Veterinary",
            "lifecycleContext": d["type"],
            "productClass": d["type"],
            "procedureContext": "National/Centralised",
            "sourcePresentation": "Structured electronic",
            "primaryDossierType": d["type"],
            "classificationConfidence": "Low" if dossier_id == "AUR-CAL-UN-018" else "High",
            "evaluationStatus": eval_status,
            "valueSource": "Derived",
            "evidenceSummary": evidence,
            "matchedCandidates": d["name"],
            "matchedRuleIds": "RUL-CLASS-001; RUL-CLASS-004",
            "sequenceCount": d["sequenceCount"],
            "sizeBytes": int(d["profile"]["sizeGB"] * 1024 * 1024 * 1024),
            "displaySizeGB": d["profile"]["sizeGB"],
            "fileCount": d["profile"]["fileCount"],
            "folderCount": d["profile"]["folderCount"],
            "rag": rag,
            "reviewRequired": "Yes" if rag != "Green" else "No",
            "findingCount": finding_count,
            "recommendationCode": "REC-PS-002" if rag != "Green" else "",
            "recommendedAction": "Confirm regional classification and remediate checksum/path findings before readiness assessment." if rag != "Green" else "",
            "comments": "",
        })
        for seq in SEQUENCES_BY_DOSSIER[dossier_id]:
            sequence_inventory.append({
                "dossierId": dossier_id,
                "sequenceId": seq["sequenceId"],
                "sequenceDisplayName": seq["sequenceDisplayName"],
                "sequencePath": seq["sequencePath"],
                "technicalStandard": seq["technicalStandard"],
                "regionalImplementation": seq["regionalImplementation"],
                "sizeBytes": seq["sizeBytes"],
                "displaySizeMB": seq["displaySizeMB"],
                "fileCount": seq["fileCount"],
                "folderCount": seq["folderCount"],
                "backboneXmlStatus": "Present",
                "checksumStatus": "Missing" if dossier_id == "AUR-MYE-EU-014" and seq["sequenceId"].endswith(("0000", "0001", "0002")) else "Present",
                "regionalXmlStatus": "Incomplete" if dossier_id in ("AUR-END-EU-017", "AUR-VIR-UK-016") and seq is SEQUENCES_BY_DOSSIER[dossier_id][0] else "Present",
                "moduleSummary": "Modules 1-5 present",
                "missingExpectedItems": "",
                "unknownItems": "",
                "evaluationStatus": "Evaluated",
                "valueSource": "Derived",
                "rag": "Green",
                "confidence": "High",
                "ruleIds": "RUL-STRUCT-010",
                "reviewRequired": "No",
                "comments": "",
            })

    effort_drivers = [
        {"driverId": "DRV-PS-001", "driverCode": "SEQ_VOLUME", "driverName": "Overall sequence volume",
         "driverCategory": "Volume", "metricCode": "MET-SEQ-COUNT", "observedValue": "243", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Evaluated", "rag": "Amber", "severity": "Medium",
         "effortImpact": "Increases Band", "confidenceImpact": "Neutral", "minimumBandOverride": "No",
         "evidenceSummary": "243 sequences across 18 dossiers is above the light-complexity threshold.",
         "ruleId": "RUL-EFFORT-001", "findingCode": "", "customerFacingExplanation": "The overall submission volume increases the expected migration effort.",
         "recommendationCode": "REC-PS-001", "recommendedAction": "Plan phased migration waves by region.", "comments": ""},
        {"driverId": "DRV-PS-002", "driverCode": "LEGACY_FORMAT", "driverName": "Legacy NeeS content",
         "driverCategory": "Format complexity", "metricCode": "MET-NEES-COUNT", "observedValue": "2", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Warning", "rag": "Amber", "severity": "Medium",
         "effortImpact": "Increases Band", "confidenceImpact": "Decreases Band", "minimumBandOverride": "No",
         "evidenceSummary": "EnduraMed and Caldriva carry legacy NeeS or transitional content requiring additional handling.",
         "ruleId": "RUL-EFFORT-004", "findingCode": "FND-PS-001", "customerFacingExplanation": "Two dossiers use legacy formats that require conversion planning.",
         "recommendationCode": "REC-PS-002", "recommendedAction": "Confirm NeeS-to-eCTD conversion approach with the customer.", "comments": ""},
        {"driverId": "DRV-PS-003", "driverCode": "REGION_UNCERTAINTY", "driverName": "Regional classification uncertainty",
         "driverCategory": "Classification", "metricCode": "MET-UNRESOLVED-CLASS", "observedValue": "1", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Warning", "rag": "Red", "severity": "High",
         "effortImpact": "Increases Band", "confidenceImpact": "Decreases Band", "minimumBandOverride": "Yes",
         "evidenceSummary": "Caldriva regional classification could not be confirmed from available evidence at assessment time.",
         "ruleId": "RUL-EFFORT-006", "findingCode": "FND-PS-002", "customerFacingExplanation": "One dossier requires confirmation of its regulatory region before a firm effort estimate can be finalized.",
         "recommendationCode": "REC-PS-003", "recommendedAction": "Obtain historical export evidence to confirm Caldriva's region.", "comments": ""},
        {"driverId": "DRV-PS-004", "driverCode": "PATH_REMEDIATION", "driverName": "Long path and archive remediation",
         "driverCategory": "Technical readiness", "metricCode": "MET-LONGPATH-COUNT", "observedValue": "17", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Warning", "rag": "Amber", "severity": "Medium",
         "effortImpact": "Neutral", "confidenceImpact": "Neutral", "minimumBandOverride": "No",
         "evidenceSummary": "17 long paths and 1 temporarily inaccessible archive location were observed across the source roots.",
         "ruleId": "RUL-EFFORT-008", "findingCode": "FND-PS-004", "customerFacingExplanation": "A modest number of long paths and one archive access issue require remediation before migration.",
         "recommendationCode": "REC-PS-004", "recommendedAction": "Confirm staging-path handling for long paths ahead of readiness assessment.", "comments": ""},
        {"driverId": "DRV-PS-005", "driverCode": "REGIONAL_MIX", "driverName": "Multi-region dossier mix",
         "driverCategory": "Classification", "metricCode": "MET-REGION-COUNT", "observedValue": "5", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Evaluated", "rag": "Green", "severity": "Low",
         "effortImpact": "Neutral", "confidenceImpact": "Neutral", "minimumBandOverride": "No",
         "evidenceSummary": "Dossiers span EU, US, UK and Canada, each with a distinct regional Module 1 implementation.",
         "ruleId": "RUL-EFFORT-010", "findingCode": "", "customerFacingExplanation": "The portfolio spans multiple regulatory regions, which is planned for but adds coordination effort.",
         "recommendationCode": "", "recommendedAction": "", "comments": ""},
    ]

    recommendations = [
        {"recommendationId": "REC-PS-001", "recommendationCode": "REC-PS-001", "area": "Planning",
         "customerFacingRecommendation": "Plan migration waves by region to manage the overall sequence volume.",
         "consultantFacingNote": "Group EU, US, UK and Canada dossiers into separate waves.", "reason": "Reduces coordination risk across regions.",
         "priority": "Medium", "owner": "Migration Lead", "requestedFrom": "Aurelis Therapeutics GmbH",
         "beforeFinalEstimate": "No", "status": "Open", "comments": ""},
        {"recommendationId": "REC-PS-002", "recommendationCode": "REC-PS-002", "area": "Format conversion",
         "customerFacingRecommendation": "Confirm the NeeS-to-eCTD conversion approach for EnduraMed and Caldriva before readiness assessment.",
         "consultantFacingNote": "Legacy format dossiers require a documented conversion path.", "reason": "Avoids rework during readiness.",
         "priority": "High", "owner": "Regulatory Lead", "requestedFrom": "Aurelis Therapeutics GmbH",
         "beforeFinalEstimate": "Yes", "status": "Open", "comments": ""},
        {"recommendationId": "REC-PS-003", "recommendationCode": "REC-PS-003", "area": "Classification",
         "customerFacingRecommendation": "Provide historical export evidence to confirm the Caldriva regulatory region.",
         "consultantFacingNote": "Region confirmation blocks a firm complexity estimate for this dossier.", "reason": "Resolves the single unresolved classification.",
         "priority": "Critical", "owner": "Regulatory Lead", "requestedFrom": "Aurelis Therapeutics GmbH",
         "beforeFinalEstimate": "Yes", "status": "Open", "comments": ""},
        {"recommendationId": "REC-PS-004", "recommendationCode": "REC-PS-004", "area": "Technical readiness",
         "customerFacingRecommendation": "Confirm the staging-path approach for long paths and the temporarily inaccessible archive location.",
         "consultantFacingNote": "Coordinate with IT on the Historical archive access issue.", "reason": "Prevents delays at readiness assessment.",
         "priority": "Medium", "owner": "Technical Lead", "requestedFrom": "Aurelis Therapeutics GmbH",
         "beforeFinalEstimate": "No", "status": "Open", "comments": ""},
        {"recommendationId": "REC-PS-005", "recommendationCode": "REC-PS-005", "area": "Evidence",
         "customerFacingRecommendation": "Confirm checksum evidence availability for MyeloNova's earliest historical sequences.",
         "consultantFacingNote": "Three sequences lack checksum files; confirm whether alternate evidence exists.", "reason": "Supports readiness evaluation of checksum completeness.",
         "priority": "Low", "owner": "Regulatory Lead", "requestedFrom": "Aurelis Therapeutics GmbH",
         "beforeFinalEstimate": "No", "status": "Open", "comments": ""},
    ]

    findings = [
        {"findingId": "FND-PS-001", "findingCode": "FND-PS-001", "entityType": "Dossier", "entityId": "AUR-END-EU-017",
         "product": "EnduraMed", "dossierId": "AUR-END-EU-017", "sequenceId": "", "findingCategory": "Format",
         "findingTitle": "Legacy NeeS structure with incomplete regional XML evidence",
         "evidenceSummary": "EnduraMed is submitted in legacy NeeS format; two historical sequences lack complete regional Module 1 XML.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived",
         "severity": "Medium", "blocker": "No", "effortImpact": "Increases Band", "confidenceImpact": "Neutral",
         "customerFacingDescription": "This dossier uses a legacy submission format that will require a documented conversion approach.",
         "consultantFacingNote": "Confirm NeeS conversion tooling coverage for the two affected sequences.",
         "recommendationCodes": "REC-PS-002", "recommendedAction": "Confirm NeeS-to-eCTD conversion approach.",
         "owner": "Regulatory Lead", "status": "Open", "reviewRequired": "Yes", "comments": ""},
        {"findingId": "FND-PS-002", "findingCode": "FND-PS-002", "entityType": "Dossier", "entityId": "AUR-CAL-UN-018",
         "product": "Caldriva", "dossierId": "AUR-CAL-UN-018", "sequenceId": "", "findingCategory": "Classification",
         "findingTitle": "Regional classification unresolved pending historical export confirmation",
         "evidenceSummary": "Available evidence does not conclusively confirm Caldriva's regulatory region; a historical legacy export requires review.",
         "evidenceReference": rf"{PROJECT['archiveRootHistorical']}\AUR-CAL-UN-018_Caldriva",
         "evaluationStatus": "Warning", "rag": "Red", "confidence": "Low", "valueSource": "Assumed",
         "severity": "High", "blocker": "No", "effortImpact": "Increases Band", "confidenceImpact": "Decreases Band",
         "customerFacingDescription": "This dossier's regulatory region could not be confirmed from the evidence supplied and requires customer input.",
         "consultantFacingNote": "Treat provisionally as EU pending confirmation; do not finalize the estimate on this assumption alone.",
         "recommendationCodes": "REC-PS-003", "recommendedAction": "Obtain historical export evidence confirming the region.",
         "owner": "Regulatory Lead", "status": "Open", "reviewRequired": "Yes", "comments": ""},
        {"findingId": "FND-PS-003", "findingCode": "FND-PS-003", "entityType": "Dossier", "entityId": "AUR-MYE-EU-014",
         "product": "MyeloNova", "dossierId": "AUR-MYE-EU-014", "sequenceId": "", "findingCategory": "Evidence",
         "findingTitle": "Missing checksum files for three historical sequences",
         "evidenceSummary": "Checksum evidence is unavailable for three of MyeloNova's earliest historical sequences; source inventory is otherwise complete.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-MYE-EU-014_MyeloNova",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Observed",
         "severity": "Medium", "blocker": "No", "effortImpact": "Neutral", "confidenceImpact": "Neutral",
         "customerFacingDescription": "Three historical sequences are missing checksum files; this is isolated and does not affect the remaining sequences.",
         "consultantFacingNote": "Confirm whether alternate integrity evidence exists before readiness assessment.",
         "recommendationCodes": "REC-PS-005", "recommendedAction": "Confirm checksum evidence availability.",
         "owner": "Regulatory Lead", "status": "Open", "reviewRequired": "Yes", "comments": ""},
        {"findingId": "FND-PS-004", "findingCode": "FND-PS-004", "entityType": "Dossier", "entityId": "AUR-HEP-CA-011",
         "product": "HepaCure", "dossierId": "AUR-HEP-CA-011", "sequenceId": "", "findingCategory": "Technical",
         "findingTitle": "Long paths and non-standard historical folder naming",
         "evidenceSummary": "Early HepaCure sequences use long file paths and non-standard historical folder naming conventions.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-HEP-CA-011_HepaCure",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Observed",
         "severity": "Medium", "blocker": "No", "effortImpact": "Neutral", "confidenceImpact": "Neutral",
         "customerFacingDescription": "Some historical folders use long paths and non-standard naming that will need staging-path handling.",
         "consultantFacingNote": "Coordinate long-path handling with the migration staging approach.",
         "recommendationCodes": "REC-PS-004", "recommendedAction": "Confirm staging-path approach for long paths.",
         "owner": "Technical Lead", "status": "Open", "reviewRequired": "Yes", "comments": ""},
        {"findingId": "FND-PS-005", "findingCode": "FND-PS-005", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016",
         "product": "ViroNexa", "dossierId": "AUR-VIR-UK-016", "sequenceId": "", "findingCategory": "Evidence",
         "findingTitle": "Incomplete regional XML evidence for one historical UK sequence",
         "evidenceSummary": "One historical ViroNexa sequence has incomplete regional Module 1 XML evidence requiring confirmation.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "Medium", "valueSource": "Observed",
         "severity": "Low", "blocker": "No", "effortImpact": "Neutral", "confidenceImpact": "Neutral",
         "customerFacingDescription": "One historical sequence has incomplete regional evidence that should be confirmed ahead of readiness assessment.",
         "consultantFacingNote": "Request the missing regional XML evidence from the customer archive.",
         "recommendationCodes": "", "recommendedAction": "Confirm regional XML completeness for the affected sequence.",
         "owner": "Regulatory Lead", "status": "Open", "reviewRequired": "Yes", "comments": ""},
    ]

    clarifications = [
        {"clarificationId": "CLR-PS-001", "priority": "Critical", "question": "Can Aurelis Therapeutics confirm the regulatory region for Caldriva using the original historical export?",
         "reason": "Resolves the single unresolved classification affecting the complexity estimate.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-CAL-UN-018", "impactOnEstimate": "May change complexity band if region differs from the provisional EU assumption.",
         "requestedFrom": "Aurelis Therapeutics GmbH Regulatory Affairs", "owner": "Regulatory Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-002", "priority": "High", "question": "What is the planned conversion approach for EnduraMed's legacy NeeS content?",
         "reason": "Confirms effort estimate for legacy format handling.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-END-EU-017", "impactOnEstimate": "Affects the legacy-format effort driver.",
         "requestedFrom": "Aurelis Therapeutics GmbH Regulatory Affairs", "owner": "Regulatory Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-003", "priority": "Medium", "question": "Can the temporarily inaccessible Historical archive location be restored before readiness assessment?",
         "reason": "Confirms whether OrbiLung's archived evidence will be available.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-ORB-EU-012", "impactOnEstimate": "Low; affects evidence completeness only.",
         "requestedFrom": "Aurelis Therapeutics GmbH IT", "owner": "Technical Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-004", "priority": "Medium", "question": "Does an alternate integrity record exist for MyeloNova's three sequences missing checksum files?",
         "reason": "Reduces the evidence-completeness gap ahead of readiness.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-MYE-EU-014", "impactOnEstimate": "Low; confidence impact only.",
         "requestedFrom": "Aurelis Therapeutics GmbH Regulatory Affairs", "owner": "Regulatory Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-005", "priority": "Medium", "question": "Can Aurelis Therapeutics confirm the target staging convention for long file paths in HepaCure?",
         "reason": "Confirms the staging-path approach ahead of migration readiness.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-HEP-CA-011", "impactOnEstimate": "Low; technical readiness driver only.",
         "requestedFrom": "Aurelis Therapeutics GmbH IT", "owner": "Technical Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-006", "priority": "Low", "question": "Can the missing regional XML evidence for the affected ViroNexa sequence be supplied from the customer archive?",
         "reason": "Confirms regional evidence completeness.", "relatedEntityType": "Dossier",
         "relatedEntityId": "AUR-VIR-UK-016", "impactOnEstimate": "Low; evidence completeness only.",
         "requestedFrom": "Aurelis Therapeutics GmbH Regulatory Affairs", "owner": "Regulatory Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-007", "priority": "Medium", "question": "What is the confirmed cutover window for the eCTDmanager migration environment?",
         "reason": "Supports migration wave planning across regions.", "relatedEntityType": "Project",
         "relatedEntityId": "AUR-MIG-26-041", "impactOnEstimate": "Affects scheduling, not complexity band.",
         "requestedFrom": "Aurelis Therapeutics GmbH Program Management", "owner": "Migration Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
        {"clarificationId": "CLR-PS-008", "priority": "Low", "question": "Are there additional MS SQL metadata extracts beyond AURREGSQL01\\REGULATORY that should be included in scope?",
         "reason": "Confirms database scope completeness.", "relatedEntityType": "Project",
         "relatedEntityId": "AUR-MIG-26-041", "impactOnEstimate": "Low; scope confirmation only.",
         "requestedFrom": "Aurelis Therapeutics GmbH IT", "owner": "Technical Lead", "status": "Open",
         "customerResponse": "", "responseSource": "", "evaluationStatus": "NotAssessed", "reviewRequired": "Yes", "comments": ""},
    ]

    path_volume_metrics = [
        {"rootId": "ROOT-PRIMARY", "sourceType": "FileSystem", "rootPath": PROJECT["primarySourceRoot"],
         "valueSource": "Observed", "accessible": "Yes", "evaluationStatus": "Warning",
         "sizeBytes": int(SOURCE_PROFILE["exportSizeGB"] * 1024**3 * 0.74), "displaySizeGB": round(SOURCE_PROFILE["exportSizeGB"] * 0.74, 2),
         "fileCount": round(SOURCE_PROFILE["fileCount"] * 0.74), "folderCount": round(SOURCE_PROFILE["folderCount"] * 0.74),
         "largestFolder": r"AUR-CAL-UN-018_Caldriva\0021", "largestFile": r"AUR-ART-EU-015_ArthoZen\0018\m5-clinical-study-report.pdf",
         "longPathCount": 12, "specialCharacterCount": 3, "accessIssueCount": 0, "rag": "Amber", "confidence": "High",
         "reviewRequired": "Yes", "findingCodes": "FND-PS-004", "comments": "Primary regulatory export root."},
        {"rootId": "ROOT-ARCHIVE-PUBLISHED", "sourceType": "Archive", "rootPath": PROJECT["archiveRootPublished"],
         "valueSource": "Observed", "accessible": "Yes", "evaluationStatus": "Evaluated",
         "sizeBytes": int(SOURCE_PROFILE["archiveSizeGB"] * 1024**3 * 0.68), "displaySizeGB": round(SOURCE_PROFILE["archiveSizeGB"] * 0.68, 2),
         "fileCount": round(SOURCE_PROFILE["fileCount"] * 0.14), "folderCount": round(SOURCE_PROFILE["folderCount"] * 0.14),
         "largestFolder": r"Published\2019", "largestFile": r"Published\2019\AUR-REN-US-013_Renalyte\annex.pdf",
         "longPathCount": 5, "specialCharacterCount": 1, "accessIssueCount": 0, "rag": "Green", "confidence": "High",
         "reviewRequired": "No", "findingCodes": "", "comments": "Published archive; no access issues observed."},
        {"rootId": "ROOT-ARCHIVE-HISTORICAL", "sourceType": "Archive", "rootPath": PROJECT["archiveRootHistorical"],
         "valueSource": "Observed", "accessible": "No", "evaluationStatus": "Warning",
         "sizeBytes": int(SOURCE_PROFILE["archiveSizeGB"] * 1024**3 * 0.32), "displaySizeGB": round(SOURCE_PROFILE["archiveSizeGB"] * 0.32, 2),
         "fileCount": round(SOURCE_PROFILE["fileCount"] * 0.12), "folderCount": round(SOURCE_PROFILE["folderCount"] * 0.12),
         "largestFolder": r"Historical\AUR-ORB-EU-012_OrbiLung", "largestFile": r"Historical\AUR-ORB-EU-012_OrbiLung\0004\m1-cover-letter.pdf",
         "longPathCount": 0, "specialCharacterCount": 3, "accessIssueCount": 1, "rag": "Amber", "confidence": "Medium",
         "reviewRequired": "Yes", "findingCodes": "", "comments": "Location was temporarily inaccessible during initial discovery; access has since been restored for review."},
    ]

    summary_metrics = [
        {"area": "Report Context", "metric": "Customer / Project", "value": f"{PROJECT['customerName']} / {PROJECT['projectName']}", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Application / Source System", "value": "Legacy regulatory document repository and eCTD export folders", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Target Environment", "value": PROJECT["targetEnvironment"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Migration Scenario", "value": PROJECT["migrationScenario"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Assessment Scope", "value": input_paths, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Generated At UTC", "value": excel_dt(PRESALES_START + timedelta(seconds=PRESALES_DURATION_S)), "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "ExecutionId", "value": execution_id, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Report Status", "value": "Draft", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Reviewed By", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Review Date", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Scope and Volume", "metric": "Total Dossiers", "value": 18, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Scope and Volume", "metric": "Total Sequences", "value": 243, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Scope and Volume", "metric": "Total Size GB", "value": SOURCE_PROFILE["exportSizeGB"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Scope and Volume", "metric": "Total File Count", "value": SOURCE_PROFILE["fileCount"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Scope and Volume", "metric": "Total Folder Count", "value": SOURCE_PROFILE["folderCount"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Classification", "metric": "Regions Identified", "value": "EU, US, UK, Canada", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Classification", "metric": "Authorities Identified", "value": "EMA, FDA, MHRA, Health Canada", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Classification", "metric": "Technical Standards Identified", "value": "ICH eCTD 3.2.2, NeeS", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Classification", "metric": "Unknown Classification Count", "value": 1, "evaluationStatus": "Warning", "rag": "Red", "confidence": "Low", "valueSource": "Derived", "reviewRequired": "Yes"},
        {"area": "Structure and Quality", "metric": "Green Dossier Count", "value": 12, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Structure and Quality", "metric": "Amber Dossier Count", "value": 5, "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Structure and Quality", "metric": "Red Dossier Count", "value": 1, "evaluationStatus": "Warning", "rag": "Red", "confidence": "High", "valueSource": "Derived", "reviewRequired": "Yes"},
        {"area": "Structure and Quality", "metric": "Unknown Dossier Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Estimate", "metric": "Final Complexity Band", "value": "High", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "Medium", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Estimate", "metric": "Estimate Confidence", "value": "Medium", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "Medium", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Estimate", "metric": "Key Effort Drivers", "value": "Sequence volume, legacy NeeS conversion, regional classification uncertainty, path/archive remediation", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "Medium", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Estimate", "metric": "Customer Clarification Count", "value": 8, "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "Yes"},
        {"area": "Estimate", "metric": "Primary Assumptions", "value": "Caldriva provisionally treated as EU pending confirmation.", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "Medium", "valueSource": "Assumed", "reviewRequired": "Yes"},
        {"area": "Estimate", "metric": "Missing Information", "value": "Caldriva historical export confirmation; MyeloNova checksum evidence for three sequences.", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "Medium", "valueSource": "Derived", "reviewRequired": "Yes"},
        {"area": "Estimate", "metric": "Recommended Next Step", "value": "Resolve outstanding clarifications, then proceed to Migration Readiness assessment.", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
    ]

    assumptions = [
        {"section": "Purpose", "item": "Intended use", "detail": "Lightweight, read-only migration assessment for the Aurelis Regulatory Content Migration 2026 project. Not a readiness or validation activity.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Read-only assessment", "detail": "Source evidence at all four roots was read only; no source content was modified.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Non-validation statement", "detail": "This assessment does not constitute regulatory validation, formal readiness confirmation or customer acceptance.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Evidence limitation", "detail": "Caldriva's classification and MyeloNova's checksum evidence remain open pending customer clarification.", "valueSource": "Derived", "evaluationStatus": "Warning", "reviewRequired": "Yes", "owner": "Regulatory Lead", "status": "Open", "comments": ""},
        {"section": "Method", "item": "Complexity presentation", "detail": "Complexity band and effort drivers are presented qualitatively; raw scoring detail is kept internal.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Method", "item": "Classification", "detail": "Region, authority, technical standard and lifecycle context are classified as independent dimensions per dossier.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Limitation", "item": "Lightweight scope", "detail": "Deep XML validation, referenced-file validation and reconciliation are out of scope for Pre-Sales Assessment.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
    ]

    return {
        "phaseCode": "PRE_SALES", "phaseName": "Pre-Sales Assessment", "mappingId": "EMAS-MAP-PRESALES",
        "mappingVersion": "1.0.0", "templateId": "EMAS-TPL-PRESALES", "templateVersion": "1.1.1",
        "executionId": execution_id, "generatedAtUtc": (PRESALES_START + timedelta(seconds=PRESALES_DURATION_S)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "finalResult": "High",
        "effortDrivers": effort_drivers, "recommendations": recommendations,
        "dossierInventory": dossier_inventory, "sequenceInventory": sequence_inventory,
        "findings": findings, "clarifications": clarifications, "pathVolumeMetrics": path_volume_metrics,
        "assumptions": assumptions, "summaryMetrics": summary_metrics,
        "executionMetadata": execution_rows, "reviewMetadata": review_rows,
    }


# ===========================================================================
# PRE-MIGRATION
# ===========================================================================
PREMIGRATION_AMBER = {"AUR-END-EU-017", "AUR-VIR-UK-016", "AUR-MYE-EU-014"}


def build_pre_migration() -> dict:
    execution_id = "AUR-MIG-26-041-PREMIG-001"
    input_paths = "; ".join([PROJECT["primarySourceRoot"], PROJECT["archiveRootPublished"], PROJECT["archiveRootHistorical"], PROJECT["stagingRoot"], PROJECT["databaseReference"]])
    execution_rows, review_rows = execution_and_review_rows(
        phase_label="premigration", start=PREMIGRATION_START, duration_s=PREMIGRATION_DURATION_S,
        powershell_version="7.6.1", entry_script="eMAS-PreMigrationReadiness.ps1",
        entry_script_version="1.0.0", warning_count=3, error_count=0,
        execution_id=execution_id,
        output_workbook_path=r"artifacts\demo\aurelis-therapeutics\Aurelis_Migration_Readiness_AUR-MIG-26-041.xlsx",
        log_path=rf"{PROJECT['stagingRoot']}\logs\eMAS-PreMigrationReadiness-{execution_id}.log",
        input_paths=input_paths, report_status="Draft",
    )

    dossier_baseline = []
    sequence_baseline = []
    for dossier_id in DOSSIER_ORDER:
        d = DOSSIERS[dossier_id]
        rag = "Amber" if dossier_id in PREMIGRATION_AMBER else "Green"
        exception_id = {"AUR-END-EU-017": "EXC-PM-001", "AUR-VIR-UK-016": "EXC-PM-002"}.get(dossier_id, "")
        comments = {
            "AUR-END-EU-017": "Legacy NeeS checksum evidence unavailable for historical sequences; covered by accepted exception EXC-PM-001.",
            "AUR-VIR-UK-016": "One historical sequence path exceeds the supported operational threshold; covered by accepted exception EXC-PM-002 via controlled staging-path normalization.",
            "AUR-MYE-EU-014": "Checksum evidence gap resolved through controlled review of source inventory; no accepted exception required.",
            "AUR-CAL-UN-018": "Regional classification confirmed as EU following customer evidence review of the historical export.",
            "AUR-ORB-EU-012": "Historical archive location access confirmed; no outstanding evidence gap.",
            "AUR-HEP-CA-011": "Long paths reduced and remaining paths are covered by the migration staging convention.",
        }.get(dossier_id, "")
        dossier_baseline.append({
            "baselineDossierId": dossier_id, "stableComparisonId": f"STABLE-{dossier_id}",
            "product": d["name"], "dossierDisplayName": d["name"], "dossierPath": d["path"],
            "region": "EU" if dossier_id == "AUR-CAL-UN-018" else d["region"],
            "authority": {"EU": "EMA", "US": "FDA", "UK": "MHRA", "Canada": "Health Canada"}.get(d["region"], "EMA"),
            "technicalStandard": "NeeS" if d["format"] in ("NeeS legacy", "Legacy export transitioning to eCTD") else "ICH eCTD 3.2.2",
            "regionalImplementation": "EU eCTD Module 1" if dossier_id == "AUR-CAL-UN-018" else {
                "EU": "EU eCTD Module 1", "US": "US FDA Module 1", "UK": "UK Module 1", "Canada": "Canada Module 1",
            }.get(d["region"], "EU eCTD Module 1"),
            "productDomain": "Human" if "Veterinary" not in d["type"] else "Veterinary",
            "lifecycleContext": d["type"], "productClass": d["type"], "procedureContext": "National/Centralised",
            "sourcePresentation": "Structured electronic", "primaryDossierType": d["type"],
            "classificationConfidence": "High", "evaluationStatus": "Warning" if rag == "Amber" else "Evaluated",
            "valueSource": "Derived", "expectedSequenceCount": d["sequenceCount"],
            "expectedFileCount": d["profile"]["fileCount"], "expectedFolderCount": d["profile"]["folderCount"],
            "expectedSizeBytes": int(d["profile"]["sizeGB"] * 1024**3), "displaySizeGB": d["profile"]["sizeGB"],
            "rag": rag, "reviewRequired": "Yes" if rag == "Amber" else "No", "includedInMigrationScope": "Yes",
            "exclusionId": "", "exceptionId": exception_id, "findingCount": 1 if exception_id else 0,
            "baselineComments": comments,
        })
        for seq in SEQUENCES_BY_DOSSIER[dossier_id]:
            seq_exception = ""
            if dossier_id == "AUR-END-EU-017" and seq is SEQUENCES_BY_DOSSIER[dossier_id][0]:
                seq_exception = "EXC-PM-001"
            elif dossier_id == "AUR-VIR-UK-016" and seq is SEQUENCES_BY_DOSSIER[dossier_id][0]:
                seq_exception = "EXC-PM-002"
            sequence_baseline.append({
                "baselineSequenceId": seq["sequenceId"], "stableComparisonId": f"STABLE-{seq['sequenceId']}",
                "baselineDossierId": dossier_id, "sequenceDisplayName": seq["sequenceDisplayName"],
                "sequencePath": seq["sequencePath"], "expectedFileCount": seq["fileCount"],
                "expectedFolderCount": seq["folderCount"], "expectedSizeBytes": seq["sizeBytes"],
                "displaySizeMB": seq["displaySizeMB"], "backboneXmlStatus": "Present",
                "checksumStatus": "Unavailable" if seq_exception == "EXC-PM-001" else "Present",
                "regionalXmlStatus": "Present", "referencedFileStatus": "Present",
                "zeroByteFileCount": 0, "longPathCount": 1 if seq_exception == "EXC-PM-002" else 0,
                "missingMandatoryItems": "", "evaluationStatus": "Warning" if seq_exception else "Evaluated",
                "valueSource": "Derived", "rag": "Amber" if seq_exception else "Green", "confidence": "High",
                "reviewRequired": "Yes" if seq_exception else "No", "includedInMigrationScope": "Yes",
                "exclusionId": "", "exceptionId": seq_exception, "findingCount": 1 if seq_exception else 0,
                "comments": "",
            })

    input_checks = [
        {"checkId": "CHK-PM-001", "checkArea": "Access", "checkName": "Source repository read access", "requirement": "Read access confirmed for all four source roots", "mandatory": "Yes", "expectedValue": "Accessible", "observedValue": "Confirmed accessible", "unit": "Status", "valueSource": "Observed", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["primarySourceRoot"], "ruleId": "RUL-INPUT-001", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Technical Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-002", "checkArea": "Staging", "checkName": "Migration staging capacity", "requirement": "Sufficient free capacity at staging root", "mandatory": "Yes", "expectedValue": ">= 400 GB free", "observedValue": "612 GB free at F:\\MigrationStaging", "unit": "GB", "valueSource": "Observed", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["stagingRoot"], "ruleId": "RUL-INPUT-002", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Technical Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-003", "checkArea": "Backup", "checkName": "Source database backup evidence", "requirement": "Recent backup evidence available for AURREGSQL01\\REGULATORY", "mandatory": "Yes", "expectedValue": "Backup within 7 days", "observedValue": "Backup confirmed 2026-07-05", "unit": "Status", "valueSource": "Observed", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["databaseReference"], "ruleId": "RUL-INPUT-003", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Technical Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-004", "checkArea": "Inventory", "checkName": "File and folder inventory completeness", "requirement": "Inventory counts reconcile with Pre-Sales baseline", "mandatory": "Yes", "expectedValue": "128,643 files / 14,987 folders", "observedValue": "128,643 files / 14,987 folders confirmed", "unit": "Count", "valueSource": "Derived", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["primarySourceRoot"], "ruleId": "RUL-INPUT-004", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Migration Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-005", "checkArea": "Technical", "checkName": "Zero-byte file resolution", "requirement": "All previously detected zero-byte files resolved or excluded", "mandatory": "Yes", "expectedValue": "0 unresolved", "observedValue": "4 of 4 resolved through controlled review", "unit": "Count", "valueSource": "Derived", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["primarySourceRoot"], "ruleId": "RUL-INPUT-005", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Regulatory Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-006", "checkArea": "Technical", "checkName": "Long path coverage", "requirement": "Long paths reduced or covered by staging convention", "mandatory": "No", "expectedValue": "Covered by staging convention", "observedValue": "1 residual path covered by accepted exception EXC-PM-002", "unit": "Count", "valueSource": "Derived", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "severity": "Low", "blocker": "No", "evidenceReference": PROJECT["stagingRoot"], "ruleId": "RUL-INPUT-006", "findingCode": "FND-PM-002", "recommendationCode": "", "requiredAction": "", "owner": "Technical Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "Yes", "comments": ""},
        {"checkId": "CHK-PM-007", "checkArea": "Classification", "checkName": "Caldriva regional classification confirmation", "requirement": "Region confirmed from historical export evidence", "mandatory": "Yes", "expectedValue": "Confirmed region", "observedValue": "Confirmed as EU", "unit": "Status", "valueSource": "CustomerProvided", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No", "evidenceReference": PROJECT["archiveRootHistorical"], "ruleId": "RUL-INPUT-007", "findingCode": "", "recommendationCode": "", "requiredAction": "", "owner": "Regulatory Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "No", "comments": ""},
        {"checkId": "CHK-PM-008", "checkArea": "Evidence", "checkName": "Legacy NeeS checksum evidence review", "requirement": "Confirm availability of alternate integrity evidence", "mandatory": "No", "expectedValue": "Alternate evidence or accepted exception", "observedValue": "No alternate evidence found; covered by accepted exception EXC-PM-001", "unit": "Status", "valueSource": "Derived", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "severity": "Low", "blocker": "No", "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed", "ruleId": "RUL-INPUT-008", "findingCode": "FND-PM-001", "recommendationCode": "", "requiredAction": "", "owner": "Regulatory Lead", "targetDate": "2026-07-07", "status": "Completed", "reviewRequired": "Yes", "comments": ""},
    ]

    file_xml_path_checks = [
        {"technicalCheckId": "TCK-PM-001", "entityType": "Dossier", "entityId": "AUR-END-EU-017", "checkType": "Checksum verification",
         "expectedValue": "Checksum file present", "observedValue": "Checksum file absent for 2 historical sequences", "unit": "Status",
         "valueSource": "Observed", "evidencePath": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed", "evidenceReference": "EXC-PM-001",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "severity": "Medium", "blocker": "No",
         "ruleId": "RUL-TECH-001", "findingCode": "FND-PM-001", "recommendationCode": "", "reviewRequired": "Yes", "comments": ""},
        {"technicalCheckId": "TCK-PM-002", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016", "checkType": "Path length verification",
         "expectedValue": f"<= {SOURCE_PROFILE['maxInitialPathLength']} characters", "observedValue": "1 historical path exceeds threshold", "unit": "Characters",
         "valueSource": "Observed", "evidencePath": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa", "evidenceReference": "EXC-PM-002",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "severity": "Medium", "blocker": "No",
         "ruleId": "RUL-TECH-002", "findingCode": "FND-PM-002", "recommendationCode": "", "reviewRequired": "Yes", "comments": ""},
        {"technicalCheckId": "TCK-PM-003", "entityType": "Dossier", "entityId": "AUR-MYE-EU-014", "checkType": "Checksum verification",
         "expectedValue": "Checksum file present", "observedValue": "Resolved through controlled review of source inventory", "unit": "Status",
         "valueSource": "Derived", "evidencePath": rf"{PROJECT['primarySourceRoot']}\AUR-MYE-EU-014_MyeloNova", "evidenceReference": "FND-PM-003",
         "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "severity": "Low", "blocker": "No",
         "ruleId": "RUL-TECH-001", "findingCode": "FND-PM-003", "recommendationCode": "", "reviewRequired": "No", "comments": ""},
        {"technicalCheckId": "TCK-PM-004", "entityType": "Portfolio", "entityId": "AUR-MIG-26-041", "checkType": "Zero-byte file scan",
         "expectedValue": "0 unresolved", "observedValue": "4 of 4 resolved", "unit": "Count",
         "valueSource": "Derived", "evidencePath": PROJECT["primarySourceRoot"], "evidenceReference": "ACT-PM-002",
         "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No",
         "ruleId": "RUL-TECH-003", "findingCode": "", "recommendationCode": "", "reviewRequired": "No", "comments": ""},
        {"technicalCheckId": "TCK-PM-005", "entityType": "Dossier", "entityId": "AUR-CAL-UN-018", "checkType": "Regional classification confirmation",
         "expectedValue": "Confirmed region", "observedValue": "Confirmed as EU", "unit": "Status",
         "valueSource": "CustomerProvided", "evidencePath": PROJECT["archiveRootHistorical"], "evidenceReference": "ACT-PM-003",
         "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No",
         "ruleId": "RUL-TECH-004", "findingCode": "", "recommendationCode": "", "reviewRequired": "No", "comments": ""},
        {"technicalCheckId": "TCK-PM-006", "entityType": "Dossier", "entityId": "AUR-ORB-EU-012", "checkType": "Archive access verification",
         "expectedValue": "Accessible", "observedValue": "Access confirmed restored", "unit": "Status",
         "valueSource": "Observed", "evidencePath": PROJECT["archiveRootHistorical"], "evidenceReference": "ACT-PM-001",
         "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "severity": "Informational", "blocker": "No",
         "ruleId": "RUL-TECH-005", "findingCode": "", "recommendationCode": "", "reviewRequired": "No", "comments": ""},
    ]

    findings = [
        {"findingId": "FND-PM-001", "findingCode": "FND-PM-001", "entityType": "Dossier", "entityId": "AUR-END-EU-017",
         "findingCategory": "Evidence", "findingTitle": "Legacy NeeS checksum evidence unavailable",
         "evidenceSummary": "Historical NeeS sequences for EnduraMed lack checksum files; no alternate integrity evidence was located.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived",
         "severity": "Medium", "blocker": "No", "originalDecisionImpact": "Warning",
         "customerFacingDescription": "Checksum evidence is unavailable for legacy historical sequences; source inventory and review evidence are otherwise complete.",
         "consultantFacingNote": "Covered by accepted exception EXC-PM-001; carry forward to Post-Migration.",
         "recommendationCodes": "", "reviewRequired": "Yes", "status": "Completed", "comments": ""},
        {"findingId": "FND-PM-002", "findingCode": "FND-PM-002", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016",
         "findingCategory": "Technical", "findingTitle": "Historical path length exceeds supported operational threshold",
         "evidenceSummary": "One historical ViroNexa sequence path exceeds the supported operational threshold and requires staging-path normalization.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa",
         "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Observed",
         "severity": "Medium", "blocker": "No", "originalDecisionImpact": "Warning",
         "customerFacingDescription": "One historical file path is longer than the supported operational threshold and will be normalized during controlled staging.",
         "consultantFacingNote": "Covered by accepted exception EXC-PM-002; carry forward to Post-Migration.",
         "recommendationCodes": "", "reviewRequired": "Yes", "status": "Completed", "comments": ""},
        {"findingId": "FND-PM-003", "findingCode": "FND-PM-003", "entityType": "Dossier", "entityId": "AUR-MYE-EU-014",
         "findingCategory": "Evidence", "findingTitle": "Residual checksum evidence gap resolved by controlled review",
         "evidenceSummary": "The three historical MyeloNova sequences identified at Pre-Sales were resolved through controlled review of source inventory evidence.",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-MYE-EU-014_MyeloNova",
         "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived",
         "severity": "Low", "blocker": "No", "originalDecisionImpact": "Informational",
         "customerFacingDescription": "This item is resolved through controlled review evidence and does not require an accepted exception.",
         "consultantFacingNote": "No accepted exception required; retained as an informational residual item.",
         "recommendationCodes": "", "reviewRequired": "No", "status": "Completed", "comments": ""},
    ]

    actions = [
        {"actionId": "ACT-PM-001", "findingId": "AUR-MIG-26-041", "priority": "Medium", "actionCategory": "Access", "requiredAction": "Restore access to the Historical archive location.", "responsibleParty": "Aurelis Therapeutics GmbH IT", "targetDate": "2026-06-25", "status": "Completed", "completionEvidence": "Access confirmed restored 2026-06-24.", "acceptanceCriteria": "Archive location accessible for evidence review.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-002", "findingId": "AUR-MIG-26-041", "priority": "Medium", "actionCategory": "Data quality", "requiredAction": "Resolve or exclude the four zero-byte files identified at Pre-Sales.", "responsibleParty": "Aurelis Therapeutics GmbH Regulatory Affairs", "targetDate": "2026-06-30", "status": "Completed", "completionEvidence": "All four resolved through controlled review; none excluded.", "acceptanceCriteria": "Zero unresolved zero-byte files.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-003", "findingId": "AUR-MIG-26-041", "priority": "Critical", "actionCategory": "Classification", "requiredAction": "Confirm the Caldriva regulatory region using historical export evidence.", "responsibleParty": "Aurelis Therapeutics GmbH Regulatory Affairs", "targetDate": "2026-06-28", "status": "Completed", "completionEvidence": "Region confirmed as EU on 2026-06-27; evidence filed with the readiness package.", "acceptanceCriteria": "Confirmed regulatory region recorded.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-004", "findingId": "FND-PM-002", "priority": "Medium", "actionCategory": "Technical readiness", "requiredAction": "Define the staging-path normalization convention for long historical paths.", "responsibleParty": "Migration Lead", "targetDate": "2026-07-02", "status": "Completed", "completionEvidence": "Staging convention documented and applied to affected sequences.", "acceptanceCriteria": "Convention documented and validated against the staging root.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-005", "findingId": "AUR-MIG-26-041", "priority": "Low", "actionCategory": "Inventory", "requiredAction": "Reconcile file and folder inventory totals against the Pre-Sales baseline.", "responsibleParty": "Migration Lead", "targetDate": "2026-07-03", "status": "Completed", "completionEvidence": "Totals reconciled: 128,643 files / 14,987 folders.", "acceptanceCriteria": "Inventory totals match within tolerance.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-006", "findingId": "AUR-MIG-26-041", "priority": "Low", "actionCategory": "Staging", "requiredAction": "Confirm staging capacity at F:\\MigrationStaging\\AUR-MIG-26-041.", "responsibleParty": "Aurelis Therapeutics GmbH IT", "targetDate": "2026-07-04", "status": "Completed", "completionEvidence": "612 GB free confirmed; sufficient for planned migration waves.", "acceptanceCriteria": "Free capacity exceeds 400 GB.", "reviewRequired": "No", "comments": ""},
        {"actionId": "ACT-PM-007", "findingId": "AUR-MIG-26-041", "priority": "Low", "actionCategory": "Backup", "requiredAction": "Confirm backup evidence for the AURREGSQL01\\REGULATORY metadata extract.", "responsibleParty": "Aurelis Therapeutics GmbH IT", "targetDate": "2026-07-05", "status": "Completed", "completionEvidence": "Backup confirmed dated 2026-07-05.", "acceptanceCriteria": "Backup evidence dated within 7 days of readiness assessment.", "reviewRequired": "No", "comments": ""},
    ]

    exceptions = [
        {"exceptionId": "EXC-PM-001", "exceptionPolicyId": "POL-EVIDENCE-001", "findingId": "FND-PM-001", "entityType": "Dossier", "entityId": "AUR-END-EU-017",
         "originalEvaluationStatus": "Warning", "originalRAG": "Amber", "originalDecisionImpact": "Warning", "originalEvidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed",
         "exceptionEffect": "AcknowledgeOnly", "justification": "EnduraMed contains legacy NeeS sequences for which historical checksum evidence is unavailable, but source inventory and controlled review evidence are available.",
         "requestedBy": "Regulatory Lead", "reviewedBy": "Migration Lead", "decisionDate": "2026-07-07",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed", "carryForwardToPostMigration": "Yes",
         "exceptionStatus": "Accepted", "reviewRequired": "Yes", "comments": ""},
        {"exceptionId": "EXC-PM-002", "exceptionPolicyId": "POL-TECHNICAL-002", "findingId": "FND-PM-002", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016",
         "originalEvaluationStatus": "Warning", "originalRAG": "Amber", "originalDecisionImpact": "Warning", "originalEvidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa",
         "exceptionEffect": "AcknowledgeOnly", "justification": "One historical ViroNexa path requires controlled staging-path normalization during migration because the original source path exceeds the supported operational threshold.",
         "requestedBy": "Technical Lead", "reviewedBy": "Migration Lead", "decisionDate": "2026-07-07",
         "evidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa", "carryForwardToPostMigration": "Yes",
         "exceptionStatus": "Accepted", "reviewRequired": "Yes", "comments": ""},
    ]

    summary_metrics = [
        {"area": "Report Context", "metric": "Customer / Project", "value": f"{PROJECT['customerName']} / {PROJECT['projectName']}", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Target Environment", "value": PROJECT["targetEnvironment"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Migration Scenario", "value": PROJECT["migrationScenario"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Baseline Identifier", "value": "AUR-MIG-26-041-BASELINE-001", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Baseline Date UTC", "value": excel_dt(PREMIGRATION_START + timedelta(seconds=PREMIGRATION_DURATION_S)), "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "ExecutionId", "value": execution_id, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Report Status", "value": "Draft", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Reviewed By", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Review Date", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Inputs and Access", "metric": "Required Inputs Complete", "value": "Yes", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Inputs and Access", "metric": "Accessible Path Count", "value": 4, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Inputs and Access", "metric": "Inaccessible Path Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Baseline", "metric": "Dossiers in Baseline", "value": 18, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Baseline", "metric": "Sequences in Baseline", "value": 243, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Baseline", "metric": "Baseline Size GB", "value": SOURCE_PROFILE["exportSizeGB"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Assessment", "metric": "Blocker Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Assessment", "metric": "Warning Count", "value": 3, "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Assessment", "metric": "Accepted Exception Count", "value": 2, "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Assessment", "metric": "Exclusion Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Assessment", "metric": "Cleanup Action Count", "value": 7, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Final Readiness Result", "value": "Ready with Accepted Exceptions", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Decision Rationale", "value": "No unresolved blockers remain; two controlled accepted exceptions (EXC-PM-001, EXC-PM-002) cover the residual checksum and path-length findings.", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Mandatory Actions Before Migration", "value": "None; carry accepted-exception evidence forward to Post-Migration Verification.", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Baseline Limitations", "value": "Checksum evidence for EnduraMed's legacy NeeS sequences remains unavailable; covered by accepted exception.", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "Yes"},
    ]

    assumptions = [
        {"section": "Purpose", "item": "Intended use", "detail": "Detailed source-data readiness assessment and reusable baseline creation for the Aurelis Regulatory Content Migration 2026 project.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Read-only assessment", "detail": "Source evidence at all four roots was read only; no source content was modified.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Non-validation statement", "detail": "This assessment does not constitute regulatory validation, migration execution or customer acceptance.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Evidence limitation", "detail": "Two accepted exceptions preserve original findings and evidence rather than erasing them; see the Exceptions register.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Baseline", "item": "Stable comparison identifiers", "detail": "Baseline dossier and sequence identifiers are carried forward unchanged for Post-Migration Verification comparison.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Exception", "item": "Evidence preservation", "detail": "Accepted exceptions EXC-PM-001 and EXC-PM-002 preserve the original finding and evidence and carry forward to Post-Migration Verification.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Limitation", "item": "Input availability", "detail": "Historical checksum evidence for EnduraMed's legacy NeeS sequences could not be located and remains an accepted limitation.", "valueSource": "Derived", "evaluationStatus": "Warning", "reviewRequired": "Yes", "owner": "Regulatory Lead", "status": "Open", "comments": ""},
    ]

    return {
        "phaseCode": "PRE_MIGRATION", "phaseName": "Pre-Migration Readiness", "mappingId": "EMAS-MAP-PREMIGRATION",
        "mappingVersion": "1.0.0", "templateId": "EMAS-TPL-PREMIGRATION", "templateVersion": "1.1.1",
        "executionId": execution_id, "generatedAtUtc": (PREMIGRATION_START + timedelta(seconds=PREMIGRATION_DURATION_S)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "finalResult": "Ready with Accepted Exceptions",
        "readinessDecision": [{
            "decisionId": "DEC-PM-001", "readinessResult": "Ready with Accepted Exceptions",
            "decisionRationale": "No unresolved blockers remain; two controlled accepted exceptions cover the residual checksum and path-length findings.",
            "blockerCount": 0, "warningCount": 3, "acceptedExceptionCount": 2, "exclusionCount": 0,
            "requiredAction": "Carry accepted-exception evidence forward to Post-Migration Verification.",
            "responsibleParty": "Migration Lead", "targetDate": "2026-07-13", "evaluationStatus": "Warning",
            "rag": "Amber", "confidence": "High", "reviewRequired": "Yes", "status": "Accepted", "comments": "",
        }],
        "inputChecks": input_checks, "dossierBaseline": dossier_baseline, "sequenceBaseline": sequence_baseline,
        "fileXmlPathChecks": file_xml_path_checks, "findings": findings, "actions": actions,
        "exceptions": exceptions, "exclusions": [],
        "assumptions": assumptions, "summaryMetrics": summary_metrics,
        "executionMetadata": execution_rows, "reviewMetadata": review_rows,
    }


write_json(HERE / "aurelis-pre-sales-result.json", build_pre_sales())
print("Wrote aurelis-pre-sales-result.json")
write_json(HERE / "aurelis-pre-migration-result.json", build_pre_migration())
print("Wrote aurelis-pre-migration-result.json")


# ===========================================================================
# POST-MIGRATION
# ===========================================================================
def build_post_migration() -> dict:
    execution_id = "AUR-MIG-26-041-POSTMIG-001"
    input_paths = "; ".join([PROJECT["stagingRoot"], PROJECT["targetEnvironment"], r"F:\MigrationStaging\AUR-MIG-26-041\MigrationSummary.xlsx"])
    execution_rows, review_rows = execution_and_review_rows(
        phase_label="postmigration", start=POSTMIGRATION_START, duration_s=POSTMIGRATION_DURATION_S,
        powershell_version="7.6.1", entry_script="eMAS-PostMigrationVerification.ps1",
        entry_script_version="1.0.0", warning_count=2, error_count=0,
        execution_id=execution_id,
        output_workbook_path=r"artifacts\demo\aurelis-therapeutics\Aurelis_Post_Migration_Verification_AUR-MIG-26-041.xlsx",
        log_path=rf"{PROJECT['stagingRoot']}\logs\eMAS-PostMigrationVerification-{execution_id}.log",
        input_paths=input_paths, report_status="Draft",
    )

    dossier_reconciliation = []
    sequence_reconciliation = []
    for dossier_id in DOSSIER_ORDER:
        d = DOSSIERS[dossier_id]
        rag = "Amber" if dossier_id in PREMIGRATION_AMBER else "Green"
        exception_id = {"AUR-END-EU-017": "EXC-POST-001", "AUR-VIR-UK-016": "EXC-POST-002"}.get(dossier_id, "")
        discrepancy_ids = {"AUR-END-EU-017": "DISC-001", "AUR-VIR-UK-016": "DISC-002"}.get(dossier_id, "")
        dossier_reconciliation.append({
            "dossierComparisonId": f"DCMP-{dossier_id}", "stableComparisonId": f"STABLE-{dossier_id}",
            "baselineDossierId": dossier_id, "baselinePresent": "Yes", "importReportPresent": "Yes", "postImportPresent": "Yes",
            "baselineDossierName": d["name"], "migratedDossierName": d["name"],
            "expectedSequenceCount": d["sequenceCount"], "observedSequenceCount": d["sequenceCount"],
            "importStatusSummary": "All sequences imported" if not discrepancy_ids else "Imported with one documented accepted difference",
            "valueSource": "Derived", "evaluationStatus": "Warning" if rag == "Amber" else "Evaluated", "confidence": "High",
            "acceptedException": "Yes" if exception_id else "No", "exceptionId": exception_id,
            "originalRAG": "Amber" if rag == "Amber" else "Green", "rag": rag,
            "reconciliationStatus": "Accepted Difference" if discrepancy_ids else "Matched",
            "reviewRequired": "Yes" if rag == "Amber" else "No", "discrepancyIds": discrepancy_ids,
            "recommendedAction": "" if not discrepancy_ids else "Retain accepted-exception evidence in the migration record.",
            "comments": "",
        })
        for seq in SEQUENCES_BY_DOSSIER[dossier_id]:
            is_first = seq is SEQUENCES_BY_DOSSIER[dossier_id][0]
            seq_exception = ""
            seq_discrepancy = ""
            if dossier_id == "AUR-END-EU-017" and is_first:
                seq_exception, seq_discrepancy = "EXC-POST-001", "DISC-002"
            elif dossier_id == "AUR-VIR-UK-016" and is_first:
                seq_exception, seq_discrepancy = "EXC-POST-002", "DISC-001"
            sequence_reconciliation.append({
                "sequenceComparisonId": f"SCMP-{seq['sequenceId']}", "stableComparisonId": f"STABLE-{seq['sequenceId']}",
                "baselineSequenceId": seq["sequenceId"], "baselineDossierId": dossier_id,
                "sequenceDisplayName": seq["sequenceDisplayName"], "baselinePresent": "Yes", "importReportPresent": "Yes", "postImportPresent": "Yes",
                "expectedValue": str(seq["fileCount"]), "observedValue": str(seq["fileCount"]),
                "importStatus": "OK" if not seq_exception else "Warning",
                "importStatusCode": "I00" if not seq_exception else "W02",
                "postImportRegion": seq["regionalImplementation"].split(" ")[0],
                "valueSource": "Derived", "evaluationStatus": "Warning" if seq_exception else "Evaluated", "confidence": "High",
                "acceptedException": "Yes" if seq_exception else "No", "exceptionId": seq_exception,
                "originalRAG": "Amber" if seq_exception else "Green", "rag": "Amber" if seq_exception else "Green",
                "reconciliationStatus": "Accepted Difference" if seq_exception else "Matched",
                "reviewRequired": "Yes" if seq_exception else "No", "discrepancyIds": seq_discrepancy, "comments": "",
            })

    matched_sequences = sum(1 for s in sequence_reconciliation if s["reconciliationStatus"] == "Matched")
    assert matched_sequences == 241, matched_sequences

    verification_scope = [
        {"scopeItemId": "SCOPE-PM-001", "scopeArea": "Dossier and sequence reconciliation", "baselineSource": "AUR-MIG-26-041-BASELINE-001",
         "migratedEvidenceSource": "MigrationSummary.xlsx and post-import verification evidence", "comparisonKey": "StableComparisonId",
         "included": "Yes", "exclusionId": "", "exceptionId": "", "valueSource": "Derived", "evaluationStatus": "Evaluated",
         "confidence": "High", "reviewRequired": "No", "limitation": "", "comments": ""},
        {"scopeItemId": "SCOPE-PM-002", "scopeArea": "File and size reconciliation", "baselineSource": "AUR-MIG-26-041-BASELINE-001",
         "migratedEvidenceSource": "Post-import verification evidence", "comparisonKey": "StableComparisonId",
         "included": "Yes", "exclusionId": "", "exceptionId": "", "valueSource": "Derived", "evaluationStatus": "Evaluated",
         "confidence": "High", "reviewRequired": "No", "limitation": "Two historical sequences compared with accepted exceptions rather than exact match.", "comments": ""},
        {"scopeItemId": "SCOPE-PM-003", "scopeArea": "Import evidence review", "baselineSource": "N/A",
         "migratedEvidenceSource": "MigrationSummary.xlsx raw import report", "comparisonKey": "SourceRowReference",
         "included": "Yes", "exclusionId": "", "exceptionId": "", "valueSource": "Derived", "evaluationStatus": "Evaluated",
         "confidence": "High", "reviewRequired": "No", "limitation": "", "comments": ""},
    ]

    baseline_comparison = [
        {"reconciliationMetricId": "RM-001", "metricCode": "MET-DOSSIER-COUNT", "metricName": "Dossier count", "entityScope": "Dossier",
         "baselineValue": "18", "importValue": "18", "postImportValue": "18", "difference": "0", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Evaluated", "confidence": "High", "comparisonRuleId": "RUL-RECON-001",
         "tolerance": 0.0, "reconciliationStatus": "Matched", "rag": "Green", "reviewRequired": "No", "discrepancyId": "", "comments": ""},
        {"reconciliationMetricId": "RM-002", "metricCode": "MET-SEQUENCE-COUNT", "metricName": "Sequence count", "entityScope": "Sequence",
         "baselineValue": "243", "importValue": "243", "postImportValue": "243", "difference": "0", "unit": "Count",
         "valueSource": "Derived", "evaluationStatus": "Evaluated", "confidence": "High", "comparisonRuleId": "RUL-RECON-002",
         "tolerance": 0.0, "reconciliationStatus": "Matched", "rag": "Green", "reviewRequired": "No", "discrepancyId": "", "comments": ""},
        {"reconciliationMetricId": "RM-003", "metricCode": "MET-FILE-COUNT", "metricName": "File count", "entityScope": "Dossier",
         "baselineValue": str(SOURCE_PROFILE["fileCount"]), "importValue": str(SOURCE_PROFILE["fileCount"]), "postImportValue": str(SOURCE_PROFILE["fileCount"]),
         "difference": "0", "unit": "Count", "valueSource": "Derived", "evaluationStatus": "Evaluated", "confidence": "High",
         "comparisonRuleId": "RUL-RECON-003", "tolerance": 0.0, "reconciliationStatus": "Matched", "rag": "Green", "reviewRequired": "No", "discrepancyId": "", "comments": ""},
        {"reconciliationMetricId": "RM-004", "metricCode": "MET-EXPORT-SIZE", "metricName": "Export size (GB)", "entityScope": "Dossier",
         "baselineValue": str(SOURCE_PROFILE["exportSizeGB"]), "importValue": str(SOURCE_PROFILE["exportSizeGB"]), "postImportValue": str(SOURCE_PROFILE["exportSizeGB"]),
         "difference": "0.00", "unit": "GB", "valueSource": "Derived", "evaluationStatus": "Evaluated", "confidence": "High",
         "comparisonRuleId": "RUL-RECON-004", "tolerance": 0.5, "reconciliationStatus": "Matched", "rag": "Green", "reviewRequired": "No", "discrepancyId": "", "comments": ""},
        {"reconciliationMetricId": "RM-005", "metricCode": "MET-CHECKSUM-COVERAGE", "metricName": "Checksum evidence coverage", "entityScope": "Sequence",
         "baselineValue": "242 of 243", "importValue": "242 of 243", "postImportValue": "242 of 243", "difference": "1 accepted exception",
         "unit": "Count", "valueSource": "Derived", "evaluationStatus": "Warning", "confidence": "High", "comparisonRuleId": "RUL-RECON-005",
         "tolerance": 1.0, "reconciliationStatus": "Accepted Difference", "rag": "Amber", "reviewRequired": "Yes", "discrepancyId": "DISC-002", "comments": ""},
    ]

    file_size_reconciliation = [
        {"fileSizeComparisonId": "FSC-001", "entityType": "Portfolio", "entityId": "AUR-MIG-26-041", "metricCode": "MET-EXPORT-SIZE",
         "expectedValue": int(SOURCE_PROFILE["exportSizeGB"] * 1024**3), "observedValue": int(SOURCE_PROFILE["exportSizeGB"] * 1024**3), "difference": 0,
         "unit": "Bytes", "valueSource": "Derived", "evaluationStatus": "Evaluated", "confidence": "High", "comparisonRuleId": "RUL-RECON-004",
         "tolerance": 524288000.0, "acceptedException": "No", "exceptionId": "", "rag": "Green", "reconciliationStatus": "Matched",
         "reviewRequired": "No", "discrepancyId": "", "comments": ""},
        {"fileSizeComparisonId": "FSC-002", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016", "metricCode": "MET-SEQ-SIZE",
         "expectedValue": SEQUENCES_BY_DOSSIER["AUR-VIR-UK-016"][0]["sizeBytes"], "observedValue": SEQUENCES_BY_DOSSIER["AUR-VIR-UK-016"][0]["sizeBytes"], "difference": 0,
         "unit": "Bytes", "valueSource": "Derived", "evaluationStatus": "Warning", "confidence": "High", "comparisonRuleId": "RUL-RECON-004",
         "tolerance": 1048576.0, "acceptedException": "Yes", "exceptionId": "EXC-POST-002", "rag": "Amber", "reconciliationStatus": "Accepted Difference",
         "reviewRequired": "Yes", "discrepancyId": "DISC-001", "comments": "Size unaffected; staging-path normalization only."},
        {"fileSizeComparisonId": "FSC-003", "entityType": "Dossier", "entityId": "AUR-END-EU-017", "metricCode": "MET-SEQ-SIZE",
         "expectedValue": SEQUENCES_BY_DOSSIER["AUR-END-EU-017"][0]["sizeBytes"], "observedValue": SEQUENCES_BY_DOSSIER["AUR-END-EU-017"][0]["sizeBytes"], "difference": 0,
         "unit": "Bytes", "valueSource": "Derived", "evaluationStatus": "Warning", "confidence": "High", "comparisonRuleId": "RUL-RECON-004",
         "tolerance": 1048576.0, "acceptedException": "Yes", "exceptionId": "EXC-POST-001", "rag": "Amber", "reconciliationStatus": "Accepted Difference",
         "reviewRequired": "Yes", "discrepancyId": "DISC-002", "comments": "Size unaffected; checksum evidence unavailable only."},
    ]

    import_evidence = [
        {"importEvidenceId": "IMP-001", "sourceRowReference": "Import Report Detail!2", "sourceName": "MigrationSummary.xlsx",
         "dossierTitle": "EnduraMed", "submission": "0000", "rawStatus": "Warning", "rawStatusCode": "W02",
         "rawDescription": "Checksum file not found for source sequence; imported using directory listing evidence only.",
         "rawComments": "Covered by accepted exception EXC-POST-001.", "rawDate": "2026-07-13",
         "normalizedEvidenceCategory": "Accepted difference", "valueSource": "Imported", "evaluationStatus": "Warning",
         "rag": "Amber", "confidence": "High", "findingCode": "", "relatedDossierComparisonId": "DCMP-AUR-END-EU-017",
         "relatedSequenceComparisonId": f"SCMP-{SEQUENCES_BY_DOSSIER['AUR-END-EU-017'][0]['sequenceId']}", "reviewRequired": "Yes", "comments": ""},
        {"importEvidenceId": "IMP-002", "sourceRowReference": "Import Report Detail!3", "sourceName": "MigrationSummary.xlsx",
         "dossierTitle": "ViroNexa", "submission": "0000", "rawStatus": "Warning", "rawStatusCode": "W05",
         "rawDescription": "Source path normalized during staging due to length; content unaffected.",
         "rawComments": "Covered by accepted exception EXC-POST-002.", "rawDate": "2026-07-13",
         "normalizedEvidenceCategory": "Accepted difference", "valueSource": "Imported", "evaluationStatus": "Warning",
         "rag": "Amber", "confidence": "High", "findingCode": "", "relatedDossierComparisonId": "DCMP-AUR-VIR-UK-016",
         "relatedSequenceComparisonId": f"SCMP-{SEQUENCES_BY_DOSSIER['AUR-VIR-UK-016'][0]['sequenceId']}", "reviewRequired": "Yes", "comments": ""},
        {"importEvidenceId": "IMP-003", "sourceRowReference": "Import Report Detail!4", "sourceName": "MigrationSummary.xlsx",
         "dossierTitle": "Lumivera", "submission": "0000", "rawStatus": "OK", "rawStatusCode": "I00",
         "rawDescription": "Sequence imported without issue.", "rawComments": "", "rawDate": "2026-07-13",
         "normalizedEvidenceCategory": "Informational", "valueSource": "Imported", "evaluationStatus": "Evaluated",
         "rag": "Green", "confidence": "High", "findingCode": "", "relatedDossierComparisonId": "DCMP-AUR-LUM-EU-001",
         "relatedSequenceComparisonId": f"SCMP-{SEQUENCES_BY_DOSSIER['AUR-LUM-EU-001'][0]['sequenceId']}", "reviewRequired": "No", "comments": ""},
        {"importEvidenceId": "IMP-004", "sourceRowReference": "Import Report Detail!5", "sourceName": "MigrationSummary.xlsx",
         "dossierTitle": "Caldriva", "submission": "0000", "rawStatus": "OK", "rawStatusCode": "I00",
         "rawDescription": "Sequence imported without issue following confirmed EU classification.", "rawComments": "", "rawDate": "2026-07-13",
         "normalizedEvidenceCategory": "Informational", "valueSource": "Imported", "evaluationStatus": "Evaluated",
         "rag": "Green", "confidence": "High", "findingCode": "", "relatedDossierComparisonId": "DCMP-AUR-CAL-UN-018",
         "relatedSequenceComparisonId": f"SCMP-{SEQUENCES_BY_DOSSIER['AUR-CAL-UN-018'][0]['sequenceId']}", "reviewRequired": "No", "comments": ""},
    ]

    discrepancies = [
        {"discrepancyId": "DISC-001", "priority": "Medium", "discrepancyType": "Path normalization", "entityType": "Sequence",
         "entityId": SEQUENCES_BY_DOSSIER["AUR-VIR-UK-016"][0]["sequenceId"], "dossierId": "AUR-VIR-UK-016",
         "sequenceId": SEQUENCES_BY_DOSSIER["AUR-VIR-UK-016"][0]["sequenceId"],
         "expectedValue": SEQUENCES_BY_DOSSIER["AUR-VIR-UK-016"][0]["sequencePath"],
         "observedValue": rf"{PROJECT['stagingRoot']}\AUR-VIR-UK-016_ViroNexa\0000_normalized",
         "evidenceSource": "Post Import Verification", "evidenceReference": "Post Import Verification!2",
         "valueSource": "Derived", "evaluationStatus": "Warning", "originalRAG": "Amber", "rag": "Amber", "confidence": "High",
         "severity": "Low", "impact": "Path recorded differently from original source path; content and size unaffected.",
         "recommendationCode": "", "recommendedAction": "Retain the accepted-exception evidence in the migration record.",
         "owner": "Migration Lead", "status": "Completed", "reviewRequired": "Yes", "comments": ""},
        {"discrepancyId": "DISC-002", "priority": "Medium", "discrepancyType": "Checksum evidence", "entityType": "Sequence",
         "entityId": SEQUENCES_BY_DOSSIER["AUR-END-EU-017"][0]["sequenceId"], "dossierId": "AUR-END-EU-017",
         "sequenceId": SEQUENCES_BY_DOSSIER["AUR-END-EU-017"][0]["sequenceId"],
         "expectedValue": "Checksum file present", "observedValue": "Checksum file unavailable",
         "evidenceSource": "Import Report Detail", "evidenceReference": "Import Report Detail!2",
         "valueSource": "Derived", "evaluationStatus": "Warning", "originalRAG": "Amber", "rag": "Amber", "confidence": "High",
         "severity": "Low", "impact": "Historical checksum evidence unavailable; source inventory and review evidence otherwise complete.",
         "recommendationCode": "", "recommendedAction": "Retain the accepted-exception evidence in the migration record.",
         "owner": "Migration Lead", "status": "Completed", "reviewRequired": "Yes", "comments": ""},
    ]

    actions = [
        {"actionId": "ACT-POST-001", "discrepancyId": "DISC-001", "priority": "Low", "actionCategory": "Documentation",
         "requiredAction": "File the staging-path normalization evidence with the migration record.", "responsibleParty": "Migration Lead",
         "targetDate": "2026-07-15", "status": "Completed", "completionEvidence": "Evidence filed 2026-07-14.",
         "acceptanceCriteria": "Evidence attached to the migration record.", "reviewRequired": "No", "comments": ""},
    ]

    accepted_exceptions = [
        {"exceptionId": "EXC-POST-001", "sourceExceptionId": "EXC-PM-001", "exceptionPolicyId": "POL-EVIDENCE-001",
         "findingOrDiscrepancyId": "DISC-002", "entityType": "Dossier", "entityId": "AUR-END-EU-017",
         "originalEvaluationStatus": "Warning", "originalRAG": "Amber", "originalReconciliationImpact": "Accepted Difference",
         "originalEvidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-END-EU-017_EnduraMed",
         "acceptedEffect": "AcknowledgeOnly", "justification": "EnduraMed contains legacy NeeS sequences for which historical checksum evidence is unavailable, but source inventory and controlled review evidence are available.",
         "approvedBy": "Migration Lead", "approvalDate": "2026-07-13", "evidenceReference": "Import Report Detail!2",
         "exceptionStatus": "Accepted", "reviewRequired": "Yes", "comments": ""},
        {"exceptionId": "EXC-POST-002", "sourceExceptionId": "EXC-PM-002", "exceptionPolicyId": "POL-TECHNICAL-002",
         "findingOrDiscrepancyId": "DISC-001", "entityType": "Dossier", "entityId": "AUR-VIR-UK-016",
         "originalEvaluationStatus": "Warning", "originalRAG": "Amber", "originalReconciliationImpact": "Accepted Difference",
         "originalEvidenceReference": rf"{PROJECT['primarySourceRoot']}\AUR-VIR-UK-016_ViroNexa",
         "acceptedEffect": "AcknowledgeOnly", "justification": "One historical ViroNexa path required controlled staging-path normalization because the original source path exceeded the supported operational threshold.",
         "approvedBy": "Migration Lead", "approvalDate": "2026-07-13", "evidenceReference": "Post Import Verification!2",
         "exceptionStatus": "Accepted", "reviewRequired": "Yes", "comments": ""},
    ]

    raw_import_report_detail = [
        {"sourceName": "MigrationSummary.xlsx", "dossierTitle": "EnduraMed", "submission": "0000", "status": "Warning",
         "statusCode": "W02", "description": "Checksum file not found for source sequence; imported using directory listing evidence only.",
         "comments": "Covered by accepted exception EXC-POST-001.", "date": "2026-07-13"},
    ]

    raw_post_import_verification = [
        {"dossierTitle": "ViroNexa", "sequenceCount": 12, "dossierDirectory": rf"{PROJECT['stagingRoot']}\AUR-VIR-UK-016_ViroNexa",
         "submissionTitle": "Sequence 0000", "submissionDirectory": rf"{PROJECT['stagingRoot']}\AUR-VIR-UK-016_ViroNexa\0000_normalized",
         "region": "UK", "createdDate": "2026-07-13"},
    ]

    summary_metrics = [
        {"area": "Report Context", "metric": "Customer / Project", "value": f"{PROJECT['customerName']} / {PROJECT['projectName']}", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Target Environment", "value": PROJECT["targetEnvironment"], "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "CustomerProvided", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Baseline Identifier", "value": "AUR-MIG-26-041-BASELINE-001", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Baseline Workbook", "value": "Aurelis_Migration_Readiness_AUR-MIG-26-041.xlsx", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "MigrationSummary Workbook", "value": "MigrationSummary.xlsx", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Imported", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Raw Evidence Included", "value": "Yes", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Generated At UTC", "value": excel_dt(POSTMIGRATION_START + timedelta(seconds=POSTMIGRATION_DURATION_S)), "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "ExecutionId", "value": execution_id, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Report Status", "value": "Draft", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Reviewed By", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Report Context", "metric": "Review Date", "value": "Not yet reviewed", "evaluationStatus": "NotAssessed", "rag": "Unknown", "confidence": "Unknown", "valueSource": "Observed", "reviewRequired": "No"},
        {"area": "Dossier Reconciliation", "metric": "Expected Dossier Count", "value": 18, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Dossier Reconciliation", "metric": "Migrated Dossier Count", "value": 18, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Dossier Reconciliation", "metric": "Matched Dossier Count", "value": 18, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Dossier Reconciliation", "metric": "Missing Dossier Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Dossier Reconciliation", "metric": "Extra Dossier Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Sequence Reconciliation", "metric": "Expected Sequence Count", "value": 243, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Sequence Reconciliation", "metric": "Migrated Sequence Count", "value": 243, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Sequence Reconciliation", "metric": "Matched Sequence Count", "value": 241, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Sequence Reconciliation", "metric": "Missing Sequence Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Sequence Reconciliation", "metric": "Extra Sequence Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Import Evidence", "metric": "Import OK Count", "value": 2, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Import Evidence", "metric": "Import Warning Count", "value": 2, "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Import Evidence", "metric": "Import Error Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Review", "metric": "Accepted Exception Count", "value": 2, "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Review", "metric": "Unresolved Discrepancy Count", "value": 0, "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Final Reconciliation Result", "value": "Reconciled with Accepted Exceptions", "evaluationStatus": "Warning", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Primary Discrepancy Drivers", "value": "Staging-path normalization (ViroNexa); unavailable legacy checksum evidence (EnduraMed).", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Limitations", "value": "Two sequence-level differences are covered by documented accepted exceptions carried forward from Migration Readiness.", "evaluationStatus": "Evaluated", "rag": "Amber", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
        {"area": "Decision", "metric": "Recommended Next Action", "value": "Close the migration record; no further reconciliation action required.", "evaluationStatus": "Evaluated", "rag": "Green", "confidence": "High", "valueSource": "Derived", "reviewRequired": "No"},
    ]

    assumptions = [
        {"section": "Purpose", "item": "Intended use", "detail": "Reconciliation of migrated evidence for the Aurelis Regulatory Content Migration 2026 project against the approved Migration Readiness baseline.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Read-only assessment", "detail": "MigrationSummary.xlsx and post-import verification evidence were read only; no source or migrated content was modified.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Non-validation statement", "detail": "This report does not constitute formal regulatory validation, customer acceptance or migration sign-off.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Boundary", "item": "Evidence limitation", "detail": "Two accepted exceptions carried forward from Migration Readiness are retained here without erasing the original discrepancy record.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Input", "item": "Import Report Detail", "detail": "Raw import-report rows are preserved exactly as supplied in MigrationSummary.xlsx; one representative row is included.", "valueSource": "Imported", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "Migration Lead", "status": "Open", "comments": ""},
        {"section": "Input", "item": "Post Import Verification", "detail": "Raw post-import verification rows are preserved exactly as supplied; one representative row is included.", "valueSource": "Imported", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "Migration Lead", "status": "Open", "comments": ""},
        {"section": "Comparison", "item": "Stable identifiers", "detail": "Dossier and sequence comparisons use the stable comparison identifiers carried forward from the Migration Readiness baseline.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
        {"section": "Exception", "item": "Evidence preservation", "detail": "Accepted exceptions EXC-POST-001 and EXC-POST-002 preserve the original discrepancy and evidence from Migration Readiness.", "valueSource": "Derived", "evaluationStatus": "Evaluated", "reviewRequired": "No", "owner": "eMAS Product Owner", "status": "Open", "comments": ""},
    ]

    return {
        "phaseCode": "POST_MIGRATION", "phaseName": "Post-Migration Verification", "mappingId": "EMAS-MAP-POSTMIGRATION",
        "mappingVersion": "1.0.0", "templateId": "EMAS-TPL-POSTMIGRATION", "templateVersion": "1.1.1",
        "executionId": execution_id, "generatedAtUtc": (POSTMIGRATION_START + timedelta(seconds=POSTMIGRATION_DURATION_S)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "finalResult": "Reconciled with Accepted Exceptions",
        "verificationScope": verification_scope, "baselineComparison": baseline_comparison,
        "dossierReconciliation": dossier_reconciliation, "sequenceReconciliation": sequence_reconciliation,
        "fileSizeReconciliation": file_size_reconciliation, "importEvidence": import_evidence,
        "discrepancies": discrepancies, "actions": actions, "acceptedExceptions": accepted_exceptions,
        "rawImportReportDetail": raw_import_report_detail, "rawPostImportVerification": raw_post_import_verification,
        "assumptions": assumptions, "summaryMetrics": summary_metrics,
        "executionMetadata": execution_rows, "reviewMetadata": review_rows,
    }


write_json(HERE / "aurelis-post-migration-result.json", build_post_migration())
print("Wrote aurelis-post-migration-result.json")
