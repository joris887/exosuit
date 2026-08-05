#!/bin/sh
# Hook guard: profile-based gating and per-hook runtime disabling.
# Called by each hook script to determine if it should run.
#
# Usage:  "$HOOKS_DIR/lib/hook-guard.sh" <hook-id> <minimum-profile>
# Exit 0: hook should run
# Exit 1: hook should be skipped (caller does: || exit 0)
#
# Environment variables:
#   EXOSUIT_PROJECT_PROFILE  lean|standard|strict (default: standard)
#                       Controls skill behavior (ceremony depth, agent dispatch).
#                       Read from env var, then CLAUDE.md **Profile:** line, then default.
#   EXOSUIT_HOOK_PROFILE     minimal|standard|strict (default: derived from project profile)
#                       Controls hook behavior. Overrides the project-derived default.
#   EXOSUIT_DISABLED_HOOKS   comma-separated hook IDs to disable (e.g., "stop,post-format")
#   EXOSUIT_STOP_MAX_ITERATIONS  override stop hook safety valve (strict profile defaults to 10)
#
# Project profile → hook profile mapping (when EXOSUIT_HOOK_PROFILE is not set):
#   lean    → minimal
#   standard → standard
#   strict  → strict
#
# Hook profile hierarchy: minimal(1) < standard(2) < strict(3)
# A hook runs only if current hook profile >= its minimum profile.
#
# POSIX-compliant — no bash required.

HOOK_ID="${1:-}"
MIN_PROFILE="${2:-standard}"

# --- Resolve HOOKS_DIR for state file writing ---
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(cd "$GUARD_DIR/.." && pwd)"

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
DISABLED="${EXOSUIT_DISABLED_HOOKS:-}"
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

# --- Detect project profile ---
PROJECT_PROFILE="${EXOSUIT_PROJECT_PROFILE:-}"
if [ -z "$PROJECT_PROFILE" ] && [ -f "CLAUDE.md" ]; then
    # Extract profile from CLAUDE.md **Profile:** line (POSIX-compatible)
    PROJECT_PROFILE=$(sed -n 's/^.*\*\*Profile:\*\*[[:space:]]*//p' CLAUDE.md 2>/dev/null | head -1 | tr -d '[:space:]')
fi
PROJECT_PROFILE="${PROJECT_PROFILE:-standard}"

# Validate project profile
case "$PROJECT_PROFILE" in
    lean|standard|strict) ;;
    *) PROJECT_PROFILE="standard" ;;
esac

# Write resolved project profile to state for other scripts to read
mkdir -p "$HOOKS_DIR/state" 2>/dev/null
printf '%s' "$PROJECT_PROFILE" > "$HOOKS_DIR/state/project-profile" 2>/dev/null

# --- Strict profile: increase stop iteration limit if not explicitly set ---
if [ "$PROJECT_PROFILE" = "strict" ] && [ -z "${EXOSUIT_STOP_MAX_ITERATIONS:-}" ]; then
    export EXOSUIT_STOP_MAX_ITERATIONS=10
fi

# --- Determine effective hook profile ---
# Explicit EXOSUIT_HOOK_PROFILE env var wins; otherwise derive from project profile.
if [ -n "${EXOSUIT_HOOK_PROFILE:-}" ]; then
    CURRENT_PROFILE="$EXOSUIT_HOOK_PROFILE"
else
    case "$PROJECT_PROFILE" in
        lean) CURRENT_PROFILE="minimal" ;;
        strict) CURRENT_PROFILE="strict" ;;
        *) CURRENT_PROFILE="standard" ;;
    esac
fi

CURRENT_LEVEL=$(profile_level "$CURRENT_PROFILE")
MIN_LEVEL=$(profile_level "$MIN_PROFILE")

if [ "$CURRENT_LEVEL" -lt "$MIN_LEVEL" ]; then
    exit 1
fi

exit 0
