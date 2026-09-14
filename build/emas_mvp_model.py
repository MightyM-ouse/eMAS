"""Source-controlled, deterministic v4.4 MVP workbook model.

The approved catalogue tables in CFG-MVP are the structured seed. This module
normalizes them into typed row dictionaries; it never reads customer evidence.
The older XLSM POC model is intentionally separate because its 43-table contract
and VBA export are not the v4.4 workbook contract.
"""
from __future__ import annotations

import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIREMENTS = ROOT / "docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md"
DOC = REQUIREMENTS.read_text(encoding="utf-8")
SOURCE_ID = "SRC-CFG-MVP-44"
PHASES = ("PreSales", "PreMigration", "PostMigration")
SHEETS = (
    "00_Home", "01_Migration_Scenarios", "02_Scenario_Questionnaire",
    "03_Scenario_Derivation_Rules", "04_Assessment_Modules", "05_Scenario_Module_Map",
    "06_Requirement_Catalogue", "07_Fields_Evidence", "08_Regulatory_Profiles",
    "09_Dossier_Sequence_ID", "10_Folder_File_Structure", "11_Missing_Refs_Integrity",
    "12_Technical_Observations", "13_Size_Volume_Metrics", "14_Source_DB_Archive_DMS",
    "15_RAG_Severity", "16_Confidence", "17_Effort_Drivers", "18_Findings",
    "19_Recommendations_Actions", "20_PreMigration_Readiness",
    "21_PostMigration_Reconciliation", "22_Value_Lists", "23_Source_References",
    "24_Final_Config_Master", "25_JSON_Field_Map", "26_JSON_Preview",
    "27_Validation_Results",
)
GENERATED = {"24_Final_Config_Master", "26_JSON_Preview", "27_Validation_Results"}


def _section(marker: str, next_marker: str | None = None) -> str:
    start = DOC.index(marker)
    end = DOC.find(next_marker, start + len(marker)) if next_marker else -1
    return DOC[start:end if end >= 0 else None]


def _tables(section: str) -> list[list[dict[str, str]]]:
    result: list[list[dict[str, str]]] = []
    lines = section.splitlines()
    i = 0
    while i < len(lines):
        if not lines[i].startswith("|") or i + 1 >= len(lines) or not re.match(r"^\|[-: |]+\|$", lines[i + 1]):
            i += 1
            continue
        headers = [c.strip() for c in lines[i].strip("|").split("|")]
        i += 2
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            cells = [re.sub(r"`", "", c.strip()) for c in lines[i].strip("|").split("|")]
            if len(cells) == len(headers):
                rows.append(dict(zip(headers, cells)))
            i += 1
        result.append(rows)
    return result


def _spec_columns(section_number: int) -> list[str]:
    marker = f"### 9.{section_number} `"
    block = _section(marker, f"### 9.{section_number + 1} `" if section_number < 28 else "## 10.")
    first = _tables(block)[0]
    key = "Column" if "Column" in first[0] else next(iter(first[0]))
    return [row[key] for row in first if row[key] != "Common rule columns"]


COMMON_RULE_COLUMNS = [r["Column"] for r in _tables(_section("### 8.2 Common rule columns", "### 8.3"))[0]]


def columns() -> OrderedDict[str, list[str]]:
    out: OrderedDict[str, list[str]] = OrderedDict()
    out["00_Home"] = []
    for i, name in enumerate(SHEETS[1:24], start=2):
        cols = _spec_columns(i)
        if name == "03_Scenario_Derivation_Rules":
            cols.insert(1, "RequirementId")
        if name in SHEETS[9:13]:
            cols = COMMON_RULE_COLUMNS + cols
        out[name] = cols
    out["24_Final_Config_Master"] = [
        "SelectedScenarioId", "Phase", "ModuleId", "ModuleApplicability",
        "RequirementId", "RequirementTitle", "RequirementStatement", "SourceSheet",
        "SourceRecordId", "RecordType", "InclusionStatus", "InclusionReason",
        "JSONPath", "ReferencedBy", "ValidationStatus", "EngineCapability",
    ]
    out["25_JSON_Field_Map"] = _spec_columns(26)
    out["26_JSON_Preview"] = ["Section", "ObjectCount", "ValidationStatus", "Preview", "SourceSheet"]
    out["27_Validation_Results"] = [
        "ValidationId", "Severity", "ControlCode", "SheetName", "RecordId",
        "ColumnName", "Message", "WhyItMatters", "CorrectiveAction", "Blocking",
        "SelectedScenarioId",
    ]
    assert tuple(out) == SHEETS, tuple(out)
    return out


SCENARIO_ATTRIBUTES = (
    ("MS-01", "eCTDmanager", "Yes", "eCTDmanager", "SQLServer", "DatabaseArchive", False, False),
    ("MS-02", "eCTDmanager", "Yes", "eCTDmanager", "Access", "DatabaseArchive", False, False),
    ("MS-03", "eCTDmanager", "Yes", "eCTDmanager", "Oracle", "DatabaseArchive", False, False),
    ("MS-04", "RegulatoryExport", "No", "RegulatoryExport", "NotApplicable", "ExportImport", False, False),
    ("MS-05", "Hybrid", "Partial", "Hybrid", "Unknown", "Hybrid", True, False),
    ("MS-06", "ArchiveStorage", "Unknown", "ArchiveStorage", "NotApplicable", "ArchiveOnly", False, False),
    ("MS-07", "Pending", "Unknown", "Unknown", "Unknown", "Unknown", False, True),
    ("MS-08", "ThirdPartySystemOrDMS", "No", "ThirdPartySystemOrDMS", "Unknown", "Adapter", False, False),
)


def scenarios() -> list[dict]:
    source = _tables(_section("## 5. Migration scenario catalogue", "## 6."))[0]
    out = []
    for n, (item, attr) in enumerate(zip(source, SCENARIO_ATTRIBUTES), 1):
        sid, family, existing, category, db, method, mixed, fallback = attr
        assert item["ScenarioId"] == sid
        out.append(dict(ScenarioId=sid, ScenarioCode=item["ScenarioCode"],
            ScenarioName=item["Scenario name"], ScenarioFamily=family,
            BusinessDescription=item["Selection basis"] + ". " + item["Principal focus"],
            ExistingECTDManager=existing, SourceSystemCategory=category,
            SourceDatabaseType=db, PrimaryMigrationMethod=method,
            TargetPlatform="ToBeDefined" if fallback else "eCTDmanager",
            SupportsMixedScope=mixed, FallbackScenario=fallback, DisplaySequence=n,
            IsActive=True, SourceId=SOURCE_ID,
            Notes="Unsupported target routes must resolve to MS-07 / NeedsReview." if fallback else ""))
    return out


