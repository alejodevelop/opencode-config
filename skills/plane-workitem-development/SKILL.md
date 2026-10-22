---
name: plane-workitem-development
description: Develop, fix, test, review, or open a PR for a Plane work item while keeping its state, progress comments, and PR links synchronized. Use when starting or resuming implementation tied to Plane, addressing requested changes, reporting a blocker, handing work off for review, or finishing merged work.
---

# Plane Work Item Development

Keep Plane synchronized with work that actually happened. Use the available Plane MCP tools for all Plane reads and writes. Use `plane-work-management` for creating or redesigning work items; this skill governs execution after a work item exists.

## Ownership And Mutation Authority

- The primary `build` agent owns every Plane mutation and every Git state change (branch, commit, push, PR, tag, release). It is the only agent authorized to synchronize Plane.
- Subagents do not synchronize Plane independently. `general` and `explore` read Plane and Git as needed and report identifiers, evidence, and recommended transitions back to `build`; they must not call mutating Plane tools.
- `reviewer` is strictly read-only and cannot call Plane or execute Git commands. It verifies the frozen Plane and Git evidence supplied by `build` plus permitted repository files, then reports findings; it never reads from or writes to Plane or Git directly.
- When a subagent is asked to synchronize Plane, it returns the intended change plus its evidence to `build`, which applies it.

## Advisory Versus Execution Mode

- Advisory (read-only) mode: the user asks for status, analysis, a plan, options, or a review. Perform only reads. Do not change Plane state, add comments, create links, or touch Git. Report findings and a proposed change set. A review request remains advisory even when it discovers actionable findings.
- Execution mode: the user explicitly asks to implement, correct, or complete work tied to the work item, or explicitly asks to synchronize review findings to Plane. Apply the workflow below only to the authorized scope.

If intent is ambiguous, default to advisory and ask one focused question before any write.

## Resolve Context

Before editing code or changing Plane:

1. Find the Git worktree root and read applicable `AGENTS.md` and nested repository instructions. Pure Plane administration that has no repository context does not require Git inspection; skip it instead of inventing a project.
2. Resolve the work item identifier to its project and UUID. Read its description, state, assignees, comments, activity, and external links.
3. Inspect the repository, current branch, local changes, and existing PR when available. Never infer progress solely from the Plane state.
4. Compare acceptance criteria and Definition of Done with the current implementation. Continue from existing evidence instead of repeating completed work.
5. Ask one focused question when multiple work items are plausible, the requested work conflicts with the item, or another required value remains ambiguous.

Repository instructions override this default workflow for state names, required evidence, branch or PR conventions, validation commands, and Definition of Done.

## Branch Preparation

Before editing code for a new feature:

1. Inspect the current branch, worktree, remotes, and any existing branch or PR for the work item.
2. Detect the repository's actual default/base branch instead of assuming `origin/main`. Prefer the remote's reported default (for example `git symbolic-ref refs/remotes/origin/HEAD`), then repository instructions, then an explicit `main`/`master` fallback. Never hardcode `main`.
3. If the worktree has local changes, handle them contextually and stop to ask what to do with them when they are unrelated to the task. Never discard, move, stash, or commit existing local changes without explicit authorization, and never assume they belong to this work item.
4. If a branch or PR already exists for the work item, continue there. Do not recreate, rebase, or replace it automatically.
5. Otherwise, request explicit authorization before fetching the latest base branch or creating/switching to a feature branch. After authorization, create it from the fetched remote base, not from a potentially stale local branch.
6. Use the repository's branch naming convention when defined. Otherwise use `feature/<WORKITEM-ID>-<slug>`, for example `feature/ERP-123-add-customer-filter`.

Treat a successfully fetched remote base as the latest stable base unless repository instructions require CI or another stability check. If the remote, default branch, work item identifier, or required branch convention cannot be resolved, ask one focused question instead of guessing. Do not begin implementation until branch preparation is complete.

## Git Authorization

Act on Git only within the following limits:

- No commit, push, pull-request creation or update, repository creation or settings change, tag, or release without explicit authorization for that action.
- No fetch, pull, branch creation, branch switch, merge, or other local Git state change without explicit authorization. Read-only inspection such as `status`, `diff`, `log`, and remote metadata queries is allowed in advisory mode.
- No force push, history rewrite (rebase, amend of shared history, reset --hard on published work), or remote branch deletion without specific confirmation of the exact refs and effect.
- Destructive local commands that could lose uncommitted work require explicit confirmation.
- Do not run Git operations that mutate a remote as a side effect of an unrelated request.

## Automatic Synchronization

Automatically update states, add comments, and attach PR links when a checkpoint below is reached. Do not ask for confirmation unless:

- marking the item `Done` or `Cancelled`;
- accepting, deferring, or dismissing a material review finding;
- the correct work item, state, PR, or scope is ambiguous;
- available evidence contradicts the requested transition;
- the action would be destructive or broad, or would cross the Git authorization limits above.

Before every write, read the relevant Plane data. Make the smallest mutation, preserve unrelated fields, then read back the result. Resolve states by current project data; never hardcode UUIDs or assume every project uses the example names. Suggested state names below are preferences only; if a preferred state does not exist, choose the closest existing state or ask, and never auto-create a missing state.

## Atomicity And Idempotency Of Writes

- A state change and its checkpoint comment are separate Plane calls and are not atomic. A transition can succeed while the comment fails, or vice versa.
- Treat them as one logical operation: if the state changed but the comment failed, post the missing comment; if the comment succeeded but the state did not change, retry the transition. Reconcile before continuing.
- Keep writes idempotent: read current state and existing comments first, and do not repeat a transition or post an equivalent comment twice. Prefer updating nothing over duplicating a record.

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

Comment only at meaningful checkpoints. Do not post a diary entry for every command, file, commit, or passing test. Use the language established by the work item or repository. Write comment bodies as HTML for `comment_html`; do not send Markdown that Plane will not render.

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

Record concrete findings, locations, impact, required corrections, validation performed, and exact conditions for returning to review. Reuse the repository's review process or the `code-review-and-quality` skill when applicable. Do not make risk-acceptance decisions on the user's behalf.

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

Creating or updating the PR itself requires explicit Git authorization. Support the repository's Git host; do not assume GitHub, GitLab, Gitea, or a particular CLI. Do not create duplicate links or equivalent comments.

## Session Recovery And Idempotency

On every resumed session, reconstruct reality from Plane and Git before mutating either:

- If Plane lags behind a completed checkpoint, synchronize it automatically and record only missing evidence.
- If Plane is ahead of the repository or PR, do not move it backward silently. Explain the contradiction and ask how to proceed.
- Search existing comments and links for equivalent content before creating records. Prefer updating nothing over posting duplicate status.
- Treat a state change and its checkpoint comment as one logical operation, even though they are separate non-atomic calls. If one write fails, report the partial result and repair it before continuing.
- Do not expose credentials, tokens, PII, private logs, or sensitive payloads in comments or links.

## End Of Work Check

Before ending a development session:

1. Run the relevant repository checks when feasible.
2. Compare actual progress with the Plane state.
3. Add any missing meaningful checkpoint comment or PR link.
4. Read back the work item and report its identifier, final state, recorded evidence, PR URL, and validation gaps.

Do not hardcode project names, identifiers, state UUIDs, assignees, providers, branches, or validation commands in this skill.
