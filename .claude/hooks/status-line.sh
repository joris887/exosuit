#!/usr/bin/env bash
# Requirements: git (always available)
# Behavior: Outputs one-line status for Claude Code status bar. Always exits 0.
# Format: "Sprint N | branch-name*" or just "branch-name*" if no sprint info.

# Path resolution (plugin/template mode compatible)
source "$(dirname "$0")/lib/paths.sh"

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
DIRTY=$(git diff --quiet 2>/dev/null && echo "" || echo "*")

PROGRESS_FILE="$(project_path "docs/progress.md")"
SPRINT=""
if [[ -f "$PROGRESS_FILE" ]]; then
  SPRINT=$(grep -m1 'Sprint\*\*:' "$PROGRESS_FILE" 2>/dev/null | sed 's/.*: *//' | tr -d ' ')
fi

if [[ -n "$SPRINT" && "$SPRINT" != "<!--"* ]]; then
  echo "Sprint ${SPRINT} | ${BRANCH}${DIRTY}"
else
  echo "${BRANCH}${DIRTY}"
fi
