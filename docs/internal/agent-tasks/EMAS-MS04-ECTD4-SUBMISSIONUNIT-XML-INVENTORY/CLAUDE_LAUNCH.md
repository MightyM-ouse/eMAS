# Claude Launch — T2 SubmissionUnit XML Inventory Design

Work on task:

EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY

Repository:

MightyM-ouse/eMAS

Authoritative base:

09c6e3bbb37f9811e045214cfb6b9bb575ce669e

Coordination branch:

coordination/emas-ms04-ectd4-submissionunit-xml-inventory

Read completely:

- docs/internal/agent-workflow/AGENT_WORKFLOW.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/TASK.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/SOURCES.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/STATUS.md

Then read only the accepted repository and official-source material required by
the task.

## Assignment

You are the primary T2 regulatory research and architecture-design worker.

Produce a source-backed design for a separate optional
SubmissionUnitXmlInventory capability and its factual CEC publication.

You must investigate the official eCTD v4 submissionunit.xml structure rather
than relying on memory or prior AI summaries. Verify exact namespaces,
elements, attributes, OIDs, identifierName values, code systems, cardinalities,
profile/version markers, application/submission/submission-unit semantics,
lifecycle relationships, compatibility, and failure behavior.

Keep factual collection separate from interpretation. Do not invent regulatory
semantics, code meanings, OIDs, aliases, or lifecycle relationships.

## Branch and PR

Create branch:

analysis/emas-ms04-ectd4-submissionunit-xml-inventory-design

from the exact coordination branch head supplied at launch time. Before writing
the report, record:

- git rev-parse HEAD;
- git merge-base HEAD origin/coordination/emas-ms04-ectd4-submissionunit-xml-inventory;
- git status --short.

If the branch does not descend from the expected authoritative base and current
coordination task commit, stop and report the mismatch.

Open a draft PR into:

coordination/emas-ms04-ectd4-submissionunit-xml-inventory

Do not merge.

## Allowed deliverables

Modify only:

- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/reports/CLAUDE.md
- docs/internal/agent-tasks/EMAS-MS04-ECTD4-SUBMISSIONUNIT-XML-INVENTORY/STATUS.md

Do not modify task instructions, sources index, workflow rules, production
code, tests, fixtures, schemas, configuration, T4/projection, rule packs,
workbooks, reports, UI, or another agent's files.

## Required output quality

The report must satisfy every acceptance criterion in TASK.md and include:

- exact official source ledger with live version/status verification;
- namespace-aware XML structure and field/cardinality table;
- current/historical/draft/unknown profile matrix;
- explicit application/submission/submission-unit/lifecycle distinctions;
- deterministic failure/status matrix;
- architecture option comparison and one bounded recommendation;
- exact ScannerObservations object-shape proposal;
- BXI and CEC impact with historical compatibility protection;
- explicit T4/projection deferral decision;
- future source-traceable fixture plan;
- exact proposed later implementation allowlist;
- unresolved conflicts and user/SME decisions.

## Stop conditions

Stop and report rather than guess if:

- an official source cannot be accessed or its version/status cannot be
  verified;
- an exact XML path or code-system meaning is not supported by an official
  artifact;
- current FDA and EU material conflicts without an authoritative resolution;
- the task would require internal/confidential sample data;
- a contract or projection change appears necessary outside this design scope;
- the coordination head moves after your branch point.

## Return to the coordinator

Return only:

- branch name;
- commit SHA;
- draft PR number/link;
- report path;
- authoritative base and coordination parent SHA;
- official source versions/statuses used;
- one-sentence architecture recommendation;
- proposed factual evidence types/count;
- ScannerObservations compatibility conclusion;
- T4/projection deferral conclusion;
- unresolved source conflicts or blocking decisions.

Codex must not be launched from this task. After fixed-SHA central review and a
new explicit user design decision, the coordinator may create a separate
bounded Codex implementation task.
