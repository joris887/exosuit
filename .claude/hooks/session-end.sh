#!/bin/sh
# SessionEnd hook: final auto-save and session cleanup.
# Fires only at actual session end (not every model turn like Stop).
# Handles: auto-save, activity log cleanup, session metrics.
#
# Input:  JSON on stdin (SessionEnd event data, includes session_id)
# Output: exit 0 always (never blocks session end)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 1. Final auto-save (same logic as pre-compact.sh) ---
if [ -d ".git" ] || [ -f ".git" ]; then
    SESSIONS_DIR="docs/sessions"
    mkdir -p "$SESSIONS_DIR" 2>/dev/null

    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    COMMITS=$(git log --oneline -5 2>/dev/null || echo "no commits")
    UNCOMMITTED=$(git diff --name-only 2>/dev/null)
    STAGED=$(git diff --cached --name-only 2>/dev/null)
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

    UNCOMMITTED_BLOCK="None"
    [ -n "$UNCOMMITTED" ] && UNCOMMITTED_BLOCK=$(printf '```\n%s\n```' "$UNCOMMITTED")
    STAGED_BLOCK="None"
    [ -n "$STAGED" ] && STAGED_BLOCK=$(printf '```\n%s\n```' "$STAGED")

    cat > "$SESSIONS_DIR/.auto-save.md" 2>/dev/null <<AUTOSAVE_EOF
# Auto-Save Session State

**Generated:** $NOW
**Trigger:** SessionEnd (session closed)
**Branch:** $BRANCH

## Recent Commits
\`\`\`
$COMMITS
\`\`\`

## Uncommitted Changes
$UNCOMMITTED_BLOCK

## Staged Changes
$STAGED_BLOCK
AUTOSAVE_EOF
fi

# --- 2. Clean up stop iteration counter ---
ITER_FILE="$HOOKS_DIR/state/stop-iteration"
[ -f "$ITER_FILE" ] && rm -f "$ITER_FILE" 2>/dev/null

# --- 3. Activity log rotation (keep last 200 entries) ---
LOG_FILE="docs/sessions/.activity-log.jsonl"
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d '[:space:]')
    if [ "$LINE_COUNT" -gt 200 ]; then
        KEEP=$((LINE_COUNT - 200))
        tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null
    fi
fi

exit 0
