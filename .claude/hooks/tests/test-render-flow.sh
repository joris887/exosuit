#!/usr/bin/env bash
# Test suite for doctor/scripts/render-flow.sh (generated flow views).
# Determinism, node/edge fidelity vs flow.yaml, --check staleness detection,
# and the GENERATED marker. Fixture cases run in isolated temp roots; the
# final cases verify the repo's own shipped views.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"
RENDER="$REPO_ROOT/.claude/skills/doctor/scripts/render-flow.sh"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

cleanup() { cd "$ORIG_PWD"; rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

check() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $name"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $name (expected '$expected', got '$actual')"; FAIL=$((FAIL + 1))
    fi
}

make_fixture() {
    local d
    d="$(mktemp -d "$TMP_ROOT/proj.XXXXXX")"
    mkdir -p "$d/.claude/skills/alpha" "$d/.claude/skills/doctor/scripts"
    cp "$RENDER" "$d/.claude/skills/doctor/scripts/render-flow.sh"
    printf '%s\n' "## alpha" "" "### Gate" "" "## Done" > "$d/.claude/skills/alpha/SKILL.md"
    cat > "$d/.claude/skills/alpha/flow.yaml" <<'EOF'
flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: the-gate, doc: "## alpha"}
  the-gate: {type: gate.hard, ok: fan, fail: STOP, evidence: tests-green, doc: "### Gate"}
  fan: {type: fanout, to: [a, b], doc: "### Gate"}
  a: {type: step, next: meet, doc: "### Gate"}
  b: {type: step, next: meet, doc: "### Gate"}
  meet: {type: join, next: done, doc: "### Gate"}
  done: {type: terminal, next_skill: [continue, handoff], doc: "## Done"}
EOF
    printf '%s' "$d"
}

echo "render-flow.sh tests"
echo "--------------------"

# --- Determinism: two renders are byte-identical ---
d="$(make_fixture)"; cd "$d"
bash "$RENDER" alpha > r1.out
bash "$RENDER" alpha > r2.out
check "deterministic output" "true" "$(cmp -s r1.out r2.out && echo true || echo false)"

# --- Node fidelity: every flow.yaml node appears; shapes per type ---
NODES_YAML=$(grep -Ec '^  [a-z0-9-]+: \{' .claude/skills/alpha/flow.yaml)
NODES_MMD=$(grep -Ec '^  [a-z0-9_]+[\[({]' r1.out)
check "all nodes rendered (incl. STOP + next_skill refs)" "true" "$([ "$NODES_MMD" -ge "$NODES_YAML" ] && echo true || echo false)"
check "gate rendered as hexagon" "1" "$(grep -c 'n_the_gate{{' r1.out || true)"
check "terminal rendered as circle" "1" "$(grep -c 'n_done((' r1.out || true)"
check "fanout renders both branches" "2" "$(grep -c '^  n_fan --> ' r1.out || true)"
check "STOP edge rendered" "1" "$(grep -c 'n_the_gate -->|fail| stop1' r1.out || true)"
check "next_skill rendered dashed" "2" "$(grep -c -- '-\.->|next skill|' r1.out || true)"
check "GENERATED marker present" "1" "$(grep -c 'GENERATED FILE' r1.out || true)"
check "edge table present" "1" "$(grep -c '^## Edges' r1.out || true)"

# --- --write / --check lifecycle ---
bash "$RENDER" --write >/dev/null 2>&1
check "--write creates generated file" "true" "$([ -f .claude/skills/alpha/flow.generated.md ] && echo true || echo false)"
RC=0; bash "$RENDER" --check >/dev/null 2>&1 || RC=$?
check "--check passes when current" "0" "$RC"
printf '# manual edit\n' >> .claude/skills/alpha/flow.generated.md
RC=0; bash "$RENDER" --check >/dev/null 2>&1 || RC=$?
check "--check fails on manual edit" "1" "$RC"
bash "$RENDER" --write >/dev/null 2>&1
sed 's/next: the-gate/next: done/' .claude/skills/alpha/flow.yaml > .claude/skills/alpha/flow.yaml.sedtmp && mv .claude/skills/alpha/flow.yaml.sedtmp .claude/skills/alpha/flow.yaml
RC=0; bash "$RENDER" --check >/dev/null 2>&1 || RC=$?
check "--check fails after flow.yaml change" "1" "$RC"
cd "$ORIG_PWD"

# --- Orphan detection: generated view without flow.yaml fails --check ---
d="$(make_fixture)"; cd "$d"
bash "$RENDER" --write >/dev/null 2>&1
rm .claude/skills/alpha/flow.yaml
RC=0; bash "$RENDER" --check >/dev/null 2>&1 || RC=$?
check "--check flags orphaned generated view" "1" "$RC"
cd "$ORIG_PWD"

# --- Reserved-word ids: node named 'end' renders with safe mermaid id ---
d="$(make_fixture)"; cd "$d"
cat > .claude/skills/alpha/flow.yaml <<'EOF'
flow: alpha
spec: 1
start: work
nodes:
  work: {type: step, next: end, doc: "## alpha"}
  end: {type: terminal, doc: "## Done"}
EOF
bash "$RENDER" alpha > r3.out
check "reserved id 'end' gets safe prefix" "1" "$(grep -c '^  n_end((' r3.out || true)"
check "no bare reserved id in edges" "0" "$(grep -c '^  n_work --> end$' r3.out || true)"

# --- Typo'd skill filter errors instead of vacuous pass ---
RC=0; bash "$RENDER" --check no-such-skill >/dev/null 2>&1 || RC=$?
check "unknown skill filter exits 1" "1" "$RC"
cd "$ORIG_PWD"

# --- Repo's own shipped views are current and complete ---
cd "$REPO_ROOT"
RC=0; bash "$RENDER" --check >/dev/null 2>&1 || RC=$?
check "shipped views current" "0" "$RC"
for s in sprint-start sprint-end story-cycle; do
    N_YAML=$(grep -Ec '^  [a-z0-9-]+: \{' ".claude/skills/$s/flow.yaml")
    N_VIEW=$(grep -Ec '^  [a-z0-9_]+[\[({]' ".claude/skills/$s/flow.generated.md")
    check "$s: view covers all $N_YAML nodes" "true" "$([ "$N_VIEW" -ge "$N_YAML" ] && echo true || echo false)"
done
cd "$ORIG_PWD"

echo ""
echo "render-flow: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
