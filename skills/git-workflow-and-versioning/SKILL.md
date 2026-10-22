---
name: git-workflow-and-versioning
description: Structures Git workflow practices and enforces a mandatory pre-change branch safety gate. Use before any file modification or mutating implementation command to verify development is not occurring on the repository's stable default/base branch. Use when making any code, documentation, configuration, or generated-file change; committing, branching, resolving conflicts, opening or reviewing a pull request, pushing, releasing, or organizing parallel work. Every implementation must use a short-lived branch created from the stable base; direct development on the base is never allowed.
---

# Git Workflow and Versioning

## Overview

Git is your safety net. Treat commits as save points, branches as sandboxes, and history as documentation. With AI agents generating code at high speed, disciplined version control is the mechanism that keeps changes manageable, reviewable, and reversible.

## When to Use

Always. Every implementation change flows through Git. Before the first implementation edit or any implementation/development command that can modify files, run the Pre-Change Branch Safety Gate below. Read-only planning, exploration, review, and separately authorized reviewed integration are not development work; they follow their own safety and authorization gates.

## Core Principles

### Trunk-Based Development (Required Isolation)

Keep the repository's stable default/base branch deployable and untouched by development work. All changes use short-lived branches that merge back within 1-3 days. Long-lived development branches are hidden costs — they diverge, create merge conflicts, and delay integration.

```
main ──●──●──●──●──●──●──●──●──●──  (always deployable)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← short-lived feature branches (1-3 days)
```

Repository-specific naming and integration conventions may vary, but branch isolation does not: never edit or run a mutating implementation command while the current worktree is on its stable default/base branch.

- **Dev branches are costs.** Every day a branch lives, it accumulates merge risk.
- **Release branches are acceptable.** When you need to stabilize a release while main moves forward.
- **Feature flags > long branches.** Prefer deploying incomplete work behind flags rather than keeping it on a branch for weeks.

### 1. Commit Early, Commit Often

Each successful increment gets its own commit. Don't accumulate large uncommitted changes.

```
Work pattern:
  Implement slice → Test → Verify → Commit → Next slice

Not this:
  Implement everything → Hope it works → Giant commit
```

Commits are save points. If the next change breaks something, you can revert to the last known-good state instantly.

### 2. Atomic Commits

Each commit does one logical thing:

```
# Good: Each commit is self-contained
git log --oneline
a1b2c3d Add task creation endpoint with validation
d4e5f6g Add task creation form component
h7i8j9k Connect form to API and add loading state
m1n2o3p Add task creation tests (unit + integration)

# Bad: Everything mixed together
git log --oneline
x1y2z3a Add task feature, fix sidebar, update deps, refactor utils
```

### 3. Descriptive Messages

Commit messages explain the *why*, not just the *what*:

```
# Good: Explains intent
feat: add email validation to registration endpoint

Prevents invalid email formats from reaching the database.
Uses Zod schema validation at the route handler level,
consistent with existing validation patterns in auth.ts.

# Bad: Describes what's obvious from the diff
update auth.ts
```

**Format:**
```
<type>: <short description>

<optional body explaining why, not what>
```

**Types:**
- `feat` — New feature
- `fix` — Bug fix
- `refactor` — Code change that neither fixes a bug nor adds a feature
- `test` — Adding or updating tests
- `docs` — Documentation only
- `chore` — Tooling, dependencies, config

### 4. Keep Concerns Separate

Don't combine formatting changes with behavior changes. Don't combine refactors with features. Each type of change should be a separate commit — and ideally a separate PR:

```
# Good: Separate concerns
git commit -m "refactor: extract validation logic to shared utility"
git commit -m "feat: add phone number validation to registration"

# Bad: Mixed concerns
git commit -m "refactor validation and add phone number field"
```

Keep refactoring separate from feature work. Use `code-review-and-quality` for change sizing and splitting criteria.

### 5. Size Your Changes

Use the thresholds and splitting strategies in `code-review-and-quality`; keep this skill focused on Git history and integration.

