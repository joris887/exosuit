#!/bin/sh
# PreCompact hook: auto-save session state before context compaction.
# Ensures critical state survives compaction deterministically.
# Reuses the same auto-save format as stop.sh for /continue compatibility.
#
# Input:  JSON on stdin (PreCompact event data)
# Output: exit 0 always (never blocks compaction)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-save git state if in a git repo
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
**Trigger:** PreCompact (context compaction)
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

    printf 'Session state saved to docs/sessions/.auto-save.md before compaction.\n' >&2
fi

exit 0
