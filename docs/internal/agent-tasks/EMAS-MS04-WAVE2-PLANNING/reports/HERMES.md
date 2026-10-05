**INDEPENDENT REVIEW REPORT: eMAS MS-04 Pre-Sales Classification Test Strategy (Adversarial Audit)**

**A. Executive assessment**  
The current Wave 1 baseline is stable for its narrow EU-centric, well-formed cases, but the proposed SD-021–SD-026 additions provide only marginal adversarial depth. They primarily stress folder-name robustness and basic multi-dossier/hierarchy isolation. They do **not** sufficiently stress the declared evidence hierarchy, the strict separation of the four dimensions (Region, TechnicalFormat, SpecificationProfile, DossierContext), conflict resolution rules, malformed/parse-failure cases, or cross-format/cross-region realities.  

Multiple incorrect implementations (over-reliance on paths, global state leakage, dimension conflation, premature invention of missing evidence, or EU overfitting) could still pass the entire proposed suite while violating the stated principles. The test corpus remains too synthetic, too EU-heavy, and too “happy-path-with-renames.” Regulatory discipline requires far broader, authoritative coverage before any FormatDetection or RegionDetection implementation begins. **The strategy is fragile against real regulatory variability.**

**B. What the proposed SD-021 to SD-026 set covers well**  
- Neutral and deliberately misleading root folder names (SD-021, SD-022) — forces implementations away from pure path heuristics.  
- Arbitrary wrapper hierarchies (SD-023) and multi-dossier under one repository root (SD-024) — tests basic scoping.  
- Presence of unrelated folders/documents (SD-025) and special-character naming (SD-026) — useful for filesystem realism and “do not invent evidence” checks.  
These catch the most obvious folder-name-over-XML mistakes and some isolation failures.

**C. Blind spots that remain**  
- No systematic conflict between *strong* StructuredXml signals from different sequences or dossiers.  
- No coverage of parse failures, malformed XML, or partial/incomplete structures.  
- No distinction between *absence* of evidence, *parse failure*, *unsupported format*, *conflicting evidence*, and *insufficient evidence*.  
- Almost zero authentic non-EU, non-eCTD-v2 structures.  
- Weak testing of Module 1 regional backbones vs. index.xml vs. DTD vs. folder heuristics when they disagree.  
- No stress on whether ASMF/DMF terminology leaks into TechnicalFormat or SpecificationProfile.  
- Insufficient wrapper-level *and* dossier-level contradictory naming.  
- No real multi-region corpus.  
- RepositoryDiscovery and ClassificationEvidenceCollection contracts are not adversarially exercised for global vs. per-DossierId state.

**D. Specific false-positive implementations that could still pass**  
- **Path-dominant cheat**: Always prefers `m1/eu` or `Module1RegionalFolder` presence for Region=EU and TechnicalFormat=eCTD, falling back to folder-name keywords (“ASMF”, “FDA”, “US”) for other dimensions. Passes all proposed renamed/misleading-name cases by ignoring or selectively using the misleading name; passes Wave 1 EU fixtures. Violates “folder names must not dominate structured regulatory evidence.”  
- **Index.xml singleton**: Treats any `index.xml` as proof of a single default (eCTD v2 EU) profile regardless of regional XML content, DTD version, or multiple sequences. Passes SD-021–SD-026 if they contain an index.xml. Directly violates question 2.  
- **Dimension conflation**: Maps any “ASMF” or “DMF” token (in path, XML, or dossier name) directly into TechnicalFormat or SpecificationProfile instead of keeping it in DossierContext. SD-022’s “FDA-US-ASMF” misleading name would be accepted as a format signal.  
- **Global evidence merger**: ClassificationEvidenceCollection aggregates all XML/paths across the entire repository without DossierId or dossier-root scoping. Passes SD-024 (two dossiers) if both are similar to baseline.

**E. Specific false-negative implementations that could still pass**  
- Overly rigid “strong XML only” rule that rejects any dossier whose strongest XML signal is in a non-first sequence or under a wrapper, even when lower-tier evidence is consistent. Could pass proposed tests if the synthetic fixtures keep the strongest signal easily discoverable in the expected location.  
- Implementation that treats *any* conflicting strong evidence as “insufficient” and refuses classification, but the proposed tests contain no conflicts, so it passes by never encountering the case.  
- One that silently drops malformed regional XML and invents defaults from index.xml or folder names — proposed tests have no malformed cases.

