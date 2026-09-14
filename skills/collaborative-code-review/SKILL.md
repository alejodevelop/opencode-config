---
name: collaborative-code-review
description: Review or re-review code, pull requests, branches, commits, or local changes through evidence-based findings and interactive triage. Use for peer review, code review, PR review, review follow-up, validating requested changes, or deciding which findings to address, defer, investigate, accept, or dismiss.
---

# Collaborative Code Review

Produce decision-quality feedback, not a pass/fail inspection. Find concrete risks, explain their consequences, expose tradeoffs, then let the user decide what deserves attention now.

Do not edit code while reviewing unless the user explicitly asks to implement selected findings.

Write for a teammate who understands the product but may not know this code. Every finding must be understandable without AI or a second explanation.

Prefer plain language:

- Prefer short sentences and familiar words.
- Describe concrete behavior instead of using jargon. When a technical term is necessary, explain it immediately.
- Use a comparison or analogy only when it makes the behavior easier to picture. Never force one.
- Name who or what is affected and what happens to them.
- Keep each section brief. Include only the detail needed to understand and decide.

## 1. Establish Scope

Infer the review target from the request and repository state:

- Use the named PR, base branch, commit, range, file, or directory when supplied.
- For a branch review, compare the merge base with `HEAD` using a three-dot diff.
- For local work, include staged, unstaged, and untracked files relevant to the change.
- If exactly one sensible target exists, use it and state the scope briefly.
- If multiple plausible targets would produce materially different reviews, ask one focused question. Never guess a base branch or silently omit local changes.
- Do not review generated, vendored, lock, snapshot, or formatting-only changes unless they alter behavior or the user requests them.

Read applicable repository instructions, requirements, issue or spec, tests, and surrounding code before judging the diff. Distinguish changed defects from unrelated pre-existing problems. Mention an existing problem only when the change aggravates it or depends on it.

### Verify Remote Scope

For every PR or remote branch review, including a re-review, treat current remote references as a precondition rather than an assumption:

1. Query the PR host or authoritative metadata to identify the declared base branch, PR number when applicable, head branch or PR reference, and remote. Never infer the base from a stale local tracking branch.
2. Fetch both the declared base and head. For a GitHub-style PR reference, use commands equivalent to:

   ```powershell
   git fetch <remote> <base-branch>
   git fetch <remote> refs/pull/<pr-number>/head:refs/remotes/<remote>/pr/<pr-number> --force
   ```

   For another host or a remote branch review, use that host's authoritative head ref or fetch the named head branch into an explicit remote-tracking ref.
3. Resolve and record the exact base SHA, head SHA, and merge-base SHA only after both fetches succeed:

   ```powershell
   git rev-parse <remote>/<base-branch>
   git rev-parse <remote>/pr/<pr-number>
   git merge-base <remote>/<base-branch> <remote>/pr/<pr-number>
   ```

4. Define the reviewed file delta with the three-dot range and the commits contributed exclusively by the PR with the two-dot range:

   ```powershell
   git diff --name-status <remote>/<base-branch>...<remote>/pr/<pr-number>
   git log --oneline <remote>/<base-branch>..<remote>/pr/<pr-number>
   ```

The presence of a commit anywhere in the head's ancestry does not prove the PR introduced it. Only commits in `<remote>/<base-branch>..<remote>/pr/<pr-number>`, computed from the freshly fetched base, are PR-contributed commits.

For each commit suspected of being mixed, unrelated, or out of scope, run:

```powershell
git merge-base --is-ancestor <commit-sha> <remote>/<base-branch>
```

- Exit code `0` means the commit already belongs to the base and was not introduced by the PR.
- Any other exit code means it is not an ancestor of the base; confirm that it appears in the two-dot commit range and gather evidence that the PR introduces it before reporting a scope finding.

Record this evidence for every remote review:

```text
Base: <remote>/<base-branch> @ <base-sha>
Head: <remote>/pr/<pr-number> @ <head-sha>
Merge base: <merge-base-sha>
Reviewed commits: <remote>/<base-branch>..<remote>/pr/<pr-number>
Reviewed diff: <remote>/<base-branch>...<remote>/pr/<pr-number>
Remote freshness: verified
```

If any PR query, fetch, or reference resolution fails because of authentication, permissions, connectivity, a missing reference, or any other error, stop the scope review. Do not use local references silently, assume freshness, determine the delta, classify commits, continue a re-review, publish comments, change Plane state, or issue an integration assessment. State exactly:

