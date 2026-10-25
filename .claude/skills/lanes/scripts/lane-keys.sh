#!/usr/bin/env bash
# Alt+1 to Alt+9 jump straight to the window with that number, Alt+0 back to
# the last window. On a phone that is one tap each: in Termius, tap Alt, then
# the number. No Ctrl-b first.
#
# Bound on the running tmux server, so they work in every session until the
# server stops; lane-start.sh and lane-status.sh run this each time. A key you
# bound yourself is left as it is.
#
# Env: EXOSUIT_LANE_ALT_KEYS=0 turns this off.
set -euo pipefail

[ "${EXOSUIT_LANE_ALT_KEYS:-1}" = "0" ] && exit 0
command -v tmux >/dev/null 2>&1 || exit 0
tmux list-sessions >/dev/null 2>&1 || exit 0

# A free key prints nothing on stdout ("unknown key" goes to stderr).
bind_if_free () {
  local key="$1"; shift
  if [ -z "$(tmux list-keys -T root "$key" 2>/dev/null || true)" ]; then
    tmux bind-key -n "$key" "$@"
  fi
}

for n in 1 2 3 4 5 6 7 8 9; do
  bind_if_free "M-$n" select-window -t ":$n"
done
bind_if_free M-0 last-window
