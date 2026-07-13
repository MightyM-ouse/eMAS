#!/usr/bin/env python3
"""Reference reader/exporter for the synthetic eMAS mapping workbook POC.

Uses only Python standard library to independently verify the XLSX table contract.
It is not a runtime or customer dependency and does not replace the VBA exporter.
"""
from __future__ import annotations

import argparse
import copy
import json
import re
import zipfile
from collections import OrderedDict, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable
from xml.etree import ElementTree as ET

NS_MAIN = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NS_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
NS_DOC_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

@dataclass(frozen=True)
class PocIssue:
    code: str
    table: str
    row: int
    field: str
    message: str

    def render(self) -> str:
        location = self.table
        if self.row:
            location += f"[{self.row}]"
        if self.field:
            location += f".{self.field}"
        return f"{self.code} {location}: {self.message}"

REQUIRED_TABLE_COLUMNS: dict[str, tuple[str, ...]] = {
    "tblConfiguration": ("ConfigurationId", "SchemaVersion", "MappingVersion", "SourceWorkbookVersion", "MinimumEngineVersion", "ExportType", "ExportedAtUtc", "ExportedBy", "Status", "ValidationRunId"),
    "tblValueLists": ("ListName", "Code", "DisplayValue", "Status", "EffectiveFrom"),
    "tblFieldCatalogue": ("FieldCode", "DisplayName", "DataType", "ValueSource", "ProducingComponent", "EvaluationOrder", "IsSensitive"),
    "tblFieldAllowedOperators": ("FieldCode", "Operator"),
    "tblFieldPhases": ("FieldCode", "Phase"),
    "tblMetricCatalogue": ("MetricCode", "DisplayName", "DataType", "Unit", "CalculationSource", "RequiredForCompleteBanding", "RoundingRule"),
    "tblMetricPhases": ("MetricCode", "Phase"),
    "tblMasterDataRelationships": ("RelationshipId", "RelationshipType", "SourceEntityType", "SourceEntityCode", "TargetEntityType", "TargetEntityCode", "Cardinality", "IsMandatory", "Status", "EffectiveFrom", "SourceReference"),
    "tblRules": ("RuleId", "RuleRevision", "RuleType", "Title", "Description", "Status", "EffectiveFrom", "Priority", "ConflictStrategy", "Specificity", "StopProcessing", "RequirementReference"),
    "tblRulePhaseAssignments": ("RulePhaseId", "RuleId", "Phase", "EvaluationStatusOnMissingInput", "IsBlocker", "ExceptionEligible", "Sequence"),
    "tblConditionGroups": ("ConditionGroupId", "RuleId", "GroupSequence", "GroupOperator"),
    "tblRuleConditions": ("ConditionId", "RuleId", "ConditionGroupId", "Sequence", "FieldCode", "Operator", "CaseSensitive", "Negate"),
    "tblRuleOutputs": ("RuleOutputId", "RuleId", "Phase", "OutputType", "OutputCode", "Sequence"),
    "tblFindings": ("FindingCode", "Title", "FindingCategory", "Description", "DefaultEvaluationStatus", "ExceptionEligible", "CustomerVisible", "Status", "EffectiveFrom", "SourceReference"),
    "tblRecommendations": ("RecommendationCode", "Title", "CustomerFacingText", "ConsultantFacingText", "Priority", "Status", "EffectiveFrom", "SourceReference"),
    "tblFindingRecommendationLinks": ("LinkId", "FindingCode", "RecommendationCode", "Phase", "LinkType", "Sequence", "Status", "EffectiveFrom"),
    "tblExceptionPolicies": ("ExceptionPolicyId", "EligibleFindingCode", "AllowedEffect", "RequiredApproverRole", "EvidenceRequirement", "ExpiryRequired", "CarryForwardToPostMigration", "Status", "EffectiveFrom", "SourceReference"),
    "tblAliases": ("AliasId", "AliasScope", "SourceSystem", "SourceFieldOrValue", "CanonicalEntityType", "CanonicalCode", "Status", "EffectiveFrom", "SourceReference"),
    "tblConflictPolicies": ("ConflictPolicyId", "RuleType", "ConflictStrategy", "TieBehavior", "StopBehavior", "DefaultPriorityIncrement", "Status", "Description"),
    "tblRagPolicies": ("RagPolicyId", "Scope", "AggregationStrategy", "GreenDefinition", "AmberDefinition", "RedDefinition", "UnknownDefinition", "Status", "SourceReference"),
    "tblConfidencePolicies": ("ConfidencePolicyId", "Scope", "EvidenceStrength", "WeightOrScore", "AgreementRequirement", "MissingEvidenceBehavior", "Status", "EffectiveFrom", "SourceReference"),
    "tblEffortDriverDefinitions": ("EffortDriverId", "DriverCode", "DriverName", "Category", "Weight", "MinimumBandOverrideEligible", "Status", "EffectiveFrom", "SourceReference"),
    "tblEffortDriverPhases": ("EffortDriverId", "Phase"),
    "tblEffortThresholds": ("EffortThresholdId", "ThresholdScopeType", "ThresholdScopeCode", "BandCode", "LowerInclusive", "UpperInclusive", "Unit", "Status", "EffectiveFrom", "SourceReference"),
    "tblDecisionPolicies": ("DecisionPolicyId", "Phase", "ResultCode", "Priority", "RequiredConditionType", "RequiredConditionReference", "MandatoryBlockerOverride", "ExceptionBehavior", "Status", "EffectiveFrom", "SourceReference"),
    "tblQuestionnaireMap": ("QuestionnaireMapId", "TriggerType", "TriggerCode", "QuestionCode", "CustomerQuestion", "Reason", "Priority", "SupportedPhase", "Status", "EffectiveFrom", "SourceReference"),
    "tblReportDefinitions": ("ReportDefinitionId", "Phase", "ReportCode", "DisplayTitle", "SheetCode", "SheetDisplayName", "ColumnCode", "ColumnDisplayName", "DataType", "Required", "Sequence", "SourceReference"),
    "tblPhaseResults": ("Phase", "Code", "DisplayValue", "Status", "EffectiveFrom"),
}

