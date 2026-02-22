______________________________________________________________________

## name: sprint-end description: Complete a sprint by discovering work from git, running quality gates, updating docs, creating PR, and merging to main. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Ending the sprint. Discovering and wrapping up all work on the current branch.

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

Analyze:

- Branch name
- All commits since branching from main
- All files changed (added, modified, deleted)
- Stories completed (parse from commit messages if using conventional format)

## 2. Quality Gates

All must pass before proceeding. Run in parallel where possible:

### 2a. Tests

Run the project's test command (from CLAUDE.md Commands section). If the project has multiple test suites (e.g., backend + frontend), run all of them.

**If tests fail:** Stop. Fix failures first, then re-run `/sprint-end`.

### 2b. Test Protection

Compare test metrics on branch vs main:

```bash
# Get test count on main
git stash && git checkout main
# Run test count command (framework-specific)
git checkout - && git stash pop
```

- **Test count gate:** Total tests on branch must be >= total on main. Fail if tests were deleted.
- **Coverage delta gate:** Coverage for touched files must not decrease. Warn if overall coverage drops.
- **Assertion density:** Check for weakened assertions (e.g., `toBeTruthy` replacing specific `toBe` checks).

If test count decreased, present the deleted tests and ask user to confirm before proceeding.

### 2c. Quality Agents

Run the following quality agents (forked context to keep main clean):

- **Code Quality Agent** (`/code-quality`): Complexity, duplication, patterns
- **Test Validator Agent** (`/test-validator`): Coverage, quality, TDD compliance

If auth/credentials/data/security files were changed:

- **Security Audit Agent** (`/security-audit`): Vulnerabilities, secrets, SQL injection

Present agent findings to user. If critical issues found, stop and fix first.

### Recovery: If Quality Gates Fail

- **Tests fail:** Stop. Show failures. Ask user to fix or run `/debug-session <error>`.
- **Test count decreased:** Show which tests were removed. Require explicit user approval to proceed.
- **Quality agents find critical issues:** Show findings. Security issues must be fixed. Others: user decides fix now vs. log to `docs/technical-debt.md`.
- **CI fails after push:** Diagnose locally, commit fix, push. Never force push.

## 3. Documentation Updates

Based on what was done in the sprint, update relevant documentation:

### 3a. Epic File (if story IDs are in commits)

- Find the epic file: `docs/reference/backlog/E##-*.md`
- Mark completed stories as `[DONE]`
- Add completion date

### 3b. BACKLOG_INDEX.md

- Update Done/In Progress/TODO counts for affected epics

### 3c. progress.md

- Add sprint entry to recent sprints
- Update Current Sprint section
- Update test count metrics

### 3d. CLAUDE.md

- Update Current Focus section if epic status changed (e.g., epic completed)
- Update completed story counts

### 3e. Commit documentation updates

```bash
git add docs/ CLAUDE.md
git commit -m "docs: update progress and backlog for sprint completion"
```

## 4. Push and Create PR

### 4a. Push branch

```bash
git push -u origin $(git branch --show-current)
```

### 4b. Create Pull Request

Use GitHub CLI with a summary derived from the commits and changes:

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

```bash
gh pr checks --watch
```

If CI fails, diagnose and fix. Commit fixes and push.

## 6. Merge and Clean Up

Once CI is green and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout main
git pull origin main
```

### Worktree Cleanup

If running in a worktree (detected in step 1):

```bash
# From the main working tree, remove the worktree
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

Output a summary:

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

## Rules

- NEVER merge without CI passing
- NEVER force push or skip hooks
- NEVER merge without running quality agents
- NEVER merge if test count decreased (without explicit user approval)
- ALWAYS discover state from git — assume no prior context
- ALWAYS update documentation for completed stories
- ALWAYS squash merge to keep main history clean
- ALWAYS clean up worktrees after merge
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
