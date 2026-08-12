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

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
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

count_events() { grep -c '"type":"\(skill\|story\)"' "$LOG_REL" 2>/dev/null || true; }
count_tools()  { grep -vc '"type":"\(skill\|story\)"' "$LOG_REL" 2>/dev/null || true; }

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

echo ""
echo "post-tool-use: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
