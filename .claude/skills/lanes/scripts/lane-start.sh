#!/usr/bin/env bash
# Create parallel lanes off the current branch, each in its own tmux window.
#
# A lane = branch <parent>-<letter>
#        + worktree <lanes-dir>/<letter>, made by parallel-work's new-worktree.sh
#          (local settings copied, parent recorded for /merge-up and /merge-down)
#        + tmux window <letter> that installs dependencies and starts Claude Code,
#          on /story-cycle <story> when a story id is given.
#
# Usage: lane-start.sh <letter>[:<story-id>] ...   e.g. lane-start.sh a:E03-S03 b:E03-S04 c
# Env:
#   EXOSUIT_LANES_DIR     where the lanes live            (default: ~/lanes/<repo>)
#   EXOSUIT_LANE_SETUP    command run first in each lane  (default: from the lockfile;
#                         set it empty to skip)
#   EXOSUIT_LANE_CLAUDE   command that starts Claude Code (default: claude)
#   EXOSUIT_LANE_SESSION  tmux session for the windows    (default: the current one;
#                         outside tmux, a session named after the repo)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NEW_WORKTREE="$HERE/../../parallel-work/scripts/new-worktree.sh"

if [ $# -lt 1 ]; then
  echo "usage: lane-start.sh <letter>[:<story-id>] ...   e.g. lane-start.sh a:E03-S03 b:E03-S04 c" >&2
  exit 2
fi
command -v tmux >/dev/null 2>&1 || { echo "ERROR: tmux is not installed" >&2; exit 1; }
[ -f "$NEW_WORKTREE" ] || { echo "ERROR: $NEW_WORKTREE not found (lanes needs parallel-work)" >&2; exit 1; }

MAIN_ROOT="$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1)"
REPO_NAME="$(basename "$MAIN_ROOT")"
LANES_DIR="${EXOSUIT_LANES_DIR:-$HOME/lanes/$REPO_NAME}"
PARENT="$(git rev-parse --abbrev-ref HEAD)"
DEFAULT="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
DEFAULT="${DEFAULT#origin/}"

case "$PARENT" in
  HEAD) echo "ERROR: HEAD is detached; check out the sprint branch first" >&2; exit 1 ;;
  main|master|"$DEFAULT")
    echo "ERROR: refusing to fan out from '$PARENT'; start a sprint branch first (/sprint-start)" >&2
    exit 1 ;;
esac
if [ -n "$(git config "branch.$PARENT.exosuitParent" || true)" ]; then
  echo "ERROR: '$PARENT' is itself a lane or stream; create lanes from the sprint branch" >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is dirty; commit or stash first so every lane starts from a known state" >&2
  exit 1
fi

if [ -n "${EXOSUIT_LANE_SESSION:-}" ]; then
  SESSION="$EXOSUIT_LANE_SESSION"
elif [ -n "${TMUX:-}" ]; then
  SESSION="$(tmux display-message -p '#S')"
else
  SESSION="${REPO_NAME//[.:]/-}"
fi
if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -c "$MAIN_ROOT"
  echo "Started tmux session $SESSION (attach with: tmux attach -t $SESSION)"
fi

setup_cmd () {
  if [ -n "${EXOSUIT_LANE_SETUP+set}" ]; then printf '%s' "$EXOSUIT_LANE_SETUP"; return; fi
  if   [ -f "$1/pnpm-lock.yaml" ];    then printf 'pnpm install --silent'
  elif [ -f "$1/package-lock.json" ]; then printf 'npm ci --silent'
  elif [ -f "$1/yarn.lock" ];         then printf 'yarn install --silent'
  elif [ -f "$1/bun.lock" ] || [ -f "$1/bun.lockb" ]; then printf 'bun install'
  elif [ -f "$1/uv.lock" ];           then printf 'uv sync'
  elif [ -f "$1/poetry.lock" ];       then printf 'poetry install'
  fi
}

mkdir -p "$LANES_DIR"

for arg in "$@"; do
  letter="${arg%%:*}"
  story=""
  [ "$arg" != "$letter" ] && story="${arg#*:}"
  if ! [[ "$letter" =~ ^[a-z]$ ]]; then
    echo "SKIP $arg: a lane is one letter, a to z"; continue
  fi
  if [ -n "$story" ] && ! [[ "$story" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "SKIP $arg: a story id holds letters, digits, dot, dash and underscore only"; continue
  fi
  branch="$PARENT-$letter"
  wt="$LANES_DIR/$letter"
  if [ -e "$wt" ]; then echo "SKIP $letter: $wt already exists"; continue; fi
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "SKIP $letter: branch $branch already exists"; continue
  fi

  bash "$NEW_WORKTREE" "$branch" "$PARENT" "$wt" >/dev/null

  cmd="${EXOSUIT_LANE_CLAUDE:-claude}"
  [ -n "$story" ] && cmd="$cmd '/story-cycle $story'"
  setup="$(setup_cmd "$wt")"
  [ -n "$setup" ] && cmd="$setup; $cmd"

  wid="$(tmux new-window -d -P -F '#{window_id}' -t "=$SESSION:" -n "$letter" -c "$wt")"
  tmux set-option -w -t "$wid" @exosuit-lane "$wt"
  tmux send-keys -t "$wid" "$cmd" C-m
  echo "LANE $letter ready: branch=$branch worktree=$wt window=$SESSION:$letter story=${story:-none}"
done

echo
echo "Switch lanes: Ctrl-b w (list) | Ctrl-b <number> | Ctrl-b n / Ctrl-b p"
