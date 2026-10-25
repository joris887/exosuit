#!/usr/bin/env bash
# What could be lost if this session ended now. Read-only: changes nothing
# except the remote-tracking refs a fetch updates.
#
# One line per finding, then a last line: VERDICT all-set | to-save
#   UNCOMMITTED <n> files in this worktree (<branch>)        -> to-save
#   UNPUSHED    <branch>: <n> commits on no remote           -> to-save
#   DETACHED    <n> commits on no branch                     -> to-save
#   LANE        <branch>: <n> commits, merges into <parent> locally
#   ELSEWHERE   <path> (<branch>): <n> uncommitted files     another worktree; its own session commits there
#   GONE        <branch>: its remote branch was deleted      usually merged; check, then delete it
#   STASH       <n> entries, on this machine only
#   NO-REMOTE   this repository has no remote                -> to-save when it has commits
set -euo pipefail

git fetch -q --all --prune 2>/dev/null || true

HERE="$(git rev-parse --show-toplevel)"
CURRENT="$(git rev-parse --abbrev-ref HEAD)"
to_save=0

if [ -z "$(git remote)" ]; then
  echo "NO-REMOTE   this repository has no remote"
  git rev-parse -q --verify HEAD >/dev/null && to_save=1
fi

n="$(git status --porcelain | wc -l | tr -d ' ')"
if [ "$n" -gt 0 ]; then
  echo "UNCOMMITTED $n files in this worktree ($CURRENT)"
  to_save=1
fi

if [ "$CURRENT" = "HEAD" ]; then
  d="$(git rev-list --count HEAD --not --branches --remotes 2>/dev/null || echo 0)"
  if [ "$d" -gt 0 ]; then
    echo "DETACHED    $d commits on no branch"
    to_save=1
  fi
fi

while IFS='|' read -r branch upstream track; do
  [ -n "$branch" ] || continue
  parent="$(git config "branch.$branch.exosuitParent" || true)"
  case "$track" in
    *gone*) echo "GONE        $branch: its remote branch was deleted"; continue ;;
  esac
  if [ -n "$upstream" ]; then
    ahead="$(git rev-list --count "$upstream..$branch" 2>/dev/null || echo 0)"
  else
    ahead="$(git rev-list --count "$branch" --not --remotes 2>/dev/null || echo 0)"
  fi
  [ "$ahead" -gt 0 ] || continue
  if [ -n "$parent" ] && [ -z "$upstream" ]; then
    echo "LANE        $branch: $ahead commits, merges into $parent locally"
  else
    echo "UNPUSHED    $branch: $ahead commits on no remote"
    to_save=1
  fi
done < <(git for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads)

# Other worktrees: listed, never counted. A lane's own Claude Code commits there.
git worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r wt; do
  [ "$wt" = "$HERE" ] && continue
  [ -d "$wt" ] || continue
  m="$(git -C "$wt" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$m" -gt 0 ]; then
    echo "ELSEWHERE   $wt ($(git -C "$wt" rev-parse --abbrev-ref HEAD)): $m uncommitted files"
  fi
done

s="$(git stash list | wc -l | tr -d ' ')"
if [ "$s" -gt 0 ]; then echo "STASH       $s entries, on this machine only"; fi

if [ "$to_save" = 1 ]; then echo "VERDICT to-save"; else echo "VERDICT all-set"; fi
