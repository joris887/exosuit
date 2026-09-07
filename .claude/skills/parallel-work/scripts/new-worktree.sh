#!/usr/bin/env bash
# Usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>] [--story <id>] [--no-parent] [-h|--help]
#
# Creates a sibling git worktree on a NEW branch and records where it came
# from, so /merge-up, /merge-down, the roster and cleanup know its parent.
#
#   <new-branch>     name of the branch to create (must not exist yet)
#   <base-ref>       LOCAL branch to fork from        (default: the checked-out branch)
#                    a sha, a tag or origin/x is refused as "does not exist locally"
#   <worktree-dir>   destination                      (default: ../<repo>-<branch, / written as ->)
#   --story <id>     record one story id in branch.<new-branch>.exosuitStory
#                    (dropped under --no-parent)
#   --no-parent      record nothing: a standalone worktree, not a stream
#                    (also skips the nested-stream refusal)
#   -h, --help       print this block and exit 0
#
# Options are separate words only (--story=x is an unknown option).
#
# Copies into the new worktree, never overwriting an existing file: .env,
# .env.local, .claude/settings.local.json, CLAUDE.local.md, then every
# colon-separated repo-relative path in EXOSUIT_WORKTREE_COPY. A destination
# that is itself a symlink is left alone (a dangling one would be written
# through), and after the parent directory is made its physical path must
# still be inside the worktree or the copy is skipped: a committed symlink on
# the base branch never redirects a copy out of the new worktree.
# .mcp.json: tracked on the new branch -> left alone; untracked and gitignored
# in the main worktree -> copied with the main worktree's absolute root path
# rewritten to the new worktree (physical and logical spellings, one awk
# pass, a match counts only when the next character is / " ' whitespace or
# the end of the line, so <root>-data/x is left alone); untracked and not
# ignored -> skipped with an advisory. Dependency directories are never copied.
#
# Records (git config, shared by every worktree of the repository):
#   branch.<new-branch>.exosuitParent = <base-ref>   (unless --no-parent)
#   branch.<new-branch>.exosuitStory  = <id>         (with --story, and a parent)
#
# stdout, in order:
#   >> git worktree add -b <b> <dir> <base>
#      recorded parent: branch.<b>.exosuitParent = <base>
#      no parent recorded (--no-parent): a standalone worktree, not a stream
#      recorded story: branch.<b>.exosuitStory = <id>
#      copied  <rel>
#      skip    <rel> (destination leaves the worktree via a symlink)
#      skip    .mcp.json (tracked on <b> — left as-is)
#      skip    .mcp.json (untracked and not gitignored in the main worktree — add it to .gitignore so streams get a rewritten copy, or copy it by hand)
#      wrote   .mcp.json (absolute paths rewritten to worktree)
#
#   Worktree ready: <dir>
#     branch <b> (off <base>)
#     note: dependency directories (node_modules, .venv, vendor, target) are
#           not copied — install them per worktree if the project needs them.
#
# stderr, exit 2 (usage; nothing touched):
#   usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>] [--story <id>] [--no-parent]
#   ERROR: unknown option <x>
#   ERROR: --story needs a value
#   ERROR: --story must not contain control characters
#   ERROR: <worktree-dir> must not contain control characters
#   ERROR: not inside a git repository
#
# stderr, exit 1 (refusals, checked in this order, before any mutation):
#   ERROR: HEAD is detached — check out a branch first, or pass an explicit <base-ref>
#   ERROR: base branch '<x>' does not exist locally
#   ERROR: <base> is itself a stream of <P> — fan out from <P>, never from inside a stream
#   ERROR: '<x>' is not a valid branch name
#   ERROR: <dir> already exists
#   ERROR: branch <b> already exists
#
# exit 0 on success. git's own failure after the checks propagates (128) with
# no rollback: remove a half-built worktree with git worktree remove <dir>,
# then git branch -d <b>. git's own progress lines go to stderr.
set -euo pipefail

