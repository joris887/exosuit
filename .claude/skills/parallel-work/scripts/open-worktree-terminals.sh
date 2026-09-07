#!/usr/bin/env bash
# Usage: open-worktree-terminals.sh <dir> [<dir> ...]
#        open-worktree-terminals.sh -h | --help
#
# Opens one terminal per worktree directory and starts a named Claude Code
# session there whose first prompt greets the coordinator. Companion to
# new-worktree.sh; the parallel-work skill passes every stream directory in
# ONE call. "opened" means the terminal accepted the request — the HELLO that
# follows (or the Session column of worktree-status.sh) is the evidence that
# claude started; this script never polls.
#
# Per-directory command, computed exactly once per directory:
#   cd '<dir>' && [CLAUDE_CONFIG_DIR='<v>' ]<base>[ --name '<branch>'][ -- '<prompt>']
#   default:  cd '<dir>' && claude --name '<branch>' -- '/parallel-work hello'
#   <branch> is the directory's checked-out branch (full symbolic ref). --name
#   is added only when the branch matches the allowlist [A-Za-z0-9._/-] under
#   LC_ALL=C; otherwise the session launches unnamed and a note says so.
#   -- ends option parsing so a base command ending in a list option
#   (--allowedTools, --disallowedTools, --add-dir) cannot swallow the prompt
#   when the session is launched unnamed (EXOSUIT_WORKTREE_NAME_SESSIONS=0, or
#   a branch outside the session-name allowlist); reproduced 2026-09-06. A
#   non-claude base command that rejects -- should set
#   EXOSUIT_WORKTREE_FIRST_PROMPT= and start the greeting by hand.
#
# Environment knobs:
#   EXOSUIT_WORKTREE_LAUNCH_CMD     base command (default: claude); --name and
#                                   the prompt are appended to it
#   EXOSUIT_WORKTREE_FIRST_PROMPT   first prompt (default: /parallel-work hello);
#                                   set but empty = no prompt and no --
#   EXOSUIT_WORKTREE_NAME_SESSIONS  0 = no --name (default: 1)
#   EXOSUIT_WORKTREE_TABS           0 = print the commands only, exit 0 (default: 1);
#                                   set but empty counts as 0, so a knob emptied
#                                   by mistake never opens a window
#   EXOSUIT_WORKTREE_OSASCRIPT      the AppleScript runner (default: the system
#                                   osascript; tests stub it)
#   EXOSUIT_WORKTREE_PROC_VERSION   test-only: the file whose contents decide
#                                   WSL detection (default: /proc/version)
#   CLAUDE_CONFIG_DIR               passed through: when set, every command is
#                                   prefixed CLAUDE_CONFIG_DIR='<v>' so the
#                                   streams share this session's registry
#
# Terminal arms (chosen once per run):
#   macOS + iTerm2        create tab with default profile + write text (unverified)
#   macOS + anything else Terminal.app: ONE untargeted `do script` per directory
#                         (no activate, no keystroke, no System Events, no
#                         front window, no delay, no polling)
#   WSL + wt.exe          wt.exe -w 0 nt wsl.exe --cd <dir> -- bash -lc "<cmd>\; exec bash"
#                         (falls back to `wt.exe nt ...`; unverified)
#   Git Bash / MSYS       wt.exe -w 0 nt -d <cygpath -w dir> <cygpath -w bash> -lc "..."
#                         (unverified)
#   Linux                 gnome-terminal --tab / konsole --new-tab
#   anything else         no opener: the commands are printed, exit 1
#
# stdout:
#   Opened <n> of <N> terminal(s):
#     opened  <dir>  ->  <cmd>
#   Couldn't open <k> of <N> terminal(s) on this terminal (<uname>).
#   Couldn't auto-open terminals on this terminal (<uname> / <TERM_PROGRAM|unknown>).
#   Open a terminal per worktree and run:
#     <cmd>
# stderr:
#   usage: open-worktree-terminals.sh <dir> [<dir> ...]
#   note: branch '<b>' has characters unsafe for a session name — session left unnamed
#   note: <dir> has no checked-out branch (detached HEAD or not a git worktree) — session left unnamed
#   note: <dir> is not a directory — nothing started
#   note: the launch command bypasses permissions; unless THIS session bypasses too, every HELLO/MERGED
#         from the streams is held here for approval (and BYE is held there) — same class on both sides, or expect one dialog per message
#   note: Terminal.app did not open a window for <dir> — nothing started (<reason>)
#   note: macOS 'Prefer tabs when opening documents' is set to Always, so the
#         streams opened as TABS of the frontmost Terminal window, not as windows.
#   note: the stream windows opened in Terminal.app behind your current app (<TERM_PROGRAM|unknown terminal>) — the launcher does not steal focus.
#
# Exit codes:
#   0  every directory opened, or EXOSUIT_WORKTREE_TABS=0
#   1  any directory failed to open, or no opener exists on this platform
#   2  usage (no directory given)
set -uo pipefail