QUESTION_ORDER = (1, 2, 3, 21, 4, 5, 22, 6, 23, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)
QUESTION_SECTIONS = ("A",) * 4 + ("B",) * 4 + ("C",) * 5 + ("D",) * 6 + ("E",) * 4


def questions() -> list[dict]:
    source = _tables(_section("The initial reusable question rows shall use", "`Q-SCN-023` shall use"))[0]
    by_id = {row["QuestionId"]: row for row in source}
    result = []
    for n, (number, section) in enumerate(zip(QUESTION_ORDER, QUESTION_SECTIONS), 1):
        qid = f"Q-SCN-{number:03d}"
        item = by_id[qid]
        answer = item["Controlled answer or type"]
        context = item["MapsToContextField"]
        if number in (17, 18, 19):
            answer_type, list_code, detail = "Size", "", "ApproximateSize"
        elif number == 20:
            answer_type, list_code, detail = "Number", "", "Summary"
        elif number == 23:
            answer_type, list_code, detail = "MultiSelectCodeList", context, "Summary"
        else:
            answer_type, list_code, detail = "CodeList", context, "AvailabilityOnly"
        trigger = item["Display condition"]
        result.append(dict(QuestionId=qid, SectionCode=section, DisplaySequence=n,
            QuestionText=item["Question"], BusinessMeaning=f"Defines {context} for scenario selection or assessment scope.",
            AnswerType=answer_type, AnswerListCode=list_code, AnswerOwner="EXTEDO" if number in (21, 22) else "Customer",
            Phase="PreSales", ParentQuestionId="Q-SCN-021" if number == 23 else "",
            TriggerOperator="Equals" if number == 23 else "",
            TriggerValue="MultipleSources" if number == 23 else "",
            MapsToContextField=context, RequiredWhenShown=True,
            MissingAnswerImpact="FollowUp" if number in (21, 22, 23) else "ConfidenceDown",
            Guidance="Provide the current source or intended migration input; EXTEDO confirms technical interpretation.",
            VerificationGuidance="Record the answer and supporting project evidence outside the reusable workbook.",
            PreSalesDetailLevel=detail, IsActive=True, SourceId=SOURCE_ID))
    return result


DERIVATION_SEEDS = (
    (10, "SDR-TARGET-UNSUPPORTED", "ValidateContext", "MS-07", "NeedsReview", "OUTSIDE_SUPPORTED_TARGET", (("TargetPlatform", "DMS"), ("TargetPlatform", "ThirdPartySystem"), ("TargetPlatform", "OtherEXTEDOProduct"))),
    (20, "SDR-MS05-MULTI", "SelectScenario", "MS-05", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "MultipleSources"))),
    (30, "SDR-MS01-SQL", "SelectScenario", "MS-01", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "ECTDManagerDatabaseArchive"), ("SourceDatabaseType", "SQLServer"))),
    (31, "SDR-MS02-ACCESS", "SelectScenario", "MS-02", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "ECTDManagerDatabaseArchive"), ("SourceDatabaseType", "Access"))),
    (32, "SDR-MS03-ORACLE", "SelectScenario", "MS-03", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "ECTDManagerDatabaseArchive"), ("SourceDatabaseType", "Oracle"))),
    (40, "SDR-MS04-EXPORT", "SelectScenario", "MS-04", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "RegulatorySubmissionExport"))),
    (50, "SDR-MS08-THIRD", "SelectScenario", "MS-08", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "ThirdPartySystem"))),
    (51, "SDR-MS08-DMS", "SelectScenario", "MS-08", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "DMS"))),
    (60, "SDR-MS06-ARCHIVE", "SelectScenario", "MS-06", "Derived", (("TargetPlatform", "eCTDmanager"), ("PrimarySourceMechanism", "ArchiveStorageOnly"))),
)
CONTEXT_QUESTION = {q["MapsToContextField"]: q["QuestionId"] for q in questions()}


def derivation_rules() -> list[dict]:
    rows = []
    for priority, rid, purpose, scenario, status, *tail in DERIVATION_SEEDS:
        reason = tail[0] if len(tail) == 2 else rid.replace("SDR-", "")
        conditions = tail[-1]
        for index, (field, value) in enumerate(conditions, 1):
            group = f"G{index}" if rid == "SDR-TARGET-UNSUPPORTED" else "G1"
            rows.append(dict(DerivationRuleId=rid, RulePurpose=purpose, RuleName=rid.replace("SDR-", "").replace("-", " "),
                RequirementId="REQ-SCN-003" if scenario == "MS-07" else "REQ-SCN-005" if scenario == "MS-05" else "REQ-SCN-001",
                Priority=priority, ConditionGroup=group, ConditionSequence=1 if group != "G1" else index,
                InputContextField=field, OriginQuestionId=CONTEXT_QUESTION[field], Operator="Equals",
                ExpectedValue=value, CandidateScenarioId=scenario, OnMatchStatus=status,
                MissingInputAction="FollowUp", FollowUpQuestionId=CONTEXT_QUESTION[field],
                ReasonCode=reason, ReasonTemplate=f"{rid} matches the approved source and target route.",
                BaseConfidence="Low" if scenario == "MS-07" else "High", IsActive=True, SourceId=SOURCE_ID,
                Notes="Different groups are OR; conditions within a group are AND."))
    for group, outcome, status in (("G1", "NoMatch", "Pending"), ("G2", "Conflict", "NeedsReview")):
        rows.append(dict(DerivationRuleId="SDR-MS07-FALLBACK", RulePurpose="Fallback", RuleName="Pending or conflicting route",
            RequirementId="REQ-SCN-003",
            Priority=900, ConditionGroup=group, ConditionSequence=1, InputContextField="SelectionOutcome",
            OriginQuestionId="", Operator="Equals", ExpectedValue=outcome, CandidateScenarioId="MS-07",
            OnMatchStatus=status, MissingInputAction="UseFallback", FollowUpQuestionId="Q-SCN-021",
            ReasonCode="NO_SUPPORTED_ROUTE" if status == "Pending" else "CONFLICTING_ROUTE",
            ReasonTemplate="No unique supported source-to-target route is available; consultant follow-up is required.",
            BaseConfidence="Unknown", IsActive=True, SourceId=SOURCE_ID,
            Notes="Evaluated only after context validation and all normal selection rules."))
    return rows


