"""Cross-collection semantic validation for eMAS Runtime JSON 1.0.0."""
from __future__ import annotations

import math
from typing import Any

from emas_schema_model import (
    COLLECTION_KEYS, MASTER_ENTITY_MAP, POLICY_KEYS, RELATIONSHIP_ENDPOINTS,
    REQUIRED_CODES, REQUIRED_VALUE_LISTS, ValidationIssue, _codes, _index,
)

def _semantic_issues(instance: dict[str, Any]) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []

    def add(code: str, path: str, message: str) -> None:
        issues.append(ValidationIssue(code, path, message))
    configuration = instance['configuration']
    if configuration.get('schemaVersion') != '1.0.0':
        add('SEM_SCHEMA_VERSION', '$.configuration.schemaVersion', 'must equal 1.0.0')
    value_lists = instance['valueLists']
    missing_lists = sorted(REQUIRED_VALUE_LISTS - set(value_lists))
    for name in missing_lists:
        add('SEM_REQUIRED_VALUE_LIST', f'$.valueLists.{name}', 'mandatory list is missing')
    for name, rows in value_lists.items():
        seen: set[str] = set()
        for i, row in enumerate(rows):
            code = str(row.get('code'))
            if code in seen:
                add('SEM_DUPLICATE_ID', f'$.valueLists.{name}[{i}].code', f'duplicate code {code}')
            seen.add(code)
    for name, expected in REQUIRED_CODES.items():
        missing_codes = sorted(expected - _codes(value_lists, name))
        for code in missing_codes:
            add('SEM_REQUIRED_CODE', f'$.valueLists.{name}', f'mandatory code {code} is missing')
    for collection, key in COLLECTION_KEYS.items():
        seen: set[str] = set()
        for i, row in enumerate(instance[collection]):
            value = str(row.get(key))
            if value in seen:
                add('SEM_DUPLICATE_ID', f'$.{collection}[{i}].{key}', f'duplicate {key} {value}')
            seen.add(value)
    for collection, key in POLICY_KEYS.items():
        seen: set[str] = set()
        for i, row in enumerate(instance['policies'][collection]):
            value = str(row.get(key))
            if value in seen:
                add('SEM_DUPLICATE_ID', f'$.policies.{collection}[{i}].{key}', f'duplicate {key} {value}')
            seen.add(value)
    composite_checks = [('rulePhases', ('ruleId', 'phase')), ('findingRecommendationLinks', ('findingCode', 'recommendationCode', 'phase', 'linkType'))]
    for collection, keys in composite_checks:
        seen: set[tuple[Any, ...]] = set()
        for i, row in enumerate(instance[collection]):
            value = tuple((row.get(k) for k in keys))
            if value in seen:
                add('SEM_DUPLICATE_COMPOSITE', f'$.{collection}[{i}]', f'duplicate composite key {keys}: {value}')
            seen.add(value)
    master_indexes: dict[str, dict[str, dict[str, Any]]] = {}
    for entity_type, (collection, key) in MASTER_ENTITY_MAP.items():
        rows = instance['masterData'][collection]
        seen: set[str] = set()
        for i, row in enumerate(rows):
            code = str(row.get(key))
            if code in seen:
                add('SEM_DUPLICATE_ID', f'$.masterData.{collection}[{i}].{key}', f'duplicate code {code}')
            seen.add(code)
        master_indexes[entity_type] = _index(rows, key)
    rules = _index(instance['rules'], 'ruleId')
    fields = _index(instance['fieldCatalogue'], 'fieldCode')
    metrics = _index(instance['metricCatalogue'], 'metricCode')
    groups = _index(instance['conditionGroups'], 'conditionGroupId')
    findings = _index(instance['findings'], 'findingCode')
    recommendations = _index(instance['recommendations'], 'recommendationCode')
    questionnaires_by_code = _index(instance['questionnaireMap'], 'questionCode')
    confidence_policies = _index(instance['policies']['confidencePolicies'], 'confidencePolicyId')
    effort_drivers_by_id = _index(instance['policies']['effortDrivers'], 'effortDriverId')
    effort_drivers_by_code = _index(instance['policies']['effortDrivers'], 'driverCode')

    def walk_temporal(value: Any, path: str) -> None:
        if isinstance(value, dict):
            start = value.get('effectiveFrom')
            end = value.get('effectiveTo')
            if start and end and (end <= start):
                add('SEM_TEMPORAL_RANGE', path, 'effectiveTo must be later than effectiveFrom')
            for key, child in value.items():
                walk_temporal(child, f'{path}.{key}')
        elif isinstance(value, list):
            for i, child in enumerate(value):
                walk_temporal(child, f'{path}[{i}]')
    walk_temporal(instance, '$')
    relationship_pairs: set[tuple[str, str, str]] = set()
    supersession_edges: dict[str, str] = {}
    for i, rel in enumerate(instance['relationships']):
        path = f'$.relationships[{i}]'
        rel_type = rel['relationshipType']
        expected = RELATIONSHIP_ENDPOINTS.get(rel_type)
        actual = (rel['sourceEntityType'], rel['targetEntityType'])
        if expected is None or actual != expected:
            add('SEM_RELATIONSHIP_ENDPOINT', path, f'{rel_type} requires endpoint types {expected}, received {actual}')
            continue
        for side in ('source', 'target'):
            entity_type = rel[f'{side}EntityType']
            code = rel[f'{side}EntityCode']
            if entity_type == 'RULE':
                exists = code in rules
            else:
                exists = code in master_indexes.get(entity_type, {})
            if not exists:
                add('SEM_BROKEN_REFERENCE', f'{path}.{side}EntityCode', f'{entity_type} code {code} does not exist')
        pair = (rel_type, rel['sourceEntityCode'], rel['targetEntityCode'])
        if pair in relationship_pairs:
            add('SEM_DUPLICATE_COMPOSITE', path, f'duplicate relationship endpoint pair {pair}')
        relationship_pairs.add(pair)
        if rel_type == 'RULE_SUPERSESSION':
            source = rel['sourceEntityCode']
            target = rel['targetEntityCode']
            if source == target:
                add('SEM_SUPERSESSION_CYCLE', path, 'a rule cannot supersede itself')
            supersession_edges[source] = target
    for start in supersession_edges:
        visited: set[str] = set()
        current = start
        while current in supersession_edges:
            if current in visited:
                add('SEM_SUPERSESSION_CYCLE', '$.relationships', f'supersession cycle includes {current}')
                break
            visited.add(current)
            current = supersession_edges[current]
    phases_by_rule: dict[str, set[str]] = {rule_id: set() for rule_id in rules}
    for i, row in enumerate(instance['rulePhases']):
        path = f'$.rulePhases[{i}]'
        rule_id = row['ruleId']
        if rule_id not in rules:
            add('SEM_BROKEN_REFERENCE', f'{path}.ruleId', f'rule {rule_id} does not exist')
        else:
            phases_by_rule[rule_id].add(row['phase'])
    groups_by_rule: dict[str, list[str]] = {rule_id: [] for rule_id in rules}
    for i, group in enumerate(instance['conditionGroups']):
        path = f'$.conditionGroups[{i}]'
        rule_id = group['ruleId']
        if rule_id not in rules:
            add('SEM_BROKEN_REFERENCE', f'{path}.ruleId', f'rule {rule_id} does not exist')
        else:
            groups_by_rule[rule_id].append(group['conditionGroupId'])
    conditions_by_group: dict[str, int] = {group_id: 0 for group_id in groups}
    for i, condition in enumerate(instance['ruleConditions']):
        path = f'$.ruleConditions[{i}]'
        rule_id = condition['ruleId']
        group_id = condition['conditionGroupId']
        field_code = condition['fieldCode']
        if rule_id not in rules:
            add('SEM_BROKEN_REFERENCE', f'{path}.ruleId', f'rule {rule_id} does not exist')
        if group_id not in groups:
            add('SEM_BROKEN_REFERENCE', f'{path}.conditionGroupId', f'group {group_id} does not exist')
        else:
            conditions_by_group[group_id] += 1
            if groups[group_id]['ruleId'] != rule_id:
                add('SEM_CONDITION_RULE_MISMATCH', path, 'condition RuleId differs from its condition-group RuleId')
        field = fields.get(field_code)
        if field is None:
            add('SEM_BROKEN_REFERENCE', f'{path}.fieldCode', f'field {field_code} does not exist')
        else:
            if condition['operator'] not in field['allowedOperators']:
                add('SEM_OPERATOR_NOT_ALLOWED', f'{path}.operator', f"operator {condition['operator']} is not allowed for {field_code}")
            rule_phases = phases_by_rule.get(rule_id, set())
            unsupported = sorted(rule_phases - set(field['supportedPhases']))
            if unsupported:
                add('SEM_FIELD_PHASE', f'{path}.fieldCode', f'field does not support rule phases {unsupported}')
    for group_id, count in conditions_by_group.items():
        if count == 0:
            add('SEM_RULE_INCOMPLETE', '$.conditionGroups', f'condition group {group_id} has no conditions')
    outputs_by_rule: dict[str, int] = {rule_id: 0 for rule_id in rules}
    all_master_codes = {code for index in master_indexes.values() for code in index}
    rag_codes = _codes(value_lists, 'RAG')
    all_controlled_codes = {code for rows in value_lists.values() for code in (str(row.get('code')) for row in rows)}
    for i, output in enumerate(instance['ruleOutputs']):
        path = f'$.ruleOutputs[{i}]'
        rule_id = output['ruleId']
        if rule_id not in rules:
            add('SEM_BROKEN_REFERENCE', f'{path}.ruleId', f'rule {rule_id} does not exist')
            continue
        outputs_by_rule[rule_id] += 1
        if output['phase'] not in phases_by_rule.get(rule_id, set()):
            add('SEM_OUTPUT_PHASE', f'{path}.phase', 'output phase is not assigned to the rule')
        output_type = output['outputType']
        code = output['outputCode']
        valid_target = True
        if output_type == 'Finding':
            valid_target = code in findings
        elif output_type == 'RAG':
            valid_target = code in rag_codes
        elif output_type == 'ClassificationCandidate':
            valid_target = code in all_master_codes
        elif output_type == 'ConfidenceImpact':
            valid_target = code in confidence_policies or code in all_controlled_codes
        elif output_type == 'EffortImpact':
            valid_target = code in effort_drivers_by_code or code in all_controlled_codes
        elif output_type == 'DecisionImpact':
            valid_target = code in all_controlled_codes
        elif output_type == 'ClarificationTrigger':
            valid_target = code in questionnaires_by_code
        if not valid_target:
            add('SEM_OUTPUT_TARGET', f'{path}.outputCode', f'{output_type} target {code} does not resolve')
    for rule_id, rule in rules.items():
        if not phases_by_rule.get(rule_id):
            add('SEM_RULE_INCOMPLETE', '$.rules', f'rule {rule_id} has no phase assignment')
        if not groups_by_rule.get(rule_id):
            add('SEM_RULE_INCOMPLETE', '$.rules', f'rule {rule_id} has no condition group')
        if not outputs_by_rule.get(rule_id):
            add('SEM_RULE_INCOMPLETE', '$.rules', f'rule {rule_id} has no output')
        finding_code = rule.get('findingCode')
        if finding_code and finding_code not in findings:
            add('SEM_BROKEN_REFERENCE', '$.rules', f'rule {rule_id} references missing finding {finding_code}')
    for i, link in enumerate(instance['findingRecommendationLinks']):
        path = f'$.findingRecommendationLinks[{i}]'
        if link['findingCode'] not in findings:
            add('SEM_BROKEN_REFERENCE', f'{path}.findingCode', 'finding does not exist')
        if link['recommendationCode'] not in recommendations:
            add('SEM_BROKEN_REFERENCE', f'{path}.recommendationCode', 'recommendation does not exist')
        condition_ref = link.get('applicabilityConditionReference')
        if condition_ref and condition_ref not in groups and (condition_ref not in fields):
            add('SEM_BROKEN_REFERENCE', f'{path}.applicabilityConditionReference', 'condition reference does not resolve')
    for i, policy in enumerate(instance['exceptionPolicies']):
        path = f'$.exceptionPolicies[{i}]'
        finding = findings.get(policy['eligibleFindingCode'])
        if finding is None:
            add('SEM_BROKEN_REFERENCE', f'{path}.eligibleFindingCode', 'finding does not exist')
        elif not finding['exceptionEligible']:
            add('SEM_EXCEPTION_INELIGIBLE', f'{path}.eligibleFindingCode', 'finding is not exception eligible')
    alias_targets: dict[str, set[str]] = {entity: set(index) for entity, index in master_indexes.items()}
    alias_targets['FIELD'] = set(fields)
    alias_targets['VALUE_LIST'] = all_controlled_codes
    for i, alias in enumerate(instance['aliases']):
        path = f'$.aliases[{i}]'
        entity_type = alias['canonicalEntityType']
        if alias['canonicalCode'] not in alias_targets.get(entity_type, set()):
            add('SEM_ALIAS_TARGET', f'{path}.canonicalCode', f"target {entity_type}/{alias['canonicalCode']} does not resolve")
    for i, driver in enumerate(instance['policies']['effortDrivers']):
        metric_code = driver.get('metricCode')
        if metric_code and metric_code not in metrics:
            add('SEM_BROKEN_REFERENCE', f'$.policies.effortDrivers[{i}].metricCode', f'metric {metric_code} does not exist')
    threshold_groups: dict[tuple[str, str, str], list[tuple[int, dict[str, Any]]]] = {}
    for i, threshold in enumerate(instance['policies']['effortThresholds']):
        path = f'$.policies.effortThresholds[{i}]'
        scope_type = threshold['thresholdScopeType']
        scope_code = threshold['thresholdScopeCode']
        if scope_type == 'DRIVER' and scope_code not in effort_drivers_by_code:
            add('SEM_BROKEN_REFERENCE', f'{path}.thresholdScopeCode', f'effort driver {scope_code} does not exist')
        lower = threshold.get('lowerBound')
        upper = threshold.get('upperBound')
        if lower is not None and upper is not None and (lower >= upper):
            add('SEM_THRESHOLD_RANGE', path, 'lowerBound must be less than upperBound')
        threshold_groups.setdefault((scope_type, scope_code, threshold['unit']), []).append((i, threshold))
    for key, rows in threshold_groups.items():
        rows.sort(key=lambda item: -math.inf if item[1].get('lowerBound') is None else item[1]['lowerBound'])
        for (prev_i, prev), (curr_i, curr) in zip(rows, rows[1:]):
            prev_upper = prev.get('upperBound')
            curr_lower = curr.get('lowerBound')
            if prev_upper is None:
                add('SEM_THRESHOLD_OVERLAP', f'$.policies.effortThresholds[{curr_i}]', f'previous band for {key} is open-ended')
                continue
            if curr_lower is None or curr_lower < prev_upper or (curr_lower == prev_upper and prev.get('upperInclusive') and curr.get('lowerInclusive')):
                add('SEM_THRESHOLD_OVERLAP', f'$.policies.effortThresholds[{curr_i}]', f'band overlaps the previous band for {key}')
            elif curr_lower > prev_upper or (curr_lower == prev_upper and (not prev.get('upperInclusive')) and (not curr.get('lowerInclusive'))):
                add('SEM_THRESHOLD_GAP', f'$.policies.effortThresholds[{curr_i}]', f'gap exists after the previous band for {key}')
    phase_result_codes = {phase_name: {row['code'] for row in instance['reportTerminology']['phaseResults'][phase_name]} for phase_name in ('PRE_SALES', 'PRE_MIGRATION', 'POST_MIGRATION')}
    for i, policy in enumerate(instance['policies']['decisionPolicies']):
        path = f'$.policies.decisionPolicies[{i}]'
        if policy['resultCode'] not in phase_result_codes[policy['phase']]:
            add('SEM_DECISION_RESULT', f'{path}.resultCode', 'result code is not valid for the selected phase')
        reference = policy['requiredConditionReference']
        if policy['requiredConditionType'] == 'CONDITION_GROUP' and reference not in groups:
            add('SEM_BROKEN_REFERENCE', f'{path}.requiredConditionReference', 'condition group does not exist')
        if policy['requiredConditionType'] == 'DERIVED_FIELD' and reference not in fields:
            add('SEM_BROKEN_REFERENCE', f'{path}.requiredConditionReference', 'derived field does not exist')
    for i, entry in enumerate(instance['questionnaireMap']):
        path = f'$.questionnaireMap[{i}]'
        if entry['triggerType'] == 'FIELD' and entry['triggerCode'] not in fields:
            add('SEM_BROKEN_REFERENCE', f'{path}.triggerCode', 'field trigger does not exist')
        if entry['triggerType'] == 'FINDING' and entry['triggerCode'] not in findings:
            add('SEM_BROKEN_REFERENCE', f'{path}.triggerCode', 'finding trigger does not exist')
    report_seen: set[tuple[str, str, str]] = set()
    for i, definition in enumerate(instance['reportTerminology']['definitions']):
        key = (definition['reportCode'], definition['sheetCode'], definition['columnCode'])
        if key in report_seen:
            add('SEM_DUPLICATE_COMPOSITE', f'$.reportTerminology.definitions[{i}]', f'duplicate report definition {key}')
        report_seen.add(key)
    return issues

