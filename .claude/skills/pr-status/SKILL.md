---
name: pr-status
version: 2.4.0
description: Check status of open pull requests and provide options for next steps. Use to review PR status, handle feedback, or merge approved PRs.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash
---
______________________________________________________________________

## pr-status

Check status of your pull requests:

## Current Open PRs (auto-fetched)

!`gh pr list --author @me --state open --json number,title,state,reviewDecision,statusCheckRollup --template '{{range .}}PR #{{.number}}: {{.title}}   Review: {{.reviewDecision}} | Checks: {{range .statusCheckRollup}}{{.state}} {{end}} {{end}}' 2>/dev/null || echo "No open PRs or gh not configured"`

## 1. Analyze PR Status

## 2. For Each Open PR

```bash
gh pr view <number> --json state,reviewDecision,statusCheckRollup,mergeable
gh pr checks <number>
```

## 3. Status Summary

```markdown
## PR Status Report

### PR #[number]: [title]
- **Branch**: [branch-name]
- **Review Status**: [Approved/Changes Requested/Pending]
- **Checks**: [Passing/Failing/Pending]
- **Mergeable**: [Yes/No - reason if no]

### Recommended Actions
- [Action based on status]
```

## 4. Available Actions

Based on PR status, offer options:

**If Approved + Checks Passing:**

```bash
gh pr merge --squash --delete-branch
```

**If Changes Requested:**

- View review comments: `gh pr view <number> --comments`
- Address feedback and push updates

**If Checks Failing:**

- View failed checks: `gh pr checks <number>`
- Fix issues and push

**If Pending Review:**

- Wait or request review: `gh pr edit <number> --add-reviewer <user>`
