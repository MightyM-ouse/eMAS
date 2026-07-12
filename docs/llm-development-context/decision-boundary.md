# LLM Decision Boundary

This context file prevents AI-assisted development from silently converting recommendations or open questions into approved eMAS requirements.

## Mandatory rules

- Treat approved repository requirements and architecture as the current implementation baseline.
- Treat decision-register AI columns as proposals and supporting evidence only.
- Do not populate or infer the user's final decision.
- Cite the applicable decision-register Item ID when work depends on an unresolved topic.
- Stop and request a decision when an unresolved topic changes runtime behavior, report meaning, regulatory interpretation, schema compatibility, release acceptance or customer-facing terminology.
- Do not modify mapping content, runtime JSON, PowerShell business interpretation or report outcomes solely because an AI recommendation exists.
- Do not resolve conflicts by choosing the newest file, the longest document or the most specific example unless an approved authority rule permits it.

## Allowed work before a decision

An LLM may:

- identify conflicts;
- summarize evidence;
- present alternatives;
- propose a recommendation;
- draft a non-authoritative example;
- prepare acceptance criteria;
- identify impacted documents and tests;
- implement technical scaffolding that does not determine the unresolved behavior.

## Prohibited work before a decision

An LLM must not:

- label a proposal as approved;
- invent regulatory rules or authority relationships;
- choose effort weights or thresholds;
- choose exception approvers or approval evidence;
- define a breaking JSON contract;
- hardcode unresolved business meaning in PowerShell;
- alter observed findings to reflect an exception;
- collapse evaluation status and RAG;
- publish internal controlled artifacts to a public repository.

## Required response when blocked

State:

1. the blocking Item ID;
2. the unresolved question;
3. the relevant evidence and conflict;
4. the recommended decision;
5. the alternatives;
6. the downstream impact;
7. the exact user or SME decision required.