> Cannot verify remote base/head references. Review scope is blocked until the references are updated.

Then provide complete commands adapted to the actual remote, declared base, and PR number, for example:

```powershell
git fetch origin master
git fetch origin refs/pull/6/head:refs/remotes/origin/pr/6 --force
git log -1 --oneline origin/master
git log -1 --oneline origin/pr/6
```

Ask the user to share the output or confirm that every command succeeded. Wait for that confirmation, then rerun the preflight before proceeding.

### Detect The Review Mode

Before reviewing, inspect the same review target's discussion, review comments, decision record, and commit history when available:

- Use **re-review** when actionable prior findings exist on the same work item or PR and later changes appear intended to address them.
- Use **initial review** when no relevant prior review exists.
- Do not classify a review as a re-review merely because comments exist. Ignore bot messages, operational notes, and general discussion unless they record a finding or its disposition.
- If the prior findings, reviewed revision, current target, or relationship between them cannot be identified reliably, ask one focused question before proceeding. Never assume a different work item or PR.

For a re-review, preserve the identity of the original work item or PR, finding IDs, comment threads, dispositions, and reviewed revision. Compare the previously reviewed revision with the current revision. Do not restart the full review from the base branch unless the user explicitly requests it or the prior review cannot be reconstructed.

## 2. Review For Outcomes

Prioritize defects and decisions that affect users or maintainers:

1. Security, privacy, authorization, data loss, and irreversible effects.
2. Incorrect behavior, regressions, broken contracts, races, and platform failures.
3. Missing requirements and unjustified scope changes.
4. Error handling, observability, migration, compatibility, and operational risks.
5. Tests missing for plausible failure paths or important changed behavior.
6. Maintainability problems that impose a concrete near-term cost.

Do not report:

- Personal style preferences presented as correctness.
- Formatting or import ordering already handled by tooling.
- Generic best practices without a failure mode in this codebase.
- Speculative scalability or abstractions unsupported by current requirements.
- Duplicate symptoms of the same root cause; consolidate them.
- Praise without a specific behavior worth preserving.

Actively look for evidence that disproves each suspected finding. A review finding is a hypothesis until verified against the code, requirements, tests, or documented platform behavior.

Before publishing a finding to Plane, Gitea, GitHub, or another external system that says a commit is mixed, unrelated, out of scope, or should be separated, rerun the complete remote-scope preflight and repeat `git merge-base --is-ancestor <commit-sha> <remote>/<base-branch>`. Publish only when the refresh succeeded, the exact SHAs are recorded, the commit is not in the updated base, it appears in the updated two-dot range, and evidence shows that the PR introduces it. Otherwise stop and report the blocked verification instead.

## 3. Build Evidence-Based Findings

Before reporting a finding, verify its location, current behavior, failure conditions, impact, and confidence. Consider viable responses and their tradeoffs, including leaving the code unchanged when reasonable. This is the reviewer's working evidence, not a checklist the reader must reconstruct.

Present that evidence through four questions:

- **What:** state the problem in one or two plain sentences. Describe what the code does, not an abstract rule it violates.
- **Why:** explain the concrete consequence, who or what is affected, and why addressing it may be worthwhile. Include the failure condition here when needed.
- **Example:** show the smallest realistic input, sequence, or before/after result that exposes the problem.
- **Possible solution:** suggest one brief, viable starting point. Do not prescribe a full implementation when several approaches could work.

Put the finding ID, severity, and exact `path:line` or smallest useful code region in the heading. Do not repeat them in the four sections.

Each finding must let the reader answer: what fails, why it matters, how it can happen, and where a fix could start. If any answer is unclear, rewrite the finding before publishing it.

Severity reflects consequence, not reviewer preference:

- **Blocker:** credible security incident, data loss, corruption, or fundamentally broken required behavior. Must be resolved or explicitly accepted by an authorized human before integration.
- **High:** likely user-visible failure or serious regression. Normally address now.
- **Medium:** real but bounded risk, maintainability cost, or test gap. Discuss timing.
- **Low:** optional improvement with limited impact. Safe to defer or dismiss.
- **Question:** insufficient evidence or missing context. Investigate before treating as a defect.

Do not inflate confidence. Convert uncertain claims into questions. Do not use severity alone to decide timing: include effort, immediacy, confidence, dependencies, and current scope.

## 4. Present The Review

Lead with findings, ordered by consequence and decision value. Keep the initial set focused; omit low-value noise. For each finding use:

