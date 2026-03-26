#!/bin/sh
# Hook guard: profile-based gating and per-hook runtime disabling.
# Called by each hook script to determine if it should run.
#
# Usage:  "$HOOKS_DIR/lib/hook-guard.sh" <hook-id> <minimum-profile>
# Exit 0: hook should run
# Exit 1: hook should be skipped (caller does: || exit 0)
#
# Environment variables:
#   JD_HOOK_PROFILE    minimal|standard|strict (default: standard)
#   JD_DISABLED_HOOKS  comma-separated hook IDs to disable (e.g., "stop,post-format")
#
# Profile hierarchy: minimal(1) < standard(2) < strict(3)
# A hook runs only if current profile >= its minimum profile.
#
# POSIX-compliant — no bash required.

HOOK_ID="${1:-}"
MIN_PROFILE="${2:-standard}"

# --- Map profile names to numeric levels ---
profile_level() {
    case "$1" in
        minimal) echo 1 ;;
        standard) echo 2 ;;
        strict) echo 3 ;;
        *) echo 2 ;;  # default to standard for unknown values
    esac
}

# --- Check if hook is disabled by ID ---
DISABLED="${JD_DISABLED_HOOKS:-}"
if [ -n "$DISABLED" ] && [ -n "$HOOK_ID" ]; then
    # Split on comma and check each entry
    OLD_IFS="$IFS"
    IFS=","
    for disabled_id in $DISABLED; do
        # Trim whitespace
        disabled_id=$(printf '%s' "$disabled_id" | tr -d ' ')
        if [ "$disabled_id" = "$HOOK_ID" ]; then
            IFS="$OLD_IFS"
            exit 1
        fi
    done
    IFS="$OLD_IFS"
fi

# --- Check profile level ---
CURRENT_PROFILE="${JD_HOOK_PROFILE:-standard}"
CURRENT_LEVEL=$(profile_level "$CURRENT_PROFILE")
MIN_LEVEL=$(profile_level "$MIN_PROFILE")

if [ "$CURRENT_LEVEL" -lt "$MIN_LEVEL" ]; then
    exit 1
fi

exit 0
