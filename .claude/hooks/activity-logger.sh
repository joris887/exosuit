#!/usr/bin/env bash
# Requirements: jq (optional — falls back to sed-based extraction)
# Behavior: Logs Edit/Write/Bash tool invocations to activity log; rotates at 200 entries
# PostToolUse hook: appends timestamped JSON lines for session activity tracking.
#
# Reads tool invocation from stdin JSON (tool_name, tool_input).
# Appends to docs/sessions/.activity-log.jsonl.

set -euo pipefail

LOG_DIR="docs/sessions"
LOG_FILE="$LOG_DIR/.activity-log.jsonl"
MAX_ENTRIES=200

# Read stdin (Claude Code passes tool invocation as JSON)
INPUT=$(cat 2>/dev/null || echo "")
[[ -z "$INPUT" ]] && exit 0

# Extract tool_name and relevant input
if command -v jq &>/dev/null; then
  tool_name=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
  # Extract file_path for Edit/Write, command for Bash
  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
  command_val=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
else
  # Fallback: sed-based extraction
  tool_name=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  file_path=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  command_val=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

# Only log Edit, Write, Bash
case "$tool_name" in
  Edit|Write|Bash) ;;
  *) exit 0 ;;
esac

# Determine the target (file path or command)
target=""
if [[ -n "$file_path" ]]; then
  target="$file_path"
elif [[ -n "$command_val" ]]; then
  # Truncate long commands
  target="${command_val:0:120}"
fi

[[ -z "$target" ]] && exit 0

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Append entry
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"ts\":\"$timestamp\",\"tool\":\"$tool_name\",\"target\":\"$target\"}" >> "$LOG_FILE"

# Rotate: keep last MAX_ENTRIES lines
if [[ -f "$LOG_FILE" ]]; then
  line_count=$(wc -l < "$LOG_FILE" | tr -d ' ')
  if (( line_count > MAX_ENTRIES )); then
    tail -n "$MAX_ENTRIES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
fi

exit 0
