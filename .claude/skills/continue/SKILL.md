---
name: continue
version: 2.4.0
description: Resume development with smart session continuation. Reads session handoff files, analyzes git state, and determines the best path forward.
trigger: manual
depends-on: []
references: []
---
______________________________________________________________________

## name: continue description: Resume development with smart session continuation. Reads session handoff files, analyzes git state, and determines the best path forward. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Resume development. Execute this smart continuation workflow:

## Current Git State (auto-fetched)

- **Branch**: !`git branch --show-current`
- **Status**: !`git status --short`
- **Open PRs**: !`gh pr list --author @me --state open --limit 5 2>/dev/null || echo "No PRs or gh not configured"`

## 0. Read Latest Session Handoff

Check for the most recent session file:

```bash
ls -t docs/sessions/session-*.md 2>/dev/null | head -1
```

If a session file exists, read it as the primary context source. It contains: completed work, pending items, next steps, files to load, test status, and warnings.

## 1. Assess Git State

**Branch Scenarios:**

- **On feature branch with changes**: Mid-sprint, continue work
- **On feature branch, clean**: Sprint may be ready for PR or needs more work
- **On main with changes**: Should not happen - create branch first
- **On main, clean**: Between sprints, ready to start new work

## 1.5. Reload Working Context

If a session file was found, use its "Files Accessed" section to reload context efficiently:

- **Modified files:** Read all — they contain your changes from last session
- **Read (context-relevant):** Read these only if continuing the same story
- **Investigated (can skip):** Skip unless the user specifically asks about them

This avoids re-exploring files that were already investigated last session.

## 2. Assess Project State

- Read @docs/progress.md for last session
- Check for any sprint spec files in progress
- Read @docs/reference/BACKLOG_INDEX.md for current story status

## 3. Determine Continuation Point

**If on a feature branch:**

- This is an active sprint
- Check if PR already exists: `gh pr view`
- If PR exists and approved: offer to merge
- If PR exists awaiting review: wait or continue work
- If no PR: continue sprint implementation

**If on main:**

- Find current IN_PROGRESS story in backlog
- If found: switch to or create its feature branch
- If none: identify next TODO story for new sprint

## 4. Handle Pending PRs

If there are open PRs awaiting merge, offer to:

- Check review status
- Merge approved PRs
- Address review feedback

## 5. Quick Verification

Run the project's test command (from CLAUDE.md Commands section) to verify everything works:

```bash
# Use the project's test command from CLAUDE.md
```

If mid-sprint: Resume from last checkpoint
If starting new sprint: Execute sprint-start workflow

## 5.5. Health Dashboard

Present a quick status pulse:

```bash
# Last commit time and branch
git log -1 --format="%cr on %D"
# Uncommitted file count
git status --short | wc -l
# Session file age
ls -lt docs/sessions/session-*.md 2>/dev/null | head -1
```

```markdown
### Session Health
- **Tests:** [passing/total] ([green/red])
- **Last commit:** [time ago] on [branch]
- **Open changes:** [count] files
- **Session file:** [age — e.g., "2 days ago" or "none found"]
```

## 6. Present Options

Based on analysis, present relevant options:

- "Continue current sprint on branch \[branch-name\]"
- "**Complete sprint**: run agents, update docs, create PR"
- "Merge approved PR #\[number\] and start next story"
- "Address review feedback on PR #\[number\]"
- "Start next story \[ID\]: \[title\] (will create new branch)"
- "Commit and push current changes to feature branch"

## 7. Wait for Direction

Present findings and wait for user choice before proceeding.
