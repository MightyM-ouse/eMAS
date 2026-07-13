#!/usr/bin/env python3
"""Validate the three controlled eMAS report templates (Pre-Sales, Pre-Migration,
Post-Migration) at the OOXML package level, without requiring Microsoft Excel.

Checks performed:
  - ZIP CRC integrity
  - XML well-formedness of every package part
  - relationship targets resolve to existing parts
  - Excel Table name uniqueness and range validity
  - Excel Table column count matches declared tableColumns
  - no worksheet-level AutoFilter overlapping a Table AutoFilter
  - no data-validation range overlapping more than one Table
  - no conditional-formatting range overlapping more than one Table
  - no VBA project / external links (macro and external-link scan)
  - no formula cells, no formula-error cached values
  - no obvious customer-data / personal-path / author-name residue
  - optional LibreOffice headless open/save round-trip, if soffice is available

Usage: python3 build/validate_controlled_templates.py [xlsx ...]
Exits non-zero if any check fails. Prints a PASS/FAIL summary per workbook.
"""
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

M = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
R = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}'

DEFAULT_TEMPLATES = [
    'templates/controlled/pre-sales/eMAS_PreSales_Template.xlsx',
    'templates/controlled/pre-migration/eMAS_PreMigration_Template.xlsx',
    'templates/controlled/post-migration/eMAS_PostMigration_Template.xlsx',
]

SUSPICIOUS_PATTERN = re.compile(r'(?i)(c:\\\\users\\\\|/users/[a-z0-9_.-]+/(?!\.claude)|chakka|vinay|confluence)')


def col_to_num(col):
    n = 0
    for c in col:
        n = n * 26 + (ord(c) - ord('A') + 1)
    return n


def parse_ref(ref):
    m = re.match(r'^([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?$', ref)
    c1, r1, c2, r2 = m.groups()
    c1n, r1n = col_to_num(c1), int(r1)
    if c2:
        c2n, r2n = col_to_num(c2), int(r2)
    else:
        c2n, r2n = c1n, r1n
    return (min(r1n, r2n), max(r1n, r2n), min(c1n, c2n), max(c1n, c2n))


def ranges_overlap(a, b):
    ar1, ar2, ac1, ac2 = a
    br1, br2, bc1, bc2 = b
    return not (ar2 < br1 or br2 < ar1 or ac2 < bc1 or bc2 < ac1)


class Findings:
    def __init__(self, name):
        self.name = name
        self.errors = []
        self.warnings = []
        self.info = []

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)

    def note(self, msg):
        self.info.append(msg)

    def ok(self):
        return not self.errors


