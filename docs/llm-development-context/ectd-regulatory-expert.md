# eCTD Regulatory Expert Context

This file provides regulatory knowledge relevant to eMAS mapping and configuration.

## Regions (from eMAS Content Catalogue)
Active regions include: EU, US, Canada, UK, Switzerland, GCC, MENA, LATAM, EAEU, RestOfEurope, Other, Unknown.

## Authorities
Active authorities include: EMA, FDA, HealthCanada, MHRA, Swissmedic, GCCDR, EEC, Other, Unknown.

## Formats
Supported formats include:
- ICH_eCTD_3_2_2, eCTD_4_0
- Regional: EU_eCTD, US_FDA_eCTD, Canada_eCTD, UK_eCTD, Swiss_eCTD, GCC_eCTD, EAEU_eCTD
- Legacy/Alternative: NeeS, VNeeS, ASMF_Related, Medical_Device_Technical_File, Non_eCTD_Electronic, Paper_Scanned
- Other / Unknown

## Dossier Classification Dimensions
- Product_Domains: Human, Veterinary, MedicalDevice, Other, Unknown
- Lifecycle_Contexts: Investigational, PostMarketing, Other, Unknown
- Product_Classes: SmallMolecule, Biologic, Vaccine, BloodProduct, Other, Unknown

## Master Data Relationships (Critical for Mapping)
Relationships are stored in dedicated link tables:
- Authority-to-Region
- Authority-to-Format
- Format-to-Region
- ProductDomain-to-Format
- ProductDomain-to-Region
- LifecycleContext-to-Format
- ProductClass-to-Format

## Rules for Mapping / Configuration
- Use normalized dimensions instead of single "Dossier Type" field where possible.
- Maintain referential integrity between Region, Authority, and Format.
- Regional format variations (e.g. EU_eCTD vs US_FDA_eCTD) must be respected in classification and folder rules.
- Legacy formats (NeeS, VNeeS, Paper_Scanned) require special handling in readiness and reconciliation logic.