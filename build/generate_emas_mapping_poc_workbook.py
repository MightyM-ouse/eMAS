#!/usr/bin/env python3
"""Generate the synthetic eMAS mapping workbook source as deterministic XLSX.

Uses only Python standard library. The generated XLSX is a macro-free build input;
the controlled Windows build imports reviewed VBA source and saves the internal XLSM.
"""
from __future__ import annotations

import argparse
import json
import re
import zipfile
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape, quoteattr

FIXED_ZIP_DATE = (2026, 7, 13, 10, 0, 0)
NS_MAIN = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NS_REL_DOC = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


def _col_name(index: int) -> str:
    result = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        result = chr(65 + remainder) + result
    return result


def _xml(value: Any) -> str:
    return escape(str(value), {'"': '&quot;'})


def _cell(ref: str, value: Any, style: int = 0) -> str:
    style_attr = f' s="{style}"' if style else ""
    if value is None or value == "":
        return f'<c r="{ref}"{style_attr}/>'
    if isinstance(value, bool):
        return f'<c r="{ref}" t="b"{style_attr}><v>{1 if value else 0}</v></c>'
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f'<c r="{ref}"{style_attr}><v>{value}</v></c>'
    return f'<c r="{ref}" t="inlineStr"{style_attr}><is><t xml:space="preserve">{_xml(value)}</t></is></c>'


def _worksheet_xml(title: str, purpose: str, headers: list[str], rows: list[dict[str, Any]], table_rel_id: str | None) -> str:
    row_xml: list[str] = []
    max_col = max(1, len(headers))
    row_xml.append(f'<row r="1" ht="28" customHeight="1">{_cell("A1", title, 1)}</row>')
    row_xml.append(f'<row r="2" ht="22" customHeight="1">{_cell("A2", purpose, 2)}</row>')
    row_xml.append('<row r="3"/>')
    header_cells = ''.join(_cell(f'{_col_name(i)}4', header, 3) for i, header in enumerate(headers, 1))
    row_xml.append(f'<row r="4">{header_cells}</row>')
    material_rows = rows if rows else [{}]
    for row_number, row in enumerate(material_rows, 5):
        cells = ''.join(_cell(f'{_col_name(i)}{row_number}', row.get(header, ''), 0) for i, header in enumerate(headers, 1))
        row_xml.append(f'<row r="{row_number}">{cells}</row>')
    cols = ''.join(f'<col min="{i}" max="{i}" width="{min(48, max(12, len(headers[i-1]) + 3))}" customWidth="1"/>' for i in range(1, max_col + 1))
    last_row = 4 + len(material_rows)
    dimension = f'A1:{_col_name(max_col)}{last_row}'
    table_parts = f'<tableParts count="1"><tablePart r:id="{table_rel_id}"/></tableParts>' if table_rel_id else ''
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<worksheet xmlns="{NS_MAIN}" xmlns:r="{NS_REL_DOC}">'
        f'<dimension ref="{dimension}"/>'
        '<sheetViews><sheetView workbookViewId="0"><pane ySplit="4" topLeftCell="A5" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
        '<sheetFormatPr defaultRowHeight="15"/>'
        f'<cols>{cols}</cols><sheetData>{"".join(row_xml)}</sheetData>'
        '<autoFilter ref="A4:' + _col_name(max_col) + str(last_row) + '"/>'
        f'{table_parts}</worksheet>'
    )


def _start_sheet_xml(source: dict[str, Any]) -> str:
    start = source['startSheet']
    rows = [f'<row r="1" ht="30" customHeight="1">{_cell("A1", start["title"], 1)}</row>']
    for idx, text in enumerate(start.get('instructions', []), 3):
        rows.append(f'<row r="{idx}" ht="24" customHeight="1">{_cell(f"A{idx}", text, 2)}</row>')
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<worksheet xmlns="{NS_MAIN}" xmlns:r="{NS_REL_DOC}">'
        '<dimension ref="A1:H12"/><sheetViews><sheetView workbookViewId="0"/></sheetViews>'
        '<sheetFormatPr defaultRowHeight="18"/><cols><col min="1" max="1" width="95" customWidth="1"/></cols>'
        f'<sheetData>{"".join(rows)}</sheetData></worksheet>'
    )


def _table_xml(table_id: int, table_name: str, headers: list[str], row_count: int) -> str:
    last_col = _col_name(len(headers))
    last_row = 4 + max(1, row_count)
    columns = ''.join(f'<tableColumn id="{i}" name={quoteattr(header)}/>' for i, header in enumerate(headers, 1))
    ref = f'A4:{last_col}{last_row}'
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<table xmlns="{NS_MAIN}" id="{table_id}" name={quoteattr(table_name)} displayName={quoteattr(table_name)} ref="{ref}" totalsRowShown="0">'
        f'<autoFilter ref="{ref}"/><tableColumns count="{len(headers)}">{columns}</tableColumns>'
        '<tableStyleInfo name="TableStyleMedium2" showFirstColumn="0" showLastColumn="0" showRowStripes="1" showColumnStripes="0"/>'
        '</table>'
    )


