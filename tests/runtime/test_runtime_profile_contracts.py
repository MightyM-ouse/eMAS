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
        contract = (ROOT / "engine" / "core" / "eMAS.Configuration.Contract.psm1").read_text(encoding="utf-8")
        prohibited_tokens = ("??", "ForEach-Object -Parallel", "&&", "||")
        for token in prohibited_tokens:
            with self.subTest(token=token):
                self.assertNotIn(token, contract)

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
