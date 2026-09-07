#!/bin/sh
# WorktreeRemove handler: merges a removed native worktree's activity log back to the main worktree. (The WorktreeCreate arm was removed: a registered WorktreeCreate hook must print the worktree path, this one never did, and every native claude --worktree creation aborted while it was registered.)
# POSIX-compliant — no bash required.
#
# Usage: sh worktree.sh WorktreeRemove
# Input: JSON on stdin (drained, not used); the event name comes from $1
# Output: nothing on stdout or stderr; always exit 0
#   A missing main worktree, a run from the main worktree itself, or any
#   event name other than WorktreeRemove is a silent no-op.
# Hook ID for EXOSUIT_DISABLED_HOOKS: worktree (minimum profile: minimal)

EVENT="$1"
cat >/dev/null  # Consume stdin

# --- Hook guard: profile + disable check ---
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
"$HOOKS_DIR/lib/hook-guard.sh" "worktree" "minimal" || exit 0

# --- Get main worktree path ---
get_main_worktree() {
    git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | sed 's/^worktree //'
}

MAIN_WT=$(get_main_worktree)
[ -z "$MAIN_WT" ] && exit 0

CURRENT=$(pwd)
[ "$CURRENT" = "$MAIN_WT" ] && exit 0

case "$EVENT" in
    WorktreeRemove)
        # Merge activity log back to main worktree
        LOG="docs/sessions/.activity-log.jsonl"
        if [ -f "$LOG" ]; then
            MAIN_LOG="$MAIN_WT/$LOG"
            mkdir -p "$(dirname "$MAIN_LOG")" 2>/dev/null
            cat "$LOG" >> "$MAIN_LOG" 2>/dev/null
        fi
        ;;
esac

exit 0
