---
name: plane-workitem-development
description: Develop, fix, test, review, or open a PR for a Plane work item while keeping its state, progress comments, and PR links synchronized. Use when starting or resuming implementation tied to Plane, addressing requested changes, reporting a blocker, handing work off for review, or finishing merged work.
---

# Plane Work Item Development

Keep Plane synchronized with work that actually happened. Use the available Plane MCP tools for all Plane reads and writes. Use `plane-work-management` for creating or redesigning work items; this skill governs execution after a work item exists.

## Resolve Context

Before editing code or changing Plane:

1. Find the Git worktree root and read applicable `AGENTS.md` and nested repository instructions.
2. Resolve the work item identifier to its project and UUID. Read its description, state, assignees, comments, activity, and external links.
3. Inspect the repository, current branch, local changes, and existing PR when available. Never infer progress solely from the Plane state.
4. Compare acceptance criteria and Definition of Done with the current implementation. Continue from existing evidence instead of repeating completed work.
5. Ask one focused question when multiple work items are plausible, the requested work conflicts with the item, or another required value remains ambiguous.

Repository instructions override this default workflow for state names, required evidence, branch or PR conventions, validation commands, and Definition of Done.

## Branch Preparation

Before editing code for a new feature:

1. Inspect the current branch, worktree, remotes, and any existing branch or PR for the work item.
2. If the worktree has local changes, stop and ask what to do with them. Never commit, stash, move, or discard them without explicit authorization.
3. If a branch or PR already exists for the work item, continue there. Do not recreate, rebase, or replace it automatically.
4. Otherwise, fetch the latest `main` from `origin` and create the feature branch from the fetched `origin/main`, not from a potentially stale local `main`.
5. Use the repository's branch naming convention when defined. Otherwise use `feature/<WORKITEM-ID>-<slug>`, for example `feature/ERP-123-add-customer-filter`.

Treat a successfully fetched `origin/main` as the latest stable base unless repository instructions require CI or another stability check. If `origin`, `main`, the work item identifier, or the required branch convention cannot be resolved, ask one focused question instead of guessing. Do not begin implementation until branch preparation is complete.

## Automatic Synchronization

Automatically update states, add comments, and attach PR links when a checkpoint below is reached. Do not ask for confirmation unless:

- marking the item `Done` or `Cancelled`;
- accepting, deferring, or dismissing a material review finding;
- the correct work item, state, PR, or scope is ambiguous;
- available evidence contradicts the requested transition.

Before every write, read the relevant Plane data. Make the smallest mutation, preserve unrelated fields, then read back the result. Resolve states by current project data; never hardcode UUIDs or assume every project uses the example names.

## State Checkpoints

Use repository-defined equivalents when these names do not exist:

| Event | State | Required record |
| --- | --- | --- |
| Implementation actually starts | `In Progress` | Start comment when it adds context not already recorded |
| Requested corrections actually start | `Changes Requested` to `In Progress` | Correction plan or acknowledged findings |
| External impediment prevents progress | `Blocked` | Cause, evidence, unblock owner, next action |
| Impediment clears | Appropriate active state | Resolution and resumed action |
| Implementation is validated and ready for review | `Review & Test` | Delivery summary, validation evidence, PR link when code review uses a PR |
| Review finds mandatory corrections | `Changes Requested` | Actionable findings and conditions for returning to review |
| Corrections are validated | `Review & Test` | Resolved findings and rerun validation |
| PR is merged and Definition of Done is demonstrated | `Done` after explicit confirmation | Merge and completion evidence |
| Work is intentionally abandoned | `Cancelled` after explicit confirmation | Reason and disposition of partial work |

Do not move an item merely because work is planned. `Changes Requested` means corrections are waiting to be resumed, not active implementation. Never move directly from active implementation to `Done`; require review or validation first.

Use `Blocked` only for an external impediment or unresolved dependency. Review defects belong in `Changes Requested`.

## Progress Records

Comment only at meaningful checkpoints. Do not post a diary entry for every command, file, commit, or passing test. Use the language established by the work item or repository.

