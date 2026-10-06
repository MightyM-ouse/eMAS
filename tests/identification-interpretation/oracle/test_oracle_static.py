import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import validate_oracle as ORACLE  # noqa: E402


class OracleStaticValidationTests(unittest.TestCase):
    def test_package_is_valid(self):
        self.assertEqual([], ORACLE.validate_package())

    def test_manifest_covers_all_mandatory_cases(self):
        manifest = ORACLE.load(HERE / "manifest.json")
        self.assertGreaterEqual(len(manifest["cases"]), 20)
        self.assertEqual(f"IDO-{len(manifest['cases']):02d}", manifest["cases"][-1]["id"])

    def _mutate(self, case_id, mutate, name="expected-identification.json"):
        original = ORACLE.ORACLE
        with tempfile.TemporaryDirectory() as tmp:
            copy_root = Path(tmp) / "oracle"
            shutil.copytree(HERE, copy_root, ignore=shutil.ignore_patterns("__pycache__"))
            path = copy_root / "cases" / case_id / name
            document = json.loads(path.read_text(encoding="utf-8"))
            mutate(document)
            path.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
            ORACLE.ORACLE = copy_root
            try:
                return ORACLE.validate_package()
            finally:
                ORACLE.ORACLE = original

    def assert_rejected(self, case_id, mutate, fragment, name="expected-identification.json"):
        errors = self._mutate(case_id, mutate, name)
        self.assertTrue(any(fragment in error for error in errors), errors)

    def test_rejects_outcome_and_support_status(self):
        self.assert_rejected("IDO-01", lambda d: d["Results"][0].update(Outcome="Value"), "Outcome")
        self.assert_rejected("IDO-01", lambda d: d["Results"][0].update(SupportStatus="Supported"), "SupportStatus")

    def test_rejects_numeric_score(self):
        self.assert_rejected("IDO-04", lambda d: d["Results"][0]["ScoreSummary"].update(NumericScore=100), "NumericScore")
        self.assert_rejected("IDO-04", lambda d: d["Results"][0]["Candidates"][0].update(Weight=1), "Weight")

    def test_rejects_unknown_cited_evidence(self):
        def mutate(d):
            d["Results"][0]["Candidates"][0]["SupportingEvidence"][0]["EvidenceId"] = "EVD-9999"
        self.assert_rejected("IDO-01", mutate, "does not exist in the scanner input")

    def test_rejects_rewritten_raw_strength(self):
        def mutate(d):
            d["Results"][0]["Candidates"][0]["SupportingEvidence"][0]["RawStrength"] = "Weak"
            d["Results"][0]["Candidates"][0]["SupportingEvidence"][0]["NormalizedStrength"] = "WEAK"
        self.assert_rejected("IDO-02", mutate, "immutable CEC record")

    def test_rejects_unknown_rule_and_wrong_dimension_candidate(self):
        self.assert_rejected("IDO-01", lambda d: d["Results"][0]["Candidates"][0].update(SupportingRuleIds=["ID-NOT-THERE"]), "not an IDENTIFICATION rule")
        self.assert_rejected("IDO-08", lambda d: d["Results"][1]["Candidates"][0].update(Value="ICH_ECTD_3_2_2"), "master data")

    def test_rejects_value_below_floor_and_strong_v4(self):
        def weak_value(d):
            r = d["Results"][0]
            r.update(EvaluationStatus="Evaluated", Value="ICH_ECTD_3_2_2", ValueSource="Derived", Confidence="LOW")
        self.assert_rejected("IDO-03", weak_value, "floor")

        def strong_v4(d):
            r = d["Results"][0]
            r["Candidates"][0]["BestSupportStrength"] = "STRONG"
            r["ScoreSummary"].update(BestStrength="STRONG", TierRank=1)
        self.assert_rejected("IDO-19", strong_v4, "physical v4")

    def test_rejects_nondeterministic_ordering(self):
        self.assert_rejected("IDO-04", lambda d: d["Results"][0]["Candidates"].reverse(), "ordered by support strength")
        self.assert_rejected("IDO-04", lambda d: d["Results"][0]["FiredRuleIds"].reverse(), "FiredRuleIds")
        self.assert_rejected("IDO-08", lambda d: d["Results"].reverse(), "sequential")

    def test_rejects_conflict_with_value(self):
        self.assert_rejected("IDO-06", lambda d: d["Results"][0].update(Value="ICH_ECTD_3_2_2", ValueSource="Derived"), "Identification/1.0 schema")


    def test_matches_pattern_case_exists_and_failure_case_is_stable(self):
        manifest = ORACLE.load(HERE / "manifest.json")
        by_id = {c["id"]: c for c in manifest["cases"]}
        self.assertEqual("Output", by_id["IDO-22"]["expectation"])
        self.assertEqual("Failure", by_id["IDO-23"]["expectation"])
        config = ORACLE.load(HERE / "cases" / "IDO-22" / "runtime-config.json")
        sensitivity = sorted(c["caseSensitive"] for c in ORACLE._pattern_conditions(config))
        self.assertEqual([False, True], sensitivity)
        failure = ORACLE.load(HERE / "cases" / "IDO-23" / "expected-failure.json")["ExpectedFailure"]
        self.assertEqual("IDI-CONFIG-005", failure["ErrorCode"])
        self.assertIsNone(failure["OutputDocument"])

    def test_rejects_unstable_failure_code_and_output_for_failure_case(self):
        self.assert_rejected("IDO-23", lambda d: d["ExpectedFailure"].update(ErrorCode="REGEX_BROKEN"), "stable contract code", "expected-failure.json")
        self.assert_rejected("IDO-23", lambda d: d["ExpectedFailure"].update(OutputDocument={}), "no output document", "expected-failure.json")

    def test_rejects_pattern_case_without_citation_change_detection(self):
        def mutate(d):
            d["Results"][0]["Candidates"][0]["SupportingRuleIds"] = ["ID-TS-NS-PATTERN-CS"]
            d["Results"][0]["FiredRuleIds"] = ["ID-TS-NS-PATTERN-CS"]
        self.assert_rejected("IDO-22", mutate, "does not output SUPPORTS")

    def test_every_central_decision_is_closed_in_the_contract(self):
        text = ORACLE.CONTRACT.read_text(encoding="utf-8")
        self.assertNotIn("[BLOCKER", text)
        for decision in sorted(ORACLE.CENTRAL_DECISIONS):
            self.assertIn(f"| {decision} |", text)


if __name__ == "__main__":
    unittest.main()
