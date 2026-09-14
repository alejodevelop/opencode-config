---
name: nexttask-daily-report
description: Generate an English NextTask daily work report from Plane activity in the ottcomputer workspace, selected Git repositories, and untracked work. Use when preparing today's NextTask entries, reconstructing a workday, reporting daily work, or allocating approximately nine working hours.
---

# NextTask Daily Report

Build an evidence-based daily report for manual entry into NextTask. Read Plane only through the `plane-ottcomputer` MCP tools. Do not use another Plane workspace. Read Git through non-mutating commands only. Never change Plane, Git, or NextTask while producing the report.

## Output Contract

Every NextTask entry must contain:

- Date
- Priority
- Title
- Description
- Time in hours
- Time in minutes

Write every field value intended for NextTask in English, regardless of the language used in Plane, Git, or the conversation. Translate and summarize source material; do not copy unclear source text verbatim. Continue asking questions and explaining decisions in the user's language.

Return plain-text blocks separated by `---`, optimized for copying one entry at a time. Do not use a table. Use this exact field order:

```text
Date: YYYY-MM-DD
Priority: High
Title: Concise outcome-oriented title
Description: Clear summary of the work completed and its result.
Time in hours: 2.5
Time in minutes: 150

---
```

Use the priority names accepted by the user's NextTask instance when known. Otherwise use `Urgent`, `High`, `Medium`, or `Low`.

## 1. Establish Scope

1. Use the user's local calendar date by default. Ask for the date only when the user requests another day or the date is ambiguous.
2. Resolve the authenticated user with `plane-ottcomputer member me`. Attribute personal activity only to that user.
3. Ask which Git repository paths to inspect for the selected date. Accept one or several paths. Do not scan unrelated directories.
4. Confirm the target is approximately 9 working hours unless the user supplies another target.

## 2. Collect Plane Evidence

Reconstruct the user's activity in the `ottcomputer` workspace for the selected date. Use the smallest set of reads that provides reliable evidence.

1. List projects and work items associated with the authenticated user or likely changed on the selected date.
2. Inspect candidate work item details, activity, comments, links, and project context when needed to understand what changed.
3. Include meaningful work such as creating or updating projects and work items, implementation progress, review, testing, investigation, coordination, comments that changed direction, and completed outcomes.
4. Treat timestamps, actor IDs, state transitions, comments, and changed fields as evidence. Do not count an item's current state as proof that work happened on the selected date.
5. Exclude automated activity, unrelated users' actions, duplicate records, and administrative noise.

When filtering requires non-trivial PQL, read the Plane PQL reference first. Resolve UUIDs before using them in filters.

## 3. Collect Git Evidence

For every selected repository:

1. Find its worktree root and read applicable `AGENTS.md` instructions.
2. Inspect commits authored by the authenticated user on the selected local date. Prefer configured Git identity; ask one focused question if attribution is ambiguous.
3. Inspect current branch, status, relevant diffs, and available PR metadata without modifying files or repository state.
4. Use work item identifiers, branch names, commit messages, PR links, changed behavior, and timestamps to correlate Git work with Plane.
5. Treat commits, files, tests, comments, and state changes as evidence for a task, not as separate tasks by default.

Never expose secrets, credentials, private payloads, PII, or sensitive source excerpts in the report.

## 4. Capture Untracked Work

After collecting digital evidence, summarize the candidate work groups and ask one focused question covering work that may not be recorded digitally, including:

- meetings and calls;
- planning or coordination;
- support and incident response;
- research or troubleshooting;
- travel or on-site work;
- administrative work;
- breaks or other company-defined time categories when they belong in NextTask.

For each additional activity, obtain enough information to identify its outcome and approximate duration. Do not invent missing activities to fill the day.

## 5. Consolidate Tasks

Group evidence by business outcome or coherent work session.

- Merge Plane, Git, PR, review, testing, and communication evidence that belongs to the same outcome.
- Keep distinct outcomes separate when they would be entered or explained independently.
- Do not create one entry per commit, file, comment, state transition, meeting segment, or tool action.
- Split a task only when the work had a clearly different outcome, priority, or NextTask reporting category.
- Prefer a few accurate entries over a detailed activity diary.
- Describe completed work factually. Do not claim completion, testing, deployment, review, or impact without evidence.

## 6. Estimate Time And Priority

Estimate duration from all available evidence, including timestamps, sequence of activity, commit spans, stated meeting length, and user-provided context. Git and Plane timestamps are boundaries and signals, not automatic proof of continuous work.

1. Assign minutes first using practical increments, normally 15 or 30 minutes.
2. Derive hours from minutes using `minutes / 60`. Keep both fields mathematically equivalent.
3. Avoid overlapping time when the same work appears in multiple sources.
4. Compare the total with the target working day, approximately 9 hours or 540 minutes by default.
5. Show the proposed entries, total minutes, total hours, and difference from the target.
6. Ask the user to confirm or adjust task grouping, durations, missing work, and inferred priorities.
7. Do not silently inflate durations or fabricate work to reach exactly 9 hours. A reasonable approximate total is valid after user confirmation.

Infer priority using, in order: explicit Plane priority, urgency or deadline evidence, business impact, blocking impact, and user context. Never infer high priority solely from time spent. Ask for correction when priority evidence is weak or conflicting.

## 7. Finalize

Generate the final English copy-and-paste blocks only after the user confirms the proposed grouping, priorities, and durations. Then include:

```text
Total time in hours: 9
Total time in minutes: 540
```

Before returning the report, verify:

- all NextTask content is in natural, professional English;
- each task represents meaningful work without excessive decomposition;
- every description states work performed and its outcome;
- hour and minute values are equivalent;
- the sum is correct;
- no evidence is counted twice;
- no unsupported claims or sensitive details appear.

If evidence is unavailable, state the gap and rely on explicit user input. Never imply that NextTask was updated; this skill produces entries for manual submission only.
