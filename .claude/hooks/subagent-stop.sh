#!/bin/sh
# SubagentStop handler: validate subagent output quality. Advisory only.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (last_assistant_message)
# Output: advisory warnings on stderr, always exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
PATTERNS_FILE="$RULES_DIR/subagent.patterns"
CONF_FILE="$RULES_DIR/subagent.conf"

# --- Helper: read config value ---
read_conf() {
    _key="$1"
    _default="$2"
    if [ -f "$CONF_FILE" ]; then
        _val=$(grep "^${_key}=" "$CONF_FILE" 2>/dev/null | sed "s/^${_key}=//" | head -1)
        if [ -n "$_val" ]; then
            printf '%s\n' "$_val"
            return
        fi
    fi
    printf '%s\n' "$_default"
}

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
MESSAGE=$(printf '%s' "$INPUT" | extract_json_string "last_assistant_message")
[ -z "$MESSAGE" ] && exit 0

WARNINGS=""

# --- Check weak claim patterns ---
if [ -f "$PATTERNS_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            '#'*|'') continue ;;
        esac

        regex=$(printf '%s' "$line" | sed 's/@@.*//')
        message=$(printf '%s' "$line" | sed 's/^[^@]*@@//')

        if printf '%s' "$MESSAGE" | grep -qEi "$regex"; then
            if [ -z "$WARNINGS" ]; then
                WARNINGS="$message"
            else
                WARNINGS="$WARNINGS
  - $message"
            fi
        fi
    done < "$PATTERNS_FILE"
fi

# --- Check for file:line references ---
REQUIRE_REFS=$(read_conf "require_references" "false")
if [ "$REQUIRE_REFS" = "true" ]; then
    MSG_LEN=$(printf '%s' "$MESSAGE" | wc -c | tr -d ' ')
    if [ "$MSG_LEN" -gt 200 ]; then
        if ! printf '%s' "$MESSAGE" | grep -qE '[a-zA-Z_/]+\.[a-zA-Z]+:[0-9]+'; then
            if [ -z "$WARNINGS" ]; then
                WARNINGS="Subagent output lacks file:line references"
            else
                WARNINGS="$WARNINGS
  - Subagent output lacks file:line references"
            fi
        fi
    fi
fi

if [ -n "$WARNINGS" ]; then
    printf 'Subagent quality warnings:\n  - %s\n' "$WARNINGS" >&2
fi

exit 0
