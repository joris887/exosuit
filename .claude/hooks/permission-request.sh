#!/bin/sh
# PermissionRequest hook: auto-approve safe tools, auto-deny dangerous ones.
# Falls through to user prompt for anything not matched.
#
# Input:  JSON on stdin (tool_name, tool_input with command field for Bash)
# Output: JSON to stdout with decision, or exit 0 silently to fall through

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
PATTERNS_FILE="$HOOKS_DIR/rules/permission.patterns"

# Exit silently if no patterns file
[ -f "$PATTERNS_FILE" ] || exit 0

# Extract tool name and command from stdin
INPUT=$(cat)
TOOL_NAME=""
COMMAND=""

if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    TOOL_NAME=$(printf '%s' "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    COMMAND=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

[ -z "$TOOL_NAME" ] && exit 0

# Match against patterns
while IFS= read -r line; do
    # Skip comments and empty lines
    case "$line" in
        '#'*|'') continue ;;
    esac

    ACTION=$(printf '%s' "$line" | cut -d'@' -f1)
    # Handle @@ separator (cut fields: 1=action, 3=tool_regex, 5=cmd_regex, 7=reason)
    TOOL_RE=$(printf '%s' "$line" | awk -F'@@' '{print $2}')
    CMD_RE=$(printf '%s' "$line" | awk -F'@@' '{print $3}')
    REASON=$(printf '%s' "$line" | awk -F'@@' '{print $4}')

    # Check tool name matches
    if printf '%s' "$TOOL_NAME" | grep -qE "$TOOL_RE" 2>/dev/null; then
        # For non-Bash tools, command regex is .* (always matches)
        if [ "$TOOL_NAME" != "Bash" ] || [ "$CMD_RE" = ".*" ]; then
            if [ "$ACTION" = "allow" ]; then
                printf '{"decision":"allow","reason":"%s"}\n' "$REASON"
                exit 0
            elif [ "$ACTION" = "deny" ]; then
                printf '{"decision":"deny","reason":"%s"}\n' "$REASON"
                exit 0
            fi
        fi
        # For Bash, also check command regex
        if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
            if printf '%s' "$COMMAND" | grep -qE "$CMD_RE" 2>/dev/null; then
                if [ "$ACTION" = "allow" ]; then
                    printf '{"decision":"allow","reason":"%s"}\n' "$REASON"
                    exit 0
                elif [ "$ACTION" = "deny" ]; then
                    printf '{"decision":"deny","reason":"%s"}\n' "$REASON"
                    exit 0
                fi
            fi
        fi
    fi
done < "$PATTERNS_FILE"

# No match — fall through to user prompt
exit 0
