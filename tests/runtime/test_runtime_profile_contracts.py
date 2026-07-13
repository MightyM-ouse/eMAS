import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class RuntimeProfileContractTests(unittest.TestCase):
    def test_engine_boundaries_exist(self):
        for relative in ("engine/core", "engine/powershell51", "engine/powershell7"):
            with self.subTest(path=relative):
                self.assertTrue((ROOT / relative).is_dir())

    def test_runtime_configuration_module_exposes_stable_interface(self):
        module = (
            ROOT / "engine" / "core" / "eMAS.RuntimeConfiguration.psm1"
        ).read_text(encoding="utf-8")
        for function_name in (
            "Import-eMASRuntimeConfiguration",
            "Test-eMASRuntimeConfiguration",
            "Get-eMASConfigurationMetadata",
            "Get-eMASConfigurationSection",
            "Get-eMASConfigurationValue",
            "Get-eMASRuleCollection",
            "Get-eMASCodeList",
            "Resolve-eMASConfigurationPath",
        ):
            with self.subTest(function=function_name):
                self.assertIn(f"function {function_name}", module)
        self.assertIn("eMAS.RuntimeConfiguration", module)
        self.assertIn("FileHashSha256", module)
        self.assertIn("BlockingIssueCount", module)

    def test_phase_entry_scripts_accept_one_runtime_configuration_path(self):
        for script_name in (
            "eMAS-PreSalesAssessment.ps1",
            "eMAS-PreMigrationReadiness.ps1",
            "eMAS-PostMigrationVerification.ps1",
        ):
            with self.subTest(script=script_name):
                script = (ROOT / "scripts" / script_name).read_text(encoding="utf-8")
                self.assertIn("$RuntimeConfigurationPath", script)
                self.assertIn("Initialize-eMASPhaseRuntime", script)
                self.assertNotIn(".xlsm", script.lower())
                self.assertNotIn(".xlsx", script.lower())

    def test_core_contract_contains_warning_and_rejects_unknown_by_contract(self):
        contract = (ROOT / "engine" / "core" / "eMAS.Configuration.Contract.psm1").read_text(encoding="utf-8")
        self.assertIn("'Warning'", contract)
        self.assertIn("Test-eMASEvaluationStatusCode", contract)
        self.assertNotIn("RecoverableWarning", contract)

    def test_core_evaluation_status_order_exactly_matches_json_schema(self):
        common_schema = json.loads(
            (ROOT / "config" / "schema" / "defs" / "common.schema.json").read_text(
                encoding="utf-8"
            )
        )
        schema_codes = common_schema["$defs"]["evaluationStatus"]["enum"]
        contract = (
            ROOT / "engine" / "core" / "eMAS.Configuration.Contract.psm1"
        ).read_text(encoding="utf-8")
        block = re.search(
            r"EvaluationStatusCodes\s*=\s*@\((.*?)^\s*\)",
            contract,
            flags=re.MULTILINE | re.DOTALL,
        )
        self.assertIsNotNone(block, "EvaluationStatusCodes contract block is missing")
        contract_codes = re.findall(r"^\s*'([^']+)'\s*,?\s*$", block.group(1), re.MULTILINE)
        self.assertEqual(
            schema_codes,
            contract_codes,
            "PowerShell contract values must match schema values exactly, including order",
        )

    def test_core_contract_avoids_powershell7_only_syntax(self):
        sources = list((ROOT / "engine" / "core").rglob("*.ps1"))
        sources.extend((ROOT / "engine" / "core").rglob("*.psm1"))
        prohibited_tokens = (
            "??",
            "ForEach-Object -Parallel",
            "&&",
            "||",
            "Test-Json",
        )
        for source_path in sources:
            source = source_path.read_text(encoding="utf-8")
            for token in prohibited_tokens:
                with self.subTest(path=source_path.name, token=token):
                    self.assertNotIn(token, source)

    def test_runtime_configuration_fixtures_are_synthetic_and_bounded(self):
        fixture_root = ROOT / "tests" / "fixtures" / "runtime-config"
        self.assertTrue((fixture_root / "valid-minimal.json").is_file())
        for fixture_path in fixture_root.glob("*.json"):
            payload = fixture_path.read_bytes()
            self.assertFalse(payload.startswith(b"\xef\xbb\xbf"))
            text = payload.decode("utf-8")
            self.assertNotIn("customer", text.lower())
            self.assertNotIn(".xlsm", text.lower())
            if fixture_path.name not in {"invalid-malformed.json", "invalid-empty.json"}:
                json.loads(text)

    def test_dependency_free_powershell_harness_covers_required_boundaries(self):
        harness_path = ROOT / "tests" / "runtime" / "Test-eMASRuntimeConfiguration.ps1"
        harness = harness_path.read_text(encoding="utf-8")
        self.assertNotIn("Import-Module Pester", harness)
        for coverage_marker in (
            "valid minimal JSON",
            "malformed JSON",
            "empty JSON",
            "missing file",
            "missing metadata",
            "missing schema version",
            "unsupported schema version",
            "duplicate rule identifiers",
            "missing recommendation reference",
            "invalid RAG value",
            "configured code list",
            "missing optional code list",
            "path containing spaces",
            "UTF-8 metadata",
            "SHA-256 identity",
            "source Runtime JSON remains read-only",
            "all phase entry scripts accept one valid Runtime JSON path",
            "all phase entry scripts stop",
        ):
            with self.subTest(marker=coverage_marker):
                self.assertIn(coverage_marker, harness)
        workflow = (ROOT / ".github" / "workflows" / "powershell-runtime-contracts.yml").read_text(encoding="utf-8")
        self.assertEqual(3, workflow.count("Test-eMASRuntimeConfiguration.ps1"))

    def test_adapter_contracts_keep_phase_runtime_split(self):
        ps51 = (ROOT / "engine" / "powershell51" / "eMAS.RuntimeAdapter.PS51.Contract.psm1").read_text(encoding="utf-8")
        ps7 = (ROOT / "engine" / "powershell7" / "eMAS.RuntimeAdapter.PS7.Contract.psm1").read_text(encoding="utf-8")
        self.assertIn("'PRE_SALES'", ps51)
        self.assertNotIn("'PRE_MIGRATION'", ps51)
        self.assertIn("'PRE_MIGRATION'", ps7)
        self.assertIn("'POST_MIGRATION'", ps7)
        self.assertNotIn("'PRE_SALES'", ps7)

    def test_runtime_workflow_declares_windows_and_macos_contract_jobs(self):
        workflow = (ROOT / ".github" / "workflows" / "powershell-runtime-contracts.yml").read_text(encoding="utf-8")
        self.assertIn("windows-powershell-51-contracts", workflow)
        self.assertIn("windows-powershell-76-contracts", workflow)
        self.assertIn("macos-powershell-76-development-contracts", workflow)
        self.assertIn("shell: powershell", workflow)
        self.assertIn("shell: pwsh", workflow)

    def test_runtime_workflow_covers_schema_and_runtime_paths(self):
        workflow = (ROOT / ".github" / "workflows" / "powershell-runtime-contracts.yml").read_text(encoding="utf-8")
        for path_filter in (
            "config/schema/**",
            "build/emas_schema_semantics.py",
            "build/emas_schema_model.py",
            "tests/schema/**",
            "docs/configuration/**",
            "engine/**",
            "scripts/**",
            "tests/fixtures/runtime-config/**",
            "tests/runtime/**",
        ):
            with self.subTest(path=path_filter):
                self.assertEqual(2, workflow.count(f'- "{path_filter}"'))

    def test_macos_job_does_not_import_windows_adapters(self):
        workflow = (ROOT / ".github" / "workflows" / "powershell-runtime-contracts.yml").read_text(encoding="utf-8")
        macos_job = workflow.split("  macos-powershell-76-development-contracts:", 1)[1]
        self.assertIn("runs-on: macos-latest", macos_job)
        self.assertIn("engine/core/eMAS.Configuration.Contract.psm1", macos_job)
        self.assertIn("PSVersion.Minor -ne 6", macos_job)
        self.assertNotIn("engine/powershell51", macos_job)
        self.assertNotIn("engine/powershell7", macos_job)


if __name__ == "__main__":
    unittest.main()
