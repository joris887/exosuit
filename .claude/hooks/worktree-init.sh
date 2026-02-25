#!/usr/bin/env bash
# Requirements: git
# Behavior: Initializes framework state in new worktree. Advisory only (exit 0).

set -euo pipefail

MAIN_WORKTREE=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/worktree //')
[[ -z "$MAIN_WORKTREE" ]] && exit 0

CURRENT=$(pwd)
[[ "$CURRENT" == "$MAIN_WORKTREE" ]] && exit 0

for f in ".failure-state.md" "docs/sessions/.auto-save.md"; do
  SRC="$MAIN_WORKTREE/$f"
  if [[ -f "$SRC" ]]; then
    mkdir -p "$(dirname "$f")"
    cp "$SRC" "$f"
  fi
done

mkdir -p "docs/sessions"
echo "Worktree initialized with framework state." >&2
exit 0
