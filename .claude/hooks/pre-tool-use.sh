#!/bin/sh
# PreToolUse handler: block dangerous commands, sanitize fixable ones, inject context.
# Loads patterns from rules/safety.patterns. Blocks matching commands (exit 2).
# Can rewrite commands via updatedInput (e.g., --force → --force-with-lease).
# Can inject additionalContext before tool execution.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (tool_input.command)
# Output: exit 0 = allow, exit 2 = block, JSON stdout = rewrite or context

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

# --- Command sanitization (updatedInput) ---
# Rewrite dangerous-but-fixable commands instead of blocking
if printf '%s' "$COMMAND" | grep -qE 'git push (--force|-f)\b'; then
    # Rewrite --force to --force-with-lease (safer)
    SAFE_CMD=$(printf '%s' "$COMMAND" | sed 's/--force\b/--force-with-lease/g; s/-f\b/--force-with-lease/g')
    printf '{"decision":"allow","updatedInput":{"command":"%s"},"systemMessage":"Rewrote --force to --force-with-lease for safety."}\n' "$SAFE_CMD"
    exit 0
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

# --- Context injection (additionalContext) ---
# Inject reminders before specific command types
if printf '%s' "$COMMAND" | grep -qE '(pytest|npm test|go test|cargo test|bundle exec rspec|dart test|dotnet test)\b'; then
    printf '{"additionalContext":"Capture the full test output — this is verification evidence needed for completion."}\n'
    exit 0
fi

if printf '%s' "$COMMAND" | grep -qE 'git push\b'; then
    printf '{"additionalContext":"After push, create a PR with gh pr create if one does not exist yet."}\n'
    exit 0
fi

exit 0
