# Git Workflow Reference

Practical guide for git in AI-assisted, sprint-based development. For enforcement rules, see `.claude/rules/git.md`. For hook-level blocking, see `.claude/hooks/rules/safety.patterns`.

## Branching Model

**Modified GitHub Flow** with optional sprint scoping.

- **`main`** — always deployable, protected, receives only squash-merged PRs
- **`sprint-<N>`** — sprint branch, cut from main at sprint start, merged at sprint end
- **`feat/<description>`** — story/feature branches, one per story, branched from sprint branch (or main for solo)
- **`fix/<description>`** — bug fix branches
- **`hotfix/<description>`** — critical production fixes (branch from main, merge directly)

### Branch Naming

Lowercase with hyphens, type prefix aligned with Conventional Commits:

```
feat/user-authentication
fix/header-css-overflow
refactor/extract-query-builder
docs/update-api-reference
test/add-auth-integration-tests
chore/upgrade-dependencies
hotfix/critical-auth-bypass
sprint-3
```

With ticket IDs: `feat/PROJ-123-payment-processing`

Regex: `^(feat|fix|hotfix|refactor|docs|test|chore|sprint)[\/-][a-z0-9][a-z0-9-]*$`

### Solo vs Team

| Concern | Solo developer | Team (2+) |
|---------|---------------|-----------|
| Sprint branch | Optional — branch from main directly | Recommended — coordinates multi-story work |
| Review | Self-review, 24h cooling period before merge | 1-2 reviewers, first response within 4 hours |
| Merge queue | Skip | Enable when team exceeds 3 contributors |
| CODEOWNERS | Skip | Configure for critical paths |

### Branch Lifecycle

All branches live at most 1 week. Branches older than 1 sprint are stale. After merge, branches are auto-deleted (GitHub setting) with local cleanup via `git fetch --prune`.

## Commit Format

**Conventional Commits v1.0.0**, enforced by hooks.

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Required Types

| Type | Purpose | SemVer |
|------|---------|--------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only | — |
| `style` | Formatting, no logic change | — |
| `refactor` | Code change, no feature/fix | — |
| `perf` | Performance improvement | — |
| `test` | Adding or fixing tests | — |
| `build` | Build system or dependencies | — |
| `ci` | CI configuration | — |
| `chore` | Maintenance tasks | — |

### Breaking Changes

Signal with `!` after type or `BREAKING CHANGE:` footer:

```
feat(api)!: change authentication to OAuth2

BREAKING CHANGE: Bearer token format changed from JWT to opaque tokens.
All existing tokens must be re-issued.
```

### Atomic Commits

Each commit encapsulates **one logical unit of change**, leaves the codebase working, and can be described in a single sentence. During AI-assisted development: commit after each completed logical step — not after each file edit, but after each meaningful, testable change.

### AI Attribution

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

Added automatically by Claude Code. Requires a blank line between description and trailers. Note: `git blame` only shows the primary author — co-author attribution lives in commit message metadata.

### Examples

```
feat(auth): add JWT token validation middleware

fix(api): handle empty request body gracefully

refactor(db): extract query builder from repository

fix(pipeline): prevent race condition in batch processing

The worker pool was not draining before shutdown, causing
in-flight items to be silently dropped. Added graceful
shutdown with a 30-second drain timeout.

Closes #142
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Pull Requests

### Size Limits

- **Target:** ≤500 LOC per PR
- **Ceiling:** 1000 LOC. Beyond ceiling, split to recover reviewer signal — defect detection drops sharply at large diffs.
- AI tools deliver larger vertical slices than humans — that's a benefit, not a problem to suppress. Scope by *outcome* (one user-observable thing), not by LOC count, and split only when the outcome itself can be split.

### Template

PRs must include these sections:

1. **What** — summary of changes (1-3 sentences)
2. **Why** — motivation, linked issue/ticket
3. **How tested** — test commands run, verification steps
4. **Type** — checkbox (feat/fix/refactor/docs/chore)
5. **Reviewer notes** — areas of concern, AI-specific review focus

### Draft PRs

Create draft PRs at the start of every feature for early CI feedback. Draft PRs block merging and suppress CODEOWNERS notifications.

### Review Protocol for AI-Generated Code

1. Read **tests first** to understand intended behavior
2. Focus on **logic and behavioral risks**, not syntax
3. Watch for **hallucinated APIs**, deleted tests, ignored constraints
4. Use line-level staging via Git GUIs for selective acceptance
5. Require **test evidence**, not AI explanation

### Ship/Show/Ask Decision Framework

Not every change needs the same review depth:

| Category | When | Action |
|----------|------|--------|
| **Ship** | Trivial fixes, typos, docs, formatting | Merge directly (CI must still pass) |
| **Show** | Standard features, bug fixes | Create PR, merge after CI, review async |
| **Ask** | Architecture changes, security, >1000 LOC, breaking changes | Create PR, wait for review before merge |

- **Solo developers:** Default to Ship/Show. Use Ask for architectural changes.
- **Teams:** Default to Show/Ask. See `TEAM_WORKFLOW.md` for risk-calibrated review requirements.
- **AI-generated code:** Default to Show minimum — AI code benefits from human review even on solo projects.

## Merging

- **Default:** Squash and merge (enforced via GitHub repository settings)
- **Exception:** Merge commit allowed for PRs >1000 LOC or infrastructure changes needing debug granularity
- **Post-merge:** Auto-delete head branches; local cleanup via `git fetch --prune`
- **Merge queue:** Enable when team exceeds 3 contributors

### Stacked PRs for Large Features

When a feature genuinely cannot be delivered as one outcome under 1000 LOC, break it into 2-4 stacked PRs:

1. Each PR builds on the previous, targeting ≤500 LOC
2. Base each subsequent branch on the previous PR's branch
3. Review and merge bottom-up (base PR first)
4. Use `git rebase --update-refs` (Git 2.38+) to maintain the stack after rebasing

```bash
# Create a stack
git checkout -b feat/auth-models        # PR 1: data models
git checkout -b feat/auth-service       # PR 2: business logic (based on PR 1)
git checkout -b feat/auth-api           # PR 3: API endpoints (based on PR 2)

