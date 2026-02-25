#!/usr/bin/env bash
# Sprint status overview — reads from git state and project docs
# Zero context cost: execute directly, do NOT read source
set -euo pipefail

echo "=== Sprint Status ==="
echo ""

# Git state
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "Branch: $BRANCH"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    echo "State:  Between sprints (on main)"
else
    COMMITS_AHEAD=$(git rev-list --count main..HEAD 2>/dev/null || echo "?")
    FILES_CHANGED=$(git diff --name-only main...HEAD 2>/dev/null | wc -l | tr -d ' ')
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "State:  Active sprint"
    echo "Commits ahead of main: $COMMITS_AHEAD"
    echo "Files changed vs main: $FILES_CHANGED"
    echo "Uncommitted changes:   $UNCOMMITTED"
fi

echo ""

# Progress from docs/progress.md
if [[ -f "docs/progress.md" ]]; then
    echo "=== From progress.md ==="
    # Extract sprint number and status
    grep -E "^\- \*\*(Sprint|Story|Status|Tests|Codebase)" docs/progress.md 2>/dev/null | head -10 || echo "(no metrics found)"
else
    echo "(docs/progress.md not found)"
fi

echo ""

# Backlog summary from epic files
if [[ -d "docs/reference/backlog" ]]; then
    echo "=== Backlog Summary ==="
    DONE=$(grep -rl '\[DONE\]\|\bDONE\b' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS=$(grep -rl '\[IN_PROGRESS\]\|\bIN_PROGRESS\b' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
    TODO=$(grep -rl '\[TODO\]\|\bTODO\b' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
    echo "Done:        $DONE stories"
    echo "In Progress: $IN_PROGRESS stories"
    echo "TODO:        $TODO stories"
else
    echo "(docs/reference/backlog/ not found)"
fi

# Open PRs
echo ""
echo "=== Open PRs ==="
if command -v gh &>/dev/null; then
    gh pr list --author @me --state open --limit 5 2>/dev/null || echo "(gh not configured or no PRs)"
else
    echo "(gh CLI not installed)"
fi
