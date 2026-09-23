#!/usr/bin/env bash
# Show status of all git worktrees: branch, recorded parent, ahead/behind.
# Usage: bash scripts/worktree-status.sh
#
# Outputs a formatted table of worktree status. Each stream is compared
# against ITS OWN parent (git config branch.<name>.exosuitParent, recorded by
# new-worktree.sh) — no branch name is hardcoded.

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: bash scripts/worktree-status.sh [OPTIONS]

Show status of all git worktrees with branch and parent information.

Options:
  -h, --help    Show this help message

Output:
  Prints a formatted table showing each worktree's path, branch, recorded
  parent branch (branch.<name>.exosuitParent, "-" when unset), and commits
  ahead/behind that parent.

Examples:
  bash scripts/worktree-status.sh
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help

echo "## Worktree Status"
echo ""
echo "| Path | Branch | Parent | Ahead/Behind parent |"
echo "|------|--------|--------|---------------------|"

# Porcelain entry = a `worktree <path>` line, a `HEAD <sha>` line (always
# present — NOT a detached marker), then `branch <ref>` OR `detached`.
WT_PATH="" WT_HEAD="" WT_BRANCH="" WT_DETACHED=0 MAIN_SEEN=0

emit_row () {
  [ -n "$WT_PATH" ] || return 0
  if [ "$MAIN_SEEN" = "0" ]; then
    # First entry = the main worktree: it IS the base (even detached), nothing
    # to compare to.
    MAIN_SEEN=1
    if [ "$WT_DETACHED" = "1" ]; then
      echo "| $WT_PATH | (detached ${WT_HEAD:0:7}) | - | (base) |"
    else
      echo "| $WT_PATH | $WT_BRANCH | - | (base) |"
    fi
  elif [ "$WT_DETACHED" = "1" ]; then
    echo "| $WT_PATH | (detached ${WT_HEAD:0:7}) | - | - |"
  else
    local parent counts ahead behind
    parent="$(git config "branch.$WT_BRANCH.exosuitParent" 2>/dev/null || true)"
    if [ -n "$parent" ] && counts="$(git rev-list --left-right --count "$parent...$WT_BRANCH" 2>/dev/null)"; then
      behind="${counts%%[[:space:]]*}"   # commits only on the parent
      ahead="${counts##*[[:space:]]}"    # commits only on this branch
      echo "| $WT_PATH | $WT_BRANCH | $parent | +$ahead/-$behind |"
    else
      echo "| $WT_PATH | $WT_BRANCH | ${parent:--} | ? |"
    fi
  fi
  WT_PATH="" WT_HEAD="" WT_BRANCH="" WT_DETACHED=0
}

while IFS= read -r line; do
  case "$line" in
    "worktree "*) emit_row; WT_PATH="${line#worktree }" ;;
    "HEAD "*)     WT_HEAD="${line#HEAD }" ;;
    "branch "*)   WT_BRANCH="${line#branch refs/heads/}" ;;
    detached)     WT_DETACHED=1 ;;
  esac
done < <(git worktree list --porcelain)
emit_row

echo ""
echo "---"
echo "Use \`/parallel-work cleanup\` (or \`git worktree remove <path>\`) to clean up merged worktrees."
