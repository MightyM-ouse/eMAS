# MS-04 regional backbone recognition

Status: implementation note for the user-authorized Phase 2 correction, 2026-10-09.
Baseline: `ef0dc9205ada01d8868f86c171a7fbd174c7756b`.

## Compatibility check before source edits

The accepted T1b task permits optional BXI-owned metadata under
`eMAS.MS04.PreSales.ScannerObservations/1.0` (its existing `RegionalEnvelope`
extension). The current BXI, CEC, ReferenceInventory, SUXI and T4 consumers
validate the contract identifier and named fields, not a closed XML-document
property set. They preserve upstream optional properties through JSON copies.
The closed schema in the T4 oracle governs the separate Identification result,
not ScannerObservations. The runtime configuration schema is also a separate
contract. Neither schema requires or permits an edit for this correction.

The current user explicitly authorized the proposed optional metadata subject
to this compatibility check. The addition therefore keeps ScannerObservations
1.0, existing required fields and status vocabularies, and projection v1.
It does not amend the controlled T4 contract, or its golden oracle. This note
records the observable scanner expansion openly; it is not a replacement for
any external controlled scanner/package specification. Package requalification
against external specifications remains required before release.

## Physical candidates and XML recognition

`XmlKind=RegionalBackbone` continues to describe a canonical physical candidate,
including missing or malformed XML, as it did for EU. It is not proof of a
regional implementation. Only `RegionalRecognition.RecognitionStatus=Matched`
corroborates a canonical path with the exact root local-name and namespace URI.

| Physical path relative to exact v3 sequence | Technical family | Root local-name | Namespace URI |
|---|---|---|---|
| `m1/eu/eu-regional.xml` | `EU_M1` | `eu-backbone` | `http://europa.eu.int` |
| `m1/us/us-regional.xml` | `US_M1` | `fda-regional` | `http://www.ich.org/fda` |

US signature and reference shape source: FDA [Module 1 specification](https://www.fda.gov/media/159382/download), introduction, sections II and V and Appendix 1.
Paths use case-insensitive whole-path comparison for Windows, retain actual
source paths, and never use basename matching to declare recognition.

Optional `XmlDocuments[].RegionalRecognition` fields:

- `PathProfileFamily`: canonical technical path family, or null.
- `XmlProfileFamily`: exact parsed root/namespace family, or null.
- `RecognitionStatus`: `Matched`, `PathXmlMismatch`, `UnrecognizedStructure`,
  `UnsupportedPath`, `AmbiguousPath`, or `NotAttempted`.
- `ExtractionSupport`: `Supported`, `UnsupportedProfile`, `NotImplemented`,
  or `NotAttempted`. This refers only to envelope extraction, never validation.

This object appears on canonical regional candidates and direct regional-name
XML candidates under `m1/<folder>/`; other XML shape and common backbones stay
unchanged. Unknown paths remain `Other`, including known roots in the wrong
location. Unsupported regional coverage records the limitation without an
interpretation rule. Root attributes and declarations remain raw observations.

EU profiles 2.0, 3.0.1 and 3.1 retain their existing helper and evidence.
US envelope extraction is explicitly `NotImplemented`; it never invokes the EU
helper. The declared FDA DTD version is not an ICH technical standard version.

## Missing paths, ordering and consumers

Legacy absent-EU records remain factual compatibility probes. US missing
descriptors are added only when discovery actually observed `m1/us`.
All XML descriptors retain deterministic global path order. New missing-US
rows may shift subsequent XML ordinals; existing US files already had Other
rows and do not add ordinals. EU-only XML ordinals remain unchanged.
Each added missing-US observation may also shift later BXI observation
ordinals. Discovery dossier, sequence and file IDs remain unchanged. Missing
US descriptors produce no leaf references, so they do not add REF ordinals;
reference joins to shifted XML IDs follow the new inventory.

New US CEC facts use internal sort group 4, after existing groups 0–3.
Existing EU evidence ordering/IDs are preserved; joins to XML IDs may change
when a new missing-US descriptor enters the inventory. EU-specific fields
are not checked on US documents. No canonical Region or Authority is assigned.

T4 remains scalar: multiple regional values are `AmbiguousProjection`.
SUXI, v4 facts and projection v1 remain unchanged. Optional ReferenceInventory
uses the existing unqualified leaf/XLink selector only for matched US DTD 3.3
documents; other new US structures get explicit uncollected coverage rather
than an invented reference profile. Legacy EU reference handling is unchanged.
The FDA appendix fixes the XLink URI to `http://www.w3c.org/1999/xlink`,
matching the existing selector; no namespace fallback is introduced.
Scanner implementation versions become BXI 0.4.0, RI 0.4.0 and CEC 0.12.0
(0.13.0 when SubmissionUnitXmlInventory is included).

## Verification and release boundary

Independent synthetic tests exercise EU, US, mixed, missing, malformed,
unsupported, multi-sequence, traceability, ordering and optional deep checks.
Existing fixtures, oracles, expectations and schemas are not changed.
The native PS5.1 T1b summary fix only reads OS metadata defensively.
Exact commands/results and unavailable external Wave1/Wave1D gates belong in
the Phase 2 handover. This correction requires package checksum updates and
full qualification before release; no frozen qualification manifest is edited.
