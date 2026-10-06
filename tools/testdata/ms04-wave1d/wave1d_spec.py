"""Declarative specification of the MS-04 Wave1D dossier-diversity fixtures.

This module is the single description of *what* each fixture is: its purpose,
source profile(s), the container/path transformation and any unrelated
synthetic content. It contains no expected scanner results.

It is imported by:
- build_wave1d.py          (builds the fixture ZIPs)
- derive_expectations.py   (transform derivation from accepted Wave 1 expectations)

oracle_wave1d.py deliberately does NOT import it: the oracle derives its facts
from the built ZIP bytes alone.
"""

from __future__ import annotations

WAVE1_ARCHIVE_ROOT = "EXTEDORIN 50mg Tablets EU-FR"

# Wave 1 ZIP convention (see .wave1-work/build_wave1.py): fixed entry time,
# explicit stored directory entries sorted by depth then name, deflated files
# sorted by name, Unix permission attributes.
FIXED_ZIP_TIME = (2026, 10, 4, 12, 0, 0)

# Fixed metadata so a rebuild is byte-for-byte reproducible.
BUILD_RECIPE_VERSION = "wave1d-builder/1.0"
BUILD_DATE = "2026-10-06"

SOURCE_FIXTURES = ("SD-002", "SD-010")

# Clearly synthetic, non-regulatory bytes for unrelated content.
SYNTHETIC_PDF = (
    b"%PDF-1.4\n"
    b"% eMAS Wave1D synthetic unrelated placeholder. Not a regulatory document.\n"
    b"%%EOF\n"
)
SYNTHETIC_TEXT = b"eMAS Wave1D synthetic unrelated text file. Not part of any dossier.\n"
# Decoy at an m1/eu/eu-regional.xml-shaped path outside any dossier. Deliberately
# NOT regional backbone vocabulary (TASK.md: do not invent regulatory XML).
SYNTHETIC_DECOY_XML = (
    b'<?xml version="1.0" encoding="UTF-8"?>\n'
    b"<note>eMAS Wave1D synthetic decoy outside any dossier. Not a backbone.</note>\n"
)

# Each dossier: (root path inside the ZIP, source fixture). Root "" means the
# sequences sit directly at the archive root.
FIXTURES = [
    {
        "sampleId": "SD-044",
        "kind": "Normative",
        "purpose": "Neutral dossier root ProductABC; removes dependence on the historical EXTEDORIN/EU-FR dossier name.",
        "dossiers": [("ProductABC", "SD-002")],
        "extraFiles": {},
        "mutation": "Re-rooted SD-002 dossier from 'EXTEDORIN 50mg Tablets EU-FR/' to 'ProductABC/'.",
    },
    {
        "sampleId": "SD-045",
        "kind": "Normative",
        "purpose": "Misleading dossier root FDA-US-ASMF; folder text must not alter structured evidence. ASMF stays DossierContext text.",
        "dossiers": [("FDA-US-ASMF", "SD-002")],
        "extraFiles": {},
        "mutation": "Re-rooted SD-002 dossier to 'FDA-US-ASMF/'.",
    },
    {
        "sampleId": "SD-046",
        "kind": "Normative",
        "purpose": "Neutral wrappers CustomerExport/ArchiveSet/ProductABC; wrapper depth and names must not alter dossier-relative evidence.",
        "dossiers": [("CustomerExport/ArchiveSet/ProductABC", "SD-002")],
        "extraFiles": {},
        "mutation": "Re-rooted SD-002 dossier to 'CustomerExport/ArchiveSet/ProductABC/'.",
    },
    {
        "sampleId": "SD-047",
        "kind": "Normative",
        "purpose": "Asymmetric multi-dossier repository (ProductABC = SD-002 profile, ProductXYZ = SD-010 profile); no cross-dossier leakage.",
        "dossiers": [("ProductABC", "SD-002"), ("ProductXYZ", "SD-010")],
        "extraFiles": {},
        "mutation": "SD-002 dossier re-rooted to 'ProductABC/' plus SD-010 dossier re-rooted to 'ProductXYZ/'.",
    },
    {
        "sampleId": "SD-048",
        "kind": "Normative",
        "purpose": "Valid dossier plus unrelated PDFs/XML/text outside valid sequence structure; none may become dossier evidence.",
        "dossiers": [("ProductABC", "SD-002")],
        "extraFiles": {
            "README.txt": SYNTHETIC_TEXT,
            "Customer Notes/meeting-notes.pdf": SYNTHETIC_PDF,
            "Archive/old-export-log.txt": SYNTHETIC_TEXT,
            "Misc/m1/eu/eu-regional.xml": SYNTHETIC_DECOY_XML,
            "ProductABC/Working Notes/todo.txt": SYNTHETIC_TEXT,
            "ProductABC/Working Notes/scan.pdf": SYNTHETIC_PDF,
        },
        "mutation": "SD-044 layout plus six synthetic unrelated files (no four-digit folder names), including a decoy Misc/m1/eu/eu-regional.xml.",
    },
    {
        "sampleId": "SD-049",
        "kind": "Normative",
        "purpose": "Safe ASCII naming variation 'Product ABC (Copy 2) & Co_v1.2'; spaces and portable punctuation must not break path handling.",
        "dossiers": [("Product ABC (Copy 2) & Co_v1.2", "SD-002")],
        "extraFiles": {},
        "mutation": "Re-rooted SD-002 dossier to 'Product ABC (Copy 2) & Co_v1.2/'.",
    },
    {
        "sampleId": "SD-050",
        "kind": "Normative",
        "purpose": "Dossier at the archive root (sequences directly at root); locks in the accepted empty-root semantics from the root-level dossier fix.",
        "dossiers": [("", "SD-002")],
        "extraFiles": {},
        "mutation": "Removed the SD-002 dossier folder; sequences 0000-0004 sit at the ZIP root.",
    },
    {
        "sampleId": "SD-051",
        "kind": "Characterization",
        "statusLabel": "CHARACTERIZATION_PENDING_DISCOVERY_DECISION",
        "purpose": "Valid dossier plus unrelated year folder Archive/2019/; characterizes the current four-digit-folder discovery heuristic without changing RepositoryDiscovery.",
        "dossiers": [("ProductABC", "SD-002")],
        "extraFiles": {"Archive/2019/annual-report.pdf": SYNTHETIC_PDF},
        "mutation": "SD-044 layout plus synthetic Archive/2019/annual-report.pdf.",
    },
]

FIXTURE_IDS = [fixture["sampleId"] for fixture in FIXTURES]


def join_root(root: str, relative: str) -> str:
    """Join a dossier root and a dossier-relative path ('' root = archive root)."""
    return relative if root == "" else f"{root}/{relative}"
