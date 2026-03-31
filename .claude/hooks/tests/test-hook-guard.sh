#!/usr/bin/env bash
# Test suite for lib/hook-guard.sh — profile hierarchy and hook disabling
set -euo pipefail

GUARD="../lib/hook-guard.sh"
PASS=0
FAIL=0

test_case() {
    local desc="$1"
    local expected_exit="$2"
    local actual_exit="$3"

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing lib/hook-guard.sh"
echo "========================="

# Save and unset env vars to test defaults
SAVED_PROJECT_PROFILE="${JD_PROJECT_PROFILE:-}"
SAVED_HOOK_PROFILE="${JD_HOOK_PROFILE:-}"
SAVED_DISABLED="${JD_DISABLED_HOOKS:-}"
SAVED_MAX_ITER="${JD_STOP_MAX_ITERATIONS:-}"

cleanup_env() {
    export JD_PROJECT_PROFILE="$SAVED_PROJECT_PROFILE"
    export JD_HOOK_PROFILE="$SAVED_HOOK_PROFILE"
    export JD_DISABLED_HOOKS="$SAVED_DISABLED"
    export JD_STOP_MAX_ITERATIONS="$SAVED_MAX_ITER"
}
trap cleanup_env EXIT

# --- Profile hierarchy tests ---
echo ""
echo "  -- Profile hierarchy: minimal(1) < standard(2) < strict(3) --"

# Standard profile, standard minimum → run (2 >= 2)
export JD_HOOK_PROFILE="standard" JD_DISABLED_HOOKS="" JD_PROJECT_PROFILE=""
actual=0; sh "$GUARD" "test-hook" "standard" || actual=$?
test_case "Standard profile >= standard minimum → run" 0 "$actual"

# Standard profile, minimal minimum → run (2 >= 1)
actual=0; sh "$GUARD" "test-hook" "minimal" || actual=$?
test_case "Standard profile >= minimal minimum → run" 0 "$actual"

# Standard profile, strict minimum → skip (2 < 3)
actual=0; sh "$GUARD" "test-hook" "strict" || actual=$?
test_case "Standard profile < strict minimum → skip" 1 "$actual"

# Strict profile, strict minimum → run (3 >= 3)
export JD_HOOK_PROFILE="strict"
actual=0; sh "$GUARD" "test-hook" "strict" || actual=$?
test_case "Strict profile >= strict minimum → run" 0 "$actual"

# Minimal profile, standard minimum → skip (1 < 2)
export JD_HOOK_PROFILE="minimal"
actual=0; sh "$GUARD" "test-hook" "standard" || actual=$?
test_case "Minimal profile < standard minimum → skip" 1 "$actual"

# Minimal profile, minimal minimum → run (1 >= 1)
actual=0; sh "$GUARD" "test-hook" "minimal" || actual=$?
test_case "Minimal profile >= minimal minimum → run" 0 "$actual"

# --- Project profile → hook profile mapping ---
echo ""
echo "  -- Project profile derives hook profile --"

# Lean project → minimal hooks
unset JD_HOOK_PROFILE
export JD_PROJECT_PROFILE="lean" JD_DISABLED_HOOKS=""
actual=0; sh "$GUARD" "test-hook" "standard" || actual=$?
test_case "Lean project → minimal hooks: skip standard" 1 "$actual"

actual=0; sh "$GUARD" "test-hook" "minimal" || actual=$?
test_case "Lean project → minimal hooks: run minimal" 0 "$actual"

# Standard project → standard hooks
export JD_PROJECT_PROFILE="standard"
actual=0; sh "$GUARD" "test-hook" "standard" || actual=$?
test_case "Standard project → standard hooks: run standard" 0 "$actual"

# Strict project → strict hooks
export JD_PROJECT_PROFILE="strict"
actual=0; sh "$GUARD" "test-hook" "strict" || actual=$?
test_case "Strict project → strict hooks: run strict" 0 "$actual"

# --- Hook disabling ---
echo ""
echo "  -- Hook disabling via JD_DISABLED_HOOKS --"

export JD_HOOK_PROFILE="standard" JD_PROJECT_PROFILE=""

# Disable specific hook
export JD_DISABLED_HOOKS="my-hook"
actual=0; sh "$GUARD" "my-hook" "minimal" || actual=$?
test_case "Disabled hook 'my-hook' → skip" 1 "$actual"

# Different hook not disabled
actual=0; sh "$GUARD" "other-hook" "minimal" || actual=$?
test_case "Non-disabled hook 'other-hook' → run" 0 "$actual"

# Multiple disabled hooks (comma-separated)
export JD_DISABLED_HOOKS="hook-a,hook-b,hook-c"
actual=0; sh "$GUARD" "hook-b" "minimal" || actual=$?
test_case "Disabled in list: 'hook-b' → skip" 1 "$actual"

actual=0; sh "$GUARD" "hook-d" "minimal" || actual=$?
test_case "Not in disabled list: 'hook-d' → run" 0 "$actual"

# Empty disabled list
export JD_DISABLED_HOOKS=""
actual=0; sh "$GUARD" "any-hook" "minimal" || actual=$?
test_case "Empty disabled list → run" 0 "$actual"

# --- Hook profile override ---
echo ""
echo "  -- JD_HOOK_PROFILE overrides project profile --"

export JD_PROJECT_PROFILE="lean" JD_HOOK_PROFILE="strict" JD_DISABLED_HOOKS=""
actual=0; sh "$GUARD" "test-hook" "strict" || actual=$?
test_case "Lean project + strict hook override → run strict" 0 "$actual"

export JD_PROJECT_PROFILE="strict" JD_HOOK_PROFILE="minimal"
actual=0; sh "$GUARD" "test-hook" "standard" || actual=$?
test_case "Strict project + minimal hook override → skip standard" 1 "$actual"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
