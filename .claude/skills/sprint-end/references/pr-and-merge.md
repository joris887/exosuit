# Steps 3.5–6: Commit, PR, CI, and Merge

Reference loaded by `/sprint-end` Steps 3.5 through 6. Covers documentation commit, PR creation, CI, and merge.

## 3.5 Commit Documentation Artifacts

Commit all documentation changes as a separate commit. This ensures documentation is preserved even if the push or PR step fails or is skipped.

```bash
# Check if there are uncommitted documentation changes
if ! git diff --quiet docs/ CLAUDE.md 2>/dev/null || \
   ! git diff --quiet --cached docs/ CLAUDE.md 2>/dev/null || \
   git ls-files --others --exclude-standard docs/ | grep -q .; then
    git add docs/ CLAUDE.md
    git commit -m "docs(sprint): update sprint documentation and session artifacts

Co-Authored-By: Claude <noreply@anthropic.com>"
fi
```

If there are no documentation changes, skip this step gracefully. This commit happens regardless of whether push will be performed.

### PR Size Check

```bash
LINES_CHANGED=$(git diff --stat $DEFAULT_BRANCH...HEAD | tail -1 | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | paste -sd+ | bc 2>/dev/null || echo "0")
```

If `LINES_CHANGED` exceeds 400 lines, warn:
> **Large PR detected** ([LINES_CHANGED] lines changed). Research shows PRs in the 200–400 line range have 40% fewer defects, and each additional 100 lines adds ~25 minutes of review time. Consider breaking this into stacked PRs for more effective review.

<IF condition="CODEOWNERS exists or CONTRIBUTORS > 1">
If `LINES_CHANGED` exceeds 200 lines, additionally note:
> For teams, `docs/reference/TEAM_WORKFLOW.md` recommends capping AI-generated PRs at 200 lines. Consider using stacked PRs to break this into reviewable chunks.
</IF>

Offer to proceed as-is or help split the PR.

<IF condition="User wants to split the PR">
**PR Splitting Strategies:**

1. **By story:** Create one PR per completed story. Cherry-pick each story's commits to a new branch:
   ```bash
   git checkout $DEFAULT_BRANCH
   git checkout -b feat/<story-description>
   git cherry-pick <story-commit-hashes>
   git push -u origin feat/<story-description>
   gh pr create --title "<type>(<scope>): <story summary>"
   ```
   Repeat for each story. Each PR should be ≤400 LOC.

2. **By layer:** Split into backend/frontend/infrastructure PRs if changes span layers.

3. **By module:** Split into separate PRs per module or package boundary.

Create split PRs in dependency order so CI passes on each. Reference the sprint spec in each PR for context. See `docs/reference/GIT_WORKFLOW.md` → Stacked PRs for advanced tooling.
</IF>

## 4. Push and Create PR

```bash
git push -u origin $(git branch --show-current)
```

Create PR with GitHub CLI. The repository includes a PR template (`.github/pull_request_template.md`) — fill in its sections rather than providing a raw body:

```bash
gh pr create --title "<type>(<scope>): <summary>" --body "$(cat <<'EOF'
## Type of Change

- [x] <matching type from template>

## Summary
<1-3 sentences summarizing what was done and why>

## Changes
<list of key changes, grouped by area>

## Test Evidence
<paste test output from step 2>

## Quality Gates
- [x] All tests pass
- [x] Test count did not decrease
- [x] Code quality agent reviewed
- [x] Test validator agent reviewed
- [x/n/a] Security audit reviewed
- [x] No hardcoded secrets introduced
- [x] Coding standards followed

## Self-Review Checklist
- [x] I read the diff and it matches the intent
- [x] No debug code or TODOs left behind
- [x] Error handling is appropriate
- [x] New code follows existing patterns
- [x/n/a] Documentation updated where needed

## AI Assistance
- **AI-assisted:** <list components where AI generated or significantly modified code>
- **Human-written:** <list components written or heavily edited by hand, or "N/A">
- **AI review focus:** <specific areas where reviewers should check for AI anti-patterns>

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## 5. Wait for CI

<IF condition="CI is configured (.github/workflows/, .gitlab-ci.yml, etc. detected)">
```bash
gh pr checks --watch
```
If CI fails, diagnose and fix. Commit fixes and push.

**Note:** The framework includes a Claude PR Review workflow (`.github/workflows/claude-pr-review.yml`). If configured with an `ANTHROPIC_API_KEY` secret, it runs automated code review on PRs. Check its status alongside other CI checks.
</IF>
<ELSE>
No CI detected — the local quality gates in step 2 serve as verification. Proceed to merge.
</ELSE>

### Human Review Handling

<IF condition="CODEOWNERS exists or PR requires human reviewers">
After CI passes, check for required human reviewers:

```bash
gh pr view --json reviewRequests,reviews
```

**If human review is required:**
1. List required reviewers from CODEOWNERS or branch protection rules
2. **Remind reviewers of Layer 4 focus** (see `docs/reference/TEAM_WORKFLOW.md` → Code Review Process):
   - Architecture alignment with documented ADRs
   - Business logic correctness — right problem solved?
   - Intent verification — matches the story spec?
   - AI-specific anti-patterns: phantom deps, code duplication, tautological tests, over-engineering
3. Request reviews if not already requested:
   ```bash
   gh pr edit --add-reviewer <reviewer>
   ```
3. Present to user:
   ```markdown
   **Human review required before merge.**
   - Reviewer(s): [list]
   - Status: [Pending / Approved / Changes Requested]

   Options:
   → Wait for review (recommended)
   → Continue to other work while waiting (`/story-cycle` or `/sprint-start --worktree`)
   ```
4. If "Changes Requested": guide user through addressing feedback, pushing updates, and re-requesting review

**If no human review required:** Proceed to merge.
</IF>

## 6. Merge and Clean Up

Once CI is green (or local gates passed) and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
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
