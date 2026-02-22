#!/usr/bin/env bash
# Requirements: git (always available)
# Behavior: Advisory environment checks at session start; never blocks (always exits 0)
# Session-start hook: validates environment, detects stale state, checks git health.
#
# Outputs warnings to stderr for Claude to relay to the user.
# Always exits 0 — advisory only, never blocking.

set -euo pipefail

WARNINGS=()

# --- 1. Project tool existence ---
# Check for common project tools referenced in CLAUDE.md Commands
if [[ -f "CLAUDE.md" ]]; then
  while IFS= read -r line; do
    case "$line" in
      *"test:"*|*"lint:"*|*"format:"*|*"build:"*|*"typecheck:"*)
        # Extract the command name (first word after the colon)
        cmd=$(echo "$line" | sed 's/.*: *//' | awk '{print $1}')
        if [[ -n "$cmd" && "$cmd" != "<"* && "$cmd" != "#"* ]]; then
          if ! command -v "$cmd" &>/dev/null; then
            WARNINGS+=("Tool '$cmd' (from CLAUDE.md Commands) not found in PATH")
          fi
        fi
        ;;
    esac
  done < CLAUDE.md
fi

# --- 2. Stale session detection ---
AUTO_SAVE="docs/sessions/.auto-save.md"
if [[ -f "$AUTO_SAVE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    file_age=$(( $(date +%s) - $(stat -f %m "$AUTO_SAVE") ))
  else
    file_age=$(( $(date +%s) - $(stat -c %Y "$AUTO_SAVE") ))
  fi
  # Warn if auto-save is older than 24 hours
  if (( file_age > 86400 )); then
    days=$(( file_age / 86400 ))
    WARNINGS+=("Stale auto-save detected ($AUTO_SAVE is ${days}d old) — consider running /continue")
  fi
fi

# --- 3. Git state checks ---
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "")

  # Warn if on main
  if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    WARNINGS+=("On $branch branch — create a feature branch before making changes")
  fi

  # Warn if detached HEAD
  if [[ -z "$branch" ]]; then
    WARNINGS+=("Detached HEAD state — checkout a branch before making changes")
  fi

  # Warn if uncommitted changes
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    WARNINGS+=("Uncommitted changes detected — consider committing or stashing before starting")
  fi
fi

# --- 4. Missing hook detection ---
SETTINGS=".claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  if ! grep -q "Stop" "$SETTINGS" 2>/dev/null; then
    WARNINGS+=("No Stop hook configured — pre-stop-quality checks won't run automatically")
  fi
  if ! grep -q "PostToolUse" "$SETTINGS" 2>/dev/null; then
    WARNINGS+=("No PostToolUse hook configured — auto-format after edits won't run")
  fi
fi

# --- Output warnings ---
if (( ${#WARNINGS[@]} > 0 )); then
  echo "Session start checks:" >&2
  for w in "${WARNINGS[@]}"; do
    echo "  ⚠ $w" >&2
  done
fi

# Always exit 0 — advisory only
exit 0
