#!/bin/sh
# PostToolUse handler: log tool invocations to activity log.
# Appends timestamped JSON lines for Edit, Write, and Bash tool use.
# Rotates at 200 entries. Advisory only (always exit 0).
# POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_ENTRIES=200

# --- JSON field extraction ---
# Extracts a field from JSON. Supports dotted paths with jq, flat keys with sed.
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

# Only log Edit, Write, Bash
case "$TOOL_NAME" in
    Edit|Write|Bash) ;;
    *) exit 0 ;;
esac

# Extract target (file_path for Edit/Write, command for Bash)
TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.file_path" "file_path")
if [ -z "$TARGET" ]; then
    TARGET=$(printf '%s' "$INPUT" | extract_json ".tool_input.command" "command" | cut -c1-120)
fi
[ -z "$TARGET" ] && exit 0

# Resolve project log directory
LOG_DIR="docs/sessions"
LOG_FILE="$LOG_DIR/.activity-log.jsonl"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

# Timestamp
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Append entry (manual JSON to avoid jq dependency for writing)
# Escape double quotes in target for JSON safety
SAFE_TARGET=$(printf '%s' "$TARGET" | sed 's/"/\\"/g')
printf '{"ts":"%s","tool":"%s","target":"%s"}\n' "$TS" "$TOOL_NAME" "$SAFE_TARGET" >> "$LOG_FILE" 2>/dev/null

# Rotate: keep last MAX_ENTRIES lines
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
    if [ "$LINE_COUNT" -gt "$MAX_ENTRIES" ]; then
        TMPFILE="$LOG_FILE.tmp"
        tail -n "$MAX_ENTRIES" "$LOG_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$LOG_FILE" 2>/dev/null
    fi
fi

exit 0
