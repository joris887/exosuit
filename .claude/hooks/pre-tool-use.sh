#!/bin/sh
# PreToolUse handler: block dangerous Bash commands + advisory warnings.
# Loads blocking patterns from rules/safety.patterns (exit 2 on match).
# Loads advisory patterns from rules/advisory.patterns (warn only, exit 0).
# Supports profile-based severity filtering via JD_HOOK_PROFILE.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (tool_input.command)
# Output: exit 0 = allow, exit 2 = block (message on stderr)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
SAFETY_FILE="$RULES_DIR/safety.patterns"
ADVISORY_FILE="$RULES_DIR/advisory.patterns"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "pre-tool-use" "minimal" || exit 0

# --- Profile level for severity filtering ---
CURRENT_PROFILE="${JD_HOOK_PROFILE:-standard}"
case "$CURRENT_PROFILE" in
    minimal) PROFILE_LEVEL=1 ;;
    strict)  PROFILE_LEVEL=3 ;;
    *)       PROFILE_LEVEL=2 ;;  # standard
esac

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

# --- Helper: map severity name to numeric level ---
severity_level() {
    case "$1" in
        critical) echo 1 ;;
        strict)   echo 3 ;;
        *)        echo 2 ;;  # standard (default)
    esac
}

# --- Helper: parse pattern line with optional severity ---
# Sets: id, regex, message, severity variables
parse_pattern_line() {
    _line="$1"

    id=$(printf '%s' "$_line" | sed 's/@@.*//')
    rest=$(printf '%s' "$_line" | sed 's/^[^@]*@@//')
    regex=$(printf '%s' "$rest" | sed 's/@@.*//')

    # Count @@ delimiters to detect severity field
    _at_count=$(printf '%s' "$_line" | tr -cd '@' | wc -c | tr -d ' ')
    _delim_count=$((_at_count / 2))

    if [ "$_delim_count" -ge 3 ]; then
        # 4-field format: id@@regex@@message@@severity
        severity=$(printf '%s' "$rest" | sed 's/.*@@//')
        message=$(printf '%s' "$rest" | sed 's/@@[^@]*$//' | sed 's/^[^@]*@@//')
    else
        # 3-field format: id@@regex@@message
        severity="standard"
        message=$(printf '%s' "$rest" | sed 's/^[^@]*@@//')
    fi
}

# --- Check blocking safety patterns ---
if [ -f "$SAFETY_FILE" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        case "$line" in
            '#'*|'') continue ;;
        esac

        parse_pattern_line "$line"

        # Profile filter: skip if rule requires higher profile than current
        SEV_LEVEL=$(severity_level "$severity")
        if [ "$PROFILE_LEVEL" -lt "$SEV_LEVEL" ]; then
            continue
        fi

        # Match command against regex
        if printf '%s' "$COMMAND" | grep -qE -- "$regex"; then
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

# --- Check advisory patterns (warn only, never block) ---
ADVISORIES=""
if [ -f "$ADVISORY_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            '#'*|'') continue ;;
        esac

        parse_pattern_line "$line"

        # Profile filter
        SEV_LEVEL=$(severity_level "$severity")
        if [ "$PROFILE_LEVEL" -lt "$SEV_LEVEL" ]; then
            continue
        fi

        if printf '%s' "$COMMAND" | grep -qE -- "$regex"; then
            if [ -z "$ADVISORIES" ]; then
                ADVISORIES="$message"
            else
                ADVISORIES="$ADVISORIES
  - $message"
            fi
        fi
    done < "$ADVISORY_FILE"
fi

if [ -n "$ADVISORIES" ]; then
    printf 'Advisory:\n  - %s\n' "$ADVISORIES" >&2
fi

exit 0
