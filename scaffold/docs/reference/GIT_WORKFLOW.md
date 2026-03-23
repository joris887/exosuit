# Git Workflow Reference

Practical examples for the git workflow. For enforcement rules, see `.claude/rules/git.md`.

## Branch Naming

```
feature/<story-id>-<short-description>
feature/E3-S05-add-user-auth
feature/E7-S01-fix-hook-paths

sprint-<number>
sprint-3
```

## Commit Format

Conventional commits with type, scope, and description:

```
feat(auth): add JWT token validation
fix(api): handle empty request body gracefully
refactor(db): extract query builder from repository
test(auth): add integration tests for login flow
docs(readme): update installation instructions
chore(deps): upgrade express to 4.19.2
ci(actions): add type checking to PR workflow
```

Multi-line commits for context:

```
fix(pipeline): prevent race condition in batch processing

The worker pool was not draining before shutdown, causing
in-flight items to be silently dropped. Added graceful
shutdown with a 30-second drain timeout.

Closes #142
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Typical Sprint Flow

```bash
# Start sprint (or use /sprint-start)
git checkout main && git pull
git checkout -b sprint-3

# Work on stories, commit each
git add src/auth/ tests/auth/
git commit -m "feat(auth): add JWT validation middleware"

# Ship sprint (or use /sprint-end)
git push -u origin sprint-3
gh pr create --title "Sprint 3: Auth + Rate Limiting" --body "..."

# After review, squash merge
gh pr merge --squash --delete-branch
```

## Rules Summary

- Never push directly to the default branch — always via PR
- Never force push — use `--force-with-lease` only if necessary
- Squash merge to main for clean history
- Delete feature branches after merge
- Never skip pre-commit hooks (`--no-verify`)
- When a hook fails, the commit did NOT happen — create a NEW commit after fixing
