#!/bin/sh
# PostToolUseFailure handler: log tool failures + inject error recovery guidance.
# 1. Logs all tool failures to docs/sessions/.failure-log.jsonl
# 2. Detects cascading failures (3+ on same target) and escalates
# 3. Injects targeted recovery guidance via systemMessage
# Advisory only (cannot block). POSIX-compliant — no bash required.
#
# Input:  JSON on stdin (tool_name, tool_input, error_message)
# Output: JSON on stdout with systemMessage (exit 0)

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "post-tool-failure" "standard" || exit 0

# --- JSON field extraction ---
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
TOOL_NAME=$(printf '%s' "$INPUT" | extract_json ".tool_name" "tool_name")
ERROR_MSG=$(printf '%s' "$INPUT" | extract_json ".error_message" "error_message")

# Extract target (file_path for Edit/Write/Read, command for Bash)
TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.file_path" "file_path")
if [ -z "$TARGET" ]; then
    TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.command" "command" | cut -c1-120)
fi
[ -z "$TARGET" ] && TARGET="unknown"

# --- 1. Log failure ---
LOG_DIR="docs/sessions"
FAIL_LOG="$LOG_DIR/.failure-log.jsonl"
mkdir -p "$LOG_DIR" 2>/dev/null
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

SAFE_TARGET=$(printf '%s' "$TARGET" | cut -c1-120 | sed 's/"/\\"/g')
SAFE_ERROR=$(printf '%s' "$ERROR_MSG" | cut -c1-200 | sed 's/"/\\"/g' | tr '\n' ' ')
printf '{"ts":"%s","type":"tool-failure","tool":"%s","target":"%s","error":"%s"}\n' \
    "$TS" "$TOOL_NAME" "$SAFE_TARGET" "$SAFE_ERROR" >> "$FAIL_LOG" 2>/dev/null

# --- 2. Cascading failure detection ---
CASCADE_COUNT=0
if [ -f "$FAIL_LOG" ]; then
    CASCADE_COUNT=$(tail -10 "$FAIL_LOG" 2>/dev/null | grep -c "\"target\":\"$SAFE_TARGET\"" 2>/dev/null || echo "0")
fi

# --- 3. Build recovery guidance ---
GUIDANCE=""

case "$TOOL_NAME" in
    Edit)
        case "$ERROR_MSG" in
            *"not found"*|*"not unique"*)
                GUIDANCE="Edit failed — re-read the file before retrying. File content may have changed. If old_string was not unique, include more surrounding context." ;;
            *)
                GUIDANCE="Edit failed. Re-read the target file to refresh context before retrying." ;;
        esac
        ;;
    Bash)
        case "$ERROR_MSG" in
            *"command not found"*)
                GUIDANCE="Command not found. Check CLAUDE.md Commands for the correct command, or verify the tool is installed." ;;
            *"permission denied"*)
                GUIDANCE="Permission denied. Check file permissions. Do NOT use sudo unless explicitly authorized." ;;
            *"timed out"*|*"timeout"*)
                GUIDANCE="Command timed out. Check for infinite loops or hanging processes. Try with a shorter timeout." ;;
            *)
                GUIDANCE="Bash command failed. Diagnose the error before retrying — do not retry the identical command." ;;
        esac
        ;;
    Read)
        GUIDANCE="File read failed. Verify the path exists using Glob before retrying."
        ;;
    Write)
        GUIDANCE="File write failed. Verify the parent directory exists and the file path is correct."
        ;;
    *)
        GUIDANCE="Tool $TOOL_NAME failed. Review the error and adjust your approach."
        ;;
esac

# Cascading failure escalation
if [ "$CASCADE_COUNT" -ge 3 ]; then
    GUIDANCE="$GUIDANCE CASCADING FAILURE ($CASCADE_COUNT on same target): STOP and reconsider your approach. The current strategy is not working — try a fundamentally different method rather than retrying variations."
fi

# --- 4. Output systemMessage ---
if [ -n "$GUIDANCE" ]; then
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$GUIDANCE" | jq -Rsc '{ systemMessage: . }'
    else
        SAFE_GUIDANCE=$(printf '%s' "$GUIDANCE" | sed 's/"/\\"/g' | tr '\n' ' ')
        printf '{"systemMessage":"%s"}\n' "$SAFE_GUIDANCE"
    fi
fi

exit 0