MASTER_TABLES = OrderedDict([
    ("regions", ("tblRegions", "RegionCode")),
    ("authorities", ("tblAuthorities", "AuthorityCode")),
    ("technicalStandards", ("tblTechnicalStandards", "TechnicalStandardCode")),
    ("regionalImplementations", ("tblRegionalImplementations", "RegionalImplementationCode")),
    ("productDomains", ("tblProductDomains", "ProductDomainCode")),
    ("lifecycleContexts", ("tblLifecycleContexts", "LifecycleContextCode")),
    ("productClasses", ("tblProductClasses", "ProductClassCode")),
    ("procedureContexts", ("tblProcedureContexts", "ProcedureContextCode")),
    ("sourcePresentations", ("tblSourcePresentations", "SourcePresentationCode")),
])

ENTITY_TABLES = {
    "REGION": ("tblRegions", "RegionCode"),
    "AUTHORITY": ("tblAuthorities", "AuthorityCode"),
    "TECHNICAL_STANDARD": ("tblTechnicalStandards", "TechnicalStandardCode"),
    "REGIONAL_IMPLEMENTATION": ("tblRegionalImplementations", "RegionalImplementationCode"),
    "PRODUCT_DOMAIN": ("tblProductDomains", "ProductDomainCode"),
    "LIFECYCLE_CONTEXT": ("tblLifecycleContexts", "LifecycleContextCode"),
    "PRODUCT_CLASS": ("tblProductClasses", "ProductClassCode"),
    "PROCEDURE_CONTEXT": ("tblProcedureContexts", "ProcedureContextCode"),
    "SOURCE_PRESENTATION": ("tblSourcePresentations", "SourcePresentationCode"),
}

