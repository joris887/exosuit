#!/usr/bin/env bash
# Test suite for lib/graph-state.sh (flow cursor) and the session-start.sh
# resume advisory. Each case runs in an ISOLATED temp git repo; the real
# scripts are invoked with sh (they are POSIX). Verifies the hard L4
# constraint: cursor keys are additive and every existing consumer's
# extraction returns byte-identical values before and after cursor writes.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$HOOKS_DIR/lib/graph-state.sh"
SESSION_START="$HOOKS_DIR/session-start.sh"
ORIG_PWD="$(pwd)"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d)"

# Neutralize environment overrides; save/restore hook-guard's profile state
export EXOSUIT_HOOK_PROFILE="standard"
export EXOSUIT_DISABLED_HOOKS=""
export EXOSUIT_PROJECT_PROFILE="standard"
STATE_DIR="$HOOKS_DIR/state"
SAVED_PROFILE=""
[ -f "$STATE_DIR/project-profile" ] && SAVED_PROFILE="$(cat "$STATE_DIR/project-profile")"

cleanup() {
    cd "$ORIG_PWD"
    rm -rf "$TMP_ROOT"
    if [ -n "$SAVED_PROFILE" ]; then
        printf '%s' "$SAVED_PROFILE" > "$STATE_DIR/project-profile"
    else
        rm -f "$STATE_DIR/project-profile"
    fi
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

make_repo() {
    local d
    d="$(mktemp -d "$TMP_ROOT/repo.XXXXXX")"
    (
        cd "$d"
        git init -q -b sprint-7 .
        git config user.email "t@example.com"
        git config user.name "t"
        echo seed > seed.txt
        git add -A && git commit -qm init
    ) >/dev/null 2>&1
    printf '%s' "$d"
}

FS="docs/sessions/.failure-state.md"

echo "graph-state.sh + resume advisory tests"
echo "--------------------------------------"

# --- Case 1: enter creates a minimal, schema-conformant file ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter story-cycle write-plan
test_case "enter creates failure-state file" "true" "$([ -f "$FS" ] && echo true || echo false)"
test_case "created file has status active" "1" "$(grep -c '^status: active' "$FS" || true)"
test_case "created file has skill" "1" "$(grep -c '^skill: story-cycle' "$FS" || true)"
test_case "created file has cursor node" "1" "$(grep -c '^node: write-plan' "$FS" || true)"
test_case "created file records current branch" "1" "$(grep -c '^branch: "sprint-7"' "$FS" || true)"
test_case "show prints cursor" "story-cycle write-plan 1 sprint-7" "$(sh "$LIB" show)"
cd "$ORIG_PWD"

# --- Case 2: enter on an existing skill-owned file is additive ---
d="$(make_repo)"; cd "$d"
mkdir -p docs/sessions
cat > "$FS" <<'EOF'
---
status: active
skill: debug-session
phase: "3"
phase_name: "Hypothesis and Testing"
started_at: "2026-08-12T10:00:00Z"
story: "fix the login bug"
branch: "old-branch"
next_action: "test hypothesis"
files_modified: [src/login.ts]
---

## Context
Root cause: not yet identified
EOF
BEFORE_SKILL=$(grep '^skill:' "$FS" | sed 's/skill: *//' | head -1)
BEFORE_PHASE=$(grep '^phase_name:' "$FS" | sed 's/phase_name: *//' | head -1)
sh "$LIB" enter debug-session form-hypothesis
AFTER_SKILL=$(grep '^skill:' "$FS" | sed 's/skill: *//' | head -1)
AFTER_PHASE=$(grep '^phase_name:' "$FS" | sed 's/phase_name: *//' | head -1)
test_case "consumer extraction of skill unchanged" "$BEFORE_SKILL" "$AFTER_SKILL"
test_case "consumer extraction of phase_name unchanged" "$BEFORE_PHASE" "$AFTER_PHASE"
test_case "cursor keys inserted" "1" "$(grep -c '^flow: debug-session' "$FS" || true)"
test_case "context body preserved" "1" "$(grep -c '^Root cause: not yet identified' "$FS" || true)"
test_case "branch updated to current" "1" "$(grep -c '^branch: "sprint-7"' "$FS" || true)"
test_case "next_action preserved" "1" "$(grep -c '^next_action: "test hypothesis"' "$FS" || true)"

# --- Case 3: attempt increments; different node resets ---
sh "$LIB" attempt debug-session form-hypothesis
test_case "attempt increments to 2" "1" "$(grep -c '^attempt: 2' "$FS" || true)"
sh "$LIB" attempt debug-session verify-fix
test_case "attempt on new node resets to 1" "1" "$(grep -c '^attempt: 1' "$FS" || true)"
test_case "node updated" "1" "$(grep -c '^node: verify-fix' "$FS" || true)"

# --- Case 4: clear removes only cursor keys ---
sh "$LIB" clear debug-session
test_case "clear keeps the file" "true" "$([ -f "$FS" ] && echo true || echo false)"
test_case "clear removes flow key" "0" "$(grep -c '^flow:' "$FS" || true)"
test_case "clear removes node key" "0" "$(grep -c '^node:' "$FS" || true)"
test_case "clear removes attempt key" "0" "$(grep -c '^attempt:' "$FS" || true)"
test_case "clear keeps skill line" "1" "$(grep -c '^skill: debug-session' "$FS" || true)"
cd "$ORIG_PWD"

# --- Case 5: corrupt file (no closing ---) is not destroyed ---
d="$(make_repo)"; cd "$d"
mkdir -p docs/sessions
printf -- '---\nskill: broken\nsome unterminated content\n' > "$FS"
sh "$LIB" enter story-cycle some-node
test_case "corrupt file content preserved (fail-open)" "1" "$(grep -c '^some unterminated content' "$FS" || true)"
cd "$ORIG_PWD"

# --- Case 6: session-start advisory fires on branch match ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter story-cycle readiness-gate
OUT=$(sh "$SESSION_START" 2>&1 || true)
test_case "advisory names flow and node on branch match" "true" "$(printf '%s' "$OUT" | grep -q "Interrupted /story-cycle at node 'readiness-gate'" && echo true || echo false)"
cd "$ORIG_PWD"

# --- Case 7: advisory silent on branch mismatch (worktree inheritance) ---
d="$(make_repo)"; cd "$d"
sh "$LIB" enter story-cycle readiness-gate
git checkout -q -b different-branch
OUT=$(sh "$SESSION_START" 2>&1 || true)
test_case "advisory silent on branch mismatch" "true" "$(printf '%s' "$OUT" | grep -q "Interrupted /" && echo false || echo true)"
cd "$ORIG_PWD"

# --- Case 8: advisory silent for pre-cursor failure-state files ---
d="$(make_repo)"; cd "$d"
mkdir -p docs/sessions
printf -- '---\nstatus: active\nskill: debug-session\nbranch: "sprint-7"\n---\n' > "$FS"
OUT=$(sh "$SESSION_START" 2>&1 || true)
test_case "advisory silent without cursor keys" "true" "$(printf '%s' "$OUT" | grep -q "Interrupted /" && echo false || echo true)"
cd "$ORIG_PWD"

echo ""
echo "graph-state: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