**F. Multi-dossier isolation risks**  
High. SD-024 tests two valid dossiers under one root but does not appear to include *conflicting* region/format signals between them, nor cases where RepositoryDiscovery assigns repository-global IDs that leak across dossier boundaries. EvidenceCollection could easily bleed strong XML signals or backbone declarations from one dossier into another if scoping is by repository rather than per-DossierId or per-dossier-root-path. Repository-global caches or ID schemes would exacerbate this. Real submissions frequently have multiple dossiers or prior sequences in the same tree.

**G. Evidence-precedence risks**  
The conceptual hierarchy (Strong StructuredXml → BackboneDeclaration → OfficialPhysicalPath → PackageStructure → FolderNameHeuristic) is sound in principle but untested under conflict. No fixtures force a strong XML signal from one sequence to contradict a strong XML signal from another, nor a strong XML vs. an OfficialPhysicalPath that implies a different region. The principles explicitly say conflicting evidence must *remain conflicting* until interpretation; the tests do not verify that an implementation cannot silently override or invent a winner. One strong signal incorrectly overriding another (question 5) is a clear gap. Malformed XML handling and “do not reconstruct” rule are untested.

**H. Required additional fixture categories before FormatDetection**  
- US eCTD v3, EU eCTD v3, eCTD v4, NeeS, unstructured/unknown exports, partial/incomplete dossiers.  
- Index.xml present + regional XML missing/malformed/unsupported.  
- Conflicting strong XML signals within the same dossier (different sequences).  
- Cases proving dimension independence (same technical structure, different regulatory context).  
- Format-specific backbone variations that index.xml alone cannot decide.

**I. Required additional fixture categories before RegionDetection**  
- Authentic Module 1 structures and regional backbones from at least EU, US, Canada, Australia, Switzerland, etc.  
- Module 1 folder present but XML/DTD indicates different or no region.  
- Regional XML in non-standard locations or under wrappers.  
- Cross-region dossiers in same repository with conflicting signals.

**J. Which fixtures can be synthetic transformations of the EU baseline**  
SD-021, SD-022, SD-023, SD-025, SD-026, plus wrapper-level contradictory naming, neutral vs. misleading at multiple levels, special characters, and added unrelated content. Any test whose validity depends only on name robustness, hierarchy tolerance, or isolation can be derived by renaming/wrapping the frozen Wave 1 EU fixtures.

**K. Which fixtures require independent real/reference structures**  
All format-specific and region-specific tests (US eCTD v3, eCTD v4, NeeS, real DMF/ASMF submissions, authentic regional Module 1 + backbone XML). Synthetic renaming is insufficient because real regulatory XML root elements, namespaces, DTD public/system identifiers, folder conventions, and sequence structures differ in non-trivial ways. Authoritative samples (or redacted reference submissions from regulatory agencies) are required. Do not invent them.

**L. Recommended minimum fixture matrix before coding FormatDetection**  
At minimum a 5 (formats: eCTD v2, v3 US, v3 EU, v4, NeeS) × 3 (regions) × 4 (evidence quality: clean, conflicting-strong, conflicting-weak, malformed/partial) × 2 (single vs multi-sequence) matrix, with additional neutral/misleading wrapper and multi-dossier variants. This yields ~200+ targeted cases. Include real samples for every major format/region combination. Wave 1 + proposed SD-021–SD-026 is <10% of this coverage.

**M. Open decisions that must be resolved before implementation**  
- Precise aggregation rule when sequences provide inconsistent region/version/format evidence (majority? strongest signal wins? fail closed? dossier-level vs sequence-level?).  
- Exact semantics when index.xml exists but regional XML is absent/malformed/contradictory.  
- Formal boundary between DossierContext (ASMF/DMF) and TechnicalFormat/SpecificationProfile — must not leak terminology.  
- Whether “Module 1 folder exists” is ever allowed to override or supplement structured XML for Region.  
- Definition of “sufficient evidence” thresholds per dimension and what happens on insufficient vs. conflicting.  
- RepositoryDiscovery contract for DossierId generation and isolation guarantees.  
- Policy on partial/incomplete dossiers and “do not reconstruct malformed XML.”  
These cannot be deferred to implementation time; they must be documented in the contract before any detection logic is written.

**N. Final verdict: NOT READY for FormatDetection design**  

The proposed fixture wave is a useful but inadequate incremental step. It does not close the adversarial gaps, does not provide the required cross-format/cross-region corpus, does not test conflict/malformed/insufficient cases rigorously, and leaves multiple incorrect heuristic implementations viable. Significant expansion with real regulatory reference structures, explicit conflict fixtures, evidence-quality differentiation, and resolution of the open decisions is required first.  

All review boundaries respected: read-only, no modifications, no code, no fixtures created, no commits, no pushes, no implementation of FormatDetection or RegionDetection. Review performed solely on the provided specification and review questions. Weaknesses were actively sought rather than minimized.