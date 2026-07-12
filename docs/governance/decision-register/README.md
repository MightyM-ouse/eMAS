# eMAS Decision Register

This folder records the governance status of unresolved eMAS architecture, configuration, regulatory, implementation, documentation, testing and release topics.

## Current review baseline

A repository and evidence review completed on 12 July 2026 covered 155 existing decision items and identified 16 additional items, resulting in 171 tracked items.

The reviewed workbook remains an internal working artifact. It contains AI proposals and evidence, but the editable user-decision fields remain the approval authority. An AI recommendation must not be interpreted as an approved eMAS requirement.

See:

- [Review summary](eMAS_Decision_Register_Review_Summary_2026-07-12.md)
- [Open-question workflow](open-question-workflow.md)
- [Historical Version 2 documentation notice](../../archive/v2-documentation-pack/README.md)

## Decision boundary

Until an item is approved through the decision workflow:

- do not treat a proposal as a requirement;
- do not alter mapping content solely because an AI recommendation exists;
- do not hardcode an unresolved regulatory or business interpretation in PowerShell;
- do not change the runtime JSON contract based on an unresolved item;
- identify the applicable decision-register Item ID in proposed changes;
- stop and request a decision when the unresolved item affects runtime behavior, report meaning, regulatory interpretation, schema compatibility or release acceptance.

## Repository handling

This repository is public. Internal Word packs, reviewed decision workbooks, internal branding assets and other controlled files are therefore not committed here. Their existence and status are documented without publishing the binary artifacts.

When an approved internal storage location or private repository is available, the controlled workbook may be stored there together with its checksum, review record and version history.

## Next stage

Open questions will be discussed and approved one by one. Approved decisions will then be applied in dependency order to:

1. the enterprise and configuration requirements;
2. the architecture and runtime JSON contract;
3. the mapping workbook design and content catalogue;
4. LLM development context and operational skills;
5. PowerShell, VBA, templates and tests.
