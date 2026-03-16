#!/bin/sh
# UserPromptSubmit handler: advisory intent classification.
# Warns about potentially destructive user requests. Never blocks.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (user_prompt)
# Output: advisory warnings on stderr, always exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
PATTERNS_FILE="$RULES_DIR/intent.patterns"

# --- JSON field extraction ---
extract_json_string() {
    _field="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".$_field // empty"
    else
        sed -n 's/.*"'"$_field"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | extract_json_string "user_prompt")
[ -z "$PROMPT" ] && exit 0

# --- Check intent patterns ---
WARNINGS=""
if [ -f "$PATTERNS_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            '#'*|'') continue ;;
        esac

        # Split on @@ delimiter: regex@@message
        regex=$(printf '%s' "$line" | sed 's/@@.*//')
        message=$(printf '%s' "$line" | sed 's/^[^@]*@@//')

        if printf '%s' "$PROMPT" | grep -qEi "$regex"; then
            if [ -z "$WARNINGS" ]; then
                WARNINGS="Warning: $message"
            else
                WARNINGS="$WARNINGS
Warning: $message"
            fi
        fi
    done < "$PATTERNS_FILE"
fi

if [ -n "$WARNINGS" ]; then
    printf '%s\n' "$WARNINGS" >&2
fi

exit 0
