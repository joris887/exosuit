#!/usr/bin/env bash
# Requirements: grep (always available)
# Behavior: Advisory intent classification on user prompts. Never blocks (exit 0).

INPUT=$(cat 2>/dev/null || echo "")
[[ -z "$INPUT" ]] && exit 0

# Extract user prompt text
if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // empty' 2>/dev/null || echo "")
else
  PROMPT=$(echo "$INPUT" | sed -n 's/.*"user_prompt"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/p' | head -1)
fi

[[ -z "$PROMPT" ]] && exit 0

# Warn about potentially destructive requests (advisory only, never block)
if echo "$PROMPT" | grep -qiE 'delete (all|everything)|drop (table|database)|remove all files|wipe|nuke|destroy|format disk'; then
  echo "Warning: This request sounds potentially destructive. Proceed with caution." >&2
fi

# Always allow
exit 0
