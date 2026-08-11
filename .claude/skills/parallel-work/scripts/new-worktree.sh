#!/usr/bin/env bash
# Create a git worktree pre-wired with the project's gitignored local settings.
#
# Usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>]
#   <new-branch>    name of the NEW branch to create for the worktree
#   <base-ref>      branch/commit to start from        (default: current branch)
#   <worktree-dir>  destination path                   (default: ../<repo>-<branch>)
#
# Propagates, when present and not already in the worktree: .env, .env.local,
# .claude/settings.local.json, CLAUDE.local.md, and .mcp.json (absolute paths
# rewritten to the new worktree; skipped when the target branch tracks it).
# Extra project-specific files: set EXOSUIT_WORKTREE_COPY to a colon-separated
# list of repo-relative paths to copy as well.
#
# Records the parent branch in git config (branch.<new-branch>.exosuitParent)
# so /merge-up and /merge-down know where this stream came from.
set -euo pipefail

NEW_BRANCH="${1:?usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>]}"
BASE_REF="${2:-$(git rev-parse --abbrev-ref HEAD)}"

# Main worktree = first entry of `git worktree list`. It holds the canonical
# local settings files.
MAIN_ROOT="$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
REPO_NAME="$(basename "$MAIN_ROOT")"
PARENT_DIR="$(dirname "$MAIN_ROOT")"

SAFE_BRANCH="${NEW_BRANCH//\//-}"
WORKTREE_DIR="${3:-$PARENT_DIR/$REPO_NAME-$SAFE_BRANCH}"

if [ -e "$WORKTREE_DIR" ]; then
  echo "ERROR: $WORKTREE_DIR already exists" >&2; exit 1
fi
if git show-ref --verify --quiet "refs/heads/$NEW_BRANCH"; then
  echo "ERROR: branch $NEW_BRANCH already exists" >&2; exit 1
fi

echo ">> git worktree add -b $NEW_BRANCH $WORKTREE_DIR $BASE_REF"
git worktree add -b "$NEW_BRANCH" "$WORKTREE_DIR" "$BASE_REF"

# Record the parent branch durably so /merge-up and /merge-down can find it.
git config "branch.$NEW_BRANCH.exosuitParent" "$BASE_REF"
echo "   recorded parent: branch.$NEW_BRANCH.exosuitParent = $BASE_REF"

copy_if_present () {
  local rel="$1"
  if [ -e "$MAIN_ROOT/$rel" ] && [ ! -e "$WORKTREE_DIR/$rel" ]; then
    mkdir -p "$(dirname "$WORKTREE_DIR/$rel")"
    cp -R "$MAIN_ROOT/$rel" "$WORKTREE_DIR/$rel"
    echo "   copied  $rel"
  fi
}

# 1. Plain local config files (gitignored, so not present in a fresh worktree)
copy_if_present ".env"
copy_if_present ".env.local"
copy_if_present ".claude/settings.local.json"
copy_if_present "CLAUDE.local.md"

# 2. .mcp.json — copy only if the target branch doesn't track it, rewriting
#    absolute paths (e.g. --cwd arguments) to point at the new worktree.
if git -C "$WORKTREE_DIR" ls-files --error-unmatch .mcp.json >/dev/null 2>&1; then
  echo "   skip    .mcp.json (tracked on $NEW_BRANCH — left as-is)"
elif [ -f "$MAIN_ROOT/.mcp.json" ]; then
  sed "s#$MAIN_ROOT#$WORKTREE_DIR#g" "$MAIN_ROOT/.mcp.json" > "$WORKTREE_DIR/.mcp.json"
  echo "   wrote   .mcp.json (absolute paths rewritten to worktree)"
fi

# 3. Project-specific extras, if configured
if [ -n "${EXOSUIT_WORKTREE_COPY:-}" ]; then
  IFS=':' read -ra EXTRAS <<< "$EXOSUIT_WORKTREE_COPY"
  for rel in "${EXTRAS[@]}"; do
    [ -n "$rel" ] && copy_if_present "$rel"
  done
fi

echo
echo "Worktree ready: $WORKTREE_DIR"
echo "  branch $NEW_BRANCH (off $BASE_REF)"
echo "  note: dependency directories (node_modules, .venv, vendor, target) are"
echo "        not copied — install them per worktree if the project needs them."