MODULE_LAYER = {"MOD-SCENARIO": "Context", "MOD-INTERPRET": "Interpretation", "MOD-READINESS": "Readiness", "MOD-RECONCILE": "Reconciliation"}
MODULE_CAPABILITY = {
    "MOD-SCENARIO": "ClassifyCandidates", "MOD-SOURCE": "ReadDatabaseAdapter", "MOD-DB": "ReadDatabaseAdapter",
    "MOD-ARCHIVE": "ReadArchiveAdapter", "MOD-DMS": "ReadDmsAdapter", "MOD-REPOSITORY": "EnumerateDirectory",
    "MOD-CLASSIFY": "ClassifyCandidates", "MOD-SEQUENCE": "DetectSequenceGap", "MOD-REFERENCE": "ResolveXmlReference",
    "MOD-FILE": "DetectZeroByte", "MOD-VOLUME": "CountItems", "MOD-MAPPING": "NormalizeIdentifier",
    "MOD-INTERPRET": "AggregateRag", "MOD-READINESS": "EvaluateReadiness", "MOD-RECONCILE": "ReconcileEntities",
}


def modules() -> list[dict]:
    source = _tables(_section("The approved MVP module catalogue is:", "### 9.6"))[0]
    out = []
    for item in source:
        mid = item["ModuleId"]
        boundary = item["Business responsibility and boundary"]
        out.append(dict(ModuleId=mid, ModuleName=item["Module name"], BusinessPurpose=boundary.split(";")[0],
            AssessmentBoundary=boundary, ModuleLayer=MODULE_LAYER.get(mid, "Evidence"),
            ExecutionMode="Orchestration" if mid == "MOD-SCENARIO" else "Runtime",
            PrimaryEvidenceDomain=mid.removeprefix("MOD-"), PrimaryEngineCapabilityGroup=MODULE_CAPABILITY[mid],
            SupportsPreSales=mid != "MOD-READINESS" and mid != "MOD-RECONCILE",
            SupportsPreMigration=mid != "MOD-RECONCILE", SupportsPostMigration=mid != "MOD-READINESS",
            InputSummary="Project context and available evidence relevant to this module.",
            OutputSummary="Traceable observations, measures, or phase outcome within the stated boundary.",
            ProducesFindings=mid not in ("MOD-SCENARIO", "MOD-VOLUME"), ProducesMetrics=mid in ("MOD-DB", "MOD-ARCHIVE", "MOD-REPOSITORY", "MOD-FILE", "MOD-VOLUME"),
            CanProduceBaselineData=mid not in ("MOD-SCENARIO", "MOD-INTERPRET", "MOD-READINESS", "MOD-RECONCILE"),
            CanSupportReconciliation=mid not in ("MOD-SCENARIO", "MOD-INTERPRET", "MOD-READINESS"),
            IsRuntimeModule=True, IsActive=True, SourceId=SOURCE_ID, Notes=""))
    return out


SHORT_MODULES = {"SCN": "SCENARIO", "SRC": "SOURCE", "DB": "DB", "ARC": "ARCHIVE", "DMS": "DMS", "REP": "REPOSITORY", "CLS": "CLASSIFY", "SEQ": "SEQUENCE", "REF": "REFERENCE", "FILE": "FILE", "VOL": "VOLUME", "MAP": "MAPPING", "INT": "INTERPRET", "RDY": "READINESS", "REC": "RECONCILE"}
PHASE_SHORT = {"PreSales": "PS", "PreMigration": "PM", "PostMigration": "PO"}


def module_mappings() -> list[dict]:
    result = []
    for phase, heading in zip(PHASES, ("#### Pre-Sales module mapping", "#### Pre-Migration module mapping", "#### Post-Migration module mapping")):
        matrix = _tables(_section(heading, "####" if False else "Illustrative JSON" if phase == "PostMigration" else "####"))[0]
        # The section extractor above cannot use a generic next #### marker, as it
        # would find the current heading; the first table is stable in each slice.
        for row in matrix:
            sid = row["Scenario"]
            choices = {}
            for applicability in ("Required", "Conditional", "Optional", "NotApplicable"):
                for code in (x.strip() for x in row[applicability].split(",")):
                    if code and code != "—":
                        choices[code] = applicability
            assert set(choices) == set(SHORT_MODULES), (phase, sid, set(SHORT_MODULES) - set(choices))
            for code, name in SHORT_MODULES.items():
                app = choices[code]
                mid = f"MOD-{name}"
                if app == "Conditional":
                    if sid == "MS-05":
                        field, op = "IncludedSourceMechanisms", "Contains"
                        value = {"DB": "ECTDManagerDatabaseArchive", "ARC": "ECTDManagerDatabaseArchive", "DMS": "DMS"}.get(code, "RegulatorySubmissionExport")
                    elif sid == "MS-08" and code == "DMS":
                        field, op, value = "PrimarySourceMechanism", "Equals", "DMS"
                    else:
                        field, op, value = {
                            "DB": ("SourceDatabaseAvailable", "Equals", "Yes"),
                            "ARC": ("ArchiveAvailable", "Equals", "Yes"),
                            "DMS": ("DmsDependency", "Equals", "Yes"),
                            "REP": ("RegulatoryExportAvailable", "Equals", "Yes"),
                            "CLS": ("RegulatoryExportAvailable", "Equals", "Yes"),
                            "SEQ": ("RegulatoryExportAvailable", "Equals", "Yes"),
                            "REF": ("RegulatoryExportAvailable", "Equals", "Yes"),
                            "FILE": ("SourceDocumentsAvailable", "Equals", "Yes"),
                            "SRC": ("PrimarySourceMechanism", "NotEquals", "Unknown"),
                            "VOL": ("EvidenceCompleteness", "NotEquals", "Unknown"),
                            "MAP": ("PrimarySourceMechanism", "NotEquals", "Unknown"),
                        }.get(code, ("EvidenceCompleteness", "NotEquals", "Unknown"))
                else:
                    field = op = value = ""
                depth = ("NotApplicable" if app == "NotApplicable" else
                         "AvailabilityOnly" if phase == "PreSales" and code in ("SCN", "SRC", "DB", "ARC", "DMS") else
                         "Summary" if phase == "PreSales" else
                         "Reconciliation" if phase == "PostMigration" else "Detailed")
                missing = "Blocked" if code == "RDY" and phase == "PreMigration" else "NotAssessed" if app == "NotApplicable" else "FollowUp" if phase == "PreSales" or app == "Conditional" else "InsufficientEvidence"
                impact = "ReadinessBlocker" if code == "RDY" and phase == "PreMigration" else "ReconciliationBlocker" if code == "REC" and phase == "PostMigration" else "ConfidenceDown" if phase == "PreSales" and app != "NotApplicable" else "None"
                baseline = "Required" if phase == "PreMigration" and app == "Required" and code not in ("SCN", "INT", "RDY") else "Candidate" if phase == "PreMigration" and app == "Conditional" else "None"
                role = "Comparison" if phase == "PostMigration" and app != "NotApplicable" and code == "REC" else "BaselineSource" if phase == "PostMigration" and app != "NotApplicable" else "None"
                result.append(dict(ScenarioModuleMapId=f"SMM-{sid.replace('-', '')}-{PHASE_SHORT[phase]}-{code}",
                    ScenarioId=sid, Phase=phase, ModuleId=mid, Applicability=app,
                    AssessmentDepth=depth, ActivationContextField=field, ActivationOperator=op,
                    ActivationValue=value, ActivationValueListCode="IncludedSourceMechanisms" if field == "IncludedSourceMechanisms" else "",
                    DefaultMissingEvidenceOutcome=missing, PhaseOutcomeImpact=impact,
                    BaselineContribution=baseline, ReconciliationRole=role,
                    ReasonCode=f"{sid.replace('-', '')}_{PHASE_SHORT[phase]}_{code}_{app.upper()}",
                    BusinessReason=(f"{mid} is {app} for {sid} in {phase} under the approved v4.4 module matrix."
                        + (" Unknown activation evidence requires follow-up; it is never false by default." if app == "Conditional" else "")),
                    IsActive=True, SourceId=SOURCE_ID, Notes=""))
    return result


