#!/bin/sh
# PreToolUse handler: block dangerous Bash commands.
# Loads patterns from rules/safety.patterns. Blocks matching commands (exit 2).
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (tool_input.command)
# Output: exit 0 = allow, exit 2 = block (message on stderr)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
STATE_DIR="$HOOKS_DIR/state"
SAFETY_FILE="$RULES_DIR/safety.patterns"

# --- JSON field extraction ---
# Try jq first, fall back to sed for simple field extraction.
extract_json_string() {
    _field="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$_field // empty"
    else
        sed -n 's/.*"'"$_field"'"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | extract_json_string "command")

# If no command, allow through
[ -z "$COMMAND" ] && exit 0

# --- Check safety patterns ---
if [ -f "$SAFETY_FILE" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        case "$line" in
            '#'*|'') continue ;;
        esac

        # Split on @@ delimiter: id@@regex@@message
        id=$(printf '%s' "$line" | sed 's/@@.*//')
        rest=$(printf '%s' "$line" | sed 's/^[^@]*@@//')
        regex=$(printf '%s' "$rest" | sed 's/@@.*//')
        message=$(printf '%s' "$rest" | sed 's/^[^@]*@@//')

        # Match command against regex
        if printf '%s' "$COMMAND" | grep -qE "$regex"; then
            printf 'BLOCKED: %s\n' "$message" >&2
            exit 2
        fi
    done < "$SAFETY_FILE"
fi

# --- Framework template repo protection ---
if printf '%s' "$COMMAND" | grep -qE '(gh\s+(pr|issue)\s+create|git\s+push)'; then
    FRAMEWORK_REPO="${JD_FRAMEWORK_REPO:-joris887/JD-LLM-Development_framework}"
    REMOTE=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE" ]; then
        case "$REMOTE" in
            *"$FRAMEWORK_REPO"*)
                printf 'BLOCKED: Remote points to the framework template repository (%s). Run: git remote set-url origin <your-project-repo-url>\n' "$FRAMEWORK_REPO" >&2
                exit 2
                ;;
        esac
    fi
fi

exit 0
