# Repository-Native Agent Workflow

The GitHub repository is the durable source of truth for agent assignments, reports, reviews, and handoffs.

Each task must record its task ID, base commit SHA, scope, assigned roles, allowed files, forbidden files, expected deliverables, validation requirements, and status.

Agents read this operating contract, their assigned `TASK.md`, and only the additional files needed for that assignment. Use the smallest context that safely supports the work. Do not expand scope.

## Ownership and isolation

- An agent may update only its assigned deliverables and must not alter another agent's report.
- Planning and review tasks are report-only unless `TASK.md` explicitly authorizes implementation.
- Each implementation owner uses a dedicated branch or worktree. Two implementation agents must not edit the same files concurrently.
- Reviewers inspect a fixed commit SHA and remain read-only except for their own report.

## Git and approval controls

- No agent automatically merges, pushes to a protected or main branch, merges a pull request, or approves on the user's behalf.
- An agent may commit and push a dedicated branch only when `TASK.md` explicitly requires it.
- User approval is required before implementation is accepted into the baseline.
- Every completed result must be persisted at the repository path assigned by `TASK.md`.
- ChatGPT reconciles cross-agent results from the repository; the user should not need to copy reports between agents.
