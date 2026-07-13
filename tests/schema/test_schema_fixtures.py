import copy
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

    def load_patch_fixture(self, patch_path):
        item = next(
            fixture
            for fixture in self.manifest["fixtures"]
            if fixture.get("patch") == patch_path
        )
        return MODULE.load_fixture_item(self.manifest_path.parent, item)[1]

    def assert_fixture_is_valid(self, patch_path):
        instance = self.load_patch_fixture(patch_path)
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertEqual([], [issue.render() for issue in issues])
        return instance

    def assert_unknown_required_code_is_rejected(self, list_name, unknown_code):
        _, instance = MODULE.load_fixture_item(
            self.manifest_path.parent, self.manifest["fixtures"][0]
        )
        instance = copy.deepcopy(instance)
        unknown_row = copy.deepcopy(instance["valueLists"][list_name][0])
        unknown_row["code"] = unknown_code
        unknown_row["displayValue"] = unknown_code
        instance["valueLists"][list_name].append(unknown_row)
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        matching = [
            issue
            for issue in issues
            if issue.code == "SEM_UNKNOWN_CODE"
            and issue.path == f"$.valueLists.{list_name}"
            and unknown_code in issue.message
        ]
        self.assertTrue(matching, [issue.render() for issue in issues])

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
        self.assert_fixture_is_valid("valid/warning-evaluation-status-valid.patch.json")

    def test_mandatory_warning_code_missing_is_rejected(self):
        instance = self.load_patch_fixture(
            "invalid/semantic-missing-warning-code.patch.json"
        )
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        matching = [
            issue
            for issue in issues
            if issue.code == "SEM_REQUIRED_CODE"
            and issue.path == "$.valueLists.EVALUATION_STATUS"
            and "WARNING" in issue.message
        ]
        self.assertTrue(matching, [issue.render() for issue in issues])

    def test_warning_is_accepted_independently_of_rag(self):
        for patch_path, expected_rag in (
            ("valid/warning-evaluation-status-valid.patch.json", "Amber"),
            ("boundary/warning-rag-separation-valid.patch.json", "Unknown"),
        ):
            with self.subTest(rag=expected_rag):
                instance = self.assert_fixture_is_valid(patch_path)
                self.assertEqual(
                    ("Warning", expected_rag),
                    (
                        instance["rulePhases"][0]["evaluationStatusOnMissingInput"],
                        instance["rulePhases"][0]["rag"],
                    ),
                )

    def test_warning_with_unknown_rag_remains_valid(self):
        instance = self.assert_fixture_is_valid(
            "boundary/warning-rag-separation-valid.patch.json"
        )
        self.assertEqual("Unknown", instance["rulePhases"][0]["rag"])

    def test_warning_with_amber_rag_remains_valid(self):
        instance = self.assert_fixture_is_valid(
            "valid/warning-evaluation-status-valid.patch.json"
        )
        self.assertEqual("Amber", instance["rulePhases"][0]["rag"])

    def test_unknown_evaluation_status_value_is_rejected(self):
        instance = self.load_patch_fixture(
            "invalid/structural-unknown-evaluation-status.patch.json"
        )
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertIn("SCHEMA_ERROR", {issue.code for issue in issues})

    def test_unknown_evaluation_status_code_is_rejected(self):
        instance = self.load_patch_fixture(
            "invalid/semantic-unknown-evaluation-status-code.patch.json"
        )
        issues = MODULE.validate_instance(self.schema, instance, self.registry)
        self.assertIn("SEM_UNKNOWN_CODE", {issue.code for issue in issues})

    def test_unknown_phase_code_is_rejected(self):
        self.assert_unknown_required_code_is_rejected("PHASE", "FUTURE_PHASE")

    def test_unknown_rag_code_is_rejected(self):
        self.assert_unknown_required_code_is_rejected("RAG", "BLUE")

    def test_unknown_value_source_code_is_rejected(self):
        self.assert_unknown_required_code_is_rejected(
            "VALUE_SOURCE", "UNCONTROLLED_SOURCE"
        )

    def test_unknown_export_type_code_is_rejected(self):
        self.assert_unknown_required_code_is_rejected("EXPORT_TYPE", "DRAFT_RELEASE")

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
