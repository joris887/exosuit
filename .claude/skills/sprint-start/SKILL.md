______________________________________________________________________

## name: sprint-start description: Pre-sprint checks and feature branch creation. Ensures clean state before starting work. Supports git worktrees for parallel development. argument-hint: \[branch-name\] \[--worktree\] disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Starting a new sprint.

## 1. Pre-flight Checks

Verify the workspace is ready for new work:

### 1a. Check for open PRs

```bash
gh pr list --author @me --state open
```

**If open PRs exist:**

- Check if any are approved → merge them: `gh pr merge --squash --delete-branch`
- If awaiting review → inform user and ask whether to proceed or wait

### 1b. Verify clean working tree

```bash
git status
```

**If uncommitted changes exist:**

- Warn user — they must commit, stash, or discard before proceeding
- Do NOT proceed with dirty working tree

### 1c. Ensure on main and up to date

```bash
git checkout main
git pull origin main
```

### 1d. Verify tests pass on main

Run the project's test command (detected by `/bootstrap`, found in CLAUDE.md Commands section):

```bash
# Use the project's test command from CLAUDE.md
# Examples: just ci, npm test, pytest, cargo test, swift test, go test
```

If tests fail on main, stop and alert user — main should always be green.

## 2. Create Feature Branch

Determine the next sprint number by reading `docs/progress.md` and finding the highest sprint number, then adding 1.

### Standard Mode (default)

Create a new branch from main:

```bash
git checkout -b sprint-<number>
```

### Worktree Mode (when `--worktree` is in $ARGUMENTS or user requests it)

Create an isolated worktree for parallel development:

```bash
# Create worktree in sibling directory
git worktree add ../$(basename $(pwd))-sprint-<number> -b sprint-<number>
```

Inform the user:

```markdown
**Worktree created:** `../<project>-sprint-<number>`

To work in this worktree, open a new Claude Code instance in that directory.
Each worktree has its own branch and working tree, so you can work on multiple stories in parallel.

**Important:** When done, run `/sprint-end` from within the worktree. It will clean up after merge.
```

### Branch Naming

- Branch naming convention: `sprint-<number>` (e.g., `sprint-001`, `sprint-002`)
- The number is always the next sequential sprint number

## 3. Done

Output a summary:

```markdown
### Sprint Ready

**Branch:** `sprint-<number>`
**Mode:** [Standard / Worktree at ../<path>]
**Main status:** Tests passing, up to date
**Open PRs:** None (or list any that exist)

Ready to start work. Use `/story-cycle <story-description>` to deliver a story.
```

## What This Skill Does NOT Do

- Does not load story context (that's `/story-cycle`'s job)
- Does not run analysis agents
- Does not create sprint spec documents
- Does not update epic files or backlog
- Does not assume any particular project structure
