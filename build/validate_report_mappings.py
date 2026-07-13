#!/usr/bin/env python3
"""Validate the three report template-map JSON files against
report-template-map.schema.json and against the actual finalized XLSX
templates they describe.

Checks performed per mapping file:
  - JSON parses
  - validates against config/report-mappings/report-template-map.schema.json
  - template.templateVersion matches the TemplateVersion recorded in the
    workbook's own Template Control table
  - requiredSheetOrder matches the workbook's actual worksheet order
  - every tableMapping/protectedTables sheetName+tableName exists in the workbook
  - every mapped targetColumn exists in that Excel Table, in the workbook
  - every actual Excel Table column is covered by the mapping (no gaps)
  - every actual Excel Table on every sheet is covered by exactly one
    tableMappings or protectedTables entry (no orphaned tables)
  - no duplicate targetColumn within one table's mapping

Requires the jsonschema package (pip install jsonschema). If unavailable,
schema validation is skipped with a clear warning and structural checks still run.

Usage: python3 build/validate_report_mappings.py [json ...]
"""
import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

M = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
R = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}'

SCHEMA_PATH = 'config/report-mappings/report-template-map.schema.json'
DEFAULT_MAPS = [
    'config/report-mappings/pre-sales.template-map.json',
    'config/report-mappings/pre-migration.template-map.json',
    'config/report-mappings/post-migration.template-map.json',
]

try:
    from jsonschema import Draft202012Validator
    HAVE_JSONSCHEMA = True
except ImportError:
    HAVE_JSONSCHEMA = False


def load_sst(z):
    sst = []
    if 'xl/sharedStrings.xml' in z.namelist():
        root = ET.fromstring(z.read('xl/sharedStrings.xml'))
        for si in root.findall(M + 'si'):
            sst.append(''.join(x.text or '' for x in si.iter(M + 't')))
    return sst


def cellval(c, sst):
    t = c.get('t')
    v = c.find(M + 'v')
    is_ = c.find(M + 'is')
    if t == 's' and v is not None:
        return sst[int(v.text)]
    if t == 'inlineStr' and is_ is not None:
        return ''.join(x.text or '' for x in is_.iter(M + 't'))
    if v is not None:
        return v.text
    return None


def load_workbook(path):
    z = zipfile.ZipFile(path)
    sst = load_sst(z)
    wb = ET.fromstring(z.read('xl/workbook.xml'))
    rels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
    relmap = {r.get('Id'): r.get('Target') for r in rels}
    sheets = {}
    sheet_xml = {}
    for s in wb.findall(M + 'sheets/' + M + 'sheet'):
        name = s.get('name')
        rid = s.get(R + 'id')
        tgt = relmap[rid]
        tgt = ('xl/' + tgt) if not tgt.startswith('/') else tgt.lstrip('/')
        sh = ET.fromstring(z.read(tgt))
        sheet_xml[name] = sh
        relpath = tgt.replace('worksheets/', 'worksheets/_rels/') + '.rels'
        tables = {}
        if relpath in z.namelist():
            srels = ET.fromstring(z.read(relpath))
            for rel in srels:
                if 'table' in rel.get('Type'):
                    tpath = 'xl/tables/' + rel.get('Target').split('/')[-1]
                    t = ET.fromstring(z.read(tpath))
                    cols = [c.get('name') for c in t.findall(M + 'tableColumns/' + M + 'tableColumn')]
                    tables[t.get('name')] = cols
        sheets[name] = tables
    return sheets, sheet_xml, sst


def find_template_control_version(sheet_xml, sst):
    for name, sh in sheet_xml.items():
        rowcells = {}
        for row in sh.iter(M + 'row'):
            for c in row.iter(M + 'c'):
                rowcells[c.get('r')] = c
        for ref, c in rowcells.items():
            if cellval(c, sst) == 'TemplateVersion':
                m = re.match(r'([A-Z]+)(\d+)', ref)
                if m.group(1) == 'A':
                    bref = f"B{m.group(2)}"
                    if bref in rowcells:
                        val = cellval(rowcells[bref], sst)
                        if val and re.match(r'^\d+\.\d+\.\d+$', val):
                            return val
    return None


