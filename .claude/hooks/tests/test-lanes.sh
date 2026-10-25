#!/usr/bin/env bash
# Test suite for the lanes skill: lane-start.sh, lane-status.sh, lane-cleanup.sh.
# Runs against a throwaway repo and a private tmux server (TMUX_TMPDIR), so it
# never touches the user's own tmux sessions.
set -euo pipefail

PASS=0
FAIL=0
SCRIPTS="$(cd "$(dirname "$0")/../.." && pwd)/skills/lanes/scripts"

test_case() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing lanes scripts"
echo "====================="

if ! command -v tmux >/dev/null 2>&1; then
    echo "  SKIP: tmux not installed"
    exit 0
fi

TMP=$(mktemp -d)
export TMUX_TMPDIR="$TMP/tmux"
mkdir -p "$TMUX_TMPDIR"
unset TMUX XDG_CONFIG_HOME
# A home of its own, so tmux loads no ~/.tmux.conf and every key starts unbound.
export HOME="$TMP/home"
mkdir -p "$HOME"
trap 'tmux kill-server 2>/dev/null || true; rm -rf "$TMP"' EXIT

export EXOSUIT_LANES_DIR="$TMP/lanes"
export EXOSUIT_LANE_CLAUDE="true"
export EXOSUIT_LANE_SESSION="lanes-test"
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
git config --global user.name test
git config --global user.email test@example.com
git config --global init.defaultBranch main

REPO="$TMP/repo"
git init -q "$REPO"
cd "$REPO"
echo one > a.txt
echo "secret=1" > .env
echo ".env" > .gitignore
git add a.txt .gitignore
git commit -qm init

rc=0; bash "$SCRIPTS/lane-start.sh" a >/dev/null 2>&1 || rc=$?
test_case "refuses to fan out from main" "1" "$rc"

git switch -qc sprint-1
# A key of your own, bound before the lanes start, must survive them.
tmux new-session -d -s other
tmux bind-key -n M-7 display-message mine
rc=0; out=$(bash "$SCRIPTS/lane-start.sh" "a:E01-S01" b 'c:x;rm' 2>&1) || rc=$?
test_case "start exits 0" "0" "$rc"
test_case "lane a branch exists" "yes" "$(git show-ref --verify --quiet refs/heads/sprint-1-a && echo yes || echo no)"
test_case "lane a worktree exists" "yes" "$([ -d "$EXOSUIT_LANES_DIR/a" ] && echo yes || echo no)"
test_case "parent recorded for merge-up" "sprint-1" "$(git config branch.sprint-1-a.exosuitParent)"
test_case ".env copied into the lane" "secret=1" "$(cat "$EXOSUIT_LANES_DIR/a/.env")"
test_case "unsafe story id skipped" "1" "$(printf '%s\n' "$out" | grep -c '^SKIP c:' || true)"
test_case "no lane made for the unsafe story" "no" "$([ -e "$EXOSUIT_LANES_DIR/c" ] && echo yes || echo no)"
test_case "session made outside tmux" "yes" "$(tmux has-session -t =lanes-test 2>/dev/null && echo yes || echo no)"
test_case "one window per lane" "a b" "$(tmux list-windows -t =lanes-test -F '#{window_name}' | grep -E '^[ab]$' | tr '\n' ' ' | sed 's/ $//')"
test_case "window tagged with its lane" "$EXOSUIT_LANES_DIR/a" "$(tmux display-message -p -t =lanes-test:a '#{@exosuit-lane}')"
test_case "Alt+1 jumps to window 1" "bind-key -T root M-1 select-window -t :1" "$(tmux list-keys -T root M-1)"
test_case "Alt+0 goes back to the last window" "bind-key -T root M-0 last-window" "$(tmux list-keys -T root M-0)"
test_case "a key bound before is left as it was" "bind-key -T root M-7 display-message mine" "$(tmux list-keys -T root M-7)"
a_idx="$(tmux display-message -p -t =lanes-test:a '#{window_index}')"
test_case "report names the lane's Alt key" "1" "$(printf '%s\n' "$out" | grep -c "^LANE a ready: .*window=lanes-test:$a_idx (Alt+$a_idx)" || true)"

tmux unbind-key -n M-9
EXOSUIT_LANE_ALT_KEYS=0 bash "$SCRIPTS/lane-keys.sh"
test_case "EXOSUIT_LANE_ALT_KEYS=0 binds nothing" "" "$(tmux list-keys -T root M-9 2>/dev/null || true)"
bash "$SCRIPTS/lane-status.sh" >/dev/null
test_case "status binds the keys again" "bind-key -T root M-9 select-window -t :9" "$(tmux list-keys -T root M-9)"

rc=0; out=$(bash "$SCRIPTS/lane-start.sh" a 2>&1) || rc=$?
test_case "existing lane skipped" "1" "$(printf '%s\n' "$out" | grep -c '^SKIP a:' || true)"

(cd "$EXOSUIT_LANES_DIR/a" && echo two >> a.txt && git commit -qam "lane a work")
status=$(bash "$SCRIPTS/lane-status.sh")
test_case "status shows lane a one ahead" "1" "$(printf '%s\n' "$status" | awk '$1 == "a" { print $4 }')"
test_case "status shows lane a window open" "yes" "$(printf '%s\n' "$status" | awk '$1 == "a" { print $7 }')"

rc=0; (cd "$EXOSUIT_LANES_DIR/b" && bash "$SCRIPTS/lane-cleanup.sh" >/dev/null 2>&1) || rc=$?
test_case "cleanup refused from inside a lane" "1" "$rc"

out=$(bash "$SCRIPTS/lane-cleanup.sh")
test_case "unmerged lane a kept" "yes" "$([ -d "$EXOSUIT_LANES_DIR/a" ] && echo yes || echo no)"
test_case "merged lane b removed" "no" "$([ -d "$EXOSUIT_LANES_DIR/b" ] && echo yes || echo no)"
test_case "lane b branch deleted" "no" "$(git show-ref --verify --quiet refs/heads/sprint-1-b && echo yes || echo no)"
test_case "lane b window closed" "0" "$(tmux list-windows -t =lanes-test -F '#{window_name}' | grep -c '^b$' || true)"
test_case "a removed lane is not reported as orphaned" "0" "$(printf '%s\n' "$out" | grep -c '^Orphaned' || true)"

bash "$SCRIPTS/lane-start.sh" d >/dev/null
git worktree remove "$EXOSUIT_LANES_DIR/d"
out=$(bash "$SCRIPTS/lane-cleanup.sh")
test_case "window of a lane removed by hand closed as orphaned" "Orphaned windows closed: d" "$(printf '%s\n' "$out" | grep '^Orphaned' || true)"
git branch -q -d sprint-1-d

git merge -q --ff-only sprint-1-a
bash "$SCRIPTS/lane-cleanup.sh" >/dev/null
test_case "lane a removed after merge" "no" "$([ -d "$EXOSUIT_LANES_DIR/a" ] && echo yes || echo no)"
test_case "lanes folder removed when empty" "no" "$([ -d "$EXOSUIT_LANES_DIR" ] && echo yes || echo no)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
