---
name: incremental-delivery
description: Control scope and deliver small user-testable vertical slices. Use when planning or implementing a feature, UI, workflow, or Plane work item; when selecting the next increment; or before requesting approval to commit.
---

# Incremental Delivery

Deliver the smallest real increment that lets the user exercise the requested behavior. Optimize for early feedback, not layer completion.

## Scope Gate

- Derive scope only from the request, acceptance criteria, repository constraints, and explicit user decisions.
- Do not add speculative infrastructure, abstractions, integrations, security schemes, configurability, or future-proofing.
- Identify unrelated ideas as out of scope; ask before expanding scope.
- Prefer the simplest maintainable solution for the current requirement. Do not abstract for hypothetical reuse.

## Slice Gate

Select one thin vertical slice that produces an observable behavior, crosses only required layers, and is independently testable. When UI exists, expose an operable interface as early as possible; do not build the database, API, and frontend as separate horizontal phases.

Use production code by default. Use mocks, fakes, or throwaway prototypes only when explicitly agreed or required by an existing test seam, and state the limitation. If supporting work is unavoidable, implement only the narrowest prerequisite and explain why.

## Test And Approval Loop

For each slice:

1. Invoke `tdd` and follow its red-green vertical-slice loop for automatable behavior. Defer refactoring until the slice is green, then review it under the repository's review process.
2. Run fresh focused checks and broader repository-required checks.
3. Never weaken, delete, skip, or rewrite a failing test merely to obtain green. Change it only for a user-approved requirement change or when demonstrably incorrect; explain why first.
4. Present the behavior, verification evidence, and concise manual test steps.
5. If UI exists, make it runnable and wait for the user to exercise it. Automated UI tests do not replace this.
6. Wait for explicit approval of this slice before requesting or making its commit. Work-item approval is not blanket commit approval.
7. After the approved commit, synchronize Plane according to `plane-workitem-development` when applicable.
8. Repeat with the next smallest slice.

Do not continue while approval or corrections are pending. Report blockers to the user; do not write them to Plane unless explicitly requested.

## Approval Request

- **Implemented:** observable behavior.
- **Verified:** commands or checks and results.
- **Try it:** exact manual test steps.
- **Awaiting:** explicit approval to commit, or corrections.
