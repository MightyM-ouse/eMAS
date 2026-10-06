import copy
import hashlib
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "build"))

import emas_xlsx_poc as POC  # noqa: E402
import emas_xlsx_poc_model as MODEL  # noqa: E402
import emas_xlsx_poc_projection as PROJECTION  # noqa: E402
import generate_emas_mapping_poc_workbook as GENERATOR  # noqa: E402
import validate_emas_schema as SCHEMA  # noqa: E402

VBA = ROOT / "config" / "vba" / "modules"
POC_ROOT = ROOT / "config" / "authoring" / "poc"


def vba(name):
    return (VBA / name).read_text(encoding="utf-8-sig")


class IdentificationWorkbookExportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.workbook = Path(cls.temp_dir.name) / "eMAS_Mapping_Configuration_POC_Source.xlsx"
        GENERATOR.generate(POC_ROOT / "workbook-source.json", cls.workbook)
        cls.tables = POC.read_xlsx_tables(cls.workbook)
        cls.json_bytes = POC.canonical_json_bytes(POC.build_runtime_json(cls.tables))
        cls.runtime = json.loads(cls.json_bytes)
        schema_path = ROOT / "config" / "schema" / "eMAS-runtime-config.schema.json"
        cls.schema = SCHEMA.load_json(schema_path)
        cls.registry = SCHEMA.build_schema_registry(schema_path)

    @classmethod
    def tearDownClass(cls):
        cls.temp_dir.cleanup()

    def rule(self, rule_id):
        return next(r for r in self.tables["tblRules"] if r["RuleId"] == rule_id)

    # Schema 1.1.0 authoring

    def test_poc_authors_and_exports_schema_1_1_0(self):
        self.assertEqual("1.1.0", self.runtime["configuration"]["schemaVersion"])
        self.assertEqual([], [i.render() for i in SCHEMA.validate_instance(self.schema, self.runtime, self.registry)])
        self.assertIn('EMAS_SCHEMA_VERSION As String = "1.1.0"', vba("modConstants.bas"))
        manifest = json.loads((POC_ROOT / "poc-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual("1.1.0", manifest["schemaVersion"])
        settings = {r["SettingCode"]: r["SettingValue"] for r in self.tables["tblTechnicalSettings"]}
        self.assertEqual("1.1.0", settings["SchemaVersion"])

    def test_controlled_lists_and_ordinal_sort_order(self):
        lists = self.runtime["valueLists"]
        self.assertEqual(["STRONG", "MEDIUM", "WEAK"], [r["code"] for r in sorted(lists["EVIDENCE_STRENGTH"], key=lambda r: r["sortOrder"])])
        self.assertEqual({"HIGH", "MEDIUM", "LOW", "UNKNOWN"}, {r["code"] for r in lists["CONFIDENCE"]})
        self.assertEqual({"SUPPORTS", "CONTRADICTS"}, {r["code"] for r in lists["EVIDENCE_POLARITY"]})
        self.assertEqual({"UNKNOWN", "MANUAL_REVIEW"}, {r["code"] for r in lists["TIE_BEHAVIOR"]})
        self.assertEqual({"NONE_REQUIRED", "INDEPENDENT_SOURCE_CLASS"}, {r["code"] for r in lists["CORROBORATION_RULE"]})
        self.assertIn("IDENTIFICATION", {r["code"] for r in lists["RULE_TYPE"]})
        self.assertTrue({r["code"] for r in lists["IDENTIFICATION_DIMENSION"]} <= set(MODEL.ENTITY_TABLES))
        all_codes = {r["Code"].upper() for r in self.tables["tblValueLists"]}
        self.assertNotIn("SUPPORTING", all_codes)

    def test_supporting_normalization_is_not_implemented_by_aliases(self):
        for alias in self.tables["tblAliases"]:
            self.assertNotIn(str(alias["CanonicalCode"]).upper(), {"STRONG", "MEDIUM", "WEAK"})
            self.assertNotIn("supporting", str(alias["SourceFieldOrValue"]).lower())

    # Runtime-eligibility projection and dependent graph

    def test_eligibility_truth_table(self):
        date = "2026-07-13"
        cases = [
            ({"Status": "Effective", "EffectiveFrom": "2026-07-13", "EffectiveTo": ""}, True),
            ({"Status": "Effective", "EffectiveFrom": "2026-07-14", "EffectiveTo": ""}, False),
            ({"Status": "Effective", "EffectiveFrom": "2026-01-01", "EffectiveTo": "2026-07-13"}, False),
            ({"Status": "Effective", "EffectiveFrom": "2026-01-01", "EffectiveTo": "2026-07-14"}, True),
            ({"Status": "Effective", "EffectiveFrom": "", "EffectiveTo": ""}, False),
        ] + [({"Status": s, "EffectiveFrom": "2026-01-01", "EffectiveTo": ""}, False) for s in ("Draft", "InReview", "Reviewed", "Superseded", "Retired")]
        for rule, expected in cases:
            with self.subTest(rule=rule):
                self.assertEqual(expected, PROJECTION.is_runtime_eligible(rule, date))

    def test_draft_rule_and_all_dependent_rows_are_excluded(self):
        draft = self.rule("ID-SYN-RI-001")
        self.assertEqual("Draft", draft["Status"])
        dependents = {
            "tblRulePhaseAssignments": "RulePhaseId", "tblConditionGroups": "ConditionGroupId",
            "tblRuleConditions": "ConditionId", "tblRuleOutputs": "RuleOutputId",
        }
        text = self.json_bytes.decode("utf-8")
        for table, key in dependents.items():
            ids = [r[key] for r in self.tables[table] if r["RuleId"] == "ID-SYN-RI-001"]
            self.assertTrue(ids, table)
            for value in ids:
                self.assertNotIn(f'"{value}"', text)
        self.assertNotIn('"ID-SYN-RI-001"', text)
        self.assertIn('"ID-SYN-TS-001"', text)

    def test_projection_has_no_orphans_and_is_idempotent(self):
        projected = PROJECTION.project_runtime_tables(self.tables)
        self.assertEqual([], PROJECTION.verify_runtime_projection(self.tables, projected))
        self.assertEqual(projected, PROJECTION.project_runtime_tables(projected))
        rule_ids = {r["ruleId"] for r in self.runtime["rules"]}
        for collection in ("rulePhases", "conditionGroups", "ruleConditions", "ruleOutputs"):
            self.assertTrue(all(r["ruleId"] in rule_ids for r in self.runtime[collection]), collection)

    def test_supersession_to_excluded_rule_is_dropped(self):
        tables = copy.deepcopy(self.tables)
        template = dict(tables["tblMasterDataRelationships"][0])
        template.update(RelationshipId="REL-SUP-001", RelationshipType="RULE_SUPERSESSION", SourceEntityType="RULE", SourceEntityCode="ID-SYN-TS-001",
                        TargetEntityType="RULE", TargetEntityCode="ID-SYN-RI-001")
        tables["tblMasterDataRelationships"].append(template)
        projected = PROJECTION.project_runtime_tables(tables)
        self.assertNotIn("REL-SUP-001", {r["RelationshipId"] for r in projected["tblMasterDataRelationships"]})
        self.assertEqual([], PROJECTION.verify_runtime_projection(tables, projected))

    def test_every_non_effective_status_is_excluded(self):
        for status in ("Draft", "InReview", "Reviewed", "Superseded", "Retired"):
            with self.subTest(status=status):
                tables = copy.deepcopy(self.tables)
                next(r for r in tables["tblRules"] if r["RuleId"] == "ID-SYN-TS-001")["Status"] = status
                runtime = POC.build_runtime_json(tables)
                self.assertNotIn("ID-SYN-TS-001", {r["ruleId"] for r in runtime["rules"]})
                self.assertNotIn("ID-SYN-TS-001", {r["ruleId"] for r in runtime["ruleOutputs"]})

    def test_dev_and_controlled_use_the_same_projection(self):
        tables = copy.deepcopy(self.tables)
        tables["tblConfiguration"][0].update(ExportType="CONTROLLED", Status="Effective")
        controlled = POC.build_runtime_json(tables)
        for collection in ("rules", "rulePhases", "conditionGroups", "ruleConditions", "ruleOutputs", "relationships"):
            self.assertEqual(self.runtime[collection], json.loads(json.dumps(controlled[collection])), collection)

    def test_verifier_detects_faulty_projection(self):
        faulty = PROJECTION.project_runtime_tables(self.tables)
        faulty["tblRuleConditions"].append(next(r for r in self.tables["tblRuleConditions"] if r["RuleId"] == "ID-SYN-RI-001"))
        codes = {i.code for i in PROJECTION.verify_runtime_projection(self.tables, faulty)}
        self.assertIn("POC_PROJECTION_ORPHAN", codes)
        missing = PROJECTION.project_runtime_tables(self.tables)
        missing["tblRules"] = [r for r in missing["tblRules"] if r["RuleId"] != "ID-SYN-TS-001"]
        self.assertIn("POC_PROJECTION_INELIGIBLE", {i.code for i in PROJECTION.verify_runtime_projection(self.tables, missing)})

    # LegacyRuleId

    def test_legacy_rule_id_is_authored_but_never_exported(self):
        self.assertEqual("LEGACY-SYN-001", self.rule("ID-SYN-RI-001")["LegacyRuleId"])
        text = self.json_bytes.decode("utf-8")
        self.assertNotIn("legacyRuleId", text)
        self.assertNotIn("LegacyRuleId", text)
        self.assertNotIn("LEGACY-SYN-001", text)
        # Even an Effective rule carrying a LegacyRuleId never serializes it.
        tables = copy.deepcopy(self.tables)
        next(r for r in tables["tblRules"] if r["RuleId"] == "ID-SYN-TS-001")["LegacyRuleId"] = "LEGACY-SYN-002"
        exported = POC.canonical_json_bytes(POC.build_runtime_json(tables)).decode("utf-8")
        self.assertNotIn("LEGACY-SYN-002", exported)
        self.assertNotIn("legacyRuleId", exported)
        self.assertEqual([], [i.render() for i in POC.validate_workbook_tables(tables)])

    def test_builder_excludes_workbook_only_columns_even_without_projection(self):
        rules = MODEL.build_runtime_json(self.tables)["rules"]
        self.assertTrue(all("legacyRuleId" not in r for r in rules))

    def test_legacy_scanner_detects_property_and_value(self):
        runtime = copy.deepcopy(self.runtime)
        runtime["rules"][0]["legacyRuleId"] = "X"
        self.assertTrue(PROJECTION.scan_runtime_json_for_legacy(runtime, self.tables))
        runtime = copy.deepcopy(self.runtime)
        runtime["rules"][0]["comment"] = "see LEGACY-SYN-001"
        self.assertTrue(PROJECTION.scan_runtime_json_for_legacy(runtime, self.tables))

    def test_no_historical_mapping_rule_is_imported(self):
        source = "".join(p.read_text(encoding="utf-8") for p in sorted((POC_ROOT / "workbook-source-parts").glob("*.json")))
        self.assertIsNone(re.search(r"R-(REG|FMT|TYP)-\d{2}", source))
        for row in self.tables["tblRules"]:
            self.assertFalse(PROJECTION.LEGACY_RULE_ID_PATTERN.match(row["RuleId"]))

    # No numeric Identification weights; non-Identification weights preserved

    def test_no_numeric_identification_weights(self):
        id_rules = {r["RuleId"] for r in self.tables["tblRules"] if r["RuleType"] == "IDENTIFICATION"}
        self.assertTrue(id_rules)
        for row in self.tables["tblRuleOutputs"]:
            if row["RuleId"] in id_rules:
                self.assertEqual("", row["OutputValue"])
        id_conf = [r for r in self.tables["tblConfidencePolicies"] if r["Scope"] == "IDENTIFICATION"]
        self.assertTrue(id_conf)
        self.assertTrue(all(r["WeightOrScore"] == "" and r["ResultConfidence"] and r["CorroborationRule"] for r in id_conf))
        weighted = [r for r in self.runtime["policies"]["confidencePolicies"] if r["scope"] != "IDENTIFICATION"]
        self.assertTrue(weighted and all(isinstance(r["weightOrScore"], (int, float)) for r in weighted))
        floor = next(r for r in self.runtime["policies"]["conflictPolicies"] if r["ruleType"] == "IDENTIFICATION")
        self.assertEqual("MEDIUM", floor["minimumEvidenceStrengthForValue"])

    # Determinism

    def test_two_exports_are_byte_identical_and_match_golden(self):
        again = POC.canonical_json_bytes(POC.build_runtime_json(POC.read_xlsx_tables(self.workbook)))
        self.assertEqual(self.json_bytes, again)
        manifest = json.loads((POC_ROOT / "poc-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["expectedJsonSha256"], hashlib.sha256(self.json_bytes).hexdigest())
        regenerated = Path(self.temp_dir.name) / "again.xlsx"
        GENERATOR.generate(POC_ROOT / "workbook-source.json", regenerated)
        self.assertEqual(self.workbook.read_bytes(), regenerated.read_bytes())

    # VBA / Python parity (source level)

    def test_vba_projection_matches_reference_contract(self):
        constants = vba("modConstants.bas")
        self.assertIn(f'EMAS_POC_EVALUATION_DATE As String = "{PROJECTION.POC_EVALUATION_DATE}"', constants)
        self.assertIn(f'EMAS_RUNTIME_STATUS As String = "{PROJECTION.RUNTIME_STATUS}"', constants)
        self.assertIn('EMAS_WORKBOOK_ONLY_RULE_COLUMNS As String = "LegacyRuleId"', constants)
        self.assertEqual({"tblRules": frozenset({"LegacyRuleId"})}, MODEL.WORKBOOK_ONLY_COLUMNS)
        builder = vba("modJsonBuilder.bas")
        for table in ("tblMasterDataRelationships", "tblRules", "tblRulePhaseAssignments", "tblConditionGroups", "tblRuleConditions", "tblRuleOutputs"):
            self.assertIn(f'BuildRuntimeGraphArray("{table}"', builder)
            self.assertNotIn(f'BuildTableArray("{table}"', builder)
        self.assertIn("AssertRuntimeJsonHasNoLegacyRuleId jsonText", builder)
        projection = vba("modRuntimeProjection.bas")
        self.assertIn('"RULE_SUPERSESSION"', projection)
        validation = vba("modValidation.bas")
        statuses = re.search(r'Array\(("Draft"[^)]*)\)', validation).group(1)
        self.assertEqual(list(PROJECTION.RULE_LIFECYCLE_STATUSES), [s.strip().strip('"') for s in statuses.split(",")])
        for code in ("SEM_OUTPUT_TARGET", "SEM_IDENTIFICATION_DIMENSION_MISMATCH", "SEM_CONTROLLED_REFERENCE", "SEM_EVIDENCE_STRENGTH_CEILING",
                     "SEM_IDENTIFICATION_METADATA_REQUIRED", "SEM_IDENTIFICATION_NUMERIC_WEIGHT", "SEM_ORDINAL_ORDER",
                     "POC_LEGACY_RULE_ID_AS_RULE_ID", "POC_RULE_LIFECYCLE", "SEM_IDENTIFICATION_METADATA_SCOPE", "SEM_IDENTIFICATION_DIMENSION"):
            self.assertIn(f'"{code}"', validation)

    def test_vba_files_keep_crlf_and_ascii(self):
        for path in VBA.glob("*.bas"):
            data = path.read_bytes()
            with self.subTest(module=path.name):
                data.decode("ascii")
                self.assertEqual(data.count(b"\n"), data.count(b"\r\n"))


if __name__ == "__main__":
    unittest.main()