```markdown
### F1 - High - `src/users.ts:42` - Users can be created without email

**What**
The registration flow saves a user even when the email is empty.

**Why**
That user cannot sign in or recover the account. It is like creating a key without a matching lock.

**Example**
`createUser({ email: "" })` succeeds, but every later sign-in attempt fails.

**Possible solution**
Validate the email before saving and return a clear validation error.
```

Avoid this:

```markdown
**What**
The implementation violates input-validation best practices and may produce an inconsistent domain entity.
```

It names concepts but does not explain the visible behavior. Write instead: "The registration flow saves a user even when the email is empty."

Keep confidence in the reviewer's evidence. If uncertainty changes the decision, state it naturally in **Why**, for example: "This matters if guest accounts are not allowed; the requirements do not make that clear." Treat insufficient evidence as a question, not a defect.

Then include:

- **Questions:** context needed to validate uncertain findings.
- **What works:** only specific choices worth preserving.
- **Validation gaps:** checks not run, inaccessible systems, missing specs, or incomplete evidence.

If no findings survive verification, say so explicitly. Never invent findings to make the review appear useful.

Do not give a final merge verdict before triage unless no actionable findings exist or the user requested a non-interactive review.

## 5. Run Interactive Triage

After presenting findings, ask the user to decide each one. When there are more than five, triage blockers and high-severity findings first, then continue in batches.

Offer these decisions without forcing the recommendation:

- **Address now:** required before integration.
- **Investigate:** gather named evidence before deciding.
- **Defer:** record why, owner or trigger, and when it becomes relevant.
- **Accept:** consciously retain an understood risk or debt.
- **Dismiss:** false positive, irrelevant, duplicate, or not worth the cost.

State the recommended decision and one-line rationale before asking. Invite alternative context. If the user challenges a finding, re-check it rather than defending it reflexively. Correct or withdraw unsupported findings plainly.

Security, privacy, authorization, data-loss, and irreversible-operation risks require explicit disposition. Never silently downgrade, defer, or dismiss them.

## 6. Close With A Decision Record

Summarize only after triage:

```markdown
## Decision Record

| ID | Decision | Rationale | Follow-up |
| --- | --- | --- | --- |
| F1 | Address now | ... | ... |

## Integration Assessment

Ready | Ready after selected fixes | Blocked pending evidence or fixes
```

List unresolved questions and validation gaps. A deferred finding needs a concrete trigger; otherwise classify it as accepted or dismissed. Preserve disagreements in neutral technical language.

## 7. Re-review Prior Findings

In re-review mode, validate the previously selected fixes rather than repeating the initial review:

1. Recover each actionable finding from the same work item or PR, including its ID, original requirement, location, disposition, and comment thread.
2. Identify the last reviewed revision and the current revision. Inspect their delta plus enough surrounding code and tests to validate behavior.
3. Reproduce or otherwise verify the original failure scenario against the current revision. A code change or author statement alone is not evidence that the finding is resolved.
4. Check for regressions directly introduced by the attempted fixes. Do not broaden this into a new full review.
5. Keep original finding IDs and update the original comment threads when the platform permits. Do not create duplicate findings or comments.
6. Create a new finding ID only for a distinct regression or defect introduced by the follow-up changes. Cross-reference the originating finding.

Classify every prior actionable finding:

- **Resolved:** the original failure no longer occurs and supporting validation passes.
- **Partially resolved:** the change addresses only part of the original requirement or scenarios.
- **Unresolved:** the original failure still occurs or the required change is absent.
- **Regressed:** the attempted fix introduces a distinct failure.
- **Obsolete:** later agreed changes remove the condition or requirement that made the finding applicable.
- **Cannot verify:** required code, environment, tests, or evidence is unavailable.

Report re-review results as a follow-up, not a fresh findings list:

```markdown
## Re-review Results

| ID | Status | Evidence | Follow-up |
| --- | --- | --- | --- |
| F1 | Resolved | `test_invalid_user` passes at `<revision>` | Resolve original thread |

## Integration Assessment

Approved | Changes requested | Blocked pending evidence
```

Resolve an original thread only for **Resolved**, **Obsolete** with an explicit rationale, or a risk explicitly accepted by an authorized human. Keep **Partially resolved**, **Unresolved**, **Regressed**, and **Cannot verify** findings open. Request changes when required findings remain open; approve only when every required finding is resolved or explicitly dispositioned.

If later evidence invalidates a published finding or integration assessment, update or withdraw the original comment and briefly explain the cause. Do not leave two contradictory decisions active.

Use the user's language for the review unless repository conventions or the user specify otherwise.
