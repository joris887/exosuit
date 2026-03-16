#!/bin/sh
# SessionStart handler: advisory environment checks.
# Validates project tools, detects stale state, checks git health.
# Never blocks (advisory only, always exit 0).
# POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOOKS_DIR/state"
WARNINGS=""

# --- Helper: append warning ---
warn() {
    if [ -z "$WARNINGS" ]; then
        WARNINGS="$1"
    else
        WARNINGS="$WARNINGS
  - $1"
    fi
}

# --- 1. Check project tool availability from CLAUDE.md ---
if [ -f "CLAUDE.md" ]; then
    for key in "test:" "lint:" "format:" "build:" "typecheck:"; do
        CMD=$(grep "$key" CLAUDE.md 2>/dev/null | sed "s/.*$key//" | awk '{print $1}' | head -1)
        if [ -n "$CMD" ]; then
            case "$CMD" in
                '<'*|'#'*|'') continue ;;
            esac
            if ! command -v "$CMD" >/dev/null 2>&1; then
                warn "Tool '$CMD' (from CLAUDE.md Commands) not found in PATH"
            fi
        fi
    done
fi

# --- 2. Stale session detection ---
AUTO_SAVE="docs/sessions/.auto-save.md"
if [ -f "$AUTO_SAVE" ]; then
    if command -v stat >/dev/null 2>&1; then
        # macOS stat vs GNU stat
        MTIME=$(stat -f %m "$AUTO_SAVE" 2>/dev/null || stat -c %Y "$AUTO_SAVE" 2>/dev/null || echo 0)
        NOW=$(date +%s 2>/dev/null || echo 0)
        if [ "$MTIME" -gt 0 ] && [ "$NOW" -gt 0 ]; then
            AGE=$((NOW - MTIME))
            if [ "$AGE" -gt 86400 ]; then
                DAYS=$((AGE / 86400))
                warn "Stale auto-save detected ($AUTO_SAVE is ${DAYS}d old) -- consider running /continue"
            fi
        fi
    fi
fi

# --- 3. Git state checks ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        case "$BRANCH" in
            main|master) warn "On $BRANCH branch -- create a feature branch before making changes" ;;
        esac
    else
        warn "Detached HEAD state -- checkout a branch before making changes"
    fi

    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        warn "Uncommitted changes detected -- consider committing or stashing before starting"
    fi
fi

# --- 4. Initialize session state ---
mkdir -p "$STATE_DIR" 2>/dev/null
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/session-started" 2>/dev/null
# Reset stop iteration counter
echo "0" > "$STATE_DIR/stop-iteration" 2>/dev/null

# --- Output warnings ---
if [ -n "$WARNINGS" ]; then
    printf 'Session start checks:\n  - %s\n' "$WARNINGS" >&2
fi

exit 0