# Each seed is one independently checkable obligation. The v4.4 family table
# defines minimum topics, not approved wording for every atomic leaf; unseeded
# source-obligation reconciliation remains a blocking content-review item.
# (ID, title, statement, owner, module, section, implementation, phase)
REQUIREMENT_SEEDS = (
    ("REQ-WBK-001", "Approved workbook structure", "eMAS shall maintain one mapping workbook with the approved 28 sheets in contract order.", "Workbook", "", "§7", "ValidationOnly", "NotApplicable"),
    ("REQ-WBK-002", "Stable filterable tables", "Every maintained workbook data area shall be a named and filterable Excel Table.", "Workbook", "", "§4; §7", "ValidationOnly", "NotApplicable"),
    ("REQ-WBK-003", "Stable identifiers", "Every executable workbook record shall have an identifier independent of its Excel row number.", "Workbook", "", "§4 MVP-GEN-003; §8.1", "ValidationOnly", "NotApplicable"),
    ("REQ-WBK-004", "No customer answers", "The reusable mapping workbook shall exclude customer-specific answers and results.", "Workbook", "", "§9.3", "ValidationOnly", "NotApplicable"),
    ("REQ-WBK-005", "Controlled authoring values", "Workbook columns with approved controlled codes shall use a value list and reject unknown codes.", "Workbook", "", "§9.23", "ValidationOnly", "NotApplicable"),
    ("REQ-WBK-006", "Macro-free workbook", "The Mapping Workbook shall remain a macro-free .xlsx file.", "Workbook", "", "§7", "ValidationOnly", "NotApplicable"),
    ("REQ-SCN-001", "Eight base scenarios", "The scenario catalogue shall contain exactly the eight approved active base scenarios.", "Workbook", "", "§5", "ValidationOnly", "NotApplicable"),
    ("REQ-SCN-002", "Separate qualifiers", "Hosting, scope, dependencies and evidence completeness shall remain qualifiers rather than new scenario identities.", "Transformer", "", "§5", "TransformerOnly", "AllPhases"),
    ("REQ-SCN-003", "Unsupported DMS target", "A DMS-to-DMS or other unsupported target route shall resolve to MS-07 with NeedsReview and OUTSIDE_SUPPORTED_TARGET.", "Transformer", "", "§5; §9.4", "TransformerOnly", "AllPhases"),
    ("REQ-SCN-004", "Incomplete known route", "Missing non-identity evidence shall retain a known base scenario and produce DerivedWithFollowUp.", "Transformer", "", "§9.4", "TransformerOnly", "AllPhases"),
    ("REQ-SCN-005", "Hybrid composition", "MultipleSources shall require at least two controlled included source mechanisms.", "Transformer", "", "§9.3", "ValidationOnly", "AllPhases"),
    ("REQ-MOD-001", "Fifteen bounded modules", "The active module catalogue shall contain exactly the fifteen approved assessment modules.", "Workbook", "", "§9.5", "ValidationOnly", "NotApplicable"),
    ("REQ-MOD-002", "Complete phase matrix", "Every active scenario, phase and module combination shall have one explicit active applicability record.", "Workbook", "", "§9.6", "ValidationOnly", "NotApplicable"),
    ("REQ-MOD-003", "Readiness phase boundary", "MOD-READINESS shall be applicable only in PreMigration.", "Workbook", "", "§9.6", "ValidationOnly", "NotApplicable"),
    ("REQ-MOD-004", "Reconciliation phase boundary", "MOD-RECONCILE shall be applicable only in PostMigration.", "Workbook", "", "§9.6", "ValidationOnly", "NotApplicable"),
    ("REQ-MOD-006", "Pending route excludes reconciliation", "MOD-RECONCILE shall be NotApplicable for MS-07 PostMigration.", "Workbook", "", "§9.6", "ValidationOnly", "NotApplicable"),
    ("REQ-MOD-005", "Unknown activation", "A Conditional module with unknown activation evidence shall create its configured follow-up or evidence outcome.", "Runtime", "", "§9.6", "Deferred", "AllPhases"),
    ("REQ-SRC-001", "Source context", "The source assessment shall record product, version, environment and dependencies independently.", "AssessmentModule", "MOD-SOURCE", "§9.5; §10", "Deferred", "AllPhases"),
    ("REQ-SRC-002", "Unsupported source semantics", "An unsupported source adapter or semantic shall produce NotAssessed with an explicit limitation.", "AssessmentModule", "MOD-SOURCE", "§10", "Deferred", "AllPhases"),
    ("REQ-DB-001", "PreSales database scale", "PreSales database assessment shall use availability and approximate scale without detailed DB-to-archive correlation.", "AssessmentModule", "MOD-DB", "§9.3; §9.5", "Deferred", "PreSales"),
    ("REQ-DB-002", "Detailed database inventory", "PreMigration database assessment shall inventory source entities, identifiers, counts and relationships.", "AssessmentModule", "MOD-DB", "§9.5; §10", "Deferred", "PreMigration"),
    ("REQ-ARC-001", "Physical lookup states", "Archive lookup shall distinguish Found, Missing, Multiple, Invalid and Inaccessible.", "AssessmentModule", "MOD-ARCHIVE", "§9.15", "Deferred", "PreAndPostMigration"),
    ("REQ-ARC-002", "False missing safeguards", "Before declaring an archive object missing, assessment shall check identifier conversion, root, recursion, extension and access assumptions.", "AssessmentModule", "MOD-ARCHIVE", "§9.15", "Deferred", "PreAndPostMigration"),
    ("REQ-DMS-001", "DMS object inventory", "DMS assessment shall preserve document, version, rendition, metadata and relationship identities.", "AssessmentModule", "MOD-DMS", "§9.15", "Deferred", "PreAndPostMigration"),
    ("REQ-DMS-002", "DMS target boundary", "DMS source mappings shall apply only to migration into eCTDmanager.", "AssessmentModule", "MOD-DMS", "§9.15", "Deferred", "AllPhases"),
    ("REQ-REP-001", "Nested container discovery", "Repository assessment shall discover ZIPs, nested ZIPs and wrapper folders while preserving container context.", "AssessmentModule", "MOD-REPOSITORY", "§9.11", "Deferred", "PreAndPostMigration"),
    ("REQ-REP-002", "Discovery is not validity", "Repository discovery shall not infer regulatory validity from a folder name alone.", "AssessmentModule", "MOD-REPOSITORY", "§9.5", "Deferred", "AllPhases"),
    ("REQ-CLS-001", "Separate classification dimensions", "Region, authority, format, version, application and dossier context shall be classified independently.", "AssessmentModule", "MOD-CLASSIFY", "§8.2; §9.9", "Deferred", "AllPhases"),
    ("REQ-CLS-002", "Strong evidence precedence", "Folder labels shall not override stronger XML, database or controlled metadata evidence.", "AssessmentModule", "MOD-CLASSIFY", "§4 MVP-GEN-010", "Deferred", "AllPhases"),
    ("REQ-SEQ-001", "Sequence inventory", "Sequence assessment shall inventory sequence or submission-unit identity and lifecycle relationships.", "AssessmentModule", "MOD-SEQUENCE", "§9.5; §9.10", "Deferred", "PreAndPostMigration"),
    ("REQ-SEQ-002", "Duplicate sequence observation", "Sequence assessment shall record duplicate or nested sequence folders as separately traceable observations.", "AssessmentModule", "MOD-SEQUENCE", "§9.10", "Deferred", "PreAndPostMigration"),
    ("REQ-SEQ-003", "Numeric gap observation", "A numeric sequence gap shall be an observation and shall not automatically establish a required missing sequence.", "AssessmentModule", "MOD-SEQUENCE", "§9.10", "Deferred", "PreAndPostMigration"),
    ("REQ-REF-001", "Missing and orphan separation", "Missing XML reference targets and orphan file candidates shall be reported as distinct findings.", "AssessmentModule", "MOD-REFERENCE", "§9.12", "Deferred", "PreAndPostMigration"),
    ("REQ-REF-002", "Reference provenance", "Each XML reference observation shall retain source file, element or path, attribute and observed value.", "AssessmentModule", "MOD-REFERENCE", "§9.12", "Deferred", "PreAndPostMigration"),
    ("REQ-FIL-001", "Unreadable file state", "An unreadable file shall produce an inaccessible or NotAssessed state rather than a successful technical result.", "AssessmentModule", "MOD-FILE", "§9.13", "Deferred", "AllPhases"),
    ("REQ-FIL-002", "No content repair", "File assessment shall not repair source content.", "AssessmentModule", "MOD-FILE", "§9.5", "Deferred", "AllPhases"),
    ("REQ-VOL-001", "Factual measures", "Volume assessment shall calculate factual counts and sizes independently from RAG, confidence and effort interpretation.", "AssessmentModule", "MOD-VOLUME", "§9.5; §9.14", "Deferred", "AllPhases"),
    ("REQ-MAP-001", "Declarative identifiers", "Source-to-target mappings shall use logical identifiers and named transformations rather than executable SQL.", "AssessmentModule", "MOD-MAPPING", "§9.15", "Deferred", "AllPhases"),
    ("REQ-INT-001", "Independent RAG and confidence", "Severity and RAG shall remain independent of evidence confidence.", "AssessmentModule", "MOD-INTERPRET", "§4 MVP-GEN-012; §9.16", "Deferred", "AllPhases"),
    ("REQ-INT-002", "Missing evidence is not pass", "Missing or inaccessible mandatory evidence shall not be interpreted as Green, Pass or Ready.", "AssessmentModule", "MOD-INTERPRET", "§4 MVP-GEN-011", "Deferred", "AllPhases"),
    ("REQ-RDY-001", "Readiness outcome", "PreMigration readiness shall select Ready, ReadyWithAcceptedExceptions or Blocked from detailed evidence.", "AssessmentModule", "MOD-READINESS", "§9.5; §9.21", "Deferred", "PreMigration"),
    ("REQ-RDY-002", "Pending route blocker", "An unresolved MS-07 route shall produce Blocked PreMigration readiness.", "AssessmentModule", "MOD-READINESS", "§9.6", "Deferred", "PreMigration"),
    ("REQ-REC-001", "Approved baseline comparison", "PostMigration reconciliation shall compare target evidence with an approved PreMigration baseline.", "AssessmentModule", "MOD-RECONCILE", "§9.5; §9.22", "Deferred", "PostMigration"),
    ("REQ-REC-002", "No pending reconciliation", "Formal PostMigration reconciliation shall not run for unresolved MS-07.", "AssessmentModule", "MOD-RECONCILE", "§9.6", "Deferred", "PostMigration"),
    ("REQ-JSN-001", "Scenario filtering", "Scenario JSON transformation shall include one confirmed scenario and its applicable module records.", "Transformer", "", "§12", "Deferred", "AllPhases"),
    ("REQ-JSN-002", "Deterministic serialization", "Unchanged workbook content and scenario selection shall produce identical canonical JSON bytes.", "Transformer", "", "§14", "Deferred", "AllPhases"),
    ("REQ-RUN-001", "JSON-only runtime", "PowerShell shall consume scenario Runtime JSON without opening or interpreting the workbook.", "Runtime", "", "§3; §16 MVP-AT-012", "Deferred", "AllPhases"),
    ("REQ-RUN-002", "No silent repair", "The runtime shall reject invalid configuration rather than silently correcting it.", "Runtime", "", "§14", "Deferred", "AllPhases"),
    ("REQ-RPT-001", "Phase reporting", "Reports shall present phase outcomes, limitations and traceability identifiers.", "Reporting", "", "§10", "Deferred", "AllPhases"),
    ("REQ-LOG-001", "Execution audit fields", "Execution logs shall record identity, timestamp, versions, parameters, warnings and output paths.", "Logging", "", "§9.7; §10", "Deferred", "AllPhases"),
    ("REQ-SEC-001", "No external transmission", "Assessment shall not transmit customer evidence to an external service without authorization.", "Runtime", "", "§10", "Deferred", "AllPhases"),
    ("REQ-SEC-002", "Read-only source evidence", "Assessment capabilities shall read source evidence without modifying source or target content.", "Runtime", "", "§10", "Deferred", "AllPhases"),
    ("REQ-NFR-001", "Culture-invariant values", "Runtime configuration shall serialize typed values without locale-dependent interpretation.", "Transformer", "", "§12", "Deferred", "AllPhases"),
    ("REQ-TST-001", "Negative validation tests", "Workbook tests shall reject duplicate IDs, invalid references and incomplete scenario mappings.", "Workbook", "", "§14; §16", "ValidationOnly", "NotApplicable"),
    ("REQ-TST-002", "Traceable exported rules", "Every exported rule shall resolve to a requirement, source, JSON path and engine capability.", "Transformer", "", "§4 MVP-GEN-015; §16", "Deferred", "AllPhases"),
)