# After PR 1 merges and main updates:
git checkout feat/auth-service
git rebase main --update-refs           # rebases both remaining branches
```

Tooling: Graphite, git-town, or GitHub's auto-merge can simplify stack management. For solo developers, manual stacking with `--update-refs` is sufficient.

## Sprint Flow

```bash
# 1. Start sprint (or use /sprint-start)
git checkout main && git pull
git checkout -b sprint-3

# 2. Work on stories — atomic commits for each logical unit
git add src/auth/ tests/auth/
git commit -m "feat(auth): add JWT validation middleware"

git add src/auth/refresh.ts tests/auth/refresh.test.ts
git commit -m "feat(auth): add token refresh endpoint"

# 3. Ship sprint (or use /sprint-end)
git push -u origin sprint-3
gh pr create --title "feat(auth): JWT authentication" --body "..."

# 4. After review, squash merge — all commits become one clean entry in main
gh pr merge --squash --delete-branch

# 5. Clean up
git checkout main && git pull
git fetch --prune
```

## AI Checkpointing

### Within a Session

- Claude Code captures checkpoints before each file modification (<50ms, <100KB)
- Use `/rewind` or `Esc+Esc` for instant rollback (code, conversation, or both)
- Checkpoints complement git — they don't replace it

### Git-Level Checkpointing

Commit after each completed logical unit using Conventional Commits. These intermediate commits are squashed before merging to main — so commit freely during development.

**Critical rule:** Allow `git add` and `git commit` automatically, but **never auto-allow `git push`**. Local commits are always safe to amend, squash, or reset. Pushing is irreversible in shared contexts.

## Safe Rollback Hierarchy

When AI-generated code needs to be undone, use the safest option available:

| Level | Command | When to use | Safety |
|-------|---------|-------------|--------|
| 1 | `/rewind` | Within current session | Instant, no git impact |
| 2 | `git restore .` or `git restore <file>` | Discard uncommitted changes (Git 2.23+) | Safe, local only |
| 3 | `git reset --soft HEAD~1` | Undo last commit, keep changes staged | Safe, local only |
| 4 | `git stash` or `git stash --include-untracked` | Temporarily shelve changes | Safe, retrievable |
| 5 | `git revert <hash>` | Undo after push (creates new commit) | Safe for shared branches |
| 6 | `git reset --hard` | Nuclear option | **Blocked by default** — requires manual override |

### Recovering from Failed AI Implementation

```bash
# Option A: Discard uncommitted changes only
git restore .                    # discard all uncommitted tracked file changes
git clean -dn                   # preview untracked files that would be removed

# Option B: Soft reset (keep changes for review)
git reset --soft HEAD~3          # undo last 3 commits, changes remain staged
git diff --cached                # review what was done
# selectively re-commit what's good

# Option C: Revert after push (safe for shared branches)
git revert <hash>                # creates a new commit that undoes the change

# Option D: Start fresh from main
git checkout main && git pull
git checkout -b feat/retry-feature
```

## Parallel Development with Worktrees

```bash
# Create isolated worktree for parallel AI session
claude -w feature-payments       # creates .claude/worktrees/feature-payments/

# Or manually:
git worktree add ../project-sprint-4 -b sprint-4
```

- Choose **truly independent tasks** to avoid cross-worktree conflicts
- Limit to 4-5 concurrent worktrees on a 32GB machine
- Run `git worktree prune` regularly after removing worktrees

## Blocked Operations

These commands are **blocked by deterministic hooks** (not advisory — cannot be bypassed):

| Command | Why blocked | Safe alternative |
|---------|------------|-----------------|
| `git push --force` / `-f` | Rewrites shared history | `--force-with-lease` if necessary |
| `git reset --hard` | Destroys uncommitted work | `git stash` or `git reset --soft` |
| `git clean -f` | Permanently deletes untracked files | `git clean -n` (dry run first) |
| `git branch -D` | Force-deletes unmerged branch | `git branch -d` (safe delete) |
| `git checkout .` | Discards all changes | `git restore .` (Git 2.23+) or `git stash` |
| `--no-verify` | Skips safety hooks | Fix the issue that the hook caught |
| `rm -rf .git` | Destroys repository | Never do this |
| Direct push to main | Bypasses review | Create a PR |

## GitHub Branch Protection (main)

Recommended settings for the default branch:

- Require pull request before merging (1+ approval for teams; 0 approvals with required status checks for solo)
- Require status checks to pass (lint, test, build)
- Require linear history (enforces squash/rebase)
- Disable force pushes and deletions
- Include administrators (no bypass)

Migrate to **GitHub Rulesets** for organization-wide rules and evaluate mode.

## Rules Summary

- Never push directly to the default branch — always via PR
- Never force push — use `--force-with-lease` only if absolutely necessary
- Always use conventional commit format: `<type>(<scope>): <description>`
- Squash merge to main for clean history
- Delete feature branches after merge
- Never skip hooks (`--no-verify`)
- When a hook fails, the commit did NOT happen — create a NEW commit after fixing
- Keep PRs at target ≤500 LOC, ceiling 1000 LOC. Beyond ceiling, split to recover reviewer signal.
- Commit after each logical unit of work during development
- Never auto-push — pushing requires explicit instruction
