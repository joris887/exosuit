---
name: sprint-end
version: 2.6.0
description: Use when the user wants to ship a sprint's work to main via PR.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/quality-gates.md]
---
______________________________________________________________________

## name: sprint-end description: Use when the user wants to ship a sprint's work to main via PR. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Ending the sprint. Discovering and wrapping up all work on the current branch.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 1. Discover Sprint State (from git, no assumptions)
  → [On main or no commits?] → STOP (nothing to ship)
  → 2. Quality Gates (tests, test protection, quality agents)
    → [All gates pass?]
      → NO: Fix issues → re-run gates
      → YES: 3. Documentation Updates (epics, backlog, progress)
        → 4. Push and Create PR
          → 5. Wait for CI
            → [CI green?]
              → NO: Fix → push → re-check
              → YES: 6. Merge and Clean Up (squash, delete branch, worktree)
                → 7. Sprint Complete Summary → DONE
```

## 1. Discover Sprint State

No assumptions about previous context. Discover everything from git:

```bash
git branch --show-current
git log main..HEAD --oneline
git diff --stat main...HEAD
git diff --name-only main...HEAD
```

**If on main:** There is no sprint to end. Inform user and stop.

**If no commits ahead of main:** Nothing to ship. Inform user and stop.

**If in a worktree:** Detect with `git rev-parse --git-common-dir`. Note the worktree path for cleanup in step 6.

Analyze: branch name, all commits since branching, all files changed, stories completed (parse from commit messages).

## 2. Quality Gates

**Mindset:** Assume there are problems. Your job is to find them. Your first assessment is almost never "all clear."

All gates must pass before proceeding. Read `references/quality-gates.md` for detailed checks (tests, test protection, quality agents, recovery).

<HARD-GATE>
Do NOT proceed to documentation updates, PR creation, or merge if ANY quality gate has failed. All gates must pass. "It's probably fine" is not a pass.
</HARD-GATE>

## 3. Documentation Updates

Based on what was done in the sprint, update relevant documentation:

- **Epic file** (`docs/reference/backlog/E##-*.md`): Mark completed stories as `[DONE]`
- **BACKLOG_INDEX.md**: Update Done/In Progress/TODO counts
- **progress.md**: Add sprint entry, update metrics
- **CLAUDE.md**: Update Current Focus if epic status changed

Commit documentation updates:

```bash
git add docs/ CLAUDE.md
git commit -m "docs: update progress and backlog for sprint completion"
```

## 4. Push and Create PR

```bash
git push -u origin $(git branch --show-current)
```

Create PR with GitHub CLI:

```bash
gh pr create --title "<type>(<scope>): <summary>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points summarizing what was done>

## Changes
<list of key changes>

## Testing
- [ ] All tests pass
- [ ] Test count did not decrease
- [ ] Quality agents reviewed

## Acceptance Criteria
<checklist from story/stories>

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## 5. Wait for CI

**If CI is configured** (detected `.github/workflows/`, `.gitlab-ci.yml`, etc.):

```bash
gh pr checks --watch
```

If CI fails, diagnose and fix. Commit fixes and push.

**If no CI detected:** The local quality gates in step 2 serve as verification. Proceed to merge.

## 6. Merge and Clean Up

Once CI is green (or local gates passed) and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout main
git pull origin main
```

**Worktree cleanup** (if running in a worktree detected in step 1):

```bash
WORKTREE_PATH=$(pwd)
cd <main-worktree-path>
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

Inform the user that the worktree has been removed and they should close the Claude Code instance that was using it.

Verify clean state:

```bash
git status
git log --oneline -3
```

## 7. Sprint Complete

```markdown
### Sprint Complete

**Branch:** `sprint-<number>` (merged and deleted)
**PR:** #<number> (<url>)
**Stories delivered:** [list]
**Commits squashed:** [count]
**Tests:** [total count] passing ([delta] vs main)
**Documentation:** Updated [list of docs updated]

**Main is clean and up to date.**
```

## Graceful Degradation

| Dependency   | If Missing                                          |
|--------------|-----------------------------------------------------|
| Sub-agents   | Run quality checks manually in the main context     |
| CI pipeline  | Local quality gates (step 2) serve as verification  |
| Test runner  | Warn user, skip test count delta, note in PR body   |
| Linter       | Skip lint check, note in PR body                    |
| Type checker | Skip typecheck, note in PR body                     |
| `gh` CLI     | Push manually, create PR via web UI                 |

## Project State Adaptation

Read CLAUDE.md Commands section before running quality gates:
- **If test command exists:** Run full test suite as part of quality gates
- **If NO test command:** Skip test gate, note "No test command configured" in PR body
- **If build command exists:** Include build verification in quality gates
- **If NO build command:** Skip build step

## Rules

- NEVER merge without CI passing (or local gates if no CI)
- NEVER force push or skip hooks
- NEVER merge without running quality agents
- NEVER merge if test count decreased (without explicit user approval)
- ALWAYS discover state from git — assume no prior context
- ALWAYS update documentation for completed stories
- ALWAYS squash merge to keep main history clean
- ALWAYS clean up worktrees after merge
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
