#!/usr/bin/env python3
"""Mapping-driven eMAS demo XLSX population using Python's standard OOXML tools.

This Python helper is an MVP report-population implementation used behind
the PowerShell command surface. It is not the final qualified production
OpenXML reporting engine.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
import time
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any

try:
    from jsonschema import Draft202012Validator
except ImportError:  # pragma: no cover - exercised as a deployment gate
    Draft202012Validator = None

NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
M = f"{{{NS}}}"
R = f"{{{REL_NS}}}"
ET.register_namespace("", NS)
ET.register_namespace("r", REL_NS)

SUPPORTED_MAPPING_VERSION = "1.0.0"
REQUIRED_TEMPLATE_VERSION = "1.1.1"
WRITE_MODES = {
    "appendRows",
    "matchRowByLabelColumns",
    "singleRowUpdate",
    "copyFromExternalSourceAppendOnly",
    "staticReleaseManaged",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def finding(
    code: str,
    message: str,
    *,
    severity: str = "Error",
    phase: str | None = None,
    mapping_target: str | None = None,
    worksheet: str | None = None,
    table: str | None = None,
    column: str | None = None,
    evidence: Any = None,
    blocking: bool = True,
) -> dict[str, Any]:
    return {
        "Code": code,
        "Severity": severity,
        "Phase": phase,
        "MappingTarget": mapping_target,
        "Worksheet": worksheet,
        "Table": table,
        "Column": column,
        "Message": message,
        "Evidence": evidence,
        "IsBlocking": blocking,
    }


class ReportError(Exception):
    def __init__(self, issue: dict[str, Any]):
        super().__init__(issue["Message"])
        self.issue = issue


class ExecutionLog:
    def __init__(self, path: Path):
        self.path = path
        path.parent.mkdir(parents=True, exist_ok=True)

    def write(self, stage: str, message: str, **fields: Any) -> None:
        payload = " ".join(
            f"{key}={json.dumps(value, ensure_ascii=False, separators=(',', ':'))}"
            for key, value in fields.items()
            if value is not None
        )
        with self.path.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{utc_now()} [{stage}] {message}{(' ' + payload) if payload else ''}\n")


def resolve_part(base_part: str, target: str) -> str:
    if target.startswith("/"):
        return target.lstrip("/")
    parts: list[str] = []
    for segment in (PurePosixPath(base_part).parent / target).parts:
        if segment == "..":
            if parts:
                parts.pop()
        elif segment not in ("", "."):
            parts.append(segment)
    return "/".join(parts)


def column_number(name: str) -> int:
    value = 0
    for character in name:
        value = value * 26 + ord(character.upper()) - 64
    return value


def column_name(number: int) -> str:
    result = ""
    while number:
        number, remainder = divmod(number - 1, 26)
        result = chr(65 + remainder) + result
    return result


def parse_range(cell_range: str) -> tuple[int, int, int, int]:
    match = re.fullmatch(r"([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?", cell_range)
    if not match:
        raise ValueError(f"Unsupported A1 range: {cell_range}")
    c1, r1, c2, r2 = match.groups()
    return int(r1), int(r2 or r1), column_number(c1), column_number(c2 or c1)


def make_range(r1: int, r2: int, c1: int, c2: int) -> str:
    return f"{column_name(c1)}{r1}:{column_name(c2)}{r2}"


def lower_camel(value: str) -> str:
    return value[:1].lower() + value[1:] if value else value


@dataclass
class TableInfo:
    name: str
    sheet_name: str
    sheet_path: str
    table_path: str
    root: ET.Element
    columns: list[str]

    @property
    def bounds(self) -> tuple[int, int, int, int]:
        return parse_range(self.root.get("ref", ""))


class OpenXmlPackage:
    def __init__(self, path: Path):
        self.path = path
        try:
            with zipfile.ZipFile(path) as archive:
                bad = archive.testzip()
                if bad:
                    raise ReportError(finding("RPT-TEMPLATE-002", "Template ZIP CRC validation failed.", evidence=bad))
                self.infos = archive.infolist()
                self.entries = {info.filename: archive.read(info.filename) for info in self.infos}
        except zipfile.BadZipFile as exc:
            raise ReportError(finding("RPT-TEMPLATE-001", "Template is not a valid XLSX ZIP package.", evidence=str(exc))) from exc
        self._roots: dict[str, ET.Element] = {}
        self.shared_strings = self._load_shared_strings()
        self.sheet_paths = self._load_sheet_paths()
        self.tables = self._load_tables()

    def root(self, part: str) -> ET.Element:
        if part not in self._roots:
            try:
                self._roots[part] = ET.fromstring(self.entries[part])
            except (KeyError, ET.ParseError) as exc:
                raise ReportError(finding("RPT-VALIDATE-002", "Required OpenXML part is missing or malformed.", evidence={"part": part, "error": str(exc)})) from exc
        return self._roots[part]

    def _load_shared_strings(self) -> list[str]:
        if "xl/sharedStrings.xml" not in self.entries:
            return []
        root = ET.fromstring(self.entries["xl/sharedStrings.xml"])
        return ["".join(node.text or "" for node in item.iter(M + "t")) for item in root.findall(M + "si")]

    def _load_sheet_paths(self) -> dict[str, str]:
        workbook = self.root("xl/workbook.xml")
        relationships = self.root("xl/_rels/workbook.xml.rels")
        relation_map = {rel.get("Id"): rel.get("Target") for rel in relationships}
        paths: dict[str, str] = {}
        for sheet in workbook.findall(M + "sheets/" + M + "sheet"):
            paths[sheet.get("name", "")] = resolve_part("xl/workbook.xml", relation_map[sheet.get(R + "id")])
        return paths

    def _load_tables(self) -> dict[str, TableInfo]:
        tables: dict[str, TableInfo] = {}
        for sheet_name, sheet_path in self.sheet_paths.items():
            rel_path = str(PurePosixPath(sheet_path).parent / "_rels" / f"{PurePosixPath(sheet_path).name}.rels")
            if rel_path not in self.entries:
                continue
            relationships = self.root(rel_path)
            for relation in relationships:
                if not (relation.get("Type") or "").endswith("/table"):
                    continue
                table_path = resolve_part(sheet_path, relation.get("Target", ""))
                table_root = self.root(table_path)
                table_name = table_root.get("name", "")
                columns = [node.get("name", "") for node in table_root.findall(M + "tableColumns/" + M + "tableColumn")]
                tables[table_name] = TableInfo(table_name, sheet_name, sheet_path, table_path, table_root, columns)
        return tables

    def cell_value(self, cell: ET.Element | None) -> Any:
        if cell is None:
            return None
        cell_type = cell.get("t")
        value = cell.find(M + "v")
        inline = cell.find(M + "is")
        if cell_type == "s" and value is not None:
            return self.shared_strings[int(value.text or "0")]
        if cell_type == "inlineStr" and inline is not None:
            return "".join(node.text or "" for node in inline.iter(M + "t"))
        if cell_type == "b" and value is not None:
            return value.text == "1"
        return value.text if value is not None else None

    def sheet_data(self, sheet_path: str) -> ET.Element:
        root = self.root(sheet_path)
        data = root.find(M + "sheetData")
        if data is None:
            data = ET.SubElement(root, M + "sheetData")
        return data

    def row(self, sheet_path: str, number: int, create: bool = False) -> ET.Element | None:
        data = self.sheet_data(sheet_path)
        for row in data.findall(M + "row"):
            current = int(row.get("r", "0"))
            if current == number:
                return row
            if current > number and create:
                created = ET.Element(M + "row", {"r": str(number)})
                data.insert(list(data).index(row), created)
                return created
        if create:
            return ET.SubElement(data, M + "row", {"r": str(number)})
        return None

    def cell(self, sheet_path: str, row_number: int, column_number_: int, create: bool = False, style_from: ET.Element | None = None) -> ET.Element | None:
        row = self.row(sheet_path, row_number, create=create)
        if row is None:
            return None
        reference = f"{column_name(column_number_)}{row_number}"
        for cell in row.findall(M + "c"):
            current = column_number(re.match(r"[A-Z]+", cell.get("r", "A1")).group())
            if cell.get("r") == reference:
                return cell
            if current > column_number_ and create:
                attributes = {"r": reference}
                if style_from is not None and style_from.get("s") is not None:
                    attributes["s"] = style_from.get("s")
                created = ET.Element(M + "c", attributes)
                row.insert(list(row).index(cell), created)
                return created
        if create:
            attributes = {"r": reference}
            if style_from is not None and style_from.get("s") is not None:
                attributes["s"] = style_from.get("s")
            return ET.SubElement(row, M + "c", attributes)
        return None

    def set_value(self, cell: ET.Element, value: Any) -> None:
        for child in list(cell):
            cell.remove(child)
        if value is None or value == "":
            cell.attrib.pop("t", None)
            return
        if isinstance(value, bool):
            cell.set("t", "b")
            ET.SubElement(cell, M + "v").text = "1" if value else "0"
        elif isinstance(value, (int, float)) and not isinstance(value, bool):
            cell.attrib.pop("t", None)
            ET.SubElement(cell, M + "v").text = str(value)
        else:
            cell.set("t", "inlineStr")
            inline = ET.SubElement(cell, M + "is")
            text = ET.SubElement(inline, M + "t")
            text.text = str(value)
            if str(value).strip() != str(value):
                text.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")

    def table_rows(self, table: TableInfo) -> list[list[Any]]:
        r1, r2, c1, c2 = table.bounds
        rows: list[list[Any]] = []
        for row_number in range(r1, r2 + 1):
            rows.append([self.cell_value(self.cell(table.sheet_path, row_number, column)) for column in range(c1, c2 + 1)])
        return rows

    def ensure_styled_row(self, table: TableInfo, row_number: int, style_row: int) -> None:
        _, _, c1, c2 = table.bounds
        for column in range(c1, c2 + 1):
            style_cell = self.cell(table.sheet_path, style_row, column)
            self.cell(table.sheet_path, row_number, column, create=True, style_from=style_cell)

    def update_table_ref(self, table: TableInfo, last_row: int) -> None:
        r1, _, c1, c2 = table.bounds
        reference = make_range(r1, last_row, c1, c2)
        table.root.set("ref", reference)
        auto_filter = table.root.find(M + "autoFilter")
        if auto_filter is not None:
            auto_filter.set("ref", reference)

    def control_metadata(self, table_name: str) -> dict[str, str]:
        if table_name not in self.tables:
            return {}
        rows = self.table_rows(self.tables[table_name])
        return {str(row[0]): str(row[1]) for row in rows[1:] if len(row) >= 2 and row[0] not in (None, "")}

    def snapshot(self, protected: list[dict[str, Any]]) -> dict[str, Any]:
        formulas: dict[str, list[tuple[str, str]]] = {}
        validations: dict[str, list[str]] = {}
        conditional: dict[str, list[str]] = {}
        for sheet_name, sheet_path in self.sheet_paths.items():
            root = self.root(sheet_path)
            formulas[sheet_name] = [(cell.get("r", ""), formula.text or "") for cell in root.iter(M + "c") if (formula := cell.find(M + "f")) is not None]
            validation_root = root.find(M + "dataValidations")
            validations[sheet_name] = [
                ET.tostring(node, encoding="unicode")
                for node in (list(validation_root) if validation_root is not None else [])
            ]
            conditional[sheet_name] = [ET.tostring(node, encoding="unicode") for node in root.findall(M + "conditionalFormatting")]
        protected_data = {
            item["tableName"]: self.table_rows(self.tables[item["tableName"]])
            for item in protected
            if item.get("protection") == "readOnly" and item.get("tableName") in self.tables
        }
        return {
            "sheets": list(self.sheet_paths),
            "tables": {name: {"sheet": table.sheet_name, "columns": table.columns, "ref": table.root.get("ref")} for name, table in self.tables.items()},
            "formulas": formulas,
            "validations": validations,
            "conditionalFormatting": conditional,
            "relationships": {name: hashlib.sha256(data).hexdigest() for name, data in self.entries.items() if name.endswith(".rels")},
            "protectedData": protected_data,
        }

    def write(self, path: Path) -> None:
        writable_parts = set(self.sheet_paths.values()) | {table.table_path for table in self.tables.values()}
        for part in writable_parts:
            if part in self._roots:
                self.entries[part] = ET.tostring(self._roots[part], encoding="utf-8", xml_declaration=True)
        path.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary_name = tempfile.mkstemp(suffix=".xlsx", dir=str(path.parent))
        os.close(descriptor)
        try:
            with zipfile.ZipFile(temporary_name, "w") as archive:
                for info in self.infos:
                    archive.writestr(info, self.entries[info.filename])
            os.replace(temporary_name, path)
            os.chmod(path, self.path.stat().st_mode)
        finally:
            if os.path.exists(temporary_name):
                os.unlink(temporary_name)


def load_json(path: Path, code: str, description: str) -> Any:
    try:
        with path.open(encoding="utf-8-sig") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise ReportError(finding(code, f"{description} could not be loaded.", evidence=str(exc))) from exc


def validate_mapping(mapping: dict[str, Any], schema: dict[str, Any]) -> None:
    if Draft202012Validator is None:
        raise ReportError(finding("RPT-VALIDATE-001", "The repository jsonschema dependency is required to validate the report mapping."))
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(mapping), key=lambda item: list(item.path))
    if errors:
        issue = errors[0]
        raise ReportError(finding("RPT-MAP-001", "Template mapping does not conform to report-template-map.schema.json.", evidence={"path": list(issue.path), "detail": issue.message}))
    if mapping.get("mappingVersion") != SUPPORTED_MAPPING_VERSION:
        raise ReportError(finding("RPT-MAP-002", "Unsupported template mapping version.", evidence=mapping.get("mappingVersion")))
    unsupported = sorted({item.get("writeMode") for item in mapping.get("tableMappings", [])} - WRITE_MODES)
    if unsupported:
        raise ReportError(finding("RPT-MAP-003", "Template mapping declares an unsupported write mode.", evidence=unsupported))


def require_collection(result: dict[str, Any], mapping: dict[str, Any], table_mapping: dict[str, Any]) -> list[dict[str, Any]]:
    names = [table_mapping["sourceCollection"], *table_mapping.get("additionalSourceCollections", [])]
    records: list[dict[str, Any]] = []
    for name in names:
        if name not in result:
            required_fields = [column for column in table_mapping["columns"] if column.get("required") and column.get("sourceField")]
            if required_fields:
                raise ReportError(finding("RPT-RESULT-004", "A mandatory normalized result collection is missing.", phase=mapping["phaseCode"], mapping_target=name, worksheet=table_mapping["sheetName"], table=table_mapping["tableName"], evidence=name))
            continue
        value = result[name]
        if isinstance(value, dict):
            value = [value]
        if not isinstance(value, list) or any(not isinstance(item, dict) for item in value):
            raise ReportError(finding("RPT-RESULT-005", "A normalized result collection must be an object or array of objects.", phase=mapping["phaseCode"], mapping_target=name, evidence=type(value).__name__))
        records.extend(value)
    return records


def validate_required_fields(records: list[dict[str, Any]], table_mapping: dict[str, Any], phase: str) -> None:
    for index, record in enumerate(records):
        for column in table_mapping["columns"]:
            source = column.get("sourceField")
            if source and column.get("required") and record.get(source) in (None, ""):
                raise ReportError(finding("RPT-RESULT-006", "A required normalized result field is missing or blank.", phase=phase, mapping_target=table_mapping["sourceCollection"], worksheet=table_mapping["sheetName"], table=table_mapping["tableName"], column=column["targetColumn"], evidence={"recordIndex": index, "sourceField": source}))


def write_record(package: OpenXmlPackage, table: TableInfo, table_mapping: dict[str, Any], row_number: int, record: dict[str, Any], *, include_labels: bool = True) -> None:
    _, _, first_column, _ = table.bounds
    style_row = int(table_mapping.get("firstDataRow") or (table.bounds[0] + 1))
    package.ensure_styled_row(table, row_number, style_row)
    for column_mapping in table_mapping["columns"]:
        source = column_mapping.get("sourceField")
        if source is None or (column_mapping.get("isLabelColumn") and not include_labels):
            continue
        target = column_mapping["targetColumn"]
        column_index = table.columns.index(target)
        cell = package.cell(table.sheet_path, row_number, first_column + column_index, create=True)
        package.set_value(cell, record.get(source))


def append_rows(package: OpenXmlPackage, table: TableInfo, table_mapping: dict[str, Any], records: list[dict[str, Any]], phase: str) -> int:
    validate_required_fields(records, table_mapping, phase)
    capacity = table_mapping.get("rowCapacity", {}).get("maxPreProvisionedRows", 1)
    if len(records) > capacity:
        raise ReportError(finding("RPT-WRITE-090", "Result rows exceed the safe pre-provisioned capacity; row shifting is not implemented in this MVP.", phase=phase, mapping_target=table_mapping["sourceCollection"], worksheet=table.sheet_name, table=table.name, evidence={"rows": len(records), "capacity": capacity}))
    header_row, _, _, _ = table.bounds
    first_data_row = int(table_mapping.get("firstDataRow") or header_row + 1)
    rows_to_keep = max(1, len(records))
    for offset in range(rows_to_keep):
        row_number = first_data_row + offset
        package.ensure_styled_row(table, row_number, first_data_row)
        if offset < len(records):
            write_record(package, table, table_mapping, row_number, records[offset])
        else:
            for column in range(table.bounds[2], table.bounds[3] + 1):
                package.set_value(package.cell(table.sheet_path, row_number, column, create=True), None)
    package.update_table_ref(table, first_data_row + rows_to_keep - 1)
    return len(records)


def match_rows(package: OpenXmlPackage, table: TableInfo, table_mapping: dict[str, Any], records: list[dict[str, Any]], phase: str) -> int:
    validate_required_fields(records, table_mapping, phase)
    rows = package.table_rows(table)
    header_row, _, first_column, _ = table.bounds
    labels = table_mapping.get("labelColumns", [])
    label_indexes = [table.columns.index(name) for name in labels]
    row_map: dict[tuple[str, ...], list[int]] = {}
    for offset, row in enumerate(rows[1:], start=1):
        key = tuple(str(row[index] if row[index] is not None else "") for index in label_indexes)
        row_map.setdefault(key, []).append(header_row + offset)
    for key, matches in row_map.items():
        if all(key) and len(matches) > 1:
            raise ReportError(finding("RPT-ROW-002", "Template contains duplicate or ambiguous label-row matches.", phase=phase, mapping_target=table_mapping["sourceCollection"], worksheet=table.sheet_name, table=table.name, evidence={"labels": key, "rows": matches}))
    written = 0
    source_keys: set[tuple[str, ...]] = set()
    for record in records:
        key_values = []
        for label in labels:
            column_mapping = next(column for column in table_mapping["columns"] if column["targetColumn"] == label)
            source = column_mapping.get("sourceField") or lower_camel(label)
            key_values.append(str(record.get(source, "")))
        key = tuple(key_values)
        if key in source_keys:
            raise ReportError(finding("RPT-ROW-002", "Normalized result contains duplicate label-row matches.", phase=phase, mapping_target=table_mapping["sourceCollection"], worksheet=table.sheet_name, table=table.name, evidence={"labels": key}))
        source_keys.add(key)
        matches = row_map.get(key, [])
        if len(matches) != 1:
            if not matches and table_mapping.get("allowAppendAdditionalRows"):
                new_row = table.bounds[1] + 1
                write_record(package, table, table_mapping, new_row, record, include_labels=True)
                package.update_table_ref(table, new_row)
                row_map[key] = [new_row]
                written += 1
                continue
            code = "RPT-ROW-001" if not matches else "RPT-ROW-002"
            raise ReportError(finding(code, "Mandatory label-row match was not unique.", phase=phase, mapping_target=table_mapping["sourceCollection"], worksheet=table.sheet_name, table=table.name, evidence={"labels": key, "matches": matches}))
        write_record(package, table, table_mapping, matches[0], record, include_labels=False)
        written += 1
    return written


def validate_contract_identity(result: dict[str, Any], mapping: dict[str, Any], control: dict[str, str]) -> None:
    checks = [
        ("phaseCode", mapping["phaseCode"], "RPT-RESULT-002", "Result phase does not match mapping phase."),
        ("mappingId", mapping["mappingId"], "RPT-RESULT-003", "Result mapping ID does not match the selected mapping."),
        ("templateId", mapping["template"]["templateId"], "RPT-TEMPLATE-003", "Result template ID does not match the selected mapping."),
        ("templateVersion", REQUIRED_TEMPLATE_VERSION, "RPT-TEMPLATE-004", "Result template version must be 1.1.1."),
    ]
    for key, expected, code, message in checks:
        if result.get(key) != expected:
            raise ReportError(finding(code, message, phase=mapping["phaseCode"], evidence={"expected": expected, "actual": result.get(key)}))
    if mapping["template"]["templateVersion"] != REQUIRED_TEMPLATE_VERSION:
        raise ReportError(finding("RPT-TEMPLATE-005", "Mapping does not target controlled template version 1.1.1.", phase=mapping["phaseCode"], evidence=mapping["template"]["templateVersion"]))
    control_checks = {"TemplateId": mapping["template"]["templateId"], "TemplateVersion": REQUIRED_TEMPLATE_VERSION, "PhaseCode": mapping["phaseCode"]}
    for key, expected in control_checks.items():
        if control.get(key) != expected:
            raise ReportError(finding("RPT-TEMPLATE-006", "Workbook Template Control metadata does not match the mapping.", phase=mapping["phaseCode"], evidence={"property": key, "expected": expected, "actual": control.get(key)}))


def validate_structure(package: OpenXmlPackage, mapping: dict[str, Any]) -> None:
    if list(package.sheet_paths) != mapping["requiredSheetOrder"]:
        raise ReportError(finding("RPT-SHEET-001", "Workbook worksheet names or order do not match the mapping.", phase=mapping["phaseCode"], evidence={"expected": mapping["requiredSheetOrder"], "actual": list(package.sheet_paths)}))
    for target in [*mapping["tableMappings"], *mapping.get("protectedTables", [])]:
        sheet = target["sheetName"]
        table_name = target["tableName"]
        if sheet not in package.sheet_paths:
            raise ReportError(finding("RPT-SHEET-002", "Mapped worksheet is missing.", phase=mapping["phaseCode"], worksheet=sheet, table=table_name))
        if table_name not in package.tables or package.tables[table_name].sheet_name != sheet:
            raise ReportError(finding("RPT-TABLE-001", "Mapped Excel table is missing from the expected worksheet.", phase=mapping["phaseCode"], worksheet=sheet, table=table_name))
        if "columns" in target:
            expected = [column["targetColumn"] for column in target["columns"]]
            actual = package.tables[table_name].columns
            if expected != actual:
                raise ReportError(finding("RPT-COLUMN-001", "Mapped Excel table columns or order do not match the controlled template.", phase=mapping["phaseCode"], worksheet=sheet, table=table_name, evidence={"expected": expected, "actual": actual}))


def validate_preservation(before: dict[str, Any], after: dict[str, Any], mapping: dict[str, Any]) -> None:
    for key, code, message in [
        ("sheets", "RPT-PRESERVE-001", "Worksheet structure changed unexpectedly."),
        ("formulas", "RPT-PRESERVE-002", "Workbook formulas changed unexpectedly."),
        ("validations", "RPT-PRESERVE-003", "Workbook data validations changed unexpectedly."),
        ("conditionalFormatting", "RPT-PRESERVE-004", "Workbook conditional formatting changed unexpectedly."),
        ("relationships", "RPT-PRESERVE-005", "Workbook relationships changed unexpectedly."),
        ("protectedData", "RPT-PRESERVE-006", "Static release-managed content changed unexpectedly."),
    ]:
        if before[key] != after[key]:
            raise ReportError(finding(code, message, phase=mapping["phaseCode"]))
    if set(before["tables"]) != set(after["tables"]):
        raise ReportError(finding("RPT-PRESERVE-007", "Excel table names changed unexpectedly.", phase=mapping["phaseCode"]))
    for table_name in before["tables"]:
        if before["tables"][table_name]["columns"] != after["tables"][table_name]["columns"]:
            raise ReportError(finding("RPT-PRESERVE-008", "Excel table column order changed unexpectedly.", phase=mapping["phaseCode"], table=table_name))


def validate_zip_package(path: Path) -> None:
    try:
        with zipfile.ZipFile(path) as archive:
            if archive.testzip():
                raise ValueError("CRC failure")
            for name in archive.namelist():
                if name.endswith((".xml", ".rels")):
                    ET.fromstring(archive.read(name))
            names = set(archive.namelist())
            for name in names:
                if not name.endswith(".rels"):
                    continue
                root = ET.fromstring(archive.read(name))
                owner = name.replace("/_rels/", "/").removesuffix(".rels")
                for relation in root:
                    if relation.get("TargetMode") == "External":
                        continue
                    target = resolve_part(owner, relation.get("Target", ""))
                    if target not in names:
                        raise ValueError(f"Unresolved relationship {name} -> {target}")
    except (OSError, zipfile.BadZipFile, ET.ParseError, ValueError) as exc:
        raise ReportError(finding("RPT-VALIDATE-003", "Generated workbook is not a structurally valid OpenXML package.", evidence=str(exc))) from exc


def export_report(result_path: Path, mapping_path: Path, schema_path: Path, template_path: Path, output_path: Path, log_path: Path) -> dict[str, Any]:
    started = time.monotonic()
    log = ExecutionLog(log_path)
    issues: list[dict[str, Any]] = []
    source_hash_before = None
    mapping: dict[str, Any] = {}
    try:
        log.write("Initializing", "Report generation started", result=str(result_path), mapping=str(mapping_path), template=str(template_path), output=str(output_path))
        result = load_json(result_path, "RPT-RESULT-001", "Normalized result JSON")
        log.write(
            "Loading normalized result",
            "Normalized phase result loaded",
            phase=result.get("phaseCode"),
            executionId=result.get("executionId"),
            resultContractVersion=result.get("resultContractVersion"),
            runtimeTrace=result.get("runtimeTrace"),
        )
        mapping = load_json(mapping_path, "RPT-MAP-004", "Template mapping JSON")
        schema = load_json(schema_path, "RPT-MAP-005", "Template mapping schema")
        validate_mapping(mapping, schema)
        log.write("Validating report mapping", "Mapping validated", mappingId=mapping["mappingId"], mappingVersion=mapping["mappingVersion"], phase=mapping["phaseCode"])
        source_hash_before = sha256_file(template_path)
        package = OpenXmlPackage(template_path)
        validate_structure(package, mapping)
        control = package.control_metadata(mapping["template"]["templateControlTable"])
        validate_contract_identity(result, mapping, control)
        before = package.snapshot(mapping.get("protectedTables", []))
        log.write("Validating controlled template", "Template structure and identity validated", templateId=control.get("TemplateId"), templateVersion=control.get("TemplateVersion"), phase=control.get("PhaseCode"), sourceTemplateSha256=source_hash_before)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(template_path, output_path)
        log.write("Copying controlled template", "Source template copied", output=str(output_path))
        target_counts: dict[str, int] = {}
        for protected in mapping.get("protectedTables", []):
            if protected["protection"] == "readOnly":
                log.write("Populating mapped targets", "staticReleaseManaged target validated and left unchanged", worksheet=protected["sheetName"], table=protected["tableName"])
        for target in mapping["tableMappings"]:
            table = package.tables[target["tableName"]]
            records = require_collection(result, mapping, target)
            mode = target["writeMode"]
            if mode == "appendRows" or mode == "copyFromExternalSourceAppendOnly":
                count = append_rows(package, table, target, records, mapping["phaseCode"])
            elif mode == "matchRowByLabelColumns":
                count = match_rows(package, table, target, records, mapping["phaseCode"])
            elif mode == "singleRowUpdate":
                if len(records) != 1:
                    raise ReportError(finding("RPT-ROW-003", "singleRowUpdate requires exactly one normalized result object.", phase=mapping["phaseCode"], mapping_target=target["sourceCollection"], worksheet=table.sheet_name, table=table.name, evidence=len(records)))
                count = append_rows(package, table, target, records, mapping["phaseCode"])
            elif mode == "staticReleaseManaged":
                count = 0
            else:
                raise ReportError(finding("RPT-WRITE-001", "Unsupported write mode.", phase=mapping["phaseCode"], mapping_target=target["sourceCollection"], evidence=mode))
            target_counts[target["tableName"]] = count
            log.write("Populating mapped targets", "Mapping target processed", worksheet=table.sheet_name, table=table.name, writeMode=mode, rowCount=count)
        package.write(output_path)
        validate_zip_package(output_path)
        generated = OpenXmlPackage(output_path)
        after = generated.snapshot(mapping.get("protectedTables", []))
        validate_preservation(before, after, mapping)
        output_control = generated.control_metadata(mapping["template"]["templateControlTable"])
        validate_contract_identity(result, mapping, output_control)
        source_hash_after = sha256_file(template_path)
        if source_hash_before != source_hash_after:
            raise ReportError(finding("RPT-PRESERVE-009", "Controlled source-template hash changed during report generation.", phase=mapping["phaseCode"], evidence={"before": source_hash_before, "after": source_hash_after}))
        raw_headers = {item["tableName"]: generated.tables[item["tableName"]].columns for item in mapping.get("protectedTables", []) if item.get("preserveHeadersExactly")}
        duration = round(time.monotonic() - started, 3)
        log.write("Completing report", "Report generation completed", durationSeconds=duration, outputSha256=sha256_file(output_path), sourceTemplateSha256=source_hash_after, resultFinal=result.get("finalResult"))
        return {
            "Status": "Passed",
            "Phase": mapping["phaseCode"],
            "FinalResult": result.get("finalResult"),
            "MappingId": mapping["mappingId"],
            "MappingVersion": mapping["mappingVersion"],
            "TemplateId": mapping["template"]["templateId"],
            "TemplateVersion": REQUIRED_TEMPLATE_VERSION,
            "SourceTemplateSha256Before": source_hash_before,
            "SourceTemplateSha256After": source_hash_after,
            "OutputWorkbookPath": str(output_path.resolve()),
            "ExecutionLogPath": str(log_path.resolve()),
            "OutputSha256": sha256_file(output_path),
            "DurationSeconds": duration,
            "TargetRowCounts": target_counts,
            "RawHeaders": raw_headers,
            "Validation": {"OverallStatus": "Valid", "BlockingIssueCount": 0, "Findings": []},
        }
    except ReportError as exc:
        issues.append(exc.issue)
        log.write("Failed", exc.issue["Message"], code=exc.issue["Code"], evidence=exc.issue.get("Evidence"))
        return {
            "Status": "Failed",
            "Phase": mapping.get("phaseCode"),
            "SourceTemplateSha256Before": source_hash_before,
            "OutputWorkbookPath": str(output_path.resolve()),
            "ExecutionLogPath": str(log_path.resolve()),
            "DurationSeconds": round(time.monotonic() - started, 3),
            "Validation": {"OverallStatus": "Invalid", "BlockingIssueCount": len(issues), "Findings": issues},
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--result", required=True, type=Path)
    parser.add_argument("--mapping", required=True, type=Path)
    parser.add_argument("--mapping-schema", required=True, type=Path)
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    arguments = parser.parse_args(argv)
    response = export_report(arguments.result, arguments.mapping, arguments.mapping_schema, arguments.template, arguments.output, arguments.log)
    print(json.dumps(response, ensure_ascii=False, separators=(",", ":")))
    return 0 if response["Status"] == "Passed" else 1


if __name__ == "__main__":
    sys.exit(main())
