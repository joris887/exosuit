#!/usr/bin/env bash
# Usage: stream-cleanup.sh [--apply] [-h|--help]
#
# Removes finished parallel streams: linked worktrees whose branch records a
# parent (branch.<b>.exosuitParent), is merged into that parent, has a clean
# tree, is not blocked by a stale upstream and, under --apply, hosts no live
# Claude session. Without --apply this is a DRY RUN: one verdict line per
# linked worktree, nothing changed. The main worktree is never a candidate.
#
# Facts come from the sibling worktree-status.sh --porcelain (located next to
# this script); everything it writes to stderr, including the session-detection
# ADVISORY, passes through to the caller. Never forces: the only
# branch-deletion flag is -d, run inside the parent's worktree so git judges
# "merged" against the parent (or against the branch's upstream when one is
# set — the reason for the upstream keeps below).
#
# stdout, one line per linked worktree, first matching rule wins:
#   CLEANUP: keep <b> <path> — this is the current worktree; run cleanup from the base (<parent>) instead
#   CLEANUP: keep <b> <path> — this is the current worktree; run cleanup from the base instead   (no recorded parent)
#   CLEANUP: keep <b> <path> — no recorded parent (not a stream; not ours to remove)
#   CLEANUP: keep <b> <path> — recorded parent '<P>' does not exist locally: restore it (git branch <P> <sha> from git reflog or the pull request) and re-run, or, once you are certain its work landed elsewhere, remove the worktree and delete the branch by hand (safe delete refuses unreachable commits; the skill never forces)
#   CLEANUP: keep <b> <path> — parent '<P>' is not checked out in any worktree; the branch is deleted from the parent's worktree, so check <P> out (git worktree add ../<repo>-<P> <P>) and re-run
#   CLEANUP: keep <b> <path> — +<n> unmerged commit(s): run /merge-up inside it first
#   CLEANUP: keep <b> <path> — worktree state unreadable (git status failed there); if the directory is gone, --apply's prune will drop the entry
#   CLEANUP: keep <b> <path> — tree is dirty: commit or stash there first
#   CLEANUP: keep <b> <path> — its upstream <r>/<b> is behind it, so git's safe delete would refuse the branch: push it (git push <r> <b>) or drop the upstream (git branch --unset-upstream <b>), then re-run
#   CLEANUP: keep <b> <path> — a Claude session (<name>) is live there; removing it now would delete that session's working directory. Close that terminal, then re-run --apply
#                                                    (the live-session keep fires under --apply only; it cannot fire while the ADVISORY says detection is unavailable)
#   CLEANUP: remove <b> <path>                       (dry run: would be removed by --apply)
#   CLEANUP: remove <b> <path> live-session=<name>   (dry run: would be removed; a session is live there — the skill sends BYE to it before --apply)
#   CLEANUP: removed <b>                             (--apply: worktree removed, branch deleted with its exosuit* keys)
#   CLEANUP: FAILED <b> — git worktree remove refused: <first non-empty git line>; left in place
#   CLEANUP: FAILED <b> — worktree removed but branch kept: <first non-empty git line>
#   CLEANUP: pruned <n>                              (--apply, always the last line: stale entries dropped by git worktree prune, 0 when none)
# stderr:
#   unknown option: <x>
#   usage: stream-cleanup.sh [--apply]
#   ERROR: not inside a git repository
#   ERROR: worktree-status.sh not found next to this script
#   ERROR: malformed porcelain row from worktree-status.sh (expected 8 TAB-separated fields): <row>
#   ERROR: the worktree-status.sh fact source produced no rows; nothing was examined
#   ADVISORY: session detection unavailable (...)    (and anything else worktree-status.sh writes to stderr)
# Exit codes:
#   0  dry run (keeps are not failures), or --apply with no FAILED line
#   1  --apply with at least one FAILED line
#   2  usage error, not inside a git repository, sibling script missing,
#      malformed porcelain, fact source produced no rows
#
# Under --apply and before git worktree remove, the stream's gitignored
# append-only session state — docs/sessions/.activity-log.jsonl,
# .failure-log.jsonl, .story-outcomes.tsv, .audit-log.jsonl, .refine-log.tsv,
# .optimization-log.tsv — is appended to the main worktree's copy of each:
# git worktree remove fires no WorktreeRemove hook, so the whole directory
# would otherwise go with the worktree. A file that is a symlink on either
# side is skipped rather than followed, and each stream file is emptied once
# its lines have landed, so a refused removal does not append them twice on
# the next run. Git's hint: lines are never printed; a FAILED line quotes
# git's first non-empty line only.
set -uo pipefail

unset CDPATH
HERE="$(cd "$(dirname "$0")" && pwd)"

# --- CLI -------------------------------------------------------------------

print_usage () {
  sed -n '/^# Usage:/,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) print_usage; exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      echo "usage: stream-cleanup.sh [--apply]" >&2
      exit 2
      ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "ERROR: not inside a git repository" >&2; exit 2; }

