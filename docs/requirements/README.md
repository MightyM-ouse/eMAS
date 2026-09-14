# eMAS Requirements

## Current branch baseline

Use [eMAS Enterprise Requirements v5.0](eMAS_Enterprise_Requirements_v5.0.md) as the product-scope baseline for this branch.

For the immediate implementation, use [Mapping Workbook and Scenario JSON MVP Requirements v4.5](../configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md). The MVP priority is:

1. capture all configurable migration-script requirements in one understandable master workbook; and
2. generate deterministic Runtime JSON for a selected migration scenario.

SharePoint integration, Office Script deployment, Power Automate workflow, formal release governance, and GxP-oriented controls are later stages and do not block the MVP proof.

## Historical and supporting baselines

Enterprise Requirements v3.0 and v3.1 are retained for traceability. Older configuration documents remain useful design references, but XLSM/VBA, WPF, governance, or non-scenario-specific JSON provisions do not override the current MVP baseline where they conflict.

Use the [v5.0 Previous Baseline Carry-Forward Register](eMAS_v5.0_Previous_Baseline_Carry_Forward.md) to decide whether older detailed requirements are retained, adapted, deferred, or superseded.

## Delivery-state boundary

A requirement baseline is not evidence that the workbook, JSON transformer, PowerShell consumer, regulatory content, tests, or production controls have been implemented or approved.