RELATIONSHIP_ENDPOINTS = {
    "AUTHORITY_TO_REGION": ("AUTHORITY", "REGION"),
    "AUTHORITY_TO_TECHNICAL_STANDARD": ("AUTHORITY", "TECHNICAL_STANDARD"),
    "AUTHORITY_TO_REGIONAL_IMPLEMENTATION": ("AUTHORITY", "REGIONAL_IMPLEMENTATION"),
    "TECHNICAL_STANDARD_TO_REGION": ("TECHNICAL_STANDARD", "REGION"),
    "TECHNICAL_STANDARD_TO_REGIONAL_IMPLEMENTATION": ("TECHNICAL_STANDARD", "REGIONAL_IMPLEMENTATION"),
    "PRODUCT_DOMAIN_TO_TECHNICAL_STANDARD": ("PRODUCT_DOMAIN", "TECHNICAL_STANDARD"),
    "PRODUCT_DOMAIN_TO_REGION": ("PRODUCT_DOMAIN", "REGION"),
    "LIFECYCLE_CONTEXT_TO_TECHNICAL_STANDARD": ("LIFECYCLE_CONTEXT", "TECHNICAL_STANDARD"),
    "PRODUCT_CLASS_TO_TECHNICAL_STANDARD": ("PRODUCT_CLASS", "TECHNICAL_STANDARD"),
    "PROCEDURE_CONTEXT_TO_TECHNICAL_STANDARD": ("PROCEDURE_CONTEXT", "TECHNICAL_STANDARD"),
    "PROCEDURE_CONTEXT_TO_REGIONAL_IMPLEMENTATION": ("PROCEDURE_CONTEXT", "REGIONAL_IMPLEMENTATION"),
    "SOURCE_PRESENTATION_TO_TECHNICAL_STANDARD": ("SOURCE_PRESENTATION", "TECHNICAL_STANDARD"),
    "RULE_SUPERSESSION": ("RULE", "RULE"),
}

BOOL_FIELDS = {
    "IsSensitive", "RequiredForCompleteBanding", "IsMandatory", "StopProcessing", "IsBlocker",
    "ExceptionEligible", "CaseSensitive", "Negate", "CustomerVisible", "ExpiryRequired",
    "CarryForwardToPostMigration", "MinimumBandOverrideEligible", "LowerInclusive", "UpperInclusive",
    "MandatoryBlockerOverride", "Required",
}
INT_FIELDS = {"EvaluationOrder", "RuleRevision", "Priority", "Specificity", "Sequence", "GroupSequence", "DefaultPriorityIncrement", "MaximumValidityDays"}
NUMBER_FIELDS = {"WeightOrScore", "Weight", "Cap", "Floor", "LowerBound", "UpperBound", "OutputValue"}

KEYS = {
    "tblRules": "RuleId",
    "tblRulePhaseAssignments": "RulePhaseId",
    "tblConditionGroups": "ConditionGroupId",
    "tblRuleConditions": "ConditionId",
    "tblRuleOutputs": "RuleOutputId",
    "tblFindings": "FindingCode",
    "tblRecommendations": "RecommendationCode",
    "tblFindingRecommendationLinks": "LinkId",
    "tblExceptionPolicies": "ExceptionPolicyId",
    "tblAliases": "AliasId",
    "tblMasterDataRelationships": "RelationshipId",
    "tblConflictPolicies": "ConflictPolicyId",
    "tblRagPolicies": "RagPolicyId",
    "tblConfidencePolicies": "ConfidencePolicyId",
    "tblEffortDriverDefinitions": "EffortDriverId",
    "tblEffortThresholds": "EffortThresholdId",
    "tblDecisionPolicies": "DecisionPolicyId",
    "tblQuestionnaireMap": "QuestionnaireMapId",
    "tblReportDefinitions": "ReportDefinitionId",
}
for _, (table, key) in MASTER_TABLES.items():
    KEYS[table] = key


def _col_index(cell_ref: str) -> int:
    letters = re.match(r"[A-Z]+", cell_ref.upper())
    if not letters:
        raise ValueError(cell_ref)
    total = 0
    for ch in letters.group(0):
        total = total * 26 + (ord(ch) - 64)
    return total


def _split_ref(ref: str) -> tuple[int, int, int, int]:
    start, end = ref.split(":")
    sr = int(re.search(r"\d+", start).group())
    er = int(re.search(r"\d+", end).group())
    return sr, _col_index(start), er, _col_index(end)