STATUS="$HERE/worktree-status.sh"
[ -f "$STATUS" ] || { echo "ERROR: worktree-status.sh not found next to this script" >&2; exit 2; }

# --- helpers ---------------------------------------------------------------

# keep <b> <path> <reason>: one keep verdict line.
keep () {
  printf 'CLEANUP: keep %s %s — %s\n' "$1" "$2" "$3"
}

# wt_of <branch>: path of the worktree that has refs/heads/<branch> checked out,
# "-" when none. Parsed line-wise from git worktree list --porcelain (paths may
# carry spaces and #); the match is on the full ref, never on a short name.
wt_of () {
  local want="refs/heads/$1" path="" line="" found="-"
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) path="${line#worktree }" ;;
      "branch "*)
        if [ "${line#branch }" = "$want" ]; then found="$path"; break; fi
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)
  printf '%s\n' "$found"
}

# physical <dir>: pwd -P of a directory, the input unchanged when it cannot be entered.
physical () {
  ( cd "$1" 2>/dev/null && pwd -P ) || printf '%s\n' "$1"
}

# git_line <text>: git's first non-empty line that is not a hint: line, control characters stripped.
git_line () {
  printf '%s\n' "$1" | awk 'NF && $1 != "hint:" { print; exit }' | LC_ALL=C tr -d '\000-\037\177'
}

# wt_count: number of entries git worktree list currently knows.
wt_count () {
  git worktree list --porcelain 2>/dev/null | grep -c '^worktree '
}

# --- ladder ----------------------------------------------------------------

CWD_P="$(pwd -P 2>/dev/null)/"
ROW=0
MAIN_ROOT=""
REPO_NAME=""
ANY_FAILED=0