## Pre-Change Branch Safety Gate

Run this gate before the first implementation edit, patch, write, formatter, code generator, migration, dependency installer, test with write side effects, or other implementation/development command that can modify the worktree. A separately authorized reviewed integration is governed by the Pre-Integration Project Memory Gate and repository integration procedure instead; it does not permit implementation edits on the stable base.

1. Find the current worktree root and read applicable repository instructions.
2. Inspect the worktree's own current branch and status. A linked worktree has an independent `HEAD`; never infer it from another checkout.
3. Detect the actual stable default/base branch without fetching. Prefer the remote's reported default, then repository instructions, then an unambiguous local `main` or `master`. Never assume the name when evidence conflicts.
4. Before creating a branch, compare the local base commit with available remote metadata using read-only inspection. If the remote base cannot be inspected, follow repository instructions or ask when freshness matters. If metadata shows the local base is stale or divergent, stop and request authorization before fetching or synchronizing it.
5. If the worktree is dirty with changes not already established as part of this same task, stop and ask. Never move, stash, reset, discard, commit, or absorb existing changes silently.
6. If `HEAD` is detached, the base is unresolved, or the repository has no initial commit, stop and ask for the missing decision. Do not edit.
7. If the current branch is the stable base, create and switch to a short-lived task branch from the verified base, then verify the branch and status again before editing.
8. If already on a non-base branch, confirm it belongs to this same task and was created from the verified stable base. Every new task requires a fresh branch or isolated worktree from that base; never reuse another task's branch or stack new work on it.

An explicit request to implement, fix, update, refactor, or otherwise modify a repository authorizes the primary agent to create and switch to the necessary short-lived branch or create an isolated branch worktree. That limited authorization does **not** authorize fetch, pull, stash, reset, commit, push, merge, rebase, cherry-pick, PR mutation, branch deletion, tag, or release.

This gate has no override. Not for a one-line fix, documentation, configuration, generated files, a hotfix, an emergency, or a direct user request to work on the stable branch. Use a `hotfix/*` branch for emergencies. If a safe work branch cannot be prepared, block implementation rather than modify the stable branch.

Direct commits and cherry-picks onto the stable base are prohibited integration paths. Completed work reaches the stable branch only through the repository's reviewed branch/PR merge process. A separately authorized reviewed integration may update the stable base; it is not development work and does not waive the requirement that all implementation occurred on its task branch.

### Feature Branches

```
main (always deployable)
  │
  ├── feature/task-creation    ← One feature per branch
  ├── feature/user-settings    ← Parallel work
  └── fix/duplicate-tasks      ← Bug fixes
```

- Branch from the repository's detected stable default/base branch; never work directly on that branch
- Keep branches short-lived (merge within 1-3 days) — long-lived branches are hidden costs
- Delete branches after merge
- Prefer feature flags over long-lived branches for incomplete features

### Branch Naming

```
feature/<short-description>   → feature/task-creation
fix/<short-description>       → fix/duplicate-tasks
chore/<short-description>     → chore/update-deps
refactor/<short-description>  → refactor/auth-module
hotfix/<short-description>    → hotfix/payment-outage
docs/<short-description>      → docs/update-installation
```

## Working with Worktrees

For parallel AI agent work, use git worktrees to run multiple branches simultaneously:

```bash
# Create a worktree for a feature branch
git worktree add ../project-feature-a feature/task-creation
git worktree add ../project-feature-b feature/user-settings

# Each worktree is a separate directory with its own branch
# Agents can work in parallel without interfering
ls ../
  project/              ← main branch
  project-feature-a/    ← task-creation branch
  project-feature-b/    ← user-settings branch

# When done, merge and clean up
git worktree remove ../project-feature-a
```

Benefits:
- Multiple agents can work on different features simultaneously
- No branch switching needed (each directory has its own branch)
- If one experiment fails, inspect and preserve valuable changes before requesting authorized worktree cleanup
- Changes are isolated until explicitly merged

