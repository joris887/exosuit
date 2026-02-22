#!/usr/bin/env bash
# Show status of all git worktrees with branch and merge info.
# Usage: bash scripts/worktree-status.sh
#
# Outputs a formatted table of worktree status.

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: bash scripts/worktree-status.sh [OPTIONS]

Show status of all git worktrees with branch and merge information.

Options:
  -h, --help    Show this help message

Output:
  Prints a formatted table showing each worktree's path, branch,
  commits ahead of main, and whether it's been merged.

Examples:
  bash scripts/worktree-status.sh
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help

echo "## Worktree Status"
echo ""
echo "| Path | Branch | Ahead of Main | Merged? |"
echo "|------|--------|---------------|---------|"

git worktree list --porcelain | while read -r line; do
  case "$line" in
    "worktree "*)
      WT_PATH="${line#worktree }"
      ;;
    "branch "*)
      BRANCH="${line#branch refs/heads/}"
      AHEAD=$(git rev-list --count main.."$BRANCH" 2>/dev/null || echo "?")
      MERGED="No"
      if git branch --merged main 2>/dev/null | grep -qw "$BRANCH"; then
        MERGED="Yes"
      fi
      echo "| $WT_PATH | $BRANCH | $AHEAD | $MERGED |"
      ;;
    "HEAD "*)
      # Detached HEAD
      HEAD="${line#HEAD }"
      echo "| $WT_PATH | (detached ${HEAD:0:7}) | - | - |"
      ;;
  esac
done

echo ""
echo "---"
echo "Use \`git worktree remove <path>\` to clean up merged worktrees."
