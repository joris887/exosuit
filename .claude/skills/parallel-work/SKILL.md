---
name: parallel-work
version: 2.4.0
description: Manage git worktrees for parallel Claude Code instances working on different stories. List, create, and clean up worktrees.
trigger: manual
depends-on: []
references: []
---
______________________________________________________________________

## name: parallel-work description: Manage git worktrees for parallel Claude Code instances working on different stories. List, create, and clean up worktrees. argument-hint: \[list|create|cleanup\] disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Manage parallel development worktrees.

## Overview

Git worktrees allow multiple Claude Code instances to work on different stories simultaneously, each with its own branch and working directory.

## Commands

### List Active Worktrees

```bash
git worktree list
```

Show all active worktrees with their branches and status.

### Create a Worktree for a Story

If `$ARGUMENTS` contains "create" or a story description:

1. Determine the branch name from the story: `feature/<story-id>-<description>`
2. Create the worktree:

```bash
git worktree add ../<project>-<story-id> -b feature/<story-id>-<description>
```

3. Output:

```markdown
### Worktree Created

**Path:** `../<project>-<story-id>`
**Branch:** `feature/<story-id>-<description>`

To start working:
1. Open a new Claude Code instance in `../<project>-<story-id>`
2. Run `/story-cycle <story-description>`

The worktree shares the git history but has its own working tree.
```

### Clean Up Merged Worktrees

If `$ARGUMENTS` contains "cleanup":

1. List all worktrees: `git worktree list`
2. For each worktree (except the main one):
   - Check if its branch has been merged to main: `git branch --merged main | grep <branch>`
   - If merged: `git worktree remove <path>` and `git branch -d <branch>`
3. Prune stale worktrees: `git worktree prune`

Output:

```markdown
### Worktree Cleanup

**Removed:** [list of removed worktrees]
**Active:** [list of remaining worktrees]
**Pruned:** [count of stale entries]
```

### Default (no arguments or "list")

Show the list of active worktrees and offer options:

```markdown
### Active Worktrees

| Path | Branch | Status |
|------|--------|--------|
| [path] | [branch] | [ahead/behind main] |

**Options:**
- Create a new worktree for a story
- Clean up merged worktrees
```

## When to Use Worktrees

- **Use worktrees** when you want to work on multiple stories at the same time with separate Claude Code instances
- **Use regular branches** when you work on stories sequentially (the default)
- **Worktree per story** is the recommended pattern — each story gets its own worktree and branch

## Coordination

When using `CLAUDE_CODE_TASK_LIST_ID` environment variable, multiple Claude Code instances can share a task list for coordination. Set the same task list ID across instances to see shared tasks.

## Rules

- Always create worktrees from the main working tree (not from another worktree)
- Always base worktree branches on an up-to-date main
- Clean up worktrees after their branches are merged
- Each worktree should have its own sprint/story branch
