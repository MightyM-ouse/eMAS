# Historical eMAS Version 2 Documentation Pack

The Version 2 Word documentation pack is retained outside this public repository as a historical traceability artifact. It is not the current implementation baseline.

## Historical files

- `00_eMAS_Documentation_Index_v2.docx`
- `01_eMAS_Vision_and_Business_Requirements_v2.docx`
- `02_eMAS_Software_Requirements_Specification_SRS_v2.docx`
- `03_eMAS_Solution_Architecture_Document_v2.docx`
- `04_eMAS_Mapping_Workbook_Design_Specification_v2.docx`
- `05_eMAS_Excel_Report_Design_Specification_v2.docx`
- `06_eMAS_PowerShell_Developer_Guide_v2.docx`
- `07_eMAS_Test_Strategy_and_Validation_Guide_v2.docx`
- `08_eMAS_User_and_Administrator_Guide_v2.docx`
- `README_eMAS_Documentation_Pack_v2.txt`

## Supersession status

The active product baseline is the repository's Enterprise Requirements v3.0 together with the approved architecture and repository documents.

The Version 2 pack contains concepts that must not be used for new implementation unless they are independently confirmed in the current baseline. Examples include:

- PowerShell reading the mapping workbook;
- runtime parameters such as `MappingWorkbookPath`;
- PowerShell converting workbook content into JSON;
- editable `IsActive` as the primary lifecycle control;
- a single flat `DossierType` dimension;
- treating `Not Assessed` as a RAG value;
- combining findings and recommendations;
- using one flat rule row for conditions, phase behavior and outputs.

## Use restrictions

The Version 2 files may be used only for:

- historical comparison;
- migration of still-valid requirements into current controlled documents;
- identification of obsolete statements;
- traceability during documentation cleanup.

They must not be used as direct coding instructions, runtime configuration requirements or regulatory-rule authority.

## Public-repository handling

The historical binaries contain internal classification, branding and traceability information. They are therefore not committed to this public repository. A controlled internal archive should retain the original files, checksum manifest, review record and supersession notice.
