---
name: undo-work
version: 3.0.1
description: Safely discard or revert failed implementation attempts and restore a clean working state.
trigger: manual
depends-on: []
references: []
---
______________________________________________________________________

## name: undo-work description: Safely discard or revert failed implementation attempts and restore a clean working state. argument-hint: [--soft | --hard | --story] disable-model-invocation: true user-invocable: true allowed-tools: Bash, Read, Glob, Grep

Safely undo work when an implementation attempt has gone wrong. Provides structured rollback with safeguards against accidental data loss.

Arguments: **$ARGUMENTS**

## 1. Assess Current State

```bash
git status
git log --oneline -10
git stash list
```

Determine the situation:
- **Uncommitted changes only** → Soft or hard reset options
- **One or more commits on feature branch** → Revert commits or reset branch
- **Mid-story-cycle** → Full story rollback

Present findings to the user before proceeding.

## 2. Confirm Scope with User

<HARD-GATE>
NEVER discard work without explicit user confirmation. Always show exactly what will be lost.
</HARD-GATE>

Show the user:
- Files that will be affected (list modified/added/deleted files)
- Commits that will be reverted (if any)
- Whether there's uncommitted work at risk

Ask the user to confirm one of these rollback levels:

| Level | What it does | When to use |
|-------|-------------|-------------|
| **Soft** | Stash uncommitted changes (recoverable via `git stash pop`) | "Let me save this aside and try a different approach" |
| **Hard** | Discard all uncommitted changes | "This attempt is wrong, start fresh from last commit" |
| **Story** | Reset branch to before the story's commits | "The whole story implementation needs to restart" |

## 3. Execute Rollback

### Soft (stash)

```bash
git stash push -m "undo-work: <user-provided reason or auto-description>"
```

Report: "Changes stashed. Use `git stash pop` to recover if needed."

### Hard (discard uncommitted)

```bash
git diff --stat          # Show what will be lost — confirm with user
git checkout -- .
git clean -fd            # Remove untracked files
```

### Story (reset branch to before story commits)

1. Identify the commit where the story started:
```bash
git log --oneline main..HEAD
```

2. Show the user exactly which commits will be removed.

3. After confirmation:
```bash
git reset --soft <commit-before-story>    # Keep changes staged (safest)
```

<IF>User wants a clean slate (not just unstaged)</IF>
```bash
git reset --hard <commit-before-story>
```

## 4. Verify Clean State

```bash
git status
git log --oneline -5
```

Confirm the working directory is in the expected state.

## 5. Document (Optional)

<IF>The failed attempt has useful learnings</IF>

Suggest the user note what went wrong in the current session context so the next attempt avoids the same pitfalls. Do NOT auto-create documentation files.

## Rules

- NEVER execute destructive git commands without showing the user exactly what will be affected and getting explicit confirmation
- NEVER force push after a reset — the rollback is local only
- Always prefer `git stash` (recoverable) over `git reset --hard` (permanent) unless the user explicitly requests hard reset
- If on `main` branch, REFUSE to reset — only feature/sprint branches
- If there are commits that have already been pushed to remote, WARN the user that local reset won't affect the remote