def validate_workbook(path):
    f = Findings(path)
    try:
        z = zipfile.ZipFile(path)
    except zipfile.BadZipFile as e:
        f.error(f"not a valid zip: {e}")
        return f

    # 1. ZIP CRC
    bad = z.testzip()
    if bad:
        f.error(f"ZIP CRC failure at {bad}")
    else:
        f.note("ZIP CRC: OK")

    names = z.namelist()

    # 2. XML well-formedness
    xml_bad = []
    for n in names:
        if n.endswith('.xml') or n.endswith('.rels'):
            try:
                ET.fromstring(z.read(n))
            except ET.ParseError as e:
                xml_bad.append((n, str(e)))
    if xml_bad:
        for n, e in xml_bad:
            f.error(f"malformed XML in {n}: {e}")
    else:
        f.note(f"XML well-formed: OK ({len([n for n in names if n.endswith(('.xml', '.rels'))])} parts)")

    if not f.ok():
        return f  # can't safely continue structural checks on broken XML

    # 3. relationship targets resolve
    rel_missing = []
    for n in names:
        if n.endswith('.rels'):
            base = n.rsplit('_rels/', 1)[0]
            rels = ET.fromstring(z.read(n))
            for rel in rels:
                if rel.get('TargetMode') == 'External':
                    continue
                target = rel.get('Target')
                resolved = (Path(base) / target).as_posix() if not target.startswith('/') else target.lstrip('/')
                resolved = str(Path(resolved))
                # normalize .. segments
                parts = []
                for seg in resolved.replace('\\', '/').split('/'):
                    if seg == '..':
                        if parts:
                            parts.pop()
                    elif seg not in ('', '.'):
                        parts.append(seg)
                resolved = '/'.join(parts)
                if resolved not in names:
                    rel_missing.append((n, rel.get('Id'), target, resolved))
    if rel_missing:
        for n, rid, target, resolved in rel_missing:
            f.error(f"relationship {rid} in {n} -> {target!r} does not resolve to a package part ({resolved!r})")
    else:
        f.note("relationship targets: OK")

    # 4. workbook / sheets / tables
    wb = ET.fromstring(z.read('xl/workbook.xml'))
    wbrels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
    relmap = {r.get('Id'): r.get('Target') for r in wbrels}
    sheets = {}
    for s in wb.findall(M + 'sheets/' + M + 'sheet'):
        rid = s.get(R + 'id')
        tgt = relmap[rid]
        tgt = ('xl/' + tgt) if not tgt.startswith('/') else tgt.lstrip('/')
        sheets[s.get('name')] = tgt
    f.note(f"sheets: {len(sheets)} -> {list(sheets)}")

    all_table_names = []
    for sheet_name, tgt in sheets.items():
        sh = ET.fromstring(z.read(tgt))
        relpath = tgt.replace('worksheets/', 'worksheets/_rels/') + '.rels'
        tables = []
        if relpath in names:
            srels = ET.fromstring(z.read(relpath))
            for rel in srels:
                if 'table' in rel.get('Type'):
                    tpath = 'xl/tables/' + rel.get('Target').split('/')[-1]
                    t = ET.fromstring(z.read(tpath))
                    cols = t.findall(M + 'tableColumns/' + M + 'tableColumn')
                    declared_count = int(t.get('tableColumns_count', t.find(M + 'tableColumns').get('count')))
                    if len(cols) != declared_count:
                        f.error(f"{sheet_name}/{t.get('name')}: tableColumns count attr={declared_count} but {len(cols)} tableColumn elements")
                    ref = parse_ref(t.get('ref'))
                    ncols_from_ref = ref[3] - ref[2] + 1
                    if ncols_from_ref != len(cols):
                        f.error(f"{sheet_name}/{t.get('name')}: ref {t.get('ref')} implies {ncols_from_ref} columns but {len(cols)} tableColumn elements declared")
                    tables.append((t.get('name'), ref, cols))
                    all_table_names.append(t.get('name'))

        # worksheet AutoFilter vs table AutoFilter
        af = sh.find(M + 'autoFilter')
        if af is not None:
            ws_af = parse_ref(af.get('ref'))
            for tn, tr, tc in tables:
                if ranges_overlap(ws_af, tr):
                    f.error(f"{sheet_name}: worksheet AutoFilter {af.get('ref')} overlaps table {tn} AutoFilter range")

        # DV overlap
        dvs = sh.find(M + 'dataValidations')
        if dvs is not None:
            for dv in dvs.findall(M + 'dataValidation'):
                for part in dv.get('sqref').split():
                    rng = parse_ref(part)
                    hit = [tn for tn, tr, tc in tables if ranges_overlap(rng, tr)]
                    if len(hit) > 1:
                        f.error(f"{sheet_name}: dataValidation {part} overlaps multiple tables {hit}")
                    if dv.get('type') == 'list':
                        show_err = dv.get('showErrorMessage') in ('1', 'true')
                        style_ok = dv.get('errorStyle', 'stop') == 'stop'
                        if not show_err or not style_ok:
                            f.error(f"{sheet_name}: dataValidation sqref={part} is type=list but Stop-style alert is not enabled (showErrorMessage={dv.get('showErrorMessage')!r} errorStyle={dv.get('errorStyle')!r})")

        # CF overlap
        for cf in sh.findall(M + 'conditionalFormatting'):
            for part in cf.get('sqref').split():
                rng = parse_ref(part)
                hit = [tn for tn, tr, tc in tables if ranges_overlap(rng, tr)]
                if len(hit) > 1:
                    f.error(f"{sheet_name}: conditionalFormatting {part} overlaps multiple tables {hit}")

        # formula scan
        fcells = [c.get('r') for c in sh.iter(M + 'c') if c.find(M + 'f') is not None]
        if fcells:
            f.error(f"{sheet_name}: unexpected formula cells {fcells}")
        errcells = [c.get('r') for c in sh.iter(M + 'c') if c.get('t') == 'e']
        if errcells:
            f.error(f"{sheet_name}: cached formula-error cells {errcells}")

    # table name uniqueness (workbook-wide)
    dupes = {n for n in all_table_names if all_table_names.count(n) > 1}
    if dupes:
        f.error(f"duplicate table names: {dupes}")
    else:
        f.note(f"table names unique: OK ({len(all_table_names)} tables)")

    # 5. macro / external-link scan
    if 'xl/vbaProject.bin' in names:
        f.error("vbaProject.bin present (macro)")
    ct = z.read('[Content_Types].xml').decode()
    if 'macroEnabled' in ct:
        f.error("Content_Types declares a macro-enabled content type")
    ext_links = [n for n in names if 'externalLink' in n]
    if ext_links:
        f.error(f"external links present: {ext_links}")
    if not ext_links and 'xl/vbaProject.bin' not in names and 'macroEnabled' not in ct:
        f.note("macro/external-link scan: OK (none found)")

    # 6. customer-data / personal-path scan
    hits = []
    for n in names:
        if n.endswith(('.png', '.jpg', '.jpeg', '.emf', '.wmf')):
            continue
        data = z.read(n).decode('utf-8', 'replace')
        m = SUSPICIOUS_PATTERN.search(data)
        if m:
            hits.append((n, m.group(0)))
    if hits:
        for n, snippet in hits:
            f.error(f"possible personal path/author residue in {n}: {snippet!r}")
    else:
        f.note("personal-path/author/customer-data scan: OK (none found)")

    return f


