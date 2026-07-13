import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "build"))
import validate_emas_schema as MODULE  # noqa: E402


class SchemaFixtureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema_path = ROOT / "config" / "schema" / "eMAS-runtime-config.schema.json"
        cls.manifest_path = ROOT / "config" / "schema" / "examples" / "fixture-manifest.json"
        cls.schema = MODULE.load_json(cls.schema_path)
        cls.manifest = MODULE.load_json(cls.manifest_path)
        cls.registry = MODULE.build_schema_registry(cls.schema_path)

    def test_manifest_expectations(self):
        fixture_root = self.manifest_path.parent
        for item in self.manifest["fixtures"]:
            with self.subTest(path=item.get("path") or item.get("patch")):
                _, instance = MODULE.load_fixture_item(fixture_root, item)
                issues = MODULE.validate_instance(self.schema, instance, self.registry)
                self.assertEqual(
                    not issues,
                    bool(item["expectedValid"]),
                    [issue.render() for issue in issues],
                )
                actual_codes = {issue.code for issue in issues}
                self.assertTrue(
                    set(item.get("expectedErrorCodes", [])).issubset(actual_codes),
                    actual_codes,
                )

    def test_schema_declares_version_1_0_0(self):
        _, valid_fixture = MODULE.load_fixture_item(
            self.manifest_path.parent, self.manifest["fixtures"][0]
        )
        self.assertEqual(valid_fixture["configuration"]["schemaVersion"], "1.0.0")

    def test_warning_evaluation_status_is_accepted(self):
        item = next(
            fixture
            for fixture in self.manifest["fixtures"]
            if fixture.get("patch") == "valid/warning-evaluation-status-valid.patch.json"
        )
        _, instance = MODULE.load_fixture_item(self.manifest_path.parent, item)
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertEqual([], [issue.render() for issue in issues])

    def test_unknown_evaluation_status_value_is_rejected(self):
        item = next(
            fixture
            for fixture in self.manifest["fixtures"]
            if fixture.get("patch") == "invalid/structural-unknown-evaluation-status.patch.json"
        )
        _, instance = MODULE.load_fixture_item(self.manifest_path.parent, item)
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertIn("SCHEMA_ERROR", {issue.code for issue in issues})

    def test_unknown_evaluation_status_code_is_rejected(self):
        item = next(
            fixture
            for fixture in self.manifest["fixtures"]
            if fixture.get("patch") == "invalid/semantic-unknown-evaluation-status-code.patch.json"
        )
        _, instance = MODULE.load_fixture_item(self.manifest_path.parent, item)
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertIn("SEM_UNKNOWN_CODE", {issue.code for issue in issues})

    def test_fixture_files_are_utf8_without_bom(self):
        paths = set()
        for item in self.manifest["fixtures"]:
            for key in ("path", "base", "patch"):
                if key in item:
                    paths.add(item[key])
            paths.update(item.get("fragments", []))
        for relative_path in sorted(paths):
            with self.subTest(path=relative_path):
                payload = (self.manifest_path.parent / relative_path).read_bytes()
                self.assertFalse(payload.startswith(b"\xef\xbb\xbf"))
                json.loads(payload.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