# --- Help and usage -----------------------------------------------------------

case "${1:-}" in
  -h|--help)
    sed -n '/^# Usage:/,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

if [ "$#" -lt 1 ]; then
  echo "usage: open-worktree-terminals.sh <dir> [<dir> ...]" >&2
  exit 2
fi

# --- Knobs --------------------------------------------------------------------

BASE_CMD="${EXOSUIT_WORKTREE_LAUNCH_CMD:-claude}"
FIRST_PROMPT="${EXOSUIT_WORKTREE_FIRST_PROMPT-/parallel-work hello}"
NAME_SESSIONS="${EXOSUIT_WORKTREE_NAME_SESSIONS:-1}"
# Bare dash, not ':-': an explicitly emptied knob means the caller wanted
# terminals off, and the failure mode of guessing otherwise is windows opening
# on someone's desk. Unset still means 1.
TABS="${EXOSUIT_WORKTREE_TABS-1}"
[ -n "$TABS" ] || TABS=0
OSASCRIPT="${EXOSUIT_WORKTREE_OSASCRIPT:-/usr/bin/osascript}"
PROC_VERSION="${EXOSUIT_WORKTREE_PROC_VERSION:-/proc/version}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}"
TERM_PROG="${TERM_PROGRAM:-}"

# --- Quoting helpers ----------------------------------------------------------

