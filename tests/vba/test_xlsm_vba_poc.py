import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "build"))

import emas_xlsx_poc as POC  # noqa: E402
import generate_emas_mapping_poc_workbook as GENERATOR  # noqa: E402
import validate_xlsm_vba_poc as VALIDATOR  # noqa: E402


class XlsmVbaPocTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.source_definition = ROOT / "config" / "authoring" / "poc" / "workbook-source.json"
        cls.workbook = Path(cls.temp_dir.name) / "eMAS_Mapping_Configuration_POC_Source.xlsx"
        GENERATOR.generate(cls.source_definition, cls.workbook)
        cls.fixture_root = ROOT / "config" / "authoring" / "poc" / "fixtures"
        cls.tables = POC.read_xlsx_tables(cls.workbook)

    @classmethod
    def tearDownClass(cls):
        cls.temp_dir.cleanup()

    def test_workbook_and_golden_json_hash_match(self):
        issues = POC.validate_workbook_tables(self.tables)
        self.assertEqual([], [issue.render() for issue in issues])
        actual = POC.canonical_json_bytes(POC.build_runtime_json(self.tables))
        manifest = json.loads((ROOT / "config" / "authoring" / "poc" / "poc-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["expectedJsonSha256"], hashlib.sha256(actual).hexdigest())
        self.assertFalse(actual.startswith(b"\xef\xbb\xbf"))

    def test_fixture_manifest_expectations(self):
        manifest = json.loads((self.fixture_root / "manifest.json").read_text(encoding="utf-8"))
        for fixture in manifest["fixtures"]:
            with self.subTest(fixture=fixture["id"]):
                tables = self.tables
                if fixture.get("patch"):
                    patch = json.loads((self.fixture_root / fixture["patch"]).read_text(encoding="utf-8"))
                    tables = POC.apply_fixture_patch(self.tables, patch)
                issues = POC.validate_workbook_tables(tables)
                self.assertEqual(bool(fixture["expectedValid"]), not issues, [i.render() for i in issues])
                self.assertTrue(set(fixture.get("expectedErrorCodes", [])).issubset({i.code for i in issues}))

    def test_vba_source_contract(self):
        failures = VALIDATOR.validate_vba_sources(ROOT / "config" / "vba" / "modules")
        self.assertEqual([], failures)

    def test_manifest_hashes(self):
        manifest = json.loads((ROOT / "config" / "authoring" / "poc" / "poc-manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["workbookSourceBundleSha256"], VALIDATOR.source_bundle_sha256(self.source_definition))
        self.assertEqual(manifest["generatedSourceWorkbookSha256"], VALIDATOR.sha256(self.workbook))
        actual = POC.canonical_json_bytes(POC.build_runtime_json(self.tables))
        self.assertEqual(manifest["expectedJsonSha256"], hashlib.sha256(actual).hexdigest())


if __name__ == "__main__":
    unittest.main()
