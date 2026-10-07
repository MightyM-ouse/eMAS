# Codex launch

Work on task:

`EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE`

Repository:

`MightyM-ouse/eMAS`

Read first:

1. `docs/internal/agent-workflow/AGENT_WORKFLOW.md`
2. `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/TASK.md`
3. `docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/STATUS.md`
4. the accepted T1b design report and central review referenced by TASK.md.

Use branch:

`implementation/emas-ms04-regional-xml-evidence-t1b-eu-envelope`

Authoritative base:

`e9530adb6f2e8b31035ca27f7267d6a2de25081d`

The implementation branch is expected to descend from the coordination branch after the formal task-order files were added.

This is a bounded implementation task, not a design task.

Implement exactly the accepted five EU regional-envelope facts for EU M1 profiles 2.0 / 3.0.1 / 3.1 through the existing BackboneXmlInventory parse and CEC factual projection.

Do not:
- perform a second XML parse;
- let CEC reopen XML;
- add new CEC Dimension codes;
- modify T4/IdentificationInterpretation;
- implement projection v2;
- normalize regulatory values;
- broaden to other EU profiles or regions;
- change historical CEC record shape/EvidenceIds;
- modify frozen fixture bytes;
- merge.

Before editing, run and record the baseline gates required by TASK.md.

After implementation, run the focused and regression/re-qualification gates required by TASK.md.

Publish:

`docs/internal/agent-tasks/EMAS-MS04-REGIONAL-XML-EVIDENCE-T1B-EU-ENVELOPE/reports/CODEX.md`

Open a **draft PR into**:

`coordination/emas-ms04-regional-xml-evidence-t1b-design`

Return:
- branch;
- authoritative base SHA;
- final commit SHA;
- draft PR number/link;
- files changed;
- focused test result;
- BXI/CEC regression results;
- Wave 1 / Wave1D results;
- T4 regression/oracle results;
- Windows PS5.1 evidence status;
- historical EvidenceId compatibility result;
- source read-only/hash result;
- blocker/open issue list.

Do not merge.
