# eMAS Canonical Document Index

**Version:** 1.0  
**Status:** Effective  
**Decision references:** DEC-2026-008, DEC-2026-096 through DEC-2026-116

| Rank | Area | Canonical artifact | Version | Status | Owner | Supersedes |
|---:|---|---|---|---|---|---|
| 1 | Enterprise requirements | `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md` | 3.1 | Effective | Product Owner | v3.0 |
| 2 | Software requirements | `docs/requirements/eMAS_Software_Requirements_Specification_v3.1.md` | 3.1 | Approved | Product Owner | Version 2 SRS |
| 3 | Mapping functional requirements | `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements_v3.1.md` | 3.1 | Approved | Product Owner | v2.0 draft |
| 4 | Mapping technical requirements | `docs/configuration/02_eMAS_Mapping_Configuration_Technical_Requirements_v3.1.md` | 3.1 | Approved | Technical Architect | v2.0 draft |
| 5 | Mapping content catalogue | `docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue_v3.1.md` | 3.1 | Approved | Product Owner | v2.0 draft |
| 6 | Runtime schema | `schemas/eMAS-runtime-config.schema.json` | 1.0.0 | Approved | Technical Architect | prose indicative structures |
| 7 | Architecture | `docs/architecture/eMAS_Solution_Architecture_v3.1.md` | 3.1 | Approved | Technical Architect | fragmented architecture notes |
| 8 | Project flow | `docs/architecture/eMAS_Project_Flow.md` | 1.0 | Approved view | Product Owner | none |
| 9 | Report design | `docs/reporting/eMAS_Report_Design_Specification_v3.1.md` | 3.1 | Approved | Product Owner | Version 2 report specification |
| 10 | Development guide | `docs/development/eMAS_PowerShell_Developer_Guide_v3.1.md` | 3.1 | Approved | PowerShell Lead | Version 2 developer guide |
| 11 | Test strategy | `docs/testing/eMAS_Test_Strategy_v3.1.md` | 3.1 | Approved | QA Lead | Version 2 test guide |
| 12 | Operations | `docs/operations/eMAS_Operations_Guide_v3.1.md` | 3.1 | Approved | Operations Owner | Version 2 user/admin guide |
| 13 | Decision log | `docs/governance/eMAS_Decision_Log.md` | 1.0 | Effective | Product Owner | reviewed decision register proposals |
| 14 | Terminology | `docs/governance/eMAS_Terminology.md` | 1.0 | Effective | Documentation Owner | distributed glossary variants |
| 15 | LLM context | `docs/llm-development-context/README.md` and `context-index.yaml` | 1.0 | Approved guidance | Documentation Owner | earlier short context |
| 16 | Operational skills | `docs/llm-development-context/skills/` | 1.0 | Approved guidance | Area owners | none |

## Rules

- Markdown in Git is canonical.
- Word, PDF and Confluence outputs are generated views and must state their source path and version.
- The internal XLSM remains the authoring source for business and regulatory rule content.
- The reviewed runtime JSON remains the runtime source.
- Historical Version 2 Word documents are superseded and retained outside the public repository.
