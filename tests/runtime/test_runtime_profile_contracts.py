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

    def test_windows_runtime_workflow_declares_51_and_76_jobs(self):
        workflow = (ROOT / ".github" / "workflows" / "powershell-runtime-contracts.yml").read_text(encoding="utf-8")
        self.assertIn("windows-powershell-51-contracts", workflow)
        self.assertIn("powershell-76-contracts", workflow)
        self.assertIn("shell: powershell", workflow)
        self.assertIn("shell: pwsh", workflow)


if __name__ == "__main__":
    unittest.main()
