#!/usr/bin/env bash
# Test suite for doctor/scripts/validate-flows.sh (flow contract validation).
#
# Each case builds an ISOLATED temp project root with fixture flow.yaml +
# SKILL.md files and runs the validator from that root, so results depend on
# the fixture, not on the real repo. The final case validates the repo's own
# shipped flow contracts.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"
VALIDATOR="$REPO_ROOT/.claude/skills/doctor/scripts/validate-flows.sh"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

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

# Build a fixture project root containing one skill with the given flow.yaml
# body. SKILL.md carries the headings the default fixtures anchor to.
make_fixture() {
    local name="$1" flow_body="$2" d
    d="$(mktemp -d "$TMP_ROOT/proj.XXXXXX")"
    mkdir -p "$d/.claude/skills/$name"
    printf '%s\n' "## $name" "" "### Do Work" "" "## Done" > "$d/.claude/skills/$name/SKILL.md"
    printf '%s\n' "$flow_body" > "$d/.claude/skills/$name/flow.yaml"
    printf '%s' "$d"
}

# Run validator in dir $1; echo its exit code (never aborts the test).
run_validator() {
    local rc=0
    ( cd "$1" && bash "$VALIDATOR" >/dev/null 2>&1 ) || rc=$?
    printf '%s' "$rc"
}

# Count FAIL lines the validator prints for dir $1
count_fails() {
    ( cd "$1" && bash "$VALIDATOR" 2>/dev/null || true ) | grep -Ec '^  FAIL ' || true
}

VALID_FLOW='flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: done, doc: "### Do Work"}
  done: {type: terminal, doc: "## Done"}'

echo "validate-flows.sh tests"
echo "-----------------------"

# Case 1: minimal valid flow
d="$(make_fixture alpha "$VALID_FLOW")"
check "valid flow passes" "0" "$(run_validator "$d")"

# Case 2: unresolved edge target
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: missing-node}
  done: {type: terminal}')"
check "unresolved edge target fails" "1" "$(run_validator "$d")"

# Case 3: router without default
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: fork
nodes:
  fork: {type: router, special: done}
  done: {type: terminal}')"
check "router missing default fails" "1" "$(run_validator "$d")"

# Case 4: no terminal node
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: work2}
  work2: {type: step, next: STOP}')"
check "no terminal fails" "1" "$(run_validator "$d")"

# Case 5: trap region — cycle with no exit to terminal or STOP
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: a
nodes:
  a: {type: step, next: b}
  b: {type: step, next: a}
  done: {type: terminal}')"
check "trap region fails" "1" "$(run_validator "$d")"

# Case 6: gateless escapable cycle without max -> WARN but exit 0
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: a
nodes:
  a: {type: step, next: b}
  b: {type: router, retry: a, default: done}
  done: {type: terminal}')"
rc="$(run_validator "$d")"
warns=$( ( cd "$d" && bash "$VALIDATOR" 2>/dev/null || true ) | grep -Ec '^  WARN .*cycle' || true)
check "unbounded escapable cycle exits 0" "0" "$rc"
check "unbounded escapable cycle warns" "1" "$warns"

# Case 7: loop node with max in the cycle -> no cycle warning
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: a
nodes:
  a: {type: step, next: check}
  check: {type: loop, back: a, done: done, max: 2}
  done: {type: terminal}')"
rc="$(run_validator "$d")"
warns=$( ( cd "$d" && bash "$VALIDATOR" 2>/dev/null || true ) | grep -Ec '^  WARN .*cycle' || true)
check "max-bounded loop exits 0" "0" "$rc"
check "max-bounded loop has no cycle warning" "0" "$warns"

# Case 8: doc anchor that does not exist in SKILL.md
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: done, doc: "### A Heading That Is Not There"}
  done: {type: terminal}')"
check "missing doc anchor fails" "1" "$(run_validator "$d")"

# Case 9: flow name does not match directory
d="$(make_fixture alpha 'flow: beta
spec: 1
start: work
nodes:
  work: {type: step, next: done}
  done: {type: terminal}')"
check "flow/dir name mismatch fails" "1" "$(run_validator "$d")"

# Case 10: unknown node type
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: banana, next: done}
  done: {type: terminal}')"
check "unknown node type fails" "1" "$(run_validator "$d")"

# Case 10b: router with only a default edge (no named edge) fails
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: fork
nodes:
  fork: {type: router, default: done}
  done: {type: terminal}')"
check "router without named edge fails" "1" "$(run_validator "$d")"

# Case 10c: fanout with a single target fails cardinality
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: fan
nodes:
  fan: {type: fanout, to: [only-one]}
  only-one: {type: step, next: done}
  done: {type: terminal}')"
check "fanout with one target fails" "1" "$(run_validator "$d")"

# Case 10d: CRLF line endings fail with a clear diagnosis
d="$(make_fixture alpha "$VALID_FLOW")"
printf '%s\r\n' "flow: alpha" "spec: 1" "start: work" "nodes:" \
  '  work: {type: step, next: done}' '  done: {type: terminal}' \
  > "$d/.claude/skills/alpha/flow.yaml"
check "CRLF file fails" "1" "$(run_validator "$d")"
crlf_msgs=$( ( cd "$d" && bash "$VALIDATOR" 2>/dev/null || true ) | grep -Ec '^  FAIL ' || true)
check "CRLF file fails with exactly one message" "1" "$crlf_msgs"

# Case 10e: doc anchor starting with '-' is not parsed as a grep option
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: done, doc: "- a dash-prefixed anchor line"}
  done: {type: terminal}')"
printf '%s\n' "- a dash-prefixed anchor line" >> "$d/.claude/skills/alpha/SKILL.md"
check "dash-prefixed doc anchor passes" "0" "$(run_validator "$d")"

# Case 10f: evidence attr on a gate.hard with a stampable marker passes
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: gate.hard, ok: done, fail: STOP, evidence: tests-green, doc: "### Do Work"}
  done: {type: terminal, doc: "## Done"}')"
check "evidence on gate.hard with known marker passes" "0" "$(run_validator "$d")"

# Case 10g: evidence with an unstampable marker fails
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: gate.hard, ok: done, fail: STOP, evidence: vibes-good}
  done: {type: terminal}')"
check "evidence with unknown marker fails" "1" "$(run_validator "$d")"

# Case 10h: evidence on a non-gate.hard node fails
d="$(make_fixture alpha 'flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: done, evidence: tests-green}
  done: {type: terminal}')"
check "evidence on non-gate node fails" "1" "$(run_validator "$d")"

# Case 11: project with no flow files passes vacuously
d="$(mktemp -d "$TMP_ROOT/proj.XXXXXX")"
mkdir -p "$d/.claude/skills/alpha"
printf '%s\n' "## alpha" > "$d/.claude/skills/alpha/SKILL.md"
check "no flow files passes vacuously" "0" "$(run_validator "$d")"

# Case 12: the repo's own shipped flow contracts are conformant
check "shipped flow contracts conformant" "0" "$(run_validator "$REPO_ROOT")"
fails="$(count_fails "$REPO_ROOT")"
check "shipped flow contracts have zero FAIL lines" "0" "$fails"

echo ""
echo "validate-flows: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