# Every empty porcelain field is "-", so a TAB IFS bind is positional and safe;
# the raw row is kept for the malformed-row message, and a ninth field (the
# append-only contract) lands in extra instead of dirty.
while IFS= read -r row; do
  [ -n "$row" ] || continue
  # shellcheck disable=SC2034  # behind, story and extra are bound for shape, not read
  IFS=$'\t' read -r path branch parent ahead behind story session dirty extra <<< "$row"
  if [ -z "$dirty" ]; then
    echo "ERROR: malformed porcelain row from worktree-status.sh (expected 8 TAB-separated fields): $row" >&2
    exit 2
  fi
  ROW=$((ROW + 1))

  # The first entry is the main worktree: never a candidate (K17).
  if [ "$ROW" -eq 1 ]; then
    MAIN_ROOT="$path"
    REPO_NAME="$(basename "$path")"
    continue
  fi

  b="$branch"

  # 1. cwd guard — first, and independent of session detection (dry run and --apply).
  ppath="$(physical "$path")"
  case "$CWD_P" in
    "$ppath/"*)
      # A worktree with no recorded parent has no base to name, and "(-)" reads
      # like a flag; say it without the parenthetical in that case.
      if [ "$parent" = "-" ]; then
        keep "$b" "$path" "this is the current worktree; run cleanup from the base instead"
      else
        keep "$b" "$path" "this is the current worktree; run cleanup from the base ($parent) instead"
      fi
      continue
      ;;
  esac

  # 2. not a stream.
  if [ "$parent" = "-" ]; then
    keep "$b" "$path" "no recorded parent (not a stream; not ours to remove)"
    continue
  fi

  # 3. parent ref gone or unmeasurable.
  if [ "$ahead" = "?" ]; then
    keep "$b" "$path" "recorded parent '$parent' does not exist locally: restore it (git branch $parent <sha> from git reflog or the pull request) and re-run, or, once you are certain its work landed elsewhere, remove the worktree and delete the branch by hand (safe delete refuses unreachable commits; the skill never forces)"
    continue
  fi

  # 4. parent exists but is checked out nowhere: the safe delete has no worktree to run in.
  pdir="$(wt_of "$parent")"
  if [ "$pdir" = "-" ]; then
    keep "$b" "$path" "parent '$parent' is not checked out in any worktree; the branch is deleted from the parent's worktree, so check $parent out (git worktree add ../$REPO_NAME-${parent//\//-} $parent) and re-run"
    continue
  fi

  # 5. unmerged work.
  if [ "$ahead" != "0" ]; then
    keep "$b" "$path" "+$ahead unmerged commit(s): run /merge-up inside it first"
    continue
  fi

  # 6. tree state unreadable.
  if [ "$dirty" = "?" ]; then
    keep "$b" "$path" "worktree state unreadable (git status failed there); if the directory is gone, --apply's prune will drop the entry"
    continue
  fi

  # 7. dirty tree (untracked files count).
  if [ "$dirty" != "clean" ]; then
    keep "$b" "$path" "tree is dirty: commit or stash there first"
    continue
  fi

  # 8. upstream keep: git branch -d judges "merged" against the upstream when
  #    one is set and resolves. When it no longer resolves — the ordinary end
  #    of a stream here: pushed with -u, pull request merged, remote branch
  #    deleted, git fetch --prune — git falls back to HEAD and deletes
  #    normally, so there is nothing to keep for. A refusal we did not predict
  #    is reported downstream as CLEANUP: FAILED, never forced.
  merge_ref="$(git config "branch.$b.merge" 2>/dev/null || true)"
  if [ -n "$merge_ref" ]; then
    r="$(git config "branch.$b.remote" 2>/dev/null || true)"
    [ -n "$r" ] || r="-"
    if up="$(git rev-parse -q --verify "$b@{upstream}" 2>/dev/null)" && [ -n "$up" ]; then
      n="$(git rev-list --count "$up..refs/heads/$b" 2>/dev/null || true)"
      if ! [ "$n" -eq 0 ] 2>/dev/null; then
        keep "$b" "$path" "its upstream $r/$b is behind it, so git's safe delete would refuse the branch: push it (git push $r $b) or drop the upstream (git branch --unset-upstream $b), then re-run"
        continue
      fi
    fi
  fi

  # 9. live-session guard (--apply only; no override — the manual valve is git worktree remove by hand).
  if [ "$APPLY" -eq 1 ] && [ "$session" != "-" ]; then
    keep "$b" "$path" "a Claude session ($session) is live there; removing it now would delete that session's working directory. Close that terminal, then re-run --apply"
    continue
  fi

  # 10. dry run: the remove rows (live-session= names the BYE recipient).
  if [ "$APPLY" -eq 0 ]; then
    if [ "$session" = "-" ]; then
      printf 'CLEANUP: remove %s %s\n' "$b" "$path"
    else
      printf 'CLEANUP: remove %s %s live-session=%s\n' "$b" "$path" "$session"
    fi
    continue
  fi

  # 11a. keep the stream's append-only session state: git worktree remove fires
  #      no WorktreeRemove hook, so the whole gitignored docs/sessions/ goes
  #      with the directory. Only append-only files are listed — concatenation
  #      is their merge; the snapshot files there (.auto-save.md,
  #      .failure-state.md) would be nonsense concatenated, so they are not
  #      rescued. A symlink on either side is skipped, never followed: cat
  #      would read some other file into the base log, and when both sides are
  #      the same file it would grow until the disk fills. Each stream file is
  #      emptied only once its lines have actually landed, so a refused removal
  #      (11b) leaves nothing to append twice on the next --apply.
  for f in .activity-log.jsonl .failure-log.jsonl .story-outcomes.tsv \
           .audit-log.jsonl .refine-log.tsv .optimization-log.tsv; do
    src="$path/docs/sessions/$f"
    dst="$MAIN_ROOT/docs/sessions/$f"
    [ -f "$src" ] && [ ! -L "$src" ] || continue
    [ ! -L "$dst" ] || continue
    mkdir -p "$MAIN_ROOT/docs/sessions" 2>/dev/null || true
    if cat "$src" >> "$dst" 2>/dev/null; then
      : > "$src" 2>/dev/null || true
    fi
  done

  # 11b. remove the worktree (never --force).
  if ! out="$(git worktree remove "$path" 2>&1 </dev/null)"; then
    line="$(git_line "$out")"
    [ -n "$line" ] || line="git worktree remove exited without a message"
    printf 'CLEANUP: FAILED %s — git worktree remove refused: %s; left in place\n' "$b" "$line"
    ANY_FAILED=1
    continue
  fi

  # 11c. safe delete of the branch, run in the parent's worktree (never forced, never retried).
  if out="$(git -C "$pdir" branch -d "$b" 2>&1 </dev/null)"; then
    printf 'CLEANUP: removed %s\n' "$b"
  else
    line="$(git_line "$out")"
    [ -n "$line" ] || line="git branch -d exited without a message"
    printf 'CLEANUP: FAILED %s — worktree removed but branch kept: %s\n' "$b" "$line"
    ANY_FAILED=1
  fi
done < <(bash "$STATUS" --porcelain)

# A process substitution's exit status is unreachable, so a dead fact source
# (unreadable sibling, a failed mktemp inside it, a truncated install) would
# otherwise look byte-for-byte like a healthy repository with no streams. The
# main worktree is always a row, even in a bare repository, so zero rows can
# only mean the source never spoke.
if [ "$ROW" -eq 0 ]; then
  echo "ERROR: the worktree-status.sh fact source produced no rows; nothing was examined" >&2
  exit 2
fi

# 12. --apply end: prune stale entries and report the count.
if [ "$APPLY" -eq 1 ]; then
  before="$(wt_count)"
  git worktree prune >/dev/null 2>&1 </dev/null
  after="$(wt_count)"
  pruned=$((before - after))
  [ "$pruned" -ge 0 ] || pruned=0
  printf 'CLEANUP: pruned %s\n' "$pruned"
  [ "$ANY_FAILED" -eq 0 ] || exit 1
fi
exit 0
