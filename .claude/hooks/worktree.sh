#!/bin/sh
# Worktree handlers: initialize new worktrees, clean up removed ones.
# WorktreeCreate: copies state files from main worktree.
# WorktreeRemove: merges activity logs back to main worktree.
# POSIX-compliant — no bash required.
#
# Usage: sh worktree.sh WorktreeCreate  (or WorktreeRemove)
# Input: JSON on stdin (not used, event type from $1)
# Output: advisory messages on stderr, always exit 0

EVENT="$1"
cat >/dev/null  # Consume stdin

# --- Get main worktree path ---
get_main_worktree() {
    git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | sed 's/^worktree //'
}

MAIN_WT=$(get_main_worktree)
[ -z "$MAIN_WT" ] && exit 0

CURRENT=$(pwd)
[ "$CURRENT" = "$MAIN_WT" ] && exit 0

case "$EVENT" in
    WorktreeCreate)
        # Copy state files from main worktree
        for rel_path in "docs/sessions/.failure-state.md" "docs/sessions/.auto-save.md"; do
            src="$MAIN_WT/$rel_path"
            dst="$CURRENT/$rel_path"
            if [ -f "$src" ]; then
                mkdir -p "$(dirname "$dst")" 2>/dev/null
                cp -p "$src" "$dst" 2>/dev/null
            fi
        done
        mkdir -p "docs/sessions" 2>/dev/null
        printf 'Worktree initialized with framework state.\n' >&2
        ;;

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