# q: single-quote for a POSIX shell (' becomes '\'').
q () {
  local s=$1 sq="'" bs='\'
  s=${s//$sq/$sq$bs$sq$sq}
  printf '%s%s%s' "$sq" "$s" "$sq"
}

# as_quote: escape for an AppleScript string literal (\ and " get a backslash).
as_quote () {
  printf '%s' "$1" | LC_ALL=C sed 's/[\\"]/\\&/g'
}

# wt_escape: Windows Terminal reads ; as a command separator — escape it as \;.
wt_escape () {
  local s=$1 bs='\'
  printf '%s' "${s//;/$bs;}"
}

# sanitise_reason: one line, CSI sequences and C0/C1 bytes removed, trimmed.
sanitise_reason () {
  local r
  r=$(printf '%s' "$1" \
    | LC_ALL=C awk '{ gsub(/\033\[[0-9;?]*[@-~]/, ""); print }' \
    | LC_ALL=C tr '\n\r\t' '   ' \
    | LC_ALL=C tr -d '\000-\037\177-\237' \
    | LC_ALL=C tr -s ' ')
  r=${r# }
  r=${r% }
  printf '%s' "$r"
}

# name_safe: 0 when the branch fits the session-name allowlist (C locale).
name_safe () {
  (
    export LC_ALL=C
    case "$1" in
      *[!A-Za-z0-9._/-]*) exit 1 ;;
    esac
    exit 0
  )
}

# --- Per-directory command (computed once) -------------------------------------

command_for () {
  local dir=$1 ref branch cmd
  cmd="cd $(q "$dir") && "
  [ -n "$CONFIG_DIR" ] && cmd="${cmd}CLAUDE_CONFIG_DIR=$(q "$CONFIG_DIR") "
  cmd="${cmd}${BASE_CMD}"
  if [ "$NAME_SESSIONS" != "0" ] && [ -d "$dir" ]; then
    ref=$(git -C "$dir" symbolic-ref -q HEAD 2>/dev/null) || ref=""
    branch=${ref#refs/heads/}
    if [ -z "$branch" ]; then
      echo "note: $dir has no checked-out branch (detached HEAD or not a git worktree) — session left unnamed" >&2
    elif name_safe "$branch"; then
      cmd="${cmd} --name $(q "$branch")"
    else
      echo "note: branch '$branch' has characters unsafe for a session name — session left unnamed" >&2
    fi
  fi
  [ -n "$FIRST_PROMPT" ] && cmd="${cmd} -- $(q "$FIRST_PROMPT")"
  printf '%s' "$cmd"
}

DIRS=()
CMDS=()
ALL=()
for dir in "$@"; do
  case "$dir" in
    /*) ;;
    *) dir="$PWD/$dir" ;;
  esac
  ALL+=("${#DIRS[@]}")
  DIRS+=("$dir")
  CMDS+=("$(command_for "$dir")")
done
TOTAL=${#DIRS[@]}

# --- Permission-class note (once per run, before any opener) --------------------

bypass=0
(
  export LC_ALL=C
  case "$BASE_CMD" in
    *--dangerously-skip-permissions*|*--permission-mode?bypassPermissions*) exit 0 ;;
  esac
  exit 1
) && bypass=1
if [ "$bypass" = "1" ]; then
  echo "note: the launch command bypasses permissions; unless THIS session bypasses too, every HELLO/MERGED" >&2
  echo "      from the streams is held here for approval (and BYE is held there) — same class on both sides, or expect one dialog per message" >&2
fi

# --- Manual mode --------------------------------------------------------------

print_hints () {
  # Arguments: indexes into CMDS.
  local i
  echo "Open a terminal per worktree and run:"
  for i in "$@"; do
    printf '  %s\n' "${CMDS[$i]}"
  done
}

if [ "$TABS" = "0" ]; then
  print_hints ${ALL[@]+"${ALL[@]}"}
  exit 0
fi

# --- Openers (one directory each; non-zero = the terminal refused) --------------

uname_s="$(uname -s 2>/dev/null || echo unknown)"

open_iterm () {
  local dir=$1 cmd=$2 text script
  text=$(as_quote "$cmd")
  script="tell application \"iTerm\"
  activate
  if (count of windows) = 0 then
    set w to (create window with default profile)
    tell current session of w to write text \"$text\"
  else
    tell current window
      create tab with default profile
      tell current session to write text \"$text\"
    end tell
  end if
end tell"
  printf '%s\n' "$script" | "$OSASCRIPT" >/dev/null 2>&1
}

open_apple_terminal () {
  # One untargeted `do script` per directory: Terminal.app opens a window (or a
  # tab, when the system Prefer-tabs setting says Always), runs the command in
  # it, and returns at once. Nothing is activated, typed or polled.
  local dir=$1 cmd=$2 script err rc reason
  script="tell application \"Terminal\"
  do script \"$(as_quote "$cmd")\"
end tell"
  err=$(printf '%s\n' "$script" | "$OSASCRIPT" 2>&1 >/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    reason=$(sanitise_reason "$err")
    [ -n "$reason" ] || reason="no detail from osascript"
    echo "note: Terminal.app did not open a window for $dir — nothing started ($reason)" >&2
    return 1
  fi
  return 0
}

open_windows_terminal () {
  # Git Bash / MSYS / Cygwin: wt.exe needs Windows spellings of the directory
  # and of this bash; the tab runs bash -lc so PATH resolves claude.
  local dir=$1 cmd=$2 wdir wbash body
  wdir=$(cygpath -w "$dir" 2>/dev/null) || wdir=$dir
  wbash=$(cygpath -w "$BASH" 2>/dev/null) || wbash=$BASH
  body="$(wt_escape "$cmd")\\; exec bash"
  wt.exe -w 0 nt -d "$wdir" "$wbash" -lc "$body" 2>/dev/null \
    || wt.exe nt -d "$wdir" "$wbash" -lc "$body" 2>/dev/null
}

open_windows_terminal_wsl () {
  # WSL: wsl.exe --cd takes the Linux path; the tab must run the Linux-side
  # claude. If execution aliases do not run from WSL, `cmd.exe /c wt.exe ...`
  # is the one-line change.
  local dir=$1 cmd=$2 body
  body="$(wt_escape "$cmd")\\; exec bash"
  wt.exe -w 0 nt wsl.exe --cd "$dir" -- bash -lc "$body" 2>/dev/null \
    || wt.exe nt wsl.exe --cd "$dir" -- bash -lc "$body" 2>/dev/null
}

open_gnome_terminal () {
  local dir=$1 cmd=$2
  gnome-terminal --tab --working-directory="$dir" -- bash -lc "$cmd; exec bash" 2>/dev/null
}

open_konsole () {
  local dir=$1 cmd=$2
  konsole --new-tab --workdir "$dir" -e bash -lc "$cmd; exec bash" 2>/dev/null
}

# --- Opener selection (once per run) ---------------------------------------------

opener=""
case "$uname_s" in
  Darwin)
    case "$TERM_PROG" in
      iTerm.app) opener=open_iterm ;;
      *)         opener=open_apple_terminal ;;
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*)
    command -v wt.exe >/dev/null 2>&1 && opener=open_windows_terminal
    ;;
  Linux)
    if LC_ALL=C grep -qi microsoft "$PROC_VERSION" 2>/dev/null && command -v wt.exe >/dev/null 2>&1; then
      opener=open_windows_terminal_wsl
    elif command -v gnome-terminal >/dev/null 2>&1; then
      opener=open_gnome_terminal
    elif command -v konsole >/dev/null 2>&1; then
      opener=open_konsole
    fi
    ;;
esac

# --- Open ---------------------------------------------------------------------

OPENED=()
FAILED=()
i=0
while [ "$i" -lt "$TOTAL" ]; do
  dir=${DIRS[$i]}
  if [ -z "$opener" ]; then
    FAILED+=("$i")
  elif [ ! -d "$dir" ]; then
    echo "note: $dir is not a directory — nothing started" >&2
    FAILED+=("$i")
  elif "$opener" "$dir" "${CMDS[$i]}"; then
    OPENED+=("$i")
  else
    FAILED+=("$i")
  fi
  i=$((i + 1))
done

# --- Terminal.app notes (only when something opened) -----------------------------

tabbing_mode () {
  local v
  if v=$(defaults read com.apple.Terminal AppleWindowTabbingMode 2>/dev/null) && [ -n "$v" ]; then
    printf '%s' "$v"
    return 0
  fi
  if v=$(defaults read -g AppleWindowTabbingMode 2>/dev/null) && [ -n "$v" ]; then
    printf '%s' "$v"
    return 0
  fi
  printf ''
}

if [ "$opener" = "open_apple_terminal" ] && [ "${#OPENED[@]}" -gt 0 ]; then
  if [ "$(tabbing_mode)" = "always" ]; then
    echo "note: macOS 'Prefer tabs when opening documents' is set to Always, so the" >&2
    echo "      streams opened as TABS of the frontmost Terminal window, not as windows." >&2
  fi
  if [ "$TERM_PROG" != "Apple_Terminal" ]; then
    echo "note: the stream windows opened in Terminal.app behind your current app (${TERM_PROG:-unknown terminal}) — the launcher does not steal focus." >&2
  fi
fi

# --- Report -------------------------------------------------------------------

if [ "${#OPENED[@]}" -gt 0 ]; then
  echo "Opened ${#OPENED[@]} of $TOTAL terminal(s):"
  for i in ${OPENED[@]+"${OPENED[@]}"}; do
    printf '  opened  %s  ->  %s\n' "${DIRS[$i]}" "${CMDS[$i]}"
  done
fi

if [ "${#FAILED[@]}" -gt 0 ]; then
  if [ -z "$opener" ]; then
    echo "Couldn't auto-open terminals on this terminal ($uname_s / ${TERM_PROG:-unknown})."
  else
    echo "Couldn't open ${#FAILED[@]} of $TOTAL terminal(s) on this terminal ($uname_s)."
  fi
  print_hints ${FAILED[@]+"${FAILED[@]}"}
  exit 1
fi

exit 0