Checkpoint records always belong in comments: start or resume context, discoveries, spike observations and results, validation evidence, decisions, blockers, review delivery, corrections, and completion evidence. The description remains the durable work contract. Update it only when requirements, scope, constraints, acceptance criteria, or required validation change; add a comment explaining the durable change and its reason.

Post detailed evidence on the work item whose work produced it. For parent and child items, summarize cross-child conclusions, aggregate risks, final decisions, and follow-up work on the parent, but never leave a child's evidence only on the parent.

### Start Or Resume

Record only new context:

```markdown
## Development started

- Scope understood: ...
- Immediate plan: ...
- Risks or open questions: ...
```

### Material Discovery

Comment when evidence changes scope, requirements, risk, or implementation direction. State the observation, impact, decision, and follow-up. Update the work item description only when its durable contract changed; keep transient progress in comments.

### Spike Result

For research or experimental work, comment with the hypothesis tested, setup, observations, reproducible evidence, limitations, conclusion, recommendation, and follow-up work. Keep these results out of the description even when the spike is complete. A parent spike receives only the synthesis across its children; each child retains its own detailed evidence.

### Blocked

```markdown
## Blocked

- Cause: ...
- Evidence: ...
- Unblock owner: ...
- Next action after unblock: ...
```

### Ready For Review

```markdown
## Ready for review

- Implemented: ...
- Validation: `command` - result
- PR: URL
- Known gaps: none | ...
```

Report commands and results exactly. Never claim a check passed when it was not run. Distinguish failures caused by the change from environmental or pre-existing failures.

### Changes Requested

Record concrete findings, locations, impact, required corrections, validation performed, and exact conditions for returning to review. Reuse the repository's review process or the `collaborative-code-review` skill when applicable. Do not make risk-acceptance decisions on the user's behalf.

### Corrections Ready

```markdown
## Review corrections ready

- Resolved: ...
- Deferred or unresolved: none | ...
- Validation rerun: `command` - result
- PR: URL
```

### Completion

Before requesting confirmation for `Done`, verify acceptance criteria are demonstrated, required checks passed, review completed, documentation is current, and no known security, privacy, data-loss, or operational blocker remains. When the work delivers versioned changes through a PR, also verify the PR is merged. A temporary spike that intentionally leaves no product changes does not require a PR; verify reproducible evidence and cleanup instead. Record concise evidence after confirmation.

### Historical Repair

When progress or results were previously placed in a description or only on a parent, preserve history: restore the description to its durable contract and add a clearly labeled historical-result comment on the work item that produced the evidence. State the evidence source when it came from another item. Do not delete existing comments merely to reorganize history.

## PR Registration

When a PR is created or discovered for the work item:

1. Read existing work item links and comments.
2. Add the canonical PR URL as a work item external link unless already present.
3. Mention the same URL in the ready-for-review or corrections-ready comment with validation evidence.
4. Keep the item in active work for a draft or incomplete PR. Move it to `Review & Test` only when it is genuinely ready.

Support the repository's Git host; do not assume GitHub, GitLab, Gitea, or a particular CLI. Do not create duplicate links or equivalent comments.

## Session Recovery And Idempotency

On every resumed session, reconstruct reality from Plane and Git before mutating either:

- If Plane lags behind a completed checkpoint, synchronize it automatically and record only missing evidence.
- If Plane is ahead of the repository or PR, do not move it backward silently. Explain the contradiction and ask how to proceed.
- Search existing comments and links for equivalent content before creating records. Prefer updating nothing over posting duplicate status.
- Treat a state change and its checkpoint comment as one logical operation. If one write fails, report the partial result and repair it before continuing.
- Do not expose credentials, tokens, PII, private logs, or sensitive payloads in comments or links.

## End Of Work Check

Before ending a development session:

1. Run the relevant repository checks when feasible.
2. Compare actual progress with the Plane state.
3. Add any missing meaningful checkpoint comment or PR link.
4. Read back the work item and report its identifier, final state, recorded evidence, PR URL, and validation gaps.

Do not hardcode project names, identifiers, state UUIDs, assignees, providers, branches, or validation commands in this skill.
