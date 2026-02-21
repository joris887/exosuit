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
- Commit footer: `Co-Authored-By: Claude <noreply@anthropic.com>`
