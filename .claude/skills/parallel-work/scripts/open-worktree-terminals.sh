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

# Each opener takes ONE directory and returns nonzero when the tab couldn't
# be opened, so the report below can say per directory what actually happened.
open_iterm () {
  local dir="$1"
  /usr/bin/osascript >/dev/null 2>&1 <<OSA
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
}

open_apple_terminal () {
  # Cmd+T needs Accessibility (System Events). If it isn't granted the keystroke
  # is a no-op and `do script` opens a NEW WINDOW instead — claude still launches
  # in the right dir, just not as a tab.
  local dir="$1"
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
}

open_windows_terminal () {
  # Native Windows bash (Git Bash / MSYS / Cygwin): cygpath exists here and
  # cmd.exe needs the Windows form of the path.
  local dir="$1" winpath
  if command -v cygpath >/dev/null 2>&1; then
    winpath="$(cygpath -w "$dir")"
  else
    winpath="$dir"
  fi
  # -w 0 = the current window; nt = new-tab; -d = starting dir. Run claude via
  # the tab's default shell so PATH resolves it and the tab stays interactive.
  wt.exe -w 0 nt -d "$winpath" cmd /k "$LAUNCH_CMD" 2>/dev/null \
    || wt.exe nt -d "$winpath" cmd /k "$LAUNCH_CMD" 2>/dev/null
}

open_windows_terminal_wsl () {
  # WSL: wsl.exe --cd takes the Linux path directly (cygpath is an MSYS tool
  # and doesn't exist here), and the tab must run the LINUX-side claude — a
  # Windows-side claude can't reach this side's Claude Code sessions.
  local dir="$1"
  wt.exe -w 0 nt wsl.exe --cd "$dir" -- bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null \
    || wt.exe nt wsl.exe --cd "$dir" -- bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null
}

open_gnome_terminal () {
  gnome-terminal --tab --working-directory="$1" -- \
    bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null
}

open_konsole () {
  konsole --new-tab --workdir "$1" -e \
    bash -lc "$LAUNCH_CMD; exec bash" 2>/dev/null
}

# Pick the per-directory opener for this platform (empty = can't script tabs).
opener=""
case "$uname_s" in
  Darwin)
    case "${TERM_PROGRAM:-}" in
      iTerm.app) opener=open_iterm ;;
      *)         opener=open_apple_terminal ;;  # Apple_Terminal / vscode / other
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*)
    command -v wt.exe >/dev/null 2>&1 && opener=open_windows_terminal
    ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null && command -v wt.exe >/dev/null 2>&1; then
      opener=open_windows_terminal_wsl        # WSL reaching Windows Terminal
    elif command -v gnome-terminal >/dev/null 2>&1; then
      opener=open_gnome_terminal
    elif command -v konsole >/dev/null 2>&1; then
      opener=open_konsole
    fi
    ;;
esac

opened=() failed=()
if [ -n "$opener" ]; then
  for dir in "$@"; do
    if "$opener" "$dir"; then opened+=("$dir"); else failed+=("$dir"); fi
  done
else
  failed=("$@")
fi

if [ "$opener" = "open_apple_terminal" ] && \
   ! /usr/bin/osascript -e 'tell application "System Events" to get name of first process' >/dev/null 2>&1; then
  echo "note: grant Terminal 'Accessibility' permission (System Settings ->" >&2
  echo "      Privacy & Security -> Accessibility) for real TABS; without it" >&2
  echo "      new windows are opened instead. iTerm2 needs no permission." >&2
fi

if [ "${#opened[@]}" -gt 0 ]; then
  echo "Opened ${#opened[@]} of $# tab(s), each running: $LAUNCH_CMD"
  for dir in "${opened[@]}"; do echo "  opened  $dir"; done
fi
if [ "${#failed[@]}" -gt 0 ]; then
  if [ -z "$opener" ]; then
    echo "Couldn't auto-open tabs on this terminal ($uname_s / ${TERM_PROGRAM:-unknown})."
  else
    echo "Couldn't open ${#failed[@]} of $# tab(s) on this terminal ($uname_s)."
  fi
  manual_hints "${failed[@]}"
fi
