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

### 2b. Quality Agents

Run the following quality agents (forked context to keep main clean):

- **Code Quality Agent** (`/code-quality`): Complexity, duplication, patterns
- **Test Validator Agent** (`/test-validator`): Coverage, quality, TDD compliance

If auth/credentials/data/security files were changed:

- **Security Audit Agent** (`/security-audit`): Vulnerabilities, secrets, SQL injection

Present agent findings to user. If critical issues found, stop and fix first.

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
**Tests:** [total count] passing
**Documentation:** Updated [list of docs updated]

**Main is clean and up to date.**
```

## Rules

- NEVER merge without CI passing
- NEVER force push or skip hooks
- NEVER merge without running quality agents
- ALWAYS discover state from git — assume no prior context
- ALWAYS update documentation for completed stories
- ALWAYS squash merge to keep main history clean
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
