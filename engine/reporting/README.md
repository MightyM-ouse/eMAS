# Reporting/OpenXML MVP

`eMAS.ReportPopulation.psm1` provides the phase-neutral PowerShell command
`Export-eMASResultToTemplate`. It delegates package-level XLSX writes to the
generic standard-library helper `emas_report_openxml.py`.

This Python helper is an MVP report-population implementation used behind
the PowerShell command surface. It is not the final qualified production
OpenXML reporting engine.

The helper modifies only copied output workbooks, validates the authoritative
mapping schema, enforces template version 1.1.1, and checks structural
preservation after every generation. It intentionally blocks rows beyond a
mapping's pre-provisioned capacity because safe shifting of following tables,
validation ranges and conditional-formatting ranges is production work.