Run the branch safety gate inside every linked worktree before modifying it. A worktree checked out on the stable base remains read-only; detached worktrees must be attached to an authorized task branch before implementation.

## The Save Point Pattern

```
Agent starts work
    │
    ├── Makes a change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    ├── Makes another change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    └── Feature complete → All commits form a clean history
```

This pattern limits each recovery to one increment. Use only recovery commands authorized for the current repository state; do not discard work automatically.

## Change Summaries

After any modification, provide a structured summary. This makes review easier, documents scope discipline, and surfaces unintended changes:

```
CHANGES MADE:
- src/routes/tasks.ts: Added validation middleware to POST endpoint
- src/lib/validation.ts: Added TaskCreateSchema using Zod

THINGS I DIDN'T TOUCH (intentionally):
- src/routes/auth.ts: Has similar validation gap but out of scope
- src/middleware/error.ts: Error format could be improved (separate task)

POTENTIAL CONCERNS:
- The Zod schema is strict — rejects extra fields. Confirm this is desired.
- Added zod as a dependency (72KB gzipped) — already in package.json
```

This pattern catches wrong assumptions early and gives reviewers a clear map of the change. The "DIDN'T TOUCH" section is especially important — it shows you exercised scope discipline and didn't go on an unsolicited renovation.

## Pre-Commit Hygiene

Before every commit:

1. Reconfirm this worktree is on the intended non-base task branch.
2. Inspect the exact staged diff and staged file inventory.
3. Run the repository-defined secret checks and relevant validation commands. Discover them from repository instructions, task runners, manifests, and CI instead of assuming a language or package manager.
4. Confirm generated files and dependency metadata are intentional.

## Pre-Integration Project Memory Gate

Before requesting, approving, or performing a reviewed branch/PR merge that lands completed, validated work on the repository's actual default/base branch, invoke `project-memory-gate`. The evaluation is mandatory even when the expected result is that no durable memory should be added. It does not make direct commits or cherry-picks onto the stable base permissible.

Run it only after implementation, verification, and review are complete and the change is frozen. If it identifies durable project knowledge, obtain explicit user approval before writing the proposed decision, runbook, or scoped `AGENTS.md` guidance. Approval to merge, commit, push, or update a PR does not implicitly authorize a memory write, and the gate does not authorize any Git mutation.

The integration sequence is:

```text
implement → test → review → freeze → project-memory-gate
          → approved memory update if needed → focused review → integrate
```

Do not skip the gate for small changes; record a concise `No memory update` verdict when the code, tests, and configuration already express everything future contributors need.

## Handling Generated Files

- Follow repository instructions and existing tracking conventions for generated files, dependency locks, build artifacts, editor configuration, and environment templates.
- Inspect ignored and untracked files before staging. Keep credentials, private keys, machine-local state, and secret-bearing environment files out of version control.
- Treat `.gitignore` and tracked generated output as repository-specific policy; propose changes only when the current policy creates a verified risk or omits a known local artifact.

## Using Git for Debugging

```bash
# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Git checkouts midpoints; run your test at each to narrow down

# View what changed recently
git log --oneline -20
git diff HEAD~5..HEAD -- src/

# Find who last changed a specific line
git blame src/services/task.ts

# Search commit messages for a keyword
git log --grep="validation" --oneline
```

## Release & Versioning

Commits are how *you* track change; a **version** is how your *consumers* track it. The moment anything else depends on your code — another team, a published package, a deployed client — "latest on main" stops being a sufficient answer to "what am I running, and is it safe to upgrade?" A version number and a changelog are the contract that answers it.

### Semantic Versioning

For anything with consumers, version `MAJOR.MINOR.PATCH` and let the number carry meaning:

```
  MAJOR  breaking change — consumers must change their code to upgrade
  MINOR  new functionality, backward-compatible — safe to upgrade
  PATCH  bug fix, backward-compatible — safe to upgrade
```

