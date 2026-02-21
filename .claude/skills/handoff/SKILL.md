______________________________________________________________________

## name: handoff description: Generate a structured handoff document for ending a development session. Saves to docs/sessions/ for the continue skill to read. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Generate a comprehensive handoff for ending a development session:

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

Save a structured session file to `docs/sessions/session-YYYY-MM-DD.md`:

```markdown
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

## Files Modified This Session
- [path/to/file]: [what changed]

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

## Warnings / Gotchas
- [Any issues the next session should be aware of]
```

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

## 5. Commit and PR Reminder

- If uncommitted changes: suggest commit message and push
- If sprint complete but no PR: suggest creating PR
- If PR approved but not merged: suggest merging

## 6. Update Persistent Files

Ensure these are current:

- @docs/progress.md: recent sprints updated
- @CLAUDE.md "Current Focus" is accurate

Output the session summary and next session prompt.
