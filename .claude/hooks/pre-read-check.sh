#!/bin/sh
# PreToolUse handler for Read: warn when reading sensitive files.
# Matches file_path against rules/sensitive-files.patterns.
# Advisory only (always exit 0) — warns on stderr.
# POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (file_path)
# Output: advisory warnings on stderr, always exit 0

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$HOOKS_DIR/rules"
PATTERNS_FILE="$RULES_DIR/sensitive-files.patterns"

# --- Hook guard: profile + disable check ---
# Raised from "standard" to "strict": this fires on EVERY Read to match a path
# regex, and is advisory only (never blocks). The cost is latency on every file
# read across a whole session; the benefit is a warning the model can also reach
# by reading .claude/rules/security.md. Strict projects still get it.
"$HOOKS_DIR/lib/hook-guard.sh" "pre-read-check" "strict" || exit 0

# --- JSON field extraction ---
# Supports dotted paths with jq, flat keys with sed. The sed fallback matches the
# key anywhere in the payload, so it finds nested values too when jq is missing.
extract_json() {
    _jq_path="$1"
    _sed_key="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r "$_jq_path // empty"
    else
        sed -n 's/.*"'"$_sed_key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}

# Read stdin once
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | extract_json ".tool_input.file_path" "file_path")

# If no file path, allow through
[ -z "$FILE_PATH" ] && exit 0

# --- Check sensitive file patterns ---
WARNINGS=""
if [ -f "$PATTERNS_FILE" ]; then
    while IFS= read -r line; do
        case "$line" in
            '#'*|'') continue ;;
        esac

        # Split on @@ delimiter: id@@regex@@message
        regex=$(printf '%s' "$line" | sed 's/^[^@]*@@//' | sed 's/@@.*//')
        message=$(printf '%s' "$line" | sed 's/.*@@//')

        if printf '%s' "$FILE_PATH" | grep -qE -- "$regex"; then
            if [ -z "$WARNINGS" ]; then
                WARNINGS="$message"
            else
                WARNINGS="$WARNINGS
  - $message"
            fi
        fi
    done < "$PATTERNS_FILE"
fi

if [ -n "$WARNINGS" ]; then
    printf 'Sensitive file warning:\n  - %s\n' "$WARNINGS" >&2
fi

exit 0
