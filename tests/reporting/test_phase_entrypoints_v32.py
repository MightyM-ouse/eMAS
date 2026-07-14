import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class PhaseEntrypointV32Tests(unittest.TestCase):
    PHASE_SCRIPTS = {
        "PRE_SALES": "scripts/eMAS-PreSalesAssessment.ps1",
        "PRE_MIGRATION": "scripts/eMAS-PreMigrationReadiness.ps1",
        "POST_MIGRATION": "scripts/eMAS-PostMigrationVerification.ps1",
    }

    def test_phase_scripts_require_normalized_result_and_use_shared_orchestrator(self):
        for phase, relative_path in self.PHASE_SCRIPTS.items():
            text = (ROOT / relative_path).read_text(encoding="utf-8")
            self.assertIn("[string] $NormalizedResultPath", text, relative_path)
            self.assertIn("Invoke-eMASPhaseReport", text, relative_path)
            self.assertIn(f"-Phase '{phase}'", text, relative_path)
            self.assertIn("-RuntimeConfigurationPath $RuntimeConfigurationPath", text)
            self.assertIn("-NormalizedResultPath $NormalizedResultPath", text)
            self.assertIn("-OutputWorkbookPath $OutputWorkbookPath", text)
            self.assertNotIn("Read-Host", text)

    def test_shared_orchestrator_validates_runtime_before_report_population(self):
        text = (ROOT / "scripts/private/Invoke-eMASPhaseReport.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("Initialize-eMASPhaseRuntime", text)
        self.assertIn("Export-eMASResultToTemplate", text)
        self.assertLess(
            text.index("Initialize-eMASPhaseRuntime"),
            text.index("Export-eMASResultToTemplate"),
        )
        self.assertIn("Write-Progress", text)
        self.assertIn("finally", text)
        self.assertIn("-Completed", text)

    def test_default_contract_paths_cover_all_phases(self):
        text = (ROOT / "scripts/private/Invoke-eMASPhaseReport.ps1").read_text(
            encoding="utf-8"
        )
        expected_paths = (
            "templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx",
            "templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx",
            "templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx",
            "config/report-mappings/pre-sales.template-map.json",
            "config/report-mappings/pre-migration.template-map.json",
            "config/report-mappings/post-migration.template-map.json",
        )
        for path in expected_paths:
            self.assertIn(path, text)

    def test_orchestrator_returns_traceable_output_metadata(self):
        text = (ROOT / "scripts/private/Invoke-eMASPhaseReport.ps1").read_text(
            encoding="utf-8"
        )
        for property_name in (
            "ExecutionId",
            "MappingVersion",
            "TemplateVersion",
            "ResultContractVersion",
            "ResultSchemaPath",
            "OutputWorkbookPath",
            "ExecutionLogPath",
            "OutputSha256",
            "TargetRowCounts",
            "Validation",
        ):
            self.assertIn(property_name, text)


if __name__ == "__main__":
    unittest.main()