def _shared_strings(zf: zipfile.ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in zf.namelist():
        return []
    root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
    result = []
    for si in root.findall(f"{{{NS_MAIN}}}si"):
        result.append("".join(t.text or "" for t in si.iter(f"{{{NS_MAIN}}}t")))
    return result


def _cell_value(cell: ET.Element, shared: list[str]) -> Any:
    t = cell.attrib.get("t")
    v = cell.find(f"{{{NS_MAIN}}}v")
    text = v.text if v is not None else ""
    if t in {"str", "inlineStr"}:
        if t == "inlineStr":
            return "".join(x.text or "" for x in cell.iter(f"{{{NS_MAIN}}}t"))
        return text
    if t == "s":
        return shared[int(text)] if text else ""
    if t == "b":
        return text == "1"
    if text == "":
        return ""
    try:
        number = float(text)
        return int(number) if number.is_integer() else number
    except ValueError:
        return text


def read_xlsx_tables(path: Path) -> dict[str, list[dict[str, Any]]]:
    with zipfile.ZipFile(path) as zf:
        shared = _shared_strings(zf)
        wb_root = ET.fromstring(zf.read("xl/workbook.xml"))
        wb_rels_root = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
        wb_rels = {rel.attrib["Id"]: rel.attrib["Target"].lstrip("/") for rel in wb_rels_root.findall(f"{{{NS_REL}}}Relationship")}
        tables: dict[str, list[dict[str, Any]]] = {}
        for sheet in wb_root.find(f"{{{NS_MAIN}}}sheets"):
            rid = sheet.attrib[f"{{{NS_DOC_REL}}}id"]
            sheet_path = wb_rels[rid]
            sheet_name = Path(sheet_path).name
            rel_path = f"xl/worksheets/_rels/{sheet_name}.rels"
            if rel_path not in zf.namelist():
                continue
            rel_root = ET.fromstring(zf.read(rel_path))
            table_targets = [rel.attrib["Target"].lstrip("/") for rel in rel_root.findall(f"{{{NS_REL}}}Relationship") if rel.attrib.get("Type", "").endswith("/table")]
            if not table_targets:
                continue
            sheet_root = ET.fromstring(zf.read(sheet_path))
            cell_map = {cell.attrib["r"]: _cell_value(cell, shared) for cell in sheet_root.iter(f"{{{NS_MAIN}}}c")}
            for table_path in table_targets:
                table_root = ET.fromstring(zf.read(table_path))
                table_name = table_root.attrib["name"]
                sr, sc, er, ec = _split_ref(table_root.attrib["ref"])
                headers = [col.attrib["name"] for col in table_root.find(f"{{{NS_MAIN}}}tableColumns")]
                rows: list[dict[str, Any]] = []
                for row_num in range(sr + 1, er + 1):
                    row: dict[str, Any] = {}
                    for offset, header in enumerate(headers):
                        col_num = sc + offset
                        n, letters = col_num, ""
                        while n:
                            n, r = divmod(n - 1, 26)
                            letters = chr(65 + r) + letters
                        value = cell_map.get(f"{letters}{row_num}", "")
                        if header in BOOL_FIELDS and value != "":
                            if isinstance(value, str):
                                value = value.strip().lower() in {"true", "1", "yes"}
                            else:
                                value = bool(value)
                        elif header in INT_FIELDS and value != "":
                            value = int(value)
                        elif header in NUMBER_FIELDS and value != "":
                            value = float(value)
                            if value.is_integer():
                                value = int(value)
                        row[header] = value
                    if any(value not in ("", None) for value in row.values()):
                        rows.append(row)
                tables[table_name] = rows
        return tables


def _camel(name: str) -> str:
    if name == "RAG":
        return "rag"
    if name == "DefaultRAG":
        return "defaultRag"
    if name == "RagPolicyId":
        return "ragPolicyId"
    return name[:1].lower() + name[1:]


def _clean_row(row: dict[str, Any], exclude: Iterable[str] = ()) -> OrderedDict[str, Any]:
    excluded = set(exclude)
    result: OrderedDict[str, Any] = OrderedDict()
    for key, value in row.items():
        if key in excluded or value in ("", None):
            continue
        result[_camel(key)] = value
    return result


def build_runtime_json(tables: dict[str, list[dict[str, Any]]]) -> OrderedDict[str, Any]:
    result: OrderedDict[str, Any] = OrderedDict()
    result["configuration"] = _clean_row(tables["tblConfiguration"][0])

    grouped_lists: OrderedDict[str, list[Any]] = OrderedDict()
    for row in tables["tblValueLists"]:
        grouped_lists.setdefault(str(row["ListName"]), []).append(_clean_row(row, {"ListName"}))
    result["valueLists"] = grouped_lists

    operators = defaultdict(list)
    for row in tables["tblFieldAllowedOperators"]:
        operators[row["FieldCode"]].append(row["Operator"])
    field_phases = defaultdict(list)
    for row in tables["tblFieldPhases"]:
        field_phases[row["FieldCode"]].append(row["Phase"])
    fields = []
    for row in tables["tblFieldCatalogue"]:
        item = _clean_row(row)
        item["allowedOperators"] = operators[row["FieldCode"]]
        item["supportedPhases"] = field_phases[row["FieldCode"]]
        fields.append(item)
    result["fieldCatalogue"] = fields

    metric_phases = defaultdict(list)
    for row in tables["tblMetricPhases"]:
        metric_phases[row["MetricCode"]].append(row["Phase"])
    metrics = []
    for row in tables["tblMetricCatalogue"]:
        item = _clean_row(row)
        item["supportedPhases"] = metric_phases[row["MetricCode"]]
        metrics.append(item)
    result["metricCatalogue"] = metrics

    master: OrderedDict[str, Any] = OrderedDict()
    for json_name, (table_name, _) in MASTER_TABLES.items():
        master[json_name] = [_clean_row(row) for row in tables[table_name]]
    result["masterData"] = master
    result["relationships"] = [_clean_row(row) for row in tables["tblMasterDataRelationships"]]
    result["rules"] = [_clean_row(row) for row in tables["tblRules"]]
    result["rulePhases"] = [_clean_row(row) for row in tables["tblRulePhaseAssignments"]]
    result["conditionGroups"] = [_clean_row(row) for row in tables["tblConditionGroups"]]
    result["ruleConditions"] = [_clean_row(row) for row in tables["tblRuleConditions"]]
    result["ruleOutputs"] = [_clean_row(row) for row in tables["tblRuleOutputs"]]
    result["findings"] = [_clean_row(row) for row in tables["tblFindings"]]
    result["recommendations"] = [_clean_row(row) for row in tables["tblRecommendations"]]
    result["findingRecommendationLinks"] = [_clean_row(row) for row in tables["tblFindingRecommendationLinks"]]
    result["exceptionPolicies"] = [_clean_row(row) for row in tables["tblExceptionPolicies"]]
    result["aliases"] = [_clean_row(row) for row in tables["tblAliases"]]

    effort_phases = defaultdict(list)
    for row in tables["tblEffortDriverPhases"]:
        effort_phases[row["EffortDriverId"]].append(row["Phase"])
    drivers = []
    for row in tables["tblEffortDriverDefinitions"]:
        item = _clean_row(row)
        item["supportedPhases"] = effort_phases[row["EffortDriverId"]]
        drivers.append(item)
    policies: OrderedDict[str, Any] = OrderedDict()
    policies["conflictPolicies"] = [_clean_row(row) for row in tables["tblConflictPolicies"]]
    policies["ragPolicies"] = [_clean_row(row) for row in tables["tblRagPolicies"]]
    policies["confidencePolicies"] = [_clean_row(row) for row in tables["tblConfidencePolicies"]]
    policies["effortDrivers"] = drivers
    policies["effortThresholds"] = [_clean_row(row) for row in tables["tblEffortThresholds"]]
    policies["decisionPolicies"] = [_clean_row(row) for row in tables["tblDecisionPolicies"]]
    result["policies"] = policies
    result["questionnaireMap"] = [_clean_row(row) for row in tables["tblQuestionnaireMap"]]

    phase_results: OrderedDict[str, list[Any]] = OrderedDict((phase, []) for phase in ("PRE_SALES", "PRE_MIGRATION", "POST_MIGRATION"))
    for row in tables["tblPhaseResults"]:
        phase_results[row["Phase"]].append(_clean_row(row, {"Phase"}))
    report: OrderedDict[str, Any] = OrderedDict()
    report["definitions"] = [_clean_row(row) for row in tables["tblReportDefinitions"]]
    report["phaseResults"] = phase_results
    result["reportTerminology"] = report
    return result
