#!/usr/bin/env bash
# Remove every lane whose branch is fully merged into its parent: worktree
# removed, branch deleted (safe -d only), tmux window closed. Lanes with
# uncommitted or unmerged work are kept and reported.
# Also closes orphaned lane windows: windows whose lane folder no longer exists.
set -euo pipefail

MAIN_ROOT="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1)"
REPO_NAME="$(basename "$MAIN_ROOT")"
LANES_DIR="${EXOSUIT_LANES_DIR:-$HOME/lanes/$REPO_NAME}"
case "$(git rev-parse --show-toplevel)/" in
  "$LANES_DIR"/*) echo "ERROR: run cleanup from the main checkout; it would close this lane's own window" >&2; exit 1 ;;
esac
HAVE_TMUX=0
command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1 && HAVE_TMUX=1

# Close every tmux window that was opened for the lane at path $1.
kill_lane_windows () {
  [ "$HAVE_TMUX" = 1 ] || return 0
  tmux list-windows -a -F '#{window_id}|#{@exosuit-lane}' 2>/dev/null |
    while IFS='|' read -r wid path; do
      [ "$path" = "$1" ] && tmux kill-window -t "$wid" 2>/dev/null || true
    done
}

removed=()
kept=()

for wt in "$LANES_DIR"/*/; do
  wt="${wt%/}"
  [ -e "$wt/.git" ] || continue
  letter="$(basename "$wt")"
  br="$(git -C "$wt" rev-parse --abbrev-ref HEAD)"
  parent="$(git -C "$wt" config "branch.$br.exosuitParent" || echo "${br%-*}")"

  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    kept+=("$letter ($br): uncommitted work; commit or discard it in the lane first")
    continue
  fi
  if ! git -C "$MAIN_ROOT" merge-base --is-ancestor "$br" "$parent" 2>/dev/null; then
    kept+=("$letter ($br): commits not in $parent; run /merge-up in the lane first")
    continue
  fi
  if ! git -C "$MAIN_ROOT" worktree remove "$wt"; then
    kept+=("$letter ($br): git could not remove the worktree")
    continue
  fi
  kill_lane_windows "$wt"
  if git -C "$MAIN_ROOT" branch -d "$br" >/dev/null 2>&1; then
    removed+=("$letter ($br)")
  else
    kept+=("$letter: worktree removed, branch $br kept (git branch -d refused it)")
  fi
done

git -C "$MAIN_ROOT" worktree prune
rmdir "$LANES_DIR" 2>/dev/null || true

# Orphaned windows: a lane window whose folder is gone (removed by hand, or by
# a cleanup that ran outside tmux).
orphaned=()
if [ "$HAVE_TMUX" = 1 ]; then
  while IFS='|' read -r wid path; do
    case "$path" in
      "$LANES_DIR"/*)
        if [ ! -d "$path" ] && tmux kill-window -t "$wid" 2>/dev/null; then
          orphaned+=("${path##*/}")
        fi ;;
    esac
  done < <(tmux list-windows -a -F '#{window_id}|#{@exosuit-lane}' 2>/dev/null || true)
fi

# Every array is read behind a length check: bash 3.2 (macOS) treats an empty
# array as unset under set -u.
if [ "${#removed[@]}" -gt 0 ]; then echo "Removed: ${removed[*]}"; else echo "Removed: none"; fi
if [ "${#kept[@]}" -gt 0 ]; then
  echo "Kept:"
  printf '  %s\n' "${kept[@]}"
else
  echo "Kept:    none"
fi
if [ "${#orphaned[@]}" -gt 0 ]; then echo "Orphaned windows closed: ${orphaned[*]}"; fi
