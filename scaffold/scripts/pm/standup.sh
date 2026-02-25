#!/usr/bin/env bash
# Daily standup summary — yesterday's work, today's focus, blockers
# Zero context cost: execute directly, do NOT read source
set -euo pipefail

echo "=== Daily Standup ==="
echo ""

# Yesterday's work (commits in last 24h)
echo "--- Yesterday ---"
YESTERDAY_COMMITS=$(git log --oneline --since="24 hours ago" 2>/dev/null || echo "")
if [[ -n "$YESTERDAY_COMMITS" ]]; then
    echo "$YESTERDAY_COMMITS"
else
    echo "(no commits in last 24 hours)"
fi
echo ""

# Today's focus
echo "--- Today ---"
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    echo "On main — ready to start new work"
    # Show next story
    if [[ -d "docs/reference/backlog" ]]; then
        NEXT=$(grep -rl '\[TODO\]\|Status: TODO' docs/reference/backlog/ 2>/dev/null | head -1 || echo "")
        if [[ -n "$NEXT" ]]; then
            echo "Next story from: $(basename "$NEXT")"
        fi
    fi
else
    echo "Active on: $BRANCH"
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$UNCOMMITTED" -gt 0 ]]; then
        echo "Uncommitted changes: $UNCOMMITTED files"
    fi
fi
echo ""

# Blockers
echo "--- Blockers ---"
# Check for failing tests indicator
if [[ -f "docs/sessions/.auto-save.md" ]]; then
    ISSUES=$(grep -i "fail\|error\|block" docs/sessions/.auto-save.md 2>/dev/null | head -3 || echo "")
    if [[ -n "$ISSUES" ]]; then
        echo "$ISSUES"
    else
        echo "(none detected)"
    fi
else
    echo "(no auto-save file — run /continue for full assessment)"
fi

# Check for open PRs needing attention
if command -v gh &>/dev/null; then
    REVIEW_NEEDED=$(gh pr list --author @me --state open --json number,title,reviewDecision --jq '.[] | select(.reviewDecision == "CHANGES_REQUESTED") | "#\(.number): \(.title)"' 2>/dev/null || echo "")
    if [[ -n "$REVIEW_NEEDED" ]]; then
        echo ""
        echo "PRs needing attention:"
        echo "$REVIEW_NEEDED"
    fi
fi