The number is a promise, so make the code match it. A "patch" that changes behavior consumers relied on is a major change wearing a disguise. When unsure whether a change is breaking, assume it is; a surprise major is far cheaper than a broken consumer.

### Tag the release, and let the tag be the source of truth

A release is an immutable point in history, not a moving branch. Tag it so it can always be reproduced:

```bash
git tag -a v1.4.0 -m "Release 1.4.0"
git push origin v1.4.0
```

Derive the version from the tag rather than hand-editing it in scattered files, so the artifact, the tag, and the changelog can never disagree.

### Keep a changelog written for humans

A changelog is not `git log`. It's the curated, consumer-facing answer to "what changed and do I care?" — grouped by `Added / Changed / Fixed / Deprecated / Removed / Security`, newest on top, every entry phrased around user impact, not internal mechanics.

```markdown
## [1.4.0] - 2025-06-12
### Added
- Bulk task import via CSV
### Fixed
- Timezone drift in recurring task due dates
### Deprecated
- `GET /v1/tasks/all` — use the paginated `GET /v1/tasks` (removal in 2.0)
```

Write the entry in the same change that makes the change, while the impact is fresh rather than reconstructed from commit archaeology. Breaking changes need a migration note and deprecation window; release execution follows the repository's own shipping procedure.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll commit when the feature is done" | One giant commit is impossible to review, debug, or revert. Commit each slice. |
| "The message doesn't matter" | Messages are documentation. Future you (and future agents) will need to understand what changed and why. |
| "I'll squash it all later" | Squashing destroys the development narrative. Prefer clean incremental commits from the start. |
| "Branches add overhead" | Short-lived branches are free and prevent conflicting work from colliding. Long-lived branches are the problem — merge within 1-3 days. |
| "It's only one line; I'll change it on main" | Change size never overrides isolation. Create a short-lived branch before any modification. |
| "This hotfix is too urgent for a branch" | Urgency calls for a short-lived `hotfix/*` branch, not unreviewed work on the stable base. |
| "I'll split this change later" | Large changes are harder to review, riskier to deploy, and harder to revert. Split before submitting, not after. |
| "Ignore policy doesn't matter" | Verify the repository's exclusion mechanism keeps credentials and machine-local state out of version control. |
| "It's just a small fix, bump the patch" | Check what consumers can observe. A behavior change they relied on is a major, whatever the diff size. |
| "The changelog is just the commit log" | Commits are for you; the changelog is for consumers, curated by impact. Generating one from raw commits buries what matters. |
| "We'll write the changelog at release time" | By then the impact is reconstructed from memory and half of it is missing. Write the entry with the change. |

## Red Flags

- Large uncommitted changes accumulating
- Commit messages like "fix", "update", "misc"
- Formatting changes mixed with behavior changes
- Secret-bearing or machine-local files are not covered by the repository's exclusion policy
- Generated files or build artifacts are staged contrary to repository policy
- Long-lived branches that diverge significantly from main
- Any file modification or mutating implementation command performed while the worktree is on the stable default/base branch
- A direct commit or cherry-pick onto the stable default/base branch
- Force-pushing to shared branches
- A breaking change shipped under a minor or patch version bump
- A release with no tag, or a version number hand-edited out of sync with the tag
- A user-facing release with no changelog entry, or a changelog that's just dumped commit messages

## Verification

For every commit:

- [ ] The change was developed entirely on a task branch created from the detected stable base
- [ ] The current worktree is still on the intended non-base task branch
- [ ] Commit does one logical thing
- [ ] Message explains the why, follows type conventions
- [ ] Tests pass before committing
- [ ] No secrets in the diff
- [ ] No formatting-only changes mixed with behavior changes
- [ ] Ignored, untracked, generated, and machine-local files follow repository policy

For every release (anything with consumers):

- [ ] The version bump matches the change: breaking → major, additive → minor, fix → patch
- [ ] The release is tagged, and the version is derived from the tag, not hand-edited out of sync
- [ ] The changelog has a curated, human-readable entry grouped by impact for this version
