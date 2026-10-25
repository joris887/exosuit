#!/usr/bin/env bash
# Show every lane: its branch, how far it is ahead of and behind its parent,
# uncommitted files, whether its tmux window is open, and the last commit.
# Run from the main checkout or from any lane. Also binds Alt+<number> again
# (lane-keys.sh), for a tmux server that restarted since the lanes were made.
set -euo pipefail

bash "$(cd "$(dirname "$0")" && pwd)/lane-keys.sh"

MAIN_ROOT="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1)"
REPO_NAME="$(basename "$MAIN_ROOT")"
LANES_DIR="${EXOSUIT_LANES_DIR:-$HOME/lanes/$REPO_NAME}"

if [ ! -d "$LANES_DIR" ] || [ -z "$(ls -A "$LANES_DIR" 2>/dev/null)" ]; then
  echo "No lanes (nothing under $LANES_DIR)."
  exit 0
fi

# Paths of the lanes that have a tmux window, one per line.
windows=""
if command -v tmux >/dev/null 2>&1; then
  windows="$(tmux list-windows -a -F '#{@exosuit-lane}' 2>/dev/null || true)"
fi

printf "%-5s %-24s %-8s %-6s %-6s %-6s %s\n" LANE BRANCH PARENT AHEAD BEHIND DIRTY "WINDOW  LAST COMMIT"
for wt in "$LANES_DIR"/*/; do
  wt="${wt%/}"
  [ -e "$wt/.git" ] || continue
  letter="$(basename "$wt")"
  br="$(git -C "$wt" rev-parse --abbrev-ref HEAD)"
  parent="$(git -C "$wt" config "branch.$br.exosuitParent" || echo "${br%-*}")"
  ahead="$(git -C "$wt" rev-list --count "$parent..$br" 2>/dev/null || echo '?')"
  behind="$(git -C "$wt" rev-list --count "$br..$parent" 2>/dev/null || echo '?')"
  dirty="$(git -C "$wt" status --porcelain | wc -l | tr -d ' ')"
  window="no"
  printf '%s\n' "$windows" | grep -Fxq "$wt" && window="yes"
  last="$(git -C "$wt" log -1 --format='%s' 2>/dev/null | cut -c1-50)"
  printf "%-5s %-24s %-8s %-6s %-6s %-6s %-7s %s\n" "$letter" "$br" "$parent" "$ahead" "$behind" "$dirty" "$window" "$last"
done

echo
echo "BEHIND > 0  run /merge-down in that lane"
echo "AHEAD > 0   work not merged yet: /merge-down, the gates, then /merge-up when the story is done"