def validate_mapping(map_path, schema):
    errors = []
    warnings = []
    m = json.load(open(map_path))

    if schema is not None:
        v = Draft202012Validator(schema)
        for e in v.iter_errors(m):
            errors.append(f"schema: {'.'.join(str(p) for p in e.path)}: {e.message}")
    else:
        warnings.append("jsonschema package not available; schema validation skipped")

    xlsx_path = m['template']['templateFilePath']
    if not Path(xlsx_path).exists():
        errors.append(f"templateFilePath does not exist: {xlsx_path}")
        return errors, warnings

    sheets, sheet_xml, sst = load_workbook(xlsx_path)

    actual_order = list(sheets.keys())
    if m['requiredSheetOrder'] != actual_order:
        errors.append(f"requiredSheetOrder mismatch: mapping={m['requiredSheetOrder']} actual={actual_order}")

    actual_version = find_template_control_version(sheet_xml, sst)
    if actual_version and actual_version != m['template']['templateVersion']:
        errors.append(f"templateVersion mismatch: mapping={m['template']['templateVersion']!r} workbook Template Control={actual_version!r}")

    all_tables_referenced = set()

    for tm in m['tableMappings']:
        sn, tn = tm['sheetName'], tm['tableName']
        if sn not in sheets:
            errors.append(f"tableMapping references unknown sheet {sn!r}")
            continue
        if tn not in sheets[sn]:
            errors.append(f"tableMapping references table {tn!r} not found on sheet {sn!r} (tables on that sheet: {list(sheets[sn])})")
            continue
        all_tables_referenced.add(tn)
        actual_cols = set(sheets[sn][tn])
        mapped_cols = [c['targetColumn'] for c in tm['columns']]
        dupes = {c for c in mapped_cols if mapped_cols.count(c) > 1}
        if dupes:
            errors.append(f"table {tn}: duplicate targetColumn mapping(s) {dupes}")
        unknown = set(mapped_cols) - actual_cols
        if unknown:
            errors.append(f"table {tn}: mapped column(s) not present in actual table {unknown}")
        missing = actual_cols - set(mapped_cols)
        if missing:
            errors.append(f"table {tn}: actual table column(s) NOT covered by mapping {missing}")
        if tm['writeMode'] == 'matchRowByLabelColumns':
            for lc in tm.get('labelColumns', []):
                if lc not in actual_cols:
                    errors.append(f"table {tn}: labelColumn {lc!r} not an actual column")

    for pt in m.get('protectedTables', []):
        sn, tn = pt['sheetName'], pt['tableName']
        if sn not in sheets or tn not in sheets.get(sn, {}):
            errors.append(f"protectedTables entry references unknown sheet/table {sn}/{tn}")
        all_tables_referenced.add(tn)

    for sn, tables in sheets.items():
        for tn in tables:
            if tn not in all_tables_referenced:
                errors.append(f"actual table {tn} on sheet {sn} is not covered by any tableMapping or protectedTables entry")

    for dc in m.get('directCellMappings', []):
        if dc['sheetName'] not in sheets:
            errors.append(f"directCellMapping references unknown sheet {dc['sheetName']!r}")

    return errors, warnings


def main(paths):
    schema = None
    if HAVE_JSONSCHEMA and Path(SCHEMA_PATH).exists():
        schema = json.load(open(SCHEMA_PATH))
        Draft202012Validator.check_schema(schema)

    all_ok = True
    for path in paths:
        print(f"\n{'=' * 90}\n{path}\n{'=' * 90}")
        errors, warnings = validate_mapping(path, schema)
        for w in warnings:
            print(f"  [warn] {w}")
        for e in errors:
            print(f"  [FAIL] {e}")
        status = "PASS" if not errors else "FAIL"
        print(f"  ---> {status}")
        all_ok = all_ok and not errors
    print()
    print("OVERALL:", "PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    paths = args or DEFAULT_MAPS
    sys.exit(main(paths))
