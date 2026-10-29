---
name: plane-work-management
description: Manage Plane projects, work items, epics, cycles, modules, states, labels, and delivery workflow through Plane MCP tools. Use when creating, updating, organizing, querying, or completing work tracked in Plane.
---

# Plane Work Management

Use the available Plane MCP tools for all Plane reads and writes.

## Ownership And Mutation Authority

- The primary `build` agent owns every Plane mutation. It is the only agent authorized to create, update, transition, link, comment on, or delete Plane data.
- Subagents do not synchronize Plane independently. `general` and `explore` may read Plane and must report the evidence, identifiers, and recommended changes back to `build`; they must not call mutating Plane tools.
- `reviewer` is strictly read-only and cannot call Plane tools. It verifies the frozen Plane evidence supplied by `build` and reports findings; it never reads from or writes to Plane directly.
- When a subagent is asked to change Plane, it returns the intended change plus its evidence to `build`, which applies it.

## Advisory Versus Execution Mode

Classify the request before acting:

- Advisory (read-only) mode: the user asks for analysis, explanation, a plan, options, a review, or a recommendation. Perform only reads. Do not create, update, transition, comment on, link, or delete anything, even when the change looks obvious. Present findings and a proposed change set.
- Execution mode: the user explicitly asks to create, update, transition, organize, or complete Plane work. Apply the Safe Workflow below.

If intent is ambiguous, default to advisory and ask one focused question before any write.

## Policy Resolution

Before changing Plane data:

1. Apply this skill as the default workflow.
2. When the work is tied to a repository, find the current Git worktree root and read `AGENTS.md` and nested agent-instruction files when present. Pure Plane administration that has no repository context does not require Git inspection; skip it instead of inventing a project.
3. Apply explicit repository instructions as overrides for project selection, naming, states, modules, required metadata, validation commands, and Definition of Done.
4. Ask one focused question when the target project or a required repository-specific value remains ambiguous.

## Safe Workflow

1. Resolve human names and identifiers to Plane UUIDs with list, search, or retrieve tools before writes. Never invent a UUID.
2. Read the target object before updating or deleting it.
3. Use `get_pql_reference` before composing non-trivial PQL filters.
4. Make the smallest requested mutation. Preserve unrelated fields and relationships. Send only the fields you intend to change.
5. Read the result back after writes. Report identifiers, changed fields, and any validation gap.

## Confirmation Requirements

Request explicit confirmation before any destructive or broad operation, including:

- deleting or archiving projects, work items, comments, links, attachments, or definitions;
- bulk or batch mutations, and any change that touches many work items or every project;
- moving or re-linking work across projects, cycles, modules, or initiatives;
- marking work `Done` or `Cancelled`;
- accepting, deferring, or dismissing a material review finding;
- creating workspace-scoped types, states, or properties when a narrower scope was requested.

State the exact objects and effect, then wait for the confirmation. Do not treat a general request as blanket authorization for destructive actions.

## HTML Fields And Mentions

Plane stores rich text as HTML, not Markdown:

- `description_html` (work item, project, initiative, page, and other rich-text fields) and `comment_html` must contain HTML markup such as `<p>`, `<ul>`, `<li>`, `<strong>`, and `<code>`. Markdown text will not render as intended.
- Read `description_stripped` or the rendered text to inspect existing content; write `description_html` when changing it.
- Mentions reference a project member by UUID, not by display name. Resolve the member's UUID first with `member list_project`, then write `@[<user-uuid>]` inside `comment_html`. A bare `@name` is ordinary text and sends no notification.
- Keep credentials, tokens, PII, and sensitive payloads out of HTML fields, comments, and links.

## Work Items And Epics

- Use work item tools for issues, tasks, and epics.
- Resolve the `Epic` work item type in the selected project instead of assuming a type ID.
- Treat `workitem_type resolve` as potentially mutating: it finds a type or creates it when missing. Inspect existing types first (`workitem_type list` / `retrieve`), and only resolve, import, or create a type when there is a real need and explicit authorization. Prefer reusing an existing type.
- Use the parent relationship required by local policy. Never assume a fixed hierarchy.
- Resolve states, labels, assignees, cycles, modules, milestones, estimates, and custom properties by current Plane data.

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

When writing this structure, convert it to HTML for `description_html` and write checkpoint records as HTML for `comment_html`.

## State Flow

- Prefer `Backlog -> Todo -> In Progress -> Review & Test -> Done` when those states exist and local policy does not define another flow.
- Before active work starts, resolve and add the human doing the work as an assignee without removing existing assignees, set the actual start date only when empty, move the item to `In Progress`, and read back all three values. Ask if the human is ambiguous or addition would require replacing an assignee.
- Move a work item from `Review & Test` to `Changes Requested` when review findings are accepted for correction. Before correcting anything, record the accepted findings and required validation plus the decision and brief reason for every material finding deferred or dismissed.
- Treat that review comment and transition as one logical checkpoint. Reconcile a partial write before continuing; never silently transition without the traceability comment.
- Keep the item in `Changes Requested` until corrections actually start; then resolve and add the human performing them without removing existing assignees, preserve the original start date, move it to `In Progress` without requiring another confirmation, and read back the assignees, date, and state.
- Move corrected work from `In Progress` back to `Review & Test`. Never treat `Changes Requested` as active implementation.
- Treat `Blocked` as a pause from active work. Record the cause, unblock owner, and next action. Return to the appropriate active state after unblocking.
- Do not use `Blocked` merely because review found defects. Use it only when an external impediment or unresolved dependency prevents progress.
- Use `Cancelled` only for discarded work and record the reason.
- Never move directly from active implementation to `Done`. Require a review or validation state first.
- When moving to `Done` after explicit confirmation, record or verify the actual completion date. Use an automatically generated completion timestamp when Plane provides one; never substitute `target_date` or another planning field.
- When validation fails with actionable corrections, use `Changes Requested`. When evidence is inconclusive, keep `Review & Test` while investigating; use `Blocked` only for a documented impediment.

Resolve states from the actual project workflow. Suggested state names in this skill are preferences only. If a preferred state does not exist, choose the closest existing state or ask; never create a missing state automatically.

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
