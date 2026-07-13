#!/usr/bin/env python3
"""Builds the fictional Aurelis Therapeutics demo dataset used for the eMAS
end-to-end internal demonstration (GitHub Issue tracked under
demo/end-to-end-mvp). Produces:

  tools/demo/data/aurelis-demo-input.json           -- shared master seed
  tools/demo/data/aurelis-pre-sales-result.json      -- normalized result object
  tools/demo/data/aurelis-pre-migration-result.json  -- normalized result object
  tools/demo/data/aurelis-post-migration-result.json -- normalized result object

The three "result" files conform exactly to the field-name contract declared
in config/report-mappings/*.template-map.json (sourceField names) and are
consumed as-is by engine/reporting/emas_report_openxml.py (the real MVP
report-population implementation) to populate copies of the three finalized
controlled templates.

All customer, project, dossier, path and personnel data is fictional.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent

# ---------------------------------------------------------------------------
# Shared project identity
# ---------------------------------------------------------------------------
PROJECT = {
    "customerName": "Aurelis Therapeutics GmbH",
    "projectName": "Aurelis Regulatory Content Migration 2026",
    "projectReference": "AUR-MIG-26-041",
    "migrationScenario": "Hybrid migration",
    "sourceLandscape": "Legacy regulatory document repository, eCTD export folders, archive storage, and MS SQL metadata extract",
    "targetEnvironment": "eCTDmanager migration environment",
    "sourceEnvironment": "AUR-REG-PRD",
    "migrationStagingEnvironment": "AUR-MIG-STG01",
    "executionAccount": r"AURCORP\svc_emas_assessment",
    "primarySourceRoot": r"E:\Aurelis\MigrationSource\RegulatoryExport",
    "archiveRootPublished": r"E:\Aurelis\Archive\Published",
    "archiveRootHistorical": r"E:\Aurelis\Archive\Historical",
    "stagingRoot": r"F:\MigrationStaging\AUR-MIG-26-041",
    "databaseReference": r"AURREGSQL01\REGULATORY",
}

DISCLOSURE = "Data classification: fictional dataset prepared for internal demonstration. Contains no customer or personal data."

# ---------------------------------------------------------------------------
# Master dossier inventory (18 dossiers, sequence counts sum to 243)
# ---------------------------------------------------------------------------
DOSSIERS = [
    # id, name, region, format, type, sequence_count
    ("AUR-LUM-EU-001", "Lumivera", "EU", "eCTD", "Human medicinal product", 18),
    ("AUR-CAR-EU-002", "Cardionex", "EU", "eCTD", "Human medicinal product", 12),
    ("AUR-NEP-US-003", "NephraVale", "US", "eCTD", "NDA lifecycle", 16),
    ("AUR-PUL-US-004", "PulmoCrest", "US", "eCTD", "IND lifecycle", 9),
    ("AUR-ONC-EU-005", "OncoRay", "EU", "eCTD / ASMF-related", "Oncology medicinal product", 7),
    ("AUR-VET-EU-006", "VetraSol", "EU", "eCTD", "Veterinary medicinal product", 11),
    ("AUR-IMM-EU-007", "Immunova", "EU", "eCTD", "Biological medicinal product", 14),
    ("AUR-NEU-UK-008", "Neurovia", "UK", "eCTD", "Human medicinal product", 13),
    ("AUR-DER-EU-009", "Dermalyn", "EU", "eCTD", "Paediatric medicinal product", 17),
    ("AUR-GLY-US-010", "Glycozen", "US", "eCTD", "BLA lifecycle", 15),
    ("AUR-HEP-CA-011", "HepaCure", "Canada", "eCTD", "NDS lifecycle", 8),
    ("AUR-ORB-EU-012", "OrbiLung", "EU", "eCTD", "Orphan medicinal product", 10),
    ("AUR-REN-US-013", "Renalyte", "US", "eCTD", "ANDA lifecycle", 19),
    ("AUR-MYE-EU-014", "MyeloNova", "EU", "eCTD", "Investigational medicinal product", 6),
    ("AUR-ART-EU-015", "ArthoZen", "EU", "eCTD", "Human medicinal product", 20),
    ("AUR-VIR-UK-016", "ViroNexa", "UK", "eCTD", "Human medicinal product", 12),
    ("AUR-END-EU-017", "EnduraMed", "EU", "NeeS legacy", "Human medicinal product", 14),
    ("AUR-CAL-UN-018", "Caldriva", "Initially unresolved, later confirmed EU", "Legacy export transitioning to eCTD", "Human medicinal product", 22),
]

assert sum(d[5] for d in DOSSIERS) == 243, "sequence counts must total exactly 243"
assert len(DOSSIERS) == 18

# Pre-Sales dossier-level RAG classification: 12 Green, 5 Amber, 1 Red
RED_DOSSIERS = {"AUR-CAL-UN-018"}
AMBER_DOSSIERS = {"AUR-END-EU-017", "AUR-MYE-EU-014", "AUR-HEP-CA-011", "AUR-ORB-EU-012", "AUR-VIR-UK-016"}
assert len(RED_DOSSIERS) == 1 and len(AMBER_DOSSIERS) == 5
GREEN_DOSSIERS = {d[0] for d in DOSSIERS} - RED_DOSSIERS - AMBER_DOSSIERS
assert len(GREEN_DOSSIERS) == 12

TECHNICAL_STANDARD_BY_FORMAT = {
    "eCTD": "ICH eCTD 3.2.2",
    "eCTD / ASMF-related": "ICH eCTD 3.2.2",
    "NeeS legacy": "NeeS",
    "Legacy export transitioning to eCTD": "NeeS",
}
REGIONAL_IMPLEMENTATION_BY_REGION = {
    "EU": "EU eCTD Module 1",
    "US": "US FDA Module 1",
    "UK": "UK Module 1",
    "Canada": "Canada Module 1",
    "Initially unresolved, later confirmed EU": "EU eCTD Module 1",
}

# Production-style source profile totals
SOURCE_PROFILE = {
    "dossierCount": 18,
    "sequenceCount": 243,
    "fileCount": 128643,
    "folderCount": 14987,
    "exportSizeGB": 86.47,
    "archiveSizeGB": 312.84,
    "databaseSizeGB": 38.19,
    "longPathsInitial": 17,
    "zeroByteFilesInitial": 4,
    "missingChecksumInitial": 3,
    "unknownFoldersInitial": 7,
    "inaccessibleArchiveLocations": 1,
    "largestSequenceGB": 4.8,
    "maxInitialPathLength": 278,
}

FILE_TYPE_WEIGHTS = [
    ("PDF", 0.462), ("XML", 0.318), ("DOCX", 0.062), ("XLSX", 0.041),
    ("JPG", 0.038), ("TIF", 0.029), ("ZIP", 0.021), ("TXT", 0.017), ("Other", 0.012),
]


def utc(y, m, d, hh, mm, ss):
    return datetime(y, m, d, hh, mm, ss, tzinfo=timezone.utc)


PRESALES_DATE = utc(2026, 6, 18, 9, 14, 22)
PREMIGRATION_DATE = utc(2026, 7, 7, 8, 5, 11)
POSTMIGRATION_DATE = utc(2026, 7, 13, 10, 42, 37)

EXCEL_EPOCH = datetime(1899, 12, 30, tzinfo=timezone.utc)


def excel_datetime(dt: datetime) -> float:
    delta = dt - EXCEL_EPOCH
    return round(delta.days + delta.seconds / 86400 + delta.microseconds / 86400000000, 10)


def excel_date(dt: datetime) -> int:
    delta = dt.replace(hour=0, minute=0, second=0, microsecond=0) - EXCEL_EPOCH
    return delta.days


def fictional_sha256(label: str) -> str:
    return hashlib.sha256(label.encode("utf-8")).hexdigest().upper()


def deterministic_jitter(seed: str, spread: float) -> float:
    """Deterministic pseudo-random value in [-spread, spread], avoiding a real RNG dependency."""
    digest = hashlib.sha256(seed.encode("utf-8")).hexdigest()
    fraction = (int(digest[:8], 16) % 10000) / 10000.0
    return (fraction * 2 - 1) * spread


# ---------------------------------------------------------------------------
# Per-dossier size/file/folder distribution (proportional to sequence count,
# with deterministic jitter so numbers are not perfectly even)
# ---------------------------------------------------------------------------
def build_dossier_profiles():
    total_sequences = SOURCE_PROFILE["sequenceCount"]
    profiles = {}
    running_files = 0
    running_folders = 0
    running_size = 0.0
    for index, (dossier_id, name, region, fmt, dtype, seq_count) in enumerate(DOSSIERS):
        share = seq_count / total_sequences
        is_last = index == len(DOSSIERS) - 1
        jitter = 1 + deterministic_jitter(dossier_id + "-files", 0.18)
        files = round(SOURCE_PROFILE["fileCount"] * share * jitter)
        jitter_f = 1 + deterministic_jitter(dossier_id + "-folders", 0.15)
        folders = round(SOURCE_PROFILE["folderCount"] * share * jitter_f)
        jitter_s = 1 + deterministic_jitter(dossier_id + "-size", 0.22)
        size_gb = round(SOURCE_PROFILE["exportSizeGB"] * share * jitter_s, 2)
        if is_last:
            files = SOURCE_PROFILE["fileCount"] - running_files
            folders = SOURCE_PROFILE["folderCount"] - running_folders
            size_gb = round(SOURCE_PROFILE["exportSizeGB"] - running_size, 2)
        else:
            running_files += files
            running_folders += folders
            running_size += size_gb
        profiles[dossier_id] = {
            "fileCount": max(files, seq_count * 4),
            "folderCount": max(folders, seq_count),
            "sizeGB": max(size_gb, 0.05),
        }
    return profiles


DOSSIER_PROFILES = build_dossier_profiles()


def dossier_path(dossier_id: str, name: str) -> str:
    return rf"{PROJECT['primarySourceRoot']}\{dossier_id}_{name}"


def sequence_number(fmt: str, index: int) -> str:
    if fmt in ("NeeS legacy", "Legacy export transitioning to eCTD"):
        return f"{index:04d}"
    return f"{index:04d}"


def build_sequences_for_dossier(dossier_id, name, region, fmt, dtype, seq_count):
    """Generate a realistic sequence history for one dossier spanning 2012-2026."""
    sequences = []
    span_start_year = 2012 + int(deterministic_jitter(dossier_id + "-start", 4)) + 4
    span_start_year = max(2012, min(span_start_year, 2023))
    total_days = int((datetime(2026, 6, 1) - datetime(span_start_year, 1, 15)).days)
    base_path = dossier_path(dossier_id, name)
    for i in range(seq_count):
        seq_num = sequence_number(fmt, i)
        offset_days = int(total_days * (i / max(seq_count - 1, 1)))
        jitter_days = int(deterministic_jitter(f"{dossier_id}-{seq_num}", 25))
        seq_date = datetime(span_start_year, 1, 15) + timedelta(days=offset_days + jitter_days)
        seq_date = min(seq_date, datetime(2026, 6, 1))
        file_count = max(3, round(12 * (1 + deterministic_jitter(f"{dossier_id}-{seq_num}-fc", 0.6))))
        folder_count = max(1, round(file_count / 6))
        size_mb = round(max(1.5, 45 * (1 + deterministic_jitter(f"{dossier_id}-{seq_num}-sz", 0.7))), 1)
        sequences.append({
            "dossierId": dossier_id,
            "sequenceId": f"{dossier_id}-SEQ-{seq_num}",
            "sequenceDisplayName": f"Sequence {seq_num}",
            "sequencePath": rf"{base_path}\{seq_num}",
            "technicalStandard": TECHNICAL_STANDARD_BY_FORMAT[fmt],
            "regionalImplementation": REGIONAL_IMPLEMENTATION_BY_REGION[region],
            "sizeBytes": int(size_mb * 1024 * 1024),
            "displaySizeMB": size_mb,
            "fileCount": file_count,
            "folderCount": folder_count,
            "submittedDateUtc": seq_date.strftime("%Y-%m-%d"),
        })
    return sequences


ALL_SEQUENCES = []
for dossier_id, name, region, fmt, dtype, seq_count in DOSSIERS:
    ALL_SEQUENCES.extend(build_sequences_for_dossier(dossier_id, name, region, fmt, dtype, seq_count))

assert len(ALL_SEQUENCES) == 243


def write_json(path: Path, payload) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    seed = {
        "project": PROJECT,
        "sourceProfile": SOURCE_PROFILE,
        "fileTypeDistribution": FILE_TYPE_WEIGHTS,
        "dossiers": [
            {
                "dossierId": d[0], "name": d[1], "region": d[2], "format": d[3],
                "type": d[4], "sequenceCount": d[5],
                "path": dossier_path(d[0], d[1]),
                "profile": DOSSIER_PROFILES[d[0]],
                "preSalesRag": "Red" if d[0] in RED_DOSSIERS else ("Amber" if d[0] in AMBER_DOSSIERS else "Green"),
            }
            for d in DOSSIERS
        ],
        "sequences": ALL_SEQUENCES,
        "disclosure": DISCLOSURE,
        "timeline": {
            "preSalesAssessmentUtc": PRESALES_DATE.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "migrationReadinessAssessmentUtc": PREMIGRATION_DATE.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "postMigrationVerificationUtc": POSTMIGRATION_DATE.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
    }
    write_json(HERE / "aurelis-demo-input.json", seed)
    print(f"Wrote {HERE / 'aurelis-demo-input.json'} ({sum(d[5] for d in DOSSIERS)} sequences across {len(DOSSIERS)} dossiers)")


if __name__ == "__main__":
    main()
