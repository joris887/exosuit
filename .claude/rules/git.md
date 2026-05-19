---
paths:
  - "**"
---

# Git Workflow Rules

## Rule Effectiveness Tracking

When a rule influences your behavior (causes you to change an approach, block an action, or apply a check you wouldn't otherwise do), emit a tracking event:

```bash
echo "{\"type\":\"rule\",\"rule\":\"git\",\"action\":\"<what-it-caused>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## Branch Rules

- Never push directly to the default branch — all changes via pull request
- Branch naming: `<type>/<description>` (e.g., `feat/user-auth`, `fix/header-overflow`) or `sprint-<N>`
- Valid type prefixes: `feat`, `fix`, `hotfix`, `refactor`, `docs`, `test`, `chore`, `sprint`
- All branches live at most 1 week — branches older than 1 sprint are stale

## Commit Rules

- Always use Conventional Commits: `<type>(<scope>): <description>`
- Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`
- Breaking changes: use `!` after type or `BREAKING CHANGE:` footer
- Atomic commits: one logical unit per commit, codebase must work after each commit
- Commit after each completed logical step during AI-assisted development

## Merge Rules

- Always squash merge to main for clean history (exception: merge commit allowed for PRs >1000 LOC or infrastructure changes needing debug granularity)
- Delete feature branches after merge
- Keep PRs at target ≤500 LOC, ceiling 1000 LOC. Beyond 1000, split to recover reviewer signal — defect detection drops sharply at large diffs.

## Safety Rules (blocked by hooks — these are redundant guardrails)

- Never force push (`--force` or `-f`) — use `--force-with-lease` only if absolutely necessary
- Never use `git reset --hard` — use `git stash` or `git reset --soft` instead
- Never use `git clean -f` without `git clean -n` first
- Never use `git branch -D` — use `git branch -d` (safe delete)
- Never use `git checkout .` — use `git restore .` (Git 2.23+) or `git stash` instead
- Prefer `git restore` over `git checkout --` for discarding file changes
- Never skip hooks (`--no-verify`) — fix the issue the hook caught
- Never amend published commits without explicit user approval

## Hook Failure Recovery

When a pre-commit hook fails, the commit did NOT happen. Always create a NEW commit after fixing the issue. Never use `--amend` after a hook failure — amending modifies the PREVIOUS commit, risking lost work.

## Push Rules

- Never push without explicit user instruction — local commits are safe, pushes are irreversible
- Never push to the default branch directly — create a PR

## Rollback Safety

Use the safest rollback option available:
1. `/rewind` — within current AI session (no git impact)
2. `git restore .` or `git restore <file>` — discard uncommitted changes (Git 2.23+)
3. `git reset --soft HEAD~1` — undo last commit, keep changes staged
4. `git stash` or `git stash --include-untracked` — temporarily shelve changes (recoverable)
5. `git revert <hash>` — undo after push (safe for shared branches)
6. `git reset --hard` — blocked by default, requires manual override
