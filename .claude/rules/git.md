---
paths:
  - "**"
---

# Git Workflow Rules

- Never push directly to main — all changes via pull request
- Never force push (`--force` or `-f`) — use `--force-with-lease` only if necessary
- Always use conventional commit format: `<type>(<scope>): <description>`
- Branch naming: `feature/<story-id>-<description>` or `sprint-<number>`
- Always squash merge to main to keep history clean
- Delete feature branches after merge
- Never skip pre-commit hooks (`--no-verify`)
- Never amend published commits without explicit user approval
- When a pre-commit hook fails, the commit did NOT happen — always create a NEW commit after fixing the issue, never `--amend` (amending would modify the PREVIOUS commit, risking lost work)
