---
name: project-memory-gate
description: Evaluate whether completed, validated work contains durable project knowledge before it lands on the repository's default/base branch through a reviewed branch or PR merge. Use for every preparation, approval, request, or performance of that integration, including trivial changes; also use when a lasting architectural decision, non-obvious invariant, recurring operational procedure, verified gotcha, deprecation, or supersession is discovered. The evaluation is mandatory before integration, but writing memory is exceptional and always requires explicit user confirmation. Session summaries, temporary plans, routine details, and trivial fixes normally produce a no-memory verdict rather than a memory artifact.
license: MIT
compatibility: Designed for Git repositories and Agent Skills-compatible coding agents. Git writes and remote operations remain subject to the host agent's authorization policy.
metadata:
  author: alejodevelop
  version: "1.0.0"
---

# Project Memory Gate

Preserve only durable, evidence-backed knowledge that future contributors cannot reliably infer from the current code, tests, and configuration. Git-tracked project files are authoritative; semantic indexes, sessions, and model recollections are not.

## Authority And Safety

- Run the evaluation before a reviewed branch or PR merge lands completed work on the actual default/base branch. Never assume the branch is named `main`. The branch safety gate in `git-workflow-and-versioning` separately prohibits development on the stable base and prohibits direct commits or cherry-picks onto it; this memory gate cannot waive that policy.
- Evaluation is read-only. It does not itself authorize edits, commits, pushes, PR changes, merges, branch changes, fetches, or other Git mutations.
- Only the primary implementation agent may perform memory writes. Read-only or review agents return evidence and recommendations; the primary agent owns the proposal presented to the user.
- Never write memory without explicit user approval of the proposed memory item. Approval to implement, commit, push, open a PR, or merge is not approval to create memory.
- Do not store secrets, credentials, personal data, private keys, environment values, hidden reasoning, raw conversations, or ignored files.
- Prefer no memory over uncertain, redundant, inferred, or weakly supported memory.

## Mandatory Pre-Integration Gate

After implementation, tests, and review are complete and changes are frozen:

1. Detect the repository's actual default/base branch from remote metadata or repository instructions. Do not fetch or switch branches without authorization.
2. Determine the feature range from the merge base and inspect the complete diff, commits, tests, configuration changes, and review evidence. Include approved but still-uncommitted changes when integration preparation occurs before the final commit.
3. Read the relevant existing memory, if present:
   - scoped `AGENTS.md` files;
   - `docs/decisions/`;
   - `docs/runbooks/`.
4. Ask the durable-knowledge question:

   > What must a contributor know months from now to modify this area correctly that cannot be discovered reliably from the current code, tests, and configuration?

5. Classify each candidate using `references/policy.md`.
6. Check for duplicate, conflicting, deprecated, or superseded knowledge.
7. Return one of two verdicts before requesting, approving, or performing the integration:
   - `No memory update` with a short reason; or
   - `Memory candidate` with type, concise content, longevity rationale, evidence, scope, and lifecycle action (`new`, `supersedes`, `deprecates`, or `removes stale guidance`).
8. If there is a candidate, ask the user to approve, revise, or reject it. Do not write while awaiting confirmation.
9. After approval, write only the minimum artifact needed, validate links and lifecycle metadata, show the exact diff, and run a focused documentation review.
10. Keep any subsequent commit, push, PR update, or merge under the normal explicit Git authorization workflow.

The gate is complete when its verdict is recorded in the response. A `No memory update` verdict is a successful and expected outcome.

## Memory Types

### Decision Record

Use `docs/decisions/` for a consequential choice with meaningful alternatives, rationale, constraints, or trade-offs. Examples include architecture, security boundaries, data ownership, public API policy, compatibility strategy, and operational topology.

Use `assets/decision-template.md`. A changed decision gets a new record; mark the old record `superseded` and link both directions. Do not rewrite history to make the new decision appear original.

### Runbook

Use `docs/runbooks/` for a verified, repeatable procedure or recurring gotcha whose omission can cause failure and whose steps are not safely inferable from automation or source. Use `assets/runbook-template.md`. When the procedure is no longer valid and has no replacement, mark it `deprecated` and state why.

A runbook must identify prerequisites, safe verification, failure/rollback guidance where applicable, and evidence. Prefer executable automation over prose when automation can safely encode the procedure.

### Stable Agent Guidance

Update the narrowest applicable `AGENTS.md` only for a concise rule that should govern most future work in that scope, such as required verification or a stable safety constraint. Link to a decision or runbook for rationale; do not duplicate it. Do not turn `AGENTS.md` into a project wiki. When such guidance stops being true, propose its removal or replacement explicitly; Git preserves its history.

## Never Preserve As Durable Memory

- Session summaries, chat transcripts, scratch notes, or model reasoning.
- Plans, TODOs, branch state, current task progress, or temporary workarounds.
- File lists, code descriptions, configuration values, or behavior obvious from current sources.
- Routine dependency bumps, formatting, visual-only fixes, mechanical refactors, and ordinary bug fixes whose regression test explains the contract.
- Unverified hypotheses, failed experiments without a durable constraint, or claims supported only by model interpretation.
- Duplicates of README, API docs, tests, issue trackers, or existing memory.

## Evidence Standard

Every durable item must cite at least one stable, reviewable source, preferably two for high-impact claims:

- a test that enforces the invariant;
- current code or configuration;
- a commit, pull request, or issue;
- an external specification or official documentation.

Record what the evidence proves, not merely its path. If evidence is missing, propose improving the implementation or tests instead of memorializing the claim.

## Proposal Format

Use this compact format before any write:

```text
Project-memory gate: MEMORY CANDIDATE
Type: decision | runbook | AGENTS guidance
Knowledge: <one concise statement>
Why durable: <future error it prevents and why sources alone are insufficient>
Evidence: <paths/tests/PRs/commits and what they establish>
Scope: <repository or subtree>
Lifecycle: new | supersedes <item> | deprecates <item> | removes stale guidance <location>

Create/update this project memory? (approve / revise / reject)
```

For no-op results:

```text
Project-memory gate: NO MEMORY UPDATE
Reason: <why the completed change is obvious, temporary, trivial, or already documented>
```

## Review And Maintenance

- Memory changes belong in the same feature/PR that makes them true whenever possible.
- Review memory against the frozen implementation, not against plans or intended behavior.
- During later gates, flag cited evidence that moved or disappeared and ask whether the item should be verified, deprecated, or superseded.
- Never silently delete history. Git keeps history, while document status controls what agents should treat as current.
- Keep records short. A future agent should locate the relevant item first and inspect authoritative sources for details.
