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
    # strip any test-injected conf override even if a case aborted mid-run
    sed -i '/^test_path_patterns=\*\.Tests\//d' "$HOOKS_DIR/rules/quality.conf" 2>/dev/null || true
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

# --- Superset invariant: every exempted test path also stamps evidence ---
# (the fix for the review's critical finding: an edit that would stamp
# test-written can never itself be warned or blocked)
d="$(make_repo)"; cd "$d"
cat > .claude/skills/alpha/flow.yaml <<'EOF'
flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: the-gate}
  the-gate: {type: gate.hard, ok: done, fail: STOP, evidence: test-written, doc: "### Gate"}
  done: {type: terminal, doc: "## Done"}
EOF
sh "$LIB" enter alpha the-gate
export EXOSUIT_FLOW_MODE=block
SUPERSET_OK=true
for tp in spec/user_spec.rb src/__tests__/user.js conftest.py t/basic.t Foo.Tests/FooTests.cs cypress/e2e/login.cy.js features/login.feature src/user.test.js tests/test_user.py; do
    RC="${OUT%%|*}"; OUT="$(run_pre_edit "$tp")"; RC="${OUT%%|*}"
    if [ "$RC" != "0" ] || [ -n "${OUT#*|}" ]; then SUPERSET_OK="blocked:$tp"; break; fi
    rm -rf "$STATE_DIR/flow"
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$tp" | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    if [ ! -f "$STATE_DIR/flow/test-written" ]; then SUPERSET_OK="unstamped:$tp"; break; fi
    rm -rf "$STATE_DIR/flow"
done
test_case "superset invariant: exempt paths all stamp evidence" "true" "$SUPERSET_OK"
unset EXOSUIT_FLOW_MODE
cd "$ORIG_PWD"

# --- Glob-expansion regression: patterns survive an EXISTING tests/ dir ---
# (round-2 critical: unquoted expansion matched globs against cwd files)
d="$(make_repo)"; cd "$d"
mkdir -p tests src/tests
printf 'x' > tests/conftest.py
printf 'x' > tests/test_existing.py
printf 'x' > src/tests/unit.py
test_case "glob regression: new test in existing tests/ dir" "0" "$(sh "$HOOKS_DIR/lib/test-paths.sh" tests/test_new_feature.py; echo $?)"
test_case "glob regression: absolute path with depth-2 match" "0" "$(sh "$HOOKS_DIR/lib/test-paths.sh" "$d/tests/helper_new.py"; echo $?)"
test_case "glob regression: source still not-test" "1" "$(sh "$HOOKS_DIR/lib/test-paths.sh" src/main.go; echo $?)"
# uppercase user override folds too
printf 'test_path_patterns=*.Tests/*\n' >> "$HOOKS_DIR/rules/quality.conf"
test_case "uppercase override matches after folding" "0" "$(sh "$HOOKS_DIR/lib/test-paths.sh" Foo.Tests/Bar.cs; echo $?)"
sed -i '/^test_path_patterns=\*\.Tests\//d' "$HOOKS_DIR/rules/quality.conf"
cd "$ORIG_PWD"

# --- Green-noise guard: honest green runs must stamp, not veto ---
d="$(make_repo)"; cd "$d"
if command -v jq >/dev/null 2>&1; then
    for green in "100% tests passed, 0 tests failed out of 12" "12 tests passed\nERROR StatusLogger could not find log4j2" "test_handles_error PASSED\n12 passed" "Passed! - Failed: 0, Passed: 12, Total: 12 tests passed"; do
        rm -rf "$STATE_DIR/flow"; rm -f "$STATE_DIR/tests-passed"
        printf '{"tool_name":"Bash","tool_input":{"command":"pytest"},"tool_output":"%s"}' "$green" | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
        if [ ! -f "$STATE_DIR/flow/tests-green" ]; then
            test_case "green-noise stamps: ${green%%\\n*}" "stamped" "missing"
        else
            test_case "green-noise stamps: ${green%%\\n*}" "stamped" "stamped"
        fi
    done
    rm -f "$STATE_DIR/tests-passed"
