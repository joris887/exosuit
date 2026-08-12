#!/usr/bin/env bash
# Test suite for flow-pre-edit.sh and stop.sh's flow enforcement (Level 5).
# Advisory-first contract: warnings never block; blocking only with explicit
# EXOSUIT_FLOW_MODE=block; test/docs edits always exempt; everything fails
# open. Each case runs in an ISOLATED temp git repo.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRE_EDIT="$HOOKS_DIR/flow-pre-edit.sh"
STOP="$HOOKS_DIR/stop.sh"
LIB="$HOOKS_DIR/lib/graph-state.sh"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

export EXOSUIT_HOOK_PROFILE="standard"
export EXOSUIT_DISABLED_HOOKS=""
export EXOSUIT_PROJECT_PROFILE="standard"
unset EXOSUIT_FLOW_MODE 2>/dev/null || true

STATE_DIR="$HOOKS_DIR/state"
SAVE_DIR="$(mktemp -d)"
for f in project-profile session-started stop-iteration suggestions-shown tests-passed; do
    [ -f "$STATE_DIR/$f" ] && cp -p "$STATE_DIR/$f" "$SAVE_DIR/$f"
done
[ -d "$STATE_DIR/flow" ] && cp -rp "$STATE_DIR/flow" "$SAVE_DIR/flow"

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
    for f in project-profile session-started stop-iteration suggestions-shown tests-passed; do
        if [ -f "$SAVE_DIR/$f" ]; then cp -p "$SAVE_DIR/$f" "$STATE_DIR/$f"; else rm -f "$STATE_DIR/$f"; fi
    done
    rm -rf "$STATE_DIR/flow"
    [ -d "$SAVE_DIR/flow" ] && cp -rp "$SAVE_DIR/flow" "$STATE_DIR/flow"
    rm -rf "$SAVE_DIR"
    unset EXOSUIT_FLOW_MODE 2>/dev/null || true
}
trap cleanup EXIT

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

# Fixture: repo with a skill 'alpha' whose flow has an evidenced hard gate,
# and a cursor parked on that gate.
make_repo() {
    local d
    d="$(mktemp -d "$TMP_ROOT/repo.XXXXXX")"
    (
        cd "$d"
        git init -q -b sprint-7 .
        git config user.email "t@example.com"
        git config user.name "t"
        mkdir -p .claude/skills/alpha
        printf '%s\n' "## alpha" "" "### Gate" "" "## Done" > .claude/skills/alpha/SKILL.md
        cat > .claude/skills/alpha/flow.yaml <<'EOF'
flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: the-gate}
  the-gate: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Gate"}
  done: {type: terminal, doc: "## Done"}
EOF
        echo seed > seed.txt
        git add -A && git commit -qm init
    ) >/dev/null 2>&1
    printf '%s' "$d"
}

# Invoke the pre-edit hook with an Edit payload; echo "<exit> <stderr>"
run_pre_edit() {
    local file_path="$1" rc=0 err
    err=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$file_path" \
        | sh "$PRE_EDIT" 2>&1 >/dev/null) || rc=$?
    printf '%s|%s' "$rc" "$err"
}

echo "flow enforcement tests (Level 5)"
echo "--------------------------------"

rm -rf "$STATE_DIR/flow" 2>/dev/null

