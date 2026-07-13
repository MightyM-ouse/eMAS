import copy
import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "engine" / "reporting"))

from emas_report_openxml import (  # noqa: E402
    OpenXmlPackage,
    export_report,
    sha256_file,
    validate_zip_package,
)


PHASES = {
    "PRE_SALES": {
        "result": "demo/results/pre-sales-result.demo.json",
        "mapping": "config/report-mappings/pre-sales.template-map.json",
        "template": "templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx",
    },
    "PRE_MIGRATION": {
        "result": "demo/results/pre-migration-result.demo.json",
        "mapping": "config/report-mappings/pre-migration.template-map.json",
        "template": "templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx",
    },
    "POST_MIGRATION": {
        "result": "demo/results/post-migration-result.demo.json",
        "mapping": "config/report-mappings/post-migration.template-map.json",
        "template": "templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx",
    },
}


class ReportGenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.temp_path = Path(cls.temp.name)
        cls.schema = ROOT / "config/report-mappings/report-template-map.schema.json"
        cls.generated = {}
        for phase in PHASES:
            cls.generated[phase] = cls.generate_phase(phase)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def generate_phase(cls, phase, *, result=None, mapping=None, template=None, suffix="valid"):
        config = PHASES[phase]
        result_path = ROOT / config["result"]
        mapping_path = ROOT / config["mapping"]
        template_path = ROOT / config["template"]
        if result is not None:
            result_path = cls.temp_path / f"{phase}-{suffix}-result.json"
            result_path.write_text(json.dumps(result), encoding="utf-8")
        if mapping is not None:
            mapping_path = cls.temp_path / f"{phase}-{suffix}-mapping.json"
            mapping_path.write_text(json.dumps(mapping), encoding="utf-8")
        if template is not None:
            template_path = template
        output = cls.temp_path / f"{phase}-{suffix}.xlsx"
        log = cls.temp_path / f"{phase}-{suffix}.log"
        response = export_report(result_path, mapping_path, cls.schema, template_path, output, log)
        return response, output, log

    @staticmethod
    def load_result(phase):
        return json.loads((ROOT / PHASES[phase]["result"]).read_text(encoding="utf-8"))

    @staticmethod
    def load_mapping(phase):
        return json.loads((ROOT / PHASES[phase]["mapping"]).read_text(encoding="utf-8"))

    def assert_failure(self, response_tuple, code):
        response = response_tuple[0]
        self.assertEqual("Failed", response["Status"])
        self.assertEqual(code, response["Validation"]["Findings"][0]["Code"])
        self.assertTrue(response["Validation"]["Findings"][0]["IsBlocking"])

    def test_01_valid_pre_sales_population(self):
        response, output, log = self.generated["PRE_SALES"]
        self.assertEqual("Passed", response["Status"])
        self.assertTrue(output.exists())
        self.assertTrue(log.exists())

    def test_02_valid_pre_migration_population(self):
        response, output, _ = self.generated["PRE_MIGRATION"]
        self.assertEqual("Ready with Accepted Exceptions", response["FinalResult"])
        self.assertTrue(output.exists())

    def test_03_valid_post_migration_population(self):
        response, output, _ = self.generated["POST_MIGRATION"]
        self.assertEqual("Reconciled with Accepted Exceptions", response["FinalResult"])
        self.assertTrue(output.exists())

    def test_04_invalid_template_id(self):
        result = self.load_result("PRE_SALES")
        result["templateId"] = "INVALID"
        self.assert_failure(self.generate_phase("PRE_SALES", result=result, suffix="bad-id"), "RPT-TEMPLATE-003")

    def test_05_invalid_template_version(self):
        result = self.load_result("PRE_SALES")
        result["templateVersion"] = "1.1.0"
        self.assert_failure(self.generate_phase("PRE_SALES", result=result, suffix="bad-version"), "RPT-TEMPLATE-004")

    def test_06_phase_mismatch(self):
        result = self.load_result("PRE_SALES")
        result["phaseCode"] = "POST_MIGRATION"
        self.assert_failure(self.generate_phase("PRE_SALES", result=result, suffix="bad-phase"), "RPT-RESULT-002")

    def test_07_missing_worksheet(self):
        mapping = self.load_mapping("PRE_SALES")
        mapping["tableMappings"][0]["sheetName"] = "Missing"
        self.assert_failure(self.generate_phase("PRE_SALES", mapping=mapping, suffix="missing-sheet"), "RPT-SHEET-002")

    def test_08_missing_table(self):
        mapping = self.load_mapping("PRE_SALES")
        mapping["tableMappings"][0]["tableName"] = "tblMissing"
        self.assert_failure(self.generate_phase("PRE_SALES", mapping=mapping, suffix="missing-table"), "RPT-TABLE-001")

    def test_09_missing_mapped_column(self):
        mapping = self.load_mapping("PRE_SALES")
        mapping["tableMappings"][0]["columns"][0]["targetColumn"] = "MissingColumn"
        self.assert_failure(self.generate_phase("PRE_SALES", mapping=mapping, suffix="missing-column"), "RPT-COLUMN-001")

    def test_10_duplicate_label_row_match(self):
        result = self.load_result("PRE_SALES")
        result["summaryMetrics"].append(copy.deepcopy(result["summaryMetrics"][0]))
        self.assert_failure(self.generate_phase("PRE_SALES", result=result, suffix="duplicate-label"), "RPT-ROW-002")

    def test_11_unsupported_write_mode(self):
        mapping = self.load_mapping("PRE_SALES")
        mapping["tableMappings"][1]["writeMode"] = "inventedMode"
        self.assert_failure(self.generate_phase("PRE_SALES", mapping=mapping, suffix="unsupported-mode"), "RPT-MAP-001")

    def test_12_append_rows(self):
        response, output, _ = self.generated["PRE_SALES"]
        self.assertEqual(3, response["TargetRowCounts"]["tblPreSalesDossiers"])
        package = OpenXmlPackage(output)
        rows = package.table_rows(package.tables["tblPreSalesDossiers"])
        self.assertEqual(["DOS-GREEN", "DOS-AMBER", "DOS-RED"], [row[0] for row in rows[1:]])

    def test_13_match_row_by_label_columns(self):
        _, output, _ = self.generated["PRE_SALES"]
        package = OpenXmlPackage(output)
        table = package.tables["tblPreSalesSummary"]
        rows = package.table_rows(table)
        match = [row for row in rows if row[0:2] == ["Estimate", "Final Complexity Band"]]
        self.assertEqual("Medium", match[0][2])
        self.assertEqual("Warning", match[0][3])

    def test_14_single_row_update(self):
        _, output, _ = self.generated["PRE_MIGRATION"]
        package = OpenXmlPackage(output)
        rows = package.table_rows(package.tables["tblPreMigrationDecision"])
        self.assertEqual(2, len(rows))
        self.assertIn("Ready with Accepted Exceptions", rows[1])

    def test_15_copy_from_external_source_append_only(self):
        _, output, _ = self.generated["POST_MIGRATION"]
        package = OpenXmlPackage(output)
        rows = package.table_rows(package.tables["tblRawImportReportDetail"])
        self.assertEqual("MigrationSummary.xlsx", rows[1][0])
        self.assertEqual("Warning", rows[1][3])

    def test_16_static_release_managed(self):
        mapping = self.load_mapping("PRE_SALES")
        source = OpenXmlPackage(ROOT / PHASES["PRE_SALES"]["template"])
        generated = OpenXmlPackage(self.generated["PRE_SALES"][1])
        control = mapping["template"]["templateControlTable"]
        self.assertEqual(source.table_rows(source.tables[control]), generated.table_rows(generated.tables[control]))

    def test_17_source_template_unchanged(self):
        for phase, (response, _, _) in self.generated.items():
            self.assertEqual(response["SourceTemplateSha256Before"], response["SourceTemplateSha256After"], phase)

    def test_18_formulas_preserved(self):
        self._assert_snapshot_property("formulas")

    def test_19_validations_preserved(self):
        self._assert_snapshot_property("validations")

    def test_20_conditional_formatting_preserved(self):
        self._assert_snapshot_property("conditionalFormatting")

    def _assert_snapshot_property(self, property_name):
        for phase, (_, output, _) in self.generated.items():
            mapping = self.load_mapping(phase)
            source = OpenXmlPackage(ROOT / PHASES[phase]["template"])
            generated = OpenXmlPackage(output)
            self.assertEqual(source.snapshot(mapping["protectedTables"])[property_name], generated.snapshot(mapping["protectedTables"])[property_name], phase)

    def test_21_raw_headers_preserved(self):
        response = self.generated["POST_MIGRATION"][0]
        self.assertEqual("Source.Name", response["RawHeaders"]["tblRawImportReportDetail"][0])

    def test_22_dossier_direcotry_preserved(self):
        response = self.generated["POST_MIGRATION"][0]
        headers = response["RawHeaders"]["tblRawPostImportVerification"]
        self.assertIn("DossierDirecotry", headers)
        self.assertNotIn("DossierDirectory", headers)

    def test_23_generated_openxml_package_validity(self):
        for _, output, _ in self.generated.values():
            validate_zip_package(output)
            with zipfile.ZipFile(output) as archive:
                self.assertIsNone(archive.testzip())

    def test_24_runtime_loader_blocking_failure_contract(self):
        common = (ROOT / "demo/scripts/private/Invoke-eMASDemoPhase.ps1").read_text(encoding="utf-8")
        bootstrap = (ROOT / "scripts/private/Initialize-eMASPhaseRuntime.ps1").read_text(encoding="utf-8")
        self.assertIn("Initialize-eMASPhaseRuntime", common)
        self.assertIn("BlockingIssueCount -gt 0", bootstrap)
        self.assertLess(common.index("Initialize-eMASPhaseRuntime"), common.index("Export-eMASResultToTemplate"))

    def test_25_timestamped_log_generation(self):
        common = (ROOT / "demo/scripts/private/Invoke-eMASDemoPhase.ps1").read_text(encoding="utf-8")
        self.assertIn("yyyyMMddTHHmmssZ", common)
        for response, _, log in self.generated.values():
            text = log.read_text(encoding="utf-8")
            self.assertIn("Mapping validated", text)
            self.assertIn(response["TemplateId"], text)
            self.assertIn("EMAS-DEMO-CONFIG", text)
            self.assertIn("Report generation completed", text)

    def test_26_progress_indicators_closed_on_failure(self):
        common = (ROOT / "demo/scripts/private/Invoke-eMASDemoPhase.ps1").read_text(encoding="utf-8")
        self.assertIn("finally", common)
        self.assertGreaterEqual(common.count("-Completed"), 2)

    def test_27_template_and_output_identity(self):
        for phase, (response, output, _) in self.generated.items():
            mapping = self.load_mapping(phase)
            package = OpenXmlPackage(output)
            control = package.control_metadata(mapping["template"]["templateControlTable"])
            self.assertEqual(mapping["template"]["templateId"], control["TemplateId"])
            self.assertEqual("1.1.1", control["TemplateVersion"])
            self.assertEqual(phase, control["PhaseCode"])
            self.assertEqual(mapping["requiredSheetOrder"], list(package.sheet_paths))

    def test_28_relationships_and_columns_preserved(self):
        for phase, (_, output, _) in self.generated.items():
            mapping = self.load_mapping(phase)
            source = OpenXmlPackage(ROOT / PHASES[phase]["template"])
            generated = OpenXmlPackage(output)
            before = source.snapshot(mapping["protectedTables"])
            after = generated.snapshot(mapping["protectedTables"])
            self.assertEqual(before["relationships"], after["relationships"])
            self.assertEqual({k: v["columns"] for k, v in before["tables"].items()}, {k: v["columns"] for k, v in after["tables"].items()})


if __name__ == "__main__":
    unittest.main()
