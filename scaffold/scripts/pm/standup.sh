#!/usr/bin/env bash
# Daily standup summary — yesterday's work, today's focus, blockers.
# Parses story checklist lines: - [ ] ID — Title (Priority, Status)
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

# Today's focus — in-progress and next ready stories
echo "--- Today ---"
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    echo "On main — ready to start new work"
else
    echo "Active on: $BRANCH"
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$UNCOMMITTED" -gt 0 ]]; then
        echo "Uncommitted changes: $UNCOMMITTED files"
    fi
fi

# Show in-progress and next ready stories
if [[ -d "docs/reference/backlog" ]]; then
    IN_PROGRESS=$(grep -rn ', in-progress)' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' || true)
    if [[ -n "$IN_PROGRESS" ]]; then
        echo ""
        echo "In progress:"
        echo "$IN_PROGRESS" | while IFS= read -r line; do
            echo "  $line"
        done
    fi

    # Show next ready story (highest priority first)
    NEXT_READY=""
    for priority in P0 P1 P2 P3; do
        if [[ -z "$NEXT_READY" ]]; then
            NEXT_READY=$(grep -rn "($priority, ready)" docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | head -1 || true)
        fi
    done
    if [[ -n "$NEXT_READY" ]]; then
        echo ""
        echo "Next ready:"
        echo "  $NEXT_READY"
    fi

    # Legacy fallback
    if [[ -z "$IN_PROGRESS" && -z "$NEXT_READY" ]]; then
        NEXT=$(grep -rn '\[TODO\]\|Status: TODO' docs/reference/backlog/ 2>/dev/null | head -1 || echo "")
        if [[ -n "$NEXT" ]]; then
            echo ""
            echo "Next story (legacy format): $NEXT"
        fi
    fi
fi
echo ""

# Blockers
echo "--- Blockers ---"
BLOCKER_COUNT=0

# Check for blocked stories
if [[ -d "docs/reference/backlog" ]]; then
    BLOCKED=$(grep -rn ', blocked' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' || true)
    if [[ -n "$BLOCKED" ]]; then
        echo "Blocked stories:"
        echo "$BLOCKED" | while IFS= read -r line; do
            echo "  $line"
        done
        BLOCKER_COUNT=$((BLOCKER_COUNT + 1))
    fi
fi

# Check for failure state
if [[ -f "docs/sessions/.failure-state.md" ]]; then
    SKILL=$(grep '^skill:' docs/sessions/.failure-state.md 2>/dev/null | head -1 | sed 's/skill: *//' || echo "unknown")
    PHASE=$(grep '^phase_name:' docs/sessions/.failure-state.md 2>/dev/null | head -1 | sed 's/phase_name: *//' || echo "unknown")
    echo "Interrupted session: $SKILL at $PHASE"
    BLOCKER_COUNT=$((BLOCKER_COUNT + 1))
fi

# Check for failing tests
if [[ -f "docs/sessions/.auto-save.md" ]]; then
    ISSUES=$(grep -i "fail\|error\|block" docs/sessions/.auto-save.md 2>/dev/null | head -3 || echo "")
    if [[ -n "$ISSUES" ]]; then
        echo "$ISSUES"
        BLOCKER_COUNT=$((BLOCKER_COUNT + 1))
    fi
fi

if [[ $BLOCKER_COUNT -eq 0 ]]; then
    echo "(none detected)"
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
