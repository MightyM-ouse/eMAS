import copy
import json
import sys
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "build"))
import validate_emas_schema as MODULE  # noqa: E402
import emas_schema_model as MODEL  # noqa: E402

BASE_1_0 = [
    "base/01-configuration-and-value-lists.json",
    "base/02-catalogue-and-master-data.json",
    "base/03-rules-and-outputs.json",
    "base/04-policies-and-reporting.json",
]
BASE_1_1 = BASE_1_0 + ["base/05-identification-1.1.json"]


class IdentificationSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema_path = ROOT / "config" / "schema" / "eMAS-runtime-config.schema.json"
        cls.manifest_path = ROOT / "config" / "schema" / "examples" / "fixture-manifest.json"
        cls.schema = MODULE.load_json(cls.schema_path)
        cls.manifest = MODULE.load_json(cls.manifest_path)
        cls.registry = MODULE.build_schema_registry(cls.schema_path)

    def build(self, fragments, patch=None):
        item = {"fragments": fragments}
        if patch:
            item["patch"] = patch
        return copy.deepcopy(MODULE.load_fixture_item(self.manifest_path.parent, item)[1])

    def issues(self, instance):
        return MODULE.validate_instance(self.schema, instance, self.registry)

    def assert_valid(self, instance):
        self.assertEqual([], [issue.render() for issue in self.issues(instance)])

    def assert_issue(self, instance, code, path=None):
        issues = self.issues(instance)
        matching = [i for i in issues if i.code == code and (path is None or i.path == path)]
        self.assertTrue(matching, [i.render() for i in issues])
        return issues

    def identification_output(self, instance):
        return next(o for o in instance["ruleOutputs"] if o["ruleId"] == "ID-TS-001")

    # Version dispatch and 1.0.0 compatibility

    def test_supported_versions_are_exactly_1_0_0_and_1_1_0(self):
        catalog = MODULE.load_json(ROOT / "config" / "schema" / "defs" / "catalog.schema.json")
        self.assertEqual(["1.0.0", "1.1.0"], catalog["$defs"]["configuration"]["properties"]["schemaVersion"]["enum"])
        self.assertEqual(("1.0.0", "1.1.0"), MODEL.SUPPORTED_SCHEMA_VERSIONS)

    def test_all_original_1_0_0_fixtures_keep_their_expectations(self):
        original = [f for f in self.manifest["fixtures"] if f["fragments"] == BASE_1_0 and not str(f.get("patch", "")).startswith("invalid/version-")]
        self.assertEqual(16, len(original))
        for item in original:
            with self.subTest(patch=item.get("patch")):
                _, instance = MODULE.load_fixture_item(self.manifest_path.parent, item)
                self.assertIn(instance.get("configuration", {}).get("schemaVersion", "1.0.0"), ("1.0.0",))
                issues = self.issues(instance)
                self.assertEqual(bool(item["expectedValid"]), not issues)
                self.assertTrue(set(item.get("expectedErrorCodes", [])) <= {i.code for i in issues})

    def test_every_1_1_property_is_rejected_by_json_schema_alone_when_labelled_1_0_0(self):
        """Proof that 1.1-only executable fields cannot silently validate as 1.0.0, without the semantic layer."""
        validator = Draft202012Validator(self.schema, registry=self.registry)
        base = self.build(BASE_1_0)
        cases = {
            "fieldCatalogue": lambda d: d["fieldCatalogue"][0].update(maxEvidenceStrength="STRONG"),
            "targetEntityType": lambda d: d["ruleOutputs"][1].update(targetEntityType="REGION"),
            "evidenceStrength": lambda d: d["ruleOutputs"][1].update(evidenceStrength="STRONG"),
            "evidencePolarity": lambda d: d["ruleOutputs"][1].update(evidencePolarity="SUPPORTS"),
            "minimumEvidenceStrengthForValue": lambda d: d["policies"]["conflictPolicies"][0].update(minimumEvidenceStrengthForValue="MEDIUM"),
            "resultConfidence": lambda d: d["policies"]["confidencePolicies"][0].update(resultConfidence="HIGH"),
            "corroborationRule": lambda d: d["policies"]["confidencePolicies"][0].update(corroborationRule="NONE_REQUIRED"),
        }
        self.assertEqual([], list(validator.iter_errors(base)))
        for name, mutate in cases.items():
            with self.subTest(property=name):
                instance = copy.deepcopy(base)
                mutate(instance)
                errors = list(validator.iter_errors(instance))
                self.assertTrue(errors)
                self.assertEqual({"SCHEMA_VERSION_FEATURE"}, {MODULE._schema_issue_code(e) for e in errors})
                instance["configuration"]["schemaVersion"] = "1.1.0"
                self.assertFalse([e for e in validator.iter_errors(instance) if MODULE._schema_issue_code(e) == "SCHEMA_VERSION_FEATURE"])

    def test_powershell_loader_contract_supports_the_same_versions(self):
        contract = (ROOT / "engine" / "core" / "eMAS.Configuration.Contract.psm1").read_text(encoding="utf-8")
        self.assertIn("SupportedSchemaVersions = @('1.0.0', '1.1.0')", contract)
        self.assertIn("SchemaVersionAdapters = @{}", contract)
        for properties in MODEL.VERSION_1_1_PROPERTIES.values():
            for name in properties:
                with self.subTest(property=name):
                    self.assertIn(f"'{name}'", contract)

    def test_identification_rule_type_requires_1_1_0(self):
        instance = self.build(BASE_1_0, "invalid/version-identification-rule-labelled-1.0.0.patch.json")
        self.assert_issue(instance, "SEM_VERSION_FEATURE", "$.rules")

    def test_1_0_0_still_requires_numeric_confidence_weight(self):
        instance = self.build(BASE_1_0, "invalid/version-1.0.0-confidence-weight-missing.patch.json")
        self.assertEqual({"SCHEMA_ERROR"}, {i.code for i in self.issues(instance)})

    def test_1_1_0_keeps_numeric_weight_mandatory_outside_identification_scope(self):
        instance = self.build(BASE_1_1)
        del instance["policies"]["confidencePolicies"][0]["weightOrScore"]
        self.assert_issue(instance, "SCHEMA_ERROR")

    def test_unsupported_schema_version_fails_fast(self):
        for version in ("1.2.0", "2.0.0", "1.0"):
            with self.subTest(version=version):
                instance = self.build(BASE_1_1)
                instance["configuration"]["schemaVersion"] = version
                self.assertEqual({"SCHEMA_UNSUPPORTED_VERSION"}, {i.code for i in self.issues(instance)})

    # Controlled codes and ordinal order

    def test_canonical_identification_code_lists(self):
        self.assertEqual({"STRONG", "MEDIUM", "WEAK"}, MODEL.REQUIRED_CODES_1_1["EVIDENCE_STRENGTH"])
        self.assertEqual({"HIGH", "MEDIUM", "LOW", "UNKNOWN"}, MODEL.REQUIRED_CODES_1_1["CONFIDENCE"])
        self.assertEqual({"SUPPORTS", "CONTRADICTS"}, MODEL.REQUIRED_CODES_1_1["EVIDENCE_POLARITY"])
        self.assertEqual({"UNKNOWN", "MANUAL_REVIEW"}, MODEL.REQUIRED_CODES_1_1["TIE_BEHAVIOR"])
        self.assertEqual({"NONE_REQUIRED", "INDEPENDENT_SOURCE_CLASS"}, MODEL.REQUIRED_CODES_1_1["CORROBORATION_RULE"])
        self.assertNotIn("EVIDENCE_STRENGTH", MODEL.REQUIRED_CODES)
        self.assertNotIn("CONFIDENCE", MODEL.REQUIRED_CODES)

    def test_evidence_strength_sort_order_is_preserved_and_required(self):
        instance = self.build(BASE_1_1)
        rows = instance["valueLists"]["EVIDENCE_STRENGTH"]
        self.assertEqual(["STRONG", "MEDIUM", "WEAK"], [r["code"] for r in sorted(rows, key=lambda r: r["sortOrder"])])
        del rows[1]["sortOrder"]
        self.assert_issue(instance, "SEM_ORDINAL_ORDER", "$.valueLists.EVIDENCE_STRENGTH")

    def test_rule_type_identification_must_be_governed(self):
        instance = self.build(BASE_1_1)
        instance["valueLists"]["RULE_TYPE"] = [r for r in instance["valueLists"]["RULE_TYPE"] if r["code"] != "IDENTIFICATION"]
        self.assert_issue(instance, "SEM_CONTROLLED_REFERENCE", "$.rules[1].ruleType")
        self.assert_issue(instance, "SEM_CONTROLLED_REFERENCE", "$.policies.conflictPolicies[1].ruleType")

    def test_controlled_reference_paths_are_stable(self):
        cases = {
            "invalid/identification-unknown-evidence-strength-1.1.patch.json": "$.ruleOutputs[2].evidenceStrength",
            "invalid/identification-unknown-evidence-polarity-1.1.patch.json": "$.ruleOutputs[2].evidencePolarity",
            "invalid/identification-unknown-tie-behavior-1.1.patch.json": "$.policies.conflictPolicies[1].tieBehavior",
            "invalid/identification-unknown-result-confidence-1.1.patch.json": "$.policies.confidencePolicies[1].resultConfidence",
            "invalid/identification-unknown-corroboration-rule-1.1.patch.json": "$.policies.confidencePolicies[1].corroborationRule",
        }
        for patch, path in cases.items():
            with self.subTest(patch=patch):
                issues = self.assert_issue(self.build(BASE_1_1, patch), "SEM_CONTROLLED_REFERENCE", path)
                self.assertEqual(1, len(issues), [i.render() for i in issues])

    def test_confidence_policy_evidence_strength_is_controlled_for_identification_scope(self):
        instance = self.build(BASE_1_1, "valid/identification-weightless-confidence-1.1.patch.json")
        instance["policies"]["confidencePolicies"][1]["evidenceStrength"] = "HIGH"
        self.assert_issue(instance, "SEM_CONTROLLED_REFERENCE", "$.policies.confidencePolicies[1].evidenceStrength")

    def test_minimum_evidence_strength_for_value_is_controlled(self):
        instance = self.build(BASE_1_1, "valid/identification-weightless-confidence-1.1.patch.json")
        instance["policies"]["conflictPolicies"][1]["minimumEvidenceStrengthForValue"] = "SUPPORTING"
        self.assert_issue(instance, "SEM_CONTROLLED_REFERENCE", "$.policies.conflictPolicies[1].minimumEvidenceStrengthForValue")

    def test_weightless_identification_confidence_is_valid_and_carries_no_number(self):
        instance = self.build(BASE_1_1, "valid/identification-weightless-confidence-1.1.patch.json")
        self.assert_valid(instance)
        rows = [p for p in instance["policies"]["confidencePolicies"] if p["scope"] == "IDENTIFICATION"]
        self.assertTrue(rows)
        self.assertTrue(all("weightOrScore" not in p for p in rows))

    # Dimension-scoped candidate resolution

    def test_candidate_resolves_only_within_declared_dimension(self):
        instance = self.build(BASE_1_1, "invalid/identification-candidate-outside-dimension-1.1.patch.json")
        # EU_MODULE1 exists globally (REGIONAL_IMPLEMENTATION) but not in the declared TECHNICAL_STANDARD dimension.
        self.assertIn("EU_MODULE1", {r["regionalImplementationCode"] for r in instance["masterData"]["regionalImplementations"]})
        self.assert_issue(instance, "SEM_OUTPUT_TARGET", "$.ruleOutputs[2].outputCode")

    def test_no_global_cross_dimension_code_uniqueness(self):
        self.assert_valid(self.build(BASE_1_1, "valid/identification-same-code-two-dimensions-1.1.patch.json"))
        instance = self.build(BASE_1_1)
        for entity_type, (collection, key) in MODEL.MASTER_ENTITY_MAP.items():
            row = copy.deepcopy(instance["masterData"][collection][0])
            row[key] = "UNKNOWN"
            instance["masterData"][collection].append(row)
        self.assert_valid(instance)
        source = (ROOT / "build" / "emas_schema_semantics.py").read_text(encoding="utf-8")
        self.assertNotIn("CROSS_DIMENSION", source)

    def test_non_identification_classification_candidate_keeps_1_0_0_resolution(self):
        instance = self.build(BASE_1_1)
        legacy = next(o for o in instance["ruleOutputs"] if o["ruleId"] == "RULE-001" and o["outputType"] == "ClassificationCandidate")
        self.assertEqual("EU", legacy["outputCode"])
        self.assert_valid(instance)
        legacy["outputCode"] = "NOT_IN_ANY_DIMENSION"
        self.assert_issue(instance, "SEM_OUTPUT_TARGET")

    def test_dimension_mismatch_and_unapproved_dimension(self):
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-dimension-mismatch-1.1.patch.json"), "SEM_IDENTIFICATION_DIMENSION_MISMATCH", "$.ruleOutputs[2].targetEntityType")
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-unapproved-dimension-1.1.patch.json"), "SEM_IDENTIFICATION_DIMENSION", "$.rules[1].conflictGroup")
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-dimension-not-canonical-1.1.patch.json"), "SEM_UNKNOWN_CODE", "$.valueLists.IDENTIFICATION_DIMENSION")

    def test_conflict_group_is_required_for_identification_rules(self):
        instance = self.build(BASE_1_1)
        del next(r for r in instance["rules"] if r["ruleId"] == "ID-TS-001")["conflictGroup"]
        self.assert_issue(instance, "SEM_IDENTIFICATION_METADATA_REQUIRED", "$.rules[1].conflictGroup")

    # Evidence-strength ceiling

    def test_strong_candidate_from_medium_or_weak_capped_field_is_rejected(self):
        for ceiling in ("MEDIUM", "WEAK"):
            with self.subTest(ceiling=ceiling):
                instance = self.build(BASE_1_1)
                next(f for f in instance["fieldCatalogue"] if f["fieldCode"] == "CEC_XML_ROOT_ELEMENT_COMMON")["maxEvidenceStrength"] = ceiling
                issues = self.assert_issue(instance, "SEM_EVIDENCE_STRENGTH_CEILING", "$.ruleOutputs[2].evidenceStrength")
                self.assertEqual(1, len(issues))

    def test_ceiling_uses_weakest_positive_field_across_or_groups(self):
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-weak-field-mixed-group-1.1.patch.json"), "SEM_EVIDENCE_STRENGTH_CEILING")

    def test_negated_guard_condition_does_not_cap_strength(self):
        self.assert_valid(self.build(BASE_1_1, "boundary/identification-strength-equals-ceiling-1.1.patch.json"))

    def test_ceiling_applies_to_contradicting_candidates(self):
        instance = self.build(BASE_1_1, "boundary/identification-contradicting-medium-1.1.patch.json")
        self.assert_valid(instance)
        self.identification_output(instance)["evidenceStrength"] = "STRONG"
        self.assert_issue(instance, "SEM_EVIDENCE_STRENGTH_CEILING")

    def test_identification_field_without_ceiling_is_rejected(self):
        instance = self.build(BASE_1_1)
        del next(f for f in instance["fieldCatalogue"] if f["fieldCode"] == "CEC_XML_ROOT_ELEMENT_COMMON")["maxEvidenceStrength"]
        self.assert_issue(instance, "SEM_IDENTIFICATION_METADATA_REQUIRED", "$.fieldCatalogue")

    def test_ceiling_guard_does_not_change_fixture_evidence(self):
        instance = self.build(BASE_1_1)
        before = json.dumps(instance, sort_keys=True)
        self.issues(instance)
        self.assertEqual(before, json.dumps(instance, sort_keys=True))

    # No numeric Identification weights / rejected result fields

    def test_numeric_identification_weights_are_rejected(self):
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-numeric-weight-1.1.patch.json"), "SEM_IDENTIFICATION_NUMERIC_WEIGHT", "$.policies.confidencePolicies[1].weightOrScore")
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-candidate-output-value-1.1.patch.json"), "SEM_IDENTIFICATION_NUMERIC_WEIGHT", "$.ruleOutputs[2].outputValue")

    def test_identification_fixtures_carry_no_numeric_identification_weight(self):
        for item in self.manifest["fixtures"]:
            if item["fragments"] != BASE_1_1 or not item["expectedValid"]:
                continue
            with self.subTest(patch=item.get("patch")):
                _, instance = MODULE.load_fixture_item(self.manifest_path.parent, item)
                id_rules = {r["ruleId"] for r in instance["rules"] if r["ruleType"] == "IDENTIFICATION"}
                self.assertFalse([o for o in instance["ruleOutputs"] if o["ruleId"] in id_rules and "outputValue" in o])
                self.assertFalse([p for p in instance["policies"]["confidencePolicies"] if p["scope"] == "IDENTIFICATION" and "weightOrScore" in p])

    def test_rejected_result_fields_are_not_schema_properties(self):
        text = "".join(p.read_text(encoding="utf-8") for p in (ROOT / "config" / "schema").rglob("*.schema.json"))
        for name in ('"Outcome"', '"outcome"', '"SupportStatus"', '"supportStatus"'):
            self.assertNotIn(name, text)

    def test_metadata_scope_and_required_metadata(self):
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-metadata-missing-1.1.patch.json"), "SEM_IDENTIFICATION_METADATA_REQUIRED", "$.ruleOutputs[2].evidencePolarity")
        self.assert_issue(self.build(BASE_1_1, "invalid/identification-metadata-out-of-scope-1.1.patch.json"), "SEM_IDENTIFICATION_METADATA_SCOPE", "$.ruleOutputs[0]")


if __name__ == "__main__":
    unittest.main()