def _styles_xml() -> str:
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font><sz val="11"/><name val="Aptos"/><family val="2"/></font>
    <font><b/><sz val="18"/><color rgb="FF17365D"/><name val="Aptos Display"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Aptos"/></font>
  </fonts>
  <fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFD9EAF7"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill></fills>
  <borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFD9E1F2"/></left><right style="thin"><color rgb="FFD9E1F2"/></right><top style="thin"><color rgb="FFD9E1F2"/></top><bottom style="thin"><color rgb="FFD9E1F2"/></bottom><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="4">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
    <xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment wrapText="1" vertical="top"/></xf>
    <xf numFmtId="0" fontId="2" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment wrapText="1" vertical="center"/></xf>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
  <dxfs count="0"/><tableStyles count="1" defaultTableStyle="TableStyleMedium2" defaultPivotStyle="PivotStyleLight16"/>
</styleSheet>'''


def _write_entry(zf: zipfile.ZipFile, name: str, content: str | bytes) -> None:
    info = zipfile.ZipInfo(name, FIXED_ZIP_DATE)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    data = content.encode('utf-8') if isinstance(content, str) else content
    zf.writestr(info, data)


def load_source(source_path: Path) -> dict[str, Any]:
    source = json.loads(source_path.read_text(encoding="utf-8"))
    if "parts" in source:
        tables: list[dict[str, Any]] = []
        for relative in source["parts"]:
            part = json.loads((source_path.parent / relative).read_text(encoding="utf-8"))
            tables.extend(part["tables"])
        source["tables"] = tables
    return source


def generate(source_path: Path, output_path: Path) -> None:
    source = load_source(source_path)
    tables = sorted(source['tables'], key=lambda item: item['sequence'])
    for table in tables:
        if not table.get('headers'):
            raise ValueError(f"{table['table']} has no headers")
        if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', table['table']):
            raise ValueError(f"invalid table name {table['table']}")
    sheets = [{'name': source['startSheet']['name'], 'table': None}] + [{'name': t['sheet'], 'table': t} for t in tables]
    if len({s['name'] for s in sheets}) != len(sheets):
        raise ValueError('duplicate sheet name')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_path, 'w') as zf:
        overrides = [
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>',
            '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
        ]
        for idx in range(1, len(sheets) + 1):
            overrides.append(f'<Override PartName="/xl/worksheets/sheet{idx}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')
        for idx in range(1, len(tables) + 1):
            overrides.append(f'<Override PartName="/xl/tables/table{idx}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml"/>')
        content_types = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>' + ''.join(overrides) + '</Types>'
        _write_entry(zf, '[Content_Types].xml', content_types)
        _write_entry(zf, '_rels/.rels', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>')
        _write_entry(zf, 'docProps/core.xml', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>eMAS Mapping Configuration Synthetic POC</dc:title><dc:creator>eMAS</dc:creator><dcterms:created xsi:type="dcterms:W3CDTF">2026-07-13T10:00:00Z</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">2026-07-13T10:00:00Z</dcterms:modified></cp:coreProperties>')
        sheet_names_xml = ''.join(f'<vt:lpstr>{_xml(s["name"])}</vt:lpstr>' for s in sheets)
        _write_entry(zf, 'docProps/app.xml', f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>eMAS POC Generator</Application><HeadingPairs><vt:vector size="2" baseType="variant"><vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant><vt:variant><vt:i4>{len(sheets)}</vt:i4></vt:variant></vt:vector></HeadingPairs><TitlesOfParts><vt:vector size="{len(sheets)}" baseType="lpstr">{sheet_names_xml}</vt:vector></TitlesOfParts></Properties>')
        sheet_entries = ''.join(f'<sheet name={quoteattr(sheet["name"])} sheetId="{idx}" r:id="rId{idx}"/>' for idx, sheet in enumerate(sheets, 1))
        _write_entry(zf, 'xl/workbook.xml', f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="{NS_MAIN}" xmlns:r="{NS_REL_DOC}"><bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews><sheets>{sheet_entries}</sheets><calcPr calcId="0"/></workbook>')
        wb_rels = ''.join(f'<Relationship Id="rId{idx}" Type="{NS_REL_DOC}/worksheet" Target="/xl/worksheets/sheet{idx}.xml"/>' for idx in range(1, len(sheets) + 1))
        wb_rels += f'<Relationship Id="rId{len(sheets)+1}" Type="{NS_REL_DOC}/styles" Target="styles.xml"/>'
        _write_entry(zf, 'xl/_rels/workbook.xml.rels', f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">{wb_rels}</Relationships>')
        _write_entry(zf, 'xl/styles.xml', _styles_xml())
        _write_entry(zf, 'xl/worksheets/sheet1.xml', _start_sheet_xml(source))
        for table_idx, table in enumerate(tables, 1):
            sheet_idx = table_idx + 1
            _write_entry(zf, f'xl/worksheets/sheet{sheet_idx}.xml', _worksheet_xml(table['sheet'], table.get('purpose', ''), table['headers'], table.get('rows', []), 'rId1'))
            _write_entry(zf, f'xl/worksheets/_rels/sheet{sheet_idx}.xml.rels', f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="{NS_REL_DOC}/table" Target="/xl/tables/table{table_idx}.xml"/></Relationships>')
            _write_entry(zf, f'xl/tables/table{table_idx}.xml', _table_xml(table_idx, table['table'], table['headers'], len(table.get('rows', []))))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path('config/authoring/poc/workbook-source.json'))
    parser.add_argument('--output', type=Path, default=Path('output/poc/eMAS_Mapping_Configuration_POC_Source.xlsx'))
    args = parser.parse_args()
    generate(args.source, args.output)
    print(args.output)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
