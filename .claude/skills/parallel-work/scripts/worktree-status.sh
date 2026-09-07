#!/usr/bin/env bash
# Usage: bash worktree-status.sh [--porcelain | --me | --gate start|merge-up|merge-down|children | -h|--help]
#
# The parallel-work fact source. Every git fact the skills route on is computed
# here and printed as fixed lines; the skills paste them and never re-derive.
# Read-only: nothing here mutates the repository. Exactly one mode per call.
#
# Identity: the branch comes from the full symbolic ref (refs/heads/<b>); a
# detached HEAD reads HEAD. A stream is a branch with branch.<b>.exosuitParent
# recorded by new-worktree.sh; its story is branch.<b>.exosuitStory. Every free
# text read out of config — story, recorded parent, branch.<b>.remote — has its
# control characters stripped and is cut at 200 bytes ("-" when empty). Paths
# are never stripped, because they are handed to git -C: a path holding a
# control character is refused instead (see --me below).
#
# Stdout by mode:
#   (default)   "## Worktree Status", a blank line, then the table
#               | Path | Branch | Parent | Ahead/Behind parent | Story | Session | Tree | Last commit |
#               main worktree row: Parent "-", "(base)", Story "-" (detached or not)
#               stream row: "+A/-B" ("?" when no parent or unmeasurable), story, session,
#               Tree clean|DIRTY|? (untracked files count as dirty), last commit age or "?"
#               detached linked worktree: "(detached <sha7>)" and "-" cells
#               a "|" in a path, branch, story or session name is rendered "\|"
#               then, only when two unmerged streams of one parent committed the same file:
#               "**Overlap (committed on both, not yet merged):**"
#               "- `<a>` and `<b>`: <up to 12 paths>[ +K more]"   (one line per pair, sorted)
#               last line: "+ahead = not merged up yet · -behind = run /merge-down there · Session '-' = no claude session in that directory"
#   --porcelain one line per worktree (git worktree list order), 8 TAB-separated fields:
#               path branch parent ahead behind story session dirty
#               "-" for every empty value; branch HEAD when detached; dirty clean|DIRTY|?;
#               ahead/behind "-" without a recorded parent, "?" when the parent cannot be measured;
#               append-only contract (a future field goes last)
#   --me        13 "key: value" lines in this order:
#               branch dir parent parent_dir ahead behind dirty parent_dirty
#               parent_merge_in_progress remote coordinator peers story
#               dirty and parent_dirty judge TRACKED changes (the gates' predicate): clean|DIRTY|?|-
#               parent_merge_in_progress: yes|no|?|-   remote: <name|->
#               coordinator: live session(s) whose cwd is in parent_dir, ","-joined, or "-"
#               peers: sibling streams' sessions (same parent, other branches), " "-separated, or "-"
#               when this worktree's path or the parent's holds a control character no
#               block is printed at all (a newline in one would forge extra key: lines
#               that outrank the real ones): the ERROR below, exit 2
#   --gate merge-up | --gate merge-down
#               the 13 --me lines, then "GATE <name>: OK" or one "GATE <name>: FAIL — <reason>" line per problem
#   --gate start
#               "branch: <B>", then any "GATE start: FAIL — ..." and "ADVISORY: ..." lines, then "GATE start: OK"
#   --gate children
#               "CHILD <c>: ..." per branch recording this branch as its parent (or "CHILD: none (...)"),
#               "ADVISORY: CHILD ..." lines, then "GATE children: OK" or "GATE children: FAIL — ..."
#
# Verdict and advisory lines (verbatim; <...> are substituted values):
#   GATE merge-up: OK
#   GATE merge-down: OK
#   GATE start: OK
#   GATE children: OK
#   GATE merge-up: FAIL — <reason>  /  GATE merge-down: FAIL — <reason>   reasons (both gates unless marked):
#     worktree path contains a control character; unsupported   (printed alone, with no --me block)
#     HEAD is detached — check out a branch
#     no recorded parent — this is not a stream (set one with: git config branch.<B>.exosuitParent <parent>)
#     recorded parent '<P>' does not exist locally
#     parent equals the current branch
#     current worktree has uncommitted tracked changes — commit or stash first (this merges committed work only)
#     cannot read this worktree's state (git status failed here)
#     merge-up only: parent '<P>' is the default branch — publish through a sprint branch and a pull request (/sprint-end), never by merging into it here
#     merge-up only: parent '<P>' is not checked out in any worktree — the merge needs a working tree to run in
#     merge-up only: parent worktree <PDIR> is dirty — someone is mid-edit there; do not merge under them
#     merge-up only: cannot read the parent worktree's state at <PDIR> (git status failed there)
#     merge-up only: parent worktree <PDIR> has a merge in progress (MERGE_HEAD) — a sibling's /merge-up is unfinished; retry later
#   GATE start: FAIL — HEAD is detached; check out the branch to fan out from
#   GATE start: FAIL — <B> is itself a stream of <P>; fan out from the base (<P>), never from inside a stream
#   ADVISORY: <N> uncommitted change(s) will NOT be in the streams (they fork from HEAD)
#   ADVISORY: cannot count uncommitted changes (git status failed here); streams fork from HEAD regardless
#   ADVISORY: <B> is the default branch — streams off it cannot /merge-up into it; publish through a sprint branch and a pull request
#   CHILD <c>: merged (0 unmerged) worktree=<path|->
#   CHILD <c>: <n> unmerged commit(s) worktree=<path|-> — run /merge-up inside it, or explicitly abandon it
#   CHILD <c>: branch GONE, config residue — run: git config --remove-section branch.<c>
#   ADVISORY: CHILD <c>: worktree <path> is dirty — uncommitted work there is not on <B>
#   ADVISORY: CHILD <c>: worktree <path> state unreadable (git status failed there)
#   CHILD: none (no stream records <B> as its parent)
#   GATE children: FAIL — <k> child stream(s) need attention
#   GATE children: FAIL — HEAD is detached — check out a branch   (printed alone: a detached
#     HEAD has no name for a child to record, so "none" would be a fail-open answer)
#
# Stderr:
#   ADVISORY: session detection unavailable (<reason>) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire
#     <reason> is one of: claude is not on PATH | claude agents --json failed | claude agents --json is not valid JSON | no JSON parser on PATH (install jq)
#     an empty or all-whitespace answer counts as "not valid JSON", never as "no sessions"
#     printed once per run; only the table, --porcelain, --me, --gate merge-up and --gate merge-down look for sessions
#   not a stream: branch <B> has no recorded parent (branch.<B>.exosuitParent)   (--me only, after all 13 lines)
#   unknown option: <x>
#   usage: --gate merge-up|merge-down|children|start
#   ERROR: not inside a git repository
#   ERROR: cannot create a temporary directory   (mktemp -d failed; nothing on stdout)
#   ERROR: worktree path contains a control character; unsupported   (--me only; nothing on stdout)
#
# Exit codes:
#   0  ok (table, --porcelain, --me inside a stream, GATE <name>: OK)
#   1  at least one GATE <name>: FAIL line was printed
#   2  usage: unknown option, bad gate name, not inside a git repository, no temporary directory,
#      --me outside a stream, or --me where a worktree path holds a control character
#
# Degradation is never silent: "?" in any count or tree cell, "-" in any empty
# cell, the stderr ADVISORY above. No "set -e": a failing lookup degrades to
# "-" or "?" and never truncates the output.
set -uo pipefail