def requirements() -> list[dict]:
    out = []
    purposes = {
        "WBK": "Consultants need a stable, inspectable configuration source.",
        "SCN": "A migration route must be selected safely before assessment.",
        "MOD": "Module execution must be explicit for every scenario and phase.",
        "SRC": "Source context determines which adapters and evidence can be trusted.",
        "DB": "Database evidence establishes scope and later comparison keys.",
        "ARC": "Physical object identity and access must be assessed without false missing claims.",
        "DMS": "Third-party content needs traceable identity and a supported target boundary.",
        "REP": "Container discovery must preserve packaging context and limitations.",
        "CLS": "Regulatory classification requires independent, evidence-backed dimensions.",
        "SEQ": "Sequence observations must be separated from unproven regulatory defects.",
        "REF": "Reference integrity findings require exact source provenance.",
        "FIL": "Technical file evidence must remain observable without source repair.",
        "VOL": "Factual scale measures support planning without deciding risk by themselves.",
        "MAP": "Declarative keys preserve traceability and keep executable logic out of Excel.",
        "INT": "Risk and confidence must not be conflated or turn unknowns into passes.",
        "RDY": "Readiness must reflect blockers and a defensible approved baseline.",
        "REC": "PostMigration comparison requires a valid expected population.",
        "JSN": "The runtime needs a deterministic, traceable scenario projection.",
        "RUN": "PowerShell must consume validated configuration without Excel interpretation.",
        "RPT": "Reviewers need phase outcomes and visible limits in reports.",
        "LOG": "Execution evidence needs repeatable audit context.",
        "SEC": "Customer evidence and source content must remain protected.",
        "NFR": "Portable serialization avoids locale-specific differences.",
        "TST": "Negative and traceability tests keep unsafe configuration from runtime.",
    }
    for rid, title, statement, owner, module, section, disposition, phase in REQUIREMENT_SEEDS:
        domain = rid.split("-")[1]
        implemented = rid in {"REQ-WBK-001", "REQ-WBK-002", "REQ-WBK-003", "REQ-WBK-004", "REQ-WBK-005", "REQ-WBK-006", "REQ-SCN-001", "REQ-MOD-001", "REQ-MOD-002", "REQ-MOD-003", "REQ-MOD-004", "REQ-MOD-006"}
        export = False  # No unreviewed/deferred runtime obligation enters candidate JSON.
        out.append(dict(RequirementId=rid, RequirementTitle=title, RequirementStatement=statement,
            BusinessPurpose=purposes[domain],
            RequirementDomain=domain, RequirementType="Safety" if domain == "SEC" else "Validation" if disposition == "ValidationOnly" else "Functional",
            ObligationLevel="Must", OwningComponent=owner, ModuleId=module,
            LifecycleStage="Authoring" if owner == "Workbook" else "Generation" if owner == "Transformer" else "Runtime",
            PhaseScope=phase, ApplicabilityBasis="ModuleDriven" if module else "Global", ScenarioId="",
            MissingEvidenceBehavior="NotApplicable" if owner in ("Workbook", "Transformer") else "NotAssessed",
            PhaseOutcomeImpact="None", ImplementationDisposition=disposition,
            ImplementationSheet={"WBK": "00_Home", "SCN": "03_Scenario_Derivation_Rules", "MOD": "05_Scenario_Module_Map", "SEQ": "09_Dossier_Sequence_ID", "ARC": "14_Source_DB_Archive_DMS"}.get(domain, ""),
            EngineCapability=MODULE_CAPABILITY.get(module, "") if disposition != "Deferred" else "",
            RuntimeExport=export, JSONPath="requirements[]" if export else "",
            AcceptanceCriterion=(f"Saved XLSX inspection verifies: {statement}" if disposition == "ValidationOnly"
                else f"A scenario test observes the stated behavior and its stable traceability ID: {statement}"),
            VerificationMethod="WorkbookValidation" if disposition == "ValidationOnly" else "ScenarioTest",
            TestReference="", SourceId=SOURCE_ID, SourceSection=section,
            RequirementBasis="eMASDesign", RequirementStatus="Approved",
            ImplementationStatus="Implemented" if implemented else "NotStarted",
            VerificationStatus="NotTested", IsActive=True,
            Notes="Content seed from approved v4.4 scope; full source-obligation disposition remains pending."))
    return out


