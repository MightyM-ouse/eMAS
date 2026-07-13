import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "build"))

import validate_operational_skills as skills_validator  # noqa: E402


class OperationalSkillTests(unittest.TestCase):
    def test_repository_skill_contracts(self):
        self.assertEqual([], skills_validator.validate_repository())

    def test_catalog_contains_seven_effective_skills(self):
        catalog = skills_validator.load_catalog()
        self.assertEqual("1.0.0", catalog["catalogVersion"])
        self.assertEqual("Effective", catalog["status"])
        self.assertEqual(7, len(catalog["skills"]))
        self.assertTrue(all(item["status"] == "Effective" for item in catalog["skills"]))

    def test_catalog_is_utf8_json_without_bom(self):
        payload = skills_validator.CATALOG_PATH.read_bytes()
        self.assertFalse(payload.startswith(b"\xef\xbb\xbf"))
        parsed = json.loads(payload.decode("utf-8"))
        self.assertIn("skills", parsed)


if __name__ == "__main__":
    unittest.main()
