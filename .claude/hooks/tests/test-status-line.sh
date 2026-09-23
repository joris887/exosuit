#!/usr/bin/env bash
# Test suite for status-line.sh — git state rendering (non-git, clean, dirty, staged, detached)
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

test_contains() {
    local desc="$1"
    local needle="$2"
    local haystack="$3"

    case "$haystack" in
        *"$needle"*)
            echo "  PASS: $desc"
            PASS=$((PASS + 1))
            ;;
        *)
            echo "  FAIL: $desc (expected to contain '$needle', got '$haystack')"
            FAIL=$((FAIL + 1))
            ;;
    esac
}

test_not_contains() {
    local desc="$1"
    local needle="$2"
    local haystack="$3"

    case "$haystack" in
        *"$needle"*)
            echo "  FAIL: $desc (expected NOT to contain '$needle', got '$haystack')"
            FAIL=$((FAIL + 1))
            ;;
        *)
            echo "  PASS: $desc"
            PASS=$((PASS + 1))
            ;;
    esac
}

# Run the status line from the current directory, stripped of ANSI codes
run_statusline() {
    bash "$HOOKS_DIR/status-line.sh" </dev/null 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g'
}

echo "Testing status-line.sh git state rendering"
echo "============================================"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# --- 1. Non-git directory must not render as detached/dirty ---
echo ""
echo "  -- non-git directory --"
mkdir "$TMPDIR_TEST/nogit"
cd "$TMPDIR_TEST/nogit"
OUT=$(run_statusline)
test_contains     "non-git dir shows 'no git'" "no git" "$OUT"
test_not_contains "non-git dir does not show 'detached'" "detached" "$OUT"
test_not_contains "non-git dir shows no dirty marker" "*" "$OUT"
test_not_contains "non-git dir shows no staged marker" "+" "$OUT"

# --- 2. Clean repo on a branch ---
echo ""
echo "  -- git repo states --"
mkdir "$TMPDIR_TEST/repo"
cd "$TMPDIR_TEST/repo"
git init -q
git config user.email "test@test.local"
git config user.name "Test"
echo "hello" > file.txt
git add file.txt
git commit -qm "init"
git checkout -qb feature-x
OUT=$(run_statusline)
test_contains     "clean repo shows branch name" "feature-x" "$OUT"
test_not_contains "clean repo shows no dirty marker" "*" "$OUT"
test_not_contains "clean repo shows no staged marker" "+" "$OUT"

# --- 3. Unstaged change ---
echo "changed" >> file.txt
OUT=$(run_statusline)
test_contains "unstaged change shows *" "feature-x*" "$OUT"

# --- 4. Staged change ---
git add file.txt
OUT=$(run_statusline)
test_contains "staged change shows +" "feature-x+" "$OUT"

# --- 5. Detached HEAD ---
git commit -qm "second"
git checkout -q --detach
OUT=$(run_statusline)
test_contains "detached HEAD shows 'detached'" "detached" "$OUT"

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