BASE_VALUE_LISTS = OrderedDict((
    ("Phase", "PreSales PreMigration PostMigration All"),
    ("ScenarioFamily", "eCTDmanager RegulatoryExport Hybrid ArchiveStorage Pending ThirdPartySystemOrDMS"),
    ("ScenarioScope", "ALL MS-01 MS-02 MS-03 MS-04 MS-05 MS-06 MS-07 MS-08"),
    ("ExistingECTDManager", "Yes No Partial Unknown"),
    ("SourceSystemCategory", "eCTDmanager RegulatoryExport ThirdPartySystemOrDMS ArchiveStorage Hybrid Unknown"),
    ("PrimaryMigrationMethod", "DatabaseArchive ExportImport ArchiveOnly Adapter Hybrid Unknown"),
    ("SourceDatabaseType", "SQLServer Access Oracle Other NotApplicable Unknown"),
    ("PrimarySourceMechanism", "ECTDManagerDatabaseArchive RegulatorySubmissionExport ThirdPartySystem DMS ArchiveStorageOnly MultipleSources Unknown"),
    ("IncludedSourceMechanisms", "ECTDManagerDatabaseArchive RegulatorySubmissionExport ThirdPartySystem DMS ArchiveStorage"),
    ("TargetPlatform", "eCTDmanager OtherEXTEDOProduct DMS ThirdPartySystem ToBeDefined"),
    ("RulePurpose", "SelectScenario ValidateContext Fallback"),
    ("OnMatchStatus", "Derived DerivedWithFollowUp Pending NeedsReview ConfirmedOverride"),
    ("MissingInputAction", "Continue FollowUp UseFallback"),
    ("Applicability", "Required Conditional Optional NotApplicable"),
    ("AssessmentDepth", "AvailabilityOnly Summary Detailed Reconciliation NotApplicable"),
    ("DefaultMissingEvidenceOutcome", "NotAssessed InsufficientEvidence FollowUp Blocked"),
    ("PhaseOutcomeImpact", "None ConfidenceDown FollowUp ReadinessBlocker ReconciliationBlocker"),
    ("BaselineContribution", "None Candidate Required Supporting"),
    ("ReconciliationRole", "None BaselineSource TargetEvidence Comparison Outcome"),
    ("ModuleLayer", "Context Evidence Interpretation Readiness Reconciliation"),
    ("ExecutionMode", "Runtime ConfigurationOnly Orchestration"),
    ("RequirementDomain", "WBK SCN MOD SRC DB ARC DMS REP CLS SEQ REF FIL VOL MAP INT RDY REC JSN RUN RPT LOG SEC NFR TST"),
    ("RequirementType", "Functional Data Validation Interface Constraint NonFunctional Safety"),
    ("ObligationLevel", "Must Should May"),
    ("OwningComponent", "AssessmentModule Workbook Transformer Runtime Reporting Logging"),
    ("LifecycleStage", "Authoring Generation Runtime Reporting CrossCutting"),
    ("PhaseScope", "AllPhases PreSales PreMigration PostMigration PreAndPostMigration NotApplicable"),
    ("ApplicabilityBasis", "Global ModuleDriven ScenarioSpecific"),
    ("MissingEvidenceBehavior", "NotAssessed InsufficientEvidence FollowUp Blocked NotApplicable"),
    ("ImplementationDisposition", "WorkbookRule EngineCapability Hybrid TransformerOnly ValidationOnly ReportOnly Deferred"),
    ("VerificationMethod", "WorkbookValidation UnitTest IntegrationTest ScenarioTest ManualReview Inspection"),
    ("RequirementStatus", "Draft Reviewed Approved Deferred Retired"),
    ("ImplementationStatus", "NotStarted InProgress Implemented NotApplicable"),
    ("VerificationStatus", "NotTested Passed Failed NotApplicable"),
    ("Region", "EU US CA UK CH AU JP SG Unknown"),
    ("TechnicalFormat", "eCTDv3 eCTDv4 NeeS VNeeS NonECTD Unknown"),
    ("EvidenceSourceType", "Folder File XML DB Archive DMS Manifest Customer Derived Target"),
    ("EvidenceState", "Present ConfirmedAbsent Unavailable Invalid Conflict"),
    ("EvaluationStatus", "Assessed NotAssessed NotApplicable Unknown Error"),
    ("RAG", "Green Amber Red Unknown"),
    ("Severity", "Info Low Medium High Critical"),
    ("Confidence", "High Medium Low Unknown"),
    ("Operator", "Equals NotEquals Contains Exists NotExists GreaterThan LessThan GreaterOrEqual LessOrEqual Between"),
    ("DataType", "String Integer Decimal Boolean Date Code Path Hash Object"),
    ("ScopeLevel", "Repository DB Archive DMS Application Dossier Sequence Module Document File"),
    ("EffortBand", "VeryLow Low Medium High VeryHigh"),
    ("RequirementBasis", "AuthorityRequirement ReviewedInterpretation ProductRequirement eMASDesign"),
    ("SourceType", "AuthorityPublication VendorDocument ProductRequirement InternalDecision Example"),
    ("SourceVerificationStatus", "Unverified Verified Example"),
    ("ListUsage", "AuthoringOnly Runtime Both"),
    ("QuestionAnswerType", "Boolean CodeList MultiSelectCodeList Number Text Size"),
    ("AnswerOwner", "Customer EXTEDO Derived"),
    ("MissingAnswerImpact", "FollowUp ConfidenceDown NotAssessed Blocker"),
    ("PreSalesDetailLevel", "AvailabilityOnly ApproximateSize Summary Detailed NotApplicable"),
    ("Transformation", "Direct Trim ToBoolean ToNumber GroupConditions ResolveReference"),
    ("NullPolicy", "Error Omit Null EmptyArray"),
    ("InclusionRule", "ActiveAndApplicable ReferencedDependency AuthoringOnly"),
    ("InclusionStatus", "Included Conditional Optional Excluded Deferred Error"),
    ("ValidationSeverity", "Error Warning Info"),
    ("ValidationStatus", "Valid Warning Error"),
    ("SelectionOutcome", "NoMatch Conflict"),
    ("EvidenceCompleteness", "Complete Partial Minimal Unknown"),
    ("MissingValueMeaning", "Absent Unavailable Invalid NotApplicable Unknown"),
    ("Aggregation", "Count Sum DistinctCount Min Max Average Percent"),
    ("Unit", "Bytes GB Count Percent Days"),
    ("JSONDataType", "String Integer Decimal Boolean Array Object Date"),
    ("QuestionSection", "A B C D E"),
))


