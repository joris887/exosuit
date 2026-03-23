---
name: fix-issue
version: 2.4.0
description: Fix a GitHub issue following project coding standards. Creates branch, implements fix with TDD, and prepares PR.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "<issue-number>"
---
______________________________________________________________________

## fix-issue

Fix GitHub issue **$ARGUMENTS** following project coding standards.

## 1. Get Issue Details

```bash
gh issue view $ARGUMENTS
```

## 2. Understand the Problem

- Read the issue description carefully
- Check for related issues or PRs
- Identify acceptance criteria

## 3. Create Feature Branch

Detect the default branch dynamically:

```bash
DEFAULT_BRANCH=$(grep -oP '^\- \*\*Default branch:\*\* \K\S+' CLAUDE.md 2>/dev/null)
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
fi
if [ -z "$DEFAULT_BRANCH" ]; then
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then DEFAULT_BRANCH="$branch"; break; fi
    done
fi
git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
git checkout -b fix/issue-$ARGUMENTS
```

**Note:** This skill is a standalone quick-fix flow (issue → branch → TDD fix → PR). For fixes that are part of an active sprint, use `/story-cycle` instead — it integrates with the sprint branch and quality gates.

## 4. Search for Relevant Code

- Use Glob and Grep to find related files
- Understand the current implementation
- Identify what needs to change

## 5. Implement Fix (TDD)

1. Write a failing test that reproduces the issue
1. Verify the test fails for the right reason
1. Implement the minimal fix
1. Verify the test passes
1. Run full test suite (use project's test command from CLAUDE.md)

## 6. Verify Fix

- Ensure code passes linting and type checking
- Review changes for quality

## 7. Commit and Push

```bash
git add .
git commit -m "$(cat <<'EOF'
fix: resolve issue #$ARGUMENTS

[Description of what was fixed and how]

Closes #$ARGUMENTS

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
git push -u origin fix/issue-$ARGUMENTS
```

## 8. Create PR

```bash
gh pr create --title "fix: resolve issue #$ARGUMENTS" --body "$(cat <<'EOF'
## Summary
Fixes #$ARGUMENTS

## Changes
- [List of changes made]

## Testing
- Added test to reproduce issue
- All tests passing

## Checklist
- [x] Issue reproduced with failing test
- [x] Fix implemented
- [x] All tests pass
- [x] Code follows project standards

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Output the PR URL when complete.
