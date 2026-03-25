---
name: sprint-start
version: 2.6.0
description: Pre-sprint checks and feature branch creation. Ensures clean state before starting work. Supports git worktrees for parallel development.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[branch-name] [--worktree]"
---
______________________________________________________________________

## sprint-start

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"sprint-start\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

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

### 1c. Ensure on default branch and up to date

Read the **Default branch** from CLAUDE.md's Git Workflow section. If not set, detect it at runtime:

```bash
# Read from CLAUDE.md first, fall back to detection
DEFAULT_BRANCH=$(grep -oP '^\- \*\*Default branch:\*\* \K\S+' CLAUDE.md 2>/dev/null)
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
fi
if [ -z "$DEFAULT_BRANCH" ]; then
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            DEFAULT_BRANCH="$branch"
            break
        fi
    done
fi
```

```bash
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
```

If the default branch was detected at runtime (not in CLAUDE.md), persist it by updating CLAUDE.md's Git Workflow section.

### 1d. Verify tests pass on default branch

Read CLAUDE.md Commands section to find the project's test command.

- **If test command exists:** Run it. If tests fail on the default branch, stop and alert user — default branch should always be green.
- **If NO test command configured:** Skip this check. Note in output: "No test command configured — consider running /bootstrap to set up."

## 2. Create Feature Branch

Determine the next sprint number by reading `docs/progress.md` and finding the highest sprint number, then adding 1.

### Standard Mode (default)

Create a new branch from the default branch:

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

<IF condition="docs/reference/PRD_SUMMARY.md exists">
**Sprint Definition of Done** (derived from PRD): Read PRD Section 6 (NFRs) and Section 7 (scope boundaries). Include applicable thresholds in the sprint summary so they're visible throughout the sprint:
- Performance targets from NFRs (e.g., "API < 200ms P95")
- Security requirements from NFRs (e.g., "all PII encrypted")
- Implementation boundaries from Section 7 (Always/Ask first/Never rules)
</IF>

Output a summary:

```markdown
### Sprint Ready

**Branch:** `sprint-<number>`
**Mode:** [Standard / Worktree at ../<path>]
**Main status:** Tests passing, up to date
**Open PRs:** None (or list any that exist)
**Definition of Done:** [from PRD NFRs + boundaries, or "Standard (no PRD)"]

Ready to start work. Use `/story-cycle <story-description>` to deliver a story.
```

## What This Skill Does NOT Do

- Does not load story context (that's `/story-cycle`'s job)
- Does not run analysis agents
- Does not create sprint spec documents
- Does not update epic files or backlog
- Does not assume any particular project structure
