#!/bin/sh
# PostToolUseFailure hook: inject error recovery guidance when tools fail.
# Reminds the model about recovery protocols from rules.
#
# Input:  JSON on stdin (tool_name, tool_input, error)
# Output: exit 0 always, stderr = advisory recovery guidance

# Extract tool name from stdin
INPUT=$(cat)
TOOL_NAME=""
if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
else
    TOOL_NAME=$(printf '%s' "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

case "$TOOL_NAME" in
    Edit|Write)
        printf 'Edit/Write failed. Recovery protocol (from edit-recovery.md):\n' >&2
        printf '  1. Re-read the file before retrying — your context may be stale\n' >&2
        printf '  2. Never retry the exact same edit that failed\n' >&2
        printf '  3. If "not unique", include more surrounding context\n' >&2
        printf '  4. After 3 failures on same file, pause and reconsider approach\n' >&2
        ;;
    Bash)
        printf 'Bash command failed. Check:\n' >&2
        printf '  1. Verify command syntax (run --help first if unsure about flags)\n' >&2
        printf '  2. Check if required tools are installed\n' >&2
        printf '  3. Verify working directory is correct\n' >&2
        ;;
esac

exit 0
