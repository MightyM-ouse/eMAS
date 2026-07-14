import copy
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "engine" / "reporting"))
sys.path.insert(0, str(ROOT / "tests" / "reporting"))

from emas_report_openxml_v32 import export_report_v32  # noqa: E402
from emas_report_openxml import OpenXmlPackage, sha256_file, validate_zip_package  # noqa: E402
from fixture_factory_v32 import build_minimal_result  # noqa: E402


PHASES = {
    "PRE_SALES": {
        "mapping": "config/report-mappings/pre-sales.template-map.json",
        "template": "templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx",
        "sheet_count": 4,
    },
    "PRE_MIGRATION": {
        "mapping": "config/report-mappings/pre-migration.template-map.json",
        "template": "templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx",
        "sheet_count": 11,
    },
    "POST_MIGRATION": {
        "mapping": "config/report-mappings/post-migration.template-map.json",
        "template": "templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx",
        "sheet_count": 15,
    },
}


class ReportGenerationV32Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.temp_path = Path(cls.temp.name)
        cls.mapping_schema_path = ROOT / "config/report-mappings/report-template-map.schema.json"
        cls.generated = {}

        for phase, config in PHASES.items():
            mapping_path = ROOT / config["mapping"]
            template_path = ROOT / config["template"]
            mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
            result_schema_path = ROOT / mapping["resultSchemaPath"]
            result_schema = json.loads(result_schema_path.read_text(encoding="utf-8"))
            result = build_minimal_result(phase, mapping, result_schema)
            cls.generated[phase] = cls.generate(
                phase,
                mapping_path=mapping_path,
                template_path=template_path,
                result_schema_path=result_schema_path,
                result=result,
                suffix="valid",
            )

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def generate(
        cls,
        phase,
        *,
        mapping_path,
        template_path,
        result_schema_path,
        result,
        suffix,
        mapping_override=None,
    ):
        result_path = cls.temp_path / f"{phase}-{suffix}-result.json"
        result_path.write_text(json.dumps(result, indent=2), encoding="utf-8")

        effective_mapping_path = mapping_path
        if mapping_override is not None:
            effective_mapping_path = cls.temp_path / f"{phase}-{suffix}-mapping.json"
            effective_mapping_path.write_text(
                json.dumps(mapping_override, indent=2),
                encoding="utf-8",
            )

        output = cls.temp_path / f"{phase}-{suffix}.xlsx"
        log = cls.temp_path / f"{phase}-{suffix}.log"
        response = export_report_v32(
            result_path,
            effective_mapping_path,
            cls.mapping_schema_path,
            template_path,
            output,
            log,
            result_schema_path,
        )
        return response, output, log, result

    @staticmethod
    def load_contract(phase):
        config = PHASES[phase]
        mapping_path = ROOT / config["mapping"]
        template_path = ROOT / config["template"]
        mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
        result_schema_path = ROOT / mapping["resultSchemaPath"]
        result_schema = json.loads(result_schema_path.read_text(encoding="utf-8"))
        return mapping_path, template_path, mapping, result_schema_path, result_schema

    def assert_failure(self, generated, code):
        response = generated[0]
        self.assertEqual("Failed", response["Status"])
        self.assertEqual(code, response["Validation"]["Findings"][0]["Code"])
        self.assertTrue(response["Validation"]["Findings"][0]["IsBlocking"])

    def test_01_mapping_and_template_versions_are_aligned(self):
        for phase, config in PHASES.items():
            _, template_path, mapping, _, _ = self.load_contract(phase)
            self.assertEqual("2.0.0", mapping["mappingVersion"])
            self.assertEqual("1.2.0", mapping["template"]["templateVersion"])
            self.assertEqual(config["sheet_count"], len(mapping["requiredSheetOrder"]))
            package = OpenXmlPackage(template_path)
            self.assertEqual(mapping["requiredSheetOrder"], list(package.sheet_paths))

    def test_02_all_phase_reports_generate_from_normalized_results(self):
        for phase, (response, output, log, _) in self.generated.items():
            self.assertEqual("Passed", response["Status"], phase)
            self.assertEqual(phase, response["Phase"])
            self.assertEqual("2.0.0", response["MappingVersion"])
            self.assertEqual("1.2.0", response["TemplateVersion"])
            self.assertEqual("1.0.0", response["ResultContractVersion"])
            self.assertTrue(Path(response["ResultSchemaPath"]).is_file())
            self.assertTrue(output.is_file())
            self.assertTrue(log.is_file())

    def test_03_controlled_source_templates_remain_unchanged(self):
        for phase, (response, _, _, _) in self.generated.items():
            self.assertEqual(
                response["SourceTemplateSha256Before"],
                response["SourceTemplateSha256After"],
                phase,
            )

    def test_04_generated_workbooks_preserve_control_identity(self):
        for phase, (_, output, _, _) in self.generated.items():
            _, _, mapping, _, _ = self.load_contract(phase)
            package = OpenXmlPackage(output)
            control = package.control_metadata(mapping["template"]["templateControlTable"])
            self.assertEqual(mapping["template"]["templateId"], control["TemplateId"])
            self.assertEqual("1.2.0", control["TemplateVersion"])
            self.assertEqual(phase, control["PhaseCode"])

    def test_05_raw_evidence_headers_are_preserved_exactly(self):
        response = self.generated["POST_MIGRATION"][0]
        self.assertIn("Source.Name", response["RawHeaders"]["tblRawImportReportDetail"])
        post_headers = response["RawHeaders"]["tblRawPostImportVerification"]
        self.assertIn("DossierDirecotry", post_headers)
        self.assertNotIn("DossierDirectory", post_headers)
        self.assertIn("tblRawDatabaseDossierExtract", response["RawHeaders"])

    def test_06_missing_required_result_property_is_blocking(self):
        mapping_path, template_path, mapping, schema_path, schema = self.load_contract("PRE_MIGRATION")
        result = build_minimal_result("PRE_MIGRATION", mapping, schema)
        del result["readinessDecision"]
        generated = self.generate(
            "PRE_MIGRATION",
            mapping_path=mapping_path,
            template_path=template_path,
            result_schema_path=schema_path,
            result=result,
            suffix="missing-required",
        )
        self.assert_failure(generated, "RPT-RESULT-SCHEMA-001")

    def test_07_unsupported_result_contract_version_is_blocking(self):
        mapping_path, template_path, mapping, schema_path, schema = self.load_contract("PRE_SALES")
        result = build_minimal_result("PRE_SALES", mapping, schema)
        result["resultContractVersion"] = "9.9.9"
        generated = self.generate(
            "PRE_SALES",
            mapping_path=mapping_path,
            template_path=template_path,
            result_schema_path=schema_path,
            result=result,
            suffix="bad-result-version",
        )
        self.assert_failure(generated, "RPT-RESULT-SCHEMA-004")

    def test_08_phase_mismatch_is_rejected_by_result_schema(self):
        mapping_path, template_path, mapping, schema_path, schema = self.load_contract("PRE_SALES")
        result = build_minimal_result("PRE_SALES", mapping, schema)
        result["phaseCode"] = "POST_MIGRATION"
        generated = self.generate(
            "PRE_SALES",
            mapping_path=mapping_path,
            template_path=template_path,
            result_schema_path=schema_path,
            result=result,
            suffix="bad-phase",
        )
        self.assert_failure(generated, "RPT-RESULT-SCHEMA-001")

    def test_09_unsupported_mapping_version_is_blocking(self):
        mapping_path, template_path, mapping, schema_path, schema = self.load_contract("PRE_SALES")
        result = build_minimal_result("PRE_SALES", mapping, schema)
        invalid_mapping = copy.deepcopy(mapping)
        invalid_mapping["mappingVersion"] = "1.0.0"
        generated = self.generate(
            "PRE_SALES",
            mapping_path=mapping_path,
            template_path=template_path,
            result_schema_path=schema_path,
            result=result,
            suffix="bad-map-version",
            mapping_override=invalid_mapping,
        )
        self.assert_failure(generated, "RPT-MAP-002")

    def test_10_generated_packages_are_valid_openxml(self):
        for _, output, _, _ in self.generated.values():
            validate_zip_package(output)
            with zipfile.ZipFile(output) as archive:
                self.assertIsNone(archive.testzip())

    def test_11_relationships_formulas_and_controls_are_preserved(self):
        for phase, (_, output, _, _) in self.generated.items():
            _, template_path, mapping, _, _ = self.load_contract(phase)
            before = OpenXmlPackage(template_path).snapshot(mapping["protectedTables"])
            after = OpenXmlPackage(output).snapshot(mapping["protectedTables"])
            for key in (
                "sheets",
                "formulas",
                "validations",
                "conditionalFormatting",
                "relationships",
                "protectedData",
            ):
                self.assertEqual(before[key], after[key], f"{phase}: {key}")

    def test_12_timestamped_utf8_logs_capture_contract_validation(self):
        for phase, (response, _, log, _) in self.generated.items():
            text = log.read_text(encoding="utf-8")
            self.assertIn("Phase result schema validation passed", text, phase)
            self.assertIn("Mapping validated", text, phase)
            self.assertIn(response["TemplateId"], text, phase)
            self.assertIn("Report generation completed", text, phase)

    def test_13_powershell_surface_uses_v32_helper_and_result_schema(self):
        module = (ROOT / "engine/reporting/eMAS.ReportPopulation.psm1").read_text(
            encoding="utf-8"
        )
        self.assertIn("emas_report_openxml_v32.py", module)
        self.assertIn("Resolve-eMASResultSchemaPath", module)
        self.assertIn("--result-schema", module)
        self.assertIn("ConvertTo-Json -Depth 100", module)

    def test_14_fixture_factory_does_not_add_unapproved_top_level_fields(self):
        for phase in PHASES:
            _, _, mapping, _, schema = self.load_contract(phase)
            result = build_minimal_result(phase, mapping, schema)
            self.assertEqual(set(schema["properties"]), set(result))
            self.assertNotIn("mappingId", result)
            self.assertNotIn("templateId", result)
            self.assertNotIn("templateVersion", result)

    def test_15_template_hash_matches_report_response(self):
        for phase, (response, _, _, _) in self.generated.items():
            _, template_path, _, _, _ = self.load_contract(phase)
            self.assertEqual(sha256_file(template_path), response["SourceTemplateSha256Before"], phase)


if __name__ == "__main__":
    unittest.main()
