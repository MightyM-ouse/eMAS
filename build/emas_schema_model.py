"""Shared models and constants for independent eMAS schema validation."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

@dataclass(frozen=True)
class ValidationIssue:
    code: str
    path: str
    message: str

    def render(self) -> str:
        return f'{self.code} {self.path}: {self.message}'
REQUIRED_VALUE_LISTS = {'DOCUMENT_STATUS', 'RULE_LIFECYCLE_STATUS', 'PHASE', 'MIGRATION_SCENARIO', 'DATA_TYPE', 'OPERATOR', 'LOGICAL_OPERATOR', 'CONFLICT_STRATEGY', 'EVIDENCE_STRENGTH', 'EVALUATION_STATUS', 'RAG', 'SEVERITY', 'CONFIDENCE', 'VALUE_SOURCE', 'REQUIREMENT_LEVEL', 'EFFORT_BAND', 'EXCEPTION_EFFECT', 'LINK_TYPE', 'RULE_TYPE', 'OUTPUT_TYPE', 'FINDING_CATEGORY', 'UNIT', 'RELATIONSHIP_TYPE', 'EXPORT_TYPE'}
REQUIRED_CODES = {'PHASE': {'PRE_SALES', 'PRE_MIGRATION', 'POST_MIGRATION'}, 'RAG': {'GREEN', 'AMBER', 'RED', 'UNKNOWN'}, 'EVALUATION_STATUS': {'EVALUATED', 'NOTASSESSED', 'NOTAPPLICABLE', 'SKIPPED', 'ERROR', 'INSUFFICIENTEVIDENCE', 'CONFLICT'}, 'VALUE_SOURCE': {'OBSERVED', 'CUSTOMERPROVIDED', 'IMPORTED', 'DERIVED', 'ASSUMED'}, 'EXPORT_TYPE': {'DEV', 'CONTROLLED'}}
MASTER_ENTITY_MAP = {'REGION': ('regions', 'regionCode'), 'AUTHORITY': ('authorities', 'authorityCode'), 'TECHNICAL_STANDARD': ('technicalStandards', 'technicalStandardCode'), 'REGIONAL_IMPLEMENTATION': ('regionalImplementations', 'regionalImplementationCode'), 'PRODUCT_DOMAIN': ('productDomains', 'productDomainCode'), 'LIFECYCLE_CONTEXT': ('lifecycleContexts', 'lifecycleContextCode'), 'PRODUCT_CLASS': ('productClasses', 'productClassCode'), 'PROCEDURE_CONTEXT': ('procedureContexts', 'procedureContextCode'), 'SOURCE_PRESENTATION': ('sourcePresentations', 'sourcePresentationCode')}
RELATIONSHIP_ENDPOINTS = {'AUTHORITY_TO_REGION': ('AUTHORITY', 'REGION'), 'AUTHORITY_TO_TECHNICAL_STANDARD': ('AUTHORITY', 'TECHNICAL_STANDARD'), 'AUTHORITY_TO_REGIONAL_IMPLEMENTATION': ('AUTHORITY', 'REGIONAL_IMPLEMENTATION'), 'TECHNICAL_STANDARD_TO_REGION': ('TECHNICAL_STANDARD', 'REGION'), 'TECHNICAL_STANDARD_TO_REGIONAL_IMPLEMENTATION': ('TECHNICAL_STANDARD', 'REGIONAL_IMPLEMENTATION'), 'PRODUCT_DOMAIN_TO_TECHNICAL_STANDARD': ('PRODUCT_DOMAIN', 'TECHNICAL_STANDARD'), 'PRODUCT_DOMAIN_TO_REGION': ('PRODUCT_DOMAIN', 'REGION'), 'LIFECYCLE_CONTEXT_TO_TECHNICAL_STANDARD': ('LIFECYCLE_CONTEXT', 'TECHNICAL_STANDARD'), 'PRODUCT_CLASS_TO_TECHNICAL_STANDARD': ('PRODUCT_CLASS', 'TECHNICAL_STANDARD'), 'PROCEDURE_CONTEXT_TO_TECHNICAL_STANDARD': ('PROCEDURE_CONTEXT', 'TECHNICAL_STANDARD'), 'PROCEDURE_CONTEXT_TO_REGIONAL_IMPLEMENTATION': ('PROCEDURE_CONTEXT', 'REGIONAL_IMPLEMENTATION'), 'SOURCE_PRESENTATION_TO_TECHNICAL_STANDARD': ('SOURCE_PRESENTATION', 'TECHNICAL_STANDARD'), 'RULE_SUPERSESSION': ('RULE', 'RULE')}
COLLECTION_KEYS = {'fieldCatalogue': 'fieldCode', 'metricCatalogue': 'metricCode', 'relationships': 'relationshipId', 'rules': 'ruleId', 'rulePhases': 'rulePhaseId', 'conditionGroups': 'conditionGroupId', 'ruleConditions': 'conditionId', 'ruleOutputs': 'ruleOutputId', 'findings': 'findingCode', 'recommendations': 'recommendationCode', 'findingRecommendationLinks': 'linkId', 'exceptionPolicies': 'exceptionPolicyId', 'aliases': 'aliasId', 'questionnaireMap': 'questionnaireMapId'}
POLICY_KEYS = {'conflictPolicies': 'conflictPolicyId', 'ragPolicies': 'ragPolicyId', 'confidencePolicies': 'confidencePolicyId', 'effortDrivers': 'effortDriverId', 'effortThresholds': 'effortThresholdId', 'decisionPolicies': 'decisionPolicyId'}

def _json_path(parts: Iterable[Any]) -> str:
    text = '$'
    for part in parts:
        if isinstance(part, int):
            text += f'[{part}]'
        else:
            text += f'.{part}'
    return text

def _index(items: list[dict[str, Any]], key: str) -> dict[str, dict[str, Any]]:
    return {str(item[key]): item for item in items if key in item}

def _codes(value_lists: dict[str, list[dict[str, Any]]], name: str) -> set[str]:
    return {str(item.get('code')) for item in value_lists.get(name, [])}

