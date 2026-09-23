#!/usr/bin/env bash
# Test suite for stop.sh completion evidence validation.
#
# Each case runs stop.sh against an ISOLATED temp git repo so results depend on
# the fixture, not on whatever the real repo happens to have uncommitted.
# (The earlier version ran against the live repo and silently changed behaviour
# depending on the working tree.)
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HOOKS_DIR/stop.sh"
STATE_DIR="$HOOKS_DIR/state"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
    rm -f "$STATE_DIR/tests-passed"
    echo "0" > "$STATE_DIR/stop-iteration" 2>/dev/null || true
}
trap cleanup EXIT

# Build an isolated repo fixture. Kinds:
#   docs         — only markdown changed (contains the literal word TODO)
#   code         — a .go file changed AND go.mod present (test suite exists)
#   code-notests — a .go file changed, NO test-suite marker present
make_repo() {
    local kind="$1"
    local d
    d="$(mktemp -d "$TMP_ROOT/repo.XXXXXX")"
    (
        cd "$d"
        git init -q .
        git config user.email "t@example.com"
        git config user.name "t"
        echo seed > seed.txt
        git add -A
        git commit -qm init
        case "$kind" in
            docs)
                printf '| Epic | Done | TODO |\n|---|---|---|\n' > BACKLOG.md
                ;;
            code)
                printf 'module example.com/x\n\ngo 1.23\n' > go.mod
                printf 'package main\n\nfunc main() {\n\t// TODO: refine\n\tprintln("hi")\n}\n' > main.go
                ;;
            code-notests)
                printf 'package main\n\nfunc main() { println("hi") }\n' > main.go
                ;;
        esac
        git add -A
    ) >/dev/null 2>&1
    printf '%s' "$d"
}

reset_state() {
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    echo "0" > "$STATE_DIR/stop-iteration" 2>/dev/null || true
    rm -f "$STATE_DIR/tests-passed" 2>/dev/null || true
}

# run_case <description> <repo-kind> <last_assistant_message> <expected-exit>
run_case() {
    local desc="$1" kind="$2" msg="$3" expected="$4"
    local repo actual=0

    reset_state
    repo="$(make_repo "$kind")"
    cd "$repo"
    printf '{"last_assistant_message":"%s"}' "$msg" | sh "$HOOK" >/dev/null 2>/dev/null || actual=$?
    cd "$ORIG_PWD"

    if [ "$actual" -eq "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

# stderr_case <description> <repo-kind> <message> <must-NOT-contain>
stderr_case() {
    local desc="$1" kind="$2" msg="$3" forbidden="$4"
    local repo out

    reset_state
    repo="$(make_repo "$kind")"
    cd "$repo"
    out="$(printf '{"last_assistant_message":"%s"}' "$msg" | sh "$HOOK" 2>&1 >/dev/null || true)"
    cd "$ORIG_PWD"

    if printf '%s' "$out" | grep -q "$forbidden"; then
        echo "  FAIL: $desc (stderr unexpectedly contained '$forbidden')"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

echo "Testing stop.sh"
echo "================"

echo ""
echo "  -- Core behaviour (code changed, test suite present) --"

# Must still BLOCK: genuine completion claim about code, no test evidence.
run_case "Block completion claim without evidence" \
    code 'The implementation is done.' 2

# Must ALLOW: completion claim accompanied by test output.
run_case "Allow completion claim with test output" \
    code 'The implementation is done. 15 tests passed.' 0

# Must ALLOW: no completion claim at all.
run_case "Allow non-completion message" \
    code 'Here is the code change I made.' 0

# Must ALLOW: post-tool-use.sh already recorded a passing run this session.
reset_state
repo="$(make_repo code)"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/tests-passed"
actual=0
cd "$repo"
printf '{"last_assistant_message":"The implementation is done."}' | sh "$HOOK" >/dev/null 2>/dev/null || actual=$?
cd "$ORIG_PWD"
rm -f "$STATE_DIR/tests-passed"
if [ "$actual" -eq 0 ]; then
    echo "  PASS: Allow when tests-passed state file exists"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Allow when tests-passed state file exists (expected 0, got $actual)"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "  -- Regressions: false positives that used to fire --"

# BUG 1: a docs-only session was asked for test output.
run_case "Docs-only change never demands test output" \
    docs 'Bootstrap complete. Discovery finished.' 0

# BUG 2: 'complete' in ordinary prose triggered the completion regex.
run_case "Bare word 'complete' in prose is not a completion claim" \
    code 'Secret scan complete. Research complete. Nothing to report.' 0

# BUG 3: no test suite in the project, yet test output was demanded.
run_case "No test suite means no evidence demand" \
    code-notests 'The implementation is done.' 0

# BUG 4: a markdown table column named TODO tripped the code-debug audit.
stderr_case "Markdown TODO does not trigger the debug audit" \
    docs 'The implementation is done.' 'TODO/FIXME'

# BUG 4b: TODO in real source no longer warns either — pattern is opt-in now.
stderr_case "TODO in source does not warn while pattern is disabled" \
    code 'The implementation is done. 3 tests passed.' 'TODO/FIXME'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