def value_lists() -> list[dict]:
    lists = OrderedDict((name, values.split()) for name, values in BASE_VALUE_LISTS.items())
    for item in questions():
        code = item["AnswerListCode"]
        if not code or code in lists:
            continue
        raw = next(r for r in _tables(_section("The initial reusable question rows shall use", "`Q-SCN-023` shall use"))[0] if r["QuestionId"] == item["QuestionId"])["Controlled answer or type"]
        raw = raw.removeprefix("Multi-select: ")
        lists[code] = [part.strip() for part in raw.split(",") if part.strip()]
    lists["ModuleId"] = [r["ModuleId"] for r in modules()]
    lists["ScenarioId"] = [r["ScenarioId"] for r in scenarios()]
    out = []
    for list_code, values in lists.items():
        for i, code in enumerate(values, 1):
            out.append(dict(ListCode=list_code, Code=code, Label=code,
                Description=f"Approved {list_code} code from the v4.4 MVP requirements.",
                SortOrder=i, Usage="Both", IsActive=True))
    return out


def fields() -> list[dict]:
    out = []
    for q in questions():
        field = q["MapsToContextField"]
        out.append(dict(FieldCode=field, DisplayName=field.replace("ApproxBytes", " approximate bytes"),
            Description=f"Normalized project-context value supplied by {q['QuestionId']}; customer answer is stored only in project execution evidence.",
            DataType="Integer" if q["AnswerType"] == "Number" else "Decimal" if q["AnswerType"] == "Size" else "Object" if q["AnswerType"] == "MultiSelectCodeList" else "Code",
            EvidenceSourceType="Customer", ProducerCapability="NormalizeQuestionnaire", ScopeLevel="Repository",
            AllowedOperator="Contains" if q["AnswerType"] == "MultiSelectCodeList" else "Equals",
            MissingValueMeaning="Unknown", Unit="Bytes" if q["AnswerType"] == "Size" else "Count" if q["AnswerType"] == "Number" else "",
            ExampleValue="", IsActive=True))
    out.extend([
        dict(FieldCode="SelectionOutcome", DisplayName="Derivation selection outcome", Description="Derived classifier state after all normal selection rules; NoMatch or Conflict.", DataType="Code", EvidenceSourceType="Derived", ProducerCapability="ClassifyCandidates", ScopeLevel="Repository", AllowedOperator="Equals", MissingValueMeaning="Unknown", Unit="", ExampleValue="NoMatch", IsActive=True),
        dict(FieldCode="EvidenceCompleteness", DisplayName="Evidence completeness", Description="Project qualifier summarizing available evidence; does not replace a known scenario.", DataType="Code", EvidenceSourceType="Derived", ProducerCapability="ClassifyCandidates", ScopeLevel="Repository", AllowedOperator="Equals", MissingValueMeaning="Unknown", Unit="", ExampleValue="Partial", IsActive=True),
    ])
    return out


