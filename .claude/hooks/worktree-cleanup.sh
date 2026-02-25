#!/usr/bin/env bash
# Requirements: git
# Behavior: Merges activity logs back to main worktree. Advisory only (exit 0).

set -euo pipefail

MAIN_WORKTREE=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/worktree //')
[[ -z "$MAIN_WORKTREE" ]] && exit 0

LOG="docs/sessions/.activity-log.jsonl"
MAIN_LOG="$MAIN_WORKTREE/$LOG"

if [[ -f "$LOG" ]]; then
  if [[ -f "$MAIN_LOG" ]]; then
    cat "$LOG" >> "$MAIN_LOG"
  else
    mkdir -p "$(dirname "$MAIN_LOG")"
    cp "$LOG" "$MAIN_LOG"
  fi
fi

exit 0
