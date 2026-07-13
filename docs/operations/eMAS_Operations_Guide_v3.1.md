# eMAS Operations Guide

**Version:** 3.1  
**Status:** Approved

## 1. Customer Pre-Sales package

The package contains only:

- `eMAS-PreSalesAssessment.ps1` or approved merged build;
- required engine files;
- `eMAS_Runtime_Config.json`;
- `eMAS_PreSales_Template.xlsx`;
- `Start-eMAS-PreSales.cmd`;
- customer instructions;
- Output folder.

It excludes the XLSM authoring workbook, VBA source, internal tests, Pre-Migration/Post-Migration interfaces and internal governance.

## 2. Internal execution

Pre-Migration and Post-Migration may run by CLI or WPF. WPF invokes the same scripts.

Operators confirm:

- approved package and manifest;
- configuration checksum;
- source access;
- output location;
- project exception file where applicable;
- template compatibility.

## 3. Evidence handling

Store report, log, input manifest, configuration hash, template version, exception evidence and reviewer outcome together in the project evidence location.

## 4. Report lifecycle

Draft → Reviewed. Reviewed does not mean electronically signed, validated or formally accepted.

## 5. Troubleshooting

Configuration errors stop execution. Optional missing evidence produces explicit NotAssessed/Unknown results. Access and technical failures are logged with the approved taxonomy.

## 6. Public-repository boundary

Never commit customer source data, reports, logs, project exceptions, credentials, internal branding assets or controlled runtime packages to the public repository.
