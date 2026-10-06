# Required Canonical and Supporting Sources

**Task:** `EMAS-MS04-IDENTIFICATION-RULES`

This task must follow the repository's authority hierarchy. Do not treat implementation code, fixtures, AI summaries, or older design documents as higher authority than the effective canonical requirements.

## A. Mandatory canonical repository sources

Read these before finalizing any identification rule design:

1. `docs/CANONICAL_DOCUMENT_INDEX.md`
2. `docs/governance/00_authority_and_precedence.md`
3. `docs/requirements/eMAS_Final_Enterprise_Requirements_v3.1.md`
4. `docs/configuration/01_eMAS_Mapping_Configuration_Functional_Requirements.md`
5. `docs/configuration/02_eMAS_Mapping_Configuration_Technical_Requirements.md`
6. `docs/configuration/03_eMAS_Mapping_Configuration_Content_Catalogue.md`
7. `docs/configuration/04_eMAS_Runtime_JSON_Contract.md`
8. `docs/configuration/05_eMAS_Normalized_Rule_Model.md`
9. `docs/configuration/06_eMAS_Normalized_Relationship_Matrix.md`
10. `docs/configuration/07_eMAS_Data_Dictionary.md`
11. `docs/architecture/phase-contracts/01_eMAS_PreSales_Assessment_Phase_Contract.md`
12. `docs/llm-development-context/ectd-regulatory-expert.md`

Authority note:

- Enterprise Requirements are rank 1.
- Mapping Functional Requirements are rank 2.
- Mapping Technical Requirements are rank 3.
- Content Catalogue is rank 4.
- Architecture and phase contracts are lower authority.
- LLM regulatory context is subordinate implementation guidance and cannot create new regulatory rules.
- Code and fixtures are evidence of implementation behavior, not regulatory authority.

If two sources conflict, follow `00_authority_and_precedence.md`: apply the higher-authority approved source, record the conflict, and do not silently reconcile it.

## B. Previously prepared eMAS reference artifacts

The following user-prepared artifacts are important supporting design inputs where available:

- `eMAS_Regulatory_Technical_Migration_Assessment_Guide_v2.0.docx`
- `eMAS_PreSalesMapping.json`
- `eMAS_Dossier_Classification_Mapping_v2.1_1386873065.xlsx`
- `eMAS_MS04_PreSales_Sample_Data_Catalogue_v1.1.xlsx`
- `eMAS-Requirement_Complete_Scenario_Matrix_v1.1_AdPromo.xlsx`

These artifacts may exist outside the Git repository.

Rules for using them:

1. If they are available in the local workspace, review them and list exactly which versions were used.
2. Treat them as project design/reference input unless the canonical repository explicitly assigns them higher authority.
3. They must not override the effective repository authority hierarchy above.
4. If one or more are unavailable, state that explicitly in the report rather than reconstructing their content from memory.
5. Do not upload internal/confidential binary mapping assets into the public repository merely to satisfy this task.
6. Where they contain regulatory claims, verify those claims against current official regulatory sources before turning them into normative identification rules.

## C. Current implementation evidence

After the canonical sources above, review the accepted current behavior:

- RepositoryDiscovery B3 reports and implementation;
- accepted eCTD v4 physical-discovery design/review/implementation reports;
- current `engine/powershell51/eMAS.RepositoryDiscovery.psm1`;
- current `engine/powershell51/eMAS.BackboneXmlInventory.psm1`;
- current `engine/powershell51/eMAS.ClassificationEvidenceCollection.psm1`;
- accepted Wave1 / Wave1D / Wave1E expectations.

These sources tell you what eMAS currently observes. They do not independently authorize new regulatory interpretation.

## D. Official regulatory sources

For any normative regulatory identification rule, use current official sources from the relevant authority or ICH.

Record:

- authority;
- title;
- version/date;
- exact section/page;
- rule derived;
- scope;
- whether the statement is a regulatory requirement or an eMAS design decision.

## E. Required report statement

The report must include a short "Source basis and precedence" section that clearly distinguishes:

1. canonical eMAS requirements;
2. previous eMAS design/mapping artifacts;
3. current implementation evidence;
4. official regulatory sources;
5. Claude analysis/design decisions.

No category may silently substitute for another.
