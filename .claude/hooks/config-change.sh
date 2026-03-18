#!/bin/sh
# ConfigChange hook: validate framework configuration on settings changes.
# Fires when .claude/settings.json or rules are modified during a session.
#
# Input:  JSON on stdin (ConfigChange event data)
# Output: exit 0 always (advisory), stderr = warnings

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE=".claude/settings.json"

# --- 1. Validate settings.json is valid JSON ---
if [ -f "$SETTINGS_FILE" ]; then
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
            printf 'WARNING: .claude/settings.json is invalid JSON after config change.\n' >&2
            printf 'Framework hooks may not load correctly. Check for syntax errors.\n' >&2
            exit 0
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null; then
            printf 'WARNING: .claude/settings.json is invalid JSON after config change.\n' >&2
            exit 0
        fi
    fi
fi

# --- 2. Verify hook script paths still exist ---
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    MISSING=""
    for script in $(jq -r '.. | .command? // empty' "$SETTINGS_FILE" 2>/dev/null | grep -o '[^ ]*\.sh' | sort -u); do
        # Resolve __PROJECT_ROOT__ placeholder
        RESOLVED=$(echo "$script" | sed "s|__PROJECT_ROOT__/||")
        if [ ! -f "$RESOLVED" ] && [ ! -f "$script" ]; then
            MISSING="$MISSING $RESOLVED"
        fi
    done
    if [ -n "$MISSING" ]; then
        printf 'WARNING: Hook scripts referenced in settings.json not found:%s\n' "$MISSING" >&2
    fi
fi

exit 0