else
    echo "  SKIP: green-noise cases (jq not available)"
fi
cd "$ORIG_PWD"

# --- Dedup separator: distinct (flow,node) pairs never collide ---
d="$(make_repo)"; cd "$d"
mkdir -p .claude/skills/alpha-red
printf '%s\n' "## alpha-red" "" "### Gate" "" "## Done" > .claude/skills/alpha-red/SKILL.md
cat > .claude/skills/alpha-red/flow.yaml <<'EOF'
flow: alpha-red
spec: 1
start: gate
nodes:
  gate: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Gate"}
  done: {type: terminal, doc: "## Done"}
EOF
cat > .claude/skills/alpha/flow.yaml <<'EOF'
flow: alpha
spec: 1
start: red-gate
nodes:
  red-gate: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Gate"}
  done: {type: terminal, doc: "## Done"}
EOF
rm -rf "$STATE_DIR/flow"
sh "$LIB" enter alpha-red gate
OUT1="$(run_pre_edit src/a.go)"
sh "$LIB" clear alpha-red
sh "$LIB" enter alpha red-gate
OUT2="$(run_pre_edit src/b.go)"
test_case "dedup: first gate warns" "true" "$(printf '%s' "${OUT1#*|}" | grep -q "Flow advisory" && echo true || echo false)"
test_case "dedup: distinct (flow,node) still warns" "true" "$(printf '%s' "${OUT2#*|}" | grep -q "Flow advisory" && echo true || echo false)"
rm -rf "$STATE_DIR/flow"
cd "$ORIG_PWD"

# --- Mixed-run guard: '3 passed, 9 failed' never stamps green; failure revokes ---
d="$(make_repo)"; cd "$d"
if command -v jq >/dev/null 2>&1; then
    rm -rf "$STATE_DIR/flow"; rm -f "$STATE_DIR/tests-passed"
    printf '{"tool_name":"Bash","tool_input":{"command":"pytest"},"tool_output":"3 passed, 9 failed"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    test_case "mixed run does not stamp tests-green" "false" "$([ -f "$STATE_DIR/flow/tests-green" ] && echo true || echo false)"
    test_case "mixed run does not stamp tests-passed" "false" "$([ -f "$STATE_DIR/tests-passed" ] && echo true || echo false)"
    printf '{"tool_name":"Bash","tool_input":{"command":"pytest"},"tool_output":"12 passed"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    test_case "clean pass stamps tests-green" "true" "$([ -f "$STATE_DIR/flow/tests-green" ] && echo true || echo false)"
    printf '{"tool_name":"Bash","tool_input":{"command":"pytest"},"tool_output":"12 failed"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    test_case "failing run revokes tests-green" "false" "$([ -f "$STATE_DIR/flow/tests-green" ] && echo true || echo false)"
    # unittest and maven red formats also revoke
    date > "$STATE_DIR/flow/tests-green"
    printf '{"tool_name":"Bash","tool_input":{"command":"make test"},"tool_output":"FAILED (errors=2)"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    test_case "unittest errors=2 revokes tests-green" "false" "$([ -f "$STATE_DIR/flow/tests-green" ] && echo true || echo false)"
    date > "$STATE_DIR/flow/tests-green"
    printf '{"tool_name":"Bash","tool_input":{"command":"mvn test"},"tool_output":"BUILD FAILURE"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    test_case "maven BUILD FAILURE revokes tests-green" "false" "$([ -f "$STATE_DIR/flow/tests-green" ] && echo true || echo false)"
    # failure log lines are valid single-line JSON even at zero fail-count
    rm -f docs/sessions/.failure-log.jsonl
    printf '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_output":"npm ERR! code ELIFECYCLE"}' | sh "$HOOKS_DIR/post-tool-use.sh" >/dev/null 2>&1 || true
    FLOG_LINES=$(wc -l < docs/sessions/.failure-log.jsonl 2>/dev/null | tr -d ' ')
    FLOG_VALID=$(head -1 docs/sessions/.failure-log.jsonl 2>/dev/null | jq -e . >/dev/null 2>&1 && echo true || echo false)
    test_case "failure log: one line per failure entry" "1" "$FLOG_LINES"
    test_case "failure log: entry is valid JSON" "true" "$FLOG_VALID"
    rm -f "$STATE_DIR/tests-passed"
else
    echo "  SKIP: mixed-run cases (jq not available)"
fi
cd "$ORIG_PWD"

# --- Advisory dedup: identical warning fires once, not per edit ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter alpha the-gate
rm -rf "$STATE_DIR/flow"
OUT1="$(run_pre_edit src/main.go)"
OUT2="$(run_pre_edit src/other.go)"
test_case "advisory dedup: first edit warns" "true" "$(printf '%s' "${OUT1#*|}" | grep -q "Flow advisory" && echo true || echo false)"
test_case "advisory dedup: second edit silent" "" "${OUT2#*|}"
rm -rf "$STATE_DIR/flow"
cd "$ORIG_PWD"

# --- Prose-spoof: doc text cannot fake structural attrs ---
d="$(make_repo)"; cd "$d"
cat > .claude/skills/alpha/flow.yaml <<'EOF'
flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: the-gate, doc: "### Gate"}
  the-gate: {type: gate.hard, ok: done, fail: STOP, doc: "### Gate"}
  done: {type: terminal, doc: "## Done"}
EOF
# gate has NO evidence attr; put fake 'evidence: tests-green' in a doc string
sed -i 's|the-gate: {type: gate.hard, ok: done, fail: STOP, doc: "### Gate"}|the-gate: {type: gate.hard, ok: done, fail: STOP, doc: "### Gate evidence: tests-green"}|' .claude/skills/alpha/flow.yaml
printf '%s\n' "### Gate evidence: tests-green" >> .claude/skills/alpha/SKILL.md
sh "$LIB" enter alpha the-gate
export EXOSUIT_FLOW_MODE=block
OUT="$(run_pre_edit src/main.go)"
test_case "prose-spoof: evidence in doc string ignored" "0|" "$OUT"
unset EXOSUIT_FLOW_MODE
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

# CLEAN tree: the check must still fire (regression: SESSIONS_DIR was only
# set inside the dirty-tree auto-save block, silently disabling this check)
git add -A >/dev/null 2>&1; git commit -qm "state" >/dev/null 2>&1 || true
printf 'docs/sessions/\n.claude/hooks/state/\n' > .gitignore
git add .gitignore >/dev/null 2>&1 && git commit -qm ignore >/dev/null 2>&1
sh "$LIB" enter alpha the-gate
git add -A >/dev/null 2>&1; git commit -qm "cursor" >/dev/null 2>&1 || true
echo "0" > "$STATE_DIR/stop-iteration"
RC=0; printf '{}' | sh "$STOP" >/dev/null 2>&1 || RC=$?
test_case "stop block: fires on CLEAN working tree too" "2" "$RC"
echo "0" > "$STATE_DIR/stop-iteration"

# Terminal prose-spoof: doc mentioning 'type: terminal' must not fake type
sed -i 's|the-gate: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Gate"}|the-gate: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Gate type: terminal"}|' .claude/skills/alpha/flow.yaml 2>/dev/null || true
if grep -q 'type: terminal"' .claude/skills/alpha/flow.yaml; then
    printf '%s\n' "### Gate type: terminal" >> .claude/skills/alpha/SKILL.md
    sh "$LIB" enter alpha the-gate
    RC=0; printf '{}' | sh "$STOP" >/dev/null 2>&1 || RC=$?
    test_case "stop block: doc prose cannot fake terminal type" "2" "$RC"
    echo "0" > "$STATE_DIR/stop-iteration"
fi

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
