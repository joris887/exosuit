#!/bin/sh
# PreToolUse handler: block dangerous Bash commands + advisory warnings.
# Loads blocking patterns from rules/safety.patterns (exit 2 on match).
# Loads advisory patterns from rules/advisory.patterns (warn only, exit 0).
# Supports profile-based severity filtering via EXOSUIT_HOOK_PROFILE.
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

# --- Explain mode: off, brief (default), verbose ---
EXPLAIN_MODE="${EXOSUIT_EXPLAIN_MODE:-brief}"

# --- Profile level for severity filtering ---
CURRENT_PROFILE="${EXOSUIT_HOOK_PROFILE:-standard}"
case "$CURRENT_PROFILE" in
    minimal) PROFILE_LEVEL=1 ;;
    strict)  PROFILE_LEVEL=3 ;;
    *)       PROFILE_LEVEL=2 ;;  # standard
esac

# --- JSON field extraction ---
# Extracts a field from JSON. Supports dotted paths with jq, flat keys with sed.
# The sed fallback matches the key anywhere in the payload, so it finds nested
# values too when jq is unavailable.
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
COMMAND=$(printf '%s' "$INPUT" | extract_json ".tool_input.command" "command")

# If no command, allow through
[ -z "$COMMAND" ] && exit 0

# --- Reduce the command to the part that actually executes ---
# A message body is prose, not a command. Writing a commit message that quotes a
# blocked command must not trip the blocker. Two narrow exclusions only:
#
#   1. Quoted values of message-carrying flags (-m, --body, ...). Note that -c is
#      deliberately absent: `psql -c "DROP TABLE users"` really does execute.
#   2. Heredoc bodies, and only for commit/PR-creation commands, where the heredoc
#      is the message. Anything after the terminator is kept, so a dangerous
#      command chained onto the end is still seen.
#
# Everything else is scanned verbatim.
scan_target() {
    _cmd="$1"

    # Heredoc bodies first, line by line, and only for message-carrying commands.
    case "$_cmd" in
        *"git commit"*|*"gh pr create"*|*"gh issue create"*)
            _cmd=$(printf '%s' "$_cmd" | awk '
                !inhd && index($0, "<<") {
                    s = substr($0, index($0, "<<") + 2)
                    sub(/^[-[:space:]]*/, "", s)
                    sub(/[[:space:]].*$/, "", s)
                    gsub(/[^A-Za-z0-9_]/, "", s)
                    if (s != "") { term = s; inhd = 1 }
                    print; next
                }
                inhd { if ($0 == term) inhd = 0; next }
                { print }
            ')
            ;;
    esac

    # Then quoted flag values. The whole command is slurped first because commit
    # messages routinely span lines, and a line-based pass would never see the
    # closing quote.
    printf '%s' "$_cmd" | awk -v Q="'" '
        { buf = buf (NR > 1 ? "\n" : "") $0 }
        END {
            flags = "(-m|-am|--message|--body|--body-file)[[:space:]]+"
            gsub(flags "\"[^\"]*\"", " MESSAGE_BODY ", buf)
            gsub(flags Q "[^" Q "]*" Q, " MESSAGE_BODY ", buf)
            printf "%s", buf
        }
    '
}

SCAN=$(scan_target "$COMMAND")

# --- Helper: map severity name to numeric level ---
severity_level() {
    case "$1" in
        critical) echo 1 ;;
        strict)   echo 3 ;;
        *)        echo 2 ;;  # standard (default)
    esac
}

# --- Helper: parse pattern line with optional severity and explanation ---
# Sets: id, regex, message, severity, explanation variables
parse_pattern_line() {
    _line="$1"

    id=$(printf '%s' "$_line" | sed 's/@@.*//')
    rest=$(printf '%s' "$_line" | sed 's/^[^@]*@@//')
    regex=$(printf '%s' "$rest" | sed 's/@@.*//')

    # Count @@ delimiters to detect field count
    _at_count=$(printf '%s' "$_line" | tr -cd '@' | wc -c | tr -d ' ')
    _delim_count=$((_at_count / 2))

    explanation=""

    if [ "$_delim_count" -ge 4 ]; then
        # 5-field format: id@@regex@@message@@severity@@explanation
        explanation=$(printf '%s' "$rest" | sed 's/.*@@//')
        # Strip explanation from rest to parse message and severity
        _no_expl=$(printf '%s' "$rest" | sed 's/@@[^@]*$//')
        severity=$(printf '%s' "$_no_expl" | sed 's/.*@@//')
        message=$(printf '%s' "$_no_expl" | sed 's/@@[^@]*$//' | sed 's/^[^@]*@@//')
    elif [ "$_delim_count" -ge 3 ]; then
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
        if printf '%s' "$SCAN" | grep -qE -- "$regex"; then
            if [ "$EXPLAIN_MODE" = "verbose" ] && [ -n "$explanation" ]; then
                printf 'BLOCKED: %s\n  %s\n' "$message" "$explanation" >&2
            elif [ "$EXPLAIN_MODE" != "off" ]; then
                printf 'BLOCKED: %s\n' "$message" >&2
            fi
            exit 2
        fi
    done < "$SAFETY_FILE"
fi

# --- Framework template repo protection ---
# The -C form is included deliberately: without it, `git -C <path> push` slipped
# past this check while still being caught by the safety patterns above.
if printf '%s' "$SCAN" | grep -qE '(gh\s+(pr|issue)\s+create|git\s+(-C\s+\S+\s+)?push)'; then
    FRAMEWORK_REPO="${EXOSUIT_FRAMEWORK_REPO:-joris887/exosuit}"
    REMOTE=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE" ]; then
        # Compare owner/repo exactly. A substring test matched any repository whose
        # name merely started with the framework's -- joris887/exosuit-homepage was
        # treated as joris887/exosuit and could never be pushed.
        REMOTE_PATH=$(printf '%s' "$REMOTE" | sed -e 's#\.git$##' -e 's#^.*[:/]\([^/][^/]*/[^/][^/]*\)$#\1#')
        case "$REMOTE_PATH" in
            "$FRAMEWORK_REPO")
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

        if printf '%s' "$SCAN" | grep -qE -- "$regex"; then
            if [ -z "$ADVISORIES" ]; then
                ADVISORIES="$message"
            else
                ADVISORIES="$ADVISORIES
  - $message"
            fi
        fi
    done < "$ADVISORY_FILE"
fi

if [ -n "$ADVISORIES" ] && [ "$EXPLAIN_MODE" != "off" ]; then
    printf 'Advisory:\n  - %s\n' "$ADVISORIES" >&2
fi

exit 0
