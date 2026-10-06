# Authoritative Source Starter — eCTD v4 Discovery Design

This is a starter list, not a substitute for Claude verifying the latest applicable versions and exact sections.

## ICH

### ICH electronic Common Technical Document - eCTD v4.0

Current ICH eCTD v4.0 landing page. As of October 2026 it identifies the current ICH eCTD v4.0 Implementation Guide as v1.7, endorsed June 2026.

https://admin.ich.org/page/ich-electronic-common-technical-document-ectd-v40

Use the current Implementation Guide package linked from this page.

### ICH eCTD v4.0 support documentation

Review the current support documentation sections covering Submission Contents / Folder and File Structure.

The support material describes the eCTD folder as the sequence number, with examples such as `1`, `2`, and identifies `submissionunit.xml` and `sha256.txt` in the submission-unit contents.

Use the current support document linked from the ICH v4 page and record exact version/page in the report.

## FDA

### eCTD Submission Standards for eCTD v4.0 and Regional M1

https://www.fda.gov/drugs/electronic-regulatory-submission-and-review/ectd-submission-standards-ectd-v40-and-regional-m1

As of September 2026 the page lists the current FDA Regional eCTD v4.0 Module 1 Implementation Guide and current validation/conformance material.

### FDA Regional eCTD v4 material

Current FDA implementation documentation states that the Sequence Number Folder is named with the actual value of the submission-unit sequence number, for example `1`.

A currently accessible FDA regional implementation PDF is:

https://www.fda.gov/media/179721/download

Claude must verify whether a newer linked current version supersedes this PDF and cite the applicable version/section.

## EU / EMA

### EU eCTD v4 project/documentation page

https://esubmission.ema.europa.eu/eCTD%20NMV/eCTD.html

Use the current EU implementation guide, validation criteria and controlled-vocabulary references linked there.

### EU eCTD v4.0 Practical Guidance

https://esubmission.ema.europa.eu/eCTD%20NMV/docs/EU%20eCTD%20v4.0%20Practical%20Guidance%20v1.pdf

The current practical guidance describes a first-level folder, a second-level folder/submission-unit content, `submissionunit.xml`, `sha256.txt`, and module folders.

Claude must verify exact semantics of the first and second levels and whether the guidance is normative, recommended practice, or region-specific packaging guidance.

## Source-use rules

- Prefer the latest official version supported/required by the regulator.
- Record exact version and section/page.
- If an older official source is still supported, distinguish "current supported", "previous supported", and "historical".
- Do not use vendor blogs to establish normative structure.
- Do not infer FDA rules for EU or EU rules for FDA.
