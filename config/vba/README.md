# VBA Source

Exported workbook VBA is stored here so that configuration logic can be reviewed in Git.

```text
vba/
├── modules/   Standard `.bas` modules
├── classes/   `.cls` class modules
└── forms/     `.frm` forms and related files
```

The approved workbook build process should import the reviewed source. Binary XLSM changes should be accompanied by corresponding exported VBA changes and a clear change summary.