# --- Advisory mode (default): warns, never blocks ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter alpha the-gate
OUT="$(run_pre_edit src/main.go)"
test_case "advisory: exit 0 on source edit at unevidenced gate" "0" "${OUT%%|*}"
test_case "advisory: warning names gate and evidence" "true" "$(printf '%s' "${OUT#*|}" | grep -q "the-gate" && printf '%s' "${OUT#*|}" | grep -q "tests-green" && echo true || echo false)"

# Test-file edit is exempt (writing the test IS the evidence)
OUT="$(run_pre_edit tests/test_main.go)"
test_case "advisory: test edit exempt (no warning)" "0|" "$OUT"
OUT="$(run_pre_edit docs/notes.md)"
test_case "advisory: docs edit exempt" "0|" "$OUT"

# Evidence present -> silent
mkdir -p "$STATE_DIR/flow"; date > "$STATE_DIR/flow/tests-green"
OUT="$(run_pre_edit src/main.go)"
test_case "advisory: silent when evidence present" "0|" "$OUT"
rm -rf "$STATE_DIR/flow"

# Cursor on a non-gate node -> silent
sh "$LIB" enter alpha work
OUT="$(run_pre_edit src/main.go)"
test_case "advisory: silent on non-gate node" "0|" "$OUT"

# Branch mismatch -> silent
sh "$LIB" enter alpha the-gate
git checkout -q -b other-branch
OUT="$(run_pre_edit src/main.go)"
test_case "advisory: silent on branch mismatch" "0|" "$OUT"
git checkout -q sprint-7
cd "$ORIG_PWD"

# --- No cursor at all -> silent ---
d="$(make_repo)"; cd "$d"
OUT="$(run_pre_edit src/main.go)"
test_case "no cursor: silent" "0|" "$OUT"
cd "$ORIG_PWD"

# --- Block mode (explicit opt-in) ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter alpha the-gate
export EXOSUIT_FLOW_MODE=block
OUT="$(run_pre_edit src/main.go)"
test_case "block: exit 2 on source edit at unevidenced gate" "2" "${OUT%%|*}"
OUT="$(run_pre_edit tests/test_main.go)"
test_case "block: test edit still exempt" "0|" "$OUT"
mkdir -p "$STATE_DIR/flow"; date > "$STATE_DIR/flow/tests-green"
OUT="$(run_pre_edit src/main.go)"
test_case "block: silent when evidence present" "0|" "$OUT"
rm -rf "$STATE_DIR/flow"
unset EXOSUIT_FLOW_MODE

# --- Off mode ---
export EXOSUIT_FLOW_MODE=off
OUT="$(run_pre_edit src/main.go)"
test_case "off: silent" "0|" "$OUT"
unset EXOSUIT_FLOW_MODE

# --- Disabled via kill switch ---
export EXOSUIT_DISABLED_HOOKS="flow-pre-edit"
OUT="$(run_pre_edit src/main.go)"
test_case "kill switch: silent" "0|" "$OUT"
export EXOSUIT_DISABLED_HOOKS=""
cd "$ORIG_PWD"

# --- stop.sh flow check (block mode only) ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter alpha the-gate
echo "0" > "$STATE_DIR/stop-iteration"
export EXOSUIT_FLOW_MODE=block
RC=0; ERR=$(printf '{}' | sh "$STOP" 2>&1 >/dev/null) || RC=$?
test_case "stop block: exit 2 at non-terminal node" "2" "$RC"
test_case "stop block: message names the flow" "true" "$(printf '%s' "$ERR" | grep -q "/alpha" && echo true || echo false)"
test_case "stop block: valve incremented" "1" "$(cat "$STATE_DIR/stop-iteration")"

# Valve releases at max
echo "5" > "$STATE_DIR/stop-iteration"
RC=0; printf '{}' | sh "$STOP" >/dev/null 2>&1 || RC=$?
test_case "stop block: valve releases at max iterations" "0" "$RC"
echo "0" > "$STATE_DIR/stop-iteration"

# Terminal node -> allowed
sh "$LIB" enter alpha done
RC=0; printf '{}' | sh "$STOP" >/dev/null 2>&1 || RC=$?
test_case "stop block: terminal node allowed" "0" "$RC"

# Advisory mode -> stop.sh untouched by flow state
unset EXOSUIT_FLOW_MODE
sh "$LIB" enter alpha the-gate
date > "$STATE_DIR/tests-passed"
RC=0; printf '{}' | sh "$STOP" >/dev/null 2>&1 || RC=$?
test_case "stop advisory: no flow blocking" "0" "$RC"
rm -f "$STATE_DIR/tests-passed"
cd "$ORIG_PWD"

echo ""
echo "flow-enforce: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