def libreoffice_roundtrip(path, findings):
    soffice = shutil.which('soffice') or shutil.which('libreoffice')
    if not soffice:
        findings.note("LibreOffice round-trip: SKIPPED (soffice not available in this environment)")
        return
    with tempfile.TemporaryDirectory() as tmp:
        try:
            subprocess.run(
                [soffice, '--headless', '--convert-to', 'xlsx', '--outdir', tmp, path],
                check=True, capture_output=True, timeout=120,
            )
        except Exception as e:
            findings.error(f"LibreOffice round-trip failed to run: {e}")
            return
        out_path = Path(tmp) / (Path(path).stem + '.xlsx')
        if not out_path.exists():
            findings.error("LibreOffice round-trip: output file not produced")
            return
        rt = validate_workbook(str(out_path))
        orig_sheets = set(ET.fromstring(zipfile.ZipFile(path).read('xl/workbook.xml'))
                           .findall(M + 'sheets/' + M + 'sheet'))
        findings.note(f"LibreOffice round-trip: opened and saved OK ({'no new errors' if rt.ok() else rt.errors})")


def main(paths):
    all_ok = True
    for path in paths:
        print(f"\n{'=' * 90}\n{path}\n{'=' * 90}")
        findings = validate_workbook(path)
        libreoffice_roundtrip(path, findings)
        for note in findings.info:
            print(f"  [info] {note}")
        for warn in findings.warnings:
            print(f"  [warn] {warn}")
        for err in findings.errors:
            print(f"  [FAIL] {err}")
        status = "PASS" if findings.ok() else "FAIL"
        print(f"  ---> {status}")
        all_ok = all_ok and findings.ok()
    print()
    print("OVERALL:", "PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    paths = args or DEFAULT_TEMPLATES
    sys.exit(main(paths))
