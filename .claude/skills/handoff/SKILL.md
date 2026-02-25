---
name: handoff
version: 2.5.0
description: Generate a structured handoff document for ending a development session. Saves to docs/sessions/ for the continue skill to read.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## handoff

Generate a comprehensive handoff for ending a development session:

## Phase 0: Validate Prerequisites

Before starting, verify:
- `docs/sessions/` directory exists (create if missing)
- No conflicting session file for today's date

If the directory is missing, create it silently and proceed.

## 1. Capture Current State

Analyze:

- Current branch: `git branch --show-current`
- Git status (uncommitted changes?)
- Open PRs: `gh pr list --author @me --state open`
- Current sprint spec (if exists)
- Last entries in @docs/progress.md

## 2. Document Progress

If work was done this session, ensure it's captured:

- Sprint spec updated with progress
- Any decisions documented
- Blockers noted

## 3. Generate Session File

Save a structured session file to `docs/sessions/session-YYYY-MM-DD.md`.

The file MUST start with YAML frontmatter for `/resume` searchability:

```markdown
---
date: YYYY-MM-DD
sprint: [current sprint number]
branch: [branch-name]
stories: [comma-separated story IDs worked on]
status: [completed | in-progress | blocked]
---

# Session Handoff — [YYYY-MM-DD]

## Git State
- **Branch:** [branch-name]
- **Uncommitted changes:** [yes/no — list if yes]
- **PR Status:** [Open #123 / Merged / Not created]

## Work Completed
- [x] [Task/story completed]
- [ ] [Task in progress — what's done, what remains]

## Key Decisions
- [Decision]: [Rationale]

## Blockers / Issues
- [Issue]: [Status]

## Files Accessed This Session

### Modified
- [path/to/file]: [what changed and why]

### Read (context-relevant)
- [path/to/file]: [why this file was important to understand]

### Investigated (can skip on resume)
- [path/to/file]: [explored but not relevant to current work]

## Test Status
- Passing: [count]
- Failing: [count]
- Coverage: [percentage if available]

## Next Steps (Minimal First Action)
1. [The single next thing to do — be very specific]
2. [Second priority]
3. [Third priority]

## Files to Load on Resume
- @[path] — [why this file is needed]

## Activity Summary

<!-- Populated from activity log if available -->

## Warnings / Gotchas
- [Any issues the next session should be aware of]
```

<IF condition="docs/sessions/.activity-log.jsonl exists">
**Activity summary:** Parse the activity log to populate the "Activity Summary" section with: total edits, total commands run, most-edited files (top 5), and edit-to-bash ratio.
</IF>

## 4. Create Next Session Prompt

Generate a ready-to-use prompt for the next session:

```markdown
## Next Session Start Prompt

Continue development.

### Context
- Last session: [date]
- Current story: [ID] - [title]
- Branch: [branch-name]
- PR Status: [Open #123 awaiting review / Not created / Merged]
- Status: [in progress / between sprints]

### Immediate Next Steps
1. [First thing to do]
2. [Second thing]
3. [Third thing]

### Files to Review
- @[path] - [why]

### Warnings/Gotchas
- [Any issues discovered]
```

## 4.5. Document Quality Check

After generating the session file, dispatch a fresh sub-agent to test it from a reader's perspective:

- **Agent type:** Explore (read-only, forked context)
- **Input:** ONLY the generated session file — no conversation history
- **Instructions:** "You are a developer starting a new session tomorrow with only this handoff file. (1) Can you understand what was done? (2) Are next steps specific enough to act on immediately? (3) Is any critical context missing? (4) Would you need to re-explore anything that could have been captured here?"

Review findings. Fix genuine gaps before finalizing.

## 5. Commit and PR Reminder

- If uncommitted changes: suggest commit message and push
- If sprint complete but no PR: suggest creating PR
- If PR approved but not merged: suggest merging

## 6. Update Persistent Files

Ensure these are current:

- @docs/progress.md: recent sprints updated
- @CLAUDE.md "Current Focus" is accurate

Output the session summary and next session prompt.
