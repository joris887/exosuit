#!/usr/bin/env bash
# Test suite for post-tool-use.sh activity-log rotation.
#
# Verifies type-aware rotation: high-volume tool lines are capped at
# MAX_ENTRIES while rare skill/story lifecycle events (parsed by /sprint-end
# metrics and /story-cycle calibration) are preserved up to MAX_EVENT_ENTRIES.
# Each case runs against an ISOLATED temp project dir so results depend on the
# fixture, not on the real repo's log.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HOOKS_DIR/post-tool-use.sh"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

# Neutralize environment overrides so results depend on fixtures only
# (mirrors test-user-prompt.sh)
export EXOSUIT_HOOK_PROFILE="standard"
export EXOSUIT_DISABLED_HOOKS=""
export EXOSUIT_PROJECT_PROFILE="standard"

# hook-guard.sh writes the resolved profile to state/project-profile on every
# invocation — save the real repo's value so the test leaves no trace.
STATE_DIR="$HOOKS_DIR/state"
SAVED_PROFILE=""
[ -f "$STATE_DIR/project-profile" ] && SAVED_PROFILE="$(cat "$STATE_DIR/project-profile")"
# The stamping cases below create/remove state/tests-passed — save the real one.
SAVED_TP_DIR="$(mktemp -d)"
[ -f "$STATE_DIR/tests-passed" ] && cp -p "$STATE_DIR/tests-passed" "$SAVED_TP_DIR/tests-passed"

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
    if [ -n "$SAVED_PROFILE" ]; then
        printf '%s' "$SAVED_PROFILE" > "$STATE_DIR/project-profile"
    else
        rm -f "$STATE_DIR/project-profile"
    fi
    if [ -f "$SAVED_TP_DIR/tests-passed" ]; then
        cp -p "$SAVED_TP_DIR/tests-passed" "$STATE_DIR/tests-passed"
    else
        rm -f "$STATE_DIR/tests-passed"
    fi
    rm -rf "$SAVED_TP_DIR"
}
trap cleanup EXIT

LOG_REL="docs/sessions/.activity-log.jsonl"

# Build an isolated project dir with a seeded activity log.
#   $1 = tool line count, $2 = skill/story event count (interleaved evenly)
make_project() {
    local tools="$1" events="$2" d
    d="$(mktemp -d "$TMP_ROOT/proj.XXXXXX")"
    mkdir -p "$d/docs/sessions"
    local i interval=0
    [ "$events" -gt 0 ] && interval=$(( tools / events + 1 ))
    for i in $(seq 1 "$tools"); do
        printf '{"ts":"2026-01-01T00:00:00Z","tool":"Bash","target":"cmd%s"}\n' "$i" >> "$d/$LOG_REL"
        if [ "$events" -gt 0 ] && [ $(( i % interval )) -eq 0 ]; then
            printf '{"type":"skill","event":"start","skill":"story-cycle","ts":"2026-01-01T00:00:00Z"}\n' >> "$d/$LOG_REL"
        fi
    done
    # Top up remaining events at the end
    local written
    written="$(grep -c '"type":"skill"' "$d/$LOG_REL" 2>/dev/null || true)"
    while [ "${written:-0}" -lt "$events" ]; do
        printf '{"type":"story","event":"status-change","id":"E01-S01","ts":"2026-01-01T00:00:00Z"}\n' >> "$d/$LOG_REL"
        written=$(( written + 1 ))
    done
    printf '%s' "$d"
}

# Invoke the hook as Claude Code would: JSON on stdin, cwd = project dir.
run_hook() {
    printf '{"tool_name":"Bash","tool_input":{"command":"marker-final-cmd"}}' | "$HOOK" >/dev/null 2>&1 || true
}

check() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (expected $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

# ERE (grep -E) for portability — BRE \| alternation is a GNU extension that
# BSD/macOS grep treats literally. Mirrors the hook's own awk regex.
count_events() { grep -Ec '"type":"(skill|story)"' "$LOG_REL" 2>/dev/null || true; }
count_tools()  { grep -Evc '"type":"(skill|story)"' "$LOG_REL" 2>/dev/null || true; }

echo "post-tool-use.sh rotation tests"
echo "-------------------------------"

# Case 1: under the cap — nothing rotates, everything survives
d="$(make_project 50 5)"
cd "$d"
run_hook
check "under-cap: skill/story events untouched" "5" "$(count_events)"
check "under-cap: tool lines = seeded + appended" "51" "$(count_tools)"
cd "$ORIG_PWD"

# Case 2: over the cap — tool lines capped at 200, events all survive
d="$(make_project 250 10)"
cd "$d"
run_hook
check "over-cap: all skill/story events preserved" "10" "$(count_events)"
check "over-cap: tool lines capped at MAX_ENTRIES" "200" "$(count_tools)"
check "over-cap: newest tool line survives rotation" "1" "$(grep -c 'marker-final-cmd' "$LOG_REL" || true)"
check "over-cap: order preserved (newest line last)" "1" "$(tail -n 1 "$LOG_REL" | grep -c 'marker-final-cmd' || true)"
cd "$ORIG_PWD"

# Case 3: event flood — events capped at MAX_EVENT_ENTRIES (500), not unbounded
d="$(make_project 10 600)"
cd "$d"
run_hook
check "event-cap: events capped at MAX_EVENT_ENTRIES" "500" "$(count_events)"
cd "$ORIG_PWD"

# --- Test-run tracking reads the real PostToolUse payload shape ---
# PostToolUse delivers the Bash result as tool_response {stdout, stderr, ...}.
# These cases pin the extraction against that shape (and the legacy fallback)
# — reading the wrong key made the tests-passed stamp and failure capture
# silently inert (the #59 class: synthetic payloads matched the
# implementation, not the platform).

# Feed the hook a payload and report which artifacts appeared.
run_payload() {
    printf '%s' "$1" | "$HOOK" >/dev/null 2>&1 || true
}

# Case 4: passing run in tool_response.stdout stamps tests-passed
d="$(make_project 1 0)"
cd "$d"
rm -f "$STATE_DIR/tests-passed"
run_payload '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"},"tool_response":{"stdout":"===== 12 passed in 0.4s =====","stderr":"","interrupted":false}}'
check "tool_response stdout pass stamps tests-passed" "true" "$([ -f "$STATE_DIR/tests-passed" ] && echo true || echo false)"
rm -f "$STATE_DIR/tests-passed"
cd "$ORIG_PWD"

# Case 5: failing run in tool_response.stderr is captured to the failure log
d="$(make_project 1 0)"
cd "$d"
run_payload '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"stdout":"","stderr":"Tests: 2 failed, 10 passed\nnpm ERR! test failed","interrupted":false}}'
check "tool_response stderr failure reaches failure log" "1" "$([ -f docs/sessions/.failure-log.jsonl ] && grep -c '"type":"test-failure"' docs/sessions/.failure-log.jsonl || echo 0)"
cd "$ORIG_PWD"

# Case 6: legacy tool_output payloads still work (defensive fallback)
d="$(make_project 1 0)"
cd "$d"
rm -f "$STATE_DIR/tests-passed"
run_payload '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"},"tool_output":"===== 3 passed in 0.1s ====="}'
check "legacy tool_output shape still stamps" "true" "$([ -f "$STATE_DIR/tests-passed" ] && echo true || echo false)"
rm -f "$STATE_DIR/tests-passed"
cd "$ORIG_PWD"

# Case 7: empty tool_response object stamps nothing
d="$(make_project 1 0)"
cd "$d"
rm -f "$STATE_DIR/tests-passed"
run_payload '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"},"tool_response":{"stdout":"","stderr":"","interrupted":false}}'
check "empty tool_response stamps nothing" "false" "$([ -f "$STATE_DIR/tests-passed" ] && echo true || echo false)"
cd "$ORIG_PWD"

echo ""
echo "post-tool-use: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