def metrics() -> list[dict]:
    # Only the directly defined PreSales scale measures can be seeded without
    # inventing source adapters, regulatory thresholds, or detailed rule logic.
    specs = (
        ("MET-DB-APPROX-BYTES", "Approximate source database bytes", "SourceDatabaseApproxBytes", "MOD-DB", "DB", "Bytes"),
        ("MET-ARC-APPROX-BYTES", "Approximate archive bytes", "ArchiveApproxBytes", "MOD-ARCHIVE", "Archive", "Bytes"),
        ("MET-EXP-APPROX-BYTES", "Approximate export bytes", "RegulatoryExportApproxBytes", "MOD-VOLUME", "Repository", "Bytes"),
        ("MET-DOS-APPROX-COUNT", "Approximate dossier or application count", "ApproxDossierCount", "MOD-VOLUME", "Repository", "Count"),
    )
    return [dict(MetricCode=mid, MetricName=name, ModuleId=module, ScopeLevel=scope,
        EvidenceSourceType="Customer", Aggregation="Sum", SourceFieldCode=field,
        Unit=unit, Phase="PreSales", ScenarioId="ALL", StoreDetail=False,
        EffortDriverId="", IsActive=True)
        for mid, name, field, module, scope, unit in specs]


def source_references() -> list[dict]:
    return [dict(SourceId=SOURCE_ID, SourceType="ProductRequirement",
        SourceTitle="eMAS Mapping Workbook and Scenario JSON MVP Requirements",
        SourceVersion="4.4 MVP", SourceDate="2026-09-13",
        Reference="docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md",
        AuthorityOrOwner="eMAS requirements baseline", VerificationStatus="Unverified",
        VerifiedBy="", VerifiedOn="", Notes="Approved branch text; source-by-source obligation reconciliation is pending.", IsActive=True)]


def source_rows() -> OrderedDict[str, list[dict]]:
    result: OrderedDict[str, list[dict]] = OrderedDict((name, []) for name in SHEETS if name != "00_Home")
    result["01_Migration_Scenarios"] = scenarios()
    result["02_Scenario_Questionnaire"] = questions()
    result["03_Scenario_Derivation_Rules"] = derivation_rules()
    result["04_Assessment_Modules"] = modules()
    result["05_Scenario_Module_Map"] = module_mappings()
    result["06_Requirement_Catalogue"] = requirements()
    result["07_Fields_Evidence"] = fields()
    result["13_Size_Volume_Metrics"] = metrics()
    result["22_Value_Lists"] = value_lists()
    result["23_Source_References"] = source_references()
    return result
