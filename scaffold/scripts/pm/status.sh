#!/usr/bin/env bash
# Sprint status overview — git state, story counts by status, flow metrics.
# Parses story checklist lines: - [ ] ID — Title (Priority, Status)
# Also supports legacy markers: [DONE], [IN_PROGRESS], [TODO]
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
    grep -E "^\- \*\*(Sprint|Story|Status|Tests|Codebase)" docs/progress.md 2>/dev/null | head -10 || echo "(no metrics found)"
else
    echo "(docs/progress.md not found)"
fi

echo ""

# Backlog summary — new format (parenthetical status)
if [[ -d "docs/reference/backlog" ]]; then
    echo "=== Backlog Summary ==="

    # New format: count status from checklist lines - [ ] ID — Title (P#, status)
    DONE=$(grep -r '\- \[x\]' docs/reference/backlog/E*.md 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS=$(grep -r ', in-progress)' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | wc -l | tr -d ' ')
    REVIEW=$(grep -r ', review)' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | wc -l | tr -d ' ')
    READY=$(grep -r ', ready)' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | wc -l | tr -d ' ')
    DRAFT=$(grep -r ', draft)' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | wc -l | tr -d ' ')
    BLOCKED_COUNT=$(grep -r ', blocked' docs/reference/backlog/E*.md 2>/dev/null | grep '\- \[ \]' | wc -l | tr -d ' ')

    # Check if any new-format stories were found
    TOTAL=$((DONE + IN_PROGRESS + REVIEW + READY + DRAFT + BLOCKED_COUNT))
    if [[ $TOTAL -eq 0 ]]; then
        # Fallback: legacy format
        DONE=$(grep -rl '\[DONE\]' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
        IN_PROGRESS=$(grep -rl '\[IN_PROGRESS\]' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
        READY=$(grep -rl '\[TODO\]' docs/reference/backlog/ 2>/dev/null | wc -l | tr -d ' ')
        REVIEW=0; DRAFT=0; BLOCKED_COUNT=0
        TOTAL=$((DONE + IN_PROGRESS + READY))
        echo "(using legacy format)"
    fi

    echo "Done:        $DONE"
    echo "Review:      $REVIEW"
    echo "In Progress: $IN_PROGRESS"
    echo "Ready:       $READY"
    echo "Draft:       $DRAFT"
    echo "Blocked:     $BLOCKED_COUNT"

    # Backlog health
    if [[ $TOTAL -gt 0 ]]; then
        NOT_DRAFT=$((TOTAL - DRAFT))
        echo ""
        echo "--- Health ---"
        echo "Total stories: $TOTAL"
        echo "Definition of Ready: $NOT_DRAFT/$TOTAL ($((NOT_DRAFT * 100 / TOTAL))%)"
        echo "Completion: $DONE/$TOTAL ($((DONE * 100 / TOTAL))%)"
    fi
else
    echo "(docs/reference/backlog/ not found)"
fi

# Story lifecycle metrics from activity log
LOG_FILE="docs/sessions/.activity-log.jsonl"
if [[ -f "$LOG_FILE" ]]; then
    STORY_EVENTS=$(grep '"type":"story"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$STORY_EVENTS" -gt 0 ]]; then
        echo ""
        echo "=== Story Flow Metrics ==="
        STARTED=$(grep '"type":"story".*"to":"in-progress"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
        COMPLETED=$(grep '"type":"story".*"to":"done"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
        echo "Stories started:   $STARTED"
        echo "Stories completed: $COMPLETED"
    fi
fi

# Open PRs
echo ""
echo "=== Open PRs ==="
if command -v gh &>/dev/null; then
    gh pr list --author @me --state open --limit 5 2>/dev/null || echo "(gh not configured or no PRs)"
else
    echo "(gh CLI not installed)"
fi
