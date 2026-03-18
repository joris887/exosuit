#!/bin/sh
# StopFailure hook: save session state when turn ends due to API error.
# Delegates to pre-compact.sh for consistent auto-save behavior.
#
# Input:  JSON on stdin (StopFailure event data)
# Output: exit 0 always (never blocks)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Reuse pre-compact auto-save logic
if [ -x "$HOOKS_DIR/pre-compact.sh" ]; then
    echo '{}' | sh "$HOOKS_DIR/pre-compact.sh" 2>/dev/null
fi

printf 'Session ended due to API error. State saved to docs/sessions/.auto-save.md\n' >&2

exit 0