# --- Constants -------------------------------------------------------------
US=$'\x1f'          # internal field separator for worktree rows (never "|")
TAB=$'\t'

# --- Help and usage errors -------------------------------------------------
print_help () {
  sed -n '/^# Usage:/,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

die_unknown () {
  echo "unknown option: $1" >&2
  exit 2
}

die_gate_usage () {
  echo "usage: --gate merge-up|merge-down|children|start" >&2
  exit 2
}

# --- Argument parsing: exactly one mode ------------------------------------
MODE=table
GATE=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) print_help; exit 0 ;;
    --porcelain|--me)
      [ "$MODE" = table ] || die_unknown "$1"
      MODE=${1#--} ;;
    --gate)
      [ "$MODE" = table ] || die_unknown "$1"
      case "${2:-}" in
        start|merge-up|merge-down|children) MODE=gate; GATE=$2 ;;
        *) die_gate_usage ;;
      esac
      shift ;;
    *) die_unknown "$1" ;;
  esac
  shift
done

# --- Repository check --------------------------------------------------------
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 2
fi

TMP=$(mktemp -d) || { echo "ERROR: cannot create a temporary directory" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

# --- Identity by full symbolic ref -------------------------------------------
ref=$(git symbolic-ref -q HEAD 2>/dev/null) || ref=""
B=${ref#refs/heads/}
[ -n "$B" ] || B=HEAD

# --- Shared helpers ----------------------------------------------------------
# nz <value>: "-" when empty
nz () { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' "-"; fi; }

# has_ctrl <value>: true when the value holds a C0 control character or DEL.
# The subshell pins LC_ALL so [[:cntrl:]] is the C set in every caller locale.
has_ctrl () (
  export LC_ALL=C
  case "$1" in *[[:cntrl:]]*) return 0 ;; esac
  return 1
)

# blank <value>: true when the value is empty or nothing but whitespace.
blank () (
  export LC_ALL=C
  case "$1" in *[![:space:]]*) return 1 ;; esac
  return 0
)

# parent_of <branch>: recorded parent, "-" when none (HEAD never has one).
# Free text from config, so it is filtered like story_of: a raw value would
# forge extra "key: value" lines in the --me block for a first-match reader.
parent_of () {
  local p
  [ "$1" != HEAD ] || { printf '%s' "-"; return; }
  p=$(git config "branch.$1.exosuitParent" 2>/dev/null | LC_ALL=C tr -d '\000-\037\177' | LC_ALL=C cut -b1-200) || p=""
  nz "$p"
}

# story_of <branch>: sanitised story, "-" when empty. Both filters are pinned
# to LC_ALL=C, so the cut is 200 bytes in every locale.
story_of () {
  local s
  s=$(git config "branch.$1.exosuitStory" 2>/dev/null | LC_ALL=C tr -d '\000-\037\177' | LC_ALL=C cut -b1-200) || s=""
  nz "$s"
}

# counts_of <parent> <branch>: sets C_AHEAD / C_BEHIND
# LEFT of --left-right is the parent's side (behind), RIGHT is the branch's (ahead).
counts_of () {
  local c
  C_AHEAD="?"; C_BEHIND="?"
  if [ "$1" = "-" ]; then C_AHEAD="-"; C_BEHIND="-"; return; fi
  if c=$(git rev-list --left-right --count "refs/heads/$1...refs/heads/$2" 2>/dev/null) && [ -n "$c" ]; then
    read -r C_BEHIND C_AHEAD <<<"$c"
    [ -n "$C_AHEAD" ] || C_AHEAD="?"
    [ -n "$C_BEHIND" ] || C_BEHIND="?"
  fi
}

# dirty_of <dir>: clean|DIRTY|? — untracked files count
dirty_of () {
  local out
  if out=$(git -C "$1" status --porcelain 2>/dev/null); then
    if [ -n "$out" ]; then printf '%s' "DIRTY"; else printf '%s' "clean"; fi
  else
    printf '%s' "?"
  fi
}

# dirty_tracked_of <dir>: clean|DIRTY|? — tracked changes only (the gates' predicate)
dirty_tracked_of () {
  local out
  if out=$(git -C "$1" status --porcelain --untracked-files=no 2>/dev/null); then
    if [ -n "$out" ]; then printf '%s' "DIRTY"; else printf '%s' "clean"; fi
  else
    printf '%s' "?"
  fi
}

# merge_in_progress <dir>: yes|no|? by the MERGE_HEAD file, --git-path anchored
merge_in_progress () {
  local m
  m=$(git -C "$1" rev-parse --git-path MERGE_HEAD 2>/dev/null) || { printf '%s' "?"; return; }
  [ -n "$m" ] || { printf '%s' "?"; return; }
  case "$m" in /*) ;; *) m="$1/$m" ;; esac
  if [ -f "$m" ]; then printf '%s' "yes"; else printf '%s' "no"; fi
}

# age_of <branch>: relative age of the branch tip, "?" on failure
age_of () {
  local a
  a=$(git log -1 --format=%cr "refs/heads/$1" -- 2>/dev/null) || a=""
  nz_q "$a"
}

# age_of_sha <sha>: the same for a detached HEAD
age_of_sha () {
  local a
  a=""
  [ -z "$1" ] || a=$(git log -1 --format=%cr "$1" -- 2>/dev/null) || a=""
  nz_q "$a"
}

# nz_q <value>: "?" when empty
nz_q () { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' "?"; fi; }

# remote_of <branch>: branch.<b>.remote, else origin when listed, else the first
# remote, else "-". Filtered like story_of at the single exit point: both config
# and a remote name are free text that would otherwise forge a "key: value" line.
remote_of () {
  local r remotes
  r=$(git config "branch.$1.remote" 2>/dev/null) || r=""
  if [ -z "$r" ]; then
    remotes=$(git remote 2>/dev/null) || remotes=""
    if printf '%s\n' "$remotes" | grep -qx origin; then
      r=origin
    else
      r=$(printf '%s\n' "$remotes" | head -n 1)
    fi
  fi
  r=$(printf '%s' "$r" | LC_ALL=C tr -d '\000-\037\177' | LC_ALL=C cut -b1-200)
  nz "$r"
}

# default_branch <branch>: the remote's HEAD branch, else main/master when local, else "-"
default_branch () {
  local r d
  r=$(remote_of "$1")
  if [ "$r" != "-" ]; then
    d=$(git symbolic-ref -q "refs/remotes/$r/HEAD" 2>/dev/null) || d=""
    if [ -n "$d" ]; then printf '%s' "${d#"refs/remotes/$r/"}"; return; fi
  fi
  for d in main master; do
    if git show-ref --verify -q "refs/heads/$d" 2>/dev/null; then printf '%s' "$d"; return; fi
  done
  printf '%s' "-"
}

# esc <value>: sets ESC with "|" rendered "\|" (table cells only)
esc () { ESC=${1//|/\\|}; }

# --- Worktree roster: git worktree list --porcelain, parsed line-wise ----------
# One entry = "worktree <path>", "HEAD <sha>" (always present, NOT the detached
# marker), then "branch <ref>" or "detached". Rows are joined with $'\x1f'.
ROWS=()
load_worktrees () {
  local line p h r d
  p=""; h=""; r=""; d=0
  while IFS= read -r line; do
    case "$line" in
      "worktree "*)
        [ -z "$p" ] || ROWS+=("$p$US$h$US$r$US$d")
        p=${line#worktree }; h=""; r=""; d=0 ;;
      "HEAD "*)   h=${line#HEAD } ;;
      "branch "*) r=${line#branch } ;;
      detached)   d=1 ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)
  [ -z "$p" ] || ROWS+=("$p$US$h$US$r$US$d")
}

# split_row <row>: sets R_PATH R_HEAD R_REF R_DET
split_row () { IFS=$US read -r R_PATH R_HEAD R_REF R_DET <<<"$1"; }

# wt_of <branch>: path of the worktree whose branch line is exactly refs/heads/<branch>, else "-"
wt_of () {
  local row
  for row in ${ROWS[@]+"${ROWS[@]}"}; do
    split_row "$row"
    if [ "$R_REF" = "refs/heads/$1" ]; then printf '%s' "$R_PATH"; return; fi
  done
  printf '%s' "-"
}

# --- Per-row facts ---------------------------------------------------------------
# compute_facts full|light — light skips story, tree and age (enough for --me and the gates)
F_PATH=(); F_HEAD=(); F_REF=(); F_BRANCH=(); F_PARENT=(); F_AHEAD=(); F_BEHIND=()
F_STORY=(); F_DIRTY=(); F_AGE=(); F_SESS=()
compute_facts () {
  local i n b
  n=${#ROWS[@]}
  for ((i = 0; i < n; i++)); do
    split_row "${ROWS[$i]}"
    F_PATH[$i]=$R_PATH; F_HEAD[$i]=$R_HEAD; F_REF[$i]=""; F_SESS[$i]="-"
    F_STORY[$i]="-"; F_DIRTY[$i]="-"; F_AGE[$i]="-"
    if [ "$R_DET" = 1 ] || [ -z "$R_REF" ]; then
      F_BRANCH[$i]=HEAD; F_PARENT[$i]="-"; F_AHEAD[$i]="-"; F_BEHIND[$i]="-"
      [ "$1" = light ] || F_AGE[$i]=$(age_of_sha "$R_HEAD")
    else
      b=${R_REF#refs/heads/}
      F_BRANCH[$i]=$b; F_REF[$i]=$R_REF
      F_PARENT[$i]=$(parent_of "$b")
      counts_of "${F_PARENT[$i]}" "$b"
      F_AHEAD[$i]=$C_AHEAD; F_BEHIND[$i]=$C_BEHIND
      if [ "$1" != light ]; then
        F_STORY[$i]=$(story_of "$b")
        F_AGE[$i]=$(age_of "$b")
      fi
    fi
    [ "$1" = light ] || F_DIRTY[$i]=$(dirty_of "$R_PATH")
  done
}

# --- Live-session join (claude agents --json → jq → python3 → "-") ---------------
SESS_WHY=""
# sessions_tsv: prints "cwd<TAB>name" lines; returns 1 with SESS_WHY set
sessions_tsv () {
  local raw
  command -v claude >/dev/null 2>&1 || { SESS_WHY="claude is not on PATH"; return 1; }
  raw="$(claude agents --json 2>/dev/null)" || { SESS_WHY="claude agents --json failed"; return 1; }
  # An empty or all-whitespace answer is not JSON. jq exits 0 on it with no
  # output, which would read as "no sessions anywhere" and silence the advisory;
  # checked here so both parsers reject the same input.
  blank "$raw" && { SESS_WHY="claude agents --json is not valid JSON"; return 1; }
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -r 'if type != "array" then error("not an array") else . end
      | .[] | select((.cwd|type)=="string" and (.name|type)=="string")
      | select((.cwd|contains("\t"))|not) | select((.name|contains("\t"))|not) | "\(.cwd)\t\(.name)"' 2>/dev/null && return 0
    SESS_WHY="claude agents --json is not valid JSON"; return 1
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$raw" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(data, list):
    sys.exit(1)
for s in data:
    if s is None:
        continue
    if not isinstance(s, dict):
        sys.exit(1)
    c = s.get("cwd")
    n = s.get("name")
    if isinstance(c, str) and isinstance(n, str) and "\t" not in c and "\t" not in n:
        sys.stdout.buffer.write((c + "\t" + n + "\n").encode("utf-8"))
' 2>/dev/null && return 0
    SESS_WHY="claude agents --json is not valid JSON"; return 1
  fi
  SESS_WHY="no JSON parser on PATH (install jq)"; return 1
}

# join_sessions: fills F_SESS[i] for every row — a session belongs to the deepest
# worktree root (pwd -P) that equals its cwd or is a "/"-terminated prefix of it;
# "," joins the sessions of one worktree. Roots reach awk through ENVIRON, TAB-joined.
join_sessions () {
  local i n roots r line
  n=${#ROWS[@]}
  if ! sessions_tsv > "$TMP/sessions.raw"; then
    echo "ADVISORY: session detection unavailable ($SESS_WHY) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire" >&2
    return 0
  fi
  LC_ALL=C tr -d '\000-\010\013-\037\177' < "$TMP/sessions.raw" > "$TMP/sessions"
  roots=""
  for ((i = 0; i < n; i++)); do
    r=$(cd "${F_PATH[$i]}" 2>/dev/null && pwd -P) || r=""
    [ -n "$r" ] || r=${F_PATH[$i]}
    if [ "$i" = 0 ]; then roots=$r; else roots="$roots$TAB$r"; fi
  done
  ROOTS="$roots" awk -F '\t' '
    BEGIN {
      n = split(ENVIRON["ROOTS"], R, "\t")
      for (i = 1; i <= n; i++) own[i] = ""
    }
    NF >= 2 && $2 != "" {
      cwd = $1; best = 0; bestlen = -1
      for (i = 1; i <= n; i++) {
        r = R[i]; L = length(r)
        if (r == "") continue
        if (cwd == r || substr(cwd, 1, L + 1) == r "/") {
          if (L > bestlen) { best = i; bestlen = L }
        }
      }
      if (best > 0) own[best] = (own[best] == "" ? $2 : own[best] "," $2)
    }
    END { for (i = 1; i <= n; i++) print (own[i] == "" ? "-" : own[i]) }
  ' "$TMP/sessions" > "$TMP/owned"
  i=0
  while IFS= read -r line; do
    [ "$i" -lt "$n" ] || break
    F_SESS[$i]=$(nz "$line")
    i=$((i + 1))
  done < "$TMP/owned"
}

# --- Committed-overlap block (roster only): unmerged-vs-unmerged pairs of one parent -
print_overlap () {
  local i j n list line a b pa pb common paths k p m
  local -a C_BR C_IDX
  n=${#ROWS[@]}
  list=""
  for ((i = 1; i < n; i++)); do
    [ "${F_PARENT[$i]}" != "-" ] || continue
    [ "${F_AHEAD[$i]}" -gt 0 ] 2>/dev/null || continue
    list="$list${F_BRANCH[$i]}$US$i"$'\n'
  done
  [ -n "$list" ] || return 0
  C_BR=(); C_IDX=()
  while IFS=$US read -r a i; do
    [ -n "$a" ] || continue
    C_BR+=("$a"); C_IDX+=("$i")
    git -c core.quotePath=off diff --name-only \
      "$(git merge-base "refs/heads/${F_PARENT[$i]}" "refs/heads/$a" 2>/dev/null)" "refs/heads/$a" -- 2>/dev/null \
      | LC_ALL=C sort -u > "$TMP/ov.$i" || : > "$TMP/ov.$i"
  done < <(printf '%s' "$list" | LC_ALL=C sort)
  m=${#C_BR[@]}
  : > "$TMP/overlap"
  for ((i = 0; i < m; i++)); do
    for ((j = i + 1; j < m; j++)); do
      a=${C_BR[$i]}; b=${C_BR[$j]}
      pa=${F_PARENT[${C_IDX[$i]}]}; pb=${F_PARENT[${C_IDX[$j]}]}
      [ "$pa" = "$pb" ] || continue
      common=$(LC_ALL=C comm -12 "$TMP/ov.${C_IDX[$i]}" "$TMP/ov.${C_IDX[$j]}" 2>/dev/null) || common=""
      [ -n "$common" ] || continue
      paths=""; k=0
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        k=$((k + 1))
        [ "$k" -gt 12 ] || paths="$paths $p"
      done <<<"$common"
      paths=${paths# }
      [ "$k" -le 12 ] || paths="$paths +$((k - 12)) more"
      printf -- '- `%s` and `%s`: %s\n' "$a" "$b" "$paths" >> "$TMP/overlap"
    done
  done
  [ -s "$TMP/overlap" ] || return 0
  echo "**Overlap (committed on both, not yet merged):**"
  while IFS= read -r line; do printf '%s\n' "$line"; done < "$TMP/overlap"
  echo ""
}

# --- Table mode ------------------------------------------------------------------
print_table () {
  local i n path branch parent story sess ab
  n=${#ROWS[@]}
  echo "## Worktree Status"
  echo ""
  echo "| Path | Branch | Parent | Ahead/Behind parent | Story | Session | Tree | Last commit |"
  echo "|------|--------|--------|---------------------|-------|---------|------|-------------|"
  for ((i = 0; i < n; i++)); do
    esc "${F_PATH[$i]}"; path=$ESC
    esc "${F_SESS[$i]}"; sess=$ESC
    if [ -z "${F_REF[$i]}" ]; then
      branch="(detached ${F_HEAD[$i]:0:7})"
    else
      esc "${F_BRANCH[$i]}"; branch=$ESC
    fi
    if [ "$i" = 0 ]; then
      echo "| $path | $branch | - | (base) | - | $sess | ${F_DIRTY[$i]} | ${F_AGE[$i]} |"
    elif [ -z "${F_REF[$i]}" ]; then
      echo "| $path | $branch | - | - | - | $sess | ${F_DIRTY[$i]} | ${F_AGE[$i]} |"
    else
      esc "${F_PARENT[$i]}"; parent=$ESC
      esc "${F_STORY[$i]}"; story=$ESC
      case "${F_AHEAD[$i]}${F_BEHIND[$i]}" in
        *-*|*\?*) ab="?" ;;
        *) ab="+${F_AHEAD[$i]}/-${F_BEHIND[$i]}" ;;
      esac
      echo "| $path | $branch | $parent | $ab | $story | $sess | ${F_DIRTY[$i]} | ${F_AGE[$i]} |"
    fi
  done
  echo ""
  print_overlap
  echo "+ahead = not merged up yet · -behind = run /merge-down there · Session '-' = no claude session in that directory"
}

# --- Porcelain mode ----------------------------------------------------------------
print_porcelain () {
  local i n
  n=${#ROWS[@]}
  for ((i = 0; i < n; i++)); do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(nz "${F_PATH[$i]}")" "$(nz "${F_BRANCH[$i]}")" "$(nz "${F_PARENT[$i]}")" \
      "$(nz "${F_AHEAD[$i]}")" "$(nz "${F_BEHIND[$i]}")" "$(nz "${F_STORY[$i]}")" \
      "$(nz "${F_SESS[$i]}")" "$(nz "${F_DIRTY[$i]}")"
  done
}

# --- The 13-line --me block (also the head of --gate merge-up / merge-down) ------
ME_P="-"; ME_PDIR="-"; ME_DIR="-"; ME_AHEAD="?"; ME_BEHIND="?"; ME_DIRTY="?"
ME_PDIRTY="-"; ME_PMIP="-"; ME_REMOTE="-"; ME_COORD="-"; ME_PEERS="-"; ME_STORY="-"

# refuse_ctrl_path: no honest block can be printed, so print none at all — in
# the voice of the mode that asked for it. Called only from print_me.
refuse_ctrl_path () {
  if [ "$MODE" = gate ]; then
    echo "GATE $GATE: FAIL — worktree path contains a control character; unsupported"
    exit 1
  fi
  echo "ERROR: worktree path contains a control character; unsupported" >&2
  exit 2
}

print_me () {
  local top i n peers statdir
  top=$(git rev-parse --show-toplevel 2>/dev/null) || top=""
  ME_DIR=""
  [ -z "$top" ] || ME_DIR=$(cd "$top" 2>/dev/null && pwd -P) || ME_DIR=""
  [ -n "$ME_DIR" ] || ME_DIR="-"
  statdir=$ME_DIR; [ "$statdir" != "-" ] || statdir="."
  ME_P=$(parent_of "$B")
  ME_PDIR=$(wt_of "$ME_P")
  # Fail closed before the first line is printed. A newline in either path emits
  # extra "key: value" lines above the real ones, and every reader of this block
  # takes the first match — that forges parent:/parent_dir: and walks a merge
  # into the wrong branch. Do not strip: both values are handed to git -C, and a
  # stripped path names a different directory.
  if has_ctrl "$ME_DIR" || has_ctrl "$ME_PDIR"; then
    refuse_ctrl_path
  fi
  counts_of "$ME_P" "$B"
  ME_AHEAD=$C_AHEAD; ME_BEHIND=$C_BEHIND
  [ "$ME_AHEAD" != "-" ] || ME_AHEAD="?"
  [ "$ME_BEHIND" != "-" ] || ME_BEHIND="?"
  ME_DIRTY=$(dirty_tracked_of "$statdir")
  if [ "$ME_PDIR" != "-" ]; then
    ME_PDIRTY=$(dirty_tracked_of "$ME_PDIR")
    ME_PMIP=$(merge_in_progress "$ME_PDIR")
  else
    ME_PDIRTY="-"; ME_PMIP="-"
  fi
  ME_REMOTE=$(remote_of "$ME_P")
  ME_COORD="-"; peers=""
  n=${#ROWS[@]}
  for ((i = 0; i < n; i++)); do
    [ -n "${F_REF[$i]}" ] || continue
    if [ "$ME_P" != "-" ] && [ "${F_REF[$i]}" = "refs/heads/$ME_P" ]; then
      ME_COORD=${F_SESS[$i]}
    elif [ "$ME_P" != "-" ] && [ "${F_BRANCH[$i]}" != "$B" ] && [ "${F_PARENT[$i]}" = "$ME_P" ] && [ "${F_SESS[$i]}" != "-" ]; then
      peers="$peers ${F_SESS[$i]}"
    fi
  done
  peers=${peers# }
  ME_PEERS=$(nz "$peers")
  ME_STORY=$(story_of "$B")
  echo "branch: $B"
  echo "dir: $ME_DIR"
  echo "parent: $ME_P"
  echo "parent_dir: $ME_PDIR"
  echo "ahead: $ME_AHEAD"
  echo "behind: $ME_BEHIND"
  echo "dirty: $ME_DIRTY"
  echo "parent_dirty: $ME_PDIRTY"
  echo "parent_merge_in_progress: $ME_PMIP"
  echo "remote: $ME_REMOTE"
  echo "coordinator: $ME_COORD"
  echo "peers: $ME_PEERS"
  echo "story: $ME_STORY"
}

# --- Gates ---------------------------------------------------------------------
FAILS=0
fail () {
  echo "GATE $GATE: FAIL — $1"
  FAILS=$((FAILS + 1))
}

gate_merge () {
  local parent_exists
  print_me
  parent_exists=0
  if [ "$B" = HEAD ]; then
    fail "HEAD is detached — check out a branch"
  elif [ "$ME_P" = "-" ]; then
    fail "no recorded parent — this is not a stream (set one with: git config branch.$B.exosuitParent <parent>)"
  else
    if git show-ref --verify -q "refs/heads/$ME_P" 2>/dev/null; then
      parent_exists=1
    else
      fail "recorded parent '$ME_P' does not exist locally"
    fi
    [ "$ME_P" != "$B" ] || fail "parent equals the current branch"
  fi
  case "$ME_DIRTY" in
    DIRTY) fail "current worktree has uncommitted tracked changes — commit or stash first (this merges committed work only)" ;;
    '?')   fail "cannot read this worktree's state (git status failed here)" ;;
  esac
  if [ "$GATE" = merge-up ] && [ "$parent_exists" = 1 ]; then
    [ "$(default_branch "$ME_P")" != "$ME_P" ] || \
      fail "parent '$ME_P' is the default branch — publish through a sprint branch and a pull request (/sprint-end), never by merging into it here"
    if [ "$ME_PDIR" = "-" ]; then
      fail "parent '$ME_P' is not checked out in any worktree — the merge needs a working tree to run in"
    else
      case "$ME_PDIRTY" in
        DIRTY) fail "parent worktree $ME_PDIR is dirty — someone is mid-edit there; do not merge under them" ;;
        '?')   fail "cannot read the parent worktree's state at $ME_PDIR (git status failed there)" ;;
      esac
      [ "$ME_PMIP" != yes ] || \
        fail "parent worktree $ME_PDIR has a merge in progress (MERGE_HEAD) — a sibling's /merge-up is unfinished; retry later"
    fi
  fi
  if [ "$FAILS" = 0 ]; then echo "GATE $GATE: OK"; exit 0; fi
  exit 1
}

gate_start () {
  local p st n
  echo "branch: $B"
  if [ "$B" = HEAD ]; then
    fail "HEAD is detached; check out the branch to fan out from"
  else
    p=$(parent_of "$B")
    [ "$p" = "-" ] || fail "$B is itself a stream of $p; fan out from the base ($p), never from inside a stream"
  fi
  if st=$(git status --porcelain 2>/dev/null); then
    n=$(printf '%s\n' "$st" | grep -c .) || n=0
    [ "$n" -eq 0 ] || echo "ADVISORY: $n uncommitted change(s) will NOT be in the streams (they fork from HEAD)"
  else
    echo "ADVISORY: cannot count uncommitted changes (git status failed here); streams fork from HEAD regardless"
  fi
  if [ "$B" != HEAD ] && [ "$(default_branch "$B")" = "$B" ]; then
    echo "ADVISORY: $B is the default branch — streams off it cannot /merge-up into it; publish through a sprint branch and a pull request"
  fi
  if [ "$FAILS" = 0 ]; then echo "GATE start: OK"; exit 0; fi
  exit 1
}

gate_children () {
  local list key val c path n k any d
  # A detached HEAD has no branch name for a child to record, so the roster
  # below would find none and answer "no streams" — a fail-open the other three
  # gates do not have. Refuse it the way they do.
  if [ "$B" = HEAD ]; then
    fail "HEAD is detached — check out a branch"
    exit 1
  fi
  list=$(git config --get-regexp '^branch\..*\.exosuitparent$' 2>/dev/null) || list=""
  k=0; any=0
  while read -r key val; do
    [ -n "$key" ] || continue
    [ "$val" = "$B" ] || continue
    c=${key%.exosuitparent}; c=${c#branch.}
    any=1
    if ! git show-ref --verify -q "refs/heads/$c" 2>/dev/null; then
      echo "CHILD $c: branch GONE, config residue — run: git config --remove-section branch.$c"
      k=$((k + 1))
      continue
    fi
    path=$(wt_of "$c")
    n=$(git rev-list --count "HEAD..refs/heads/$c" 2>/dev/null) || n="?"
    [ -n "$n" ] || n="?"
    if [ "$n" = 0 ]; then
      echo "CHILD $c: merged (0 unmerged) worktree=$path"
    else
      echo "CHILD $c: $n unmerged commit(s) worktree=$path — run /merge-up inside it, or explicitly abandon it"
      k=$((k + 1))
    fi
    if [ "$path" != "-" ]; then
      d=$(dirty_of "$path")
      case "$d" in
        DIRTY) echo "ADVISORY: CHILD $c: worktree $path is dirty — uncommitted work there is not on $B" ;;
        '?')   echo "ADVISORY: CHILD $c: worktree $path state unreadable (git status failed there)" ;;
      esac
    fi
  done <<<"$list"
  [ "$any" = 1 ] || echo "CHILD: none (no stream records $B as its parent)"
  if [ "$k" = 0 ]; then echo "GATE children: OK"; exit 0; fi
  echo "GATE children: FAIL — $k child stream(s) need attention"
  exit 1
}

# --- Dispatch --------------------------------------------------------------------
case "$MODE" in
  table)
    load_worktrees; compute_facts full; join_sessions; print_table; exit 0 ;;
  porcelain)
    load_worktrees; compute_facts full; join_sessions; print_porcelain; exit 0 ;;
  me)
    load_worktrees; compute_facts light; join_sessions; print_me
    if [ "$ME_P" = "-" ]; then
      echo "not a stream: branch $B has no recorded parent (branch.$B.exosuitParent)" >&2
      exit 2
    fi
    exit 0 ;;
  gate)
    case "$GATE" in
      start)    gate_start ;;
      children) load_worktrees; gate_children ;;
      *)        load_worktrees; compute_facts light; join_sessions; gate_merge ;;
    esac ;;
esac
