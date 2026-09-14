---
name: plane-work-management
description: Manage Plane projects, work items, epics, cycles, modules, states, labels, and delivery workflow through Plane MCP tools. Use when creating, updating, organizing, querying, or completing work tracked in Plane.
---

# Plane Work Management

Use the available Plane MCP tools for all Plane reads and writes.

## Policy Resolution

Before changing Plane data:

1. Find the current Git worktree root.
2. Read `AGENTS.md` and nested agent-instruction files when present.
3. Apply this skill as the default workflow. Apply explicit repository instructions as overrides for project selection, naming, states, modules, required metadata, validation commands, and Definition of Done.
4. Ask one focused question when the target project or a required repository-specific value remains ambiguous.

## Work Item Design

- Represent one business need or independently observable outcome with one main work item.
- Keep the main backlog about outcomes, not technical layers, files, tests, implementation decisions, or acceptance cases.
- Create a child only when it can be assigned, implemented, reviewed, or tracked independently, or needs its own state.
- Keep durable implementation constraints, expected affected areas, acceptance examples, and required tests in the main item.
- Write for a contributor who has no access to prior conversations. Define business terms and avoid claims such as "works correctly".
- Use observable Given/When/Then acceptance scenarios when they improve clarity.

The description is the durable contract for work that remains understandable before execution. Keep objectives, context, expected behavior, scope, exclusions, acceptance criteria, known constraints, and required validation there. Do not put progress, narrative status, executed commands, observed results, test counts, discoveries, decisions made during execution, or completion evidence in the description; record them as comments.

For parent and child work items, keep detailed execution evidence on the item that performed the work. Use the parent for cross-child synthesis, aggregate risks, the final decision, and follow-up work. Never use a parent comment as the only execution record for a child.

For spikes, keep the question, hypotheses, planned experiment, scope, and success criteria in the description. Record observations, evidence, results, limitations, conclusions, and recommendations as comments.

Use this structure when applicable:

```markdown
## Objective

## Context

## Expected behavior
1. ...

## Scope
- ...

## Acceptance criteria
### Scenario: name
Given ...
When ...
Then ...

## Implementation notes
- ...

## Definition of Done
- Required tests and checks, phrased as work to perform rather than results already obtained.
- Repository Definition of Done satisfied.
```

## Safe Workflow

1. Resolve human names and identifiers to Plane UUIDs with list, search, or retrieve tools before writes.
2. Read the target object before updating or deleting it.
3. Use `get_pql_reference` before composing non-trivial PQL filters.
4. Make the smallest requested mutation. Preserve unrelated fields and relationships.
5. Read the result back after writes. Report identifiers, changed fields, and any validation gap.

## Work Items And Epics

- Use work item tools for issues, tasks, and epics.
- Resolve the `Epic` work item type in the selected project instead of assuming a type ID.
- Use the parent relationship required by local policy. Never assume a fixed hierarchy.
- Resolve states, labels, assignees, cycles, modules, milestones, estimates, and custom properties by current Plane data.

## State Flow

- Prefer `Backlog -> Todo -> In Progress -> Review & Test -> Done` when those states exist and local policy does not define another flow.
- Move a work item from `Review & Test` to `Changes Requested` when review finds actionable corrections. Record the findings and required validation before changing the state.
- Keep the item in `Changes Requested` until the assignee confirms they have started the corrections; then move it to `In Progress`.
- Move corrected work from `In Progress` back to `Review & Test`. Never treat `Changes Requested` as active implementation.
- Treat `Blocked` as a pause from active work. Record the cause, unblock owner, and next action. Return to the appropriate active state after unblocking.
- Do not use `Blocked` merely because review found defects. Use it only when an external impediment or unresolved dependency prevents progress.
- Use `Cancelled` only for discarded work and record the reason.
- Never move directly from active implementation to `Done`. Require a review or validation state first.
- When validation fails with actionable corrections, use `Changes Requested`. When evidence is inconclusive, keep `Review & Test` while investigating; use `Blocked` only for a documented impediment.

## Completion

Before marking work complete:

- Demonstrate the acceptance criteria.
- Run the repository's required tests and checks.
- Confirm no known silent failures, exposed credentials, PII, or sensitive payloads.
- Confirm external mutations are protected against duplicates and blind retries when applicable.
- Complete code review and functional validation.
- Apply additional repository Definition of Done requirements.
- Request explicit confirmation when completion evidence or approval is unavailable.

Do not hardcode project names, identifiers, modules, state UUIDs, labels, or repository-specific commands in this skill.
