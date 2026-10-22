# Project Memory Admission Policy

## Admission Test

Admit a candidate only when every answer is **yes**:

1. **Durable:** Is it likely to matter after the current branch, session, and release?
2. **Non-obvious:** Can a competent contributor not infer it reliably from current code, tests, configuration, or existing docs?
3. **Consequential:** Could forgetting it cause a wrong design, unsafe operation, compatibility break, repeated incident, or costly rediscovery?
4. **Verified:** Is it supported by stable, reviewable evidence rather than a model inference or unconfirmed observation?
5. **Minimal:** Is this the smallest non-duplicative artifact and the correct scope?

If any answer is no, return `No memory update`.

## Classification

| Candidate | Destination | Example |
|---|---|---|
| Consequential choice and rationale | `docs/decisions/` | PostgreSQL is authoritative for payment idempotency |
| Repeatable non-obvious operation or verified gotcha | `docs/runbooks/` | Safe recovery order after a failed migration |
| Stable rule governing most future work in a scope | Narrowest `AGENTS.md` | Integration tests are mandatory for schema changes |
| Current work, implementation detail, or evident behavior | Nowhere | Files changed by the feature |

## Lifecycle

- `proposed`: discussed but not yet made true by the project.
- `accepted`: implemented and supported by current evidence.
- `deprecated`: no longer recommended, but not directly replaced.
- `superseded`: replaced by a named newer record.
- `rejected`: considered and deliberately not adopted.

Only `accepted` items are current authority. Proposed items must not be presented as project reality. Deprecated, superseded, and rejected items remain historical evidence and must be excluded from normal current-context summaries.

A memory proposal written before its implementation exists must remain `proposed`. Mark it `accepted` only after the implementation and verification evidence are present. When the gate runs after implementation has been frozen, an approved record may be created as `accepted` because the feature itself already makes the decision true.

When accepted knowledge becomes false without a replacement, propose `deprecates <item>` and record the reason and evidence. When scoped `AGENTS.md` guidance becomes false, propose `removes stale guidance <location>` or a precise replacement. Both actions require explicit approval; preserve decision/runbook records with lifecycle status, while Git preserves removed instruction history.

## Strong No-Op Examples

- A CSS alignment fix with a regression screenshot or visual test.
- A renamed internal helper with no contract or rationale change.
- A configuration value already declared and explained next to its source.
- A normal defect whose test clearly captures the durable behavior.
- A dependency patch update without a project-specific constraint.

## Strong Admission Examples

- A security boundary chosen after rejecting plausible alternatives.
- A business invariant distributed across several modules and enforced by tests.
- A provider limitation that forces a non-obvious retry or ordering strategy.
- A recovery procedure where executing steps out of order can lose data.
- A new decision that invalidates an accepted earlier decision.
