# eCTD Regulatory Classification Context

**Status:** Effective implementation guidance; new controlled content requires Regulatory SME approval  
**Authority:** Subordinate to approved configuration requirements, controlled value lists and the content catalogue

This file provides normalized regulatory-classification context for eMAS mapping and configuration work. It does not independently approve new regulatory rules.

## Classification dimensions

eMAS classifies independent dimensions rather than one flat dossier type:

- Region;
- Authority;
- TechnicalStandard;
- RegionalImplementation;
- ProductDomain;
- LifecycleContext;
- ProductClass;
- ProcedureContext where applicable;
- SourcePresentation where applicable.

A display-level primary dossier type may be derived for reporting, but it is not the authoring master dimension.

## Regions and groupings

Current catalogue examples include EU, US, Canada, UK, Switzerland, GCC, MENA, LATAM, EAEU, RestOfEurope, Other and Unknown.

Important controls:

- EU, US, Canada, UK, Switzerland, GCC and EAEU may represent specific regional implementation contexts when linked to approved authorities and standards.
- MENA, LATAM and RestOfEurope are broad internal groupings, not individual regulatory authorities.
- A broad grouping must not determine a country-specific folder structure or authority rule without a more specific approved relationship.

## Authorities

Current catalogue examples include EMA, FDA, HealthCanada, MHRA, Swissmedic, GCCDR, EEC, Other and Unknown.

Authority values must be maintained through controlled master data and link tables. New authorities or renamed authorities require source evidence and Regulatory SME approval.

## TechnicalStandard

Examples include:

- ICH eCTD 3.2.2;
- eCTD 4.0;
- NeeS;
- VNeeS;
- Non-eCTD Electronic;
- Other;
- Unknown.

A technical standard describes the submission packaging or exchange standard. It must not be confused with a regional implementation, regulatory procedure or source presentation.

## RegionalImplementation

Regional implementations are layered on a technical standard. Examples include:

- EU eCTD Module 1;
- US FDA Module 1;
- Canada Module 1;
- UK Module 1;
- Switzerland Module 1;
- GCC Module 1;
- EAEU Module 1.

Regional implementations are not mutually exclusive alternatives to the underlying TechnicalStandard.

## ProcedureContext

ASMF is governed as a regulatory procedure or dossier context, not a TechnicalStandard. Its technical standard and regional implementation are classified independently.

Medical-device technical-file context must be placed in the approved ProductDomain, ProductClass, ProcedureContext or SourcePresentation dimensions according to the approved content model. It must not automatically be treated as a technical submission standard.

## SourcePresentation

`Paper/Scanned` is governed as SourcePresentation when it describes how source material is packaged or supplied. It is not automatically a regulatory technical standard.

## Product dimensions

Current normalized examples include:

- **ProductDomain:** Human, Veterinary, MedicalDevice, Other, Unknown;
- **LifecycleContext:** Investigational, PostMarketing, Other, Unknown;
- **ProductClass:** SmallMolecule, Biologic, Vaccine, BloodProduct, Other, Unknown.

Exact controlled values remain governed by the approved content catalogue and value lists.

## Master-data relationships

Relationships are stored in dedicated link tables, including where applicable:

- Authority-to-Region;
- Authority-to-TechnicalStandard;
- Authority-to-RegionalImplementation;
- TechnicalStandard-to-Region;
- TechnicalStandard-to-RegionalImplementation;
- ProductDomain-to-TechnicalStandard;
- ProductDomain-to-Region;
- LifecycleContext-to-TechnicalStandard;
- ProductClass-to-TechnicalStandard;
- ProcedureContext-to-Region or authority where approved.

Every relationship must use stable identifiers and pass referential-integrity validation.

## Evidence and conflict rules

- Prefer structured XML, namespace and approved metadata evidence over path-name hints.
- Path or title text alone is weak evidence unless an approved rule says otherwise.
- When strong indicators conflict, return the configured conflict or insufficient-evidence outcome rather than silently selecting a region or standard.
- Conflict resolution must use the approved configuration strategy, not row order or developer preference.
- Record evidence source, rule ID, evaluation status and confidence separately.

## SME boundary

New or changed regulatory content remains Draft until the required Regulatory SME review is recorded.

Stop and request review when:

- an authority, region, standard or procedure is absent from approved master data;
- official evidence is unavailable or contradictory;
- a proposed relationship changes regulatory interpretation;
- folder or mandatory-file expectations are inferred from a broad regional grouping;
- an example is being promoted into controlled mapping content.
