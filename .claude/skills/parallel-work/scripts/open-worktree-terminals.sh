#!/usr/bin/env bash
# open-worktree-terminals.sh — open each given directory in a NEW TAB of the
# current terminal and launch Claude Code in it.
# Companion to new-worktree.sh: adapts to however many dirs you pass.
#
# Usage: open-worktree-terminals.sh <dir> [<dir> ...]
# Env:
#   EXOSUIT_WORKTREE_LAUNCH_CMD   command run in each new tab (default: "claude")
#   EXOSUIT_WORKTREE_TABS=0       skip auto-open; just print the cd hints
#
# Cross-platform, best-effort — degrades to new windows / printed hints when a
# platform can't script tabs:
#   macOS + iTerm2         → native tabs (no OS permission needed)          [best]
#   macOS + Terminal.app   → tabs via Cmd+T; needs Accessibility permission,
#                            else falls back to new windows (still launches claude)
#   Windows + Windows Term → `wt -w 0 nt` tabs in the current window
#   Linux + gnome/konsole  → --tab / --new-tab
#   anything else          → prints the exact commands to run by hand
set -uo pipefail

LAUNCH_CMD="${EXOSUIT_WORKTREE_LAUNCH_CMD:-claude}"

if [ "$#" -lt 1 ]; then
  echo "usage: open-worktree-terminals.sh <dir> [<dir> ...]" >&2
  exit 2
fi

# Opt-out: just print what would run.
manual_hints () {
  echo "Open a tab per worktree and run:"
  local d
  for d in "$@"; do echo "  cd '$d' && $LAUNCH_CMD"; done
}

if [ "${EXOSUIT_WORKTREE_TABS:-1}" = "0" ]; then
  manual_hints "$@"
  exit 0
fi

uname_s="$(uname -s 2>/dev/null || echo unknown)"

open_iterm () {
  local dir
  for dir in "$@"; do
    /usr/bin/osascript >/dev/null 2>&1 <<OSA || return 1
tell application "iTerm"
  activate
  if (count of windows) = 0 then
    set w to (create window with default profile)
    tell current session of w to write text "cd '$dir' && $LAUNCH_CMD"
  else
    tell current window
      create tab with default profile
      tell current session to write text "cd '$dir' && $LAUNCH_CMD"
    end tell
  end if
end tell
OSA
  done
}

open_apple_terminal () {
  # Cmd+T needs Accessibility (System Events). If it isn't granted the keystroke
  # is a no-op and `do script` opens a NEW WINDOW instead — claude still launches
  # in the right dir, just not as a tab.
  local dir
  for dir in "$@"; do
    /usr/bin/osascript >/dev/null 2>&1 <<OSA
tell application "Terminal"
  activate
  try
    tell application "System Events" to keystroke "t" using command down
    delay 0.6
  end try
  do script "cd '$dir' && $LAUNCH_CMD" in front window
  delay 0.4
end tell
OSA
  done
  if ! /usr/bin/osascript -e 'tell application "System Events" to get name of first process' >/dev/null 2>&1; then
    echo "note: grant Terminal 'Accessibility' permission (System Settings ->" >&2
    echo "      Privacy & Security -> Accessibility) for real TABS; without it" >&2
    echo "      new windows are opened instead. iTerm2 needs no permission." >&2
  fi
}

open_windows_terminal () {
  local dir winpath
  for dir in "$@"; do
    if command -v cygpath >/dev/null 2>&1; then
      winpath="$(cygpath -w "$dir")"
    else
      winpath="$dir"
    fi
    # -w 0 = the current window; nt = new-tab; -d = starting dir. Run claude via
    # the tab's default shell so PATH resolves it and the tab stays interactive.
    wt.exe -w 0 nt -d "$winpath" cmd /k "$LAUNCH_CMD" 2>/dev/null \
      || wt.exe nt -d "$winpath" cmd /k "$LAUNCH_CMD" 2>/dev/null \
      || return 1
  done
}

open_gnome_terminal () {
  local dir
  for dir in "$@"; do
    gnome-terminal --tab --working-directory="$dir" -- \
      bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null || return 1
  done
}

open_konsole () {
  local dir
  for dir in "$@"; do
    konsole --new-tab --workdir "$dir" -e \
      bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null || return 1
  done
}

opened=0
case "$uname_s" in
  Darwin)
    case "${TERM_PROGRAM:-}" in
      iTerm.app) open_iterm "$@" && opened=1 ;;
      *)         open_apple_terminal "$@" && opened=1 ;;  # Apple_Terminal / vscode / other
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if command -v wt.exe >/dev/null 2>&1; then open_windows_terminal "$@" && opened=1; fi
    ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null && command -v wt.exe >/dev/null 2>&1; then
      open_windows_terminal "$@" && opened=1        # WSL reaching Windows Terminal
    elif command -v gnome-terminal >/dev/null 2>&1; then
      open_gnome_terminal "$@" && opened=1
    elif command -v konsole >/dev/null 2>&1; then
      open_konsole "$@" && opened=1
    fi
    ;;
esac

if [ "$opened" = "1" ]; then
  echo "Opened $# tab(s), each running: $LAUNCH_CMD"
else
  echo "Couldn't auto-open tabs on this terminal ($uname_s / ${TERM_PROGRAM:-unknown})."
  manual_hints "$@"
fi