# --- Helpers ---------------------------------------------------------------

print_usage () {
  sed -n '/^# Usage:/,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

usage_error () {
  echo "usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>] [--story <id>] [--no-parent]" >&2
  exit 2
}

# true when the argument holds a C0 control character or DEL
has_control_chars () (
  export LC_ALL=C
  case "$1" in *[[:cntrl:]]*) return 0 ;; esac
  return 1
)

# copy <rel> from the main worktree into the new one; never overwrites, and
# never writes outside the worktree. -e follows symlinks, so a committed
# dangling link at the destination reads as absent and cp would write through
# it; -L catches that leaf. A committed symlink on a parent directory is not a
# leaf at all -- mkdir -p resolves through it -- so the directory that will
# hold the file is compared physically against the worktree after it is made.
copy_if_present () {
  local rel="$1" dest="$WORKTREE_DIR/$1"
  local destdir wt_phys dd_phys
  [ -e "$MAIN_ROOT/$rel" ] || return 0
  if [ -e "$dest" ] || [ -L "$dest" ]; then return 0; fi
  destdir="$(dirname "$dest")"
  mkdir -p "$destdir"
  wt_phys="$(cd "$WORKTREE_DIR" && pwd -P)" || return 0
  dd_phys="$(cd "$destdir" && pwd -P)" || return 0
  case "$dd_phys/" in
    "$wt_phys"/*) ;;
    *)
      echo "   skip    $rel (destination leaves the worktree via a symlink)"
      return 0
      ;;
  esac
  cp -R "$MAIN_ROOT/$rel" "$dest"
  echo "   copied  $rel"
}

# --- Arguments -------------------------------------------------------------

NEW_BRANCH=""
BASE_ARG=""
DIR_ARG=""
STORY=""
NO_PARENT=0
npos=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --story)
      if [ $# -lt 2 ] || [ -z "${2-}" ]; then
        echo "ERROR: --story needs a value" >&2
        exit 2
      fi
      STORY="$2"
      shift 2
      continue
      ;;
    --no-parent)
      NO_PARENT=1
      ;;
    --*)
      echo "ERROR: unknown option $1" >&2
      exit 2
      ;;
    *)
      npos=$((npos + 1))
      case $npos in
        1) NEW_BRANCH="$1" ;;
        2) BASE_ARG="$1" ;;
        3) DIR_ARG="$1" ;;
        *) usage_error ;;
      esac
      ;;
  esac
  shift
done

[ -n "$NEW_BRANCH" ] || usage_error

if [ -n "$STORY" ] && has_control_chars "$STORY"; then
  echo "ERROR: --story must not contain control characters" >&2
  exit 2
fi

# Checked on the argument, before it is absolutised: a newline in a worktree
# path forges extra "key: value" lines in the --me block every other script
# reads, and the path is handed to git -C, so it cannot be stripped either.
if [ -n "$DIR_ARG" ] && has_control_chars "$DIR_ARG"; then
  echo "ERROR: <worktree-dir> must not contain control characters" >&2
  exit 2
fi

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "ERROR: not inside a git repository" >&2
  exit 2
}

# --- Identity: the base branch by full symbolic ref (a tag named like the
#     branch never confuses it; --abbrev-ref would print heads/<b>) ----------

if [ -n "$BASE_ARG" ]; then
  BASE_REF="$BASE_ARG"
else
  ref="$(git symbolic-ref -q HEAD 2>/dev/null)" || ref=""
  BASE_REF="${ref#refs/heads/}"
  if [ -z "$BASE_REF" ]; then
    echo "ERROR: HEAD is detached — check out a branch first, or pass an explicit <base-ref>" >&2
    exit 1
  fi
fi

# --- Main worktree = first entry of the porcelain list (parsed line-wise:
#     paths may contain spaces and #) --------------------------------------

MAIN_ROOT=""
WT_LIST="$(git worktree list --porcelain 2>/dev/null)" || WT_LIST=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      MAIN_ROOT="${line#worktree }"
      break
      ;;
  esac
done <<< "$WT_LIST"
if [ -z "$MAIN_ROOT" ]; then
  MAIN_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || MAIN_ROOT=""
fi
if [ -z "$MAIN_ROOT" ]; then
  echo "ERROR: not inside a git repository" >&2
  exit 2
fi
REPO_NAME="$(basename "$MAIN_ROOT")"
PARENT_DIR="$(dirname "$MAIN_ROOT")"

SAFE_BRANCH="${NEW_BRANCH//\//-}"
WORKTREE_DIR="${DIR_ARG:-$PARENT_DIR/$REPO_NAME-$SAFE_BRANCH}"
case "$WORKTREE_DIR" in
  /*) ;;
  *) WORKTREE_DIR="${PWD:-$(pwd)}/$WORKTREE_DIR" ;;
esac

# --- Refusals, in contract order, before any mutation ---------------------

if ! git show-ref --verify --quiet -- "refs/heads/$BASE_REF" 2>/dev/null; then
  echo "ERROR: base branch '$BASE_REF' does not exist locally" >&2
  exit 1
fi

if [ "$NO_PARENT" -eq 0 ]; then
  BASE_PARENT="$(git config "branch.$BASE_REF.exosuitParent" 2>/dev/null | LC_ALL=C tr -d '\000-\037\177')" || BASE_PARENT=""
  if [ -n "$BASE_PARENT" ]; then
    echo "ERROR: $BASE_REF is itself a stream of $BASE_PARENT — fan out from $BASE_PARENT, never from inside a stream" >&2
    exit 1
  fi
fi

if ! git check-ref-format --branch "$NEW_BRANCH" >/dev/null 2>&1; then
  echo "ERROR: '$NEW_BRANCH' is not a valid branch name" >&2
  exit 1
fi

if [ -e "$WORKTREE_DIR" ] || [ -L "$WORKTREE_DIR" ]; then
  echo "ERROR: $WORKTREE_DIR already exists" >&2
  exit 1
fi

if git show-ref --verify --quiet -- "refs/heads/$NEW_BRANCH" 2>/dev/null; then
  echo "ERROR: branch $NEW_BRANCH already exists" >&2
  exit 1
fi

# --- Create ----------------------------------------------------------------

echo ">> git worktree add -b $NEW_BRANCH $WORKTREE_DIR $BASE_REF"
# The full ref is what runs: a tag named like the base would otherwise win
# the name lookup. git's progress lines stay on stderr so stdout is ours.
git worktree add -b "$NEW_BRANCH" "$WORKTREE_DIR" "refs/heads/$BASE_REF" 1>&2

# --- Records ---------------------------------------------------------------

if [ "$NO_PARENT" -eq 1 ]; then
  echo "   no parent recorded (--no-parent): a standalone worktree, not a stream"
else
  git config "branch.$NEW_BRANCH.exosuitParent" "$BASE_REF"
  echo "   recorded parent: branch.$NEW_BRANCH.exosuitParent = $BASE_REF"
  if [ -n "$STORY" ]; then
    git config "branch.$NEW_BRANCH.exosuitStory" "$STORY"
    echo "   recorded story: branch.$NEW_BRANCH.exosuitStory = $STORY"
  fi
fi

# --- Local files: gitignored settings, then project extras -----------------

copy_if_present ".env"
copy_if_present ".env.local"
copy_if_present ".claude/settings.local.json"
copy_if_present "CLAUDE.local.md"

if [ -n "${EXOSUIT_WORKTREE_COPY:-}" ]; then
  EXTRAS=()
  IFS=':' read -r -a EXTRAS <<< "$EXOSUIT_WORKTREE_COPY"
  for rel in ${EXTRAS[@]+"${EXTRAS[@]}"}; do
    if [ -n "$rel" ]; then
      copy_if_present "$rel"
    fi
  done
fi

# --- .mcp.json: tracked -> skip; ignored -> copy with roots rewritten;
#     untracked and not ignored -> skip advisory ----------------------------

if git -C "$WORKTREE_DIR" ls-files --error-unmatch -- .mcp.json >/dev/null 2>&1; then
  echo "   skip    .mcp.json (tracked on $NEW_BRANCH — left as-is)"
elif [ -f "$MAIN_ROOT/.mcp.json" ]; then
  if git -C "$MAIN_ROOT" check-ignore -q -- .mcp.json 2>/dev/null; then
    if [ ! -e "$WORKTREE_DIR/.mcp.json" ]; then
      # Two spellings of the main root are rewritten: the physical path
      # (pwd -P) and the logical path, derived from the caller's $PWD when it
      # reaches the same directory (same inode) through a symlink.
      PHYS_ROOT="$(cd "$MAIN_ROOT" && pwd -P)" || PHYS_ROOT=""
      LOGICAL_ROOT=""
      if [ -n "$PHYS_ROOT" ] && [ -n "${PWD:-}" ]; then
        PWD_PHYS="$(pwd -P)" || PWD_PHYS=""
        case "$PWD_PHYS/" in
          "$PHYS_ROOT/"*)
            rel="${PWD_PHYS#"$PHYS_ROOT"}"
            cand="${PWD%"$rel"}"
            if [ -n "$cand" ] && [ "$cand" != "$PHYS_ROOT" ] && [ "$cand" -ef "$PHYS_ROOT" ]; then
              LOGICAL_ROOT="$cand"
            fi
            ;;
        esac
      fi
      # One pass, left to right: at each position the longest spelling that
      # matches AND is followed by / " ' whitespace or end of line is
      # replaced; everything else is copied byte for byte. Values travel
      # through ENVIRON so awk never unescapes them.
      FROM1="$PHYS_ROOT" FROM2="$LOGICAL_ROOT" TO="$WORKTREE_DIR" LC_ALL=C awk '
        BEGIN {
          n = 0
          if (ENVIRON["FROM1"] != "") from[++n] = ENVIRON["FROM1"]
          if (ENVIRON["FROM2"] != "") from[++n] = ENVIRON["FROM2"]
          for (a = 1; a <= n; a++)
            for (b = a + 1; b <= n; b++)
              if (length(from[b]) > length(from[a])) { t = from[a]; from[a] = from[b]; from[b] = t }
          to = ENVIRON["TO"]
        }
        {
          line = $0; out = ""; i = 1; len = length(line)
          while (i <= len) {
            hit = 0
            for (k = 1; k <= n; k++) {
              fl = length(from[k])
              if (substr(line, i, fl) == from[k]) {
                c = substr(line, i + fl, 1)
                if (c == "" || c == "/" || c == "\"" || c == "\047" || c == " " || c == "\t" || c == "\r") {
                  out = out to; i += fl; hit = 1; break
                }
              }
            }
            if (!hit) { out = out substr(line, i, 1); i++ }
          }
          print out
        }' "$MAIN_ROOT/.mcp.json" > "$WORKTREE_DIR/.mcp.json"
      echo "   wrote   .mcp.json (absolute paths rewritten to worktree)"
    fi
  else
    echo "   skip    .mcp.json (untracked and not gitignored in the main worktree — add it to .gitignore so streams get a rewritten copy, or copy it by hand)"
  fi
fi

# --- Report ----------------------------------------------------------------

echo
echo "Worktree ready: $WORKTREE_DIR"
echo "  branch $NEW_BRANCH (off $BASE_REF)"
echo "  note: dependency directories (node_modules, .venv, vendor, target) are"
echo "        not copied — install them per worktree if the project needs them."
